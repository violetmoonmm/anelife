#include "IcmsUpnpStack.h"
#include "Trace.h"
#include "HttpDefines.h"

#define  SDK_VERSION_MAJOR   1
#define  SDK_VERSION_MINOR   00
#define  SDK_VERSION_BUILD   0x1016

#define  SDK_VERSION   (SDK_VERSION_MAJOR<<24 | SDK_VERSION_MINOR<<16 | SDK_VERSION_BUILD)

#define SDK_NAME  "SH_CLIENT"

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

CIcmsUpnpStack::CIcmsUpnpStack()
{
	//断线回调
	m_cbDisConnect = NULL;
	m_pUserDisConnect = NULL;
	//消息回调
	m_cbMsgCb = NULL;
	m_pUserMsg = NULL;

	m_bIsStart = false; //是否启动
	//m_emStatus = emIdle;
	m_hTaskThread = NULL;

	m_usServPort_uc_fd = 0;				//服务端口 接受uc和设备注册
	m_usServPort_proxy = 0;				//服务端口 接受代理注册
	m_bUse_uc_fd = false;				//启动uc和fd注册服务
	m_bUse_proxy = false;				//启动代理注册服务
	m_iLocalType = emEpTypeUnknown;		//本端类型

	m_sSock_uc_fd = FCL_INVALID_SOCKET;	//套接字 uc和fd注册侦听
	m_sSock_proxy = FCL_INVALID_SOCKET;	//套接字 proxy注册侦听

	m_bAutoReConnect = false;

	m_cbLoginCb = NULL;
	m_pUserLogin = NULL;

#ifdef PLAT_WIN32
	InitWinSock();
#endif
}
CIcmsUpnpStack::~CIcmsUpnpStack()
{
	if ( m_bIsStart )
	{
		StopTaskThread();
	}
	m_bIsStart = false;
#ifdef PLAT_WIN32
	CleanupWinSock();
#endif
}
CIcmsUpnpStack * CIcmsUpnpStack::Instance()
{
	static CIcmsUpnpStack s_instance;
	return &s_instance;
}

//查找实例
CConnUser * CIcmsUpnpStack::LookupInstance(unsigned int uiId)
{
	std::map<unsigned int,CConnUser*>::iterator it;
	CConnUser *pIns = NULL;
	it = m_insMap.find(uiId);
	if ( m_insMap.end() != it )
	{
		return it->second;
	}
	return NULL;
}

//初始化
int CIcmsUpnpStack::Init()
{
	int iRet;
	iRet = StartTaskThread();
	return iRet;
}
//反初始化
void CIcmsUpnpStack::UnInit()
{
	StopTaskThread();

	return ;
}

//设置断线回调
void CIcmsUpnpStack::SetDisconnectCallback(fDisConnect cbDisConnect,void *pUser)
{
	m_cbDisConnect = cbDisConnect;
	m_pUserDisConnect = pUser;
}

//设置消息通知回调
void CIcmsUpnpStack::SetMessageCallback(fMessCallBack cbMessage,void * pUser)
{
	m_cbMsgCb = cbMessage;
	m_pUserMsg = pUser;
}

//设置登录通知回调
void CIcmsUpnpStack::SetOnLoginCallback(fOnLogin cbOnLogin,void * pUser)
{
	m_cbLoginCb = cbOnLogin;
	m_pUserLogin = pUser;
}

std::string CIcmsUpnpStack::GetLocalIp(UInt32 hLoginID)
{
	std::map<unsigned int,CConnUser*>::iterator it;
	CConnUser *pInst = NULL;
	it = m_insMap.find(hLoginID);
	if ( m_insMap.end() == it )
	{
		//not find
		ERROR_TRACE("instance "<<hLoginID<<" not find.");
		return std::string("");
	}
	pInst = it->second;
	if ( pInst )
	{
		return pInst->LocalIp();
	}

	return std::string(""); 
}

