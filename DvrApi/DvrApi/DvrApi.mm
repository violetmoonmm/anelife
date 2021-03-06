#include "DvipMsg.h"
#include "DvrApi.h"
#include "DvrClient.h"
#include "Trace.h"
#include "DvrGeneral.h"

// SDK初始化
bool CALL_METHOD CLIENT_Init_Dvr(fOnDisConnect cbDisConnect,void *pUser)
{
    char szReleaseNotes[256]={0};
    sprintf(szReleaseNotes,"**sh_client_sdk, released on %s %s**",__DATE__,__TIME__);
    INFO_TRACE(szReleaseNotes);
    
    //CDvrClient::Instance()->SetDisConnectCb(cbDisConnect,pUser);
    CDvrGeneral::Instance()->SetDisConnectCb(cbDisConnect,pUser);
    return  true;
}
bool CALL_METHOD CLIENT_InitEx(fOnDisConnectEx cbDisConnect,void *pUser)
{
    char szReleaseNotes[256]={0};
    sprintf(szReleaseNotes,"**sh_client_sdk, released on %s %s**",__DATE__,__TIME__);
    INFO_TRACE(szReleaseNotes);
    //CDvrClient::Instance()->SetDisConnectCb(cbDisConnect,pUser);
    CDvrGeneral::Instance()->SetDisConnectCbEx(cbDisConnect,pUser);
    return  true;
}

// SDK退出清理
void CALL_METHOD CLIENT_Cleanup_Dvr()
{
}
//------------------------------------------------------------------------


//------------------------------------------------------------------------
// 设置是否断线重连
void CALL_METHOD CLIENT_SetAutoReconnect_Dvr(bool bReconnect)
{
    //CDvrClient::Instance()->SetAutoReconnect(bReconnect);
    CDvrGeneral::Instance()->SetAutoReconnect(bReconnect);
}

// 向设备注册
UInt32 CALL_METHOD CLIENT_Login_Dvr(char *pchServIP,UInt16 wServPort,char *pchUsername,char *pchPassword,Int32 *error)
{
    int iRet = 0;
    UInt32 hLoginID = 0;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->CreateInstance();
    if ( !pInst )
    {
        ERROR_TRACE("create inst failed.");
        return 0;
    }
    iRet = pInst->CLIENT_Login(pchServIP,wServPort,pchUsername,pchPassword);
    if ( 0 != iRet )
    {
        CDvrGeneral::Instance()->ReleaseInstance(hLoginID);
    }
    else
    {
        hLoginID = pInst->GetLoginId();
    }
    
    if ( error )
    {
        *error = iRet;
    }
    return hLoginID;
}

// 向设备注销
bool CALL_METHOD CLIENT_Logout_Dvr(UInt32 hLoginID)
{
    int iRet = 0;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    iRet = pInst->Logout_Sync();
    CDvrGeneral::Instance()->ReleaseInstance(hLoginID);
    if ( 0 == iRet )
    {
        return true;
    }
    else
    {
        return false;
    }
}

