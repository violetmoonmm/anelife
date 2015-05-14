#include "ISClient.h"
#include "CommonDefine.h"
#include "DvrGeneral.h"

#define DEVICE_TYPE_MODULE_ID			51		//…Ë±∏∂À¿‡–Õ
#define CONTROLPOINT_TYPE_MODULE_ID		54		//øÿ÷∆µ„∂À¿‡–Õ
#define PROXY_TYPE_MODULE_ID			31		//¥˙¿Ì∂À¿‡–Õ
#define FDMS_TYPE_MODULE_ID				32		//FDMS¿‡–Õ
#define SHBG_TYPE_MODULE_ID				52		//SHBG¿‡–Õ


CISClient::CISClient(void)
{
    m_hSubThread = 0;
    m_bSubExitThread = true;
    m_uiSid = 0;
    
    m_emParseStatus = emStageIdle;
    
    m_ucModuleId = CONTROLPOINT_TYPE_MODULE_ID; //control point
    m_strEndpointType = "/Smarthome/cp";
    
    m_ucModuleId = 0; //≥ı º,Œ¥∂®“Â¿‡–Õ
    //∂¡»°macµÿ÷∑
    unsigned long long ullMac = GetMacAddrEx();
    if ( 0 == ullMac )
    {
        //»Áπ˚∂¡»° ß∞‹,‘Ú»°ÀÊª˙ ˝
        GenerateRand(m_ucMac,6);
    }
    else
    {
        m_ucMac[0] = ((ullMac & 0X0000FF0000000000ULL)>>40);
        m_ucMac[1] = ((ullMac & 0X000000FF00000000ULL)>>32);
        m_ucMac[2] = ((ullMac & 0X00000000FF000000ULL)>>24);
        m_ucMac[3] = ((ullMac & 0X0000000000FF0000ULL)>>16);
        m_ucMac[4] = ((ullMac & 0X000000000000FF00ULL)>>8);
        m_ucMac[5] = ((ullMac & 0X00000000000000FFULL)>>0);
    }
}

CISClient::~CISClient(void)
{
    StopSubThread();
    ClearGateway();
    
    Stop();
    ClearCacheMsg();
    
    ClearSend();
    Clear_Tasks();
    
    INFO_TRACE("~CISClient m_strServIp="<<m_strServIp);
}


void CISClient::OnDisconnect(int iReason)
{
    if ( m_cbOnDisConnect )
    {
        std::list<RemoteGateWay*> listObj = ListObj();
        std::list<RemoteGateWay*>::iterator it;
        for (it=listObj.begin();it!=listObj.end();it++)
        {
            RemoteGateWay* pObj = *it;
            std::string strGwVCode = std::string(pObj->gwInfo.szGwVCode);
            int iRet = SetGwLogin(strGwVCode,false,iReason);
            if (iRet == 1)
            {
                INFO_TRACE("cbOnDisConnect iStatus= 0"<<" error="<<iReason<<" strGwVCode="<<strGwVCode);
                m_cbOnDisConnect(CDvrGeneral::Instance()->GetLoginId(strGwVCode),emRemote,
                                 (char*)m_strServIp.c_str(),(unsigned short)m_iServPort,false,iReason,m_pUser);
                INFO_TRACE("cbOnDisConnect end");
            }
        }
    }
}

int CISClient::OnDealData() //¥¶¿Ì ˝æ›
{
    if ( 0 >= m_iRecvIndex ) //no data
    {
        //ERROR_TRACE("no data to process");
        return 0;
    }
    
    bool bHasPack = true;
    do
    {
        if ( m_emParseStatus == emStageIdle || m_emParseStatus == emStageHeader ) //httpÕ∑√ª”–Ω” ’ÕÍ’˚
        {
            //≤È’“httpÕ∑Ω· ¯
            char *pHdrTail = NULL;
            if ( m_iRecvIndex < 4 ) //not enough data to hold http header
            {
                return 0;
            }
            for(int i=0;i<=m_iRecvIndex-4;i++)
            {
                if ( m_szRecvBuf[i] == '\r'
                    && m_szRecvBuf[i+1] == '\n'
                    && m_szRecvBuf[i+2] == '\r'
                    && m_szRecvBuf[i+3] == '\n' )
                {
                    pHdrTail = m_szRecvBuf+i;
                    break;
                }
            }
            //pHdrTail = strstr(m_szRecvBuf,"\r\n\r\n"));
            if ( NULL == pHdrTail ) //Õ∑√ª”–Ω· ¯
            {
                bHasPack = false;
                return 0;
            }
            
            int iHdrLen = (int)(pHdrTail-m_szRecvBuf+4);
            
            if ( !ParseHttpHeader(m_szRecvBuf,iHdrLen+4,m_curMsg) )
            {
                ERROR_TRACE("Parse http header failed");
                ERROR_TRACE(m_szRecvBuf);
                //Ã¯π˝
                //if ( m_iRecvIndex > iHdrLen ) // £”‡µƒ ˝æ›«∞“∆
                //{
                //	memmove(m_szRecvBuf,&m_szRecvBuf[iHdrLen],m_iRecvIndex-iHdrLen);
                //	m_iRecvIndex -= iHdrLen;
                //}
                //else //“—æ≠√ª”– ˝æ›ø…“‘¥¶¿Ì
                //{
                //	bHasPack = false;
                //	m_iRecvIndex = 0;
                //}
                
                memset(m_szRecvBuf,0,MAX_BUF_LEN);
                bHasPack = false;
                m_iRecvIndex = 0;
                
                m_emParseStatus = emStageIdle;
                continue;
            }
            
            int iContentLength = m_curMsg.iContentLength;
            if ( m_curMsg.bIsChunkMode ) //chuncked mode
            {
                ERROR_TRACE("not support current");
                return -1;
            }
            if ( iContentLength == 0 ) //√ª”–œ˚œ¢ÃÂ
            {
                //ªÿµ˜…œ≤„
                OnHttpMsg(m_curMsg,NULL,0);
                
                m_curMsg.Clear();
                
                //«Âø’http
                if ( m_iRecvIndex > iHdrLen+iContentLength ) // £”‡µƒ ˝æ›«∞“∆
                {
                    memmove(m_szRecvBuf,&m_szRecvBuf[iHdrLen+iContentLength],m_iRecvIndex-iHdrLen-iContentLength);
                    m_iRecvIndex -= (iHdrLen+iContentLength);
                }
                else
                {
                    bHasPack = false;
                    m_iRecvIndex = 0;
                }
                m_emParseStatus = emStageIdle;
                
                
                //continue;
            }
            else
            {
                if ( m_iRecvIndex >= iHdrLen+iContentLength ) //“—æ≠ÕÍ≥…
                {
                    //ªÿµ˜…œ≤„
                    OnHttpMsg(m_curMsg,&m_szRecvBuf[iHdrLen],iContentLength);
                    
                    m_curMsg.Clear();
                    
                    if ( m_iRecvIndex > iHdrLen+iContentLength ) //»‘»ª”– £”‡ ˝æ›
                    {
                        //ERROR_TRACE("Still left some data not handled");
                        memmove(m_szRecvBuf,&m_szRecvBuf[iHdrLen+iContentLength],m_iRecvIndex-iHdrLen-iContentLength);
                        m_iRecvIndex -= (iHdrLen+iContentLength);
                        m_emParseStatus = emStageIdle;
                        //continue;
                    }
                    else //“—æ≠√ª”–ø…“‘¥¶¿Ìµƒ ˝æ›
                    {
                        m_iRecvIndex = 0;
                        m_emParseStatus = emStageIdle;
                        bHasPack = false;
                    }
                    
                }
                else //ƒ⁄»›√ª”–Ω” ’ÕÍ≥…
                {
                    m_iContentWriteIndex = 0;
                    m_pContent = new char[iContentLength];
                    if ( !m_pContent )
                    {
                        ERROR_TRACE("out of memory");
                        return -2;
                    }
                    m_iContentWriteIndex = m_iRecvIndex-iHdrLen;
                    m_iRecvIndex = 0;
                    memcpy(m_pContent,&m_szRecvBuf[iHdrLen],m_iContentWriteIndex);
                    m_emParseStatus = emStageContent;
                    
                    //m_pContent = NULL;
                    bHasPack = false;
                    //return 0;
                }
                
            }
        }
        else if ( m_emParseStatus == emStageContent ) //httpÕ∑≤ø“—æ≠ÕÍ≥…,µ»¥˝ƒ⁄»›Ω” ’ÕÍ≥…
        {
            if ( m_curMsg.iContentLength > m_iContentWriteIndex+m_iRecvIndex ) //»‘»ª√ª”–ÕÍ≥…contentΩ” ’
            {
                memcpy(m_pContent+m_iContentWriteIndex,m_szRecvBuf,m_iRecvIndex);
                m_iContentWriteIndex += m_iRecvIndex;
                m_iRecvIndex = 0;
                bHasPack = false;
                //return 0;
            }
            else
            {
                memcpy(m_pContent+m_iContentWriteIndex,m_szRecvBuf,m_curMsg.iContentLength-m_iContentWriteIndex);
                
                //ªÿµ˜…œ≤„
                OnHttpMsg(m_curMsg,m_pContent,m_curMsg.iContentLength);
                
                //÷ÿ÷√◊¥Ã¨
                m_emParseStatus = emStageIdle;
                if ( m_curMsg.iContentLength == m_iContentWriteIndex+m_iRecvIndex )
                {
                    m_iRecvIndex = 0;
                    bHasPack = false;
                }
                else
                {
                    memmove(m_szRecvBuf,&m_szRecvBuf[m_curMsg.iContentLength-m_iContentWriteIndex],m_iRecvIndex-(m_curMsg.iContentLength-m_iContentWriteIndex));
                    //m_iWriteIndex = m_curMsg.iContentLength-m_iContentWriteIndex;
                    m_iRecvIndex = m_iRecvIndex-(m_curMsg.iContentLength-m_iContentWriteIndex);
                }
                //m_iWriteIndex = 0;
                m_iContentWriteIndex = 0;
                m_pContent = NULL;
                m_curMsg.Clear();
                
                //return 1;
            }
        }
    }
    while( bHasPack );
    
    return 0;
}

