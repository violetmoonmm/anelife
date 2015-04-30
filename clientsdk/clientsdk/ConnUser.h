#ifndef CLIENTUSER_H
#define CLIENTUSER_H

#include "Platform.h"
#include "CommonDefine.h"
#include "HttpDataSession.h"
#include <string>

class CConnUser;

class IConnUserSinker
{
public:
	virtual ~IConnUserSinker()
	{
	}
	
	enum EmUserStage
	{
		emConnctionDisconnected,
		emRegisterSuccess,
		emRegisterFailed,
	};

	//virtual int OnRegisterReq(HttpMessage &msg,const char *pContent,int iContentLength) = 0;
	//virtual int OnRegisterRsp(HttpMessage &msg,const char *pContent,int iContentLength) = 0;
	//virtual int OnUnRegisterReq(HttpMessage &msg,const char *pContent,int iContentLength) = 0;
	//virtual int OnUnRegisterRsp(HttpMessage &msg,const char *pContent,int iContentLength) = 0;
	virtual int OnMessage(CConnUser *pConn,HttpMessage &msg,const char *pContent,int iContentLength) = 0;

	virtual int OnStatusChange(CConnUser *pConn,EmUserStage emStatus,int iReason) = 0;
	
	virtual int OnLogin(CConnUser *pConn,int iUserType,const std::string &strUser,std::string &strPassword,int &iResult) = 0;
};

class CConnUser : public IHttpDataSessionSinker
{
public:
	CConnUser();
	CConnUser(FCL_SOCKET sock);
	~CConnUser();

	enum EmStatus
	{
		emIdle,
		emConnecting,
		emConnected,
		emRegistering,
		emRegistered,
		emUnRegistering,
		emUnRegistered
	};
	
	enum EmDisConnectReason
	{
		emDisRe_None,					//����Ҫ
		emDisRe_ConnectFailed,          //����ʧ��
		emDisRe_Disconnected,           //����ʧ��
		emDisRe_ConnectTimeout,			//���ӳ�ʱ
		emDisRe_RegistedFailed,			//ע��ʧ��
		emDisRe_RegistedTimeout,		//ע�ᳬʱ
		emDisRe_RegistedRefused,		//ע�ᱻ�ܾ�
		emDisRe_Keepalivetimeout,		//����ʧ��
		emDisRe_UnRegistered,			//ע��
		emDisRe_PasswordInvalid,		//�������
		emDisRe_Unknown,                //δ֪ԭ��
	};

	virtual int OnHttpMsgIn(HttpMessage &msg,const char *pContent,int iContentLength);
	virtual int OnDisconnect(int iReason);

	void SetSinker(IConnUserSinker *pSinker)
	{
		m_pSinker = pSinker;
	}
	void SetLocalVcode(const std::string &strVcode)
	{
		m_strVcodeLocal = strVcode;
	}
	void SetServerInfo(const std::string &strServIp,unsigned short usServPort,const std::string &strServVcode)
	{
		m_strServIp = strServIp;
		m_usServPort = usServPort;
		m_strVcodePeer = strServVcode;
	}
	void SetLocalType(int iType);;
	//{
	//	m_iType = iType;
	//}
	void SetIsClient(bool bIsClient)
	{
		m_bIsClient = bIsClient;
	}

	unsigned int GetUserId()
	{
		return m_uiUserId;
	}

	CConnUser::EmStatus GetStatus()
	{
		return m_emStatus;
	}

	bool IsRegistered()
	{
		return m_emStatus == emRegistered ? true : false;
	}

	FCL_SOCKET GetSocket()
	{
		return m_sSock;
	}
	bool IsClient()
	{
		return m_bIsClient;
	}
	
	bool HasCanRemoved()
	{
		return m_bToBeRemoved;
	}
	void SetCanRemoved()
	{
		m_bToBeRemoved = true; //����ɾ�����
	}

