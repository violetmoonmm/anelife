//
//  DeviceData.h
//  eLife
//
//  Created by mac on 14-4-2.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>


#define SH_DEVICE_COMMLIGHT         @"CommLight"
#define SH_DEVICE_LEVELLIGHT        @"LevelLight"
#define SH_DEVICE_CURTAIN           @"Curtain"
#define SH_DEVICE_AIRCONDITION      @"AirCondition"
#define SH_DEVICE_IPC               @"IPCamera"
#define SH_DEVICE_ALARMZONE         @"AlarmZone"
#define SH_DEVICE_GROUNDHEAT        @"GroundHeat"
#define SH_DEVICE_AMMETER           @"IntelligentAmmeter"
#define SH_DEVICE_BACKGROUNDMUSIC   @"BackgroundMusic"
#define SH_DEVICE_FRESHAIR          @"FreshAir"
#define SH_DEVICE_HUMITURE          @"Humiture"
#define SH_DEVICE_SOCKET            @"BlanketSocket"
#define SH_DEVICE_ENVMONITOR        @"EnvironmentMonitor"
#define SH_DEVICE_IRC               @"InfraredRemoteControl"


typedef enum _GetConfigStep
{
    GetConfigStepWaiting = 0,
    GetConfigStepDoing = 1,
    GetConfigStepFinished = 2
    
} GetConfigStep;


typedef enum _GatewayState
{
    GatewayStatusInit = 0,//初始状态（未登录或正在登录）
    GatewayStatusLoginFailed = 1,//登录失败
    GatewayStatusOnline = 2,//登录成功后在线
    GatewayStatusOffline = 3,//登录成功后，后来断线
    
} GatewayState;


typedef enum _VideoQuality
{
   
    VideoQualityClear = 0,//清晰
    VideoQualityFluent = 1//流畅
    
} VideoQuality;


enum _ErroCode
{
    ErrorAdded = 100, //该网关已经添加
    ErrorTimeout = 101 //超时
};


typedef struct _SHRange
{
    NSInteger min;
    NSInteger max;
    
    
} SHRange;

//设备状态基类
@interface SHStateBase : NSObject

@property (nonatomic) BOOL online;
@property (nonatomic) BOOL powerOn;

@end

//开关型灯光状态
@interface SHLightState : SHStateBase


@end

//调光型灯光状态
@interface SHDimmerLightState : SHLightState

@property (nonatomic) int brightness;

@end

//窗帘状态
@interface SHCurtainState : SHStateBase

@property (nonatomic) int shading;

@end

//空调状态
@interface SHAirconditionState : SHStateBase

@property (nonatomic) int temperature;//设置温度
@property (nonatomic) float environmentTemp;//环境温度
//@property (nonatomic,strong) NSString *mode; //模式 "1"自动 ，"2"制冷 ，"3"制热 "4"除湿 "5"送风
//@property (nonatomic,strong) NSString *windSpeed; //风速 "1"自动 ，"2"低速 "3"中速 "4"高速

@property (nonatomic,strong) NSString *mode; //模式 "Auto" "Hot" "Cold" "Wet" "Wind"
@property (nonatomic,strong) NSString *windSpeed; //风速 "Stop" "Auto" "High" "Middle" "Low"


@end

//地暖状态
@interface SHGroundHeatState : SHStateBase

@property (nonatomic) int temperature;

@end

//背景音乐状态
@interface SHBgdMusicState : SHStateBase

@property (nonatomic,assign) BOOL mute;//是否静音
@property (nonatomic,strong) NSString *song;//音乐
@property (nonatomic,strong) NSString *playState;//播放状态 Play/Pause/Stop
@property (nonatomic,strong) NSString *name;
@property (nonatomic,assign) NSInteger volume;//音量

@end

//报警防区状态
@interface SHAlarmZoneState : SHStateBase

//@property (nonatomic,strong) NSString *mode;//报警模式，布撤防

@property (nonatomic) bool enable;//布放是否开启

@end

//电表状态
@interface SHAmmeterState : SHStateBase

@property (nonatomic,strong) NSDictionary *data;//电表数据

@end


@interface SHInfraredRemoteControlState : SHStateBase

@property (nonatomic,assign) BOOL STUOn;//机顶盒
@property (nonatomic,assign) BOOL TVOn;//电视

@end

@interface SHGatewayStatus : NSObject

@property (nonatomic,assign) bool remoteOnline;//是否远程在线
@property (nonatomic,assign) bool localOnline;//是否本地在线

@property (nonatomic,assign) GatewayState state;

@end


/* 智能家居设备 */
@interface SHDevice : NSObject

//@property (nonatomic,strong) NSString *virtualCode;//设备虚号
@property (nonatomic,strong) NSString *type;
@property (nonatomic,strong) NSString *name;

@property (nonatomic,strong) NSString *udn;//udn(远程模式)
@property (nonatomic,strong) NSString *serialNumber;//序列号

@property (nonatomic,strong) NSMutableArray *serviceList;

@property (nonatomic,strong) NSString *gatewaySN;//所属网关序列号
@property (nonatomic,strong) NSString *gatewayVC;//所属网关虚号（远程模式）

