#include "EndpointUc.h"

#include "Trace.h"
#include "rapidxml.hpp"
#include <list>
#include "HttpDefines.h"
#include "UcApi.h"
#include "ZipLib.h"

#define DEFAULT_DEVICE_TYPE     "type:dahua-zwan-main-gateway"
#define DEFAULT_FRIENDLY_NAME   "name:dahua-zwan-main-gateway"
#define DEFAULT_UDN             "udn:dahua-zwan-main-gateway"
#define DEFAULT_BASE_PATH       "/"
#define DEFAULT_HTTP_PORT       10080

#define SSDP_NOTIFY_ALIVE          "NOTIFY * HTTP/1.1\r\n"               \
                                   "Host: 239.255.255.250:1900\r\n"      \
								   "Location: %s\r\n"                    \
								   "NTS: ssdp:alive\r\n"                 \
								   "Cache-Control: max-age=20\r\n"       \
								   "Server: dhzwan upnp/1.0\r\n"         \
								   "USN: %s\r\n"                         \
								   "NT: %s\r\n"                          \
								   "\r\n"

#define SSDP_NOTIFY_BYEBYE         "NOTIFY * HTTP/1.1\r\n"               \
								   "NTS: ssdp:byebye\r\n"                \
								   "USN: %s\r\n"                         \
								   "NT: %s\r\n"                          \
								   "\r\n"

#define ACTION_BODY   "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n"                              \
					  "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" "  \
					  "xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">\r\n"                  \
					  "\t<s:Body>\r\n"                                                              \
					  "\t\t<u:%s xmlns:u=\"%s\">\r\n"                                               \
					  "%s\r\n"                                                                      \
					  "\t\t</u:%s>\r\n"                                                             \
					  "\t</s:Body>\r\n"                                                             \
					  "</s:Envelope>"

#define CONTROLPOINT_TYPE_MODULE_ID		54		//控制点端类型

unsigned int CEndpointUc::s_uiSeq = 0; //包标识
unsigned long long CEndpointUc::s_ullSessionId = 0; //会话标识
unsigned int CEndpointUc::s_uiLoginId = 0; //包标识

#define  SDK_VERSION_MAJOR   1
#define  SDK_VERSION_MINOR   00
#define  SDK_VERSION_BUILD   0x1016

#define  SDK_VERSION   (SDK_VERSION_MAJOR<<24 | SDK_VERSION_MINOR<<16 | SDK_VERSION_BUILD)

#define SDK_NAME  "SH_CONTROLPOINT"

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

CEndpointUc::CEndpointUc():m_cbDisConnect(NULL),m_pUser(NULL)

{
	INFO_TRACE("stack : "<<SDK_NAME<<" version : "
				<<SDK_VERSION_MAJOR<<"."<<((SDK_VERSION_MINOR&0XF0)>>4)
				<<(SDK_VERSION_MINOR&0X0F)<<"."
				<<std::hex<<((SDK_VERSION_BUILD&0XFF00)>>8)
				<<std::hex<<(SDK_VERSION_BUILD&0X00FF)
				<<" compile : "<<__DATE__<< " "<<__TIME__);

#ifdef PLAT_WIN32
	InitWinSock();
#endif
	m_bIsStart = false; //设备状态

	//m_strBasePath = DEFAULT_BASE_PATH;
	//m_strUuid = DEFAULT_UDN;
	//m_strFriendlyName = DEFAULT_FRIENDLY_NAME;
	//m_strDeviceType = DEFAULT_DEVICE_TYPE;
	m_usServPort = DEFAULT_HTTP_PORT;
	m_strServIp = "127.0.0.1";

	m_ucMac[0] = 0XAA;
	m_ucMac[1] = 0XBB;
	m_ucMac[2] = 0XCC;
	m_ucModuleId = 1;

	//m_uiLoginId = MakeLoginId();
	m_uiLoginId = 0;
	m_emStatus = emIdle;
	m_iLoginError = UPCL_ERROR_UNKNOWN;

	m_bFirstConnect = true;
	m_bFirstLogin = true;
	m_bAutoReConnect = false; //默认登录成功一次后断线不自动重连

	m_cbEventNotify = NULL;
	m_pEventNotifyUser = NULL;

	m_bNeedSubscrible = false; //是否需要订阅,现在默认获取设备列表后不自动订阅

	m_strEventListenIp = "127.0.0.1";
	m_usEventListenPort = 80;

	m_ucModuleId = CONTROLPOINT_TYPE_MODULE_ID; //control point
	//读取mac地址
	unsigned long long ullMac = GetMacAddrEx();
	if ( 0 == ullMac )
	{
		//如果读取失败,则取随机数
		GenerateRand(m_ucMac,6);
	}
	else
	{
		//m_ucMac[0] = (unsigned char)((uiMac&0XFF000000)>>24);
		//m_ucMac[1] = (unsigned char)((uiMac&0XFF000000)>>16);
		//m_ucMac[2] = (unsigned char)((uiMac&0XFF000000)>>8);

		m_ucMac[0] = ((ullMac & 0X0000FF0000000000ULL)>>40);
		m_ucMac[1] = ((ullMac & 0X000000FF00000000ULL)>>32);
		m_ucMac[2] = ((ullMac & 0X00000000FF000000ULL)>>24);
		m_ucMac[3] = ((ullMac & 0X0000000000FF0000ULL)>>16);
		m_ucMac[4] = ((ullMac & 0X000000000000FF00ULL)>>8);
		m_ucMac[5] = ((ullMac & 0X00000000000000FFULL)>>0);
	}

}

CEndpointUc::~CEndpointUc()
{
	if ( m_bIsStart )
	{
		Stop();
	}
#ifdef PLAT_WIN32
	CleanupWinSock();
#endif
}

CEndpointUc * CEndpointUc::Instance()
{
	static CEndpointUc s_instance;
	return &s_instance;
}
void CEndpointUc::UnInit()
{
	m_emStatus = emIdle;
	m_bFirstConnect = true;
	m_bFirstLogin = true;
	m_bAutoReConnect = true; //默认登录成功一次后断线自动重连
	m_cbDisConnect = NULL;
	m_pUser = NULL;
	FCL_CLOSE_SOCKET(m_sSock);
	m_reqList.clear();
	m_vecSubdcrible.clear();
	//if ( m_pSession )
	//{
	//	delete m_pSession;
	//	m_pSession = NULL;
	//}
	//m_uiLoginId = MakeLoginId();
	m_uiLoginId = 0;
}

unsigned int CEndpointUc::MakeReqId()
{
	return ++CEndpointUc::s_uiSeq;
}
//unsigned long long CEndpointUc::MakeSessionId()
//{
//	unsigned long long uiSessionId;
//	uiSessionId = (unsigned long long)((unsigned long long)m_ucMac[0]<<56
//		                                | (unsigned long long)m_ucMac[1]<<48
//										| (unsigned long long)m_ucMac[2]<<40
//										| (unsigned long long)m_ucModuleId<<32
//										| (unsigned long long)GetTickCount());
//	return uiSessionId;
//}
std::string CEndpointUc::MakeSessionId()
{
	//unsigned long long uiSessionId;
	//uiSessionId = (unsigned long long)((unsigned long long)m_ucMac[0]<<56
	//	                                | (unsigned long long)m_ucMac[1]<<48
	//									| (unsigned long long)m_ucMac[2]<<40
	//									| (unsigned long long)m_ucModuleId<<32
	//									| (unsigned long long)GetTickCount());

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
std::string CEndpointUc::MakeTags()
{
	unsigned int uiReqId = MakeReqId();
	//unsigned long long ullSessId = MakeSessionId();
	std::string strSessionId = MakeSessionId();
	char szBuf[128] = {0};
	sprintf(szBuf,"sessionid=%s,seq=%u",strSessionId.c_str(),uiReqId);
	return std::string(szBuf);
}

unsigned int CEndpointUc::MakeLoginId()
{
	++CEndpointUc::s_uiLoginId;
	if ( 0 == CEndpointUc::s_uiLoginId )
	{
		++CEndpointUc::s_uiLoginId;
	}
	return CEndpointUc::s_uiLoginId;
}

int CEndpointUc::Start()
{
	int iRet;
	iRet = ZW_SH_Init(CEndpointUc::fnOnDisConnect_s,this);
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_Init() failed.err="<<iRet);
		return -1;
	}
	ZW_SH_SetMessCallBack(CEndpointUc::fnOnMessage_s,this);

	iRet = StartTaskThread();
	if ( 0 == iRet )
	{
		m_bIsStart = true;
	}
	return iRet;
}

int CEndpointUc::Stop()
{
	INFO_TRACE("uninit start");
	m_bIsStart = false;
	m_bExitTaskThread = true;
#ifdef PLAT_WIN32
	DWORD dwRet = WaitForSingleObject(m_hTaskThread,5000);
	if ( dwRet == WAIT_TIMEOUT )
	{
		ERROR_TRACE("force terminate net thread.");
		TerminateThread(m_hTaskThread,0);
	}
#else
	void *result;
	pthread_join(m_hTaskThread,&result);
#endif
	UnInit();
	INFO_TRACE("uninit end");
	return 0;
}

