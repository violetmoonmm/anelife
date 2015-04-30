#include "DvrGeneral.h"
#include "DvipClient.h"
#include "ISClient.h"

unsigned int CDvrGeneral::s_ui_LoginId = 0;

CDvrGeneral * CDvrGeneral::s_instance = NULL;

#ifdef PLAT_WIN32
int InitWinSock()
{
    WSADATA wsaData;
    return WSAStartup(MAKEWORD(2,2),&wsaData);
}
int CleanupWinSock()
{
    return WSACleanup();
}
#endif

CDvrGeneral::CDvrGeneral()
{
    m_cbOnDisConnect = 0;
    m_pUser = 0;
    
    m_cbOnEventNotify = NULL;
    m_pEventNotifyUser = NULL;
    
#ifdef PLAT_WIN32
    InitWinSock();
#endif
    
    m_bRemote = false;
    m_pRemoteInst = NULL;
    
    m_bCast = false;
}
CDvrGeneral::~CDvrGeneral()
{
    INFO_TRACE("destroy sdk!");
    std::list<CDvipClient*>::iterator iter;
    CDvipClient *pInst = NULL;
    for(iter=m_lstInst.begin();iter!=m_lstInst.end();iter++)
    {
        pInst = *iter;
        if (pInst->IsLogin())
        {
            pInst->Logout();
        }
        
        delete pInst;
    }
    m_lstInst.clear();
    
    if (m_pRemoteInst)
    {
        if (m_pRemoteInst->IsLogin())
        {
            m_pRemoteInst->Logout();
        }
        delete m_pRemoteInst;
        m_pRemoteInst = NULL;
    }
    
#ifdef PLAT_WIN32
    CleanupWinSock();
#endif
}

CDvrGeneral *CDvrGeneral::Instance()
{
    if (s_instance == NULL)
    {
        s_instance = new CDvrGeneral();
    }
    return s_instance;
}

unsigned int CDvrGeneral::CreateInstance(GatewayInfo gwInfo)
{
    INFO_TRACE("sn="<<gwInfo.szSn<<" ip="<<gwInfo.szIp<<" port="<<gwInfo.iPort
               <<" user="<<gwInfo.szUser<<" pwd="<<gwInfo.szPwd<<" vcode="<<gwInfo.szGwVCode);
    
    if (!strcmp(gwInfo.szSn,""))
    {
        ERROR_TRACE("no sn!");
        return 0;
    }
    GatewayObj obj;
    memset(&obj,0,sizeof(GatewayObj));
    obj.gwInfo = gwInfo;
    obj.hLoginId = CreateLoginId();
    
    //建立本地连接
    
    CDvipClient* pInst = new CDvipClient();
    if ( pInst == NULL)
    {
        ERROR_TRACE("out of memory");
        return 0;
    }
    pInst->SetDisConnectCb(m_cbOnDisConnect,m_pUser);
    pInst->SetEventNotifyCb(m_cbOnEventNotify,m_pEventNotifyUser);
    pInst->SetGateway(obj.hLoginId ,gwInfo.szIp,gwInfo.iPort,
                      gwInfo.szUser,gwInfo.szPwd,gwInfo.szSn);
    pInst->Start();
    
    int iRet = pInst->Login(3000);
    if (iRet != 0)
    {
    }
    m_lstInst.push_back(pInst);
    
    if (m_bRemote)
    {
        if (m_pRemoteInst)
        {
            if (!m_pRemoteInst->IsLogin())
            {
                iRet = m_pRemoteInst->Login(10000);
                if (iRet == 0)//登陆成功，刷新网关状态
                {
                    m_pRemoteInst->TryTouchGateway();
                }
            }
            else
            {
                INFO_TRACE("remote connection exist.");
            }
            m_pRemoteInst->AddGateway(gwInfo);
        }
        else
        {
            WARN_TRACE("not find remote instance");
        }
    }
    
    m_lstGateway.push_back(obj);
    return obj.hLoginId;
}

