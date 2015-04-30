#ifndef EndpointUc_h
#define EndpointUc_h

#include <string>
#include <vector>
#include <map>

#include "Platform.h"
#include "CommonDefine.h"
//#include "HttpDataSession.h"
//#include "ShSession.h"
#include "MuteX.h"
#include "clientsdk.h"
#include "SdkCommonDefine.h"

class CEndpointUc

{
public:
	CEndpointUc();
	virtual ~CEndpointUc();

	//用户认证信息
	class HttpAuthInfo
	{
	public:
		//虚号和序列号必须存在且唯一,即每个虚号和设备序列号必须一一对应
		std::string strVcode;		//设备虚号 
		std::string strSn;			//设备序列号
		std::string strUser;		//用户名
		std::string	strPassword;	//密码

		/////////缓存上次认证信息,如果短时间室内需要多次动作,可以使用相同的认证种子,以减小交互开销/////////
		long long llLast;			//上次认证时间,为0时表示还未进行过认证
		std::string strScheme;		//模式,必须为摘要模式 Digest
		std::string strRealm;		//服务端资源保护域,当前对于网关采用域@网关sn模式,比如获取设备列表为config@12345678,其中config为查询设备列表所属保护域,12345678为设备sn
		std::string strNonce;		//随机数
		/////////缓存上次认证信息,如果短时间室内需要多次动作,可以使用相同的认证种子,以减小交互开销/////////
	};


	//订阅信息
	class EventSubscrible
	{
	public:

		enum EmSubscribleStatus
		{
			emSubStatus_Idle,			//初始状态
			emSubStatus_Subscribling,   //正在订阅
			emSubStatus_Subscribled,	//已经订阅
		};

		EventSubscrible()
		{
			llLastUpdate = 0;
			ullTimeOut = 30*60*1000; //30分钟
			llLastSend = 0;
			iSendInterval = 20*60*1000; //10分钟发一次续订
			//iStatus = 0;
			emStatus = emSubStatus_Idle;
		}
		EventSubscrible(const EventSubscrible &a)
		{
			strEventUrl		= a.strEventUrl;
			strCallback		= a.strCallback;  //回调路径
			strSid			= a.strSid;       //SID
			strUserId		= a.strUserId;    //虚号
			strTags			= a.strTags;      //请求标识
			llLastUpdate	= a.llLastUpdate;
			ullTimeOut		= a.ullTimeOut;
			llLastSend		= a.llLastSend;
			iSendInterval	= a.iSendInterval;
			emStatus		= a.emStatus;
			strUdn			= a.strUdn; //设备udn
			strServiceType	= a.strServiceType; //服务类型
		}
		EventSubscrible & operator=(const EventSubscrible &a)
		{
			if ( this == &a )
			{
				return *this;
			}
			strEventUrl		= a.strEventUrl;
			strCallback		= a.strCallback;  //回调路径
			strSid			= a.strSid;       //SID
			strUserId		= a.strUserId;    //虚号
			strTags			= a.strTags;      //请求标识
			llLastUpdate	= a.llLastUpdate;
			ullTimeOut		= a.ullTimeOut;
			llLastSend		= a.llLastSend;
			iSendInterval	= a.iSendInterval;
			emStatus		= a.emStatus;
			strUdn			= a.strUdn; //设备udn
			strServiceType	= a.strServiceType; //服务类型
			return *this;
		}
		~EventSubscrible()
		{
		}

		std::string strEventUrl;  //订阅路径
		std::string strCallback;  //回调路径
		std::string strSid;       //SID
		std::string strUserId;    //虚号
		std::string strTags;      //请求标识
		unsigned long long llLastUpdate;
		unsigned long long ullTimeOut;
		unsigned long long llLastSend;
		int iSendInterval;
		//int iStatus;           //状态 0 初始 1 订阅请求中 2 订阅成功
		EmSubscribleStatus emStatus;
		std::string strUdn; //设备udn
		std::string strServiceType; //服务类型
	};