//启动
int CEndpointUc::StartTaskThread()
{
	m_bExitTaskThread = false;
#ifdef PLAT_WIN32
	DWORD dwThreadId;
	m_hTaskThread = CreateThread(NULL,0,CEndpointUc::TaskThreadProc,this,0,&dwThreadId);
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

	if ((iRet = ::pthread_create(&m_hTaskThread, &attr,CEndpointUc::TaskThreadProc, this)) != 0) 
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
int CEndpointUc::StopTaskThread()
{
	m_bExitTaskThread = true;
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
unsigned long __stdcall CEndpointUc::TaskThreadProc(void *pParam)
#else
void* CEndpointUc::TaskThreadProc(void *pParam)
#endif
{
	CEndpointUc *pUser = (CEndpointUc*)pParam;
	pUser->TaskFuncProc();
	return 0;
}

void CEndpointUc::TaskFuncProc(void)
{
	while ( !m_bExitTaskThread )
	{
		//m_sshServer.Process();
		Task_Process();
		FclSleep(1);
	}


}
void CEndpointUc::Task_Process(void)
{
	int iRet;
	static long long llConnStart = 0;
	static long long llRegister = 0;
	//static bool bFirst = true;

	if ( !m_bIsStart ) //设备没有启动
	{
		FclSleep(1);
		return ;
	}

	switch ( m_emStatus )
	{
	case emIdle:
		{
			llConnStart = 0;
			if ( m_bFirstConnect )
			{
				m_bFirstConnect = false;
				//发起注册请求
				//ConnectAysc();
			}
			else
			{
				if ( !m_bFirstLogin ) //已经成功登录过
				{
					if ( m_bAutoReConnect ) //断线自动重连
					{
						if ( _abs64(m_llRetryInterval-GetCurrentTimeMs()) > CEndpointUc::GS_RETRY_INTERVAL )
						{
							//ConnectAysc();
							//发起注册请求
						}
					}
				}
			}
			break;
		}
	case emRegistering:
		{
			//判断是否注册超时
			break;
		}
	case emRegistered:
		{
			break;
		}
	default:
		WARN_TRACE("unknown status");
		break;
	}
	 
	//轮询数据
	if ( emRegistered == m_emStatus ) //已经注册
	{
		Process_Task(); //处理任务列表
		ProcessEventSubscrible();
	}
	FclSleep(1);
}

#ifdef PLAT_WIN32
void __stdcall CEndpointUc::fnOnDisConnect_s(UInt32 lLoginID,int iStatus,int iReason,void *pUser)
#else
void CEndpointUc::fnOnDisConnect_s(UInt32 lLoginID,int iStatus,int iReason,void *pUser)
#endif
{
	CEndpointUc *pArg = (CEndpointUc*)pUser;
	if ( !pUser )
	{
		ERROR_TRACE("invalid pUser,is null");
		return ;
	}
	pArg->fnOnDisConnect(lLoginID,iStatus,iReason);
}

#ifdef PLAT_WIN32
void __stdcall CEndpointUc::fnOnMessage_s(UInt32 lLoginID,LPHTTP_HEADER pHdr,void * pContent,int iContentLength,void *pUser)	
#else
void CEndpointUc::fnOnMessage_s(UInt32 lLoginID,LPHTTP_HEADER pHdr,void * pContent,int iContentLength,void *pUser)
#endif
{
	CEndpointUc *pArg = (CEndpointUc*)pUser;
	if ( !pUser )
	{
		ERROR_TRACE("invalid pUser,is null");
		return ;
	}
	pArg->fnOnMessage(lLoginID,pHdr,pContent,iContentLength);
}

//断线回调
void  CEndpointUc::fnOnDisConnect(UInt32 lLoginID,int iStatus,int iReason)
{
	if ( 0 == iStatus ) //断线
	{
		INFO_TRACE("disconnect.reason="<<iReason);
		m_emStatus = emIdle;
		m_llRetryInterval = GetCurrentTimeMs();
		if ( !m_bFirstLogin )
		{
			if ( m_cbDisConnect )
			{
				if ( 0 == iStatus && 8 == iReason )
				{
					//主动注销,不向上回调
				}
				else
				{
					m_cbDisConnect(m_uiLoginId,(char*)m_strServIp.c_str(),m_usServPort,m_pUser);
				}
			}
		}
	}
	else if ( 1 == iStatus ) //登录成功
	{
		INFO_TRACE("register OK.");
		m_emStatus = emRegistered;
		m_strEventListenIp = ZW_SH_GetLocalIp(lLoginID);
	}
	else if (  2 == iStatus ) //登录失败
	{
		INFO_TRACE("register failed.reason="<<iReason);
		m_emStatus = emIdle;
		switch ( iReason )
		{
		case 1:	//连接失败
			m_iLoginError = UPCL_ERROR_NETWORK;
			break;
		//case 2:	//断线
		//	m_iLoginError = ;
		//	break;
		case 3:	//连接超时
			m_iLoginError = UPCL_ERROR_NETWORK;
			break;
		case 4:	//注册失败
			m_iLoginError = UPCL_ERROR_NETWORK;
			break;
		case 5:	//注册超时
			m_iLoginError = UPCL_ERROR_TIMEOUT;
			break;
		case 6:	//注册被拒绝
			m_iLoginError = UPCL_ERROR_REFUSED;
			break;
		//case 7:	//保活失败
		//	m_iLoginError = ;
		//	break;
		//case 8:	//注销
		//	m_iLoginError = ;
		//	break;
		case 8:	//密码错误
			m_iLoginError = UPCL_ERROR_PASSWORD_INVALID;
			break;
		default:
			m_iLoginError = UPCL_ERROR_UNKNOWN;
			break;
		}

		m_llRetryInterval = GetCurrentTimeMs();
		if ( !m_bFirstLogin )
		{
			if ( m_cbDisConnect )
			{
				m_cbDisConnect(m_uiLoginId,(char*)m_strServIp.c_str(),m_usServPort,m_pUser);
			}
		}
	}
}

//消息通知
void  CEndpointUc::fnOnMessage(UInt32 lLoginID,LPHTTP_HEADER pHdr,void * pContent,int iContentLength)
{
	//INFO_TRACE("recv msg");
	if ( !pHdr )
	{
		ERROR_TRACE("invalid param");
		return ;
	}

	for(int i=0;i<pHdr->iCount;i++)
	{
		INFO_TRACE("name="<<pHdr->hdrs[i].szName<<",value="<<pHdr->hdrs[i].szValue<<".");
	}
	if ( lLoginID != m_uiLoginId )
	{
		ERROR_TRACE("login-id invalid.current login-id="<<m_uiLoginId<<" recv login-id="<<lLoginID);
	}
	if ( HTTP_TYPE_RESPONSE == pHdr->iType
		&& 0 == strcmp(ACTION_REGISTER_RSP,pHdr->szAction)
		)
	{
		//注册回应
		if ( 200 == pHdr->iStatusCode ) //注册成功
		{
			INFO_TRACE("register OK.");
			m_emStatus = emRegistered;
		}
		else //注册失败
		{
			INFO_TRACE("register failed.ret="<<pHdr->iStatusCode);
			m_emStatus = emIdle;
		}
	}
	else if (  HTTP_TYPE_RESPONSE == pHdr->iType
				&& 0 == strcmp(ACTION_SEARCH_RSP,pHdr->szAction)
			)
	{
		//搜索网关列表回应
	}
	else if (  HTTP_TYPE_RESPONSE == pHdr->iType
				&& 0 == strcmp(ACTION_GETDEVLIST_RSP,pHdr->szAction)
			)
	{
		//获取设备列表回应
		INFO_TRACE("recv getDeviceList rsp");

		if ( pHdr->iStatusCode == 401 ) //需要认证
		{
			ProcessUpnpAuthTaskRsp(pHdr,pContent,iContentLength);
			return ;
		}

		//处理数据
		unsigned uiSeq;
		uiSeq = GetSeq(std::string(pHdr->szTags));

		TaskItem *pTask = FetchRequest(uiSeq);
		if ( !pTask )
		{
			ERROR_TRACE("not find seq. rsp transid="<<uiSeq);			
			return ;
		}

		//RequestList::iterator it = m_reqList.find(uiSeq);
		//if ( m_reqList.end() == it )
		//{
		//	ERROR_TRACE("not find seq. rsp transid="<<uiSeq);			
		//	return ;
		//}
		//TaskItem *pTask = (*it).second;
		//m_reqList.erase(uiSeq);
		pTask->iStatus = 1;
		pTask->iStatusCode = pHdr->iStatusCode;
		//int iEncoding = 0; //0 不压缩 1 gzip 2 zlib
		std::string strEncoding;
		if ( pContent && iContentLength > 0 )
		{
			if ( pHdr->iCount > 0 )
			{
				for(int i=0;i<pHdr->iCount;i++)
				{
					if ( 0 == strncasecmp(pHdr->hdrs[i].szName,"Content-Encoding",strlen("Content-Encoding")) )
					{
						strEncoding = pHdr->hdrs[i].szValue;
					}
				}
			}
			if ( strEncoding == "gzip" || strEncoding == "deflate" ) //gzip or zlib
			{
				//iEncoding = 1;
				//解压
				char *pOut = NULL;
				int iOutLen = 0;
				bool bRet;
				bRet = ZipLib::Decompress((char*)pContent,iContentLength,pOut,iOutLen);
				if ( !bRet ) //压缩失败,仍然采用不压缩方式方式 
				{
					ERROR_TRACE("decompress failed.");
					pTask->strRsp = std::string((char*)pContent,iContentLength);
				}
				else
				{
					pTask->strRsp = std::string((char*)pOut,iOutLen);
					if ( pOut )
					{
						delete []pOut;
						pOut = NULL;
					}
				}
			}

			else //其他,忽略
			{
				pTask->strRsp = std::string((char*)pContent,iContentLength);
			}

		}
		pTask->hEvent.Signal();
	}
	else if (  HTTP_TYPE_RESPONSE == pHdr->iType
				&& 0 == strcmp(ACTION_ACTION_RSP,pHdr->szAction)
			)
	{
		//设备控制回应
		INFO_TRACE("recv action rsp");

		if ( pHdr->iStatusCode == 401 ) //需要认证
		{
			ProcessUpnpAuthTaskRsp(pHdr,pContent,iContentLength);
			return ;
		}

		//处理数据
		unsigned uiSeq;
		uiSeq = GetSeq(std::string(pHdr->szTags));

		TaskItem *pTask = FetchRequest(uiSeq);
		if ( !pTask )
		{
			ERROR_TRACE("not find seq. rsp transid="<<uiSeq);			
			return ;
		}

		//RequestList::iterator it = m_reqList.find(uiSeq);
		//if ( m_reqList.end() == it )
		//{
		//	ERROR_TRACE("not find seq. rsp transid="<<uiSeq);			
		//	return ;
		//}
		//TaskItem *pTask = (*it).second;
		//m_reqList.erase(uiSeq);
		pTask->iStatus = 1;
		pTask->iStatusCode = pHdr->iStatusCode;
		if ( pContent && iContentLength > 0 )
		{
			pTask->strRsp = std::string((char*)pContent,iContentLength);
		}
		pTask->hEvent.Signal();
	
	}
	else if (  HTTP_TYPE_RESPONSE == pHdr->iType
				&& 0 == strcmp(ACTION_QUERY_RSP,pHdr->szAction)
			)
	{
		//查询配置文件回应
		INFO_TRACE("recv query rsp");

		if ( pHdr->iStatusCode == 401 ) //需要认证
		{
			ProcessUpnpAuthTaskRsp(pHdr,pContent,iContentLength);
			return ;
		}

		//处理数据
		unsigned uiSeq;
		uiSeq = GetSeq(std::string(pHdr->szTags));

		TaskItem *pTask = FetchRequest(uiSeq);
		if ( !pTask )
		{
			ERROR_TRACE("not find seq. rsp transid="<<uiSeq);			
			return ;
		}

		//RequestList::iterator it = m_reqList.find(uiSeq);
		//if ( m_reqList.end() == it )
		//{
		//	ERROR_TRACE("not find seq. rsp transid="<<uiSeq);			
		//	return ;
		//}
		//TaskItem *pTask = (*it).second;
		//m_reqList.erase(uiSeq);
		pTask->iStatus = 1;
		pTask->iStatusCode = pHdr->iStatusCode;
		if ( pContent && iContentLength > 0 )
		{
			pTask->strRsp = std::string((char*)pContent,iContentLength);
		}
		pTask->hEvent.Signal();
	}
	else if (  HTTP_TYPE_RESPONSE == pHdr->iType
				&& 0 == strcmp(ACTION_DOWNLOADFILE_RSP,pHdr->szAction)
			)
	{
		//文件下载回应
		INFO_TRACE("recv download file rsp");

		//处理数据
		unsigned uiSeq;
		uiSeq = GetSeq(std::string(pHdr->szTags));

		TaskItem *pTask = FetchRequest(uiSeq);
		if ( !pTask )
		{
			ERROR_TRACE("not find seq. rsp transid="<<uiSeq);			
			return ;
		}
		//RequestList::iterator it = m_reqList.find(uiSeq);
		//if ( m_reqList.end() == it )
		//{
		//	ERROR_TRACE("not find seq. rsp transid="<<uiSeq);			
		//	return ;
		//}
		//TaskItem *pTask = (*it).second;
		//m_reqList.erase(uiSeq);
		pTask->iStatus = 1;
		pTask->iStatusCode = pHdr->iStatusCode;
		if ( pContent && iContentLength > 0 )
		{
			pTask->strRsp = std::string((char*)pContent,iContentLength);
		}
		pTask->hEvent.Signal();
	}
	else if ( HTTP_TYPE_RESPONSE == pHdr->iType
			  && 0 == strcmp(ACTION_SUBSCRIBLE_RSP,pHdr->szAction)
			)
	{
		INFO_TRACE("recv subscrible rsp msg");

		if ( pHdr->iStatusCode == 401 ) //需要认证
		{
			unsigned uiSeq;
			uiSeq = GetSeq(std::string(pHdr->szTags));

			TaskItem *pTask = FindRequest(uiSeq);
			if ( pTask ) //上层主动发送
			{
				ProcessUpnpAuthTaskRsp(pHdr,pContent,iContentLength);
				return ;
			}
			else //内部处理
			{
				//带认证信息的订阅
				std::string strAuthenticate;
				for(int i=0;i<pHdr->iCount;i++)
				{
					if ( 0 == strncasecmp(pHdr->hdrs[i].szName,HEADER_NAME_UPNP_AUTHENTICATE,strlen(HEADER_NAME_UPNP_AUTHENTICATE)) )
					{
						strAuthenticate = pHdr->hdrs[i].szValue;
						break;
					}
				}
				if ( strAuthenticate.empty() )
				{
					//错误,没有认证信息
					ERROR_TRACE("not find Upnp-Authenticate.");
					return ;
				}
				std::string strTags = pHdr->szTags;
				int iRet = Subscrible2_Auth(strTags,strAuthenticate);
				if ( 0 != iRet )
				{
					ERROR_TRACE("auth subscrible failed");
				}
			}
			return ;
		}

		//订阅回应
		std::string strTo = pHdr->szTo;
		std::string strTags = pHdr->szTags;
		std::string strSid;
		int iTimeout = 1800;

		for(int i=0;i<pHdr->iCount;i++)
		{
			if ( 0 == strncasecmp(pHdr->hdrs[i].szName,"SID",4) )
			{
				strSid = pHdr->hdrs[i].szValue;
			}
			else if ( 0 == strncasecmp(pHdr->hdrs[i].szName,"TIMEOUT",8) )
			{
				sscanf(pHdr->hdrs[i].szValue,"Second-%d",&iTimeout);
				if ( iTimeout<300 || iTimeout>3600*24)
				{
					iTimeout = 1800;
				}
			}
		}
		OnSubscribleRsp(strTo,strTags,strSid,iTimeout,pHdr->iStatusCode);
	}
	else if ( HTTP_TYPE_RESPONSE == pHdr->iType
			  && 0 == strcmp(ACTION_RENEW_RSP,pHdr->szAction)
			)
	{
		INFO_TRACE("recv renew rsp msg");
	
		if ( pHdr->iStatusCode == 401 ) //需要认证
		{
			unsigned uiSeq;
			uiSeq = GetSeq(std::string(pHdr->szTags));

			TaskItem *pTask = FindRequest(uiSeq);
			if ( pTask ) //上层主动发送
			{
				ProcessUpnpAuthTaskRsp(pHdr,pContent,iContentLength);
				return ;
			}
			else //内部处理
			{
				//带认证信息的订阅
				std::string strAuthenticate;
				for(int i=0;i<pHdr->iCount;i++)
				{
					if ( 0 == strncasecmp(pHdr->hdrs[i].szName,HEADER_NAME_UPNP_AUTHENTICATE,strlen(HEADER_NAME_UPNP_AUTHENTICATE)) )
					{
						strAuthenticate = pHdr->hdrs[i].szValue;
						break;
					}
				}
				if ( strAuthenticate.empty() )
				{
					//错误,没有认证信息
					ERROR_TRACE("not find Upnp-Authenticate.");
					return ;
				}
				std::string strTags = pHdr->szTags;
				int iRet = RenewSubscrible2_Auth(strTags,strAuthenticate);
				if ( 0 != iRet )
				{
					ERROR_TRACE("auth subscrible failed");
				}
			}
			return ;
		}

		//订阅回应
		std::string strTo = pHdr->szTo;
		std::string strTags = pHdr->szTags;
		std::string strSid;
		int iTimeout = 1800;

		for(int i=0;i<pHdr->iCount;i++)
		{
			if ( 0 == strncasecmp(pHdr->hdrs[i].szName,"SID",4) )
			{
				strSid = pHdr->hdrs[i].szValue;
			}
			else if ( 0 == strncasecmp(pHdr->hdrs[i].szName,"TIMEOUT",8) )
			{
				sscanf(pHdr->hdrs[i].szValue,"Second-%d",&iTimeout);
				if ( iTimeout<300 || iTimeout>3600*24)
				{
					iTimeout = 1800;
				}
			}
		}
		OnRenewSubscribleRsp(strTo,strTags,strSid,iTimeout,pHdr->iStatusCode);
	}
	else if ( HTTP_TYPE_RESPONSE == pHdr->iType
			  && 0 == strcmp(ACTION_UNSUBSCRIBLE_RSP,pHdr->szAction)
			)
	{
		INFO_TRACE("recv unsubscrible rsp msg");

		if ( pHdr->iStatusCode == 401 ) //需要认证
		{
			unsigned uiSeq;
			uiSeq = GetSeq(std::string(pHdr->szTags));

			TaskItem *pTask = FindRequest(uiSeq);
			if ( pTask ) //上层主动发送
			{
				ProcessUpnpAuthTaskRsp(pHdr,pContent,iContentLength);
				return ;
			}
			else //内部处理
			{
				//带认证信息的订阅
				std::string strAuthenticate;
				for(int i=0;i<pHdr->iCount;i++)
				{
					if ( 0 == strncasecmp(pHdr->hdrs[i].szName,HEADER_NAME_UPNP_AUTHENTICATE,strlen(HEADER_NAME_UPNP_AUTHENTICATE)) )
					{
						strAuthenticate = pHdr->hdrs[i].szValue;
						break;
					}
				}
				if ( strAuthenticate.empty() )
				{
					//错误,没有认证信息
					ERROR_TRACE("not find Upnp-Authenticate.");
					return ;
				}
				std::string strTags = pHdr->szTags;
				int iRet = UnSubscrible2_Auth(strTags,strAuthenticate);
				if ( 0 != iRet )
				{
					ERROR_TRACE("auth subscrible failed");
				}
			}
			return ;
		}
	
		//取消订阅回应
		std::string strTo = pHdr->szTo;
		std::string strTags = pHdr->szTags;

		OnCancelSubscribleRsp(strTo,strTags,pHdr->iStatusCode);
	}
	else if ( HTTP_TYPE_REQUEST == pHdr->iType
			  && 0 == strcmp(ACTION_NOTIFY_REQ,pHdr->szAction)
			)
	{
		//事件通知请求
		//发送回应
		HTTP_HEADER stHdrRsp = {0};
		stHdrRsp.iType = HTTP_TYPE_RESPONSE; //请求消息
		//stHdrRsp.iMethod = HTTP_METHOD_EX_NOTIFY; //通知
		stHdrRsp.iProtocolVer = 2; //HTTP/1.1
		stHdrRsp.iStatusCode = 200;
		strcpy(stHdrRsp.szAction,ACTION_NOTIFY_RSP);
		strcpy(stHdrRsp.szFrom,pHdr->szFrom);
		strcpy(stHdrRsp.szTo,pHdr->szTo);
		strcpy(stHdrRsp.szTags,pHdr->szTags);
		stHdrRsp.iContentLength = 0;
		stHdrRsp.iCount = 0;
		int iRet = ZW_SH_SendMessage(lLoginID,&stHdrRsp,(void*)NULL,0);		
		if ( 0 != iRet )
		{
			ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		}

		//
		std::string strCallbackPath;
		std::string strContentType;
		std::string strHost;
		std::string strNT;
		std::string strNTS;
		std::string strSid;
		unsigned int uiEventId;
		std::string strContent;

		strCallbackPath = pHdr->szPath;
		for(int i=0;i<pHdr->iCount;i++)
		{
			if ( 0 == strncasecmp(pHdr->hdrs[i].szName,"Content-Type",13) )
			{
				strContentType = pHdr->hdrs[i].szValue;
			}
			else if ( 0 == strncasecmp(pHdr->hdrs[i].szName,"Host",5) )
			{
				strHost = pHdr->hdrs[i].szValue;
			}
			else if ( 0 == strncasecmp(pHdr->hdrs[i].szName,"NT",3) )
			{
				strNT = pHdr->hdrs[i].szValue;
			}
			else if ( 0 == strncasecmp(pHdr->hdrs[i].szName,"NTS",4) )
			{
				strNTS = pHdr->hdrs[i].szValue;
			}
			else if ( 0 == strncasecmp(pHdr->hdrs[i].szName,"SID",4) )
			{
				strSid = pHdr->hdrs[i].szValue;
			}
			else if ( 0 == strncasecmp(pHdr->hdrs[i].szName,"SEQ",4) )
			{
				uiEventId = atoi(pHdr->hdrs[i].szValue);
			}
		}
		if ( pContent )
		{
			strContent = std::string((char*)pContent,iContentLength);
		}
		ProcessEventNotify(strCallbackPath,strSid,uiEventId,strContent);
	}
	else if ( HTTP_TYPE_RESPONSE == pHdr->iType
			  && 0 == strcmp(ACTION_GATEWAYAUTH_RSP,pHdr->szAction)
			)
	{
		//查询配置文件回应
		INFO_TRACE("recv gateway auth rsp");

		if ( pHdr->iStatusCode == 401 ) //需要认证
		{
			ProcessUpnpAuthTaskRsp(pHdr,pContent,iContentLength);
			return ;
		}

		//处理数据
		unsigned uiSeq;
		uiSeq = GetSeq(std::string(pHdr->szTags));

		TaskItem *pTask = FetchRequest(uiSeq);
		if ( !pTask )
		{
			ERROR_TRACE("not find seq. rsp transid="<<uiSeq);			
			return ;
		}
		////RequestList::iterator it = m_reqList.find(uiSeq);
		////if ( m_reqList.end() == it )
		////{
		////	ERROR_TRACE("not find seq. rsp transid="<<uiSeq);			
		////	return ;
		////}
		////TaskItem *pTask = (*it).second;
		////m_reqList.erase(uiSeq);
		//if ( pHdr->iStatusCode == 401 ) //需要认证
		//{
		//	//填充认证信息
		//	std::string strAuthenticate;
		//	std::string strAuthorization;
		//	std::string strVcode;

		//	for(int i=0;i<pHdr->iCount;i++)
		//	{
		//		if ( 0 == strncasecmp(pHdr->hdrs[i].szName,HEADER_NAME_UPNP_AUTHENTICATE,strlen(HEADER_NAME_UPNP_AUTHENTICATE)) )
		//		{
		//			strAuthenticate = pHdr->hdrs[i].szValue;
		//			break;
		//		}
		//	}
		//	if ( strAuthenticate.empty() )
		//	{
		//		//错误
		//		pTask->iStatus = 1;
		//		pTask->iStatusCode = pHdr->iStatusCode;
		//		if ( pContent && iContentLength > 0 )
		//		{
		//			pTask->strRsp = std::string((char*)pContent,iContentLength);
		//		}
		//		pTask->hEvent.Signal();
		//		return ;
		//	}

		//	strVcode = pHdr->szTo;
		//	bool bRet = ProcessAuthReq(strVcode,strAuthenticate,strAuthorization,std::string("POST"),std::string("/gateway/auth/notify"));
		//	if ( !bRet )
		//	{
		//		pTask->iStatus = 1;
		//		pTask->iStatusCode = pHdr->iStatusCode;
		//		if ( pContent && iContentLength > 0 )
		//		{
		//			pTask->strRsp = std::string((char*)pContent,iContentLength);
		//		}
		//		pTask->hEvent.Signal();
		//		return ;
		//	}

		//	//发送认证信息
		//	LPHTTP_HEADER pHdr2 = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)];
		//	if ( !pHdr2 )
		//	{
		//		ERROR_TRACE("out of memory");
		//		return ;
		//	}

		//	pHdr2->iType = HTTP_TYPE_REQUEST; //请求消息
		//	pHdr2->iMethod = HTTP_METHOD_POST; //
		//	pHdr2->iProtocolVer = 2; //HTTP/1.1
		//	strcpy(pHdr2->szPath,"/gateway/auth");
		//	strcpy(pHdr2->szAction,ACTION_GATEWAYAUTH_REQ);
		//	strcpy(pHdr2->szFrom,pHdr->szFrom);
		//	strcpy(pHdr2->szTo,pHdr->szTo);
		//	strcpy(pHdr2->szTags,pHdr->szTags);
		//	pHdr2->iContentLength = 0;
		//	pHdr2->iCount = 1;
		//	strcpy(pHdr2->hdrs[0].szName,HEADER_NAME_UPNP_AUTHORIZATION);
		//	strcpy(pHdr2->hdrs[0].szValue,strAuthorization.c_str());

		//	int iRet = ZW_SH_SendMessage(lLoginID,pHdr2,(void*)NULL,0);		
		//	if ( 0 != iRet )
		//	{
		//		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		//		pTask->iStatus = 1;
		//		pTask->iStatusCode = pHdr->iStatusCode;
		//		if ( pContent && iContentLength > 0 )
		//		{
		//			pTask->strRsp = std::string((char*)pContent,iContentLength);
		//		}
		//		pTask->hEvent.Signal();
		//	}
		//	else
		//	{
		//		AddRequest(uiSeq,pTask);
		//	}
		//	
		//	//返回
		//	return ;
		//}
		
		//其他返回码,信令结束
		pTask->iStatus = 1;
		pTask->iStatusCode = pHdr->iStatusCode;
		if ( pContent && iContentLength > 0 )
		{
			pTask->strRsp = std::string((char*)pContent,iContentLength);
		}
		pTask->hEvent.Signal();
	}
	else
	{
		ERROR_TRACE("recv msg,not process,discard.");
	}
}

int CEndpointUc::CLIENT_Login(char *pchServIP
							   ,UInt16 wServPort
							   ,char *pchServVirtcode
							   ,char *pchVirtCode
							   ,char *pchPassword)
{
	int iRet = 0;
	UInt32 uiLoginId = 0;
	bool bResult = false;
	long long llStart = GetCurrentTimeMs();
	long long llEnd;

	if ( emIdle != m_emStatus ) //状态不对
	{
		ERROR_TRACE("already registed.status="<<m_emStatus);
		return UPCL_ERROR_DUPLICATE_REGISTER;
	}
	
	ZW_SH_SetAutoReconnect(m_bAutoReConnect);
	//发送登录请求
	uiLoginId = ZW_SH_Login(pchServIP,wServPort,pchServVirtcode,pchVirtCode,pchPassword,&iRet);
	if ( 0 == uiLoginId )
	{
		ERROR_TRACE("login failed.err="<<iRet);
		iRet = UPCL_ERROR_UNKNOWN;
		return iRet;
	}
	m_uiLoginId = uiLoginId;
	m_bFirstConnect = true;

	m_emStatus = emRegistering; //改为正在注册状态
	//保存参数
	m_strServIp = pchServIP;
	m_usServPort = wServPort;
	m_strServVirtualcode = pchServVirtcode;
	m_strVirtualCode = pchVirtCode;
	m_strPassword = pchPassword;
	
	//等待登录结果
	do
	{
		if ( m_emStatus == emRegistered ) //注册成功
		{
			bResult = true;
			INFO_TRACE("login OK.");
		}
		else if ( emIdle == m_emStatus ) //注册失败
		{
			bResult = true;
			INFO_TRACE("login failed.");
		}
		else
		{
			FclSleep(1);
		}
		llEnd = GetCurrentTimeMs();

	}while( _abs64(llEnd-llStart) < 15000 && !bResult );

	//登录

	//
	if ( emRegistered == m_emStatus )
	{
		m_bFirstLogin = false;
		iRet  = 0;
	}
	else //注册失败
	{
		ERROR_TRACE("login failed");
		iRet = m_iLoginError;
	}

	return iRet;
}

int CEndpointUc::CLIENT_Logout()
{
	int iRet = 0;
	bool bRet = false;
	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		iRet = -1;
		return iRet;
	}

	//登出
	iRet = ZW_SH_Logout(m_uiLoginId);

	//等待登录结果
	bool bResult = false;
	long long llStart = GetCurrentTimeMs();
	long long llEnd;
	do
	{
		if ( m_emStatus == emIdle ) //登出成功
		{
			bResult = true;
			INFO_TRACE("logout OK.");
		}
		else
		{
			FclSleep(1);
		}
		llEnd = GetCurrentTimeMs();

	}while( _abs64(llEnd-llStart) < 5000 && !bResult );

	if ( !bResult )
	{
		//登出失败,强制释放
		WARN_TRACE("logout failed.force release");
		ZW_SH_Release(m_uiLoginId);
	}
	//反初始化
	m_bFirstConnect = true;
	m_bFirstLogin = true;
	//m_bAutoReConnect = false; //默认登录成功一次后断线不自动重连

	//m_cbEventNotify = NULL;
	//m_pEventNotifyUser = NULL;

	m_bNeedSubscrible = false; //是否需要订阅,现在默认获取设备列表后不自动订阅

	//m_strEventListenIp = "127.0.0.1";
	//m_usEventListenPort = 80;
	m_emStatus = emIdle;
	m_uiLoginId = 0;
	return 0;
}

bool CEndpointUc::CLIENT_QueryGatewayList(LPUPNP_GATEWAY pUpnpGateway,Int32 maxlen,Int32 *devicecount,Int32 waittime)
{
	int iRet = 0;
	bool bRet = false;
	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		bRet = false;
		return bRet;
	}

	//发送查询请求
	std::string strTags;
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		bRet = false;
		return bRet;
	}
	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_EX_SEARCH; //搜索
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,"/Smarhome/cp");
	strcpy(pHdr->szAction,ACTION_SEARCH_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,m_strServVirtualcode.c_str());
	strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	pHdr->iContentLength = 0;
	pHdr->iCount = 0;

	iRet = ZW_SH_SendMessage(GetId(),pHdr,(void*)NULL,0);		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		bRet = false;
		return bRet;
	}
	if ( pHdr )
	{
		delete pHdr;
	}

	//等待结果
	unsigned int uiSeq = GetSeq(strTags);
	TaskItem *pTask = new TaskItem(strTags,GetCurrentTimeMs(),(unsigned int)waittime);
	if ( !pTask )
	{
		ERROR_TRACE("out of memory");
		return false;
	}
	AddRequest(uiSeq,pTask);
	//m_reqList[uiSeq] = pTask;
	pTask->hEvent.Wait(0);
	if ( 1 == pTask->iStatus ) //成功
	{
		//解析内容
		*devicecount = 0;
		if ( pTask->strRsp.size() > 0 )
		{
			if ( !ParseGatewayList(pTask->strRsp,pUpnpGateway,maxlen,*devicecount) )
			{
				ERROR_TRACE("parse rsp failed");
				//return -1;
				bRet = false;
			}
			else
			{
				bRet = true;
			}
			//返回
		}
		else
		{
			bRet = true;
		}
	}
	else
	{
		ERROR_TRACE("exec failed.ret="<<pTask->iStatus);
		bRet = false;
	}

	if ( pTask )
	{
		delete pTask;
	}
	return bRet;
}
bool CEndpointUc::ParseGatewayList(std::string &strMsg,LPUPNP_GATEWAY pUpnpGateway,Int32 maxlen,Int32 &count)
{
	rapidxml::xml_document<> xmlDoc;
	rapidxml::xml_node<> *pRoot;
	rapidxml::xml_node<> *pGateway;
	rapidxml::xml_node<> *pNode;

	count = 0;
	xmlDoc.parse<0>((char*)strMsg.c_str());

	//解析头部
	pRoot = xmlDoc.first_node("content");

	if ( !pRoot ) //没有
	{
		ERROR_TRACE("not find root node");
		return true;
	}

	//读取服务列表
	for(pGateway=pRoot->first_node();pGateway!=0;pGateway=pGateway->next_sibling())
	{
		if ( pGateway->name() && 0 == strcmp(pGateway->name(),"upnp-device") )
		{
			pNode = pGateway->first_node("v-code");
			if ( pNode && pNode->value() )
			{
				strcpy(pUpnpGateway[count].szVirtCode,pNode->value());
			}
			else
			{
				pUpnpGateway[count].szVirtCode[0] = '\0';
			}
			pNode = pGateway->first_node("root-device");
			if ( pNode && pNode->value() )
			{
				strcpy(pUpnpGateway[count].szUdn,pNode->value());
			}
			else
			{
				pUpnpGateway[count].szUdn[0] = '\0';
			}
			pNode = pGateway->first_node("location");
			if ( pNode && pNode->value() )
			{
				strcpy(pUpnpGateway[count].szLocation,pNode->value());
			}
			else
			{
				pUpnpGateway[count].szLocation[0] = '\0';
			}
			count++;
			if ( count >= maxlen ) //缓冲区不够
			{
				INFO_TRACE("not engouth buffer to gateway-list");
				break;
			}
		}

	}

	return true;
}

