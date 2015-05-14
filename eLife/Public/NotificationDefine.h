//
//  NotificationDefine.h
//  eLife
//
//  Created by 陈杰 on 14/12/26.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const IPSearchNotification;
extern NSString *const IPSearchNotificationDataKey;

extern NSString *const LoginSuccessNotification;
extern NSString *const LoginFailedNotification;

extern NSString *const MQRecvCommunityMsgNotification;//社区信息
extern NSString *const MQRecvCommunityMsgNotificationKey;



extern NSString *const OnAlarmNotification;
extern NSString *const OnAlarmNotificationKey;

extern NSString *const IPSearchNotification;
extern NSString *const IPSearchNotificationDataKey;

extern NSString *const GetGatewayListNotification;//获取到网关列表
extern NSString *const GetGatewayListNotificationKey ;//网关


extern NSString *const DeviceListGetReadyNotifacation;//设备列表准备好通知

extern NSString *const BindGatewayNotification;//绑定网关
extern NSString *const BindGatewayNotificationKey;//绑定网关

extern NSString *const DelGatewayNotification;//删除绑定
extern NSString *const DelGatewayNotificationKey;//删除绑定

extern NSString *const EditGatewayNotication;//修改网关信息
extern NSString *const NeedRefreshGatewayKey;//需要刷新网关数据

extern NSString *const RefreshDeviceListStartNotification;//刷新设备列表开始通知
extern NSString *const RefreshDeviceListEndNotification;//刷新设备列表完成通知

extern NSString *const LogoutNotification;//退出登录通知

extern NSString *const SHTerminateNotification;//退出登录时智能家居服务结束通知

extern NSString *const FtpDownloadConfigNotification;//ftp 下载配置通知
extern NSString *const FtpDownloadFilePathKey;//ftp 下载配置通知 文件路径key
extern NSString *const FtpDownloadFileNameKey;//文件名
extern NSString *const FtpDownloadGatewaySNKey;//网关sn

extern NSString *const DeviceStatusChangeNotification;//设备状态变更通知

extern NSString *const GatewayStatusChangeNotification;//网关状态变更通知
extern NSString *const GatewayPreviousStateKey;//网关之前状态key

extern NSString *const QueryDeviceStatusNotification;//查询设备状态完成通知

extern NSString *const MQConnectStatusNotification;//mq连接状态通知

extern NSString *const SetLockPasswordGobackNotification;//设置手势密码返回通知

extern NSString *const GetGatewayConfigStepNotification;//获取网关配置阶段通知
extern NSString *const GetGatewayConfigStepNotificationKey;//获取网关配置阶段通知key

extern NSString *const FileDownloadNotification;//下载文件通知
//extern NSString *const FileDownloadNotificationDataKey;//下载文件通知数据key

extern NSString *const CallRedirectNotification;//呼叫转移

extern NSString *const CallRedirectIPCKey;//呼叫转移ipc

extern NSString *const PlayVideoNotification;//视频播放通知
