#pragma once

#include "Platform.h"
#include <string>
#include <map>
#include <vector>
#include "MuteX.h"
#include "CommonDefine.h"
#include "Trace.h"
#include "DvipMsg.h"
#include "json.h"
#include "ShApi.h"

#include "MD5Inc.h"
#include "aes.h"


typedef struct _EventInfo
{
    std::string Code;
    int Index;
    std::string Action;
    int UTC;
    int EventID;
    std::string SourceDevice;
}EventInfo;

typedef struct _FileProcessInfo
{
    bool bSOF;
    bool bEOF;
    int Channel;
    int Length;
    
    std::string Time;
    std::string FilePath;
    std::string FTPPath;
    
    EventInfo _event;
}FileProcessInfo;

class SendPacket
{
public:
    SendPacket()
    {
        _buf = 0;
        _bufSize = 0;
        _sendIndex = 0;
    }
    SendPacket(char *&buf,int len)
    {
        _buf = buf;
        _bufSize = len;
        _sendIndex = 0;
    }
    ~SendPacket()
    {
        if ( _buf )
        {
            delete []_buf;
            _buf = 0;
        }
    }
    char *_buf;
    int _bufSize;
    int _sendIndex;
};

class CBaseClient
{
public:
    
    enum EmStatus
    {
        emNone,
        emIdle,
        emRegistering,
        emRegistered,
        emUnRegistered
    };
    
    CBaseClient(void);
    virtual ~CBaseClient(void);
    
    int Start();
    int Stop();
    int Connect(char *pszIp,int iPort); //连接
    void Close();//关闭连接
    
    bool IsConnected()
    {
        return (m_nConnStatus==2)?true:false;
    }
    
    void SetDisConnectCb(fOnDisConnect pFcb,void *pUser)
    {
        m_cbOnDisConnect = pFcb;
        m_pUser = pUser;
    }
    
    void SetEventNotifyCb(fOnEventNotify pFcb,void *pUser)
    {
        m_cbOnEventNotify = pFcb;
        m_pEventNotifyUser = pUser;
    }
    
    virtual int Login(int waittime)=0;
    virtual int Logout()=0;
    virtual void AutoReconnect()=0;
    //保活请求
    virtual int KeepAlive()=0;
    virtual int OnDealData();
    virtual int DvipSend(unsigned int id,char *pszMethod, char * pContent,int iContentLength,std::string strGwVCode="",bool bDvip=false)=0;
    virtual void OnDisconnect(int iReason) = 0;
    //验证授权码
    virtual int VerifyAuthCode(const char *sPhoneNumber,const char *sMeid,const char *sAuthCode,std::string strGwVCode="")=0;
    //读取IPC列表
    virtual int GetIPC(std::string &strConfig,std::string strGwVCode="")=0;
    
    int SendData(char *pData,int iDataLen); //发送数据
    
    void OnRegisterSuccess(int iReason);
    void OnRegisterFailed(int iReason);
    //保活超时或recv失败
    void OnTcpDisconnect(int iReason);
    
    //获取授权码
    int GetAuthCode(const char* sSn,const char *sPhoneNumber,const char *sMeid,const char* sModel,const char *sUsername,const char *sPasswrod,
                    char *buffer,int buflen,std::string strGwVCode="");
    
    //读取配置 特定配置
    int GetConfig(const std::string &strName,std::string &strConfig,std::string strGwVCode="");
    
    //设置配置信息
    int SetConfig(std::string strName,Json::Value jsonConfig,std::string strGwVCode="");
    
    //智能家居控制
    int Control(char * pszDevType,char *pszDeviceId,char *pszParams,int iParamsLen,std::string strGwVCode="");
    //智能家居设备状态查询
    int GetState(char * pszDevType,char *pszDeviceId,
                 char *szBuf,int iBufSize,std::string strGwVCode="");
    
    //智能家居设备状态查询
    int ReadDevice(char * pszDevType,char *pszDeviceId,
                   char *pszParams,char *szBuf,int iBufSize,std::string strGwVCode="");
    
    //设置情景模式
    int SetSceneMode(std::string &strMode,std::string strGwVCode="");
    
    // 布撤防
    int SetArmMode(const char *pszDeviceId,bool bEnable,const char *password,std::string strGwVCode="");
    // 取得报警防区状态
    int GetArmMode(char *pszDeviceId,bool & bEnable,std::string strGwVCode="");
    
    // 视频遮挡配置
    int GetVideoCovers(char *pszDeviceId,bool &bEnable,std::string strGwVCode="");
    int SetVideoCovers(char *pszDeviceId,bool bEnable,std::string strGwVCode="");
    int SetExtraBitrate(char *pszDeviceId,int iBitRate,std::string strGwVCode="");
    