//获取设备列表
int CEndpointUc::CLIENT_GetDeviceList(char *pDeviceUdn
									  ,char *pDeviceLocation
									  ,LPUPNP_DEVICE pUpnpDevice
									  ,Int32 maxlen
									  ,Int32 *devicecount
									  ,Int32 waittime
									  )
{
	int iRet = 0;
	bool bRet = false;

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		iRet = UPCL_ERROR_NOT_REGISTER;
		return iRet;
	}

	std::string strVcode;
	std::string strAuthorization;
	std::string strMethod;
	std::string strUri;

	strVcode = pDeviceUdn;
	strMethod = "GET";
	strUri = pDeviceLocation;
	strAuthorization = GetAuthInfo(strVcode,strMethod,strUri);

	//发送查询请求
	std::string strTags;
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		iRet = UPCL_ERROR_NO_MORE_RESOURCE;
		return iRet;
	}
	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_GET; //搜索
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,pDeviceLocation);
	strcpy(pHdr->szAction,ACTION_GETDEVLIST_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,pDeviceUdn);
	strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	pHdr->iContentLength = 0;
	if ( strAuthorization.empty() )
	{
		pHdr->iCount = 1;
		strcpy(pHdr->hdrs[0].szName,"Accept-Encoding");
		strcpy(pHdr->hdrs[0].szValue,"gzip");
	}
	else
	{
		pHdr->iCount = 2;
		strcpy(pHdr->hdrs[0].szName,"Accept-Encoding");
		strcpy(pHdr->hdrs[0].szValue,"gzip");
		strcpy(pHdr->hdrs[1].szName,HEADER_NAME_UPNP_AUTHORIZATION);
		strcpy(pHdr->hdrs[1].szValue,strAuthorization.c_str());
	}
	iRet = ZW_SH_SendMessage(GetId(),pHdr,(void*)NULL,0);		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		iRet = UPCL_ERROR_NETWORK;
		return iRet;
	}

	unsigned int uiSeq = GetSeq(strTags);
	TaskItem *pTask = new TaskItem(strTags,GetCurrentTimeMs(),(unsigned int)waittime);
	if ( !pTask )
	{
		ERROR_TRACE("out of memory");
		iRet = UPCL_ERROR_NO_MORE_RESOURCE;
		return iRet;
	}
	pTask->pHdrReq = pHdr;
	AddRequest(uiSeq,pTask);
	pTask->hEvent.Wait(0);
	if ( 1 == pTask->iStatus && 200 == pTask->iStatusCode ) //成功
	{
		//解析内容
		*devicecount = 0;
		Int32 count = 0;
		if ( pTask->strRsp.size() > 0 )
		{
			DeviceData data;
			if ( !ParseGetDeviceListResp((char*)pTask->strRsp.c_str(),(unsigned int)pTask->strRsp.size(),data) )
			{
				ERROR_TRACE("parse rsp failed");
				iRet = UPCL_ERROR_NO_MORE_RESOURCE;
			}
			else
			{
				if ( data.m_vecSericeList.size() > 0 )
				{

					//if ( count >= maxlen )
					//{
					//	INFO_TRACE("not enough buf for device-list");
					//}
					strcpy(pUpnpDevice[count].szUdn,data.m_strUDN.c_str());
					strcpy(pUpnpDevice[count].szDeviceType,data.m_strDeviceType.c_str());
					strcpy(pUpnpDevice[count].szFriendlyName,data.m_strFriendlyName.c_str());
					strcpy(pUpnpDevice[count].szRoomId,data.m_strLayoutId.c_str());
					pUpnpDevice[count].iServiceCount = data.m_vecSericeList.size();
					strcpy(pUpnpDevice[count].szCameraId,data.m_strCameraId.c_str());
					for(size_t j=0;j<data.m_vecSericeList.size();j++)
					{

						strcpy(pUpnpDevice[count].stServiceList[j].szType
							  ,data.m_vecSericeList[j]->m_strServiceType.c_str());
						strcpy(pUpnpDevice[count].stServiceList[j].szId
							,data.m_vecSericeList[j]->m_strServiceId.c_str());
						strcpy(pUpnpDevice[count].stServiceList[j].szControlUrl
							,data.m_vecSericeList[j]->m_strControlUrl.c_str());
						strcpy(pUpnpDevice[count].stServiceList[j].szEventUrl
							,data.m_vecSericeList[j]->m_strEventSubUrl.c_str());
						pUpnpDevice[count].stServiceList[j].bCanSubscrible = true;
					}
					count++;
				}
				for(size_t i=0;i<data.m_vecEmbededDeviceList.size();i++,count++)
				{
					if ( count >= maxlen )
					{
						INFO_TRACE("not enough buf for device-list");
						break;
					}
					strcpy(pUpnpDevice[count].szUdn,data.m_vecEmbededDeviceList[i]->m_strUDN.c_str());
					strcpy(pUpnpDevice[count].szDeviceType,data.m_vecEmbededDeviceList[i]->m_strDeviceType.c_str());
					strcpy(pUpnpDevice[count].szFriendlyName,data.m_vecEmbededDeviceList[i]->m_strFriendlyName.c_str());
					strcpy(pUpnpDevice[count].szRoomId,data.m_vecEmbededDeviceList[i]->m_strLayoutId.c_str());
					pUpnpDevice[count].iServiceCount = data.m_vecEmbededDeviceList[i]->m_vecSericeList.size();
					strcpy(pUpnpDevice[count].szCameraId,data.m_vecEmbededDeviceList[i]->m_strCameraId.c_str());
					for(size_t j=0;j<data.m_vecEmbededDeviceList[i]->m_vecSericeList.size();j++)
					{
						strcpy(pUpnpDevice[count].stServiceList[j].szType
							  ,data.m_vecEmbededDeviceList[i]->m_vecSericeList[j]->m_strServiceType.c_str());
						strcpy(pUpnpDevice[count].stServiceList[j].szId
							,data.m_vecEmbededDeviceList[i]->m_vecSericeList[j]->m_strServiceId.c_str());
						strcpy(pUpnpDevice[count].stServiceList[j].szControlUrl
							,data.m_vecEmbededDeviceList[i]->m_vecSericeList[j]->m_strControlUrl.c_str());
						strcpy(pUpnpDevice[count].stServiceList[j].szEventUrl
							,data.m_vecEmbededDeviceList[i]->m_vecSericeList[j]->m_strEventSubUrl.c_str());
						pUpnpDevice[count].stServiceList[j].bCanSubscrible = true;
					}
				}
				*devicecount = count;
				iRet = UPCL_NO_ERROR;
////////////*********内部不做自动订阅,全部由外部决定*********////////////////
				//if ( m_bNeedSubscrible ) //是否需要订阅
				//{
				//	//清理以前订阅列表
				//	//UnSubscribleAll();
				//	UnSubscribleAll(std::string(pDeviceUdn));
				//	//订阅
				//	std::string strPeer(pDeviceUdn);
				//	SubscribleDevice(strPeer,data);
				//}
////////////*********内部不做自动订阅,全部由外部决定*********////////////////
			}
			//返回
		}
		else
		{
			iRet = UPCL_NO_ERROR;
		}
	}
	else
	{
		if ( pTask->iStatus == 1 )
		{
			//有回应
			iRet = HttpCode2Error(pTask->iStatusCode);
			ERROR_TRACE("exec failed.err="<<pTask->iStatusCode);
		}
		else
		{
			iRet = UPCL_ERROR_TIMEOUT;
			ERROR_TRACE("exec failed.timeout");
		}
	}

	if ( pTask )
	{
		delete pTask;
	}
	return iRet;
}
//获取设备列表
int  CEndpointUc::CLIENT_GetDeviceList(char *pDeviceUdn,char *pDeviceLocation,std::string &strDeviceList,Int32 waittime)
{
	int iRet = 0;
	bool bRet = false;

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		iRet = UPCL_ERROR_NOT_REGISTER;
		return iRet;
	}

	std::string strVcode;
	std::string strAuthorization;
	std::string strMethod;
	std::string strUri;

	strVcode = pDeviceUdn;
	strMethod = "GET";
	strUri = pDeviceLocation;
	strAuthorization = GetAuthInfo(strVcode,strMethod,strUri);

	//发送查询请求
	std::string strTags;
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		iRet = UPCL_ERROR_NO_MORE_RESOURCE;
		return iRet;
	}
	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_GET; //搜索
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,pDeviceLocation);
	strcpy(pHdr->szAction,ACTION_GETDEVLIST_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,pDeviceUdn);
	strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	pHdr->iContentLength = 0;
	if ( strAuthorization.empty() )
	{
		pHdr->iCount = 1;
		strcpy(pHdr->hdrs[0].szName,"Accept-Encoding");
		strcpy(pHdr->hdrs[0].szValue,"gzip");
	}
	else
	{
		pHdr->iCount = 2;
		strcpy(pHdr->hdrs[0].szName,"Accept-Encoding");
		strcpy(pHdr->hdrs[0].szValue,"gzip");
		strcpy(pHdr->hdrs[1].szName,HEADER_NAME_UPNP_AUTHORIZATION);
		strcpy(pHdr->hdrs[1].szValue,strAuthorization.c_str());
	}
	iRet = ZW_SH_SendMessage(GetId(),pHdr,(void*)NULL,0);		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		iRet = UPCL_ERROR_NETWORK;
		return iRet;
	}

	unsigned int uiSeq = GetSeq(strTags);
	TaskItem *pTask = new TaskItem(strTags,GetCurrentTimeMs(),(unsigned int)waittime);
	if ( !pTask )
	{
		ERROR_TRACE("out of memory");
		iRet = UPCL_ERROR_NO_MORE_RESOURCE;
		return iRet;
	}
	pTask->pHdrReq = pHdr;
	AddRequest(uiSeq,pTask);
	pTask->hEvent.Wait(0);
	if ( 1 == pTask->iStatus && 200 == pTask->iStatusCode ) //成功
	{
		strDeviceList = pTask->strRsp;
		iRet = UPCL_NO_ERROR;
	}
	else
	{
		if ( pTask->iStatus == 1 )
		{
			//有回应
			iRet = HttpCode2Error(pTask->iStatusCode);
			ERROR_TRACE("exec failed.err="<<pTask->iStatusCode);
		}
		else
		{
			iRet = UPCL_ERROR_TIMEOUT;
			ERROR_TRACE("exec failed.timeout");
		}
	}

	if ( pTask )
	{
		delete pTask;
	}
	return iRet;
}
//批量订阅服务
int CEndpointUc::CLIENT_Subscrible_Batch(LPSUBSCRIBLE_INFO pSubList,int iCount,int iTimeout)
{
	std::string strCallback;
	char szCallback[256];
	std::string strVcode;

	UnSubscribleAll();

	//有状态变量需要订阅?直接订阅
	for(int i= 0;i<iCount;i++) //获取服务描述
	{

		sprintf(szCallback,"<http://%s:%d/%s/%s>"
				,m_strEventListenIp.c_str(),m_usEventListenPort
				,pSubList[i].szUdn
				,pSubList[i].szServiceId);
		strCallback = szCallback;
		strVcode = pSubList[i].szVcode;
		if ( 0 == Subscrible(pSubList[i].szUdn,pSubList[i].szServiceType
							 ,strVcode,pSubList[i].szEventSubUrl,strCallback) )
		{
		}
		else
		{
			ERROR_TRACE("subscrible service failed.udn="
						<<pSubList[i].szUdn<<" vcode="<<pSubList[i].szVcode
						<<" serviceType="<<pSubList[i].szServiceType
						<<" eventUrl="<<pSubList[i].szEventSubUrl);

		}

	}


	return 0;
}