void CISClient::Reconnect()
{
    if ( !IsLogin())
    {
        m_llLastTime  = GetCurrentTimeMs() - CBaseClient::GS_RECONNECT_INTEVAL;
    }
}

int CISClient::OnHttpMsg(HttpMessage &msg,const char *pContent,int iContentLength)
{
    std::string strMethod;
    strMethod = msg.GetValueNoCase(HEADER_NAME_ACTION);
    int iMethod;
    iMethod = LookupMethod(strMethod.c_str());
    if ( -1 == iMethod )
    {
        ERROR_TRACE("not find method");
        INFO_TRACE("recv msg,method="<<strMethod);
    }
    switch ( iMethod )
    {
            //case emMethod_RegisterReq:
            //	{
            //		return OnRegisterReq(msg,pContent,iContentLength);
            //		break;
            //	}
        case emMethod_RegisterRsp:
        {
            return OnRegisterRsp(msg,pContent,iContentLength);
            break;
        }
            //case emMethod_KeepaliveReq:
            //	{
            //		return OnKeepAliveReq(msg,pContent,iContentLength);
            //		break;
            //	}
        case emMethod_KeepaliveRsp:
        {
            return OnKeepAliveRsp(msg,pContent,iContentLength);
            break;
        }
            //case emMethod_UnRegisterReq:
            //	{
            //		return OnUnRegisterReq(msg,pContent,iContentLength);
            //		break;
            //	}
        case emMethod_UnRegisterRsp:
        {
            return OnUnRegisterRsp(msg,pContent,iContentLength);
            break;
        }
        case emMethod_NotifyReq:
        {
            return OnNotifyReq(msg,pContent,iContentLength);
            break;
        }
        case emMethod_DvipMethodReq:
        case emMethod_DvipMethodRsp:
        case emMethod_GatewayAuthRsp:
        {
            return OnDvipMethodRsp(msg,pContent,iContentLength);
            break;
        }
        default:
            return OnRecvMsg(msg,pContent,iContentLength);
            break;
    }
    
    return -1;
}

int CISClient::CacheMsg(LastMsg msg)
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockLastMsg);
    
    bool found = false;
    std::list<LastMsg>::iterator it;
    for (it=m_lstLastMsg.begin();it!=m_lstLastMsg.end();it++)
    {
        if (it->strGwVCode == msg.strGwVCode)
        {
            found = true;
            it->strMethod = msg.strMethod;
            it->strContent = msg.strContent;
            
            break;
        }
    }
    
    if (!found)
    {
        m_lstLastMsg.push_back(msg);
    }
    
    return 0;
}

bool CISClient::FetchMsg(std::string strGwVCode,LastMsg & msg)
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockLastMsg);
    
    bool found = false;
    std::list<LastMsg>::iterator it;
    for (it=m_lstLastMsg.begin();it!=m_lstLastMsg.end();it++)
    {
        if (it->strGwVCode == strGwVCode)
        {
            found = true;
            msg = *it;
            break;
        }
    }
    
    return found;
}

int CISClient::ClearCacheMsg()
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockLastMsg);
    m_lstLastMsg.clear();
    
    return 0;
}

int CISClient::AddGateway(GatewayInfo gwInfo)
{
    DelGateway(gwInfo);
    
    RemoteGateWay * obj = new RemoteGateWay();
    obj->llLastSubscribeTime = GetCurrentTimeMs();
    obj->gwInfo = gwInfo;
    obj->bHasSubscribe = false;
    obj->authInfo.iAuthStatus = 0;
    obj->authInfo.bHasAuthCode = false;
    memset(obj->authInfo.szAuthCode,0,256);
    
    if (m_hSubThread == 0)
    {
        StartSubThread();
    }
    obj->llLastSubscribeTime = GetCurrentTimeMs()-CISClient::GS_SUBSCRIBE_INTERVAL+30*1000;//15√Î÷Æ∫Û∑¢∆∂©‘ƒ«Î«Û
    
    if(IsLogin())
    {
        int iRet = TouchGateway(std::string(obj->gwInfo.szGwVCode));
        obj->bRemoteOnline = (iRet == 0)?true:false;
    }
    else
        obj->bRemoteOnline = false;
    
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    m_lstGwObj.push_back(obj);
    
    return 0;
}

int CISClient::DelGateway(GatewayInfo gwInfo)
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    
    bool found = false;
    RemoteGateWay * pObj = NULL;
    std::list<RemoteGateWay *>::iterator it;
    for (it=m_lstGwObj.begin();it!=m_lstGwObj.end();it++)
    {
        pObj = *it;
        if (!strcmp(gwInfo.szSn,pObj->gwInfo.szSn))
        {
            found = true;
            break;
        }
    }
    
    if (found)
    {
        //INFO_TRACE("remote erase gateway "<<gwInfo.szSn);
        m_lstGwObj.erase(it);
    }
    
    return 0;
}

void CISClient::ClearGateway()
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    m_lstGwObj.clear();
}

void CISClient::TryTouchGateway()
{
    //À¢–¬»œ÷§–≈œ¢
    ClearAuthorization();
    
    //À¢–¬Õ¯πÿ◊¥Ã¨£¨÷ÿ–¬»œ÷§
    std::list<RemoteGateWay*> listObj = ListObj();
    std::list<RemoteGateWay*>::iterator it;
    for (it=listObj.begin();it!=listObj.end();it++)
    {
        bool bCallBack = true;
        RemoteGateWay * pObj = *it;
        std::string strGwVCode = std::string(pObj->gwInfo.szGwVCode);
        int iRet = TouchGateway(strGwVCode);
        bool bOnline = false;
        int error = 0;
        if (iRet == 0)//–°Õ¯πÿ”–∑µªÿ”¶¥
        {
            bOnline = true;
            error = 0;
        }
        else
        {
            bOnline = false;
            error = emDisRe_ConnectFailed;
        }
        
        iRet = SetGwLogin(strGwVCode,bOnline,error);
        
        if (iRet == 1)
        {
            if ( m_cbOnDisConnect )
            {
                //ªÒ»°–Ú¡–∫≈
                std::string strConfig;
                iRet = GetConfig("ChangeId",strConfig,strGwVCode);//≥…π¶
                if (iRet == 0)
                {
                    if (IsAuthed(strGwVCode))
                    {
                        error = emDisRe_AuthOK;
                    }
                }
                
                if (error != emDisRe_AuthOK)
                {
                    INFO_TRACE("cbOnDisConnect iStatus="<<bOnline<<" error="<<error<<" strGwVCode="<<strGwVCode);
                    m_cbOnDisConnect(CDvrGeneral::Instance()->GetLoginId(strGwVCode),emRemote,
                                     (char*)m_strServIp.c_str(),(unsigned short)m_iServPort,bOnline,error,m_pUser);
                    INFO_TRACE("cbOnDisConnect end");
                }
            }
        }
    }
}

