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
        emDisRe_None,					//不需要
        emDisRe_ConnectFailed,          //连接失败
        emDisRe_Disconnected,           //断线
        emDisRe_ConnectTimeout,			//连接超时
        emDisRe_RegistedFailed,			//注册失败
        emDisRe_RegistedTimeout,		//注册超时
        emDisRe_RegistedRefused,		//注册被拒绝
        emDisRe_Keepalivetimeout,		//保活失败
        emDisRe_UnRegistered,			//注销
        
        emDisRe_UserNotValid,			//用户名无效
        emDisRe_PasswordNotValid,		//密码无效
        
        emDisRe_Unknown,                //未知原因
    };
    
    
    //static CDvrClient * Instance();
    
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
    //int Login_Sync(const char *pServIp,unsigned short usServPort,const char *pUsername,const char *pPassword);
    int CLIENT_Login(const char *pServIp,unsigned short usServPort,const char *pUsername,const char *pPassword);
    int Login_Sync();
    int Login_Asyc();
    int Logout_Sync(int iTimeout = 5000);
    
    //删除配置 所有
    int ConfigManager_deleteFile(int iTimeout);
    //删除配置 特定配置
    int ConfigManager_deleteConfig(std::string &strName,int iTimeout);
    //读取配置 特定配置
    int ConfigManager_getConfig(const std::string &strName,std::string &strConfig,int iTimeout);
    //设置设备信息
    int SetDeviceInfo_Sync(char *pszDeviceId,char * pszName,int iTimeout);
    
    //读取设备配置 特定配置
    int MagicBox_getDevConfig(const std::string &strName,std::string &strConfig,int iTimeout);
    
    //获取房间列表
    int GetHouseInfo_Sync(std::vector<Smarthome_HouseInfo> &vecHouse,int iTimeout);
    //设置房间列表
    int SetHouseInfo_Sync(std::vector<Smarthome_HouseInfo> &vecHouse,int iTimeout);
    //获取情景模式
    int Get_SceneMode_Sync(int &iCurrentId,std::vector<Smarthome_SceneInfo> &vecScenes,int iTimeout);
    //设置情景模式
    int Set_SceneMode_Sync(int iCurrentId,std::vector<Smarthome_SceneInfo> &vecScenes,int iTimeout);
    //获取设备列表
    int GetDeviceList_Sync(std::vector<Smarthome_DeviceInfo> &vecDevice,int iTimeout);
    //获取设备列表
    int GetDeviceList_Sync(std::string &strType,std::string &strDevices,int iTimeout);
    
    //获取设备列表信息摘要
    int GetDeviceDigest_Sync(std::string &strType,std::string &strDigest,int iTimeout);
    //获取情景模式
    int Get_SceneMode_Sync(std::string &strMode,int iTimeout);
    //设置情景模式
    int Set_SceneMode_Sync(std::string &strMode,int iTimeout);
    // 保存情景模式
    int Save_SceneMode_Sync(std::string &strName,std::vector<Smarthome_DeviceInfo> vecDevice,int iTimeout);
    // 修改情景模式名称
    int Modify_SceneMode_Sync(std::string &strMode,std::string &strName,int iTimeout);
    // 删除情景模式
    int Remove_SceneMode_Sync(std::string &strMode,int iTimeout);
    
    
    //获取灯光配置
    int Light_getConfig_Sync(std::vector<Smarthome_Light> &vecHouse,int iTimeout);
    //设置灯光配置
    int Light_setConfig_Sync(std::vector<Smarthome_Light> &vecHouse,int iTimeout);
    
    //灯光控制 开
    int SetPowerOn_Sync(char *pszDeviceId,int iTimeout);
    //灯光控制 关
    int SetPowerOff_Sync(char *pszDeviceId,int iTimeout);
    
    // 灯光控制 设置灯光亮度
    int Light_setBrightLevel_Sync(char *pszDeviceId,int iLevel,int iTimeout);
    // 灯光控制 调节灯光亮度
    int Light_adjustBright_Sync(char *pszDeviceId,int iLevel,int iTimeout);
    // 灯光控制 延时关灯
    int Light_keepOn_Sync(char *pszDeviceId,int iTime,int iTimeout);
    // 灯光控制 灯闪烁
    int Light_blink_Sync(char *pszDeviceId,int iTime,int iTimeout);
    // 灯光控制 以指定速度打开一组灯
    int Light_openGroup_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout);
    // 灯光控制 以指定速度关闭一组灯
    int Light_closeGroup_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout);
    // 灯光控制 以指定速度调亮灯光
    int Light_brightLevelUp_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout);
    // 灯光控制 以指定速度调暗灯光
    int Light_brightLevelDown_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout);
    //获取灯光状态
    int GetPowerStatus_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iBright,int iTimeout);
    
    ///窗帘
    // 获取窗帘配置
    int Curtain_getConfig_Sync(std::vector<Smarthome_Curtain> &vecCurtains,int iTimeout);
    // 设置窗帘配置
    int  Curtain_setConfig_Sync(std::vector<Smarthome_Curtain> &vecCurtains,int iTimeout);
    
    //打开
    int Curtain_open_Sync(char *pszDeviceId,int iTimeout);
    //关闭
    int Curtain_close_Sync(char *pszDeviceId,int iTimeout);
    //停止
    int Curtain_stop_Sync(char *pszDeviceId,int iTimeout);
    //调整窗帘遮光�
    int Curtain_adjustShading_Sync(char *pszDeviceId,int iScale,int iTimeout);
    //调整窗帘遮光�
    int Curtain_setShading_Sync(char *pszDeviceId,int iScale,int iTimeout);
    
    //获取状态
    int Curtain_getState_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iShading,int iTimeout);
    
    
    ///地暖
    // 获取地暖配置
    int GroundHeat_getConfig_Sync(std::vector<Smarthome_GroundHeat> &vecDevices,int iTimeout);
    // 设置地暖配置
    int GroundHeat_setConfig_Sync(std::vector<Smarthome_GroundHeat> &vecDevices,int iTimeout);
    
    // 开
    int GroundHeat_open_Sync(char *pszDeviceId,int iTimeout);
    // 关
    int GroundHeat_close_Sync(char *pszDeviceId,int iTimeout);
    // 设定地暖温度
    int GroundHeat_setTemperature_Sync(char *pszDeviceId,int iTemperture,int iTimeout);
    // 调节地暖温度
    int GroundHeat_adjustTemperature_Sync(char *pszDeviceId,int iScale,int iTimeout);
    // 获取地暖状态
    int GroundHeat_getState_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iTemperture,int iTimeout);
    
    
    // 获取空调配置
    int AirCondition_getConfig_Sync(std::vector<Smarthome_AirCondition> &vecDevices,int iTimeout);
    // 设置空调配置
    int AirCondition_setConfig_Sync(std::vector<Smarthome_AirCondition> &vecDevices,int iTimeout);
    // 开
    int AirCondition_open_Sync(char *pszDeviceId,int iTimeout);
    // 关
    int AirCondition_close_Sync(char *pszDeviceId,int iTimeout);
    // 设定空调温度
    int AirCondition_setTemperature_Sync(char *pszDeviceId,int iTemperture,int iTimeout);
    // 调节温度
    int AirCondition_adjustTemperature_Sync(char *pszDeviceId,int iScale,int iTimeout);
    // 设置工作模式
    int AirCondition_setMode_Sync(char *pszDeviceId,std::string strMode,int iTemperture,int iTimeout);
    // 设置送风模式
    int AirCondition_setWindMode_Sync(char *pszDeviceId,std::string strWindMode,int iTimeout);
    // 一键控制
    int AirCondition_oneKeyControl(char *pszDeviceId,bool bIsOn,std::string strMode,
                                   int iTemperature,std::string strWindMode,int iTimeout);
    
    // 取得空调状态
    int AirCondition_getState_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iTemperture,std::string &strMode,std::string &strWindMode,float &fActTemperture,int iTimeout);
    
    
    //智能电表
    // 获取智能电表配置
    int IntelligentAmmeter_getConfig_Sync(std::vector<Smarthome_IntelligentAmmeter> &vecDevices,int iTimeout);
    // 设置智能电表配置
    int IntelligentAmmeter_setConfig_Sync(std::vector<Smarthome_IntelligentAmmeter> &vecDevices,int iTimeout);
    // 获取智能电表设备基本信息
    int IntelligentAmmeter_getBasicInfo(char *pszDeviceId,IntelligentAmmeter_BasicInfo &stInfo,int waittime);
    // 获取电表数据
    int IntelligentAmmeter_readMeter(char *pszDeviceId,PositiveEnergy &stPositive,InstancePower &stInst,int waittime);
    // 获取电表上次结算数据
    int IntelligentAmmeter_readMeterPrev(char *pszDeviceId,int &iTime,PositiveEnergy &stPositive,int waittime);
    
    //报警
    // 布撤防
    int Alarm_setArmMode(const char *pszDeviceId,const char *mode,const char *password,int waittime);
    // 取得报警防区状态
    int Alarm_getArmMode_Sync(char *pszDeviceId,std::string &strMode,int iTimeout);
    
    // 视频遮挡配置
    int GetVideoCovers(bool &bEnable,int iTimeout);
    int SetVideoCovers(bool bEnable,int iTimeout);
    
    //IPCamera
    // 取得IPC状态
    int IPC_getState_Sync(char *pszDeviceId,bool &bIsOnline,int iTimeout);
    
    //订阅
    int Subscrible_Sync(int iTimeout);
    //取消订阅
    int Unsubscrible_Sync(int iTimeout);
    
    // 实时上传数据－图片
    int RealLoadPicture(int iTimeout);
    
    // 停止上传数据－图片
    int StopLoadPic(int iTimeout);
    
    // 抓图请求
    int SnapPicture(char *pszDeviceId,int iTimeout);
    
    
    ///////////////门禁控制
    int AccessControl_modifyPassword(char *type,char *user,char *oldPassword,char *newPassword,int waittime);
    ////////////////////外部接口///////////////////////
    
    
    //子连接使能开关
    bool EnableSubConnect(bool bEnable);
    bool StartListen();
    bool StopListen();
    
    //实时监视
    unsigned int StartRealPlay(int iChannel,fRealDataCallBack pCb,void * pUser);
    //停止监视
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
    
    int Connect_Async(); //连接 异步
    int PollData(); //轮询数据
    int Process_Data(); //处理数据
    int SendData(char *pData,int iDataLen); //发送数据
    void OnDataPacket(const char *pData,int pDataLen);
    bool LoginRequest(); //登录请求
    bool LoginRequest(unsigned int uiSessId,const char *pPasswordMd5,const char *pPasswordType,const char *pRandom,const char *pRealm); //登录请求(权鉴信息)
    bool KeepaliveRequest(); //保活请求
    bool LogoutRequest(); //登出请求
    
    struct TransInfo;
    //收到注册回应
    void OnLoginResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //收到保活回应
    void OnKeepaliveResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //收到登出回应
    void OnLogoutResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    
    //收到通知消息
    void OnNotification(dvip_hdr &hdr,const char *pData,int pDataLen);
    
    //收到分包数据
    int OnPackage(dvip_hdr &hdr,const char *pData,int pDataLen);
    
    //收到获取智能家居管理实例回应
    void OnSmarthome_instance_rsp(TransInfo *pTrans,const char *pData,int pDataLen);
    //收到释放智能家居管理实例回应
    void OnSmarthome_destroy_rsp(TransInfo *pTrans,const char *pData,int pDataLen);
    //收到获取设备列表回应
    void OnSmarthome_getDeviceList_rsp(TransInfo *pTrans,const char *pData,int pDataLen);
    
    void OnConnect(); //连接成功通知
    void OnDataRecv(); //接收数据通知
    void OnDataSend(); //可以发送数据通知
    
    void OnDisConnected(int iReason);
    void OnRegisterSuccess(int iReason);
    void OnRegisterFailed(int iReason);
    
    
    //获取智能家居实例
    bool Smarthome_instance_Req();
    //收到回应
    void OnSmarthome_instance_Rsp(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //释放智能家居实例
    bool Smarthome_destory_Req(unsigned int uiObject);
    //收到回应
    void OnSmarthome_destroy_Rsp(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //获取智能家居设备列表
    bool Smarthome_getDeviceList_Req(unsigned int uiObject,int iType);
    //收到回应
    void OnSmarthome_getDeviceList_Rsp(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    
    //创建对象实例 全局实例
    int Dvip_instance(char *pszMethod,unsigned &uiObject,int iTimeout=5000);
    //创建对象实例 通过设备id
    int Dvip_instance(char *pszMethod,char *pszDeviceId,unsigned &uiObject,int iTimeout=5000);
    //创建对象实例 全局实例
    int Dvip_instance(char *pszMethod,const Json::Value &jsParams,unsigned &uiObject,int iTimeout=5000);
    //释放实例
    int Dvip_destroy(char *pszMethod,unsigned uiObject,int iTimeout=5000);
    
    //调用方法 输入输出参数为空,方法返回值为bool 一般函数原型 bool call(void)
    int Dvip_method_v_b_v(char *pszMethod,unsigned uiObject,bool &bResult,int iTimeout=5000);
    
    //调用方法 输入参数为json(params : {}),输出参数也为json(params : {}),方法返回值为bool 一般函数原型 bool call(void)
    int Dvip_method_json_b_json(char *pszMethod,unsigned uiObject,Json::Value &inParams,bool &bResult,Json::Value &outParams,int iTimeout=5000);
    
    //调用方法 输入参数为空,输出参数为空,方法返回值为bool 一般函数原型 bool call(void)
    //int Dvip_method_v_b_bbi(char *pszMethod,unsigned uiObject,bool &bReturn,bool &bOutParam1,bool &bOutParam2,int &iOutParam3,int iTimeout=5000);
    //获取窗帘状态
    int Dvip_Light_getState(char *pszMethod,unsigned uiObject,bool &bReturn,bool &bIsOnline,bool &bIsOn,int &iBright,int iTimeout=5000);
    //获取窗帘状态
    int Dvip_Curtain_getState(char *pszMethod,unsigned uiObject,bool &bReturn,bool &bIsOnline,bool &bIsOn,int &iShading,int iTimeout=5000);
    
    //获取配置信息
    int Dvip_getConfig(unsigned uiObject,char *pszConfigPath,bool &bResult,Json::Value &jsonCfg,int iTimeout=5000);
    //设置配置信息
    int Dvip_setConfig(unsigned uiObject,char *pszConfigPath,Json::Value &jsonCfg,bool &bResult,int iTimeout=5000);
    
    //设置配置信息
    int Dvip_setDeviceInfo(unsigned uiObject,Json::Value &jsonCfg,bool &bResult,int iTimeout=5000);
    
    //解析场景信息
    bool ParseScence(Json::Value &jsonConfig,std::vector<Smarthome_SceneInfo> &vecScenes);
    //打包场景信息
    bool EncodeScence(Json::Value &jsonConfig,std::vector<Smarthome_SceneInfo> &vecScenes);
    
    //获取设备配置信息
    int Dvip_getDevConfig(unsigned uiObject,char *pszConfigPath,bool &bResult,Json::Value &jsonCfg,int iTimeout=5000);
    
    //断线退出清理事务
    void Clear_Tasks();
    
    /////////线程处理////////////
#ifdef WIN32
    static unsigned long __stdcall ThreadProc(void *pParam);
#else
    static void* ThreadProc(void *pParam);
#endif
    void ThreadProc(void);
    void Thread_Process();
    
    //启动处理线程
    int StartThread();
    //结束处理线程
    int StopThread();
    
    //任务处理
    void Process_Task();
    
    FCL_THREAD_HANDLE m_hThread;
    bool m_bExitThread;
    
    
    //本端信息
    std::string m_strUsername;  //用户名
    std::string m_strPassword;  //密码
    
    //服务端信息
    std::string m_strServIp; //服务端ip
    int m_iServPort;		 //服务端端口
    
    FCL_SOCKET m_sSock; //连接套接字
    EmStatus m_emStatus; //连接状态
    int m_error;//错误码
    unsigned int m_uiSessionId; //登录会话id
    int m_iTimeout; //超时时间 秒
    int m_iFailedTimes; //连续失败次数
    bool m_bAutoReConnect;	//是否自动重连
    bool m_bIsFirstConnect;	//是否第一次连接
    unsigned int m_uiLoginId;
    long long m_llLastTime;
    
    //请求类型
    enum EmRequestType
    {
        emRT_Unknown,		//未知类型
        
        
        emRT_method_v_b_v,	//通用方法 void call(void)
        emRT_method_json_b_json,	//通用方法 bool call([IN] json,[OUT] json)
        
        emRT_instance,		//获取实例
        emRT_destroy,		//销毁实例
        
        emRT_getConfig,		//获取配置
        emRT_setConfig,		//设置配置
        
        emRT_Login,			//登录请求
        emRT_Keepalive,		//保活请求
        emRT_Logout,		//登出请求
        
        ////////////////智能家居////////////////
        emRT_Smarthome_instance,		//获取实例
        emRT_Smarthome_destroy,			//销毁实例
        emRT_Smarthome_getDeviceList,	//获取设备列表
        
        emRT_Smarthome_setDeviceInfo,	//设置设备信息
        
        //灯光
        emRT_Light_instance,			//获取实例
        emRT_Light_destroy,				//释放实例
        emRT_Light_open,				//开灯
        emRT_Light_close,				//关灯
        emRT_Light_getState,			//获取状态
        
        //窗帘
        emRT_Curtain_instance,			//获取实例
        emRT_Curtain_destroy,			//释放实例
        emRT_Curtain_open,				//打开
        emRT_Curtain_close,				//关闭
        emRT_Curtain_stop,				//停止
        emRT_Curtain_getState,			//获取状态
        ////////////////智能家居////////////////
        //emRT_Login,			//登录请求
        
        ////////////////设备配置////////////////
        emRT_MagicBox_instance,		//获取实例
        emRT_MagicBox_destroy,			//销毁实例
        emRT_MagicBox_getDevConfig,		//查询设备配置
        
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
        long long	start; //任务发起时间
        unsigned int timeout; //超时时间
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
    //请求列表
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
    TransInfo * FetchRequest(unsigned int uiReq) //从列表中取出
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
    
    // 网络连接断开回调
    fOnDisConnect m_cbOnDisConnect;
    void *m_pUser;
    
    // 网络连接状态变化回调
    fOnDisConnectEx m_cbOnDisConnectEx;
    void *m_pUserEx;
    
    //订阅信息
    // 状态变化回调函数原形
    fOnEventNotify m_cbOnEventNotify;
    void *m_pEventNotifyUser;
    
    unsigned int m_uiEventObjectId;
    unsigned int m_uiSid;
    unsigned int m_uiSubscribeReqId;
    bool m_bHasSubscrible;
    
    //报警通知
    fOnAlarmNotify m_cbOnAlarmNotify;
    void *m_pAlarmNotifyUser;
    
    unsigned int m_uiSnapObjectId;
    //unsigned int m_uiSnapSid;
    
    const static  int MAX_BUF_LEN = 1024*128;
    //网络接收缓冲
    char m_szRecvBuf[MAX_BUF_LEN];
    int m_iRecvIndex; //接收缓冲索引
    
    static unsigned int s_ui_RequestId; 
    static unsigned int s_ui_LoginId; 
    static unsigned int s_ui_RealHandle; 
    
    const static unsigned int GS_LOGIN_TIMEOUT = 15000;			//登录超时时间
    const static unsigned int GS_KEEPALIVE_INTEVAL = 15000;		//保活间隔
    const static unsigned int GS_TIMEOUT = 30000;				//超时时间
    
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