
#include "MultiCast.h"
#include "DvipMsg.h"
#include "UtilFuncs.h"
//#include "json.h"

#if defined(_WIN32)
#include <Ws2tcpip.h>
#else
#endif


CMultiCastClient::CMultiCastClient(void)
{
    m_sock = FCL_INVALID_SOCKET;
    memset(m_szMCastIpAddr,0,32);
    m_usMCastPort = 0;
    m_pIPSearchcb = NULL;
    m_pIPSearchUser = NULL;
    
    m_bExitThread = false;
    m_hMCastThread = NULL;
}
CMultiCastClient::~CMultiCastClient()
{
    m_pIPSearchcb = NULL;
    if (m_hMCastThread)
    {
        Stop();
    }
}

int CMultiCastClient::Start(char *szMCastIpAddr, unsigned short usMCastPort,fOnIPSearch pFcb,void *pUser)
{
    int iRet;
    m_bExitThread = false;
    
    strncpy(m_szMCastIpAddr,szMCastIpAddr,32-1);
    m_usMCastPort = usMCastPort;
    m_pIPSearchcb = pFcb;
    m_pIPSearchUser = pUser;
    
    INFO_TRACE("szMCastIpAddr="<<szMCastIpAddr<<"usMCastPort="<<usMCastPort);
    iRet = StartMCast();
    if ( 0 != iRet )
    {
        return iRet;
    }
    
#ifdef PLAT_WIN32
    DWORD dwThreadId;
    m_hMCastThread = CreateThread(NULL,0,CMultiCastClient::MCastThread,this,0,&dwThreadId);
#else
    pthread_attr_t attr;
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
    
    if ((iRet = ::pthread_create(&m_hMCastThread, &attr,CMultiCastClient::MCastThread, this)) != 0)
    {
        ERROR_TRACE("pthread_create() failed! error code="<<iRet);
        ::pthread_attr_destroy(&attr);
        return -1;
    }
    ::pthread_attr_destroy(&attr);
    
#endif
    
    return 0;
}
int CMultiCastClient::Stop(void)
{
    m_bExitThread = true;
    
#ifdef _WIN32
    DWORD dwRet = WaitForSingleObject(m_hMCastThread,5000);
    if ( dwRet == WAIT_TIMEOUT )
    {
        TerminateThread(m_hMCastThread,0);
    }
#else
    void *result;
    pthread_join(m_hMCastThread,&result);
#endif
    
    m_hMCastThread = 0;
    
    return 0;
}

