#ifndef COMMONDEFINE_H
#define COMMONDEFINE_H

#include <string>
#include <vector>
#include <list>
#include <functional>
#include <algorithm>
#include "Platform.h"

std::string ToUpper(std::string strSrc);
std::string ToLowwer(std::string strSrc);

#if 0
//trim left space
std::string TrimLeft(std::string &s)
{
	s.erase(s.begin(),std::find_if(s.begin(),s.end(),std::not1(std::ptr_fun<int,int>(std::isspace))));
	return s;
}
//trim right space
std::string TrimRight(std::string &s)
{
	s.erase(std::find_if(s.rbegin(),s.rend(),std::not1(std::ptr_fun<int,int>(std::isspace))).base(),s.end());
	return s;
}
//trim both space
std::string TrimBoth(std::string &s)
{
	return TrimLef(TrimRight(s));
}
#endif


class CIsSpace
{
public:
	int operator() (const char c)
	{
		return c == ' ';
	}
};

class CIsQuote
{
public:
	int operator() (const char c)
	{
		return c == '\"';
	}
};

template<typename IS> 
void LTrimString(std::string &aTrim, IS aIs)
{
	LPCSTR pStart = aTrim.c_str();
	LPCSTR pMove = pStart;

	for ( ; *pMove; ++pMove)
	{
		if (!aIs(*pMove))
		{
			if (pMove != pStart)
			{
				size_t nLen = strlen(pMove);
				aTrim.replace(0, nLen, pMove, nLen);
				aTrim.resize(nLen);
			}
			return;
		}
	}
};

template<typename IS> 
void RTrimString(std::string &aTrim, IS aIs)
{
	if (aTrim.empty())
		return;

	LPCSTR pStart = aTrim.c_str();
	LPCSTR pEnd = pStart + aTrim.length() - 1;
	LPCSTR pMove = pEnd;

	for ( ; pMove >= pStart; --pMove)
	{
		if (!aIs(*pMove))
		{
			if (pMove != pEnd)
				aTrim.resize(pMove - pStart + 1);
			return;
		}
	}
};

template<typename IS> 
void TrimString(std::string &aTrim, IS aIs)
{
	LTrimString(aTrim, aIs);
	RTrimString(aTrim, aIs);
};

//�û���Ϣ
class CClientUser
{
public:
	std::string m_strUsername;
	std::string m_strPassword;
};

class NameValue
{
public:
	NameValue()
	{
	}
	NameValue(const char* name,const char* value)
	{
		m_strArgumentName = name;
		m_strArgumentValue = value;
	}
	NameValue(const std::string name,const std::string value)
	{
		m_strArgumentName = name;
		m_strArgumentValue = value;
	}
	std::string m_strArgumentName;
	std::string m_strArgumentValue;
};

typedef enum _tagHttpMethod
{
	emMethodGet           = 1,        // http get
	emMethodPost          = 2,        // http post
	emMethodNotify        = 3,      // ��չ NOTIFY   �¼�֪ͨ
	emMethodNotifyStar    = 4,      // ��չ NOTIFY * SSDP
	emMethodMsearch       = 5,      // ��չ M-SEARCH * SSDP
	emMethodSubscrible    = 6,      // ��չ SUBSCRIBLE
	emMethodUnSubscrible  = 7,      // ��չ UNSUBSCRIBLE
	emMethodRegister      = 8,      // ��չ REGISTER
	emMethodSearch        = 9,      // ��չ SEARCH

}HttpMethod;

class HttpMessage
{
public:
	HttpMessage()
	{
		iType = 0;
		iMethod = 0;
		iStatusCode = 0;
		iContentLength = 0;
		bIsChunkMode = false;
	}

