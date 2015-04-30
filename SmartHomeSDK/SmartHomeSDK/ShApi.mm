
#include "ShApi.h"
#include "Trace.h"
#include "DvrGeneral.h"
#include "DvipClient.h"
#include "ISClient.h"


// SDK��ʼ��
SH_API bool CALL_METHOD SH_Init(fOnDisConnect cbDisConnect,void *pUser)
{
    char szReleaseNotes[256]={0};
    sprintf(szReleaseNotes,"**sh_sdk, released on %s %s**",__DATE__,__TIME__);
    INFO_TRACE(szReleaseNotes);
    
    //INFO_TRACE("test at 2014-12-27:18:25:00");
    CDvrGeneral::Instance()->SetDisConnectCb(cbDisConnect,pUser);
    return  true;
}

// SDK�˳�����
SH_API void CALL_METHOD SH_Cleanup()
{
    CDvrGeneral::UnIstance();
    INFO_TRACE("SH_Cleanup");
}

// Syslogʹ��
SH_API void CALL_METHOD SH_EnableSyslog(bool bEnable,char *szIp,int iPort)
{
#if defined(NO_LOGLIB) && defined(ANDROID)
    EnableSyslog(bEnable,szIp,iPort);
#endif
}

//------------------------------------------------------------------------


//------------------------------------------------------------------------

// ���ö�����Ϣ�ص�
SH_API void CALL_METHOD SH_SetEventNotify(fOnEventNotify fcbEvent,void *pUser)
{
    CDvrGeneral::Instance()->SetEventNotifyCb(fcbEvent,pUser);
}

//���ÿͻ�����Ϣ
//SH_API void CALL_METHOD SH_SetClientInfo(char * szVCode,char *szPwd,char *szMeid)
//{
//	CDvrGeneral::Instance()->SetClientInfo(szVCode,szPwd,"18900000000",szMeid);
//}

//���ô��Ʒ���������Ϣ
SH_API void CALL_METHOD SH_SetServerInfo(UserInfo user,UamsInfo uams)
{
    INFO_TRACE("user: szVCode="<<user.szVCode<<" user.szPwd="
               <<user.szPwd<<" user.szPhoneNumber="<<user.szPhoneNumber
               <<" user.szMeid="<<user.szMeid<<" user.szModel="<<user.szModel);
    INFO_TRACE("uams: szServerVCode="<<uams.szServerVCode<<" uams.szServerIp="<<uams.szServerIp<<" uams.iPort="<<uams.iPort);
    
    if ( !strcmp(user.szPhoneNumber,"")|| !strcmp(user.szMeid,""))
    {
        ERROR_TRACE("SetClientInfo failed! invalid param!");
        return;
    }
    CDvrGeneral::Instance()->SetClientInfo(user.szVCode,user.szPwd,user.szPhoneNumber,user.szMeid,user.szModel);
    
    if (!strcmp(user.szVCode,"")|| !strcmp(user.szPwd,"")
        || !strcmp(uams.szServerVCode,"")|| !strcmp(uams.szServerIp,"")
        || uams.iPort <= 0
        )
    {
        ERROR_TRACE("SH_SetServerInfo failed! invalid param!");
        return;
    }
    CDvrGeneral::Instance()->SetServerInfo(uams.szServerVCode,uams.szServerIp,uams.iPort);
}

// �������ӳ��,��һ��
SH_API unsigned int CALL_METHOD SH_AddGateWay(GatewayInfo gwInfo)
{
    int iRet = 0;
    unsigned int hLoginID  = CDvrGeneral::Instance()->CreateInstance(gwInfo);
    if ( hLoginID == 0)
    {
        ERROR_TRACE("create inst failed.");
        return 0;
    }
    INFO_TRACE("SH_AddGateWay hLoginID="<<hLoginID);
    
    return hLoginID;
}

//ƽ̨ת��ʹ��
SH_API bool CALL_METHOD SH_EnableRemote(bool bEnable)
{
    return CDvrGeneral::Instance()->EnableRemote(bEnable);
}

// ɾ������ӳ�䣬���غ�Զ�̿��Զ���ɾ��ӳ�䣬
SH_API bool CALL_METHOD SH_DelGateWay(unsigned int hLoginID)
{
    return CDvrGeneral::Instance()->ReleaseInstance(hLoginID);
}

