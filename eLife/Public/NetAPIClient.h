//
//  NetAPIClient.h
//  eLife
//
//  Created by mac on 14-3-17.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"
#import "DeviceData.h"
#import "User.h"



//错误码，映射sdk错误码：EmDisConnectReason
enum DisConnectReason
{
    DisRe_None=0,					//不需要
    DisRe_ConnectFailed=10001,    //连接失败
    DisRe_Disconnected,           //断线
    DisRe_RegistedFailed,			//注册失败
    DisRe_RegistedRefused,		//注册被拒绝
    DisRe_Keepalivetimeout,		//保活失败
    DisRe_UserInvalid,			//用户名无效
    DisRe_PasswordInvalid,		//密码无效
    DisRe_SerialNoInvalid,		//序列号无效
    DisRe_AuthCodeInvalid,		//授权码无效
    DisRe_AuthFailed,				//授权码认证失败
    DisRe_NotAuthMode,			//小网关不在授权模式，拒绝授权
    DisRe_OutOfAuthLimit,			//超过授权用户额度，拒绝授权
    
    DisRe_AuthOK,					//认证成功
    
    DisRe_ParamInvalid = 10021,	//参数异常
    
    DisRe_Unknown = 10101,                //未知原因
};

@interface NetAPIClient : NSObject
{
@public
    void *icrc_handle;
}

@property (nonatomic,strong,readonly) NSString *callId;

@property (nonatomic,strong,readonly) NSMutableArray *gatewayList;//网关列表

//重定向后的服务器ip和port
@property (nonatomic,strong,readonly) NSString *serverAddr;
@property (nonatomic,readonly) int serverPort;


@property (nonatomic,readonly) NSString *lastVersion;//最新客户端版本号

@property (nonatomic,readonly) VersionInfo *versionInfo;

@property (nonatomic,assign) BOOL MQConnected;

@property (nonatomic,assign) BOOL enableReconnect;//是否需要平台重连


+ (NetAPIClient *)sharedClient;



- (void)beginTask;

//检查版本
- (void)checkVersion:(void (^)(VersionInfo *))successCallback failureCallback:(void (^)(void))failureCallback;

//- (VersionInfo *)checkVersion;

//用户注册
- (void)userRegister:(NSString *)user pswd:(NSString *)pswd email:(NSString *)email authCode:(NSString *)authCode  authCodeText:(NSString *)authCodeText successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback;

//用户登录
- (void)loginWithUser:(NSString *)user psd:(NSString *)psd successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback;

//重新登录
- (void)loginInBackground;


- (void)queryGatewayListFromDB;

//待修改...
- (void)cancelLogin;
- (void)cancelLogout;

- (void)registerPushService:(NSString *)token;

//找回密码
- (void)retrievePassword:(NSString *)user email:(NSString *)email successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback;

//修改密码
- (void)changeOldPassword:(NSString *)oldPswd newPassword:(NSString *)newPswd successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback;

//修改邮箱
- (void)changeEmail:(NSString *)newEmail successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback;

//用户登出
- (void)logoutTimeout:(int)timeout successCallback:(void(^)(void))successCallback failureCallback:(void (^)(void))failureCallback;

//申请重置
- (void)applyResetPasswordWithUser:(NSString *)user  successCallback:(void (^)(NSDictionary *result))successCallback failureCallback:(void (^)(int errCode))failureCallback;

//发送重置密码
- (void)resetPasswordWithUser:(NSString *)user pswd:(NSString *)pswd  successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback;

//重置身份识别码
- (void)resetAuthCodeWithUser:(NSString *)user pswd:(NSString *)pswd  authCode:(NSString *)authCode successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback;



//获取智能家居配置
- (void)getSHConfig;

- (void)sendToken:(NSString *)token;

- (void)connectMQ;

- (void)SHCleanUp;


//网关数
- (NSInteger)numberOfGateways;

//设备数
- (NSInteger)numberOfDevices;

