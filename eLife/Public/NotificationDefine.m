//
//  NotificationDefine.m
//  eLife
//
//  Created by 陈杰 on 14/12/26.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "NotificationDefine.h"


NSString *const LoginSuccessNotification = @"LoginSuccessNotification";
NSString *const LoginFailedNotification = @"LoginFailedNotification";

NSString *const MQRecvCommunityMsgNotification = @"MQRecvCommunityMsgNotification";//社区信息
NSString *const MQRecvCommunityMsgNotificationKey = @"MQRecvCommunityMsgNotificationKey";//社区信息key

NSString *const OnAlarmNotification = @"OnAlarmNotification";
NSString *const OnAlarmNotificationKey = @"OnAlarmNotificationKey";

NSString *const IPSearchNotification = @"IPSearchNotification";
NSString *const IPSearchNotificationDataKey = @"IPSearchNotificationDataKey";

NSString *const GetGatewayListNotification = @"GetGatewayListNotification";//网关
NSString *const GetGatewayListNotificationKey = @"GetGatewayListNotificationKey";//网关

NSString *const BindGatewayNotification = @"BindGatewayNotification";//绑定网关
NSString *const BindGatewayNotificationKey = @"BindGatewayNotificationKey";//绑定网关

NSString *const DelGatewayNotification = @"DelGatewayNotification";//删除绑定
NSString *const DelGatewayNotificationKey = @"DelGatewayNotificationKey";//删除绑定

NSString *const EditGatewayNotication = @"EditGatewayNotication";//修改网关信息
NSString *const NeedRefreshGatewayKey = @"NeedRefreshGatewayKey";//需要刷新网关数据

NSString *const DeviceListGetReadyNotifacation = @"DeviceListGetReadyNotifacation";//设备列表ready


NSString *const LogoutNotification = @"LogoutNotification";//登出

NSString *const SHTerminateNotification = @"SHTerminateNotification";//退出登录时智能家居服务结束通知

NSString *const FtpDownloadConfigNotification = @"FtpDownloadConfigNotification";
NSString *const FtpDownloadFilePathKey = @"FtpDownloadFilePathKey";
NSString *const FtpDownloadFileNameKey = @"FtpDownloadFileNameKey";

NSString *const DeviceStatusChangeNotification = @"DeviceStatusChangeNotification";//设备状态变更通知

NSString *const GatewayStatusChangeNotification = @"GatewayStatusChangeNotification";//网关状态变更通知
NSString *const GatewayPreviousStateKey = @"GatewayPreviousStateKey";//网关之前状态key

NSString *const QueryDeviceStatusNotification = @"QueryDeviceStatusNotification";//查询到设备状态通知

NSString *const MQConnectStatusNotification = @"MQConnectStatusNotification";//mq连接状态通知

NSString *const SetLockPasswordGobackNotification = @"SetLockPasswordGobackNotification";

NSString *const GetGatewayConfigStepNotification = @"GetGatewayConfigStepNotification";//获取网关配置阶段通知
NSString *const GetGatewayConfigStepNotificationKey = @"GetGatewayConfigStepNotificationKey";//获取网关配置阶段通知key

NSString *const FileDownloadNotification = @"FileDownloadNotification";//下载文件通知
//NSString *const FileDownloadNotificationDataKey = @"FileDownloadNotificationDataKey";//下载文件通知数据key

NSString *const CallRedirectNotification = @"MQRecvCallRedirectNotification";//呼叫转移
NSString *const CallRedirectIPCKey = @"CallRedirectIPCKey";//呼叫转移ipc

NSString *const PlayVideoNotification = @"PlayVideoNotification";//视频播放通知
