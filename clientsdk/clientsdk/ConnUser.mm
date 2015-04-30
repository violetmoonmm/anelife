#include "ConnUser.h"
#include "Trace.h"
#include "HttpDefines.h"
#include "SdkCommonDefine.h"
#include "MD5Inc.h"

#define DEVICE_TYPE_MODULE_ID			51		//设备端类型
#define CONTROLPOINT_TYPE_MODULE_ID		54		//控制点端类型
#define PROXY_TYPE_MODULE_ID			31		//代理端类型
#define FDMS_TYPE_MODULE_ID				32		//FDMS类型
#define SHBG_TYPE_MODULE_ID				52		//SHBG类型

unsigned int CConnUser::s_uiIdentify = 0; //包标识
unsigned long long CConnUser::s_ullSessionId = 0; //会话标识
unsigned int CConnUser::s_uiUserId = 0; //用户Id


//class CIsSpace
//{
//public:
//	int operator() (const char c)
//	{
//		return c == ' ';
//	}
//};
//
//class CIsQuote
//{
//public:
//	int operator() (const char c)
//	{
//		return c == '\"';
//	}
//};
//
//template<typename IS> 
//void LTrimString(std::string &aTrim, IS aIs)
//{
//	LPCSTR pStart = aTrim.c_str();
//	LPCSTR pMove = pStart;
//
//	for ( ; *pMove; ++pMove)
//	{
//		if (!aIs(*pMove))
//		{
//			if (pMove != pStart)
//			{
//				size_t nLen = strlen(pMove);
//				aTrim.replace(0, nLen, pMove, nLen);
//				aTrim.resize(nLen);
//			}
//			return;
//		}
//	}
//};
//
//template<typename IS> 
//void RTrimString(std::string &aTrim, IS aIs)
//{
//	if (aTrim.empty())
//		return;
//
//	LPCSTR pStart = aTrim.c_str();
//	LPCSTR pEnd = pStart + aTrim.length() - 1;
//	LPCSTR pMove = pEnd;
//
//	for ( ; pMove >= pStart; --pMove)
//	{
//		if (!aIs(*pMove))
//		{
//			if (pMove != pEnd)
//				aTrim.resize(pMove - pStart + 1);
//			return;
//		}
//	}
//};
//
//template<typename IS> 
//void TrimString(std::string &aTrim, IS aIs)
//{
//	LTrimString(aTrim, aIs);
//	RTrimString(aTrim, aIs);
//};

//局部函数
bool ParseAuthParams(const std::string &strAuth,std::string &strMethod,std::vector<NameValue> &params)
{
	bool bRet = false;
	std::string strSchme;
	std::string strName;
	std::string strValue;

	if ( strAuth.empty() )
	{
		return false;
	}
	
	char *pstart = (char*)strAuth.c_str();
	char *pend = (char*)strAuth.c_str()+strAuth.size();
	char *pcur = pstart;
	char *pnode;
	//解析头部
	while( pcur!=pend&&*pcur==' ' ) pcur++;
	if ( pcur == pend )
	{
		return false;
	}
	pnode=pcur;
	while( pcur!=pend&&*pcur!=' ' ) pcur++;
	if ( pcur == pend )
	{
		return false;
	}
	strSchme = std::string(pnode,pcur);
	strMethod = strSchme;
	bool bFinish = false;
	do
	{
		while( pcur!=pend&&*pcur==' ' ) pcur++;
		if ( pcur == pend )
		{
			bFinish = true;
			break;
		}
		pnode=pcur;
		while( pcur!=pend&&*pcur!='=' ) pcur++;
		if ( pcur == pend )
		{
			bFinish = true;
			return false;
			//break;
		}
		strName = std::string(pnode,pcur);
		pcur++;
		pnode=pcur;
		while( pcur!=pend&&*pcur!=',' ) pcur++;
		if ( pcur == pend )
		{
			bFinish = true;
			//return false;
			//break;
			strValue = std::string(pnode,pcur);
			TrimString<CIsSpace>(strValue,CIsSpace());
			if ( strValue.size() > 0 && strValue[0] == '\"' )
			{
				TrimString<CIsQuote>(strValue,CIsQuote());
			}
			params.push_back(NameValue(strName,strValue));
			//return true;
		}
		else
		{
			strValue = std::string(pnode,pcur);
			TrimString<CIsSpace>(strValue,CIsSpace());
			if ( strValue.size() > 0 && strValue[0] == '\"' )
			{
				TrimString<CIsQuote>(strValue,CIsQuote());
			}
			params.push_back(NameValue(strName,strValue));
			pcur++;
		}

	}while(!bFinish);

	return true;
}
////解析Authorization参数
//bool ParseAuthorization(const std::string &strAuthorization
//						,std::string &strRealm
//						,std::string &strRandom
//						,std::string &strResponse)
//{
//	bool bRet;
//	if ( strAuthorization.empty() || 0 != strncasecmp(strAuthorization.c_str(),"Digest ",7) )
//	{
//		return false;
//	}
//	
//	
//}