	std::string GetValue(const std::string strName)
	{
		for(size_t i=0;i<vecHeaderValues.size();i++)
		{
			if ( vecHeaderValues[i].m_strArgumentName == strName )
			{
				return vecHeaderValues[i].m_strArgumentValue;
			}
		}
		return std::string();
	}
	std::string GetValue(const char* strName)
	{
		return GetValue(std::string(strName));
	}
	std::string GetValueNoCase(const std::string strName)
	{
		std::string strNameUpper = ToUpper(strName);
		std::string strTempUpper;

		for(size_t i=0;i<vecHeaderValues.size();i++)
		{
			strTempUpper = ToUpper(vecHeaderValues[i].m_strArgumentName);
			if ( strTempUpper == strNameUpper )
			//if ( vecHeaderValues[i].m_strArgumentName == strName )
			{
				return vecHeaderValues[i].m_strArgumentValue;
			}
		}
		return std::string();
	}
	std::string GetValueNoCase(const char* strName)
	{
		return GetValueNoCase(std::string(strName));
	}

	void SetValue(std::string strName,std::string strValue)
	{
		std::string strNameUpper = ToUpper(strName);
		std::string strTempUpper;
		for(size_t i=0;i<vecHeaderValues.size();i++)
		{
			strTempUpper = ToUpper(vecHeaderValues[i].m_strArgumentName);
			if ( strTempUpper == strNameUpper )
			{
				 vecHeaderValues[i].m_strArgumentValue = strValue;
				 return ;
			}
			//if ( vecHeaderValues[i].m_strArgumentName == strName )
			//{
			//	 vecHeaderValues[i].m_strArgumentValue = strValue;
			//	 return ;
			//}
		}
		vecHeaderValues.push_back(NameValue(strName,strValue));
		return ;

	}

	void RemoveValueNoCase(std::string strName)
	{
		std::string strNameUpper = ToUpper(strName);
		std::string strTempUpper;

		for(size_t i=0;i<vecHeaderValues.size();i++)
		{
			strTempUpper = ToUpper(vecHeaderValues[i].m_strArgumentName);
			if ( strTempUpper == strNameUpper )
			{
				vecHeaderValues.erase(vecHeaderValues.begin()+i);
				return ;
			}
		}
	}
	std::string ToHttpheader()
	{
		std::string strTemp;
		if ( 1 == iType ) //request
		{
			switch ( iMethod )
			{
			case emMethodGet:   //GET
				strTemp += "GET ";
				break;
			case emMethodPost:   //POST
				strTemp += "POST ";
				break;
			case emMethodNotify:   //NOTIFY
				strTemp += "NOTIFY ";
				break;
			case emMethodNotifyStar:   //NOTIFY *
				strTemp += "NOTIFY * ";
				break;
			case emMethodMsearch:   //M-SEARCH *
				strTemp += "M-SEARCH * ";
				break;
			case emMethodSubscrible:   //SUBSCRIBLE
				strTemp += "SUBSCRIBLE ";
				break;
			case emMethodUnSubscrible:   //UNSUBSCRIBLE
				strTemp += "UNSUBSCRIBLE ";
				break;
			case emMethodRegister:   //REGISTER
				strTemp += "REGISTER ";
				break;
			case emMethodSearch:   //SEARCH
				strTemp += "SEARCH ";
				break;
			default:
				return strTemp;
			}
			strTemp += strPath;
			strTemp += " HTTP/1.1\r\n";

		}
		else if ( 2 == iType ) //response
		{
			strTemp += "HTTP/1.1 ";
			switch ( iStatusCode )
			{
			case 200:
				strTemp += "200 OK";
				break;
			case 401:
				strTemp += "401 Unauthorited";
				break;
			default:
				{
					char szTemp[64];
					sprintf(szTemp,"%d Unknown",iStatusCode);
					strTemp += szTemp;
					break;
				}
			}
			strTemp += "\r\n";
		}
		else //δ֪,��Ӧ�ó���
		{
			return strTemp;
		}

		char szTemp[64];
		sprintf(szTemp,"%d",iContentLength);
		this->SetValue("Content-Length",szTemp);
		//strTemp += szTemp;
		//strTemp += "\r\n";
		for(size_t i=0;i<vecHeaderValues.size();i++)
		{
			strTemp += vecHeaderValues[i].m_strArgumentName;
			strTemp += ":";
			strTemp += vecHeaderValues[i].m_strArgumentValue;
			strTemp += "\r\n";
		}
		
		//char szTemp[64];
		//sprintf(szTemp,"Content-Length: %d",iContentLength);
		//strTemp += szTemp;
		//strTemp += "\r\n";
		//strTemp += "Server: Windows Xp\r\n";

		strTemp += "\r\n";
		return strTemp;

	}

