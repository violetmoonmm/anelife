#ifndef DvrClient_h
#define DvrClient_h

#include "Platform.h"
#include <string>
#include <map>
#include <vector>
#include "DvipMsg.h"
#include "MuteX.h"
#include "UtilFuncs.h"
#include "json.h"
#include "Trace.h"
#include "DvrApi.h"
#include "UserConn.h"

using namespace std;

#define MAX_CHANNEL 1

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

typedef struct _RealPlayTag
{
    int iChannel;
    unsigned int uRealHandle;
    
    CUserConn *subConn;
}RealPlayTag;

class CDvrClient
{
public:
    CDvrClient();
    ~CDvrClient();
    
    enum EmStatus
    {
        emIdle,
        emConnecting,
        emConnected,
        emRegistering,
        emRegistered
    };
    
    enum EmDisConnectReason
    {
        emDisRe_None,					//²»ĞèÒª
        emDisRe_ConnectFailed,          //Á¬½ÓÊ§°Ü
        emDisRe_Disconnected,           //¶ÏÏß
        emDisRe_ConnectTimeout,			//Á¬½Ó³¬Ê±
        emDisRe_RegistedFailed,			//×¢²áÊ§°Ü
        emDisRe_RegistedTimeout,		//×¢²á³¬Ê±
        emDisRe_RegistedRefused,		//×¢²á±»¾Ü¾ø
        emDisRe_Keepalivetimeout,		//±£»îÊ§°Ü
        emDisRe_UnRegistered,			//×¢Ïú
        
        emDisRe_UserNotValid,			//ÓÃ»§ÃûÎŞĞ§
        emDisRe_PasswordNotValid,		//ÃÜÂëÎŞĞ§
        
        emDisRe_Unknown,                //Î´ÖªÔ­Òò
    };
    
    
    //static CDvrClient * Instance();
    
    ////////////////////Íâ²¿½Ó¿Ú///////////////////////
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
    //int Login_Sync(const char *pServIp,unsigned short usServPort,const char *pUsername,const char *pPassword);
    int CLIENT_Login(const char *pServIp,unsigned short usServPort,const char *pUsername,const char *pPassword);
    int Login_Sync();
    int Login_Asyc();
    int Logout_Sync(int iTimeout = 5000);
    
    //É¾³ıÅäÖÃ ËùÓĞ
    int ConfigManager_deleteFile(int iTimeout);
    //É¾³ıÅäÖÃ ÌØ¶¨ÅäÖÃ
    int ConfigManager_deleteConfig(std::string &strName,int iTimeout);
    //¶ÁÈ¡ÅäÖÃ ÌØ¶¨ÅäÖÃ
    int ConfigManager_getConfig(const std::string &strName,std::string &strConfig,int iTimeout);
    //ÉèÖÃÉè±¸ĞÅÏ¢
    int SetDeviceInfo_Sync(char *pszDeviceId,char * pszName,int iTimeout);
    
    //¶ÁÈ¡Éè±¸ÅäÖÃ ÌØ¶¨ÅäÖÃ
    int MagicBox_getDevConfig(const std::string &strName,std::string &strConfig,int iTimeout);
    
    //»ñÈ¡·¿¼äÁĞ±í
    int GetHouseInfo_Sync(std::vector<Smarthome_HouseInfo> &vecHouse,int iTimeout);
    //ÉèÖÃ·¿¼äÁĞ±í
    int SetHouseInfo_Sync(std::vector<Smarthome_HouseInfo> &vecHouse,int iTimeout);
    //»ñÈ¡Çé¾°Ä£Ê½
    int Get_SceneMode_Sync(int &iCurrentId,std::vector<Smarthome_SceneInfo> &vecScenes,int iTimeout);
    //ÉèÖÃÇé¾°Ä£Ê½
    int Set_SceneMode_Sync(int iCurrentId,std::vector<Smarthome_SceneInfo> &vecScenes,int iTimeout);
    //»ñÈ¡Éè±¸ÁĞ±í
    int GetDeviceList_Sync(std::vector<Smarthome_DeviceInfo> &vecDevice,int iTimeout);
    //»ñÈ¡Éè±¸ÁĞ±í
    int GetDeviceList_Sync(std::string &strType,std::string &strDevices,int iTimeout);
    
