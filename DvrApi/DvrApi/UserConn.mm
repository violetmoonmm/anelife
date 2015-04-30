#include "UserConn.h"

CUserConn::CUserConn(unsigned int uiLoginId,std::string strServIp,int iServPort)
{
    m_uiLoginId = uiLoginId;
    m_strServIp = strServIp;
    m_iServPort = iServPort;
    m_sSock=FCL_INVALID_SOCKET;
    
    m_iRecvIndex = 0;
    
    m_bKeepAlive = false;
    m_llLastTime = 0;
}

CUserConn::~CUserConn(void)
{
}

int CUserConn::Connect(fRealDataCallBack pCb,void * pUser)
{
    m_pCb = pCb;
    m_pUser = pUser;
    
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
    
    //	int iBlock = 1;
    //#ifdef PLAT_WIN32
    //	iRet = ::ioctlsocket(m_sSock,FIONBIO,(u_long FAR *)&iBlock);
    //	if ( SOCKET_ERROR == iRet )
    //	{
    //		ERROR_TRACE("set socket opt failed,errno="<<WSAGetLastError());
    //		FCL_CLOSE_SOCKET(m_sSock);
    //		return -1;
    //	}
    //#else
    //	iBlock = ::fcntl(m_sSock, F_GETFL, 0);
    //	if ( -1 != iBlock )
    //	{
    //		iBlock |= O_NONBLOCK;
    //		iRet = ::fcntl(m_sSock, F_SETFL, iBlock);
    //		if ( -1 == iRet )
    //		{
    //			ERROR_TRACE("set socket opt failed,errno="<<WSAGetLastError());
    //			FCL_CLOSE_SOCKET(m_sSock);
    //			return -1;
    //		}
    //	}
    //#endif
    
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
                return 0; //阻塞,等待连接
                
            }
            else //失败
            {
                ERROR_TRACE("connect failed,errno="<<WSAGetLastError());
                FCL_CLOSE_SOCKET(m_sSock);
                return -1;
            }
        }
        else
        {
            INFO_TRACE("connect ok");
            
            StartThread();
            return 0;
        }
        
        return 0;
    }
    
    int CUserConn::Disconnect()
    {
        if (m_uiLoginId)
        {
            dh2_hdr hdr;
            memset(&hdr,0,sizeof(dh2_hdr));
            hdr.cmd = 0xF1;
            hdr.extlen = 0;
            memcpy(hdr.data,&m_uiLoginId,4);
            hdr.data[0]=0x01;//实时监视
            
            SendData((char*)&hdr,32);
        }
        
        FclSleep(1000);
        StopThread();
        
        FCL_CLOSE_SOCKET(m_sSock);
        m_sSock = FCL_INVALID_SOCKET;
        
        return 0;
    }
    
    //启动
    int CUserConn::StartThread()
    {
        m_bExitThread = false;
#ifdef PLAT_WIN32
        DWORD dwThreadId;
        m_hThread = CreateThread(NULL,0,CUserConn::ThreadProc,this,0,&dwThreadId);
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
        
        if ((iRet = ::pthread_create(&m_hThread, &attr,CUserConn::ThreadProc, this)) != 0)
        {
            ERROR_TRACE("pthread_create() failed! error code="<<iRet);
            ::pthread_attr_destroy(&attr);
            return -1;
        }
        ::pthread_attr_destroy(&attr);
#endif
        
        return 0;
    }
    //结束
    int CUserConn::StopThread()
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
    unsigned long __stdcall CUserConn::ThreadProc(void *pParam)
#else
    void* CUserConn::ThreadProc(void *pParam)
