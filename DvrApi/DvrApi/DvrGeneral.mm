#include "DvrGeneral.h"
#include "DvrClient.h"

CDvrGeneral::CDvrGeneral()
{
    m_cbOnDisConnect = 0;
    m_pUser = 0;
    
    m_cbOnDisConnectEx = 0;
    m_pUserEx = 0;
    
    m_cbOnEventNotify = NULL;
    m_pEventNotifyUser = NULL;
    
    m_cbOnAlarmNotify = NULL;
    m_pAlarmNotifyUser = NULL;
    
    m_bCast = false;
}
CDvrGeneral::~CDvrGeneral()
{
}

CDvrGeneral *CDvrGeneral::Instance()
{
    static CDvrGeneral s_instance;
    return &s_instance;
}

CDvrClient * CDvrGeneral::CreateInstance()
{
    unsigned int uiLoginId = 0;
    CDvrClient *pInst = NULL;
    
    pInst = new CDvrClient();
    if ( !pInst )
    {
        ERROR_TRACE("out of memory");
        return NULL;
    }
    pInst->CreateLoginId();
    pInst->SetDisConnectCb(m_cbOnDisConnect,m_pUser);
    pInst->SetDisConnectCbEx(m_cbOnDisConnectEx,m_pUserEx);
    pInst->SetEventNotifyCb(m_cbOnEventNotify,m_pEventNotifyUser);
    pInst->SetAlarmNotifyCb(m_cbOnAlarmNotify,m_pAlarmNotifyUser);
    pInst->SetAutoReconnect(m_bAutoReConnect);
    
    m_lstInst.push_back(pInst);
    
    return pInst;
}
int CDvrGeneral::ReleaseInstance(unsigned int uiLoginId)
{
    std::list<CDvrClient*>::iterator it;
    CDvrClient *pInst;
    for(it=m_lstInst.begin();it!=m_lstInst.end();it++)
    {
        pInst = *it;
        if ( pInst && pInst->GetLoginId() ==uiLoginId )
        {
            m_lstInst.remove(pInst);
            delete pInst;
            return 0;
        }
    }
    return -1;
}

CDvrClient * CDvrGeneral::FindInstance(unsigned int uiLoginId)
{
    std::list<CDvrClient*>::iterator it;
    CDvrClient *pInst;
    for(it=m_lstInst.begin();it!=m_lstInst.end();it++)
    {
        pInst = *it;
        if ( pInst && pInst->GetLoginId() ==uiLoginId )
        {
            return pInst;
        }
    }
    return NULL;
}

CDvrClient * CDvrGeneral::FindRealPlayInstance(unsigned int uiRealHandle)
{
    std::list<CDvrClient*>::iterator it;
    CDvrClient *pInst;
    for(it=m_lstInst.begin();it!=m_lstInst.end();it++)
    {
        pInst = *it;
        if ( pInst )
        {
            if (pInst->HasRealHandle(uiRealHandle))
            {
                return pInst;
            }
        }
    }
    return NULL;
}


//¿ªÆô×é²¥
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

//Í£Ö¹×é²¥
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

//ËÑË÷
bool CDvrGeneral::MCast_search(char *szMac)
{
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