bool ParseLayout(char *pXml
				 ,unsigned int uiLen
				 ,LPLAYOUT_FLOOR pOutFloors
				 ,int maxFloors
				 ,int &iFloors
				 ,LPLAYOUT_ROOM pOutRooms
				 ,int maxRooms
				 ,int &iRooms)
{
	rapidxml::xml_document<> xmlDoc; 
	rapidxml::xml_node<> *pRoot;
	rapidxml::xml_node<> *pFloors;
	rapidxml::xml_node<> *pFloor;
	rapidxml::xml_node<> *pRooms;
	rapidxml::xml_node<> *pRoom;
	rapidxml::xml_node<> *pNode;
	rapidxml::xml_attribute<> *pAtti;

	std::string strId;
	std::string strUpperId;
	std::string strName;
	int iType;

	std::string strXml;
	try
	{
		strXml = std::string(pXml,uiLen);
		xmlDoc.parse<0>((char*)strXml.c_str()/*pXml*/);
	}
	catch(...)
	{
		ERROR_TRACE("parse layout xml failed.xml="<<pXml);
		ERROR_TRACE("<<<<TRACE xml  "<<pXml);
		return false;
	}

	//解析头部
	pRoot = xmlDoc.first_node("Body");

	if ( !pRoot ) //没有
	{
		ERROR_TRACE("not find root node");
		return true;
	}

	//解析内容

	iFloors = 0;
	iRooms = 0;
	pFloors = pRoot->first_node("floors");

	if ( pFloors )
	{
		//读取服务列表
		for(pFloor = pFloors->first_node();pFloor!=0;pFloor=pFloor->next_sibling())
		{
			if ( 0 == strcmp("floor",pFloor->name()) )
			{
				pNode = pFloor->first_node("id");
				if ( pNode && pNode->value() )
				{
					strId = pNode->value();
				}
				else
				{
					strId = "";
				}
				pNode = pFloor->first_node("name");
				if ( pNode && pNode->value() )
				{
					strName = pNode->value();
				}
				else
				{
					strName = "";
				}
				if ( iFloors < maxFloors )
				{
					strcpy(pOutFloors[iFloors].szId,strId.c_str());
					strcpy(pOutFloors[iFloors].szName,strName.c_str());
					iFloors++;
				}
				else
				{
					WARN_TRACE("too small floor buf");
					break;
				}
			}
			else //错误,不应该有其他节点
			{
			}
		}
	}

	pRooms = pRoot->first_node("rooms");

	if ( pRooms )
	{
		//读取服务列表
		for(pRoom = pRooms->first_node();pRoom!=0;pRoom=pRoom->next_sibling())
		{
			if ( 0 == strcmp("room",pRoom->name()) )
			{
				pAtti = pRoom->first_attribute("floor");
				if ( pAtti && pAtti->value() )
				{
					strUpperId = pAtti->value();
				}
				else
				{
					strUpperId = "";
				}
				pNode = pRoom->first_node("id");
				if ( pNode && pNode->value() )
				{
					strId = pNode->value();
				}
				else
				{
					strId = "";
				}
				pNode = pRoom->first_node("name");
				if ( pNode && pNode->value() )
				{
					strName = pNode->value();
				}
				else
				{
					strName = "";
				}
				pNode = pRoom->first_node("type");
				if ( pNode && pNode->value() )
				{
					iType = atoi(pNode->value());
				}
				else
				{
					iType = 0;
				}
				if ( iRooms < maxRooms )
				{
					strcpy(pOutRooms[iRooms].szId,strId.c_str());
					strcpy(pOutRooms[iRooms].szName,strName.c_str());
					strcpy(pOutRooms[iRooms].szFloor,strUpperId.c_str());
					pOutRooms[iRooms].iType = iType;
					//INFO_TRACE("room "<<iRooms<<": id "<<strId<<" floor "<<strUpperId<<" name "<<strName<<" type "<<iType);
					//INFO_TRACE("room "<<iRooms<<": id "<<pOutRooms[iRooms].szId<<" floor "<<pOutRooms[iRooms].szFloor<<" name "<<pOutRooms[iRooms].szName<<" type "<<pOutRooms[iRooms].iType);
					iRooms++;
				}
				else
				{
					WARN_TRACE("too small floor buf");
					break;
				}
			}
			else //错误,不应该有其他节点
			{
			}
		}
	}
	return true;
}

//获取房间信息
int  CEndpointUc::CLIENT_GetLayout(char *pDeviceVCode
									,LPLAYOUT_FLOOR pFloors
									,Int32 maxFloors
									,Int32 *floors
									,LPLAYOUT_ROOM pRooms
									,Int32 maxRooms
									,Int32 *rooms
									,Int32 waittime)	
{
	int iRet = UPCL_NO_ERROR;
	bool bRet = false;

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		iRet = UPCL_ERROR_NOT_REGISTER;
		return iRet;
	}

	std::string strVcode;
	std::string strAuthorization;
	std::string strMethod;
	std::string strUri;

	strVcode = pDeviceVCode;
	strMethod = "POST";
	strUri = "/query/layout";
	strAuthorization = GetAuthInfo(strVcode,strMethod,strUri);

	//发送查询请求
	std::string strTags;
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		iRet = UPCL_ERROR_NO_MORE_RESOURCE;
		return iRet;
	}
	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_POST; //搜索
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,"/query/layout");
	strcpy(pHdr->szAction,ACTION_QUERY_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,pDeviceVCode);
	strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	pHdr->iContentLength = 0;
	if ( strAuthorization.empty() )
	{
		pHdr->iCount = 0;
	}
	else
	{
		pHdr->iCount = 1;
		strcpy(pHdr->hdrs[0].szName,HEADER_NAME_UPNP_AUTHORIZATION);
		strcpy(pHdr->hdrs[0].szValue,strAuthorization.c_str());
	}

	iRet = ZW_SH_SendMessage(GetId(),pHdr,(void*)NULL,0);		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		iRet = UPCL_ERROR_NETWORK;
		return iRet;
	}

	unsigned int uiSeq = GetSeq(strTags);
	TaskItem *pTask = new TaskItem(strTags,GetCurrentTimeMs(),(unsigned int)waittime);
	if ( !pTask )
	{
		ERROR_TRACE("out of memory");
		iRet = UPCL_ERROR_NO_MORE_RESOURCE;
		return iRet;
	}
	pTask->pHdrReq = pHdr;
	AddRequest(uiSeq,pTask);
	pTask->hEvent.Wait(0);
	if ( 1 == pTask->iStatus && 200 == pTask->iStatusCode ) //成功
	{
		//解析内容
		*floors = 0;
		*rooms = 0;
		if ( pTask->strRsp.size() > 0 )
		{
			DeviceData data;
			if ( !ParseLayout((char*)pTask->strRsp.c_str()
							 ,(unsigned int)pTask->strRsp.size()
							 ,pFloors
							 ,maxFloors
							 ,*floors
							 ,pRooms
							 ,maxRooms
							 ,*rooms) )
			{
				ERROR_TRACE("parse rsp failed");
				iRet = UPCL_ERROR_NO_MORE_RESOURCE;
			}
			else
			{
				iRet = UPCL_NO_ERROR;
			}
		}
		else
		{
			iRet = UPCL_NO_ERROR;
		}
	}
	else
	{
		if ( pTask->iStatus == 1 )
		{
			//有回应
			iRet = HttpCode2Error(pTask->iStatusCode);
			ERROR_TRACE("exec failed.err="<<pTask->iStatusCode);
		}
		else
		{
			iRet = UPCL_ERROR_TIMEOUT;
			ERROR_TRACE("exec failed.timeout");
		}
	}

	if ( pTask )
	{
		delete pTask;
	}
	return iRet;
}

// 设备控制
bool  CEndpointUc::CLIENT_Control(char *pDeviceVCode
									 ,char *pControlUrl
									 ,char *pServiceType
									 ,char *pActionName
									 ,LPACTION_PARAM pInParam
									 ,Int32 incount
									 ,LPACTION_PARAM pOutParam
									 ,Int32 maxlen
									 ,Int32 *outcount
									 ,Int32 waittime)
{
	int iRet = 0;
	bool bRet = false;

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		iRet = UPCL_ERROR_NOT_REGISTER;
		return iRet;
	}

	std::string strVcode;
	std::string strAuthorization;
	std::string strMethod;
	std::string strUri;

	strVcode = pDeviceVCode;
	strMethod = "POST";
	strUri = pControlUrl;
	strAuthorization = GetAuthInfo(strVcode,strMethod,strUri);

	std::string strTags;
	char szBody[1024];
	std::string strParams;
	std::string strSoapAction;
	int iBodyLength = 0;
	bool bFirst = true;
	if ( incount > 0 )
	{
		for(int i=0;i<incount;i++)
		{
			if ( bFirst )
			{
				strParams += "\t\t\t<";
				bFirst = false;
			}
			else
			{
				strParams += "\r\n\t\t\t<";
			}
			strParams += pInParam[i].szName;
			strParams += ">";
			strParams += pInParam[i].szValue;
			strParams += "</";
			strParams += pInParam[i].szName;
			strParams += ">";
		}
	}

	sprintf(szBody,ACTION_BODY,pActionName,pServiceType,strParams.c_str(),pActionName);
	iBodyLength = strlen(szBody);

	strSoapAction = "\"";
	strSoapAction += pServiceType;
	strSoapAction += "#";
	strSoapAction += pActionName;
	strSoapAction += "\"";

	//发送查询请求
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)*3];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		iRet = UPCL_ERROR_NO_MORE_RESOURCE;
		return iRet;
	}
	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_POST; //搜索
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,pControlUrl);
	strcpy(pHdr->szAction,ACTION_ACTION_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,pDeviceVCode);
	strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	//SOAPAction
	strcpy(pHdr->hdrs[0].szName,"SOAPAction");
	strcpy(pHdr->hdrs[0].szValue,strSoapAction.c_str());
	//Content-Type
	strcpy(pHdr->hdrs[1].szName,"Content-Type");
	strcpy(pHdr->hdrs[1].szValue,"text/xml");
	//charset
	strcpy(pHdr->hdrs[2].szName,"charset");
	strcpy(pHdr->hdrs[2].szValue,"\"utf-8\"");
	//pHdr->iCount = 3;
	if ( strAuthorization.empty() )
	{
		pHdr->iCount = 3;
	}
	else
	{
		pHdr->iCount = 4;
		strcpy(pHdr->hdrs[3].szName,HEADER_NAME_UPNP_AUTHORIZATION);
		strcpy(pHdr->hdrs[3].szValue,strAuthorization.c_str());
	}

	pHdr->iContentLength = strlen(szBody);

	iRet = ZW_SH_SendMessage(GetId(),pHdr,(void*)szBody,strlen(szBody));		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		iRet = UPCL_ERROR_NETWORK;
		return iRet;
	}

	unsigned int uiSeq = GetSeq(strTags);
	TaskItem *pTask = new TaskItem(strTags,GetCurrentTimeMs(),(unsigned int)waittime);
	if ( !pTask )
	{
		ERROR_TRACE("out of memory");
		iRet = UPCL_ERROR_NO_MORE_RESOURCE;
		return iRet;
	}
	pTask->pHdrReq = pHdr;
	pTask->strReq = szBody;
	AddRequest(uiSeq,pTask);
	pTask->hEvent.Wait(0);
	if ( 1 == pTask->iStatus && 200 == pTask->iStatusCode ) //成功
	{

		//解析内容
		*outcount = 0;
		Int32 count = 0;
		if ( pTask->strRsp.size() > 0 )
		{
			std::vector<NameValue> outArgs;
			std::string strActionRsp = pActionName;
			strActionRsp += "Response";
			if ( !ParseAction((char*)pTask->strRsp.c_str(),pTask->strRsp.size(),(char*)strActionRsp.c_str(),pServiceType,outArgs) )
			{
				ERROR_TRACE("parse rsp failed");
				iRet = UPCL_ERROR_NO_MORE_RESOURCE;
			}
			else
			{
				bRet = true;
				for(size_t i=0;i<outArgs.size();i++,count++)
				{
					if ( count >= maxlen )
					{
						ERROR_TRACE("not enough out args buf");
						iRet = UPCL_ERROR_BUFFER_TOO_SMALL;
						break;
					}
					strcpy(pOutParam[count].szName,outArgs[i].m_strArgumentName.c_str());
					strcpy(pOutParam[count].szValue,outArgs[i].m_strArgumentValue.c_str());
				}
			}

			if ( bRet )
			{
				*outcount = count;
				iRet = UPCL_NO_ERROR;
			}
		}
		else
		{
			iRet = UPCL_NO_ERROR;
		}

	}
	else
	{
		if ( pTask->iStatus == 1 )
		{
			//有回应
			iRet = HttpCode2Error(pTask->iStatusCode);
			ERROR_TRACE("exec failed.err="<<pTask->iStatusCode);
		}
		else
		{
			iRet = UPCL_ERROR_TIMEOUT;
			ERROR_TRACE("exec failed.timeout");
		}
	}

	if ( pTask )
	{
		delete pTask;
	}
	return iRet;
}

	/////////////////////////////