//平台转发使能
bool CDvrGeneral::EnableRemote(bool bEnable)
{
    if (m_bRemote != bEnable)
    {
        if (!m_pRemoteInst)
        {
            ERROR_TRACE("not find remote instance!");
            return false;
        }
        std::list<GatewayObj>::iterator it;
        GatewayInfo gwInfo;
        bool found = false;
        for(it=m_lstGateway.begin();it!=m_lstGateway.end();it++)
        {
            gwInfo = it->gwInfo;
            if (m_bRemote)
            {
                m_pRemoteInst->DelGateway(gwInfo);
                if (m_pRemoteInst->GwNum() == 0)//无订阅
                {
                    m_pRemoteInst->StopSubThread();
                    int iRet = m_pRemoteInst->Logout();
                    if (iRet == 0)//登陆成功
                    {
                    }
                }
            }
            else
            {
                if (!m_pRemoteInst->IsLogin())
                {
                    int iRet = m_pRemoteInst->Login(10000);
                }
                else
                {
                    INFO_TRACE("remote connection exist.");
                }
                m_pRemoteInst->AddGateway(gwInfo);
            }
        }
    }
    m_bRemote = bEnable;
    
    return true;
}

bool CDvrGeneral::ReleaseInstance(unsigned int hLoginID)
{
    int iRet = 0;
    std::list<GatewayObj>::iterator it;
    GatewayInfo gwInfo;
    bool found = false;
    for(it=m_lstGateway.begin();it!=m_lstGateway.end();it++)
    {
        if ( it->hLoginId ==hLoginID )//找到网关对象
        {
            found = true;
            gwInfo = it->gwInfo;
            m_lstGateway.erase(it);
            break;
        }
    }
    
    if(!found)
    {
        ERROR_TRACE("invalid hLoginID="<<hLoginID);
        return false;
    }
    
    std::list<CDvipClient*>::iterator iter;
    found = false;
    CDvipClient *pInst = NULL;
    for(iter=m_lstInst.begin();iter!=m_lstInst.end();iter++)
    {
        pInst = *iter;
        if ( pInst && pInst->GetLoginId() ==hLoginID )
        {
            found = true;
            break;
        }
    }
    
    if (found)
    {
        if (pInst->IsLogin())
        {
            iRet = pInst->Logout();
            if (iRet == 0)//登陆成功
            {
                //INFO_TRACE("local connection close! ");
            }
        }
        
        delete pInst;
        m_lstInst.erase(iter);
    }
    
    if (m_bRemote)
    {
        if (!m_pRemoteInst)
        {
            ERROR_TRACE("not find remote instance!");
            return true;
        }
        
        m_pRemoteInst->DelGateway(gwInfo);
        if (m_pRemoteInst->GwNum() == 0)//无订阅
        {
            m_pRemoteInst->StopSubThread();
            iRet = m_pRemoteInst->Logout();
            if (iRet == 0)//登陆成功
            {
                //INFO_TRACE("remote connection close! ");
            }
        }
    }
    
    return true;
}

CBaseClient * CDvrGeneral::FindInstance(unsigned int hLoginID,std::string & strGwCode)
{
    strGwCode="";
    
    std::list<GatewayObj>::iterator it;
    bool found = false;
    for(it=m_lstGateway.begin();it!=m_lstGateway.end();it++)
    {
        if ( it->hLoginId == hLoginID )//找到网关对象
        {
            found = true;
            break;
        }
    }
    if(!found)
    {
        ERROR_TRACE("invalid hLoginID="<<hLoginID);
        return NULL;
    }
    
    found = false;
    CDvipClient *pInst = NULL;
    std::list<CDvipClient*>::iterator iter;
    for(iter=m_lstInst.begin();iter!=m_lstInst.end();iter++)
    {
        pInst = *iter;
        if ( pInst && pInst->GetLoginId() ==hLoginID )
        {
            found = true;
            break;
        }
    }
    if (!found)
    {
        ERROR_TRACE("no local inst found!");
        return NULL;
    }
    
    bool bViaRemote = false;
    if (m_pRemoteInst)
    {
        if (m_pRemoteInst->IsLogin() && !pInst->IsLogin())//本地不在线而远程在线
        {
            bViaRemote = true;
        }
    }
    else
    {
        WARN_TRACE("not find remote instance");
    }
    
    if (bViaRemote)
    {
        strGwCode = std::string(it->gwInfo.szGwVCode);
        INFO_TRACE("remote inst strGwCode="<<strGwCode);
        return (CBaseClient*)m_pRemoteInst;
    }
    else
    {
        if (pInst->IsLogin())
        {
            return (CBaseClient*)pInst;
        }
        else
        {
            ERROR_TRACE("local & remote offline. hLoginID="<<hLoginID);
            return NULL;
        }
    }
}

