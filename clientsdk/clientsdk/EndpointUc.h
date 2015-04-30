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

	//�û���֤��Ϣ
	class HttpAuthInfo
	{
	public:
		//��ź����кű��������Ψһ,��ÿ����ź��豸���кű���һһ��Ӧ
		std::string strVcode;		//�豸��� 
		std::string strSn;			//�豸���к�
		std::string strUser;		//�û���
		std::string	strPassword;	//����

		/////////�����ϴ���֤��Ϣ,�����ʱ��������Ҫ��ζ���,����ʹ����ͬ����֤����,�Լ�С��������/////////
		long long llLast;			//�ϴ���֤ʱ��,Ϊ0ʱ��ʾ��δ���й���֤
		std::string strScheme;		//ģʽ,����ΪժҪģʽ Digest
		std::string strRealm;		//�������Դ������,��ǰ�������ز�����@����snģʽ,�����ȡ�豸�б�Ϊconfig@12345678,����configΪ��ѯ�豸�б�����������,12345678Ϊ�豸sn
		std::string strNonce;		//�����
		/////////�����ϴ���֤��Ϣ,�����ʱ��������Ҫ��ζ���,����ʹ����ͬ����֤����,�Լ�С��������/////////
	};


	//������Ϣ
	class EventSubscrible
	{
	public:

		enum EmSubscribleStatus
		{
			emSubStatus_Idle,			//��ʼ״̬
			emSubStatus_Subscribling,   //���ڶ���
			emSubStatus_Subscribled,	//�Ѿ�����
		};

		EventSubscrible()
		{
			llLastUpdate = 0;
			ullTimeOut = 30*60*1000; //30����
			llLastSend = 0;
			iSendInterval = 20*60*1000; //10���ӷ�һ������
			//iStatus = 0;
			emStatus = emSubStatus_Idle;
		}
		EventSubscrible(const EventSubscrible &a)
		{
			strEventUrl		= a.strEventUrl;
			strCallback		= a.strCallback;  //�ص�·��
			strSid			= a.strSid;       //SID
			strUserId		= a.strUserId;    //���
			strTags			= a.strTags;      //�����ʶ
			llLastUpdate	= a.llLastUpdate;
			ullTimeOut		= a.ullTimeOut;
			llLastSend		= a.llLastSend;
			iSendInterval	= a.iSendInterval;
			emStatus		= a.emStatus;
			strUdn			= a.strUdn; //�豸udn
			strServiceType	= a.strServiceType; //��������
		}
		EventSubscrible & operator=(const EventSubscrible &a)
		{
			if ( this == &a )
			{
				return *this;
			}
			strEventUrl		= a.strEventUrl;
			strCallback		= a.strCallback;  //�ص�·��
			strSid			= a.strSid;       //SID
			strUserId		= a.strUserId;    //���
			strTags			= a.strTags;      //�����ʶ
			llLastUpdate	= a.llLastUpdate;
			ullTimeOut		= a.ullTimeOut;
			llLastSend		= a.llLastSend;
			iSendInterval	= a.iSendInterval;
			emStatus		= a.emStatus;
			strUdn			= a.strUdn; //�豸udn
			strServiceType	= a.strServiceType; //��������
			return *this;
		}
		~EventSubscrible()
		{
		}

		std::string strEventUrl;  //����·��
		std::string strCallback;  //�ص�·��
		std::string strSid;       //SID
		std::string strUserId;    //���
		std::string strTags;      //�����ʶ
		unsigned long long llLastUpdate;
		unsigned long long ullTimeOut;
		unsigned long long llLastSend;
		int iSendInterval;
		//int iStatus;           //״̬ 0 ��ʼ 1 ���������� 2 ���ĳɹ�
		EmSubscribleStatus emStatus;
		std::string strUdn; //�豸udn
		std::string strServiceType; //��������
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
		long long m_llStart; //������ʱ��
		unsigned int m_uiTimeout; //��ʱʱ��
		std::string m_strTags; //������
		int iTaskType;
		int iStatus;
		int iStatusCode;
		std::string strRsp;
		CEventThread hEvent;

		//������Ϣ ������������,�����ڰ�ȫ��֤ʱ�ٴη���ʹ��
		LPHTTP_HEADER pHdrReq;	//����ͷ
		std::string strReq;		//��������
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


	//����
	int Subscrible(const std::string &strUDN,const std::string &strServiceType,const std::string &strVirtCode,const std::string &strEventUrl,const std::string &strCallback);
	//int Subscrible(const std::string &strUDN,const std::string &strServiceType,const std::string &strVirtCode,const std::string &strEventUrl,const std::string &strHostIp,unsigned short usHostPort,const std::string &strEventUri,const std::string &strCallback);
	//����
	int RenewSubscrible(const std::string &strVirtCode,const std::string &strEventUrl,const std::string &strSid);
	//ȡ������
	int UnSubscrible(const std::string &strVirtCode,const std::string &strEventUrl,const std::string &strSid);
	//ȡ������
	int UnSubscrible_NoMutex(const std::string &strVirtCode,const std::string &strEventUrl,const std::string &strSid);
	
	//////////�ٴη�������
	//����
	int Subscrible2_Auth(const std::string &strTags,const std::string &strAuthenticate);
	//����
	int RenewSubscrible2_Auth(const std::string &strTags,const std::string &strAuthenticate);
	//ȡ������
	int UnSubscrible2_Auth(const std::string &strTags,const std::string &strAuthenticate);



	//int StartHttpServer();

	//����
	int StartTaskThread();
	//����
	int StopTaskThread();

	void Process_Task();

	void SetDisConnectCb(fOnDisConnect cbDisConnect,void *pUser)
	{
		m_cbDisConnect = cbDisConnect;
		m_pUser = pUser;
	}

	//�¼�֪ͨ�ص�
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

	//��¼
	int Login();

	int CLIENT_Login(char *pchServIP,UInt16 wServPort,char *pchServVirtcode,char *pchVirtCode,char *pchPassword);
	int CLIENT_Logout();

	//��ȡ�����б�
	bool CLIENT_QueryGatewayList(LPUPNP_GATEWAY pUpnpGateway,Int32 maxlen,Int32 *devicecount,Int32 waittime);
	bool ParseGatewayList(std::string &strMsg,LPUPNP_GATEWAY pUpnpGateway,Int32 maxlen,Int32 &cout);

	//��ȡ�豸�б�
	int  CLIENT_GetDeviceList(char *pDeviceUdn,char *pDeviceLocation,LPUPNP_DEVICE pUpnpDevice,Int32 maxlen,Int32 *devicecount,Int32 waittime);
	//��ȡ�豸�б�
	int  CLIENT_GetDeviceList(char *pDeviceUdn,char *pDeviceLocation,std::string &strDeviceList,Int32 waittime);
	
	//��ȡ������Ϣ
	int  CLIENT_GetLayout(char *pDeviceVCode
							,LPLAYOUT_FLOOR pFloors
							,Int32 maxFloors
							,Int32 *floors
							,LPLAYOUT_ROOM pRooms
							,Int32 maxRooms
							,Int32 *rooms
							,Int32 waittime);	
	// �豸����
	bool  CLIENT_Control(char *pDeviceVCode,char *pControlUrl,char *pServiceType,char *pActionName,LPACTION_PARAM pInParam,Int32 incount,LPACTION_PARAM pOutParam,Int32 maxlen,Int32 *outcount,Int32 waittime);

	//�������ķ���
	int CLIENT_Subscrible_Batch(LPSUBSCRIBLE_INFO pSubList,int iCount,int iTimeout);
	
	// ��ѯ�����ļ��汾��Ϣ
	int CLIENT_GetConfigVerion(char *pDeviceVCode,LPCONFIG_VERSION pVer,Int32 waittime);
	bool ParseVersionInfo(std::string &strMsg,LPCONFIG_VERSION pVer);

	// ��ѯ�����ļ��汾��Ϣ
	int  CLIENT_DownloadConfigFile(char *pDeviceVCode,char *pFileUrl,char *pszSaveFile,Int32 waittime);
	bool SaveToFile(const char  *pszFile,const char *pData,int iSize);
	
	
	/////////////////////////////
	//�豸��֤
	int CLIENT_DeviceAuth(char *pszDeviceVcode,char *pszUser,char *pszPassword,char *pszDeviceSn,Int32 waittime);
	//�豸���ñ����ѯ
	int CLIENT_QueryDeviceConfigChange(char *pszDeviceVcode,std::string &strChangeId,Int32 waittime);
	//�����û����ذ󶨹�ϵ��Ϣ,����ʱ�����ǰ��������Ϣ,��˱�����øýӿ������������
	int CLIENT_SetGatewayUserList(LPGATEWAY_USER pUserList,Int32 count);
	/////////////////////////////
	
	int SearchDevice_Sync(const std::string &strDevCcode);

	void Task_Process(void);

	//�յ����Ļ�Ӧ
	virtual int OnSubscribleRsp(const std::string &strTo,const std::string &strTags,const std::string &strSid,int iTimeout,int iResult);

	//�յ�������Ӧ
	virtual int OnRenewSubscribleRsp(const std::string &strTo,const std::string &strTags,const std::string &strSid,int iTimeout,int iResult);

	//�յ�ȡ�����Ļ�Ӧ
	virtual int OnCancelSubscribleRsp(const std::string &strTo,const std::string &strTags,int iResult);

	//�յ��¼�֪ͨ
	virtual int OnEventNotifyReq(const std::string &strTo,std::string &strTags,const std::string &strCallback,std::string &strSid,unsigned int uiSeq,std::vector<NameValue> &vecArgs);
	//�յ��¼���Ӧ
	virtual int OnEventNotifyRsp(const std::string &strTo,std::string &strTags,int iResult);

	int ProcessEventNotify(const std::string &strCallback,const std::string &strSid,unsigned int uiEventId,std::string &strContent);

	//����
	int SubscribleDevice(const std::string &strVcode,DeviceData &dev);
	//ȡ������ ָ���û�
	int UnSubscribleAll(const std::string &strVcode);
	//ȡ������
	int UnSubscribleAll();
	//�������б�
	int ClearSubscribler();
	////�յ��¼�֪ͨ
	//int OnEventNotifyReq(const std::string &strTo,std::string &strTags,const std::string &strCallback,std::string &strSid,unsigned int uiSeq,std::vector<NameValue> &vecArgs);
	//��������Ϣ
	int ProcessEventSubscrible();


	//�豸��ѯ ͬ��ģʽ
	int DeviceQuery_Sync(const std::string &strDeviceVcode,const std::string &strType,const std::string &strCondition,std::string &strRsp,int iTimeout); 
	
	//�豸����
	int DeviceDownload_Sync(const std::string &strDeviceVcode,const std::string &strUrl,std::string &strRsp,int iTimeout);

	////ͨ����Ϣ
	//virtual int OnGeneralMsg(HttpMessage &msg,const char *pContent,int iLength);

	//����eventurl��ȡ������uri
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

	bool m_bIsStart; //�豸״̬

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

	//�¼�֪ͨ�ص�
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
	static unsigned int s_uiSeq; //����ʶ
	static unsigned long long s_ullSessionId; //�Ự��ʶ

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
	TaskItem * FetchRequest(unsigned int uiReq) //���б���ȡ��
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
		//������û����ͬ���豸,������滻
		for(size_t i=0;i<m_vecAuth.size();i++)
		{
			pTemp = m_vecAuth[i];
			if ( pTemp && pTemp->strVcode == pAuth->strVcode )
			{
				if ( pTemp->strSn == pAuth->strSn ) //��ź��豸���кŶ���ͬ
				{
					//��������
					pTemp->strUser = pAuth->strUser;
					pTemp->strPassword = pAuth->strPassword;

					//��ռ�¼,�´����»�ȡ��֤
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
					//��ͬ��Ŷ��豸���к�ȴ��ͬ,ʧ��
					return false;
				}
			}
		}
		//û��,��ӵ��б�
		m_vecAuth.push_back(pAuth);
		//��ռ�¼,�´����»�ȡ��֤
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
		//������û����ͬ���豸,������滻
		for(size_t i=0;i<m_vecAuth.size();i++)
		{
			pAuth = m_vecAuth[i];
			if ( pAuth && pAuth->strVcode == strVcode )
			{
				if ( pAuth->strSn == strSn ) //��ź��豸���кŶ���ͬ
				{
					//��ͬ��Ŷ��豸�����к�
					return false;
				}
				else
				{
					//��ͬ��Ŷ��豸���к�ȴ��ͬ,ʧ��
					return false;
				}
			}
		}

		//û��,��ӵ��б�
		pAuth = new HttpAuthInfo();
		if ( !pAuth )
		{
			return false;
		}
		pAuth->strVcode = strVcode;
		pAuth->strSn = strSn;
		pAuth->strUser = strUser;
		pAuth->strPassword = strPassword;

		//��ռ�¼,�´����»�ȡ��֤
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
			if ( pAuth && pAuth->strVcode == strVcode ) //����
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
			if ( pAuth && pAuth->strVcode == strVcode ) //����
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
			if ( pAuth && pAuth->strVcode == strVcode ) //����
			{
				if ( pAuth->strUser != strUser || pAuth->strPassword != strPassword )
				{
					//�˻���Ϣ�б仯
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
			if ( pAuth && pAuth->strVcode == strVcode ) //����
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
			if ( pAuth && pAuth->strVcode == strVcode ) //����
			{
				return true;
			}
		}

		return false;
	}

	std::string GetAuthInfo(const std::string &strVcode,std::string strMethod,std::string strUri);
	bool ProcessAuthReq(const std::string &strVcode,const std::string &strAuthenticate,std::string &strAuthorization,std::string strMethod,std::string strUri);
	
	//�յ���Ҫ��֤��Ӧ,������֤ �����������б���
	bool ProcessUpnpAuthTaskRsp(LPHTTP_HEADER pHdr,void * pContent,int iContentLength);

	bool m_bNeedSubscrible; //�Ƿ���Ҫ����

	bool m_bFirstConnect;    //��һ������
	bool m_bFirstLogin;      //��һ�ε�¼
	bool m_bAutoReConnect;   //�Ƿ���������
	static unsigned int s_uiLoginId; //����ʶ
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