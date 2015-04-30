#include "json.h"
#include "DvrClient.h"
#include "Trace.h"
#include "DvipMsg.h"
#include "UtilFuncs.h"
#include "MD5Inc.h"

unsigned int CDvrClient::s_ui_RequestId = 0;
unsigned int CDvrClient::s_ui_LoginId = 0;
unsigned int CDvrClient::s_ui_RealHandle = 0;

#ifdef PLAT_WIN32
int InitWinSock()
{
    WSADATA wsaData;
    return WSAStartup(MAKEWORD(2,2),&wsaData);
}
int CleanupWinSock()
{
    return WSACleanup();
}
#endif

CDvrClient::CDvrClient()
{
    m_hThread = NULL;
    m_bExitThread = true;;
    
    //±æ∂À–≈œ¢
    m_strUsername = "";  //”√ªß√˚
    m_strPassword = "";  //√‹¬Î
    
    //∑˛ŒÒ∂À–≈œ¢
    m_strServIp = ""; //∑˛ŒÒ∂Àip
    m_iServPort = 0;		 //∑˛ŒÒ∂À∂Àø⁄
    
    m_sSock = FCL_INVALID_SOCKET; //¡¨Ω”Ã◊Ω”◊÷
    m_emStatus = emIdle; //¡¨Ω”◊¥Ã¨
    m_error = 0;
    m_uiSessionId = 0; //µ«¬ºª·ª∞id
    m_iTimeout = 15; //≥¨ ± ±º‰ √Î
    
    m_iFailedTimes = 0; //¡¨–¯ ß∞‹¥Œ ˝
    m_bAutoReConnect = false;	// «∑Ò◊‘∂Ø÷ÿ¡¨
    m_uiLoginId = 0;
    m_llLastTime = 0;
    m_bIsFirstConnect = true;
    
    m_cbOnDisConnect = 0;
    m_pUser = 0;
    
    m_cbOnDisConnectEx = 0;
    m_pUserEx = 0;
    
    m_iRecvIndex = 0;
    
    m_cbOnEventNotify = NULL;
    m_pEventNotifyUser = NULL;
    
    m_cbOnAlarmNotify = NULL;
    m_pAlarmNotifyUser = NULL;
    
    m_uiEventObjectId = 0;
    m_uiSid = 0;
    m_uiSubscribeReqId = 0;
    m_bHasSubscrible = false;
    
    m_uiSnapObjectId = 0;
    
    m_idle=IDLE_NORMAL;
    
    m_hasMainConn = NULL;
    m_pMainConn = NULL;
    for (int i = 0; i<MAX_CHANNEL;i++)
    {
        memset(&m_RealPlayArray[i],0,sizeof(RealPlayTag));
    }
    
    m_uRealHandle = 0;
    
#ifdef PLAT_WIN32
    InitWinSock();
#endif
}

CDvrClient::~CDvrClient()
{
    Clear_Tasks();
#ifdef PLAT_WIN32
    CleanupWinSock();
#endif
}

//CDvrClient * CDvrClient::Instance()
//{
//	static CDvrClient s_instance;
//	return &s_instance;
//}

int CDvrClient::Start()
{
    if ( 0 != StartThread() )
    {
        ERROR_TRACE("start thread failed.");
        return -1;
    }
    return 0;
}

int CDvrClient::Stop()
{
    if ( 0 != StopThread() )
    {
        ERROR_TRACE("stop thread failed.");
        return -1;
    }
    return 0;
}

int CDvrClient::Login()
{
    return Connect_Async();
    //return -1;
}

int CDvrClient::Logout()
{
    return -1;
}

//∆Ù∂Ø
int CDvrClient::StartThread()
{
    m_bExitThread = false;
#ifdef PLAT_WIN32
    DWORD dwThreadId;
    m_hThread = CreateThread(NULL,0,CDvrClient::ThreadProc,this,0,&dwThreadId);
#else
    pthread_attr_t attr;
    int iRet;
    if ( (iRet = ::pthread_attr_init(&attr)) != 0 )
    {
        ERROR_TRACE("pthread_attr_init() failed! error code="<<iRet);
        return -1;
    }
    
    int dstate = PTHREAD_CREATE_JOINABLE;
    
    if ( (iRet = ::pthread_attr_setdetachstate(&attr,dstate)) != 0 )
    {
        ERROR_TRACE("pthread_attr_setdetachstate() failed! error code="<<iRet);
        ::pthread_attr_destroy(&attr);
        return -1;
    }
    
    if ((iRet = ::pthread_create(&m_hThread, &attr,CDvrClient::ThreadProc, this)) != 0)
    {
        ERROR_TRACE("pthread_create() failed! error code="<<iRet);
        ::pthread_attr_destroy(&attr);
        return -1;
    }
    ::pthread_attr_destroy(&attr);
#endif
    
    return 0;
}
//Ω· ¯
int CDvrClient::StopThread()
{
    m_bExitThread = true;
    if ( NULL == m_hThread )
    {
        return 0;
    }
#ifdef PLAT_WIN32
    DWORD dwRet;
    dwRet = WaitForSingleObject(m_hThread,5000);
    if ( dwRet == WAIT_TIMEOUT )
    {
        TerminateThread(m_hThread,0);
    }
#else
    void *result;
    pthread_join(m_hThread,&result);
#endif
    m_hThread = 0;
    
    return 0;
}
#ifdef WIN32
unsigned long __stdcall CDvrClient::ThreadProc(void *pParam)
#else
void* CDvrClient::ThreadProc(void *pParam)
#endif
{
    CDvrClient *pUser = (CDvrClient*)pParam;
    pUser->ThreadProc();
    return 0;
}

void CDvrClient::ThreadProc(void)
{
    while ( !m_bExitThread )
    {
        Thread_Process();
        FclSleep(1);
    }
}

void CDvrClient::Thread_Process()
{
    //ºÏ≤È∂® ±∆˜
    long long llCur = GetCurrentTimeMs();
    int iRet;
    bool bRet;
    
    switch ( m_emStatus )
    {
        case emIdle: //ø’œ–◊¥Ã¨
        {
            //m_llLastTime = GetCurrentTimeMs();
            
            if ( m_bAutoReConnect ) //∂œœﬂ◊‘∂Ø÷ÿ¡¨
            {
                if ( _abs64(m_llLastTime-GetCurrentTimeMs()) > CDvrClient::GS_LOGIN_TIMEOUT )
                {
                    iRet = Connect_Async();
                    if ( 0 > iRet ) // ß∞‹
                    {
                        ERROR_TRACE("connect failed");
                        m_llLastTime = GetCurrentTimeMs();
                        OnRegisterFailed(emDisRe_ConnectFailed);
                    }
                    else
                    {
                        m_llLastTime = GetCurrentTimeMs();
                    }
                }
            }
            break;
        }
        case emConnecting:
        {
            if ( _abs64(m_llLastTime-GetCurrentTimeMs()) > CDvrClient::GS_LOGIN_TIMEOUT )
            {
                ERROR_TRACE("connect timeout");
                m_llLastTime = GetCurrentTimeMs();
                m_emStatus = emIdle;
                OnRegisterFailed(emDisRe_ConnectTimeout);
            }
            break;
        }
        case emConnected:
        {
            //m_emStatus = emRegistered;
            //◊¢≤·
            bRet = LoginRequest();
            
            if ( bRet )
            {
                m_emStatus = emRegistering;
                m_llLastTime = GetCurrentTimeMs();
            }
            else
            {
                ERROR_TRACE("reqister failed");
                m_emStatus = emIdle;
                m_llLastTime = GetCurrentTimeMs();
                OnRegisterFailed(emDisRe_RegistedFailed);
            }
            break;
        }
        case emRegistering:
        {
            if ( _abs64(m_llLastTime-GetCurrentTimeMs()) > CDvrClient::GS_LOGIN_TIMEOUT )
            {
                ERROR_TRACE("register timeout");
                m_llLastTime = GetCurrentTimeMs();
                m_emStatus = emIdle;
                OnRegisterFailed(emDisRe_RegistedTimeout);
            }
            break;
        }
        case emRegistered:
        {
            if ( _abs64(m_llLastTime-GetCurrentTimeMs()) > CDvrClient::GS_KEEPALIVE_INTEVAL )
            {
                m_iFailedTimes++;
                if ( m_iFailedTimes >= 3 ) //≥¨π˝±£ªÓ¥Œ ˝
                {
                    //ªÿµ˜…œ≤„,±£ªÓ ß∞‹
                    ERROR_TRACE("keepalive timeout");
                    //m_emStatus = emIdle;
                    OnDisConnected(emDisRe_Keepalivetimeout);
                }
                else //∑¢ÀÕ±£ªÓ«Î«Û
                {
                    m_llLastTime = llCur;
                    KeepaliveRequest();
                }
            }
            else
            {
                Process_Task();
            }
            break;
        }
        default:
            WARN_TRACE("unknown status");
            break;
    }
    
    PollData();
    
    return ;
}