std::list<RemoteGateWay*> CISClient::ListObj()
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    return m_lstGwObj;
}

bool CISClient::SetSubscribe(std::string strGwVCode,bool bHasSubscribe,long long llLastSubscribeTime)
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    
    bool bRet = false;
    std::list<RemoteGateWay*>::iterator it;
    for (it=m_lstGwObj.begin();it!=m_lstGwObj.end();it++)
    {
        RemoteGateWay* pObj = *it;
        if (strGwVCode == pObj->gwInfo.szGwVCode)
        {
            bRet = true;
            pObj->bHasSubscribe = bHasSubscribe;
            pObj->llLastSubscribeTime = llLastSubscribeTime;
            *it = pObj;
            break;
        }
    }
    
    return bRet;
}


bool CISClient::GetAuthCode(std::string strGwVCode,int & iAuthStatus,int & iFailedTimes,std::string & strAuthCode)
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    bool bRet = false;
    std::list<RemoteGateWay*>::iterator it;
    for (it=m_lstGwObj.begin();it!=m_lstGwObj.end();it++)
    {
        RemoteGateWay* pObj = *it;
        if (strGwVCode == pObj->gwInfo.szGwVCode && pObj->authInfo.bHasAuthCode)
        {
            bRet = true;
            iAuthStatus = pObj->authInfo.iAuthStatus;
            strAuthCode = std::string(pObj->authInfo.szAuthCode);
            iFailedTimes= pObj->authInfo.iFailedTimes;
            break;
        }
    }
    
    return bRet;
}

bool CISClient::SetAuthCode(std::string strGwVCode,std::string strAuthCode)
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    
    bool bRet = false;
    std::list<RemoteGateWay*>::iterator it;
    for (it=m_lstGwObj.begin();it!=m_lstGwObj.end();it++)
    {
        RemoteGateWay* pObj = *it;
        if (strGwVCode == pObj->gwInfo.szGwVCode)
        {
            bRet = true;
            pObj->authInfo.iAuthStatus = 0;
            pObj->authInfo.bHasAuthCode = true;
            pObj->authInfo.iFailedTimes = 0;
            strcpy(pObj->authInfo.szAuthCode,(char*)strAuthCode.c_str());
            memset(pObj->authInfo.szAuthorization,0,1024);
            *it = pObj;
            break;
        }
    }
    
    return bRet;
}


bool CISClient::SetAuthStatus(std::string strGwVCode,int iAuthStatus)
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    
    bool bRet = false;
    std::list<RemoteGateWay*>::iterator it;
    for (it=m_lstGwObj.begin();it!=m_lstGwObj.end();it++)
    {
        RemoteGateWay* pObj = *it;
        if (strGwVCode == pObj->gwInfo.szGwVCode)
        {
            bRet = true;
            pObj->authInfo.iAuthStatus = iAuthStatus;
            if (iAuthStatus == 1)
            {
                pObj->authInfo.iFailedTimes++;
            }
            else if (iAuthStatus == 2 || iAuthStatus == 0)
            {
                pObj->authInfo.iFailedTimes = 0;
            }
            *it = pObj;
            break;
        }
    }
    
    return bRet;
}

bool CISClient::GetAuthorization(std::string strGwVCode,int & iAuthStatus,std::string & strAuthorization)
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    bool bRet = false;
    std::list<RemoteGateWay*>::iterator it;
    for (it=m_lstGwObj.begin();it!=m_lstGwObj.end();it++)
    {
        RemoteGateWay* pObj = *it;
        if (strGwVCode == pObj->gwInfo.szGwVCode && pObj->authInfo.bHasAuthCode)
        {
            bRet = true;
            iAuthStatus = pObj->authInfo.iAuthStatus;
            strAuthorization = std::string(pObj->authInfo.szAuthorization);
            break;
        }
    }
    
    return bRet;
}

void CISClient::ClearAuthorization()
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    std::list<RemoteGateWay*>::iterator it;
    for (it=m_lstGwObj.begin();it!=m_lstGwObj.end();it++)
    {
        RemoteGateWay* pObj = *it;
        pObj->authInfo.iAuthStatus = 0;
        memset(pObj->authInfo.szAuthorization,0,1024);
    }
}

bool CISClient::AuthOK(std::string strGwVCode,bool bEnable)
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    bool bRet = false;
    int iError = (bEnable)?emDisRe_AuthOK:emDisRe_AuthFailed;
    std::list<RemoteGateWay*>::iterator it;
    for (it=m_lstGwObj.begin();it!=m_lstGwObj.end();it++)
    {
        RemoteGateWay* pObj = *it;
        if (strGwVCode == pObj->gwInfo.szGwVCode)
        {
            if (pObj->nError != iError)
            {
                pObj->nError = iError;
                bRet = true;
                *it=pObj;
            }
            break;
        }
    }
    
    return bRet;
}

bool CISClient::IsAuthed(std::string strGwVCode)
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    bool bRet = false;
    std::list<RemoteGateWay*>::iterator it;
    for (it=m_lstGwObj.begin();it!=m_lstGwObj.end();it++)
    {
        RemoteGateWay* pObj = *it;
        if (strGwVCode == pObj->gwInfo.szGwVCode)
        {
            if (pObj->nError == emDisRe_AuthOK)
            {
                bRet = true;
            }
            break;
        }
    }
    
    return bRet;
}

bool CISClient::SetAuthorization(std::string strGwVCode,std::string strAuth)
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    
    bool bRet = false;
    std::list<RemoteGateWay*>::iterator it;
    for (it=m_lstGwObj.begin();it!=m_lstGwObj.end();it++)
    {
        RemoteGateWay* pObj = *it;
        if (strGwVCode == pObj->gwInfo.szGwVCode)
        {
            bRet = true;
            strncpy(pObj->authInfo.szAuthorization,(char*)strAuth.c_str(),1024-1);
            *it=pObj;
            break;
        }
    }
    
    return bRet;
}

int CISClient::SetGwLogin(std::string strGwVCode,bool bOnline,int nError)
{
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    
    int iRet = -1;
    std::list<RemoteGateWay*>::iterator it;
    for (it=m_lstGwObj.begin();it!=m_lstGwObj.end();it++)
    {
        RemoteGateWay* pObj = *it;
        if (strGwVCode == pObj->gwInfo.szGwVCode)
        {
            iRet = 0;
            pObj->nError = nError;
            if (bOnline == true)//Õ¯πÿ…œœﬂ£¨5s÷ÿ–¬∑¢∆»œ÷§∫Õ∂©‘ƒ
            {
                pObj->llLastSubscribeTime = GetCurrentTimeMs()-CISClient::GS_SUBSCRIBE_INTERVAL+5*1000;
            }
            else
            {
                pObj->bHasSubscribe = false;
                pObj->authInfo.iAuthStatus = 0;
                memset(pObj->authInfo.szAuthorization,0,1024);
            }
            
            bool bPrevOnline = pObj->bRemoteOnline;
            pObj->bRemoteOnline = bOnline;
            *it = pObj;
            if (bPrevOnline != bOnline)
            {
                iRet = 1;
            }
            break;
        }
    }
    
    return iRet;
}

