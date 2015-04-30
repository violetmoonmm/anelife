#ifndef DvrGeneral_h
#define DvrGeneral_h

#include "Platform.h"
#include <string>
#include <list>
#include "DvipMsg.h"
#include "MuteX.h"
#include "DvrApi.h"
#include "MultiCast.h"

class CDvrClient;

class CDvrGeneral
{
public:
    CDvrGeneral();
    ~CDvrGeneral();
    
    static CDvrGeneral *Instance();
    
    ////////////////////外部接口///////////////////////
    void SetDisConnectCb(fOnDisConnect pFcb,void *pUser)
    {
        m_cbOnDisConnect = pFcb;
        m_pUser = pUser;
    }
    void SetDisConnectCbEx(fOnDisConnectEx pFcb,void *pUser)
    {
        m_cbOnDisConnectEx = pFcb;
        m_pUserEx = pUser;
    }
    void SetEventNotifyCb(fOnEventNotify pFcb,void *pUser)
    {
        m_cbOnEventNotify = pFcb;
        m_pEventNotifyUser = pUser;
    }
    void SetAlarmNotifyCb(fOnAlarmNotify pFcb,void *pUser)
    {
        m_cbOnAlarmNotify = pFcb;
        m_pAlarmNotifyUser = pUser;
    }
    void SetAutoReconnect(bool bAuto)
    {
        m_bAutoReConnect = bAuto;
    }
    
    CDvrClient * CreateInstance();
    int ReleaseInstance(unsigned int uiLoginId);
    
    CDvrClient * FindInstance(unsigned int uiLoginId);
    CDvrClient * FindRealPlayInstance(unsigned int uiRealHandle);
    
    //开启组播
    bool MCast_start(fOnIPSearch pFcb,void *pUser);
    //停止组播
    bool MCast_stop(void);
    //搜索
    bool MCast_search(char *szMac);
    
private:
    std::list<CDvrClient*> m_lstInst;
    
    // 网络连接断开回调
    fOnDisConnect m_cbOnDisConnect;
    void *m_pUser;
    
    fOnDisConnectEx	m_cbOnDisConnectEx;
    void * m_pUserEx;
    
    //订阅信息
    // 状态变化回调函数原形
    fOnEventNotify m_cbOnEventNotify;
    void *m_pEventNotifyUser;
    
    //报警通知
    fOnAlarmNotify m_cbOnAlarmNotify;
    void *m_pAlarmNotifyUser;
    
    bool m_bAutoReConnect;
    
    CMultiCastClient m_mcast;
    bool m_bCast;
};

#endif