//注册
UInt32 CIcmsUpnpStack::Login(char *pchServIP
						   ,UInt16 wServPort
						   ,char *pchServVirtcode
						   ,char *pchVirtCode
						   ,char *pchPassword
						   ,Int32 *error)
{
	//1  查找实例是否已经存在

	//2 创建实例
	int iRet = 0;
	unsigned int uiUserId = 0;
	CConnUser *pInst = new CConnUser();
	if ( NULL == pInst )
	{
		ERROR_TRACE("out of memory.");
		iRet = -1;
		if ( error )
		{
			*error = iRet;
		}
		return 0;
	}
	//初始化参数
	pInst->SetLocalVcode(std::string(pchVirtCode));
	pInst->SetServerInfo(std::string(pchServIP),wServPort,std::string(pchServVirtcode));
	pInst->SetLocalType(m_iLocalType);
	pInst->SetIsClient(true);
	pInst->SetSinker(this);
	pInst->SetAutoReconnect(m_bAutoReConnect);
	if ( pchPassword )
	{
		pInst->SetPassword(std::string(pchPassword));
	}

	//3 实例发起注册
	iRet = pInst->Register();
	if ( 0 > iRet )
	{
		ERROR_TRACE("register failed");
		delete pInst;
		if ( error )
		{
			*error = iRet;
		}
	}
	else
	{
		uiUserId = pInst->GetUserId();
		m_insMap[uiUserId] = pInst;
		if ( error )
		{
			*error = 0;
		}
	}
	
	return uiUserId;
}
//注销
int CIcmsUpnpStack::Logout(UInt32 hLoginID)
{
	INFO_TRACE("logout : instance Id "<<hLoginID<<".");
	std::map<unsigned int,CConnUser*>::iterator it;
	CConnUser *pInst = NULL;
	it = m_insMap.find(hLoginID);
	if ( m_insMap.end() == it )
	{
		//not find
		ERROR_TRACE("instance "<<hLoginID<<" not find.");
		return -1;
	}
	pInst = it->second;
	//m_insMap.erase(hLoginID);
	pInst->UnRegister();
	//delete pInst;

	INFO_TRACE("logout request : instance Id "<<hLoginID<<".");
	return 0; 
}
//强制释放
int CIcmsUpnpStack::Force_Release(UInt32 hLoginID)
{
	INFO_TRACE("Force release : instance Id "<<hLoginID<<".");
	std::map<unsigned int,CConnUser*>::iterator it;
	CConnUser *pInst = NULL;
	it = m_insMap.find(hLoginID);
	if ( m_insMap.end() == it )
	{
		//not find
		ERROR_TRACE("instance "<<hLoginID<<" not find.");
		return -1;
	}
	pInst = it->second;
	m_insMap.erase(hLoginID);
	pInst->UnRegister();
	delete pInst;

	INFO_TRACE("Force release : instance Id "<<hLoginID<<".");
	return 0; 
}
//发送消息
int CIcmsUpnpStack::SendMessage(UInt32 hLoginID,LPHTTP_HEADER pHdr,void * pContent,int iContentLength)
{
	CConnUser *pInst;
	pInst = LookupInstance(hLoginID);
	if ( !pInst )
	{
		ERROR_TRACE("not find instance");
		return -1;
	}
	//if ( !pInst->IsRegistered() )
	//{
	//	ERROR_TRACE("not registered");
	//	return -1;
	//}

	HttpMessage msg;
	msg.iType = pHdr->iType;
	if ( msg.iType == 1 )
	{
		msg.strPath = pHdr->szPath;
	}
	else
	{
		msg.iStatusCode = pHdr->iStatusCode;
	}
	msg.iContentLength = iContentLength;
	msg.iMethod = pHdr->iMethod;
	msg.SetValue(HEADER_NAME_FROM,pHdr->szFrom);
	msg.SetValue(HEADER_NAME_TO,pHdr->szTo);
	msg.SetValue(HEADER_NAME_TAGS,pHdr->szTags);
	msg.SetValue(HEADER_NAME_ACTION,pHdr->szAction);
	for(int i=0;i<pHdr->iCount;i++)
	{
		msg.SetValue(pHdr->hdrs[i].szName,pHdr->hdrs[i].szValue);
	}
	return pInst->SendMessage(msg,(char*)pContent,iContentLength);
	//return -1;
}

