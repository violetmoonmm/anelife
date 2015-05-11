#include "WebsClient.h"
#include "CommonDefine.h"
#include "DvrGeneral.h"

unsigned int CWebsClient::s_ui_RequestId = 0; 


CWebsClient::CWebsClient(void)
{
	m_hThread = 0;
	m_hWorkThread = 0;
	m_bExitThread = true;

	m_sSock = FCL_INVALID_SOCKET;
	m_nConnStatus = 0;
	m_emStatus = emNone;

	m_waittime = 5000;
	m_error = 0;

	memset(m_szRecvBuf,0,MAX_BUF_LEN);
	m_iRecvIndex = 0;

	//本端信息
	m_strUsername = "";  //用户名
	m_strPassword = "";  //密码

	//服务端信息
	m_strServIp = ""; //服务端ip
	m_iServPort = 0;		 //服务端端口

	m_emParseStatus = emStageIdle;

	m_strEndpointType = "/general";

	m_ucModuleId = 0; //初始,未定义类型
	//读取mac地址
	unsigned long long ullMac = GetMacAddrEx();
	if ( 0 == ullMac )
	{
		//如果读取失败,则取随机数
		GenerateRand(m_ucMac,6);
	}
	else
	{
		m_ucMac[0] = ((ullMac & 0X0000FF0000000000ULL)>>40);
		m_ucMac[1] = ((ullMac & 0X000000FF00000000ULL)>>32);
		m_ucMac[2] = ((ullMac & 0X00000000FF000000ULL)>>24);
		m_ucMac[3] = ((ullMac & 0X0000000000FF0000ULL)>>16);
		m_ucMac[4] = ((ullMac & 0X000000000000FF00ULL)>>8);
		m_ucMac[5] = ((ullMac & 0X00000000000000FFULL)>>0);
	}
}

CWebsClient::~CWebsClient(void)
{
	ClearSend();
	Close();
	StopThread();
}

int CWebsClient::Connect(char *pszIp,int iPort) //连接
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
			//阻塞,等待连接
			do
			{
				if ( m_nConnStatus == 2 ) //连接成功
				{
					bResult = true;
				}
				else if (m_nConnStatus == 0) //连接失败
				{
					bResult = true;
				}
				else
				{
					FclSleep(1);
				}
				llEnd = GetCurrentTimeMs();

			}while( _abs64(llEnd-llStart) < 3*1000 && !bResult );

			if (bResult == true && m_nConnStatus == 2)//连接成功
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
		else //失败
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

void CWebsClient::Close()
{
	FCL_CLOSE_SOCKET(m_sSock);
	m_nConnStatus = 0;
	m_iRecvIndex = 0;
	memset(m_szRecvBuf,0,MAX_BUF_LEN);
}


