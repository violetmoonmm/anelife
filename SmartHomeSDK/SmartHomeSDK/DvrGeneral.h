#ifndef DvrGeneral_h
#define DvrGeneral_h

#include "Platform.h"
#include <string>
#include <list>
#include "MuteX.h"
#include "ShApi.h"
#include "BaseClient.h"
#include "MultiCast.h"

class CDvipClient;
class CISClient;

typedef struct
{
    unsigned int hLoginId;
    GatewayInfo gwInfo;
}GatewayObj;

class CDvrGeneral
{
public:
    CDvrGeneral();
    ~CDvrGeneral();
    
    static CDvrGeneral * s_instance;
    
    static CDvrGeneral *Instance();
    static  int  UnIstance()
    {
        if(s_instance != NULL)
        {
            delete s_instance;
            s_instance = NULL;
        }
        return 1;
    }
    
    ////////////////////外部接口///////////////////////
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
    
    unsigned int CreateLoginId()
    {
        unsigned int uiLoginId = ++s_ui_LoginId;
        if ( uiLoginId == 0 )
        {
            uiLoginId = ++s_ui_LoginId;
        }
        return uiLoginId;
    }
    
    unsigned int GetLoginId(std::string strGwVCode);
    int GetGatewayInfo(unsigned int uiLoginId,GatewayInfo & info);
    bool IsLocalLogin(std::string strGwVCode,int & nError);
    
    //平台转发使能
    bool EnableRemote(bool bEnable);
    
    unsigned int CreateInstance(GatewayInfo gwInfo);
    bool ReleaseInstance(unsigned int hLoginID);
    CBaseClient * FindInstance(unsigned int hLoginID,std::string & strGwCode);
    
    void ManuelReconnect();
    
    bool AuthCode(unsigned int hLoginID,std::string strAuthCode);
    
    //设置客户端信息
    void SetClientInfo(char * szVCode,char *szPwd,char*szPhoneNo,char *szMeid,const char* szModel);
    void SetServerInfo(char * szServerVCode,char * szServerIp,int iPort);
    
    const char* MEID()
    {
        return (const char*)m_strMeid.c_str();
    }
    
    const char* PhoneNo()
    {
        return (const char*)m_strPhoneNo.c_str();
    }
    
    const char* Model()
    {
        return (const char*)m_strModel.c_str();
    }
    
    bool GateWayStatus(unsigned int hLoginID,bool & bLocal,int & nLocalError,
                       bool & bRemote,int & nRemoteError);
    
    //开启组播
    bool MCast_start(fOnIPSearch pFcb,void *pUser);
    //停止组播
    bool MCast_stop(void);
    //搜索
    bool MCast_search(char *szMac,bool bGateWayOnly);
    
private:
    std::list<GatewayObj> m_lstGateway;
    
    std::list<CDvipClient*> m_lstInst;
    
    bool m_bRemote;
    CISClient  *m_pRemoteInst;
    
    // 网络连接断开回调
    fOnDisConnect m_cbOnDisConnect;
    void *m_pUser;
    
    //订阅信息
    // 状态变化回调函数原形
    fOnEventNotify m_cbOnEventNotify;
    void *m_pEventNotifyUser;
    
    //本端信息
    std::string m_strVcodeLocal;
    std::string m_strMeid;
    std::string m_strPwd;
    std::string m_strPhoneNo;
    std::string m_strModel;
    
    static unsigned int s_ui_LoginId; 
    
    CMultiCastClient m_mcast;
    bool m_bCast;
};

#endif
