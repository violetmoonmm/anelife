#pragma once
#include "BaseClient.h"
#include "CommonDefine.h"

struct HttpQueryReq
{
	std::string strPath;
	int iFailedTimes;

	std::string strRspParam;
	int result;

	CEventThread hEvent;
};

class CWebsClient 
{
public:
	CWebsClient(void);
	~CWebsClient(void);
	
	void SetServerInfo(const std::string &strServIp,unsigned short usServPort,const std::string &strUserName,const std::string &strPassword)
	{
		m_strServIp = strServIp;
		m_iServPort = usServPort;
		m_strUsername = strUserName;
		m_strPassword = strPassword;
		INFO_TRACE("http param: ip="<<m_strServIp<<" port="<<m_iServPort<<" user="<<m_strUsername<<" pwd="<<m_strPassword);
	}
	
	int HttpQuery(const std::string strPath,std::string &strResult);

	int GetClientStatus(char* pszSn,std::string & strResult);

private:
	int Connect(char *pszIp,int iPort); //����
	void Close();//�ر�����

	bool IsConnected()
	{
		return (m_nConnStatus==2)?true:false;
	}

	int SendData(char *pData,int iDataLen); //��������
	//���ʱ��recvʧ��
	void OnTcpDisconnect(int iReason);
	unsigned int CreateReqId()
	{
		unsigned int uiRet = 0;
		uiRet = ++s_ui_RequestId;
		if ( uiRet == 0 )
		{
			uiRet = ++s_ui_RequestId;
		}
		return uiRet;
	}

	/////////�̴߳���////////////
#ifdef WIN32
	static unsigned long __stdcall ThreadProc(void *pParam);
#else
	static void* ThreadProc(void *pParam);
#endif
	void ThreadProc(void);//���ݽ����߳�

	void Thread_Process();

	//���������߳�
	int StartThread();
	//���������߳�
	int StopThread();

	void OnConnect(int iConnStatus); //���ӳɹ�֪ͨ
	void OnDataRecv(); //��������֪ͨ
	void OnDataSend(); //���Է�������֪ͨ

	int OnDealData();

	int OnHttpMsg(HttpMessage &msg,const char *pContent,int iContentLength);

	void ClearSend();//��շ��ͻ���

	std::string MakeSessionId();
	std::string MakeTags(unsigned int uiReqId);

public:
	FCL_SOCKET m_sSock; //�����׽���
	int m_nConnStatus; //����״̬

	int m_waittime;			 //����ʱʱ�䣬ms
	int m_error;			 //������
	EmStatus m_emStatus; //����״̬

	//�������Ϣ
	std::string m_strServIp; //�����ip
	int m_iServPort;		 //����˶˿�
	std::string m_strUsername;  //�û���
	std::string m_strPassword;  //����

	std::string m_strEndpointType;

	FCL_THREAD_HANDLE m_hThread;
	bool m_bExitThread;

	const static  int MAX_BUF_LEN = 1024*128;
	//������ջ���
	char m_szRecvBuf[MAX_BUF_LEN];
	int m_iRecvIndex; //���ջ�������

	FCL_THREAD_HANDLE m_hWorkThread;

	static unsigned int s_ui_RequestId; 

	HttpParseStatus m_emParseStatus;

	HttpMessage m_curMsg;
	char *m_pContent;
	int m_iContentWriteIndex;

	//����
	std::string m_strRealm;
	std::string m_strRandom;

	unsigned char m_ucMac[6];
	unsigned char m_ucModuleId;

private:
	std::list<SendPacket*> _lstSend;   //���ͻ���
	CMutexThreadRecursive m_senLock;

	HttpQueryReq m_curReq;
	std::string m_strAuthorization;

};