    //»ñÈ¡Éè±¸ÁĞ±íĞÅÏ¢ÕªÒª
    int GetDeviceDigest_Sync(std::string &strType,std::string &strDigest,int iTimeout);
    //»ñÈ¡Çé¾°Ä£Ê½
    int Get_SceneMode_Sync(std::string &strMode,int iTimeout);
    //ÉèÖÃÇé¾°Ä£Ê½
    int Set_SceneMode_Sync(std::string &strMode,int iTimeout);
    // ±£´æÇé¾°Ä£Ê½
    int Save_SceneMode_Sync(std::string &strName,std::vector<Smarthome_DeviceInfo> vecDevice,int iTimeout);
    // ĞŞ¸ÄÇé¾°Ä£Ê½Ãû³Æ
    int Modify_SceneMode_Sync(std::string &strMode,std::string &strName,int iTimeout);
    // É¾³ıÇé¾°Ä£Ê½
    int Remove_SceneMode_Sync(std::string &strMode,int iTimeout);
    
    
    //»ñÈ¡µÆ¹âÅäÖÃ
    int Light_getConfig_Sync(std::vector<Smarthome_Light> &vecHouse,int iTimeout);
    //ÉèÖÃµÆ¹âÅäÖÃ
    int Light_setConfig_Sync(std::vector<Smarthome_Light> &vecHouse,int iTimeout);
    
    //µÆ¹â¿ØÖÆ ¿ª
    int SetPowerOn_Sync(char *pszDeviceId,int iTimeout);
    //µÆ¹â¿ØÖÆ ¹Ø
    int SetPowerOff_Sync(char *pszDeviceId,int iTimeout);
    