//启动
int CWebsClient::StartThread()
{
	m_bExitThread = false;
#ifdef PLAT_WIN32
	DWORD dwThreadId;
	m_hThread = CreateThread(NULL,0,CWebsClient::ThreadProc,this,0,&dwThreadId);
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

	if ((iRet = ::pthread_create(&m_hThread, &attr,CWebsClient::ThreadProc, this)) != 0) 
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
int CWebsClient::StopThread()
{
	m_bExitThread = true;
	if ( 0 == m_hThread)
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
unsigned long __stdcall CWebsClient::ThreadProc(void *pParam)
#else
void* CWebsClient::ThreadProc(void *pParam)
#endif
{
	CWebsClient *pUser = (CWebsClient*)pParam;
	pUser->ThreadProc();
	return 0;
}

void CWebsClient::ThreadProc(void)
{
	while ( !m_bExitThread )
	{
		Thread_Process();
		FclSleep(1);
	}
}

void CWebsClient::Thread_Process()
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

	//处理每个会话
	if ( FCL_INVALID_SOCKET == m_sSock )
	{
		return;
	}

	if ( 1 == m_nConnStatus ) //正在连接
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
	if ( iTotal == 0 ) //超时
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
		if ( bIsConnecting ) //连接成功
		{
			int iSockErr = 0; 
			int iAddrSize = sizeof(iSockErr);

			int iRet = 0;
#ifdef PLAT_WIN32 
			iRet = getsockopt(m_sSock,SOL_SOCKET,SO_ERROR,(char*)&iSockErr,&iAddrSize);  
#else 
			iRet = getsockopt(m_sSock,SOL_SOCKET,SO_ERROR,(char*)&iSockErr,(socklen_t*)&iAddrSize);
#endif 
			if ( 0 == iRet && iSockErr == 0 ) //确认成功 
			{ 
				//通知连接成功
				OnConnect(2); 
			} 
			else //失败 
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
		//这里可以认为连接断开，回调通知上层，由于当前连接还有保活，所以未曾处理
		return;
	}
	else
	{
		return ;
	}
}

void CWebsClient::OnConnect(int iConnStatus) //连接成功通知
{
	m_nConnStatus = iConnStatus;
	m_iRecvIndex = 0;
}

void CWebsClient::OnDataRecv() //接收数据通知
{
	//接收数据
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
		if ( EINPROGRESS == error || EINTR == error)//处理中或被中断
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

void CWebsClient::OnDataSend() //可以发送数据通知
{
	CMutexGuardT<CMutexThreadRecursive> theLock(m_senLock);
	if ( _lstSend.size() == 0 ) //缓冲区没有数据
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
	//if ( (*it)->_sendIndex == (*it)->_bufSize ) //当前包已经发送完成
	if ( pPack->_sendIndex == pPack->_bufSize ) //当前包已经发送完成
	{
		//return 0;
	}
	else //没有发送完成
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

int CWebsClient::OnDealData()
{
	if ( 0 >= m_iRecvIndex ) //no data
	{
		//ERROR_TRACE("no data to process");
		return 0;
	}

	bool bHasPack = true;
	do
	{
		if ( m_emParseStatus == emStageIdle || m_emParseStatus == emStageHeader ) //http头没有接收完整
		{
			//查找http头结束
			char *pHdrTail = NULL;
			if ( m_iRecvIndex < 4 ) //not enough data to hold http header
			{
				return 0;
			}
			for(int i=0;i<=m_iRecvIndex-4;i++)
			{
				if ( m_szRecvBuf[i] == '\r'
					&& m_szRecvBuf[i+1] == '\n'
					&& m_szRecvBuf[i+2] == '\r'
					&& m_szRecvBuf[i+3] == '\n' )
				{
					pHdrTail = m_szRecvBuf+i;
					break;
				}
			}
			//pHdrTail = strstr(m_szRecvBuf,"\r\n\r\n"));
			if ( NULL == pHdrTail ) //头没有结束
			{
				bHasPack = false;
				return 0;
			}

			int iHdrLen = (int)(pHdrTail-m_szRecvBuf+4);

			if ( !ParseHttpHeader(m_szRecvBuf,iHdrLen+4,m_curMsg) )
			{
				ERROR_TRACE("Parse http header failed");
				ERROR_TRACE(m_szRecvBuf);
				//跳过
				//if ( m_iRecvIndex > iHdrLen ) //剩余的数据前移
				//{
				//	memmove(m_szRecvBuf,&m_szRecvBuf[iHdrLen],m_iRecvIndex-iHdrLen);
				//	m_iRecvIndex -= iHdrLen;
				//}
				//else //已经没有数据可以处理
				//{
				//	bHasPack = false;
				//	m_iRecvIndex = 0;
				//}

				memset(m_szRecvBuf,0,MAX_BUF_LEN);
				bHasPack = false;
				m_iRecvIndex = 0;

				m_emParseStatus = emStageIdle;
				continue;
			}

			int iContentLength = m_curMsg.iContentLength;
			if ( m_curMsg.bIsChunkMode ) //chuncked mode 
			{
				ERROR_TRACE("not support current");
				return -1;
			}
			if ( iContentLength == 0 ) //没有消息体
			{
				//回调上层
				OnHttpMsg(m_curMsg,NULL,0);

				m_curMsg.Clear();

				//清空http
				if ( m_iRecvIndex > iHdrLen+iContentLength ) //剩余的数据前移
				{
					memmove(m_szRecvBuf,&m_szRecvBuf[iHdrLen+iContentLength],m_iRecvIndex-iHdrLen-iContentLength);
					m_iRecvIndex -= (iHdrLen+iContentLength);
				}
				else
				{
					bHasPack = false;
					m_iRecvIndex = 0;
				}
				m_emParseStatus = emStageIdle;


				//continue;
			}
			else
			{
				if ( m_iRecvIndex >= iHdrLen+iContentLength ) //已经完成
				{
					//回调上层
					OnHttpMsg(m_curMsg,&m_szRecvBuf[iHdrLen],iContentLength);

					m_curMsg.Clear();

					if ( m_iRecvIndex > iHdrLen+iContentLength ) //仍然有剩余数据
					{
						//ERROR_TRACE("Still left some data not handled");
						memmove(m_szRecvBuf,&m_szRecvBuf[iHdrLen+iContentLength],m_iRecvIndex-iHdrLen-iContentLength);
						m_iRecvIndex -= (iHdrLen+iContentLength);
						m_emParseStatus = emStageIdle;
						//continue;
					}
					else //已经没有可以处理的数据
					{
						m_iRecvIndex = 0;
						m_emParseStatus = emStageIdle;
						bHasPack = false;
					}

				}
				else //内容没有接收完成
				{
					m_iContentWriteIndex = 0;
					m_pContent = new char[iContentLength];
					if ( !m_pContent )
					{
						ERROR_TRACE("out of memory");
						return -2;
					}
					m_iContentWriteIndex = m_iRecvIndex-iHdrLen;
					m_iRecvIndex = 0;
					memcpy(m_pContent,&m_szRecvBuf[iHdrLen],m_iContentWriteIndex);
					m_emParseStatus = emStageContent;

					//m_pContent = NULL;
					bHasPack = false;
					//return 0;
				}

			}
		}
		else if ( m_emParseStatus == emStageContent ) //http头部已经完成,等待内容接收完成
		{
			if ( m_curMsg.iContentLength > m_iContentWriteIndex+m_iRecvIndex ) //仍然没有完成content接收
			{
				memcpy(m_pContent+m_iContentWriteIndex,m_szRecvBuf,m_iRecvIndex);
				m_iContentWriteIndex += m_iRecvIndex;
				m_iRecvIndex = 0;
				bHasPack = false;
				//return 0;
			}
			else
			{
				memcpy(m_pContent+m_iContentWriteIndex,m_szRecvBuf,m_curMsg.iContentLength-m_iContentWriteIndex);

				//回调上层
				OnHttpMsg(m_curMsg,m_pContent,m_curMsg.iContentLength);

				//重置状态
				m_emParseStatus = emStageIdle;
				if ( m_curMsg.iContentLength == m_iContentWriteIndex+m_iRecvIndex )
				{
					m_iRecvIndex = 0;
					bHasPack = false;
				}
				else
				{
					memmove(m_szRecvBuf,&m_szRecvBuf[m_curMsg.iContentLength-m_iContentWriteIndex],m_iRecvIndex-(m_curMsg.iContentLength-m_iContentWriteIndex));
					//m_iWriteIndex = m_curMsg.iContentLength-m_iContentWriteIndex;
					m_iRecvIndex = m_iRecvIndex-(m_curMsg.iContentLength-m_iContentWriteIndex);
				}
				//m_iWriteIndex = 0;
				m_iContentWriteIndex = 0;
				m_pContent = NULL;
				m_curMsg.Clear();

				//return 1;
			}
		}
	}
	while( bHasPack );

	return 0;
}

void CWebsClient::OnTcpDisconnect(int iReason)
{
	EmStatus m_emPreStatus = m_emStatus;

	Close();
	m_emStatus = emIdle;
	m_error = iReason;

	if (m_emPreStatus == emRegistered)
	{
	}
}

void CWebsClient::ClearSend()//清空发送缓冲
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

int CWebsClient::SendData(char *pData,int iLen)
{
	CMutexGuardT<CMutexThreadRecursive> theLock(m_senLock);
	if ( _lstSend.size() != 0 ) //发送缓冲中已经有数据,直接填入发送缓冲
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
		else //没有发送完全
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
		//_lastActionTime = time(NULL); //上次活跃时间
	}
	return 0;
}


std::string CWebsClient::MakeSessionId()
{
	int iRanBytes = rand()%5+1;
	int iLen = 6+1+4+iRanBytes;
	unsigned char ucSession[32] = {0};
	memcpy(ucSession,m_ucMac,6);
	memcpy(&ucSession[6],&m_ucModuleId,1);
	unsigned int uiTick = GetTickCount();
	memcpy(&ucSession[7],&uiTick,4);
	GenerateRand(&ucSession[11],iRanBytes);
	char szBuf[8];
	std::string strSessionId;
	for(int i=0;i<iLen;i++)
	{
		sprintf(szBuf,"%02X",ucSession[i]);
		strSessionId += szBuf;
	}

	return strSessionId;
}
std::string CWebsClient::MakeTags(unsigned int uiReqId)
{
	//unsigned int uiReqId = MakeReqId();
	std::string strSessionId = MakeSessionId();
	char szBuf[128] = {0};
	sprintf(szBuf,"sessionid=%s,seq=%u",strSessionId.c_str(),uiReqId);
	return std::string(szBuf);
}

int CWebsClient::OnHttpMsg(HttpMessage &msg,const char *pContent,int iContentLength)
{
	if (msg.iStatusCode == 200)//ok
	{
		Json::Reader jsonParser;
		Json::Value jsonContent;
		bool bRet = true;
		bRet = jsonParser.parse(pContent,jsonContent);
		if ( !bRet )
		{
			ERROR_TRACE("parse msg body failed");
			return -1;
		}
		
		std::string strRspParam;
		int error;
		if ( jsonContent["result"].isNull() || !jsonContent["result"].isInt() ) 
		{
			ERROR_TRACE("no result or result type is not int.");
			return -1;
		}
		error = jsonContent["result"].asInt();
		if (error == 0)//成功
		{
			m_curReq.strRspParam = jsonContent.toUnStyledString();
			m_curReq.result = 0;
			m_curReq.hEvent.Signal();
		}
		else
		{
			m_curReq.strRspParam = jsonContent.toUnStyledString();
			m_curReq.result = error;//-1001 方法不存在，-1002 设备不存在
			m_curReq.hEvent.Signal();
		}
	}
	else if (msg.iStatusCode == 401)//need auth
	{
		std::string strWWWAuthenticate;
		bool bRet = false;
		HttpAuth auth;

		strWWWAuthenticate = msg.GetValueNoCase("WWW-Authenticate");
		if ( !strWWWAuthenticate.empty() )
		{
			//解析认证内容
			bRet = ParseHttpAuthParams(strWWWAuthenticate,auth);
			if ( bRet )
			{
				if ( auth.strScheme == "Basic" ) //基本
				{
				}
				else if ( auth.strScheme == "Digest" ) //摘要算法
				{
					if ( auth.strRealm.empty() || auth.strNonce.empty() )
					{
						ERROR_TRACE("username realm nonce and response param must exist.");
					}
					else
					{
						if (m_curReq.iFailedTimes > 0)//前一次认证失败
						{
							ERROR_TRACE("auth failed");
							m_curReq.strRspParam = "";
							m_curReq.result = -1000;//-1000 摘要认证失败，可能是用户密码错误
							m_curReq.hEvent.Signal();
						}
						else
						{
							auth.strUsername = m_strUsername;
							auth.strUri = m_curReq.strPath;//msg.strPath;
							auth.strResponse = CalcAuthMd5(auth.strUsername,m_strPassword,auth.strRealm,auth.strNonce,std::string("POST"),auth.strUri);
							m_strAuthorization = auth.ToString();
							m_strRealm = auth.strRealm;
							m_strRandom = auth.strNonce;

							//重发请求
							HttpMessage regMsg;
							regMsg.iType = 1;
							regMsg.iMethod = emMethodPost;
							regMsg.strPath = m_curReq.strPath;
							regMsg.iContentLength = 0;
							regMsg.SetValue("Authorization",m_strAuthorization);
							std::string strMsg = regMsg.ToHttpheader();

							//发送查询请求消息
							int iRet = SendData((char*)strMsg.c_str(),(int)strMsg.size());
							if (iRet)
							{
								INFO_TRACE(m_curReq.strPath);
								m_curReq.iFailedTimes++;
							}
						}					
					}
				}
				//既非基本也非摘要算法,拒绝
				else
				{
					ERROR_TRACE("auth scheme must be Digest.current scheme="<<auth.strScheme<<".");
				}
			}
			else
			{
				ERROR_TRACE("parse WWW-Authenticate failed.");
			}
		}
		else
			ERROR_TRACE("parse WWW-Authenticate failed.");
	}
	else//服务器拒绝，预留错误
	{
		ERROR_TRACE("server refused! error="<<msg.iStatusCode);
		m_curReq.strRspParam = "";
		m_curReq.result = msg.iStatusCode;//http错误
		m_curReq.hEvent.Signal();
	}

	return -1;
}

int CWebsClient::HttpQuery(const std::string strPath,std::string &strResult)
{
	int iRet = 0;
	iRet = StartThread();
	if (iRet < 0)
	{
		return -1;
	}

	iRet = Connect((char*)m_strServIp.c_str(),m_iServPort);
	if (iRet < 0)
	{
		StopThread();
		return -2;//连接失败
	}

	HttpMessage regMsg;
	regMsg.iType = 1;
	regMsg.iMethod = emMethodPost;
	regMsg.strPath = strPath;

	regMsg.iContentLength = 0;
	std::string strMsg = regMsg.ToHttpheader();

	//缓存当前记录
	m_curReq.strPath = strPath;
	m_curReq.result = -1;

	//发送查询请求消息
	iRet = SendData((char*)strMsg.c_str(),(int)strMsg.size());
	if ( 0 <= iRet )
	{
		iRet = m_curReq.hEvent.Wait(5000);
		if ( 0 != m_curReq.result )//失败
		{
			iRet = -4;
		}
		else
		{
			iRet = 0;
			//成功
			strResult = m_curReq.strRspParam;
		}
	}
	else
	{
		iRet = -3;
	}

	Close();
	StopThread();

	return iRet;
}

int CWebsClient::GetClientStatus(char* pszSn,std::string & strResult)
{
	std::string strPath = m_strEndpointType;
	strPath += "?type=query&action=";
	strPath += "clientStatus";
	strPath += "&device=";
	strPath += pszSn;
	return HttpQuery(strPath,strResult);
}
