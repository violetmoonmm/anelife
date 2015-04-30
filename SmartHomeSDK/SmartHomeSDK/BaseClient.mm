#include "BaseClient.h"
#include "DvrGeneral.h"

unsigned int CBaseClient::s_ui_RequestId = 0;


void HexToBinary(char *dst, const char *src)
{
    int count = strlen(src) >> 1;
    for (int i = 0; i < count; i++)
    {
        unsigned char hi = src[2*i+0];
        unsigned char lo = src[2*i+1];
        if      (hi>='0'&&hi<='9') hi = hi-'0';
        else if (hi>='a'&&hi<='f') hi = hi-'a'+10;
        else if (hi>='A'&&hi<='F') hi = hi-'A'+10;
        else    hi = 0;
        if      (lo>='0'&&lo<='9') lo = lo-'0';
        else if (lo>='a'&&lo<='f') lo = lo-'a'+10;
        else if (lo>='A'&&lo<='F') lo = lo-'A'+10;
        else    lo = 0;
        dst[i] = (hi<<4) + lo;
    }
}

void BinaryToHex(char *dst, const char *src, int srclen)
{
    for (int i = 0; i < srclen; i++)
    {
        unsigned char hi = (unsigned char)src[i] >> 4;
        unsigned char lo = src[i] & 15;
        dst[2*i+0] = (hi<10) ? (hi+'0') : (hi-10+'A');
        dst[2*i+1] = (lo<10) ? (lo+'0') : (lo-10+'A');
    }
    dst[2*srclen] = '\0';
}

CBaseClient::CBaseClient(void)
{
    m_hThread = 0;
    m_hWorkThread = 0;
    m_bExitThread = true;
    
    m_cbOnDisConnect = 0;
    m_pUser = 0;
    
    m_cbOnEventNotify = NULL;
    m_pEventNotifyUser = NULL;
    m_sSock = FCL_INVALID_SOCKET;
    m_nConnStatus = 0;
    m_emStatus = emNone;
    
    m_waittime = 5000;
    m_error = 0;
    
    memset(m_szRecvBuf,0,MAX_BUF_LEN);
    m_iRecvIndex = 0;
    
    m_uiSessionId = 0; //µ«¬ºª·ª∞id
    
    //±æ∂À–≈œ¢
    m_strUsername = "";  //”√ªß√˚
    m_strPassword = "";  //√‹¬Î
    
    //∑˛ŒÒ∂À–≈œ¢
    m_strServIp = ""; //∑˛ŒÒ∂Àip
    m_iServPort = 0;		 //∑˛ŒÒ∂À∂Àø⁄
    
    m_bAutoConnect = false;
    
    m_uiLoginId = 0;
    
    m_iRegFailedTimes = 0;
    m_llLastTime = 0;
    m_llLastHeartbeatTime = 0;
}

CBaseClient::~CBaseClient(void)
{
    
}

int CBaseClient::Start()
{
    if ( 0 != StartThread() )
    {
        ERROR_TRACE("start thread failed.");
        return -1;
    }
    return 0;
}

int CBaseClient::Stop()
{
    if ( 0 != StopThread() )
    {
        ERROR_TRACE("stop thread failed.");
        return -1;
    }
    return 0;
}

