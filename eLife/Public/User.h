//
//  User.h
//  ihc
//
//  Created by mac on 13-5-18.
//  Copyright (c) 2013年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum _AlarmVideoSetting
{
    AVSEnableVideo = 0, //报警开启视频
    AVSEnableViaWifi = 1,//仅wifi开启
    AVSDisable = 2 //不开启
} AlarmVideoSetting;

@interface User : NSObject


@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *password;
@property (nonatomic,strong) NSString *devToken;
@property (nonatomic,strong) NSString *virtualCode;
@property (nonatomic,strong) NSString *city;
@property (nonatomic,strong) NSString *ISP;
@property (nonatomic,strong) NSString *authCodeText;//半明文身份识别码

@property (nonatomic,strong) NSString *lockPswd;//手势密码
@property (nonatomic,assign) BOOL enableLockPswd;//是否开启了手势密码
@property (nonatomic,assign) BOOL locked;//app当前是否已经锁屏

@property (nonatomic,assign) BOOL haveLogin;//账号是否已经登录/注销
//@property (nonatomic,assign) BOOL enableAlarmVideo;//2G/3G/4G报警自动打开视频

@property (nonatomic,assign) BOOL disableAlarm;//是否接受报警
@property (nonatomic,assign) AlarmVideoSetting alarmVideo;//报警联动视频设置

+ (User *)currentUser;

@end


@interface VersionInfo : NSObject

@property (nonatomic,strong) NSString *versionName;//版本名
@property (nonatomic,strong) NSString *versionDesc;//描述
@property (nonatomic,strong) NSDate *publishDate;//发布日期
@property (nonatomic,strong) NSString *supportVersion;//支持的最小版本
@property (nonatomic,strong) NSString *updateUrl;//升级url

@end

//网关授权用户
@interface GatewayUser : NSObject

@property (nonatomic,strong) NSString *authID;//授权ID
@property (nonatomic,strong) NSString *meid;//meid
@property (nonatomic,strong) NSString *phoneNumber;//手机号
@property (nonatomic,strong) NSString *deviceModel;//设备型号
@property (nonatomic,assign) BOOL enable;//是否启用
@property (nonatomic,assign) BOOL online;//是否在线
@property (nonatomic,assign) NSInteger loginTime;

@end