CConnUser::CConnUser():m_dataSession(this)
{
	m_emStatus = emIdle;

	m_usServPort = 0;

	m_sSock = FCL_INVALID_SOCKET;

	m_pSinker = NULL;

	m_iType = emEpTypeUnknown; //终端类型
	m_bIsClient = true; //当前终端是客户端
	m_uiUserId = MakeUserId();
	m_bAutoReConnect = false; //是否自动重连

	m_iFailedTimes = 0;
	m_llLastTime = 0;
	m_llLastHeartbeatTime = 0;

	m_iHeartBeatInterval = CConnUser::GS_RETRY_INTERVAL;	//心跳间隔
	m_iMaxTimeout = CConnUser::GS_MAX_TIMEOUT;	//保活超时时间

	m_bToBeRemoved = false; //可以删除标记

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
CConnUser::CConnUser(FCL_SOCKET sock):m_sSock(sock)
{
	m_emStatus = emIdle;

	m_usServPort = 0;

	//m_sSock = FCL_INVALID_SOCKET;

	m_pSinker = NULL;

	m_iType = emEpTypeUnknown; //终端类型
	m_bIsClient = true; //当前终端是客户端
	m_uiUserId = MakeUserId();//0/*MakeUserId()*/;
	m_bAutoReConnect = false; //是否自动重连

	m_iFailedTimes = 0;
	m_llLastTime = GetCurrentTimeMs();
	m_llLastHeartbeatTime = 0;

	m_dataSession.SetSocket(sock);
	m_dataSession.SetSinker(this);

	m_iHeartBeatInterval = CConnUser::GS_RETRY_INTERVAL;	//心跳间隔
	m_iMaxTimeout = CConnUser::GS_MAX_TIMEOUT;	//保活超时时间

	m_bToBeRemoved = false; //可以删除标记

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
CConnUser::~CConnUser()
{
	if ( m_sSock != FCL_INVALID_SOCKET )
	{
		FCL_CLOSE_SOCKET(m_sSock);
	}
}
void CConnUser::SetLocalType(int iType)
{
	m_iType = iType;
	if ( m_iType == emEpType_ControlPint )
	{
		m_ucModuleId = CONTROLPOINT_TYPE_MODULE_ID; //control point
		m_strEndpointType = "/Smarthome/cp";

		m_iHeartBeatInterval = CConnUser::GS_RETRY_INTERVAL;	//心跳间隔
		m_iMaxTimeout = CConnUser::GS_MAX_TIMEOUT;	//保活超时时间
	}
	else if ( m_iType == emEpType_Device )
	{
		m_ucModuleId = DEVICE_TYPE_MODULE_ID; //device
		m_strEndpointType = "/Smarthome/fd";
	}
	else if ( m_iType == emEpType_Proxy )
	{
		m_ucModuleId = PROXY_TYPE_MODULE_ID; //proxy
		m_strEndpointType = "/Smarthome/proxy";
	}
	else if ( m_iType == emEpType_Fdms )
	{
		m_ucModuleId = FDMS_TYPE_MODULE_ID; //fdms
		m_strEndpointType = "/Smarthome/fdms";
	}
	else if ( m_iType == emEpType_Shbg )
	{
		m_ucModuleId = SHBG_TYPE_MODULE_ID; //shbg
		m_strEndpointType = "/Smarthome/shbg";
	}
	else
	{
		m_ucModuleId = 0;
	}
}

int CConnUser::OnHttpMsgIn(HttpMessage &msg,const char *pContent,int iContentLength)
{
	std::string strMethod;
	strMethod = msg.GetValueNoCase(HEADER_NAME_ACTION);
	int iMethod;
	iMethod = LookupMethod(strMethod.c_str());
	if ( -1 == iMethod )
	{
		//ERROR_TRACE("not find method");
		INFO_TRACE("recv msg,method="<<strMethod);
	}
	switch ( iMethod )
	{
	case emMethod_RegisterReq:
		{
			return OnRegisterReq(msg,pContent,iContentLength);
			break;
		}
	case emMethod_RegisterRsp:
		{
			return OnRegisterRsp(msg,pContent,iContentLength);
			break;
		}
	case emMethod_KeepaliveReq:
		{
			return OnKeepAliveReq(msg,pContent,iContentLength);
			break;
		}
	case emMethod_KeepaliveRsp:
		{
			return OnKeepAliveRsp(msg,pContent,iContentLength);
			break;
		}
	case emMethod_UnRegisterReq:
		{
			return OnUnRegisterReq(msg,pContent,iContentLength);
			break;
		}
	case emMethod_UnRegisterRsp:
		{
			return OnUnRegisterRsp(msg,pContent,iContentLength);
			break;
		}
	default:
		return OnRecvMsg(msg,pContent,iContentLength);
		break;
	}

	return -1;
}
int CConnUser::OnDisconnect(int iReason)
{
	m_emStatus = emIdle;
	OnDisConnected(emDisRe_Disconnected);
	return 0;
}

unsigned int CConnUser::MakeReqId()
{
	return ++CConnUser::s_uiIdentify;
}
unsigned int CConnUser::MakeUserId()
{
	return ++CConnUser::s_uiUserId;
}
std::string CConnUser::MakeSessionId()
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
std::string CConnUser::MakeTags()
{
	unsigned int uiReqId = MakeReqId();
	std::string strSessionId = MakeSessionId();
	char szBuf[128] = {0};
	sprintf(szBuf,"sessionid=%s,seq=%u",strSessionId.c_str(),uiReqId);
	return std::string(szBuf);
}

std::string CConnUser::LocalIp()
{
	std::string strIp;
	int iRet = 0;
    struct sockaddr_in inet_address;
 #ifdef PLAT_WIN32
   /*socklen_t*/int name_length = sizeof(inet_address);
#else
   socklen_t name_length = sizeof(inet_address);
#endif

	iRet = getsockname(m_sSock,(struct sockaddr*)&inet_address,&name_length);
	if ( FCL_SOCKET_ERROR == iRet )
	{
		ERROR_TRACE("getsocketname() failed.err="<<WSAGetLastError());
	}
	else
	{
		strIp = inet_ntoa(inet_address.sin_addr);
	}
	return strIp;
}

//注册请求
int CConnUser::Register()
{
	int iRet;
	m_llLastTime = GetCurrentTimeMs();
	iRet = Connect();
	if ( 1 == iRet ) //连接完成
	{
		//发送注册请求
	}
	else if ( 0 == iRet ) //正在连接
	{
	}
	else //失败
	{
		ERROR_TRACE("connect failed.err="<<iRet);
		return -1;
	}
	return 0;
}

int CConnUser::UnRegister()
{
	int iRet;
	HttpMessage regMsg;
	regMsg.iType = 1;
	regMsg.iMethod = emMethodRegister;
	regMsg.strPath = m_strEndpointType;
	if ( regMsg.strPath.empty() )
	{
		ERROR_TRACE("unsupport endpoint");
	}
	//if ( emEpType_ControlPint == m_iType ) //UPNP控制点
	//{
	//	regMsg.strPath = "/Smarthome/cp";
	//}
	//else if ( emEpType_Device == m_iType ) //UPNP设备
	//{
	//	regMsg.strPath = "/Smarthome/fd";
	//}
	//else if ( emEpType_Proxy == m_iType ) //PROXY类型终端 可以向其他代理终端注册
	//{
	//	regMsg.strPath = "/Smarthome/proxy";
	//}
	//else if ( emEpType_Fdms == m_iType ) //FDMS类型终端 家庭大网关设备管理服务器
	//{
	//	regMsg.strPath = "/Smarthome/fdms";
	//}
	//else if ( emEpType_Shbg == m_iType ) //SHBG类型终端 家庭大网关设备
	//{
	//	regMsg.strPath = "/Smarthome/shbg";
	//}
	//else //不支持的客户端类型 
	//{
	//	ERROR_TRACE("unsupport endpoint");
	//}
	regMsg.iContentLength = 0;
	regMsg.SetValue(HEADER_NAME_FROM,m_strVcodeLocal);
	regMsg.SetValue(HEADER_NAME_TO,m_strVcodePeer);
	regMsg.SetValue(HEADER_NAME_TAGS,MakeTags());
	//if ( emEpType_Device == m_iType ) //UPNP设备
	//{
	//	regMsg.SetValue(std::string("USN"),m_strUuid);
	//	regMsg.SetValue(std::string("Location"),m_strLocation);
	//}
	regMsg.SetValue(HEADER_NAME_ACTION,ACTION_UNREGISTER_REQ);

	std::string strMsg = regMsg.ToHttpheader();

	//发送注册请求消息
	iRet = m_dataSession.SendData((char*)strMsg.c_str(),(int)strMsg.size());
	if ( 0 <= iRet )
	{
		//m_emStatus = emRegistering; //正在注册
		return 0;
	}
	else
	{
		//m_emStatus = emIdle;
		ERROR_TRACE("send data failed");
		return -1;
	}
	return -1;
}

int CConnUser::SendMessage(HttpMessage &msg,const char *pContent,int iContentLength)
{
	int iRet;
	std::string strMsg = msg.ToHttpheader();
	if ( pContent && iContentLength > 0 )
	{
		std::string strContent(pContent,iContentLength);
		strMsg += strContent;
	}
	//发送注册请求消息
	iRet = m_dataSession.SendData((char*)strMsg.c_str(),(int)strMsg.size());
	if ( 0 <= iRet )
	{
		if ( 2 == msg.iType
			&& msg.GetValueNoCase(HEADER_NAME_ACTION) == ACTION_REGISTER_RSP
			&& msg.iStatusCode == 200
			)
		{
			//注册成功
			m_emStatus = emRegistered;
		}
		return 0;
	}
	else
	{
		ERROR_TRACE("send data failed");
		return -1;
	}
}
int CConnUser::Connect()
{
	fd_set fds;
	timeval tv;
	int iTotal;
	int iRet;

	//FCL_SOCKET sock = FCL_INVALID_SOCKET;
	//iError = DCN_NO_ERROR;

	if ( m_sSock != FCL_INVALID_SOCKET )
	{
		//shuntdown(
		FCL_CLOSE_SOCKET(m_sSock);
	}

	m_sSock = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
	if( FCL_INVALID_SOCKET == m_sSock )
	{
		ERROR_TRACE("create socket failed,errno="<<WSAGetLastError());
		//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
		//iError = DCN_ERROR_SOCKET;
		return -1;
	}	

	int iBlock = 1;
#ifdef PLAT_WIN32
	iRet = ::ioctlsocket(m_sSock,FIONBIO,(u_long FAR *)&iBlock);
	if ( SOCKET_ERROR == iRet ) 
	{
		ERROR_TRACE("set socket opt failed,errno="<<WSAGetLastError());
		//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
		FCL_CLOSE_SOCKET(m_sSock);
		//iError = DCN_ERROR_SOCKET;
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
			//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
			FCL_CLOSE_SOCKET(m_sSock);
			//iError = DCN_ERROR_SOCKET;
			return -1;
		}
	}
#endif

	sockaddr_in servAddr;
	servAddr.sin_family = AF_INET;
	servAddr.sin_addr.s_addr = inet_addr(m_strServIp.c_str());
	servAddr.sin_port = htons(m_usServPort);
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
		//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
		//DC_CLOSE_SOCKET(sock);
		//iError = DCN_ERROR_SOCKET;
		m_emStatus = emConnected;
		return 1;
	}

	return 0;
}