	class TaskItem
	{
	public:
		TaskItem()
		{
			m_llStart = 0;
			m_uiTimeout = 5000;
			iStatus = 0;
			pHdrReq = NULL;
		}
		TaskItem(const std::string &tags,long long llBegin,unsigned int uiTimeout=5000)
		{
			m_llStart = llBegin;
			m_uiTimeout = uiTimeout;
			m_strTags = tags;
			iStatus = 0;
			pHdrReq = NULL;
		}

		~TaskItem()
		{
			if ( pHdrReq )
			{
				delete pHdrReq;
				pHdrReq = NULL;
			}
		}

		std::string & Tags()
		{
			return m_strTags;
		}
		bool IsTimeOut()
		{
			return ( _abs64(GetCurrentTimeMs()-m_llStart) >= m_uiTimeout ) ? true : false;
		}
	//private:
		long long m_llStart; //任务发起时间
		unsigned int m_uiTimeout; //超时时间
		std::string m_strTags; //任务标记
		int iTaskType;
		int iStatus;
		int iStatusCode;
		std::string strRsp;
		CEventThread hEvent;

		//请求信息 缓冲请求数据,用来在安全认证时再次发送使用
		LPHTTP_HEADER pHdrReq;	//请求头
		std::string strReq;		//请求内容
	};

	enum EmStatus
	{
		emIdle,
		//emConnecting,
		//emConnected,
		emRegistering,
		emRegistered
	};

	static CEndpointUc * Instance();

	int Start();
	int Stop();
	void UnInit();

	int SearchDevice(const std::string &strDevCcode);

	int GetDeviceList(const std::string &strDevCcode,const std::string &strLocation);

	int Action(const std::string &strDevice,const std::string &strControlUrl,const std::string &strServiceType,
		       const std::string &strActionName,const std::vector<NameValue> &inArgs,
			   std::vector<NameValue> &outArgs);


	//订阅
	int Subscrible(const std::string &strUDN,const std::string &strServiceType,const std::string &strVirtCode,const std::string &strEventUrl,const std::string &strCallback);
	//int Subscrible(const std::string &strUDN,const std::string &strServiceType,const std::string &strVirtCode,const std::string &strEventUrl,const std::string &strHostIp,unsigned short usHostPort,const std::string &strEventUri,const std::string &strCallback);
	//续订
	int RenewSubscrible(const std::string &strVirtCode,const std::string &strEventUrl,const std::string &strSid);
	//取消订阅
	int UnSubscrible(const std::string &strVirtCode,const std::string &strEventUrl,const std::string &strSid);
	//取消订阅
	int UnSubscrible_NoMutex(const std::string &strVirtCode,const std::string &strEventUrl,const std::string &strSid);
	
	//////////再次发送请求
	//订阅
	int Subscrible2_Auth(const std::string &strTags,const std::string &strAuthenticate);
	//续订
	int RenewSubscrible2_Auth(const std::string &strTags,const std::string &strAuthenticate);
	//取消订阅
	int UnSubscrible2_Auth(const std::string &strTags,const std::string &strAuthenticate);



	//int StartHttpServer();

	//启动
	int StartTaskThread();
	//结束
	int StopTaskThread();

	void Process_Task();

	void SetDisConnectCb(fOnDisConnect cbDisConnect,void *pUser)
	{
		m_cbDisConnect = cbDisConnect;
		m_pUser = pUser;
	}

	//事件通知回调
	void SetEventNotifyCb(bool bEnableEvent,fOnEventNotify cbEventNotify,void *pUser)
	{
		m_bNeedSubscrible = bEnableEvent;
		m_cbEventNotify = cbEventNotify;
		m_pEventNotifyUser = pUser;
	}

	void SetParam(char *pServIp,unsigned short usPort,char *pServVirtCode,char *pVirtCode,char *pPassword)
	{
		m_strServIp = pServIp;
		m_usServPort = usPort;
		m_strServVirtualcode = pServVirtCode;
		m_strVirtualCode = pVirtCode;
		m_strPassword = pPassword;
	}