// 订阅
void CALL_METHOD CLIENT_SetEventNotify_Dvr(fOnEventNotify fcbEvent,void *pUser)
{
    //CDvrClient::Instance()->SetEventNotifyCb(fcbEvent,pUser);
    CDvrGeneral::Instance()->SetEventNotifyCb(fcbEvent,pUser);
}
// 设置报警消息回调
void CALL_METHOD CLIENT_SetAlarmNotify_Dvr(fOnAlarmNotify fcbAlarm,void *pUser)
{
    //CDvrClient::Instance()->SetAlarmNotifyCb(fcbAlarm,pUser);
    CDvrGeneral::Instance()->SetAlarmNotifyCb(fcbAlarm,pUser);
}
bool CALL_METHOD CLIENT_Subscrible(UInt32 hLoginID,bool bIsSubscrible,Int32 waittime)
{
    int iRet = 0;
    bool bRet = true;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( bIsSubscrible )
    {
        iRet = pInst->Subscrible_Sync(waittime);
    }
    else
    {
        iRet = pInst->Unsubscrible_Sync(waittime);
    }
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

//------------------------------------------------------------------------


// 删除配置
bool CALL_METHOD CLIENT_ConfigManager_deleteFile(UInt32 hLoginID,Int32 waittime)
{
    int iRet = 0;
    bool bRet = true;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->ConfigManager_deleteFile(waittime);
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
// 删除指定配置
bool CALL_METHOD CLIENT_ConfigManager_deleteConfig(UInt32 hLoginID
                                                   ,char *pszName
                                                   ,Int32 waittime)

{
    int iRet = 0;
    bool bRet = true;
    std::string strName;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszName )
    {
        strName = "";
    }
    else
    {
        strName = pszName;
    }
    iRet = pInst->ConfigManager_deleteConfig(strName,waittime);
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

// 获取房间信息
bool CALL_METHOD CLIENT_SmartHome_getConfig_HouseTypeInfo(UInt32 hLoginID
                                                          ,LPLAYOUT_FLOOR pFloors
                                                          ,Int32 maxFloors
                                                          ,Int32 *floors
                                                          ,LPLAYOUT_ROOM pRooms
                                                          ,Int32 maxRooms
                                                          ,Int32 *rooms
                                                          ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    int iTemp = 0;
    std::vector<Smarthome_HouseInfo> vecHouses;	//房间列表
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !floors || !rooms )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    if ( maxFloors > 0 && !pFloors || maxRooms > 0 && !pRooms )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->GetHouseInfo_Sync(vecHouses,waittime);
    if ( 0 == iRet )
    {
        bRet = true;
        *floors = vecHouses.size();
        if ( 0 == *floors )
        {
            *rooms = 0;
            return true;
        }
        if ( vecHouses.size() > maxFloors )
        {
            WARN_TRACE("too small buf to floors");
        }
        iTemp = 0;
        for(size_t i=0;i<vecHouses.size();i++)
        {
            if ( i < *floors )
            {
                strcpy(pFloors[i].szName,vecHouses[i].strName.c_str());
                strcpy(pFloors[i].szId,vecHouses[i].strId.c_str());
            }
            for(size_t j=0;j<vecHouses[i].vecAreas.size();j++)
            {
                if ( iTemp < maxRooms )
                {
                    strcpy(pRooms[iTemp].szName,vecHouses[i].vecAreas[j].strName.c_str());
                    strcpy(pRooms[iTemp].szFloor,vecHouses[i].vecAreas[j].strFloorId.c_str());
                    strcpy(pRooms[iTemp].szId,vecHouses[i].vecAreas[j].strId.c_str());
                    if ( vecHouses[i].vecAreas[j].strType == "Kitchen" ) //厨房
                    {
                        pRooms[iTemp].iType = 1;
                    }
                    else if ( vecHouses[i].vecAreas[j].strType == "Livingroom" ) //客厅
                    {
                        pRooms[iTemp].iType = 2;
                    }
                    else if ( vecHouses[i].vecAreas[j].strType == "Diningroom" ) //餐厅
                    {
                        pRooms[iTemp].iType = 3;
                    }
                    else if ( vecHouses[i].vecAreas[j].strType == "Bedroom" ) //卧室
                    {
                        pRooms[iTemp].iType = 4;
                    }
                    else if ( vecHouses[i].vecAreas[j].strType == "Bathroom" ) //卫生间
                    {
                        pRooms[iTemp].iType = 5;
                    }
                    else if ( vecHouses[i].vecAreas[j].strType == "Studyroom" ) //书房
                    {
                        pRooms[iTemp].iType = 6;
                    }
                    else
                    {
                        pRooms[iTemp].iType = 0;
                    }
                    iTemp++;
                }
                else
                {
                    WARN_TRACE("too small buf to rooms");
                    break;
                }
            }
        }
        *rooms = iTemp;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

// 设置房间信息
bool CALL_METHOD CLIENT_SmartHome_setConfig_HouseTypeInfo(UInt32 hLoginID
                                                          ,LPLAYOUT_FLOOR pFloors
                                                          ,Int32 floors
                                                          ,LPLAYOUT_ROOM pRooms
                                                          ,Int32 rooms
                                                          ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    int iTemp = 0;
    std::vector<Smarthome_HouseInfo> vecHouses;	//房间列表
    Smarthome_HouseInfo houseInfo;
    Smarthome_AreaInfo areaInfo;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pFloors || !pRooms )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    for(int i=0;i<floors;i++)
    {
        houseInfo.strName = pFloors[i].szName;
        houseInfo.strId = pFloors[i].szId;
        for(int j=0;j<rooms;j++)
        {
            if ( houseInfo.strId == pRooms[j].szFloor )
            {
                areaInfo.strName =  pRooms[j].szName;
                areaInfo.strId =  pRooms[j].szId;
                areaInfo.strFloorId =  pRooms[j].szFloor;
                if ( 1 == pRooms[j].iType )	//厨房
                {
                    areaInfo.strType = "Kitchen";
                }
                if ( 2 == pRooms[j].iType ) //客厅
                {
                    areaInfo.strType = "Livingroom";
                }
                if ( 3 == pRooms[j].iType )	//餐厅
                {
                    areaInfo.strType = "Diningroom";
                }
                if ( 4 == pRooms[j].iType )	//卧室
                {
                    areaInfo.strType = "Bedroom";
                }
                if ( 5 == pRooms[j].iType )	//卫生间
                {
                    areaInfo.strType = "Bathroom";
                }
                if ( 6 == pRooms[j].iType )	//书房
                {
                    areaInfo.strType = "Studyroom";
                }
                else
                {
                    areaInfo.strType = "Undefined";
                }
                houseInfo.vecAreas.push_back(areaInfo);
            }
        }
        vecHouses.push_back(houseInfo);
    }
    iRet = pInst->SetHouseInfo_Sync(vecHouses,waittime);
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

// 获取情景模式信息
bool CALL_METHOD CLIENT_SmartHome_getConfig_SceneMode(UInt32 hLoginID
                                                      ,int *iCurrentId
                                                      ,LPSMARTHOME_SCENE_MODE pScenes
                                                      ,Int32 maxScenes
                                                      ,Int32 *scenes
                                                      ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    int iTemp = 0;
    std::vector<Smarthome_SceneInfo> vecScenes;	//场景列表
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    //if ( !floors || !rooms )
    //{
    //	ERROR_TRACE("invalid param");
    //	return false;
    //}
    //if ( maxFloors > 0 && !pFloors || maxRooms > 0 && !pRooms )
    //{
    //	ERROR_TRACE("invalid param");
    //	return false;
    //}
    if ( !iCurrentId || maxScenes > 0 && !pScenes )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Get_SceneMode_Sync(*iCurrentId,vecScenes,waittime);
    if ( 0 == iRet )
    {
        bRet = true;
        if ( maxScenes < vecScenes.size() )
        {
            *scenes = maxScenes;
        }
        else
        {
            *scenes = vecScenes.size();
        }
        for(int i=0;i<*scenes;i++)
        {
            strcpy(pScenes[i].szBrand,vecScenes[i].strBrand.c_str());
            strcpy(pScenes[i].szName,vecScenes[i].strName.c_str());
            
            //灯光
            if ( pScenes[i].iLightCount < vecScenes[i].vecLight.size() )
            {
            }
            else
            {
                pScenes[i].iLightCount = vecScenes[i].vecLight.size();
            }
            for( int j=0;j<pScenes[i].iLightCount;j++)
            {
                strcpy(pScenes[i].pLights[j].szId,vecScenes[i].vecLight[j].strDeviceId.c_str());
                strcpy(pScenes[i].pLights[j].szName,vecScenes[i].vecLight[j].strDeviceName.c_str());
                strcpy(pScenes[i].pLights[j].szBrand,vecScenes[i].vecLight[j].strBrand.c_str());
                strcpy(pScenes[i].pLights[j].szAddress,vecScenes[i].vecLight[j].AddrToStr().c_str());
                pScenes[i].pLights[j].iAreaId = vecScenes[i].vecLight[j].iPosID;
                pScenes[i].pLights[j].xPos = vecScenes[i].vecLight[j].xPos;
                pScenes[i].pLights[j].yPos = vecScenes[i].vecLight[j].yPos;
                strcpy(pScenes[i].pLights[j].szState,vecScenes[i].vecLight[j].strState.c_str());
                pScenes[i].pLights[j].iRange = vecScenes[i].vecLight[j].iRange;
                strcpy(pScenes[i].pLights[j].szType,vecScenes[i].vecLight[j].strType.c_str());
            }
            
            //窗帘
            if ( pScenes[i].iCurtainCount < vecScenes[i].vecCurtain.size() )
            {
            }
            else
            {
                pScenes[i].iCurtainCount = vecScenes[i].vecCurtain.size();
            }
            for( int j=0;j<pScenes[i].iCurtainCount;j++)
            {
                strcpy(pScenes[i].pCurtains[j].szId,vecScenes[i].vecCurtain[j].strDeviceId.c_str());
                strcpy(pScenes[i].pCurtains[j].szName,vecScenes[i].vecCurtain[j].strDeviceName.c_str());
                strcpy(pScenes[i].pCurtains[j].szBrand,vecScenes[i].vecCurtain[j].strBrand.c_str());
                strcpy(pScenes[i].pCurtains[j].szAddress,vecScenes[i].vecCurtain[j].AddrToStr().c_str());
                pScenes[i].pCurtains[j].iAreaId = vecScenes[i].vecCurtain[j].iPosID;
                pScenes[i].pCurtains[j].xPos = vecScenes[i].vecCurtain[j].xPos;
                pScenes[i].pCurtains[j].yPos = vecScenes[i].vecCurtain[j].yPos;
                strcpy(pScenes[i].pCurtains[j].szState,vecScenes[i].vecCurtain[j].strState.c_str());
                pScenes[i].pCurtains[j].iRange = vecScenes[i].vecCurtain[j].iRange;
                strcpy(pScenes[i].pCurtains[j].szType,vecScenes[i].vecCurtain[j].strType.c_str());
            }
            
            //地暖
            if ( pScenes[i].iGroundHeatCount < vecScenes[i].vecGroundHeat.size() )
            {
            }
            else
            {
                pScenes[i].iGroundHeatCount = vecScenes[i].vecGroundHeat.size();
            }
            for( int j=0;j<pScenes[i].iGroundHeatCount;j++)
            {
                strcpy(pScenes[i].pGroundHeats[j].szId,vecScenes[i].vecGroundHeat[j].strDeviceId.c_str());
                strcpy(pScenes[i].pGroundHeats[j].szName,vecScenes[i].vecGroundHeat[j].strDeviceName.c_str());
                strcpy(pScenes[i].pGroundHeats[j].szBrand,vecScenes[i].vecGroundHeat[j].strBrand.c_str());
                strcpy(pScenes[i].pGroundHeats[j].szAddress,vecScenes[i].vecGroundHeat[j].AddrToStr().c_str());
                pScenes[i].pGroundHeats[j].iAreaId = vecScenes[i].vecGroundHeat[j].iPosID;
                //pScenes[i].pGroundHeats[j].xPos = vecScenes[i].vecGroundHeat[j].xPos;
                //pScenes[i].pGroundHeats[j].yPos = vecScenes[i].vecGroundHeat[j].yPos;
                strcpy(pScenes[i].pGroundHeats[j].szState,vecScenes[i].vecGroundHeat[j].strState.c_str());
                pScenes[i].pGroundHeats[j].iRange = vecScenes[i].vecGroundHeat[j].iRange;
                //strcpy(pScenes[i].pGroundHeats[j].szType,vecScenes[i].vecGroundHeat[j].strType.c_str());
            }
            
            //空调
            if ( pScenes[i].iAirConditionCount < vecScenes[i].vecAirCondition.size() )
            {
            }
            else
            {
                pScenes[i].iAirConditionCount = vecScenes[i].vecAirCondition.size();
            }
            for( int j=0;j<pScenes[i].iAirConditionCount;j++)
            {
                strcpy(pScenes[i].pAirConditions[j].szId,vecScenes[i].vecAirCondition[j].strDeviceId.c_str());
                strcpy(pScenes[i].pAirConditions[j].szName,vecScenes[i].vecAirCondition[j].strDeviceName.c_str());
                strcpy(pScenes[i].pAirConditions[j].szBrand,vecScenes[i].vecAirCondition[j].strBrand.c_str());
                strcpy(pScenes[i].pAirConditions[j].szAddress,vecScenes[i].vecAirCondition[j].AddrToStr().c_str());
                pScenes[i].pAirConditions[j].iAreaId = vecScenes[i].vecAirCondition[j].iPosID;
                pScenes[i].pAirConditions[j].xPos = vecScenes[i].vecAirCondition[j].xPos;
                pScenes[i].pAirConditions[j].yPos = vecScenes[i].vecAirCondition[j].yPos;
                strcpy(pScenes[i].pAirConditions[j].szState,vecScenes[i].vecAirCondition[j].strState.c_str());
                pScenes[i].pAirConditions[j].iRange = vecScenes[i].vecAirCondition[j].iRange;
                strcpy(pScenes[i].pAirConditions[j].szType,vecScenes[i].vecAirCondition[j].strType.c_str());
                strcpy(pScenes[i].pAirConditions[j].szMode,vecScenes[i].vecAirCondition[j].strMode.c_str());
                strcpy(pScenes[i].pAirConditions[j].szWindMode,vecScenes[i].vecAirCondition[j].strWindMode.c_str());
            }
        }
    }
    else
    {
        bRet = false;
    }
    return bRet;
}
// 设置情景模式信息
bool CALL_METHOD CLIENT_SmartHome_setConfig_SceneMode(UInt32 hLoginID
                                                      ,int iCurrentId
                                                      ,LPSMARTHOME_SCENE_MODE pScenes
                                                      ,Int32 scenes
                                                      ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    int iTemp = 0;
    std::vector<Smarthome_SceneInfo> vecScenes;	//场景列表
    Smarthome_SceneInfo info;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    //if ( !floors || !rooms )
    //{
    //	ERROR_TRACE("invalid param");
    //	return false;
    //}
    //if ( maxFloors > 0 && !pFloors || maxRooms > 0 && !pRooms )
    //{
    //	ERROR_TRACE("invalid param");
    //	return false;
    //}
    
    
    for(int i=0;i<scenes;i++)
    {
        info.strBrand = pScenes[i].szBrand;
        info.strName = pScenes[i].szName;
        
        for( int j=0;j<pScenes[i].iLightCount;j++)
        {
            Smarthome_Light light;
            light.strDeviceId = pScenes[i].pLights[j].szId;
            light.strDeviceName = pScenes[i].pLights[j].szName;
            light.strBrand = pScenes[i].pLights[j].szBrand;
            light.AddrFromStr(pScenes[i].pLights[j].szAddress);
            light.iPosID = pScenes[i].pLights[j].iAreaId;
            light.xPos = pScenes[i].pLights[j].xPos;
            light.yPos = pScenes[i].pLights[j].yPos;
            light.strState = pScenes[i].pLights[j].szState;
            light.iRange = pScenes[i].pLights[j].iRange;
            light.strType = pScenes[i].pLights[j].szType;
            info.vecLight.push_back(light);
            light.strDeviceId = "";
            light.strDeviceName = "";;
            light.strBrand = "";;
            light.vecAddress.clear();
            light.iPosID = -1;
            light.xPos = -1;
            light.yPos = -1;
            light.strState = "";
            light.iRange = -1;
            light.strType = "";
        }
        
        //窗帘
        for( int j=0;j<pScenes[i].iCurtainCount;j++)
        {
            Smarthome_Curtain curtain;
            curtain.strDeviceId = pScenes[i].pCurtains[j].szId;
            curtain.strDeviceName = pScenes[i].pCurtains[j].szName;
            curtain.strBrand = pScenes[i].pCurtains[j].szBrand;
            curtain.AddrFromStr(pScenes[i].pCurtains[j].szAddress);
            curtain.iPosID = pScenes[i].pCurtains[j].iAreaId;
            curtain.xPos = pScenes[i].pCurtains[j].xPos;
            curtain.yPos = pScenes[i].pCurtains[j].yPos;
            curtain.strState = pScenes[i].pCurtains[j].szState;
            curtain.iRange = pScenes[i].pCurtains[j].iRange;
            curtain.strType = pScenes[i].pCurtains[j].szType;
            info.vecCurtain.push_back(curtain);
            curtain.strDeviceId = "";
            curtain.strDeviceName = "";;
            curtain.strBrand = "";;
            curtain.vecAddress.clear();
            curtain.iPosID = -1;
            curtain.xPos = -1;
            curtain.yPos = -1;
            curtain.strState = "";
            curtain.iRange = -1;
            curtain.strType = "";
        }
        
        //地暖
        for( int j=0;j<pScenes[i].iGroundHeatCount;j++)
        {
            Smarthome_GroundHeat groundHeat;
            groundHeat.strDeviceId = pScenes[i].pGroundHeats[j].szId;
            groundHeat.strDeviceName = pScenes[i].pGroundHeats[j].szName;
            groundHeat.strBrand = pScenes[i].pGroundHeats[j].szBrand;
            groundHeat.AddrFromStr(pScenes[i].pGroundHeats[j].szAddress);
            groundHeat.iPosID = pScenes[i].pGroundHeats[j].iAreaId;
            //groundHeat.xPos = pScenes[i].pGroundHeats[j].xPos;
            //groundHeat.yPos = pScenes[i].pGroundHeats[j].yPos;
            groundHeat.strState = pScenes[i].pGroundHeats[j].szState;
            groundHeat.iRange = pScenes[i].pGroundHeats[j].iRange;
            //groundHeat.strType = pScenes[i].pGroundHeats[j].szType;
            info.vecGroundHeat.push_back(groundHeat);
            groundHeat.strDeviceId = "";
            groundHeat.strDeviceName = "";;
            groundHeat.strBrand = "";;
            groundHeat.vecAddress.clear();
            groundHeat.iPosID = -1;
            //groundHeat.xPos = -1;
            //groundHeat.yPos = -1;
            groundHeat.strState = "";
            groundHeat.iRange = -1;
            //groundHeat.strType = "";
        }
        
        //空调
        for( int j=0;j<pScenes[i].iAirConditionCount;j++)
        {
            Smarthome_AirCondition airCondition;
            airCondition.strDeviceId = pScenes[i].pAirConditions[j].szId;
            airCondition.strDeviceName = pScenes[i].pAirConditions[j].szName;
            airCondition.strBrand = pScenes[i].pAirConditions[j].szBrand;
            airCondition.AddrFromStr(pScenes[i].pAirConditions[j].szAddress);
            airCondition.iPosID = pScenes[i].pAirConditions[j].iAreaId;
            airCondition.xPos = pScenes[i].pAirConditions[j].xPos;
            airCondition.yPos = pScenes[i].pAirConditions[j].yPos;
            airCondition.strState = pScenes[i].pAirConditions[j].szState;
            airCondition.iRange = pScenes[i].pAirConditions[j].iRange;
            airCondition.strType = pScenes[i].pAirConditions[j].szType;
            airCondition.strMode = pScenes[i].pAirConditions[j].szMode;
            airCondition.strWindMode = pScenes[i].pAirConditions[j].szWindMode;
            info.vecAirCondition.push_back(airCondition);
            airCondition.strDeviceId = "";
            airCondition.strDeviceName = "";;
            airCondition.strBrand = "";;
            airCondition.vecAddress.clear();
            airCondition.iPosID = -1;
            airCondition.xPos = -1;
            airCondition.yPos = -1;
            airCondition.strState = "";
            airCondition.iRange = -1;
            airCondition.strType = "";
            airCondition.strMode = "";
            airCondition.strWindMode = "";
        }
        vecScenes.push_back(info);
        info.vecLight.clear();
        info.vecCurtain.clear();
        info.vecGroundHeat.clear();
        info.vecAirCondition.clear();
    }
    
    iRet = pInst->Set_SceneMode_Sync(iCurrentId,vecScenes,waittime);
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

// 获取UPNP设备列表
bool CALL_METHOD CLIENT_SmartHome_getDeviceList(UInt32 hLoginID
                                                ,LPSMARTHOME_DEVICE pDevices
                                                ,Int32 maxlen
                                                ,Int32 *devicecount
                                                ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    std::vector<Smarthome_DeviceInfo> vecDevice;	//设备列表
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pDevices || !devicecount )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->GetDeviceList_Sync(vecDevice,waittime);
    if ( 0 == iRet )
    {
        bRet = true;
        if ( vecDevice.size() > 0 )
        {
            if ( maxlen >= vecDevice.size() )
            {
                *devicecount = (int)vecDevice.size();
            }
            else
            {
                *devicecount = maxlen;
                if ( maxlen <= 0 )
                {
                    *devicecount = 0;
                    return false;
                }
            }
            for(int i=0;i<*devicecount;i++)
            {
                strcpy(pDevices[i].szDeviceType,vecDevice[i].strDeviceType.c_str());
                strcpy(pDevices[i].szDeviceId,vecDevice[i].strDeviceId.c_str());
                strcpy(pDevices[i].szDeviceName,vecDevice[i].strDeviceName.c_str());
                sprintf(pDevices[i].szRoomId,"%d",vecDevice[i].iAreaID);
            }
        }
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

CLIENT_API bool CALL_METHOD CLIENT_SmartHome_getDeviceDigest(UInt32 hLoginID
                                                             ,char *pszType
                                                             ,char *pszDigest
                                                             ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    std::string strType = pszType;
    std::string strDigest;
    iRet = pInst->GetDeviceDigest_Sync(strType,strDigest,waittime);
    if ( 0 == iRet )
    {
        strcpy(pszType,strDigest.c_str());
        
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

bool CALL_METHOD CLIENT_SmartHome_setDeviceInfo(UInt32 hLoginID,char *pszDeviceId,char * pszName,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->SetDeviceInfo_Sync(pszDeviceId,pszName,waittime);
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

// 获取智能家居情景模式
bool CALL_METHOD CLIENT_SmartHome_getSceneMode(UInt32 hLoginID
                                               ,char *pszScene
                                               ,Int32 length
                                               ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    std::string strMode;	//模式名称
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszScene || length <= 0 )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Get_SceneMode_Sync(strMode,waittime);
    if ( 0 == iRet )
    {
        bRet = true;
        if ( strMode.size() >= length )
        {
            WARN_TRACE("too small in buffer,trunced");
            strncpy(pszScene,strMode.c_str(),length-1);
        }
        else
        {
            strcpy(pszScene,strMode.c_str());
        }
    }
    else
    {
        bRet = false;
    }
    return bRet;
}
// 设置情景模式
bool CALL_METHOD CLIENT_SmartHome_setSceneMode(UInt32 hLoginID
                                               ,char *pszSceneId
                                               ,Int32 waittime)

{
    int iRet = 0;
    bool bRet = false;
    std::string strMode;	//模式ID
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszSceneId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    strMode = pszSceneId;
    iRet = pInst->Set_SceneMode_Sync(strMode,waittime);
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

// 保存情景模式,pszScene名称，pDevices设备列表
bool CALL_METHOD CLIENT_SmartHome_saveSceneMode(UInt32 hLoginID
                                                ,char *pszScene
                                                ,LPSMARTHOME_DEVICE pDevices
                                                ,Int32 devices
                                                ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    std::string strName;	//模式名称
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszScene )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    strName = pszScene;
    std::vector<Smarthome_DeviceInfo> vecDevice;
    for (int i = 0;i<devices;i++)
    {
        Smarthome_DeviceInfo tmpDevice;
        memset(&tmpDevice,0,sizeof(Smarthome_DeviceInfo));
        tmpDevice.strDeviceId = pDevices[i].szDeviceId;
        vecDevice.push_back(tmpDevice);
    }
    
    iRet = pInst->Save_SceneMode_Sync(strName,vecDevice,waittime);
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

// 修改情景模式名称,pszSceneId模式ID,pszScene名称
bool CALL_METHOD CLIENT_SmartHome_modifySceneMode(UInt32 hLoginID
                                                  ,char *pszSceneId
                                                  ,char *pszScene
                                                  ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    std::string strMode;	//模式id
    std::string strName;	//模式名称
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszSceneId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    strMode = pszSceneId;
    strName = pszScene;
    iRet = pInst->Modify_SceneMode_Sync(strMode,strName,waittime);
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

// 删除情景模式，pszSceneId
bool CALL_METHOD CLIENT_SmartHome_removeSceneMode(UInt32 hLoginID
                                                  ,char *pszSceneId
                                                  ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    std::string strMode;	//模式名称
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszSceneId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    strMode = pszSceneId;
    iRet = pInst->Remove_SceneMode_Sync(strMode,waittime);
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

////////////////////////////灯光
// 获取灯光信息
bool CALL_METHOD CLIENT_Light_getConfig(UInt32 hLoginID
                                        ,LPLIGHT_CONFIG pDevices
                                        ,Int32 maxDevices
                                        ,Int32 *devices
                                        ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    int iTemp = 0;
    std::vector<Smarthome_Light> vecDevices;	//
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !devices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    if ( maxDevices > 0 && !pDevices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Light_getConfig_Sync(vecDevices,waittime);
    if ( 0 == iRet )
    {
        bRet = true;
        *devices = vecDevices.size();
        if ( 0 == *devices )
        {
            return true;
        }
        if ( vecDevices.size() > maxDevices )
        {
            WARN_TRACE("too small buf to floors");
            *devices = maxDevices;
        }
        iTemp = 0;
        for(size_t i=0;i<vecDevices.size();i++)
        {
            if ( i < *devices )
            {
                strcpy(pDevices[i].szId,vecDevices[i].strDeviceId.c_str());
                strcpy(pDevices[i].szName,vecDevices[i].strDeviceName.c_str());
                strcpy(pDevices[i].szBrand,vecDevices[i].strBrand.c_str());
                strcpy(pDevices[i].szAddress,vecDevices[i].AddrToStr().c_str());
                pDevices[i].iAreaId = vecDevices[i].iPosID;
                pDevices[i].xPos = vecDevices[i].xPos;
                pDevices[i].yPos = vecDevices[i].yPos;
                strcpy(pDevices[i].szState,vecDevices[i].strState.c_str());
                pDevices[i].iRange = vecDevices[i].iRange;
                strcpy(pDevices[i].szType,vecDevices[i].strType.c_str());
            }
        }
    }
    else
    {
        bRet = false;
    }
    return bRet;
}
// 设置灯光信息
bool CALL_METHOD CLIENT_Light_setConfig(UInt32 hLoginID
                                        ,LPLIGHT_CONFIG pDevices
                                        ,Int32 devices
                                        ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    int iTemp = 0;
    std::vector<Smarthome_Light> vecDevices;	//
    Smarthome_Light devInfo;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pDevices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    for(int i=0;i<devices;i++)
    {
        devInfo.strDeviceId = pDevices[i].szId;
        devInfo.strDeviceName = pDevices[i].szName;
        devInfo.strBrand = pDevices[i].szBrand;
        devInfo.AddrFromStr(pDevices[i].szAddress);
        devInfo.iPosID = pDevices[i].iAreaId;
        devInfo.xPos = pDevices[i].xPos;
        devInfo.yPos = pDevices[i].yPos;
        devInfo.strState = pDevices[i].szState;
        devInfo.iRange = pDevices[i].iRange;
        devInfo.strType = pDevices[i].szType;
        vecDevices.push_back(devInfo);
        devInfo.vecAddress.clear();
    }
    iRet = pInst->Light_setConfig_Sync(vecDevices,waittime);
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

// 灯光控制 开
bool CALL_METHOD CLIENT_Light_open(UInt32 hLoginID,char *pszDeviceId,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->SetPowerOn_Sync(pszDeviceId,waittime);
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
// 灯光控制 关
bool CALL_METHOD CLIENT_Light_close(UInt32 hLoginID,char *pszDeviceId,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->SetPowerOff_Sync(pszDeviceId,waittime);
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

// 灯光控制 设置灯光亮度
bool CALL_METHOD CLIENT_Light_setBrightLevel(UInt32 hLoginID,char *pszDeviceId,int iLevel,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Light_setBrightLevel_Sync(pszDeviceId,iLevel,waittime);
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
// 灯光控制 调节灯光亮度
bool CALL_METHOD CLIENT_Light_adjustBright(UInt32 hLoginID,char *pszDeviceId,int iLevel,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Light_adjustBright_Sync(pszDeviceId,iLevel,waittime);
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

// 灯光控制 延时关灯
bool CALL_METHOD CLIENT_Light_keepOn(UInt32 hLoginID,char *pszDeviceId,int iTime,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Light_keepOn_Sync(pszDeviceId,iTime,waittime);
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
// 灯光控制 灯闪烁
bool CALL_METHOD CLIENT_Light_blink(UInt32 hLoginID,char *pszDeviceId,int iTime,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Light_blink_Sync(pszDeviceId,iTime,waittime);
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
// 灯光控制 以指定速度打开一组灯
bool CALL_METHOD CLIENT_Light_openGroup(UInt32 hLoginID,char *pszDeviceId,int iType,int iSpeed,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Light_openGroup_Sync(pszDeviceId,iType,iSpeed,waittime);
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
// 灯光控制 以指定速度关闭一组灯
bool CALL_METHOD CLIENT_Light_closeGroup(UInt32 hLoginID,char *pszDeviceId,int iType,int iSpeed,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Light_closeGroup_Sync(pszDeviceId,iType,iSpeed,waittime);
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
// 灯光控制 以指定速度调亮灯光
bool CALL_METHOD CLIENT_Light_brightLevelUp(UInt32 hLoginID,char *pszDeviceId,int iType,int iSpeed,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Light_brightLevelUp_Sync(pszDeviceId,iType,iSpeed,waittime);
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
// 灯光控制 以指定速度调暗灯光
bool CALL_METHOD CLIENT_Light_brightLevelDown(UInt32 hLoginID,char *pszDeviceId,int iType,int iSpeed,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Light_brightLevelDown_Sync(pszDeviceId,iType,iSpeed,waittime);
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
// 灯光控制 获取灯状态
bool CALL_METHOD CLIENT_Light_getState(UInt32 hLoginID
                                       ,char *pszDeviceId
                                       ,LPLIGHT_STATE pState
                                       ,Int32 waittime)
{
    int iRet = 0;
    bool bIsOnline = false;
    bool bIsOn = false;
    int iBright = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId || !pState )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->GetPowerStatus_Sync(pszDeviceId,bIsOnline,bIsOn,iBright,waittime);
    if ( 0 == iRet )
    {
        bRet = true;
        pState->bIsOnline = bIsOnline;
        pState->bIsOn = bIsOn;
        pState->iBright = iBright;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}



////////////////////////////窗帘
// 获取窗帘配置
CLIENT_API bool CALL_METHOD CLIENT_Curtain_getConfig(UInt32 hLoginID
                                                     ,LPCURTAIN_CONFIG pDevices
                                                     ,Int32 maxDevices
                                                     ,Int32 *devices
                                                     ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    int iTemp = 0;
    std::vector<Smarthome_Curtain> vecDevices;	//
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !devices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    if ( maxDevices > 0 && !pDevices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Curtain_getConfig_Sync(vecDevices,waittime);
    if ( 0 == iRet )
    {
        bRet = true;
        *devices = vecDevices.size();
        if ( 0 == *devices )
        {
            return true;
        }
        if ( vecDevices.size() > maxDevices )
        {
            WARN_TRACE("too small buf to floors");
            *devices = maxDevices;
        }
        iTemp = 0;
        for(size_t i=0;i<vecDevices.size();i++)
        {
            if ( i < *devices )
            {
                strcpy(pDevices[i].szId,vecDevices[i].strDeviceId.c_str());
                strcpy(pDevices[i].szName,vecDevices[i].strDeviceName.c_str());
                strcpy(pDevices[i].szBrand,vecDevices[i].strBrand.c_str());
                strcpy(pDevices[i].szAddress,vecDevices[i].AddrToStr().c_str());
                pDevices[i].iAreaId = vecDevices[i].iPosID;
                pDevices[i].xPos = vecDevices[i].xPos;
                pDevices[i].yPos = vecDevices[i].yPos;
                strcpy(pDevices[i].szState,vecDevices[i].strState.c_str());
                pDevices[i].iRange = vecDevices[i].iRange;
                strcpy(pDevices[i].szType,vecDevices[i].strType.c_str());
            }
        }
    }
    else
    {
        bRet = false;
    }
    return bRet;
}
// 设置窗帘配置
CLIENT_API bool CALL_METHOD CLIENT_Curtain_setConfig(UInt32 hLoginID
                                                     ,LPCURTAIN_CONFIG pDevices
                                                     ,Int32 devices
                                                     ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    int iTemp = 0;
    std::vector<Smarthome_Curtain> vecDevices;	//
    Smarthome_Curtain devInfo;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pDevices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    for(int i=0;i<devices;i++)
    {
        devInfo.strDeviceId = pDevices[i].szId;
        devInfo.strDeviceName = pDevices[i].szName;
        devInfo.strBrand = pDevices[i].szBrand;
        devInfo.AddrFromStr(pDevices[i].szAddress);
        devInfo.iPosID = pDevices[i].iAreaId;
        devInfo.xPos = pDevices[i].xPos;
        devInfo.yPos = pDevices[i].yPos;
        devInfo.strState = pDevices[i].szState;
        devInfo.iRange = pDevices[i].iRange;
        devInfo.strType = pDevices[i].szType;
        vecDevices.push_back(devInfo);
        devInfo.vecAddress.clear();
    }
    iRet = pInst->Curtain_setConfig_Sync(vecDevices,waittime);
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
//打开
bool CALL_METHOD CLIENT_Curtain_open(UInt32 hLoginID,char *pszDeviceId,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Curtain_open_Sync(pszDeviceId,waittime);
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
//关闭
bool CALL_METHOD CLIENT_Curtain_close(UInt32 hLoginID,char *pszDeviceId,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Curtain_close_Sync(pszDeviceId,waittime);
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
//停止
bool CALL_METHOD CLIENT_Curtain_stop(UInt32 hLoginID,char *pszDeviceId,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Curtain_stop_Sync(pszDeviceId,waittime);
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
//调整窗帘遮光�
bool CALL_METHOD CLIENT_Curtain_adjustShading(UInt32 hLoginID,char *pszDeviceId,int iScale,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Curtain_adjustShading_Sync(pszDeviceId,iScale,waittime);
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

//设置窗帘遮光�
CLIENT_API bool CALL_METHOD CLIENT_Curtain_setShading(UInt32 hLoginID,char *pszDeviceId,int iScale,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Curtain_setShading_Sync(pszDeviceId,iScale,waittime);
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

//获取窗帘设备状态
bool CALL_METHOD CLIENT_Curtain_getState(UInt32 hLoginID
                                         ,char *pszDeviceId
                                         ,LPCURTAIN_STATE pState
                                         ,Int32 waittime)
{
    int iRet = 0;
    bool bIsOnline = false;
    bool bIsOn = false;
    int iShading = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId || !pState )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Curtain_getState_Sync(pszDeviceId,bIsOnline,bIsOn,iShading,waittime);
    if ( 0 == iRet )
    {
        bRet = true;
        pState->bIsOnline = bIsOnline;
        pState->bIsOn = bIsOn;
        pState->iShading = iShading;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}


///地暖
// 获取地暖配置
CLIENT_API bool CALL_METHOD CLIENT_GroundHeat_getConfig(UInt32 hLoginID
                                                        ,LPGROUNDHEAT_CONFIG pDevices
                                                        ,Int32 maxDevices
                                                        ,Int32 *devices
                                                        ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    int iTemp = 0;
    std::vector<Smarthome_GroundHeat> vecDevices;	//
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !devices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    if ( maxDevices > 0 && !pDevices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->GroundHeat_getConfig_Sync(vecDevices,waittime);
    if ( 0 == iRet )
    {
        bRet = true;
        *devices = vecDevices.size();
        if ( 0 == *devices )
        {
            return true;
        }
        if ( vecDevices.size() > maxDevices )
        {
            WARN_TRACE("too small buf to floors");
            *devices = maxDevices;
        }
        iTemp = 0;
        for(size_t i=0;i<vecDevices.size();i++)
        {
            if ( i < *devices )
            {
                strcpy(pDevices[i].szId,vecDevices[i].strDeviceId.c_str());
                strcpy(pDevices[i].szName,vecDevices[i].strDeviceName.c_str());
                strcpy(pDevices[i].szBrand,vecDevices[i].strBrand.c_str());
                strcpy(pDevices[i].szAddress,vecDevices[i].AddrToStr().c_str());
                pDevices[i].iAreaId = vecDevices[i].iPosID;
                //pDevices[i].xPos = vecDevices[i].xPos;
                //pDevices[i].yPos = vecDevices[i].yPos;
                strcpy(pDevices[i].szState,vecDevices[i].strState.c_str());
                pDevices[i].iRange = vecDevices[i].iRange;
                //strcpy(pDevices[i].szType,vecDevices[i].strType.c_str());
            }
        }
    }
    else
    {
        bRet = false;
    }
    return bRet;
}
// 设置地暖配置
CLIENT_API bool CALL_METHOD CLIENT_GroundHeat_setConfig(UInt32 hLoginID
                                                        ,LPGROUNDHEAT_CONFIG pDevices
                                                        ,Int32 devices
                                                        ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    int iTemp = 0;
    std::vector<Smarthome_GroundHeat> vecDevices;	//
    Smarthome_GroundHeat devInfo;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pDevices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    for(int i=0;i<devices;i++)
    {
        devInfo.strDeviceId = pDevices[i].szId;
        devInfo.strDeviceName = pDevices[i].szName;
        devInfo.strBrand = pDevices[i].szBrand;
        devInfo.AddrFromStr(pDevices[i].szAddress);
        devInfo.iPosID = pDevices[i].iAreaId;
        //devInfo.xPos = pDevices[i].xPos;
        //devInfo.yPos = pDevices[i].yPos;
        devInfo.strState = pDevices[i].szState;
        devInfo.iRange = pDevices[i].iRange;
        //devInfo.strType = pDevices[i].szType;
        vecDevices.push_back(devInfo);
        devInfo.vecAddress.clear();
    }
    iRet = pInst->GroundHeat_setConfig_Sync(vecDevices,waittime);
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
// 开
bool CALL_METHOD CLIENT_GroundHeat_open(UInt32 hLoginID,char *pszDeviceId,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->GroundHeat_open_Sync(pszDeviceId,waittime);
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
// 关
bool CALL_METHOD CLIENT_GroundHeat_close(UInt32 hLoginID,char *pszDeviceId,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->GroundHeat_close_Sync(pszDeviceId,waittime);
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
// 设定地暖温度
bool CALL_METHOD CLIENT_GroundHeat_setTemperature(UInt32 hLoginID,char *pszDeviceId,int iTemperature,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->GroundHeat_setTemperature_Sync(pszDeviceId,iTemperature,waittime);
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
// 调节地暖温度
bool CALL_METHOD CLIENT_GroundHeat_adjustTemperature(UInt32 hLoginID,char *pszDeviceId,int iScale,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->GroundHeat_adjustTemperature_Sync(pszDeviceId,iScale,waittime);
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
// 获取地暖状态
bool CALL_METHOD CLIENT_GroundHeat_getState(UInt32 hLoginID,char *pszDeviceId,LPGROUNDHEAT_STATE pState,Int32 waittime)
{
    int iRet = 0;
    bool bIsOnline = false;
    bool bIsOn = false;
    int iTemperature = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId || !pState )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->GroundHeat_getState_Sync(pszDeviceId,bIsOnline,bIsOn,iTemperature,waittime);
    if ( 0 == iRet )
    {
        bRet = true;
        pState->bIsOnline = bIsOnline;
        pState->bIsOn = bIsOn;
        pState->iTemperature = iTemperature;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}


///空调
// 获取空调配置
bool CALL_METHOD CLIENT_AirCondition_getConfig(UInt32 hLoginID
                                               ,LPAIRCONDITION_CONFIG pDevices
                                               ,Int32 maxDevices
                                               ,Int32 *devices
                                               ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    int iTemp = 0;
    std::vector<Smarthome_AirCondition> vecDevices;	//
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !devices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    if ( maxDevices > 0 && !pDevices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->AirCondition_getConfig_Sync(vecDevices,waittime);
    if ( 0 == iRet )
    {
        bRet = true;
        *devices = vecDevices.size();
        if ( 0 == *devices )
        {
            return true;
        }
        if ( vecDevices.size() > maxDevices )
        {
            WARN_TRACE("too small buf to floors");
            *devices = maxDevices;
        }
        iTemp = 0;
        for(size_t i=0;i<vecDevices.size();i++)
        {
            if ( i < *devices )
            {
                strcpy(pDevices[i].szId,vecDevices[i].strDeviceId.c_str());
                strcpy(pDevices[i].szName,vecDevices[i].strDeviceName.c_str());
                strcpy(pDevices[i].szBrand,vecDevices[i].strBrand.c_str());
                strcpy(pDevices[i].szAddress,vecDevices[i].AddrToStr().c_str());
                pDevices[i].iAreaId = vecDevices[i].iPosID;
                pDevices[i].xPos = vecDevices[i].xPos;
                pDevices[i].yPos = vecDevices[i].yPos;
                strcpy(pDevices[i].szState,vecDevices[i].strState.c_str());
                pDevices[i].iRange = vecDevices[i].iRange;
                strcpy(pDevices[i].szType,vecDevices[i].strType.c_str());
                strcpy(pDevices[i].szMode,vecDevices[i].strMode.c_str());
                strcpy(pDevices[i].szWindMode,vecDevices[i].strWindMode.c_str());
            }
        }
    }
    else
    {
        bRet = false;
    }
    return bRet;
}
// 设置空调配置
bool CALL_METHOD CLIENT_AirCondition_setConfig(UInt32 hLoginID
                                               ,LPAIRCONDITION_CONFIG pDevices
                                               ,Int32 devices
                                               ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    int iTemp = 0;
    std::vector<Smarthome_AirCondition> vecDevices;	//
    Smarthome_AirCondition devInfo;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pDevices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    for(int i=0;i<devices;i++)
    {
        devInfo.strDeviceId = pDevices[i].szId;
        devInfo.strDeviceName = pDevices[i].szName;
        devInfo.strBrand = pDevices[i].szBrand;
        devInfo.AddrFromStr(pDevices[i].szAddress);
        devInfo.iPosID = pDevices[i].iAreaId;
        devInfo.xPos = pDevices[i].xPos;
        devInfo.yPos = pDevices[i].yPos;
        devInfo.strState = pDevices[i].szState;
        devInfo.iRange = pDevices[i].iRange;
        devInfo.strType = pDevices[i].szType;
        devInfo.strMode = pDevices[i].szMode;
        devInfo.strWindMode = pDevices[i].szWindMode;
        vecDevices.push_back(devInfo);
        devInfo.vecAddress.clear();
    }
    iRet = pInst->AirCondition_setConfig_Sync(vecDevices,waittime);
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
// 开
bool CALL_METHOD CLIENT_AirCondition_open(UInt32 hLoginID,char *pszDeviceId,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->AirCondition_open_Sync(pszDeviceId,waittime);
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
// 关
bool CALL_METHOD CLIENT_AirCondition_close(UInt32 hLoginID,char *pszDeviceId,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->AirCondition_close_Sync(pszDeviceId,waittime);
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
// 设定空调温度
bool CALL_METHOD CLIENT_AirCondition_setTemperature(UInt32 hLoginID,char *pszDeviceId,int iTemperture,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->AirCondition_setTemperature_Sync(pszDeviceId,iTemperture,waittime);
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
// 调节温度
bool CALL_METHOD CLIENT_AirCondition_adjustTemperature(UInt32 hLoginID,char *pszDeviceId,int iScale,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->AirCondition_adjustTemperature_Sync(pszDeviceId,iScale,waittime);
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
// 设置工作模式
bool CALL_METHOD CLIENT_AirCondition_setMode(UInt32 hLoginID,char *pszDeviceId,char *pszMode,int iTemperture,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    std::string strMode;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId || !pszMode )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    strMode = pszMode;
    iRet = pInst->AirCondition_setMode_Sync(pszDeviceId,strMode,iTemperture,waittime);
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
// 设置送风模式
bool CALL_METHOD CLIENT_AirCondition_setWindMode(UInt32 hLoginID,char *pszDeviceId,char *pszWindMode,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    std::string strWindMode;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId || !pszWindMode )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    strWindMode = pszWindMode;
    iRet = pInst->AirCondition_setWindMode_Sync(pszDeviceId,strWindMode,waittime);
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

CLIENT_API bool CALL_METHOD CLIENT_AirCondition_oneKeyControl(UInt32 hLoginID,char *pszDeviceId,bool bIsOn,char *pszMode,
                                                              int iTemperature,char * pszWindMode,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    std::string strMode;
    std::string strWindMode;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId)
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    strMode = pszMode;
    strWindMode = pszWindMode;
    iRet = pInst->AirCondition_oneKeyControl(pszDeviceId,bIsOn,strMode,iTemperature,strWindMode,waittime);
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

// 取得空调状态
bool CALL_METHOD CLIENT_AirCondition_getState(UInt32 hLoginID,char *pszDeviceId,LPAIRCONDITION_STATE pState,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    bool bIsOnline = false;
    bool bIsOn = false;
    int iTemperture = 0;
    std::string strMode;
    std::string strWindMode;
    float fActTemperture;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId || !pState )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->AirCondition_getState_Sync(pszDeviceId,bIsOnline,bIsOn,iTemperture,strMode,strWindMode,fActTemperture,waittime);
    if ( 0 == iRet )
    {
        pState->bIsOn = bIsOn;
        pState->bIsOnline = bIsOnline;
        pState->iTemperature = iTemperture;
        strcpy(pState->szMode,strMode.c_str());
        strcpy(pState->szWindMode,strWindMode.c_str());
        pState->fActTemperature = fActTemperture;
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}


//////////////////////////智能电表//////////////////////////
// 获取智能电表配置
bool CALL_METHOD CLIENT_IntelligentAmmeter_getConfig(UInt32 hLoginID
                                                     ,LPINTELLIGENTAMMETER_CONFIG pDevices
                                                     ,Int32 maxDevices
                                                     ,Int32 *devices
                                                     ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    int iTemp = 0;
    std::vector<Smarthome_IntelligentAmmeter> vecDevices;	//
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !devices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    if ( maxDevices > 0 && !pDevices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->IntelligentAmmeter_getConfig_Sync(vecDevices,waittime);
    if ( 0 == iRet )
    {
        bRet = true;
        *devices = vecDevices.size();
        if ( 0 == *devices )
        {
            return true;
        }
        if ( vecDevices.size() > maxDevices )
        {
            WARN_TRACE("too small buf to devices");
            *devices = maxDevices;
        }
        iTemp = 0;
        for(size_t i=0;i<vecDevices.size();i++)
        {
            if ( i < *devices )
            {
                strcpy(pDevices[i].szId,vecDevices[i].strDeviceId.c_str());
                strcpy(pDevices[i].szName,vecDevices[i].strDeviceName.c_str());
                strcpy(pDevices[i].szBrand,vecDevices[i].strBrand.c_str());
                strcpy(pDevices[i].szAddress,vecDevices[i].AddrToStr().c_str());
                pDevices[i].iAreaId = vecDevices[i].iPosID;
                pDevices[i].xPos = vecDevices[i].xPos;
                pDevices[i].yPos = vecDevices[i].yPos;
                strcpy(pDevices[i].szType,vecDevices[i].strType.c_str());
            }
        }
    }
    else
    {
        bRet = false;
    }
    return bRet;
}
// 设置智能电表配置
bool CALL_METHOD CLIENT_IntelligentAmmeter_setConfig(UInt32 hLoginID
                                                     ,LPINTELLIGENTAMMETER_CONFIG pDevices
                                                     ,Int32 devices
                                                     ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    int iTemp = 0;
    std::vector<Smarthome_IntelligentAmmeter> vecDevices;	//
    Smarthome_IntelligentAmmeter devInfo;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pDevices )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    for(int i=0;i<devices;i++)
    {
        devInfo.strDeviceId = pDevices[i].szId;
        devInfo.strDeviceName = pDevices[i].szName;
        devInfo.strBrand = pDevices[i].szBrand;
        devInfo.AddrFromStr(pDevices[i].szAddress);
        devInfo.iPosID = pDevices[i].iAreaId;
        devInfo.xPos = pDevices[i].xPos;
        devInfo.yPos = pDevices[i].yPos;
        devInfo.strType = pDevices[i].szType;
        vecDevices.push_back(devInfo);
        devInfo.vecAddress.clear();
    }
    iRet = pInst->IntelligentAmmeter_setConfig_Sync(vecDevices,waittime);
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
// 获取智能电表设备基本信息
bool CALL_METHOD CLIENT_IntelligentAmmeter_getBasicInfo(UInt32 hLoginID
                                                        ,char *pszDeviceId
                                                        ,LPINTM_BASIC_INFO pInfo
                                                        ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    IntelligentAmmeter_BasicInfo stInfo;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId || !pInfo )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->IntelligentAmmeter_getBasicInfo(pszDeviceId,stInfo,waittime);
    if ( 0 == iRet )
    {
        //pState->bIsOn = bIsOn;
        //pState->bIsOnline = bIsOnline;
        //pState->iTemperature = iTemperture;
        //strcpy(pState->szMode,strMode.c_str());
        //strcpy(pState->szWindMode,strWindMode.c_str());
        //pState->fActTemperature = fActTemperture;
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}
// 获取电表数据
bool CALL_METHOD CLIENT_IntelligentAmmeter_readMeter(UInt32 hLoginID
                                                     ,char *pszDeviceId
                                                     ,LPINTM_POSITIVE_ENERGY pEnergy
                                                     ,LPINTM_POSITIVE_POWER pPower
                                                     ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    PositiveEnergy stPositive;
    InstancePower stInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId || !pEnergy || !pPower )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->IntelligentAmmeter_readMeter(pszDeviceId,stPositive,stInst,waittime);
    if ( 0 == iRet )
    {
        bRet = true;
        pEnergy->iPositiveActiveEnergy = stPositive.iTotalActive;
        pEnergy->iSharpPositiveActiveEnergy = stPositive.iSharpActive;
        pEnergy->iPeakPositiveActiveEnergy = stPositive.iPeakActive;
        pEnergy->iShoulderPositiveActiveEnergy = stPositive.iShoulderActive;
        pEnergy->iOffPeakPositiveActiveEnergy = stPositive.iOffPeakActive;
        
        pEnergy->iPositiveReactiveEnergy = stPositive.iTotalReactive;
        pEnergy->iSharpPositiveReactiveEnergy = stPositive.iSharpReactive;
        pEnergy->iPeakPositiveReactiveEnergy = stPositive.iPeakReactive;
        pEnergy->iShoulderPositiveReactiveEnergy = stPositive.iSharpReactive;
        pEnergy->iOffPeakPositiveReactiveEnergy = stPositive.iOffPeakReactive;
        
        pPower->iActivePower = stInst.iActivePower;
        pPower->iReactivePower = stInst.iReactivePower;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}
// 获取电表上次结算数据
bool CALL_METHOD CLIENT_IntelligentAmmeter_readMeterPrev(UInt32 hLoginID
                                                         ,char *pszDeviceId
                                                         ,int *pTime
                                                         ,LPINTM_POSITIVE_ENERGY pEnergy
                                                         ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    PositiveEnergy stPositive;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId || !pTime || !pEnergy )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->IntelligentAmmeter_readMeterPrev(pszDeviceId,*pTime,stPositive,waittime);
    if ( 0 == iRet )
    {
        bRet = true;
        pEnergy->iPositiveActiveEnergy = stPositive.iTotalActive;
        pEnergy->iSharpPositiveActiveEnergy = stPositive.iSharpActive;
        pEnergy->iPeakPositiveActiveEnergy = stPositive.iPeakActive;
        pEnergy->iShoulderPositiveActiveEnergy = stPositive.iShoulderActive;
        pEnergy->iOffPeakPositiveActiveEnergy = stPositive.iOffPeakActive;
        
        pEnergy->iPositiveReactiveEnergy = stPositive.iTotalReactive;
        pEnergy->iSharpPositiveReactiveEnergy = stPositive.iSharpReactive;
        pEnergy->iPeakPositiveReactiveEnergy = stPositive.iPeakReactive;
        pEnergy->iShoulderPositiveReactiveEnergy = stPositive.iSharpReactive;
        pEnergy->iOffPeakPositiveReactiveEnergy = stPositive.iOffPeakReactive;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}


//////门禁
// 修改密码
//type 密码类型	OpenDoor-开门密码 Alarm-防劫持报警密码
//user 用户ID
//oldPassword 旧密码
//newPassword 新密码
bool CALL_METHOD CLIENT_AccessControl_modifyPassword(UInt32 hLoginID
                                                     ,char *type
                                                     ,char *user
                                                     ,char *oldPassword
                                                     ,char *newPassword
                                                     ,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !type )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->AccessControl_modifyPassword(type,user,oldPassword,newPassword,waittime);
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

// 读取配置信息
//szName 配置名称 读取支持的配置 HouseTypeInfo 户型图 Light 灯光 Curtain 窗帘 GroundHeat 地暖 AirCondition 空调 IntelligentAmmeter 智能电表 AlarmZone 报警防区 IPCamera IP摄像头
//szBuf 缓冲区 获取
//iBufSize 缓冲区大小 调用时指定szBuf的大小 返回时内部会返回实际结果大小 
//注 如果输入缓冲区太小 ,也会失败,此时iBufSize会返回实际需要的缓冲区大小
bool CALL_METHOD CLIENT_ConfigManager_getConfig(UInt32 hLoginID,char *szName,char *szBuf,int *iBufSize,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    std::string strName;
    std::string strConfig;
    int iRealSize;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !szName || !szBuf || !iBufSize )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    strName = szName;
    //szName 配置名称 读取支持的配置 HouseTypeInfo 户型图 Light(CommLight 普通型 LevelLight 可调光) 灯光 
    //Curtain 窗帘 GroundHeat 地暖 AirCondition 空调 IntelligentAmmeter 智能电表 
    //AlarmZone 报警防区 IPCamera IP摄像头 SceneMode情景模式 ChangeId配置变更ID
    if (!strcmp(szName,"ChangeId"))
    {
        strName = "All";
        iRet = pInst->GetDeviceDigest_Sync(strName,strConfig,waittime);
    }
    else if (!strcmp(szName,"Light") || !strcmp(szName,"Curtain") 
             || !strcmp(szName,"AirCondition") || !strcmp(szName,"GroundHeat")
             || !strcmp(szName,"IntelligentAmmeter"))
    {	
        iRet = pInst->GetDeviceList_Sync(strName,strConfig,waittime);
    }
    else 
    {
        if (!strcmp(szName,"IPCamera"))
        {
            iRet = pInst->ConfigManager_getConfig("IPCInfo",strConfig,waittime);
        }
        else if (!strcmp(szName,"AlarmZone"))
        {
            iRet = pInst->ConfigManager_getConfig("Alarm",strConfig,waittime);
        }
        else
            iRet = pInst->ConfigManager_getConfig(strName,strConfig,waittime);
    }
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

// 机器操作,读取设备配置
//szName 配置名称 读取支持的配置 SerialNo 获取设备序列号 
//szBuf 缓冲区 获取
//iBufSize 缓冲区大小 调用时指定szBuf的大小 返回时内部会返回实际结果大小 
//注 如果输入缓冲区太小 ,也会失败,此时iBufSize会返回实际需要的缓冲区大小
CLIENT_API bool CALL_METHOD CLIENT_getDevConfig(UInt32 hLoginID,char *szName,char *szBuf,int *iBufSize,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    std::string strName;
    std::string strConfig;
    int iRealSize;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !szName || !szBuf || !iBufSize )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    strName = szName;
    iRet = pInst->MagicBox_getDevConfig(strName,strConfig,waittime);
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


//////报警Alarm
// 布撤防
//mode 模式 Arming 布防 Disarming 撤防
//password 布撤防密码
bool CALL_METHOD CLIENT_Alarm_setArmMode(UInt32 hLoginID,char *pszDeviceId,char *mode,char *password,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    std::string strName;
    std::string strConfig;
    //	int iRealSize;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId || !mode )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Alarm_setArmMode(pszDeviceId,mode,password,waittime);
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
bool CALL_METHOD CLIENT_Alarm_getArmMode(UInt32 hLoginID,char *pszDeviceId,LPALARMZONE_STATE pState,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    std::string strMode;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId || !pState )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->Alarm_getArmMode_Sync(pszDeviceId,strMode,waittime);
    if ( 0 == iRet )
    {
        strcpy(pState->szMode,strMode.c_str());
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

// 视频遮挡配置
bool CALL_METHOD CLIENT_GetVideoCovers(UInt32 hLoginID,bool &bEnable,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    std::string strName;
    std::string strConfig;
    //	int iRealSize;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->GetVideoCovers(bEnable,waittime);
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

CLIENT_API bool CALL_METHOD CLIENT_SetVideoCovers(UInt32 hLoginID,bool bEnable,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    std::string strName;
    std::string strConfig;
    //	int iRealSize;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->SetVideoCovers(bEnable,waittime);
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

//////////////////////////IPCamera//////////////////////////
// 获取摄像机状态
CLIENT_API bool CALL_METHOD CLIENT_IPCamera_getState(UInt32 hLoginID,char *pszDeviceId,LPIPCAMERA_STATE pState,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    bool bIsOnline = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId || !pState )
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->IPC_getState_Sync(pszDeviceId,bIsOnline,waittime);
    if ( 0 == iRet )
    {
        pState->bIsOnline = bIsOnline;
        bRet = true;
    }
    else
    {
        bRet = false;
    }
    return bRet;
}

// 实时上传数据－图片
CLIENT_API bool CALL_METHOD CLIENT_RealLoadPicture(UInt32 hLoginID,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    bool bIsOnline = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->RealLoadPicture(waittime);
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

// 停止上传数据－图片
CLIENT_API bool CALL_METHOD CLIENT_StopLoadPic(UInt32 hLoginID,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    bool bIsOnline = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    iRet = pInst->StopLoadPic(waittime);
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

// 抓图请求
CLIENT_API bool CALL_METHOD CLIENT_SnapPicture(UInt32 hLoginID,char *pszDeviceId,Int32 waittime)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    if ( !pszDeviceId)
    {
        ERROR_TRACE("invalid param");
        return false;
    }
    iRet = pInst->SnapPicture(pszDeviceId,waittime);
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

//子连接（基于二代协议）使能开关，使能后IPC报警、码流提取等功能接口才有效
CLIENT_API bool CALL_METHOD CLIENT_EnableSubConnect(UInt32 hLoginID,bool bEnable)
{
    int iRet = 0;
    bool bRet = false;
    bool bIsOnline = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    return pInst->EnableSubConnect(bEnable);
}

//监听报警
CLIENT_API bool CALL_METHOD CLIENT_StartListen(UInt32 hLoginID)
{
    int iRet = 0;
    bool bRet = false;
    bool bIsOnline = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    return pInst->StartListen();
}

//停止监听报警
CLIENT_API bool CALL_METHOD CLIENT_StopListen(UInt32 hLoginID)
{
    int iRet = 0;
    bool bRet = false;
    bool bIsOnline = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    return pInst->StopListen();
}

//实时监视
CLIENT_API unsigned int CALL_METHOD  CLIENT_StartRealPlay(UInt32 hLoginID,int iChannel,fRealDataCallBack pCb,void * pUser)
{
    int iRet = 0;
    bool bRet = false;
    bool bIsOnline = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindInstance(hLoginID);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.id="<<hLoginID);
        return false;
    }
    
    return pInst->StartRealPlay(iChannel,pCb,pUser);
}

//停止监视
CLIENT_API bool CALL_METHOD  CLIENT_StopRealPlay(unsigned int uiRealHandle)
{
    int iRet = 0;
    bool bRet = false;
    CDvrClient *pInst;
    
    pInst = CDvrGeneral::Instance()->FindRealPlayInstance(uiRealHandle);
    if ( !pInst )
    {
        ERROR_TRACE("not find instance.uiRealHandle="<<uiRealHandle);
        return false;
    }
    
    iRet = pInst->StopRealPlay(uiRealHandle);
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
CLIENT_API bool CALL_METHOD CLIENT_StartDevFinder(fOnIPSearch pFcb,void *pUser)
{
    return CDvrGeneral::Instance()->MCast_start(pFcb,pUser);
}

//停止设备搜索
CLIENT_API bool CALL_METHOD CLIENT_StopDevFinder()
{
    return CDvrGeneral::Instance()->MCast_stop();
}

//搜索,可指定mac地址
CLIENT_API bool CALL_METHOD CLIENT_IPSearch(char *szMac)
{
    return CDvrGeneral::Instance()->MCast_search(szMac);
}