	void Clear()
	{
		iType = 0;
		strMethod = "";
		iMethod = 0;
		strPath = "";
		iStatusCode = 0;
		iContentLength = 0;
		bIsChunkMode = false;
		strHeader = "";
		vecHeaderValues.clear();
	}

	int iType; //1 request 2 response
	std::string strMethod; //���� ����
	int iMethod; //����
	std::string strPath; //path ����
	int iStatusCode; //״̬�� ��Ӧ
	int iContentLength; //���ݳ���
	bool bIsChunkMode;  //�Ƿ�chunkedģʽ
	std::string strHeader; //httpͷ
	std::vector<NameValue> vecHeaderValues;
	
};

class EventSub
{
public:
	std::string strEventSubUrl;
	std::string strCallback;
	std::string strSid;
	std::string strDeviceId;
	std::string strServiceType;
	int iStatus; //0 δ���� 1 �Ѿ�����
	long long llLastSubTime;
};


class StateVariable
{
public:
	std::string strName;
	std::string strDataType;
	std::string strValue;
	bool bSendEvents;
	std::string strDefaultValue; //Ĭ��ֵ
};

class Argument
{
public:
	std::string strName;
	std::string strValue;
	int iDirection;
	StateVariable * pRelatedStateVariable;
};

class Action
{
public:
	std::string strName;
	std::vector<Argument*> vecArgs;
};

class CEventSuscribler
{
public:
	CEventSuscribler()
	{
		m_ullId = CreateId();
		m_llLastUpDate = 0;
		m_llTimeout = 0;
		m_uiEventId = 0;
		m_bFirst = true;
	}
	~CEventSuscribler()
	{
	}
	unsigned long long CreateId()
	{
		return ++s_id_generator;
	}
	unsigned int CreateEventSeq()
	{
		//return ++s_event_key_generator;
		if ( m_bFirst )
		{
			m_bFirst = false;
			m_uiEventId = 0;
			return m_uiEventId;
		}
		m_uiEventId++;
		if ( 0 == m_uiEventId )
		{
			m_uiEventId++;
		}
		return m_uiEventId;
	}
	unsigned long long m_ullId; //����Id
	std::string m_strSid; //SID
	std::string m_strCallbackUrl; //�ص�
	std::string m_strUserId; //�����߱�ʶ��Ϣ ���
	long long m_llLastUpDate; //�ϴθ���ʱ��
	long long m_llTimeout; //��ʱʱ��

	unsigned int m_uiEventId; //֪ͨid,��һ�α���Ϊ0,�˺��1��ʼѭ��(������Ϊ0)
	bool m_bFirst;
	static unsigned long long s_id_generator;
	static unsigned int s_event_key_generator;
};

class Service;

class CEventTask
{
public:
	CEventTask(CEventSuscribler *aUser);

	CEventTask(StateVariable *aVar,CEventSuscribler *aUser);

	CEventTask(Service *aService,CEventSuscribler *aUser);

	void AddVar(StateVariable *aVar);

	~CEventTask();


	//StateVariable *var;
	CEventSuscribler *user;

	std::string strCallback;        //�ص���ַ
	std::string strSid;             //SID
	std::string strUserId;          //���
	unsigned int uiSeq;             //SEQ
	std::vector<NameValue> vecArgs; //�����б�
	std::list<NameValue*> vecArgs2; //�����б�

};