	void SetAutoReconnect(bool bAuto)
	{
		m_bAutoReConnect = bAuto;
	}

	unsigned int GetId()
	{
		return m_uiLoginId;
	}

	//登录
	int Login();

	int CLIENT_Login(char *pchServIP,UInt16 wServPort,char *pchServVirtcode,char *pchVirtCode,char *pchPassword);
	int CLIENT_Logout();

	//获取网关列表
	bool CLIENT_QueryGatewayList(LPUPNP_GATEWAY pUpnpGateway,Int32 maxlen,Int32 *devicecount,Int32 waittime);
	bool ParseGatewayList(std::string &strMsg,LPUPNP_GATEWAY pUpnpGateway,Int32 maxlen,Int32 &cout);

	//获取设备列表
	int  CLIENT_GetDeviceList(char *pDeviceUdn,char *pDeviceLocation,LPUPNP_DEVICE pUpnpDevice,Int32 maxlen,Int32 *devicecount,Int32 waittime);
	//获取设备列表
	int  CLIENT_GetDeviceList(char *pDeviceUdn,char *pDeviceLocation,std::string &strDeviceList,Int32 waittime);
	
	//获取房间信息
	int  CLIENT_GetLayout(char *pDeviceVCode
							,LPLAYOUT_FLOOR pFloors
							,Int32 maxFloors
							,Int32 *floors
							,LPLAYOUT_ROOM pRooms
							,Int32 maxRooms
							,Int32 *rooms
							,Int32 waittime);	
	// 设备控制
	bool  CLIENT_Control(char *pDeviceVCode,char *pControlUrl,char *pServiceType,char *pActionName,LPACTION_PARAM pInParam,Int32 incount,LPACTION_PARAM pOutParam,Int32 maxlen,Int32 *outcount,Int32 waittime);

	//批量订阅服务
	int CLIENT_Subscrible_Batch(LPSUBSCRIBLE_INFO pSubList,int iCount,int iTimeout);
	
	// 查询配置文件版本信息
	int CLIENT_GetConfigVerion(char *pDeviceVCode,LPCONFIG_VERSION pVer,Int32 waittime);
	bool ParseVersionInfo(std::string &strMsg,LPCONFIG_VERSION pVer);

	// 查询配置文件版本信息
	int  CLIENT_DownloadConfigFile(char *pDeviceVCode,char *pFileUrl,char *pszSaveFile,Int32 waittime);
	bool SaveToFile(const char  *pszFile,const char *pData,int iSize);
	
	
	/////////////////////////////
	//设备认证
	int CLIENT_DeviceAuth(char *pszDeviceVcode,char *pszUser,char *pszPassword,char *pszDeviceSn,Int32 waittime);
	//设备配置变更查询
	int CLIENT_QueryDeviceConfigChange(char *pszDeviceVcode,std::string &strChangeId,Int32 waittime);
	//设置用户网关绑定关系信息,设置时清除以前的所有信息,因此必须调用该接口因此设置所有
	int CLIENT_SetGatewayUserList(LPGATEWAY_USER pUserList,Int32 count);
	/////////////////////////////
	
	int SearchDevice_Sync(const std::string &strDevCcode);

	void Task_Process(void);

	//收到订阅回应
	virtual int OnSubscribleRsp(const std::string &strTo,const std::string &strTags,const std::string &strSid,int iTimeout,int iResult);

	//收到续订回应
	virtual int OnRenewSubscribleRsp(const std::string &strTo,const std::string &strTags,const std::string &strSid,int iTimeout,int iResult);

	//收到取消订阅回应
	virtual int OnCancelSubscribleRsp(const std::string &strTo,const std::string &strTags,int iResult);

	//收到事件通知
	virtual int OnEventNotifyReq(const std::string &strTo,std::string &strTags,const std::string &strCallback,std::string &strSid,unsigned int uiSeq,std::vector<NameValue> &vecArgs);
	//收到事件回应
	virtual int OnEventNotifyRsp(const std::string &strTo,std::string &strTags,int iResult);

