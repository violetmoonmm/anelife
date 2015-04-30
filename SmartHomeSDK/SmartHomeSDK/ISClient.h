#pragma once
#include "BaseClient.h"
#include "CommonDefine.h"

typedef struct _AuthInfo
{
    int iAuthStatus;	//0:Œ¥»œ÷§£¨1£∫»œ÷§÷–£¨2: »œ÷§≥…π¶
    
    bool bHasAuthCode;
    char szAuthCode[256];	// ⁄»®¬Î
    
    char szAuthorization[1024];	//»œ÷§Õ∑
    
    int iFailedTimes;
}AuthInfo;

class RemoteGateWay
{
public:
    RemoteGateWay()
    {
        memset(&gwInfo,0,sizeof(GatewayInfo));
        memset(&authInfo,0,sizeof(AuthInfo));
        
        nError = 0;
        
        bHasSubscribe = false;
        llLastSubscribeTime = GetCurrentTimeMs();
    }
    
public:
    GatewayInfo gwInfo;//Õ¯πÿª˘±æ–≈œ¢
    AuthInfo authInfo;//»œ÷§–≈œ¢
    
    bool bRemoteOnline;
    int nError;
    
    bool bHasSubscribe;		// «∑Ò“—∂©‘ƒ
    long long llLastSubscribeTime; //…œ¥Œ∂©‘ƒ ±º‰ ms
};

typedef struct _LastMsg
{
    std::string strGwVCode;
    std::string strMethod;
    std::string strContent;
}LastMsg;

class CISClient: public CBaseClient
{
public:
    CISClient(void);
    ~CISClient(void);
    
    enum HttpParseStatus
    {
        emStageIdle,
        emStageHeader,
        emStageContent,
    };
    
    void SetLocalVcode(const std::string &strVcode)
    {
        m_strVcodeLocal = strVcode;
        INFO_TRACE("m_strVcodeLocal="<<m_strVcodeLocal);
    }
    void SetServerInfo(const std::string &strServIp,unsigned short usServPort,const std::string &strServVcode)
    {
        m_strServIp = strServIp;
        m_iServPort = usServPort;
        m_strVcodePeer = strServVcode;
    }
    
    void SetPassword(const std::string &strPassword)
    {
        m_strPassword = strPassword;
    }
    
    int DvipSend(unsigned int id,char *pszMethod, char * pContent,int iContentLength,std::string strGwVCode="",bool bDvip=false);
    
    int Login(int waittime);
    int Logout();
    void AutoReconnect();
    int KeepAlive();
    
    void OnDisconnect(int iReason);
    int OnDealData();
    
    int GetIPC(std::string &strConfig,std::string strGwVCode);
    
    //∂©‘ƒ
    int Subscrible(std::string strGwVCode);
    //»°œ˚∂©‘ƒ
    int Unsubscrible(std::string strGwVCode);
    
    //—È÷§ ⁄»®¬Î
    int VerifyAuthCode(const char *sPhoneNumber,const char *sMeid,const char *sAuthCode,std::string strGwVCode="");
    
    int Dvip_Touch(std::string strGwVCode);
    
    //∆Ù∂Ø¥¶¿Ìœﬂ≥Ã
    int StartSubThread();
    //Ω· ¯¥¶¿Ìœﬂ≥Ã
    int StopSubThread();
    
public:
    int AddGateway(GatewayInfo gwInfo);
    int DelGateway(GatewayInfo gwInfo);
    void ClearGateway();
    void TryTouchGateway();
    
    int GwNum()
    {
        return m_lstGwObj.size();
    }
    
    std::list<RemoteGateWay*> ListObj();
    
    void Reconnect();
    
    bool SetSubscribe(std::string strGwVCode,bool bHasSubscribe,long long llLastSubscribeTime);
    
    bool GetAuthCode(std::string strGwVCode,int & iAuthStatus,int & iFailedTimes,std::string & strAuthCode);
    bool SetAuthCode(std::string strGwVCode,std::string strAuthCode);
    bool SetAuthStatus(std::string strGwVCode,int iAuthStatus);
    bool SetAuthorization(std::string strGwVCode,std::string strAuth);
    bool GetAuthorization(std::string strGwVCode,int & iAuthStatus,std::string & strAuthorization);
    void ClearAuthorization();
    bool AuthOK(std::string strGwVCode,bool bEnable);
    bool IsAuthed(std::string strGwVCode);
    
    int SetGwLogin(std::string strGwVCode,bool bOnline,int nError);
    bool IsGwLogin(std::string strGwVCode,int & nError);
    
    int CacheMsg(LastMsg msg);
    bool FetchMsg(std::string strGwVCode,LastMsg & msg);
    int ClearCacheMsg();
    
private:
    //unsigned int MakeReqId();
    unsigned int MakeUserId();
    std::string MakeSessionId();
    std::string MakeTags(unsigned int uiReqId);
    
#ifdef WIN32
    static unsigned long __stdcall SubProc(void *pParam);
#else
    static void* SubProc(void *pParam);
#endif
    void SubProc(void);//∂©‘ƒœﬂ≥Ã
    
    int Login_Sync();
    int UnRegister();
    
    //∑¢ÀÕ◊¢≤·«Î«Û
    int RegisterReq();
    //∑¢ÀÕ◊¢≤·«Î«Û
    int RegisterReq(const std::string &strAuth);
    // ’µΩ◊¢≤·ªÿ”¶
    int OnRegisterRsp(HttpMessage &msg,const char *pContent,int iContentLength);
    // ’µΩ◊¢œ˙ªÿ”¶
    int OnUnRegisterRsp(HttpMessage &msg,const char *pContent,int iContentLength);
    
    // ’µΩ±£ªÓªÿ”¶
    int OnKeepAliveRsp(HttpMessage &msg,const char *pContent,int iContentLength);
    // ¬º˛Õ®÷™
    int OnNotifyReq(HttpMessage &msg,const char *pContent,int iContentLength);
    
    // ’µΩdvipªÿ”¶
    int OnDvipMethodRsp(HttpMessage &msg,const char *pContent,int iContentLength);
    
    int OnHttpMsg(HttpMessage &msg,const char *pContent,int iContentLength);
    
    // ’µΩ∆’Õ®œ˚œ¢
    int OnRecvMsg(HttpMessage &msg,const char *pContent,int iContentLength);
    
    void OnDisConnected(int iReason);
    
public:
    FCL_THREAD_HANDLE m_hSubThread;
    bool m_bSubExitThread;
    
private:
    HttpParseStatus m_emParseStatus;
    
    HttpMessage m_curMsg;
    char *m_pContent;
    int m_iContentWriteIndex;
    
    //–È∫≈
    std::string m_strVcodeLocal;
    std::string m_strVcodePeer;
    
    bool m_bUnregister;
    
    //º”√‹
    std::string m_strRealm;
    std::string m_strRandom;
    
    std::string m_strEndpointType;
    
    unsigned char m_ucMac[6];
    unsigned char m_ucModuleId;
    
    const static long long GS_SUBSCRIBE_INTERVAL = 5*60*1000;	//∂©‘ƒº‰∏Ù 5∑÷÷”
    
    CMutexThreadRecursive m_lockGwObj;
    std::list<RemoteGateWay*> m_lstGwObj;
    
    CMutexThreadRecursive m_lockLastMsg;
    std::list<LastMsg> m_lstLastMsg;
};