    int RemoteOpenDoor(char *pszShortNumber,std::string strGwVCode="");
    
    int ShareManager_browseDir(std::string & strShareList,std::string strGwVCode="");
    int ShareManager_downloadFile(char * pszShareFile,char *pszLocalPath,std::string strGwVCode="");
    
    int AuthManager_getAuthList(std::string & strAuthList,std::string strGwVCode="");
    int AuthManager_delAuth(char *pszPhone,char* pszMeid,std::string strGwVCode="");
    
    //magicbox
    int MagicBox_Control(std::string strAction,std::string & strOutParams,std::string strGwVCode="");
    
    //探测网关状态
    int TouchGateway(std::string strGwVCode="");
    
    //获取设备列表信息摘要
    int GetDeviceDigest_Sync(std::string &strType,std::string &strDigest,std::string strGwVCode="");
    
    //获取设备列表
    int GetDeviceList_Sync(std::string &strType,std::string &strDevices,std::string strGwVCode="");
    
    int general_control(char *pszDeviceId,char *pszDeviceType,
                        char * pszAction,Json::Value jsonInParams,std::string strGwVCode="");
    
public:
    bool IsLogin()
    {
        return (m_emStatus==emRegistered)?true:false;
    }
    
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
    
    //请求类型
    enum EmRequestType
    {
        emRT_Unknown,		//未知类型
        
        
        emRT_method_v_b_v,	//通用方法 void call(void)
        emRT_method_json_b_json,	//通用方法 bool call([IN] json,[OUT] json)
        
        emRT_instance,		//获取实例
        emRT_destroy,		//销毁实例
        
        emRT_getConfig,		//获取配置
        emRT_setConfig,		//设置配置
        
        emRT_Login,			//登录请求
        emRT_Keepalive,		//保活请求
        emRT_Logout,		//登出请求
        
    };
    
    struct TransInfo
    {
        enum EmTaskStatus
        {
            emTaskStatus_Failed = -1001,
            emTaskStatus_Timeout = -1002,
            emTaskStatus_Cancel = -1003,
            
            emTaskStatus_Idle = 0,
            emTaskStatus_Success,
            
        };
        EmRequestType type;
        unsigned int seq;
        long long	start; //任务发起时间
        unsigned int timeout; //超时时间
        std::string m_strTags;
        int result;
        CDvipMsg *pRspMsg;
        CEventThread hEvent;
        
        TransInfo()
        {
            type = emRT_Unknown;
            seq = 0;
            start = 0;
            timeout = 5000;
            result = emTaskStatus_Idle;
            pRspMsg = 0;
        }
        TransInfo(unsigned int id,long long llBegin,unsigned int uiTimeout=5000)
        {
            type = emRT_Unknown;
            seq = id;
            start = llBegin;
            timeout = uiTimeout;
            result = emTaskStatus_Idle;
            pRspMsg = 0;
        }
        TransInfo(unsigned int id,EmRequestType tp,long long llBegin,unsigned int uiTimeout=5000)
        {
            type = tp;
            seq = id;
            start = llBegin;
            timeout = uiTimeout;
            result = emTaskStatus_Idle;
            pRspMsg = 0;
        }
        ~TransInfo()
        {
        }
        bool IsTimeOut()
        {
            return ( _abs64(GetCurrentTimeMs()-start) >= timeout ) ? true : false;
        }
    };
    //请求列表
    typedef std::map<unsigned int,TransInfo*> RequestList;
    RequestList m_reqList;
    CMutexThreadRecursive m_lockReqList;
    void AddRequest(unsigned int uiReq,TransInfo *trans)
    {
        if (trans->type > 9 || trans->type < 0)
        {
            INFO_TRACE("invalid request");
        }
        CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
        //INFO_TRACE("add seq "<<uiReq<<" type "<<trans->type);
        m_reqList[uiReq] = trans;
    }
    TransInfo * FindRequest(unsigned int uiReq)
    {
        CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
        RequestList::iterator it = m_reqList.find(uiReq);
        if ( m_reqList.end() == it )
        {
            return NULL;
        }
        return it->second;
    }
    TransInfo * FetchRequest(unsigned int uiReq) //从列表中取出
    {
        CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
        TransInfo *pTrans = NULL;
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
        //INFO_TRACE("remove seq "<<uiReq);
        TransInfo *pTrans = it->second;
        m_reqList.erase(it);
        return 1;
    }
    
    
private:
    /////////线程处理////////////
#ifdef WIN32
    static unsigned long __stdcall ThreadProc(void *pParam);
    static unsigned long __stdcall ThreadRun(void *pParam);
#else
    static void* ThreadProc(void *pParam);
    static void* ThreadRun(void *pParam);
#endif
    void ThreadProc(void);//数据接收线程
    void ThreadRun(void);//工作线程
    