	int ProcessEventNotify(const std::string &strCallback,const std::string &strSid,unsigned int uiEventId,std::string &strContent);

	//订阅
	int SubscribleDevice(const std::string &strVcode,DeviceData &dev);
	//取消订阅 指定用户
	int UnSubscribleAll(const std::string &strVcode);
	//取消订阅
	int UnSubscribleAll();
	//清理订阅列表
	int ClearSubscribler();
	////收到事件通知
	//int OnEventNotifyReq(const std::string &strTo,std::string &strTags,const std::string &strCallback,std::string &strSid,unsigned int uiSeq,std::vector<NameValue> &vecArgs);
	//处理订阅信息
	int ProcessEventSubscrible();


	//设备查询 同步模式
	int DeviceQuery_Sync(const std::string &strDeviceVcode,const std::string &strType,const std::string &strCondition,std::string &strRsp,int iTimeout); 
	
	//设备下载
	int DeviceDownload_Sync(const std::string &strDeviceVcode,const std::string &strUrl,std::string &strRsp,int iTimeout);

	////通用消息
	//virtual int OnGeneralMsg(HttpMessage &msg,const char *pContent,int iLength);

	//根据eventurl获取主机和uri
	bool GetEventUri(const std::string &strEventUrl,std::string &strIp,unsigned short &iPort,std::string &strEventUri);

	int HttpCode2Error(int iStatusCode);

#ifdef PLAT_WIN32
	static void __stdcall fnOnDisConnect_s(UInt32 lLoginID,int iStatus,int iReason,void *pUser);
	static void __stdcall fnOnMessage_s(UInt32 lLoginID,LPHTTP_HEADER pHdr,void * pContent,int iContentLength,void *pUser);	
#else
	static void fnOnDisConnect_s(UInt32 lLoginID,int iStatus,int iReason,void *pUser);
	static void fnOnMessage_s(UInt32 lLoginID,LPHTTP_HEADER pHdr,void * pContent,int iContentLength,void *pUser);
#endif
	void  fnOnDisConnect(UInt32 lLoginID,int iStatus,int iReason);
	void  fnOnMessage(UInt32 lLoginID,LPHTTP_HEADER pHdr,void * pContent,int iContentLength);

	bool m_bIsStart; //设备状态

	EmStatus m_emStatus;
	int m_iLoginError;

	unsigned short m_usServPort;
	std::string m_strServIp;

	std::string m_strEventListenIp;
	unsigned short m_usEventListenPort;
	std::string m_strVirtualCode;
	std::string m_strServVirtualcode;
	std::string m_strPassword;

	fOnDisConnect m_cbDisConnect;
	void *m_pUser;

	//事件通知回调
	fOnEventNotify m_cbEventNotify;
	void *m_pEventNotifyUser;

	FCL_SOCKET m_sSock;

	FCL_THREAD_HANDLE m_hTaskThread;
	bool m_bExitTaskThread;

	//int ConnectAysc();
	unsigned int MakeReqId();
	//unsigned long long MakeSessionId();
	std::string MakeSessionId();
	std::string MakeTags();
	//int PollData();
	//int PollSessionData();
	//int PollConnect();

	//int CreateSession();
	unsigned int GetSeq(const std::string &strTags);

	unsigned char m_ucMac[6];
	unsigned char m_ucModuleId;
	static unsigned int s_uiSeq; //包标识
	static unsigned long long s_ullSessionId; //会话标识

	unsigned int m_uiLoginId;

