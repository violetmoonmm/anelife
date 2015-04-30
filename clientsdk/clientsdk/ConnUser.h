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
		emDisRe_None,					//不需要
		emDisRe_ConnectFailed,          //连接失败
		emDisRe_Disconnected,           //连接失败
		emDisRe_ConnectTimeout,			//连接超时
		emDisRe_RegistedFailed,			//注册失败
		emDisRe_RegistedTimeout,		//注册超时
		emDisRe_RegistedRefused,		//注册被拒绝
		emDisRe_Keepalivetimeout,		//保活失败
		emDisRe_UnRegistered,			//注销
		emDisRe_PasswordInvalid,		//密码错误
		emDisRe_Unknown,                //未知原因
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
		m_bToBeRemoved = true; //可以删除标记
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

	//注册请求
	int Register();
	int UnRegister();

	int SendMessage(HttpMessage &msg,const char *pContent,int iContentLength);

	int OnDataIn();
	int OnDataOut();

	//收到连接请求
	int OnConnect(int iResult);
	int Process_Data();
	int Process();
	int Release();

private:
	unsigned int MakeReqId();
	unsigned int MakeUserId();
	std::string MakeSessionId();
	std::string MakeTags();


	//连接请求
	int Connect();
	//发送注册请求
	int RegisterReq();
	//发送注册请求
	int RegisterReq(const std::string &strAuth);
	//收到注册请求
	int OnRegisterReq(HttpMessage &msg,const char *pContent,int iContentLength);
	//发送注册回应
	int RegisterRsp();
	//收到注册回应
	int OnRegisterRsp(HttpMessage &msg,const char *pContent,int iContentLength);
	//保活请求
	int KeepAliveReq();
	//收到保活请求
	int OnKeepAliveReq(HttpMessage &msg,const char *pContent,int iContentLength);
	//保活回应
	int KeepAliveRsp();
	//收到保活回应
	int OnKeepAliveRsp(HttpMessage &msg,const char *pContent,int iContentLength);

	//收到登出请求
	int OnUnRegisterReq(HttpMessage &msg,const char *pContent,int iContentLength);
	//收到登出回应
	int OnUnRegisterRsp(HttpMessage &msg,const char *pContent,int iContentLength);

	//收到普通消息
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

	int m_iType; //终端类型
	bool m_bIsClient; //当前终端是客户端
	unsigned int m_uiUserId;
	bool m_bAutoReConnect; //是否自动重连

	int m_iPeerType; //对端类型

	int m_iFailedTimes;
	long long m_llLastTime;	//上次保活成功时间
	long long m_llLastHeartbeatTime; //上次发送保活时间 只对客户端有用

	bool m_bToBeRemoved; //可以删除标记

	std::string m_strPassword;
	std::string m_strRealm;
	std::string m_strRandom;

	std::string m_strEndpointType;

	unsigned char m_ucMac[6];
	unsigned char m_ucModuleId;
	static unsigned int s_uiIdentify; //包标识
	static unsigned long long s_ullSessionId; //会话标识
	static unsigned int s_uiUserId; //用户Id

	int m_iHeartBeatInterval;	//心跳间隔
	int m_iMaxTimeout;	//保活超时时间

	long long m_llRetryInterval;
	const static long long GS_RETRY_INTERVAL = 15000;
	const static long long GS_MAX_TIMEOUT = 60000;
	const static long long GS_RETRY_INTERVAL_UC = 1*60*1000;	//uc 心跳间隔 1分钟
	const static long long GS_MAX_TIMEOUT_UC = 5*60*1000;		//uc 超时时间 5分钟
};

#endif