@property (nonatomic,strong) NSString *roomId;
@property (nonatomic,strong) NSString *roomName;

@property (nonatomic,strong) SHStateBase *state;

@property (nonatomic,strong) NSString *cameraId;
@property (nonatomic,strong) NSString *icon;//显示图标


@property (nonatomic,strong) id range;

- (NSInteger)maxRange;
- (NSInteger)minRange;

@end

//网关
@interface SHGateway : NSObject

@property (nonatomic,strong) NSString *virtualCode;//虚号
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *pswd;
@property (nonatomic,strong) NSString *serialNumber;//序列号
@property (nonatomic,strong) NSString *user;
@property (nonatomic,strong) NSString *addr;//
@property (nonatomic,assign) NSInteger port;
@property (nonatomic,assign) NSInteger type;
@property (nonatomic,strong) NSString *typeEx;
@property (nonatomic,strong) NSString *position;
@property (nonatomic,strong) NSString *commName;

@property (nonatomic,strong) NSString *city;//城市
@property (nonatomic,strong) NSString *ISP;//运营商
@property (nonatomic,strong) NSString *externalIP;//外部IP
@property (nonatomic,assign) NSInteger grade;//等级

@property (nonatomic,strong) SHGatewayStatus *status;//连接状态
@property (nonatomic,assign) NSInteger disconnectReason;//未连接原因

@property (nonatomic,strong) NSString *changeId;//配置变更id

@property (nonatomic,strong) NSString *authCode;//授权码
@property (nonatomic,assign) BOOL authorized;//授权是否成功

@property (nonatomic,strong) NSString *ARMSAddr;
@property (nonatomic,assign) NSInteger ARMSPort;

@property (nonatomic) UInt32 loginId;


//配置
@property (nonatomic,strong,readonly) NSMutableArray *roomArray;//房间列表
@property (nonatomic,strong,readonly) NSMutableArray *ipcArray;//ipc列表
@property (nonatomic,strong,readonly) NSMutableArray *alarmZoneArray;//报警防区列表
@property (nonatomic,strong,readonly) NSMutableArray *sceneModeArray;//情景模式列表
@property (nonatomic,strong,readonly) NSMutableArray *deviceArray;//设备列表
@property (nonatomic,strong,readonly) NSMutableArray *ammeterArray;//电表
@property (nonatomic,strong,readonly) NSMutableArray *envMonitorArray;//环境监测仪器


@property (nonatomic) GetConfigStep getConfigStep;//智能家居配置获取step


//ipc远程 (for temp use...)
@property (nonatomic) BOOL IPCPublic;//是否已经获取过IPC远程的配置



- (BOOL)isOnline;

- (void)putDeviceIntoRoom;

- (NSArray *)devicesForType:(NSString *)deviceType;

- (NSString *)roomNameForDevice:(SHDevice *)device;

@end



/* 视频设备 */
@interface SHVideoDevice : SHDevice

//@property (nonatomic,strong) NSString *virtualCode;//设备虚号
@property (nonatomic,strong) NSString *user;//用户
@property (nonatomic,strong) NSString *pswd;//密码
@property (nonatomic,strong) NSString *ip;//网路ip
@property (nonatomic) NSInteger port;//端口
@property (nonatomic) NSInteger devChannel;//设备通道号
@property (nonatomic) NSInteger devType;//设备类型 0 ipc 1 门口机

//公网
@property (nonatomic,strong) NSString *pubUser;//用户
@property (nonatomic,strong) NSString *pubPswd;//密码
@property (nonatomic,strong) NSString *pubIp;//网路ip
@property (nonatomic) NSInteger pubPort;//端口

@property (nonatomic) NSUInteger loginId;
@property (nonatomic) bool coverEnable;


- (NSString *)videoUrl;

- (NSString *)pubVideoUrl;

@end

/*报警防区*/
@interface SHAlarmZone : SHDevice

//@property (nonatomic,strong) NSString *channelId;//通道id
//@property (nonatomic,strong) NSString *deviceId;//设备id
@property (nonatomic,strong) NSString *sensorType;//报警类型
@property (nonatomic,strong) NSString *sensorMethod;
@property (nonatomic,strong) NSString *ipcID;//联动视频ipcid

@end

/*情景模式*/
@interface SHSceneMode : SHDevice

//@property (nonatomic,strong) NSString *sceneName;//情景模式名


@end

/*红外遥控器*/
@interface SHInfraredRemoteControl : SHDevice

@property (nonatomic,strong) NSString *moduleName;//模块


@end


@interface SHLayout : NSObject

@property (nonatomic,strong) NSString *layoutId;
@property (nonatomic,strong) NSString *layoutName;
@property (nonatomic,strong) NSString *gatewaySN;//所属网关序列号
@property (nonatomic,strong) NSString *gatewayVC;//所属网关虚号


@end

@interface SHFloor : SHLayout

@end

@interface SHRoom : SHLayout

@property (nonatomic,strong) NSString *floorId;
@property (nonatomic) NSInteger type;//节点类型: 0 未定义 1 厨房 2 客厅 3 餐厅 4 卧室 5 卫生间 6 书房

@property (nonatomic,strong,readonly) NSMutableArray *deviceArray;

@end