	typedef std::map<unsigned int,TaskItem*> RequestList;
	RequestList m_reqList;
	CMutexThreadRecursive m_lockReqList;
	void AddRequest(unsigned int uiReq,TaskItem *trans)
	{
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
		//INFO_TRACE("[TEST] add seq "<<uiReq);
		m_reqList[uiReq] = trans;
	}
	TaskItem * FindRequest(unsigned int uiReq)
	{
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
		RequestList::iterator it = m_reqList.find(uiReq);
		if ( m_reqList.end() == it )
		{
			return NULL;
		}
		return it->second;
	}
	TaskItem * FetchRequest(unsigned int uiReq) //从列表中取出
	{
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
		TaskItem *pTrans = NULL;
		RequestList::iterator it = m_reqList.find(uiReq);
		if ( m_reqList.end() == it )
		{
			return NULL;
		}
		pTrans = it->second;
		m_reqList.erase(it);
		return pTrans;
	}
	int RemoveRequest(unsigned int uiReq)
	{
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
		RequestList::iterator it = m_reqList.find(uiReq);
		if ( m_reqList.end() == it )
		{
			return 0;
		}
		//INFO_TRACE("[TEST] remove seq "<<uiReq);
		TaskItem *pTrans = it->second;
		m_reqList.erase(it);
		delete pTrans;
		return 1;
	}