#endif
    {
        CUserConn *pUser = (CUserConn*)pParam;
        pUser->ThreadProc();
        return 0;
    }
    
    void CUserConn::ThreadProc(void)
    {
        int fds = 0;
        timeval tv;
        fd_set fd_recv;
        FD_ZERO(&fd_recv);
        
        tv.tv_sec = 0;
        tv.tv_usec = 100*1000;
        
        while ( !m_bExitThread )
        {
            FclSleep(1);
            
            if ( m_bKeepAlive && _abs64(m_llLastTime-GetCurrentTimeMs()) > 15000 )
            {
                keepalive();
                m_llLastTime = GetCurrentTimeMs();
            }
            
            FD_SET(m_sSock,&fd_recv);
            fds = (int)m_sSock;
            int iTotal = select(fds+1,&fd_recv,0,0,&tv);
#ifdef PLAT_WIN32
            if ( SOCKET_ERROR == iTotal )
            {
                errno = WSAGetLastError();
                ERROR_TRACE("socket select error. errno="<<errno<<".");
            }
#else
            if ( -1 == iTotal )
            {
                ERROR_TRACE("socket select error. errno="<<errno<<".");
            }
#endif
            if ( iTotal == 0 ) //超时
            {
                continue;
            }
            
            if ( FD_ISSET(m_sSock,&fd_recv) )
            {
                //接收数据
                int iDataLen = recv(m_sSock,&m_szRecvBuf[m_iRecvIndex],MAX_DATA_LEN-m_iRecvIndex,0);
                if ( iDataLen < 0 )
                {
                    ERROR_TRACE("recv failed.err="<<WSAGetLastError());
                }
                else
                {
                    m_iRecvIndex += iDataLen;
                    //INFO_TRACE("recv data iDataLen="<<iDataLen<<" m_iRecvIndex="<<m_iRecvIndex);
                    OnDealData();
                }
            }
        }
    }
    
    int CUserConn::OnDealData() //处理数据
    {
        int iCurIndex = 0;
        bool bHavePacket = true;
        
        if ( m_iRecvIndex < DVIP_HDR_LENGTH )
        {
            return 0;
        }
        do
        {
            if ( m_iRecvIndex-iCurIndex >= DVIP_HDR_LENGTH )
            {
                //32字节头的5-8字节表示包长度
                unsigned int extlen = *(unsigned int*)(m_szRecvBuf + iCurIndex + 4);
                if ( extlen+DVIP_HDR_LENGTH <= m_iRecvIndex-iCurIndex )
                {
                    //处理数据
                    OnDataPacket(&m_szRecvBuf[iCurIndex],(int)(extlen+DVIP_HDR_LENGTH));
                    iCurIndex += (extlen+DVIP_HDR_LENGTH);
                }
                else //不够一包数据
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
            if ( m_iRecvIndex == iCurIndex ) //数据全部处理完
            {
                m_iRecvIndex = 0;
            }
            else
            {
                memmove(m_szRecvBuf,&m_szRecvBuf[iCurIndex],m_iRecvIndex-iCurIndex);
                m_iRecvIndex -= iCurIndex;
            }
        }
        
        return 0;
    }
    
    void CUserConn::OnDataPacket(const char *pData,int iDataLen)
    {
        switch ((unsigned char)pData[0])
        {
            case 0xB0://登陆ACK
            {
                m_result = (unsigned char)pData[8];//0 成功 1失败 3已登陆
                if(m_result == 0 || m_result == 3)
                {
                    m_result = 0;
                    memcpy(&m_uiLoginId,pData+16,4);
                }
                //m_hEvent.Signal();
                INFO_TRACE("recv login response: result="<<m_result<<" m_uiLoginId="<<m_uiLoginId);
            }
                break;
            case 0xB1://心跳应答
            {
                //INFO_TRACE("recv keep alive response");
            }
                break;
            case 0xF1://子连接
            {
                m_result = (unsigned char)pData[6];//0 连接映射 1失败 2已连接
                INFO_TRACE("recv sub connect response m_result="<<m_result);
            }
                break;
            case 0xBC://媒体数据应答
            {
                //INFO_TRACE("recv real data: iDataLen="<<iDataLen);
                char *szBuf = new char[iDataLen-32];
                memset(szBuf,0,iDataLen-32);
                memcpy(szBuf,pData+32,iDataLen-32);
                if (m_pCb)
                {
                    m_pCb(m_uiRealHandle,0,szBuf,iDataLen-32,m_pUser);
                }
                delete szBuf;
            }
                break;
            case 0x69://报警订阅应答
            {
                m_result = (unsigned char)pData[8];//0 成功 1失败 2无权限 3设备忙
                INFO_TRACE("recv alarm listen response m_result="<<m_result);
                for (int i=0;i<iDataLen;i++)
                {
                    printf("%02x",pData[i]);
                }
                printf("\n");
            }
                break;
                //case 0xB1:
                //	{
                
                //	}
                //	break;
            default:
                INFO_TRACE("invalid cmd="<<(unsigned char)pData[0]);
                break;
        }
        
        return ;
    }
    
    int CUserConn::SendData(char *pData,int iDataLen) //发送数据
    {
        int iSendLen;
        iSendLen = send(m_sSock,pData,iDataLen,0);
        if ( iSendLen == iDataLen ) //全部发送完成
        {
            return iSendLen;
        }
        else if ( iSendLen == FCL_SOCKET_ERROR ) //发送失败
        {
            ERROR_TRACE("send failed.err="<<WSAGetLastError()<<" send len="<<iSendLen);
            return iSendLen;
        }
        else //部分发送完成,剩余未发送部分处理:暂时没有处理
        {
            return iSendLen;
        }
    }
    
    unsigned int CUserConn::login()
    {
        m_result = -1;
        //发送注册请求
        dh2_hdr hdr;
        memset(&hdr,0,sizeof(dh2_hdr));
        hdr.cmd = 0xA0;
        hdr.resv[2]=0x60;
        hdr.extlen = 0;
        memcpy(hdr.data,"admin",5);
        memcpy(hdr.data+8,"admin",5);
        hdr.data[16]=0x04;
        hdr.data[17]=0x01;
        hdr.data[22]=0xA1;
        hdr.data[23]=0xAA;
        
        INFO_TRACE("send login cmd 0xA0");
        int iSendLength = SendData((char*)&hdr,32);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            return 0;
        }
        
        int iCount = 3000; 
        while (iCount--)
        {
            if (m_result != -1)
            {
                break;
            }
            FclSleep(1);
        }
        
        if (iCount == 0 || m_result == 1)
        {
            ERROR_TRACE("SimpleLogin failed");
            return 0;
        }
        
        m_bKeepAlive = true;
        m_llLastTime = GetCurrentTimeMs();
        
        return m_uiLoginId;
    }
    
    void CUserConn::keepalive()
    {
        //发送心跳请求
        dh2_hdr hdr;
        memset(&hdr,0,sizeof(dh2_hdr));
        hdr.cmd = 0xA1;
        hdr.extlen = 0;
        
        int iSendLength = SendData((char*)&hdr,32);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            return ;
        }
    }
    
    int CUserConn::CreateDataConnect(unsigned long uiRealHandle)
    {
        m_result = -1;
        m_uiRealHandle = uiRealHandle;
        dh2_hdr hdr;
        memset(&hdr,0,sizeof(dh2_hdr));
        hdr.cmd = 0xF1;
        //hdr.resv[2] = 0x58;
        hdr.extlen = 0;
        memcpy(hdr.data,&m_uiLoginId,4);
        hdr.data[4]=0x01;//实时监视
        hdr.data[5]=0x01;//0通道
        hdr.data[9]=0x00;//建立连接
        
        INFO_TRACE("send sub connect cmd 0xF1");
        int iSendLength = SendData((char*)&hdr,32);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            return 0;
        }
        
        int iCount = 3000; 
        while (iCount--)
        {
            if (m_result != -1)
            {
                break;
            }
            FclSleep(1);
        }
        
        if (iCount == 0 || m_result == 1)
        {
            ERROR_TRACE("SimpleLogin failed");
            return 0;
        }
        
        return 0;
    }
    
    int CUserConn::StartRealPlay()
    {
        dh2_hdr hdr;
        memset(&hdr,0,sizeof(dh2_hdr));
        hdr.cmd = 0x11;
        hdr.extlen = 16;
        hdr.data[0]=0x01;//实时监视
        
        char szData[48]={0};
        memcpy(szData,&hdr,32);
        
        INFO_TRACE("send cmd 0x11");
        int iSendLength = SendData(szData,48);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            return 0;
        }
        return 0;
    }
    
    int CUserConn::StopRealPlay()
    {
        dh2_hdr hdr;
        memset(&hdr,0,sizeof(dh2_hdr));
        hdr.cmd = 0x11;
        hdr.extlen = 16;
        hdr.data[0]=0x00;//停止实时监视
        
        char szData[48]={0};
        memcpy(szData,&hdr,32);
        
        INFO_TRACE("send cmd 0x11");
        int iSendLength = SendData(szData,48);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            return 0;
        }
        return 0;
    }
    
    int CUserConn::StartAlarmListen()
    {
        dh2_hdr hdr;
        memset(&hdr,0,sizeof(dh2_hdr));
        hdr.cmd = 0x68;
        hdr.extlen = 16;
        hdr.data[0]=0x02;//订阅
        
        char szData[32]={0};
        memcpy(szData,&hdr,32);
        
        INFO_TRACE("send cmd 0x68");
        int iSendLength = SendData(szData,32);
        if ( 0 > iSendLength )
        {
            ERROR_TRACE("send failed");
            return 0;
        }
        return 0;
    }
    
    int CUserConn::StopAlarmListen()
    {
        return 0;
    }