//启动
int CIcmsUpnpStack::StartTaskThread()
{
	m_bExitTaskThread = false;
#ifdef PLAT_WIN32
	DWORD dwThreadId;
	m_hTaskThread = CreateThread(NULL,0,CIcmsUpnpStack::TaskThreadProc,this,0,&dwThreadId);
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

	if ((iRet = ::pthread_create(&m_hTaskThread, &attr,CIcmsUpnpStack::TaskThreadProc, this)) != 0) 
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
int CIcmsUpnpStack::StopTaskThread()
{
	m_bExitTaskThread = true;
	if ( NULL == m_hTaskThread )
	{
		return 0;
	}
#ifdef PLAT_WIN32
	DWORD dwRet;
	dwRet = WaitForSingleObject(m_hTaskThread,5000);
	if ( dwRet == WAIT_TIMEOUT )
	{
		TerminateThread(m_hTaskThread,0);
	}
#else
	void *result;
	pthread_join(m_hTaskThread,&result);
#endif
	m_hTaskThread = 0;

	return 0;
}

#ifdef PLAT_WIN32
unsigned long __stdcall CIcmsUpnpStack::TaskThreadProc(void *pParam)
#else
void* CIcmsUpnpStack::TaskThreadProc(void *pParam)
#endif
{
	CIcmsUpnpStack *pUser = (CIcmsUpnpStack*)pParam;
	pUser->TaskFuncProc();
	return 0;
}

void CIcmsUpnpStack::TaskFuncProc(void)
{
	while ( !m_bExitTaskThread )
	{
		Task_Process();
		FclSleep(1);
	}
}
void CIcmsUpnpStack::Task_Process()
{
	int iRet;
	//接收数据
	iRet = PollSessionData();

	//检查是否有新连接
	PollAccept();

	//处理每个会话
	//CHttpDataSession *pTemp;
	//std::list<CHttpDataSession*>::iterator it;
	CConnUser *pTemp = NULL;
	unsigned int uiIndex =0;
	std::map<unsigned int,CConnUser*>::iterator it;
	for(it=m_insMap.begin();it!=m_insMap.end();/*it++*/)
	{
		uiIndex++;
		pTemp = (*it).second;
		pTemp->Process_Data();
		iRet = pTemp->Process();
		if ( 1 == iRet )
		{
			it++;
			////uiId = (*it).first;
			//it = m_insMap.begin();
			//for(int i=0;i<uiIndex;i++)
			//{
			//	if ( it == m_insMap.end() )
			//	{
			//		break;
			//	}
			//	it++;
			//}
			////it = m_insMap.begin()+uiIndex;
			////m_insMap.erase(uiId);
			//if ( it == m_insMap.end() )
			//{
			//	break;
			//}
		}
		else
		{
			it++;
		}
	}

	//清理需要删除的连接
	for(it=m_insMap.begin();it!=m_insMap.end();/*it++*/)
	{
		pTemp = (*it).second;
		if ( pTemp->HasCanRemoved() ) //可以清除
		{
			unsigned int uiFirst = it->first;
			it++;
			m_insMap.erase(uiFirst);
			delete pTemp;
			if ( it == m_insMap.end() )
			{
				break;
			}
		}
		else
		{
			it++;
		}
	}

}
int CIcmsUpnpStack::PollSessionData()
{
	int fds;
	timeval tv;
	int iTotal;
	fd_set fd_send;
	fd_set fd_recv;
	FD_ZERO(&fd_send);
	FD_ZERO(&fd_recv);
	sockaddr_in addr;
	int iAddrSize = sizeof(addr);
	FCL_SOCKET sock = FCL_INVALID_SOCKET;
	int iCount = 0;
	
	CConnUser *pTemp = NULL;
	std::map<unsigned int,CConnUser*>::iterator it;
	int iDataLen =0;

	tv.tv_sec = 0;
	tv.tv_usec = 100*1000;
	fds = 0;
	FD_ZERO(&fd_recv);
	FD_ZERO(&fd_send);
		
	//处理每个会话
	for(it=m_insMap.begin();it!=m_insMap.end();it++)
	{
		pTemp = (*it).second;
		if ( pTemp &&pTemp->GetSocket() != FCL_INVALID_SOCKET )
		{
			if ( emConnecting == pTemp->GetStatus() ) //
			{
				FD_SET(pTemp->GetSocket(),&fd_send);
			}
			else
			{
				FD_SET(pTemp->GetSocket(),&fd_recv);
				if ( pTemp->IsWaitForSend() ) //当前发送缓冲还有数据,需要等待发送
				{
					FD_SET(pTemp->GetSocket(),&fd_send);
				}
			}
			if ( (int)(pTemp->GetSocket()) > fds )
			{
				fds = (int)pTemp->GetSocket();
			}
		}
	}

	if ( fds <= 0 )
	{
		//WARN_TRACE("not socket to process");
		return 0;
	}

	iTotal = select(fds+1,&fd_recv,&fd_send,0,&tv);
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
	if ( iTotal == 0 ) //超时
	{
		//continue;
		return 0;
	}

	//处理每个会话
	for(it=m_insMap.begin();it!=m_insMap.end();/*it++*/)
	{
		pTemp = it->second;
		if ( pTemp && FD_ISSET(pTemp->GetSocket(),&fd_recv) )
		{
			iCount++;
			iDataLen = pTemp->OnDataIn();
			if ( 0 == iDataLen ) //断线
			{
				INFO_TRACE("disconnect,remove it");
				//pTemp->SetCanRemoved();
				it++;
				//std::map<unsigned int,CConnUser*>::iterator itTemp = it;
				//it++;
				//m_insMap.erase(itTemp);
				//pTemp->Release();
				//delete pTemp;
				//if ( it == m_insMap.end() )
				//{
				//	break;
				//}
			}
			else if ( 0 > iDataLen )
			{
				ERROR_TRACE("recv failed,remove it");
				//pTemp->SetCanRemoved();
				it++;
				//std::map<unsigned int,CConnUser*>::iterator itTemp = it;
				//it++;
				//m_insMap.erase(itTemp);
				//pTemp->Release();
				//delete pTemp;
				//if ( it == m_insMap.end() )
				//{
				//	break;
				//}
			}
			else
			{
				it++;
			}
		}
		else if ( pTemp && FD_ISSET(pTemp->GetSocket(),&fd_send) )
		{
			if ( emConnecting == pTemp->GetStatus() ) //正在连接
			{
				pTemp->OnConnect(0);
			}
			else //可以发送数据
			{
				pTemp->OnDataOut();
			}
			it++;
		}
		else
		{
			it++;
		}
	}

	return iCount;
}

int CIcmsUpnpStack::OnMessage(CConnUser *pConn,HttpMessage &msg,const char *pContent,int iContentLength)
{
	if ( !pConn )
	{
		ERROR_TRACE("invalid user handle");
		return -1;
	}

	unsigned int uiUserId;

	uiUserId = pConn->GetUserId();

	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)*msg.vecHeaderValues.size()];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		return -1;
	}

	if ( msg.iType == 1 ) //请求
	{
		pHdr->iType = 1;
		pHdr->iMethod = msg.iMethod;
		strcpy(pHdr->szPath,msg.strPath.c_str());
	}
	else
	{
		pHdr->iType = 2;
		pHdr->iStatusCode = msg.iStatusCode;
	}
	pHdr->iProtocolVer = 2; //HTTP/1.1

	strcpy(pHdr->szFrom,msg.GetValueNoCase(HEADER_NAME_FROM).c_str());
	strcpy(pHdr->szTo,msg.GetValueNoCase(HEADER_NAME_TO).c_str());
	strcpy(pHdr->szTags,msg.GetValueNoCase(HEADER_NAME_TAGS).c_str());
	strcpy(pHdr->szAction,msg.GetValueNoCase(HEADER_NAME_ACTION).c_str());

	pHdr->iCount = 0;
	for(size_t i=0;i<msg.vecHeaderValues.size();i++)
	{
		if ( msg.vecHeaderValues[i].m_strArgumentName != HEADER_NAME_FROM 
			 && msg.vecHeaderValues[i].m_strArgumentName != HEADER_NAME_TO
			 && msg.vecHeaderValues[i].m_strArgumentName != HEADER_NAME_TAGS
			 && msg.vecHeaderValues[i].m_strArgumentName != HEADER_NAME_ACTION
			 && msg.vecHeaderValues[i].m_strArgumentName != "Content-Length"
			 )
		{
			strcpy(pHdr->hdrs[pHdr->iCount].szName,msg.vecHeaderValues[i].m_strArgumentName.c_str());
			strcpy(pHdr->hdrs[pHdr->iCount].szValue,msg.vecHeaderValues[i].m_strArgumentValue.c_str());
			pHdr->iCount++;
		}
	}

	if ( m_cbMsgCb )
	{
		m_cbMsgCb(uiUserId,pHdr,(void*)pContent,iContentLength,m_pUserMsg);
	}
	if ( pHdr )
	{
		delete pHdr;
	}
	return 0;
}
int CIcmsUpnpStack::OnStatusChange(CConnUser *pConn,EmUserStage emStatus,int iReason)
{
	if ( !pConn )
	{
		ERROR_TRACE("invalid user handle");
		return -1;
	}
	if ( m_cbDisConnect )
	{
		m_cbDisConnect(pConn->GetUserId(),(int)emStatus,iReason,m_pUserDisConnect);
	}
	if ( emRegisterFailed == emStatus || emConnctionDisconnected == emStatus )
	{
		if ( !pConn->IsClient() ) //服务端
		{
			pConn->SetCanRemoved();
		}
		else if ( pConn->IsAutoReconnect() )
		{
			if ( emConnctionDisconnected == emStatus && CConnUser::emDisRe_UnRegistered == iReason )
			{
				//主动登出
				pConn->SetCanRemoved();
			}
			else
			{
			}
		}
		else //非自动重连
		{
			pConn->SetCanRemoved();
		}
		
	}
		
	//if ( emRegisterFailed == emStatus ) //连接失败
	//{
	//	m_insMap.erase(pConn->GetUserId());
	//	delete pConn;
	//}
	//if ( !pConn->IsClient() )
	//{
	//	
	//	//本端是服务端,删除
	//	//m_insMap.erase(pConn->GetUserId());
	//	//delete pConn;
	//}
	//else //暂时不做处理
	//{
	//}
	return 0;
}