class Service
{
public:
	Service()
	{
	}
	Service(std::string type,std::string id,std::string scpdUrl,std::string controlUrl,std::string subUrl)
	{
		m_strServiceType = type;
		m_strServiceId = id;
		m_strSPDUrl = scpdUrl;
		m_strControlUrl = controlUrl;
		m_strEventSubUrl = subUrl;
	}


	StateVariable *GetStateVariable(std::string name)
	{
		for(size_t i=0;i<vecStateVariables.size();i++)
		{
			if ( vecStateVariables[i]->strName == name )
			{
				return vecStateVariables[i];
			}
		}
		return 0;
	}

	//��ȡ����״ֵ̬
	bool GetStateVariableValue(const std::string &name,std::string &value)
	{
		for(size_t i=0;i<vecStateVariables.size();i++)
		{
			if ( vecStateVariables[i]->strName == name )
			{
				value = vecStateVariables[i]->strValue;
				return true;
			}
		}
		return false;
		
	}
	//���ñ���״ֵ̬
	bool SetStateVariableValue(const std::string &name,std::string &value)
	{
		for(size_t i=0;i<vecStateVariables.size();i++)
		{
			if ( vecStateVariables[i]->strName == name )
			{
				if ( value != vecStateVariables[i]->strValue ) //״ֵ̬�ı�
				{
					vecStateVariables[i]->strValue = value;
					//д�¼�֪ͨ
					if ( m_lstSubscribler.size() > 0 )
					{
						AddEvent(vecStateVariables[i]);
					}
				}
			
				return true;
			}
		}
		return false;		
	}

	bool AddEvent(StateVariable *var)
	{
		std::list<CEventSuscribler*>::iterator it;
		for(it=m_lstSubscribler.begin();it!=m_lstSubscribler.end();it++)
		{
			m_lstTask.push_back(CEventTask(var,*it));
		}
		return true;
	}

	CEventSuscribler *FindSubscribler(const std::string &strCallbackUrl)
	{
		CEventSuscribler *pTemp;
		std::list<CEventSuscribler*>::iterator it;
		for(it=m_lstSubscribler.begin();it!=m_lstSubscribler.end();it++)
		{
			pTemp = *it;
			if ( pTemp->m_strCallbackUrl == strCallbackUrl )
			{
				return pTemp;
			}
			
		}
		return NULL;

	}
	CEventSuscribler *FindSubscribler2(const std::string &strSid)
	{
		CEventSuscribler *pTemp;
		std::list<CEventSuscribler*>::iterator it;
		for(it=m_lstSubscribler.begin();it!=m_lstSubscribler.end();it++)
		{
			pTemp = *it;
			if ( pTemp->m_strSid == strSid )
			{
				return pTemp;
			}
			
		}
		return NULL;

	}

	CEventSuscribler *FindSubscribler(const std::string &strUserId,const std::string &strCallbackUrl)
	{
		CEventSuscribler *pTemp;
		std::list<CEventSuscribler*>::iterator it;
		for(it=m_lstSubscribler.begin();it!=m_lstSubscribler.end();it++)
		{
			pTemp = *it;
			if ( pTemp->m_strUserId == strUserId
				&& pTemp->m_strCallbackUrl == strCallbackUrl )
			{
				return pTemp;
			}
			
		}
		return NULL;

	}

