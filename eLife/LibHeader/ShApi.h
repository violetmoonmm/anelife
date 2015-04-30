#ifndef ShApi_h
#define ShApi_h

#if (defined(WIN32) || defined(WIN64))

#ifdef SHAPI_EXPORTS

#ifndef SH_API
#define SH_API  __declspec(dllexport)
#endif

#else

#ifndef SH_API
#define SH_API  __declspec(dllimport)
#endif

#endif

#define CALLBACK __stdcall
#define CALL_METHOD  __stdcall  //__cdecl



#else	//linux

#define SH_API	extern "C"
#define CALL_METHOD
#define CALLBACK


#endif

#ifdef __cplusplus
extern "C" {
#endif
    
    /************************************************************************
     ** 枚举定义
     ***********************************************************************/
    enum emWorkMode	//工作模式
    {
        emLocal = 0x01,
        emRemote,
    };
    
    enum emEventType	//事件类型
    {
        emDeviceState = 0x01,	//设备状态
        emAlarm,				//报警
        emDownFile,				//文件下载
    };
    
    //错误码
    enum EmDisConnectReason
    {
        emDisRe_None=0,					//不需要
        emDisRe_ConnectFailed=10001,    //连接失败
        emDisRe_Disconnected,           //断线
        emDisRe_RegistedFailed,			//注册失败
        emDisRe_RegistedRefused,		//注册被拒绝
        emDisRe_Keepalivetimeout,		//保活失败
        emDisRe_UserInvalid,			//用户名无效
        emDisRe_PasswordInvalid,		//密码无效
        emDisRe_SerialNoInvalid,		//序列号无效
        emDisRe_AuthCodeInvalid,		//授权码无效
        emDisRe_AuthFailed,				//授权码认证失败
        emDisRe_NotAuthMode,			//小网关不在授权模式，拒绝授权
        emDisRe_OutOfAuthLimit,			//超过授权用户额度，拒绝授权
        
        emDisRe_AuthOK,					//认证成功
        
        emDisRe_ParamInvalid = 10021,	//参数异常
        
        emDisRe_Unknown = 10101,                //未知原因
    };
    /************************************************************************
     ** 结构体定义
     ***********************************************************************/
    typedef struct _UserInfo
    {
        char szVCode[20];//用户虚号
        char szPwd[20];//用户密码（callid）
        char szMeid[64];//meid
        char szPhoneNumber[20];//手机号
        char szModel[32];//手机型号
    }UserInfo;
    
    typedef struct _UamsInfo
    {
        char szServerIp[20];	//uams服务器IP
        int iPort;
        char szServerVCode[20];
    }UamsInfo;
    
    typedef struct _GatewayInfo //网关信息
    {
        char szSn[64];			//序列号
        char szGwVCode[20];		//虚号
        char szIp[20];
        int iPort;
        char szUser[20];
        char szPwd[20];
    }GatewayInfo;
    
    /************************************************************************
     ** 回调函数定义
     ***********************************************************************/
    
    // 网络连接断开回调函数原形 status 状态 0 断开 1 登录成功 2 登录失败 reason 失败原因
    // mode 本地/远程
    typedef void (CALLBACK *fOnDisConnect)(unsigned int hLoginID,emWorkMode mode,
                                           char *pchServIP,int nServPort,int status,int reason,void *pUser);
    
    // 状态变化回调函数原形
    // pszEvent为状态信息，与type值相关
    // emDeviceState:  {"Data":{"Bright":0,"Level":0,"Name":"1-1","On":false,"Online":true},"DeviceId":"Dahua#01052688#16843009","Type":"CommLight"}
    // emAlarm: {"Action":"Stop","Data":"","DeviceId":"","Type":"AlarmZone"}
    // emFileEnd: {"Data":{"FilePath":"","LocalPath":"","Result":true},"DeviceId":"","Type":"DownFile"}
    typedef void (CALLBACK *fOnEventNotify)(unsigned int hLoginID,emEventType type,char * pszEvent,void *pUser);
    
    //设备搜索回调函数原形
    typedef void (CALLBACK *fOnIPSearch)(char *pDeviceInfo,void *pUser);
    
    /************************************************************************
     ** 接口定义
     ***********************************************************************/
    
    // SDK初始化
    SH_API bool CALL_METHOD SH_Init(fOnDisConnect cbDisConnect,void *pUser);
    
    // SDK退出清理
    SH_API void CALL_METHOD SH_Cleanup();
    
    // Syslog使能
    SH_API void CALL_METHOD SH_EnableSyslog(bool bEnable,char *szIp,int iPort);
    
    //------------------------------------------------------------------------
    
    
    //------------------------------------------------------------------------
    
    // 设置订阅消息回调
    SH_API void CALL_METHOD SH_SetEventNotify(fOnEventNotify fcbEvent,void *pUser);
    
    ////设置客户端信息
    //SH_API void CALL_METHOD SH_SetClientInfo(char * szVCode,char *szPwd,char *szMeid);
    
    //设置大华云服务连接信息,此时不向uams建立连接
    SH_API void CALL_METHOD SH_SetServerInfo(UserInfo user,UamsInfo uams);
    
    //平台转发使能
    SH_API bool CALL_METHOD SH_EnableRemote(bool bEnable);
    
    // 添加网关映射,内部建立直连和平台转发连接（超时时间分别为5000ms和10000ms），在线状态和错误码通过SH_GateWayStatus接口查询
    SH_API unsigned int CALL_METHOD SH_AddGateWay(GatewayInfo gwInfo);
    
    // 删除网关映射，删除网关时内部断开直连连接，取消远程状态订阅，网关被删光时断开平台转发连接
    SH_API bool CALL_METHOD SH_DelGateWay(unsigned int hLoginID);
    
    // 查询在线状态，在掉线回调通知里也可以调用
    SH_API bool CALL_METHOD SH_GateWayStatus(unsigned int hLoginID,bool & bLocal,int & nLocalError,
                                             bool & bRemote,int & nRemoteError);
    
    //网关授权，获取授权码
    SH_API int CALL_METHOD SH_GatewayAuth(unsigned int hLoginID,char *szBuf,int iBufSize);
    //验证授权码
    SH_API bool CALL_METHOD SH_VerifyAuthCode(unsigned int hLoginID,const char *sAuthCode);
    
    //网络恢复时通知sdk立即重连网关
    SH_API void CALL_METHOD SH_ManuelReconnect();
    
    // 读取配置信息
    /*szConfigName 配置名称 读取支持的配置 HouseTypeInfo 户型图 Light(CommLight 普通型 LevelLight 可调光) 灯光
     Curtain 窗帘 GroundHeat 地暖 AirCondition 空调 IntelligentAmmeter 智能电表
     AlarmZone 报警防区 IPCamera IP摄像头 SceneMode情景模式 ChangeId配置变更ID
     EnvironmentMonitor环境检测仪 BlanketSocket通用插座  All所有设备（灯、窗帘、、、IP摄像头 报警防区）
     ComInterface串口 DeviceController控制器
     ShareFile共享文件（.panel.zip为面板）
     AuthUser授权用户
     
     szBuf 缓冲区 获取
     iBufSize 缓冲区大小 调用时指定szBuf的大小 返回时内部会返回实际结果大小
     注 如果输入缓冲区太小 ,也会失败,此时iBufSize会返回实际需要的缓冲区大小*/
    /*
     所有设备列表形如：
     {"Devices":{"AirCondition":[{"AreaID":3,"ControlMode":"oneKey","DeviceID":"401","Name":"鍗у绌鸿皟","Online":true,"Range":[15,30],"Type":"AirCondition"}],"AlarmZone":null,
     "BlanketSocket":[{"AreaID":4,"DeviceID":"902","Name":"澶у崕閫氱敤鎻掑骇","Online":true,"Type":"BlanketSocket"}],
     "Curtain":null,
     "EnvironmentMonitor":null,
     "GroundHeat":null,
     "IPCamera":[{"AreaID":2,"DeviceID":"0","Ip":"10.48.1.103","Name":"181-103","Password":"admin","Port":37777,"Type":"IPCamera","Username":"admin"}],
     "IntelligentAmmeter":[{"AreaID":0,"DeviceID":"301","Name":"鐢佃〃","Online":true,"Type":"IntelligentAmmeter"}],
     "Light":null}}
     */
    SH_API bool CALL_METHOD SH_GetConfig(unsigned int hLoginID,char *szConfigName,char *szBuf,int *iBufSize);
    
    //工程配置接口
    SH_API bool CALL_METHOD SH_SetConfig(unsigned int hLoginID,char *szConfigName,char *szBuf,int iBufSize);
    
    //智能家居控制，pszDevType设备类型支持CommLight/LevelLight/Curtain/AirCondition/BlanketSocket
    /*pszParams控制参数根据pszDevType有变化
     CommLight
     开灯 {"action":"open"}
     关灯 {"action":"close"}
     
     LevelLight
     开灯 {"action":"open"}
     关灯 {"action":"close"}
     调光 {"action":"setBrightLevel","Level":-1}
     
     Curtain
     开 {"action":"open"}
     关 {"action":"close"}
     停 {"action":"stop"}
     调行程 {"action":"setShading","Scale":-1}
     
     AirCondition
     开 {"action":"open"}
     关 {"action":"close"}
     温度控制 {"action":"setTemperature","Temperature":25}
     模式控制 {"action":"setMode","Mode":"Auto"/"Cold"/"Hot"/"Wet"/"Wind","Temperature":25}
     风速控制 {"action":"setWindMode","WindMode":"Stop"/"Auto"/"High"/"Middle"/"Low"}
     组合控制 {"action":"CompoundControl","On":true,"Mode":"Auto"/"Cold"/"Hot"/"Wet"/"Wind","Temperature":25,"WindMode":"Stop"/"Auto"/"High"/"Middle"/"Low"}
     
     BlanketSocket
     开 {"action":"open"}
     关 {"action":"close"}
     
     GroundHeat
     开 {"action":"open"}
     关 {"action":"close"}
     温度控制 {"action":"setTemperature","Temperature":25}
     
     BackgroundMusic
     开 {"action":"open"}
     关 {"action":"close"}
     静音 {"action":"mute","Enable":true}
     暂停播放 {"action":"pause"}
     恢复播放 {"action":"resume"}
     上一曲 {"action":"lastPiece"}
     下一曲 {"action":"nextPiece"}
     设置音量 {"action":"setVolume","Volume":20}
     */
    SH_API bool CALL_METHOD SH_Control(unsigned int hLoginID,char * pszDevType,char *pszDeviceId,char *pszParams,int iParamsLen);
    
    /*智能家居状态查询,
     pszDevType设备类型支持CommLight/LevelLight/Curtain/AirCondition/
     IntelligentAmmeter/BlanketSocket/GroudHeat/All/BackgroundMusic
     szBuf为输出参数，由外部分配内存，形如：{"State":{"Bright":1,"On":true,"Online":true}}*/
    
    /*DevType传值“All”时返回所有设备的状态，格式形如：
     [
     {"DeviceID":"1001","DeviceType":"CommLight","State":{"Bright":0,"On":false,"Online":false}},
     {"DeviceID":"2001","DeviceType":"LevelLight","State":{"Bright":0,"On":false,"Online":false}},
     {"DeviceID":"503","DeviceType":"GroundHeat","State":{"On":false,"Online":false,"Temperature":0}},
     {"DeviceID":"5001","DeviceType":"AirCondition","State":{"ActualTemperature":0.0,"Mode":"","On":false,"Online":false,"Temperature":0,"WindMode":""}},
     {"DeviceID":"0","DeviceType":"AlarmZone","State":{"Enable":true}},
     {"DeviceID":"902","DeviceType":"BlanketSocket","State":{"On":false,"Online":false}}
     ]
     */
    
    SH_API bool CALL_METHOD SH_GetState(unsigned int hLoginID,char * pszDevType,char *pszDeviceId,
                                        char *szBuf,int iBufSize);
    
    /*智能家居设备信息读取（如抄表、查询环境监测信息等）,pszDevType设备类型,pszParams读取操作，不同类型设备支持读取操作不一样
     IntelligentAmmeter
     抄表 readMeter
     szBuf返回
     {
     "InstantPower":{			瞬时功率
     "ActivePower":530,		瞬时有功（NN.NNNN）（数值*1000）
     "ReactivePower":0		瞬时无功（NN.NNNN）（数值*1000）
     },
     “PositiveEnergys”:{	正向电量信息
     "PositiveActiveEnergy" : 111	正向有功总电量（实际总电量*100，比如1234.12kWh表示为123412，下同）	(kWh)/100
     "SharpPositiveActiveEnergy" : 11	尖时段正向有功总电量（可选项，当前大部分地区都没有使用这个时段）	(kWh) /100
     "PeakPositiveActiveEnergy" : 11	峰时段正向有功总电量	(kWh) /100
     "ShoulderPositiveActiveEnergy" : 11	平时段正向有功总电量	(kWh) /100
     "OffPeakPositiveActiveEnergy" : 11	谷时段正向有功总电量	(kWh) /100
     "PositiveReactiveEnergy" : 111	正向无功总电量	(kWh) /100
     "SharpPositiveReactiveEnergy" : 111	尖时段正向无功总电量	(kWh) /100
     "PeakPositiveReactiveEnergy" : 111	峰时段正向无功总电量	(kWh) /100
     "ShoulderPositiveReactiveEnergy" : 111	平时段正向无功总电量	(kWh) /100
     "OffPeakPositiveReactiveEnergy" : 111	谷时段正向无功总电量	(kWh) /100
     }
     }
     
     抄上一次结算结果 readMeterPrev
     szBuf返回
     {"PositiveEnergys":{"OffPeakPositiveActiveEnergy":4020,"OffPeakPositiveReactiveEnergy":0,"PeakPositiveActiveEnergy":7102,"PeakPositiveReactiveEnergy":0,"PositiveActiveEnergy":11122,"PositiveReactiveEnergy":0,"SharpPositiveActiveEnergy":0,"SharpPositiveReactiveEnergy":0,"ShoulderPositiveActiveEnergy":0,"ShoulderPositiveReactiveEnergy":0}}
     
     EnvironmentMonitor
     读空气质量 readMeter
     szBuf返回{
     "EnvironmentQuality":{
     "CH4":0.0,							甲烷           单位 %
     "CO":0.0,							一氧化碳		ppm
     "CO2":867.0,						二氧化碳		ppm
     "HCHO":0.0,							甲醛			ppb
     "Humidity":31.10000038146973,		湿度			%
     "Illuminance":48.0,					光照度			lx
     "Occupancy":256.0,					人体接近感应
     "PM25":99.0,						PM2.5			ug/m3
     "Temperature":23.60000038146973,
     "VOC":230.0							挥发性有机物    ppb
     }
     }
     */
    SH_API bool CALL_METHOD SH_ReadDevice(unsigned int hLoginID,char * pszDevType,char *pszDeviceId,
                                          char *pszParams,char *szBuf,int iBufSize);
    
    // 设置情景模式
    SH_API bool CALL_METHOD SH_SetSceneMode(unsigned int hLoginID,char *pszSceneId);
    
    //////报警Alarm
    // 布撤防 password 布撤防密码
    SH_API bool CALL_METHOD SH_SetArmMode(unsigned int hLoginID,char *pszDeviceId,bool bEnable,char *password);
    
    // 取得防区状态
    SH_API bool CALL_METHOD SH_GetArmMode(unsigned int hLoginID,char *pszDeviceId,bool & bEnable);
    
    // 视频遮挡配置,本地模式直接连接IPC设备控制，暂不支持远程
    //SH_API bool CALL_METHOD SH_GetVideoCovers(unsigned int hLoginID,bool & bEnable);
    
    //SH_API bool CALL_METHOD SH_SetVideoCovers(unsigned int hLoginID,bool bEnable);
    
    // 视频遮挡配置，通过小网关修改IPC
    SH_API bool CALL_METHOD SH_GetVideoCovers(unsigned int hLoginID,char *pszDeviceId,bool & bEnable);
    
    SH_API bool CALL_METHOD SH_SetVideoCovers(unsigned int hLoginID,char *pszDeviceId,bool bEnable);
    
    // 共享文件下载，列表查询见GetConfig.ShareFile
    // pszShareFile共享文件名 pszLocalPath本地存储路径
    SH_API bool CALL_METHOD SH_DownloadShareFile(unsigned int hLoginID,char * pszShareFile,char *pszLocalPath);
    
    // 删除授权用户，列表查询见GetConfig.AuthList
    SH_API bool CALL_METHOD SH_DelAuth(unsigned int hLoginID,char * pszPhone,char *pszMeid);
    
    //恢复配置
    SH_API bool CALL_METHOD SH_ResetConfig(unsigned int hLoginID);
    
    //重启小网关
    SH_API bool CALL_METHOD SH_RestartDev(unsigned int hLoginID);
    
    //重启网关设备
    SH_API bool CALL_METHOD SH_RebootDev(unsigned int hLoginID);
    
    //开启设备搜索
    SH_API bool CALL_METHOD SH_StartDevFinder(fOnIPSearch pFcb,void *pUser);
    //停止设备搜索
    SH_API bool CALL_METHOD SH_StopDevFinder();
    //搜索,可指定mac地址
    SH_API bool CALL_METHOD SH_IPSearch(char *szMac,bool bGateWayOnly = true);
    
#ifdef __cplusplus
}
#endif

#endif