bool CISClient::IsGwLogin(std::string strGwVCode,int & nError)
{
    bool bRet = false;
    if (!IsLogin())//∑˛ŒÒ∆˜≤ª‘⁄œﬂ
    {
        nError = m_error;
        return bRet;
    }
    
    CMutexGuardT<CMutexThreadRecursive> theLock(m_lockGwObj);
    std::list<RemoteGateWay*>::iterator it;
    for (it=m_lstGwObj.begin();it!=m_lstGwObj.end();it++)
    {
        RemoteGateWay* pObj = *it;
        if (strGwVCode == pObj->gwInfo.szGwVCode)
        {
            bRet = pObj->bRemoteOnline ;
            break;
        }
    }
    
    return bRet;
}

//unsigned int CISClient::MakeReqId()
//{
//	return ++CISClient::s_uiIdentify;
//}

std::string CISClient::MakeSessionId()
{
    int iRanBytes = rand()%5+1;
    int iLen = 6+1+4+iRanBytes;
    unsigned char ucSession[32] = {0};
    memcpy(ucSession,m_ucMac,6);
    memcpy(&ucSession[6],&m_ucModuleId,1);
    unsigned int uiTick = GetTickCount();
    memcpy(&ucSession[7],&uiTick,4);
    GenerateRand(&ucSession[11],iRanBytes);
    char szBuf[8];
    std::string strSessionId;
    for(int i=0;i<iLen;i++)
    {
        sprintf(szBuf,"%02X",ucSession[i]);
        strSessionId += szBuf;
    }
    
    return strSessionId;
}
std::string CISClient::MakeTags(unsigned int uiReqId)
{
    //unsigned int uiReqId = MakeReqId();
    std::string strSessionId = MakeSessionId();
    char szBuf[128] = {0};
    sprintf(szBuf,"sessionid=%s,seq=%u",strSessionId.c_str(),uiReqId);
    return std::string(szBuf);
}

int CISClient::Login(int waittime)
{
    int iRet = 0;
    m_waittime = waittime;
    
    m_emStatus = emNone;
    int error = emDisRe_None;
    if (!IsConnected())
    {
        iRet = Connect((char*)m_strServIp.c_str(),m_iServPort);
        if ( iRet < 0 )
        {
            //ERROR_TRACE("connect failed!m_strServIp="<<m_strServIp<<" m_iServPort="<<m_iServPort);
            OnRegisterFailed(emDisRe_ConnectFailed);
            error = emDisRe_ConnectFailed;
            return error;
        }
    }
    iRet = Login_Sync();
    if ( 0 != iRet ) // ß∞‹
    {
        error = iRet;
    }
    else//µ«¬Ω≥…π¶∫Û∏¸–¬œ÷”–Õ¯πÿ◊¥Ã¨
    {
    }
    
    return error;
}

int CISClient::Login_Sync()
{
    bool bResult = false;
    long long llStart = GetCurrentTimeMs();
    long long llEnd;
    m_error = 0;
    int iRet = RegisterReq();
    if ( iRet == 0 )
    {
    }
    else
    {
        OnRegisterFailed(emDisRe_RegistedFailed);
        return emDisRe_RegistedFailed;
    }
    
    m_emStatus = emRegistering; //’˝‘⁄◊¢≤·
    
    //µ»¥˝µ«¬ºΩ·π˚
    do
    {
        if ( m_emStatus == emRegistered ) //◊¢≤·≥…π¶
        {
            bResult = true;
        }
        else if ( emIdle == m_emStatus ) //◊¢≤· ß∞‹
        {
            bResult = true;
        }
        else
        {
            FclSleep(1);
        }
        llEnd = GetCurrentTimeMs();
        
    }while( _abs64(llEnd-llStart) < m_waittime && !bResult );
    
    if ( bResult == true )
    {
        if (emRegistered == m_emStatus)
        {
            iRet  = 0;
        }
        else
        {
            iRet = m_error;
        }
    }
    else //◊¢≤· ß∞‹
    {
        OnRegisterFailed(emDisRe_RegistedFailed);
        iRet = emDisRe_RegistedFailed;
    }
    return iRet;
}

int CISClient::Logout()
{
    return UnRegister();
}

void CISClient::AutoReconnect()
{
    int iRet = Login_Sync();
    if ( 0 != iRet ) // ß∞‹
    {
    }
    else
    {
        TryTouchGateway();
    }
}

//∑¢ÀÕ◊¢≤·«Î«Û
int CISClient::RegisterReq()
{
    HttpMessage regMsg;
    regMsg.iType = 1;
    regMsg.iMethod = emMethodRegister;
    regMsg.strPath = m_strEndpointType;
    if ( regMsg.strPath.empty() )
    {
        ERROR_TRACE("unsupport endpoint");
    }
    
    regMsg.iContentLength = 0;
    regMsg.SetValue(HEADER_NAME_FROM,m_strVcodeLocal);
    regMsg.SetValue(HEADER_NAME_TO,m_strVcodePeer);
    unsigned int uiReqId = CreateReqId();
    regMsg.SetValue(HEADER_NAME_TAGS,MakeTags(uiReqId));
    
    regMsg.SetValue(HEADER_NAME_ACTION,ACTION_REGISTER_REQ);
    
    std::string strMsg = regMsg.ToHttpheader();
    
    //∑¢ÀÕ◊¢≤·«Î«Ûœ˚œ¢
    int iRet = SendData((char*)strMsg.c_str(),(int)strMsg.size());
    if ( 0 <= iRet )
    {
        return 0;
    }
    else
    {
        return -1;
    }
    
    return 0;
}

//∑¢ÀÕ◊¢≤·«Î«Û
int CISClient::RegisterReq(const std::string &strAuth)
{
    HttpMessage regMsg;
    regMsg.iType = 1;
    regMsg.iMethod = emMethodRegister;
    regMsg.strPath = m_strEndpointType;
    if ( regMsg.strPath.empty() )
    {
        ERROR_TRACE("unsupport endpoint");
    }
    
    regMsg.iContentLength = 0;
    regMsg.SetValue(HEADER_NAME_FROM,m_strVcodeLocal);
    regMsg.SetValue(HEADER_NAME_TO,m_strVcodePeer);
    unsigned int uiReqId = CreateReqId();
    regMsg.SetValue(HEADER_NAME_TAGS,MakeTags(uiReqId));
    regMsg.SetValue(HEADER_NAME_ACTION,ACTION_REGISTER_REQ);
    regMsg.SetValue("Authorization",strAuth);
    
    std::string strMsg = regMsg.ToHttpheader();
    
    //∑¢ÀÕ◊¢≤·«Î«Ûœ˚œ¢
    int iRet = SendData((char*)strMsg.c_str(),(int)strMsg.size());
    if ( 0 <= iRet )
    {
        return 0;
    }
    else
    {
        //ERROR_TRACE("send data failed");
        return -1;
    }
    
    return 0;
}

int CISClient::UnRegister()
{
    m_bAutoConnect = false;
    
    INFO_TRACE("remote UnRegister");
    
    //if (!IsLogin())
    //{
    //	WARN_TRACE("not login!");
    //	m_emStatus = emIdle;
    
    //	return -1;
    //}
    m_emStatus = emIdle;
    
    int iRet;
    HttpMessage regMsg;
    regMsg.iType = 1;
    regMsg.iMethod = emMethodRegister;
    regMsg.strPath = m_strEndpointType;
    if ( regMsg.strPath.empty() )
    {
        ERROR_TRACE("unsupport endpoint");
    }
    
    regMsg.iContentLength = 0;
    regMsg.SetValue(HEADER_NAME_FROM,m_strVcodeLocal);
    regMsg.SetValue(HEADER_NAME_TO,m_strVcodePeer);
    unsigned int uiReqId = CreateReqId();
    regMsg.SetValue(HEADER_NAME_TAGS,MakeTags(uiReqId));
    regMsg.SetValue(HEADER_NAME_ACTION,ACTION_UNREGISTER_REQ);
    
    std::string strMsg = regMsg.ToHttpheader();
    
    m_bUnregister = false;
    //∑¢ÀÕ◊¢≤·«Î«Ûœ˚œ¢
    iRet = SendData((char*)strMsg.c_str(),(int)strMsg.size());
    if ( 0 <= iRet )
    {
        bool bResult = false;
        long long llStart = GetCurrentTimeMs();
        long long llEnd;
        
        //µ»¥˝µ«¬ºΩ·π˚
        do
        {
            if ( m_bUnregister == true ) //◊¢≤·≥…π¶
            {
                bResult = true;
            }
            else
            {
                FclSleep(1);
            }
            llEnd = GetCurrentTimeMs();
            
        }while( _abs64(llEnd-llStart) < 5000 && !bResult );
        //if(bResult)
        return 0;
    }
    else
    {
        //ERROR_TRACE("send data failed");
        return -1;
    }
    return -1;
}