	CEventSuscribler *FindSubscribler2(const std::string &strUserId,const std::string &strSid)
	{
		CEventSuscribler *pTemp;
		std::list<CEventSuscribler*>::iterator it;
		for(it=m_lstSubscribler.begin();it!=m_lstSubscribler.end();it++)
		{
			pTemp = *it;
			if ( pTemp->m_strUserId == strUserId
				&& pTemp->m_strSid == strSid )
			{
				return pTemp;
			}
			
		}
		return NULL;

	}
	bool RemoveSubscribler(CEventSuscribler *pSub)
	{
		CEventSuscribler *pTemp = NULL;
		std::list<CEventSuscribler*>::iterator it;
		for(it=m_lstSubscribler.begin();it!=m_lstSubscribler.end();it++)
		{
			pTemp = *it;
			if ( pTemp == pSub )
			{
				m_lstSubscribler.erase(it);
				break;
			}
			
		}
		if ( !pTemp ) //û���ҵ�
		{
			return false;
		}

		//�������
		std::list<CEventTask>::iterator it2=m_lstTask.begin();
		std::list<CEventTask>::iterator itTemp;
		//CEventTask *pEvt;
		for(std::list<CEventTask>::iterator it2=m_lstTask.begin();it2!=m_lstTask.end();it2++)
		{
			//pEvt = *it2;
			if ( it2->user == pTemp )
			{
				itTemp = it2;
				it2++;
				m_lstTask.erase(itTemp);
				//delete pEvt;
			}
			else
			{
				it2++;
			}
		}
		delete pTemp;
		pTemp = NULL;
		return true;
	}

	std::string m_strServiceType;
	std::string m_strServiceId;
	std::string m_strSPDUrl;
	std::string m_strControlUrl;
	std::string m_strEventSubUrl;

	std::string m_strDescDoc;
	std::vector<Action*> vecActions;
	std::vector<StateVariable*> vecStateVariables;
	EventSub m_eventSub; //�¼�������Ϣ
	std::list<CEventSuscribler*> m_lstSubscribler; //���������б�
	std::list<CEventTask> m_lstTask;

	//����ʵ��Ŀ��λ��
	std::string m_strScpdIp;
	unsigned short m_usScpdPort;
	std::string m_strScpdlPath;

	//����ʵ��Ŀ��λ��
	std::string m_strControlIp;
	unsigned short m_usControlPort;
	std::string m_strControlPath;

	//����ʵ��Ŀ��λ��
	std::string m_strEventSubIp;
	unsigned short m_usEventSubPort;
	std::string m_strEventSubPath;
};

class DeviceData
{
public:
	DeviceData()
	{
	}
	DeviceData(std::string type,std::string name,std::string udn)
	{
		m_strDeviceType = type;
		m_strFriendlyName = name;
		m_strUDN = udn;
	}

	std::string m_strDeviceType;
	std::string m_strFriendlyName;
	std::string m_strUDN;
	std::string m_strManufacturer;
	std::string m_strSerialNumber;
	std::string m_strPresentationURL;
	std::string m_strControlMode; //�й����ܼҾ����������ֶ� ��������ģʽ upnp_soap http_post
	std::string m_strLayoutId;
	std::string m_strCameraId;
	//std::string m_strUpperId;
	std::vector<Service*> m_vecSericeList;
	std::vector<DeviceData*> m_vecEmbededDeviceList;

	std::string m_strDescDoc; //�豸�����ĵ���xml����
	std::string m_strIp;      //�豸���ơ�����ip
	unsigned short m_usPort;  //�豸���ơ����Ķ˿�
	std::string m_strPath;    //��·��

	long long m_llLastActive; //�ϴλ�Ծʱ��
};

class InspectDeviceTask
{
public:
	InspectDeviceTask():usPort(0)
	{
	}
	InspectDeviceTask(std::string loc,std::string uuid)
	{
		strLocation = loc;
		strUuid = uuid;
	}

	std::string strLocation;
	std::string strIp;
	unsigned short usPort;
	std::string strPath;
	std::string strUuid;
};

class HttpPostRespAction
{
public:
	std::string strName;
	std::vector<NameValue> args;
};

bool ParseHttpHeader(char *msg,int len,HttpMessage &httpMsg);
int connect_sync(char *ip,unsigned short port,FCL_SOCKET & sock); //ͬ������
int RecvHttpResponse(FCL_SOCKET sock,char **ppContent,int *pContentLength,
								   int iTimeout,HttpMessage &httpMessage);
bool ParseGetDeviceListResp(char *pXml,unsigned int uiLen,DeviceData &deviceData);
bool ParseGetServiceResp(char *pXml,unsigned int uiLen,Service &service);

void FclSleep(int iMillSec);

long long GetCurrentTimeMs();