//设备认证
int CEndpointUc::CLIENT_DeviceAuth(char *pszDeviceVcode
								   ,char *pszUser
								   ,char *pszPassword
								   ,char *pszDeviceSn
								   ,Int32 waittime
								   )
{
	int iRet = -1;
	bool bRet = false;

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		iRet = UPCL_ERROR_NOT_REGISTER;
		return iRet;
	}

	std::string strTags;
	std::string strContent;
	
	std::string strVcode;

	strVcode = pszDeviceVcode;

	if ( !Auth_IsExist(strVcode) ) //设备不存在
	{
		ERROR_TRACE("not find in devicelist.vcode="<<strVcode);
		iRet = UPCL_ERROR_NOT_REGISTER;
		return iRet;
	}

	//发送查询请求
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		iRet = UPCL_ERROR_NO_MORE_RESOURCE;
		return iRet;
	}
	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_POST; //POST
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,"/gateway/auth");
	strcpy(pHdr->szAction,ACTION_GATEWAYAUTH_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,pszDeviceVcode);
	strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	pHdr->iCount = 0;
	pHdr->iContentLength = 0;

	iRet = ZW_SH_SendMessage(GetId(),pHdr,NULL,0);		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		iRet = UPCL_ERROR_NETWORK;
		return iRet;
	}

	unsigned int uiSeq = GetSeq(strTags);
	TaskItem *pTask = new TaskItem(strTags,GetCurrentTimeMs(),(unsigned int)waittime);
	if ( !pTask )
	{
		ERROR_TRACE("out of memory");
		if ( pHdr )
		{
			delete pHdr;
		}
		iRet = UPCL_ERROR_NO_MORE_RESOURCE;
		return iRet;
	}
	pTask->pHdrReq = pHdr;

	AddRequest(uiSeq,pTask);
	pTask->hEvent.Wait(0);
	if ( 1 == pTask->iStatus && 200 == pTask->iStatusCode ) //成功
	{
		INFO_TRACE("gateway auth OK.");
		iRet = UPCL_NO_ERROR;
	}
	else
	{
		if ( pTask->iStatus == 1 )
		{
			//有回应
			iRet = HttpCode2Error(pTask->iStatusCode);
			ERROR_TRACE("exec failed.err="<<pTask->iStatusCode);
		}
		else
		{
			iRet = UPCL_ERROR_TIMEOUT;
			ERROR_TRACE("exec failed.timeout");
		}
	}

	if ( pTask )
	{
		delete pTask;
	}

	return iRet;
}

bool ParseChangeId(std::string &strMsg,std::string &strChangeId)
{
	rapidxml::xml_document<> xmlDoc;
	rapidxml::xml_node<> *pRoot;
	rapidxml::xml_node<> *pGateway;
	rapidxml::xml_node<> *pNode;

	try
	{
		xmlDoc.parse<0>((char*)strMsg.c_str());
	}
	catch(...)
	{
		ERROR_TRACE("parse change-id rsp xml failed");
		return false;
	}
	//解析头部
	pRoot = xmlDoc.first_node("Body");

	if ( !pRoot ) //没有
	{
		ERROR_TRACE("not find root node");
		return false;
	}

	pNode = pRoot->first_node("change-id");
	if ( pNode && pNode->value() )
	{
		strChangeId = pNode->value();
		return true;
	}
	else
	{
		ERROR_TRACE("no chage-id node or value is mpty");
		return false;
	}

	return true;
}
//设备配置变更查询
int CEndpointUc::CLIENT_QueryDeviceConfigChange(char *pszDeviceVcode,std::string &strChangeId,Int32 waittime)
{
	int iRet = -1;
	bool bRet = false;

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		iRet = UPCL_ERROR_NOT_REGISTER;
		return iRet;
	}

	std::string strTags;
	std::string strContent;

	//如果需要认证,添加验证信息
	std::string strVcode;
	std::string strAuthorization;

	strVcode = pszDeviceVcode;

	strAuthorization = GetAuthInfo(strVcode,std::string("POST"),std::string("/query/configChange"));

	//发送查询请求
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		iRet = UPCL_ERROR_NO_MORE_RESOURCE;
		return iRet;
	}
	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_POST; //POST
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,"/query/configChange");
	strcpy(pHdr->szAction,ACTION_QUERY_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,pszDeviceVcode);
	strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	if ( strAuthorization.empty() )
	{
		pHdr->iCount = 0;
	}
	else
	{
		pHdr->iCount = 1;
		strcpy(pHdr->hdrs[0].szName,HEADER_NAME_UPNP_AUTHORIZATION);
		strcpy(pHdr->hdrs[0].szValue,strAuthorization.c_str());
	}

	iRet = ZW_SH_SendMessage(GetId(),pHdr,NULL,0);		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		iRet = UPCL_ERROR_NETWORK;
		return iRet;
	}

	unsigned int uiSeq = GetSeq(strTags);
	TaskItem *pTask = new TaskItem(strTags,GetCurrentTimeMs(),(unsigned int)waittime);
	if ( !pTask )
	{
		ERROR_TRACE("out of memory");
		iRet = UPCL_ERROR_NO_MORE_RESOURCE;
		return iRet;
	}
	pTask->pHdrReq = pHdr;
	AddRequest(uiSeq,pTask);
	pTask->hEvent.Wait(0);
	if ( 1 == pTask->iStatus && 200 == pTask->iStatusCode ) //成功
	{
		//解析内容
		if ( pTask->strRsp.size() > 0 )
		{
			if ( !ParseChangeId(pTask->strRsp,strChangeId) )
			{
				ERROR_TRACE("parse rsp failed");
				iRet = UPCL_ERROR_NO_MORE_RESOURCE;
				return iRet;
			}
			else
			{
				iRet = UPCL_NO_ERROR;
			}
			//返回
		}
		else
		{
			iRet = UPCL_NO_ERROR;
		}
	}
	else
	{
		if ( pTask->iStatus == 1 )
		{
			//有回应
			iRet = HttpCode2Error(pTask->iStatusCode);
			ERROR_TRACE("exec failed.err="<<pTask->iStatusCode);
		}
		else
		{
			iRet = UPCL_ERROR_TIMEOUT;
			ERROR_TRACE("exec failed.timeout");
		}
	}

	if ( pTask )
	{
		delete pTask;
	}

	return iRet;
}

//设置用户网关绑定关系信息,设置时清除以前的所有信息,因此必须调用该接口因此设置所有
int CEndpointUc::CLIENT_SetGatewayUserList(LPGATEWAY_USER pUserList,Int32 count)
{
	int iRet = 0;
	bool bRet = true;
	std::string strVcode;
	std::string strSn;
	std::string strUser;
	std::string strPassword;

	Auth_Clear();
	for(int i=0;i<count;i++)
	{
		strVcode = pUserList[i].szVcode;
		strSn = pUserList[i].szSn;
		strUser = pUserList[i].szUser;
		strPassword = pUserList[i].szPassword;
		bRet = Auth_Add(strVcode,strSn,strUser,strPassword);
		if ( !bRet )
		{
			ERROR_TRACE("add gateway user info failed.vcode="<<strVcode<<" device-sn="<<strSn<<" user="<<strUser<<" password="<<strPassword);
			Auth_Clear();
			return -1;
		}
	}
	return 0;
}
	/////////////////////////////

unsigned int CEndpointUc::GetSeq(const std::string &strTags)
{
	unsigned int uiSeq = 0;
	if ( strTags.empty() )
	{
		return uiSeq;
	}
	//char *pSeqS = strTags.c_str();
	size_t pos1 = strTags.find("seq=");
	if ( std::string::npos == pos1 )
	{
		return uiSeq;
	}
	pos1 += 4;
	char szBuf[64] = {0};
	int iIndex = 0;
	for(size_t i=pos1;i<strTags.size();i++)
	{
		if ( strTags[i] != ',' )
		{
			szBuf[iIndex] = strTags[i];
			iIndex++;
			if ( iIndex > 63 ) //太长
			{
				ERROR_TRACE("too long seq");
				return uiSeq;
			}
		}
		else
		{
			break;
		}
	}
	uiSeq = (unsigned int)atoi(szBuf);
	return uiSeq;
}

void CEndpointUc::Process_Task()
{
	CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
	if ( m_reqList.size() <= 0 )
	{
		return ;
	}
	TaskItem *pTask;
	RequestList::iterator it;
	for(it=m_reqList.begin();it!=m_reqList.end();)
	{
		pTask = it->second;
		if ( pTask->IsTimeOut() )
		{

			RequestList::iterator itTemp = it;
			it++;
			m_reqList.erase(itTemp);
			pTask->iStatus = -1;
			pTask->hEvent.Signal();
			if ( it == m_reqList.end() )
			{
				break;
			}
		}
		it++;
	}
	return ;
}

//订阅
int CEndpointUc::Subscrible(const std::string &strUDN
							,const std::string &strServiceType
							,const std::string &strVirtCode
							,const std::string &strEventUrl
							//,const std::string &strHostIp
							//,unsigned short usHostPort
							//,const std::string &strEventUri
							,const std::string &strCallback)
{
	int iRet = 0;
	std::string strEventUri;
	std::string strHostIp;
	unsigned short usHostPort = 0;
	char szBuf[64] = {0};

	INFO_TRACE("subscrible.vcode="<<strVirtCode<<" eventurl="<<strEventUrl<<" CALLBACK="<<strCallback);
	if ( strVirtCode.empty() || strEventUrl.empty() ) //参数检查
	{
		ERROR_TRACE("invalid param.");
		return -1;
	}

	std::string strPath;
	std::string strTimeout;
	std::string strTo;
	//std::string strCallback;
	std::string strTags;

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		return -1;
	}

	GetEventUri(strEventUrl,strHostIp,usHostPort,strEventUri);

	std::string strAuthorization;
	std::string strMethod = "SUBSCRIBLE";
	strAuthorization = GetAuthInfo(strVirtCode,strMethod,strEventUri);

	//发送订阅请求
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)*5];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		return -1;
	}

	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_EX_SUBSCRIBLE; //订阅
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,strEventUri.c_str());
	strcpy(pHdr->szAction,ACTION_SUBSCRIBLE_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,strVirtCode.c_str());
	strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	//Host 订阅主机信息
	strcpy(pHdr->hdrs[0].szName,"Host");
	sprintf(szBuf,"%s:%d",strHostIp.c_str(),usHostPort);
	strcpy(pHdr->hdrs[0].szValue,szBuf);
	//User-Agent 客户端产品信息
	strcpy(pHdr->hdrs[1].szName,"User-Agent");
	strcpy(pHdr->hdrs[1].szValue,"dhzwan upnp 1.0");
	//CALLBACK
	strcpy(pHdr->hdrs[2].szName,"CALLBACK");
	strcpy(pHdr->hdrs[2].szValue,strCallback.c_str());
	//NT
	strcpy(pHdr->hdrs[3].szName,"NT");
	strcpy(pHdr->hdrs[3].szValue,"upnp:event");
	//TIMEOUT
	strcpy(pHdr->hdrs[4].szName,"TIMEOUT");
	strcpy(pHdr->hdrs[4].szValue,"Second-1800");
	if ( strAuthorization.empty() )
	{
		pHdr->iCount = 5;
	}
	else
	{
		pHdr->iCount = 6;
		
		//Upnp-Authorization
		strcpy(pHdr->hdrs[5].szName,HEADER_NAME_UPNP_AUTHORIZATION);
		strcpy(pHdr->hdrs[5].szValue,strAuthorization.c_str());
	}
	pHdr->iContentLength = 0;

	iRet = ZW_SH_SendMessage(GetId(),pHdr,(void*)NULL,0);		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		return -1;
	}
	if ( pHdr )
	{
		delete pHdr;
	}

	//添加到订阅列表
	EventSubscrible *pSubInfo = new EventSubscrible();
	pSubInfo->strCallback = strCallback;
	pSubInfo->strEventUrl = strEventUrl;
	pSubInfo->strUserId = strVirtCode;
	pSubInfo->strTags = strTags;
	//pSubInfo->iStatus = 1;
	pSubInfo->emStatus = EventSubscrible::emSubStatus_Subscribling;
	pSubInfo->strUdn = strUDN;
	pSubInfo->strServiceType = strServiceType;
	//m_vecSubdcrible.push_back(pSubInfo);
	AddSubscrble(pSubInfo);

	return 0;
}

//续订
int CEndpointUc::RenewSubscrible(const std::string &strVirtCode
								,const std::string &strEventUrl
								//,const std::string &strHostIp
								//,unsigned short usHostPort
								//,const std::string &strEventUri
								,const std::string &strSid)
{
	int iRet = 0;
	std::string strEventUri;
	std::string strHostIp;
	unsigned short usHostPort = 0;
	char szBuf[64] = {0};

	INFO_TRACE("renew.vcode="<<strVirtCode<<" eventurl="<<strEventUrl<<" SID="<<strSid);
	if ( strVirtCode.empty() || strEventUrl.empty() ) //参数检查
	{
		ERROR_TRACE("invalid param.");
		return -1;
	}

	std::string strPath;
	std::string strTimeout;
	std::string strTo;
	//std::string strCallback;
	std::string strTags;

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		return -1;
	}

	//发送订阅请求
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)*3];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		return -1;
	}
	GetEventUri(strEventUrl,strHostIp,usHostPort,strEventUri);
	
	std::string strAuthorization;
	std::string strMethod = "SUBSCRIBLE";
	strAuthorization = GetAuthInfo(strVirtCode,strMethod,strEventUri);

	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_EX_SUBSCRIBLE; //订阅
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,strEventUri.c_str());
	strcpy(pHdr->szAction,ACTION_RENEW_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,strVirtCode.c_str());
	strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	//Host 订阅主机信息
	strcpy(pHdr->hdrs[0].szName,"Host");
	sprintf(szBuf,"%s:%d",strHostIp.c_str(),usHostPort);
	strcpy(pHdr->hdrs[0].szValue,szBuf);
	//strcpy(pHdr->hdrs[0].szValue,strHostIp.c_str());
	//strcat(pHdr->hdrs[0].szValue,":");
	//strcat(pHdr->hdrs[0].szValue,atoi(usHostPort));
	//SID
	strcpy(pHdr->hdrs[1].szName,"SID");
	strcpy(pHdr->hdrs[1].szValue,strSid.c_str());
	//TIMEOUT
	strcpy(pHdr->hdrs[2].szName,"TIMEOUT");
	strcpy(pHdr->hdrs[2].szValue,"Second-1800");
	if ( strAuthorization.empty() )
	{
		pHdr->iCount = 3;
	}
	else
	{
		pHdr->iCount = 4;
		
		//Upnp-Authorization
		strcpy(pHdr->hdrs[3].szName,HEADER_NAME_UPNP_AUTHORIZATION);
		strcpy(pHdr->hdrs[3].szValue,strAuthorization.c_str());
	}

	pHdr->iContentLength = 0;

	iRet = ZW_SH_SendMessage(GetId(),pHdr,(void*)NULL,0);		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		return -1;
	}

	//EventSubscrible *pSub = NULL;

	////查找订阅请求
	//for(size_t i=0;i<m_vecSubdcrible.size();i++)
	//{
	//	if ( strSid == m_vecSubdcrible[i]->strSid )
	//	{
	//		pSub = m_vecSubdcrible[i];
	//		pSub->strTags = strTags;
	//		break;
	//	}
	//}
	//
	//if ( !pSub )
	//{
	//	ERROR_TRACE("not find sid for renew");
	//	//return -1;
	//}

	bool bRet = UpdateSubscrble_Tags(strSid,strTags);
	if ( !bRet )
	{
		ERROR_TRACE("not find sid for renew");
		//return -1;
	}

	if ( pHdr )
	{
		delete pHdr;
	}

	return 0;
}
//取消订阅
int CEndpointUc::UnSubscrible(const std::string &strVirtCode
								 ,const std::string &strEventUrl
								 ,const std::string &strSid)
{
	int iRet = 0;
	std::string strEventUri;
	std::string strHostIp;
	unsigned short usHostPort = 0;
	char szBuf[64] = {0};

	INFO_TRACE("unsubscrible.vcode="<<strVirtCode<<" eventurl="<<strEventUrl<<" SID="<<strSid);
	if ( strVirtCode.empty() || strEventUrl.empty() ) //参数检查
	{
		ERROR_TRACE("invalid param.");
		return -1;
	}

	std::string strPath;
	std::string strTo;
	std::string strTags;

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		return -1;
	}

	//发送订阅请求
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)*2];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		return -1;
	}
	GetEventUri(strEventUrl,strHostIp,usHostPort,strEventUri);

	std::string strAuthorization;
	std::string strMethod = "UNSUBSCRIBLE";
	strAuthorization = GetAuthInfo(strVirtCode,strMethod,strEventUri);

	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_EX_UNSUBSCRIBLE; //取消订阅
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,strEventUri.c_str());
	strcpy(pHdr->szAction,ACTION_UNSUBSCRIBLE_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,strVirtCode.c_str());
	strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	//Host 订阅主机信息
	strcpy(pHdr->hdrs[0].szName,"Host");
	sprintf(szBuf,"%s:%d",strHostIp.c_str(),usHostPort);
	strcpy(pHdr->hdrs[0].szValue,szBuf);
	//SID
	strcpy(pHdr->hdrs[1].szName,"SID");
	strcpy(pHdr->hdrs[1].szValue,strSid.c_str());
	if ( strAuthorization.empty() )
	{
		pHdr->iCount = 2;
	}
	else
	{
		pHdr->iCount = 3;
		
		//Upnp-Authorization
		strcpy(pHdr->hdrs[2].szName,HEADER_NAME_UPNP_AUTHORIZATION);
		strcpy(pHdr->hdrs[2].szValue,strAuthorization.c_str());
	}

	pHdr->iContentLength = 0;

	iRet = ZW_SH_SendMessage(GetId(),pHdr,(void*)NULL,0);		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		return -1;
	}

	//EventSubscrible *pSub = NULL;

	////查找订阅请求
	//for(size_t i=0;i<m_vecSubdcrible.size();i++)
	//{
	//	if ( strSid == m_vecSubdcrible[i]->strSid )
	//	{
	//		pSub = m_vecSubdcrible[i];
	//		pSub->strTags = strTags;
	//		break;
	//	}
	//}
	//
	//if ( !pSub )
	//{
	//	ERROR_TRACE("not find sid for unsubscrible");
	//	//return -1;
	//}

	bool bRet = UpdateSubscrble_Tags(strSid,strTags);
	if ( !bRet )
	{
		ERROR_TRACE("not find sid for unsubscrible");
		//return -1;
	}

	if ( pHdr )
	{
		delete pHdr;
	}

	return 0;
}
//取消订阅 不使用锁
int CEndpointUc::UnSubscrible_NoMutex(const std::string &strVirtCode
									  ,const std::string &strEventUrl
									  ,const std::string &strSid)
{
	int iRet = 0;
	std::string strEventUri;
	std::string strHostIp;
	unsigned short usHostPort = 0;
	char szBuf[64] = {0};

	INFO_TRACE("unsubscrible.vcode="<<strVirtCode<<" eventurl="<<strEventUrl<<" SID="<<strSid);
	if ( strVirtCode.empty() || strEventUrl.empty() ) //参数检查
	{
		ERROR_TRACE("invalid param.");
		return -1;
	}

	std::string strPath;
	std::string strTo;
	std::string strTags;

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		return -1;
	}

	//发送订阅请求
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)*2];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		return -1;
	}
	GetEventUri(strEventUrl,strHostIp,usHostPort,strEventUri);

	std::string strAuthorization;
	std::string strMethod = "UNSUBSCRIBLE";
	strAuthorization = GetAuthInfo(strVirtCode,strMethod,strEventUri);

	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_EX_UNSUBSCRIBLE; //取消订阅
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,strEventUri.c_str());
	strcpy(pHdr->szAction,ACTION_UNSUBSCRIBLE_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,strVirtCode.c_str());
	strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	//Host 订阅主机信息
	strcpy(pHdr->hdrs[0].szName,"Host");
	sprintf(szBuf,"%s:%d",strHostIp.c_str(),usHostPort);
	strcpy(pHdr->hdrs[0].szValue,szBuf);
	//SID
	strcpy(pHdr->hdrs[1].szName,"SID");
	strcpy(pHdr->hdrs[1].szValue,strSid.c_str());
	if ( strAuthorization.empty() )
	{
		pHdr->iCount = 2;
	}
	else
	{
		pHdr->iCount = 3;
		
		//Upnp-Authorization
		strcpy(pHdr->hdrs[2].szName,HEADER_NAME_UPNP_AUTHORIZATION);
		strcpy(pHdr->hdrs[2].szValue,strAuthorization.c_str());
	}

	pHdr->iContentLength = 0;

	iRet = ZW_SH_SendMessage(GetId(),pHdr,(void*)NULL,0);		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		return -1;
	}

	EventSubscrible *pSub = NULL;

	//查找订阅请求
	for(size_t i=0;i<m_vecSubdcrible.size();i++)
	{
		if ( strSid == m_vecSubdcrible[i]->strSid )
		{
			pSub = m_vecSubdcrible[i];
			pSub->strTags = strTags;
			break;
		}
	}
	
	if ( !pSub )
	{
		ERROR_TRACE("not find sid for unsubscrible");
		//return -1;
	}

	if ( pHdr )
	{
		delete pHdr;
	}

	return 0;
}

	//////////再次发送请求
