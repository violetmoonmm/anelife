
#include "ShApi.h"
#include "Trace.h"
#include "DvrGeneral.h"
#include "DvipClient.h"
#include "ISClient.h"


// SDK初始化
SH_API bool CALL_METHOD SH_Init(fOnDisConnect cbDisConnect,void *pUser)
{
    char szReleaseNotes[256]={0};
    sprintf(szReleaseNotes,"**sh_sdk, released on %s %s**",__DATE__,__TIME__);
    INFO_TRACE(szReleaseNotes);
    
    //INFO_TRACE("test at 2014-12-27:18:25:00");
    CDvrGeneral::Instance()->SetDisConnectCb(cbDisConnect,pUser);
    return  true;
}

// SDK退出清理
SH_API void CALL_METHOD SH_Cleanup()
{
    CDvrGeneral::UnIstance();
    INFO_TRACE("SH_Cleanup");
}

// Syslog使能
SH_API void CALL_METHOD SH_EnableSyslog(bool bEnable,char *szIp,int iPort)
{
#if defined(NO_LOGLIB) && defined(ANDROID)
    EnableSyslog(bEnable,szIp,iPort);
#endif
}

//------------------------------------------------------------------------


//------------------------------------------------------------------------

// 设置订阅消息回调
SH_API void CALL_METHOD SH_SetEventNotify(fOnEventNotify fcbEvent,void *pUser)
{
    CDvrGeneral::Instance()->SetEventNotifyCb(fcbEvent,pUser);
}

//设置客户端信息
//SH_API void CALL_METHOD SH_SetClientInfo(char * szVCode,char *szPwd,char *szMeid)
//{
//	CDvrGeneral::Instance()->SetClientInfo(szVCode,szPwd,"18900000000",szMeid);
//}

//设置大华云服务连接信息
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

// 添加网关映射,传一次
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

//平台转发使能
SH_API bool CALL_METHOD SH_EnableRemote(bool bEnable)
{
    return CDvrGeneral::Instance()->EnableRemote(bEnable);
}

// 删除网关映射，本地和远程可以独立删除映射，
SH_API bool CALL_METHOD SH_DelGateWay(unsigned int hLoginID)
{
    return CDvrGeneral::Instance()->ReleaseInstance(hLoginID);
}

// 查询在线状态
SH_API bool CALL_METHOD SH_GateWayStatus(unsigned int hLoginID,bool & bLocal,int & nLocalError,
                                         bool & bRemote,int & nRemoteError)
{
    return CDvrGeneral::Instance()->GateWayStatus(hLoginID,bLocal,nLocalError,bRemote,nRemoteError);
}

//获取授权码
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

//验证授权码
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

//网络恢复时通知sdk立即重连网关
SH_API void CALL_METHOD SH_ManuelReconnect()
{
    INFO_TRACE("manuel reconnect");
    CDvrGeneral::Instance()->ManuelReconnect();
}

// 读取配置信息
//szConfigName 配置名称 读取支持的配置 HouseTypeInfo 户型图 Light(CommLight 普通型 LevelLight 可调光) 灯光
//Curtain 窗帘 GroundHeat 地暖 AirCondition 空调 IntelligentAmmeter 智能电表
//AlarmZone 报警防区 IPCamera IP摄像头 SceneMode情景模式 ChangeId配置变更ID
//szBuf 缓冲区 获取
//iBufSize 缓冲区大小 调用时指定szBuf的大小 返回时内部会返回实际结果大小
//注 如果输入缓冲区太小 ,也会失败,此时iBufSize会返回实际需要的缓冲区大小
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
    //szName 配置名称 读取支持的配置 HouseTypeInfo 户型图 Light(CommLight 普通型 LevelLight 可调光) 灯光
    //Curtain 窗帘 GroundHeat 地暖 AirCondition 空调 IntelligentAmmeter 智能电表
    //AlarmZone 报警防区 IPCamera IP摄像头 SceneMode情景模式 ChangeId配置变更ID
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
        //面板查询
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

//智能家居控制
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

//智能家居状态查询,iBufSize建议大于1K
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

//智能家居状态查询,iBufSize建议大于1K
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

// 设置情景模式
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

// 布撤防 password 布撤防密码
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

// 取得防区状态
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

//恢复配置
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

// 共享文件下载，列表查询见GetConfig.ShareFile
// pszShareFile共享文件名 pszLocalPath本地存储路径
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

// 删除授权用户，列表查询见GetConfig.AuthList
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

//重启网关设备
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

//开启设备搜索
SH_API bool CALL_METHOD SH_StartDevFinder(fOnIPSearch pFcb,void *pUser)
{
    return CDvrGeneral::Instance()->MCast_start(pFcb,pUser);
}

//停止设备搜索
SH_API bool CALL_METHOD SH_StopDevFinder()
{
    return CDvrGeneral::Instance()->MCast_stop();
}

//搜索,可指定mac地址
SH_API bool CALL_METHOD SH_IPSearch(char *szMac,bool bGateWayOnly)
{
    return CDvrGeneral::Instance()->MCast_search(szMac,bGateWayOnly);
}