bool CDvrGeneral::AuthCode(unsigned int hLoginID,std::string strAuthCode)
{
    std::list<GatewayObj>::iterator it;
    bool found = false;
    for(it=m_lstGateway.begin();it!=m_lstGateway.end();it++)
    {
        if ( it->hLoginId == hLoginID )//找到网关对象
        {
            found = true;
            break;
        }
    }
    if(!found)
    {
        ERROR_TRACE("invalid hLoginID="<<hLoginID);
        return false;
    }
    
    CDvipClient *pInst = NULL;
    std::list<CDvipClient*>::iterator iter;
    for(iter=m_lstInst.begin();iter!=m_lstInst.end();iter++)
    {
        pInst = *iter;
        if ( pInst && pInst->GetLoginId() ==hLoginID )
        {
            pInst->AuthCode(strAuthCode);
            break;
        }
    }
    if (!found)
    {
        ERROR_TRACE("not find local inst!");
        return false;
    }
    
    if (m_pRemoteInst)
    {
        m_pRemoteInst->SetAuthCode(std::string(it->gwInfo.szGwVCode),strAuthCode);
    }
    
    return true;
}

void CDvrGeneral::SetClientInfo(char * szVCode,char *szPwd,char*szPhoneNo,char *szMeid,const char* szModel)
{
    m_strVcodeLocal = std::string(szVCode);
    m_strMeid = std::string(szMeid);
    m_strPwd = std::string(szPwd);
    m_strPhoneNo = std::string(szPhoneNo);
    m_strModel = std::string(szModel);
}

void CDvrGeneral::SetServerInfo(char * szServerVCode,char * szServerIp,int iPort)
{
    if (m_pRemoteInst)
    {
        INFO_TRACE("remote instance exist! logout it");
        m_pRemoteInst->Logout();
        m_pRemoteInst->Stop();
        delete m_pRemoteInst;
        m_pRemoteInst = NULL;
    }
    
    m_pRemoteInst = new CISClient();
    if ( NULL == m_pRemoteInst )
    {
        ERROR_TRACE("out of memory.");
        return;
    }
    
    //初始化参数
    std::string strVCode = m_strVcodeLocal+";meid="+m_strMeid;
    m_pRemoteInst->SetLocalVcode(strVCode);
    m_pRemoteInst->SetServerInfo(std::string(szServerIp),iPort,std::string(szServerVCode));
    m_pRemoteInst->SetPassword(m_strPwd);
    m_pRemoteInst->SetDisConnectCb(m_cbOnDisConnect,m_pUser);
    m_pRemoteInst->SetEventNotifyCb(m_cbOnEventNotify,m_pEventNotifyUser);
    m_pRemoteInst->Start();
    
    m_bRemote = true;
}

bool CDvrGeneral::GateWayStatus(unsigned int hLoginID,bool & bLocal,int & nLocalError,
                                bool & bRemote,int & nRemoteError)
{
    int iRet = 0;
    bLocal = false;
    bRemote = false;
    nLocalError = 0;
    nRemoteError = 0;
    std::list<GatewayObj>::iterator it;
    GatewayInfo gwInfo;
    bool found = false;
    for(it=m_lstGateway.begin();it!=m_lstGateway.end();it++)
    {
        if ( it->hLoginId ==hLoginID )//找到网关对象
        {
            found = true;
            gwInfo = it->gwInfo;
            break;
        }
    }
    
    if(!found)
    {
        ERROR_TRACE("invalid hLoginID="<<hLoginID);
        return false;
    }
    
    bLocal = IsLocalLogin(std::string(gwInfo.szGwVCode),nLocalError);
    
    if (m_bRemote && m_pRemoteInst)
    {
        bRemote = m_pRemoteInst->IsGwLogin(std::string(gwInfo.szGwVCode),nRemoteError);
    }
    
    INFO_TRACE("GateWayStatus: hLoginID="<<hLoginID<<" local="<<bLocal<<":"<<nLocalError<<" remote="<<bRemote<<":"<<nRemoteError);
    
    return true;
}


unsigned int CDvrGeneral::GetLoginId(std::string strGwVCode)
{
    unsigned int uiLoginId = 0;
    std::list<GatewayObj>::iterator it;
    for(it=m_lstGateway.begin();it!=m_lstGateway.end();it++)
    {
        if ( !strcmp(it->gwInfo.szGwVCode,(char*)strGwVCode.c_str()) )//找到网关对象
        {
            uiLoginId = it->hLoginId;
            break;
        }
    }
    
    return uiLoginId;
}