int CDvrClient::Connect_Async() //¡¨Ω”
{
    //	fd_set fds;
    //	timeval tv;
    //	int iTotal;
    int iRet;
    
    if ( m_sSock != FCL_INVALID_SOCKET )
    {
        FCL_CLOSE_SOCKET(m_sSock);
    }
    
    m_sSock = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
    
    int nosigpipe = 1;
    setsockopt(m_sSock, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe, sizeof(nosigpipe));
    
    if( FCL_INVALID_SOCKET == m_sSock )
    {
        ERROR_TRACE("create socket failed,errno="<<WSAGetLastError());
        return -1;
    }
    
    int iBlock = 1;
#ifdef PLAT_WIN32
    iRet = ::ioctlsocket(m_sSock,FIONBIO,(u_long FAR *)&iBlock);
    if ( SOCKET_ERROR == iRet )
    {
        ERROR_TRACE("set socket opt failed,errno="<<WSAGetLastError());
        FCL_CLOSE_SOCKET(m_sSock);
        return -1;
    }
#else
    iBlock = ::fcntl(m_sSock, F_GETFL, 0);
    if ( -1 != iBlock )
    {
        iBlock |= O_NONBLOCK;
        iRet = ::fcntl(m_sSock, F_SETFL, iBlock);
        if ( -1 == iRet )
        {
            ERROR_TRACE("set socket opt failed,errno="<<WSAGetLastError());
            FCL_CLOSE_SOCKET(m_sSock);
            return -1;
        }
    }
#endif
    
    SetTcpKeepalive(m_sSock);
    
    sockaddr_in servAddr;
    servAddr.sin_family = AF_INET;
    servAddr.sin_addr.s_addr = inet_addr(m_strServIp.c_str());
    servAddr.sin_port = htons(m_iServPort);
    iRet = connect(m_sSock,(struct sockaddr*) &servAddr,sizeof(servAddr));
    if ( FCL_SOCKET_ERROR == iRet )
    {
#ifdef PLAT_WIN32
        if ( WSAEWOULDBLOCK == WSAGetLastError() )
        {
#else
            if ( EINPROGRESS == WSAGetLastError() )
            {
                //errno = EWOULDBLOCK;
#endif
                m_emStatus = emConnecting;
                m_llLastTime = GetCurrentTimeMs();
                return 0; //◊Ë»˚,µ»¥˝¡¨Ω”
                
            }
            else // ß∞‹
            {
                ERROR_TRACE("connect failed,errno="<<WSAGetLastError());
                FCL_CLOSE_SOCKET(m_sSock);
                return -1;
            }
        }
        else
        {
            INFO_TRACE("connect ok");
            m_emStatus = emConnected;
            m_llLastTime = GetCurrentTimeMs();
            return 1;
        }
        
        return 0;
    }
    
    int CDvrClient::PollData()
    {
        int fds;
        timeval tv;
        int iTotal;
        fd_set fd_send;
        fd_set fd_recv;
        fd_set fd_expt;
        FD_ZERO(&fd_send);
        FD_ZERO(&fd_recv);
        FD_ZERO(&fd_expt);
        sockaddr_in addr;
        int iAddrSize = sizeof(addr);
        FCL_SOCKET sock = FCL_INVALID_SOCKET;
        int iCount = 0;
        bool bIsConnecting = false;
        
        int iDataLen =0;
        
        tv.tv_sec = 0;
        tv.tv_usec = 100*1000;
        fds = 0;
        FD_ZERO(&fd_recv);
        FD_ZERO(&fd_send);
        
        //¥¶¿Ì√ø∏ˆª·ª∞
        if ( FCL_INVALID_SOCKET == m_sSock )
        {
            return -1;
        }
        
        if ( emConnecting == m_emStatus ) //’˝‘⁄¡¨Ω”
        {
            bIsConnecting = true;
            FD_SET(m_sSock,&fd_send);
        }
        else
        {
            FD_SET(m_sSock,&fd_recv);
        }
        FD_SET(m_sSock,&fd_expt);
        
        fds = (int)m_sSock;
        
        //if ( fds <= 0 )
        //{
        //	//WARN_TRACE("not socket to process");
        //	return 0;
        //}
        
        iTotal = select(fds+1,&fd_recv,&fd_send,&fd_expt,&tv);
#ifdef PLAT_WIN32
        if ( SOCKET_ERROR == iTotal )
        {
            errno = WSAGetLastError();
            ERROR_TRACE("socket select error. errno="<<errno<<".");
            return -1;
        }
#else
        if ( -1 == iTotal )
        {
            ERROR_TRACE("socket select error. errno="<<errno<<".");
            return -1;
        }
#endif
        if ( iTotal == 0 ) //≥¨ ±
        {
            //continue;
            return 0;
        }
        
        if ( FD_ISSET(m_sSock,&fd_recv) )
        {
            OnDataRecv();
            return 1;
        }
        else if ( FD_ISSET(m_sSock,&fd_send) )
        {
            if ( bIsConnecting ) //¡¨Ω”≥…π¶
            {
                //Õ®÷™¡¨Ω”≥…π¶
                OnConnect();
                return 1;
            }
            else
            {
                OnDataSend();
                return 1;
            }
        }
        else
        {
            return -1;
        }
        
    }
    
    bool CDvrClient::LoginRequest() //µ«¬º«Î«Û
    {
        dvip_hdr hdr;
        Json::Value jsonContent;
        unsigned int uiReqId;
        unsigned int uiContentLength = 0;
        std::string strContent;
        char szBuf[1024];
        int iPacketLength;
        int iSendLength;
        
        uiReqId = CreateReqId();
        hdr.size = DVIP_HDR_LENGTH;		//hdr≥§∂»
        //MAGIC
        hdr.magic[0] = 'D';
        hdr.magic[1] = 'H';
        hdr.magic[2] = 'I';
        hdr.magic[3] = 'P';
        hdr.session_id = 0;
        hdr.request_id = uiReqId;
        hdr.packet_length = 0;
        hdr.packet_index = 0;
        hdr.message_length = 0;
        hdr.data_length = 0;
        
        jsonContent["id"] = uiReqId; //«Î«Ûid requstId
        jsonContent["method"] = "global.login"; //∑Ω∑® µ«¬º«Î«Û
        ////≤Œ ˝¡–±Ì
        //jsonContent["params"]["deviceId"] = "Dahua3.0"; //…Ë±∏ID£¨Œ®“ª±Í ∂∆ΩÃ®π‹¿Ìœ¬µƒ…Ë±∏£¨◊˜Œ™¥˙¿Ìº∂¡™∂®Œªƒø±Í…Ë±∏ ± π”√
        //jsonContent["params"]["proxyToken"] = "Dahua3.0"; //¥˙¿Ì¡Ó≈∆£¨”√”⁄¥˙¿Ì∑˛ŒÒ∆˜º¯»® π”√
        jsonContent["params"]["loginType"] = "Direct"; //µ«¬º∑Ω Ω Œ™ø’±Ì æ"Direct" "Direct" µ„∂‘µ„µ«¬º "CMS" Õ®π˝CMS∑˛ŒÒ∆˜µ«¬º "LDAP" Õ®π˝LDAP∑˛ŒÒ∆˜µ«¬º "ActiveDirectory" Õ®π˝AD∑˛ŒÒ∆˜µ«¬º
        jsonContent["params"]["userName"] = m_strUsername; //”√ªß√˚
        jsonContent["params"]["password"] = "******";//m_strPassword; //√‹¬Î
        jsonContent["params"]["clientType"] = "Dahua3.0"; //øÕªß∂À¿‡–Õ
        jsonContent["params"]["ipAddr"] = "127.0.0.1"; //øÕªß∂Àipµÿ÷∑
        jsonContent["params"]["authorityType"] = "Default"; //º¯»®∑Ω Ω "Default" ®C ƒ¨»œº¯»®∑Ω Ω  "HttpDigest" ®C HTTP ’™“™º¯»®∑Ω Ω
        //jsonContent["params"]["authorityInfo"] = "127.0.0.1"; //∏Ωº”º¯»®–≈œ¢  "authorityType" Œ™ "Default"  ±£¨∆‰÷µŒ™ø’°£ "authorityType" Œ™ "HttpDigest"  ±£¨∆‰÷µŒ™£∫nc:cnonce:qop:ha2°£≤Œº˚HttpDigestº¯»®º”√‹
        //jsonContent["params"]["stochasticId"] = "127.0.0.1"; //ÀÊª˙ ˝£¨”√”⁄∑¿µ¡∞Ê—È÷§£¨Ωˆµ⁄“ª¥Œ«Î«Û ±‘ˆº”¥À÷µ
        jsonContent["params"]["userTag"] = "zwan";
        
        strContent = jsonContent.toStyledString();
        uiContentLength = strContent.size();
        hdr.packet_length = uiContentLength;
        hdr.message_length = uiContentLength;
        
        memcpy(szBuf,&hdr,DVIP_HDR_LENGTH);
        memcpy(&szBuf[DVIP_HDR_LENGTH],strContent.c_str(),uiContentLength);
        
        //∑¢ÀÕ ˝æ›
        iPacketLength = uiContentLength+DVIP_HDR_LENGTH;
        iSendLength = send(m_sSock,szBuf,iPacketLength,0);
        if ( iSendLength  == iPacketLength )
        {
            //∑¢ÀÕ≥…π¶
            //return true;
        }
        else if ( iSendLength == FCL_SOCKET_ERROR )
        {
            ERROR_TRACE("send login request failed.err="<<WSAGetLastError());
            return false;
        }
        else// if ( iSendLength < iPacketLength )
        {
            INFO_TRACE("send parital data.total="<<iPacketLength<<" sended="<<iSendLength);
            //ÃÌº”µΩ∑¢ÀÕª∫≥Â¡–±Ì÷–
            //return true;
        }
        TransInfo *pTrans = new TransInfo;
        if ( !pTrans )
        {
            ERROR_TRACE("out of memory");
            return false;
        }
        pTrans->type = emRT_Login;
        pTrans->seq = uiReqId;
        AddRequest(uiReqId,pTrans);
        return true;
    }
    //µ«¬º«Î«Û(»®º¯–≈œ¢)
    bool CDvrClient::LoginRequest(unsigned int uiSessId
                                  ,const char *pPasswordMd5
                                  ,const char *pPasswordType
                                  ,const char *pRandom
                                  ,const char *pRealm)
    {
        dvip_hdr hdr;
        Json::Value jsonContent;
        unsigned int uiReqId;
        unsigned int uiContentLength = 0;
        std::string strContent;
        char szBuf[1024];
        int iPacketLength;
        int iSendLength;
        
        uiReqId = CreateReqId();
        hdr.size = DVIP_HDR_LENGTH;		//hdr≥§∂»
        //MAGIC
        hdr.magic[0] = 'D';
        hdr.magic[1] = 'H';
        hdr.magic[2] = 'I';
        hdr.magic[3] = 'P';
        hdr.session_id = uiSessId;
        hdr.request_id = uiReqId;
        hdr.packet_length = 0;
        hdr.packet_index = 0;
        hdr.message_length = 0;
        hdr.data_length = 0;
        
        jsonContent["id"] = uiReqId; //«Î«Ûid requstId
        jsonContent["session"] = uiSessId; //session-id
        jsonContent["method"] = "global.login"; //∑Ω∑® µ«¬º«Î«Û
        ////≤Œ ˝¡–±Ì
        //jsonContent["params"]["deviceId"] = "Dahua3.0"; //…Ë±∏ID£¨Œ®“ª±Í ∂∆ΩÃ®π‹¿Ìœ¬µƒ…Ë±∏£¨◊˜Œ™¥˙¿Ìº∂¡™∂®Œªƒø±Í…Ë±∏ ± π”√
        //jsonContent["params"]["proxyToken"] = "Dahua3.0"; //¥˙¿Ì¡Ó≈∆£¨”√”⁄¥˙¿Ì∑˛ŒÒ∆˜º¯»® π”√
        //jsonContent["params"]["loginType"] = "Dahua3.0"; //µ«¬º∑Ω Ω Œ™ø’±Ì æ"Direct" "Direct" µ„∂‘µ„µ«¬º "CMS" Õ®π˝CMS∑˛ŒÒ∆˜µ«¬º "LDAP" Õ®π˝LDAP∑˛ŒÒ∆˜µ«¬º "ActiveDirectory" Õ®π˝AD∑˛ŒÒ∆˜µ«¬º
        jsonContent["params"]["userName"] = m_strUsername; //”√ªß√˚
        jsonContent["params"]["password"] = pPasswordMd5;//m_strPassword; //√‹¬Î
        jsonContent["params"]["passwordType"] = pPasswordType;//m_strPassword; //√‹¬Î
        jsonContent["params"]["random"] = pRandom;//m_strPassword; //√‹¬Î
        jsonContent["params"]["realm"] = pRealm;//m_strPassword; //√‹¬Î
        jsonContent["params"]["clientType"] = "Dahua3.0"; //øÕªß∂À¿‡–Õ
        jsonContent["params"]["ipAddr"] = "127.0.0.1"; //øÕªß∂Àipµÿ÷∑
        //jsonContent["params"]["authorityType"] = "Default"; //º¯»®∑Ω Ω "Default" ®C ƒ¨»œº¯»®∑Ω Ω  "HttpDigest" ®C HTTP ’™“™º¯»®∑Ω Ω
        //jsonContent["params"]["authorityInfo"] = "127.0.0.1"; //∏Ωº”º¯»®–≈œ¢  "authorityType" Œ™ "Default"  ±£¨∆‰÷µŒ™ø’°£ "authorityType" Œ™ "HttpDigest"  ±£¨∆‰÷µŒ™£∫nc:cnonce:qop:ha2°£≤Œº˚HttpDigestº¯»®º”√‹
        //jsonContent["params"]["stochasticId"] = pRandom; //ÀÊª˙ ˝£¨”√”⁄∑¿µ¡∞Ê—È÷§£¨Ωˆµ⁄“ª¥Œ«Î«Û ±‘ˆº”¥À÷µ
        jsonContent["params"]["userTag"] = "zwan";
        
        strContent = jsonContent.toStyledString();
        uiContentLength = strContent.size();
        hdr.packet_length = uiContentLength;
        hdr.message_length = uiContentLength;
        
        memcpy(szBuf,&hdr,DVIP_HDR_LENGTH);
        memcpy(&szBuf[DVIP_HDR_LENGTH],strContent.c_str(),uiContentLength);
        
        //∑¢ÀÕ ˝æ›
        iPacketLength = uiContentLength+DVIP_HDR_LENGTH;
        iSendLength = send(m_sSock,szBuf,iPacketLength,0);
        if ( iSendLength  == iPacketLength )
        {
            //∑¢ÀÕ≥…π¶
            //return true;
        }
        else if ( iSendLength == FCL_SOCKET_ERROR )
        {
            ERROR_TRACE("send login request failed.err="<<WSAGetLastError());
            return false;
        }
        else// if ( iSendLength < iPacketLength )
        {
            INFO_TRACE("send parital data.total="<<iPacketLength<<" sended="<<iSendLength);
            //ÃÌº”µΩ∑¢ÀÕª∫≥Â¡–±Ì÷–
            //return true;
        }
        TransInfo *pTrans = new TransInfo;
        if ( !pTrans )
        {
            ERROR_TRACE("out of memory");
            return false;
        }
        pTrans->type = emRT_Login;
        pTrans->seq = uiReqId;
        AddRequest(uiReqId,pTrans);
        return true;
    }
    bool CDvrClient::KeepaliveRequest() //±£ªÓ«Î«Û
    {
        dvip_hdr hdr;
        Json::Value jsonContent;
        unsigned int uiReqId;
        unsigned int uiContentLength = 0;
        std::string strContent;
        char szBuf[1024];
        int iPacketLength;
        int iSendLength;
        
        uiReqId = CreateReqId();
        hdr.size = DVIP_HDR_LENGTH;		//hdr≥§∂»
        //MAGIC
        hdr.magic[0] = 'D';
        hdr.magic[1] = 'H';
        hdr.magic[2] = 'I';
        hdr.magic[3] = 'P';
        hdr.session_id = m_uiSessionId;
        hdr.request_id = uiReqId;
        hdr.packet_length = 0;
        hdr.packet_index = 0;
        hdr.message_length = 0;
        hdr.data_length = 0;
        
        jsonContent["id"] = uiReqId; //«Î«Ûid requstId
        jsonContent["session"] = m_uiSessionId; //session-id
        jsonContent["method"] = "global.keepAlive"; //∑Ω∑® ±£ªÓ«Î«Û
        ////≤Œ ˝¡–±Ì
        jsonContent["params"]["timeout"] = 60;//m_iTimeout; //≥¨ ± ±º‰
        
        strContent = jsonContent.toStyledString();
        uiContentLength = strContent.size();
        hdr.packet_length = uiContentLength;
        hdr.message_length = uiContentLength;
        
        memcpy(szBuf,&hdr,DVIP_HDR_LENGTH);
        memcpy(&szBuf[DVIP_HDR_LENGTH],strContent.c_str(),uiContentLength);
        
        //∑¢ÀÕ ˝æ›
        iPacketLength = uiContentLength+DVIP_HDR_LENGTH;
        iSendLength = send(m_sSock,szBuf,iPacketLength,0);
        if ( iSendLength  == iPacketLength )
        {
            //∑¢ÀÕ≥…π¶
            //INFO_TRACE("[keepalive] send keepalive req");
            //return true;
        }
        else if ( iSendLength == FCL_SOCKET_ERROR )
        {
            ERROR_TRACE("send keepalive request failed.err="<<WSAGetLastError());
            return false;
        }
        else// if ( iSendLength < iPacketLength )
        {
            INFO_TRACE("send parital data.total="<<iPacketLength<<" sended="<<iSendLength);
            //ÃÌº”µΩ∑¢ÀÕª∫≥Â¡–±Ì÷–
            //return true;
        }
        TransInfo *pTrans = new TransInfo(uiReqId,emRT_Keepalive,GetCurrentTimeMs(),CDvrClient::GS_KEEPALIVE_INTEVAL);
        if ( !pTrans )
        {
            ERROR_TRACE("out of memory");
            return false;
        }
        //pTrans->type = emRT_Keepalive;
        //pTrans->seq = uiReqId;
        //pTrans->timeout = CDvrClient::GS_KEEPALIVE_INTEVAL;
        AddRequest(uiReqId,pTrans);
        //INFO_TRACE("[keepalive] add req "<<pTrans->seq);
        return true;
    }
    bool CDvrClient::LogoutRequest() //µ«≥ˆ«Î«Û
    {
        dvip_hdr hdr;
        Json::Value jsonContent;
        unsigned int uiReqId;
        unsigned int uiContentLength = 0;
        std::string strContent;
        char szBuf[1024];
        int iPacketLength;
        int iSendLength;
        
        uiReqId = CreateReqId();
        hdr.size = DVIP_HDR_LENGTH;		//hdr≥§∂»
        //MAGIC
        hdr.magic[0] = 'D';
        hdr.magic[1] = 'H';
        hdr.magic[2] = 'I';
        hdr.magic[3] = 'P';
        hdr.session_id = m_uiSessionId;
        hdr.request_id = uiReqId;
        hdr.packet_length = 0;
        hdr.packet_index = 0;
        hdr.message_length = 0;
        hdr.data_length = 0;
        
        jsonContent["id"] = uiReqId; //«Î«Ûid requstId
        jsonContent["method"] = "global.logout"; //∑Ω∑® µ«≥ˆ«Î«Û
        ////≤Œ ˝¡–±Ì
        //jsonContent["params"]["timeout"] = m_iTimeout; //”√ªß√˚
        
        strContent = jsonContent.toStyledString();
        uiContentLength = strContent.size();
        hdr.packet_length = uiContentLength;
        hdr.message_length = uiContentLength;
        
        memcpy(szBuf,&hdr,DVIP_HDR_LENGTH);
        memcpy(&szBuf[DVIP_HDR_LENGTH],strContent.c_str(),uiContentLength);
        
        //∑¢ÀÕ ˝æ›
        iPacketLength = uiContentLength+DVIP_HDR_LENGTH;
        iSendLength = send(m_sSock,szBuf,iPacketLength,0);
        if ( iSendLength  == iPacketLength )
        {
            //∑¢ÀÕ≥…π¶
            //return true;
        }
        else if ( iSendLength == FCL_SOCKET_ERROR )
        {
            ERROR_TRACE("send logout request failed.err="<<WSAGetLastError());
            return false;
        }
        else// if ( iSendLength < iPacketLength )
        {
            INFO_TRACE("send parital data.total="<<iPacketLength<<" sended="<<iSendLength);
            //ÃÌº”µΩ∑¢ÀÕª∫≥Â¡–±Ì÷–
            //return true;
        }
        TransInfo *pTrans = new TransInfo(uiReqId,emRT_Logout,GetCurrentTimeMs());
        if ( !pTrans )
        {
            ERROR_TRACE("out of memory");
            return false;
        }
        //pTrans->type = emRT_Logout;
        //pTrans->seq = uiReqId;
        AddRequest(uiReqId,pTrans);
        return true;
    }
    
    CDvipMsg * CDvrClient::CreateMsg(EmRequestType emType)
    {
        CDvipMsg *pMsg = NULL;
        
        switch ( emType )
        {
            case emRT_method_v_b_v:
            {
                CMsg_method_v_b_v_rsp *pMsgInst = new CMsg_method_v_b_v_rsp();
                pMsg = pMsgInst;
                break;
            }
            case emRT_method_json_b_json:
            {
                CMsg_method_json_b_json_rsp *pMsgInst = new CMsg_method_json_b_json_rsp();
                pMsg = pMsgInst;
                break;
            }
                
            case emRT_instance:	//ªÒ»° µ¿˝
            {
                CMsgDvip_instance_rsp *pMsgInst = new CMsgDvip_instance_rsp();
                pMsg = pMsgInst;
                break;
            }
            case emRT_destroy:	// Õ∑≈ µ¿˝
            {
                CMsgDvip_destroy_rsp *pMsgInst = new CMsgDvip_destroy_rsp();
                pMsg = pMsgInst;
                break;
            }
                
            case emRT_getConfig:
            {
                CMsgConfigManager_getConfig_rsp *pMsgInst = new CMsgConfigManager_getConfig_rsp();
                pMsg = pMsgInst;
                break;
            }
            case emRT_setConfig:
            {
                CMsgConfigManager_setConfig_rsp *pMsgInst = new CMsgConfigManager_setConfig_rsp();
                pMsg = pMsgInst;
                break;
            }
                
                ///////////÷«ƒ‹º“æ”//////////////
            case emRT_Smarthome_instance:	//ªÒ»° µ¿˝
            {
                CMsgSmarthome_instance_rsp *pMsgInst = new CMsgSmarthome_instance_rsp();
                pMsg = pMsgInst;
                break;
            }
            case emRT_Smarthome_destroy:	// Õ∑≈ µ¿˝
            {
                CMsgSmarthome_destroy_rsp *pMsgInst = new CMsgSmarthome_destroy_rsp();
                pMsg = pMsgInst;
                break;
            }
            case emRT_Smarthome_getDeviceList:	//ªÒ»°…Ë±∏¡–±Ì
            {
                CMsgSmarthome_getDeviceList_rsp *pMsgInst = new CMsgSmarthome_getDeviceList_rsp();
                pMsg = pMsgInst;
                break;
            }
            case emRT_Smarthome_setDeviceInfo:	//…Ë÷√…Ë±∏–≈œ¢
            {
                CMsgSmarthome_setDeviceInfo_rsp *pMsgInst = new CMsgSmarthome_setDeviceInfo_rsp();
                pMsg = pMsgInst;
                break;
            }
                //µ∆π‚
            case emRT_Light_instance:	//ªÒ»° µ¿˝
            {
                CMsgLight_instance_rsp *pMsgInst = new CMsgLight_instance_rsp();
                pMsg = pMsgInst;
                break;
            }
            case emRT_Light_destroy:	// Õ∑≈ µ¿˝
            {
                CMsgLight_destroy_rsp *pMsgInst = new CMsgLight_destroy_rsp();
                pMsg = pMsgInst;
                break;
            }
            case emRT_Light_open:		//ø™µ∆
            {
                CMsgLight_open_rsp *pMsgInst = new CMsgLight_open_rsp();
                pMsg = pMsgInst;
                break;
            }
            case emRT_Light_close:		//πÿµ∆
            {
                CMsgLight_close_rsp *pMsgInst = new CMsgLight_close_rsp();
                pMsg = pMsgInst;
                break;
            }
            case emRT_Light_getState:	//ªÒ»°µ∆π‚◊¥Ã¨
            {
                CMsgLight_getState_rsp *pMsgInst = new CMsgLight_getState_rsp();
                pMsg = pMsgInst;
                break;
            }
                
                ///¥∞¡±
            case emRT_Curtain_instance:	//ªÒ»° µ¿˝
            {
                CMsgCurtain_instance_rsp *pMsgInst = new CMsgCurtain_instance_rsp();
                pMsg = pMsgInst;
                break;
            }
            case emRT_Curtain_destroy:	// Õ∑≈ µ¿˝
            {
                CMsgCurtain_destroy_rsp *pMsgInst = new CMsgCurtain_destroy_rsp();
                pMsg = pMsgInst;
                break;
            }
            case emRT_Curtain_getState:	//ªÒ»°¥∞¡±◊¥Ã¨
            {
                CMsgCurtain_getState_rsp *pMsgInst = new CMsgCurtain_getState_rsp();
                pMsg = pMsgInst;
                break;
            }
                ///////////÷«ƒ‹º“æ”//////////////
                
                ///////////…Ë±∏≈‰÷√//////////////
            case emRT_MagicBox_instance:	//ªÒ»° µ¿˝
            {
                CMsgMagicBox_instance_rsp *pMsgInst = new CMsgMagicBox_instance_rsp();
                pMsg = pMsgInst;
                break;
            }
            case emRT_MagicBox_destroy:	// Õ∑≈ µ¿˝
            {
                CMsgMagicBox_destroy_rsp *pMsgInst = new CMsgMagicBox_destroy_rsp();
                pMsg = pMsgInst;
                break;
            }
            case emRT_MagicBox_getDevConfig:	//ªÒ»°…Ë±∏≈‰÷√
            {
                CMsgMagicBox_getDevConfig_rsp *pMsgInst = new CMsgMagicBox_getDevConfig_rsp();
                pMsg = pMsgInst;
                break;
            }
            default:
                break;
        }
        return pMsg;
    }
    
    void CDvrClient::OnConnect() //¡¨Ω”≥…π¶Õ®÷™
    {
        INFO_TRACE("connect ok");
        m_emStatus = emConnected;
        m_iRecvIndex = 0;
    }
    void CDvrClient::OnDataRecv() //Ω” ’ ˝æ›Õ®÷™
    {
        //Ω” ’ ˝æ›
        int iDataLen;
        iDataLen = recv(m_sSock,&m_szRecvBuf[m_iRecvIndex],MAX_BUF_LEN-m_iRecvIndex,0);
        if ( iDataLen < 0 )
        {
            ERROR_TRACE("recv failed.err="<<WSAGetLastError());
            //OnDisconnect(2);
            OnDisConnected(emDisRe_Unknown);
        }
        else if ( 0 == iDataLen ) //disconnect
        {
            OnDisConnected(emDisRe_Disconnected);
        }
        else
        {
            m_iRecvIndex += iDataLen;
            Process_Data();
        }
        
        return ;
    }
    int CDvrClient::Process_Data() //¥¶¿Ì ˝æ›
    {
        int iCurIndex = 0;
        dvip_hdr hdr;
        bool bHavePacket = true;
        
        if ( m_iRecvIndex <= DVIP_HDR_LENGTH )
        {
            return 0;
        }
        do
        {
            if ( m_iRecvIndex-iCurIndex >= DVIP_HDR_LENGTH )
            {
                memcpy(&hdr,&m_szRecvBuf[iCurIndex],DVIP_HDR_LENGTH);
                if ( hdr.packet_length+DVIP_HDR_LENGTH <= m_iRecvIndex-iCurIndex )
                {
                    //¥¶¿Ì ˝æ›
                    OnDataPacket(&m_szRecvBuf[iCurIndex],(int)(hdr.packet_length+DVIP_HDR_LENGTH));
                    iCurIndex += (hdr.packet_length+DVIP_HDR_LENGTH);
                }
                else //≤ªπª“ª∞¸ ˝æ›
                {
                    bHavePacket = false;
                }
            }
            else
            {
                bHavePacket = false;
            }
        } while ( bHavePacket );
        
        if ( iCurIndex != 0 )
        {
            if ( m_iRecvIndex == iCurIndex ) // ˝æ›»´≤ø¥¶¿ÌÕÍ
            {
                m_iRecvIndex = 0;
            }
            else
            {
                memmove(m_szRecvBuf,&m_szRecvBuf[iCurIndex],m_iRecvIndex-iCurIndex);
                m_iRecvIndex -= iCurIndex;
            }
        }
        ////≤∞¸
        //if ( m_iRecvIndex <= DVIP_HDR_LENGTH )
        //{
        //	return 0;
        //	//
        //	dvip_hdr hdr;
        //	memcpy(&hdr,m_szRecvBuf,DVIP_HDR_LENGTH);
        //	if ( hdr.packet_length+DVIP_HDR_LENGTH >= m_iRecvIndex )
        //	{
        //		//◊„πª“ª∞¸ ˝æ›,∑≈»Î ˝æ›ª∫≥Â
        //
        //	}
        //}
        return 0;
    }
    int CDvrClient::SendData(char *pData,int iDataLen) //∑¢ÀÕ ˝æ›
    {
        int iSendLen;
        iSendLen = send(m_sSock,pData,iDataLen,0);
        if ( iSendLen == iDataLen ) //»´≤ø∑¢ÀÕÕÍ≥…
        {
            return iSendLen;
        }
        else if ( iSendLen == FCL_SOCKET_ERROR ) //∑¢ÀÕ ß∞‹
        {
            ERROR_TRACE("send failed.err="<<WSAGetLastError()<<" send len="<<iSendLen);
            return iSendLen;
        }
        else //≤ø∑÷∑¢ÀÕÕÍ≥…, £”‡Œ¥∑¢ÀÕ≤ø∑÷¥¶¿Ì:‘› ±√ª”–¥¶¿Ì
        {
            return iSendLen;
        }
    }
    void CDvrClient::OnDataPacket(const char *pData,int iDataLen)
    {
        int iMsgIndex = 0;
        dvip_hdr hdr;
        Json::Reader jsonParser;
        Json::Value jsonContent;
        bool bRet = true;
        int iRet = 0;
        
        memcpy(&hdr,pData,DVIP_HDR_LENGTH);
        if ( hdr.size != DVIP_HDR_LENGTH ) //Õ∑≤ø≥§∂»
        {
            if ( hdr.size < DVIP_HDR_LENGTH )
            {
                ERROR_TRACE("invalid msg hdr,too short.");
                return ;
            }
            else
            {
                ERROR_TRACE("msg hdr have extend data,not support now.");
                return ;
            }
        }
        else
        {
            iMsgIndex += DVIP_HDR_LENGTH;
        }
        
        if ( hdr.message_length == 0 )
        {
            ERROR_TRACE("invalid msg no msg body.");
            return ;
        }
        
        if (hdr.data_length>0 && hdr.packet_index == 0)// ’µΩ∑÷∞¸ ˝æ›µƒµ⁄“ª∞¸
        {
            m_idle = IDLE_PACKAGE;
        }
        
        if (m_idle == IDLE_NORMAL)//’˝≥£ƒ£ Ω
        {
            if (hdr.data_length>0)//«Î«Û¥¯¿©’π ˝æ›
            {
                ERROR_TRACE("not ready for package.");
                return;
            }
            
            TransInfo *pTrans;
            //idŒ™0ªÚattechµƒid ±±Ì æµ±«∞∞¸Œ™Õ®÷™∞¸
            if ( 0 == hdr.request_id || (m_bHasSubscrible&&m_uiSubscribeReqId == hdr.request_id))
            {
                //«Î«ÛIDŒ™ø’,notificationœ˚œ¢
                OnNotification(hdr,pData+DVIP_HDR_LENGTH,iDataLen-DVIP_HDR_LENGTH);
                return ;
            }
            else{
                pTrans = FetchRequest(hdr.request_id);
                
                if ( !pTrans )
                {
                    ERROR_TRACE("not find request.reqid="<<hdr.request_id);
                    
                    //’“≤ªµΩ«Î«ÛIDŒ™,notificationœ˚œ¢
                    //OnNotification(hdr,pData+DVIP_HDR_LENGTH,iDataLen-DVIP_HDR_LENGTH);
                    return ;
                }
            }
            
            if ( emRT_Login != pTrans->type )
            {
                if ( m_uiSessionId != hdr.session_id )
                {
                    ERROR_TRACE("session id invalid.cur="<<hdr.session_id<<"my="<<m_uiSessionId);
                    return ;
                }
            }
            CDvipMsg *pMsg = NULL;
            
            switch ( pTrans->type )
            {
                case emRT_Login: //µ«¬º
                    return OnLoginResponse(hdr,pTrans,pData+DVIP_HDR_LENGTH,iDataLen-DVIP_HDR_LENGTH);
                    break;
                case emRT_Keepalive: //±£ªÓ
                    return OnKeepaliveResponse(hdr,pTrans,pData+DVIP_HDR_LENGTH,iDataLen-DVIP_HDR_LENGTH);
                    break;
                case emRT_Logout: //µ«≥ˆ
                    return OnLogoutResponse(hdr,pTrans,pData+DVIP_HDR_LENGTH,iDataLen-DVIP_HDR_LENGTH);
                    break;
                default:
                    pMsg = CreateMsg(pTrans->type);
                    break;
            }
            
            if ( !pMsg )
            {
                ERROR_TRACE("Create msg failed")
                pTrans->result = TransInfo::emTaskStatus_Failed;
                pTrans->hEvent.Signal();
                return ;
            }
            iRet = pMsg->Decode((char*)pData,(unsigned int)iDataLen);
            if ( 0 != iRet )
            {
                ERROR_TRACE("decode msg failed");
                delete pMsg;
                pTrans->result = TransInfo::emTaskStatus_Failed;
                pTrans->hEvent.Signal();
                return ;
            }
            pTrans->result = TransInfo::emTaskStatus_Success;
            pTrans->pRspMsg = pMsg;
            pTrans->hEvent.Signal();
        }
        else if (m_idle == IDLE_PACKAGE)
        {
            iRet = OnPackage(hdr,pData+DVIP_HDR_LENGTH,iDataLen-DVIP_HDR_LENGTH);
            if (iRet<0)//◊È∞¸ ß∞‹ªÚΩ· ¯£¨∑µªÿ’˝≥£ƒ£ Ω
            {
                m_idle = IDLE_NORMAL;
            }
        }
        
        return ;
    }
#if 0
    void CDvrClient::OnDataPacket(const char *pData,int pDataLen)
    {
        int iMsgIndex = 0;
        dvip_hdr hdr;
        Json::Reader jsonParser;
        Json::Value jsonContent;
        bool bRet;
        
        memcpy(&hdr,pData,DVIP_HDR_LENGTH);
        if ( hdr.size != DVIP_HDR_LENGTH ) //Õ∑≤ø≥§∂»
        {
            if ( hdr.size < DVIP_HDR_LENGTH )
            {
                ERROR_TRACE("invalid msg hdr,too short.");
                return ;
            }
            else
            {
                ERROR_TRACE("msg hdr have extend data,not support now.");
                return ;
            }
        }
        else
        {
            iMsgIndex += DVIP_HDR_LENGTH;
        }
        
        if ( hdr.message_length == 0 )
        {
            ERROR_TRACE("invalid msg no msg body.");
            return ;
        }
        
        
        bRet = jsonParser.parse(pData+DVIP_HDR_LENGTH,pData+DVIP_HDR_LENGTH+hdr.message_length,jsonContent);
        if ( !bRet )
        {
            ERROR_TRACE("parse msg body failed");
            return ;
        }
        
        std::string strMethod;
        std::string strResult;
        bool bIsResult = true;
        
        //
        if ( !jsonContent["result"].isNull() ) //µ˜”√ªÿ”¶
        {
            bIsResult = true;
        }
        else if ( !jsonContent["method"].isNull() ) //µ˜”√«Î«ÛªÚÕ®÷™œ˚œ¢
        {
            bIsResult = false;
            //ERROR_TRACE("no method field");
            //return ;
        }
        else
        {
            ERROR_TRACE("invalid msg,no result and no memthod");
            return ;
        }
        if ( bIsResult )
        {
            bool bResult = false;
            int iResult = 0;
            unsigned int uiReqId;
            unsigned int uiSessionId;
            bool bIsResultOk = false;
            
            if ( jsonContent["result"].isBool() )
            {
                bResult = jsonContent["result"].asBool();
                if ( bResult )
                {
                    bIsResultOk = true;
                }
                else
                {
                    bIsResultOk = false;
                }
            }
            else if ( jsonContent["result"].asInt() )
            {
                iResult = jsonContent["result"].asInt();
                if ( 0 == iResult )
                {
                    bIsResultOk = true;
                }
                else
                {
                    bIsResultOk = false;
                }
            }
            else
            {
                ERROR_TRACE("invalid result type not bool or int");
                return ;
            }
            
            uiReqId = jsonContent["id"].asUInt();
            uiSessionId = jsonContent["session"].asUInt();
            
            
            
            if ( emRegistering == m_emStatus ) //’˝‘⁄◊¢≤·
            {
                if ( bIsResultOk == false ) //µ«¬º ß∞‹
                {
                    if ( !jsonContent["error"].isNull()
                        && !jsonContent["error"]["code"].isNull()
                        && jsonContent["error"]["code"].isInt() )
                    {
                        int iErrorCode = jsonContent["error"]["code"].asInt();
                        if ( 0x1003000f == iErrorCode ) //”√ªß÷ —Ø
                        {
                            //÷ÿ–¬∑¢∆µ«¬º,–Ø¥¯—È÷§–≈œ¢
                            INFO_TRACE("login resonse,need auth");
                            std::string strMac;
                            std::string strRealm;
                            std::string strEncryption;
                            std::string strAuthorization;
                            std::string strRandom;
                            
                            strRealm		=	jsonContent["params"]["realm"].asString();
                            strMac			=	jsonContent["params"]["mac"].asString();
                            strEncryption	=	jsonContent["params"]["encryption"].asString();
                            strAuthorization=	jsonContent["params"]["authorization"].asString();
                            strRandom		=	jsonContent["params"]["random"].asString();
                            
                            //º∆À„µ«¬ºƒ⁄»›
                            std::string strMd5String;
                            std::string strMd5Password;
                            strMd5String = m_strUsername;
                            strMd5String += ":";
                            //strMd5String += " ";
                            strMd5String += strRealm;
                            strMd5String += ":";
                            //strMd5String += " ";
                            strMd5String += m_strPassword;
                            struct MD5Context md5c;
                            unsigned char ucResult[16];
                            char szTemp[16];
                            MD5Init(&md5c);
                            MD5Update(&md5c,(unsigned char*)strMd5String.c_str(),strMd5String.size());
                            MD5Final(ucResult,&md5c);
                            //out[0] = '\0';
                            for(int i=0; i<16; i++ )
                            {
                                sprintf(szTemp,"%02X",ucResult[i]);
                                strMd5Password += szTemp;
                                //strcat(out,tmp);
                            }
                            //‘Ÿ¥Œ∑¢ÀÕ◊¢≤·«Î(¥¯»®º¯–≈œ¢)
                            LoginRequest(uiSessionId,strMd5Password.c_str(),"Default",strRandom.c_str(),strRealm.c_str());
                        }
                        else //µ«¬º ß∞‹
                        {
                            ERROR_TRACE("login failed.err="<<iErrorCode);
                            OnRegisterFailed(iErrorCode);
                            return ;
                        }
                    }
                }
                else //µ«¬º≥…π¶
                {
                    INFO_TRACE("login OK");
                    OnRegisterSuccess((int)uiSessionId);
                }
            }
        }
        else //«Î«ÛªÚÕ®÷™,‘›≤ª¥¶¿Ì
        {
            strMethod = jsonContent["method"].asString();
        }
        
    }
#endif
    void CDvrClient::OnDataSend() //ø…“‘∑¢ÀÕ ˝æ›Õ®÷™
    {
    }
    
    // ’µΩ◊¢≤·ªÿ”¶
    void CDvrClient::OnLoginResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen)
    {
        int iMsgIndex = 0;
        //dvip_hdr hdr;
        Json::Reader jsonParser;
        Json::Value jsonContent;
        bool bRet;
        
        if ( hdr.message_length == 0 )
        {
            ERROR_TRACE("invalid msg no msg body.");
            return ;
        }
        
        
        bRet = jsonParser.parse(pData,pData+hdr.message_length,jsonContent);
        if ( !bRet )
        {
            ERROR_TRACE("parse msg body failed");
            return ;
        }
        
        
        //
        if ( jsonContent["result"].isNull()
            || !jsonContent["result"].isBool() ) //Ω·π˚
        {
            ERROR_TRACE("no result or result type is not bool.");
            return ;
        }
        
        bool bIsResultOk = jsonContent["result"].asBool();
        
        unsigned int uiReqId = jsonContent["id"].asUInt();
        unsigned int uiSessionId = jsonContent["session"].asUInt();
        if ( uiReqId != hdr.request_id/* || uiSessionId != hdr.session_id*/ )
        {
            ERROR_TRACE("reqid or sessid not same with hdr");
            return ;
        }
        
        if ( emRegistering != m_emStatus ) //≤ª «’˝‘⁄◊¢≤·
        {
            ERROR_TRACE("status ivalid,not in logining.status="<<(int)m_emStatus);
            return ;
        }
        if ( bIsResultOk ) //µ«¬º≥…π¶
        {
            
            INFO_TRACE("login OK");
            OnRegisterSuccess((int)uiSessionId);
            return ;
        }
        
        if ( !jsonContent["error"].isNull()
            && !jsonContent["error"]["code"].isNull()
            && jsonContent["error"]["code"].isInt() )
        {
            int iErrorCode = jsonContent["error"]["code"].asInt();
            if ( 0x1003000f == iErrorCode || 401 == iErrorCode) //”√ªß÷ —Ø
            {
                //÷ÿ–¬∑¢∆µ«¬º,–Ø¥¯—È÷§–≈œ¢
                INFO_TRACE("login resonse,need auth");
                
                std::string strMac;
                std::string strRealm;
                std::string strEncryption;
                std::string strAuthorization;
                std::string strRandom;
                
                strRealm		=	jsonContent["params"]["realm"].asString();
                strMac			=	jsonContent["params"]["mac"].asString();
                strEncryption	=	jsonContent["params"]["encryption"].asString();
                strAuthorization=	jsonContent["params"]["authorization"].asString();
                strRandom		=	jsonContent["params"]["random"].asString();
                
                //º∆À„µ«¬ºƒ⁄»›
                std::string strMd5String;
                std::string strMd5Password;
                strMd5String = m_strUsername;
                strMd5String += ":";
                //strMd5String += " ";
                strMd5String += strRealm;
                strMd5String += ":";
                //strMd5String += " ";
                strMd5String += m_strPassword;
                struct MD5Context md5c;
                unsigned char ucResult[16];
                char szTemp[16];
                MD5Init(&md5c);
                MD5Update(&md5c,(unsigned char*)strMd5String.c_str(),strMd5String.size());
                MD5Final(ucResult,&md5c);
                for(int i=0; i<16; i++ )
                {
                    sprintf(szTemp,"%02X",ucResult[i]);
                    strMd5Password += szTemp;
                }
                //º∆À„º¯»®
                strMd5String = m_strUsername;
                strMd5String += ":";
                strMd5String += strRandom;
                strMd5String += ":";
                strMd5String += strMd5Password;
                MD5Init(&md5c);
                MD5Update(&md5c,(unsigned char*)strMd5String.c_str(),strMd5String.size());
                MD5Final(ucResult,&md5c);
                strMd5Password = "";
                for(int i=0; i<16; i++ )
                {
                    sprintf(szTemp,"%02X",ucResult[i]);
                    strMd5Password += szTemp;
                }
                
                //‘Ÿ¥Œ∑¢ÀÕ◊¢≤·«Î(¥¯»®º¯–≈œ¢)
                bRet = LoginRequest(uiSessionId,strMd5Password.c_str(),"Default",strRandom.c_str(),strRealm.c_str());
                if ( !bRet )
                {
                    ERROR_TRACE("LoginRequest() failed.");
                }
            }
            else //µ«¬º ß∞‹
            {
                switch (iErrorCode)
                {
                    case 0x10030006:
                        iErrorCode = emDisRe_UserNotValid;
                        break;
                    case 0x10030007:
                        iErrorCode = emDisRe_PasswordNotValid;
                        break;
                }
                
                //ERROR_TRACE("login failed.err="<<iErrorCode);
                OnRegisterFailed(iErrorCode);
                return ;
            }
        }
        
    }
    // ’µΩ±£ªÓªÿ”¶
    void CDvrClient::OnKeepaliveResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen)
    {
        Json::Reader jsonParser;
        Json::Value jsonContent;
        bool bRet;
        
        if ( hdr.message_length == 0 )
        {
            ERROR_TRACE("invalid msg no msg body.");
            return ;
        }
        
        
        bRet = jsonParser.parse(pData,pData+hdr.message_length,jsonContent);
        if ( !bRet )
        {
            ERROR_TRACE("parse msg body failed");
            return ;
        }
        
        
        //
        if ( jsonContent["result"].isNull()
            || !jsonContent["result"].isBool() ) //Ω·π˚
        {
            ERROR_TRACE("no result or result type is not bool.");
            return ;
        }
        
        bool bIsResultOk = jsonContent["result"].asBool();
        
        unsigned int uiReqId = jsonContent["id"].asUInt();
        unsigned int uiSessionId = jsonContent["session"].asUInt();
        if ( uiReqId != hdr.request_id || uiSessionId != hdr.session_id )
        {
            ERROR_TRACE("reqid or sessid not same with hdr");
            return ;
        }
        
        if ( emRegistered != m_emStatus ) //ªπ√ª”–◊¢≤·≥…π¶
        {
            ERROR_TRACE("status ivalid,not in logining.status="<<(int)m_emStatus);
            return ;
        }
        if ( bIsResultOk ) //±£ªÓ≥…π¶
        {
            //INFO_TRACE("[keepalive] recv rsp");
            m_iFailedTimes = 0;
            m_llLastTime= GetCurrentTimeMs();
            int iTimeout =  jsonContent["params"]["timeout"].asInt();
            if ( iTimeout > 0 && iTimeout < m_iTimeout )
            {
                m_iTimeout = iTimeout;
            }
        }
        
    }
    // ’µΩµ«≥ˆªÿ”¶
    void CDvrClient::OnLogoutResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen)
    {
        Json::Reader jsonParser;
        Json::Value jsonContent;
        bool bRet;
        
        if ( hdr.message_length == 0 )
        {
            ERROR_TRACE("invalid msg no msg body.");
            return ;
        }
        
        
        bRet = jsonParser.parse(pData,pData+hdr.message_length,jsonContent);
        if ( !bRet )
        {
            ERROR_TRACE("parse msg body failed");
            return ;
        }
        
        
        //
        if ( jsonContent["result"].isNull()
            || !jsonContent["result"].isBool() ) //Ω·π˚
        {
            ERROR_TRACE("no result or result type is not bool.");
            return ;
        }
        
        bool bIsResultOk = jsonContent["result"].asBool();
        
        unsigned int uiReqId = jsonContent["id"].asUInt();
        unsigned int uiSessionId = jsonContent["session"].asUInt();
        if ( uiReqId != hdr.request_id || uiSessionId != hdr.session_id )
        {
            ERROR_TRACE("reqid or sessid not same with hdr");
            return ;
        }
        
        if ( emRegistered != m_emStatus ) //ªπ√ª”–◊¢≤·≥…π¶
        {
            ERROR_TRACE("status ivalid,not in logining.status="<<(int)m_emStatus);
            return ;
        }
        if ( bIsResultOk ) //µ«≥ˆ≥…π¶
        {
            INFO_TRACE("logout OK.");
        }
    }
    // ’µΩªÒ»°÷«ƒ‹º“æ”π‹¿Ì µ¿˝ªÿ”¶
    void CDvrClient::OnSmarthome_instance_rsp(TransInfo *pTrans,const char *pData,int iDataLen)
    {
        int iRet = 0;
        CMsgSmarthome_instance_rsp *pRspMsg = new CMsgSmarthome_instance_rsp();
        if ( !pRspMsg )
        {
            ERROR_TRACE("out of memory");
            if ( pTrans )
            {
                pTrans->result = TransInfo::emTaskStatus_Failed;
                pTrans->hEvent.Signal();
                return ;
            }
        }
        iRet = pRspMsg->Decode((char*)pData,(unsigned int)iDataLen);
        if ( 0 != iRet )
        {
            ERROR_TRACE("parse rsp msg failed");
            if ( pTrans )
            {
                pTrans->result = TransInfo::emTaskStatus_Failed;
                pTrans->hEvent.Signal();
                return ;
            }
        }
        pTrans->result = TransInfo::emTaskStatus_Success;
        pTrans->pRspMsg = pRspMsg;
        pTrans->hEvent.Signal();
        return ;
    }
    // ’µΩ Õ∑≈÷«ƒ‹º“æ”π‹¿Ì µ¿˝ªÿ”¶
    void CDvrClient::OnSmarthome_destroy_rsp(TransInfo *pTrans,const char *pData,int iDataLen)
    {
        int iRet = 0;
        CMsgSmarthome_destroy_rsp *pRspMsg = new CMsgSmarthome_destroy_rsp();
        if ( !pRspMsg )
        {
            ERROR_TRACE("out of memory");
            if ( pTrans )
            {
                pTrans->result = TransInfo::emTaskStatus_Failed;
                pTrans->hEvent.Signal();
                return ;
            }
        }
        iRet = pRspMsg->Decode((char*)pData,(unsigned int)iDataLen);
        if ( 0 != iRet )
        {
            ERROR_TRACE("parse rsp msg failed");
            if ( pTrans )
            {
                pTrans->result = TransInfo::emTaskStatus_Failed;
                pTrans->hEvent.Signal();
                return ;
            }
        }
        pTrans->result = TransInfo::emTaskStatus_Success;
        pTrans->pRspMsg = pRspMsg;
        pTrans->hEvent.Signal();
        return ;
    }
    // ’µΩªÒ»°…Ë±∏¡–±Ìªÿ”¶
    void CDvrClient::OnSmarthome_getDeviceList_rsp(TransInfo *pTrans,const char *pData,int iDataLen)
    {
        int iRet = 0;
        CMsgSmarthome_getDeviceList_rsp *pRspMsg = new CMsgSmarthome_getDeviceList_rsp();
        if ( !pRspMsg )
        {
            ERROR_TRACE("out of memory");
            if ( pTrans )
            {
                pTrans->result = TransInfo::emTaskStatus_Failed;
                pTrans->hEvent.Signal();
                return ;
            }
        }
        iRet = pRspMsg->Decode((char*)pData,(unsigned int)iDataLen);
        if ( 0 != iRet )
        {
            ERROR_TRACE("parse rsp msg failed");
            if ( pTrans )
            {
                pTrans->result = TransInfo::emTaskStatus_Failed;
                pTrans->hEvent.Signal();
                return ;
            }
        }
        pTrans->result = TransInfo::emTaskStatus_Success;
        pTrans->pRspMsg = pRspMsg;
        pTrans->hEvent.Signal();
        return ;
    }
    
    void CDvrClient::OnDisConnected(int iReason)
    {
        EmStatus m_emPreStatus = m_emStatus;
        
        FCL_CLOSE_SOCKET(m_sSock);
        m_emStatus = emIdle;
        m_uiEventObjectId = 0;
        m_uiSid = 0;
        m_bHasSubscrible = false;
        Clear_Tasks();
        
        if ( emDisRe_UnRegistered == iReason ) //µ«≥ˆ
        {
            INFO_TRACE("logout OK.");
        }
        else
        {
            INFO_TRACE("disconnect.reason="<<iReason);
            if ( m_emPreStatus == emRegistered ) //“—æ≠µ«¬º≥…π¶∫Û∂œø™
            {
                if ( m_cbOnDisConnect )
                {
                    m_cbOnDisConnect(m_uiLoginId,(char*)m_strServIp.c_str(),(unsigned short)m_iServPort,m_pUser);
                }
                if ( m_cbOnDisConnectEx )
                {
                    //disconnect
                    m_cbOnDisConnectEx(m_uiLoginId,(char*)m_strServIp.c_str(),(unsigned short)m_iServPort,0,iReason,m_pUserEx);
                }
                m_bIsFirstConnect = false;
            }
            else if ( m_bIsFirstConnect ) //µ⁄“ª¥Œµ«¬º ±
            {
                if ( m_cbOnDisConnectEx )
                {
                    //µ«¬º ß∞‹
                    m_cbOnDisConnectEx(m_uiLoginId,(char*)m_strServIp.c_str(),(unsigned short)m_iServPort,2,iReason,m_pUserEx);
                }
            }
            else //∑«µ⁄“ª¥Œ
            {
                m_bIsFirstConnect = false;
            }
        }
        //if ( m_pSinker )
        //{
        //	m_pSinker->OnStatusChange(this,IConnUserSinker::emConnctionDisconnected,iReason);
        //}
    }
    //◊¢≤·≥…π¶Õ®÷™
    void CDvrClient::OnRegisterSuccess(int iReason)
    {
        m_emStatus = emRegistered;
        m_uiSessionId = (unsigned int)iReason;
        m_iFailedTimes = 0;
        m_llLastTime = GetCurrentTimeMs();
        INFO_TRACE("register OK.");
        if ( m_bAutoReConnect ) //“Ï≤Ωƒ£ Ω
        {
            if ( m_cbOnDisConnectEx )
            {
                //µ«¬º≥…π¶
                m_cbOnDisConnectEx(m_uiLoginId,(char*)m_strServIp.c_str(),(unsigned short)m_iServPort,1,0,m_pUserEx);
            }
            m_bIsFirstConnect = false;
        }
    }
    void CDvrClient::OnRegisterFailed(int iReason)
    {
        FCL_CLOSE_SOCKET(m_sSock);
        m_emStatus = emIdle;
        m_error = iReason;
        INFO_TRACE("login failed.reason="<<iReason);
        //m_bIsFirstConnect = false;
        
        if ( m_bAutoReConnect ) //“Ï≤Ωƒ£ Ω
        {
            if ( m_bIsFirstConnect )
            {
                //if ( m_pSinker )
                //{
                //	m_pSinker->OnStatusChange(this,IConnUserSinker::emRegisterFailed,iReason);
                //}
                if ( m_cbOnDisConnectEx )
                {
                    //µ«¬º ß∞‹
                    m_cbOnDisConnectEx(m_uiLoginId,(char*)m_strServIp.c_str(),(unsigned short)m_iServPort,2,iReason,m_pUserEx);
                }
                m_bIsFirstConnect = false;
            }
        }
    }
    
    //ªÒ»°÷«ƒ‹º“æ” µ¿˝
    bool CDvrClient::Smarthome_instance_Req()
    {
        dvip_hdr hdr;
        Json::Value jsonContent;
        unsigned int uiReqId;
        unsigned int uiContentLength = 0;
        std::string strContent;
        char szBuf[1024];
        int iPacketLength;
        int iSendLength;
        
        uiReqId = CreateReqId();
        hdr.size = DVIP_HDR_LENGTH;		//hdr≥§∂»
        //MAGIC
        hdr.magic[0] = 'D';
        hdr.magic[1] = 'H';
        hdr.magic[2] = 'I';
        hdr.magic[3] = 'P';
        hdr.session_id = m_uiSessionId;
        hdr.request_id = uiReqId;
        hdr.packet_length = 0;
        hdr.packet_index = 0;
        hdr.message_length = 0;
        hdr.data_length = 0;
        
        jsonContent["id"] = uiReqId; //«Î«Ûid requstId
        jsonContent["session"] = m_uiSessionId; //sessionId
        jsonContent["method"] = "SmartHomeManager.factory.instance"; //∑Ω∑® ªÒ»°÷«ƒ‹º“æ”π‹¿Ì µ¿˝ID
        ////≤Œ ˝¡–±Ì Œﬁ≤Œ ˝
        
        strContent = jsonContent.toStyledString();
        uiContentLength = strContent.size();
        hdr.packet_length = uiContentLength;
        hdr.message_length = uiContentLength;
        
        memcpy(szBuf,&hdr,DVIP_HDR_LENGTH);
        memcpy(&szBuf[DVIP_HDR_LENGTH],strContent.c_str(),uiContentLength);
        
        //∑¢ÀÕ ˝æ›
        iPacketLength = uiContentLength+DVIP_HDR_LENGTH;
        iSendLength = send(m_sSock,szBuf,iPacketLength,0);
        if ( iSendLength  == iPacketLength )
        {
            //∑¢ÀÕ≥…π¶
            //return true;
        }
        else if ( iSendLength == FCL_SOCKET_ERROR )
        {
            ERROR_TRACE("send logout request failed.err="<<WSAGetLastError());
            return false;
        }
        else// if ( iSendLength < iPacketLength )
        {
            INFO_TRACE("send parital data.total="<<iPacketLength<<" sended="<<iSendLength);
            //ÃÌº”µΩ∑¢ÀÕª∫≥Â¡–±Ì÷–
            //return true;
        }
        TransInfo *pTrans = new TransInfo;
        if ( !pTrans )
        {
            ERROR_TRACE("out of memory");
            return false;
        }
        pTrans->type = emRT_Smarthome_instance;
        pTrans->seq = uiReqId;
        AddRequest(uiReqId,pTrans);
        return true;
    }
    // ’µΩªÿ”¶
    void CDvrClient::OnSmarthome_instance_Rsp(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen)
    {
        Json::Reader jsonParser;
        Json::Value jsonContent;
        bool bRet;
        
        if ( hdr.message_length == 0 )
        {
            ERROR_TRACE("invalid msg no msg body.");
            return ;
        }
        
        
        bRet = jsonParser.parse(pData,pData+hdr.message_length,jsonContent);
        if ( !bRet )
        {
            ERROR_TRACE("parse msg body failed");
            return ;
        }
        
        if ( emRegistered != m_emStatus ) //ªπ√ª”–◊¢≤·≥…π¶
        {
            ERROR_TRACE("status ivalid,not in logining.status="<<(int)m_emStatus);
            return ;
        }
        
        unsigned int uiReqId = jsonContent["id"].asUInt();
        unsigned int uiSessionId = jsonContent["session"].asUInt();
        if ( uiReqId != hdr.request_id || uiSessionId != hdr.session_id )
        {
            ERROR_TRACE("reqid or sessid not same with hdr");
            return ;
        }
        
        //
        if ( jsonContent["result"].isNull()
            || !jsonContent["result"].isInt() ) //Ω·π˚
        {
            ERROR_TRACE("no result or result type is not int.");
            return ;
        }
        
        unsigned int uiObjectId = (unsigned int)jsonContent["result"].asInt();
        if ( 0 == uiObjectId ) // ß∞‹
        {
        }
        else //≥…π¶
        {
        }
    }
    // Õ∑≈÷«ƒ‹º“æ” µ¿˝
    bool CDvrClient::Smarthome_destory_Req(unsigned int uiObject)
    {
        return false;
    }
    // ’µΩªÿ”¶
    void CDvrClient::OnSmarthome_destroy_Rsp(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen)
    {
    }
    //ªÒ»°÷«ƒ‹º“æ”…Ë±∏¡–±Ì
    bool CDvrClient::Smarthome_getDeviceList_Req(unsigned int uiObject,int iType)
    {
        return false;
    }
    // ’µΩªÿ”¶
    void CDvrClient::OnSmarthome_getDeviceList_Rsp(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen)
    {
    }
    
    //¥¥Ω®∂‘œÛ µ¿˝ »´æ÷ µ¿˝
    int CDvrClient::Dvip_instance(char *pszMethod,unsigned &uiObject,int iTimeout)
    {
        int iRet = 0;
        int iDataLength = 0;
        int iSendLength = 0;
        unsigned uiReq;
        char szBuf[1024];
        TransInfo *pTask = NULL;
        //unsigned int uiObjectId = 0;
        //int iReturnCode = 0;
        CDvipMsg *pReqMsg = NULL;
        EmRequestType emReqType;
        
        uiReq = CreateReqId();
        if ( 0 == strcmp(pszMethod,"SmartHomeManager.factory.instance") )
        {
            CMsgSmarthome_instance_req *pSmarthome = new CMsgSmarthome_instance_req(uiReq,m_uiSessionId);
            pReqMsg = pSmarthome;
            emReqType = emRT_Smarthome_instance;
        }
        else if	( 0 == strcmp(pszMethod,"magicBox.factory.instance") )
        {
            CMsgMagicBox_instance_req *pMagicBox = new CMsgMagicBox_instance_req(uiReq,m_uiSessionId);
            pReqMsg = pMagicBox;
            emReqType = emRT_MagicBox_instance;
        }
        else
        {
            CMsgDvip_instance_req *pInstanceReq = new CMsgDvip_instance_req(uiReq,m_uiSessionId,pszMethod);
            pReqMsg = pInstanceReq;
            emReqType = emRT_instance;
        }
        if ( !pReqMsg )
        {
            ERROR_TRACE("create req msg failed");
            return -1;
        }
        iRet = pReqMsg->Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            delete pReqMsg;
            return -1;
        }
        delete pReqMsg;
        pTask = new TransInfo(uiReq,emReqType,GetCurrentTimeMs());
        if ( !pTask )
        {
            ERROR_TRACE("out of memory");
            delete pReqMsg;
            return -1;
        }
        AddRequest(uiReq,pTask);
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("instance failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        if ( emReqType == emRT_Smarthome_instance )
        {
            CMsgSmarthome_instance_rsp *pInstRsp = (CMsgSmarthome_instance_rsp*)pTask->pRspMsg;
            uiObject = pInstRsp->m_uiObjectId;
        }
        else if ( emReqType == emRT_instance )
        {
            CMsgDvip_instance_rsp *pInstRsp = (CMsgDvip_instance_rsp*)pTask->pRspMsg;
            uiObject = pInstRsp->m_uiObjectId;
        }
        else if	( emReqType == emRT_MagicBox_instance )
        {
            CMsgMagicBox_instance_rsp *pInstRsp = (CMsgMagicBox_instance_rsp*)pTask->pRspMsg;
            uiObject = pInstRsp->m_uiObjectId;
        }
        else
        {
            ERROR_TRACE("unknown method");
            return -1;
        }
        delete pTask;
        
        return 0;
    }
    
    //¥¥Ω®∂‘œÛ µ¿˝ Õ®π˝…Ë±∏id
    int CDvrClient::Dvip_instance(char *pszMethod,char *pszDeviceId,unsigned &uiObject,int iTimeout)
    {
        Json::Value jsParams;
        
        jsParams["DeviceID"] = pszDeviceId;
        return Dvip_instance(pszMethod,jsParams,uiObject,iTimeout);
        
        
        //int iRet = 0;
        //int iDataLength = 0;
        //int iSendLength = 0;
        //unsigned uiReq;
        //char szBuf[1024];
        //TransInfo *pTask = NULL;
        //unsigned int uiObjectId = 0;
        //int iReturnCode = 0;
        //CDvipMsg *pReqMsg = NULL;
        //EmRequestType emReqType;
        
        //uiReq = CreateReqId();
        //CMsgDvip_instance_req reqMsg(uiReq,m_uiSessionId,pszMethod,pszDeviceId,true);
        //emReqType = emRT_instance;
        ////if ( 0 == strcmp(pszMethod,"Light.factory.instance") )
        ////{
        ////	CMsgLight_instance_req *pLight = new CMsgLight_instance_req(uiReq,m_uiSessionId,pszDeviceId);
        ////	pReqMsg = pLight;
        ////	emReqType = emRT_Light_instance;
        ////}
        ////else if ( 0 == strcmp(pszMethod,"Curtain.factory.instance") )
        ////{
        ////	CMsgCurtain_instance_req *pCurtain = new CMsgCurtain_instance_req(uiReq,m_uiSessionId,pszDeviceId);
        ////	pReqMsg = pCurtain;
        ////	emReqType = emRT_Curtain_instance;
        ////}
        ////else
        ////{
        ////	ERROR_TRACE("unknown method");
        ////	return -1;
        ////}
        ////if ( !pReqMsg )
        ////{
        ////	ERROR_TRACE("create req msg failed");
        ////	return -1;
        ////}
        //iRet = /*pReqMsg->*/reqMsg.Encode(szBuf,1024);
        //if ( 0 >= iRet )
        //{
        //	ERROR_TRACE("encode failed.");
        //	//delete pReqMsg;
        //	return -1;
        //}
        ////delete pReqMsg;
        //pTask = new TransInfo(uiReq,emReqType,GetCurrentTimeMs());
        //if ( !pTask )
        //{
        //	ERROR_TRACE("out of memory");
        //	return -1;
        //}
        //AddRequest(uiReq,pTask);
        ////∑¢ÀÕ ˝æ›
        //iDataLength = iRet;
        //iSendLength = SendData(szBuf,iDataLength);
        //if ( 0 > iSendLength )
        //{
        //	ERROR_TRACE("send failed");
        //	if ( pTask )
        //	{
        //		delete pTask;
        //	}
        //	return -1;
        //}
        
        //iRet = pTask->hEvent.Wait(0);
        //if ( TransInfo::emTaskStatus_Success != pTask->result )
        //{
        //	ERROR_TRACE("instance failed");
        //	if ( pTask )
        //	{
        //		delete pTask;
        //	}
        //	return -1;
        //}
        //if ( !pTask->pRspMsg )
        //{
        //	ERROR_TRACE("rsp msg failed");
        //	if ( pTask )
        //	{
        //		delete pTask;
        //	}
        //	return -1;
        //}
        
        //if ( emReqType == emRT_instance )
        //{
        //	CMsgDvip_instance_rsp *pInstRsp = (CMsgDvip_instance_rsp*)pTask->pRspMsg;
        //	uiObject = pInstRsp->m_uiObjectId;
        //}
        ////if ( emReqType == emRT_Light_instance )
        ////{
        ////	CMsgLight_instance_rsp *pInstRsp = (CMsgLight_instance_rsp*)pTask->pRspMsg;
        ////	uiObject = pInstRsp->m_uiObjectId;
        ////}
        ////else if ( emReqType == emRT_Curtain_instance )
        ////{
        ////	CMsgCurtain_instance_rsp *pInstRsp = (CMsgCurtain_instance_rsp*)pTask->pRspMsg;
        ////	uiObject = pInstRsp->m_uiObjectId;
        ////}
        //else
        //{
        //	ERROR_TRACE("unknown method");
        //	return -1;
        //}
        //delete pTask;
        
        //return 0;
    }
    
    //¥¥Ω®∂‘œÛ µ¿˝ »´æ÷ µ¿˝
    int CDvrClient::Dvip_instance(char *pszMethod,const Json::Value &jsParams,unsigned &uiObject,int iTimeout)
    {
        int iRet = 0;
        int iDataLength = 0;
        int iSendLength = 0;
        unsigned uiReq;
        char szBuf[1024];
        TransInfo *pTask = NULL;
        unsigned int uiObjectId = 0;
        int iReturnCode = 0;
        CDvipMsg *pReqMsg = NULL;
        EmRequestType emReqType;
        
        uiReq = CreateReqId();
        CMsgDvip_instance_req reqMsg(uiReq,m_uiSessionId,pszMethod,jsParams);
        emReqType = emRT_instance;
        iRet = reqMsg.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            return -1;
        }
        pTask = new TransInfo(uiReq,emReqType,GetCurrentTimeMs());
        if ( !pTask )
        {
            ERROR_TRACE("out of memory");
            return -1;
        }
        AddRequest(uiReq,pTask);
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("instance failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        if ( emReqType == emRT_instance )
        {
            CMsgDvip_instance_rsp *pInstRsp = (CMsgDvip_instance_rsp*)pTask->pRspMsg;
            uiObject = pInstRsp->m_uiObjectId;
        }
        else
        {
            ERROR_TRACE("unknown method");
            return -1;
        }
        delete pTask;
        
        return 0;
    }
    
    // Õ∑≈ µ¿˝
    int CDvrClient::Dvip_destroy(char *pszMethod,unsigned uiObject,int iTimeout)
    {
        int iRet = 0;
        int iDataLength = 0;
        int iSendLength = 0;
        unsigned uiReq;
        char szBuf[1024];
        TransInfo *pTask = NULL;
        unsigned int uiObjectId = 0;
        int iReturnCode = 0;
        CDvipMsg *pReqMsg = NULL;
        EmRequestType emReqType;
        
        uiReq = CreateReqId();
        if ( 0 == strcmp(pszMethod,"SmartHomeManager.destroy") )
        {
            CMsgSmarthome_destroy_req *pSmarthome = new CMsgSmarthome_destroy_req(uiReq,m_uiSessionId,uiObject);
            pReqMsg = pSmarthome;
            emReqType = emRT_Smarthome_destroy;
        }
        else if ( 0 == strcmp(pszMethod,"Light.destroy") )
        {
            CMsgLight_destroy_req *pLight = new CMsgLight_destroy_req(uiReq,m_uiSessionId,uiObject);
            pReqMsg = pLight;
            emReqType = emRT_Light_destroy;
        }
        else if ( 0 == strcmp(pszMethod,"Curtain.destroy") )
        {
            CMsgCurtain_destroy_req *pCurtain = new CMsgCurtain_destroy_req(uiReq,m_uiSessionId,uiObject);
            pReqMsg = pCurtain;
            emReqType = emRT_Curtain_destroy;
        }
        else
        {
            CMsgDvip_destroy_req *pDestroyMsg = new CMsgDvip_destroy_req(uiReq,m_uiSessionId,pszMethod,uiObject);
            pReqMsg = pDestroyMsg;
            emReqType = emRT_destroy;
            //ERROR_TRACE("unknown method");
            //return -1;
        }
        if ( !pReqMsg )
        {
            ERROR_TRACE("create req msg failed");
            return -1;
        }
        iRet = pReqMsg->Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            delete pReqMsg;
            return -1;
        }
        delete pReqMsg;
        pTask = new TransInfo(uiReq,emReqType,GetCurrentTimeMs());
        if ( !pTask )
        {
            ERROR_TRACE("out of memory");
            return -1;
        }
        AddRequest(uiReq,pTask);
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("exec failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        if ( emReqType == emRT_Smarthome_destroy )
        {
            CMsgSmarthome_destroy_rsp *pInstRsp = (CMsgSmarthome_destroy_rsp*)pTask->pRspMsg;
        }
        else if ( emReqType == emRT_Light_destroy )
        {
            CMsgLight_destroy_rsp *pInstRsp = (CMsgLight_destroy_rsp*)pTask->pRspMsg;
        }
        else if ( emReqType == emRT_Curtain_destroy )
        {
            CMsgCurtain_destroy_rsp *pInstRsp = (CMsgCurtain_destroy_rsp*)pTask->pRspMsg;
        }
        else
        {
            CMsgDvip_destroy_rsp *pInstRsp = (CMsgDvip_destroy_rsp*)pTask->pRspMsg;
            //ERROR_TRACE("unknown method");
            //return -1;
        }
        delete pTask;
        
        return 0;
    }
    //µ˜”√∑Ω∑®  ‰»Î ‰≥ˆ≤Œ ˝Œ™ø’,∑Ω∑®∑µªÿ÷µŒ™bool “ª∞„∫Ø ˝‘≠–Õ bool call(void)
    int CDvrClient::Dvip_method_v_b_v(char *pszMethod,unsigned uiObject,bool &bResult,int iTimeout)
    {
        int iRet = 0;
        int iDataLength = 0;
        int iSendLength = 0;
        unsigned uiReq;
        char szBuf[1024];
        TransInfo *pTask = NULL;
        //unsigned int uiObjectId = 0;
        //int iReturnCode = 0;
        //CDvipMsg *pReqMsg = NULL;
        //EmRequestType emReqType;
        
        uiReq = CreateReqId();
        CMsg_method_v_b_v_req reqMsg(uiReq,m_uiSessionId,uiObject,pszMethod);
        iRet = reqMsg.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            //delete pReqMsg;
            return -1;
        }
        //delete pReqMsg;
        pTask = new TransInfo(uiReq,emRT_method_v_b_v,GetCurrentTimeMs());
        if ( !pTask )
        {
            ERROR_TRACE("out of memory");
            return -1;
        }
        AddRequest(uiReq,pTask);
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("exec failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        CMsg_method_v_b_v_rsp *pRspMsg = (CMsg_method_v_b_v_rsp*)pTask->pRspMsg;
        bResult = pRspMsg->m_bResult;
        delete pTask;
        
        return 0;
    }
    //µ˜”√∑Ω∑®  ‰»Î≤Œ ˝Œ™json(params : {}), ‰≥ˆ≤Œ ˝“≤Œ™json(params : {}),∑Ω∑®∑µªÿ÷µŒ™bool “ª∞„∫Ø ˝‘≠–Õ bool call(void)
    int CDvrClient::Dvip_method_json_b_json(char *pszMethod
                                            ,unsigned uiObject
                                            ,Json::Value &inParams
                                            ,bool &bResult
                                            ,Json::Value &outParams
                                            ,int iTimeout)
    {
        int iRet = 0;
        int iDataLength = 0;
        int iSendLength = 0;
        unsigned uiReq;
        char szBuf[1024];
        TransInfo *pTask = NULL;
        
        uiReq = CreateReqId();
        CMsg_method_json_b_json_req reqMsg(uiReq,m_uiSessionId,uiObject,pszMethod,inParams);
        iRet = reqMsg.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            return -1;
        }
        pTask = new TransInfo(uiReq,emRT_method_json_b_json,GetCurrentTimeMs(),iTimeout);
        if ( !pTask )
        {
            ERROR_TRACE("out of memory");
            return -1;
        }
        
        AddRequest(uiReq,pTask);
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("exec failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        CMsg_method_json_b_json_rsp *pRspMsg = (CMsg_method_json_b_json_rsp*)pTask->pRspMsg;
        bResult = pRspMsg->m_bResult;
        if ( bResult )
        {
            outParams = pRspMsg->m_jsParams;
        }
        delete pTask;
        
        return uiReq;
    }
    //ªÒ»°¥∞¡±◊¥Ã¨
    int CDvrClient::Dvip_Light_getState(char *pszMethod
                                        ,unsigned uiObject
                                        ,bool &bResult
                                        ,bool &bIsOnline
                                        ,bool &bIsOn
                                        ,int &iBright
                                        ,int iTimeout)
    {
        int iRet = 0;
        int iDataLength = 0;
        int iSendLength = 0;
        unsigned uiReq;
        char szBuf[1024];
        TransInfo *pTask = NULL;
        
        uiReq = CreateReqId();
        CMsgLight_getState_req reqMsg(uiReq,m_uiSessionId,uiObject);
        iRet = reqMsg.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            //delete pReqMsg;
            return -1;
        }
        //delete pReqMsg;
        pTask = new TransInfo(uiReq,emRT_Light_getState,GetCurrentTimeMs());
        if ( !pTask )
        {
            ERROR_TRACE("out of memory");
            return -1;
        }
        AddRequest(uiReq,pTask);
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("exec failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        CMsgLight_getState_rsp *pRspMsg = (CMsgLight_getState_rsp*)pTask->pRspMsg;
        bResult = pRspMsg->m_bResult;
        if ( bResult )
        {
            bIsOnline = pRspMsg->m_bIsOnline;
            bIsOn = pRspMsg->m_bIsOn;
            iBright = pRspMsg->m_iLevel;
        }
        delete pTask;
        
        return 0;
    }
    
    //ªÒ»°¥∞¡±◊¥Ã¨
    int CDvrClient::Dvip_Curtain_getState(char *pszMethod
                                          ,unsigned uiObject
                                          ,bool &bResult
                                          ,bool &bIsOnline
                                          ,bool &bIsOn
                                          ,int &iShading
                                          ,int iTimeout)
    {
        int iRet = 0;
        int iDataLength = 0;
        int iSendLength = 0;
        unsigned uiReq;
        char szBuf[1024];
        TransInfo *pTask = NULL;
        
        uiReq = CreateReqId();
        CMsgCurtain_getState_req reqMsg(uiReq,m_uiSessionId,uiObject);
        iRet = reqMsg.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            //delete pReqMsg;
            return -1;
        }
        //delete pReqMsg;
        pTask = new TransInfo(uiReq,emRT_Curtain_getState,GetCurrentTimeMs());
        if ( !pTask )
        {
            ERROR_TRACE("out of memory");
            return -1;
        }
        AddRequest(uiReq,pTask);
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("exec failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        CMsgCurtain_getState_rsp *pRspMsg = (CMsgCurtain_getState_rsp*)pTask->pRspMsg;
        bResult = pRspMsg->m_bResult;
        if ( bResult )
        {
            bIsOnline = pRspMsg->m_bIsOnline;
            bIsOn = pRspMsg->m_bIsOn;
            iShading = pRspMsg->m_iLevel;
        }
        delete pTask;
        
        return 0;
    }
    
    ////////////////////Õ‚≤øΩ”ø⁄///////////////////////