//±£ªÓ«Î«Û
int CISClient::KeepAlive()
{
    int iRet;
    HttpMessage regMsg;
    regMsg.iType = 1;
    regMsg.iMethod = emMethodRegister;
    regMsg.strPath = m_strEndpointType;
    if ( regMsg.strPath.empty() )
    {
        ERROR_TRACE("unsupport endpoint");
    }
    regMsg.iContentLength = 0;
    regMsg.SetValue(HEADER_NAME_FROM,m_strVcodeLocal);
    regMsg.SetValue(HEADER_NAME_TO,m_strVcodePeer);
    unsigned int uiReqId = CreateReqId();
    regMsg.SetValue(HEADER_NAME_TAGS,MakeTags(uiReqId));
    regMsg.SetValue(HEADER_NAME_ACTION,ACTION_KEEPALIVE_REQ);
    
    std::string strMsg = regMsg.ToHttpheader();
    //∑¢ÀÕ±£ªÓ«Î«Ûœ˚œ¢
    iRet = SendData((char*)strMsg.c_str(),(int)strMsg.size());
    if ( 0 <= iRet )
    {
        return 0;
    }
    else
    {
        //ERROR_TRACE("send data failed");
        return -1;
    }
}

// ’µΩ◊¢≤·ªÿ”¶
int CISClient::OnRegisterRsp(HttpMessage &msg,const char *pContent,int iContentLength)
{
    int iStatus = msg.iStatusCode;
    
    if ( 200 == iStatus ) //µ«¬º≥…π¶
    {
        OnRegisterSuccess(emDisRe_None);
    }
    else // ß∞‹
    {
        if ( 401 == iStatus ) //–Ë“™√‹¬Î—È÷§
        {
            std::string strWWWAuthenticate;
            std::string strAuthorization;
            bool bRet = false;
            HttpAuth auth;
            int iRet;
            
            strWWWAuthenticate = msg.GetValueNoCase("WWW-Authenticate");
            if ( strWWWAuthenticate.empty() )
            {
                //»œ÷§ƒ⁄»›≤ª¥Ê‘⁄
                ERROR_TRACE("no WWW-Authenticate find,discard.");
                OnRegisterFailed(emDisRe_RegistedRefused);
                return 0;
            }
            
            //Ω‚Œˆ»œ÷§ƒ⁄»›
            bRet = ParseHttpAuthParams(strWWWAuthenticate,auth);
            if ( !bRet )
            {
                ERROR_TRACE("parse WWW-Authenticate failed.");
                OnRegisterFailed(emDisRe_RegistedRefused);
                return 0;
            }
            if ( auth.strScheme == "Basic" ) //ª˘±æ
            {
                if ( auth.strRealm.empty() )
                {
                    ERROR_TRACE("realm param must exist.");
                    OnRegisterFailed(emDisRe_RegistedRefused);
                    return 0;
                }
                auth.bIsResponse = true;
                auth.strResponse = CalcBasic(m_strVcodeLocal,m_strPassword);
                strAuthorization += auth.ToString();
                m_strRealm = auth.strRealm;
                m_strRandom = auth.strNonce;
                
                iRet = RegisterReq(strAuthorization);
                if (iRet < 0)
                {
                    ERROR_TRACE("send Authenticate failed.");
                    OnRegisterFailed(emDisRe_RegistedFailed);
                }
                return 0;
            }
            else if ( auth.strScheme == "Digest" ) //’™“™À„∑®
            {
                if ( auth.strRealm.empty() || auth.strNonce.empty() )
                {
                    ERROR_TRACE("username realm nonce and response param must exist.");
                    OnRegisterFailed(emDisRe_RegistedRefused);
                    return 0;
                }
                auth.strUsername = m_strVcodeLocal;
                auth.strUri = m_strEndpointType;//msg.strPath;
                auth.strResponse = CalcAuthMd5(auth.strUsername,m_strPassword,auth.strRealm,auth.strNonce,std::string("POST"),auth.strUri);
                strAuthorization += auth.ToString();
                m_strRealm = auth.strRealm;
                m_strRandom = auth.strNonce;
                
                iRet = RegisterReq(strAuthorization);
                if (iRet < 0)
                {
                    ERROR_TRACE("send Authenticate failed.");
                    OnRegisterFailed(emDisRe_RegistedFailed);
                }
                return 0;
            }
            //if ( auth.strScheme != "Digest" ) //º»∑«ª˘±æ“≤∑«’™“™À„∑®,æ‹æ¯
            else
            {
                ERROR_TRACE("auth scheme must be Digest.current scheme="<<auth.strScheme<<".");
                OnRegisterFailed(emDisRe_RegistedRefused);
                return 0;
            }
            
            if ( auth.strRealm.empty() || auth.strNonce.empty() )
            {
                ERROR_TRACE("username realm nonce and response param must exist.");
                OnRegisterFailed(emDisRe_RegistedRefused);
                return 0;
            }
            
            //return 0;
        }
        else
        {
            ERROR_TRACE("server refused.code="<<iStatus);
            if ( iStatus == UPNP_STATUS_CODE_REFUSED )
            {
                OnRegisterFailed(emDisRe_RegistedRefused);
            }
            else if ( iStatus == UPNP_STATUS_CODE_AUTH_FAILED )
            {
                OnRegisterFailed(emDisRe_AuthFailed);
            }
            else if ( iStatus == UPNP_STATUS_CODE_PASSWORD_INVALID )
            {
                OnRegisterFailed(emDisRe_PasswordInvalid);
            }
            else
            {
                OnRegisterFailed(emDisRe_RegistedRefused);
            }
            return 0;
        }
    }
    
    return 0;
}

// ’µΩ±£ªÓªÿ”¶
int CISClient::OnKeepAliveRsp(HttpMessage &msg,const char *pContent,int iContentLength)
{
    int iStatus;
    
    iStatus = msg.iStatusCode;
    
    if ( 200 == iStatus ) //±£ªÓ≥…π¶
    {
        //INFO_TRACE("keepalive OK");
        //m_iStatus = 2;
    }
    else // ß∞‹
    {
        ERROR_TRACE("keepalive failed.");
        //m_iStatus = 0;
    }
    m_llLastTime = GetCurrentTimeMs();
    
    return 0;
}

// ’µΩµ«≥ˆªÿ”¶
int CISClient::OnUnRegisterRsp(HttpMessage &msg,const char *pContent,int iContentLength)
{
    m_bUnregister = true;
    INFO_TRACE("remote unregister ok.");
    
    return 0;
}

// ’µΩµ«≥ˆªÿ”¶
int CISClient::OnNotifyReq(HttpMessage &msg,const char *pContent,int iContentLength)
{
    INFO_TRACE("OnNotifyReq: "<<pContent);
    std::vector<NameValue*> args;
    bool bRet = ParseNotifyBody((char*)pContent,iContentLength,args);
    if (!bRet)
    {
        ERROR_TRACE("parser notify body failed. "<<pContent);
        return -1;
    }
    
    std::string vcode;
    std::string status;
    
    std::vector<NameValue*>::iterator it;
    for (it = args.begin();it != args.end(); it++)
    {
        NameValue * tmp = *it;
        if (tmp->m_strArgumentName == "vcode")
        {
            vcode = tmp->m_strArgumentValue;
        }
        else if (tmp->m_strArgumentName == "status")
        {
            status = tmp->m_strArgumentValue;
        }
        else
        {
        }
    }
    
    if (vcode.empty() || status.empty())
    {
        ERROR_TRACE("vcode or status empty");
        return -1;
    }
    
    bool bOnline = (status=="Online")?true:false;
    int iError = (status=="Online")?0:emDisRe_Disconnected;
    int iRet = SetGwLogin(vcode,bOnline,iError);
    if (iRet == 1)
    {
        INFO_TRACE("cbOnDisConnect iStatus="<<bOnline<<" strGwVCode="<<vcode);
        m_cbOnDisConnect(CDvrGeneral::Instance()->GetLoginId(vcode),emRemote,
                         (char*)m_strServIp.c_str(),(unsigned short)m_iServPort,false,iError,m_pUser);
        INFO_TRACE("cbOnDisConnect end");
    }
    return 0;
}