int SetBlockMode(FCL_SOCKET sock,bool bIsNoBlock); //�����׽�������ģʽ

//����http url(url�ﲻ��������)
bool SplitHttpUrl(const std::string url,std::string &strIp,unsigned short &usPort,std::string &strPath);

std::string MakeJsessionId();

//std::string ToUpper(std::string strSrc);

bool ParseNotifyBody(char *msg,int len,std::vector<NameValue*> &args);

#ifdef PLAT_WIN32
#else
unsigned int WSAGetLastError();
#endif

bool ParseAction(char *pXml,unsigned int uiLen,char *action,char *serviceType,std::vector<NameValue> &outArgs);

bool http_post_parse_action_resp(char *pXml,unsigned int uiLen,std::vector<HttpPostRespAction> &outArgs);
std::string gen_soap_action_resp(std::string strServiceType,Action *pAction,std::vector<HttpPostRespAction> &outArgs);

bool ParseGetDeviceListResp(char *pXml,unsigned int uiLen,DeviceData &deviceData);
bool ParseGetServiceResp(char *pXml,unsigned int uiLen,Service &service);

typedef enum EndpointTypeEm
{
	emEpTypeUnknown,
	emEpType_ControlPint,
	emEpType_Device,
	emEpType_Proxy,
	emEpType_Fdms,
	emEpType_Shbg,
};

#ifndef PLAT_WIN32
unsigned int GetTickCount();
#endif //PLAT_WIN32

//����uuid,�����ģʽ
std::string GeterateGuid();
unsigned int GetMacAddr();
unsigned long long GetMacAddrEx();
unsigned long long GetSysTime100ns();
//����bytes��Ŀ�������
void GenerateRand(unsigned char *buf,int bytes);

int LookupMethod(const char *method);

//��ȡ��ǰʱ�� rfc1123�ж���ĸ�ʽ wkday "," SP 2DIGIT SP month SP 4DIGIT SP 2DIGIT ":" 2DIGIT ":" 2DIGIT
char *GetIso1123Date();

///httpժҪ�㷨
//httpժҪ��Ӧ��Ϣ
//class HttpAuthenticate
//{
//public:
//	std::string strScheme;	//ģʽ,����ΪժҪģʽ
//	std::string strRealm;	//�������Դ������,��ǰ�������ز�����@����snģʽ,�����ȡ�豸�б�Ϊconfig@12345678,����configΪ��ѯ�豸�б�����������,12345678Ϊ�豸sn
//	std::string strNonce;	//�����
//	std::vector<NameValue> params;
//};
////httpժҪ������Ϣ
class HttpAuth
{
public:
	HttpAuth():bIsResponse(false)
	{
	}

	std::string strUsername;//�û���
	std::string strScheme;	//ģʽ,����ΪժҪģʽ
	std::string strRealm;	//�������Դ������,��ǰ�������ز�����@����snģʽ,�����ȡ�豸�б�Ϊconfig@12345678,����configΪ��ѯ�豸�б�����������,12345678Ϊ�豸sn
	std::string strNonce;	//�����
	std::string strUri;		//����·��
	std::string strResponse;//
	std::vector<NameValue> params;

	bool bIsResponse;
	std::string ToString();
};


//����WWW-Authenticate��Authorization
bool ParseHttpAuthParams(const std::string &strAuth,HttpAuth &auth,bool bIsResponse = false);
////����Authorization
//bool ParseHttpAuthorizationParams(const std::string &strAuth,HttpAuthorization &auth);

std::string CalcAuthMd5(const std::string &strUsername,const std::string &strPassword,const std::string &strRealm,const std::string &strNonce,const std::string &strMethod,const std::string &strUri);

//����������� ʱ��+mac+�����
std::string MakeNonce();

std::string CalcAuthVerifyMd5(const std::string &strPassword,const std::string &strNonce,const std::string &strDeviceSerial);

std::string CalcBasic(const std::string &strUsername,const std::string &strPassword);

#endif