#if 0
    int CDvrClient::Login_Sync(const char *pServIp,unsigned short usServPort,const char *pUsername,const char *pPassword)
    {
        int iRet = 0;
        bool bResult = false;
        long long llStart = GetCurrentTimeMs();
        long long llEnd;
        
        if ( m_emStatus != emIdle )
        {
            ERROR_TRACE("invalid status.status="<<(int)m_emStatus);
            return -1;
        }
        m_bIsFirstConnect = true;
        
        CreateLoginId();
        
        //±æ∂À–≈œ¢
        m_strUsername = pUsername;  //”√ªß√˚
        m_strPassword = pPassword;  //√‹¬Î
        
        //∑˛ŒÒ∂À–≈œ¢
        m_strServIp = pServIp; //∑˛ŒÒ∂Àip
        m_iServPort = (int)usServPort;		 //∑˛ŒÒ∂À∂Àø⁄
        
        if ( 0 != Start() )
        {
            ERROR_TRACE("start failed");
            return -1;
        }
        if ( 0 != Login() )
        {
            ERROR_TRACE("login request failed");
            return -1;
        }
        
        //µ»¥˝µ«¬ºΩ·π˚
        do
        {
            if ( m_emStatus == emRegistered ) //◊¢≤·≥…π¶
            {
                bResult = true;
                INFO_TRACE("login OK.");
            }
            else if ( emIdle == m_emStatus ) //◊¢≤· ß∞‹
            {
                bResult = true;
                INFO_TRACE("login failed.");
            }
            else
            {
                FclSleep(1);
            }
            llEnd = GetCurrentTimeMs();
            
        }while( _abs64(llEnd-llStart) < CDvrClient::GS_LOGIN_TIMEOUT*1000 && !bResult );
        
        //µ«¬º
        
        //
        if ( emRegistered == m_emStatus )
        {
            //m_bFirstLogin = false;
            iRet  = 0;
        }
        else //◊¢≤· ß∞‹
        {
            ERROR_TRACE("login failed");
            iRet = -1;
        }
        return iRet;
    }
