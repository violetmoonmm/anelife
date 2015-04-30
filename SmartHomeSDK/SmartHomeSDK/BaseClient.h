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
    int Connect(char *pszIp,int iPort); //����
    void Close();//�ر�����
    
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
    //��������
    virtual int KeepAlive()=0;
    virtual int OnDealData();
    virtual int DvipSend(unsigned int id,char *pszMethod, char * pContent,int iContentLength,std::string strGwVCode="",bool bDvip=false)=0;
    virtual void OnDisconnect(int iReason) = 0;
    //��֤��Ȩ��
    virtual int VerifyAuthCode(const char *sPhoneNumber,const char *sMeid,const char *sAuthCode,std::string strGwVCode="")=0;
    //��ȡIPC�б�
    virtual int GetIPC(std::string &strConfig,std::string strGwVCode="")=0;
    
    int SendData(char *pData,int iDataLen); //��������
    
    void OnRegisterSuccess(int iReason);
    void OnRegisterFailed(int iReason);
    //���ʱ��recvʧ��
    void OnTcpDisconnect(int iReason);
    
    //��ȡ��Ȩ��
    int GetAuthCode(const char* sSn,const char *sPhoneNumber,const char *sMeid,const char* sModel,const char *sUsername,const char *sPasswrod,
                    char *buffer,int buflen,std::string strGwVCode="");
    
    //��ȡ���� �ض�����
    int GetConfig(const std::string &strName,std::string &strConfig,std::string strGwVCode="");
    
    //����������Ϣ
    int SetConfig(std::string strName,Json::Value jsonConfig,std::string strGwVCode="");
    
    //���ܼҾӿ���
    int Control(char * pszDevType,char *pszDeviceId,char *pszParams,int iParamsLen,std::string strGwVCode="");
    //���ܼҾ��豸״̬��ѯ
    int GetState(char * pszDevType,char *pszDeviceId,
                 char *szBuf,int iBufSize,std::string strGwVCode="");
    
    //���ܼҾ��豸״̬��ѯ
    int ReadDevice(char * pszDevType,char *pszDeviceId,
                   char *pszParams,char *szBuf,int iBufSize,std::string strGwVCode="");
    
    //�����龰ģʽ
    int SetSceneMode(std::string &strMode,std::string strGwVCode="");
    
    // ������
    int SetArmMode(const char *pszDeviceId,bool bEnable,const char *password,std::string strGwVCode="");
    // ȡ�ñ�������״̬
    int GetArmMode(char *pszDeviceId,bool & bEnable,std::string strGwVCode="");
    
    // ��Ƶ�ڵ�����
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
    
    //̽������״̬
    int TouchGateway(std::string strGwVCode="");
    
    //��ȡ�豸�б���ϢժҪ
    int GetDeviceDigest_Sync(std::string &strType,std::string &strDigest,std::string strGwVCode="");
    
    //��ȡ�豸�б�
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
    
    //��������
    enum EmRequestType
    {
        emRT_Unknown,		//δ֪����
        
        
        emRT_method_v_b_v,	//ͨ�÷��� void call(void)
        emRT_method_json_b_json,	//ͨ�÷��� bool call([IN] json,[OUT] json)
        
        emRT_instance,		//��ȡʵ��
        emRT_destroy,		//����ʵ��
        
        emRT_getConfig,		//��ȡ����
        emRT_setConfig,		//��������
        
        emRT_Login,			//��¼����
        emRT_Keepalive,		//��������
        emRT_Logout,		//�ǳ�����
        
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
        long long	start; //������ʱ��
        unsigned int timeout; //��ʱʱ��
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
    //�����б�
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
    TransInfo * FetchRequest(unsigned int uiReq) //���б���ȡ��
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
    /////////�̴߳���////////////
#ifdef WIN32
    static unsigned long __stdcall ThreadProc(void *pParam);
    static unsigned long __stdcall ThreadRun(void *pParam);
#else
    static void* ThreadProc(void *pParam);
    static void* ThreadRun(void *pParam);
#endif
    void ThreadProc(void);//���ݽ����߳�
    void ThreadRun(void);//�����߳�
    
    void Thread_Process();
    void Thread_Run();
    
    //���������߳�
    int StartThread();
    //���������߳�
    int StopThread();
    
    void OnConnect(int iConnStatus); //���ӳɹ�֪ͨ
    void OnDataRecv(); //��������֪ͨ
    void OnDataSend(); //���Է�������֪ͨ
    
public:
    //��������ʵ�� ȫ��ʵ��
    int Dvip_instance(char *pszMethod,unsigned &uiObject,int iTimeout=5000,std::string strGwVCode="");
    //��������ʵ�� ͨ���豸id
    int Dvip_instance(char *pszMethod,char *pszDeviceId,unsigned &uiObject,int iTimeout=5000,std::string strGwVCode="");
    //��������ʵ�� ȫ��ʵ��
    int Dvip_instance(char *pszMethod,const Json::Value &jsParams,unsigned &uiObject,int iTimeout=5000,std::string strGwVCode="");
    //�ͷ�ʵ��
    int Dvip_destroy(char *pszMethod,unsigned uiObject,int iTimeout=5000,std::string strGwVCode="");
    
    //���÷��� �����������Ϊ��,��������ֵΪbool һ�㺯��ԭ�� bool call(void)
    int Dvip_method_v_b_v(char *pszMethod,unsigned uiObject,bool &bResult,int iTimeout=5000,std::string strGwVCode="");
    
    //���÷��� �����������Ϊ��,��������ֵΪbool һ�㺯��ԭ�� bool call(void) ���ȴ��ظ�
    int Dvip_method_v_b_v_no_rsp(char *pszMethod,unsigned uiObject,bool &bResult,int iTimeout=5000,std::string strGwVCode="");
    
    //���÷��� �������Ϊjson(params : {}),�������ҲΪjson(params : {}),��������ֵΪbool һ�㺯��ԭ�� bool call(void)
    int Dvip_method_json_b_json(char *pszMethod,unsigned uiObject,Json::Value &inParams,bool &bResult,Json::Value &outParams,int iTimeout=5000,std::string strGwVCode="");
    
    CDvipMsg *CreateMsg(EmRequestType emType);
    
    //�յ�֪ͨ��Ϣ
    void OnNotification(unsigned int uiLoginId,dvip_hdr &hdr,const char *pData,int pDataLen);
    
    //�յ��ְ�����
    int OnPackage(unsigned int uiLoginId,dvip_hdr &hdr,const char *pData,int pDataLen);
    
    //������
    void Process_Task();
    //�����˳���������
    void Clear_Tasks();
    
    void ClearSend();//��շ��ͻ���
    
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
    
    bool m_bAutoConnect;
    
    // �������ӶϿ��ص�
    fOnDisConnect m_cbOnDisConnect;
    void *m_pUser;
    
    //������Ϣ
    // ״̬�仯�ص�����ԭ��
    fOnEventNotify m_cbOnEventNotify;
    void *m_pEventNotifyUser;
    
    FCL_THREAD_HANDLE m_hThread;
    bool m_bExitThread;
    
    const static  int MAX_BUF_LEN = 1024*128;
    //������ջ���
    char m_szRecvBuf[MAX_BUF_LEN];
    int m_iRecvIndex; //���ջ�������
    
    FCL_THREAD_HANDLE m_hWorkThread;
    
    static unsigned int s_ui_RequestId; 
    unsigned int m_uiSessionId; //��¼�Ựid
    
    //const static  int MAX_FILE_LEN = 1024*128;
    //char m_filebuffer[MAX_FILE_LEN];
    //int m_filelength;
    
    unsigned int m_uiDownReqId;
    unsigned int m_bSinglePack;
    std::string m_strShareFile;
    std::string m_strLocalPath;
    int m_pos;
    int m_packet_index;
    
    const static unsigned int GS_RECONNECT_INTEVAL = 15000;		//�������
    const static long long GS_HEARTBEAT_INTERVAL = 15*1000;
    const static long long GS_MAX_HEARTBEAT_TIMEOUT = 60000;
    
    //��������
    unsigned int m_uiLoginId;
    unsigned int m_uiSid;
    
    //����
    int m_iRegFailedTimes; //����ʧ�ܴ���
    long long m_llLastTime;	//�ϴα���ɹ�ʱ��
    long long m_llLastHeartbeatTime; //�ϴη��ͱ���ʱ�� ֻ�Կͻ�������
    
private:
    std::list<SendPacket*> _lstSend;   //���ͻ���
    CMutexThreadRecursive m_senLock;
};

void HexToBinary(char *dst, const char *src);
void BinaryToHex(char *dst, const char *src, int srclen);