//收到连接请求
int CConnUser::OnConnect(int iResult)
{
	if ( 0 == iResult ) //连接成功
	{
		INFO_TRACE("connect ok");
		m_emStatus = emConnected;
		m_dataSession.SetSocket(m_sSock);
	}
	else
	{
		ERROR_TRACE("connect failed");
		m_emStatus = emIdle;

	}
	return 0;
}

//发送注册请求
int CConnUser::RegisterReq()
{
	int iRet;
	HttpMessage regMsg;
	regMsg.iType = 1;
	regMsg.iMethod = emMethodRegister;
	regMsg.strPath = m_strEndpointType;
	if ( regMsg.strPath.empty() )
	{
		ERROR_TRACE("unsupport endpoint");
	}
	//if ( emEpType_ControlPint == m_iType ) //UPNP控制点
	//{
	//	regMsg.strPath = "/Smarthome/cp";
	//}
	//else if ( emEpType_Device == m_iType ) //UPNP设备
	//{
	//	regMsg.strPath = "/Smarthome/fd";
	//}
	//else if ( emEpType_Proxy == m_iType ) //PROXY类型终端 可以向其他代理终端注册
	//{
	//	regMsg.strPath = "/Smarthome/proxy";
	//}
	//else if ( emEpType_Fdms == m_iType ) //FDMS类型终端 家庭大网关设备管理服务器
	//{
	//	regMsg.strPath = "/Smarthome/fdms";
	//}
	//else if ( emEpType_Shbg == m_iType ) //SHBG类型终端 家庭大网关设备
	//{
	//	regMsg.strPath = "/Smarthome/shbg";
	//}
	//else //不支持的客户端类型 
	//{
	//	ERROR_TRACE("unsupport endpoint");
	//}
	regMsg.iContentLength = 0;
	regMsg.SetValue(HEADER_NAME_FROM,m_strVcodeLocal);
	regMsg.SetValue(HEADER_NAME_TO,m_strVcodePeer);
	regMsg.SetValue(HEADER_NAME_TAGS,MakeTags());
	if ( emEpType_Device == m_iType ) //UPNP设备
	{
		regMsg.SetValue(std::string("USN"),m_strUuid);
		regMsg.SetValue(std::string("Location"),m_strLocation);
	}
	regMsg.SetValue(HEADER_NAME_ACTION,ACTION_REGISTER_REQ);

	std::string strMsg = regMsg.ToHttpheader();

	//发送注册请求消息
	iRet = m_dataSession.SendData((char*)strMsg.c_str(),(int)strMsg.size());
	if ( 0 <= iRet )
	{
		m_emStatus = emRegistering; //正在注册
		return 0;
	}
	else
	{
		m_emStatus = emIdle;
		ERROR_TRACE("send data failed");
		return -1;
	}
}
//发送注册请求
int CConnUser::RegisterReq(const std::string &strAuth)
{
	int iRet;
	HttpMessage regMsg;
	regMsg.iType = 1;
	regMsg.iMethod = emMethodRegister;
	regMsg.strPath = m_strEndpointType;
	if ( regMsg.strPath.empty() )
	{
		ERROR_TRACE("unsupport endpoint");
	}
	//if ( emEpType_ControlPint == m_iType ) //UPNP控制点
	//{
	//	regMsg.strPath = "/Smarthome/cp";
	//}
	//else if ( emEpType_Device == m_iType ) //UPNP设备
	//{
	//	regMsg.strPath = "/Smarthome/fd";
	//}
	//else if ( emEpType_Proxy == m_iType ) //PROXY类型终端 可以向其他代理终端注册
	//{
	//	regMsg.strPath = "/Smarthome/proxy";
	//}
	//else //不支持的客户端类型 
	//{
	//	ERROR_TRACE("unsupport endpoint");
	//}
	regMsg.iContentLength = 0;
	regMsg.SetValue(HEADER_NAME_FROM,m_strVcodeLocal);
	regMsg.SetValue(HEADER_NAME_TO,m_strVcodePeer);
	regMsg.SetValue(HEADER_NAME_TAGS,MakeTags());
	if ( emEpType_Device == m_iType ) //UPNP设备
	{
		regMsg.SetValue(std::string("USN"),m_strUuid);
		regMsg.SetValue(std::string("Location"),m_strLocation);
	}
	regMsg.SetValue(HEADER_NAME_ACTION,ACTION_REGISTER_REQ);
	regMsg.SetValue("Authorization",strAuth);

	std::string strMsg = regMsg.ToHttpheader();

	//发送注册请求消息
	iRet = m_dataSession.SendData((char*)strMsg.c_str(),(int)strMsg.size());
	if ( 0 <= iRet )
	{
		m_emStatus = emRegistering; //正在注册
		return 0;
	}
	else
	{
		m_emStatus = emIdle;
		ERROR_TRACE("send data failed");
		return -1;
	}
}
//收到注册请求
int CConnUser::OnRegisterReq(HttpMessage &msg,const char *pContent,int iContentLength)
{
	//如果本端是客户端,不应该接收到本消息
	if ( m_bIsClient )
	{
		ERROR_TRACE("client cannot accept register request");
		return -1;
	}


	int iResult = -1;
	std::string strFrom;
	std::string strTo;
	std::string strTags;
	std::string strLocation;
	std::string strUsn;
	int iPeerType = -1;

	strFrom = msg.GetValueNoCase(HEADER_NAME_FROM);
	strTo = msg.GetValueNoCase(HEADER_NAME_TO);
	strTags = msg.GetValueNoCase(HEADER_NAME_TAGS);
	strLocation = msg.GetValueNoCase("Location");
	strUsn = msg.GetValueNoCase("USN");

	if ( strTo == m_strVcodeLocal ) //是注册到本代理
	{
	}
	else if ( strTo.empty() )
	{
		if ( strTo.empty() )
		{
			ERROR_TRACE("empty server vcode. local="<<m_strVcodeLocal);
		}
		else
		{
			ERROR_TRACE("server vcode not same.server vcode="<<strTo<<" local vcode="<<m_strVcodeLocal);
		}
		int iRet;
		HttpMessage rspMsg;
		rspMsg.iType = 2;
		rspMsg.iStatusCode = UPNP_STATUS_CODE_REFUSED;

		rspMsg.iContentLength = 0;
		rspMsg.SetValue(HEADER_NAME_FROM,msg.GetValueNoCase(HEADER_NAME_FROM));
		rspMsg.SetValue(HEADER_NAME_TO,msg.GetValueNoCase(HEADER_NAME_TO));
		rspMsg.SetValue(HEADER_NAME_TAGS,msg.GetValueNoCase(HEADER_NAME_TAGS));
		rspMsg.SetValue(HEADER_NAME_ACTION,ACTION_REGISTER_RSP);

		iRet = SendMessage(rspMsg,NULL,0);
		//通知连接被拒绝
		OnRegisterFailed(emDisRe_RegistedRefused);

		return -1;
	}
	//else
	//{
	//	ERROR_TRACE("server vcode not same.server vcode="<<strTo<<" local vcode="<<m_strVcodeLocal);
	//	return -1;
	//}

	//{

		m_strVcodePeer = strFrom;
		//m_strUuid = strUsn;
		//m_strLocation = strLocation;
		if ( msg.strPath == "/Smarthome/cp" ) //uc 端
		{
			iPeerType = emEpType_ControlPint;
			m_iPeerType = emEpType_ControlPint;
		}
		else if ( msg.strPath == "/Smarthome/fd" ) //device 端
		{
			iPeerType = emEpType_Device;
			m_iPeerType = emEpType_Device;
		}
		else if ( msg.strPath == "/Smarthome/proxy" ) //proxy 端
		{
			iPeerType = emEpType_Proxy;
			m_iPeerType = emEpType_Proxy;
		}
		else if ( msg.strPath == "/Smarthome/fdms" ) //fdms 端
		{
			iPeerType = emEpType_Fdms;
			m_iPeerType = emEpType_Fdms;
		}
		else if ( msg.strPath == "/Smarthome/shbg" ) //shbg 端
		{
			iPeerType = emEpType_Shbg;
			m_iPeerType = emEpType_Shbg;
		}
		else
		{
			ERROR_TRACE("unknown peer path");
			int iRet;
			HttpMessage rspMsg;
			rspMsg.iType = 2;
			rspMsg.iStatusCode = UPNP_STATUS_CODE_REFUSED;

			rspMsg.iContentLength = 0;
			rspMsg.SetValue(HEADER_NAME_FROM,msg.GetValueNoCase(HEADER_NAME_FROM));
			rspMsg.SetValue(HEADER_NAME_TO,msg.GetValueNoCase(HEADER_NAME_TO));
			rspMsg.SetValue(HEADER_NAME_TAGS,msg.GetValueNoCase(HEADER_NAME_TAGS));
			rspMsg.SetValue(HEADER_NAME_ACTION,ACTION_REGISTER_RSP);

			iRet = SendMessage(rspMsg,NULL,0);
			//通知连接被拒绝
			OnRegisterFailed(emDisRe_RegistedRefused);
			return -1;
		}
	//}
	//else //不是注册到本地
	//{
	//	ERROR_TRACE("not register to me,proxy redirect is not support now,discard it.");
	//	return -1;
	//}
	//通知上层有注册请求 由上层验证和决定是否接受注册
	if ( m_uiUserId == 0 )
	{
		m_uiUserId = MakeUserId();
	}

	//if ( m_pSinker )
	//{
	//	m_pSinker->OnMessage(this,msg,pContent,iContentLength);
	//}
	//return 0;

	if ( m_strRealm.empty() )
	{
		std::string strRandom;
		std::string strRealm = m_strVcodeLocal;
		strRandom = MakeNonce();

		std::string strPassword;
		int iResult;
		if ( m_pSinker )
		{
			m_pSinker->OnLogin(this,m_iPeerType,m_strVcodePeer,strPassword,iResult);
		}
		else
		{
			//放弃
			ERROR_TRACE("no callback to process,discard");
			return -1;
		}
		if( 0 == iResult ) //不用验证,直接接收注册
		{
			//发送注册回应	
			int iRet;
			HttpMessage rspMsg;
			rspMsg.iType = 2;
			rspMsg.iStatusCode = 200;

			rspMsg.iContentLength = 0;
			rspMsg.SetValue(HEADER_NAME_FROM,msg.GetValueNoCase(HEADER_NAME_FROM));
			rspMsg.SetValue(HEADER_NAME_TO,msg.GetValueNoCase(HEADER_NAME_TO));
			rspMsg.SetValue(HEADER_NAME_TAGS,msg.GetValueNoCase(HEADER_NAME_TAGS));
			rspMsg.SetValue(HEADER_NAME_ACTION,ACTION_REGISTER_RSP);

			iRet = SendMessage(rspMsg,NULL,0);	
			OnRegisterSuccess(emDisRe_None);
			if ( m_iPeerType = emEpType_ControlPint )
			{
				m_iHeartBeatInterval = CConnUser::GS_RETRY_INTERVAL;	//心跳间隔
				m_iMaxTimeout = CConnUser::GS_MAX_TIMEOUT;	//保活超时时间
			}
			m_llLastTime = GetCurrentTimeMs();
		}
		else if ( 1 == iResult )
		{
			//发送需要验证回应
			int iRet;
			HttpMessage rspMsg;
			rspMsg.iType = 2;
			rspMsg.iStatusCode = 401;
			std::string strChallenge;

			rspMsg.iContentLength = 0;
			rspMsg.SetValue(HEADER_NAME_FROM,msg.GetValueNoCase(HEADER_NAME_FROM));
			rspMsg.SetValue(HEADER_NAME_TO,msg.GetValueNoCase(HEADER_NAME_TO));
			rspMsg.SetValue(HEADER_NAME_TAGS,msg.GetValueNoCase(HEADER_NAME_TAGS));
			rspMsg.SetValue(HEADER_NAME_ACTION,ACTION_REGISTER_RSP);

			HttpAuth auth;
			
			auth.bIsResponse = false;
			auth.strScheme = "Basic";
			auth.strRealm = strRealm;
			strChallenge = auth.ToString();

			rspMsg.SetValue("WWW-Authenticate",strChallenge);

			m_strPassword = strPassword;
			m_strRealm = strRealm;
			m_strRandom = strRandom;

			iRet = SendMessage(rspMsg,NULL,0);
		}
		else //直接拒绝
		{
			int iRet;
			HttpMessage rspMsg;
			rspMsg.iType = 2;
			if ( -1 == iResult ) //查找不到用户
			{
				rspMsg.iStatusCode = UPNP_STATUS_CODE_NOT_FOUND;
			}
			else if ( -2 == iResult ) //查找不到用户密码
			{
				rspMsg.iStatusCode = UPNP_STATUS_CODE_PASSWORD_INVALID;
			}
			else
			{
				rspMsg.iStatusCode = 400;
			}

			rspMsg.iContentLength = 0;
			rspMsg.SetValue(HEADER_NAME_FROM,msg.GetValueNoCase(HEADER_NAME_FROM));
			rspMsg.SetValue(HEADER_NAME_TO,msg.GetValueNoCase(HEADER_NAME_TO));
			rspMsg.SetValue(HEADER_NAME_TAGS,msg.GetValueNoCase(HEADER_NAME_TAGS));
			rspMsg.SetValue(HEADER_NAME_ACTION,ACTION_REGISTER_RSP);

			iRet = SendMessage(rspMsg,NULL,0);
			//通知连接被拒绝
			OnRegisterFailed(emDisRe_RegistedRefused);
		}
	}
	else
	{
		std::string strAuthorization;
		std::string strMd5Password;
		bool bRet = false;

		HttpAuth auth;

		strAuthorization = msg.GetValueNoCase("Authorization");
		if ( strAuthorization.empty() )
		{
			//认证内容不存在
			ERROR_TRACE("no Authorization find,discard.");
			return -1;
		}
		//解析认证信息
		do
		{
			bRet = ParseHttpAuthParams(strAuthorization,auth,true);
			if ( !bRet )
			{
				ERROR_TRACE("parse Authorization failed.");
				//return -1;
				break;
			}
			if ( auth.strScheme != "Basic" && auth.strScheme != "Digest" ) //非基本或摘要算法,拒绝
			{
				ERROR_TRACE("auth scheme must be Basic or Digest.current scheme="<<auth.strScheme<<".");
				//return -1;
				break;
			}
			if ( auth.strScheme == "Basic" )
			{
				if ( auth.strResponse.empty() )
				{
					ERROR_TRACE("Authorization some field is empty");
					//return -1;
					break;
				}

				//验证内容
				strMd5Password = CalcBasic(m_strVcodePeer,m_strPassword);
			}
			else if ( auth.strScheme != "Digest" )
			{
				if ( auth.strNonce != m_strRandom ) //随机种子不同,重新请求
				{
					ERROR_TRACE("nonce not same,retry next.from nonce="<<auth.strNonce<<" my nonce="<<m_strRandom);
					break;
				}
				if ( auth.strUsername.empty() || auth.strRealm.empty() || auth.strNonce.empty() || auth.strUri.empty() || auth.strResponse.empty() )
				{
					ERROR_TRACE("Authorization some field is empty");
					//return -1;
					break;
				}
				if ( auth.strUsername != m_strVcodePeer || auth.strRealm != m_strRealm/* || auth.strNonce != m_strRandom*/ )
				{
					ERROR_TRACE("username realm param must same with pre alloc.alloc realm="<<m_strRealm<<" ");
					break;
					//return -1;
				}
				strMd5Password = CalcAuthMd5(auth.strUsername,m_strPassword,auth.strRealm,auth.strNonce,std::string("POST"),auth.strUri);
				if ( strMd5Password != auth.strResponse ) //失败
				{
					ERROR_TRACE("password invlid.password="<<m_strRealm<<".");
					break;
				}
			}
		}
		while ( 0 );

		//if ( strMd5Password != auth.strResponse ) //失败
		if ( !bRet ) //失败
		{
			ERROR_TRACE("password invlid="<<m_strRealm<<" ");
			int iRet;
			HttpMessage rspMsg;
			rspMsg.iType = 2;
			rspMsg.iStatusCode = UPNP_STATUS_CODE_AUTH_FAILED;//400;
			std::string strChallenge;

			rspMsg.iContentLength = 0;
			rspMsg.SetValue(HEADER_NAME_FROM,msg.GetValueNoCase(HEADER_NAME_FROM));
			rspMsg.SetValue(HEADER_NAME_TO,msg.GetValueNoCase(HEADER_NAME_TO));
			rspMsg.SetValue(HEADER_NAME_TAGS,msg.GetValueNoCase(HEADER_NAME_TAGS));
			rspMsg.SetValue(HEADER_NAME_ACTION,ACTION_REGISTER_RSP);

			iRet = SendMessage(rspMsg,NULL,0);
			return -1;

		}
		else
		{
			//登录成功
			//发送注册回应	
			int iRet;
			HttpMessage rspMsg;
			rspMsg.iType = 2;
			rspMsg.iStatusCode = 200;

			rspMsg.iContentLength = 0;
			rspMsg.SetValue(HEADER_NAME_FROM,msg.GetValueNoCase(HEADER_NAME_FROM));
			rspMsg.SetValue(HEADER_NAME_TO,msg.GetValueNoCase(HEADER_NAME_TO));
			rspMsg.SetValue(HEADER_NAME_TAGS,msg.GetValueNoCase(HEADER_NAME_TAGS));
			rspMsg.SetValue(HEADER_NAME_ACTION,ACTION_REGISTER_RSP);

			iRet = SendMessage(rspMsg,NULL,0);	
			OnRegisterSuccess(emDisRe_None);
			if ( m_iPeerType = emEpType_ControlPint )
			{
				m_iHeartBeatInterval = CConnUser::GS_RETRY_INTERVAL;	//心跳间隔
				m_iMaxTimeout = CConnUser::GS_MAX_TIMEOUT;	//保活超时时间
			}
			m_llLastTime = GetCurrentTimeMs();
		}
	}
	//if ( m_pSinker )
	//{
	//	m_pSinker->OnLogin(this,msg,pContent,iContentLength);
	//}
	return -1;
}
//发送注册回应
int CConnUser::RegisterRsp()
{
	//如果本端是客户端,不应该接收到本消息
	if ( m_bIsClient )
	{
		ERROR_TRACE("client cannot accept register request");
		return -1;
	}

	return -1;
}
//收到注册回应
int CConnUser::OnRegisterRsp(HttpMessage &msg,const char *pContent,int iContentLength)
{
	int iStatus;

	//如果本端是服务端,不应该接收到本消息
	if ( !m_bIsClient )
	{
		ERROR_TRACE("server cannot accept register request");
		return -1;
	}

	iStatus = msg.iStatusCode;

	if ( 200 == iStatus ) //登录成功
	{
		INFO_TRACE("login OK");
		m_iFailedTimes = 0;
		m_emStatus = emRegistered;
		m_llLastTime = GetCurrentTimeMs();
		m_llLastHeartbeatTime = GetCurrentTimeMs();
		OnRegisterSuccess(emDisRe_None);
	}
	else //失败
	{
		if ( 401 == iStatus ) //需要密码验证
		{

			std::string strWWWAuthenticate;
			std::string strAuthorization;
			bool bRet = false;
			HttpAuth auth;
			int iRet;

			strWWWAuthenticate = msg.GetValueNoCase("WWW-Authenticate");
			if ( strWWWAuthenticate.empty() )
			{
				//认证内容不存在
				ERROR_TRACE("no WWW-Authenticate find,discard.");
				m_emStatus = emIdle;
				OnRegisterFailed(emDisRe_RegistedRefused);
				return 0;
			}

			//解析认证内容
			bRet = ParseHttpAuthParams(strWWWAuthenticate,auth);
			if ( !bRet )
			{
				ERROR_TRACE("parse WWW-Authenticate failed.");
				m_emStatus = emIdle;
				OnRegisterFailed(emDisRe_RegistedRefused);
				return 0;
			}
			if ( auth.strScheme == "Basic" ) //基本
			{
				if ( auth.strRealm.empty() )
				{
					ERROR_TRACE("realm param must exist.");
					m_emStatus = emIdle;
					OnRegisterFailed(emDisRe_RegistedRefused);
					return 0;
				}
				auth.bIsResponse = true;
				auth.strResponse = CalcBasic(m_strVcodeLocal,m_strPassword);
				strAuthorization += auth.ToString();
				m_strRealm = auth.strRealm;
				m_strRandom = auth.strNonce;

				iRet = RegisterReq(strAuthorization);
				return 0;
			}
			else if ( auth.strScheme == "Digest" ) //摘要算法
			{
				if ( auth.strRealm.empty() || auth.strNonce.empty() )
				{
					ERROR_TRACE("username realm nonce and response param must exist.");
					m_emStatus = emIdle;
					OnRegisterFailed(emDisRe_RegistedRefused);
					return 0;
				}
				auth.strUsername = m_strVcodeLocal;
				auth.strUri = m_strEndpointType;//msg.strPath;
				auth.strResponse = CalcAuthMd5(auth.strUsername,m_strPassword,auth.strRealm,auth.strNonce,std::string("POST"),auth.strUri);
				strAuthorization += auth.ToString();
				m_strRealm = auth.strRealm;
				m_strRandom = auth.strNonce;

				iRet = RegisterReq(strAuthorization);
				return 0;
			}
			//if ( auth.strScheme != "Digest" ) //既非基本也非摘要算法,拒绝
			else
			{
				ERROR_TRACE("auth scheme must be Digest.current scheme="<<auth.strScheme<<".");
				m_emStatus = emIdle;
				OnRegisterFailed(emDisRe_RegistedRefused);
				return 0;
			}
		
			if ( auth.strRealm.empty() || auth.strNonce.empty() )
			{
				ERROR_TRACE("username realm nonce and response param must exist.");
				m_emStatus = emIdle;
				OnRegisterFailed(emDisRe_RegistedRefused);
				return 0;
			}

			//return 0;
		}
		else
		{
			ERROR_TRACE("login failed.server refused.code="<<iStatus);
			m_emStatus = emIdle;
			if ( iStatus == UPNP_STATUS_CODE_REFUSED )
			{
				OnRegisterFailed(emDisRe_RegistedRefused);
			}
			else if ( iStatus == UPNP_STATUS_CODE_AUTH_FAILED )
			{
				OnRegisterFailed(emDisRe_PasswordInvalid);
			}
			else if ( iStatus == UPNP_STATUS_CODE_PASSWORD_INVALID )
			{
				OnRegisterFailed(emDisRe_PasswordInvalid);
			}
			else
			{
				OnRegisterFailed(emDisRe_RegistedRefused);
			}
			return 0;
		}
	}
	//if ( m_pSessionSinker )
	//{
	//	m_pSessionSinker->OnRegisterResult(m_strVcodeLocal,m_strVcodePeer,iStatus);
	//}

	return 0;
	//判断注册结果
	//return -1;
}
//保活请求
int CConnUser::KeepAliveReq()
{
	int iRet;
	HttpMessage regMsg;
	regMsg.iType = 1;
	regMsg.iMethod = emMethodRegister;
	regMsg.strPath = m_strEndpointType;
	if ( regMsg.strPath.empty() )
	{
		ERROR_TRACE("unsupport endpoint");
	}
	regMsg.iContentLength = 0;
	regMsg.SetValue(HEADER_NAME_FROM,m_strVcodeLocal);
	regMsg.SetValue(HEADER_NAME_TO,m_strVcodePeer);
	regMsg.SetValue(HEADER_NAME_TAGS,MakeTags());
	regMsg.SetValue(HEADER_NAME_ACTION,ACTION_KEEPALIVE_REQ);
	if ( m_iType == emEpType_ControlPint && !m_strPassword.empty() )
	{
		regMsg.SetValue(HEADER_NAME_VERIFY_CODE,m_strPassword);
	}

	std::string strMsg = regMsg.ToHttpheader();
	//发送保活请求消息
	iRet = m_dataSession.SendData((char*)strMsg.c_str(),(int)strMsg.size());
	if ( 0 <= iRet )
	{
		return 0;
	}
	else
	{
		ERROR_TRACE("send data failed");
		return -1;
	}
}
//收到保活请求
int CConnUser::OnKeepAliveReq(HttpMessage &msg,const char *pContent,int iContentLength)
{
	//如果本端是客户端,不应该接收到本消息
	if ( m_bIsClient )
	{
		ERROR_TRACE("client cannot accept register request");
		return -1;
	}

	//修改状态
	m_iFailedTimes = 0;
	m_llLastTime = GetCurrentTimeMs();

	//发送保活回应
	int iRet;
	HttpMessage rspMsg;
	rspMsg.iType = 2;
	
	rspMsg.iStatusCode = 200;

	rspMsg.iContentLength = 0;
	rspMsg.SetValue(HEADER_NAME_FROM,m_strVcodeLocal);
	rspMsg.SetValue(HEADER_NAME_TO,m_strVcodePeer);
	rspMsg.SetValue(HEADER_NAME_TAGS,msg.GetValueNoCase(HEADER_NAME_TAGS));
	rspMsg.SetValue(HEADER_NAME_ACTION,ACTION_KEEPALIVE_RSP);

	std::string strMsg = rspMsg.ToHttpheader();
	iRet = m_dataSession.SendData((char*)strMsg.c_str(),(int)strMsg.size());
	if ( 0 <= iRet )
	{
		return 0;
	}
	else
	{
		ERROR_TRACE("send data failed");
		return -1;
	}
}
//保活回应
int CConnUser::KeepAliveRsp()
{
	ERROR_TRACE("not implement method");
	return -1;
}
//收到保活回应
int CConnUser::OnKeepAliveRsp(HttpMessage &msg,const char *pContent,int iContentLength)
{
	int iStatus;

	//如果本端不是客户端,不应该接收到本消息
	if ( !m_bIsClient )
	{
		ERROR_TRACE("client cannot accept register request");
		return -1;
	}

	iStatus = msg.iStatusCode;

	if ( 200 == iStatus ) //保活成功
	{
		//INFO_TRACE("keepalive OK");
		//m_iStatus = 2;
	}
	else //失败
	{
		ERROR_TRACE("keepalive failed.");
		//m_iStatus = 0;
	}
	m_iFailedTimes = 0;
	m_llLastTime = GetCurrentTimeMs();

	return 0;
}