    // µÆ¹â¿ØÖÆ ÉèÖÃµÆ¹âÁÁ¶È
    int Light_setBrightLevel_Sync(char *pszDeviceId,int iLevel,int iTimeout);
    // µÆ¹â¿ØÖÆ µ÷½ÚµÆ¹âÁÁ¶È
    int Light_adjustBright_Sync(char *pszDeviceId,int iLevel,int iTimeout);
    // µÆ¹â¿ØÖÆ ÑÓÊ±¹ØµÆ
    int Light_keepOn_Sync(char *pszDeviceId,int iTime,int iTimeout);
    // µÆ¹â¿ØÖÆ µÆÉÁË¸
    int Light_blink_Sync(char *pszDeviceId,int iTime,int iTimeout);
    // µÆ¹â¿ØÖÆ ÒÔÖ¸¶¨ËÙ¶È´ò¿ªÒ»×éµÆ
    int Light_openGroup_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout);
    // µÆ¹â¿ØÖÆ ÒÔÖ¸¶¨ËÙ¶È¹Ø±ÕÒ»×éµÆ
    int Light_closeGroup_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout);
    // µÆ¹â¿ØÖÆ ÒÔÖ¸¶¨ËÙ¶Èµ÷ÁÁµÆ¹â
    int Light_brightLevelUp_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout);
    // µÆ¹â¿ØÖÆ ÒÔÖ¸¶¨ËÙ¶Èµ÷°µµÆ¹â
    int Light_brightLevelDown_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout);
    //»ñÈ¡µÆ¹â×´Ì¬
    int GetPowerStatus_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iBright,int iTimeout);
    
    ///´°Á±
    // »ñÈ¡´°Á±ÅäÖÃ
    int Curtain_getConfig_Sync(std::vector<Smarthome_Curtain> &vecCurtains,int iTimeout);
    // ÉèÖÃ´°Á±ÅäÖÃ
    int  Curtain_setConfig_Sync(std::vector<Smarthome_Curtain> &vecCurtains,int iTimeout);
    
    //´ò¿ª
    int Curtain_open_Sync(char *pszDeviceId,int iTimeout);
    //¹Ø±Õ
    int Curtain_close_Sync(char *pszDeviceId,int iTimeout);
    //Í£Ö¹
    int Curtain_stop_Sync(char *pszDeviceId,int iTimeout);
    //µ÷Õû´°Á±ÕÚ¹âÂ
    int Curtain_adjustShading_Sync(char *pszDeviceId,int iScale,int iTimeout);
    //µ÷Õû´°Á±ÕÚ¹âÂ
    int Curtain_setShading_Sync(char *pszDeviceId,int iScale,int iTimeout);
    
    //»ñÈ¡×´Ì¬
    int Curtain_getState_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iShading,int iTimeout);
    
    
    ///µØÅ¯
    // »ñÈ¡µØÅ¯ÅäÖÃ
    int GroundHeat_getConfig_Sync(std::vector<Smarthome_GroundHeat> &vecDevices,int iTimeout);
    // ÉèÖÃµØÅ¯ÅäÖÃ
    int GroundHeat_setConfig_Sync(std::vector<Smarthome_GroundHeat> &vecDevices,int iTimeout);
    
    // ¿ª
    int GroundHeat_open_Sync(char *pszDeviceId,int iTimeout);
    // ¹Ø
    int GroundHeat_close_Sync(char *pszDeviceId,int iTimeout);
    // Éè¶¨µØÅ¯ÎÂ¶È
    int GroundHeat_setTemperature_Sync(char *pszDeviceId,int iTemperture,int iTimeout);
    // µ÷½ÚµØÅ¯ÎÂ¶È
    int GroundHeat_adjustTemperature_Sync(char *pszDeviceId,int iScale,int iTimeout);
    // »ñÈ¡µØÅ¯×´Ì¬
    int GroundHeat_getState_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iTemperture,int iTimeout);
    
    
    // »ñÈ¡¿Õµ÷ÅäÖÃ
    int AirCondition_getConfig_Sync(std::vector<Smarthome_AirCondition> &vecDevices,int iTimeout);
    // ÉèÖÃ¿Õµ÷ÅäÖÃ
    int AirCondition_setConfig_Sync(std::vector<Smarthome_AirCondition> &vecDevices,int iTimeout);
    // ¿ª
    int AirCondition_open_Sync(char *pszDeviceId,int iTimeout);
    // ¹Ø
    int AirCondition_close_Sync(char *pszDeviceId,int iTimeout);
    // Éè¶¨¿Õµ÷ÎÂ¶È
    int AirCondition_setTemperature_Sync(char *pszDeviceId,int iTemperture,int iTimeout);
    // µ÷½ÚÎÂ¶È
    int AirCondition_adjustTemperature_Sync(char *pszDeviceId,int iScale,int iTimeout);
    // ÉèÖÃ¹¤×÷Ä£Ê½
    int AirCondition_setMode_Sync(char *pszDeviceId,std::string strMode,int iTemperture,int iTimeout);
    // ÉèÖÃËÍ·çÄ£Ê½
    int AirCondition_setWindMode_Sync(char *pszDeviceId,std::string strWindMode,int iTimeout);
    // Ò»¼ü¿ØÖÆ
    int AirCondition_oneKeyControl(char *pszDeviceId,bool bIsOn,std::string strMode,
                                   int iTemperature,std::string strWindMode,int iTimeout);
    
    // È¡µÃ¿Õµ÷×´Ì¬
    int AirCondition_getState_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iTemperture,std::string &strMode,std::string &strWindMode,float &fActTemperture,int iTimeout);
    
    
    //ÖÇÄÜµç±í
    // »ñÈ¡ÖÇÄÜµç±íÅäÖÃ
    int IntelligentAmmeter_getConfig_Sync(std::vector<Smarthome_IntelligentAmmeter> &vecDevices,int iTimeout);
    // ÉèÖÃÖÇÄÜµç±íÅäÖÃ
    int IntelligentAmmeter_setConfig_Sync(std::vector<Smarthome_IntelligentAmmeter> &vecDevices,int iTimeout);
    // »ñÈ¡ÖÇÄÜµç±íÉè±¸»ù±¾ĞÅÏ¢
    int IntelligentAmmeter_getBasicInfo(char *pszDeviceId,IntelligentAmmeter_BasicInfo &stInfo,int waittime);
    // »ñÈ¡µç±íÊı¾İ
    int IntelligentAmmeter_readMeter(char *pszDeviceId,PositiveEnergy &stPositive,InstancePower &stInst,int waittime);
    // »ñÈ¡µç±íÉÏ´Î½áËãÊı¾İ
    int IntelligentAmmeter_readMeterPrev(char *pszDeviceId,int &iTime,PositiveEnergy &stPositive,int waittime);
    
    //±¨¾¯
    // ²¼³··À
    int Alarm_setArmMode(const char *pszDeviceId,const char *mode,const char *password,int waittime);
    // È¡µÃ±¨¾¯·ÀÇø×´Ì¬
    int Alarm_getArmMode_Sync(char *pszDeviceId,std::string &strMode,int iTimeout);
    
    // ÊÓÆµÕÚµ²ÅäÖÃ
    int GetVideoCovers(bool &bEnable,int iTimeout);
    int SetVideoCovers(bool bEnable,int iTimeout);
    
    //IPCamera
    // È¡µÃIPC×´Ì¬
    int IPC_getState_Sync(char *pszDeviceId,bool &bIsOnline,int iTimeout);
    
    //¶©ÔÄ
    int Subscrible_Sync(int iTimeout);
    //È¡Ïû¶©ÔÄ
    int Unsubscrible_Sync(int iTimeout);
    
    // ÊµÊ±ÉÏ´«Êı¾İ£­Í¼Æ¬
    int RealLoadPicture(int iTimeout);
    
    // Í£Ö¹ÉÏ´«Êı¾İ£­Í¼Æ¬
    int StopLoadPic(int iTimeout);
    
    // ×¥Í¼ÇëÇó
    int SnapPicture(char *pszDeviceId,int iTimeout);
    
    
    ///////////////ÃÅ½û¿ØÖÆ
    int AccessControl_modifyPassword(char *type,char *user,char *oldPassword,char *newPassword,int waittime);
    ////////////////////Íâ²¿½Ó¿Ú///////////////////////
    
    
    //×ÓÁ¬½ÓÊ¹ÄÜ¿ª¹Ø
    bool EnableSubConnect(bool bEnable);
    bool StartListen();
    bool StopListen();
    
    //ÊµÊ±¼àÊÓ
    unsigned int StartRealPlay(int iChannel,fRealDataCallBack pCb,void * pUser);
    //Í£Ö¹¼àÊÓ
    int StopRealPlay(unsigned int uiRealHandle);
    
    unsigned int GetLoginId()
    {
        return m_uiLoginId;
    }
    
    int Start();
    int Stop();
    int Login();
    int Logout();
    
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
    void CreateLoginId()
    {
        //unsigned int uiRet = 0;
        m_uiLoginId = ++s_ui_LoginId;
        if ( m_uiLoginId == 0 )
        {
            m_uiLoginId = ++s_ui_LoginId;
        }
        //return uiRet;
    }
    unsigned int CreateRealHandle()
    {
        unsigned int uiRealHandle = ++s_ui_RealHandle;
        if ( uiRealHandle == 0 )
        {
            uiRealHandle = ++s_ui_RealHandle;
        }
        return uiRealHandle;
    }
    
    bool HasRealHandle(unsigned int uiRealHandle);
    bool IsRealPlay();
    