	bool IsAutoReconnect()
	{
		return m_bAutoReConnect;
	}
	void SetAutoReconnect(bool bAuto)
	{
		m_bAutoReConnect = bAuto;
	}

	bool IsWaitForSend()
	{
		return m_dataSession.IsWaitForSend();
	}
	void SetPassword(const std::string &strPassword)
	{
		m_strPassword = strPassword;
	}

	std::string LocalIp();

	//ע������
	int Register();
	int UnRegister();

	int SendMessage(HttpMessage &msg,const char *pContent,int iContentLength);

	int OnDataIn();
	int OnDataOut();

	//�յ���������
	int OnConnect(int iResult);
	int Process_Data();
	int Process();
	int Release();

private:
	unsigned int MakeReqId();
	unsigned int MakeUserId();
	std::string MakeSessionId();
	std::string MakeTags();


	//��������
	int Connect();
	//����ע������
	int RegisterReq();
	//����ע������
	int RegisterReq(const std::string &strAuth);
	//�յ�ע������
	int OnRegisterReq(HttpMessage &msg,const char *pContent,int iContentLength);
	//����ע���Ӧ
	int RegisterRsp();
	//�յ�ע���Ӧ
	int OnRegisterRsp(HttpMessage &msg,const char *pContent,int iContentLength);
	//��������
	int KeepAliveReq();
	//�յ���������
	int OnKeepAliveReq(HttpMessage &msg,const char *pContent,int iContentLength);
	//�����Ӧ
	int KeepAliveRsp();
	//�յ������Ӧ
	int OnKeepAliveRsp(HttpMessage &msg,const char *pContent,int iContentLength);

	//�յ��ǳ�����
	int OnUnRegisterReq(HttpMessage &msg,const char *pContent,int iContentLength);
	//�յ��ǳ���Ӧ
	int OnUnRegisterRsp(HttpMessage &msg,const char *pContent,int iContentLength);

	//�յ���ͨ��Ϣ
	int OnRecvMsg(HttpMessage &msg,const char *pContent,int iContentLength);

	int Process_Client();
	int Process_Server();
	
	void OnDisConnected(int iReason);
	void OnRegisterSuccess(int iReason);
	void OnRegisterFailed(int iReason);

private:
	EmStatus m_emStatus;

	unsigned short m_usServPort;
	std::string m_strServIp;

	std::string m_strVcodeLocal;
	std::string m_strVcodePeer;

	std::string m_strUuid;
	std::string m_strLocation;

	FCL_SOCKET m_sSock;

	CHttpDataSession m_dataSession;

	IConnUserSinker *m_pSinker;

	int m_iType; //�ն�����
	bool m_bIsClient; //��ǰ�ն��ǿͻ���
	unsigned int m_uiUserId;
	bool m_bAutoReConnect; //�Ƿ��Զ�����

	int m_iPeerType; //�Զ�����

	int m_iFailedTimes;
	long long m_llLastTime;	//�ϴα���ɹ�ʱ��
	long long m_llLastHeartbeatTime; //�ϴη��ͱ���ʱ�� ֻ�Կͻ�������

	bool m_bToBeRemoved; //����ɾ�����

	std::string m_strPassword;
	std::string m_strRealm;
	std::string m_strRandom;

	std::string m_strEndpointType;

	unsigned char m_ucMac[6];
	unsigned char m_ucModuleId;
	static unsigned int s_uiIdentify; //����ʶ
	static unsigned long long s_ullSessionId; //�Ự��ʶ
	static unsigned int s_uiUserId; //�û�Id

	int m_iHeartBeatInterval;	//�������
	int m_iMaxTimeout;	//���ʱʱ��

	long long m_llRetryInterval;
	const static long long GS_RETRY_INTERVAL = 15000;
	const static long long GS_MAX_TIMEOUT = 60000;
	const static long long GS_RETRY_INTERVAL_UC = 1*60*1000;	//uc ������� 1����
	const static long long GS_MAX_TIMEOUT_UC = 5*60*1000;		//uc ��ʱʱ�� 5����
};

#endif