// ��ѯ����״̬
SH_API bool CALL_METHOD SH_GateWayStatus(unsigned int hLoginID,bool & bLocal,int & nLocalError,
                                         bool & bRemote,int & nRemoteError)
{
    return CDvrGeneral::Instance()->GateWayStatus(hLoginID,bLocal,nLocalError,bRemote,nRemoteError);
}

//��ȡ��Ȩ��
SH_API int CALL_METHOD SH_GatewayAuth(unsigned int hLoginID,char *szBuf,int iBufSize)
{
    int iRet = 0;
    bool bRet = false;
    
    if ( szBuf == NULL)
    {
        ERROR_TRACE("SH_GatewayAuth failed! invalid param!");
        return emDisRe_ParamInvalid;
    }
    
    CBaseClient *pInst;
    
    GatewayInfo info;
    iRet = CDvrGeneral::Instance()->GetGatewayInfo(hLoginID,info);
    if (iRet < 0)
    {
        ERROR_TRACE("not find gateway info.id="<<hLoginID);
        return emDisRe_ParamInvalid;
    }
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_GatewayAuth not find instance.id="<<hLoginID);
        return emDisRe_Disconnected;
    }
    
    iRet = pInst->GetAuthCode(info.szSn,CDvrGeneral::Instance()->PhoneNo(),
                              CDvrGeneral::Instance()->MEID(),CDvrGeneral::Instance()->Model(),
                              info.szUser,info.szPwd,szBuf,iBufSize,strGwVCode);
    if ( 0 == iRet )
    {
        INFO_TRACE("GetAuthCode ok. szCode="<<szBuf);
    }
    else
    {
    }
    return iRet;
}

//��֤��Ȩ��
SH_API bool CALL_METHOD SH_VerifyAuthCode(unsigned int hLoginID,const char *sAuthCode)
{
    int iRet = 0;
    bool bRet = false;
    if ( sAuthCode == NULL)
    {
        ERROR_TRACE("SH_VerifyAuthCode failed! invalid param!");
        return false;
    }
    
    CBaseClient *pInst;
    CDvrGeneral::Instance()->AuthCode(hLoginID,sAuthCode);
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_VerifyAuthCode not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->VerifyAuthCode(CDvrGeneral::Instance()->PhoneNo(),CDvrGeneral::Instance()->MEID(),
                                 sAuthCode,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    
    return bRet;
}

//����ָ�ʱ֪ͨsdk������������
SH_API void CALL_METHOD SH_ManuelReconnect()
{
    INFO_TRACE("manuel reconnect");
    CDvrGeneral::Instance()->ManuelReconnect();
}

// ��ȡ������Ϣ
//szConfigName �������� ��ȡ֧�ֵ����� HouseTypeInfo ����ͼ Light(CommLight ��ͨ�� LevelLight �ɵ���) �ƹ�
//Curtain ���� GroundHeat ��ů AirCondition �յ� IntelligentAmmeter ���ܵ��
//AlarmZone �������� IPCamera IP����ͷ SceneMode�龰ģʽ ChangeId���ñ��ID
//szBuf ������ ��ȡ
//iBufSize ��������С ����ʱָ��szBuf�Ĵ�С ����ʱ�ڲ��᷵��ʵ�ʽ����С
//ע ������뻺����̫С ,Ҳ��ʧ��,��ʱiBufSize�᷵��ʵ����Ҫ�Ļ�������С
SH_API bool CALL_METHOD SH_GetConfig(unsigned int hLoginID,char *szConfigName,char *szBuf,int *iBufSize)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    std::string strName;
    std::string strConfig;
    int iRealSize;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_GetConfig not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !szConfigName || !szBuf || !iBufSize )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    memset(szBuf,0,*iBufSize);
    
    strName = szConfigName;
    //szName �������� ��ȡ֧�ֵ����� HouseTypeInfo ����ͼ Light(CommLight ��ͨ�� LevelLight �ɵ���) �ƹ�
    //Curtain ���� GroundHeat ��ů AirCondition �յ� IntelligentAmmeter ���ܵ��
    //AlarmZone �������� IPCamera IP����ͷ SceneMode�龰ģʽ ChangeId���ñ��ID
    if (strName == "ChangeId")
    {
        strName = "All";
        iRet = pInst->GetDeviceDigest_Sync(strName,strConfig,strGwVCode);
    }
    else if (/*strName == "Light" || strName=="Curtain"
              || strName == "AirCondition" || strName=="GroundHeat"
              || strName=="IntelligentAmmeter" || */strName=="All"
             /*|| strName == "EnvironmentMonitor" || strName == "BlanketSocket"*/)
    {
        //INFO_TRACE("GetDeviceList_Sync strName="<<strName);
        iRet = pInst->GetDeviceList_Sync(strName,strConfig,strGwVCode);
    }
    else if (strName == "ShareFile")
    {
        //����ѯ
        iRet = pInst->ShareManager_browseDir(strConfig,strGwVCode);
    }
    else if (strName=="IPCamera")
    {
        iRet = pInst->GetIPC(strConfig,strGwVCode);
    }
    else if (strName=="AlarmZone")
    {
        iRet = pInst->GetConfig("Alarm",strConfig,strGwVCode);
    }
    else if (strName == "AuthUser")
    {
        iRet = pInst->AuthManager_getAuthList(strConfig,strGwVCode);
    }
    else
        iRet = pInst->GetConfig(strName,strConfig,strGwVCode);
    
    if ( 0 == iRet )
    {
        bRet = true;
        iRealSize = strConfig.size()+1;
        if ( *iBufSize < iRealSize )
        {
            *iBufSize = iRealSize;
            return false;
        }
        else
        {
            *iBufSize = iRealSize;
            strcpy(szBuf,strConfig.c_str());
            return true;
        }
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

SH_API bool CALL_METHOD SH_SetConfig(unsigned int hLoginID,char *szConfigName,char *szBuf,int iBufSize)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    std::string strName;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_SetConfig not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !szConfigName || !szBuf || !iBufSize )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    
    INFO_TRACE("SH_SetConfig strName="<<szConfigName);
    strName = szConfigName;
    Json::Value jsonConfig;
    Json::Reader jsonParser;
    bRet = jsonParser.parse(szBuf,jsonConfig);
    if ( !bRet )
    {
        ERROR_TRACE("parse szBuf failed.szBuf="<<szBuf);
        return false;
    }
    INFO_TRACE("jsonConfig="<<jsonConfig.toStyledString());
    
    if (strName=="AlarmZone")
    {
        iRet = pInst->SetConfig("Alarm",jsonConfig,strGwVCode);
    }
    else
        iRet = pInst->SetConfig(strName,jsonConfig,strGwVCode);
    
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