    void Thread_Process();
    void Thread_Run();
    
    //启动处理线程
    int StartThread();
    //结束处理线程
    int StopThread();
    
    void OnConnect(int iConnStatus); //连接成功通知
    void OnDataRecv(); //接收数据通知
    void OnDataSend(); //可以发送数据通知
    
public:
    //创建对象实例 全局实例
    int Dvip_instance(char *pszMethod,unsigned &uiObject,int iTimeout=5000,std::string strGwVCode="");
    //创建对象实例 通过设备id
    int Dvip_instance(char *pszMethod,char *pszDeviceId,unsigned &uiObject,int iTimeout=5000,std::string strGwVCode="");
    //创建对象实例 全局实例
    int Dvip_instance(char *pszMethod,const Json::Value &jsParams,unsigned &uiObject,int iTimeout=5000,std::string strGwVCode="");
    //释放实例
    int Dvip_destroy(char *pszMethod,unsigned uiObject,int iTimeout=5000,std::string strGwVCode="");
    
    //调用方法 输入输出参数为空,方法返回值为bool 一般函数原型 bool call(void)
    int Dvip_method_v_b_v(char *pszMethod,unsigned uiObject,bool &bResult,int iTimeout=5000,std::string strGwVCode="");
    
    //调用方法 输入输出参数为空,方法返回值为bool 一般函数原型 bool call(void) 不等待回复
    int Dvip_method_v_b_v_no_rsp(char *pszMethod,unsigned uiObject,bool &bResult,int iTimeout=5000,std::string strGwVCode="");
    
    //调用方法 输入参数为json(params : {}),输出参数也为json(params : {}),方法返回值为bool 一般函数原型 bool call(void)
    int Dvip_method_json_b_json(char *pszMethod,unsigned uiObject,Json::Value &inParams,bool &bResult,Json::Value &outParams,int iTimeout=5000,std::string strGwVCode="");
    
    CDvipMsg *CreateMsg(EmRequestType emType);
    
    //收到通知消息
    void OnNotification(unsigned int uiLoginId,dvip_hdr &hdr,const char *pData,int pDataLen);
    
    //收到分包数据
    int OnPackage(unsigned int uiLoginId,dvip_hdr &hdr,const char *pData,int pDataLen);
    
    //任务处理
    void Process_Task();
    //断线退出清理事务
    void Clear_Tasks();
    
    void ClearSend();//清空发送缓冲
    
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
    
    bool m_bAutoConnect;
    
    // 网络连接断开回调
    fOnDisConnect m_cbOnDisConnect;
    void *m_pUser;
    
    //订阅信息
    // 状态变化回调函数原形
    fOnEventNotify m_cbOnEventNotify;
    void *m_pEventNotifyUser;
    
    FCL_THREAD_HANDLE m_hThread;
    bool m_bExitThread;
    
    const static  int MAX_BUF_LEN = 1024*128;
    //网络接收缓冲
    char m_szRecvBuf[MAX_BUF_LEN];
    int m_iRecvIndex; //接收缓冲索引
    
    FCL_THREAD_HANDLE m_hWorkThread;
    
    static unsigned int s_ui_RequestId; 
    unsigned int m_uiSessionId; //登录会话id
    
    //const static  int MAX_FILE_LEN = 1024*128;
    //char m_filebuffer[MAX_FILE_LEN];
    //int m_filelength;
    
    unsigned int m_uiDownReqId;
    unsigned int m_bSinglePack;
    std::string m_strShareFile;
    std::string m_strLocalPath;
    int m_pos;
    int m_packet_index;
    
    const static unsigned int GS_RECONNECT_INTEVAL = 15000;		//重连间隔
    const static long long GS_HEARTBEAT_INTERVAL = 15*1000;
    const static long long GS_MAX_HEARTBEAT_TIMEOUT = 60000;
    
    //本地连接
    unsigned int m_uiLoginId;
    unsigned int m_uiSid;
    
    //保活
    int m_iRegFailedTimes; //连续失败次数
    long long m_llLastTime;	//上次保活成功时间
    long long m_llLastHeartbeatTime; //上次发送保活时间 只对客户端有用
    
private:
    std::list<SendPacket*> _lstSend;   //发送缓冲
    CMutexThreadRecursive m_senLock;
};

void HexToBinary(char *dst, const char *src);
void BinaryToHex(char *dst, const char *src, int srclen);