//根据网关id查网关
- (SHGateway *)lookupGatewayById:(NSString *)gatewaySN;



//查询ipc列表
- (void)getIpcList:(void(^)(NSArray *))callback;

//查询ipc码流
- (void)getIpcBitrate:(SHDevice *)device successCallback:(void (^)(VideoQuality grade))successCallback failureCallback:(void (^)(void))failureCallback;

//设置码流
- (void)setIpcBitrate:(SHDevice *)device quality:(VideoQuality)quality successCallback:(void (^)(void))successCallback failureCallback:(void (^)(void))failureCallback;

//查询视频资源转发数是否达到限制
- (void)queryIpcVideoCount:(SHDevice *)device successCallback:(void (^)(BOOL max))successCallback failureCallback:(void (^)(void))failureCallback;

//查询共享面板列表
- (void)getShareFileListOfGateway:(SHGateway *)gateway successCallback:(void (^)(NSArray *fileList))successCallback failureCallback:(void (^)(void))failureCallback;

//下载共享文件
- (void)downloadShareFile:(NSString *)remotePath toLocalPath:(NSString *)localPath fromGateway:(SHGateway *)gateway successCallback:(void (^)(void))successCallback failureCallback:(void (^)(void))failureCallback;

//批量下载共享文件
- (void)downloadShareFiles:(NSArray *)remotePaths toLocalPaths:(NSArray *)localPaths fromGateway:(SHGateway *)gateway;

//呼叫开锁
- (void)unlockSuccessCallback:(void(^)(void))successCallback
              failureCallback:(void(^)(void))failureCallback;

#pragma mark 网关操作

//删除网关绑定
- (void)removeGateway:(SHGateway *)gateway timeout:(int)timeout successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback;

//绑定网关
- (void)bindGateway:(SHGateway *)gateway successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback;

//修改网关信息
- (void)editGateway:(SHGateway *)gateway withName:(NSString *)name user:(NSString *)user pswd:(NSString *)pswd ip:(NSString *)ip port:(NSString *)port timeout:(int)timeout successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback;

//重新授权
- (void)reauthGateway:(SHGateway *)gateway successCallback:(void (^)(void))successCallback failureCallback:(void (^)(NSString *error))failureCallback;

//删除网关授权用户
- (void)removeAuthUser:(GatewayUser *)user fromGateway:(SHGateway *)gateway successCallback:(void (^)(void))successCallback failureCallback:(void (^)(void))failureCallback;

//查询网关授权用户
- (void)getAuthUsersOfGateway:(SHGateway *)gateway successCallback:(void (^)(NSArray *))successCallback failureCallback:(void (^)(void))failureCallback;

//同步配置
- (void)synchronizeConfig:(SHGateway *)gateway completionCallback:(void (^)(void))completionCallback;

#pragma mark 回调处理
- (void)onEventCallBack:(unsigned int )loginId params:(NSDictionary *)params;

- (void)onAlarmCallBack:(unsigned int )loginId params:(NSDictionary *)params;

- (void)onFileDownloadCallBack:(unsigned int )loginId params:(NSDictionary *)params;

- (void)onCallRedirectCallBack:(unsigned int )loginId params:(NSDictionary *)params;

#pragma mark 信息查询
- (void)queryLeaveMsg:(LeaveMsg *)leaveMsg;

- (void)queryHomeMsg:(HomeMsg *)homeMsg;

- (void)queryAlarmMsg:(AlarmRecord *)alarm;

- (void)queryPropertyMsg:(PropertyMsg *)msgId;

- (void)queryCommunityMsg:(CommunityMsg *)msgId;




#pragma mark 情景模式 & 报警防区


//情景模式控制
- (void)setSceneMode:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;

//布撤防
- (void)setAlarmMode:(SHDevice *)device enable:(bool)enable password:(NSString *)password successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;


#pragma mark 家居控制
/*
 *根据设备类型控制
 */