	std::vector<EventSubscrible*> m_vecSubdcrible;
	CMutexThreadRecursive m_lockSubList;
	void AddSubscrble(EventSubscrible *pSub)
	{
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockSubList);
		m_vecSubdcrible.push_back(pSub);
	}
	EventSubscrible * FindSubscrble_bySid(const std::string &strSid)
	{
		EventSubscrible *pSub = NULL;
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockSubList);
		for(size_t i=0;i<m_vecSubdcrible.size();i++)
		{
			if ( strSid == m_vecSubdcrible[i]->strSid )
			{
				pSub = m_vecSubdcrible[i];
				return pSub;

			}
		}
		return pSub;
	}
	EventSubscrible * FindSubscrble_byTags(const std::string &strTags)
	{
		EventSubscrible *pSub = NULL;
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockSubList);
		for(size_t i=0;i<m_vecSubdcrible.size();i++)
		{
			if ( strTags == m_vecSubdcrible[i]->strTags )
			{
				pSub = m_vecSubdcrible[i];
				return pSub;
			}
		}
		return pSub;
	}
	bool GetSubscrble_byTags(const std::string &strTags,EventSubscrible &sub)
	{
		EventSubscrible *pSub = NULL;
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockSubList);
		for(size_t i=0;i<m_vecSubdcrible.size();i++)
		{
			if ( strTags == m_vecSubdcrible[i]->strTags )
			{
				sub = *m_vecSubdcrible[i];
				//pSub = m_vecSubdcrible[i];
				//return pSub;
				return true;
			}
		}
		return false/*pSub*/;
	}

	bool UpdateSubscrble_Tags(const std::string &strSid,const std::string &strTags)
	{
		EventSubscrible *pSub = NULL;
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockSubList);
		for(size_t i=0;i<m_vecSubdcrible.size();i++)
		{
			if ( strSid == m_vecSubdcrible[i]->strSid )
			{
				pSub = m_vecSubdcrible[i];
				pSub->strTags = strTags;
				return true;
			}
		}
		return false;
	}

	bool UpdateSubscrble_OK(EventSubscrible *pSub,const std::string &strSid)
	{
		//EventSubscrible *pSub = NULL;
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockSubList);
		for(size_t i=0;i<m_vecSubdcrible.size();i++)
		{
			if ( pSub == m_vecSubdcrible[i] )
			{
				//pSub = m_vecSubdcrible[i];
				pSub->strSid = strSid;
				pSub->llLastUpdate = GetCurrentTimeMs();
				pSub->llLastSend = GetCurrentTimeMs();
				pSub->emStatus = EventSubscrible::emSubStatus_Subscribled;
				return true;
			}
		}
		return false;
	}
	bool UpdateSubscrble_Renew_OK(EventSubscrible *pSub)
	{
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockSubList);
		for(size_t i=0;i<m_vecSubdcrible.size();i++)
		{
			if ( pSub == m_vecSubdcrible[i] )
			{
				pSub->llLastUpdate = GetCurrentTimeMs();
				return true;
			}
		}
		return false;
	}
	bool RemoveSubscrble(EventSubscrible *pSub)
	{
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockSubList);
		for(size_t i=0;i<m_vecSubdcrible.size();i++)
		{
			if ( pSub == m_vecSubdcrible[i] )
			{
				m_vecSubdcrible.erase(m_vecSubdcrible.begin()+i);
				delete pSub;
				return true;
			}
		}
		return false;
	}
	//CHttpDataSession *m_pDataSession;
	//CShSession *m_pSession;

	std::vector<HttpAuthInfo*> m_vecAuth;
	CMutexThreadRecursive m_lockAuthList;
	bool Auth_Add(HttpAuthInfo *pAuth)
	{
		HttpAuthInfo *pTemp = NULL;
		if ( !pAuth )
		{
			return false;
		}
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockAuthList);
		//检索有没有相同的设备,如果有替换
		for(size_t i=0;i<m_vecAuth.size();i++)
		{
			pTemp = m_vecAuth[i];
			if ( pTemp && pTemp->strVcode == pAuth->strVcode )
			{
				if ( pTemp->strSn == pAuth->strSn ) //虚号和设备序列号都相同
				{
					//更新内容
					pTemp->strUser = pAuth->strUser;
					pTemp->strPassword = pAuth->strPassword;

					//清空记录,下次重新获取验证
					pTemp->llLast = 0;
					pTemp->strScheme = "";
					pTemp->strRealm = "";
					pTemp->strNonce = "";

					delete pAuth;
					pAuth = NULL;
					return true;
				}
				else
				{
					//相同虚号而设备序列号却不同,失败
					return false;
				}
			}
		}
		//没有,添加到列表
		m_vecAuth.push_back(pAuth);
		//清空记录,下次重新获取验证
		pAuth->llLast = 0;
		pAuth->strScheme = "";
		pAuth->strRealm = "";
		pAuth->strNonce = "";

		return true;
	}
	bool Auth_Add(const std::string &strVcode,const std::string &strSn,const std::string &strUser,const std::string &strPassword)
	{
		HttpAuthInfo *pAuth = NULL;
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockAuthList);
		//检索有没有相同的设备,如果有替换
		for(size_t i=0;i<m_vecAuth.size();i++)
		{
			pAuth = m_vecAuth[i];
			if ( pAuth && pAuth->strVcode == strVcode )
			{
				if ( pAuth->strSn == strSn ) //虚号和设备序列号都相同
				{
					//相同虚号而设备和序列号
					return false;
				}
				else
				{
					//相同虚号而设备序列号却不同,失败
					return false;
				}
			}
		}

		//没有,添加到列表
		pAuth = new HttpAuthInfo();
		if ( !pAuth )
		{
			return false;
		}
		pAuth->strVcode = strVcode;
		pAuth->strSn = strSn;
		pAuth->strUser = strUser;
		pAuth->strPassword = strPassword;

		//清空记录,下次重新获取验证
		pAuth->llLast = 0;
		pAuth->strScheme = "";
		pAuth->strRealm = "";
		pAuth->strNonce = "";
		m_vecAuth.push_back(pAuth);

		return true;
	}
	void Auth_Clear()
	{
		HttpAuthInfo *pAuth = NULL;
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockAuthList);
		
		for(size_t i=0;i<m_vecAuth.size();i++)
		{
			pAuth = m_vecAuth[i];
			if ( pAuth  )
			{
				delete pAuth;
			}
		}

		m_vecAuth.clear();

		return ;
	}
	bool Auth_GetUser(const std::string &strVcode
					  ,std::string &strUser
					  ,std::string &strPassword
					 )
	{
		HttpAuthInfo *pAuth = NULL;
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockAuthList);
		
		for(size_t i=0;i<m_vecAuth.size();i++)
		{
			pAuth = m_vecAuth[i];
			if ( pAuth && pAuth->strVcode == strVcode ) //存在
			{
				strUser = pAuth->strUser;
				strPassword = pAuth->strPassword;
				return true;
			}
		}

		return false;
	}
	bool Auth_Get(const std::string &strVcode
				 ,std::string &strUser
				 ,std::string &strPassword
				 ,std::string &strScheme
				 ,std::string &strRealm
				 ,std::string &strNonce
				 )
	{
		HttpAuthInfo *pAuth = NULL;
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockAuthList);
		
		for(size_t i=0;i<m_vecAuth.size();i++)
		{
			pAuth = m_vecAuth[i];
			if ( pAuth && pAuth->strVcode == strVcode ) //存在
			{
				strUser = pAuth->strUser;
				strPassword = pAuth->strPassword;
				strScheme = pAuth->strScheme;
				strRealm = pAuth->strRealm;
				strNonce = pAuth->strNonce;
				return true;
			}
		}

		return false;
	}
	bool Auth_Update(const std::string &strVcode
					,const std::string &strUser
					,const std::string &strPassword
					,const std::string &strScheme
					,const std::string &strRealm
					,const std::string &strNonce
					)
	{
		HttpAuthInfo *pAuth = NULL;
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockAuthList);

		for(size_t i=0;i<m_vecAuth.size();i++)
		{
			pAuth = m_vecAuth[i];
			if ( pAuth && pAuth->strVcode == strVcode ) //存在
			{
				if ( pAuth->strUser != strUser || pAuth->strPassword != strPassword )
				{
					//账户信息有变化
				}
				pAuth->strUser = strUser;
				pAuth->strPassword = strPassword;
				pAuth->llLast = GetCurrentTimeMs();
				pAuth->strScheme = strScheme;
				pAuth->strRealm = strRealm;
				pAuth->strNonce = strNonce;
				return true;
			}
		}

		return false;
	}
	bool Auth_UpdateAuth(const std::string &strVcode
						,const std::string &strScheme
						,const std::string &strRealm
						,const std::string &strNonce
					)
	{
		HttpAuthInfo *pAuth = NULL;
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockAuthList);

		for(size_t i=0;i<m_vecAuth.size();i++)
		{
			pAuth = m_vecAuth[i];
			if ( pAuth && pAuth->strVcode == strVcode ) //存在
			{
				pAuth->llLast = GetCurrentTimeMs();
				pAuth->strScheme = strScheme;
				pAuth->strRealm = strRealm;
				pAuth->strNonce = strNonce;
				return true;
			}
		}

		return false;
	}
	bool Auth_IsExist(const std::string &strVcode)
	{
		HttpAuthInfo *pAuth = NULL;
		CMutexGuardT<CMutexThreadRecursive> theLock(m_lockAuthList);

		for(size_t i=0;i<m_vecAuth.size();i++)
		{
			pAuth = m_vecAuth[i];
			if ( pAuth && pAuth->strVcode == strVcode ) //存在
			{
				return true;
			}
		}

		return false;
	}

	std::string GetAuthInfo(const std::string &strVcode,std::string strMethod,std::string strUri);
	bool ProcessAuthReq(const std::string &strVcode,const std::string &strAuthenticate,std::string &strAuthorization,std::string strMethod,std::string strUri);
	
	//收到需要认证回应,处理认证 请求在任务列表里
	bool ProcessUpnpAuthTaskRsp(LPHTTP_HEADER pHdr,void * pContent,int iContentLength);

	bool m_bNeedSubscrible; //是否需要订阅

	bool m_bFirstConnect;    //第一次连接
	bool m_bFirstLogin;      //第一次登录
	bool m_bAutoReConnect;   //是否主动重连
	static unsigned int s_uiLoginId; //包标识
	unsigned int MakeLoginId();

	long long m_llRetryInterval;
	const static long long GS_RETRY_INTERVAL = 15000;

#ifdef WIN32
	static unsigned long __stdcall TaskThreadProc(void *pParam); 
#else
	static void* TaskThreadProc(void *pParam);
#endif
	void TaskFuncProc(void);
};

#endif