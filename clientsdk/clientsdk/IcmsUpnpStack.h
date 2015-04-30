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


	/////////////////////////�ⲿ����
	//��ʼ��
	int Init();
	//����ʼ��
	void UnInit();

	//���ñ�������
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

	//���ö��߻ص�
	void SetDisconnectCallback(fDisConnect cbDisConnect,void *pUser);
	//������Ϣ֪ͨ�ص�
	void SetMessageCallback(fMessCallBack cbMessage,void * pUser);
	//���õ�¼֪ͨ�ص�
	void SetOnLoginCallback(fOnLogin fOnLogin,void * pUser);
	//�����Ƿ��Զ�����
	void SetAutoReconnect(bool bAuto)
	{
		m_bAutoReConnect = bAuto;
	}

	//ע�� ������Ϊ�ն�ע��
	UInt32 Login(char *pchServIP,UInt16 wServPort,char *pchServVirtcode,char *pchVirtCode,char *pchPassword,Int32 *error=0);
	//ע��
	int Logout(UInt32 hLoginID);
	//ǿ���ͷ�
	int Force_Release(UInt32 hLoginID);

	//ִ�ж���
	int SendMessage(UInt32 hLoginID,LPHTTP_HEADER pHdr,void * pContent,int iContentLength);


	std::string GetLocalIp(UInt32 hLoginID);

	virtual int OnMessage(CConnUser *pConn,HttpMessage &msg,const char *pContent,int iContentLength);

	virtual int OnStatusChange(CConnUser *pConn,EmUserStage emStatus,int iReason);

	virtual int OnLogin(CConnUser *pConn,int iUserType,const std::string &strUser,std::string &strPassword,int &iResult);

	//����uc��fdע����������
	int StartUcAndFdListen();
	//�ر�uc��fdע����������
	int StopUcAndFdListen();
	//����proxyע����������
	int StartProxyListen();
	//�ر�proxyע����������
	int StopProxyListen();

	/////////////////////////�ڲ�����
private:
	//���������߳�
	int StartTaskThread();
	//���������߳�
	int StopTaskThread();

	bool StartListen(const char *ip,unsigned short port,FCL_SOCKET &sock);

	//����ʵ��
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

	//���߻ص�
	fDisConnect m_cbDisConnect;
	void * m_pUserDisConnect;
	//��Ϣ�ص�
	fMessCallBack m_cbMsgCb;
	void *m_pUserMsg;

	//��¼�ص�
	fOnLogin m_cbLoginCb;
	void *m_pUserLogin;

	bool m_bIsStart; //�豸״̬

	unsigned short m_usServPort_uc_fd;	//����˿� ����uc���豸ע��
	unsigned short m_usServPort_proxy;	//����˿� ���ܴ���ע��
	std::string m_strServIp;
	bool m_bUse_uc_fd;					//����uc��fdע�����
	bool m_bUse_proxy;					//��������ע�����
	int m_iLocalType;					//��������
	std::string m_strVirtualCode;		//�������

	FCL_SOCKET m_sSock_uc_fd;			//�׽��� uc��fdע������
	FCL_SOCKET m_sSock_proxy;			//�׽��� proxyע������


	FCL_THREAD_HANDLE m_hTaskThread;
	bool m_bExitTaskThread;

	bool m_bAutoReConnect; //�Ƿ��Զ�����

	std::map<unsigned int,CConnUser*> m_insMap;

	const static long long GS_RETRY_INTERVAL = 15000;

};

#endif