#ifdef _WIN32
unsigned long  CMultiCastClient::MCastThread(void *pParam)
#else
void* CMultiCastClient::MCastThread(void *pParam)
#endif
{
    CMultiCastClient *pMCast = (CMultiCastClient*)pParam;
    pMCast->MCastTrans();
    return 0;
}
int CMultiCastClient::MCastTrans(void)
{
    int fds;
    timeval tv;
    int iTotal;
    fd_set fd_recv;
    FD_ZERO(&fd_recv);
    sockaddr_in addr;
    int iAddrSize = sizeof(addr);
    int iDataLen;
    char szDataBuf[2048];
    
    while ( true )
    {
        if ( m_bExitThread ) //退出线程
        {
            break;
        }
        
        FclSleep(1);
        
        tv.tv_sec = 0;
        tv.tv_usec = 200*1000; //200ms
        fds = 0;
        FD_ZERO(&fd_recv);
        FD_SET(m_sock,&fd_recv);
        fds = (int)m_sock;
        
        iTotal = select(fds+1,&fd_recv,0,0,&tv);
#ifdef _WIN32
        if ( SOCKET_ERROR == iTotal )
        {
            errno = WSAGetLastError();
            ERROR_TRACE("MCastTrans socket errno="<<errno);
        }
#else
        if ( -1 == iTotal )
        {
            ERROR_TRACE("MCastTrans socket errno="<<errno);
        }
#endif
        if ( 0 ==  iTotal ) //超时
        {
            continue;
        }
        
        iAddrSize = sizeof(addr);
        iDataLen = recvfrom(m_sock,szDataBuf,2048,0,
                            (struct sockaddr*)&addr,
#if !defined(_WIN32)
                            (socklen_t*)
#endif
                            &iAddrSize);
#ifdef _WIN32
        if ( SOCKET_ERROR == iDataLen )
        {
            errno = WSAGetLastError();
            if ( EWOULDBLOCK == errno )
            {
#else
                if ( -1 == iDataLen )
                {
                    if ( EAGAIN == errno )
                    {
                        errno = EWOULDBLOCK;
#endif
                    }
                    else //error
                    {
                        //VT_ERROR_TRACE("CVTStack::NetTransThread socket error recv.");
                    }
                    ERROR_TRACE("MCastTrans socket errno="<<errno);
                }
                else
                {
                    //数据处理
                    OnDataRecv(szDataBuf,iDataLen);
                }
            }
            
            //退出广播组
            StopMCast();
            
            return 0;
        }
        //开启组播
        int CMultiCastClient::StartMCast(void)
        {
            int iRet;
            struct sockaddr_in local_addr;              //本地地址
            struct ip_mreq mreq;
            
            m_sockSend = (int)socket(AF_INET,SOCK_DGRAM,0);         //建立套接字
            if( FCL_INVALID_SOCKET == m_sockSend )
            {
#ifdef _WIN32
                errno = WSAGetLastError();
#endif
                ERROR_TRACE("StartMCast socket error,error code="<<errno);
                return -1;
            }
            
            //加入组播
            m_sock = (int)socket(AF_INET,SOCK_DGRAM,0);     //建立套接字
            if( FCL_INVALID_SOCKET == m_sock )
            {
#ifdef _WIN32
                errno = WSAGetLastError();
#endif
                ERROR_TRACE("StartMCast socket error,error code="<<errno);
                return -1;
            }
            
            //	BOOL bReuse = true;
            //	iRet = setsockopt(m_sock, SOL_SOCKET, SO_REUSEADDR, (char*)&bReuse, sizeof(BOOL));
            //	if ( 0 != iRet )
            //	{
            //#ifdef _WIN32
            //		errno = WSAGetLastError();
            //#endif
            //		ERROR_TRACE("StartMCast setsockopt():SO_REUSEADDR error,error code="<<errno);
            //		return -1;
            //	}
            //初始化地址
            memset(&local_addr, 0, sizeof(local_addr));
            local_addr.sin_family = AF_INET;
            local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
            local_addr.sin_port = htons(m_usMCastPort);
            //绑定socket
            iRet = bind(m_sock,(struct sockaddr*)&local_addr,sizeof(local_addr));
            if( 0 != iRet )
            {
#ifdef _WIN32
                errno = WSAGetLastError();
#endif
                ERROR_TRACE("StartMCast bind() error,error code="<<errno);
                
                FCL_CLOSE_SOCKET(m_sock);
                return -1;
            }
            
            //设置回环许可
            //	int loop = 1;
            //	iRet = setsockopt(m_sock,IPPROTO_IP,IP_MULTICAST_LOOP,(char*)&loop,sizeof(loop));
            //	if( 0 != iRet )
            //	{
            //#ifdef _WIN32
            //		errno = WSAGetLastError();
            //#endif
            //		ERROR_TRACE("StartMCast setsockopt():IP_MULTICAST_LOOP error,error code="<<errno);
            //		FCL_CLOSE_SOCKET(m_sock);
            //
            //		return -1;
            //	}
            
            //加入多播组
            mreq.imr_multiaddr.s_addr = inet_addr(m_szMCastIpAddr); //多播地址
            mreq.imr_interface.s_addr = htonl(INADDR_ANY); //网络接口为默认
            iRet = setsockopt(m_sock,IPPROTO_IP,IP_ADD_MEMBERSHIP,(char *)&mreq,sizeof(mreq));
            if ( 0 != iRet )
            {
#ifdef _WIN32
                errno = WSAGetLastError();
#endif
                ERROR_TRACE("StartMCast setsockopt():IP_ADD_MEMBERSHIP error,error code="<<errno);
                FCL_CLOSE_SOCKET(m_sock);
                return -1;
            }
            
            //设置为非阻塞模式
            int iBlock = 1; //no block
#ifdef _WIN32
            iRet = ::ioctlsocket(m_sock,FIONBIO,(u_long FAR *)&iBlock);
            if ( SOCKET_ERROR == iRet )
            {
                errno = ::WSAGetLastError();
                iRet = -1;
            }
#else
            iBlock = ::fcntl(m_sock,F_GETFL,0);
            if ( -1 != iBlock )
            {
                iBlock |= O_NONBLOCK;
                iRet = ::fcntl(m_sock,F_SETFL,iBlock);
            }
#endif
            if ( -1 == iRet )
            {
                FCL_CLOSE_SOCKET(m_sock);
                ERROR_TRACE("StartMCast set noblock mode error,error code="<<errno);
                return -1;
            }
            return 0;
        }
        //结束组播
        int CMultiCastClient::StopMCast(void)
        {
            int iRet = 0;
            struct ip_mreq mreq;
            
            mreq.imr_multiaddr.s_addr = inet_addr(m_szMCastIpAddr); //多播地址
            mreq.imr_interface.s_addr = htonl(INADDR_ANY); //网络接口为默认
            
            iRet = setsockopt(m_sock,IPPROTO_IP,IP_DROP_MEMBERSHIP,(char *)&mreq,sizeof(mreq));
            if ( 0 !=  iRet)
            {
                iRet = -1;
#ifdef _WIN32
                errno = WSAGetLastError();
#endif
                ERROR_TRACE("StopMCast setsockopt():IP_ADD_MEMBERSHIP error,error code="<<errno);
            }
            if(m_sockSend > 0)
                FCL_CLOSE_SOCKET(m_sockSend);
            if(m_sock > 0)
                FCL_CLOSE_SOCKET(m_sock);
            return iRet;
        }
        
        //数据发送给服务端
        int CMultiCastClient::SendMCast_Msg(char *pData,unsigned int iLen,unsigned short usRspCode) //发送命令
        {
            //发送组播数据
            struct sockaddr_in addr;
            memset(&addr,0,sizeof(addr));
            addr.sin_family = AF_INET;
            addr.sin_addr.s_addr = inet_addr(m_szMCastIpAddr);
            addr.sin_port = htons(m_usMCastPort);
            int iRet = sendto(m_sockSend,pData,iLen,0,(struct sockaddr*)&addr,sizeof(addr));
            if ( iRet != iLen )
            {
#ifdef _WIN32
                errno = WSAGetLastError();
#endif
                ERROR_TRACE("SendMCast_Msg socket sendto() failed,error code="<<errno);
                return -1;
            }
            
            return 0;
        }
        int CMultiCastClient::OnDataRecv(char szBuf[],int iLen)
        {
            bool bSingle = true;
            if ( 32 > iLen )
            {
                ERROR_TRACE("CMultiCastClient::OnDataRecv() recv data too short");
                return -1;
            }
            
            dvip_hdr hdr;//32字节头
            memset(&hdr,0,sizeof(dvip_hdr));
            memcpy(&hdr,&szBuf[0],DVIP_HDR_LENGTH);
            if (hdr.message_length > 0)
            {
                Json::Reader jsonParser;
                Json::Value jsonContent;
                bool bRet = true;
                
                bRet = jsonParser.parse(szBuf+DVIP_HDR_LENGTH,szBuf+DVIP_HDR_LENGTH+hdr.message_length,jsonContent);
                if ( !bRet )
                {
                    ERROR_TRACE("parse msg body failed");
                    return -1;
                }
                
                //
                if ( jsonContent["method"].isNull()
                    || !jsonContent["method"].isString() ) //方法
                {
                    ERROR_TRACE("no method or method type is not string.");
                    return -1;
                }
                std::string strMethod = jsonContent["method"].asString();
                if ( strMethod != "client.notifyDevInfo" )
                {
                    WARN_TRACE("invalid notification method.method="<<strMethod);
                    return 0;
                }
                
                std::string strTmp = jsonContent.toUnStyledString();
                std::string strType;
                if (!jsonContent["params"]["deviceInfo"]["DeviceType"].isNull() 
                    && jsonContent["params"]["deviceInfo"]["DeviceType"].isString())
                {
                    strType = jsonContent["params"]["deviceInfo"]["DeviceType"].asString();
                }
                
                if (strType != "SHG2000A" && strType != "shsg")
                {
                    WARN_TRACE("invalid device type: "<<strType);
                    return 0;
                }
                
                Json::Value jsonResult;
                jsonResult["DeviceType"]=strType;
                if ( !jsonContent["mac"].isNull() && jsonContent["mac"].isString() ) 
                {
                    jsonResult["mac"]=jsonContent["mac"];
                }		
                if ( !jsonContent["params"]["deviceInfo"]["SerialNo"].isNull() 
                    &&jsonContent["params"]["deviceInfo"]["SerialNo"].isString() ) 
                {
                    jsonResult["SerialNo"]=jsonContent["params"]["deviceInfo"]["SerialNo"];
                }
                if ( !jsonContent["params"]["deviceInfo"]["MachineName"].isNull() 
                    &&jsonContent["params"]["deviceInfo"]["MachineName"].isString() ) 
                {
                    jsonResult["MachineName"]=jsonContent["params"]["deviceInfo"]["MachineName"];
                }
                if ( !jsonContent["params"]["deviceInfo"]["Version"].isNull() 
                    &&jsonContent["params"]["deviceInfo"]["Version"].isString() ) 
                {
                    jsonResult["Version"]=jsonContent["params"]["deviceInfo"]["Version"];
                }
                if ( !jsonContent["params"]["deviceInfo"]["Port3"].isNull() 
                    &&jsonContent["params"]["deviceInfo"]["Port3"].isString() ) 
                {
                    jsonResult["Port"]=jsonContent["params"]["deviceInfo"]["Port3"];
                }
                if ( !jsonContent["params"]["deviceInfo"]["IPv4Address"]["IPAddress"].isNull() 
                    &&jsonContent["params"]["deviceInfo"]["IPv4Address"]["IPAddress"].isString() ) 
                {
                    jsonResult["IPv4Address"]["IPAddress"]=jsonContent["params"]["deviceInfo"]["IPv4Address"]["IPAddress"];
                }
                if ( !jsonContent["params"]["deviceInfo"]["IPv4Address"]["SubnetMask"].isNull() 
                    &&jsonContent["params"]["deviceInfo"]["IPv4Address"]["SubnetMask"].isString() ) 
                {
                    jsonResult["IPv4Address"]["SubnetMask"]=jsonContent["params"]["deviceInfo"]["IPv4Address"]["SubnetMask"];
                }
                if ( !jsonContent["params"]["deviceInfo"]["IPv4Address"]["DefaultGateway"].isNull() 
                    &&jsonContent["params"]["deviceInfo"]["IPv4Address"]["DefaultGateway"].isString() ) 
                {
                    jsonResult["IPv4Address"]["DefaultGateway"]=jsonContent["params"]["deviceInfo"]["IPv4Address"]["DefaultGateway"];
                }
                std::string strContent = jsonResult.toUnStyledString();
                INFO_TRACE(strContent);
                
                if (m_pIPSearchcb)
                {
                    m_pIPSearchcb((char*)strContent.c_str(),m_pIPSearchUser);
                }
            }
            
            return 0;
        }