int CIcmsUpnpStack::OnLogin(CConnUser *pConn
							,int iUserType
							,const std::string &strUser
							,std::string &strPassword
							,int &iResult)
{
	if ( m_cbLoginCb == NULL ) //没有回调
	{
		iResult = -2;
		return 0;
	}
	REGISTER_VERIFY_INFO verInfo = {0};
	verInfo.iUserType = iUserType;
	strcpy(verInfo.szUser,strUser.c_str());
	m_cbLoginCb(pConn->GetUserId(),&verInfo,m_pUserLogin);
	iResult = verInfo.iResult;
	if ( iResult == 1 ) //需要密码验证
	{
		strPassword = verInfo.szPassword;
	}
	return 0;
}

//启动uc和fd注册侦听服务
int CIcmsUpnpStack::StartUcAndFdListen()
{
	if ( !StartListen(NULL,m_usServPort_uc_fd,m_sSock_uc_fd) )
	{
		ERROR_TRACE("start listen failed");
		return -1;
	}

	m_bUse_uc_fd = true;

	return 0;
}
//关闭uc和fd注册侦听服务
int CIcmsUpnpStack::StopUcAndFdListen()
{
	m_bUse_uc_fd = false;
	FCL_CLOSE_SOCKET(m_sSock_uc_fd);
	return 0;
}
//启动proxy注册侦听服务
int CIcmsUpnpStack::StartProxyListen()
{
	if ( !StartListen(NULL,m_usServPort_proxy,m_sSock_proxy) )
	{
		ERROR_TRACE("start listen failed");
		return -1;
	}

	m_bUse_proxy = true;

	return 0;
}
//关闭proxy注册侦听服务
int CIcmsUpnpStack::StopProxyListen()
{
	m_bUse_proxy = false;
	FCL_CLOSE_SOCKET(m_sSock_proxy);
	return 0;
}

