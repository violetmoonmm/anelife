//
//  DBManager.h
//  eLife
//
//  Created by mac on 14-4-8.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceData.h"
#import "Message.h"
#import "User.h"

@interface DBManager : NSObject

+ (DBManager *)defaultManager;

- (BOOL)open;

- (void)close;

- (void)createTables;



#pragma mark 信息
- (BOOL)insertAlarmRecord:(AlarmRecord *)record;

- (BOOL)insertHomeMsg:(HomeMsg *)msg;

- (BOOL)insertCommunityMsg:(CommunityMsg *)msg;

- (BOOL)insertCallRedirect:(CallRedirect *)callRecord;

- (BOOL)insertPropertyMsg:(PropertyMsg *)msg;

- (int)insertLeaveMsg:(LeaveMsg *)msg;

- (BOOL)insertContact:(SHGateway *)gateway;

- (BOOL)insertContacts:(NSArray *)gateways;

- (NSMutableArray *)queryContact;

- (NSMutableArray *)queryAlarmRecord:(NSUInteger)number;

- (NSMutableArray *)queryHomeMsg:(NSUInteger)number;

- (NSMutableArray *)queryCommunityMsg:(NSUInteger)number;

- (NSMutableArray *)queryPropertyMsg:(NSUInteger)number;

- (NSMutableArray *)queryLeaveMsg:(NSUInteger)number;

- (NSMutableArray *)queryCallRedirect:(NSUInteger)number;


- (BOOL)setHomeMsgRead;
- (BOOL)setAlarmMsgRead;
- (BOOL)setPropertyMsgRead;
- (BOOL)setCommunityMsgRead;
- (BOOL)setLeaveMsgRead;

- (BOOL)setHomeMsgRead:(HomeMsg *)msg;
- (BOOL)setAlarmMsgRead:(AlarmRecord *)msg;
- (BOOL)setPropertyMsgRead:(PropertyMsg *)msg;
- (BOOL)setCommunityMsgRead:(CommunityMsg *)msg;
- (BOOL)setLeaveMsg:(LeaveMsg *)msg status:(MessgaeStatus)status;

- (BOOL)setLeaveMsgsRead:(NSString *)fromId;
- (BOOL)updateLeaveMsg:(LeaveMsg *)msg;

#pragma mark 其他
- (BOOL)insertEnergyData:(NSString *)cur prior:(NSString *)pri;
- (NSDictionary *)queryEnergy;

- (void)savePanelConfig:(NSDictionary *)config;
- (NSDictionary *)queryPanelConfig;

#pragma mark 智能家居

/*
 *插入的时候，gatewaySN都填网关的序列号
 */
- (void)insertGateways:(NSArray *)gateways;//插入网关列表

- (void)addGateway:(SHGateway *)gateway;

- (void)insertRooms:(NSArray *)rooms gatewaySN:(NSString *)gatewaySN;//插入房间列表

- (void)insertDevices:(NSArray *)devices gatewaySN:(NSString *)gatewaySN;//插入设备列表

- (void)insertIpcs:(NSArray *)ipcs gatewaySN:(NSString *)gatewaySN;//插入ipc列表

- (void)insertAlarmZones:(NSArray *)alarmZones gatewaySN:(NSString *)gatewaySN;//插入报警防区列表

- (void)insertSceneMode:(NSArray *)sceneModes gatewaySN:(NSString *)gatewaySN;//插入情景模式

- (void)insertAmmeter:(NSArray *)ammeters gatewaySN:(NSString *)gatewaySN;//插入电表

- (void)insertEnvMonitors:(NSArray *)envMonitors gatewaySN:(NSString *)gatewaySN;//插入环境监测器

- (void)insertAuthUsers:(NSArray *)authUsers gatewaySN:(NSString *)gatewaySN;//插入授权用户表

/*
 *查询的时候，gatewaySN都填网关的序列号
 */
- (NSArray *)queryGateways;//查询网关列表

- (NSArray *)queryDevicesByGatewaySN:(NSString *)gatewaySN;//查询智能家居设备列表

- (NSArray *)queryRoomsByGatewaySN:(NSString *)gatewaySN;//查询房间列表

- (NSArray *)queryIpcsByGatewaySN:(NSString *)gatewaySN;//查询ipc

- (NSArray *)queryAlarmZonesByGatewaySN:(NSString *)gatewaySN;//查询报警防区

- (NSArray *)querySceneModesByGatewaySN:(NSString *)gatewaySN;//查询情景模式

- (NSArray *)queryAmmetersByGatewaySN:(NSString *)gatewaySN;//查询电表

- (NSArray *)queryEnvMonitorsByGatewaySN:(NSString *)gatewaySN;//查询电表


- (void)updateGateway:(SHGateway *)gateway;

- (void)removeGateway:(SHGateway *)gateway;

- (NSInteger)numberOfGateways;

@end