//订阅
int CEndpointUc::Subscrible2_Auth(const std::string &strTags,const std::string &strAuthenticate)
{
	int iRet = 0;
	bool bRet;
	EventSubscrible sub;
	std::string strVirtCode;
	std::string strEventUrl;
	std::string strCallback;

	std::string strEventUri;
	std::string strHostIp;
	unsigned short usHostPort = 0;
	char szBuf[64] = {0};

	bRet = GetSubscrble_byTags(strTags,sub);
	if ( !bRet )
	{
		ERROR_TRACE("not find subscrible");
		return -1;
	}

	strVirtCode = sub.strUserId;
	strEventUrl = sub.strEventUrl;
	strCallback = sub.strCallback;
	//int iRet = 0;

	INFO_TRACE("subscrible.vcode="<<strVirtCode<<" eventurl="<<strEventUrl<<" CALLBACK="<<strCallback);
	if ( strVirtCode.empty() || strEventUrl.empty() ) //参数检查
	{
		ERROR_TRACE("invalid param.");
		return -1;
	}

	//std::string strPath;
	//std::string strTimeout;
	//std::string strTo;
	//std::string strCallback;
	//std::string strTags;

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		return -1;
	}

	//发送订阅请求
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)*5];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		return -1;
	}

	GetEventUri(strEventUrl,strHostIp,usHostPort,strEventUri);
	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_EX_SUBSCRIBLE; //订阅
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,strEventUri.c_str());
	strcpy(pHdr->szAction,ACTION_SUBSCRIBLE_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,strVirtCode.c_str());
	//strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	//Host 订阅主机信息
	strcpy(pHdr->hdrs[0].szName,"Host");
	sprintf(szBuf,"%s:%d",strHostIp.c_str(),usHostPort);
	strcpy(pHdr->hdrs[0].szValue,szBuf);
	//User-Agent 客户端产品信息
	strcpy(pHdr->hdrs[1].szName,"User-Agent");
	strcpy(pHdr->hdrs[1].szValue,"dhzwan upnp 1.0");
	//CALLBACK
	strcpy(pHdr->hdrs[2].szName,"CALLBACK");
	strcpy(pHdr->hdrs[2].szValue,strCallback.c_str());
	//NT
	strcpy(pHdr->hdrs[3].szName,"NT");
	strcpy(pHdr->hdrs[3].szValue,"upnp:event");
	//TIMEOUT
	strcpy(pHdr->hdrs[4].szName,"TIMEOUT");
	strcpy(pHdr->hdrs[4].szValue,"Second-1800");
	if ( strAuthenticate.empty() )
	{
		pHdr->iCount = 5;
	}
	else
	{
		std::string strAuthorization;
		std::string strMethod = "SUBSCRIBLE";
		std::string strUri = strEventUri;
		bRet = ProcessAuthReq(strVirtCode,strAuthenticate,strAuthorization,strMethod,strUri);
		if ( !bRet )
		{
			ERROR_TRACE("make auth failed.");
			return -1;
		}
		pHdr->iCount = 6;
		//Upnp-Authorization
		strcpy(pHdr->hdrs[5].szName,HEADER_NAME_UPNP_AUTHORIZATION);
		strcpy(pHdr->hdrs[5].szValue,strAuthorization.c_str());
	}
	pHdr->iContentLength = 0;

	iRet = ZW_SH_SendMessage(GetId(),pHdr,(void*)NULL,0);		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		return -1;
	}
	if ( pHdr )
	{
		delete pHdr;
	}

	return 0;
}
//续订
int CEndpointUc::RenewSubscrible2_Auth(const std::string &strTags,const std::string &strAuthenticate)
{
	int iRet = 0;
	bool bRet;
	EventSubscrible sub;
	std::string strVirtCode;
	std::string strEventUrl;
	//std::string strCallback;
	std::string strSid;
	std::string strEventUri;
	std::string strHostIp;
	unsigned short usHostPort = 0;
	char szBuf[64] = {0};

	bRet = GetSubscrble_byTags(strTags,sub);
	if ( !bRet )
	{
		ERROR_TRACE("not find subscrible");
		return -1;
	}

	strVirtCode = sub.strUserId;
	strEventUrl = sub.strEventUrl;
	//strCallback = sub.strCallback;
	strSid = sub.strSid;

	//int iRet = 0;
	//EventSubscrible *pSub = NULL;
	//pSub = FindSubscrble_byTags(strTags);

	//int iRet = 0;
	//std::string strEventUri;
	//std::string strHostIp;
	//unsigned short usHostPort = 0;
	//char szBuf[64] = {0};

	INFO_TRACE("renew.vcode="<<strVirtCode<<" eventurl="<<strEventUrl<<" SID="<<strSid);
	if ( strVirtCode.empty() || strEventUrl.empty() ) //参数检查
	{
		ERROR_TRACE("invalid param.");
		return -1;
	}

	//std::string strPath;
	//std::string strTimeout;
	//std::string strTo;
	////std::string strCallback;
	//std::string strTags;

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		return -1;
	}

	//发送订阅请求
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)*3];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		return -1;
	}
	GetEventUri(strEventUrl,strHostIp,usHostPort,strEventUri);
	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_EX_SUBSCRIBLE; //订阅
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,strEventUri.c_str());
	strcpy(pHdr->szAction,ACTION_RENEW_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,strVirtCode.c_str());
	//strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	//Host 订阅主机信息
	strcpy(pHdr->hdrs[0].szName,"Host");
	sprintf(szBuf,"%s:%d",strHostIp.c_str(),usHostPort);
	strcpy(pHdr->hdrs[0].szValue,szBuf);
	//strcpy(pHdr->hdrs[0].szValue,strHostIp.c_str());
	//strcat(pHdr->hdrs[0].szValue,":");
	//strcat(pHdr->hdrs[0].szValue,atoi(usHostPort));
	//SID
	strcpy(pHdr->hdrs[1].szName,"SID");
	strcpy(pHdr->hdrs[1].szValue,strSid.c_str());
	//TIMEOUT
	strcpy(pHdr->hdrs[2].szName,"TIMEOUT");
	strcpy(pHdr->hdrs[2].szValue,"Second-1800");
	//pHdr->iCount = 3;
	if ( strAuthenticate.empty() )
	{
		pHdr->iCount = 3;
	}
	else
	{
		std::string strAuthorization;
		std::string strMethod = "SUBSCRIBLE";
		std::string strUri = strEventUri;
		bRet = ProcessAuthReq(strVirtCode,strAuthenticate,strAuthorization,strMethod,strUri);
		if ( !bRet )
		{
			ERROR_TRACE("make auth failed.");
			return -1;
		}
		pHdr->iCount = 4;
		//Upnp-Authorization
		strcpy(pHdr->hdrs[3].szName,HEADER_NAME_UPNP_AUTHORIZATION);
		strcpy(pHdr->hdrs[3].szValue,strAuthorization.c_str());
	}

	pHdr->iContentLength = 0;

	iRet = ZW_SH_SendMessage(GetId(),pHdr,(void*)NULL,0);		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		return -1;
	}

	if ( pHdr )
	{
		delete pHdr;
	}

	return 0;
}
//取消订阅
int CEndpointUc::UnSubscrible2_Auth(const std::string &strTags,const std::string &strAuthenticate)
{
	int iRet = 0;
	bool bRet;
	EventSubscrible sub;
	std::string strVirtCode;
	std::string strEventUrl;
	std::string strSid;
	std::string strEventUri;
	std::string strHostIp;
	unsigned short usHostPort = 0;
	char szBuf[64] = {0};

	bRet = GetSubscrble_byTags(strTags,sub);
	if ( !bRet )
	{
		ERROR_TRACE("not find subscrible");
		return -1;
	}

	strVirtCode = sub.strUserId;
	strEventUrl = sub.strEventUrl;
	strSid = sub.strSid;

	INFO_TRACE("unsubscrible.vcode="<<strVirtCode<<" eventurl="<<strEventUrl<<" SID="<<strSid);
	if ( strVirtCode.empty() || strEventUrl.empty() ) //参数检查
	{
		ERROR_TRACE("invalid param.");
		return -1;
	}

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		return -1;
	}

	//发送订阅请求
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)*1];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		return -1;
	}
	GetEventUri(strEventUrl,strHostIp,usHostPort,strEventUri);
	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_EX_UNSUBSCRIBLE; //取消订阅
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,strEventUri.c_str());
	strcpy(pHdr->szAction,ACTION_UNSUBSCRIBLE_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,strVirtCode.c_str());
	//strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	//Host 订阅主机信息
	strcpy(pHdr->hdrs[0].szName,"Host");
	sprintf(szBuf,"%s:%d",strHostIp.c_str(),usHostPort);
	strcpy(pHdr->hdrs[0].szValue,szBuf);
	//SID
	strcpy(pHdr->hdrs[1].szName,"SID");
	strcpy(pHdr->hdrs[1].szValue,strSid.c_str());
	if ( strAuthenticate.empty() )
	{
		pHdr->iCount = 2;
	}
	else
	{
		std::string strAuthorization;
		std::string strMethod = "UNSUBSCRIBLE";
		std::string strUri = strEventUri;
		bRet = ProcessAuthReq(strVirtCode,strAuthenticate,strAuthorization,strMethod,strUri);
		if ( !bRet )
		{
			ERROR_TRACE("make auth failed.");
			return -1;
		}
		pHdr->iCount = 3;
		//Upnp-Authorization
		strcpy(pHdr->hdrs[2].szName,HEADER_NAME_UPNP_AUTHORIZATION);
		strcpy(pHdr->hdrs[2].szValue,strAuthorization.c_str());
	}

	pHdr->iContentLength = 0;

	iRet = ZW_SH_SendMessage(GetId(),pHdr,(void*)NULL,0);		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		return -1;
	}

	if ( pHdr )
	{
		delete pHdr;
	}

	return 0;
}

//收到订阅回应
int CEndpointUc::OnSubscribleRsp(const std::string &strTo
							   ,const std::string &strTags
							   ,const std::string &strSid
							   ,int iTimeout
							   ,int iResult)
{
	int iRet = 0;
	EventSubscrible *pSub = NULL;

	//查找订阅请求
	//for(size_t i=0;i<m_vecSubdcrible.size();i++)
	//{
	//	if ( strTags == m_vecSubdcrible[i]->strTags )
	//	{
	//		pSub = m_vecSubdcrible[i];
	//		break;
	//	}
	//}
	
	pSub = FindSubscrble_byTags(strTags);

	if ( !pSub )
	{
		ERROR_TRACE("not find subscrible");
		return -1;
	}

	//检查是否有事件存在(同步订阅时存在)
	unsigned uiSeq;
	uiSeq = GetSeq(strTags);
	TaskItem *pTask = FetchRequest(uiSeq);
	//RequestList::iterator it = m_reqList.find(uiSeq);
	if ( !pTask )
	{
		ERROR_TRACE("not find seq. rsp transid="<<uiSeq);			
	}
	//if ( m_reqList.end() == it )
	//{
	//	ERROR_TRACE("not find seq. rsp transid="<<uiSeq);			
	//	//return ;
	//}
	else
	{
		//TaskItem *pTask = (*it).second;
		//m_reqList.erase(uiSeq);
		pTask->iStatus = 1;
		pTask->iStatusCode = iResult;
		//if ( pContent && iContentLength > 0 )
		//{
		//	pTask->strRsp = std::string((char*)pContent,iContentLength);
		//}
		pTask->hEvent.Signal();
	}

	if ( 200 == iResult ) //订阅成功
	{
		//pSub->strSid = strSid;
		//pSub->llLastUpdate = GetCurrentTimeMs();
		//pSub->llLastSend = GetCurrentTimeMs();
		////pSub->iStatus = 2;
		//pSub->emStatus = EventSubscrible::emSubStatus_Subscribled;
		bool bRet = UpdateSubscrble_OK(pSub,strSid);
		if ( bRet )
		{
			INFO_TRACE("event subscrible OK.eventurl="<<pSub->strEventUrl<<" sid="<<strSid);
		}
		else
		{
			ERROR_TRACE("event subscrible failed.eventurl="<<pSub->strEventUrl<<" sid="<<strSid);
		}
		return 0;
	}
	else
	{
		ERROR_TRACE("event subscrible failed.result="<<iResult);
		bool bRet = RemoveSubscrble(pSub);
		//for(size_t i=0;i<m_vecSubdcrible.size();i++)
		//{
		//	if ( pSub == m_vecSubdcrible[i] )
		//	{
		//		m_vecSubdcrible.erase(m_vecSubdcrible.begin()+i);
		//		delete pSub;
		//		break;
		//	}
		//}
		return -1;
	}

	//return iRet;
}