//收到登出请求
int CConnUser::OnUnRegisterReq(HttpMessage &msg,const char *pContent,int iContentLength)
{
	//如果本端是客户端,不应该接收到本消息
	if ( m_bIsClient )
	{
		ERROR_TRACE("client cannot accept unregister request");
		return -1;
	}

	//修改状态
	//m_iFailedTimes = 0;
	//m_llLastTime = GetCurrentTimeMs();

	//发送保活回应
	int iRet;
	HttpMessage rspMsg;
	rspMsg.iType = 2;
	
	rspMsg.iStatusCode = 200;

	rspMsg.iContentLength = 0;
	rspMsg.SetValue(HEADER_NAME_FROM,m_strVcodePeer);
	rspMsg.SetValue(HEADER_NAME_TO,m_strVcodeLocal);
	rspMsg.SetValue(HEADER_NAME_TAGS,msg.GetValueNoCase(HEADER_NAME_TAGS));
	rspMsg.SetValue(HEADER_NAME_ACTION,ACTION_UNREGISTER_RSP);

	std::string strMsg = rspMsg.ToHttpheader();
	iRet = m_dataSession.SendData((char*)strMsg.c_str(),(int)strMsg.size());
	if ( 0 <= iRet )
	{
		//return 0;
	}
	else
	{
		ERROR_TRACE("send data failed");
		return -1;
	}

	//断开连接
	m_emStatus = emUnRegistered;
	//通知登出
	OnDisConnected(emDisRe_UnRegistered);

	return 0;
}
//收到登出回应
int CConnUser::OnUnRegisterRsp(HttpMessage &msg,const char *pContent,int iContentLength)
{
	//如果本端是客户端,不应该接收到本消息
	if ( !m_bIsClient )
	{
		ERROR_TRACE("server cannot accept unregister response");
		return -1;
	}

	//修改状态
	//m_iFailedTimes = 0;
	//m_llLastTime = GetCurrentTimeMs();


	//断开连接
	m_emStatus = emUnRegistered;

	//通知登出
	OnDisConnected(emDisRe_UnRegistered);

	return 0;
}