int CBaseClient::Connect(char *pszIp,int iPort) //¡¨Ω”
{
    int iRet;
    
    if ( m_sSock != FCL_INVALID_SOCKET )
    {
        FCL_CLOSE_SOCKET(m_sSock);
    }
    m_sSock = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
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
    
    //SetTcpKeepalive(m_sSock);
    sockaddr_in servAddr;
    servAddr.sin_family = AF_INET;
    servAddr.sin_addr.s_addr = inet_addr(pszIp);
    servAddr.sin_port = htons(iPort);
    iRet = connect(m_sSock,(struct sockaddr*) &servAddr,sizeof(servAddr));
    if ( FCL_SOCKET_ERROR == iRet )
    {
#ifdef PLAT_WIN32
        if ( WSAEWOULDBLOCK == WSAGetLastError() )
        {
#else
            if ( EINPROGRESS == WSAGetLastError() )
            {
#endif
                m_nConnStatus = 1;
                
                long long llStart = GetCurrentTimeMs();
                long long llEnd;
                bool bResult = false;
                //◊Ë»˚,µ»¥˝¡¨Ω”
                do
                {
                    if ( m_nConnStatus == 2 ) //¡¨Ω”≥…π¶
                    {
                        bResult = true;
                    }
                    else if (m_nConnStatus == 0) //¡¨Ω” ß∞‹
                    {
                        bResult = true;
                    }
                    else
                    {
                        FclSleep(1);
                    }
                    llEnd = GetCurrentTimeMs();
                    
                }while( _abs64(llEnd-llStart) < 1*1000 && !bResult );
                
                if (bResult == true && m_nConnStatus == 2)//¡¨Ω”≥…π¶
                {
                    INFO_TRACE("connect ok."<<" pszIp="<<pszIp<<" m_sSock="<<m_sSock);
                    return 1;
                }
                else
                {
                    m_nConnStatus = 0;
                    ERROR_TRACE("connect timeout!"<<" pszIp="<<pszIp<<" m_sSock="<<m_sSock);
                    FCL_CLOSE_SOCKET(m_sSock);
                }
                return -1;
            }
            else // ß∞‹
            {
                m_nConnStatus = 0;
                ERROR_TRACE("connect failed immediately,errno="<<WSAGetLastError()<<" pszIp="<<pszIp<<" m_sSock="<<m_sSock);
                FCL_CLOSE_SOCKET(m_sSock);
                return -1;
            }
        }
        else
        {
            INFO_TRACE("connect ok immediately!"<<" m_sSock="<<m_sSock);
            m_nConnStatus = 2;
            
            return 1;
        }
        
        return 0;
    }
    
    void CBaseClient::Close()
    {
        FCL_CLOSE_SOCKET(m_sSock);
        m_nConnStatus = 0;
        m_iRecvIndex = 0;
        memset(m_szRecvBuf,0,MAX_BUF_LEN);
    }
    
    
    //∆Ù∂Ø
    int CBaseClient::StartThread()
    {
        m_bExitThread = false;
#ifdef PLAT_WIN32
        DWORD dwThreadId;
        m_hThread = CreateThread(NULL,0,CBaseClient::ThreadProc,this,0,&dwThreadId);
        m_hWorkThread = CreateThread(NULL,0,CBaseClient::ThreadRun,this,0,&dwThreadId);
        
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
        
        if ((iRet = ::pthread_create(&m_hThread, &attr,CBaseClient::ThreadProc, this)) != 0)
        {
            ERROR_TRACE("pthread_create() failed! error code="<<iRet);
            ::pthread_attr_destroy(&attr);
            return -1;
        }
        
        if ((iRet = ::pthread_create(&m_hWorkThread, &attr,CBaseClient::ThreadRun, this)) != 0)
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
    int CBaseClient::StopThread()
    {
        m_bExitThread = true;
        if ( 0 == m_hThread && 0 == m_hWorkThread)
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
        
        dwRet = WaitForSingleObject(m_hWorkThread,5000);
        if ( dwRet == WAIT_TIMEOUT )
        {
            TerminateThread(m_hWorkThread,0);
        }
#else
        void *result;
        pthread_join(m_hThread,&result);
        pthread_join(m_hWorkThread,&result);
#endif
        
        m_hThread = 0;
        m_hWorkThread = 0;
        
        return 0;
    }
#ifdef WIN32
    unsigned long __stdcall CBaseClient::ThreadProc(void *pParam)
#else
    void* CBaseClient::ThreadProc(void *pParam)
#endif
    {
        CBaseClient *pUser = (CBaseClient*)pParam;
        pUser->ThreadProc();
        return 0;
    }
    
    void CBaseClient::ThreadProc(void)
    {
        while ( !m_bExitThread )
        {
            Thread_Process();
            FclSleep(1);
        }
    }
    
#ifdef WIN32
    unsigned long __stdcall CBaseClient::ThreadRun(void *pParam)
#else
    void* CBaseClient::ThreadRun(void *pParam)
#endif
    {
        CBaseClient *pUser = (CBaseClient*)pParam;
        pUser->ThreadRun();
        return 0;
    }
    
    void CBaseClient::ThreadRun(void)
    {
        while ( !m_bExitThread )
        {
            Thread_Run();
            FclSleep(1);
        }
    }
    
    void CBaseClient::Thread_Run()
    {
        //ºÏ≤È∂® ±∆˜
        long long llCur = GetCurrentTimeMs();
        int iRet;
        
        switch ( m_emStatus )
        {
            case emIdle: //ø’œ–◊¥Ã¨ ±◊‘∂Ø÷ÿ¡¨
            {
                if (!m_bAutoConnect)//≤ª”√µ«¬Ω
                {
                    break;
                }
                
                unsigned int uiReconnectInteval = 0;
                if (m_iRegFailedTimes > 3)
                    uiReconnectInteval = CBaseClient::GS_RECONNECT_INTEVAL*4;
                else
                    uiReconnectInteval = CBaseClient::GS_RECONNECT_INTEVAL;
                if ( _abs64(m_llLastTime-GetCurrentTimeMs()) > uiReconnectInteval/*CDvipClient::GS_RECONNECT_INTEVAL*/ )
                {
                    if (!IsConnected())
                    {
                        Close();
                        iRet = Connect((char*)m_strServIp.c_str(),m_iServPort);
                        if ( iRet < 0 )
                        {
                            OnRegisterFailed(emDisRe_ConnectFailed);
                            break;
                        }
                    }
                    AutoReconnect();
                }
                break;
            }
            case emRegistered:
            {
                if ( _abs64(m_llLastHeartbeatTime-GetCurrentTimeMs()) > CBaseClient::GS_HEARTBEAT_INTERVAL)
                {
                    if ( _abs64(m_llLastTime-GetCurrentTimeMs()) > CBaseClient::GS_MAX_HEARTBEAT_TIMEOUT )
                    {
                        //ªÿµ˜…œ≤„,±£ªÓ ß∞‹
                        ERROR_TRACE("keepalive timeout.");
                        OnTcpDisconnect(emDisRe_Keepalivetimeout);
                    }
                    else //∑¢ÀÕ±£ªÓ«Î«Û
                    {
                        m_llLastHeartbeatTime = llCur;
                        
                        KeepAlive();
                    }
                }
                else
                {
                    //∂©‘ƒ¬÷—Ø
                    Process_Task();
                }
                
                break;
            }
            default:
                //WARN_TRACE("unknown status="<<m_emStatus);
                break;
        }
        
        return ;
    }
    
    void CBaseClient::Thread_Process()
    {
        int fds;
        timeval tv;
        int iTotal;
        fd_set fd_send;
        fd_set fd_recv;
        fd_set fd_expt;
        
        bool bIsConnecting = false;
        
        tv.tv_sec = 0;
        tv.tv_usec = 10*1000;
        fds = 0;
        FD_ZERO(&fd_recv);
        FD_ZERO(&fd_send);
        FD_ZERO(&fd_expt);
        
        //¥¶¿Ì√ø∏ˆª·ª∞
        if ( FCL_INVALID_SOCKET == m_sSock )
        {
            return;
        }
        
        if ( 1 == m_nConnStatus ) //’˝‘⁄¡¨Ω”
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
        iTotal = select(fds+1,&fd_recv,&fd_send,&fd_expt,&tv);
#ifdef PLAT_WIN32
        if ( SOCKET_ERROR == iTotal )
        {
            errno = WSAGetLastError();
            ERROR_TRACE("socket select error. errno="<<errno<<"."<<" m_sSock="<<m_sSock);
            return;
        }
#else
        if ( -1 == iTotal )
        {
            ERROR_TRACE("socket select error. errno="<<errno<<"."<<" m_sSock="<<m_sSock);
            return ;
        }
#endif
        if ( iTotal == 0 ) //≥¨ ±
        {
            //WARN_TRACE("select timeout!"<<" m_sSock="<<m_sSock);
            //continue;
            return;
        }
        
        if ( FD_ISSET(m_sSock,&fd_recv) )
        {
            if (m_nConnStatus == 2)
            {
                OnDataRecv();
            }
            return;
        }
        else if ( FD_ISSET(m_sSock,&fd_send) )
        {
            if ( bIsConnecting ) //¡¨Ω”≥…π¶
            {
                int iSockErr = 0;
                int iAddrSize = sizeof(iSockErr);
                
                int iRet = 0;
#ifdef PLAT_WIN32
                iRet = getsockopt(m_sSock,SOL_SOCKET,SO_ERROR,(char*)&iSockErr,&iAddrSize);
#else
                iRet = getsockopt(m_sSock,SOL_SOCKET,SO_ERROR,(char*)&iSockErr,(socklen_t*)&iAddrSize);
#endif
                if ( 0 == iRet && iSockErr == 0 ) //»∑»œ≥…π¶
                {
                    //Õ®÷™¡¨Ω”≥…π¶
                    OnConnect(2);
                }
                else // ß∞‹
                {
                    ERROR_TRACE("getsockopt failed! errno="<<iSockErr<<" m_sSock="<<m_sSock);
                    OnConnect(0);
                }
                return;
            }
            else
            {
                OnDataSend();
                return;
            }
        }
        else if ( FD_ISSET(m_sSock,&fd_expt))
        {
            ERROR_TRACE("fd_expt failed!"<<" m_sSock="<<m_sSock);
            OnConnect(0);
            //’‚¿Ôø…“‘»œŒ™¡¨Ω”∂œø™£¨ªÿµ˜Õ®÷™…œ≤„£¨”…”⁄µ±«∞¡¨Ω”ªπ”–±£ªÓ£¨À˘“‘Œ¥‘¯¥¶¿Ì
            return;
        }
        else
        {
            return ;
        }
    }
    
    void CBaseClient::OnConnect(int iConnStatus) //¡¨Ω”≥…π¶Õ®÷™
    {
        m_nConnStatus = iConnStatus;
        m_iRecvIndex = 0;
    }
    
    void CBaseClient::OnDataRecv() //Ω” ’ ˝æ›Õ®÷™
    {
        //Ω” ’ ˝æ›
        int iDataLen;
        if (m_iRecvIndex == 0)
        {
            memset(m_szRecvBuf,0,MAX_BUF_LEN);
        }
        iDataLen = recv(m_sSock,&m_szRecvBuf[m_iRecvIndex],MAX_BUF_LEN-m_iRecvIndex,0);
        if ( iDataLen < 0 )
        {
            int error = WSAGetLastError();
#ifdef PLAT_WIN32
            if ( WSAEWOULDBLOCK == error ||  EINTR == error)
            {
#else
                if ( EINPROGRESS == error || EINTR == error)//¥¶¿Ì÷–ªÚ±ª÷–∂œ
                {
#endif
                    
                }
                else
                {
                    ERROR_TRACE("recv failed.err="<<WSAGetLastError()<<" m_sSock="<<m_sSock);
                    OnTcpDisconnect(emDisRe_Disconnected);
                }
            }
            else if ( 0 == iDataLen ) //disconnect
            {
                ERROR_TRACE("recv failed.close from server"<<" m_sSock="<<m_sSock);
                OnTcpDisconnect(emDisRe_Disconnected);
            }
            else
            {
                m_iRecvIndex += iDataLen;
                OnDealData();
            }
            
            return ;
        }
        
        void CBaseClient::OnDataSend() //ø…“‘∑¢ÀÕ ˝æ›Õ®÷™
        {
            CMutexGuardT<CMutexThreadRecursive> theLock(m_senLock);
            if ( _lstSend.size() == 0 ) //ª∫≥Â«¯√ª”– ˝æ›
            {
                return;
            }
            std::list<SendPacket*>::iterator it;
            int iSendedSize;
            SendPacket *pPack/* = *it*/;
            for(it = _lstSend.begin();it!=_lstSend.end();it++)
            {
                /*SendPacket **/pPack = *it;
                //iSendedSize =_socket.Send((&pPack->_buf[pPack->_sendIndex]),pPack->_bufSize-pPack->_sendIndex);
                iSendedSize = send(m_sSock,&pPack->_buf[pPack->_sendIndex],pPack->_bufSize-pPack->_sendIndex,0);
                if ( iSendedSize != pPack->_bufSize-pPack->_sendIndex )
                {
                    if ( iSendedSize > 0 )
                    {
                        pPack->_sendIndex += iSendedSize;
                    }
                    break;
                }
                else
                {
                    pPack->_sendIndex = pPack->_bufSize;
                }
                
            }
            //if ( (*it)->_sendIndex == (*it)->_bufSize ) //µ±«∞∞¸“—æ≠∑¢ÀÕÕÍ≥…
            if ( pPack->_sendIndex == pPack->_bufSize ) //µ±«∞∞¸“—æ≠∑¢ÀÕÕÍ≥…
            {
                //return 0;
            }
            else //√ª”–∑¢ÀÕÕÍ≥…
            {
                if ( it == _lstSend.begin() )
                {
                    return;
                }
                it--;
            }
            
            for(std::list<SendPacket*>::iterator it2 = _lstSend.begin();it2!=it;it2++)
            {
                /*SendPacket **/pPack = *it2;
                //it2++;
                //_lstSend.erase(pPack/*it2*/);
                delete pPack;
            }
            _lstSend.erase(_lstSend.begin(),it);
        }
        
        int CBaseClient::OnDealData()
        {
            m_iRecvIndex = 0;
            return 0;
        }
        
        void CBaseClient::OnTcpDisconnect(int iReason)
        {
            EmStatus m_emPreStatus = m_emStatus;
            
            Close();
            Clear_Tasks();
            m_llLastTime = GetCurrentTimeMs();
            m_emStatus = emIdle;
            m_error = iReason;
            
            if (m_emPreStatus == emRegistered)
            {
                m_bAutoConnect = true;
                INFO_TRACE("disconnect.reason="<<iReason<<" m_uiLoginId="<<m_uiLoginId);
                OnDisconnect(iReason);
            }
        }
        
        //◊¢≤·≥…π¶Õ®÷™
        void CBaseClient::OnRegisterSuccess(int iReason)
        {
            m_emStatus = emRegistered;
            m_bAutoConnect = false;
            m_error = 0;
            m_llLastTime = GetCurrentTimeMs();
            m_llLastHeartbeatTime = GetCurrentTimeMs();
            
            m_iRegFailedTimes = 0;
            INFO_TRACE("register OK.m_uiLoginId="<<m_uiLoginId);
        }
        void CBaseClient::OnRegisterFailed(int iReason)
        {
            m_emStatus = emIdle;
            m_error = iReason;
            m_bAutoConnect = true;
            m_llLastTime = GetCurrentTimeMs();
            
            m_iRegFailedTimes++;
            INFO_TRACE("register failed.reason="<<iReason<<" m_uiLoginId="<<m_uiLoginId);
        }
        //
        //int CBaseClient::SendData(char *pData,int iDataLen) //∑¢ÀÕ ˝æ›
        //{
        //	int iSendLen;
        //	iSendLen = send(m_sSock,pData,iDataLen,0);
        //	if ( iSendLen == iDataLen ) //»´≤ø∑¢ÀÕÕÍ≥…
        //	{
        //		return iSendLen;
        //	}
        //	else if ( iSendLen == FCL_SOCKET_ERROR ) //∑¢ÀÕ ß∞‹
        //	{
        //		ERROR_TRACE("send failed.err="<<WSAGetLastError()<<" send len="<<iSendLen);
        //		return iSendLen;
        //	}
        //	else //≤ø∑÷∑¢ÀÕÕÍ≥…, £”‡Œ¥∑¢ÀÕ≤ø∑÷¥¶¿Ì:‘› ±√ª”–¥¶¿Ì
        //	{
        //		return iSendLen;
        //	}
        //}
        
        void CBaseClient::ClearSend()//«Âø’∑¢ÀÕª∫≥Â
        {
            CMutexGuardT<CMutexThreadRecursive> theLock(m_senLock);
            std::list<SendPacket*>::iterator it;
            SendPacket *pTemp;
            for(it=_lstSend.begin();it!=_lstSend.end();it++)
            {
                pTemp = *it;
                if ( pTemp )
                {
                    delete pTemp;
                    pTemp = NULL;
                }
            }
            _lstSend.clear();
        }
        
        int CBaseClient::SendData(char *pData,int iLen)
        {
            CMutexGuardT<CMutexThreadRecursive> theLock(m_senLock);
            if ( _lstSend.size() != 0 ) //∑¢ÀÕª∫≥Â÷–“—æ≠”– ˝æ›,÷±Ω”ÃÓ»Î∑¢ÀÕª∫≥Â
            {
                SendPacket *pPack = new SendPacket();
                if ( !pPack )
                {
                    return 0;
                }
                pPack->_buf = new char[iLen];
                if ( !pPack->_buf )
                {
                    return 0;
                }
                pPack->_bufSize = iLen;
                memcpy(pPack->_buf,pData,iLen);
                _lstSend.push_back(pPack);
                return 0;
            }
            
            int iSendedSize;
            iSendedSize = send(m_sSock,pData,iLen,0);
            if ( iSendedSize != iLen )
            {
                if ( iSendedSize <= 0 )
                {
                    bool bIsBlocked = false;
                    DWORD dwErr;
                    
#ifdef PLAT_WIN32
                    dwErr = WSAGetLastError();
                    if ( SOCKET_ERROR == iSendedSize && dwErr == WSAEWOULDBLOCK )
                    {
                        bIsBlocked = true;
                    }
#else
                    dwErr = errno;
                    if ( -1 == iSendedSize && EINPROGRESS == dwErr )
                    {
                        bIsBlocked = true;
                    }
#endif
                    
                    if ( !bIsBlocked )
                    {
                        ERROR_TRACE("send failed.err="<<dwErr<<" m_sSock="<<m_sSock);
                        return -1;
                    }
                    SendPacket *pPack = new SendPacket();
                    if ( !pPack )
                    {
                        return 0;
                    }
                    pPack->_buf = new char[iLen];
                    if ( !pPack->_buf )
                    {
                        return 0;
                    }
                    pPack->_bufSize = iLen;
                    memcpy(pPack->_buf,pData,iLen);
                    _lstSend.push_back(pPack);
                    return 0;
                }
                else //√ª”–∑¢ÀÕÕÍ»´
                {
                    SendPacket *pPack = new SendPacket();
                    if ( !pPack )
                    {
                        return 0;
                    }
                    pPack->_buf = new char[iLen-iSendedSize];
                    if ( !pPack->_buf )
                    {
                        return 0;
                    }
                    pPack->_bufSize = iLen-iSendedSize;
                    memcpy(pPack->_buf,pData+iSendedSize,iLen-iSendedSize);
                    _lstSend.push_back(pPack);
                    return 0;
                    
                }
            }
            else
            {
                //_lastActionTime = time(NULL); //…œ¥ŒªÓ‘æ ±º‰
            }
            return 0;
        }
        
        void CBaseClient::Process_Task()
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
                    INFO_TRACE("timeout,remove seq "<<it->first<<" type="<<pTask->type);
                    if (pTask)
                    {
                        pTask->result = TransInfo::emTaskStatus_Timeout;
                        pTask->hEvent.Signal();
                    }
                    
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
        void CBaseClient::Clear_Tasks()
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
                pTask = (TransInfo*)it->second;
                if (pTask)
                {
                    INFO_TRACE("cancel seq "<<it->first<<" type="<<pTask->type);
                    
                    pTask = it->second;
                    pTask->result = TransInfo::emTaskStatus_Cancel;
                    pTask->hEvent.Signal();
                }
            }
            
            m_reqList.clear();
            
            return ;
        }
        
        
        CDvipMsg * CBaseClient::CreateMsg(EmRequestType emType)
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
                    
                    ///////////÷«ƒ‹º“æ”//////////////
                    
                default:
                    break;
            }
            return pMsg;
        }
        
        //¥¥Ω®∂‘œÛ µ¿˝ »´æ÷ µ¿˝
        int CBaseClient::Dvip_instance(char *pszMethod,unsigned &uiObject,int iTimeout,std::string strGwVCode)
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
            
            CMsgDvip_instance_req *pInstanceReq = new CMsgDvip_instance_req(uiReq,m_uiSessionId,pszMethod);
            pReqMsg = pInstanceReq;
            emReqType = emRT_instance;
            
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
            //∑¢ÀÕ ˝æ›
            iDataLength = iRet;
            iSendLength = DvipSend(uiReq,pszMethod,szBuf,iDataLength,strGwVCode);
            if ( 0 > iSendLength )
            {
                if ( pTask )
                {
                    delete pTask;
                    pTask = NULL;
                }
                return -1;
            }
            
            AddRequest(uiReq,pTask);
            
            iRet = pTask->hEvent.Wait(0);
            if ( TransInfo::emTaskStatus_Success != pTask->result )
            {
                //ERROR_TRACE("instance failed");
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
        
        //¥¥Ω®∂‘œÛ µ¿˝ Õ®π˝…Ë±∏id
        int CBaseClient::Dvip_instance(char *pszMethod,char *pszDeviceId,unsigned &uiObject,int iTimeout,std::string strGwVCode)
        {
            Json::Value jsParams;
            
            jsParams["DeviceID"] = pszDeviceId;
            return Dvip_instance(pszMethod,jsParams,uiObject,iTimeout,strGwVCode);
        }
        
        //¥¥Ω®∂‘œÛ µ¿˝ »´æ÷ µ¿˝
        int CBaseClient::Dvip_instance(char *pszMethod,const Json::Value &jsParams,unsigned &uiObject,int iTimeout,std::string strGwVCode)
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
            //∑¢ÀÕ ˝æ›
            iDataLength = iRet;
            iSendLength = DvipSend(uiReq,pszMethod,szBuf,iDataLength,strGwVCode);
            if ( 0 > iSendLength )
            {
                ERROR_TRACE("send failed");
                if ( pTask )
                {
                    delete pTask;
                    pTask = NULL;
                }
                return -1;
            }
            AddRequest(uiReq,pTask);
            
            iRet = pTask->hEvent.Wait(0);
            if ( TransInfo::emTaskStatus_Success != pTask->result )
            {
                //ERROR_TRACE("instance failed");
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
        int CBaseClient::Dvip_destroy(char *pszMethod,unsigned uiObject,int iTimeout,std::string strGwVCode)
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
            
            CMsgDvip_destroy_req *pDestroyMsg = new CMsgDvip_destroy_req(uiReq,m_uiSessionId,pszMethod,uiObject);
            pReqMsg = pDestroyMsg;
            emReqType = emRT_destroy;
            
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
            //∑¢ÀÕ ˝æ›
            iDataLength = iRet;
            iSendLength = DvipSend(uiReq,pszMethod,szBuf,iDataLength,strGwVCode);
            if ( 0 > iSendLength )
            {
                if ( pTask )
                {
                    delete pTask;
                }
                return -1;
            }
            AddRequest(uiReq,pTask);
            
            iRet = pTask->hEvent.Wait(0);
            if ( TransInfo::emTaskStatus_Success != pTask->result )
            {
                //ERROR_TRACE("exec failed");
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
            
            CMsgDvip_destroy_rsp *pInstRsp = (CMsgDvip_destroy_rsp*)pTask->pRspMsg;
            
            delete pTask;
            
            return 0;
        }
        //µ˜”√∑Ω∑®  ‰»Î ‰≥ˆ≤Œ ˝Œ™ø’,∑Ω∑®∑µªÿ÷µŒ™bool “ª∞„∫Ø ˝‘≠–Õ bool call(void)
        int CBaseClient::Dvip_method_v_b_v(char *pszMethod,unsigned uiObject,bool &bResult,int iTimeout,std::string strGwVCode)
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
            //∑¢ÀÕ ˝æ›
            iDataLength = iRet;
            iSendLength = DvipSend(uiReq,pszMethod,szBuf,iDataLength,strGwVCode);
            if ( 0 > iSendLength )
            {
                if ( pTask )
                {
                    delete pTask;
                    pTask = NULL;
                }
                return -1;
            }
            AddRequest(uiReq,pTask);
            
            iRet = pTask->hEvent.Wait(0);
            if ( TransInfo::emTaskStatus_Success != pTask->result )
            {
                //ERROR_TRACE("exec failed");
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
        
        //µ˜”√∑Ω∑®  ‰»Î ‰≥ˆ≤Œ ˝Œ™ø’,∑Ω∑®∑µªÿ÷µŒ™bool “ª∞„∫Ø ˝‘≠–Õ bool call(void) ≤ªµ»¥˝ªÿ∏¥
        int CBaseClient::Dvip_method_v_b_v_no_rsp(char *pszMethod,unsigned uiObject,bool &bResult,int iTimeout,std::string strGwVCode)
        {
            int iRet = 0;
            int iDataLength = 0;
            int iSendLength = 0;
            unsigned uiReq;
            char szBuf[1024];
            
            uiReq = CreateReqId();
            CMsg_method_v_b_v_req reqMsg(uiReq,m_uiSessionId,uiObject,pszMethod);
            iRet = reqMsg.Encode(szBuf,1024);
            if ( 0 >= iRet )
            {
                ERROR_TRACE("encode failed.");
                return -1;
            }
            
            //∑¢ÀÕ ˝æ›
            iDataLength = iRet;
            iSendLength = DvipSend(uiReq,pszMethod,szBuf,iDataLength,strGwVCode);
            if ( 0 > iSendLength )
            {
                ERROR_TRACE("send failed");
                return -1;
            }
            
            return 0;
        }
        
        //µ˜”√∑Ω∑®  ‰»Î≤Œ ˝Œ™json(params : {}), ‰≥ˆ≤Œ ˝“≤Œ™json(params : {}),∑Ω∑®∑µªÿ÷µŒ™bool “ª∞„∫Ø ˝‘≠–Õ bool call(void)
        int CBaseClient::Dvip_method_json_b_json(char *pszMethod
                                                 ,unsigned uiObject
                                                 ,Json::Value &inParams
                                                 ,bool &bResult
                                                 ,Json::Value &outParams
                                                 ,int iTimeout
                                                 ,std::string strGwVCode)
        {
            int iRet = 0;
            int iDataLength = 0;
            int iSendLength = 0;
            unsigned uiReq;
            char szBuf[1024*32];
            TransInfo *pTask = NULL;
            
            uiReq = CreateReqId();
            CMsg_method_json_b_json_req reqMsg(uiReq,m_uiSessionId,uiObject,pszMethod,inParams);
            iRet = reqMsg.Encode(szBuf,1024*32);
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
            
            if (!strcmp(pszMethod,"ShareManager.downloadFile"))
            {
                m_uiDownReqId = uiReq;
                INFO_TRACE("ShareManager.downloadFile uiReq="<<uiReq);
            }
            //∑¢ÀÕ ˝æ›
            iDataLength = iRet;
            iSendLength = DvipSend(uiReq,pszMethod,szBuf,iDataLength,strGwVCode);
            if ( 0 > iSendLength )
            {
                if ( pTask )
                {
                    delete pTask;
                    pTask = NULL;
                }
                return -1;
            }
            AddRequest(uiReq,pTask);
            
            iRet = pTask->hEvent.Wait(0);
            if ( TransInfo::emTaskStatus_Success != pTask->result )
            {
                if ( pTask )
                {
                    delete pTask;
                }
                return -1;
            }
            if ( !pTask->pRspMsg )
            {
                WARN_TRACE("no rsp msg!");
                if ( pTask )
                {
                    delete pTask;
                }
            }
            else
            {
                CMsg_method_json_b_json_rsp *pRspMsg = (CMsg_method_json_b_json_rsp*)pTask->pRspMsg;
                bResult = pRspMsg->m_bResult;
                //if ( bResult )
                {
                    outParams = pRspMsg->m_jsParams;
                }
                delete pTask;
            }
            
            return 0;
        }
        
        
        // ’µΩÕ®÷™œ˚œ¢
        void CBaseClient::OnNotification(unsigned int uiLoginId,dvip_hdr &hdr,const char *pData,int pDataLen)
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
            if ( m_uiSid != 0 )
            {
                if ( m_uiSid != uiSID)
                {
                    ERROR_TRACE("SID difference.my sid=."<<m_uiSid<<" received="<<uiSID);
                    return ;
                }
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
                else if ( strEventCode == "VideoTalk") //∫ÙΩ–
                {
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
                    else if ( strDeviceType == "BlanketSocket" ) //Õ®”√≤Â◊˘
                    {
                    }
                    else if ( strDeviceType == "EnvironmentMonitor" ) //ª∑æ≥ºÏ≤‚“«
                    {
                    }
                    else if ( strDeviceType == "SceneMode" ) //ª∑æ≥ºÏ≤‚“«
                    {
                    }
                    else if ( strDeviceType == "BackgroundMusic" ) //ª∑æ≥ºÏ≤‚“«
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
                    
                    if ( m_cbOnEventNotify )
                    {
                        Json::Value jsonEvent;
                        jsonEvent["DeviceID"]=strDeviceId;
                        jsonEvent["Type"]=strDeviceType;
                        jsonEvent["Data"]=jsEvent["Data"]["State"];
                        std::string strEvent = jsonEvent.toUnStyledString();
                        INFO_TRACE("event notify: strEvent="<<strEvent);
                        m_cbOnEventNotify(uiLoginId,emDeviceState,(char*)strEvent.c_str(),m_pEventNotifyUser);
                        //INFO_TRACE("event notify end");
                    }
                }
                else if ( strEventCode == "AlarmLocal" ) //±æµÿ±®æØ
                {
                    std::string strExtInfo;
                    // ¬º˛œÍœ∏ ˝æ›
                    if ( jsEvent["Data"].isNull() || !jsEvent["Data"].isObject() )
                    {
                        WARN_TRACE("no alarm data");
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
                    
                    if ( m_cbOnEventNotify )
                    {
                        Json::Value jsonEvent;
                        char szDeviceId[10]={0};
                        sprintf(szDeviceId,"%d",iEventIndex);//‘›“‘Õ®µ¿∫≈◊ˆDeviceId
                        jsonEvent["DeviceID"]=szDeviceId;
                        jsonEvent["Type"]="AlarmZone";
                        jsonEvent["Action"]=strEventAction;
                        jsonEvent["Data"]=strExtInfo;
                        std::string strEvent = jsonEvent.toUnStyledString();
                        INFO_TRACE("event notify: strEvent="<<strEvent);
                        m_cbOnEventNotify(uiLoginId,emAlarm,(char*)strEvent.c_str(),m_pEventNotifyUser);
                        //INFO_TRACE("event notify end");
                    }
                }
                else if ( strEventCode == "VideoTalk") //∫ÙΩ–
                {
                    if ( m_cbOnEventNotify )
                    {
                        Json::Value jsonEvent;
                        jsonEvent["Type"]="VideoTalk";
                        jsonEvent["Action"]="VideoTalk";
                        jsonEvent["Data"]=jsEvent["Data"].toUnStyledString();
                        std::string strEvent = jsonEvent.toUnStyledString();
                        INFO_TRACE("event notify: strEvent="<<strEvent);
                        m_cbOnEventNotify(uiLoginId,emAlarm,(char*)strEvent.c_str(),m_pEventNotifyUser);
                        //INFO_TRACE("event notify end");
                    }
                }
                //	else if ( strEventCode == "ArmModeChange" ) //±æµÿ±®æØ
                //	{
                //		std::string strExtInfo;
                //		// ¬º˛œÍœ∏ ˝æ›
                //		if ( jsEvent["Data"].isNull() || !jsEvent["Data"].isObject() )
                //		{
                //			WARN_TRACE("no event data");
                //			//continue ;
                //		}
                
                //		std::string strMode;
                //		if ( !jsEvent["Data"].isNull() )
                //		{
                //			strExtInfo = jsEvent["Data"].toUnStyledString();
                //		}
                //		//¥´∏–∆˜¿‡–Õ
                //		if ( !jsEvent["Data"]["Mode"].isNull() && jsEvent["Data"]["Mode"].isString() )
                //		{
                //			strMode = jsEvent["Data"]["Mode"].asString();
                //		}
                //		else
                //		{
                //			strMode = "";
                //		}
                
                //		int iAlarmState = -1;
                //		if (strMode == "Arming")
                //		{
                //			iAlarmState = 21;
                //		}
                //		else if (strMode == "Disarming")
                //		{
                //			iAlarmState = 22;
                //		}
                
                //		//if ( m_cbOnAlarmNotify )
                //		//{
                //		//	m_cbOnAlarmNotify(m_uiLoginId,iEventIndex+1,iAlarmState,(char*)strExtInfo.c_str(),
                //		//		NULL,0,m_pAlarmNotifyUser);
                //		//}
                //	}
            }
            return ;
        }
        
        
        // ’µΩÕ®÷™œ˚œ¢
        int CBaseClient::OnPackage(unsigned int uiLoginId,dvip_hdr &hdr,const char *pData,int pDataLen)
        {
            INFO_TRACE("package: packet_length="<<hdr.packet_length<<" packect_index="<<hdr.packet_index);
            if (hdr.request_id != m_uiDownReqId)
            {
                ERROR_TRACE("package: invalid request id "<<hdr.request_id);
                return -1;
            }
            int iRet = 0;
            if (hdr.packet_index == 0)//µ⁄“ª∞¸ ˝æ›
            {
                INFO_TRACE("package: file start,data_length="<<hdr.data_length<<" message_length="<<hdr.message_length);
                m_pos = 0;
                m_packet_index = hdr.packet_index;
                m_pos+=hdr.packet_length-hdr.message_length;
                
                FILE * fp;
                fp=fopen((char*)m_strLocalPath.c_str(),"wb+");//¥Úø™ø…∂¡–¥Œƒº˛£¨»ÙŒƒº˛¥Ê‘⁄‘ÚŒƒº˛≥§∂»«ÂŒ™¡„£¨º¥∏√Œƒº˛ƒ⁄»›ª·œ˚ ß°£»ÙŒƒº˛≤ª¥Ê‘⁄‘ÚΩ®¡¢∏√Œƒº˛
                if(fp == NULL)
                {
                    ERROR_TRACE("package: fopen failed! m_strLocalPath="<<m_strLocalPath<<" errno="<<errno);
                    iRet = -2;
                }
                else
                {
                    fwrite(pData+hdr.message_length,1,hdr.packet_length-hdr.message_length,fp);
                    fclose(fp);
                }
                
                TransInfo *pTrans;
                pTrans = FetchRequest(hdr.request_id);
                if ( !pTrans )
                {
                    ERROR_TRACE("not find request.reqid="<<hdr.request_id);
                }
                else
                {
                    CDvipMsg *pMsg = CreateMsg(pTrans->type);
                    if ( !pMsg )
                    {
                        ERROR_TRACE("Create msg failed")
                        pTrans->result = TransInfo::emTaskStatus_Failed;
                    }
                    else
                    {
                        int iContentLen = hdr.message_length+DVIP_HDR_LENGTH;
                        char *pContent = new char[iContentLen];
                        if (pContent != NULL)
                        {
                            memcpy(pContent,&hdr,DVIP_HDR_LENGTH);
                            memcpy(pContent+DVIP_HDR_LENGTH,pData,hdr.message_length);
                            iRet = pMsg->Decode((char*)pContent,(unsigned int)iContentLen);
                            delete pContent;
                            if ( 0 != iRet )
                            {
                                ERROR_TRACE("decode msg failed");
                                delete pMsg;
                                pTrans->result = TransInfo::emTaskStatus_Failed;
                            }
                            else
                            {
                                if (m_pos == hdr.data_length)
                                {
                                    m_bSinglePack = true;
                                }
                                pTrans->result = TransInfo::emTaskStatus_Success;
                                pTrans->pRspMsg = pMsg;
                            }
                        }
                        else
                        {
                            pTrans->result = TransInfo::emTaskStatus_Failed;
                            ERROR_TRACE("malloc failed!");
                        }
                    }
                    pTrans->hEvent.Signal();
                }
            }
            else
            {
                if (m_packet_index+1 == hdr.packet_index)//¡¨–¯
                {
                    m_packet_index = hdr.packet_index;
                    m_pos+=hdr.packet_length;
                    
                    FILE * fp;
                    //“‘∏Ωº”∑Ω Ω¥Úø™ø…∂¡–¥µƒŒƒº˛°£»ÙŒƒº˛≤ª¥Ê‘⁄£¨‘Úª·Ω®¡¢∏√Œƒº˛£¨»Áπ˚Œƒº˛¥Ê‘⁄£¨–¥»Îµƒ ˝æ›ª·±ªº”µΩŒƒº˛Œ≤∫Û£¨º¥Œƒº˛‘≠œ»µƒƒ⁄»›ª·±ª±£¡Ù°£
                    fp=fopen((char*)m_strLocalPath.c_str(),"ab+");
                    if(fp == NULL)
                    {
                        ERROR_TRACE("package: fopen failed! m_strLocalPath="<<m_strLocalPath<<" errno="<<errno);
                        remove((char*)m_strLocalPath.c_str());
                        iRet = -2;
                    }
                    else
                    {
                        fwrite(pData,1,hdr.packet_length,fp);
                        fclose(fp);
                    }
                }
                else//◊È∞¸¥ÌŒÛ£¨ÕÀ≥ˆ
                {
                    ERROR_TRACE("package: index error! m_strLocalPath="<<m_strLocalPath);
                    remove((char*)m_strLocalPath.c_str());
                    m_pos = 0;
                    m_packet_index = 0;
                    iRet = -3;
                }
            }
            
            bool bEnd = false;
            bool bResult = false;
            if (iRet < 0)
            {
                bEnd = true;
            }
            else
            {
                if(hdr.data_length== m_pos)//◊Ó∫Û“ª∞¸
                {
                    INFO_TRACE("OnPackage: file end");
                    m_pos = 0;
                    m_packet_index = 0;
                    if (hdr.packet_index>0)//∂‡∞¸
                    {
                        bEnd = true;
                        bResult = true;
                    }
                }
            }
            
            if (bEnd)
            {
                Json::Value jsonEvent;
                //jsonEvent["DeviceID"]="";
                //jsonEvent["Type"]="DownFile";
                jsonEvent["Data"]["FilePath"]=m_strShareFile;
                jsonEvent["Data"]["LocalPath"]=m_strLocalPath;
                jsonEvent["Data"]["Result"]=bResult;
                std::string strEvent = jsonEvent.toUnStyledString();
                INFO_TRACE("event notify: strEvent="<<strEvent);
                
                m_uiDownReqId = 0;
                m_strLocalPath = "";
                m_strShareFile = "";
                
                //‘∂≥Ãƒ£ Ω”…–È∫≈’“µ«¬Ωid
                m_cbOnEventNotify(uiLoginId,emDownFile,(char*)strEvent.c_str(),m_pEventNotifyUser);
            }
            
            return 0;
        }
        
        //∂¡»°≈‰÷√ Ãÿ∂®≈‰÷√
        int CBaseClient::GetConfig(const std::string &strName,std::string &strConfig,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;;
            int iReturn = 0;
            
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("configManager.factory.instance",uiObjectId,m_waittime,strGwVCode);
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
            
            Json::Value jsonInParams;
            Json::Value jsonOutParams;
            jsonInParams["name"] = (char*)strName.c_str();
            
            std::string strMethod = "configManager.getConfig";
            iRet = Dvip_method_json_b_json((char*)strMethod.c_str(),uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            
            if ( 0 > iRet )
            {
                ERROR_TRACE(strMethod<<" exec failed.");
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    INFO_TRACE(strMethod<<" response ok. strName="<<strName);
                    strConfig = jsonOutParams.toUnStyledString();
                    //strConfig = jsonOutParams.toStyledString();
                    iReturn = 0;
                    INFO_TRACE(strConfig);
                }
                else
                {
                    ERROR_TRACE(strMethod<<" response failed. strName="<<strName);
                    iReturn = -1;
                }
            }
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy("configManager.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("configManager destroy failed.");
                //return -1;
            }
            
            return iReturn;
        }
        
        //…Ë÷√≈‰÷√–≈œ¢
        int CBaseClient::SetConfig(std::string strName,Json::Value jsonConfig,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;;
            int iReturn = 0;
            
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("configManager.factory.instance",uiObjectId,m_waittime,strGwVCode);
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
            
            Json::Value jsonInParams;
            Json::Value jsonOutParams;
            jsonInParams["name"] = strName;
            jsonInParams["table"] = jsonConfig;
            std::string strMethod = "configManager.setConfig";
            iRet = Dvip_method_json_b_json((char*)strMethod.c_str(),uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE(strMethod<<" exec failed.");
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    INFO_TRACE(strMethod<<" response ok. strName="<<strName);
                    
                    iReturn = 0;
                }
                else
                {
                    ERROR_TRACE(strMethod<<" response failed. strName="<<strName);
                    iReturn = -1;
                }
            }
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy("configManager.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("configManager destroy failed.");
                //return -1;
            }
            
            return iReturn;
        }
        
        int CBaseClient::Control(char * pszDevType,char *pszDeviceId,char *pszParams,int iParamsLen,std::string strGwVCode)
        {
            int iRet = 0;
            INFO_TRACE("control pszDevType="<<pszDevType<<" pszDeviceId="<<pszDeviceId<<" pszParams="<<pszParams);
            if (pszParams == NULL || iParamsLen <= 0)
            {
                ERROR_TRACE("invalid params");
                return -1;
            }
            Json::Reader jsonParser;
            Json::Value jsonContent;
            bool bRet;
            bRet = jsonParser.parse(pszParams,jsonContent);
            if ( !bRet )
            {
                ERROR_TRACE("parse params failed");
                return -1;
            }
            
            std::string strAction;
            if (!jsonContent["action"].isNull()&& jsonContent["action"].isString() )
            {
                strAction = jsonContent["action"].asString();
            }
            else
            {
                ERROR_TRACE("no action!");
                return -1;
            }
            
            Json::Value jsonInParams;
            
            char szDevType[32]={0};
            strcpy(szDevType,pszDevType);
            int iType = LookupDeviceType(pszDevType);
            switch (iType)
            {
                case emCommLight://{"action":"open"}
                {
                    strcpy(szDevType,"Light");
                    if (strAction == "open")
                    {
                    }
                    else if (strAction == "close")
                    {
                    }
                    else
                    {
                        WARN_TRACE("unsurport action="<<strAction);
                        return -1;
                    }
                }
                    break;
                case emLevelLight://{"action":"open","Level":-1}
                {
                    strcpy(szDevType,"Light");
                    if (strAction == "open")
                    {
                    }
                    else if (strAction == "close")
                    {
                    }
                    else if (strAction == "setBrightLevel")
                    {
                        if (!jsonContent["Level"].isNull()&& jsonContent["Level"].isInt() )//¡¡∂»µ˜Ω⁄
                        {
                            jsonInParams["Level"] = jsonContent["Level"].asInt();
                        }
                        else
                        {
                            ERROR_TRACE("no level!");
                            return -1;
                        }
                    }
                    else
                    {
                        WARN_TRACE("unsurport action="<<strAction);
                        return -1;
                    }
                }
                    break;
                case emCurtain://{"action":"open","Scale":-1}
                {
                    if (strAction == "open")
                    {
                    }
                    else if (strAction == "close")
                    {
                    }
                    else if (strAction == "stop")
                    {
                    }
                    else if (strAction == "setShading")
                    {
                        if (!jsonContent["Scale"].isNull()&& jsonContent["Scale"].isInt() )//’⁄π‚¬ µ˜Ω⁄
                        {
                            jsonInParams["Scale"] = jsonContent["Scale"].asInt();
                        }
                        else
                        {
                            ERROR_TRACE("no Scale!");
                            return -1;
                        }
                    }
                    else
                    {
                        WARN_TRACE("unsurport action="<<strAction);
                        return -1;
                    }
                }
                    break;
                case emAirCondition:
                {
                    if (strAction == "open")
                    {
                    }
                    else if (strAction == "close")
                    {
                    }
                    else if (strAction == "setTemperature")
                    {
                        if (!jsonContent["Temperature"].isNull()&& jsonContent["Temperature"].isInt() )
                        {
                            jsonInParams["temperature"] = jsonContent["Temperature"].asInt();
                        }
                        else
                        {
                            ERROR_TRACE("no temperature!");
                            return -1;
                        }
                    }
                    else if (strAction == "setMode")
                    {
                        if (!jsonContent["Mode"].isNull()&& jsonContent["Mode"].isString() )
                        {
                            jsonInParams["Mode"] = jsonContent["Mode"].asString();
                        }
                        
                        if (!jsonContent["Temperature"].isNull()&& jsonContent["Temperature"].isInt() )
                        {
                            jsonInParams["Temperature"] = jsonContent["Temperature"].asInt();
                        }
                    }
                    else if (strAction == "setWindMode")
                    {
                        if (!jsonContent["WindMode"].isNull()&& jsonContent["WindMode"].isString() )
                        {
                            jsonInParams["Mode"] = jsonContent["WindMode"].asString();
                        }
                    }
                    else if (strAction == "CompoundControl")
                    {
                        if (!jsonContent["On"].isNull()&& jsonContent["On"].isBool() )
                        {
                            jsonInParams["On"] = jsonContent["On"].asBool();
                        }
                        
                        if (!jsonContent["Mode"].isNull()&& jsonContent["Mode"].isString() )
                        {
                            jsonInParams["Mode"] = jsonContent["Mode"].asString();
                        }
                        
                        if (!jsonContent["Temperature"].isNull()&& jsonContent["Temperature"].isInt() )
                        {
                            jsonInParams["Temperature"] = jsonContent["Temperature"].asInt();
                        }
                        
                        if (!jsonContent["WindMode"].isNull()&& jsonContent["WindMode"].isString() )
                        {
                            jsonInParams["WindMode"] = jsonContent["WindMode"].asString();
                        }
                    }
                    else
                    {
                        WARN_TRACE("unsurport action="<<strAction);
                        return -1;
                    }
                }
                    break;
                case emGroudHeat:
                {
                    if (strAction == "open")
                    {
                    }
                    else if (strAction == "close")
                    {
                    }
                    else if (strAction == "setTemperature")
                    {
                        if (!jsonContent["Temperature"].isNull()&& jsonContent["Temperature"].isInt() )
                        {
                            jsonInParams["temperature"] = jsonContent["Temperature"].asInt();
                        }
                        else
                        {
                            ERROR_TRACE("no temperature!");
                            return -1;
                        }
                    }
                    else
                    {
                        WARN_TRACE("unsurport action="<<strAction);
                        return -1;
                    }
                }
                    break;
                case emBlanketSocket:
                {
                    if (strAction == "open")
                    {
                    }
                    else if (strAction == "close")
                    {
                    }
                    else
                    {
                        WARN_TRACE("unsurport action="<<strAction);
                        return -1;
                    }
                }
                    break;
                case emBackgroundMusic:
                {
                    if (strAction == "open")
                    {
                    }
                    else if (strAction == "close")
                    {
                    }
                    else if (strAction == "pause")
                    {
                    }
                    else if (strAction == "resume")
                    {
                    }
                    else if (strAction == "mute")
                    {
                        if (!jsonContent["Enable"].isNull()&& jsonContent["Enable"].isBool() )
                        {
                            jsonInParams["Enable"] = jsonContent["Enable"].asBool();
                        }
                        else
                        {
                            ERROR_TRACE("no Enable!");
                            return -1;
                        }
                    }
                    else if (strAction == "lastPiece")
                    {
                    }
                    else if (strAction == "nextPiece")
                    {
                    }
                    else if (strAction == "setVolume")
                    {
                        if (!jsonContent["Volume"].isNull()&& jsonContent["Volume"].isInt() )
                        {
                            jsonInParams["Volume"] = jsonContent["Volume"].asInt();
                        }
                        else
                        {
                            ERROR_TRACE("no Volume!");
                            return -1;
                        }
                    }
                    else
                    {
                        WARN_TRACE("unsurport action="<<strAction);
                        return -1;
                    }
                }
                    break;
                default:
                {
                    WARN_TRACE("unsurport device type="<<pszDevType);
                    return -1;
                }
                    break;
            }
            
            //INFO_TRACE("jsonInParams="<<(char*)jsonInParams.toUnStyledString().c_str());
            return general_control(pszDeviceId,szDevType,(char*)strAction.c_str(),jsonInParams,strGwVCode);
        }
        
        int CBaseClient::GetState(char * pszDevType,char *pszDeviceId,
                                  char *szBuf,int iBufSize,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            std::string strMethod;
            if (!strcmp(pszDevType,"All"))//≤È—Ø
            {
                INFO_TRACE("GetState pszDevType="<<pszDevType);
                strMethod = "SmartHomeManager.factory.instance";
                iRet = Dvip_instance((char*)strMethod.c_str(),uiObjectId,m_waittime,strGwVCode);
            }
            else
            {
                INFO_TRACE("GetState pszDevType="<<pszDevType<<" pszDeviceId="<<pszDeviceId);
                //¥¥Ω® µ¿˝
                strMethod = pszDevType;
                strMethod += ".factory.instance";
                iRet = Dvip_instance((char*)strMethod.c_str(),pszDeviceId,uiObjectId,m_waittime,strGwVCode);
            }
            
            if ( 0 != iRet )
            {
                ERROR_TRACE(strMethod<<" failed.");
                return -1;
            }
            if ( 0 == uiObjectId )
            {
                ERROR_TRACE(strMethod<<"from server failed.objectid=0");
                return -1;
            }
            
            Json::Value jsonInParams;
            Json::Value jsonOutParams;
            if (!strcmp(pszDevType,"All"))//≤È—Ø
            {
                strMethod = "SmartHomeManager.getDeviceState";
                jsonInParams["DeviceType"] = "All";
            }
            else
            {
                strMethod = pszDevType;
                strMethod += ".getState";
            }
            
            iRet = Dvip_method_json_b_json((char*)strMethod.c_str(),uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE(strMethod<<" exec failed.");
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    INFO_TRACE(strMethod<<" exec OK.");
                    iReturn = 0;
                    //Ω‚Œˆ
                    std::string strState = jsonOutParams.toUnStyledString();
                    if (strState.length()>iBufSize)
                    {
                        iReturn = -1;
                        ERROR_TRACE("buffer small!iRealSize="<<strState.length()<<" iBufSize="<<iBufSize);
                    }
                    else
                    {
                        memset(szBuf,0,iBufSize);
                        strncpy(szBuf,(char*)strState.c_str(),strState.length());
                        //INFO_TRACE(szBuf);
                    }
                }
                else
                {
                    ERROR_TRACE(strMethod<<" exec failed.");
                    iReturn = -1;
                }
            }
            
            if (!strcmp(pszDevType,"All"))//≤È—Ø
            {
                strMethod = "SmartHomeManager.destroy";
            }
            else
            {
                strMethod = pszDevType;
                strMethod += ".destroy";
            }
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy((char*)strMethod.c_str(),uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE(strMethod<<" failed.");
            }
            
            return iReturn;
        }
        
        int CBaseClient::ReadDevice(char * pszDevType,char *pszDeviceId,
                                    char *pszParams,char *szBuf,int iBufSize,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            INFO_TRACE("ReadDevice pszDevType="<<pszDevType<<" pszDeviceId="<<pszDeviceId);
            
            std::string strMethod;
            
            //¥¥Ω® µ¿˝
            strMethod = pszDevType;
            strMethod += ".factory.instance";
            iRet = Dvip_instance((char*)strMethod.c_str(),pszDeviceId,uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE(strMethod<<" failed.");
                return -1;
            }
            if ( 0 == uiObjectId )
            {
                ERROR_TRACE(strMethod<<" from server failed.objectid=0");
                return -1;
            }
            
            Json::Value jsonInParams;
            Json::Value jsonOutParams;
            strMethod = pszDevType;
            strMethod += ".";
            strMethod +=  pszParams;
            iRet = Dvip_method_json_b_json((char*)strMethod.c_str(),uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE(strMethod<<" exec failed.");
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    INFO_TRACE(strMethod<<" exec OK.");
                    iReturn = 0;
                    //Ω‚Œˆ
                    std::string strState = jsonOutParams.toUnStyledString();
                    if (strState.length()>iBufSize)
                    {
                        iReturn = -1;
                    }
                    else
                    {
                        memset(szBuf,0,iBufSize);
                        strncpy(szBuf,(char*)strState.c_str(),strState.length());
                        INFO_TRACE(szBuf);
                    }
                }
                else
                {
                    ERROR_TRACE(strMethod<<" exec failed.");
                    iReturn = -1;
                }
            }
            
            // Õ∑≈ µ¿˝
            strMethod = pszDevType;
            strMethod += ".destroy";
            iRet = Dvip_destroy((char*)strMethod.c_str(),uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE(strMethod<<" failed.");
            }
            
            return iReturn;
        }
        //ªÒ»°…Ë±∏¡–±Ì–≈œ¢’™“™
        int CBaseClient::GetDeviceDigest_Sync(std::string &strType,std::string &strDigest,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("SmartHomeManager.factory.instance",uiObjectId,m_waittime,strGwVCode);
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
            
            iRet = Dvip_method_json_b_json("SmartHomeManager.getDeviceDigest",uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE("SmartHomeManager.getDeviceDigest exec failed.");
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    INFO_TRACE("SmartHomeManager.getDeviceDigest ok.");
                    
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
            }
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy("SmartHomeManager.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("SmartHomeManager destroy failed.");
                //return -1;
            }
            
            return iReturn;
        }
        
        //ªÒ»°…Ë±∏¡–±Ì
        int CBaseClient::GetDeviceList_Sync(std::string &strType,std::string &strDevices,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("SmartHomeManager.factory.instance",uiObjectId,m_waittime,strGwVCode);
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
            
            iRet = Dvip_method_json_b_json("SmartHomeManager.getDeviceList",uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE("SmartHomeManager.getDeviceList exec failed.");
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    iReturn = 0;
                    if ( !jsonOutParams.isNull())
                    {
                        strDevices = jsonOutParams.toUnStyledString();
                        //strDevices = jsonOutParams.toStyledString();
                    }
                }
                else
                {
                    ERROR_TRACE("SmartHomeManager.getDeviceList exec failed.");
                    iReturn = -1;
                }
            }
            
            INFO_TRACE(strDevices);
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy("SmartHomeManager.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("SmartHomeManager destroy failed.");
                //return -1;
            }
            
            return iReturn;
        }
        
        int CBaseClient::general_control(char *pszDeviceId,char *pszDeviceType,
                                         char * pszAction,Json::Value jsonInParams,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            std::string strMethod;
            
            //¥¥Ω® µ¿˝
            strMethod = pszDeviceType;
            strMethod += ".factory.instance";
            iRet = Dvip_instance((char*)strMethod.c_str(),pszDeviceId,uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE(strMethod<<" failed.");
                return -1;
            }
            if ( 0 == uiObjectId )
            {
                ERROR_TRACE(strMethod<<" from server failed.objectid=0");
                return -1;
            }
            
            Json::Value jsonOutParams;
            
            strMethod = pszDeviceType;
            strMethod += ".";
            strMethod += pszAction;
            iRet = Dvip_method_json_b_json((char*)strMethod.c_str(),uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE(strMethod<<" exec failed.");
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    INFO_TRACE(strMethod<<" exec OK.");
                    iReturn = 0;
                }
                else
                {
                    ERROR_TRACE(strMethod<<" exec failed.");
                    iReturn = -1;
                }
            }
            
            // Õ∑≈ µ¿˝
            strMethod = pszDeviceType;
            strMethod += ".destroy";
            iRet = Dvip_destroy((char*)strMethod.c_str(),uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE(strMethod<<" failed.");
            }
            
            return iReturn;
        }
        
        int CBaseClient::SetSceneMode(std::string &strMode,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("SmartHomeManager.factory.instance",uiObjectId,m_waittime,strGwVCode);
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
            iRet = Dvip_method_json_b_json("SmartHomeManager.setSceneMode",uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE("SmartHomeManager.setSceneMode exec failed.");
                iReturn = -1;
            }
            else
            {
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
            }
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy("SmartHomeManager.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("SmartHomeManager destroy failed.");
                //return -1;
            }
            
            return iReturn;
        }
        
        // ≤º≥∑∑¿
        int CBaseClient::SetArmMode(const char *pszDeviceId,bool bEnable,const char *password,std::string strGwVCode)
        {
            int iReturn = 0;
            bool bExtendAlarm = false;
            int channel = atoi(pszDeviceId);
            if (channel<0)
            {
                ERROR_TRACE("invalid pszDeviceId = "<<pszDeviceId);
                return -1;
            }
            //else if (channel >= 10000)
            //{
            //	channel -= 10000;
            //	bExtendAlarm = true;
            //}
            
            char szChan[11]={0};
            sprintf(szChan,"%d",channel);
            
            Json::Value jsonConfig;
            jsonConfig=bEnable;
            std::string strPath ;
            //if (bExtendAlarm)
            //{
            //	strPath = "ExAlarm[";
            //}
            //else
            {
                strPath = "Alarm[";
            }
            strPath+=szChan;
            strPath+="].Enable";
            
            iReturn = SetConfig((char*)strPath.c_str(),jsonConfig,strGwVCode);
            
            return iReturn;
        }
        
        // »°µ√±®æØ∑¿«¯◊¥Ã¨
        int CBaseClient::GetArmMode(char *pszDeviceId,bool & bEnable,std::string strGwVCode)
        {
            int iRet = 0;
            
            bool bExtendAlarm = false;
            int channel = atoi(pszDeviceId);
            if (channel<0)
            {
                ERROR_TRACE("invalid pszDeviceId = "<<pszDeviceId);
                return -1;
            }
            //else if (channel >= 10000)
            //{
            //	channel -= 10000;
            //	bExtendAlarm = true;
            //}
            
            char szChan[11]={0};
            sprintf(szChan,"%d",channel);
            
            std::string strPath ;
            //if (bExtendAlarm)
            //{
            //	strPath = "ExAlarm[";
            //}
            //else
            {
                strPath = "Alarm[";
            }
            strPath+=szChan;
            strPath+="].Enable";
            
            std::string strConfig;
            iRet = GetConfig(strPath,strConfig,strGwVCode);
            if ( 0 == iRet )
            {
                Json::Value jsonConfig;
                Json::Reader jsonParser;
                bool bRet = jsonParser.parse(strConfig,jsonConfig);
                
                if ( !jsonConfig["table"].isNull()&& jsonConfig["table"].isBool() )
                {
                    bEnable = jsonConfig["table"].asBool();
                }
            }
            
            return iRet;
        }
        
        int CBaseClient::SetExtraBitrate(char *pszDeviceId,int iBitRate,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("IPCamera.factory.instance",pszDeviceId,uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("IPCamera.factory.instance failed.");
                return -1;
            }
            if ( 0 == uiObjectId )
            {
                ERROR_TRACE("IPCamera.factory.instance failed.objectid=0");
                return -1;
            }
            
            Json::Value jsonInParams;
            Json::Value jsonOutParams;
            jsonInParams["BitRate"]=iBitRate;
            iRet = Dvip_method_json_b_json("IPCamera.setExtraBitRate",uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE("IPCamera.setExtraBitRate failed.");
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    ERROR_TRACE("PCamera.setExtraBitRate ok.");
                }
                else
                {
                    ERROR_TRACE("PCamera.setExtraBitRate failed.");
                    iReturn = -1;
                }
            }
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy("IPCamera.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("IPCamera.destroy failed.");
                //return -1;
            }
            
            return iReturn;
        }
        
        //  ”∆µ’⁄µ≤≈‰÷√
        int CBaseClient::GetVideoCovers(char *pszDeviceId,bool &bEnable,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("IPCamera.factory.instance",pszDeviceId,uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("IPCamera.factory.instance failed.");
                return -1;
            }
            if ( 0 == uiObjectId )
            {
                ERROR_TRACE("IPCamera.factory.instance failed.objectid=0");
                return -1;
            }
            
            Json::Value jsonInParams;
            Json::Value jsonOutParams;
            
            iRet = Dvip_method_json_b_json("IPCamera.getVideoCovers",uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE("IPCamera.getVideoCovers exec failed.");
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    if ( !jsonOutParams.isNull() && jsonOutParams["Enable"].isBool())
                    {
                        bEnable = jsonOutParams["Enable"].asBool();
                        iReturn = 0;
                    }
                    else
                    {
                        ERROR_TRACE("parse Enable failed.");
                        iReturn = -1;
                    }
                }
                else
                {
                    ERROR_TRACE("PCamera.getVideoCovers exec failed.");
                    iReturn = -1;
                }
            }
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy("IPCamera.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("IPCamera.destroy failed.");
                //return -1;
            }
            
            return iReturn;
        }
        
        int CBaseClient::SetVideoCovers(char *pszDeviceId,bool bEnable,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("IPCamera.factory.instance",pszDeviceId,uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("IPCamera.factory.instance failed.");
                return -1;
            }
            if ( 0 == uiObjectId )
            {
                ERROR_TRACE("IPCamera.factory.instance failed.objectid=0");
                return -1;
            }
            
            Json::Value jsonInParams;
            Json::Value jsonOutParams;
            jsonInParams["Enable"]=bEnable;
            iRet = Dvip_method_json_b_json("IPCamera.setVideoCovers",uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE("IPCamera.setVideoCovers failed.");
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    ERROR_TRACE("PCamera.setVideoCovers ok.");
                }
                else
                {
                    ERROR_TRACE("PCamera.setVideoCovers  failed.");
                    iReturn = -1;
                }
            }
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy("IPCamera.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("IPCamera.destroy failed.");
                //return -1;
            }
            
            return iReturn;
        }
        
        int CBaseClient::RemoteOpenDoor(char *pszShortNumber,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("accessControl.factory.instance",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("accessControl.factory.instance failed.");
                return -1;
            }
            if ( 0 == uiObjectId )
            {
                ERROR_TRACE("IPCamera.factory.instance failed.objectid=0");
                return -1;
            }
            
            Json::Value jsonInParams;
            Json::Value jsonOutParams;
            jsonInParams["ShortNumber"]=pszShortNumber;
            jsonInParams["Type"]="Remote";
            iRet = Dvip_method_json_b_json("accessControl.openDoor",uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE("accessControl.openDoor failed.");
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    ERROR_TRACE("accessControl.openDoor ok.");
                }
                else
                {
                    ERROR_TRACE("accessControl.openDoor  failed.");
                    iReturn = -1;
                }
            }
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy("accessControl.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("accessControl.destroy failed.");
                //return -1;
            }
            
            return iReturn;
        }
        
        int CBaseClient::AuthManager_getAuthList(std::string & strAuthList,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("Authorize.factory.instance",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("Authorize.factory.instance failed.");
                return -1;
            }
            if ( 0 == uiObjectId )
            {
                ERROR_TRACE("Authorize.factory.instance from server failed.objectid=0");
                return -1;
            }
            
            Json::Value jsonInParams;
            Json::Value jsonOutParams;
            
            iRet = Dvip_method_json_b_json("Authorize.getAuthList",uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE("Authorize.getAuthList exec failed.");
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    if ( !jsonOutParams.isNull() )
                    {
                        strAuthList = jsonOutParams.toUnStyledString();
                        iReturn = 0;
                        
                        INFO_TRACE("Authorize.getAuthList ok! strAuthList="<<strAuthList);
                    }
                    else
                    {
                        ERROR_TRACE("auth list null.");
                        iReturn = -1;
                    }
                }
                else
                {
                    ERROR_TRACE("Authorize.getAuthList exec failed.");
                    iReturn = -1;
                }
            }
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy("Authorize.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("Authorize destroy failed.");
                //return -1;
            }
            
            return iReturn;
        }
        
        int CBaseClient::AuthManager_delAuth(char *pszPhone,char* pszMeid,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            INFO_TRACE("delAuth: pszPhone="<<pszPhone<<" pszMeid="<<pszMeid);
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("Authorize.factory.instance",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("Authorize.factory.instance failed.");
                return -1;
            }
            if ( 0 == uiObjectId )
            {
                ERROR_TRACE("Authorize.factory.instance from server failed.objectid=0");
                return -1;
            }
            
            Json::Value jsonInParams;
            jsonInParams["PhoneNumber"]=pszPhone;
            jsonInParams["MEID"]=pszMeid;
            
            Json::Value jsonOutParams;
            
            iRet = Dvip_method_json_b_json("Authorize.delAuth",uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE("Authorize.delAuth exec failed.");
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    INFO_TRACE("Authorize.delAuth ok! ");
                    iReturn = 0;
                }
                else
                {
                    ERROR_TRACE("Authorize.delAuth exec failed.");
                    iReturn = -1;
                }
                
            }
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy("Authorize.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("Authorize destroy failed.");
                //return -1;
            }
            
            return iReturn;
        }
        
        int CBaseClient::ShareManager_browseDir(std::string &strShareList,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("ShareManager.factory.instance",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("ShareManager.factory.instance failed.");
                return -1;
            }
            if ( 0 == uiObjectId )
            {
                ERROR_TRACE("ShareManager.factory.instance from server failed.objectid=0");
                return -1;
            }
            
            Json::Value jsonInParams;
            Json::Value jsonOutParams;
            jsonInParams["filter"]["ext"]=".panel.zip";
            iRet = Dvip_method_json_b_json("ShareManager.browseDir",uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE("ShareManager.browseDir exec failed.");
                iReturn = -1;
            }
            else
            {
                if ( !jsonOutParams.isNull() )
                {
                    strShareList = jsonOutParams.toUnStyledString();
                    iReturn = 0;
                    
                    INFO_TRACE("ShareManager.browseDir ok! strShareList="<<strShareList);
                }
                else
                {
                    ERROR_TRACE("share list null.");
                    iReturn = -1;
                }
            }
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy("ShareManager.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("ShareManager destroy failed.");
                //return -1;
            }
            
            return iReturn;
        }
        
        int CBaseClient::ShareManager_downloadFile(char * pszShareFile,char *pszLocalPath,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;;
            int iReturn = 0;
            
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("ShareManager.factory.instance",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("ShareManager instance failed.");
                return -1;
            }
            if ( 0 == uiObjectId )
            {
                ERROR_TRACE("ShareManager instance from server failed.objectid=0");
                return -1;
            }
            
            Json::Value jsonInParams;
            Json::Value jsonOutParams;
            jsonInParams["filter"]["FilePath"] = pszShareFile;
            std::string strMethod = "ShareManager.downloadFile";
            
            m_bSinglePack = false;
            m_strShareFile = pszShareFile;
            m_strLocalPath = pszLocalPath;
            INFO_TRACE(strMethod<<"  pszShareFile="<<pszShareFile<<" pszLocalPath="<<pszLocalPath);
            iRet = Dvip_method_json_b_json((char*)strMethod.c_str(),uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE(strMethod<<" exec failed. pszShareFile="<<pszShareFile<<" pszLocalPath="<<pszLocalPath);
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    INFO_TRACE(strMethod<<" response ok. pszShareFile="<<pszShareFile<<" pszLocalPath="<<pszLocalPath);
                    iReturn = 0;
                    if (m_bSinglePack)
                    {
                        Json::Value jsonEvent;
                        //jsonEvent["DeviceID"]="";
                        //jsonEvent["Type"]="DownFile";
                        jsonEvent["Data"]["FilePath"]=m_strShareFile;
                        jsonEvent["Data"]["LocalPath"]=m_strLocalPath;
                        jsonEvent["Data"]["Result"]=true;
                        std::string strEvent = jsonEvent.toUnStyledString();
                        INFO_TRACE("event notify: strEvent="<<strEvent);
                        
                        m_uiDownReqId = 0;
                        m_strLocalPath = "";
                        m_strShareFile = "";
                        unsigned int uiLoginId = CDvrGeneral::Instance()->GetLoginId(strGwVCode);
                        m_cbOnEventNotify(uiLoginId,emDownFile,(char*)strEvent.c_str(),m_pEventNotifyUser);
                    }
                }
                else
                {
                    m_uiDownReqId = 0;
                    m_strLocalPath = "";
                    m_strShareFile = "";
                    ERROR_TRACE(strMethod<<" response failed. pszShareFile="<<pszShareFile<<" pszLocalPath="<<pszLocalPath);
                    iReturn = -1;
                }
            }
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy("ShareManager.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("ShareManager destroy failed.");
                //return -1;
            }
            
            return iReturn;
        }
        
        int CBaseClient::MagicBox_Control(std::string strAction,std::string & strOutParams,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("magicBox.factory.instance",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("magicBox.factory.instance failed.");
                return -1;
            }
            if ( 0 == uiObjectId )
            {
                ERROR_TRACE("magicBox.factory.instance from server failed.objectid=0");
                return -1;
            }
            
            Json::Value jsonInParams;
            Json::Value jsonOutParams;
            
            std::string strMethod="magicBox.";
            strMethod+=strAction;
            iRet = Dvip_method_json_b_json((char*)strMethod.c_str(),uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE(strMethod<<" exec failed.");
                iReturn = -1;
            }
            else
            {
                if ( bRet )
                {
                    if ( !jsonOutParams.isNull() )
                    {
                        strOutParams = jsonOutParams.toUnStyledString();
                    }
                    INFO_TRACE(strMethod<<" exec ok.");
                    iReturn = 0;
                }
                else
                {
                    ERROR_TRACE(strMethod<<" exec failed.");
                    iReturn = -1;
                }
            }
            
            // Õ∑≈ µ¿˝
            iRet = Dvip_destroy("magicBox.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("magicBox destroy failed.");
            }
            
            return iReturn;
        }
        
        int CBaseClient::GetAuthCode(const char* sSn,const char *sPhoneNumber,const char *sMeid,const char* sModel,const char *sUsername,const char *sPasswrod,char *buffer,int buflen,std::string strGwVCode)
        {
            int iRet = 0;
            unsigned int uiObjectId = 0;
            bool bRet = true;
            int iReturn = 0;
            
            //¥¥Ω® µ¿˝
            iRet = Dvip_instance("Authorize.factory.instance",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iRet )
            {
                ERROR_TRACE("Authorize instance failed.");
                return emDisRe_AuthFailed;
            }
            if ( 0 == uiObjectId )
            {
                ERROR_TRACE("Authorize instance from server failed.objectid=0");
                return emDisRe_AuthFailed;
            }
            
            char sAesKey[16];
            for (int i=0; i<16; i++)
            {
                sAesKey[i] = GetRandomInteger() & 255; //128bitsÀÊª˙ ˝√‹‘ø
            }
            
            char hexkey[32+1];
            BinaryToHex(hexkey, sAesKey, 16);
            
            Json::Value jsonInParams;
            Json::Value jsonOutParams;
            
            jsonInParams["PhoneNumber"] = sPhoneNumber;
            jsonInParams["MEID"       ] = sMeid;
            jsonInParams["Model"      ] = sModel;
            jsonInParams["Seed"       ] = hexkey;
            jsonInParams["sn"       ] = sSn;
            
            if ( strcmp(sUsername,"") && strcmp(sPasswrod,"") )
            {
                int orglen  = strlen(sPasswrod);
                int padlen  = (-orglen)&15;
                int reallen = orglen + padlen;
                char *temp = new char[reallen];
                memcpy(temp, sPasswrod, orglen);
                memset(temp+orglen, '\0', padlen);
                
                AVAES aes;
                av_aes_init(&aes, (unsigned char*)sAesKey, 128, 0);
                av_aes_crypt(&aes, (unsigned char*)temp, (unsigned char*)temp, (reallen>>4), NULL, 0);
                
                char *encryptpsw = new char[2*reallen+1];
                BinaryToHex(encryptpsw, temp, reallen);
                
                jsonInParams["userName"] = sUsername;
                jsonInParams["password"] = encryptpsw;
                
                delete[] temp;
                delete[] encryptpsw;
            }
            
            iRet = Dvip_method_json_b_json("Authorize.alloc",uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE("Authorize.alloc exec failed.");
                return emDisRe_AuthFailed;
            }
            else
            {
                if ( bRet )
                {
                    iRet = emDisRe_None;
                    
                    //Ω‚Œˆƒ⁄»›
                    if ( !jsonOutParams["AuthCode"].isNull() && jsonOutParams["AuthCode"].isString() )
                    {
                        const char *aescode = jsonOutParams["AuthCode"].asCString();
                        int aeslen = strlen(aescode);
                        if (aeslen % 32)
                        {
                            WARN_TRACE("AuthCode is not int group of 128 bits");
                            iRet = emDisRe_AuthFailed;
                        }
                        else
                        {
                            char *bicode = new char[aeslen>>1];
                            HexToBinary(bicode, aescode);
                            
                            AVAES aes;
                            av_aes_init(&aes, (unsigned char*)sAesKey, 128, 1);
                            av_aes_crypt(&aes, (unsigned char*)bicode, (unsigned char*)bicode, (aeslen>>5), NULL, 1);
                            
                            if (buflen < ((aeslen>>1)+1))
                            {
                                WARN_TRACE("buf not enough");
                                iRet = emDisRe_AuthFailed;
                            }
                            else
                            {
                                memcpy(buffer, bicode, (aeslen>>1));
                                buffer[(aeslen>>1)] = '\0';
                            }
                            delete bicode;
                        }
                    }
                    else
                    {
                        WARN_TRACE("no AuthCode");
                        iRet = emDisRe_AuthFailed;
                    }
                }
                else
                {
                    std::string strError = jsonOutParams.toUnStyledString();
                    WARN_TRACE("Authorize.alloc fail! strError="<<strError);
                    
                    if ( !jsonOutParams["error"].isNull()
                        && !jsonOutParams["error"]["code"].isNull()
                        && jsonOutParams["error"]["code"].isInt() )
                    {
                        int iErrorCode = jsonOutParams["error"]["code"].asInt();
                        if ( 0x10030006 == iErrorCode) //”√ªß√˚¥ÌŒÛ
                        {
                            iRet = emDisRe_UserInvalid;
                        }
                        else if (0x10030007 == iErrorCode)//√‹¬Î¥ÌŒÛ
                        {
                            iRet = emDisRe_PasswordInvalid;
                        }
                        else if (0x10030101 == iErrorCode)//–Ú¡–∫≈Œﬁ–ß
                        {
                            iRet = emDisRe_SerialNoInvalid;
                        }
                        else if (0x1003000c == iErrorCode)//≤ª‘⁄ ⁄»®ƒ£ Ω
                        {
                            iRet = emDisRe_NotAuthMode;
                        }
                        else if (0x1003000d == iErrorCode)//≥¨π˝ ⁄»®”√ªß∂Ó∂»
                        {
                            iRet = emDisRe_OutOfAuthLimit;
                        }
                        else// ⁄»® ß∞‹
                        {
                            iRet = emDisRe_AuthFailed;
                        }
                    }
                    else
                        iRet = emDisRe_AuthFailed;
                }
            }
            
            // Õ∑≈ µ¿˝
            int iResult = Dvip_destroy("Authorize.destroy",uiObjectId,m_waittime,strGwVCode);
            if ( 0 != iResult )
            {
                ERROR_TRACE("Authorize.destroy failed.");
            }
            
            if (0 != iRet)
            {
                WARN_TRACE("iRet = "<<iRet);
            }
            return iRet;
        }
        
        
        //ÃΩ≤‚Õ¯πÿ◊¥Ã¨
        int CBaseClient::TouchGateway(std::string strGwVCode)
        {
            int iRet = 0;
            bool bRet = false;
            int iReturn = 0;
            
            Json::Value jsonInParams;
            Json::Value jsonOutParams;
            
            iRet = Dvip_method_json_b_json("Authorize.touch",0,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
            if ( 0 > iRet )
            {
                ERROR_TRACE("Authorize.touch failed.strGwVCode="<<strGwVCode);
                iReturn = -1;
            }
            else 
            {
                if ( bRet )
                {
                    INFO_TRACE("Authorize.touch OK.strGwVCode="<<strGwVCode);
                    iReturn = 0;
                }
                else
                {
                    ERROR_TRACE("Authorize.touch failed.strGwVCode="<<strGwVCode);
                    iReturn = -1;
                }
            }
            return iReturn;
        }
        