//收到续订回应
int CEndpointUc::OnRenewSubscribleRsp(const std::string &strTo
										 ,const std::string &strTags
										 ,const std::string &strSid
										 ,int iTimeout
										 ,int iResult)
{
	int iRet = 0;
	EventSubscrible *pSub = NULL;

	//查找订阅请求
	//for(size_t i=0;i<m_vecSubdcrible.size();i++)
	//{
	//	if ( strTags == m_vecSubdcrible[i]->strTags )
	//	{
	//		pSub = m_vecSubdcrible[i];
	//		break;
	//	}
	//}
	pSub = FindSubscrble_byTags(strTags);
	if ( !pSub )
	{
		ERROR_TRACE("not find subscrible");
		return -1;
	}

	if ( 200 == iResult ) //续订成功
	{
		//pSub->strSid = strSid;
		bool bRet = UpdateSubscrble_Renew_OK(pSub);
		//pSub->llLastUpdate = GetCurrentTimeMs();
		//pSub->iStatus = 2;
		INFO_TRACE("event renew subscrible OK.eventurl="<<pSub->strEventUrl<<" sid="<<strSid);
		return 0;
	}
	else
	{
		ERROR_TRACE("event renew subscrible failed.result="<<iResult);
		return -1;
	}
}

//收到取消订阅回应
int CEndpointUc::OnCancelSubscribleRsp(const std::string &strTo
										  ,const std::string &strTags
										  ,int iResult)
{
	int iRet = 0;
	EventSubscrible *pSub = NULL;
	size_t i;
	//查找订阅请求
	//for(i=0;i<m_vecSubdcrible.size();i++)
	//{
	//	if ( strTags == m_vecSubdcrible[i]->strTags )
	//	{
	//		pSub = m_vecSubdcrible[i];
	//		break;
	//	}
	//}
	pSub = FindSubscrble_byTags(strTags);
	if ( !pSub )
	{
		ERROR_TRACE("not find subscrible");
		return -1;
	}

	if ( 200 == iResult ) //续订成功
	{
		//pSub->strSid = strSid;
		//pSub->llLastUpdate = GetCurrentTimeMs();
		//pSub->iStatus = 2;
		INFO_TRACE("event cancel subscrible OK.eventurl="<<pSub->strEventUrl<<" sid="<<pSub->strSid);
		//m_vecSubdcrible.erase(m_vecSubdcrible.begin()+i);
		bool bRet = RemoveSubscrble(pSub);
		return 0;
	}
	else
	{
		ERROR_TRACE("event cancel subscrible failed.result="<<iResult);
		//m_vecSubdcrible.erase(m_vecSubdcrible.begin()+i);
		bool bRet = RemoveSubscrble(pSub);
		return -1;
	}
}

int CEndpointUc::SubscribleDevice(const std::string &strVcode,DeviceData &dev)
{
	std::string strCallback;
	char szCallback[256];
	//std::string strEventUri;
	//std::string strHostIp;
	//unsigned short usHostPort;

	//有状态变量需要订阅?直接订阅
	for(size_t i= 0;i<dev.m_vecSericeList.size();i++) //获取服务描述
	{
		if ( !dev.m_vecSericeList[i]->m_strEventSubUrl.empty() )
		{
			sprintf(szCallback,"<http://%s:%d/%s/%s>"
					,m_strEventListenIp.c_str(),m_usEventListenPort
					,dev.m_strUDN.c_str()
					,dev.m_vecSericeList[i]->m_strServiceId.c_str());
			strCallback = szCallback;
			//GetEventUri(dev.m_vecSericeList[i]->m_strEventSubUrl,strHostIp,usHostPort,strEventUri);
			if ( 0 == Subscrible(dev.m_strUDN
								,dev.m_vecSericeList[i]->m_strServiceType
								,strVcode,dev.m_vecSericeList[i]->m_strEventSubUrl
								//,strHostIp
								//,usHostPort
								//,strEventUri
								,strCallback) )
			{
			}
			else
			{
				ERROR_TRACE("subscrible service failed");

			}
		}
	}

	//获取嵌入设备服务描述
	for(size_t i= 0;i<dev.m_vecEmbededDeviceList.size();i++) //获取服务描述
	{
		for(size_t j=0;j<dev.m_vecEmbededDeviceList[i]->m_vecSericeList.size();j++)
		{
			if ( !dev.m_vecEmbededDeviceList[i]->m_vecSericeList[j]->m_strEventSubUrl.empty() )
			{
				sprintf(szCallback,"<http://%s:%d/%s/%s>"
						,m_strEventListenIp.c_str(),m_usEventListenPort
						,dev.m_vecEmbededDeviceList[i]->m_strUDN.c_str()
						,dev.m_vecEmbededDeviceList[i]->m_vecSericeList[j]->m_strServiceId.c_str());
				strCallback = szCallback;
				//GetEventUri(dev.m_vecEmbededDeviceList[i]->m_vecSericeList[j]->m_strEventSubUrl,strHostIp,usHostPort,strEventUri);
				if ( 0 == Subscrible(dev.m_vecEmbededDeviceList[i]->m_strUDN
									,dev.m_vecEmbededDeviceList[i]->m_vecSericeList[j]->m_strServiceType
									,strVcode,dev.m_vecEmbededDeviceList[i]->m_vecSericeList[j]->m_strEventSubUrl
									//,strHostIp
									//,usHostPort
									//,strEventUri
									,strCallback) )
				{
				}
				else
				{
					ERROR_TRACE("subscrible service failed");
				}
			}
		}
	}
	return 0;
}
//取消订阅 指定用户
int CEndpointUc::UnSubscribleAll(const std::string &strVcode)
{
	CMutexGuardT<CMutexThreadRecursive> theLock(m_lockSubList);
	std::vector<EventSubscrible*>::iterator it;
	std::vector<EventSubscrible*>::iterator itTemp;
	EventSubscrible *pSub;
	int i = 0;
	for(it=m_vecSubdcrible.begin();it!=m_vecSubdcrible.end();)
	{
		pSub = *it;
		if (  pSub && pSub->strUserId == strVcode )
		{
			if ( pSub->emStatus == EventSubscrible::emSubStatus_Subscribled ) //已经订阅
			{
				//取消订阅
				/*UnSubscrible*/UnSubscrible_NoMutex(pSub->strUserId,pSub->strEventUrl,pSub->strSid);
			}
			else
			{
			}
			//itTemp = it;
			//it++;
			it = m_vecSubdcrible.erase(it/*itTemp*/);
			delete pSub;
			if ( it == m_vecSubdcrible.end() )
			{
				break;
			}
			//else
			//{
			//	break;
			//}
		}
		else
		{
			it++;
		}
	}

	//清理订阅列表
	for(size_t i=0;i<m_vecSubdcrible.size();i++)
	{
		if ( m_vecSubdcrible[i] )
		{
			delete m_vecSubdcrible[i];
			m_vecSubdcrible[i] = NULL;
		}
	}
	m_vecSubdcrible.clear();
	return 0;
}
//取消订阅
int CEndpointUc::UnSubscribleAll()
{
	CMutexGuardT<CMutexThreadRecursive> theLock(m_lockSubList);
	for(size_t i=0;i<m_vecSubdcrible.size();i++)
	{
		if ( m_vecSubdcrible[i]
			&& m_vecSubdcrible[i]->emStatus == EventSubscrible::emSubStatus_Subscribled ) //已经订阅
		{
			//取消订阅
			/*UnSubscrible*/UnSubscrible_NoMutex(m_vecSubdcrible[i]->strUserId,m_vecSubdcrible[i]->strEventUrl,m_vecSubdcrible[i]->strSid);
		}
	}

	//清理订阅列表
	for(size_t i=0;i<m_vecSubdcrible.size();i++)
	{
		if ( m_vecSubdcrible[i] )
		{
			delete m_vecSubdcrible[i];
			m_vecSubdcrible[i] = NULL;
		}
	}
	m_vecSubdcrible.clear();
	return 0;
}
//清理订阅列表
int CEndpointUc::ClearSubscribler()
{
	CMutexGuardT<CMutexThreadRecursive> theLock(m_lockSubList);
	//清理订阅列表
	for(size_t i=0;i<m_vecSubdcrible.size();i++)
	{
		if ( m_vecSubdcrible[i] )
		{
			delete m_vecSubdcrible[i];
			m_vecSubdcrible[i] = NULL;
		}
	}
	m_vecSubdcrible.clear();
	return 0;
}

//处理订阅信息
int CEndpointUc::ProcessEventSubscrible()
{
	int iRet = -1;
	EventSubscrible *pSub = NULL;
	size_t i;
	long long llCur;

	llCur = GetCurrentTimeMs();
	CMutexGuardT<CMutexThreadRecursive> theLock(m_lockSubList);
	//查找订阅请求
	for(i=0;i<m_vecSubdcrible.size();i++)
	{
		if ( m_vecSubdcrible[i]->emStatus == EventSubscrible::emSubStatus_Subscribled
			&& _abs64(llCur - m_vecSubdcrible[i]->llLastUpdate) > m_vecSubdcrible[i]->ullTimeOut )
		{
			//pSub = m_vecSubdcrible[i];
			//break;
			//超时
			ERROR_TRACE("subscrible timeout.eventUrl="<<m_vecSubdcrible[i]->strEventUrl);
			m_vecSubdcrible[i]->emStatus = EventSubscrible::emSubStatus_Idle;
		}
		else if ( m_vecSubdcrible[i]->emStatus == EventSubscrible::emSubStatus_Subscribled
				&&_abs64(llCur - m_vecSubdcrible[i]->llLastSend) > m_vecSubdcrible[i]->iSendInterval )
		{
			//发送续订请求
			iRet = RenewSubscrible(m_vecSubdcrible[i]->strUserId,m_vecSubdcrible[i]->strEventUrl,m_vecSubdcrible[i]->strSid);
			//更新发送时间
			m_vecSubdcrible[i]->llLastSend = llCur;
		}
	}


	return 0;
}

//收到事件通知
int CEndpointUc::OnEventNotifyReq(const std::string &strTo
									 ,std::string &strTags
									 ,const std::string &strCallback
									 ,std::string &strSid
									 ,unsigned int uiSeq
									 ,std::vector<NameValue> &vecArgs)
{
	INFO_TRACE("event notify");
	return -1;
}
//收到事件回应
int CEndpointUc::OnEventNotifyRsp(const std::string &strTo
									 ,std::string &strTags
									 ,int iResult)
{
	return -1;
}

//查询配置文件版本信息
int CEndpointUc::CLIENT_GetConfigVerion(char *pDeviceVCode
										 ,LPCONFIG_VERSION pVer
										 ,Int32 waittime)
{
	int iRet = -1;
	bool bRet = false;

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		iRet = -1;
		return iRet;
	}

	std::string strTags;
	std::string strContent;

	//body 消息体
	strContent += "<?xml version=\"1.0\"?>\r\n";
	strContent += "<Body>\r\n";
	strContent += "\t<type>\r\n";
	strContent += "1";
	strContent += "\t</type>\r\n";
	strContent += "\t<content>\r\n";
	strContent += pVer->szCfgType;
	strContent += "\t</content>\r\n";
	strContent += "</Body>\r\n";

	//发送查询请求
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		iRet = -1;
		return iRet;
	}
	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_POST; //搜索
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,"/query");
	strcpy(pHdr->szAction,ACTION_QUERY_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,pDeviceVCode);
	strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	pHdr->iCount = 0;
	pHdr->iContentLength = strContent.size();

	iRet = ZW_SH_SendMessage(GetId(),pHdr,(void*)strContent.c_str(),strContent.size());		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		iRet = -1;
		return iRet;
	}
	if ( pHdr )
	{
		delete pHdr;
	}

	unsigned int uiSeq = GetSeq(strTags);
	TaskItem *pTask = new TaskItem(strTags,GetCurrentTimeMs(),(unsigned int)waittime);
	if ( !pTask )
	{
		ERROR_TRACE("out of memory");
		return false;
	}
	AddRequest(uiSeq,pTask);
	//m_reqList[uiSeq] = pTask;
	pTask->hEvent.Wait(0);
	if ( 1 == pTask->iStatus ) //成功
	{
		//解析内容
		if ( pTask->strRsp.size() > 0 )
		{
			if ( !ParseVersionInfo(pTask->strRsp,pVer) )
			{
				ERROR_TRACE("parse rsp failed");
				//return -1;
				bRet = false;
			}
			else
			{
				bRet = true;
			}
			//返回
		}
		else
		{
			bRet = true;
		}
	}
	else
	{
		ERROR_TRACE("exec failed.ret="<<pTask->iStatus);
		bRet = false;
	}

	if ( pTask )
	{
		delete pTask;
	}
	if ( bRet )
	{
		iRet = 0;
		return iRet;
	}
	else
	{
		iRet = -1;
		return iRet;
	}
	//return bRet;
}
bool CEndpointUc::ParseVersionInfo(std::string &strMsg,LPCONFIG_VERSION pVer)
{
	rapidxml::xml_document<> xmlDoc;
	rapidxml::xml_node<> *pRoot;
	rapidxml::xml_node<> *pGateway;
	rapidxml::xml_node<> *pNode;

	xmlDoc.parse<0>((char*)strMsg.c_str());

	//解析头部
	pRoot = xmlDoc.first_node("Body");

	if ( !pRoot ) //没有
	{
		ERROR_TRACE("not find root node");
		return true;
	}

	pNode = pRoot->first_node("content");

	if ( !pNode ) //没有
	{
		ERROR_TRACE("not find content node");
		return true;
	}
	if ( !pNode->value() )
	{
		strcpy(pVer->szCfgVersion,pNode->value());
	}

	return true;
}

//查询配置文件版本信息
int  CEndpointUc::CLIENT_DownloadConfigFile(char *pDeviceVCode
											 ,char *pFileUrl
											 ,char *pszSaveFile
											 ,Int32 waittime)
{
	int iRet = -1;
	bool bRet = false;
	std::string strTags;

	if ( emRegistered != m_emStatus ) //状态不对
	{
		ERROR_TRACE("not registed.status="<<m_emStatus);
		iRet = -1;
		return iRet;
	}

	//发送查询请求
	LPHTTP_HEADER pHdr = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)];
	if ( !pHdr )
	{
		ERROR_TRACE("out of memory");
		iRet = -1;
		return iRet;
	}
	pHdr->iType = HTTP_TYPE_REQUEST; //请求消息
	pHdr->iMethod = HTTP_METHOD_POST; //搜索
	pHdr->iProtocolVer = 2; //HTTP/1.1
	strcpy(pHdr->szPath,pFileUrl);
	strcpy(pHdr->szAction,ACTION_DOWNLOADFILE_REQ);
	strcpy(pHdr->szFrom,m_strVirtualCode.c_str());
	strcpy(pHdr->szTo,pDeviceVCode);
	strTags = MakeTags();
	strcpy(pHdr->szTags,strTags.c_str());
	pHdr->iCount = 0;
	pHdr->iContentLength = 0;

	iRet = ZW_SH_SendMessage(GetId(),pHdr,(void*)NULL,0);		
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		if ( pHdr )
		{
			delete pHdr;
		}
		iRet = -1;
		return iRet;
	}
	if ( pHdr )
	{
		delete pHdr;
	}

	unsigned int uiSeq = GetSeq(strTags);
	TaskItem *pTask = new TaskItem(strTags,GetCurrentTimeMs(),(unsigned int)waittime);
	if ( !pTask )
	{
		ERROR_TRACE("out of memory");
		return false;
	}
	AddRequest(uiSeq,pTask);
	//m_reqList[uiSeq] = pTask;
	pTask->hEvent.Wait(0);
	if ( 1 == pTask->iStatus ) //成功
	{
		//解析内容
		if ( pTask->strRsp.size() > 0 )
		{
			//保存到文件
			bRet = SaveToFile(pszSaveFile,pTask->strRsp.c_str(),pTask->strRsp.size());
			if ( !bRet )
			{
				ERROR_TRACE("save failed");
				//return -1;
				bRet = false;
			}
			else
			{
				bRet = true;
			}
			//返回
		}
		else
		{
			bRet = true;
		}
	}
	else
	{
		ERROR_TRACE("exec failed.ret="<<pTask->iStatus);
		bRet = false;
	}

	if ( pTask )
	{
		delete pTask;
	}
	if ( bRet )
	{
		iRet = 0;
		return iRet;
	}
	else
	{
		iRet = -1;
		return iRet;
	}
}
bool CEndpointUc::SaveToFile(const char  *pszFile,const char *pData,int iSize)
{
	FILE *fp = 0;
	bool bRet = false;

#if defined(_MSC_VER) && (_MSC_VER >= 1400 )
	errno_t err = fopen_s(&fp,pszFile,"wb");
	if ( 0 != err || !fp )
	{
		return false;
	}
#else
	fp = fopen(pszFile,"wb");
	if ( !fp )
	{
		return false;
	}
#endif

	if ( fwrite(pData,1,iSize,fp) != iSize )
	{
		bRet = false;
	}
	else
	{
		bRet = true;
	}
	fclose(fp);
	return bRet;
}