bool CIcmsUpnpStack::StartListen(const char *ip,unsigned short port,FCL_SOCKET &sock)
{
	sockaddr_in addr;
	sock = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
	if( sock == FCL_INVALID_SOCKET )
	{
#ifdef PLAT_WIN32
		errno = WSAGetLastError();
#endif
		ERROR_TRACE("socket() error. errno="<<errno<<".");
		return false;
	}
	int iOn = 1;
	int iRet;


	int iBlock = 1;
#ifdef PLAT_WIN32
	iRet = ::ioctlsocket(sock,FIONBIO,(u_long FAR *)&iBlock);
	if ( iRet == SOCKET_ERROR ) 
	{
		errno = ::WSAGetLastError();
		iRet = -1;
	}
#else
	iBlock = ::fcntl(sock, F_GETFL, 0);
	if (iBlock != -1)
	{
		iBlock |= O_NONBLOCK;
		iRet = ::fcntl(sock, F_SETFL, iBlock);
	}
#endif
	if ( -1 == iRet )
	{
		FCL_CLOSE_SOCKET(sock);
		ERROR_TRACE("set noblock mode error. errno="<<errno<<".");
		return false;
	}

	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	if ( !ip || 0 == strcmp(ip,"0.0.0.0") )
	{
		addr.sin_addr.s_addr = INADDR_ANY;
	}
	else
	{
		addr.sin_addr.s_addr = inet_addr(ip);
	}

	addr.sin_port = htons(port);
	if ( 0 != bind(sock, (struct sockaddr*)&addr, sizeof(addr)) )
	{
#ifdef PLAT_WIN32
		errno = WSAGetLastError();
#else
#endif
		FCL_CLOSE_SOCKET(sock);
		ERROR_TRACE("bind error. errno="<<errno<<".");
		return false;
	}

	listen(sock,5);

	return true;
}