private:
    
    int Connect_Async(); //Á¬½Ó Òì²½
    int PollData(); //ÂÖÑ¯Êı¾İ
    int Process_Data(); //´¦ÀíÊı¾İ
    int SendData(char *pData,int iDataLen); //·¢ËÍÊı¾İ
    void OnDataPacket(const char *pData,int pDataLen);
    bool LoginRequest(); //µÇÂ¼ÇëÇó
    bool LoginRequest(unsigned int uiSessId,const char *pPasswordMd5,const char *pPasswordType,const char *pRandom,const char *pRealm); //µÇÂ¼ÇëÇó(È¨¼øĞÅÏ¢)
    bool KeepaliveRequest(); //±£»îÇëÇó
    bool LogoutRequest(); //µÇ³öÇëÇó
    
    struct TransInfo;
    //ÊÕµ½×¢²á»ØÓ¦
    void OnLoginResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //ÊÕµ½±£»î»ØÓ¦
    void OnKeepaliveResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //ÊÕµ½µÇ³ö»ØÓ¦
    void OnLogoutResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    
    //ÊÕµ½Í¨ÖªÏûÏ¢
    void OnNotification(dvip_hdr &hdr,const char *pData,int pDataLen);
    
    //ÊÕµ½·Ö°üÊı¾İ
    int OnPackage(dvip_hdr &hdr,const char *pData,int pDataLen);
    
    //ÊÕµ½»ñÈ¡ÖÇÄÜ¼Ò¾Ó¹ÜÀíÊµÀı»ØÓ¦
    void OnSmarthome_instance_rsp(TransInfo *pTrans,const char *pData,int pDataLen);
    //ÊÕµ½ÊÍ·ÅÖÇÄÜ¼Ò¾Ó¹ÜÀíÊµÀı»ØÓ¦
    void OnSmarthome_destroy_rsp(TransInfo *pTrans,const char *pData,int pDataLen);
    //ÊÕµ½»ñÈ¡Éè±¸ÁĞ±í»ØÓ¦
    void OnSmarthome_getDeviceList_rsp(TransInfo *pTrans,const char *pData,int pDataLen);
    
    void OnConnect(); //Á¬½Ó³É¹¦Í¨Öª
    void OnDataRecv(); //½ÓÊÕÊı¾İÍ¨Öª
    void OnDataSend(); //¿ÉÒÔ·¢ËÍÊı¾İÍ¨Öª
    
    void OnDisConnected(int iReason);
    void OnRegisterSuccess(int iReason);
    void OnRegisterFailed(int iReason);
    
    
    //»ñÈ¡ÖÇÄÜ¼Ò¾ÓÊµÀı
    bool Smarthome_instance_Req();
    //ÊÕµ½»ØÓ¦
    void OnSmarthome_instance_Rsp(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //ÊÍ·ÅÖÇÄÜ¼Ò¾ÓÊµÀı
    bool Smarthome_destory_Req(unsigned int uiObject);
    //ÊÕµ½»ØÓ¦
    void OnSmarthome_destroy_Rsp(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //»ñÈ¡ÖÇÄÜ¼Ò¾ÓÉè±¸ÁĞ±í
    bool Smarthome_getDeviceList_Req(unsigned int uiObject,int iType);
    //ÊÕµ½»ØÓ¦
    void OnSmarthome_getDeviceList_Rsp(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    
    //´´½¨¶ÔÏóÊµÀı È«¾ÖÊµÀı
    int Dvip_instance(char *pszMethod,unsigned &uiObject,int iTimeout=5000);
    //´´½¨¶ÔÏóÊµÀı Í¨¹ıÉè±¸id
    int Dvip_instance(char *pszMethod,char *pszDeviceId,unsigned &uiObject,int iTimeout=5000);
    //´´½¨¶ÔÏóÊµÀı È«¾ÖÊµÀı
    int Dvip_instance(char *pszMethod,const Json::Value &jsParams,unsigned &uiObject,int iTimeout=5000);
    //ÊÍ·ÅÊµÀı
    int Dvip_destroy(char *pszMethod,unsigned uiObject,int iTimeout=5000);
    
    //µ÷ÓÃ·½·¨ ÊäÈëÊä³ö²ÎÊıÎª¿Õ,·½·¨·µ»ØÖµÎªbool Ò»°ãº¯ÊıÔ­ĞÍ bool call(void)
    int Dvip_method_v_b_v(char *pszMethod,unsigned uiObject,bool &bResult,int iTimeout=5000);
    
    //µ÷ÓÃ·½·¨ ÊäÈë²ÎÊıÎªjson(params : {}),Êä³ö²ÎÊıÒ²Îªjson(params : {}),·½·¨·µ»ØÖµÎªbool Ò»°ãº¯ÊıÔ­ĞÍ bool call(void)
    int Dvip_method_json_b_json(char *pszMethod,unsigned uiObject,Json::Value &inParams,bool &bResult,Json::Value &outParams,int iTimeout=5000);
    
    //µ÷ÓÃ·½·¨ ÊäÈë²ÎÊıÎª¿Õ,Êä³ö²ÎÊıÎª¿Õ,·½·¨·µ»ØÖµÎªbool Ò»°ãº¯ÊıÔ­ĞÍ bool call(void)
    //int Dvip_method_v_b_bbi(char *pszMethod,unsigned uiObject,bool &bReturn,bool &bOutParam1,bool &bOutParam2,int &iOutParam3,int iTimeout=5000);
    //»ñÈ¡´°Á±×´Ì¬
    int Dvip_Light_getState(char *pszMethod,unsigned uiObject,bool &bReturn,bool &bIsOnline,bool &bIsOn,int &iBright,int iTimeout=5000);
    //»ñÈ¡´°Á±×´Ì¬
    int Dvip_Curtain_getState(char *pszMethod,unsigned uiObject,bool &bReturn,bool &bIsOnline,bool &bIsOn,int &iShading,int iTimeout=5000);
    
    //»ñÈ¡ÅäÖÃĞÅÏ¢
    int Dvip_getConfig(unsigned uiObject,char *pszConfigPath,bool &bResult,Json::Value &jsonCfg,int iTimeout=5000);
    //ÉèÖÃÅäÖÃĞÅÏ¢
    int Dvip_setConfig(unsigned uiObject,char *pszConfigPath,Json::Value &jsonCfg,bool &bResult,int iTimeout=5000);
    
    //ÉèÖÃÅäÖÃĞÅÏ¢
    int Dvip_setDeviceInfo(unsigned uiObject,Json::Value &jsonCfg,bool &bResult,int iTimeout=5000);
    
    //½âÎö³¡¾°ĞÅÏ¢
    bool ParseScence(Json::Value &jsonConfig,std::vector<Smarthome_SceneInfo> &vecScenes);
    //´ò°ü³¡¾°ĞÅÏ¢
    bool EncodeScence(Json::Value &jsonConfig,std::vector<Smarthome_SceneInfo> &vecScenes);
    
    //»ñÈ¡Éè±¸ÅäÖÃĞÅÏ¢
    int Dvip_getDevConfig(unsigned uiObject,char *pszConfigPath,bool &bResult,Json::Value &jsonCfg,int iTimeout=5000);
    
    //¶ÏÏßÍË³öÇåÀíÊÂÎñ
    void Clear_Tasks();
    
    /////////Ïß³Ì´¦Àí////////////
#ifdef WIN32
    static unsigned long __stdcall ThreadProc(void *pParam);
#else
    static void* ThreadProc(void *pParam);
#endif
    void ThreadProc(void);
    void Thread_Process();
    
    //Æô¶¯´¦ÀíÏß³Ì
    int StartThread();
    //½áÊø´¦ÀíÏß³Ì
    int StopThread();
    
    //ÈÎÎñ´¦Àí
    void Process_Task();
    
    FCL_THREAD_HANDLE m_hThread;
    bool m_bExitThread;
    
    
    //±¾¶ËĞÅÏ¢
    std::string m_strUsername;  //ÓÃ»§Ãû
    std::string m_strPassword;  //ÃÜÂë
    
    //·şÎñ¶ËĞÅÏ¢
    std::string m_strServIp; //·şÎñ¶Ëip
    int m_iServPort;		 //·şÎñ¶Ë¶Ë¿Ú
    
    FCL_SOCKET m_sSock; //Á¬½ÓÌ×½Ó×Ö
    EmStatus m_emStatus; //Á¬½Ó×´Ì¬
    int m_error;//´íÎóÂë
    unsigned int m_uiSessionId; //µÇÂ¼»á»°id
    int m_iTimeout; //³¬Ê±Ê±¼ä Ãë
    int m_iFailedTimes; //Á¬ĞøÊ§°Ü´ÎÊı
    bool m_bAutoReConnect;	//ÊÇ·ñ×Ô¶¯ÖØÁ¬
    bool m_bIsFirstConnect;	//ÊÇ·ñµÚÒ»´ÎÁ¬½Ó
    unsigned int m_uiLoginId;
    long long m_llLastTime;
    
    //ÇëÇóÀàĞÍ
    enum EmRequestType
    {
        emRT_Unknown,		//Î´ÖªÀàĞÍ
        
        
        emRT_method_v_b_v,	//Í¨ÓÃ·½·¨ void call(void)
        emRT_method_json_b_json,	//Í¨ÓÃ·½·¨ bool call([IN] json,[OUT] json)
        
        emRT_instance,		//»ñÈ¡ÊµÀı
        emRT_destroy,		//Ïú»ÙÊµÀı
        
        emRT_getConfig,		//»ñÈ¡ÅäÖÃ
        emRT_setConfig,		//ÉèÖÃÅäÖÃ
        
        emRT_Login,			//µÇÂ¼ÇëÇó
        emRT_Keepalive,		//±£»îÇëÇó
        emRT_Logout,		//µÇ³öÇëÇó
        
        ////////////////ÖÇÄÜ¼Ò¾Ó////////////////
        emRT_Smarthome_instance,		//»ñÈ¡ÊµÀı
        emRT_Smarthome_destroy,			//Ïú»ÙÊµÀı
        emRT_Smarthome_getDeviceList,	//»ñÈ¡Éè±¸ÁĞ±í
        
        emRT_Smarthome_setDeviceInfo,	//ÉèÖÃÉè±¸ĞÅÏ¢
        
        //µÆ¹â
        emRT_Light_instance,			//»ñÈ¡ÊµÀı
        emRT_Light_destroy,				//ÊÍ·ÅÊµÀı
        emRT_Light_open,				//¿ªµÆ
        emRT_Light_close,				//¹ØµÆ
        emRT_Light_getState,			//»ñÈ¡×´Ì¬
        
        //´°Á±
        emRT_Curtain_instance,			//»ñÈ¡ÊµÀı
        emRT_Curtain_destroy,			//ÊÍ·ÅÊµÀı
        emRT_Curtain_open,				//´ò¿ª
        emRT_Curtain_close,				//¹Ø±Õ
        emRT_Curtain_stop,				//Í£Ö¹
        emRT_Curtain_getState,			//»ñÈ¡×´Ì¬
        ////////////////ÖÇÄÜ¼Ò¾Ó////////////////
        //emRT_Login,			//µÇÂ¼ÇëÇó
        
        ////////////////Éè±¸ÅäÖÃ////////////////
        emRT_MagicBox_instance,		//»ñÈ¡ÊµÀı
        emRT_MagicBox_destroy,			//Ïú»ÙÊµÀı
        emRT_MagicBox_getDevConfig,		//²éÑ¯Éè±¸ÅäÖÃ
        
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
        long long	start; //ÈÎÎñ·¢ÆğÊ±¼ä
        unsigned int timeout; //³¬Ê±Ê±¼ä
        int result;
        CDvipMsg *pRspMsg;
        CEventThread hEvent;
        
        TransInfo()
        {
            type = emRT_Unknown;
            seq = 0;
            start = 0;
            timeout = 10000;
            result = emTaskStatus_Idle;
            pRspMsg = 0;
        }
        TransInfo(unsigned int id,long long llBegin,unsigned int uiTimeout=10000)
        {
            type = emRT_Unknown;
            seq = id;
            start = llBegin;
            timeout = uiTimeout;
            result = emTaskStatus_Idle;
            pRspMsg = 0;
        }
        TransInfo(unsigned int id,EmRequestType tp,long long llBegin,unsigned int uiTimeout=10000)
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
    //ÇëÇóÁĞ±í
    typedef std::map<unsigned int,TransInfo*> RequestList;
    RequestList m_reqList;
    CMutexThreadRecursive m_lockReqList;
    void AddRequest(unsigned int uiReq,TransInfo *trans)
    {
        CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
        //INFO_TRACE("[TEST] add seq "<<uiReq);
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
    TransInfo * FetchRequest(unsigned int uiReq) //´ÓÁĞ±íÖĞÈ¡³ö
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
        //INFO_TRACE("[TEST] remove seq "<<uiReq);
        TransInfo *pTrans = it->second;
        m_reqList.erase(it);
        delete pTrans;
        return 1;
    }
    
    CDvipMsg *CreateMsg(EmRequestType emType);
    
    // ÍøÂçÁ¬½Ó¶Ï¿ª»Øµ÷
    fOnDisConnect m_cbOnDisConnect;
    void *m_pUser;
    
    // ÍøÂçÁ¬½Ó×´Ì¬±ä»¯»Øµ÷
    fOnDisConnectEx m_cbOnDisConnectEx;
    void *m_pUserEx;
    
    //¶©ÔÄĞÅÏ¢
    // ×´Ì¬±ä»¯»Øµ÷º¯ÊıÔ­ĞÎ
    fOnEventNotify m_cbOnEventNotify;
    void *m_pEventNotifyUser;
    
    unsigned int m_uiEventObjectId;
    unsigned int m_uiSid;
    unsigned int m_uiSubscribeReqId;
    bool m_bHasSubscrible;
    
    //±¨¾¯Í¨Öª
    fOnAlarmNotify m_cbOnAlarmNotify;
    void *m_pAlarmNotifyUser;
    
    unsigned int m_uiSnapObjectId;
    //unsigned int m_uiSnapSid;
    
    const static  int MAX_BUF_LEN = 1024*128;
    //ÍøÂç½ÓÊÕ»º³å
    char m_szRecvBuf[MAX_BUF_LEN];
    int m_iRecvIndex; //½ÓÊÕ»º³åË÷Òı
    
    static unsigned int s_ui_RequestId; 
    static unsigned int s_ui_LoginId; 
    static unsigned int s_ui_RealHandle; 
    
    const static unsigned int GS_LOGIN_TIMEOUT = 15000;			//µÇÂ¼³¬Ê±Ê±¼ä
    const static unsigned int GS_KEEPALIVE_INTEVAL = 15000;		//±£»î¼ä¸ô
    const static unsigned int GS_TIMEOUT = 30000;				//³¬Ê±Ê±¼ä
    
    enum emIdle{
        IDLE_NORMAL=0,
        IDLE_PACKAGE,
    };
    int m_idle;
    FileProcessInfo m_fileinfo;
    const static  int MAX_PIC_LEN = 1024*128;
    char m_filebuffer[MAX_PIC_LEN];
    int m_pos;
    int m_packet_index;
    
    bool m_hasMainConn;
    CUserConn * m_pMainConn;
    RealPlayTag m_RealPlayArray[MAX_CHANNEL];
    unsigned int m_uRealHandle;
};

#endif