#ifndef IcmsUpnpStack_H
#define IcmsUpnpStack_H

#include "SdkCommonDefine.h"
#include "Platform.h"
#include "CommonDefine.h"

#include "ConnUser.h"

#include <map>


class CIcmsUpnpStack : public IConnUserSinker
{
public:
	CIcmsUpnpStack();
	~CIcmsUpnpStack();

	enum EmStatus
	{
		emIdle,
		emConnecting,
		emConnected,
		emRegistering,
		emRegistered
	};

	static CIcmsUpnpStack * Instance();


	/////////////////////////外部方法
	//初始化
	int Init();
	//反初始化
	void UnInit();

	//设置本端类型
	void SetLocalType(int iType)
	{
		m_iLocalType = iType;
	}

	void SetLocalVcode(char *pVcode)
	{
		if ( pVcode )
		{
			m_strVirtualCode = pVcode;
		}
		else
		{
			m_strVirtualCode = "";
		}
	}
	void SetListenPort(int iType,unsigned short usPort)
	{
		if ( ENDPOINT_TYPE_UC == iType )
		{
			//m_bUse_uc_fd = true;
			m_usServPort_uc_fd = usPort;
		}
		else if ( ENDPOINT_TYPE_PROXY == iType )
		{
			//m_bUse_proxy = true;
			m_usServPort_proxy = usPort;
		}
	}

	//设置断线回调
	void SetDisconnectCallback(fDisConnect cbDisConnect,void *pUser);
	//设置消息通知回调
	void SetMessageCallback(fMessCallBack cbMessage,void * pUser);
	//设置登录通知回调
	void SetOnLoginCallback(fOnLogin fOnLogin,void * pUser);
	//设置是否自动重连
	void SetAutoReconnect(bool bAuto)
	{
		m_bAutoReConnect = bAuto;
	}

	//注册 本端作为终端注册
	UInt32 Login(char *pchServIP,UInt16 wServPort,char *pchServVirtcode,char *pchVirtCode,char *pchPassword,Int32 *error=0);
	//注销
	int Logout(UInt32 hLoginID);
	//强制释放
	int Force_Release(UInt32 hLoginID);

	//执行动作
	int SendMessage(UInt32 hLoginID,LPHTTP_HEADER pHdr,void * pContent,int iContentLength);


	std::string GetLocalIp(UInt32 hLoginID);

	virtual int OnMessage(CConnUser *pConn,HttpMessage &msg,const char *pContent,int iContentLength);

	virtual int OnStatusChange(CConnUser *pConn,EmUserStage emStatus,int iReason);

	virtual int OnLogin(CConnUser *pConn,int iUserType,const std::string &strUser,std::string &strPassword,int &iResult);

	//启动uc和fd注册侦听服务
	int StartUcAndFdListen();
	//关闭uc和fd注册侦听服务
	int StopUcAndFdListen();
	//启动proxy注册侦听服务
	int StartProxyListen();
	//关闭proxy注册侦听服务
	int StopProxyListen();

	/////////////////////////内部方法
private:
	//启动处理线程
	int StartTaskThread();
	//结束处理线程
	int StopTaskThread();

	bool StartListen(const char *ip,unsigned short port,FCL_SOCKET &sock);

	//查找实例
	CConnUser * LookupInstance(unsigned int uiId);

	int PollSessionData();
	void PollAccept();
	void OnNewConnection(FCL_SOCKET sock);

#ifdef WIN32
	static unsigned long __stdcall TaskThreadProc(void *pParam); 
#else
	static void* TaskThreadProc(void *pParam);
#endif
	void TaskFuncProc(void);
	void Task_Process();

private:

	//断线回调
	fDisConnect m_cbDisConnect;
	void * m_pUserDisConnect;
	//消息回调
	fMessCallBack m_cbMsgCb;
	void *m_pUserMsg;

	//登录回调
	fOnLogin m_cbLoginCb;
	void *m_pUserLogin;

	bool m_bIsStart; //设备状态

	unsigned short m_usServPort_uc_fd;	//服务端口 接受uc和设备注册
	unsigned short m_usServPort_proxy;	//服务端口 接受代理注册
	std::string m_strServIp;
	bool m_bUse_uc_fd;					//启动uc和fd注册服务
	bool m_bUse_proxy;					//启动代理注册服务
	int m_iLocalType;					//本端类型
	std::string m_strVirtualCode;		//本端虚号

	FCL_SOCKET m_sSock_uc_fd;			//套接字 uc和fd注册侦听
	FCL_SOCKET m_sSock_proxy;			//套接字 proxy注册侦听


	FCL_THREAD_HANDLE m_hTaskThread;
	bool m_bExitTaskThread;

	bool m_bAutoReConnect; //是否自动重连

	std::map<unsigned int,CConnUser*> m_insMap;

	const static long long GS_RETRY_INTERVAL = 15000;

};

#endif