int CISClient::OnRecvMsg(HttpMessage &msg,const char *pContent,int iContentLength)
{
    return 0;
}

int CISClient::OnDvipMethodRsp(HttpMessage &msg,const char *pContent,int iContentLength)
{
    m_llLastTime = GetCurrentTimeMs();//÷ÿ÷√±£ªÓ
    
    int iStatus = msg.iStatusCode;
    std::string strGwVCode;
    if (msg.strPath == "/dvip/notification")
    {
        strGwVCode = msg.GetValueNoCase(HEADER_NAME_FROM);
    }
    else
        strGwVCode = msg.GetValueNoCase(HEADER_NAME_TO);
    
    int iAuthStatus;
    int iFailedTimes;
    std::string strAuthCode;
    bool bHasAuthCode = GetAuthCode(strGwVCode,iAuthStatus,iFailedTimes,strAuthCode);
    if ( 200 == iStatus || iStatus == 0) //µ«¬º≥…π¶
    {
        if (bHasAuthCode)
        {
            if (iAuthStatus == 1)//µ»¥˝»œ÷§÷–
            {
                INFO_TRACE("gateway auth ok! strGwVCode="<<strGwVCode);
                //–ﬁ∏ƒ»œ÷§◊¥Ã¨
                SetAuthStatus(strGwVCode,2);
                if (AuthOK(strGwVCode,true))
                {
                    if ( m_cbOnDisConnect )
                    {
                        INFO_TRACE("cbOnDisConnect emDisRe_AuthOK strGwVCode="<<strGwVCode);
                        m_cbOnDisConnect(CDvrGeneral::Instance()->GetLoginId(strGwVCode),emRemote,
                                         (char*)m_strServIp.c_str(),(unsigned short)m_iServPort,true,emDisRe_AuthOK,m_pUser);
                        INFO_TRACE("cbOnDisConnect end");
                    }
                }
            }
        }
        
        if (pContent == NULL)//Œﬁƒ⁄»›
        {
            WARN_TRACE("no content!");
            return 0;
        }
        
        int iMsgIndex = 0;
        dvip_hdr hdr;
        Json::Reader jsonParser;
        Json::Value jsonContent;
        bool bRet = true;
        int iRet = 0;
        
        memcpy(&hdr,pContent,DVIP_HDR_LENGTH);
        if ( hdr.size != DVIP_HDR_LENGTH ) //Õ∑≤ø≥§∂»
        {
            if ( hdr.size < DVIP_HDR_LENGTH )
            {
                ERROR_TRACE("invalid msg hdr,too short.");
                return -1;
            }
            else
            {
                ERROR_TRACE("msg hdr have extend data,not support now.");
                return -1;
            }
        }
        else
        {
            iMsgIndex += DVIP_HDR_LENGTH;
        }
        
        if ( hdr.message_length == 0 )
        {
            ERROR_TRACE("invalid msg no msg body.");
            return -1;
        }
        
        if (hdr.data_length>0)//”–¿©’π ˝æ›£¨◊È∞¸
        {
            unsigned int uiLoginId = CDvrGeneral::Instance()->GetLoginId(strGwVCode);
            if (uiLoginId > 0)
            {
                INFO_TRACE("strGwVCode="<<strGwVCode<<" uiLoginId="<<uiLoginId);
                //«Î«ÛIDŒ™ø’,notificationœ˚œ¢
                iRet = OnPackage(uiLoginId,hdr,pContent+DVIP_HDR_LENGTH,iContentLength-DVIP_HDR_LENGTH);
                if (iRet<0)//◊È∞¸ ß∞‹ªÚΩ· ¯£¨∑µªÿ’˝≥£ƒ£ Ω
                {
                }
            }
            else
                ERROR_TRACE("not find uiLoginId! strGwVCode="<<strGwVCode);
        }
        else
        {
            TransInfo *pTrans;
            //idŒ™0ªÚattechµƒid ±±Ì æµ±«∞∞¸Œ™Õ®÷™∞¸
            if ( 0 == hdr.request_id)
            {
                unsigned int uiLoginId = CDvrGeneral::Instance()->GetLoginId(strGwVCode);
                if (uiLoginId > 0)
                {
                    INFO_TRACE("strGwVCode="<<strGwVCode<<" uiLoginId="<<uiLoginId);
                    //«Î«ÛIDŒ™ø’,notificationœ˚œ¢
                    OnNotification(uiLoginId,hdr,pContent+DVIP_HDR_LENGTH,iContentLength-DVIP_HDR_LENGTH);
                }
                else
                    ERROR_TRACE("not find uiLoginId! strGwVCode="<<strGwVCode);
                return 0;
            }
            else
            {
                pTrans = FetchRequest(hdr.request_id);
                if ( !pTrans )
                {
                    ERROR_TRACE("not find request.reqid="<<hdr.request_id);
                    return -1;
                }
            }
            
            CDvipMsg *pMsg = NULL;
            switch ( pTrans->type )
            {
                case emRT_Login: //µ«¬º
                    break;
                case emRT_Keepalive: //±£ªÓ
                    break;
                case emRT_Logout: //µ«≥ˆ
                    break;
                default:
                    pMsg = CreateMsg(pTrans->type);
                    break;
            }
            
            if ( !pMsg )
            {
                ERROR_TRACE("Create msg failed")
                pTrans->result = TransInfo::emTaskStatus_Failed;
            }
            else
            {
                iRet = pMsg->Decode((char*)pContent,(unsigned int)iContentLength);
                if ( 0 != iRet )
                {
                    ERROR_TRACE("decode msg failed");
                    delete pMsg;
                    pTrans->result = TransInfo::emTaskStatus_Failed;
                }
                else
                {
                    pTrans->result = TransInfo::emTaskStatus_Success;
                    pTrans->pRspMsg = pMsg;
                }
            }
            
            pTrans->hEvent.Signal();
        }
    }
    else // ß∞‹
    {
        if ( 401 == iStatus ) //–Ë“™√‹¬Î—È÷§
        {
            INFO_TRACE("unnp need auth,strGwVCode="<<strGwVCode);
            if (bHasAuthCode == false)
            {
                ERROR_TRACE("no auth code.auth verify failed! strGwVCode="<<strGwVCode);
                return -1;
            }
            
            if (iFailedTimes > 1)
            {
                ERROR_TRACE("auth verify  failed! strGwVCode="<<strGwVCode);
                if (AuthOK(strGwVCode,false))
                {
                    int iError = 0;
                    bool bOnline = IsGwLogin(strGwVCode,iError);
                    if (bOnline)
                    {
                        if ( m_cbOnDisConnect )
                        {
                            INFO_TRACE("cbOnDisConnect emDisRe_AuthFailed strGwVCode="<<strGwVCode);
                            m_cbOnDisConnect(CDvrGeneral::Instance()->GetLoginId(strGwVCode),emRemote,
                                             (char*)m_strServIp.c_str(),(unsigned short)m_iServPort,true,emDisRe_AuthFailed,m_pUser);
                            INFO_TRACE("cbOnDisConnect end");
                        }
                    }
                }
                return -1;
            }
            
            std::string strWWWAuthenticate;
            std::string strAuthorization;
            bool bRet = false;
            HttpAuth auth;
            int iRet;
            
            strWWWAuthenticate = msg.GetValueNoCase("UPNP-Authenticate");
            if ( !strWWWAuthenticate.empty() )
            {
                //Ω‚Œˆ»œ÷§ƒ⁄»›
                bRet = ParseHttpAuthParams(strWWWAuthenticate,auth);
                if ( bRet )
                {
                    if ( auth.strScheme == "Basic" ) //ª˘±æ
                    {
                    }
                    else if ( auth.strScheme == "Digest" ) //’™“™À„∑®
                    {
                        if ( auth.strRealm.empty() || auth.strNonce.empty() )
                        {
                            ERROR_TRACE("username realm nonce and response param must exist.");
                        }
                        else
                        {
                            auth.strUsername = CDvrGeneral::Instance()->PhoneNo();
                            auth.strUsername += CDvrGeneral::Instance()->MEID();
                            auth.strUri = m_strEndpointType;//msg.strPath;
                            auth.strResponse = CalcAuthMd5(auth.strUsername,strAuthCode
                                                           ,auth.strRealm,auth.strNonce,std::string("POST"),auth.strUri);
                            strAuthorization += auth.ToString();
                            //º«¬º»œ÷§œ˚œ¢
                            if (iAuthStatus == 0 || iAuthStatus == 2)//Œ¥»œ÷§ªÚ“—»œ÷§µ´nonce±‰∏¸
                            {
                                INFO_TRACE("strAuthorization="<<strAuthorization<<" strGwVCode="<<strGwVCode);
                                SetAuthorization(strGwVCode,strAuthorization);
                            }
                            else
                            {
                            }
                            SetAuthStatus(strGwVCode,1);
                            
                            //∑µªÿ»œ÷§–≈œ¢
                            LastMsg msg;
                            bool bRet = FetchMsg(strGwVCode,msg);
                            if (bRet)
                            {
                                unsigned int uiReqId = CreateReqId();
                                iRet = DvipSend(uiReqId,(char*)msg.strMethod.c_str(),(char*)msg.strContent.c_str(),
                                                msg.strContent.length(),strGwVCode,true);
                            }
                        }
                    }
                    //º»∑«ª˘±æ“≤∑«’™“™À„∑®,æ‹æ¯
                    else
                    {
                        ERROR_TRACE("auth scheme must be Digest.current scheme="<<auth.strScheme<<".");
                    }
                }
                else
                    ERROR_TRACE("parse UPNP-Authenticate failed.");
            }
            else
            {
                //»œ÷§ƒ⁄»›≤ª¥Ê‘⁄
                ERROR_TRACE("no UPNP-Authenticate find,discard.");
            }
        }
        else
        {
            switch (iStatus)
            {
                case UPNP_STATUS_CODE_REFUSED:
                {
                    ERROR_TRACE("server refused.code="<<iStatus);
                }
                    break;
                case UPNP_STATUS_CODE_NOT_FOUND:
                {
                    ERROR_TRACE("peer not found.code="<<iStatus);
                }
                    break;
                case UPNP_STATUS_CODE_OFFINE:
                {
                    ERROR_TRACE("peer offline.code="<<iStatus);
                }
                    break;
                case UPNP_STATUS_CODE_NOT_REACH:
                {
                    ERROR_TRACE("peer not reach.code="<<iStatus);
                }
                    break;
                default:
                {
                    ERROR_TRACE("rsp failed.code="<<iStatus);
                }
                    break;
            }
            
            std::string strTags = msg.GetValueNoCase(HEADER_NAME_TAGS);
            int first = strTags.find_last_of("seq=");
            if(first == std::string::npos) { 
                ERROR_TRACE("not find seq!");
                return -1;
            } 
            
            std::string strReq = strTags.substr(first+1, strTags.size());
            unsigned int uiReqId = atoi(strReq.c_str());
            
            if (uiReqId>0)
            {
                TransInfo *pTrans;
                pTrans = FetchRequest(uiReqId);
                if ( !pTrans )
                {
                    ERROR_TRACE("not find request.reqid="<<uiReqId);
                    return -1;
                }
                
                pTrans->result = TransInfo::emTaskStatus_Failed;
                pTrans->hEvent.Signal();
            }
            
            return 0;
        }
    }
    
    return 0;
}