- (void)setPowerOn:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//开
- (void)setPowerOff:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//关

/*
 *灯光控制
 */
- (void)lightOpen:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//灯光开
- (void)lightClose:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//灯光关
- (void)lightSetBrightness:(SHDevice *)device level:(int)level successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//设置灯光亮度到指定值level
- (void)lightAdjustBrightness:(SHDevice *)device step:(int)step successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//灯光步进调节 (step正负表示加减)


/*
 *窗帘控制
 */
- (void)curtainOpen:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//窗帘开
- (void)curtainClose:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//窗帘关
- (void)curtainStop:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//窗帘停
- (void)curtainSetShading:(SHDevice *)device level:(int)level successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//窗帘设置遮光率


/*
 *空调控制
 */
- (void)airConditionOpen:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//空调开
- (void)airConditionClose:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//空调关
- (void)airConditionSetTemperature:(SHDevice *)device temperature:(int)temperature successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//空调设定温度到指定temperature
- (void)airConditionAdjustTemperature:(SHDevice *)device step:(int)step successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//空调步进调节 (step正负表示加减)
- (void)airConditionSetMode:(SHDevice *)device mode:(NSString *)mode temperature:(int)temperature successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//空调设置工作模式
- (void)airConditionSetWindMode:(SHDevice *)device windMode:(NSString *)windMode successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//空调设置送风模式

//- (void)airConditionGetState:(SHDevice *)deviceId successCallback:(void(^)(NSDictionary *))successCallback failureCallback:(void(^)(void))failureCallback;//空调获取状态

/*
 *地暖
 */
- (void)groundHeatOpen:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//地暖开
- (void)groundHeatClose:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//地暖关
- (void)groundHeatSetTemperature:(SHDevice *)device temperature:(int)temperature successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//地暖设定温度到指定temperature
- (void)groundHeatAdjustTemperature:(SHDevice *)device step:(int)step successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//地暖步进调节 (step正负表示加减)

/*
 *插座
 */
- (void)socketOpen:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//插座开
- (void)socketClose:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//插座关

/*
 *背景音乐
 */
- (void)bgdMusicOpen:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//背景音乐开
- (void)bgdMusicClose:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//背景音乐关
- (void)bgdMusicSetMute:(SHDevice *)device mute:(BOOL)mute successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//背景音乐设置静音
- (void)bgdMusicSetVolume:(SHDevice *)device volume:(NSInteger)volume successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//背景音乐设置静音
- (void)bgdMusicPause:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//背景音乐暂停播放
- (void)bgdMusicResume:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//背景音乐恢复播放
- (void)bgdMusicPlayLast:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//背景音乐播放上一曲
- (void)bgdMusicPlayNext:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;//背景音乐播放下一曲

/*
 *红外遥控
 */
- (void)remoteControl:(SHInfraredRemoteControl *)device key:(NSString *)key successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;

/*
 *云台控制
 */
- (void)PTZControlMove:(SHDevice *)device direction:(int)direction successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;

- (void)PTZControlScale:(SHDevice *)device factor:(CGFloat)factor successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;


#pragma mark 抄表 & 环境监测

- (void)readEnvironmentMonitor:(SHDevice *)device successCallback:(void(^)(NSDictionary *))successCallback failureCallback:(void(^)(void))failureCallback;


- (void)readAmmeterMeter:(SHDevice *)device successCallback:(void(^)(NSDictionary *))successCallback failureCallback:(void(^)(void))failureCallback;

#pragma mark 视频遮盖


- (void)getVideoCover:(SHVideoDevice *)videoDevice successCallback:(void(^)(bool enable))successCallback failureCallback:(void(^)(void))failureCallback;


- (void)setVideoCover:(SHVideoDevice *)videoDevice enable:(bool)enable successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;

#pragma mark IP 搜索

- (bool)startSearch;

- (bool)searchDevice;

- (bool)stopSearch;

@end