//���ܼҾӿ���
SH_API bool CALL_METHOD SH_Control(unsigned int hLoginID,char * pszDevType,char *pszDeviceId,char *pszParams,int iParamsLen)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_Control not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->Control(pszDevType,pszDeviceId,pszParams,iParamsLen,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

//���ܼҾ�״̬��ѯ,iBufSize�������1K
SH_API bool CALL_METHOD SH_GetState(unsigned int hLoginID,char * pszDevType,char *pszDeviceId,
                                    char *szBuf,int iBufSize)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_GetState not find instance.id="<<hLoginID);
        return false;
    }
    
    char szDeviceType[32]={0};
    if (!strcmp(pszDevType,"CommLight") || !strcmp(pszDevType,"LevelLight"))
    {
        strcpy(szDeviceType,"Light");
    }
    else
        strcpy(szDeviceType,pszDevType);
    
    iRet = pInst->GetState(szDeviceType,pszDeviceId,szBuf,iBufSize,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

//���ܼҾ�״̬��ѯ,iBufSize�������1K
SH_API bool CALL_METHOD SH_ReadDevice(unsigned int hLoginID,char * pszDevType,char *pszDeviceId,
                                      char *pszParams,char *szBuf,int iBufSize)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_ReadDevice not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->ReadDevice(pszDevType,pszDeviceId,pszParams,szBuf,iBufSize,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

// �����龰ģʽ
SH_API bool CALL_METHOD SH_SetSceneMode(unsigned int hLoginID,char *pszSceneId)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_SetSceneMode not find instance.id="<<hLoginID);
        return false;
    }
    
    std::string strSceneId = pszSceneId;
    iRet = pInst->SetSceneMode(strSceneId,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

// ������ password ����������
SH_API bool CALL_METHOD SH_SetArmMode(unsigned int hLoginID,char *pszDeviceId,bool bEnable,char *password)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_SetArmMode not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->SetArmMode(pszDeviceId,bEnable,password,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

// ȡ�÷���״̬
SH_API bool CALL_METHOD SH_GetArmMode(unsigned int hLoginID,char *pszDeviceId,bool & bEnable)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_GetArmMode not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->GetArmMode(pszDeviceId,bEnable,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

SH_API bool CALL_METHOD SH_GetVideoCovers(unsigned int hLoginID,char *pszDeviceId,bool & bEnable)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_GetVideoCovers not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->GetVideoCovers(pszDeviceId,bEnable,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

SH_API bool CALL_METHOD SH_SetVideoCovers(unsigned int hLoginID,char *pszDeviceId,bool bEnable)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_SetVideoCovers not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->SetVideoCovers(pszDeviceId,bEnable,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}


SH_API bool CALL_METHOD SH_SetExtraBitrate(unsigned int hLoginID,char *pszDeviceId,int iBitRate)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_SetExtraBitrate not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->SetExtraBitrate(pszDeviceId,iBitRate,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

SH_API bool CALL_METHOD SH_GetExtraBitrate(unsigned int hLoginID,char *pszDeviceId,int & iBitRate)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_SetExtraBitrate not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->GetExtraBitrate(pszDeviceId,iBitRate,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

SH_API bool CALL_METHOD SH_RemoteOpenDoor(unsigned int hLoginID,char *pszShortNumber)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_RemoteOpenDoor not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->RemoteOpenDoor(pszShortNumber,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

//�ָ�����
SH_API bool CALL_METHOD SH_ResetConfig(unsigned int hLoginID)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_ResetConfig not find instance.id="<<hLoginID);
        return false;
    }
    
    std::string strConfig;
    iRet = pInst->MagicBox_Control("resetConfig",strConfig,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

SH_API bool CALL_METHOD SH_RestartDev(unsigned int hLoginID)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_RestartDev not find instance.id="<<hLoginID);
        return false;
    }
    
    std::string strConfig;
    iRet = pInst->MagicBox_Control("restart",strConfig,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

// �����ļ����أ��б��ѯ��GetConfig.ShareFile
// pszShareFile�����ļ��� pszLocalPath���ش洢·��
SH_API bool CALL_METHOD SH_DownloadShareFile(unsigned int hLoginID,char * pszShareFile,char *pszLocalPath)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_RestartDev not find instance.id="<<hLoginID);
        return false;
    }
    
    std::string strConfig;
    iRet = pInst->ShareManager_downloadFile(pszShareFile,pszLocalPath,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

// ɾ����Ȩ�û����б��ѯ��GetConfig.AuthList
SH_API bool CALL_METHOD SH_DelAuth(unsigned int hLoginID,char * pszPhone,char *pszMeid)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_RestartDev not find instance.id="<<hLoginID);
        return false;
    }
    
    std::string strConfig;
    iRet = pInst->AuthManager_delAuth(pszPhone,pszMeid,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

//���������豸
SH_API bool CALL_METHOD SH_RebootDev(unsigned int hLoginID)
{
    int iRet = 0;
    bool bRet = false;
    CBaseClient *pInst;
    
    std::string strGwVCode;
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID,strGwVCode);
    if ( !pInst )
    {
        ERROR_TRACE("SH_RestartDev not find instance.id="<<hLoginID);
        return false;
    }
    
    std::string strConfig;
    //iRet = pInst->MagicBox_Control("reboot",strConfig,strGwVCode);
    iRet = pInst->MagicBox_Control("getSoftwareVersion",strConfig,strGwVCode);
    iRet = pInst->MagicBox_Control("getAdapterVersion",strConfig,strGwVCode);
    if ( 0 == iRet )
    {
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

//�����豸����
SH_API bool CALL_METHOD SH_StartDevFinder(fOnIPSearch pFcb,void *pUser)
{
    return CDvrGeneral::Instance()->MCast_start(pFcb,pUser);
}

//ֹͣ�豸����
SH_API bool CALL_METHOD SH_StopDevFinder()
{
    return CDvrGeneral::Instance()->MCast_stop();
}

//����,��ָ��mac��ַ
SH_API bool CALL_METHOD SH_IPSearch(char *szMac,bool bGateWayOnly)
{
    return CDvrGeneral::Instance()->MCast_search(szMac,bGateWayOnly);
}