////通用消息
//int CEndpointUc::OnGeneralMsg(HttpMessage &msg,const char *pContent,int iLength)
//{
//	std::string strVcode;
//	std::string strAction;
//	std::string strTags;
//	if ( 1 == msg.iType )
//	{
//		strVcode = msg.GetValueNoCase("To");
//	}
//	else
//	{
//		strVcode = msg.GetValueNoCase("From");
//	}
//	if ( strVcode != m_strVirtualCode )
//	{
//		ERROR_TRACE("not me msg,discard it");
//		return -1;
//	}
//	strAction = msg.GetValueNoCase("NTS");
//	if ( strAction == "queryResponse" ) //查询回应
//	{
//	}
//	else if ( strAction == "downloadFileResponse" ) //下载回应
//	{
//	}
//	else
//	{
//		ERROR_TRACE("unknown action.act="<<strAction);
//		return -1;
//	}
//
//	strTags = msg.GetValueNoCase("Tags");
//
//	//处理数据
//	unsigned uiSeq;
//	uiSeq = GetSeq(strTags);
//
//	RequestList::iterator it = m_reqList.find(uiSeq);
//	if ( m_reqList.end() == it )
//	{
//		ERROR_TRACE("not find seq. rsp transid="<<uiSeq);			
//		return -1;
//	}
//	TaskItem *pTask = (*it).second;
//	m_reqList.erase(uiSeq);
//	pTask->iStatus = 1;
//	pTask->iStatusCode = msg.iStatusCode;
//	pTask->strRsp = std::string(pContent,iLength);
//	pTask->hEvent.Signal();
//	return 0;
//}

int CEndpointUc::ProcessEventNotify(const std::string &strCallback
									,const std::string &strSid
									,unsigned int uiEventId
									,std::string &strContent)
{
	int iRet = 0;
	std::vector<NameValue*> args;
	std::string strEventUrl;
	std::string strUdn; //设备udn
	std::string strServiceType; //服务类型
	LPACTION_PARAM pParam = NULL;
	int iCount = 0;

	if ( !ParseNotifyBody((char*)strContent.c_str(),strContent.size(),args) )
	{
		ERROR_TRACE("parse notify message failed");
		return -1;
	}
	//查找eventurl
	bool bFind = false;
	m_lockSubList.Lock();
	for(size_t i=0;i<m_vecSubdcrible.size();i++)
	{
		if ( m_vecSubdcrible[i]
		&& m_vecSubdcrible[i]->strSid == strSid )
		{
			strEventUrl = m_vecSubdcrible[i]->strEventUrl;
			strUdn = m_vecSubdcrible[i]->strUdn;
			strServiceType = m_vecSubdcrible[i]->strServiceType;
			bFind = true;
		}
	}
	if ( !bFind )
	{
		WARN_TRACE("not find sid.cur sid="<<strSid<<" callback="<<strCallback);
		INFO_TRACE("current subscrible list:");
		for(size_t i=0;i<m_vecSubdcrible.size();i++)
		{
			if ( m_vecSubdcrible[i] )
			{
				INFO_TRACE("suscribler ["<<i<<"] vcode="<<m_vecSubdcrible[i]->strUserId
							<<" eventurl="<<m_vecSubdcrible[i]->strEventUrl
							<<" SID="<<m_vecSubdcrible[i]->strSid
							<<" udn="<<m_vecSubdcrible[i]->strUdn
							<<" serviceType="<<m_vecSubdcrible[i]->strServiceType
							<<" status="<<(int)m_vecSubdcrible[i]->emStatus);
			}
		}

	}
	m_lockSubList.UnLock();

	std::string strParams;
	strParams = "{";
	for(size_t i=0;i<args.size();i++)
	{
		strParams += args[i]->m_strArgumentName;
		strParams += "=";
		strParams += args[i]->m_strArgumentValue;
		strParams += ",";
	}
	if ( strParams[strParams.size()-1] == ',' )
	{
		strParams[strParams.size()-1] = '}';
	}
	else
	{
		strParams += "}";
	}
	INFO_TRACE("recv event notify.callback="<<strCallback<<" udn="
				<<strUdn<<" serviceType="<<strServiceType<<" sid="
				<<strSid<<" evenid="<<uiEventId<< " params : "<<strParams);

	if ( m_cbEventNotify )
	{
		iCount = args.size();
		if ( iCount )
		{
			pParam = new ACTION_PARAM[iCount];
			if ( !pParam )
			{
				ERROR_TRACE("out of memory");
			}
			else
			{
				for(int i=0;i<iCount;i++)
				{
					strcpy(pParam[i].szName,args[i]->m_strArgumentName.c_str());
					strcpy(pParam[i].szValue,args[i]->m_strArgumentValue.c_str());
				}
			}
		}
		m_cbEventNotify(m_uiLoginId,(char*)strUdn.c_str(),(char*)strServiceType.c_str(),(char*)strEventUrl.c_str(),pParam,iCount,m_pEventNotifyUser);
	}
	return iRet;
}

//根据eventurl获取主机和uri
bool CEndpointUc::GetEventUri(const std::string &strEventUrl,std::string &strIp,unsigned short &usPort,std::string &strEventUri)
{
	if ( strEventUrl.size() > 6
		&& 0 == strncasecmp(strEventUrl.c_str(),"HTTP://",7) )
	{
		//完整url,解析
		if ( !SplitHttpUrl(strEventUrl,strIp,usPort,strEventUri) )
		{
			ERROR_TRACE("parse failed");
			return false;
		}
		else
		{
			return true;
		}
	}
	else
	{
		strEventUri = strEventUrl;
		strIp = m_strServIp;
		usPort = m_usServPort;
		return true;
	}
}

std::string CEndpointUc::GetAuthInfo(const std::string &strVcode,std::string strMethod,std::string strUri)
{
	bool bRet;
	std::string strAuth;
	std::string strUser;
	std::string strPassword;
	std::string strScheme;
	std::string strRealm;
	std::string strNonce;
	HttpAuth auth;

	bRet = Auth_Get(strVcode,strUser,strPassword,strScheme,strRealm,strNonce);
	if ( bRet )
	{
		if ( strUser.empty() )
		{
			ERROR_TRACE("not find user.vcode="<<strVcode);
			return strAuth;
		}
		if ( strRealm.empty() || strNonce.empty() )
		{
			INFO_TRACE("no realm or nonce,maybe first request.");
			return strAuth;
		}
		strAuth = CalcAuthMd5(strUser,strPassword,strRealm,strNonce,strMethod,strUri);
		auth.strScheme = "Digest";
		auth.strUsername = strUser;
		auth.strRealm = strRealm;
		auth.strNonce = strNonce;
		auth.strUri = strUri;
		auth.strResponse = strAuth;
		return auth.ToString()/*strAuth*/;
	}
	return std::string("")/*strAuth*/;
}
bool CEndpointUc::ProcessAuthReq(const std::string &strVcode
								 ,const std::string &strAuthenticate
								 ,std::string &strAuthorization
								 ,std::string strMethod
								 ,std::string strUri
								 )
{
	bool bRet = false;
	HttpAuth auth;

	std::string strAuth;
	std::string strUser;
	std::string strPassword;

	bRet = Auth_GetUser(strVcode,strUser,strPassword);
	if ( !bRet )
	{
		ERROR_TRACE("not find user.vcode="<<strVcode);
		return bRet;
	}

	//解析认证内容
	bRet = ParseHttpAuthParams(strAuthenticate,auth);
	if ( !bRet )
	{
		ERROR_TRACE("parse Upnp-Authenticate failed.");
		return bRet;
	}
	if ( auth.strScheme != "Digest" ) //非摘要算法,拒绝
	{
		ERROR_TRACE("auth scheme must be Digest.current scheme="<<auth.strScheme<<".");
		return bRet;
	}
	if ( auth.strRealm.empty() || auth.strNonce.empty() )
	{
		ERROR_TRACE("username realm nonce and response param must exist.");
		return bRet;
	}
	auth.strUsername = strUser;
	auth.strUri = strUri;
	auth.strResponse = CalcAuthMd5(auth.strUsername,strPassword,auth.strRealm,auth.strNonce,strMethod,auth.strUri);
	strAuthorization += auth.ToString();
	
	//更新到列表中去
	Auth_UpdateAuth(strVcode,auth.strScheme,auth.strRealm,auth.strNonce);

	bRet = true;
	return bRet;

}

//收到需要认证回应,处理认证 请求在任务列表里
bool CEndpointUc::ProcessUpnpAuthTaskRsp(LPHTTP_HEADER pHdr,void * pContent,int iContentLength)
{
	bool bRet = true;
	int iRet = 0;
	//处理数据
	unsigned uiSeq;

	uiSeq = GetSeq(std::string(pHdr->szTags));

	TaskItem *pTask = FetchRequest(uiSeq);
	if ( !pTask )
	{
		ERROR_TRACE("not find seq. rsp transid="<<uiSeq);			
		return false;
	}

	//填充认证信息
	std::string strAuthenticate;
	std::string strAuthorization;
	std::string strVcode;

	for(int i=0;i<pHdr->iCount;i++)
	{
		if ( 0 == strncasecmp(pHdr->hdrs[i].szName,HEADER_NAME_UPNP_AUTHENTICATE,strlen(HEADER_NAME_UPNP_AUTHENTICATE)) )
		{
			strAuthenticate = pHdr->hdrs[i].szValue;
			break;
		}
	}
	if ( strAuthenticate.empty() )
	{
		//错误
		pTask->iStatus = -1;
		pTask->iStatusCode = pHdr->iStatusCode;
		if ( pContent && iContentLength > 0 )
		{
			pTask->strRsp = std::string((char*)pContent,iContentLength);
		}
		pTask->hEvent.Signal();
		return false;
	}

	//复制认证信息
	if ( !pTask->pHdrReq )
	{
		//请求内容为空
		pTask->iStatus = -1;
		pTask->iStatusCode = pHdr->iStatusCode;
		if ( pContent && iContentLength > 0 )
		{
			pTask->strRsp = std::string((char*)pContent,iContentLength);
		}
		pTask->hEvent.Signal();
		return false;
	}

	strVcode = pTask->pHdrReq->szTo;
	std::string strMethod;
	std::string strUri;
	if ( pTask->pHdrReq->iMethod == HTTP_METHOD_GET )
	{
		strMethod = "GET";
	}
	else if ( pTask->pHdrReq->iMethod == HTTP_METHOD_POST )
	{
		strMethod = "POST";
	}
	else if ( pTask->pHdrReq->iMethod == HTTP_METHOD_EX_SUBSCRIBLE )
	{
		strMethod = "SUBSCRIBLE";
	}
	else if ( pTask->pHdrReq->iMethod == HTTP_METHOD_EX_UNSUBSCRIBLE )
	{
		strMethod = "UNSUBSCRIBLE";
	}
	else if ( pTask->pHdrReq->iMethod == HTTP_METHOD_POST )
	{
		ERROR_TRACE("Unknown method.method="<<pTask->pHdrReq->iMethod);
		strMethod = "Unknown";
	}
	strUri = pTask->pHdrReq->szPath;
	bRet = ProcessAuthReq(strVcode,strAuthenticate,strAuthorization,strMethod,strUri);
	if ( !bRet )
	{
		pTask->iStatus = -1;
		pTask->iStatusCode = pHdr->iStatusCode;
		if ( pContent && iContentLength > 0 )
		{
			pTask->strRsp = std::string((char*)pContent,iContentLength);
		}
		pTask->hEvent.Signal();
		return false;
	}


	for(int i=0;i<pTask->pHdrReq->iCount;i++)
	{
		if ( 0 == strncasecmp(pTask->pHdrReq->hdrs[i].szName,HEADER_NAME_UPNP_AUTHORIZATION,strlen(HEADER_NAME_UPNP_AUTHORIZATION)) )
		{
			//请求里已经携带认证信息,直接替换,并重发
			strcpy(pTask->pHdrReq->hdrs[i].szValue,strAuthorization.c_str());
			if ( pTask->strReq.empty() )
			{
				iRet = ZW_SH_SendMessage(m_uiLoginId,pTask->pHdrReq,(void*)NULL,0);		
			}
			else
			{
				iRet = ZW_SH_SendMessage(m_uiLoginId,pTask->pHdrReq,(void*)pTask->strReq.c_str(),pTask->strReq.size());		
			}
			if ( 0 != iRet )
			{
				ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
				pTask->iStatus = -1;
				pTask->iStatusCode = pHdr->iStatusCode;
				if ( pContent && iContentLength > 0 )
				{
					pTask->strRsp = std::string((char*)pContent,iContentLength);
				}
				pTask->hEvent.Signal();
				return false;
			}
			else
			{
				AddRequest(uiSeq,pTask);
				return true;
			}

		}
	}

	//上次请求没有携带认证信息
	//发送认证信息
	LPHTTP_HEADER pHdr2 = (LPHTTP_HEADER)new char[sizeof(HTTP_HEADER)+sizeof(NAME_VALUE)*(pTask->pHdrReq->iCount+1)];
	if ( !pHdr2 )
	{
		ERROR_TRACE("out of memory");
		pTask->iStatus = -1;
		pTask->iStatusCode = pHdr->iStatusCode;
		if ( pContent && iContentLength > 0 )
		{
			pTask->strRsp = std::string((char*)pContent,iContentLength);
		}
		pTask->hEvent.Signal();
		return false;
	}

	//头复制
	pHdr2->iType = pTask->pHdrReq->iType;
	pHdr2->iMethod = pTask->pHdrReq->iMethod; //
	pHdr2->iProtocolVer = pTask->pHdrReq->iProtocolVer; //HTTP/1.1
	strcpy(pHdr2->szPath,pTask->pHdrReq->szPath);
	strcpy(pHdr2->szAction,pTask->pHdrReq->szAction);
	strcpy(pHdr2->szFrom,pTask->pHdrReq->szFrom);
	strcpy(pHdr2->szTo,pTask->pHdrReq->szTo);
	strcpy(pHdr2->szTags,pTask->pHdrReq->szTags);
	pHdr2->iContentLength = pTask->pHdrReq->iContentLength;
	pHdr2->iCount = pTask->pHdrReq->iCount+1;
	for(int i=0;i<pTask->pHdrReq->iCount;i++)
	{
		strcpy(pHdr2->hdrs[i].szName,pTask->pHdrReq->hdrs[0].szName);
		strcpy(pHdr2->hdrs[i].szValue,pTask->pHdrReq->hdrs[0].szValue);
	}
	strcpy(pHdr2->hdrs[pTask->pHdrReq->iCount].szName,HEADER_NAME_UPNP_AUTHORIZATION);
	strcpy(pHdr2->hdrs[pTask->pHdrReq->iCount].szValue,strAuthorization.c_str());

	if ( pTask->strReq.empty() )
	{
		iRet = ZW_SH_SendMessage(m_uiLoginId,pHdr2,(void*)NULL,0);		
	}
	else
	{
		iRet = ZW_SH_SendMessage(m_uiLoginId,pHdr2,(void*)pTask->strReq.c_str(),pTask->strReq.size());		
	}
	if ( 0 != iRet )
	{
		ERROR_TRACE("ZW_SH_SendMessage() failed.err="<<iRet);
		pTask->iStatus = -1;
		pTask->iStatusCode = pHdr->iStatusCode;
		if ( pContent && iContentLength > 0 )
		{
			pTask->strRsp = std::string((char*)pContent,iContentLength);
		}
		pTask->hEvent.Signal();
		return false;
	}
	else
	{
		LPHTTP_HEADER pHdrTemp = pTask->pHdrReq;
		pTask->pHdrReq = pHdr2;
		AddRequest(uiSeq,pTask);
		delete pHdrTemp;
		pHdrTemp = NULL;
		return true;
	}

	//返回
	return true;

}

int CEndpointUc::HttpCode2Error(int iStatusCode)
{
	int iRet;
	switch ( iStatusCode )
	{
	case UPNP_STATUS_CODE_REFUSED:			//命令被拒绝
		iRet = UPCL_ERROR_REFUSED;
		break;
	case UPNP_STATUS_CODE_NOT_FOUND:		//找不到对端
		iRet = UPCL_ERROR_NOT_FOUND;
		break;
	case UPNP_STATUS_CODE_OFFINE:			//对端不在线
		iRet = UPCL_ERROR_OFFINE;
		break;
	case UPNP_STATUS_CODE_BUSY:				//忙
		iRet = UPCL_ERROR_REFUSED;
		break;
	case UPNP_STATUS_CODE_BAD_REQUEST:		//命令无效
		iRet = UPCL_ERROR_REFUSED;
		break;
	case UPNP_STATUS_CODE_AUTH_FAILED:		//认证失败
		iRet = UPCL_ERROR_PASSWORD_INVALID;
		break;
	case UPNP_STATUS_CODE_HAVE_REGISTERED:	//已经登录
		iRet = UPCL_ERROR_DUPLICATE_REGISTER;
		break;
	case UPNP_STATUS_CODE_PASSWORD_INVALID:	//密码错误
		iRet = UPCL_ERROR_PASSWORD_INVALID;
		break;
	case UPNP_STATUS_CODE_NOT_REACH:		//对端不可达
		iRet = UPCL_ERROR_NOT_REACH;
		break;
	default:
		iRet = UPCL_ERROR_REFUSED;
		break;
	}
	return iRet;
}