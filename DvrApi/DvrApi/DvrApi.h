#ifndef DvrApi_h
#define DvrApi_h

#if (defined(WIN32) || defined(WIN64))

#ifdef CLIENTSDK_EXPORTS

#ifndef CLIENT_API
#define CLIENT_API  __declspec(dllexport)
#endif

#else

#ifndef CLIENT_API
#define CLIENT_API  __declspec(dllimport)
#endif

#endif

#define CALLBACK __stdcall
#define CALL_METHOD  __stdcall  //__cdecl



#else	//linux

#define CLIENT_API	extern "C"
#define CALL_METHOD
#define CALLBACK


#endif

//typedef DVR_HANDLE unsigned int;

#define Int16 short
#define UInt16 unsigned short

#define Int32 int
#define UInt32 unsigned int

//#define Int64 long long
//#define UInt64 unsigned long long

#ifdef __cplusplus
extern "C" {
#endif
    
    /************************************************************************
     ** 常量定义
     ***********************************************************************/
#define VIRT_CODE_LEN 			    64			// 虚号最大长度
#define UDN_LEN 				    256			// UDN最大长度
#define LOCATION_LEN 				512			// Location最大长度
#define DEVICETYPE_LEN 				256			// 设备类型最大长度
#define DEVICENAME_LEN 				256			// 设备名称最大长度
#define PARAM_LEN 				    64			// 参数最大长度
#define MAX_SERVICE_LEN 		    256			// 最大长度
#define MAX_SERVICE_NUM 		    32			// 一个设备拥有最大服务数目
#define MAX_PATH_LEN 		        260			// 文件路径最大长度
    
#define MAX_LAYOUT_NAME				64
    
    /************************************************************************
     ** 枚举定义
     ***********************************************************************/
    
    /************************************************************************
     ** 结构体定义
     ***********************************************************************/
    
    // 设备信息
    typedef struct
    {
        char		 szDeviceId[UDN_LEN];				// 设备id
        char         szDeviceName[UDN_LEN];				// 设备名称
        char         szDeviceType[DEVICETYPE_LEN];		// 设备类型
        char         szRoomId[MAX_LAYOUT_NAME];			// 设备所在房间
    }SMARTHOME_DEVICE, *LPSMARTHOME_DEVICE;
    
    // 楼层信息
    typedef struct
    {
        char szId[MAX_LAYOUT_NAME];		//编号
        char szName[MAX_LAYOUT_NAME];	//名称
    }LAYOUT_FLOOR,*LPLAYOUT_FLOOR;
    
    // 房间信息
    typedef struct
    {
        char szId[MAX_LAYOUT_NAME];		//编号
        char szFloor[MAX_LAYOUT_NAME];	//楼层
        int iType;						//节点类型: 0 未定义 1 厨房 2 客厅 3 餐厅 4 卧室 5 卫生间 6 书房
        char szName[MAX_LAYOUT_NAME];  //名称
    }LAYOUT_ROOM,*LPLAYOUT_ROOM;
    
    // 灯光配置信息
    typedef struct
    {
        char szName[MAX_LAYOUT_NAME];	//名称
        char szBrand[MAX_LAYOUT_NAME];	//厂家
        char szId[MAX_LAYOUT_NAME];		//设备ID
        //char szType[MAX_LAYOUT_NAME];	//设备类型
        char szAddress[MAX_LAYOUT_NAME];//设备地址,分段如12.1.1.1
        int iAreaId;					//设备区域地址
        int xPos;						//设备区域坐标
        int yPos;						//设备区域坐标
        char szState[64];				//设备状态 "Open" 打开 "Close" 关闭
        int iRange;						//灯亮度幅度值 LevelLight可调灯时，此值才有意义
        char szType[64];				//灯光设备类型 CommLight普通灯光 或LevelLight可调灯
    }LIGHT_CONFIG,*LPLIGHT_CONFIG;
    
    // 灯光状态信息
    typedef struct
    {
        bool bIsOnline;		//设备是否在线
        bool bIsOn;			//灯光是否打开
        int iBright;		//灯光强度 整形值
    }LIGHT_STATE,*LPLIGHT_STATE;
    
    // 窗帘配置信息
    typedef struct
    {
        char szName[MAX_LAYOUT_NAME];	//名称
        char szBrand[MAX_LAYOUT_NAME];	//厂家
        char szId[MAX_LAYOUT_NAME];		//设备ID
        //char szType[MAX_LAYOUT_NAME];	//设备类型
        char szAddress[MAX_LAYOUT_NAME];//设备地址,分段如12.1.1.1
        int iAreaId;					//设备地址
        int xPos;						//设备区域坐标
        int yPos;						//设备区域坐标
        char szState[64];				//设备状态 "Open" 打开 "Close" 关闭
        int iRange;						//幅度值
        char szType[64];				//设备类型 Curtain
    }CURTAIN_CONFIG,*LPCURTAIN_CONFIG;
    
    // 窗帘状态信息
    typedef struct
    {
        bool bIsOnline;		//设备是否在线
        bool bIsOn;			//灯光是否打开
        int iShading;		//窗帘遮光率 整形值，最大100
    }CURTAIN_STATE,*LPCURTAIN_STATE;
    
    // 地暖配置信息
    typedef struct
    {
        char szName[MAX_LAYOUT_NAME];	//名称
        char szBrand[MAX_LAYOUT_NAME];	//厂家
        char szId[MAX_LAYOUT_NAME];		//设备ID
        //char szType[MAX_LAYOUT_NAME];	//设备类型
        char szAddress[MAX_LAYOUT_NAME];//设备地址,分段如12.1.1.1
        int iAreaId;					//设备地址
        int xPos;						//设备区域坐标
        int yPos;						//设备区域坐标
        char szState[64];				//设备状态 "Open" 打开 "Close" 关闭
        int iRange;						//幅度值(温度)
    }GROUNDHEAT_CONFIG,*LPGROUNDHEAT_CONFIG;
    
    // 地暖状态信息
    typedef struct
    {
        bool bIsOnline;		//设备是否在线
        bool bIsOn;			//灯光是否打开
        int iTemperature;	//地暖温度 整形值
    }GROUNDHEAT_STATE,*LPGROUNDHEAT_STATE;
    
    // 空调配置信息
    typedef struct
    {
        char szName[MAX_LAYOUT_NAME];	//名称
        char szBrand[MAX_LAYOUT_NAME];	//厂家
        char szId[MAX_LAYOUT_NAME];		//设备ID
        //char szType[MAX_LAYOUT_NAME];	//设备类型
        char szAddress[MAX_LAYOUT_NAME];//设备地址,分段如12.1.1.1
        int iAreaId;					//设备地址
        int xPos;						//设备区域坐标
        int yPos;						//设备区域坐标
        char szState[64];				//设备状态 "Open" 打开 "Close" 关闭
        int iRange;						//幅度值(温度)	单位：摄氏度
        char szType[64];				//设备类型 AirCondition
        char szMode[64];				//工作模式 "Auto"自动 "Hot"制热 "Cold"制冷 "Wet"除湿 "Wind"通风
        char szWindMode[64];			//风速 "Stop"停止 "Auto"自动 "High"高速 "Middle"中速 "Low"低速
    }AIRCONDITION_CONFIG,*LPAIRCONDITION_CONFIG;
    
    // 空调状态信息
    typedef struct
    {
        bool bIsOnline;			//设备是否在线
        bool bIsOn;				//灯光是否打开
        int iTemperature;		//空调温度 整形值
        char szMode[64];		//模式 "Auto" "Hot" "Cold" "Wet" "Wind"
        char szWindMode[64];	//风速 "Stop" "Auto" "High" "Middle" "Low"
        float fActTemperature;	//当前温度
    }AIRCONDITION_STATE,*LPAIRCONDITION_STATE;
    
    // 报警防区状态信息
    typedef struct
    {
        char szMode[64];		//模式 "Arming" "Disarming"
    }ALARMZONE_STATE,*LPALARMZONE_STATE;
    
    
    // IPCamera状态信息
    typedef struct
    {
        bool bIsOnline;			//设备是否在线
    }IPCAMERA_STATE,*LPIPCAMERA_STATE;
    
    // 参数信息
    typedef struct
    {
        char          szName[PARAM_LEN];				// udn
        char          szValue[PARAM_LEN];				// 设备类型
    }ACTION_PARAM, *LPACTION_PARAM;
    
    // 智能家居情景模式
    typedef struct
    {
        char szBrand[MAX_LAYOUT_NAME];		//厂家名称
        char szName[MAX_LAYOUT_NAME];		//情景名称
        //灯光列表
        LPLIGHT_CONFIG pLights;	//灯光列表
        int iLightCount;
        
        //窗帘列表
        LPCURTAIN_CONFIG pCurtains;	//窗帘列表
        int iCurtainCount;
        
        //地暖列表
        LPGROUNDHEAT_CONFIG pGroundHeats;	//地暖列表
        int iGroundHeatCount;
        
        //空调列表
        LPAIRCONDITION_CONFIG pAirConditions;	//空调列表
        int iAirConditionCount;
        
        
    }SMARTHOME_SCENE_MODE,*LPSMARTHOME_SCENE_MODE;
    
#define MAX_YEAR_ZONE		16	//最大年时区数
#define MAX_DAY_ZONE_TABLE  16	//最大日时段表数
#define MAX_DAY_ZONE		10	//最大日段数
    
    // 电表配置信息
    typedef struct
    {
        char szName[MAX_LAYOUT_NAME];	//名称
        char szBrand[MAX_LAYOUT_NAME];	//厂家
        char szId[MAX_LAYOUT_NAME];		//设备ID
        char szAddress[MAX_LAYOUT_NAME];//设备地址,分段如12.1.1.1
        int iAreaId;					//设备地址
        int xPos;						//设备区域坐标
        int yPos;						//设备区域坐标
        char szType[64];				//设备类型 IntelligentAmmeter
    }INTELLIGENTAMMETER_CONFIG,*LPINTELLIGENTAMMETER_CONFIG;
    
    typedef struct
    {
        int iTime;											//电表当前时间
        char szTabelNo[16];									//表号
        char szDeviceNo[16];								//设备号
        int iRateCount;										//费率数目<=4
        int YearZoneCount;									//年时区数目
        int DayZoneTableCount;								//日时段表数目
        char yz[MAX_YEAR_ZONE][3];							//年时段 第一字节为月,第二字节为日,第三字节为日时段表号
        char dz[MAX_DAY_ZONE_TABLE][MAX_DAY_ZONE][3];		//日时段 第一字节为小时,第二字节为分钟,第三字节为费率号
    }INTM_BASIC_INFO,*LPINTM_BASIC_INFO;
    
    //正向能量参数
    typedef struct INTM_POSITIVE_ENERGY_t
    {
        int iPositiveActiveEnergy;			//正向正向有功总电能	单位: (kWh)/100
        int iSharpPositiveActiveEnergy;		//尖时段正向有功总电能	单位: (kWh)/100
        int iPeakPositiveActiveEnergy;		//峰时段正向有功总电能	单位: (kWh)/100
        int iShoulderPositiveActiveEnergy;	//平时段正向有功总电能	单位: (kWh)/100
        int iOffPeakPositiveActiveEnergy;	//谷时段正向有功总电能	单位: (kWh)/100
        
        int iPositiveReactiveEnergy;		//正向无功总电量		单位: (kWh)/100
        int iSharpPositiveReactiveEnergy;	//尖时段正向无功总电量	单位: (kWh)/100
        int iPeakPositiveReactiveEnergy;	//峰时段正向无功总电量	单位: (kWh)/100
        int iShoulderPositiveReactiveEnergy;//平时段正向无功总电量	单位: (kWh)/100
        int iOffPeakPositiveReactiveEnergy;	//谷时段正向无功总电量	单位: (kWh)/100
    }INTM_POSITIVE_ENERGY,*LPINTM_POSITIVE_ENERGY;
    
    //正向功率参数
    typedef struct INTM_POSITIVE_POWER_t
    {
        int iActivePower;	//有功功率
        int iReactivePower;	//无功功率
    }INTM_POSITIVE_POWER,*LPINTM_POSITIVE_POWER;
    
    /************************************************************************
     ** 回调函数定义
     ***********************************************************************/
    
    // 网络连接断开回调函数原形
    typedef void (CALLBACK *fOnDisConnect)(UInt32 lLoginID,char *pchServIP,UInt16 nServPort,void *pUser);
    
    // 网络连接断开回调函数原形 status 状态 0 断开 1 登录成功 2 登录失败 reason 失败原因
    typedef void (CALLBACK *fOnDisConnectEx)(UInt32 lLoginID,char *pchServIP,UInt16 nServPort,Int32 status,Int32 reason,void *pUser);
    
    // 状态变化回调函数原形
    typedef void (CALLBACK *fOnEventNotify)(UInt32 lLoginID,char *pszDeviceId,char *pszDeviceType,char *pEventInfo,void *pUser);
    
    //报警通知回调函数原型
    typedef void (CALLBACK *fOnAlarmNotify)(unsigned int uiLoginID,int iAlarmChannel,int iAlarmState,char *pExtInfo,
                                            char *szBuf,int iBufSize,void *pUser);
    
    //设备搜索回调函数原形
    typedef void (CALLBACK *fOnIPSearch)(char *pDeviceInfo,void *pUser);
    
    //实时监视数据回调
    typedef void (CALLBACK *fRealDataCallBack)(
                                               unsigned int  uiRealHandle,
                                               int  dwDataType,
                                               char  *szBuf,
                                               int  iBufsize,
                                               void* pUser
                                               );
    /************************************************************************
     ** 接口定义
     ***********************************************************************/
    
    // SDK初始化
    
    CLIENT_API bool CALL_METHOD CLIENT_Init_Dvr(fOnDisConnect cbDisConnect,void *pUser);
    CLIENT_API bool CALL_METHOD CLIENT_InitEx(fOnDisConnectEx cbDisConnect,void *pUser);
    
    // SDK退出清理
    CLIENT_API void CALL_METHOD CLIENT_Cleanup_Dvr();
    
    //------------------------------------------------------------------------
    
    
    //------------------------------------------------------------------------
    
    // 设置是否断线重连
    CLIENT_API void CALL_METHOD CLIENT_SetAutoReconnect_Dvr(bool bReconnect);
    
    // 向设备注册
    CLIENT_API UInt32 CALL_METHOD CLIENT_Login_Dvr(char *pchServIP,UInt16 wServPort,char *pchUsername,char *pchPassword,Int32 *error=0);
    
    
    // 向设备注销
    CLIENT_API bool CALL_METHOD CLIENT_Logout_Dvr(UInt32 hLoginID);
    
    // 设置订阅消息回调
    CLIENT_API void CALL_METHOD CLIENT_SetEventNotify_Dvr(fOnEventNotify fcbEvent,void *pUser);
    
    // 设置报警消息回调
    CLIENT_API void CALL_METHOD CLIENT_SetAlarmNotify_Dvr(fOnAlarmNotify fcbAlarm,void *pUser);
    
    // 订阅
    CLIENT_API bool CALL_METHOD CLIENT_Subscrible(UInt32 hLoginID
                                                  ,bool bIsSubscrible
                                                  ,Int32 waittime=1000);
    
    
    ////////////配置
    // 删除配置
    //CLIENT_API bool CALL_METHOD CLIENT_ConfigManager_deleteFile(UInt32 hLoginID,Int32 waittime=1000);
    // 删除指定配置
    //CLIENT_API bool CALL_METHOD CLIENT_ConfigManager_deleteConfig(UInt32 hLoginID
    //															  ,char *pszName
    //																,Int32 waittime=1000);
    
    //------------------------------------------------------------------------
    //////////////////////////智能家居//////////////////////////
    //// 获取房间信息
    //CLIENT_API bool CALL_METHOD CLIENT_SmartHome_getConfig_HouseTypeInfo(UInt32 hLoginID
    //																	,LPLAYOUT_FLOOR pFloors
    //																	,Int32 maxFloors
    //																	,Int32 *floors
    //																	,LPLAYOUT_ROOM pRooms
    //																	,Int32 maxRooms
    //																	,Int32 *rooms
    //																	,Int32 waittime=1000);
    //// 设置房间信息
    //CLIENT_API bool CALL_METHOD CLIENT_SmartHome_setConfig_HouseTypeInfo(UInt32 hLoginID
    //																	,LPLAYOUT_FLOOR pFloors
    //																	,Int32 floors
    //																	,LPLAYOUT_ROOM pRooms
    //																	,Int32 rooms
    //																	,Int32 waittime=1000);
    //// 获取情景模式信息
    //CLIENT_API bool CALL_METHOD CLIENT_SmartHome_getConfig_SceneMode(UInt32 hLoginID
    //																 ,int *iCurrentId
    //																,LPSMARTHOME_SCENE_MODE pScenes
    //																,Int32 maxScenes
    //																,Int32 *scenes
    //																,Int32 waittime=1000);
    //// 设置情景模式信息
    //CLIENT_API bool CALL_METHOD CLIENT_SmartHome_setConfig_SceneMode(UInt32 hLoginID
    //																 ,int iCurrentId
    //																,LPSMARTHOME_SCENE_MODE pScenes
    //																,Int32 scenes
    //																,Int32 waittime=1000);
    //// 获取UPNP设备列表
    //CLIENT_API bool CALL_METHOD CLIENT_SmartHome_getDeviceList(UInt32 hLoginID
    //														   ,LPSMARTHOME_DEVICE pDevices
    //														   ,Int32 maxlen
    //														   ,Int32 *devicecount
    //															,Int32 waittime=1000);
    
    //CLIENT_API bool CALL_METHOD CLIENT_SmartHome_getDeviceDigest(UInt32 hLoginID
    //																 ,char *pszType
    //																 ,char *pszDigest
    //																 ,Int32 waittime=1000);
    
    CLIENT_API bool CALL_METHOD CLIENT_SmartHome_setDeviceInfo(UInt32 hLoginID,char *pszDeviceId,char * pszName,Int32 waittime=1000);
    
    // 获取智能家居情景模式
    CLIENT_API bool CALL_METHOD CLIENT_SmartHome_getSceneMode(UInt32 hLoginID
                                                              ,char *pszScene
                                                              ,Int32 length
                                                              ,Int32 waittime=1000);
    // 设置情景模式
    CLIENT_API bool CALL_METHOD CLIENT_SmartHome_setSceneMode(UInt32 hLoginID
                                                              ,char *pszSceneId
                                                              ,Int32 waittime=1000);
    
    // 保存情景模式,pszScene名称，pDevices设备列表
    CLIENT_API bool CALL_METHOD CLIENT_SmartHome_saveSceneMode(UInt32 hLoginID
                                                               ,char *pszScene
                                                               ,LPSMARTHOME_DEVICE pDevices
                                                               ,Int32 devices
                                                               ,Int32 waittime=1000);
    
    // 修改情景模式名称,pszSceneId模式ID,pszScene名称
    CLIENT_API bool CALL_METHOD CLIENT_SmartHome_modifySceneMode(UInt32 hLoginID
                                                                 ,char *pszSceneId
                                                                 ,char *pszScene
                                                                 ,Int32 waittime=1000);
    
    // 删除情景模式，pszSceneId
    CLIENT_API bool CALL_METHOD CLIENT_SmartHome_removeSceneMode(UInt32 hLoginID
                                                                 ,char *pszSceneId
                                                                 ,Int32 waittime=1000);
    
    //////////////////////////灯光//////////////////////////
    //// 获取灯光配置
    //CLIENT_API bool CALL_METHOD CLIENT_Light_getConfig(UInt32 hLoginID
    //												,LPLIGHT_CONFIG pLights
    //											     ,Int32 maxLights
    //												 ,Int32 *lights
    //												 ,Int32 waittime=1000);
    //// 设置灯光配置
    //CLIENT_API bool CALL_METHOD CLIENT_Light_setConfig(UInt32 hLoginID
    //												 ,LPLIGHT_CONFIG pLights
    //												 ,Int32 lights
    //												 ,Int32 waittime=1000);
    
    // 灯光控制 开
    CLIENT_API bool CALL_METHOD CLIENT_Light_open(UInt32 hLoginID,char *pszDeviceId,Int32 waittime=1000);
    // 灯光控制 关
    CLIENT_API bool CALL_METHOD CLIENT_Light_close(UInt32 hLoginID,char *pszDeviceId,Int32 waittime=1000);
    // 灯光控制 设置灯光亮度
    CLIENT_API bool CALL_METHOD CLIENT_Light_setBrightLevel(UInt32 hLoginID,char *pszDeviceId,int iLevel,Int32 waittime=1000);
    // 灯光控制 调节灯光亮度
    CLIENT_API bool CALL_METHOD CLIENT_Light_adjustBright(UInt32 hLoginID,char *pszDeviceId,int iLevel,Int32 waittime=1000);
    // 灯光控制 延时关灯
    CLIENT_API bool CALL_METHOD CLIENT_Light_keepOn(UInt32 hLoginID,char *pszDeviceId,int iTime,Int32 waittime=1000);
    // 灯光控制 灯闪烁
    CLIENT_API bool CALL_METHOD CLIENT_Light_blink(UInt32 hLoginID,char *pszDeviceId,int iTime,Int32 waittime=1000);
    // 灯光控制 以指定速度打开一组灯
    CLIENT_API bool CALL_METHOD CLIENT_Light_openGroup(UInt32 hLoginID,char *pszDeviceId,int iType,int iSpeed,Int32 waittime=1000);
    // 灯光控制 以指定速度关闭一组灯
    CLIENT_API bool CALL_METHOD CLIENT_Light_closeGroup(UInt32 hLoginID,char *pszDeviceId,int iType,int iSpeed,Int32 waittime=1000);
    // 灯光控制 以指定速度调亮灯光
    CLIENT_API bool CALL_METHOD CLIENT_Light_brightLevelUp(UInt32 hLoginID,char *pszDeviceId,int iType,int iSpeed,Int32 waittime=1000);
    // 灯光控制 以指定速度调暗灯光
    CLIENT_API bool CALL_METHOD CLIENT_Light_brightLevelDown(UInt32 hLoginID,char *pszDeviceId,int iType,int iSpeed,Int32 waittime=1000);
    // 灯光控制 获取灯状态
    CLIENT_API bool CALL_METHOD CLIENT_Light_getState(UInt32 hLoginID,char *pszDeviceId,LPLIGHT_STATE pState,Int32 waittime=1000);
    
    
    //////////////////////////窗帘//////////////////////////
    // 获取窗帘配置
    //CLIENT_API bool CALL_METHOD CLIENT_Curtain_getConfig(UInt32 hLoginID
    //													,LPCURTAIN_CONFIG pDevices
    //													,Int32 maxDevice
    //													,Int32 *devices
    //													,Int32 waittime=1000);
    //// 设置窗帘配置
    //CLIENT_API bool CALL_METHOD CLIENT_Curtain_setConfig(UInt32 hLoginID
    //													,LPCURTAIN_CONFIG pDevices
    //													,Int32 devices
    //													,Int32 waittime=1000);
    //打开
    CLIENT_API bool CALL_METHOD CLIENT_Curtain_open(UInt32 hLoginID,char *pszDeviceId,Int32 waittime=1000);
    //关闭
    CLIENT_API bool CALL_METHOD CLIENT_Curtain_close(UInt32 hLoginID,char *pszDeviceId,Int32 waittime=1000);
    //停止
    CLIENT_API bool CALL_METHOD CLIENT_Curtain_stop(UInt32 hLoginID,char *pszDeviceId,Int32 waittime=1000);
    //调整窗帘遮光率
    CLIENT_API bool CALL_METHOD CLIENT_Curtain_adjustShading(UInt32 hLoginID,char *pszDeviceId,int iScale,Int32 waittime=1000);
    //设置窗帘遮光率
    CLIENT_API bool CALL_METHOD CLIENT_Curtain_setShading(UInt32 hLoginID,char *pszDeviceId,int iScale,Int32 waittime=1000);
    //获取窗帘设备状态
    CLIENT_API bool CALL_METHOD CLIENT_Curtain_getState(UInt32 hLoginID,char *pszDeviceId,LPCURTAIN_STATE pState,Int32 waittime=1000);
    
    
    //////////////////////////地暖//////////////////////////
    //// 获取地暖配置
    //CLIENT_API bool CALL_METHOD CLIENT_GroundHeat_getConfig(UInt32 hLoginID
    //														,LPGROUNDHEAT_CONFIG pDevices
    //														,Int32 maxDevices
    //														,Int32 *devices
    //														,Int32 waittime=1000);
    //// 设置地暖配置
    //CLIENT_API bool CALL_METHOD CLIENT_GroundHeat_setConfig(UInt32 hLoginID
    //														,LPGROUNDHEAT_CONFIG pDevices
    //														,Int32 devices
    //														,Int32 waittime=1000);
    // 开
    CLIENT_API bool CALL_METHOD CLIENT_GroundHeat_open(UInt32 hLoginID,char *pszDeviceId,Int32 waittime=1000);
    // 关
    CLIENT_API bool CALL_METHOD CLIENT_GroundHeat_close(UInt32 hLoginID,char *pszDeviceId,Int32 waittime=1000);
    // 设定地暖温度
    CLIENT_API bool CALL_METHOD CLIENT_GroundHeat_setTemperature(UInt32 hLoginID,char *pszDeviceId,int iTemperature,Int32 waittime=1000);
    // 调节地暖温度
    CLIENT_API bool CALL_METHOD CLIENT_GroundHeat_adjustTemperature(UInt32 hLoginID,char *pszDeviceId,int iScale,Int32 waittime=1000);
    // 获取地暖状态
    CLIENT_API bool CALL_METHOD CLIENT_GroundHeat_getState(UInt32 hLoginID,char *pszDeviceId,LPGROUNDHEAT_STATE pState,Int32 waittime=1000);
    
    
    //////////////////////////空调//////////////////////////
    //// 获取空调配置
    //CLIENT_API bool CALL_METHOD CLIENT_AirCondition_getConfig(UInt32 hLoginID
    //														,LPAIRCONDITION_CONFIG pDevices
    //														,Int32 maxDevices
    //														,Int32 *devices
    //														,Int32 waittime=1000);
    //// 设置空调配置
    //CLIENT_API bool CALL_METHOD CLIENT_AirCondition_setConfig(UInt32 hLoginID
    //														,LPAIRCONDITION_CONFIG pDevices
    //														,Int32 devices
    //														,Int32 waittime=1000);
    // 开
    CLIENT_API bool CALL_METHOD CLIENT_AirCondition_open(UInt32 hLoginID,char *pszDeviceId,Int32 waittime=1000);
    // 关
    CLIENT_API bool CALL_METHOD CLIENT_AirCondition_close(UInt32 hLoginID,char *pszDeviceId,Int32 waittime=1000);
    // 设定空调温度
    CLIENT_API bool CALL_METHOD CLIENT_AirCondition_setTemperature(UInt32 hLoginID,char *pszDeviceId,int iTemperature,Int32 waittime=1000);
    // 调节温度
    CLIENT_API bool CALL_METHOD CLIENT_AirCondition_adjustTemperature(UInt32 hLoginID,char *pszDeviceId,int iScale,Int32 waittime=1000);
    // 设置工作模式
    CLIENT_API bool CALL_METHOD CLIENT_AirCondition_setMode(UInt32 hLoginID,char *pszDeviceId,char *pszMode,int iTemperature,Int32 waittime=1000);
    // 设置送风模式
    CLIENT_API bool CALL_METHOD CLIENT_AirCondition_setWindMode(UInt32 hLoginID,char *pszDeviceId,char *pszWindMode,Int32 waittime=1000);
    // 取得空调状态
    CLIENT_API bool CALL_METHOD CLIENT_AirCondition_getState(UInt32 hLoginID,char *pszDeviceId,LPAIRCONDITION_STATE pState,Int32 waittime=1000);
    // 一键控制
    CLIENT_API bool CALL_METHOD CLIENT_AirCondition_oneKeyControl(UInt32 hLoginID,char *pszDeviceId,bool bIsOn,char *pszMode,
                                                                  int iTemperature,char * pszWindMode,Int32 waittime=1000);
    
    //////////////////////////智能电表//////////////////////////
    //// 获取智能电表配置
    //CLIENT_API bool CALL_METHOD CLIENT_IntelligentAmmeter_getConfig(UInt32 hLoginID
    //																,LPINTELLIGENTAMMETER_CONFIG pDevices
    //																,Int32 maxDevices
    //																,Int32 *devices
    //																,Int32 waittime=1000);
    //// 设置智能电表配置
    //CLIENT_API bool CALL_METHOD CLIENT_IntelligentAmmeter_setConfig(UInt32 hLoginID
    //																,LPINTELLIGENTAMMETER_CONFIG pDevices
    //																,Int32 devices
    //																,Int32 waittime=1000);
    // 获取智能电表设备基本信息
    CLIENT_API bool CALL_METHOD CLIENT_IntelligentAmmeter_getBasicInfo(UInt32 hLoginID,char *pszDeviceId,LPINTM_BASIC_INFO pInfo,Int32 waittime=1000);
    // 获取电表数据
    CLIENT_API bool CALL_METHOD CLIENT_IntelligentAmmeter_readMeter(UInt32 hLoginID,char *pszDeviceId,LPINTM_POSITIVE_ENERGY pEnergy,LPINTM_POSITIVE_POWER pPower,Int32 waittime=1000);
    // 获取电表上次结算数据
    CLIENT_API bool CALL_METHOD CLIENT_IntelligentAmmeter_readMeterPrev(UInt32 hLoginID,char *pszDeviceId,int *pTime,LPINTM_POSITIVE_ENERGY pEnergy,Int32 waittime=1000);
    
    //////门禁
    // 修改密码
    //type 密码类型	OpenDoor-开门密码 Alarm-防劫持报警密码
    //user 用户ID
    //oldPassword 旧密码
    //newPassword 新密码
    CLIENT_API bool CALL_METHOD CLIENT_AccessControl_modifyPassword(UInt32 hLoginID,char *type,char *user,char *oldPassword,char *newPassword,Int32 waittime=1000);
    
    
    // 读取配置信息
    //szName 配置名称 读取支持的配置 HouseTypeInfo 户型图 Light(CommLight 普通型 LevelLight 可调光) 灯光
    //Curtain 窗帘 GroundHeat 地暖 AirCondition 空调 IntelligentAmmeter 智能电表
    //AlarmZone 报警防区 IPCamera IP摄像头 SceneMode情景模式 ChangeId配置变更ID
    //szBuf 缓冲区 获取
    //iBufSize 缓冲区大小 调用时指定szBuf的大小 返回时内部会返回实际结果大小
    //注 如果输入缓冲区太小 ,也会失败,此时iBufSize会返回实际需要的缓冲区大小
    CLIENT_API bool CALL_METHOD CLIENT_ConfigManager_getConfig(UInt32 hLoginID,char *szName,char *szBuf,int *iBufSize,Int32 waittime=1000);
    
    //////报警Alarm
    // 布撤防
    //mode 模式 Arming 布防 Disarming 撤防
    //password 布撤防密码
    CLIENT_API bool CALL_METHOD CLIENT_Alarm_setArmMode(UInt32 hLoginID,char *pszDeviceId,char *mode,char *password,Int32 waittime=1000);
    
    // 取得防区状态
    CLIENT_API bool CALL_METHOD CLIENT_Alarm_getArmMode(UInt32 hLoginID,char *pszDeviceId,LPALARMZONE_STATE pState,Int32 waittime=1000);
    
    // 视频遮挡配置
    CLIENT_API bool CALL_METHOD CLIENT_GetVideoCovers(UInt32 hLoginID,bool &bEnable,Int32 waittime=1000);
    CLIENT_API bool CALL_METHOD CLIENT_SetVideoCovers(UInt32 hLoginID,bool bEnable,Int32 waittime=1000);
    
    //////////////////////////IPCamera//////////////////////////
    // 获取摄像机状态
    CLIENT_API bool CALL_METHOD CLIENT_IPCamera_getState(UInt32 hLoginID,char *pszDeviceId,LPIPCAMERA_STATE pState,Int32 waittime=1000);
    
    
    // 机器操作,读取设备配置
    //szName 操作名称 读取支持的配置 getSerialNo 获取设备序列号
    //szBuf 缓冲区 获取
    //iBufSize 缓冲区大小 调用时指定szBuf的大小 返回时内部会返回实际结果大小
    //注 如果输入缓冲区太小 ,也会失败,此时iBufSize会返回实际需要的缓冲区大小
    CLIENT_API bool CALL_METHOD CLIENT_getDevConfig(UInt32 hLoginID,char *szName,char *szBuf,int *iBufSize,Int32 waittime=1000);
    
    // 实时上传数据－图片
    CLIENT_API bool CALL_METHOD CLIENT_RealLoadPicture(UInt32 hLoginID,Int32 waittime=1000);
    
    // 停止上传数据－图片
    CLIENT_API bool CALL_METHOD CLIENT_StopLoadPic(UInt32 hLoginID,Int32 waittime=1000);
    
    // 抓图请求
    //CLIENT_API bool CALL_METHOD CLIENT_SnapPicture(UInt32 hLoginID,char *pszDeviceId,Int32 waittime=1000);
    
    //子连接（基于二代协议）使能开关，使能后IPC报警、码流提取等功能接口才有效
    CLIENT_API bool CALL_METHOD CLIENT_EnableSubConnect(UInt32 hLoginID,bool bEnable);
    
    //监听报警
    //CLIENT_API bool CALL_METHOD CLIENT_StartListen(UInt32 hLoginID);
    //停止监听报警
    //CLIENT_API bool CALL_METHOD CLIENT_StopListen(UInt32 hLoginID);
    
    
    //实时监视
    CLIENT_API unsigned int CALL_METHOD CLIENT_StartRealPlay(UInt32 hLoginID,int iChannel,fRealDataCallBack pCb,void * pUser);
    //停止监视
    CLIENT_API bool CALL_METHOD CLIENT_StopRealPlay(unsigned int uiRealHandle);
    
    
    //开启设备搜索
    CLIENT_API bool CALL_METHOD CLIENT_StartDevFinder(fOnIPSearch pFcb,void *pUser);
    //停止设备搜索
    CLIENT_API bool CALL_METHOD CLIENT_StopDevFinder();
    //搜索,可指定mac地址
    CLIENT_API bool CALL_METHOD CLIENT_IPSearch(char *szMac);
    
#ifdef __cplusplus
}
#endif

#endif
