#pragma once
#include "Platform.h"
#include "Trace.h"
#include "DvipMsg.h"
#include "UtilFuncs.h"
#include "DvrApi.h"
#include "MuteX.h"


using namespace std;

struct dh2_hdr
{
    unsigned char cmd;
    unsigned char resv[3];
    unsigned int extlen;
    unsigned char data[24];
};

class CUserConn
{
public:
    CUserConn(unsigned int uiLoginId,std::string strServIp,int iServPort);
    ~CUserConn(void);
    
public:
    int Connect(fRealDataCallBack pCb,void * pUser);
    int Disconnect();
    
#ifdef WIN32
    static unsigned long __stdcall ThreadProc(void *pParam);
#else
    static void* ThreadProc(void *pParam);
#endif
    void ThreadProc(void);
    void Thread_Process();
    
    unsigned int LoginId()
    {
        return m_uiLoginId;
    }
    
    unsigned int login();
    void keepalive();
    
    int CreateDataConnect(unsigned long uiRealHandle);
    
    int StartRealPlay();
    int StopRealPlay();
    
    int StartAlarmListen();
    int StopAlarmListen();
private:
    
    //启动处理线程
    int StartThread();
    //结束处理线程
    int StopThread();
    
    int OnDealData(); //处理数据
    void OnDataPacket(const char *pData,int pDataLen);
    
    int SendData(char *pData,int iDataLen); //发送数据
public:
    CEventThread m_hEvent;
    int m_result;
    
    unsigned int m_uiLoginId;
    unsigned long m_uiRealHandle;
    
    bool m_bKeepAlive;
    long long m_llLastTime;
    
private:
    std::string m_strServIp;
    int m_iServPort;
    
    FCL_SOCKET m_sSock;
    FCL_THREAD_HANDLE m_hThread;
    bool m_bExitThread;
    const static  int MAX_DATA_LEN = 128*1024;
    //网络接收缓冲
    char m_szRecvBuf[MAX_DATA_LEN];
    int m_iRecvIndex; //接收缓冲索引
    
    fRealDataCallBack m_pCb;
    void * m_pUser;
};
