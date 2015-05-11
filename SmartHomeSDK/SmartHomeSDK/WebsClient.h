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
	int Connect(char *pszIp,int iPort); //连接
	void Close();//关闭连接

	bool IsConnected()
	{
		return (m_nConnStatus==2)?true:false;
	}

	int SendData(char *pData,int iDataLen); //发送数据
	//保活超时或recv失败
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

	/////////线程处理////////////
#ifdef WIN32
	static unsigned long __stdcall ThreadProc(void *pParam);
#else
	static void* ThreadProc(void *pParam);
#endif
	void ThreadProc(void);//数据接收线程

	void Thread_Process();

	//启动处理线程
	int StartThread();
	//结束处理线程
	int StopThread();

	void OnConnect(int iConnStatus); //连接成功通知
	void OnDataRecv(); //接收数据通知
	void OnDataSend(); //可以发送数据通知

	int OnDealData();

	int OnHttpMsg(HttpMessage &msg,const char *pContent,int iContentLength);

	void ClearSend();//清空发送缓冲

	std::string MakeSessionId();
	std::string MakeTags(unsigned int uiReqId);

public:
	FCL_SOCKET m_sSock; //连接套接字
	int m_nConnStatus; //连接状态

	int m_waittime;			 //请求超时时间，ms
	int m_error;			 //错误码
	EmStatus m_emStatus; //连接状态

	//服务端信息
	std::string m_strServIp; //服务端ip
	int m_iServPort;		 //服务端端口
	std::string m_strUsername;  //用户名
	std::string m_strPassword;  //密码

	std::string m_strEndpointType;

	FCL_THREAD_HANDLE m_hThread;
	bool m_bExitThread;

	const static  int MAX_BUF_LEN = 1024*128;
	//网络接收缓冲
	char m_szRecvBuf[MAX_BUF_LEN];
	int m_iRecvIndex; //接收缓冲索引

	FCL_THREAD_HANDLE m_hWorkThread;

	static unsigned int s_ui_RequestId; 

	HttpParseStatus m_emParseStatus;

	HttpMessage m_curMsg;
	char *m_pContent;
	int m_iContentWriteIndex;

	//加密
	std::string m_strRealm;
	std::string m_strRandom;

	unsigned char m_ucMac[6];
	unsigned char m_ucModuleId;

private:
	std::list<SendPacket*> _lstSend;   //发送缓冲
	CMutexThreadRecursive m_senLock;

	HttpQueryReq m_curReq;
	std::string m_strAuthorization;

};