int CDvrGeneral::GetGatewayInfo(unsigned int uiLoginId,GatewayInfo & info)
{
    int iRet = -1;
    std::list<GatewayObj>::iterator it;
    for(it=m_lstGateway.begin();it!=m_lstGateway.end();it++)
    {
        if ( uiLoginId == it->hLoginId )//找到网关对象
        {
            info = it->gwInfo;
            iRet = 0;
            break;
        }
    }
    
    return iRet;
}

bool CDvrGeneral::IsLocalLogin(std::string strGwVCode,int & nError)
{
    bool bRet = false;
    unsigned int uiLoginId = GetLoginId(strGwVCode);
    if (uiLoginId > 0)
    {
        CDvipClient *pInst = NULL;
        std::list<CDvipClient*>::iterator iter;
        for(iter=m_lstInst.begin();iter!=m_lstInst.end();iter++)
        {
            pInst = *iter;
            if ( pInst && pInst->GetLoginId() ==uiLoginId )
            {
                if (pInst->IsLogin())
                {
                    bRet = true;
                }
                
                nError = pInst->m_error;
                break;
            }
        }
    }
    
    return bRet;
}

void CDvrGeneral::ManuelReconnect()
{
    CDvipClient *pInst = NULL;
    std::list<CDvipClient*>::iterator iter;
    for(iter=m_lstInst.begin();iter!=m_lstInst.end();iter++)
    {
        pInst = *iter;
        if ( pInst )
        {
            pInst->Reconnect();
        }
    }
    
    if (m_pRemoteInst)
    {
        m_pRemoteInst->Reconnect();
    }
}

//开启组播
bool CDvrGeneral::MCast_start(fOnIPSearch pFcb,void *pUser)
{
    if (m_bCast == true)
    {
        INFO_TRACE("MCast started!");
        return true;
    }
    
    int iRet = m_mcast.Start("239.255.255.251",37810,pFcb,pUser);
    if (iRet < 0)
    {
        return false;
    }
    m_bCast = true;
    return true;
}

//停止组播
bool CDvrGeneral::MCast_stop(void)
{
    if (m_bCast == false)
    {
        INFO_TRACE("MCast not started!");
        return false;
    }
    m_bCast = false;
    int iRet = m_mcast.Stop();
    if (iRet<0)
        return false;
    return true;
}

//搜索
bool CDvrGeneral::MCast_search(char *szMac,bool bGateWayOnly)
{
    m_mcast.GateWayOnly(bGateWayOnly);
    
    dvip_hdr hdr;
    memset(&hdr,0,sizeof(dvip_hdr));
    memset(&hdr,0,sizeof(hdr));
    hdr.size = DVIP_HDR_LENGTH;
    hdr.magic[0] = 'D';
    hdr.magic[1] = 'H';
    hdr.magic[2] = 'I';
    hdr.magic[3] = 'P';
    hdr.session_id = 0; 
    hdr.request_id=0;  
    hdr.packet_index = 0; 
    hdr.message_length = 0; 
    hdr.data_length = 0; 
    
    Json::Value jsonSearch;
    jsonSearch["method"]="DHDiscover.search";
    if (szMac == NULL)
    {
        jsonSearch["params"]["mac"]="";
    }
    else
        jsonSearch["params"]["mac"]=szMac;
    
    std::string strContent = jsonSearch.toStyledString();
    hdr.packet_length = strContent.size();
    hdr.message_length = strContent.size();
    
    char * pData = new char[DVIP_HDR_LENGTH+hdr.packet_length];
    if (pData == NULL)
    {
        ERROR_TRACE("DHDiscover.search: new memory failed!");
        return false;
    }
    memset(pData,0,DVIP_HDR_LENGTH+hdr.packet_length);
    
    memcpy(pData,(char*)&hdr,sizeof(hdr));
    memcpy(pData+DVIP_HDR_LENGTH,strContent.c_str(),hdr.packet_length);
    
    int iRet = m_mcast.SendMCast_Msg(pData,DVIP_HDR_LENGTH+hdr.packet_length);
    delete pData;
    pData = NULL;
    if (iRet < 0)
    {
        return false;
    }
    return true;
}