//∑¢ÀÕœ˚œ¢
int CISClient::DvipSend(unsigned int id,char *pszMethod,char * pContent,int iContentLength,std::string strGwVCode,bool bDvip)
{
    HttpMessage regMsg;
    regMsg.iType = 1;
    regMsg.iMethod = emMethodPost;
    regMsg.strPath = "/dvip/"+std::string(pszMethod);
    if ( regMsg.strPath.empty() )
    {
        ERROR_TRACE("unsupport endpoint");
        return -1;
    }
    
    regMsg.iContentLength = 0;
    regMsg.SetValue(HEADER_NAME_FROM,m_strVcodeLocal);
    regMsg.SetValue(HEADER_NAME_TO,strGwVCode);
    regMsg.SetValue(HEADER_NAME_TAGS,MakeTags(id));
    
    if (bDvip == false &&
        (!strcmp(pszMethod,"Authorize.factory.instance") 
         || !strcmp(pszMethod,"Authorize.alloc")
         || !strcmp(pszMethod,"Authorize.touch")
         || !strcmp(pszMethod,"Authorize.destroy")
    /*		|| !strcmp(pszMethod,"Authorize.getAuthList")
     || !strcmp(pszMethod,"Authorize.delAuth")*/)
        )
    {
        regMsg.SetValue(HEADER_NAME_ACTION,ACTION_GATEWAYAUTH_REQ);
    }
    else
    {
        regMsg.SetValue(HEADER_NAME_ACTION,ACTION_DVIPMETHOD_REQ);
        
        int iAuthStatus;
        std::string strAuthorization;
        if (GetAuthorization(strGwVCode,iAuthStatus,strAuthorization))
        {
            if ( iAuthStatus > 0  )//¥Ê‘⁄»œ÷§¬Î
            {
                regMsg.SetValue("Upnp-Authorization",strAuthorization);
            }
        }
    }
    
    regMsg.iContentLength = iContentLength;
    
    std::string strMsg = regMsg.ToHttpheader();
    
    LastMsg msg;
    msg.strGwVCode = strGwVCode;
    msg.strMethod = std::string(pszMethod);
    
    if ( pContent && iContentLength > 0 )
    {
        std::string strContent(pContent,iContentLength);
        strMsg += strContent;
        
        msg.strContent = strContent;
    }
    
    //ª∫¥Ê“ªÃı÷∏¡Ó£¨≤¢∑¢ª·”–“Ï≥£
    CacheMsg(msg);
    
    //∑¢ÀÕ«Î«Ûœ˚œ¢
    return SendData((char*)strMsg.c_str(),(int)strMsg.size());
}

int CISClient::Dvip_Touch(std::string strGwVCode)
{
    int iRet = 0;
    int iDataLength = 0;
    int iSendLength = 0;
    unsigned uiReq;
    char szBuf[1024];
    TransInfo *pTask = NULL;
    
    uiReq = CreateReqId();
    CMsg_method_json_b_json_req reqMsg(uiReq,0,0,"Authorize.touch");
    iRet = reqMsg.Encode(szBuf,1024);
    if ( 0 >= iRet )
    {
        ERROR_TRACE("encode failed.");
        return -1;
    }
    pTask = new TransInfo(uiReq,emRT_method_json_b_json,GetCurrentTimeMs(),m_waittime);
    if ( !pTask )
    {
        ERROR_TRACE("out of memory");
        return -1;
    }
    
    //∑¢ÀÕ ˝æ›
    iDataLength = iRet;
    iSendLength = DvipSend(uiReq,"Authorize.touch",szBuf,iDataLength,strGwVCode,true);
    if ( 0 > iSendLength )
    {
        if ( pTask )
        {
            delete pTask;
            pTask = NULL;
        }
        return -1;
    }
    
    AddRequest(uiReq,pTask);
    
    iRet = pTask->hEvent.Wait(0);
    if ( TransInfo::emTaskStatus_Success != pTask->result )
    {
        //ERROR_TRACE("exec failed");
        if ( pTask )
        {
            delete pTask;
        }
        return -1;
    }
    if ( !pTask->pRspMsg )
    {
        ERROR_TRACE("rsp msg failed");
        if ( pTask )
        {
            delete pTask;
        }
        return -1;
    }
    
    CMsg_method_json_b_json_rsp *pRspMsg = (CMsg_method_json_b_json_rsp*)pTask->pRspMsg;
    bool bResult = pRspMsg->m_bResult;
    if ( bResult )
    {
    }
    delete pTask;
    
    return 0;
}