//int CConnUser::PollSessionData()

int CConnUser::OnDataIn()
{
	return m_dataSession.OnDataIn();
}
int CConnUser::OnDataOut()
{
	return m_dataSession.OnDataOut();
}
int CConnUser::Process_Data()
{
	int iRet;
	iRet = m_dataSession.Process_Data();
	return iRet;
}
int CConnUser::Process()
{
	int iRet;
	if ( m_bIsClient ) //客户端
	{
		iRet = Process_Client();
	}
	else //服务端
	{
		iRet = Process_Server();
	}

	return iRet;
}
int CConnUser::Release()
{
	return -1;
}

int CConnUser::Process_Client()
{
	//检查定时器
	long long llCur = GetCurrentTimeMs();
	int iRet;

	switch ( m_emStatus )
	{
	case emIdle: //空闲状态
		{
			//m_llLastTime = GetCurrentTimeMs();

			if ( m_bAutoReConnect ) //断线自动重连
			{
				if ( _abs64(m_llLastTime-GetCurrentTimeMs()) > CConnUser::GS_RETRY_INTERVAL )
				{
					iRet = Connect();
					if ( 0 > iRet ) //失败
					{
						ERROR_TRACE("connect failed");
						m_llLastTime = GetCurrentTimeMs();
						m_emStatus = emIdle;
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
			if ( _abs64(m_llLastTime-GetCurrentTimeMs()) > CConnUser::GS_RETRY_INTERVAL )
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
			//注册			
			iRet = RegisterReq();
			if ( 0 == iRet )
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
			if ( _abs64(m_llLastTime-GetCurrentTimeMs()) > CConnUser::GS_RETRY_INTERVAL )
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
			if ( _abs64(m_llLastHeartbeatTime/*m_llLastTime*/-GetCurrentTimeMs()) > m_iHeartBeatInterval/*CConnUser::GS_RETRY_INTERVAL*/ )
			{
				//m_iFailedTimes++;
				//if ( m_iFailedTimes >= 3 ) //超过保活次数
				if ( _abs64(m_llLastTime-GetCurrentTimeMs()) > m_iMaxTimeout )
				{
					//回调上层,保活失败
					ERROR_TRACE("keepalive timeout.peer="<<m_strVcodePeer);
					m_emStatus = emIdle;
					OnDisConnected(emDisRe_Keepalivetimeout);
				}
				else //发送保活请求
				{
					//m_llLastTime = llCur;
					m_llLastHeartbeatTime = llCur;
					KeepAliveReq();
				}
			}
			break;
		}
	case emUnRegistering:
		{
			break;
		}
	case emUnRegistered:
		{
			break;
		}
	default:
		WARN_TRACE("unknown status");
		break;
	}

	return 0;
}
int CConnUser::Process_Server()
{
	//检查定时器
	long long llCur = GetCurrentTimeMs();
	int iRet;

	switch ( m_emStatus )
	{
	case emIdle: //空闲状态
		{
			if ( _abs64(m_llLastTime-GetCurrentTimeMs()) > CConnUser::GS_RETRY_INTERVAL )
			{
				ERROR_TRACE("connect failed");
				m_llLastTime = GetCurrentTimeMs();
				m_emStatus = emIdle;
				OnDisConnected(emDisRe_ConnectFailed);
				return 1;
			}

			break;
		}
	case emConnecting:
		{
			ERROR_TRACE("no impl.server should not  occur");
			break;
		}
	case emConnected:
		{
			ERROR_TRACE("no impl.server should not  occur");
			break;
		}
	case emRegistering:
		{
			if ( _abs64(m_llLastTime-GetCurrentTimeMs()) > CConnUser::GS_RETRY_INTERVAL )
			{
				ERROR_TRACE("register timeout");
				m_llLastTime = GetCurrentTimeMs();
				m_emStatus = emIdle;
				OnDisConnected(emDisRe_RegistedTimeout);
				return 1;
			}
			break;
		}
	case emRegistered:
		{
			if ( _abs64(m_llLastTime-GetCurrentTimeMs()) > m_iMaxTimeout/*CConnUser::GS_RETRY_INTERVAL*/ )
			{
				//m_iFailedTimes++;
				//if ( m_iFailedTimes >= 3 ) //超过保活次数
				//{
					//回调上层,保活失败
					ERROR_TRACE("keepalive timeout.peer="<<m_strVcodePeer);
					m_emStatus = emIdle;
					OnDisConnected(emDisRe_Keepalivetimeout);
					return 1;
				//}
				//else //发送保活请求
				//{
				//	m_llLastTime = llCur;
				//}
			}
			break;
		}
	case emUnRegistering:
		{
			break;
		}
	case emUnRegistered:
		{
			break;
		}
	default:
		WARN_TRACE("unknown status");
		break;
	}

	return 0;
}

//void CConnUser::DisConnect(int iReason)
//{
//	FCL_CLOSE_SOCKET(m_sSock);
//	if ( m_pSinker )
//	{
//		m_pSinker->OnDisconnect(this,iReason);
//	}
//}

void CConnUser::OnDisConnected(int iReason)
{
	FCL_CLOSE_SOCKET(m_sSock);
	if ( m_pSinker )
	{
		m_pSinker->OnStatusChange(this,IConnUserSinker::emConnctionDisconnected,iReason);
	}
}
void CConnUser::OnRegisterSuccess(int iReason)
{
	if ( m_pSinker )
	{
		m_pSinker->OnStatusChange(this,IConnUserSinker::emRegisterSuccess,0);
	}
}
void CConnUser::OnRegisterFailed(int iReason)
{
	FCL_CLOSE_SOCKET(m_sSock);
	if ( m_pSinker )
	{
		m_pSinker->OnStatusChange(this,IConnUserSinker::emRegisterFailed,iReason);
	}
}

//收到普通消息
int CConnUser::OnRecvMsg(HttpMessage &msg,const char *pContent,int iContentLength)
{
	//通知上层消息请求

	if ( m_pSinker )
	{
		m_pSinker->OnMessage(this,msg,pContent,iContentLength);
	}
	return -1;
}