void CIcmsUpnpStack::PollAccept()
{
	int fds;
	timeval tv;
	int iTotal;
	fd_set fd_send;
	fd_set fd_recv;
	FD_ZERO(&fd_send);
	FD_ZERO(&fd_recv);
	sockaddr_in addr;
	int iAddrSize = sizeof(addr);
	FCL_SOCKET sock = FCL_INVALID_SOCKET;
	std::vector<FCL_SOCKET> vecSock;

	tv.tv_sec = 0;
	tv.tv_usec = 100*1000;
	fds = 0;
	FD_ZERO(&fd_recv);
	FD_ZERO(&fd_send);

	if ( m_bUse_uc_fd )
	{
		if ( FCL_INVALID_SOCKET != m_sSock_uc_fd )
		{
			FD_SET(m_sSock_uc_fd,&fd_recv);
			vecSock.push_back(m_sSock_uc_fd);
			if ( fds < m_sSock_uc_fd )
			{
				fds = (int)m_sSock_uc_fd;
			}
		}
	}
	if ( m_bUse_proxy )
	{
		if ( FCL_INVALID_SOCKET != m_sSock_proxy )
		{
			FD_SET(m_sSock_proxy,&fd_recv);
			vecSock.push_back(m_sSock_proxy);
			if ( fds < m_sSock_proxy )
			{
				fds = (int)m_sSock_proxy;
			}
		}
	}

	if ( vecSock.size() <= 0 )
	{
		return ;
	}
	//if ( fds < 0 )
	//{
	//	return ;
	//}

	iTotal = select(fds+1,&fd_recv,&fd_send,0,&tv);
#ifdef PLAT_WIN32
	if ( SOCKET_ERROR == iTotal )
	{
		errno = WSAGetLastError();
		ERROR_TRACE("socket select error. errno="<<errno<<".");
		return ;
	}
#else
	if ( -1 == iTotal )
	{
		ERROR_TRACE("socket select error. errno="<<errno<<".");
		return ;
	}
#endif
	if ( iTotal == 0 ) //超时
	{
		return ;
	}

	for( size_t i=0;i<vecSock.size();i++)
	{
		if ( FD_ISSET(vecSock[i],&fd_recv) )
		{

			/*FCL_SOCKET */sock = accept(vecSock[i],(sockaddr*)&addr,
#if !defined(PLAT_WIN32)
				(socklen_t*)
#endif
				&iAddrSize);
			if ( FCL_INVALID_SOCKET == sock ) //错误
			{
#ifdef PLAT_WIN32
				errno = WSAGetLastError();
#endif
				ERROR_TRACE("socket accept error. errno="<<errno<<".");
				FCL_CLOSE_SOCKET(sock);
				//return sock;
			}
			else
			{
				int iRet;
				int iBlock = 1;
#ifdef PLAT_WIN32
				iRet = ::ioctlsocket(sock,FIONBIO,(u_long FAR *)&iBlock);
				if (iRet == SOCKET_ERROR) 
				{
					errno = ::WSAGetLastError();
					iRet = -1;
				}
#else
				iBlock = ::fcntl(sock, F_GETFL, 0);
				if (iBlock != -1)
				{
					iBlock |= O_NONBLOCK;
					iRet = ::fcntl(sock, F_SETFL, iBlock);
				}
#endif
				if ( -1 == iRet )
				{
					ERROR_TRACE("socket set noblock mode error. errno="<<errno<<".");
					//return sock;
					FCL_CLOSE_SOCKET(sock);
				}
				else //新的连接
				{
					OnNewConnection(sock);
				}
			}

		}
	}

	return ;
}

void CIcmsUpnpStack::OnNewConnection(FCL_SOCKET sock)
{
	//2 创建实例
	int iRet = 0;
	CConnUser *pInst = new CConnUser(sock);
	if ( NULL == pInst )
	{
		ERROR_TRACE("out of memory.");
		return ;
	}
	//初始化参数
	pInst->SetLocalVcode(std::string(m_strVirtualCode));
	pInst->SetLocalType(m_iLocalType);
	pInst->SetIsClient(false);
	pInst->SetSinker(this);

	m_insMap[pInst->GetUserId()] = pInst;

	return ;
}