//∂©‘ƒ
int CISClient::Subscrible(std::string strGwVCode)
{
    int iRet = 0;
    bool bRet = false;
    int iReturn = 0;
    unsigned int uiSID = 0;
    
    //¥Ú∞¸∑øº‰–≈œ¢
    Json::Value jsonInParams;
    Json::Value jsonOutParams;
    //jsonInParams["codes"][0] = "DeviceState";
    
    //attach
    iRet = Dvip_method_json_b_json("eventManager.attach",0,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
    if ( 0 > iRet )
    {
        ERROR_TRACE("eventManager.attach failed.strGwVCode="<<strGwVCode);
        iReturn = -1;
    }
    else
    {
        if ( bRet )
        {
            INFO_TRACE("eventManager.attach OK.strGwVCode="<<strGwVCode);
            m_uiSid = 0;
            
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("eventManager.attach failed.strGwVCode="<<strGwVCode);
            iReturn = -1;
        }
    }
    return iReturn;
}

//»°œ˚∂©‘ƒ
int CISClient::Unsubscrible(std::string strGwVCode)
{
    int iRet = 0;
    bool bRet = true;;
    int iReturn = 0;
    
    Json::Value jsonInParams;
    Json::Value jsonOutParams;
    //jsonInParams["SID"] = m_uiSid;
    
    //detach
    iRet = Dvip_method_json_b_json("eventManager.detach",0,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
    if ( 0 > iRet )
    {
        ERROR_TRACE("eventManager.detach failed.strGwVCode="<<strGwVCode);
        iReturn = -1;
        return -1;
    }
    if ( bRet )
    {
        INFO_TRACE("eventManager.detach OK.strGwVCode="<<strGwVCode);
        iReturn = 0;
    }
    else
    {
        ERROR_TRACE("eventManager.detach failed.strGwVCode="<<strGwVCode);
        iReturn = -1;
    }
    
    return iReturn;
}

//∆Ù∂Ø
int CISClient::StartSubThread()
{
    m_bSubExitThread = false;
#ifdef PLAT_WIN32
    DWORD dwThreadId;
    m_hSubThread = CreateThread(NULL,0,CISClient::SubProc,this,0,&dwThreadId);
#else
    pthread_attr_t attr;
    int iRet;
    if ( (iRet = ::pthread_attr_init(&attr)) != 0 ) 
    {
        ERROR_TRACE("pthread_attr_init() failed! error code="<<iRet);
        return -1;
    }
    
    int dstate = PTHREAD_CREATE_JOINABLE;
    
    if ( (iRet = ::pthread_attr_setdetachstate(&attr,dstate)) != 0 ) 
    {
        ERROR_TRACE("pthread_attr_setdetachstate() failed! error code="<<iRet);
        ::pthread_attr_destroy(&attr);
        return -1;
    }
    
    if ((iRet = ::pthread_create(&m_hSubThread, &attr, CISClient::SubProc, this)) != 0) 
    {
        ERROR_TRACE("pthread_create() failed! error code="<<iRet);
        ::pthread_attr_destroy(&attr);
        return -1;
    }
    ::pthread_attr_destroy(&attr);
#endif
    
    return 0;
}
//Ω· ¯
int CISClient::StopSubThread()
{
    m_bSubExitThread = true;
    if ( 0 == m_hSubThread )
    {
        return 0;
    }
#ifdef PLAT_WIN32
    DWORD dwRet;
    dwRet = WaitForSingleObject(m_hSubThread,5000);
    if ( dwRet == WAIT_TIMEOUT )
    {
        TerminateThread(m_hSubThread,0);
    }
    
#else
    void *result;
    pthread_join(m_hSubThread,&result);
#endif
    
    m_hSubThread = 0;
    
    INFO_TRACE("StopSubThread!!!");
    return 0;
}
#ifdef WIN32
unsigned long __stdcall CISClient::SubProc(void *pParam)
#else
void* CISClient::SubProc(void *pParam)
#endif
{
    CISClient *pUser = (CISClient*)pParam;
    pUser->SubProc();
    return 0;
}

void CISClient::SubProc(void)
{
    while ( !m_bSubExitThread )
    {
        if (m_emStatus == emRegistered)
        {
            //∂©‘ƒÕ¯πÿ ¬º˛
            std::list<RemoteGateWay*> listObj = ListObj();
            std::list<RemoteGateWay*>::iterator it;
            for (it=listObj.begin();it!=listObj.end();it++)
            {
                if (m_bSubExitThread )
                {
                    break;
                }
                
                RemoteGateWay* pObj = *it;
                if (!pObj->bRemoteOnline)
                {
                    continue;
                }
                
                std::string strGwVCode = std::string(pObj->gwInfo.szGwVCode);
                int nError = 0;
                bool bLocal = CDvrGeneral::Instance()->IsLocalLogin(strGwVCode,nError);
                if (bLocal == false )
                {
                    if (_abs64(pObj->llLastSubscribeTime-GetCurrentTimeMs()) > CISClient::GS_SUBSCRIBE_INTERVAL)//±æµÿ≤ª‘⁄œﬂ∂¯‘∂≥ÃŒ¥∂©‘ƒ£¨‘Ú¡¢º¥∂©‘ƒ
                    {
                        int iRet = Subscrible(strGwVCode);
                        if (iRet == 0)
                            pObj->bHasSubscribe = true;
                        else
                            pObj->bHasSubscribe = false;
                        
                        pObj->llLastSubscribeTime = GetCurrentTimeMs();
                        *it = pObj;
                        SetSubscribe(strGwVCode,pObj->bHasSubscribe,GetCurrentTimeMs());
                        
                        FclSleep(2000);
                    }
                }
                else
                {
                    if(pObj->bHasSubscribe == true)//±æµÿ‘⁄œﬂ∂¯‘∂≥Ã“—∂©‘ƒ£¨‘Ú¡¢º¥»°œ˚∂©‘ƒ
                    {
                        int iRet = Unsubscrible(strGwVCode);
                        SetSubscribe(strGwVCode,false,GetCurrentTimeMs());
                    }
                }
                
                FclSleep(1);
            }
        }
        FclSleep(1);
    }
}

//—È÷§ ⁄»®¬Î
int CISClient::VerifyAuthCode(const char *sPhoneNumber,const char *sMeid,const char *sAuthCode,std::string strGwVCode)
{
    int iRet = Dvip_Touch(strGwVCode);
    if (iRet == 0)
    {
    }
    else
    {
        WARN_TRACE("timeout,verify failed!");
        SetAuthStatus(strGwVCode,0);
    }
    
    return iRet;
}

//∂¡»°IPC¡–±Ì
int CISClient::GetIPC(std::string &strConfig,std::string strGwVCode)
{
    int iRet = 0;
    unsigned int uiObjectId = 0;
    bool bRet = true;;
    int iReturn = 0;
    
    Json::Value jsonInParams;
    Json::Value jsonOutParams;
    
    std::string strMethod = "configManager.getConfig.IPC";
    iRet = Dvip_method_json_b_json((char*)strMethod.c_str(),0,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
    if ( 0 > iRet )
    {
        ERROR_TRACE(strMethod<<" exec failed.");
        iReturn = -1;
        return iReturn;
    }
    else
    {
        if ( bRet )
        {
            INFO_TRACE(strMethod<<" response ok.");
            strConfig = jsonOutParams.toUnStyledString();
            //strConfig = jsonOutParams.toStyledString();
            
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE(strMethod<<" response failed.");
            iReturn = -1;
        }
    }
    
    INFO_TRACE(strConfig);
    
    return iReturn;
}