#endif
    int CDvrClient::CLIENT_Login(const char *pServIp
                                 ,unsigned short usServPort
                                 ,const char *pUsername
                                 ,const char *pPassword
                                 )
    {
        int iRet = 0;
        bool bResult = false;
        long long llStart = GetCurrentTimeMs();
        //	long long llEnd;
        
        if ( m_emStatus != emIdle )
        {
            ERROR_TRACE("invalid status.status="<<(int)m_emStatus);
            return -1;
        }
        m_bIsFirstConnect = true;
        
        //±æ∂À–≈œ¢
        m_strUsername = pUsername;  //”√ªß√˚
        m_strPassword = pPassword;  //√‹¬Î
        
        //∑˛ŒÒ∂À–≈œ¢
        m_strServIp = pServIp; //∑˛ŒÒ∂Àip
        m_iServPort = (int)usServPort;		 //∑˛ŒÒ∂À∂Àø⁄
        
        if ( m_bAutoReConnect )
        {
            //◊‘∂Øƒ£ Ω,“Ï≤Ω
            return Login_Asyc();
        }
        else
        {
            return Login_Sync();
        }
    }
    int CDvrClient::Login_Sync()
    {
        int iRet = 0;
        bool bResult = false;
        long long llStart = GetCurrentTimeMs();
        long long llEnd;
        
        if ( 0 != Start() )
        {
            ERROR_TRACE("start failed");
            return -1;
        }
        
        if ( 0 != Login() )
        {
            ERROR_TRACE("login request failed");
            return -1;
        }
        
        //µ»¥˝µ«¬ºΩ·π˚
        do
        {
            if ( m_emStatus == emRegistered ) //◊¢≤·≥…π¶
            {
                bResult = true;
                INFO_TRACE("login OK.");
            }
            else if ( emIdle == m_emStatus ) //◊¢≤· ß∞‹
            {
                bResult = true;
                
                INFO_TRACE("login failed.");
            }
            else
            {
                FclSleep(1);
            }
            llEnd = GetCurrentTimeMs();
            
        }while( _abs64(llEnd-llStart) < CDvrClient::GS_LOGIN_TIMEOUT*1000 && !bResult );
        
        //µ«¬º
        
        //
        if ( emRegistered == m_emStatus )
        {
            //m_bFirstLogin = false;
            iRet  = 0;
        }
        else //◊¢≤· ß∞‹
        {
            ERROR_TRACE("login failed");
            iRet = -1;
            if (m_error == emDisRe_UserNotValid)
            {
                iRet = -9;
            }
            else if (m_error == emDisRe_PasswordNotValid)
            {
                iRet = -10;
            }
            if ( 0 != Stop() )
            {
                ERROR_TRACE("stop failed");
            }
        }
        return iRet;
    }
    int CDvrClient::Login_Asyc()
    {
        //int iRet = 0;
        m_llLastTime = GetCurrentTimeMs();
        
        if ( 0 != Start() )
        {
            ERROR_TRACE("start failed");
            return -1;
        }
        if ( 0 != Login() )
        {
            ERROR_TRACE("login request failed");
            Stop();
            return -1;
        }
        
        //≤ª”√µ»¥˝Ω·π˚
        return 0;
    }
    int CDvrClient::Logout_Sync(int iTimeout)
    {
        int iRet = 0;
        bool bRet = true;
        //int iTimeout = 5000;
        
        iRet = Dvip_method_v_b_v("global.logout",0,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("logout failed.err="<<iRet);
            //return iRet;
        }
        if ( bRet )
        {
            INFO_TRACE("logout OK.");
        }
        else
        {
            ERROR_TRACE("logout failed,server return false.");
            iRet = -1;
        }
        
        Stop();
        
        FCL_CLOSE_SOCKET(m_sSock);
        m_emStatus = emIdle;
        
        return iRet;
    }
    
    //ªÒ»°…Ë±∏¡–±Ì
    int CDvrClient::GetDeviceList_Sync(std::vector<Smarthome_DeviceInfo> &vecDevice,int iTimeout)
    {
        int iRet = 0;
        int iDataLength = 0;
        int iSendLength = 0;
        unsigned uiReq;
        char szBuf[1024];
        TransInfo *pTask = NULL;
        unsigned int uiObjectId = 0;
        int iReturnCode = 0;
        
        if ( emRegistered != m_emStatus )
        {
            ERROR_TRACE("status invalid,not registered.status="<<(int)m_emStatus);
            return -1;
        }
        
        //ªÒ»°÷«ƒ‹º“æ”π‹¿Ì µ¿˝
        uiReq = CreateReqId();
        CMsgSmarthome_instance_req instReq(uiReq,m_uiSessionId);
        iRet = instReq.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            return -1;
        }
        pTask = new TransInfo(uiReq,emRT_Smarthome_instance,GetCurrentTimeMs());
        if ( !pTask )
        {
            ERROR_TRACE("out of memory");
            return -1;
        }
        AddRequest(uiReq,pTask);
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("smarthome instance failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg || emMsgType_Smarthome_instance_rsp != pTask->pRspMsg->Type() )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        CMsgSmarthome_instance_rsp *pInstRsp = (CMsgSmarthome_instance_rsp*)pTask->pRspMsg;
        if ( 0 == pInstRsp->m_uiObjectId )
        {
            ERROR_TRACE("rsp msg failed.object id=0");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        
        //2 ªÒ»°…Ë±∏¡–±Ì
        uiReq = CreateReqId();
        uiObjectId = pInstRsp->m_uiObjectId;
        CMsgSmarthome_getDeviceList_req getReq(uiReq,m_uiSessionId,uiObjectId,"All");
        iRet = getReq.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            iReturnCode = -1;
            return -1;
        }
        pTask->result = 0;
        if ( pTask->pRspMsg )
        {
            delete pTask->pRspMsg;
        }
        pTask->pRspMsg = NULL;
        pTask->seq = uiReq;
        pTask->hEvent.Reset();
        pTask->type = emRT_Smarthome_getDeviceList;
        AddRequest(uiReq,pTask);
        
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("smarthome getDeviceList failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg || emMsgType_Smarthome_getDeviceList_rsp != pTask->pRspMsg->Type() )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        CMsgSmarthome_getDeviceList_rsp *pGetRsp = (CMsgSmarthome_getDeviceList_rsp*)pTask->pRspMsg;
        if ( !pGetRsp->m_bResult )
        {
            ERROR_TRACE("rsp msg failed.result failed");
            iReturnCode = -1;
            //if ( pTask )
            //{
            //	delete pTask;
            //}
            //return -1;
        }
        else
        {
            //…Ë±∏¡–±Ì
            iReturnCode = 0;
            vecDevice = pGetRsp->m_vecDevice;
        }
        
        //3  Õ∑≈÷«ƒ‹º“æ”π‹¿Ì µ¿˝
        uiReq = CreateReqId();
        CMsgSmarthome_destroy_req destroyReq(uiReq,m_uiSessionId,uiObjectId);
        iRet = destroyReq.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            return -1;
        }
        pTask->result = 0;
        if ( pTask->pRspMsg )
        {
            delete pTask->pRspMsg;
        }
        pTask->pRspMsg = NULL;
        pTask->seq = uiReq;
        pTask->hEvent.Reset();
        pTask->type = emRT_Smarthome_destroy;
        AddRequest(uiReq,pTask);
        
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("smarthome getDeviceList failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg || emMsgType_Smarthome_destroy_rsp != pTask->pRspMsg->Type() )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        CMsgSmarthome_destroy_rsp *pDestroyRsp = (CMsgSmarthome_destroy_rsp*)pTask->pRspMsg;
        if ( !pDestroyRsp->m_bResult )
        {
            ERROR_TRACE("rsp msg failed.result failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        return 0;
    }
    
    //ªÒ»°…Ë±∏¡–±Ì
    int CDvrClient::GetDeviceList_Sync(std::string &strType,std::string &strDevices,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("SmartHomeManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("SmartHomeManager instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Type"] = strType;
        
        iRet = Dvip_method_json_b_json("SmartHomeManager.getDeviceList",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("SmartHomeManager.getDeviceList exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            iReturn = 0;
            if ( !jsonOutParams.isNull())
            {
                strDevices = jsonOutParams.toUnStyledString();
                
                if (!jsonOutParams["Devices"][strType].isNull())
                {
                    strDevices = jsonOutParams["Devices"][strType].toUnStyledString();
                    Json::Value jsonDevices;
                    
                    if ( !jsonOutParams["Devices"][strType].isNull()
                        && jsonOutParams["Devices"][strType].isArray() )
                    {
                        Json::ArrayIndex devices = jsonOutParams["Devices"][strType].size();
                        for(Json::ArrayIndex device=0;device<devices;device++)
                        {
                            Json::Value jsonDevice = jsonOutParams["Devices"][strType][device];
                            
                            //DeviceID
                            if ( !jsonDevice["DeviceID"].isNull()
                                && jsonDevice["DeviceID"].isString() )
                            {
                                jsonDevices["table"][device]["DeviceID"] = jsonDevice["DeviceID"].asString();
                            }
                            else
                            {
                                jsonDevices["table"][device]["DeviceID"] = "";
                            }
                            //Name
                            if ( !jsonDevice["Name"].isNull()
                                && jsonDevice["Name"].isString() )
                            {
                                jsonDevices["table"][device]["Name"] = jsonDevice["Name"].asString();
                            }
                            else
                            {
                                jsonDevices["table"][device]["Name"] = "";
                            }
                            
                            //AreaID
                            if ( !jsonDevice["AreaID"].isNull()
                                && jsonDevice["AreaID"].isInt() )
                            {
                                jsonDevices["table"][device]["AreaID"] = jsonDevice["AreaID"].asInt();
                            }
                            else
                            {
                                jsonDevices["table"][device]["AreaID"] = -1;
                            }
                            
                            //Type
                            if ( !jsonDevice["SubType"].isNull()
                                && jsonDevice["SubType"].isString() )
                            {
                                jsonDevices["table"][device]["Type"] = jsonDevice["SubType"].asString();
                            }
                            else
                            {
                                if ( !jsonDevice["Type"].isNull()
                                    && jsonDevice["Type"].isString() )
                                {
                                    jsonDevices["table"][device]["Type"] = jsonDevice["Type"].asString();
                                }
                                else
                                    jsonDevices["table"][device]["Type"] = strType;
                            }
                            
                            //Level
                            if ( !jsonDevice["Level"].isNull() && jsonDevice["Level"].isInt())
                            {
                                int iLevel = jsonDevice["Level"].asInt();
                                if (iLevel > 1)//支持范围调节
                                {
                                    jsonDevices["table"][device]["Range"][0] = 0;
                                    jsonDevices["table"][device]["Range"][1] = iLevel;
                                }
                                
                                jsonDevices["table"][device]["Level"] = jsonDevice["Level"];
                            }
                            
                            //Range
                            if ( !jsonDevice["Range"].isNull())
                            {
                                jsonDevices["table"][device]["Range"] = jsonDevice["Range"];
                            }
                            
                            //Range
                            if ( !jsonDevice["ControlMode"].isNull())
                            {
                                jsonDevices["table"][device]["ControlMode"] = jsonDevice["ControlMode"];
                            }
                            
                            if ( !jsonDevice["Online"].isNull())
                            {
                                jsonDevices["table"][device]["Online"] = jsonDevice["Online"];
                            }
                        }
                    }
                    
                    strDevices = jsonDevices.toUnStyledString();
                }
            }
        }
        else
        {
            ERROR_TRACE("SmartHomeManager.getDeviceList exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("SmartHomeManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    //ªÒ»°…Ë±∏¡–±Ì–≈œ¢’™“™
    int CDvrClient::GetDeviceDigest_Sync(std::string &strType,std::string &strDigest,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("SmartHomeManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("SmartHomeManager instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["type"] = strType;
        
        iRet = Dvip_method_json_b_json("SmartHomeManager.getDeviceDigest",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("SmartHomeManager.getDeviceDigest exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            iReturn = 0;
            if ( !jsonOutParams.isNull()&& !jsonOutParams["digist"].isNull())
            {
                if ( jsonOutParams["digist"].isString())
                {
                    Json::Value jsonReturn;
                    jsonReturn["table"]["Version"] = jsonOutParams["digist"].asString();
                    strDigest = jsonReturn.toUnStyledString();
                    //INFO_TRACE("digist="<<strDigest);
                }
            }
        }
        else
        {
            ERROR_TRACE("SmartHomeManager.getDeviceDigest exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("SmartHomeManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    //ªÒ»°«Èæ∞ƒ£ Ω
    int CDvrClient::Get_SceneMode_Sync(std::string &strMode,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("SmartHomeManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("SmartHomeManager instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        //ªÒ»°≥°æ∞ƒ£ Ω
        iRet = Dvip_method_json_b_json("SmartHomeManager.getSceneMode",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager.getSceneMode exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            strMode = "";
            int iMode = -1;
            std::vector<std::string> vecScenes;
            std::string strTemp;
            INFO_TRACE("SmartHomeManager.getSceneMode exec OK.");
            if ( !jsonOutParams.isNull()
                && !jsonOutParams["Scene"].isNull()
                )
            {
                strTemp = jsonOutParams.toUnStyledString();
                if ( !jsonOutParams["Scene"]["Profiles"].isNull()
                    && jsonOutParams["Scene"]["Profiles"].isArray()
                    )
                {
                    for(Json::ArrayIndex i=0;i<jsonOutParams["Scene"]["Profiles"].size();i++)
                    {
                        strTemp = jsonOutParams["Scene"]["Profiles"][i].asString();
                        vecScenes.push_back(strTemp);
                        //vecScenes[i] = jsonOutParams["Scene"]["Profiles"][i].asString();
                    }
                    //vecScenes = jsonOutParams["Scene"]["Profiles"].getMemberNames();
                }
                if ( !jsonOutParams["Scene"]["CurrentProfile"].isNull()
                    && jsonOutParams["Scene"]["CurrentProfile"].isInt()
                    )
                {
                    iMode = jsonOutParams["Scene"]["CurrentProfile"].asInt();
                }
                if ( iMode >=0 && iMode < vecScenes.size() )
                {
                    strMode = vecScenes[iMode];
                }
                else
                {
                    WARN_TRACE("invalid scene mode");
                }
            }
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("SmartHomeManager.getSceneMode exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("SmartHomeManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    //…Ë÷√«Èæ∞ƒ£ Ω
    int CDvrClient::Set_SceneMode_Sync(std::string &strMode,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("SmartHomeManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("SmartHomeManager instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Scene"] = strMode;
        //ªÒ»°≥°æ∞ƒ£ Ω
        iRet = Dvip_method_json_b_json("SmartHomeManager.setSceneMode",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("SmartHomeManager.setSceneMode exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            strMode = "";
            int iMode = -1;
            std::vector<std::string> vecScenes;
            INFO_TRACE("SmartHomeManager.setSceneMode exec OK.");
            if ( !jsonOutParams.isNull()
                && !jsonOutParams["Scene"].isNull()
                )
            {
                if ( !jsonOutParams["Scene"]["Profiles"].isNull()
                    && jsonOutParams["Scene"]["Profiles"].isArray()
                    )
                {
                    vecScenes = jsonOutParams["Scene"]["Profiles"].getMemberNames();
                }
                if ( !jsonOutParams["Scene"]["CurrentProfile"].isNull()
                    && jsonOutParams["Scene"]["CurrentProfile"].isInt()
                    )
                {
                    iMode = jsonOutParams["Scene"]["CurrentProfile"].asInt();
                }
                if ( iMode >=0 && iMode < vecScenes.size() )
                {
                    strMode = vecScenes[iMode];
                }
                else
                {
                    WARN_TRACE("invalid scene mode");
                }
            }
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("SmartHomeManager.setSceneMode exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("SmartHomeManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    // ±£¥Ê«Èæ∞ƒ£ Ω
    int CDvrClient::Save_SceneMode_Sync(std::string &strName,std::vector<Smarthome_DeviceInfo> vecDevice,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("SmartHomeManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("SmartHomeManager instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["info"]["Name"] = strName;
        for (int i = 0;i<vecDevice.size();i++)
        {
            Smarthome_DeviceInfo tmp = vecDevice.at(i);
            jsonInParams["info"]["DeviceList"][i]=tmp.strDeviceId;
        }
        //±£¥Ê≥°æ∞ƒ£ Ω
        iRet = Dvip_method_json_b_json("SmartHomeManager.saveSceneMode",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("SmartHomeManager.saveSceneMode exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("SmartHomeManager.saveSceneMode exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("SmartHomeManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            //return -1;
            iReturn = -1;
        }
        
        return iReturn;
    }
    
    // –ﬁ∏ƒ«Èæ∞ƒ£ Ω√˚≥∆
    int CDvrClient::Modify_SceneMode_Sync(std::string &strMode,std::string &strName,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("SmartHomeManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("SmartHomeManager instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["info"]["Scene"] = strMode;
        jsonInParams["info"]["Name"] = strName;
        
        //±£¥Ê≥°æ∞ƒ£ Ω
        iRet = Dvip_method_json_b_json("SmartHomeManager.modifySceneMode",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("SmartHomeManager.modifySceneMode exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("SmartHomeManager.modifySceneMode exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("SmartHomeManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    // …æ≥˝«Èæ∞ƒ£ Ω
    int CDvrClient::Remove_SceneMode_Sync(std::string &strMode,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("SmartHomeManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("SmartHomeManager instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Scene"] = strMode;
        
        //±£¥Ê≥°æ∞ƒ£ Ω
        iRet = Dvip_method_json_b_json("SmartHomeManager.removeSceneMode",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("SmartHomeManager.removeSceneMode exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("SmartHomeManager.removeSceneMode exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("SmartHomeManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    //…Ë÷√…Ë±∏–≈œ¢
    int CDvrClient::SetDeviceInfo_Sync(char *pszDeviceId,char * pszName,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("SmartHomeManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("SmartHomeManager instance from server failed.objectid=0");
            return -1;
        }
        
        //¥Ú∞¸…Ë±∏–≈œ¢
        Json::Value jsonConfig;
        jsonConfig["info"]["DeviceID"] = pszDeviceId;
        jsonConfig["info"]["Name"] = pszName;
        
        iRet = Dvip_setDeviceInfo(uiObjectId,jsonConfig,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Dvip_setDeviceInfo failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("Dvip_setDeviceInfo OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("SmartHomeManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    ////////////////////µ∆π‚
    //ªÒ»°µ∆π‚≈‰÷√
    int CDvrClient::Light_getConfig_Sync(std::vector<Smarthome_Light> &vecDevices,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //ªÒ»°∑øº‰–≈œ¢
        Json::Value jsonConfig;
        iRet = Dvip_getConfig(uiObjectId,"Light",bRet,jsonConfig,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager.getConfig [Light] exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("configManager.getConfig [Light] exec OK.");
            iReturn = 0;
            //Ω‚Œˆƒ⁄»›
            if ( !jsonConfig["table"].isNull()
                && jsonConfig["table"].isArray() )
            {
                Json::ArrayIndex devices = jsonConfig["table"].size();
                for(Json::ArrayIndex device=0;device<devices;device++)
                {
                    Json::Value jsonDevice = jsonConfig["table"][device];
                    Smarthome_Light shDevice;
                    
                    //DeviceID
                    if ( !jsonDevice["DeviceID"].isNull()
                        && jsonDevice["DeviceID"].isString() )
                    {
                        shDevice.strDeviceId = jsonDevice["DeviceID"].asString();
                    }
                    else
                    {
                        shDevice.strDeviceId = "";
                    }
                    //Name
                    if ( !jsonDevice["Name"].isNull()
                        && jsonDevice["Name"].isString() )
                    {
                        shDevice.strDeviceName = jsonDevice["Name"].asString();
                    }
                    else
                    {
                        shDevice.strDeviceName = "";
                    }
                    //Brand
                    if ( !jsonDevice["Brand"].isNull()
                        && jsonDevice["Brand"].isString() )
                    {
                        shDevice.strBrand = jsonDevice["Brand"].asString();
                    }
                    else
                    {
                        shDevice.strBrand = "";
                    }
                    //Comm ¥Æø⁄µÿ÷∑
                    if ( !jsonDevice["Comm"].isNull()
                        && !jsonDevice["Comm"]["Address"].isNull()
                        && jsonDevice["Comm"]["Address"].isArray() )
                    {
                        for(Json::ArrayIndex addr=0;addr<jsonDevice["Comm"]["Address"].size();addr++)
                        {
                            if ( !jsonDevice["Comm"]["Address"][addr].isNull()
                                && jsonDevice["Comm"]["Address"][addr].isInt() )
                            {
                                shDevice.vecAddress.push_back(jsonDevice["Comm"]["Address"][addr].asInt());
                            }
                        }
                    }
                    else
                    {
                        shDevice.vecAddress.clear();
                    }
                    //PosID
                    if ( !jsonDevice["PosID"].isNull()
                        && jsonDevice["PosID"].isInt() )
                    {
                        shDevice.iPosID = jsonDevice["PosID"].asInt();
                    }
                    else
                    {
                        shDevice.iPosID = -1;
                    }
                    //Point …Ë±∏‘⁄PosIDŒª÷√◊¯±Í
                    if ( !jsonDevice["Point"].isNull()
                        && jsonDevice["Point"].isArray()
                        && 2 == jsonDevice["Point"].size() )
                    {
                        shDevice.xPos = jsonDevice["Point"][0].asInt();
                        shDevice.yPos = jsonDevice["Point"][1].asInt();
                    }
                    else
                    {
                        shDevice.xPos = -1;
                        shDevice.yPos = -1;
                    }
                    //State
                    if ( !jsonDevice["State"].isNull()
                        && jsonDevice["State"].isString() )
                    {
                        shDevice.strState = jsonDevice["State"].asString();
                    }
                    else
                    {
                        shDevice.strState = "";
                    }
                    //Range
                    if ( !jsonDevice["Range"].isNull()
                        && jsonDevice["Range"].isInt() )
                    {
                        shDevice.iRange = jsonDevice["Range"].asInt();
                    }
                    else
                    {
                        shDevice.iRange = -1;
                    }
                    //Type
                    if ( !jsonDevice["Type"].isNull()
                        && jsonDevice["Type"].isString() )
                    {
                        shDevice.strType = jsonDevice["Type"].asString();
                    }
                    else
                    {
                        shDevice.strType = "";
                    }
                    
                    vecDevices.push_back(shDevice);
                    shDevice.vecAddress.clear();
                }
            }
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    //…Ë÷√µ∆π‚≈‰÷√
    int CDvrClient::Light_setConfig_Sync(std::vector<Smarthome_Light> &vecDevices,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //¥Ú∞¸∑øº‰–≈œ¢
        Json::Value jsonConfig;
        for(int i=0;i<vecDevices.size();i++)
        {
            jsonConfig[i]["DeviceID"] = vecDevices[i].strDeviceId;
            jsonConfig[i]["Name"] = vecDevices[i].strDeviceName;
            jsonConfig[i]["Brand"] = vecDevices[i].strBrand;
            for(int j=0;j<vecDevices[i].vecAddress.size();j++)
            {
                jsonConfig[i]["Comm"]["Address"][j] = vecDevices[i].vecAddress[j];
            }
            jsonConfig[i]["PosID"] = vecDevices[i].iPosID;
            jsonConfig[i]["Point"][0] = vecDevices[i].xPos;
            jsonConfig[i]["Point"][1] = vecDevices[i].yPos;
            jsonConfig[i]["State"] = vecDevices[i].strState;
            jsonConfig[i]["Range"] = vecDevices[i].iRange;
            jsonConfig[i]["Type"] = vecDevices[i].strType;
        }
        iRet = Dvip_setConfig(uiObjectId,"Light",jsonConfig,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    //µ∆π‚øÿ÷∆ ø™
    int CDvrClient::SetPowerOn_Sync(char *pszDeviceId,int iTimeout)
    {
        int iRet = 0;
        int iDataLength = 0;
        int iSendLength = 0;
        unsigned uiReq;
        char szBuf[1024];
        TransInfo *pTask = NULL;
        unsigned int uiObjectId = 0;
        int iReturnCode = 0;
        
        if ( emRegistered != m_emStatus )
        {
            ERROR_TRACE("status invalid,not registered.status="<<(int)m_emStatus);
            return -1;
        }
        
        //ªÒ»°÷«ƒ‹º“æ”π‹¿Ì µ¿˝
        uiReq = CreateReqId();
        CMsgLight_instance_req instReq(uiReq,m_uiSessionId,pszDeviceId);
        iRet = instReq.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            return -1;
        }
        pTask = new TransInfo(uiReq,emRT_Light_instance,GetCurrentTimeMs());
        if ( !pTask )
        {
            ERROR_TRACE("out of memory");
            return -1;
        }
        AddRequest(uiReq,pTask);
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("Light instance failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg || emMsgType_Light_instance_rsp != pTask->pRspMsg->Type() )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        CMsgLight_instance_rsp *pInstRsp = (CMsgLight_instance_rsp*)pTask->pRspMsg;
        if ( 0 == pInstRsp->m_uiObjectId )
        {
            ERROR_TRACE("rsp msg failed.object id=0");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        
        //2 ªÒ»°…Ë±∏¡–±Ì
        uiReq = CreateReqId();
        uiObjectId = pInstRsp->m_uiObjectId;
        CMsgLight_open_req getReq(uiReq,m_uiSessionId,uiObjectId);
        iRet = getReq.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            iReturnCode = -1;
            return -1;
        }
        pTask->result = 0;
        if ( pTask->pRspMsg )
        {
            delete pTask->pRspMsg;
        }
        pTask->pRspMsg = NULL;
        pTask->seq = uiReq;
        pTask->hEvent.Reset();
        pTask->type = emRT_Light_open;
        AddRequest(uiReq,pTask);
        
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("Light open failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg || emMsgType_Light_open_rsp != pTask->pRspMsg->Type() )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        CMsgLight_open_rsp *pGetRsp = (CMsgLight_open_rsp*)pTask->pRspMsg;
        if ( !pGetRsp->m_bResult )
        {
            ERROR_TRACE("rsp msg failed.result failed");
            iReturnCode = -1;
            //if ( pTask )
            //{
            //	delete pTask;
            //}
            //return -1;
        }
        else
        {
            //…Ë±∏¡–±Ì
            iReturnCode = 0;
        }
        
        //3  Õ∑≈÷«ƒ‹º“æ”π‹¿Ì µ¿˝
        uiReq = CreateReqId();
        CMsgLight_destroy_req destroyReq(uiReq,m_uiSessionId,uiObjectId);
        iRet = destroyReq.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            return -1;
        }
        pTask->result = 0;
        if ( pTask->pRspMsg )
        {
            delete pTask->pRspMsg;
        }
        pTask->pRspMsg = NULL;
        pTask->seq = uiReq;
        pTask->hEvent.Reset();
        pTask->type = emRT_Light_destroy;
        AddRequest(uiReq,pTask);
        
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("Light destroy failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg || emMsgType_Light_destroy_rsp != pTask->pRspMsg->Type() )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        CMsgLight_destroy_rsp *pDestroyRsp = (CMsgLight_destroy_rsp*)pTask->pRspMsg;
        if ( !pDestroyRsp->m_bResult )
        {
            ERROR_TRACE("rsp msg failed.result failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        return 0;
    }
    
    //µ∆π‚øÿ÷∆ πÿ
    int CDvrClient::SetPowerOff_Sync(char *pszDeviceId,int iTimeout)
    {
        int iRet = 0;
        int iDataLength = 0;
        int iSendLength = 0;
        unsigned uiReq;
        char szBuf[1024];
        TransInfo *pTask = NULL;
        unsigned int uiObjectId = 0;
        int iReturnCode = 0;
        
        if ( emRegistered != m_emStatus )
        {
            ERROR_TRACE("status invalid,not registered.status="<<(int)m_emStatus);
            return -1;
        }
        
        //ªÒ»°÷«ƒ‹º“æ”π‹¿Ì µ¿˝
        uiReq = CreateReqId();
        CMsgLight_instance_req instReq(uiReq,m_uiSessionId,pszDeviceId);
        iRet = instReq.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            return -1;
        }
        pTask = new TransInfo(uiReq,emRT_Light_instance,GetCurrentTimeMs());
        if ( !pTask )
        {
            ERROR_TRACE("out of memory");
            return -1;
        }
        AddRequest(uiReq,pTask);
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("Light instance failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg || emMsgType_Light_instance_rsp != pTask->pRspMsg->Type() )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        CMsgLight_instance_rsp *pInstRsp = (CMsgLight_instance_rsp*)pTask->pRspMsg;
        if ( 0 == pInstRsp->m_uiObjectId )
        {
            ERROR_TRACE("rsp msg failed.object id=0");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        
        //2 πÿµ∆
        uiReq = CreateReqId();
        uiObjectId = pInstRsp->m_uiObjectId;
        CMsgLight_close_req getReq(uiReq,m_uiSessionId,uiObjectId);
        iRet = getReq.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            iReturnCode = -1;
            return -1;
        }
        pTask->result = 0;
        if ( pTask->pRspMsg )
        {
            delete pTask->pRspMsg;
        }
        pTask->pRspMsg = NULL;
        pTask->seq = uiReq;
        pTask->hEvent.Reset();
        pTask->type = emRT_Light_close;
        AddRequest(uiReq,pTask);
        
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("Light close failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg || emMsgType_Light_close_rsp != pTask->pRspMsg->Type() )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        CMsgLight_close_rsp *pGetRsp = (CMsgLight_close_rsp*)pTask->pRspMsg;
        if ( !pGetRsp->m_bResult )
        {
            ERROR_TRACE("rsp msg failed.result failed");
            iReturnCode = -1;
            //if ( pTask )
            //{
            //	delete pTask;
            //}
            //return -1;
        }
        else
        {
            //…Ë±∏¡–±Ì
            iReturnCode = 0;
        }
        
        //3  Õ∑≈÷«ƒ‹º“æ”π‹¿Ì µ¿˝
        uiReq = CreateReqId();
        CMsgLight_destroy_req destroyReq(uiReq,m_uiSessionId,uiObjectId);
        iRet = destroyReq.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            return -1;
        }
        pTask->result = 0;
        if ( pTask->pRspMsg )
        {
            delete pTask->pRspMsg;
        }
        pTask->pRspMsg = NULL;
        pTask->seq = uiReq;
        pTask->hEvent.Reset();
        pTask->type = emRT_Light_destroy;
        AddRequest(uiReq,pTask);
        
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("Light destroy failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg || emMsgType_Light_destroy_rsp != pTask->pRspMsg->Type() )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        CMsgLight_destroy_rsp *pDestroyRsp = (CMsgLight_destroy_rsp*)pTask->pRspMsg;
        if ( !pDestroyRsp->m_bResult )
        {
            ERROR_TRACE("rsp msg failed.result failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        return 0;
    }
    
    // µ∆π‚øÿ÷∆ …Ë÷√µ∆π‚¡¡∂»
    int CDvrClient::Light_setBrightLevel_Sync(char *pszDeviceId,int iLevel,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        if ( emRegistered != m_emStatus )
        {
            ERROR_TRACE("status invalid,not registered.status="<<(int)m_emStatus);
            return -1;
        }
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("Light.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("Light instance from server failed.objectid=0");
            return -1;
        }
        
        //iLevel = iLevel*8/100;
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Level"] = iLevel;
        //…Ë÷√µ∆π‚¡¡∂»
        iRet = Dvip_method_json_b_json("Light.setBrightLevel",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("Light.setBrightLevel exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("Light.setBrightLevel exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("Light.setBrightLevel exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Light.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
        }
        
        return iReturn;
    }
    
    // µ∆π‚øÿ÷∆ µ˜Ω⁄µ∆π‚¡¡∂»
    int CDvrClient::Light_adjustBright_Sync(char *pszDeviceId,int iLevel,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        if ( emRegistered != m_emStatus )
        {
            ERROR_TRACE("status invalid,not registered.status="<<(int)m_emStatus);
            return -1;
        }
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("Light.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("Light instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Level"] = iLevel;
        //µ˜Ω⁄µ∆π‚¡¡∂»
        iRet = Dvip_method_json_b_json("Light.adjustBright",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("Light.adjustBright exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("Light.adjustBright exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("Light.adjustBright exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Light.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
        }
        
        return iReturn;
    }
    // µ∆π‚øÿ÷∆ —” ±πÿµ∆
    int CDvrClient::Light_keepOn_Sync(char *pszDeviceId,int iTime,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        if ( emRegistered != m_emStatus )
        {
            ERROR_TRACE("status invalid,not registered.status="<<(int)m_emStatus);
            return -1;
        }
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("Light.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("Light instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Time"] = iTime;
        //µ˜Ω⁄µ∆π‚¡¡∂»
        iRet = Dvip_method_json_b_json("Light.keepOn",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("Light.keepOn exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("Light.keepOn exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("Light.keepOn exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Light.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
        }
        
        return iReturn;
    }
    // µ∆π‚øÿ÷∆ µ∆…¡À∏
    int CDvrClient::Light_blink_Sync(char *pszDeviceId,int iTime,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        if ( emRegistered != m_emStatus )
        {
            ERROR_TRACE("status invalid,not registered.status="<<(int)m_emStatus);
            return -1;
        }
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("Light.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("Light instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Time"] = iTime;
        //µ˜Ω⁄µ∆π‚¡¡∂»
        iRet = Dvip_method_json_b_json("Light.blink",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("Light.blink exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("Light.blink exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("Light.blink exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Light.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
        }
        
        return iReturn;
    }
    // µ∆π‚øÿ÷∆ “‘÷∏∂®ÀŸ∂»¥Úø™“ª◊Èµ∆
    int CDvrClient::Light_openGroup_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        if ( emRegistered != m_emStatus )
        {
            ERROR_TRACE("status invalid,not registered.status="<<(int)m_emStatus);
            return -1;
        }
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("Light.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("Light instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Type"] = iType;
        jsonInParams["Speed"] = iSpeed;
        //µ˜Ω⁄µ∆π‚¡¡∂»
        iRet = Dvip_method_json_b_json("Light.openGroup",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("Light.openGroup exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("Light.openGroup exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("Light.openGroup exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Light.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
        }
        
        return iReturn;
    }
    // µ∆π‚øÿ÷∆ “‘÷∏∂®ÀŸ∂»πÿ±’“ª◊Èµ∆
    int CDvrClient::Light_closeGroup_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        if ( emRegistered != m_emStatus )
        {
            ERROR_TRACE("status invalid,not registered.status="<<(int)m_emStatus);
            return -1;
        }
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("Light.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("Light instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Type"] = iType;
        jsonInParams["Speed"] = iSpeed;
        //µ˜Ω⁄µ∆π‚¡¡∂»
        iRet = Dvip_method_json_b_json("Light.closeGroup",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("Light.closeGroup exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("Light.closeGroup exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("Light.closeGroup exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Light.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
        }
        
        return iReturn;
    }
    // µ∆π‚øÿ÷∆ “‘÷∏∂®ÀŸ∂»µ˜¡¡µ∆π‚
    int CDvrClient::Light_brightLevelUp_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        if ( emRegistered != m_emStatus )
        {
            ERROR_TRACE("status invalid,not registered.status="<<(int)m_emStatus);
            return -1;
        }
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("Light.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("Light instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Type"] = iType;
        jsonInParams["Speed"] = iSpeed;
        //µ˜Ω⁄µ∆π‚¡¡∂»
        iRet = Dvip_method_json_b_json("Light.brightLevelUp",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("Light.brightLevelUp exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("Light.brightLevelUp exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("Light.brightLevelUp exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Light.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
        }
        
        return iReturn;
    }
    // µ∆π‚øÿ÷∆ “‘÷∏∂®ÀŸ∂»µ˜∞µµ∆π‚
    int CDvrClient::Light_brightLevelDown_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        if ( emRegistered != m_emStatus )
        {
            ERROR_TRACE("status invalid,not registered.status="<<(int)m_emStatus);
            return -1;
        }
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("Light.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("Light instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Type"] = iType;
        jsonInParams["Speed"] = iSpeed;
        //µ˜Ω⁄µ∆π‚¡¡∂»
        iRet = Dvip_method_json_b_json("Light.brightLevelDown",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("Light.brightLevelDown exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("Light.brightLevelDown exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("Light.brightLevelDown exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Light.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
        }
        
        return iReturn;
    }
    
    //ªÒ»°µ∆π‚◊¥Ã¨
    int CDvrClient::GetPowerStatus_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iBright,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        Json::Value jsParams;
        
        if ( emRegistered != m_emStatus )
        {
            ERROR_TRACE("status invalid,not registered.status="<<(int)m_emStatus);
            return -1;
        }
        
        //¥¥Ω® µ¿˝
        jsParams["DeviceID"] = pszDeviceId;
        iRet = Dvip_instance("Light.factory.instance",jsParams/*pszDeviceId*/,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("Light instance from server failed.objectid=0");
            return -1;
        }
        
        //
        iRet = Dvip_Light_getState("Light.getState",uiObjectId,bRet,bIsOnline,bIsOn,iBright,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Light.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Light instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    //¥∞¡±
    // ªÒ»°¥∞¡±≈‰÷√
    int CDvrClient::Curtain_getConfig_Sync(std::vector<Smarthome_Curtain> &vecDevices,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //ªÒ»°¥∞¡±≈‰÷√–≈œ¢
        Json::Value jsonConfig;
        iRet = Dvip_getConfig(uiObjectId,"Curtain",bRet,jsonConfig,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager.getConfig [Curtain] exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("configManager.getConfig [Curtain] exec OK.");
            iReturn = 0;
            //Ω‚Œˆƒ⁄»›
            if ( !jsonConfig["table"].isNull()
                && jsonConfig["table"].isArray() )
            {
                Json::ArrayIndex devices = jsonConfig["table"].size();
                for(Json::ArrayIndex device=0;device<devices;device++)
                {
                    Json::Value jsonDevice = jsonConfig["table"][device];
                    Smarthome_Curtain shDevice;
                    
                    //DeviceID
                    if ( !jsonDevice["DeviceID"].isNull()
                        && jsonDevice["DeviceID"].isString() )
                    {
                        shDevice.strDeviceId = jsonDevice["DeviceID"].asString();
                    }
                    else
                    {
                        shDevice.strDeviceId = "";
                    }
                    //Name
                    if ( !jsonDevice["Name"].isNull()
                        && jsonDevice["Name"].isString() )
                    {
                        shDevice.strDeviceName = jsonDevice["Name"].asString();
                    }
                    else
                    {
                        shDevice.strDeviceName = "";
                    }
                    //Brand
                    if ( !jsonDevice["Brand"].isNull()
                        && jsonDevice["Brand"].isString() )
                    {
                        shDevice.strBrand = jsonDevice["Brand"].asString();
                    }
                    else
                    {
                        shDevice.strBrand = "";
                    }
                    //Comm ¥Æø⁄µÿ÷∑
                    if ( !jsonDevice["Comm"].isNull()
                        && !jsonDevice["Comm"]["Address"].isNull()
                        && jsonDevice["Comm"]["Address"].isArray() )
                    {
                        for(Json::ArrayIndex addr=0;addr<jsonDevice["Comm"]["Address"].size();addr++)
                        {
                            if ( !jsonDevice["Comm"]["Address"][addr].isNull()
                                && jsonDevice["Comm"]["Address"][addr].isInt() )
                            {
                                shDevice.vecAddress.push_back(jsonDevice["Comm"]["Address"][addr].asInt());
                            }
                        }
                    }
                    else
                    {
                        shDevice.vecAddress.clear();
                    }
                    //PosID
                    if ( !jsonDevice["PosID"].isNull()
                        && jsonDevice["PosID"].isInt() )
                    {
                        shDevice.iPosID = jsonDevice["PosID"].asInt();
                    }
                    else
                    {
                        shDevice.iPosID = -1;
                    }
                    //Point …Ë±∏‘⁄PosIDŒª÷√◊¯±Í
                    if ( !jsonDevice["Point"].isNull()
                        && jsonDevice["Point"].isArray()
                        && 2 == jsonDevice["Point"].size() )
                    {
                        shDevice.xPos = jsonDevice["Point"][0].asInt();
                        shDevice.yPos = jsonDevice["Point"][1].asInt();
                    }
                    else
                    {
                        shDevice.xPos = -1;
                        shDevice.yPos = -1;
                    }
                    //State
                    if ( !jsonDevice["State"].isNull()
                        && jsonDevice["State"].isString() )
                    {
                        shDevice.strState = jsonDevice["State"].asString();
                    }
                    else
                    {
                        shDevice.strState = "";
                    }
                    //Range
                    if ( !jsonDevice["Range"].isNull()
                        && jsonDevice["Range"].isInt() )
                    {
                        shDevice.iRange = jsonDevice["Range"].asInt();
                    }
                    else
                    {
                        shDevice.iRange = -1;
                    }
                    //Type
                    if ( !jsonDevice["Type"].isNull()
                        && jsonDevice["Type"].isString() )
                    {
                        shDevice.strType = jsonDevice["Type"].asString();
                    }
                    else
                    {
                        shDevice.strType = "";
                    }
                    
                    vecDevices.push_back(shDevice);
                    shDevice.vecAddress.clear();
                }
            }
            
        }
        else
        {
            ERROR_TRACE("configManager.getConfig [Curtain] exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
        }
        
        return iReturn;
    }
    // …Ë÷√¥∞¡±≈‰÷√
    int CDvrClient::Curtain_setConfig_Sync(std::vector<Smarthome_Curtain> &vecDevices,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //¥Ú∞¸∑øº‰–≈œ¢
        Json::Value jsonConfig;
        for(int i=0;i<vecDevices.size();i++)
        {
            jsonConfig[i]["DeviceID"] = vecDevices[i].strDeviceId;
            jsonConfig[i]["Name"] = vecDevices[i].strDeviceName;
            jsonConfig[i]["Brand"] = vecDevices[i].strBrand;
            for(int j=0;j<vecDevices[i].vecAddress.size();j++)
            {
                jsonConfig[i]["Comm"]["Address"][j] = vecDevices[i].vecAddress[j];
            }
            jsonConfig[i]["PosID"] = vecDevices[i].iPosID;
            jsonConfig[i]["Point"][0] = vecDevices[i].xPos;
            jsonConfig[i]["Point"][1] = vecDevices[i].yPos;
            jsonConfig[i]["State"] = vecDevices[i].strState;
            jsonConfig[i]["Range"] = vecDevices[i].iRange;
            jsonConfig[i]["Type"] = vecDevices[i].strType;
        }
        iRet = Dvip_setConfig(uiObjectId,"Curtain",jsonConfig,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager.setConfig [Curtain] exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("configManager.setConfig [Curtain] exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("configManager.setConfig [Curtain] exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    //¥Úø™
    int CDvrClient::Curtain_open_Sync(char *pszDeviceId,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("Curtain.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("curtain instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("curtain instance from server failed.objectid=0");
            return -1;
        }
        
        //øÿ÷∆¥∞¡±
        iRet = Dvip_method_v_b_v("Curtain.open",uiObjectId,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Curtain.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("curtain instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    //πÿ±’
    int CDvrClient::Curtain_close_Sync(char *pszDeviceId,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("Curtain.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("curtain instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("curtain instance from server failed.objectid=0");
            return -1;
        }
        
        //øÿ÷∆¥∞¡±
        iRet = Dvip_method_v_b_v("Curtain.close",uiObjectId,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Curtain.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("curtain instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    //Õ£÷π
    int CDvrClient::Curtain_stop_Sync(char *pszDeviceId,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("Curtain.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("curtain instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("curtain instance from server failed.objectid=0");
            return -1;
        }
        
        //øÿ÷∆¥∞¡±
        iRet = Dvip_method_v_b_v("Curtain.stop",uiObjectId,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Curtain.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("curtain instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    //µ˜’˚¥∞¡±’⁄π‚¬
    int CDvrClient::Curtain_adjustShading_Sync(char *pszDeviceId,int iScale,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("Curtain.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("curtain instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("curtain instance from server failed.objectid=0");
            return -1;
        }
        
        //øÿ÷∆¥∞¡±
        iRet = Dvip_method_v_b_v("Curtain.adjustShading",uiObjectId,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("Curtain.adjustShading exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("Curtain.adjustShading exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("Curtain.adjustShading exec failed.");
            iReturn = -1;
        }
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Scale"] = iScale;
        //µ˜Ω⁄µ∆π‚¡¡∂»
        iRet = Dvip_method_json_b_json("Curtain.adjustShading",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("Curtain.adjustShading exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("Curtain.adjustShading exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("Curtain.adjustShading exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Curtain.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("curtain instance failed.");
        }
        
        return iReturn;
    }
    //…Ë÷√¥∞¡±’⁄π‚¬
    int CDvrClient::Curtain_setShading_Sync(char *pszDeviceId,int iScale,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("Curtain.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("curtain instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("curtain instance from server failed.objectid=0");
            return -1;
        }
        
        //øÿ÷∆¥∞¡±
        //iRet = Dvip_method_v_b_v("Curtain.setShading",uiObjectId,bRet,iTimeout);
        //if ( 0 != iRet )
        //{
        //	ERROR_TRACE("Curtain.setShading exec failed.");
        //	iReturn = -1;
        //	//return -1;
        //}
        //if ( bRet )
        //{
        //	INFO_TRACE("Curtain.setShading exec OK.");
        //	iReturn = 0;
        //}
        //else
        //{
        //	ERROR_TRACE("Curtain.setShading exec failed.");
        //	iReturn = -1;
        //}
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Scale"] = iScale;
        //µ˜Ω⁄µ∆π‚¡¡∂»
        iRet = Dvip_method_json_b_json("Curtain.setShading",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("Curtain.setShading exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("Curtain.setShading exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("Curtain.setShading exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Curtain.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("curtain instance failed.");
        }
        
        return iReturn;
    }
    
    //ªÒ»°◊¥Ã¨
    int CDvrClient::Curtain_getState_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iShading,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        //bool bIsOnline = false;
        //bool bIsOn = false;
        //int iShading = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("Curtain.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("curtain instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("curtain instance from server failed.objectid=0");
            return -1;
        }
        
        //øÿ÷∆¥∞¡±
        iRet = Dvip_Curtain_getState("Curtain.getState",uiObjectId,bRet,bIsOnline,bIsOn,iShading,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("Curtain.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("curtain instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    //ªÒ»°∑øº‰¡–±Ì
    int CDvrClient::GetHouseInfo_Sync(std::vector<Smarthome_HouseInfo> &vecHouse,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //ªÒ»°∑øº‰–≈œ¢
        Json::Value jsonConfig;
        iRet = Dvip_getConfig(uiObjectId,"HouseTypeInfo",bRet,jsonConfig,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            iReturn = 0;
            //Ω‚Œˆƒ⁄»›
            Json::Value jsonHouse;
            if ( !jsonConfig["table"].isNull()
                && jsonConfig["table"].isArray() )
            {
                Json::ArrayIndex size = jsonConfig["table"].size();
                if ( size > 0 )
                {
                    /*Json::Value */jsonHouse = jsonConfig["table"][0];
                }
                
            }
            else if ( !jsonConfig["table"].isNull()
                     && jsonConfig["table"].isObject() )
            {
                jsonHouse = jsonConfig["table"];
            }
            if ( !jsonHouse.isNull() )
            {
                
                if ( !jsonHouse["Floors"].isNull()
                    && jsonConfig["Floors"].isArray() )
                {
                    Smarthome_HouseInfo houseInfo;
                    Smarthome_AreaInfo areaInfo;
                    Json::ArrayIndex floors = jsonHouse["Floors"].size();
                    for(Json::ArrayIndex floor=0;floor<floors;floor++)
                    {
                        if ( !jsonHouse["Floors"][floor]["Name"].isNull()
                            && jsonHouse["Floors"][floor]["Name"].isString() )
                        {
                            houseInfo.strName = jsonHouse["Floors"][floor]["Name"].asString();
                        }
                        else
                        {
                            houseInfo.strName = "";
                        }
                        if ( !jsonHouse["Floors"][floor]["ID"].isNull()
                            && jsonHouse["Floors"][floor]["ID"].isInt() )
                        {
                            char szBuf[64];
                            sprintf(szBuf,"%d",jsonHouse["Floors"][floor]["ID"].asInt());
                            houseInfo.strId = szBuf;
                        }
                        else
                        {
                            houseInfo.strId = "";
                        }
                        if ( !jsonHouse["Floors"][floor]["Areas"].isNull()
                            && jsonHouse["Floors"][floor]["Areas"].isArray() )
                        {
                            Json::ArrayIndex areas = jsonHouse["Floors"][floor]["Areas"].size();
                            for(Json::ArrayIndex area=0;area<areas;area++)
                            {
                                if ( !jsonHouse["Floors"][floor]["Areas"][area]["Name"].isNull()
                                    && jsonHouse["Floors"][floor]["Areas"][area]["Name"].isString() )
                                {
                                    areaInfo.strName = jsonHouse["Floors"][floor]["Areas"][area]["Name"].asString();
                                }
                                else
                                {
                                    areaInfo.strName = "";
                                }
                                if ( !jsonHouse["Floors"][floor]["Areas"][area]["ID"].isNull()
                                    && jsonHouse["Floors"][floor]["Areas"][area]["ID"].isInt() )
                                {
                                    char szBuf[64];
                                    sprintf(szBuf,"%d",jsonHouse["Floors"][floor]["Areas"][area]["ID"].asInt());
                                    areaInfo.strId = szBuf;
                                }
                                else
                                {
                                    areaInfo.strId = "";
                                }
                                if ( !jsonHouse["Floors"][floor]["Areas"][area]["Type"].isNull()
                                    && jsonHouse["Floors"][floor]["Areas"][area]["Type"].isString() )
                                {
                                    areaInfo.strType = jsonHouse["Floors"][floor]["Areas"][area]["Type"].asString();
                                }
                                else
                                {
                                    areaInfo.strType = "";
                                }
                                areaInfo.strFloorId = houseInfo.strId;
                                houseInfo.vecAreas.push_back(areaInfo);
                            }
                        }
                        vecHouse.push_back(houseInfo);
                        houseInfo.vecAreas.clear();
                    }
                }
                
            }
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    //…Ë÷√∑øº‰¡–±Ì
    int CDvrClient::SetHouseInfo_Sync(std::vector<Smarthome_HouseInfo> &vecHouse,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //¥Ú∞¸∑øº‰–≈œ¢
        Json::Value jsonConfig;
        jsonConfig["FloorNumber"] = (int)vecHouse.size();
        for(int i=0;i<vecHouse.size();i++)
        {
            jsonConfig["Floors"][i]["ID"] = atoi(vecHouse[i].strId.c_str());
            jsonConfig["Floors"][i]["Name"] = vecHouse[i].strName;
            //jsonConfig["Floors"][i]["Rect"][0] = 0;
            //jsonConfig["Floors"][i]["Rect"][1] = 0;
            //jsonConfig["Floors"][i]["Rect"][2] = 250;
            //jsonConfig["Floors"][i]["Rect"][3] = 250;
            //jsonConfig["Floors"][i]["PicturePath"] = "/floor.jpg";
            for(int j=0;j<vecHouse[i].vecAreas.size();j++)
            {
                jsonConfig["Floors"][i]["Areas"][j]["ID"] = atoi(vecHouse[i].vecAreas[j].strId.c_str());
                //jsonConfig["Floors"][i]["Areas"][j]["Rect"][0] = 0;
                //jsonConfig["Floors"][i]["Areas"][j]["Rect"][1] = 0;
                //jsonConfig["Floors"][i]["Areas"][j]["Rect"][2] = 250;
                //jsonConfig["Floors"][i]["Areas"][j]["Rect"][3] = 250;
                //jsonConfig["Floors"][i]["Areas"][j]["PicturePath"] = "/floor.jpg";
                jsonConfig["Floors"][i]["Areas"][j]["Name"] = vecHouse[i].vecAreas[j].strName;
                jsonConfig["Floors"][i]["Areas"][j]["Type"] = vecHouse[i].vecAreas[j].strType;
            }
        }
        iRet = Dvip_setConfig(uiObjectId,"HouseTypeInfo",jsonConfig,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    //ªÒ»°«Èæ∞ƒ£ Ω
    int CDvrClient::Get_SceneMode_Sync(int &iCurrentId,std::vector<Smarthome_SceneInfo> &vecScenes,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        iCurrentId = -1;
        //ªÒ»°∑øº‰–≈œ¢
        Json::Value jsonConfig;
        iRet = Dvip_getConfig(uiObjectId,"SceneMode",bRet,jsonConfig,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("SmartHomeManager.getconfig SceneMode exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("SmartHomeManager.getconfig SceneMode exec OK.");
            iReturn = 0;
            //Ω‚Œˆƒ⁄»›
            if ( !jsonConfig["table"].isNull()
                && jsonConfig["table"].isObject() )
            {
                Json::Value &jsonSceneMode = jsonConfig["table"]/*[0]*/;
                if ( !jsonSceneMode["CurrentProfileID"].isNull()
                    && jsonSceneMode["CurrentProfileID"].isInt()
                    )
                {
                    iCurrentId = jsonSceneMode["CurrentProfileID"].asInt();
                }
                if ( !jsonSceneMode["Profiles"].isNull()
                    && jsonSceneMode["Profiles"].isArray() )
                {
                    Json::ArrayIndex scenes = jsonSceneMode["Profiles"].size();
                    for(Json::ArrayIndex scene=0;scene<scenes;scene++)
                    {
                        Json::Value &jsonScene = jsonSceneMode["Profiles"][scene];
                        Smarthome_SceneInfo shScene;
                        
                        //Brand
                        if ( !jsonScene["Brand"].isNull()
                            && jsonScene["Brand"].isString() )
                        {
                            shScene.strBrand = jsonScene["Brand"].asString();
                        }
                        else
                        {
                            shScene.strBrand = "";
                        }
                        //Name
                        if ( !jsonScene["Name"].isNull()
                            && jsonScene["Name"].isString() )
                        {
                            shScene.strName = jsonScene["Name"].asString();
                        }
                        else
                        {
                            shScene.strName = "";
                        }
                        
                        
                        //µ∆π‚…Ë±∏¡–±Ì
                        if ( !jsonScene["Light"].isNull()
                            && jsonScene["Light"].isArray() )
                        {
                            Json::ArrayIndex devices = jsonScene["Light"].size();
                            for(Json::ArrayIndex device=0;device<devices;device++)
                            {
                                Json::Value &jsonDevice= jsonConfig["Light"][device];
                                Smarthome_Light shDevice;
                                
                                //DeviceID
                                if ( !jsonDevice["DeviceID"].isNull()
                                    && jsonDevice["DeviceID"].isString() )
                                {
                                    shDevice.strDeviceId = jsonDevice["DeviceID"].asString();
                                }
                                else
                                {
                                    shDevice.strDeviceId = "";
                                }
                                //Name
                                if ( !jsonDevice["Name"].isNull()
                                    && jsonDevice["Name"].isString() )
                                {
                                    shDevice.strDeviceName = jsonDevice["Name"].asString();
                                }
                                else
                                {
                                    shDevice.strDeviceName = "";
                                }
                                //Brand
                                if ( !jsonDevice["Brand"].isNull()
                                    && jsonDevice["Brand"].isString() )
                                {
                                    shDevice.strBrand = jsonDevice["Brand"].asString();
                                }
                                else
                                {
                                    shDevice.strBrand = "";
                                }
                                //Comm ¥Æø⁄µÿ÷∑
                                if ( !jsonDevice["Comm"].isNull()
                                    && !jsonDevice["Comm"]["Address"].isNull()
                                    && jsonDevice["Comm"]["Address"].isArray() )
                                {
                                    for(Json::ArrayIndex addr=0;addr<jsonDevice["Comm"]["Address"].size();addr++)
                                    {
                                        if ( !jsonDevice["Comm"]["Address"][addr].isNull()
                                            && jsonDevice["Comm"]["Address"][addr].isInt() )
                                        {
                                            shDevice.vecAddress.push_back(jsonDevice["Comm"]["Address"][addr].asInt());
                                        }
                                    }
                                }
                                else
                                {
                                    shDevice.vecAddress.clear();
                                }
                                //PosID
                                if ( !jsonDevice["PosID"].isNull()
                                    && jsonDevice["PosID"].isInt() )
                                {
                                    shDevice.iPosID = jsonDevice["PosID"].asInt();
                                }
                                else
                                {
                                    shDevice.iPosID = -1;
                                }
                                //Point …Ë±∏‘⁄PosIDŒª÷√◊¯±Í
                                if ( !jsonDevice["Point"].isNull()
                                    && jsonDevice["Point"].isArray()
                                    && 2 == jsonDevice["Point"].size() )
                                {
                                    shDevice.xPos = jsonDevice["Point"][0].asInt();
                                    shDevice.yPos = jsonDevice["Point"][1].asInt();
                                }
                                else
                                {
                                    shDevice.xPos = -1;
                                    shDevice.yPos = -1;
                                }
                                //State
                                if ( !jsonDevice["State"].isNull()
                                    && jsonDevice["State"].isString() )
                                {
                                    shDevice.strState = jsonDevice["State"].asString();
                                }
                                else
                                {
                                    shDevice.strState = "";
                                }
                                //Range
                                if ( !jsonDevice["Range"].isNull()
                                    && jsonDevice["Range"].isInt() )
                                {
                                    shDevice.iRange = jsonDevice["Range"].asInt();
                                }
                                else
                                {
                                    shDevice.iRange = -1;
                                }
                                //Type
                                if ( !jsonDevice["Type"].isNull()
                                    && jsonDevice["Type"].isString() )
                                {
                                    shDevice.strType = jsonDevice["Type"].asString();
                                }
                                else
                                {
                                    shDevice.strType = "";
                                }
                                
                                shScene.vecLight.push_back(shDevice);
                                shDevice.vecAddress.clear();
                            }
                        } //Light
                        
                        //¥∞¡±…Ë±∏¡–±Ì
                        if ( !jsonScene["Curtain"].isNull()
                            && jsonScene["Curtain"].isArray() )
                        {
                            Json::ArrayIndex devices = jsonScene["Curtain"].size();
                            for(Json::ArrayIndex device=0;device<devices;device++)
                            {
                                Json::Value &jsonDevice= jsonConfig["Curtain"][device];
                                Smarthome_Curtain shDevice;
                                
                                //DeviceID
                                if ( !jsonDevice["DeviceID"].isNull()
                                    && jsonDevice["DeviceID"].isString() )
                                {
                                    shDevice.strDeviceId = jsonDevice["DeviceID"].asString();
                                }
                                else
                                {
                                    shDevice.strDeviceId = "";
                                }
                                //Name
                                if ( !jsonDevice["Name"].isNull()
                                    && jsonDevice["Name"].isString() )
                                {
                                    shDevice.strDeviceName = jsonDevice["Name"].asString();
                                }
                                else
                                {
                                    shDevice.strDeviceName = "";
                                }
                                //Brand
                                if ( !jsonDevice["Brand"].isNull()
                                    && jsonDevice["Brand"].isString() )
                                {
                                    shDevice.strBrand = jsonDevice["Brand"].asString();
                                }
                                else
                                {
                                    shDevice.strBrand = "";
                                }
                                //Comm ¥Æø⁄µÿ÷∑
                                if ( !jsonDevice["Comm"].isNull()
                                    && !jsonDevice["Comm"]["Address"].isNull()
                                    && jsonDevice["Comm"]["Address"].isArray() )
                                {
                                    for(Json::ArrayIndex addr=0;addr<jsonDevice["Comm"]["Address"].size();addr++)
                                    {
                                        if ( !jsonDevice["Comm"]["Address"][addr].isNull()
                                            && jsonDevice["Comm"]["Address"][addr].isInt() )
                                        {
                                            shDevice.vecAddress.push_back(jsonDevice["Comm"]["Address"][addr].asInt());
                                        }
                                    }
                                }
                                else
                                {
                                    shDevice.vecAddress.clear();
                                }
                                //PosID
                                if ( !jsonDevice["PosID"].isNull()
                                    && jsonDevice["PosID"].isInt() )
                                {
                                    shDevice.iPosID = jsonDevice["PosID"].asInt();
                                }
                                else
                                {
                                    shDevice.iPosID = -1;
                                }
                                //Point …Ë±∏‘⁄PosIDŒª÷√◊¯±Í
                                if ( !jsonDevice["Point"].isNull()
                                    && jsonDevice["Point"].isArray()
                                    && 2 == jsonDevice["Point"].size() )
                                {
                                    shDevice.xPos = jsonDevice["Point"][0].asInt();
                                    shDevice.yPos = jsonDevice["Point"][1].asInt();
                                }
                                else
                                {
                                    shDevice.xPos = -1;
                                    shDevice.yPos = -1;
                                }
                                //State
                                if ( !jsonDevice["State"].isNull()
                                    && jsonDevice["State"].isString() )
                                {
                                    shDevice.strState = jsonDevice["State"].asString();
                                }
                                else
                                {
                                    shDevice.strState = "";
                                }
                                //Range
                                if ( !jsonDevice["Range"].isNull()
                                    && jsonDevice["Range"].isInt() )
                                {
                                    shDevice.iRange = jsonDevice["Range"].asInt();
                                }
                                else
                                {
                                    shDevice.iRange = -1;
                                }
                                //Type
                                if ( !jsonDevice["Type"].isNull()
                                    && jsonDevice["Type"].isString() )
                                {
                                    shDevice.strType = jsonDevice["Type"].asString();
                                }
                                else
                                {
                                    shDevice.strType = "";
                                }
                                
                                shScene.vecCurtain.push_back(shDevice);
                                shDevice.vecAddress.clear();
                            }
                        } //Curtain
                        
                        
                        //µÿ≈Ø…Ë±∏¡–±Ì
                        if ( !jsonScene["GroundHeat"].isNull()
                            && jsonScene["GroundHeat"].isArray() )
                        {
                            Json::ArrayIndex devices = jsonScene["GroundHeat"].size();
                            for(Json::ArrayIndex device=0;device<devices;device++)
                            {
                                Json::Value &jsonDevice = jsonConfig["GroundHeat"][device];
                                Smarthome_GroundHeat shDevice;
                                
                                //DeviceID
                                if ( !jsonDevice["DeviceID"].isNull()
                                    && jsonDevice["DeviceID"].isString() )
                                {
                                    shDevice.strDeviceId = jsonDevice["DeviceID"].asString();
                                }
                                else
                                {
                                    shDevice.strDeviceId = "";
                                }
                                //Name
                                if ( !jsonDevice["Name"].isNull()
                                    && jsonDevice["Name"].isString() )
                                {
                                    shDevice.strDeviceName = jsonDevice["Name"].asString();
                                }
                                else
                                {
                                    shDevice.strDeviceName = "";
                                }
                                //Brand
                                if ( !jsonDevice["Brand"].isNull()
                                    && jsonDevice["Brand"].isString() )
                                {
                                    shDevice.strBrand = jsonDevice["Brand"].asString();
                                }
                                else
                                {
                                    shDevice.strBrand = "";
                                }
                                //Comm ¥Æø⁄µÿ÷∑
                                if ( !jsonDevice["Comm"].isNull()
                                    && !jsonDevice["Comm"]["Address"].isNull()
                                    && jsonDevice["Comm"]["Address"].isArray() )
                                {
                                    for(Json::ArrayIndex addr=0;addr<jsonDevice["Comm"]["Address"].size();addr++)
                                    {
                                        if ( !jsonDevice["Comm"]["Address"][addr].isNull()
                                            && jsonDevice["Comm"]["Address"][addr].isInt() )
                                        {
                                            shDevice.vecAddress.push_back(jsonDevice["Comm"]["Address"][addr].asInt());
                                        }
                                    }
                                }
                                else
                                {
                                    shDevice.vecAddress.clear();
                                }
                                //PosID
                                if ( !jsonDevice["PosID"].isNull()
                                    && jsonDevice["PosID"].isInt() )
                                {
                                    shDevice.iPosID = jsonDevice["PosID"].asInt();
                                }
                                else
                                {
                                    shDevice.iPosID = -1;
                                }
                                ////Point …Ë±∏‘⁄PosIDŒª÷√◊¯±Í
                                //if ( !jsonDevice["Point"].isNull()
                                //	&& jsonDevice["Point"].isArray()
                                //	&& 2 == jsonDevice["Point"].size() )
                                //{
                                //	shDevice.xPos = jsonDevice["Point"][0].asInt();
                                //	shDevice.yPos = jsonDevice["Point"][1].asInt();
                                //}
                                //else
                                //{
                                //	shDevice.xPos = -1;
                                //	shDevice.yPos = -1;
                                //}
                                //State
                                if ( !jsonDevice["State"].isNull()
                                    && jsonDevice["State"].isString() )
                                {
                                    shDevice.strState = jsonDevice["State"].asString();
                                }
                                else
                                {
                                    shDevice.strState = "";
                                }
                                //Range
                                if ( !jsonDevice["Range"].isNull()
                                    && jsonDevice["Range"].isInt() )
                                {
                                    shDevice.iRange = jsonDevice["Range"].asInt();
                                }
                                else
                                {
                                    shDevice.iRange = -1;
                                }
                                ////Type
                                //if ( !jsonDevice["Type"].isNull()
                                //	&& jsonDevice["Type"].isString() )
                                //{
                                //	shDevice.strType = jsonDevice["Type"].asString();
                                //}
                                //else
                                //{
                                //	shDevice.strType = "";
                                //}
                                
                                shScene.vecGroundHeat.push_back(shDevice);
                                shDevice.vecAddress.clear();
                            }
                        } //GroundHeat
                        
                        //ø’µ˜…Ë±∏¡–±Ì
                        if ( !jsonScene["AirCondition"].isNull()
                            && jsonScene["AirCondition"].isArray() )
                        {
                            Json::ArrayIndex devices = jsonScene["AirCondition"].size();
                            for(Json::ArrayIndex device=0;device<devices;device++)
                            {
                                Json::Value &jsonDevice = jsonConfig["AirCondition"][device];
                                Smarthome_AirCondition shDevice;
                                
                                //DeviceID
                                if ( !jsonDevice["DeviceID"].isNull()
                                    && jsonDevice["DeviceID"].isString() )
                                {
                                    shDevice.strDeviceId = jsonDevice["DeviceID"].asString();
                                }
                                else
                                {
                                    shDevice.strDeviceId = "";
                                }
                                //Name
                                if ( !jsonDevice["Name"].isNull()
                                    && jsonDevice["Name"].isString() )
                                {
                                    shDevice.strDeviceName = jsonDevice["Name"].asString();
                                }
                                else
                                {
                                    shDevice.strDeviceName = "";
                                }
                                //Brand
                                if ( !jsonDevice["Brand"].isNull()
                                    && jsonDevice["Brand"].isString() )
                                {
                                    shDevice.strBrand = jsonDevice["Brand"].asString();
                                }
                                else
                                {
                                    shDevice.strBrand = "";
                                }
                                //Comm ¥Æø⁄µÿ÷∑
                                if ( !jsonDevice["Comm"].isNull()
                                    && !jsonDevice["Comm"]["Address"].isNull()
                                    && jsonDevice["Comm"]["Address"].isArray() )
                                {
                                    for(Json::ArrayIndex addr=0;addr<jsonDevice["Comm"]["Address"].size();addr++)
                                    {
                                        if ( !jsonDevice["Comm"]["Address"][addr].isNull()
                                            && jsonDevice["Comm"]["Address"][addr].isInt() )
                                        {
                                            shDevice.vecAddress.push_back(jsonDevice["Comm"]["Address"][addr].asInt());
                                        }
                                    }
                                }
                                else
                                {
                                    shDevice.vecAddress.clear();
                                }
                                //PosID
                                if ( !jsonDevice["PosID"].isNull()
                                    && jsonDevice["PosID"].isInt() )
                                {
                                    shDevice.iPosID = jsonDevice["PosID"].asInt();
                                }
                                else
                                {
                                    shDevice.iPosID = -1;
                                }
                                //Point …Ë±∏‘⁄PosIDŒª÷√◊¯±Í
                                if ( !jsonDevice["Point"].isNull()
                                    && jsonDevice["Point"].isArray()
                                    && 2 == jsonDevice["Point"].size() )
                                {
                                    shDevice.xPos = jsonDevice["Point"][0].asInt();
                                    shDevice.yPos = jsonDevice["Point"][1].asInt();
                                }
                                else
                                {
                                    shDevice.xPos = -1;
                                    shDevice.yPos = -1;
                                }
                                //State
                                if ( !jsonDevice["State"].isNull()
                                    && jsonDevice["State"].isString() )
                                {
                                    shDevice.strState = jsonDevice["State"].asString();
                                }
                                else
                                {
                                    shDevice.strState = "";
                                }
                                //Range
                                if ( !jsonDevice["Range"].isNull()
                                    && jsonDevice["Range"].isInt() )
                                {
                                    shDevice.iRange = jsonDevice["Range"].asInt();
                                }
                                else
                                {
                                    shDevice.iRange = -1;
                                }
                                //Type
                                if ( !jsonDevice["Type"].isNull()
                                    && jsonDevice["Type"].isString() )
                                {
                                    shDevice.strType = jsonDevice["Type"].asString();
                                }
                                else
                                {
                                    shDevice.strType = "";
                                }
                                //Mode
                                if ( !jsonDevice["Mode"].isNull()
                                    && jsonDevice["Mode"].isString() )
                                {
                                    shDevice.strMode = jsonDevice["Mode"].asString();
                                }
                                else
                                {
                                    shDevice.strMode = "";
                                }
                                //WindMode
                                if ( !jsonDevice["WindMode"].isNull()
                                    && jsonDevice["WindMode"].isString() )
                                {
                                    shDevice.strWindMode = jsonDevice["WindMode"].asString();
                                }
                                else
                                {
                                    shDevice.strWindMode = "";
                                }
                                
                                shScene.vecAirCondition.push_back(shDevice);
                                shDevice.vecAddress.clear();
                            }
                        } //AirCondition
                        
                        //ÃÌº”µΩ≥°æ∞¡–±Ì
                        vecScenes.push_back(shScene);
                        //«Â¿Ìª∫≥Â
                        shScene.vecLight.clear();
                        shScene.vecCurtain.clear();
                        shScene.vecGroundHeat.clear();
                        shScene.vecAirCondition.clear();
                    }
                }
            }
        }
        else
        {
            ERROR_TRACE("SmartHomeManager.getconfig SceneMode exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    //…Ë÷√«Èæ∞ƒ£ Ω
    int CDvrClient::Set_SceneMode_Sync(int iCurrentId,std::vector<Smarthome_SceneInfo> &vecScenes,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //¥Ú∞¸∑øº‰–≈œ¢
        Json::Value jsonConfig;
        
        jsonConfig["CurrentProfileID"] = iCurrentId;
        for(int i=0;i<vecScenes.size();i++)
        {
            jsonConfig["Profiles"][i]["Brand"] = vecScenes[i].strBrand;
            jsonConfig["Profiles"][i]["Name"] = vecScenes[i].strName;
            
            //µ∆π‚¡–±Ì
            for(int j=0;j<vecScenes[i].vecLight.size();j++)
            {
                jsonConfig["Profiles"][i]["Light"][j]["DeviceID"] = vecScenes[i].vecLight[j].strDeviceId;
                jsonConfig["Profiles"][i]["Light"][j]["Name"] = vecScenes[i].vecLight[j].strDeviceName;
                jsonConfig["Profiles"][i]["Light"][j]["Brand"] = vecScenes[i].vecLight[j].strBrand;
                for(int k=0;k<vecScenes[i].vecLight[j].vecAddress.size();k++)
                {
                    jsonConfig["Profiles"][i]["Light"][j]["Comm"]["Address"][k] = vecScenes[i].vecLight[j].vecAddress[k];
                }
                jsonConfig["Profiles"][i]["Light"][j]["PosID"] = vecScenes[i].vecLight[j].iPosID;
                jsonConfig["Profiles"][i]["Light"][j]["Point"][0] = vecScenes[i].vecLight[j].xPos;
                jsonConfig["Profiles"][i]["Light"][j]["Point"][1] = vecScenes[i].vecLight[j].yPos;
                jsonConfig["Profiles"][i]["Light"][j]["State"] = vecScenes[i].vecLight[j].strState;
                jsonConfig["Profiles"][i]["Light"][j]["Range"] = vecScenes[i].vecLight[j].iRange;
                jsonConfig["Profiles"][i]["Light"][j]["Type"] = vecScenes[i].vecLight[j].strType;
            }
            
            //¥∞¡±¡–±Ì
            for(int j=0;j<vecScenes[i].vecCurtain.size();j++)
            {
                jsonConfig["Profiles"][i]["Curtain"][j]["DeviceID"] = vecScenes[i].vecCurtain[j].strDeviceId;
                jsonConfig["Profiles"][i]["Curtain"][j]["Name"] = vecScenes[i].vecCurtain[j].strDeviceName;
                jsonConfig["Profiles"][i]["Curtain"][j]["Brand"] = vecScenes[i].vecCurtain[j].strBrand;
                for(int k=0;k<vecScenes[i].vecCurtain[j].vecAddress.size();k++)
                {
                    jsonConfig["Profiles"][i]["Curtain"][j]["Comm"]["Address"][k] = vecScenes[i].vecCurtain[j].vecAddress[k];
                }
                jsonConfig["Profiles"][i]["Curtain"][j]["PosID"] = vecScenes[i].vecCurtain[j].iPosID;
                jsonConfig["Profiles"][i]["Curtain"][j]["Point"][0] = vecScenes[i].vecCurtain[j].xPos;
                jsonConfig["Profiles"][i]["Curtain"][j]["Point"][1] = vecScenes[i].vecCurtain[j].yPos;
                jsonConfig["Profiles"][i]["Curtain"][j]["State"] = vecScenes[i].vecCurtain[j].strState;
                jsonConfig["Profiles"][i]["Curtain"][j]["Range"] = vecScenes[i].vecCurtain[j].iRange;
                jsonConfig["Profiles"][i]["Curtain"][j]["Type"] = vecScenes[i].vecCurtain[j].strType;
            }
            
            
            //µÿ≈Ø¡–±Ì
            for(int j=0;j<vecScenes[i].vecGroundHeat.size();j++)
            {
                jsonConfig["Profiles"][i]["GroundHeat"][j]["DeviceID"] = vecScenes[i].vecGroundHeat[j].strDeviceId;
                jsonConfig["Profiles"][i]["GroundHeat"][j]["Name"] = vecScenes[i].vecGroundHeat[j].strDeviceName;
                jsonConfig["Profiles"][i]["GroundHeat"][j]["Brand"] = vecScenes[i].vecGroundHeat[j].strBrand;
                for(int k=0;k<vecScenes[i].vecGroundHeat[j].vecAddress.size();k++)
                {
                    jsonConfig["Profiles"][i]["GroundHeat"][j]["Comm"]["Address"][k] = vecScenes[i].vecGroundHeat[j].vecAddress[k];
                }
                jsonConfig["Profiles"][i]["GroundHeat"][j]["PosID"] = vecScenes[i].vecGroundHeat[j].iPosID;
                //jsonConfig["Profiles"][i]["GroundHeat"][j]["Point"][0] = vecScenes[i].vecGroundHeat[j].xPos;
                //jsonConfig["Profiles"][i]["GroundHeat"][j]["Point"][1] = vecScenes[i].vecGroundHeat[j].yPos;
                jsonConfig["Profiles"][i]["GroundHeat"][j]["State"] = vecScenes[i].vecGroundHeat[j].strState;
                jsonConfig["Profiles"][i]["GroundHeat"][j]["Range"] = vecScenes[i].vecGroundHeat[j].iRange;
                //jsonConfig["Profiles"][i]["GroundHeat"][j]["Type"] = vecScenes[i].vecGroundHeat[j].strType;
            }
            
            //ø’µ˜¡–±Ì
            for(int j=0;j<vecScenes[i].vecAirCondition.size();j++)
            {
                jsonConfig["Profiles"][i]["AirCondition"][j]["DeviceID"] = vecScenes[i].vecAirCondition[j].strDeviceId;
                jsonConfig["Profiles"][i]["AirCondition"][j]["Name"] = vecScenes[i].vecAirCondition[j].strDeviceName;
                jsonConfig["Profiles"][i]["AirCondition"][j]["Brand"] = vecScenes[i].vecAirCondition[j].strBrand;
                for(int k=0;k<vecScenes[i].vecAirCondition[j].vecAddress.size();k++)
                {
                    jsonConfig["Profiles"][i]["AirCondition"][j]["Comm"]["Address"][k] = vecScenes[i].vecAirCondition[j].vecAddress[k];
                }
                jsonConfig["Profiles"][i]["AirCondition"][j]["PosID"] = vecScenes[i].vecAirCondition[j].iPosID;
                jsonConfig["Profiles"][i]["AirCondition"][j]["Point"][0] = vecScenes[i].vecAirCondition[j].xPos;
                jsonConfig["Profiles"][i]["AirCondition"][j]["Point"][1] = vecScenes[i].vecAirCondition[j].yPos;
                jsonConfig["Profiles"][i]["AirCondition"][j]["State"] = vecScenes[i].vecAirCondition[j].strState;
                jsonConfig["Profiles"][i]["AirCondition"][j]["Range"] = vecScenes[i].vecAirCondition[j].iRange;
                jsonConfig["Profiles"][i]["AirCondition"][j]["Type"] = vecScenes[i].vecAirCondition[j].strType;
                jsonConfig["Profiles"][i]["AirCondition"][j]["Mode"] = vecScenes[i].vecAirCondition[j].strMode;
                jsonConfig["Profiles"][i]["AirCondition"][j]["WindMode"] = vecScenes[i].vecAirCondition[j].strWindMode;
            }
            
        }
        iRet = Dvip_setConfig(uiObjectId,"SceneMode",jsonConfig,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    
    ///µÿ≈Ø
    // ªÒ»°µÿ≈Ø≈‰÷√
    int CDvrClient::GroundHeat_getConfig_Sync(std::vector<Smarthome_GroundHeat> &vecDevices,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //ªÒ»°µÿ≈Ø≈‰÷√–≈œ¢
        Json::Value jsonConfig;
        iRet = Dvip_getConfig(uiObjectId,"GroundHeat",bRet,jsonConfig,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager.getConfig [GroundHeat] exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("configManager.getConfig [GroundHeat] exec OK.");
            iReturn = 0;
            //Ω‚Œˆƒ⁄»›
            if ( !jsonConfig["table"].isNull()
                && jsonConfig["table"].isArray() )
            {
                Json::ArrayIndex devices = jsonConfig["table"].size();
                for(Json::ArrayIndex device=0;device<devices;device++)
                {
                    Json::Value jsonDevice = jsonConfig["table"][device];
                    Smarthome_GroundHeat shDevice;
                    
                    //DeviceID
                    if ( !jsonDevice["DeviceID"].isNull()
                        && jsonDevice["DeviceID"].isString() )
                    {
                        shDevice.strDeviceId = jsonDevice["DeviceID"].asString();
                    }
                    else
                    {
                        shDevice.strDeviceId = "";
                    }
                    //Name
                    if ( !jsonDevice["Name"].isNull()
                        && jsonDevice["Name"].isString() )
                    {
                        shDevice.strDeviceName = jsonDevice["Name"].asString();
                    }
                    else
                    {
                        shDevice.strDeviceName = "";
                    }
                    //Brand
                    if ( !jsonDevice["Brand"].isNull()
                        && jsonDevice["Brand"].isString() )
                    {
                        shDevice.strBrand = jsonDevice["Brand"].asString();
                    }
                    else
                    {
                        shDevice.strBrand = "";
                    }
                    //Comm ¥Æø⁄µÿ÷∑
                    if ( !jsonDevice["Comm"].isNull()
                        && !jsonDevice["Comm"]["Address"].isNull()
                        && jsonDevice["Comm"]["Address"].isArray() )
                    {
                        for(Json::ArrayIndex addr=0;addr<jsonDevice["Comm"]["Address"].size();addr++)
                        {
                            if ( !jsonDevice["Comm"]["Address"][addr].isNull()
                                && jsonDevice["Comm"]["Address"][addr].isInt() )
                            {
                                shDevice.vecAddress.push_back(jsonDevice["Comm"]["Address"][addr].asInt());
                            }
                        }
                    }
                    else
                    {
                        shDevice.vecAddress.clear();
                    }
                    //PosID
                    if ( !jsonDevice["PosID"].isNull()
                        && jsonDevice["PosID"].isInt() )
                    {
                        shDevice.iPosID = jsonDevice["PosID"].asInt();
                    }
                    else
                    {
                        shDevice.iPosID = -1;
                    }
                    ////Point …Ë±∏‘⁄PosIDŒª÷√◊¯±Í
                    //if ( !jsonDevice["Point"].isNull()
                    //	&& jsonDevice["Point"].isArray()
                    //	&& 2 == jsonDevice["Point"].size() )
                    //{
                    //	shDevice.xPos = jsonDevice["Point"][0].asInt();
                    //	shDevice.yPos = jsonDevice["Point"][1].asInt();
                    //}
                    //else
                    //{
                    //	shDevice.xPos = -1;
                    //	shDevice.yPos = -1;
                    //}
                    //State
                    if ( !jsonDevice["State"].isNull()
                        && jsonDevice["State"].isString() )
                    {
                        shDevice.strState = jsonDevice["State"].asString();
                    }
                    else
                    {
                        shDevice.strState = "";
                    }
                    //Range
                    if ( !jsonDevice["Range"].isNull()
                        && jsonDevice["Range"].isInt() )
                    {
                        shDevice.iRange = jsonDevice["Range"].asInt();
                    }
                    else
                    {
                        shDevice.iRange = -1;
                    }
                    ////Type
                    //if ( !jsonDevice["Type"].isNull()
                    //	&& jsonDevice["Type"].isString() )
                    //{
                    //	shDevice.strType = jsonDevice["Type"].asString();
                    //}
                    //else
                    //{
                    //	shDevice.strType = "";
                    //}
                    
                    vecDevices.push_back(shDevice);
                    shDevice.vecAddress.clear();
                }
            }
            
        }
        else
        {
            ERROR_TRACE("configManager.getConfig [GroundHeat] exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
        }
        
        return iReturn;
    }
    // …Ë÷√µÿ≈Ø≈‰÷√
    int CDvrClient::GroundHeat_setConfig_Sync(std::vector<Smarthome_GroundHeat> &vecDevices,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //¥Ú∞¸∑øº‰–≈œ¢
        Json::Value jsonConfig;
        for(int i=0;i<vecDevices.size();i++)
        {
            jsonConfig[i]["DeviceID"] = vecDevices[i].strDeviceId;
            jsonConfig[i]["Name"] = vecDevices[i].strDeviceName;
            jsonConfig[i]["Brand"] = vecDevices[i].strBrand;
            for(int j=0;j<vecDevices[i].vecAddress.size();j++)
            {
                jsonConfig[i]["Comm"]["Address"][j] = vecDevices[i].vecAddress[j];
            }
            jsonConfig[i]["PosID"] = vecDevices[i].iPosID;
            //jsonConfig[i]["Point"][0] = vecDevices[i].xPos;
            //jsonConfig[i]["Point"][1] = vecDevices[i].yPos;
            jsonConfig[i]["State"] = vecDevices[i].strState;
            jsonConfig[i]["Range"] = vecDevices[i].iRange;
            //jsonConfig[i]["Type"] = vecDevices[i].strType;
        }
        iRet = Dvip_setConfig(uiObjectId,"GroundHeat",jsonConfig,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager.setConfig [GroundHeat] exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("configManager.setConfig [GroundHeat] exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("configManager.setConfig [GroundHeat] exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    // ø™
    int CDvrClient::GroundHeat_open_Sync(char *pszDeviceId,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("GroundHeat.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("GroundHeat instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("GroundHeat instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        //¥Úø™µÿ≈Ø
        iRet = Dvip_method_json_b_json("GroundHeat.open",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("GroundHeat.open exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("GroundHeat.open exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("GroundHeat.open exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("GroundHeat.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("GroundHeat instance failed.");
        }
        
        return iReturn;
    }
    // πÿ
    int CDvrClient::GroundHeat_close_Sync(char *pszDeviceId,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("GroundHeat.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("GroundHeat instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("GroundHeat instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        //πÿ±’µÿ≈Ø
        iRet = Dvip_method_json_b_json("GroundHeat.close",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("GroundHeat.close exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("GroundHeat.close exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("GroundHeat.close exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("GroundHeat.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("GroundHeat instance failed.");
        }
        
        return iReturn;
    }
    // …Ë∂®µÿ≈ØŒ¬∂»
    int CDvrClient::GroundHeat_setTemperature_Sync(char *pszDeviceId,int iTemperture,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("GroundHeat.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("GroundHeat instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("GroundHeat instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["temperature"] = iTemperture;
        //…Ë∂®µÿ≈ØŒ¬∂»
        iRet = Dvip_method_json_b_json("GroundHeat.setTemperature",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("GroundHeat.setTemperature exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("GroundHeat.setTemperature exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("GroundHeat.setTemperature exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("GroundHeat.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("GroundHeat instance failed.");
        }
        
        return iReturn;
    }
    // µ˜Ω⁄µÿ≈ØŒ¬∂»
    int CDvrClient::GroundHeat_adjustTemperature_Sync(char *pszDeviceId,int iScale,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("GroundHeat.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("GroundHeat instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("GroundHeat instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Scale"] = iScale;
        //µ˜Ω⁄µÿ≈ØŒ¬∂»
        iRet = Dvip_method_json_b_json("GroundHeat.adjustTemperature",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("GroundHeat.adjustTemperature exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("GroundHeat.adjustTemperature exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("GroundHeat.adjustTemperature exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("GroundHeat.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("GroundHeat instance failed.");
        }
        
        return iReturn;
    }
    // ªÒ»°µÿ≈Ø◊¥Ã¨
    int CDvrClient::GroundHeat_getState_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iTemperture,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("GroundHeat.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("GroundHeat instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("GroundHeat instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        //ªÒ»°µÿ≈Ø◊¥Ã¨
        iRet = Dvip_method_json_b_json("GroundHeat.getState",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("GroundHeat.getState exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("GroundHeat.getState exec OK.");
            if ( jsonOutParams.isNull() || jsonOutParams["State"].isNull() )
            {
                ERROR_TRACE("GroundHeat.getState exec failed:no state info.");
                iReturn = -1;
            }
            else
            {
                Json::Value jsState = jsonOutParams["State"];
                if ( !jsState["Online"].isNull()
                    && jsState["Online"].isBool()
                    )
                {
                    bIsOnline = jsState["Online"].asBool();
                }
                else
                {
                    WARN_TRACE("no Online param or invalid");
                    bIsOnline = false;
                }
                if ( !jsState["On"].isNull()
                    && jsState["On"].isBool()
                    )
                {
                    bIsOn = jsonOutParams["On"].asBool();
                }
                else
                {
                    WARN_TRACE("no On param or invalid");
                    bIsOn = false;
                }
                if ( !jsState["Temperature"].isNull()
                    && jsState["Temperature"].isInt()
                    )
                {
                    iTemperture = jsState["Temperature"].asInt();
                }
                else
                {
                    WARN_TRACE("no Temperature param or invalid");
                    iTemperture = -1;
                }
                
            }
            
            
            
            //if ( !jsonOutParams.isNull() )
            //{
            //	if ( !jsonOutParams["Online"].isNull()
            //		&& jsonOutParams["Online"].asBool()
            //		)
            //	{
            //		bIsOnline = jsonOutParams["Online"].asBool();
            //	}
            //	else
            //	{
            //		WARN_TRACE("no Online param or invalid");
            //		bIsOnline = false;
            //	}
            //	if ( !jsonOutParams["On"].isNull()
            //		&& jsonOutParams["On"].asBool()
            //		)
            //	{
            //		bIsOn = jsonOutParams["On"].asBool();
            //	}
            //	else
            //	{
            //		WARN_TRACE("no On param or invalid");
            //		bIsOn = false;
            //	}
            //	if ( !jsonOutParams["Temperature"].isNull()
            //		&& jsonOutParams["Temperature"].asInt()
            //		)
            //	{
            //		iTemperture = jsonOutParams["Temperature"].asInt();
            //	}
            //	else
            //	{
            //		WARN_TRACE("no Temperature param or invalid");
            //		iTemperture = -1;
            //	}
            //}
            //iReturn = 0;
        }
        else
        {
            ERROR_TRACE("GroundHeat.getState exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("GroundHeat.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("GroundHeat instance failed.");
        }
        
        return iReturn;
    }
    
    //∂©‘ƒ
    int CDvrClient::Subscrible_Sync(int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        unsigned int uiSID = 0;
        bool bNeedDestroy = false;
        
        if ( m_bHasSubscrible )
        {
            //“—æ≠∂©‘ƒ
            WARN_TRACE("have subscribled.");
            iReturn = 0;
            return iReturn;
        }
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("eventManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("eventManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("eventManager instance from server failed.objectid=0");
            return -1;
        }
        
        //¥Ú∞¸∑øº‰–≈œ¢
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["codes"][0] = "DeviceState";
        jsonInParams["codes"][1] = "AlarmLocal";
        jsonInParams["codes"][2] = "ArmModeChange";
        //jsonInParams["codes"][0] = "*";
        
        //attach
        iRet = Dvip_method_json_b_json("eventManager.attach",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
            bNeedDestroy = true;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            if ( !jsonOutParams.isNull()
                && !jsonOutParams["SID"].isNull()
                )
            {
                uiSID = jsonOutParams["SID"].asUInt();
                m_uiEventObjectId = uiObjectId;
                m_uiSid = uiSID;
                m_uiSubscribeReqId = iRet;
                m_bHasSubscrible = true;
                iReturn = 0;
            }
            else
            {
                ERROR_TRACE("response no SID");
                bNeedDestroy = true;
                iReturn = -1;
            }
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            bNeedDestroy = true;
            iReturn = -1;
        }
        
        if ( bNeedDestroy )
        {
            //–Ë“™ Õ∑≈ µ¿˝  Õ∑≈ µ¿˝
            iRet = Dvip_destroy("eventManager.destroy",m_uiEventObjectId,iTimeout);
            if ( 0 != iRet )
            {
                ERROR_TRACE("eventManager destroy failed.");
            }
        }
        
        return iReturn;
    }
    //»°œ˚∂©‘ƒ
    int CDvrClient::Unsubscrible_Sync(int iTimeout)
    {
        int iRet = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        if ( !m_bHasSubscrible )
        {
            ERROR_TRACE("not subscrible,no need cancel.");
            return -1;
        }
        //¥Ú∞¸∑øº‰–≈œ¢
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["codes"][0] = "DeviceState";
        jsonInParams["SID"] = m_uiSid;
        
        //detach
        iRet = Dvip_method_json_b_json("eventManager.detach",m_uiEventObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("eventManager.destroy",m_uiEventObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("eventManager destroy failed.");
            //return -1;
        }
        
        m_bHasSubscrible = false;
        m_uiEventObjectId = 0;
        m_uiSid = 0;
        m_uiSubscribeReqId = 0;
        
        return iReturn;
    }
    
    //  µ ±…œ¥´ ˝æ›£≠Õº∆¨
    int CDvrClient::RealLoadPicture(int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        bool bNeedDestroy = false;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("snapManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("snapManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("snapManager instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        
        //attach
        iRet = Dvip_method_json_b_json("snapManager.attachFileProc",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
            bNeedDestroy = true;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            m_uiSnapObjectId = uiObjectId;
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            bNeedDestroy = true;
            iReturn = -1;
        }
        
        if ( bNeedDestroy )
        {
            //–Ë“™ Õ∑≈ µ¿˝  Õ∑≈ µ¿˝
            iRet = Dvip_destroy("snapManager.destroy",m_uiSnapObjectId,iTimeout);
            if ( 0 != iRet )
            {
                ERROR_TRACE("snapManager destroy failed.");
            }
        }
        
        return iReturn;
    }
    
    // Õ£÷π…œ¥´ ˝æ›£≠Õº∆¨
    int CDvrClient::StopLoadPic(int iTimeout)
    {
        int iRet = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        if ( m_uiSnapObjectId == 0 )
        {
            ERROR_TRACE("not need StopLoadPic.");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        
        //detach
        iRet = Dvip_method_json_b_json("snapManager.detachFileProc",m_uiSnapObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("snapManager.destroy",m_uiSnapObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("snapManager destroy failed.");
            //return -1;
        }
        
        m_uiSnapObjectId = 0;
        
        return iReturn;
    }
    
    // ◊•Õº«Î«Û
    int CDvrClient::SnapPicture(char *pszDeviceId,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        if ( m_uiSnapObjectId == 0 )
        {
            ERROR_TRACE("not RealLoadPic, SnapPicture failed.");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["DeviceID"]=pszDeviceId;
        iRet = Dvip_method_json_b_json("snapManager.snapshot",m_uiSnapObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("snapManager.snapshot exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("snapManager.snapshot exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("snapManager.snapshot exec failed.");
            iReturn = -1;
        }
        
        return iReturn;
    }
    
    /// ø’µ˜
    // ªÒ»°ø’µ˜≈‰÷√
    int CDvrClient::AirCondition_getConfig_Sync(std::vector<Smarthome_AirCondition> &vecDevices,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //ªÒ»°µÿ≈Ø≈‰÷√–≈œ¢
        Json::Value jsonConfig;
        iRet = Dvip_getConfig(uiObjectId,"AirCondition",bRet,jsonConfig,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager.getConfig [AirCondition] exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("configManager.getConfig [AirCondition] exec OK.");
            iReturn = 0;
            //Ω‚Œˆƒ⁄»›
            if ( !jsonConfig["table"].isNull()
                && jsonConfig["table"].isArray() )
            {
                Json::ArrayIndex devices = jsonConfig["table"].size();
                for(Json::ArrayIndex device=0;device<devices;device++)
                {
                    Json::Value jsonDevice = jsonConfig["table"][device];
                    Smarthome_AirCondition shDevice;
                    
                    //DeviceID
                    if ( !jsonDevice["DeviceID"].isNull()
                        && jsonDevice["DeviceID"].isString() )
                    {
                        shDevice.strDeviceId = jsonDevice["DeviceID"].asString();
                    }
                    else
                    {
                        shDevice.strDeviceId = "";
                    }
                    //Name
                    if ( !jsonDevice["Name"].isNull()
                        && jsonDevice["Name"].isString() )
                    {
                        shDevice.strDeviceName = jsonDevice["Name"].asString();
                    }
                    else
                    {
                        shDevice.strDeviceName = "";
                    }
                    //Brand
                    if ( !jsonDevice["Brand"].isNull()
                        && jsonDevice["Brand"].isString() )
                    {
                        shDevice.strBrand = jsonDevice["Brand"].asString();
                    }
                    else
                    {
                        shDevice.strBrand = "";
                    }
                    //Comm ¥Æø⁄µÿ÷∑
                    if ( !jsonDevice["Comm"].isNull()
                        && !jsonDevice["Comm"]["Address"].isNull()
                        && jsonDevice["Comm"]["Address"].isArray() )
                    {
                        for(Json::ArrayIndex addr=0;addr<jsonDevice["Comm"]["Address"].size();addr++)
                        {
                            if ( !jsonDevice["Comm"]["Address"][addr].isNull()
                                && jsonDevice["Comm"]["Address"][addr].isInt() )
                            {
                                shDevice.vecAddress.push_back(jsonDevice["Comm"]["Address"][addr].asInt());
                            }
                        }
                    }
                    else
                    {
                        shDevice.vecAddress.clear();
                    }
                    //PosID
                    if ( !jsonDevice["PosID"].isNull()
                        && jsonDevice["PosID"].isInt() )
                    {
                        shDevice.iPosID = jsonDevice["PosID"].asInt();
                    }
                    else
                    {
                        shDevice.iPosID = -1;
                    }
                    //Point …Ë±∏‘⁄PosIDŒª÷√◊¯±Í
                    if ( !jsonDevice["Point"].isNull()
                        && jsonDevice["Point"].isArray()
                        && 2 == jsonDevice["Point"].size() )
                    {
                        shDevice.xPos = jsonDevice["Point"][0].asInt();
                        shDevice.yPos = jsonDevice["Point"][1].asInt();
                    }
                    else
                    {
                        shDevice.xPos = -1;
                        shDevice.yPos = -1;
                    }
                    //State
                    if ( !jsonDevice["State"].isNull()
                        && jsonDevice["State"].isString() )
                    {
                        shDevice.strState = jsonDevice["State"].asString();
                    }
                    else
                    {
                        shDevice.strState = "";
                    }
                    //Range
                    if ( !jsonDevice["Range"].isNull()
                        && jsonDevice["Range"].isInt() )
                    {
                        shDevice.iRange = jsonDevice["Range"].asInt();
                    }
                    else
                    {
                        shDevice.iRange = -1;
                    }
                    //Type
                    if ( !jsonDevice["Type"].isNull()
                        && jsonDevice["Type"].isString() )
                    {
                        shDevice.strType = jsonDevice["Type"].asString();
                    }
                    else
                    {
                        shDevice.strType = "";
                    }
                    //Mode
                    if ( !jsonDevice["Mode"].isNull()
                        && jsonDevice["Mode"].isString() )
                    {
                        shDevice.strMode = jsonDevice["Mode"].asString();
                    }
                    else
                    {
                        shDevice.strMode = "";
                    }
                    //WindMode
                    if ( !jsonDevice["WindMode"].isNull()
                        && jsonDevice["WindMode"].isString() )
                    {
                        shDevice.strWindMode = jsonDevice["WindMode"].asString();
                    }
                    else
                    {
                        shDevice.strWindMode = "";
                    }
                    vecDevices.push_back(shDevice);
                    shDevice.vecAddress.clear();
                }
            }
            
        }
        else
        {
            ERROR_TRACE("configManager.getConfig [AirCondition] exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
        }
        
        return iReturn;
    }
    // …Ë÷√ø’µ˜≈‰÷√
    int CDvrClient::AirCondition_setConfig_Sync(std::vector<Smarthome_AirCondition> &vecDevices,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //¥Ú∞¸∑øº‰–≈œ¢
        Json::Value jsonConfig;
        for(int i=0;i<vecDevices.size();i++)
        {
            jsonConfig[i]["DeviceID"] = vecDevices[i].strDeviceId;
            jsonConfig[i]["Name"] = vecDevices[i].strDeviceName;
            jsonConfig[i]["Brand"] = vecDevices[i].strBrand;
            for(int j=0;j<vecDevices[i].vecAddress.size();j++)
            {
                jsonConfig[i]["Comm"]["Address"][j] = vecDevices[i].vecAddress[j];
            }
            jsonConfig[i]["PosID"] = vecDevices[i].iPosID;
            jsonConfig[i]["Point"][0] = vecDevices[i].xPos;
            jsonConfig[i]["Point"][1] = vecDevices[i].yPos;
            jsonConfig[i]["State"] = vecDevices[i].strState;
            jsonConfig[i]["Range"] = vecDevices[i].iRange;
            jsonConfig[i]["Type"] = vecDevices[i].strType;
            jsonConfig[i]["Mode"] = vecDevices[i].strMode;
            jsonConfig[i]["WindMode"] = vecDevices[i].strWindMode;
        }
        iRet = Dvip_setConfig(uiObjectId,"AirCondition",jsonConfig,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager.setConfig [AirCondition] exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("configManager.setConfig [AirCondition] exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("configManager.setConfig [AirCondition] exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    // ø™
    int CDvrClient::AirCondition_open_Sync(char *pszDeviceId,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("AirCondition.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("AirCondition instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        //ø™
        iRet = Dvip_method_json_b_json("AirCondition.open",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("AirCondition.open exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("AirCondition.open exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("AirCondition.open exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("AirCondition.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
        }
        
        return iReturn;
    }
    // πÿ
    int CDvrClient::AirCondition_close_Sync(char *pszDeviceId,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("AirCondition.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("AirCondition instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        //πÿ
        iRet = Dvip_method_json_b_json("AirCondition.close",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("AirCondition.close exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("AirCondition.close exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("AirCondition.close exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("AirCondition.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
        }
        
        return iReturn;
    }
    // …Ë∂®ø’µ˜Œ¬∂»
    int CDvrClient::AirCondition_setTemperature_Sync(char *pszDeviceId,int iTemperture,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("AirCondition.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("AirCondition instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["temperature"] = iTemperture;
        //…Ë∂®ø’µ˜Œ¬∂»
        iRet = Dvip_method_json_b_json("AirCondition.setTemperature",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("AirCondition.setTemperature exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("AirCondition.setTemperature exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("AirCondition.setTemperature exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("AirCondition.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
        }
        
        return iReturn;
    }
    // µ˜Ω⁄Œ¬∂»
    int CDvrClient::AirCondition_adjustTemperature_Sync(char *pszDeviceId,int iScale,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("AirCondition.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("AirCondition instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Scale"] = iScale;
        //µ˜Ω⁄Œ¬∂»
        iRet = Dvip_method_json_b_json("AirCondition.adjustTemperature",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("AirCondition.adjustTemperature exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("AirCondition.adjustTemperature exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("AirCondition.adjustTemperature exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("AirCondition.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
        }
        
        return iReturn;
    }
    // …Ë÷√π§◊˜ƒ£ Ω
    int CDvrClient::AirCondition_setMode_Sync(char *pszDeviceId,std::string strMode,int iTemperture,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("AirCondition.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("AirCondition instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Mode"] = strMode;
        jsonInParams["Temperature"] = iTemperture;
        //…Ë÷√π§◊˜ƒ£ Ω
        iRet = Dvip_method_json_b_json("AirCondition.setMode",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("AirCondition.setMode exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("AirCondition.setMode exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("AirCondition.setMode exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("AirCondition.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
        }
        
        return iReturn;
    }
    // …Ë÷√ÀÕ∑Áƒ£ Ω
    int CDvrClient::AirCondition_setWindMode_Sync(char *pszDeviceId,std::string strWindMode,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("AirCondition.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("AirCondition instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["Mode"] = strWindMode;
        //…Ë÷√ÀÕ∑Áƒ£ Ω
        iRet = Dvip_method_json_b_json("AirCondition.setWindMode",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("AirCondition.setWindMode exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("AirCondition.setWindMode exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("AirCondition.setWindMode exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("AirCondition.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
        }
        
        return iReturn;
    }
    
    // “ªº¸øÿ÷∆
    int CDvrClient::AirCondition_oneKeyControl(char *pszDeviceId,bool bIsOn,std::string strMode,
                                               int iTemperature,std::string strWindMode,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("AirCondition.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("AirCondition instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["On"] = bIsOn;
        jsonInParams["Mode"] = strMode;
        jsonInParams["Temperature"] = iTemperature;
        jsonInParams["WindMode"] = strWindMode;
        
        iRet = Dvip_method_json_b_json("AirCondition.oneKeyControl",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("AirCondition.oneKeyControl exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("AirCondition.oneKeyControl exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("AirCondition.oneKeyControl exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("AirCondition.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
        }
        
        return iReturn;
    }
    
    // »°µ√ø’µ˜◊¥Ã¨
    int CDvrClient::AirCondition_getState_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iTemperture,std::string &strMode,std::string &strWindMode,float &fActTemperture,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("AirCondition.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("AirCondition instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        //»°µ√ø’µ˜◊¥Ã¨
        iRet = Dvip_method_json_b_json("AirCondition.getState",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("AirCondition.getState exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("AirCondition.getState exec OK.");
            if ( jsonOutParams.isNull() || jsonOutParams["State"].isNull() )
            {
                ERROR_TRACE("AirCondition.getState exec failed.");
                iReturn = -1;
            }
            else
            {
                Json::Value jsState = jsonOutParams["State"];
                if ( !jsState["Online"].isNull()
                    && jsState["Online"].isBool()
                    )
                {
                    bIsOnline = jsState["Online"].asBool();
                }
                else
                {
                    WARN_TRACE("no Online param or invalid");
                    bIsOnline = false;
                }
                if ( !jsState["On"].isNull()
                    && jsState["On"].isBool()
                    )
                {
                    bIsOn = jsState["On"].asBool();
                }
                else
                {
                    WARN_TRACE("no On param or invalid");
                    bIsOn = false;
                }
                if ( !jsState["Temperature"].isNull()
                    && jsState["Temperature"].isInt()
                    )
                {
                    iTemperture = jsState["Temperature"].asInt();
                }
                else
                {
                    WARN_TRACE("no Temperature param or invalid");
                    iTemperture = 0;
                }
                if ( !jsState["Mode"].isNull()
                    && jsState["Mode"].isString()
                    )
                {
                    strMode = jsState["Mode"].asString();
                }
                else
                {
                    WARN_TRACE("no Mode param or invalid");
                    strMode = "";
                }
                if ( !jsState["WindMode"].isNull()
                    && jsState["WindMode"].isString()
                    )
                {
                    strWindMode = jsState["WindMode"].asString();
                }
                else
                {
                    WARN_TRACE("no WindMode param or invalid");
                    strWindMode = "";
                }
                if ( !jsState["ActualTemperature"].isNull()
                    && jsState["ActualTemperature"].isDouble()
                    )
                {
                    fActTemperture = jsState["ActualTemperature"].asDouble();
                }
                else
                {
                    WARN_TRACE("no ActualTemperature param or invalid");
                    fActTemperture = 0;
                }
                
            }
            //if ( !jsonOutParams.isNull() )
            //{
            //	if ( !jsonOutParams["Online"].isNull()
            //		&& jsonOutParams["Online"].asBool()
            //		)
            //	{
            //		bIsOnline = jsonOutParams["Online"].asBool();
            //	}
            //	else
            //	{
            //		WARN_TRACE("no Online param or invalid");
            //		bIsOnline = false;
            //	}
            //	if ( !jsonOutParams["On"].isNull()
            //		&& jsonOutParams["On"].asBool()
            //		)
            //	{
            //		bIsOn = jsonOutParams["On"].asBool();
            //	}
            //	else
            //	{
            //		WARN_TRACE("no On param or invalid");
            //		bIsOn = false;
            //	}
            //	if ( !jsonOutParams["Temperature"].isNull()
            //		&& jsonOutParams["Temperature"].asInt()
            //		)
            //	{
            //		iTemperture = jsonOutParams["Temperature"].asInt();
            //	}
            //	else
            //	{
            //		WARN_TRACE("no Temperature param or invalid");
            //		iTemperture = -1;
            //	}
            //	if ( !jsonOutParams["Mode"].isNull()
            //		&& jsonOutParams["Mode"].isString()
            //		)
            //	{
            //		strMode = jsonOutParams["Mode"].asString();
            //	}
            //	else
            //	{
            //		WARN_TRACE("no Mode param or invalid");
            //		strMode = "";
            //	}
            //	if ( !jsonOutParams["WindMode"].isNull()
            //		&& jsonOutParams["WindMode"].isString()
            //		)
            //	{
            //		strWindMode = jsonOutParams["WindMode"].asString();
            //	}
            //	else
            //	{
            //		WARN_TRACE("no WindMode param or invalid");
            //		strWindMode = "";
            //	}
            //}
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("AirCondition.getState exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("AirCondition.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("AirCondition instance failed.");
        }
        
        return iReturn;
    }
    
    //÷«ƒ‹µÁ±Ì
    // ªÒ»°÷«ƒ‹µÁ±Ì≈‰÷√
    int CDvrClient::IntelligentAmmeter_getConfig_Sync(std::vector<Smarthome_IntelligentAmmeter> &vecDevices
                                                      ,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //ªÒ»°µÿ≈Ø≈‰÷√–≈œ¢
        Json::Value jsonConfig;
        iRet = Dvip_getConfig(uiObjectId,"IntelligentAmmeter",bRet,jsonConfig,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager.getConfig [IntelligentAmmeter] exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("configManager.getConfig [IntelligentAmmeter] exec OK.");
            iReturn = 0;
            //Ω‚Œˆƒ⁄»›
            if ( !jsonConfig["table"].isNull()
                && jsonConfig["table"].isArray() )
            {
                Json::ArrayIndex devices = jsonConfig["table"].size();
                for(Json::ArrayIndex device=0;device<devices;device++)
                {
                    Json::Value jsonDevice = jsonConfig["table"][device];
                    Smarthome_IntelligentAmmeter shDevice;
                    
                    //DeviceID
                    if ( !jsonDevice["DeviceID"].isNull()
                        && jsonDevice["DeviceID"].isString() )
                    {
                        shDevice.strDeviceId = jsonDevice["DeviceID"].asString();
                    }
                    else
                    {
                        shDevice.strDeviceId = "";
                    }
                    //Name
                    if ( !jsonDevice["Name"].isNull()
                        && jsonDevice["Name"].isString() )
                    {
                        shDevice.strDeviceName = jsonDevice["Name"].asString();
                    }
                    else
                    {
                        shDevice.strDeviceName = "";
                    }
                    //Brand
                    if ( !jsonDevice["Brand"].isNull()
                        && jsonDevice["Brand"].isString() )
                    {
                        shDevice.strBrand = jsonDevice["Brand"].asString();
                    }
                    else
                    {
                        shDevice.strBrand = "";
                    }
                    //Comm ¥Æø⁄µÿ÷∑
                    if ( !jsonDevice["Comm"].isNull()
                        && !jsonDevice["Comm"]["Address"].isNull()
                        && jsonDevice["Comm"]["Address"].isArray() )
                    {
                        for(Json::ArrayIndex addr=0;addr<jsonDevice["Comm"]["Address"].size();addr++)
                        {
                            if ( !jsonDevice["Comm"]["Address"][addr].isNull()
                                && jsonDevice["Comm"]["Address"][addr].isInt() )
                            {
                                shDevice.vecAddress.push_back(jsonDevice["Comm"]["Address"][addr].asInt());
                            }
                        }					
                    }
                    else
                    {
                        shDevice.vecAddress.clear();
                    }
                    //PosID
                    if ( !jsonDevice["PosID"].isNull()
                        && jsonDevice["PosID"].isInt() )
                    {
                        shDevice.iPosID = jsonDevice["PosID"].asInt();
                    }
                    else
                    {
                        shDevice.iPosID = -1;
                    }				
                    //Point …Ë±∏‘⁄PosIDŒª÷√◊¯±Í
                    if ( !jsonDevice["Point"].isNull()
                        && jsonDevice["Point"].isArray()
                        && 2 == jsonDevice["Point"].size() )
                    {
                        shDevice.xPos = jsonDevice["Point"][0].asInt();
                        shDevice.yPos = jsonDevice["Point"][1].asInt();
                    }
                    else
                    {
                        shDevice.xPos = -1;
                        shDevice.yPos = -1;
                    }
                    //Type
                    if ( !jsonDevice["Type"].isNull()
                        && jsonDevice["Type"].isString() )
                    {
                        shDevice.strType = jsonDevice["Type"].asString();
                    }
                    else
                    {
                        shDevice.strType = "";
                    }
                    vecDevices.push_back(shDevice);
                    shDevice.vecAddress.clear();
                }
            }
            
        }
        else
        {
            ERROR_TRACE("configManager.getConfig [IntelligentAmmeter] exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
        }
        
        return iReturn;
    }
    // …Ë÷√÷«ƒ‹µÁ±Ì≈‰÷√
    int CDvrClient::IntelligentAmmeter_setConfig_Sync(std::vector<Smarthome_IntelligentAmmeter> &vecDevices
                                                      ,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //¥Ú∞¸∑øº‰–≈œ¢
        Json::Value jsonConfig;
        for(int i=0;i<vecDevices.size();i++)
        {
            jsonConfig[i]["DeviceID"] = vecDevices[i].strDeviceId;
            jsonConfig[i]["Name"] = vecDevices[i].strDeviceName;
            jsonConfig[i]["Brand"] = vecDevices[i].strBrand;
            for(int j=0;j<vecDevices[i].vecAddress.size();j++)
            {
                jsonConfig[i]["Comm"]["Address"][j] = vecDevices[i].vecAddress[j];
            }
            jsonConfig[i]["PosID"] = vecDevices[i].iPosID;
            jsonConfig[i]["Point"][0] = vecDevices[i].xPos;
            jsonConfig[i]["Point"][1] = vecDevices[i].yPos;
            jsonConfig[i]["Type"] = vecDevices[i].strType;
        }
        iRet = Dvip_setConfig(uiObjectId,"IntelligentAmmeter",jsonConfig,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager.setConfig [IntelligentAmmeter] exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("configManager.setConfig [IntelligentAmmeter] exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("configManager.setConfig [IntelligentAmmeter] exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    // ªÒ»°÷«ƒ‹µÁ±Ì…Ë±∏ª˘±æ–≈œ¢
    int CDvrClient::IntelligentAmmeter_getBasicInfo(char *pszDeviceId
                                                    ,IntelligentAmmeter_BasicInfo &stInfo
                                                    ,int iTimeout
                                                    )
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("IntelligentAmmeter.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("IntelligentAmmeter instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("IntelligentAmmeter instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        //»°µ√ø’µ˜◊¥Ã¨
        iRet = Dvip_method_json_b_json("IntelligentAmmeter.getBasicInfo",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("IntelligentAmmeter.getBasicInfo exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            //Ω‚Œˆƒ⁄»›
            INFO_TRACE("IntelligentAmmeter.getBasicInfo exec OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("IntelligentAmmeter.getBasicInfo exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("IntelligentAmmeter.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("IntelligentAmmeter.destroy failed.");
        }
        
        return iReturn;
    }
    // ªÒ»°µÁ±Ì ˝æ›
    int CDvrClient::IntelligentAmmeter_readMeter(char *pszDeviceId
                                                 ,PositiveEnergy &stPositive
                                                 ,InstancePower &stInst
                                                 ,int iTimeout
                                                 )
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("IntelligentAmmeter.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("IntelligentAmmeter instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("IntelligentAmmeter instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        //»°µ√ø’µ˜◊¥Ã¨
        iRet = Dvip_method_json_b_json("IntelligentAmmeter.readMeter",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("IntelligentAmmeter.readMeter exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            //Ω‚Œˆƒ⁄»›
            INFO_TRACE("IntelligentAmmeter.readMeter exec OK.");
            
            if ( !jsonOutParams["PositiveEnergys"].isNull() && jsonOutParams["PositiveEnergys"].isObject() )
            {
                //’˝œÚ”–π¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["PositiveActiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["PositiveActiveEnergy"].isInt()
                    )
                {
                    stPositive.iTotalActive = jsonOutParams["PositiveEnergys"]["PositiveActiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iTotalActive = 0;
                }
                //º‚ ±∂Œ’˝œÚ”–π¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["SharpPositiveActiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["SharpPositiveActiveEnergy"].isInt()
                    )
                {
                    stPositive.iSharpActive = jsonOutParams["PositiveEnergys"]["SharpPositiveActiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iSharpActive = 0;
                }
                //∑Â ±∂Œ’˝œÚ”–π¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["PeakPositiveActiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["PeakPositiveActiveEnergy"].isInt()
                    )
                {
                    stPositive.iPeakActive = jsonOutParams["PositiveEnergys"]["PeakPositiveActiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iPeakActive = 0;
                }
                //∆Ω ±∂Œ’˝œÚ”–π¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["ShoulderPositiveActiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["ShoulderPositiveActiveEnergy"].isInt()
                    )
                {
                    stPositive.iShoulderActive = jsonOutParams["PositiveEnergys"]["ShoulderPositiveActiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iShoulderActive = 0;
                }
                
                //π» ±∂Œ’˝œÚ”–π¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["OffPeakPositiveActiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["OffPeakPositiveActiveEnergy"].isInt()
                    )
                {
                    stPositive.iOffPeakActive = jsonOutParams["PositiveEnergys"]["OffPeakPositiveActiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iOffPeakActive = 0;
                }
                
                
                //’˝œÚŒﬁπ¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["PositiveReactiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["PositiveReactiveEnergy"].isInt()
                    )
                {
                    stPositive.iTotalReactive = jsonOutParams["PositiveEnergys"]["PositiveReactiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iTotalReactive = 0;
                }
                //º‚ ±∂Œ’˝œÚŒﬁπ¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["SharpPositiveReactiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["SharpPositiveReactiveEnergy"].isInt()
                    )
                {
                    stPositive.iSharpReactive = jsonOutParams["PositiveEnergys"]["SharpPositiveReactiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iSharpReactive = 0;
                }
                //∑Â ±∂Œ’˝œÚŒﬁπ¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["PeakPositiveReactiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["PeakPositiveReactiveEnergy"].isInt()
                    )
                {
                    stPositive.iPeakReactive = jsonOutParams["PositiveEnergys"]["PeakPositiveReactiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iPeakReactive = 0;
                }
                //∆Ω ±∂Œ’˝œÚŒﬁπ¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["ShoulderPositiveReactiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["ShoulderPositiveReactiveEnergy"].isInt()
                    )
                {
                    stPositive.iShoulderReactive = jsonOutParams["PositiveEnergys"]["ShoulderPositiveReactiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iShoulderReactive = 0;
                }
                //π» ±∂Œ’˝œÚŒﬁπ¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["OffPeakPositiveReactiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["OffPeakPositiveReactiveEnergy"].isInt()
                    )
                {
                    stPositive.iOffPeakReactive = jsonOutParams["PositiveEnergys"]["OffPeakPositiveReactiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iOffPeakReactive = 0;
                }
                
            }
            else
            {
                WARN_TRACE("no PositiveEnergys node.");
                stPositive.Init();
            }
            
            if ( !jsonOutParams["InstantPower"].isNull() && jsonOutParams["InstantPower"].isObject() )
            {
                //”–”√π¶¬ 
                if ( !jsonOutParams["InstantPower"]["ActivePower"].isNull()
                    && jsonOutParams["InstantPower"]["ActivePower"].isInt()
                    )
                {
                    stInst.iActivePower = jsonOutParams["InstantPower"]["ActivePower"].asInt();
                    
                }
                else
                {
                    stInst.iActivePower = 0;
                }
                //Œﬁ”√π¶¬ 
                if ( !jsonOutParams["InstantPower"]["ReactivePower"].isNull()
                    && jsonOutParams["InstantPower"]["ReactivePower"].isInt()
                    )
                {
                    stInst.iReactivePower = jsonOutParams["InstantPower"]["ReactivePower"].asInt();
                    
                }
                else
                {
                    stInst.iReactivePower = 0;
                }
            }
            else
            {
                WARN_TRACE("no InstantPower node.");
                stInst.iActivePower = 0;
                stInst.iReactivePower = 0;
            }
            
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("IntelligentAmmeter.readMeter exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("IntelligentAmmeter.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("IntelligentAmmeter.destroy failed.");
        }
        
        return iReturn;
    }
    // ªÒ»°µÁ±Ì…œ¥ŒΩ·À„ ˝æ›
    int CDvrClient::IntelligentAmmeter_readMeterPrev(char *pszDeviceId
                                                     ,int &iTime
                                                     ,PositiveEnergy &stPositive
                                                     ,int iTimeout
                                                     )
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("IntelligentAmmeter.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("IntelligentAmmeter instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("IntelligentAmmeter instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        //»°µ√ø’µ˜◊¥Ã¨
        iRet = Dvip_method_json_b_json("IntelligentAmmeter.readMeterPrev",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("IntelligentAmmeter.readMeterPrev exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            //Ω‚Œˆƒ⁄»›
            INFO_TRACE("IntelligentAmmeter.readMeterPrev exec OK.");
            
            if ( jsonOutParams["Time"].isNull() && jsonOutParams["Time"].isString() )
            {
                //Ω‚Œˆ ±º‰,≤¢◊™ªªŒ™int–Œ Ω
                std::string strTime = jsonOutParams["Time"].asString();
                iTime = DHTimr2Utc(strTime.c_str());
            }
            
            if ( !jsonOutParams["PositiveEnergys"].isNull() && jsonOutParams["PositiveEnergys"].isObject() )
            {
                //’˝œÚ”–π¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["PositiveActiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["PositiveActiveEnergy"].isInt()
                    )
                {
                    stPositive.iTotalActive = jsonOutParams["PositiveEnergys"]["PositiveActiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iTotalActive = 0;
                }
                //º‚ ±∂Œ’˝œÚ”–π¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["SharpPositiveActiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["SharpPositiveActiveEnergy"].isInt()
                    )
                {
                    stPositive.iSharpActive = jsonOutParams["PositiveEnergys"]["SharpPositiveActiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iSharpActive = 0;
                }
                //∑Â ±∂Œ’˝œÚ”–π¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["PeakPositiveActiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["PeakPositiveActiveEnergy"].isInt()
                    )
                {
                    stPositive.iPeakActive = jsonOutParams["PositiveEnergys"]["PeakPositiveActiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iPeakActive = 0;
                }
                //∆Ω ±∂Œ’˝œÚ”–π¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["ShoulderPositiveActiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["ShoulderPositiveActiveEnergy"].isInt()
                    )
                {
                    stPositive.iShoulderActive = jsonOutParams["PositiveEnergys"]["ShoulderPositiveActiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iShoulderActive = 0;
                }
                
                //π» ±∂Œ’˝œÚ”–π¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["OffPeakPositiveActiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["OffPeakPositiveActiveEnergy"].isInt()
                    )
                {
                    stPositive.iOffPeakActive = jsonOutParams["PositiveEnergys"]["OffPeakPositiveActiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iOffPeakActive = 0;
                }
                
                
                //’˝œÚŒﬁπ¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["PositiveReactiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["PositiveReactiveEnergy"].isInt()
                    )
                {
                    stPositive.iTotalReactive = jsonOutParams["PositiveEnergys"]["PositiveReactiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iTotalReactive = 0;
                }
                //º‚ ±∂Œ’˝œÚŒﬁπ¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["SharpPositiveReactiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["SharpPositiveReactiveEnergy"].isInt()
                    )
                {
                    stPositive.iSharpReactive = jsonOutParams["PositiveEnergys"]["SharpPositiveReactiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iSharpReactive = 0;
                }
                //∑Â ±∂Œ’˝œÚŒﬁπ¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["PeakPositiveReactiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["PeakPositiveReactiveEnergy"].isInt()
                    )
                {
                    stPositive.iPeakReactive = jsonOutParams["PositiveEnergys"]["PeakPositiveReactiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iPeakReactive = 0;
                }
                //∆Ω ±∂Œ’˝œÚŒﬁπ¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["ShoulderPositiveReactiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["ShoulderPositiveReactiveEnergy"].isInt()
                    )
                {
                    stPositive.iShoulderReactive = jsonOutParams["PositiveEnergys"]["ShoulderPositiveReactiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iShoulderReactive = 0;
                }
                //π» ±∂Œ’˝œÚŒﬁπ¶◊‹µÁ¡ø
                if ( !jsonOutParams["PositiveEnergys"]["OffPeakPositiveReactiveEnergy"].isNull()
                    && jsonOutParams["PositiveEnergys"]["OffPeakPositiveReactiveEnergy"].isInt()
                    )
                {
                    stPositive.iOffPeakReactive = jsonOutParams["PositiveEnergys"]["OffPeakPositiveReactiveEnergy"].asInt();
                    
                }
                else
                {
                    stPositive.iOffPeakReactive = 0;
                }
                
            }
            else
            {
                WARN_TRACE("no PositiveEnergys node.");
                stPositive.Init();
            }
            
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("IntelligentAmmeter.readMeterPrev exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("IntelligentAmmeter.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("IntelligentAmmeter.destroy failed.");
        }
        
        return iReturn;
    }
    
    //±®æØ
    // ≤º≥∑∑¿
    //int CDvrClient::Alarm_setArmMode(const char *pszDeviceId,const char *mode,const char *password,int iTimeout)
    //{
    //	int iRet = 0;
    //	unsigned int uiObjectId = 0;
    //	bool bRet = true;
    //	int iReturn = 0;
    //
    //	//¥¥Ω® µ¿˝
    //	iRet = Dvip_instance("alarm.factory.instance",/*(char*)pszDeviceId,*/uiObjectId,iTimeout);
    //	if ( 0 != iRet )
    //	{
    //		ERROR_TRACE("alarm instance failed.");
    //		return -1;
    //	}
    //	if ( 0 == uiObjectId )
    //	{
    //		ERROR_TRACE("alarm instance from server failed.objectid=0");
    //		return -1;
    //	}
    //
    //	Json::Value jsonInParams;
    //	Json::Value jsonOutParams;
    //	jsonInParams["mode"] = mode;
    //	if ( password )
    //	{
    //		jsonInParams["pwd"] = password;
    //	}
    //
    //	iRet = Dvip_method_json_b_json("alarm.setArmMode",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
    //	if ( 0 > iRet )
    //	{
    //		ERROR_TRACE("alarm.setArmMode exec failed.");
    //		iReturn = -1;
    //	}
    //	if ( bRet )
    //	{
    //		//Ω‚Œˆƒ⁄»›
    //		INFO_TRACE("alarm.setArmMode exec OK.");
    //
    //		iReturn = 0;
    //	}
    //	else
    //	{
    //		ERROR_TRACE("alarm.setArmMode exec failed.");
    //		iReturn = -1;
    //	}
    //
    //	// Õ∑≈ µ¿˝
    //	iRet = Dvip_destroy("alarm.destroy",uiObjectId,iTimeout);
    //	if ( 0 != iRet )
    //	{
    //		ERROR_TRACE("alarm.destroy failed.");
    //	}
    //
    //	return iReturn;
    //}
    
    int CDvrClient::Alarm_setArmMode(const char *pszDeviceId,const char *mode,const char *password,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        bool bEnable = false;
        if (!strcmp(mode,"Arming"))
        {
            bEnable = true;
        }
        else if (!strcmp(mode,"Disarming"))
        {
            bEnable = false;
        }
        else
        {	
            ERROR_TRACE("invalid mode = "<<mode);
            return -1;
        }
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        int channel = atoi(pszDeviceId)-1;
        if (channel<0)
        {
            ERROR_TRACE("invalid pszDeviceId = "<<pszDeviceId);
            return -1;
        }
        char szChan[11]={0};
        sprintf(szChan,"%d",channel);
        
        Json::Value jsonConfig;
        jsonConfig=bEnable;
        std::string strPath = "Alarm[";
        strPath+=szChan;
        strPath+="].Enable";
        iRet = Dvip_setConfig(uiObjectId,(char*)strPath.c_str(),jsonConfig,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager.setConfig  exec failed. strPath ="<<strPath);
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("configManager.setConfig exec OK.strPath ="<<strPath);
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("configManager.setConfig exec failed.strPath ="<<strPath);
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    // »°µ√±®æØ∑¿«¯◊¥Ã¨
    //int CDvrClient::Alarm_getArmMode_Sync(char *pszDeviceId,std::string &strMode,int iTimeout)
    //{
    //	int iRet = 0;
    //	unsigned int uiObjectId = 0;
    //	bool bRet = true;
    //	int iReturn = 0;
    //
    //	//¥¥Ω® µ¿˝
    //	iRet = Dvip_instance("alarm.factory.instance",/*(char*)pszDeviceId,*/uiObjectId,iTimeout);
    //	if ( 0 != iRet )
    //	{
    //		ERROR_TRACE("alarm instance failed.");
    //		return -1;
    //	}
    //	if ( 0 == uiObjectId )
    //	{
    //		ERROR_TRACE("alarm instance from server failed.objectid=0");
    //		return -1;
    //	}
    //
    //	Json::Value jsonInParams;
    //	Json::Value jsonOutParams;
    //	jsonInParams["info"]["DeviceId"] = pszDeviceId;
    //
    //	iRet = Dvip_method_json_b_json("alarm.getArmMode",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
    //	if ( 0 > iRet )
    //	{
    //		ERROR_TRACE("alarm.getArmMode exec failed.");
    //		iReturn = -1;
    //	}
    //	if ( bRet )
    //	{
    //		//Ω‚Œˆƒ⁄»›
    //		INFO_TRACE("alarm.getArmMode exec OK.");
    //		if ( jsonOutParams.isNull() || jsonOutParams["armMode"].isNull() )
    //		{
    //			ERROR_TRACE("alarm.getArmMode exec failed.");
    //			iReturn = -1;
    //		}
    //		else
    //		{
    //			Json::Value jsMode = jsonOutParams["armMode"];
    //			//strMode = jsonOutParams["armMode"].asString();
    //			if ( !jsMode["Mode"].isNull()&& jsMode["Mode"].isString())
    //			{
    //				strMode = jsMode["Mode"].asString();
    //			}
    //			else
    //			{
    //				WARN_TRACE("no Mode param or invalid");
    //				strMode = "";
    //			}
    //			iReturn = 0;
    //		}
    //	}
    //	else
    //	{
    //		ERROR_TRACE("alarm.getArmMode exec failed.");
    //		iReturn = -1;
    //	}
    //
    //	// Õ∑≈ µ¿˝
    //	iRet = Dvip_destroy("alarm.destroy",uiObjectId,iTimeout);
    //	if ( 0 != iRet )
    //	{
    //		ERROR_TRACE("alarm.destroy failed.");
    //	}
    //
    //	return iReturn;
    //}
    
    int CDvrClient::Alarm_getArmMode_Sync(char *pszDeviceId,std::string &strMode,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        int channel = atoi(pszDeviceId)-1;
        if (channel<0)
        {
            ERROR_TRACE("invalid pszDeviceId = "<<pszDeviceId);
            return -1;
        }
        char szChan[11]={0};
        sprintf(szChan,"%d",channel);
        
        std::string strPath = "Alarm[";
        strPath+=szChan;
        strPath+="].Enable";
        Json::Value jsonOutParams;
        iRet = Dvip_getConfig(uiObjectId,(char*)strPath.c_str(),bRet,jsonOutParams,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager.getConfig  exec failed. strPath ="<<strPath);
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("configManager.getConfig exec OK.strPath ="<<strPath);
            iReturn = 0;
            if ( !jsonOutParams.isNull() && jsonOutParams["table"].isBool() )
            {
                iReturn = 0;
                bool bEnable = jsonOutParams["table"].asBool();
                
                if ( bEnable == true)
                {
                    strMode = "Arming";
                }
                else
                {
                    strMode = "Disarming";
                }
                INFO_TRACE("strMode ="<<strMode);
            }
            else
            {
                iReturn = -1;
            }
        }
        else
        {
            ERROR_TRACE("configManager.getConfig exec failed.strPath ="<<strPath);
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    //  ”∆µ’⁄µ≤≈‰÷√
    int CDvrClient::GetVideoCovers(bool &bEnable,int iTimeout)
    {
        bEnable = false;
        std::string strPath = "VideoWidget[0].Covers";
        
        std::string strDevConfig;
        int iRet = ConfigManager_getConfig(strPath,strDevConfig,iTimeout);
        if (iRet == 0)
        {
            INFO_TRACE("GetBlindDetect ok");
            Json::Value jsonConfig,jsonDevConfig;
            Json::Reader jsonParser;
            bool bRet = jsonParser.parse(strDevConfig,jsonDevConfig);
            
            if ( !jsonDevConfig["table"].isNull()&& jsonDevConfig["table"].isArray() )
            {
                for(Json::ArrayIndex index=0;index<jsonDevConfig["table"].size();index++)
                {	
                    if (jsonDevConfig["table"][index]["EncodeBlend"].isBool())
                    {
                        bool found = jsonDevConfig["table"][index]["EncodeBlend"].asBool();
                        if (found == true)
                        {
                            bEnable = true;
                            break;
                        }
                    }
                }
            }
        }
        else
        {
            INFO_TRACE("GetBlindDetect failed!");
            return -1;
        }
        
        return iRet;
    }
    
    int CDvrClient::SetVideoCovers(bool bEnable,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        std::string strPath = "VideoWidget[0].Covers";
        
        std::string strDevConfig;
        iRet = ConfigManager_getConfig(strPath,strDevConfig,iTimeout);
        if (iRet == 0)
        {
            INFO_TRACE("GetBlindDetect ok");
        }
        else
        {
            INFO_TRACE("GetBlindDetect failed!");
            return -1;
        }
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonConfig,jsonDevConfig;
        Json::Reader jsonParser;
        bRet = jsonParser.parse(strDevConfig,jsonDevConfig);
        
        if ( !jsonDevConfig["table"].isNull()&& jsonDevConfig["table"].isArray() )
        {
            for(Json::ArrayIndex index=0;index<jsonDevConfig["table"].size();index++)
            {	
                jsonConfig[index]["PreviewBlend"] = bEnable;
                jsonConfig[index]["EncodeBlend"] = bEnable;
                jsonConfig[index]["EncodeBlendExtra1"] = bEnable;
                jsonConfig[index]["EncodeBlendExtra2"] = bEnable;
                jsonConfig[index]["EncodeBlendExtra3"] = bEnable;
                
                if ( !jsonDevConfig["table"][index]["BackColor"].isNull())
                {
                    jsonConfig[index]["BackColor"] = jsonDevConfig["table"][index]["BackColor"];
                }
                
                if ( !jsonDevConfig["table"][index]["Rect"].isNull())
                {
                    jsonConfig[index]["Rect"] = jsonDevConfig["table"][index]["Rect"];
                }
                //jsonConfig[index]["Mosaic"]=true;
            }
        }
        
        iRet = Dvip_setConfig(uiObjectId,(char*)strPath.c_str(),jsonConfig,bRet,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager.setConfig  exec failed. strPath ="<<strPath);
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("configManager.setConfig exec OK.strPath ="<<strPath);
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("configManager.setConfig exec failed.strPath ="<<strPath);
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    //bool CDvrClient::SetBlindDetect(bool bEnable,int iTimeout)
    //{
    //	int iRet = 0;
    //	unsigned int uiObjectId = 0;
    //	bool bRet = true;;
    //	int iReturn = 0;
    //
    //	//¥¥Ω® µ¿˝
    //	iRet = Dvip_instance("devVideoInput.factory.instance",uiObjectId,iTimeout);
    //	if ( 0 != iRet )
    //	{
    //		ERROR_TRACE("devVideoInput instance failed.");
    //		return -1;
    //	}
    //	if ( 0 == uiObjectId )
    //	{
    //		ERROR_TRACE("devVideoInput instance from server failed.objectid=0");
    //		return -1;
    //	}
    //
    //	Json::Value jsonInParams;
    //	Json::Value jsonOutParams;
    //	jsonInParams["index"] = 0;
    //	jsonInParams["enable"] = bEnable;
    //
    //	iRet = Dvip_method_json_b_json("devVideoInput.setCover",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
    //	if ( 0 > iRet )
    //	{
    //		ERROR_TRACE("devVideoInput.setCover exec failed.");
    //		iReturn = -1;
    //	}
    //	if ( bRet )
    //	{
    //		INFO_TRACE("devVideoInput.setCover exec OK.");
    //		iReturn = 0;
    //	}
    //	else
    //	{
    //		ERROR_TRACE("devVideoInput.setCover exec failed.");
    //		iReturn = -1;
    //	}
    //
    //	// Õ∑≈ µ¿˝
    //	iRet = Dvip_destroy("devVideoInput.destroy",uiObjectId,iTimeout);
    //	if ( 0 != iRet )
    //	{
    //		ERROR_TRACE("devVideoInput instance failed.");
    //	}
    //
    //	return iReturn;
    //}
    
    // »°µ√IPC◊¥Ã¨
    int CDvrClient::IPC_getState_Sync(char *pszDeviceId,bool &bIsOnline,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("IPCamera.factory.instance",pszDeviceId,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("IPCamera instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("IPCamera instance from server failed.objectid=0");
            return -1;
        }
        
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        
        iRet = Dvip_method_json_b_json("IPCamera.getState",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("IPCamera.getState exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("IPCamera.getState exec OK.");
            if ( jsonOutParams.isNull() || jsonOutParams["State"].isNull() )
            {
                ERROR_TRACE("IPCamera.getState exec failed.");
                iReturn = -1;
            }
            else
            {
                Json::Value jsState = jsonOutParams["State"];
                if ( !jsState["Online"].isNull()
                    && jsState["Online"].isBool()
                    )
                {
                    bIsOnline = jsState["Online"].asBool();
                }
                else
                {
                    WARN_TRACE("no Online param or invalid");
                    bIsOnline = false;
                }
            }
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("IPCamera.getState exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("IPCamera.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("IPCamera instance failed.");
        }
        
        return iReturn;
    }
    
    //…æ≥˝≈‰÷√ À˘”–
    int CDvrClient::ConfigManager_deleteFile(int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //÷¥––
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        iRet = Dvip_method_json_b_json("configManager.deleteFile",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("configManager.deleteFile exec failed.");
            iReturn = -1;
        }
        else
        {
            if ( bRet )
            {
                INFO_TRACE("configManager.deleteFile exec OK.");
                iReturn = 0;
            }
            else
            {
                ERROR_TRACE("configManager.deleteFile exec failed.");
                iReturn = -1;
            }
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
        }
        
        return iReturn;
    }
    //…æ≥˝≈‰÷√ Ãÿ∂®≈‰÷√
    int CDvrClient::ConfigManager_deleteConfig(std::string &strName,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //÷¥––
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["name"] = strName;
        iRet = Dvip_method_json_b_json("configManager.deleteConfig",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("configManager.deleteConfig exec failed.");
            iReturn = -1;
        }
        else
        {
            if ( bRet )
            {
                INFO_TRACE("configManager.deleteConfig exec OK.");
                iReturn = 0;
            }
            else
            {
                ERROR_TRACE("configManager.deleteConfig exec failed.");
                iReturn = -1;
            }
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
        }
        
        return iReturn;
    }
    //∂¡»°≈‰÷√ Ãÿ∂®≈‰÷√
    int CDvrClient::ConfigManager_getConfig(const std::string &strName,std::string &strConfig,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("configManager.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //ªÒ»°∑øº‰–≈œ¢
        Json::Value jsonConfig;
        iRet = Dvip_getConfig(uiObjectId,(char*)strName.c_str(),bRet,jsonConfig,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            if (strName == "IPCInfo")
            {
                //			strConfig = jsonConfig.toUnStyledString();
                if ( !jsonConfig.isNull())
                {
                    Json::Value jsonDevices;
                    
                    if ( !jsonConfig["table"].isNull()
                        && jsonConfig["table"].isArray() )
                    {
                        Json::ArrayIndex devices = jsonConfig["table"].size();
                        for(Json::ArrayIndex device=0;device<devices;device++)
                        {
                            Json::Value jsonDevice = jsonConfig["table"][device];
                            
//                            //DeviceID
//                            if ( !jsonDevice["DeviceID"].isNull()
//                                && jsonDevice["DeviceID"].isString() )
//                            {
//                                jsonDevices["table"][device]["DeviceID"] = jsonDevice["DeviceID"].asString();
//                            }
//                            else
//                            {
                                char szDev[4]={0};
                                sprintf(szDev,"%d",device+1);
                                jsonDevices["table"][device]["DeviceID"] = szDev;
//                            }
                            //Name
                            if ( !jsonDevice["Name"].isNull()
                                && jsonDevice["Name"].isString() )
                            {
                                jsonDevices["table"][device]["Name"] = jsonDevice["Name"].asString();
                            }
                            else
                            {
                                jsonDevices["table"][device]["Name"] = "";
                            }
                            
                            //AreaID
                            if ( !jsonDevice["AreaID"].isNull()
                                && jsonDevice["AreaID"].isInt() )
                            {
                                jsonDevices["table"][device]["AreaID"] = jsonDevice["AreaID"].asInt();
                            }
                            else
                            {
                                jsonDevices["table"][device]["AreaID"] = -1;
                            }				
                            
                            if ( !jsonDevice["Ip"].isNull()
                                && jsonDevice["Ip"].isString() )
                            {
                                jsonDevices["table"][device]["Ip"] = jsonDevice["Ip"].asString();
                            }
                            else
                            {
                                jsonDevices["table"][device]["Ip"] = "";
                            }
                            
                            if ( !jsonDevice["Port"].isNull()
                                && jsonDevice["Port"].isInt() )
                            {
                                jsonDevices["table"][device]["Port"] = jsonDevice["Port"].asInt();
                            }
                            else
                            {
                                jsonDevices["table"][device]["Port"] = 37777;
                            }
                            
                            if ( !jsonDevice["Username"].isNull()
                                && jsonDevice["Username"].isString() )
                            {
                                jsonDevices["table"][device]["Username"] = jsonDevice["Username"].asString();
                            }
                            else
                            {
                                jsonDevices["table"][device]["Username"] = "";
                            }
                            
                            if ( !jsonDevice["Password"].isNull()
                                && jsonDevice["Password"].isString() )
                            {
                                jsonDevices["table"][device]["Password"] = jsonDevice["Password"].asString();
                            }
                            else
                            {
                                jsonDevices["table"][device]["PassWord"] = "";
                            }
                            
                            if ( !jsonDevice["Type"].isNull()
                                && jsonDevice["Type"].isString() )
                            {
                                jsonDevices["table"][device]["Type"] = jsonDevice["Type"].asString();
                            }
                            else
                            {
                                jsonDevices["table"][device]["Type"] = "IPCamera";
                            }
                        }
                    }
                    
                    strConfig = jsonDevices.toUnStyledString();
                }
            }
            else if (strName == "Alarm")
            {
                //strConfig = jsonConfig.toUnStyledString();
                if ( !jsonConfig.isNull())
                {
                    Json::Value jsonDevices;
                    
                    if ( !jsonConfig["table"].isNull()
                        && jsonConfig["table"].isArray() )
                    {
                        Json::ArrayIndex devices = jsonConfig["table"].size();
                        for(Json::ArrayIndex device=0;device<devices;device++)
                        {
                            Json::Value jsonDevice = jsonConfig["table"][device];
                            
                            std::string strLog = jsonDevice.toUnStyledString();
                            //DeviceID
                            if ( !jsonDevice["DeviceID"].isNull()
                                && jsonDevice["DeviceID"].isString() )
                            {
                                jsonDevices["table"][device]["DeviceID"] = jsonDevice["DeviceID"].asString();
                            }
                            else
                            {
                                char szChan[4]={0};
                                sprintf(szChan,"%d",device);
                                jsonDevices["table"][device]["DeviceID"] = szChan;//Õ®µ¿∫≈
                            }
                            //Name
                            if ( !jsonDevice["Name"].isNull()
                                && jsonDevice["Name"].isString() )
                            {
                                jsonDevices["table"][device]["Name"] = jsonDevice["Name"].asString();
                            }
                            else
                            {
                                jsonDevices["table"][device]["Name"] = "";
                            }
                            
                            //AreaID
                            if ( !jsonDevice["AreaID"].isNull()
                                && jsonDevice["AreaID"].isInt() )
                            {
                                jsonDevices["table"][device]["AreaID"] = jsonDevice["AreaID"].asInt();
                            }
                            else
                            {
                                jsonDevices["table"][device]["AreaID"] = 0;
                            }				
                            
                            if ( !jsonDevice["SenseMethod"].isNull()
                                && jsonDevice["SenseMethod"].isString() )
                            {
                                jsonDevices["table"][device]["SenseMethod"] = jsonDevice["SenseMethod"].asString();
                            }
                            else
                            {
                                jsonDevices["table"][device]["SenseMethod"] = "";
                            }
                            
                            if ( !jsonDevice["SensorType"].isNull()
                                && jsonDevice["SensorType"].isString() )
                            {
                                jsonDevices["table"][device]["SensorType"] = jsonDevice["SensorType"].asString();
                            }
                            else
                            {
                                jsonDevices["table"][device]["SensorType"] = "";
                            }
                            
                            if ( !jsonDevice["Enable"].isNull()
                                && jsonDevice["Enable"].isBool() )
                            {
                                bool enable = jsonDevice["Enable"].asBool();
                                if (enable == true)
                                {
                                    jsonDevices["table"][device]["Mode"] = "Arming";
                                }
                                else
                                {
                                    jsonDevices["table"][device]["Mode"] = "Disarming";
                                }
                            }
                            
                            jsonDevices["table"][device]["Type"] = "AlarmZone";
                        }
                    }
                    
                    strConfig = jsonDevices.toUnStyledString();
                }
            }
            else
                strConfig = jsonConfig.toUnStyledString();
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("configManager.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    //∂¡»°…Ë±∏≈‰÷√ Ãÿ∂®≈‰÷√
    int CDvrClient::MagicBox_getDevConfig(const std::string &strName,std::string &strConfig,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("magicBox.factory.instance",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("magicBox instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("magicBox instance from server failed.objectid=0");
            return -1;
        }
        
        //ªÒ»°∑øº‰–≈œ¢
        Json::Value jsonConfig;
        iRet = Dvip_getDevConfig(uiObjectId,(char*)strName.c_str(),bRet,jsonConfig,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
            //return -1;
        }
        if ( bRet )
        {
            INFO_TRACE("method exec OK.");
            strConfig = jsonConfig.toUnStyledString();
            
            if (!strcmp((char*)strName.c_str(),"getSerialNo"))
            {
                Json::Value jsonReturn;
                jsonReturn["table"]=jsonConfig;
                strConfig = jsonReturn.toUnStyledString();
            }
            else
                strConfig = jsonConfig.toUnStyledString();
            
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("method exec failed.");
            iReturn = -1;
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("magicBox.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("magicBox destroy failed.");
            //return -1;
        }
        
        return iReturn;
    }
    
    ///////////////√≈Ω˚øÿ÷∆
    int CDvrClient::AccessControl_modifyPassword(char *type,char *user,char *oldPassword,char *newPassword,int iTimeout)
    {
        int iRet = 0;
        unsigned int uiObjectId = 0;
        bool bRet = true;;
        int iReturn = 0;
        
        Json::Value jsParams;
        jsParams["channel"] = 0;
        //¥¥Ω® µ¿˝
        iRet = Dvip_instance("accessControl.factory.instance",jsParams,uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("configManager instance failed.");
            return -1;
        }
        if ( 0 == uiObjectId )
        {
            ERROR_TRACE("configManager instance from server failed.objectid=0");
            return -1;
        }
        
        //÷¥––
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["type"] = type;
        jsonInParams["user"] = user;
        if ( type  )
        {
            jsonInParams["type"] = type;
        }
        if ( user  )
        {
            jsonInParams["user"] = user;
        }
        if ( oldPassword  )
        {
            jsonInParams["oldPassword"] = oldPassword;
        }
        if ( newPassword  )
        {
            jsonInParams["newPassword"] = newPassword;
        }
        iRet = Dvip_method_json_b_json("accessControl.modifyPassword",uiObjectId,jsonInParams,bRet,jsonOutParams,iTimeout);
        if ( 0 > iRet )
        {
            ERROR_TRACE("accessControl.modifyPassword exec failed.");
            iReturn = -1;
        }
        else
        {
            if ( bRet )
            {
                INFO_TRACE("accessControl.modifyPassword exec OK.");
                iReturn = 0;
            }
            else
            {
                ERROR_TRACE("accessControl.modifyPassword exec failed.");
                iReturn = -1;
            }
        }
        
        // Õ∑≈ µ¿˝
        iRet = Dvip_destroy("accessControl.destroy",uiObjectId,iTimeout);
        if ( 0 != iRet )
        {
            ERROR_TRACE("accessControl.destroy failed.");
        }
        
        return iReturn;
    }
    
    ////////////////////Õ‚≤øΩ”ø⁄///////////////////////
    
    
    //ªÒ»°≈‰÷√–≈œ¢
    int CDvrClient::Dvip_getConfig(unsigned uiObject
                                   ,char *pszConfigPath
                                   ,bool &bResult
                                   ,Json::Value &jsonCfg
                                   ,int iTimeout)
    {
        int iRet = 0;
        int iDataLength = 0;
        int iSendLength = 0;
        unsigned uiReq;
        char szBuf[1024];
        TransInfo *pTask = NULL;
        
        uiReq = CreateReqId();
        CMsgConfigManager_getConfig_req reqMsg(uiReq,m_uiSessionId,uiObject,pszConfigPath);
        iRet = reqMsg.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            //delete pReqMsg;
            return -1;
        }
        //delete pReqMsg;
        pTask = new TransInfo(uiReq,emRT_getConfig,GetCurrentTimeMs());
        if ( !pTask )
        {
            ERROR_TRACE("out of memory");
            return -1;
        }
        AddRequest(uiReq,pTask);
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("exec failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        CMsgConfigManager_getConfig_rsp *pRspMsg = (CMsgConfigManager_getConfig_rsp*)pTask->pRspMsg;
        bResult = pRspMsg->m_bResult;
        if ( bResult )
        {
            jsonCfg = pRspMsg->m_jsonConfig;
            //bIsOnline = pRspMsg->m_bIsOnline;
            //bIsOn = pRspMsg->m_bIsOn;
            //iShading = pRspMsg->m_iLevel;
        }
        delete pTask;
        
        return 0;
    }
    //…Ë÷√≈‰÷√–≈œ¢
    int CDvrClient::Dvip_setConfig(unsigned uiObject
                                   ,char *pszConfigPath
                                   ,Json::Value &jsonCfg
                                   ,bool &bResult
                                   ,int iTimeout)
    {
        int iRet = 0;
        int iDataLength = 0;
        int iSendLength = 0;
        unsigned uiReq;
        char szBuf[4096];
        bool bUseExtBuffer = false;
        char *pExtBuffer = NULL;
        TransInfo *pTask = NULL;
        
        uiReq = CreateReqId();
        CMsgConfigManager_setConfig_req reqMsg(uiReq,m_uiSessionId,uiObject,pszConfigPath,jsonCfg);
        iRet = reqMsg.Encode(szBuf,4096);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            if ( abs(iRet) > 4096 ) // ˝æ›ª∫≥ÂÃ´∂Ã
            {
                bUseExtBuffer = true;
                iRet = abs(iRet);
                pExtBuffer = new char [iRet+1];
                if ( !pExtBuffer )
                {
                    ERROR_TRACE("out of memory");
                    return -1;
                }
                INFO_TRACE("realloc buf and encode.");
                iRet = reqMsg.Encode(pExtBuffer,iRet+1);
                if ( 0 >= iRet )
                {
                    ERROR_TRACE("encode failed.");
                    delete pExtBuffer;
                    return -1;
                }
            }
            else //∆‰À˚¥ÌŒÛ
            {
                return -1;
            }
            //delete pReqMsg;
            //return -1;
        }
        //delete pReqMsg;
        pTask = new TransInfo(uiReq,emRT_getConfig,GetCurrentTimeMs());
        if ( !pTask )
        {
            ERROR_TRACE("out of memory");
            return -1;
        }
        AddRequest(uiReq,pTask);
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        if ( bUseExtBuffer )
        {
            iSendLength = SendData(pExtBuffer,iDataLength);
        }
        else
        {
            iSendLength = SendData(szBuf,iDataLength);
        }
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            if ( pExtBuffer )
            {
                delete pExtBuffer;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("exec failed");
            if ( pTask )
            {
                delete pTask;
            }
            if ( pExtBuffer )
            {
                delete pExtBuffer;
            }
            return -1;
        }
        if ( !pTask->pRspMsg )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            if ( pExtBuffer )
            {
                delete pExtBuffer;
            }
            return -1;
        }
        
        CMsgConfigManager_setConfig_rsp *pRspMsg = (CMsgConfigManager_setConfig_rsp*)pTask->pRspMsg;
        bResult = pRspMsg->m_bResult;
        if ( bResult )
        {
            //jsonCfg = pRspMsg->m_jsonConfig;
            //bIsOnline = pRspMsg->m_bIsOnline;
            //bIsOn = pRspMsg->m_bIsOn;
            //iShading = pRspMsg->m_iLevel;
        }
        delete pTask;
        if ( pExtBuffer )
        {
            delete pExtBuffer;
        }
        
        return 0;
    }
    
    //ªÒ»°…Ë±∏≈‰÷√–≈œ¢
    int CDvrClient::Dvip_getDevConfig(unsigned uiObject,char *pszConfigPath,bool &bResult,Json::Value &jsonCfg,int iTimeout)
    {
        int iRet = 0;
        int iDataLength = 0;
        int iSendLength = 0;
        unsigned uiReq;
        char szBuf[1024];
        TransInfo *pTask = NULL;
        
        uiReq = CreateReqId();
        CMsgMagicBox_getDevConfig_req reqMsg(uiReq,m_uiSessionId,uiObject,pszConfigPath);
        iRet = reqMsg.Encode(szBuf,1024);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            //delete pReqMsg;
            return -1;
        }
        //delete pReqMsg;
        pTask = new TransInfo(uiReq,emRT_getConfig,GetCurrentTimeMs());
        if ( !pTask )
        {
            ERROR_TRACE("out of memory");
            return -1;
        }
        AddRequest(uiReq,pTask);
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        iSendLength = SendData(szBuf,iDataLength);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("exec failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        if ( !pTask->pRspMsg )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            return -1;
        }
        
        CMsgMagicBox_getDevConfig_rsp *pRspMsg = (CMsgMagicBox_getDevConfig_rsp*)pTask->pRspMsg;
        bResult = pRspMsg->m_bResult;
        if ( bResult )
        {
            jsonCfg = pRspMsg->m_jsonConfig;
            //bIsOnline = pRspMsg->m_bIsOnline;
            //bIsOn = pRspMsg->m_bIsOn;
            //iShading = pRspMsg->m_iLevel;
        }
        delete pTask;
        
        return 0;
    }
    
    //…Ë÷√≈‰÷√–≈œ¢
    int CDvrClient::Dvip_setDeviceInfo(unsigned uiObject,Json::Value &jsonCfg,bool &bResult,int iTimeout)
    {
        int iRet = 0;
        int iDataLength = 0;
        int iSendLength = 0;
        unsigned uiReq;
        char szBuf[4096];
        bool bUseExtBuffer = false;
        char *pExtBuffer = NULL;
        TransInfo *pTask = NULL;
        
        uiReq = CreateReqId();
        CMsgSmarthome_setDeviceInfo_req reqMsg(uiReq,m_uiSessionId,uiObject,jsonCfg);
        iRet = reqMsg.Encode(szBuf,4096);
        if ( 0 >= iRet )
        {
            ERROR_TRACE("encode failed.");
            if ( abs(iRet) > 4096 ) // ˝æ›ª∫≥ÂÃ´∂Ã
            {
                bUseExtBuffer = true;
                iRet = abs(iRet);
                pExtBuffer = new char [iRet+1];
                if ( !pExtBuffer )
                {
                    ERROR_TRACE("out of memory");
                    return -1;
                }
                INFO_TRACE("realloc buf and encode.");
                iRet = reqMsg.Encode(pExtBuffer,iRet+1);
                if ( 0 >= iRet )
                {
                    ERROR_TRACE("encode failed.");
                    delete pExtBuffer;
                    return -1;
                }
            }
            else //∆‰À˚¥ÌŒÛ
            {
                return -1;
            }
            //delete pReqMsg;
            //return -1;
        }
        //delete pReqMsg;
        pTask = new TransInfo(uiReq,emRT_Smarthome_setDeviceInfo,GetCurrentTimeMs());
        if ( !pTask )
        {
            ERROR_TRACE("out of memory");
            return -1;
        }
        AddRequest(uiReq,pTask);
        //∑¢ÀÕ ˝æ›
        iDataLength = iRet;
        if ( bUseExtBuffer )
        {
            iSendLength = SendData(pExtBuffer,iDataLength);
        }
        else
        {
            iSendLength = SendData(szBuf,iDataLength);
        }
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            if ( pTask )
            {
                delete pTask;
            }
            if ( pExtBuffer )
            {
                delete pExtBuffer;
            }
            return -1;
        }
        
        iRet = pTask->hEvent.Wait(0);
        if ( TransInfo::emTaskStatus_Success != pTask->result )
        {
            ERROR_TRACE("exec failed");
            if ( pTask )
            {
                delete pTask;
            }
            if ( pExtBuffer )
            {
                delete pExtBuffer;
            }
            return -1;
        }
        if ( !pTask->pRspMsg )
        {
            ERROR_TRACE("rsp msg failed");
            if ( pTask )
            {
                delete pTask;
            }
            if ( pExtBuffer )
            {
                delete pExtBuffer;
            }
            return -1;
        }
        
        CMsgSmarthome_setDeviceInfo_rsp *pRspMsg = (CMsgSmarthome_setDeviceInfo_rsp*)pTask->pRspMsg;
        bResult = pRspMsg->m_bResult;
        if ( bResult )
        {
            //jsonCfg = pRspMsg->m_jsonConfig;
            //bIsOnline = pRspMsg->m_bIsOnline;
            //bIsOn = pRspMsg->m_bIsOn;
            //iShading = pRspMsg->m_iLevel;
        }
        delete pTask;
        if ( pExtBuffer )
        {
            delete pExtBuffer;
        }
        
        return 0;
    }
    
    bool CDvrClient::EnableSubConnect(bool bEnable)
    {
        if(bEnable == true) //Ω®¡¢◊”¡¨Ω”
        {
            if (m_hasMainConn)//“—¡¨Ω”
            {
                return true;
            }
            
            m_pMainConn = new CUserConn(0,m_strServIp,37777);
            int iRet = m_pMainConn->Connect(NULL,NULL);
            if (iRet == 0)
            {
                INFO_TRACE("main connect ok");
                m_hasMainConn = true;
                
                FclSleep(10);
                //µ«¬Ω
                iRet = m_pMainConn->login();
                if (iRet == 0)
                {
                    WARN_TRACE("simple login failed");
                    m_pMainConn->Disconnect();
                    delete m_pMainConn;
                    return false;
                }
                
                m_hasMainConn = true;
            }
            else
            {
                INFO_TRACE("sub connect failed!");
                return false;
            }
        }
        else// ∂œø™◊”¡¨Ω”
        {
            if (!m_hasMainConn)//Œ¥¡¨Ω”
            {
                return true;
            }
            
            m_pMainConn->Disconnect();
            delete m_pMainConn;
            m_hasMainConn = false;
        }
        
        return true;
    }
    
    bool CDvrClient::StartListen()
    {
        if (m_hasMainConn)
        {
            return m_pMainConn->StartAlarmListen();
        }
        else
        {
            WARN_TRACE("no sub connect");
            return false;
        }
    }
    
    bool CDvrClient::StopListen()
    {
        if (m_hasMainConn)
        {
            return m_pMainConn->StopAlarmListen();
        }
        else
        {
            WARN_TRACE("no sub connect");
            return false;
        }
    }
    
    
    // µ ±º‡ ”
    unsigned int CDvrClient::StartRealPlay(int iChannel,fRealDataCallBack pCb,void * pUser)
    {
        if (iChannel >= MAX_CHANNEL)
        {
            WARN_TRACE("invalid channel="<<iChannel);
            return 0;
        }
        if (pCb == NULL)
        {
            WARN_TRACE("invalid callback");
            return 0;
        }
        
        if (m_RealPlayArray[iChannel].uRealHandle > 0)
        {
            WARN_TRACE("real data is callbacking! channel="<<iChannel);
            return m_RealPlayArray[iChannel].uRealHandle;
        }
        
        if (m_hasMainConn == false)
        {
            //m_pMainConn = new CUserConn(0,m_strServIp,37777);
            //int iRet = m_pMainConn->Connect(NULL,NULL);
            //if (iRet == 0)
            //{
            //	INFO_TRACE("main connect ok");
            //	m_hasMainConn = true;
            
            //	FclSleep(10);
            //	//µ«¬Ω
            //	iRet = m_pMainConn->login();
            //	if (iRet == 0)
            //	{
            //		WARN_TRACE("simple login failed");
            //		m_pMainConn->Disconnect();
            //		delete m_pMainConn;
            //		return 0;
            //	}
            
            //	m_hasMainConn = true;
            //}
            //else
            //{
            //	WARN_TRACE("main connect failed");
            //	return 0;
            //}
            
            WARN_TRACE("sub connect not established!");
            return 0;
        }
        
        memset(&m_RealPlayArray[iChannel],0,sizeof(RealPlayTag));
        m_RealPlayArray[iChannel].iChannel = iChannel;
        m_RealPlayArray[iChannel].uRealHandle = CreateRealHandle();
        m_RealPlayArray[iChannel].subConn = new CUserConn(m_pMainConn->LoginId(),m_strServIp,37777);
        
        m_RealPlayArray[iChannel].subConn->Connect(pCb,pUser);
        m_RealPlayArray[iChannel].subConn->CreateDataConnect(m_RealPlayArray[iChannel].uRealHandle);
        
        m_pMainConn->StartRealPlay();
        
        return m_RealPlayArray[iChannel].uRealHandle;
    }
    
    bool CDvrClient::HasRealHandle(unsigned int uiRealHandle)
    {
        bool found = false;
        for (int i=0;i<MAX_CHANNEL;i++)
        {
            if (m_RealPlayArray[i].uRealHandle == uiRealHandle)
            {
                found = true;
                break;
            }
        }
        
        return found;
    }
    
    
    bool CDvrClient::IsRealPlay()
    {
        bool found = false;
        for (int i=0;i<MAX_CHANNEL;i++)
        {
            if (m_RealPlayArray[i].uRealHandle > 0)
            {
                found = true;
                break;
            }
        }
        
        return found;
    }
    
    //Õ£÷πº‡ ”
    int CDvrClient::StopRealPlay(unsigned int uiRealHandle)
    {
        if (uiRealHandle == 0)
        {
            return false;
        }
        bool found = false;
        int index = 0;
        for (;index<MAX_CHANNEL;index++)
        {
            if (m_RealPlayArray[index].uRealHandle == uiRealHandle)
            {
                found = true;
                break;
            }
        }
        
        if (found == false)
        {
            WARN_TRACE("invalid handle: uiRealHandle="<<uiRealHandle);
            return -1;
        }
        
        if (m_hasMainConn)
        {
            m_pMainConn->StopRealPlay();
            
            CUserConn * pSubConn = m_RealPlayArray[index].subConn;
            pSubConn->Disconnect();
            delete pSubConn;
            m_RealPlayArray[index].iChannel = 0;
            m_RealPlayArray[index].uRealHandle = 0;
            
            //if (!IsRealPlay())
            //{
            //	m_pMainConn->Disconnect();
            //	delete m_pMainConn;
            //	m_hasMainConn = false;
            //}
        }
        
        return 0;
    }
    
    // ’µΩÕ®÷™œ˚œ¢
    void CDvrClient::OnNotification(dvip_hdr &hdr,const char *pData,int pDataLen)
    {
        std::string strMethod;
        unsigned int uiSID = 0;
        std::string strEventCode;
        int iEventIndex = 0;
        std::string strEventAction;
        std::string strDeviceId;
        std::string strDeviceType;
        std::string strDeviceState;
        Json::Reader jsonParser;
        Json::Value jsonContent;
        Json::Value jsonDeviceState;
        bool bRet = true;
        
        if ( hdr.message_length == 0 )
        {
            ERROR_TRACE("invalid msg no msg body.");
            return ;
        }
        
        bRet = jsonParser.parse(pData,pData+hdr.message_length,jsonContent);
        if ( !bRet )
        {
            ERROR_TRACE("parse msg body failed");
            return ;
        }
        
        //
        if ( jsonContent["method"].isNull() 
            || !jsonContent["method"].isString() ) //∑Ω∑®
        {
            ERROR_TRACE("no method or method type is not string.");
            return ;
        }
        strMethod = jsonContent["method"].asString();
        if ( strMethod != "client.notifyEventStream" /*&& strMethod != "client.notifySnapFile"*/)
        {
            ERROR_TRACE("invalid notification method.method="<<strMethod);
            return ;
        }
        
        if ( jsonContent["params"].isNull() )
        {
            ERROR_TRACE("no params.");
            return ;
        }
        if ( jsonContent["params"]["SID"].isNull()
            || !jsonContent["params"]["SID"].isInt() )
        {
            ERROR_TRACE("no SID or SID type is not int.");
            return ;
        }
        uiSID = jsonContent["params"]["SID"].asInt();
        if ( m_uiSid != uiSID )
        {
            ERROR_TRACE("SID difference.my sid=."<<m_uiSid<<" received="<<uiSID);
            return ;
        }
        
        if ( jsonContent["params"]["eventList"].isNull()
            || !jsonContent["params"]["eventList"].isArray()
            )
        {
            ERROR_TRACE("eventList not exist or type not array.");
            return ;
        }
        for(Json::ArrayIndex i=0;i<jsonContent["params"]["eventList"].size();i++)
        {
            // ¬º˛¿‡–Õ
            Json::Value &jsEvent = jsonContent["params"]["eventList"][i];
            if ( jsEvent["Code"].isNull() || !jsEvent["Code"].isString() )
            {
                ERROR_TRACE("event Code not exist or type not string");
                continue ;
            }
            strEventCode = jsEvent["Code"].asString();
            if ( strEventCode == "DeviceState" ) //÷«ƒ‹º“æ”…Ë±∏◊¥Ã¨
            {
            }
            else if ( strEventCode == "AlarmLocal" ) //±æµÿ±®æØ
            {
                //INFO_TRACE("event code not process now.eventcode="<<strEventCode);
            }
            else if ( strEventCode == "ArmModeChange" ) //±®æØ≤º≥∑∑¿ƒ£ Ω±‰ªØ
            {
                //INFO_TRACE("event code not process now.eventcode="<<strEventCode);
            }
            else
            {
                INFO_TRACE("event code not process now.eventcode="<<strEventCode);
                continue ;
            }
            
            //–Ú∫≈
            if ( !jsEvent["Index"].isNull() && jsEvent["Index"].isInt() )
            {
                iEventIndex = jsEvent["Index"].asInt();
            }
            else
            {
                iEventIndex = 0;
            }
            
            // ¬º˛∂Ø◊˜¿‡–Õ Start End Pulse
            if ( !jsEvent["Action"].isNull() && jsEvent["Action"].isString() )
            {
                strEventAction = jsEvent["Action"].asString();
            }
            else
            {
                strEventAction = "";
            }
            
            if ( strEventCode == "DeviceState" ) //÷«ƒ‹º“æ”…Ë±∏◊¥Ã¨
            {
                // ¬º˛œÍœ∏ ˝æ›
                if ( jsEvent["Data"].isNull() || !jsEvent["Data"].isObject() )
                {
                    WARN_TRACE("no event data");
                    continue ;
                }
                
                if ( !jsEvent["Data"]["DeviceID"].isNull() && jsEvent["Data"]["DeviceID"].isString() )
                {
                    strDeviceId = jsEvent["Data"]["DeviceID"].asString();
                }
                else
                {
                    strDeviceId = "";
                }
                if ( !jsEvent["Data"]["Type"].isNull() && jsEvent["Data"]["Type"].isString() )
                {
                    strDeviceType = jsEvent["Data"]["Type"].asString();
                    
                    if (strDeviceType == "Light")//µ∆π‚…Ë±∏–Ë“™Ω¯“ª≤Ω»∑∂®◊”¿‡–Õ
                    {
                        if ( !jsEvent["Data"]["SubType"].isNull() && jsEvent["Data"]["SubType"].isString() )
                        {
                            strDeviceType = jsEvent["Data"]["SubType"].asString();
                        }
                    }
                }
                else
                {
                    strDeviceType = "";
                }
                
                if ( strDeviceType == "CommLight" ) //∆’Õ®–Õµ∆π‚
                {
                }
                else if ( strDeviceType == "LevelLight" ) //µ˜π‚–Õµ∆π‚
                {
                }
                else if ( strDeviceType == "Curtain" ) //¥∞¡±
                {
                }
                else if ( strDeviceType == "AirCondition" ) //ø’µ˜
                {
                }
                else if ( strDeviceType == "GroundHeat" ) //µÿ≈Ø
                {
                }
                else if ( strDeviceType == "IPCamera" ) //IPCamera
                {
                }
                else
                {
                    INFO_TRACE("device type current not process.type="<<strDeviceType);
                    continue;
                }
                if ( jsEvent["Data"]["State"].isNull() )
                {
                    WARN_TRACE("no Sate");
                    continue;
                }
                jsonDeviceState = jsEvent["Data"]["State"];
                strDeviceState = jsonDeviceState.toUnStyledString();
                INFO_TRACE("event notify: device-id="<<strDeviceId
                           <<" device-type="<<strDeviceType<<" device-state="<<strDeviceState);
                if ( m_cbOnEventNotify )
                {
                    m_cbOnEventNotify(m_uiLoginId,(char*)strDeviceId.c_str(),
                                      (char*)strDeviceType.c_str(),(char*)strDeviceState.c_str(),m_pEventNotifyUser);
                }
                
            }
            else if ( strEventCode == "AlarmLocal" ) //±æµÿ±®æØ
            {
                std::string strExtInfo;
                // ¬º˛œÍœ∏ ˝æ›
                if ( jsEvent["Data"].isNull() || !jsEvent["Data"].isObject() )
                {
                    WARN_TRACE("no event data");
                    //continue ;
                }
                else
                    strExtInfo = jsEvent["Data"].toUnStyledString();
                
                //ªÿµ˜…œ≤„
                int iAlarmState;
                if ( strEventAction == "Start" )
                {
                    iAlarmState = 1;
                }
                else if ( strEventAction == "Stop" )
                {
                    iAlarmState = 0;
                }
                else if ( strEventAction == "Pulse" )
                {
                    iAlarmState = 1;
                }
                else if (strEventAction == "Armed")
                {
                    iAlarmState = 21;
                }
                else if (strEventAction == "Bypass")
                {
                    iAlarmState = 22;
                }
                else //Œ¥÷™
                {
                    iAlarmState = 0;
                }
                if ( m_cbOnAlarmNotify )
                {
                    m_cbOnAlarmNotify(m_uiLoginId,iEventIndex+1,iAlarmState,(char*)strExtInfo.c_str(),
                                      NULL,0,m_pAlarmNotifyUser);
                }
            }
            else if ( strEventCode == "ArmModeChange" ) //±æµÿ±®æØ
            {
                std::string strExtInfo;
                // ¬º˛œÍœ∏ ˝æ›
                if ( jsEvent["Data"].isNull() || !jsEvent["Data"].isObject() )
                {
                    WARN_TRACE("no event data");
                    //continue ;
                }
                
                std::string strMode;
                if ( !jsEvent["Data"].isNull() )
                {
                    strExtInfo = jsEvent["Data"].toUnStyledString();
                }
                //¥´∏–∆˜¿‡–Õ
                if ( !jsEvent["Data"]["Mode"].isNull() && jsEvent["Data"]["Mode"].isString() )
                {
                    strMode = jsEvent["Data"]["Mode"].asString();
                }
                else
                {
                    strMode = "";
                }
                
                int iAlarmState = -1;
                if (strMode == "Arming")
                {
                    iAlarmState = 21;
                }
                else if (strMode == "Disarming")
                {
                    iAlarmState = 22;
                }
                
                if ( m_cbOnAlarmNotify )
                {
                    m_cbOnAlarmNotify(m_uiLoginId,iEventIndex+1,iAlarmState,(char*)strExtInfo.c_str(),
                                      NULL,0,m_pAlarmNotifyUser);
                }
            }
        }
        return ;
    }
    
    
    // ’µΩÕ®÷™œ˚œ¢
    int CDvrClient::OnPackage(dvip_hdr &hdr,const char *pData,int pDataLen)
    {
        printf("OnPackage: packet_length=%d,packect_index=%d\n",
               hdr.packet_length,hdr.packet_index);
        
        if (hdr.packet_index == 0)//µ⁄“ª∞¸ ˝æ›
        {
            std::string strMethod;
            Json::Reader jsonParser;
            Json::Value jsonContent;
            bool bRet = true;
            
            if ( hdr.message_length == 0 )
            {
                ERROR_TRACE("invalid msg no msg body.");
                return -1;
            }
            
            bRet = jsonParser.parse(pData,pData+hdr.message_length,jsonContent);
            if ( !bRet )
            {
                ERROR_TRACE("parse msg body failed");
                return -1;
            }
            
            //
            if ( jsonContent["method"].isNull() 
                || !jsonContent["method"].isString() ) //∑Ω∑®
            {
                ERROR_TRACE("no method or method type is not string.");
                return -1;
            }
            strMethod = jsonContent["method"].asString();
            if (strMethod != "client.notifySnapFile")
            {
                ERROR_TRACE("invalid notification method.method="<<strMethod);
                return -1;
            }
            
            if ( jsonContent["params"].isNull() )
            {
                ERROR_TRACE("no params.");
                return -1;
            }
            
            if ( jsonContent["params"]["info"].isNull())
            {
                ERROR_TRACE("no info.");
                return -1;
            }
            
            memset(&m_fileinfo,0,sizeof(FileProcessInfo));
            
            if (!jsonContent["params"]["info"]["Channel"].isNull()
                && jsonContent["params"]["info"]["Channel"].isInt())
            {
                m_fileinfo.Channel = jsonContent["params"]["info"]["Channel"].asInt();
            }
            
            if (!jsonContent["params"]["info"]["Time"].isNull()
                && jsonContent["params"]["info"]["Time"].isString())
            {
                m_fileinfo.Time = jsonContent["params"]["info"]["Time"].asString();
            }
            
            if (!jsonContent["params"]["info"]["FilePath"].isNull()
                && jsonContent["params"]["info"]["FilePath"].isString())
            {
                m_fileinfo.FilePath = jsonContent["params"]["info"]["FilePath"].asString();
            }
            
            if (!jsonContent["params"]["info"]["FTPPath"].isNull()
                && jsonContent["params"]["info"]["FTPPath"].isString())
            {
                m_fileinfo.FTPPath = jsonContent["params"]["info"]["FTPPath"].asString();
            }
            
            if (!jsonContent["params"]["info"]["Length"].isNull()
                && jsonContent["params"]["info"]["Length"].isInt())
            {
                m_fileinfo.Length = jsonContent["params"]["info"]["Length"].asInt();
            }
            
            if (!jsonContent["params"]["info"]["SOF"].isNull()
                && jsonContent["params"]["info"]["SOF"].isBool())
            {
                m_fileinfo.bSOF = jsonContent["params"]["info"]["SOF"].asBool();
            }
            
            if (!jsonContent["params"]["info"]["SOF"].isNull()
                && jsonContent["params"]["info"]["SOF"].isBool())
            {
                m_fileinfo.bSOF = jsonContent["params"]["info"]["SOF"].asBool();
            }
            
            if (!jsonContent["params"]["info"]["EOF"].isNull()
                && jsonContent["params"]["info"]["EOF"].isBool())
            {
                m_fileinfo.bEOF = jsonContent["params"]["info"]["EOF"].asBool();
            }
            
            printf("OnPackage: file start,data_legth=%d,message_length=%d\n",hdr.data_length,hdr.message_length);
            
            //EventsΩ‚Œˆ
            if ( jsonContent["params"]["info"]["Events"].isNull()
                || !jsonContent["params"]["info"]["Events"].isArray()
                )
            {
                ERROR_TRACE("eventList not exist or type not array.");
                return -1;
            }
            
            if ( !jsonContent["params"]["info"]["Events"][0]["Code"].isNull()
                || jsonContent["params"]["info"]["Events"][0]["Code"].isString()
                )
            {
                m_fileinfo._event.Code = jsonContent["params"]["info"]["Events"][0]["Code"].asString();
            }
            
            if ( !jsonContent["params"]["info"]["Events"][0]["Action"].isNull()
                || jsonContent["params"]["info"]["Events"][0]["Action"].isString()
                )
            {
                m_fileinfo._event.Action = jsonContent["params"]["info"]["Events"][0]["Action"].asString();
            }
            
            if ( !jsonContent["params"]["info"]["Events"][0]["Index"].isNull()
                || jsonContent["params"]["info"]["Events"][0]["Index"].isInt()
                )
            {
                m_fileinfo._event.Index = jsonContent["params"]["info"]["Events"][0]["Index"].asInt();
            }
            
            if ( !jsonContent["params"]["info"]["Events"][0]["UTC"].isNull()
                || jsonContent["params"]["info"]["Events"][0]["UTC"].isInt()
                )
            {
                m_fileinfo._event.UTC = jsonContent["params"]["info"]["Events"][0]["UTC"].asInt();
            }
            
            if ( !jsonContent["params"]["info"]["Events"][0]["EventID"].isNull()
                || jsonContent["params"]["info"]["Events"][0]["EventID"].isInt()
                )
            {
                m_fileinfo._event.EventID = jsonContent["params"]["info"]["Events"][0]["EventID"].asInt();
            }
            
            if ( !jsonContent["params"]["info"]["Events"][0]["Data"].isNull())
            {
                if ( !jsonContent["params"]["info"]["Events"][0]["Data"]["SourceDevice"].isNull()
                    || jsonContent["params"]["info"]["Events"][0]["Data"]["SourceDevice"].isString()
                    )
                {
                    m_fileinfo._event.SourceDevice = 
                    jsonContent["params"]["info"]["Events"][0]["Data"]["SourceDevice"].asString();
                }
            }
            
            INFO_TRACE("event code "<<m_fileinfo._event.Code);
            
            //Ω‚Œˆ¿©’π ˝æ›
            memset(m_filebuffer,0,MAX_PIC_LEN);
            m_pos = 0;
            m_packet_index = hdr.packet_index;
            
            memcpy(m_filebuffer+m_pos,pData+hdr.message_length,hdr.packet_length-hdr.message_length);
            m_pos+=hdr.packet_length-hdr.message_length;
        }
        else
        {
            if (m_packet_index+1 == hdr.packet_index)//¡¨–¯
            {
                m_packet_index = hdr.packet_index;
                memcpy(m_filebuffer+m_pos,pData,hdr.packet_length);
                m_pos+=hdr.packet_length;
            }
            else//◊È∞¸¥ÌŒÛ£¨ÕÀ≥ˆ
            {
                memset(&m_fileinfo,0,sizeof(FileProcessInfo));
                memset(m_filebuffer,0,MAX_PIC_LEN);
                m_pos = 0;
                m_packet_index = hdr.packet_index;
                
                return -2;
            }
            
            if(hdr.data_length== m_pos)//◊Ó∫Û“ª∞¸
            {
                printf("OnPackage: file end\n");
                
                if ( m_cbOnAlarmNotify )
                {
                    int iAlarmState = 0;
                    if (m_fileinfo._event.Code == "AlarmLocal" || m_fileinfo._event.Code == "Manual")
                    {
                        if (m_fileinfo._event.Action == "Start")
                        {
                            iAlarmState = 1;
                        }
                        else if (m_fileinfo._event.Action == "Stop")
                        {
                            iAlarmState = 0;
                        }
                        else
                        {
                            iAlarmState = -1;
                        }
                        Json::Value jsonExtInfo;
                        jsonExtInfo["DeviceId"]=m_fileinfo._event.SourceDevice;
                        m_cbOnAlarmNotify(m_uiLoginId,m_fileinfo.Channel,iAlarmState,
                                          (char*)(std::string(jsonExtInfo.toUnStyledString()).c_str()),
                                          m_filebuffer,m_pos,m_pAlarmNotifyUser);
                    }
                    else//
                    {
                        
                    }
                }
                
                memset(m_filebuffer,0,MAX_PIC_LEN);
                m_pos = 0;
                m_packet_index = 0;
                return -3;
            }
        }
        
        return 0;
    }
    
    //Ω‚Œˆ≥°æ∞–≈œ¢
    bool CDvrClient::ParseScence(Json::Value &jsonConfig,std::vector<Smarthome_SceneInfo> &vecScenes)
    {
        return false;
    }
    //¥Ú∞¸≥°æ∞–≈œ¢
    bool CDvrClient::EncodeScence(Json::Value &jsonConfig,std::vector<Smarthome_SceneInfo> &vecScenes)
    {
        return false;
    }
    
    void CDvrClient::Process_Task()
    {
        CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
        if ( m_reqList.size() <= 0 )
        {
            return ;
        }
        TransInfo *pTask;
        RequestList::iterator it;
        for(it=m_reqList.begin();it!=m_reqList.end();)
        {
            pTask = it->second;
            if ( pTask->IsTimeOut() )
            {
                INFO_TRACE("timeout,remove seq "<<it->first);
                pTask->result = TransInfo::emTaskStatus_Timeout;
                pTask->hEvent.Signal();
                
                m_reqList.erase(it++);
                if (m_reqList.size()==0)
                {
                    break;
                }
                if (it == m_reqList.end())
                {
                    break;
                }
            }
            else
                it++;
        }
        
        return ;
    }
    
    //∂œœﬂÕÀ≥ˆ«Â¿Ì ¬ŒÒ
    void CDvrClient::Clear_Tasks()
    {
        CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
        if ( m_reqList.size() <= 0 )
        {
            return ;
        }
        TransInfo *pTask;
        RequestList::iterator it;
        for(it=m_reqList.begin();it!=m_reqList.end();it++)
        {
            INFO_TRACE("cancel seq "<<it->first);
            
            pTask = it->second;
            pTask->result = TransInfo::emTaskStatus_Cancel;
            pTask->hEvent.Signal();
        }
        
        m_reqList.clear();
        
        return ;
    }
