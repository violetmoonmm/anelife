//
//  DBManager.m
//  eLife
//
//  Created by mac on 14-4-8.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "DBManager.h"
#import "FMDatabase.h"
#import "User.h"
#import "PublicDefine.h"



@implementation DBManager
{
    FMDatabase *_db;
}

+ (DBManager *)defaultManager
{
    static DBManager *manager = nil;
    static dispatch_once_t once;
    dispatch_once(&once,^{
        manager = [[DBManager alloc] init];
        
    });
    
    return manager;
}

- (id)init
{
    if (self = [super init]) {

    }
    
    return self;
}

- (BOOL)open
{
    if (_db)
    {
        [_db close];
    }
    
    if ([User currentUser].name) {
        
        NSString *dbDir = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[User currentUser].name];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir;
        BOOL existed = [fileManager fileExistsAtPath:dbDir isDirectory:&isDir];
        if ( !(isDir == YES && existed == YES) )
        {
            NSError *erro;
            if (![fileManager createDirectoryAtPath:dbDir withIntermediateDirectories:YES attributes:nil error:&erro]) {
                
                NSLog(@"createDirectoryAtPath:%@ erro:%@",dbDir,[erro description]);
            }
        }
        
        
        NSString *dbPath = [dbDir stringByAppendingPathComponent:@"Database.db"];
        //创建数据库实例 db  这里说明下:如果路径中不存在"Database.db"的文件,sqlite会自动创建"Database.db"
        _db = [FMDatabase databaseWithPath:dbPath] ;
        
        return [_db open];

    }
    
    return NO;
}

- (void)close
{
    [_db close];
}

- (void)createTables
{
    NSLog(@"db createTables");
    
    //报警记录表
     NSString *const ALARM_RECORD_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS alarmrecord (id integer primary key autoincrement,msgid long , alarmtime integer, alarmstatus text,  alarmtype text, devicename text,areaaddr text, msgstatus integer,recordid text); ";
    [_db executeUpdate:ALARM_RECORD_TABLE_CREATE_SQL];
    
    //家庭信息表
     NSString  *const HOME_MSG_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS homemsg (id integer primary key autoincrement, msgid integer , type integer, time integer, fullContent text, pic text,thumbnail text,msgstatus integer); ";
   BOOL bret = [_db executeUpdate:HOME_MSG_TABLE_CREATE_SQL];
    if (!bret) {
        NSLog(@"can not create table");
    }
    
    //社区信息表
     NSString *const COMMUNITY_INFO_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS communitymsg (id integer primary key autoincrement,msgid integer , type integer, time integer,title text ,fullContent text, pic text,thumbnail text,desc text,msgstatus integer); ";
    [_db executeUpdate:COMMUNITY_INFO_TABLE_CREATE_SQL];
    
    //物业信息表
    NSString *const PROPERTY_MSG_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS propertymsg (id integer primary key autoincrement,msgid integer , type integer, time integer,title text ,fullContent text, pic text,thumbnail text,desc text,msgstatus integer); ";
    [_db executeUpdate:PROPERTY_MSG_TABLE_CREATE_SQL];
    
    //留影留言信息表
    NSString *const LEAVE_MSG_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS leavemsg (id integer primary key autoincrement,msgid integer , type integer, time integer,title text ,fullContent text, pic text,thumbnail text,fromid text,toid text, msgstatus integer); ";
    [_db executeUpdate:LEAVE_MSG_TABLE_CREATE_SQL];
    
    
    //联系人表
    NSString *CONTACT_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS contact (id integer primary key autoincrement,vircode text ,name text); ";
    [_db executeUpdate:CONTACT_TABLE_CREATE_SQL];
    
    //能耗表
    NSString *ENERGY_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS energy (id integer primary key autoincrement,current text ,prior text,time integer); ";
    [_db executeUpdate:ENERGY_TABLE_CREATE_SQL];
    
    
    
    
    //网关表
    NSString *GATEWAY_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS gateway (id integer primary key autoincrement,vircode text ,name text,user text,pswd text,addr text,port integer,comm text,sn text , changeid text,position text,authcode text,ipcpublic bit,city text,isp text,grade integer); ";
    [_db executeUpdate:GATEWAY_TABLE_CREATE_SQL];

    
    //设备列表
    NSString *REMOTE_DEVICE_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS device (id integer primary key autoincrement,sn text ,udn text, name text,roomid text,gatewaysn text, gatewayvc text,type text,cameraid text,ctrlurl text,servicetype text, serviceId text ,eventurl text,range text,icon text); ";
    [_db executeUpdate:REMOTE_DEVICE_TABLE_CREATE_SQL];
    
    

    
    //房间列表
    NSString *REMOTE_ROOM_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS room (id integer primary key autoincrement,roomid text ,name text,floorid text,type integer,gatewaysn text,gatewayvc text); ";
    [_db executeUpdate:REMOTE_ROOM_TABLE_CREATE_SQL];

    
    //摄像头列表
    NSString *REMOTE_IPC_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS ipc (id integer primary key autoincrement,sn text,udn text,name text ,user text,pswd text,ip text, port integer,gatewaysn text, gatewayvc text,pubuser text,pubpswd text,pubip text, pubport integer); ";
   [_db executeUpdate:REMOTE_IPC_TABLE_CREATE_SQL];
    
    
    //报警防区表
    NSString *REMOTE_ALARMZONE_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS alarmzone (id integer primary key autoincrement,sn text ,udn text,name text,roomid text, gatewaysn text,gatewayvc text,type text,cameraid text,ctrlurl text,servicetype text, serviceId text ,eventurl text,sensortype text,sensormethod text); ";
    [_db executeUpdate:REMOTE_ALARMZONE_TABLE_CREATE_SQL];
    
    
    //情景模式表
    NSString *SCENE_MODE_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS scenemode (id integer primary key autoincrement,sn text ,udn text,name text,roomid text, gatewaysn text,gatewayvc text,type text,cameraid text,ctrlurl text,servicetype text, serviceId text ,eventurl text,range text); ";
    [_db executeUpdate:SCENE_MODE_TABLE_CREATE_SQL];
    
    //ammeter表
    NSString *AMMETER_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS ammeter (id integer primary key autoincrement,sn text ,udn text,name text,roomid text, gatewaysn text,gatewayvc text,type text,cameraid text,ctrlurl text,servicetype text, serviceId text ,eventurl text); ";
    [_db executeUpdate:AMMETER_TABLE_CREATE_SQL];
    
    //环境监测器
    NSString *ENVMONITOR_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS envmonitor (id integer primary key autoincrement,sn text ,udn text,name text,roomid text, gatewaysn text,gatewayvc text,type text,cameraid text,ctrlurl text,servicetype text, serviceId text ,eventurl text); ";
    [_db executeUpdate:ENVMONITOR_TABLE_CREATE_SQL];
    
    //面板配置表
    NSString *const PANEL_CONFIG_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS panel (id integer primary key autoincrement,config text); ";
    [_db executeUpdate:PANEL_CONFIG_TABLE_CREATE_SQL];
    
//    //网关授权用户表
//    NSString *AUTHUSER_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS authuser (id integer primary key autoincrement,sn text ,udn text,name text,); ";
//    [_db executeUpdate:ENVMONITOR_TABLE_CREATE_SQL];
}

#pragma mark 信息

- (BOOL)insertAlarmRecord:(AlarmRecord *)msg;
{
   
   BOOL b =  [_db executeUpdate:@"INSERT INTO alarmrecord (msgid, alarmtime, alarmstatus,alarmtype, devicename, areaaddr,msgstatus,recordid) VALUES (?,?,?,?,?,?,?,?)",[NSNumber numberWithLong:msg.msgId] , [NSNumber numberWithInt:msg.alarmTime],msg.alarmStatus,msg.alarmType,msg.channelName,msg.areaAddr,[NSNumber numberWithInt:msg.msgStatus],msg.recordID];
    
    return b;
    
}

- (BOOL)insertHomeMsg:(HomeMsg *)msg
{
    BOOL b =  [_db executeUpdate:@"INSERT INTO homemsg (msgid, type, time, fullContent, pic, thumbnail,msgstatus) VALUES (?,?,?,?,?,?,?)",[NSNumber numberWithLong:msg.msgId],[NSNumber numberWithInt:msg.type],[NSNumber numberWithInt:msg.time],msg.fullContent,msg.pic,msg.thumbnail,[NSNumber numberWithInt:msg.msgStatus]];
    
    return b;
}

- (BOOL)insertCommunityMsg:(CommunityMsg *)msg
{
    
    BOOL b =  [_db executeUpdate:@"INSERT INTO communitymsg (msgid, type, time,title, fullContent, pic, thumbnail,msgstatus) VALUES (?,?,?,?,?,?,?,?)",[NSNumber numberWithLong:msg.msgId],[NSNumber numberWithInt:msg.type],[NSNumber numberWithInt:msg.time],msg.title,msg.fullContent,msg.pic,msg.thumbnail,[NSNumber numberWithInt:msg.msgStatus]];
    
    return b;
}



- (BOOL)insertPropertyMsg:(PropertyMsg *)msg
{
    BOOL b =  [_db executeUpdate:@"INSERT INTO propertymsg (msgid, type, time,title, fullContent, pic, thumbnail,msgstatus) VALUES (?,?,?,?,?,?,?,?)",[NSNumber numberWithLong:msg.msgId],[NSNumber numberWithInt:msg.type],[NSNumber numberWithInt:msg.time],msg.title,msg.fullContent,msg.pic,msg.thumbnail,[NSNumber numberWithInt:msg.msgStatus]];
    
    return b;
}

- (int)insertLeaveMsg:(LeaveMsg *)msg
{
    BOOL b =  [_db executeUpdate:@"INSERT INTO leavemsg (msgid, type, time,title, fullContent, pic, thumbnail,fromid,toid,msgstatus) VALUES (?,?,?,?,?,?,?,?,?,?)",[NSNumber numberWithLong:msg.msgId],[NSNumber numberWithInt:msg.type],[NSNumber numberWithInt:msg.sendTime],msg.title,msg.fullContent,msg.picPath,msg.thumbnailPath,msg.fromId,msg.toId,[NSNumber numberWithInt:msg.msgStatus]];
    
//        BOOL b =  [_db executeUpdate:@"INSERT INTO leavemsg (msgid, type, time,title, fullContent, pic, thumbnail,fromid,toid,msgstatus) VALUES (?,?,?,?,?,?,?,?,?,?)",[NSNumber numberWithLong:1000],[NSNumber numberWithInt:msg.type],[NSNumber numberWithInt:2000],msg.title,msg.fullContent,msg.picPath,msg.thumbnailPath,msg.fromId,msg.toId,[NSNumber numberWithInt:msg.msgStatus]];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM leavemsg where time = ? and msgid = ?",[NSNumber numberWithLong:msg.sendTime],[NSNumber numberWithLong:msg.msgId]];
    
    int localId;
    
    while ([rs next]) {

        localId = [rs intForColumn:@"id"];
    }
    
    [rs close];
    
    return localId;
}

- (BOOL)insertContact:(SHGateway *)gateway
{

    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM contact WHERE vircode = ?",gateway.virtualCode];
    
    int rcdId = 0;
    
    if ([rs next]) {
        rcdId = [rs intForColumn:@"id"];
    }
    
    if (rcdId > 0) {//找到重复的记录
          [_db executeUpdate: @"REPLACE INTO contact(id,vircode,name) VALUES (?,?,?)",[NSNumber numberWithInt:rcdId],gateway.virtualCode,gateway.name];
       
    }
    else {
        [_db executeUpdate: @"INSERT INTO contact(vircode,name) VALUES (?,?)",gateway.virtualCode,gateway.name];
    }
    
  
    
    [rs close];
    
    return YES;
}

- (BOOL)insertContacts:(NSArray *)gateways
{
    [_db beginTransaction];
    
    BOOL b;
    
    for (SHGateway *gateway in gateways)
    {
    
       b = [self insertContact:gateway];
    }
    
    [_db commit];
    
    return b;
}

- (NSMutableArray *)queryContact
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM contact"];
    
    while ([rs next]) {
        
        SHGateway *record = [[SHGateway alloc] init];

        record.virtualCode = [rs stringForColumn:@"vircode"];
        record.name = [rs stringForColumn:@"name"];
        
        [tempArray addObject:record];
        
    }
    
    [rs close];
    
    return tempArray;
    
}

- (NSMutableArray *)queryAlarmRecord:(NSUInteger)number
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM alarmrecord"];

    while ([rs next]) {

        AlarmRecord *record = [[AlarmRecord alloc] init];
        record.msgId = [rs longForColumn:@"msgid"];
        record.msgStatus = [rs intForColumn:@"msgstatus"];
        record.alarmTime = [rs intForColumn:@"alarmtime"];
        record.alarmStatus = [rs stringForColumn:@"alarmstatus"];
        record.alarmType = [rs stringForColumn:@"alarmType"];
        record.channelName = [rs stringForColumn:@"devicename"];
        record.areaAddr = [rs stringForColumn:@"areaaddr"];
        record.recordID = [rs stringForColumn:@"recordid"];

        [tempArray addObject:record];

    }

    [rs close];
    
    return tempArray;

}

- (NSMutableArray *)queryHomeMsg:(NSUInteger)number
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM homemsg"];
    
    while ([rs next]) {
        
        HomeMsg *record = [[HomeMsg alloc] init];
        record.msgId = [rs longForColumn:@"msgid"];
        record.type = [rs intForColumn:@"type"];
        record.time = [rs intForColumn:@"time"];
        record.fullContent = [rs stringForColumn:@"fullContent"];
        record.pic = [rs stringForColumn:@"pic"];
        record.thumbnail = [rs stringForColumn:@"thumbnail"];
        record.msgStatus = [rs intForColumn:@"msgstatus"];
        
        [tempArray addObject:record];
        
    }
    
    [rs close];
    
    return tempArray;
    
}

- (NSMutableArray *)queryCommunityMsg:(NSUInteger)number
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM communitymsg"];
    
    while ([rs next]) {
        
        CommunityMsg *record = [[CommunityMsg alloc] init];
        record.msgId = [rs longForColumn:@"msgid"];
        record.type = [rs intForColumn:@"type"];
        record.time = [rs intForColumn:@"time"];
        record.title = [rs stringForColumn:@"title"];
        record.fullContent = [rs stringForColumn:@"fullContent"];
        record.pic = [rs stringForColumn:@"pic"];
        record.thumbnail = [rs stringForColumn:@"thumbnail"];
        record.msgStatus = [rs intForColumn:@"msgstatus"];
        
        [tempArray addObject:record];
        
    }
    
    [rs close];
    
    return tempArray;
    
}



- (NSMutableArray *)queryPropertyMsg:(NSUInteger)number
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM propertymsg"];
    
    while ([rs next]) {
        
        PropertyMsg *record = [[PropertyMsg alloc] init];
        record.msgId = [rs longForColumn:@"msgid"];
        record.type = [rs intForColumn:@"type"];
        record.time = [rs intForColumn:@"time"];
        record.title = [rs stringForColumn:@"title"];
        record.fullContent = [rs stringForColumn:@"fullContent"];
        record.pic = [rs stringForColumn:@"pic"];
        record.thumbnail = [rs stringForColumn:@"thumbnail"];
        record.msgStatus = [rs intForColumn:@"msgstatus"];
        
        [tempArray addObject:record];
        
    }
    
    [rs close];
    
    return tempArray;
    
}

- (NSMutableArray *)queryLeaveMsg:(NSUInteger)number
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM leavemsg"];
    
    while ([rs next]) {
        
        LeaveMsg *record = [[LeaveMsg alloc] init];
        record.localId = [rs intForColumn:@"id"];
        record.msgId = [rs longForColumn:@"msgid"];
        record.type = [rs intForColumn:@"type"];
        record.sendTime = [rs intForColumn:@"time"];
        record.title = [rs stringForColumn:@"title"];
        record.fullContent = [rs stringForColumn:@"fullContent"];
        record.picPath = [rs stringForColumn:@"pic"];
        record.thumbnailPath = [rs stringForColumn:@"thumbnail"];
        record.fromId = [rs stringForColumn:@"fromid"];
        record.toId = [rs stringForColumn:@"toid"];
        record.msgStatus = [rs intForColumn:@"msgstatus"];
        
        [tempArray addObject:record];
        
    }
    
    [rs close];
    
    return tempArray;
}

- (BOOL)setHomeMsgRead
{
    BOOL b = [_db executeUpdate:@"UPDATE homemsg SET msgstatus = 1"];
    
    return b;
}

- (BOOL)setAlarmMsgRead
{
    BOOL b = [_db executeUpdate:@"UPDATE alarmrecord SET msgstatus = 1"];
    
    return b;
}

- (BOOL)setPropertyMsgRead
{
    BOOL b = [_db executeUpdate:@"UPDATE propertymsg SET msgstatus = 1"];
    
    return b;
}

- (BOOL)setCommunityMsgRead
{
    BOOL b = [_db executeUpdate:@"UPDATE communitymsg SET msgstatus = 1"];
    
    return b;
}

- (BOOL)setLeaveMsgRead
{
    BOOL b = [_db executeUpdate:@"UPDATE leavemsg SET msgstatus = 1"];
    
    return b;
}

- (BOOL)setHomeMsgRead:(HomeMsg *)msg
{
    BOOL b = [_db executeUpdate:@"UPDATE homemsg SET msgstatus = 1 WHERE msgid = ?",[NSNumber numberWithLong:msg.msgId]];
    
    return b;
}
- (BOOL)setAlarmMsgRead:(AlarmRecord *)msg
{
    BOOL b = [_db executeUpdate:@"UPDATE alarmrecord SET msgstatus = 1 WHERE msgid = ?",[NSNumber numberWithLong:msg.msgId]];
    
    return b;
}

- (BOOL)setPropertyMsgRead:(PropertyMsg *)msg
{
    BOOL b = [_db executeUpdate:@"UPDATE propertymsg SET msgstatus = 1 WHERE msgid = ?",[NSNumber numberWithLong:msg.msgId]];
    
    return b;
}

- (BOOL)setCommunityMsgRead:(CommunityMsg *)msg
{
    BOOL b = [_db executeUpdate:@"UPDATE communitymsg SET msgstatus = 1 WHERE msgid = ?",[NSNumber numberWithLong:msg.msgId]];
    
    return b;
}

- (BOOL)setLeaveMsg:(LeaveMsg *)msg status:(MessgaeStatus)status;
{
    BOOL b = [_db executeUpdate:@"UPDATE leavemsg SET msgstatus = ? WHERE msgid = ?",[NSNumber numberWithInteger:status],[NSNumber numberWithLong:msg.msgId]];
    
    return b;
}

- (BOOL)setLeaveMsgsRead:(NSString *)fromId
{

    BOOL b = [_db executeUpdate:@"UPDATE leavemsg SET msgstatus = 1 WHERE fromid = ? And type != ?",fromId,[NSNumber numberWithInt:20]];//其他消息设为MessageStatusRead
    
    b = [_db executeUpdate:@"UPDATE leavemsg SET msgstatus = ? WHERE fromid = ? AND type = ? AND msgstatus = ?",[NSNumber numberWithInt:MessageStatusVoiceUnread],fromId,[NSNumber numberWithInt:20],[NSNumber numberWithInt:MessageStatusUnread]];//语音消息MessageStatusUnread设为MessageStatusVoiceUnread
    
    return b;
}

- (BOOL)updateLeaveMsg:(LeaveMsg *)msg;
{
    BOOL b =  [_db executeUpdate:@"UPDATE leavemsg SET time = ? , title = ? WHERE id = ?",[NSNumber numberWithInt:msg.sendTime],msg.title,[NSNumber numberWithInt:msg.localId]];
    
    return b;
}

- (BOOL)insertEnergyData:(NSString *)cur prior:(NSString *)pri
{
    BOOL b = [_db executeUpdate:@"DELETE FROM energy"];
    
     b =  [_db executeUpdate:@"INSERT INTO energy (current, prior) VALUES (?,?)",cur,pri];
    
    return b;
}

- (NSDictionary *)queryEnergy
{
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM energy"];
    NSString *currentStr = nil;
    NSString *priorStr = nil;
    if ([rs next]) {
        
        currentStr  = [rs stringForColumn:@"current"];
        priorStr = [rs stringForColumn:@"prior"];
    }
    
    [rs close];
    
    NSError *erro;
    NSDictionary *dicCur =  nil;
    if (currentStr) {
        dicCur = [NSJSONSerialization JSONObjectWithData:[currentStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&erro];
    }
    
    if (!dicCur) {
        dicCur = [NSDictionary dictionary];
    }
    
    NSDictionary *dicPri = nil;
    if (priorStr) {
        dicPri = [NSJSONSerialization JSONObjectWithData:[priorStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&erro];
    }
    
    if (!dicPri) {
        dicPri = [NSDictionary dictionary];
    }

    return [NSDictionary dictionaryWithObjectsAndKeys:dicCur,CurrentPeriodKey , dicPri, PriorPeriodKey,nil];
}

#pragma mark 面板配置

- (void)savePanelConfig:(NSDictionary *)config
{
    
    
    if ([NSJSONSerialization isValidJSONObject:config]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:config options:0 error:&error];
        if (jsonData) {
            NSString *strConfig = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            [_db executeUpdate:@"DELETE  FROM panel"];
            
            [_db executeUpdate:@"INSERT INTO panel (config) VALUES (?) ",strConfig];
        }
        
    }
    

}

- (NSDictionary *)queryPanelConfig
{
    NSDictionary *objConfig = nil;
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM panel"];
    
    while ([rs next]) {
        NSString *strConfig  = [rs stringForColumn:@"config"];
        
        NSError *erro;
        if (strConfig) {
            objConfig = [NSJSONSerialization JSONObjectWithData:[strConfig dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&erro];
        }
        

    }
    
   
    [rs close];
    
    return objConfig;
}

#pragma mark 智能家居插入

- (void)insertGateways:(NSArray *)gateways
{
    [_db beginTransaction];
    
    [_db executeUpdate:@"DELETE  FROM gateway"];
    
    for (SHGateway *gateway in gateways) {
        
    [_db executeUpdate:@"INSERT INTO gateway (vircode, name,user,pswd,addr,port,comm,sn,changeid,position,authcode,ipcpublic,city,isp,grade) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",gateway.virtualCode,gateway.name,gateway.user,gateway.pswd,gateway.addr,[NSNumber numberWithInt:gateway.port],gateway.commName,gateway.serialNumber,gateway.changeId,gateway.position,gateway.authCode,gateway.IPCPublic,gateway.city,gateway.ISP,[NSNumber numberWithInt:gateway.grade]];
    }
    
    [_db commit];
}

- (void)addGateway:(SHGateway *)gateway
{
    [_db executeUpdate:@"INSERT INTO gateway (vircode, name,user,pswd,addr,port,comm,sn,changeid,position,authcode,ipcpublic,city,isp,grade) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",gateway.virtualCode,gateway.name,gateway.user,gateway.pswd,gateway.addr,[NSNumber numberWithInt:gateway.port],gateway.commName,gateway.serialNumber,gateway.changeId,gateway.position,gateway.authCode,gateway.IPCPublic,gateway.city,gateway.ISP,[NSNumber numberWithInt:gateway.grade]];

}


- (void)insertRooms:(NSArray *)rooms gatewaySN:(NSString *)gatewaySN
{

    [_db beginTransaction];
    
    BOOL b = [_db executeUpdate:@"DELETE  FROM room WHERE gatewaysn = ?",gatewaySN];
    
    for (SHRoom *tempRoom in rooms) {
        b =  [_db executeUpdate:@"INSERT INTO room (roomid, name,floorid,type,gatewaysn ,gatewayvc) VALUES (?,?,?,?,?,?)",tempRoom.layoutId,tempRoom.layoutName,tempRoom.floorId,[NSNumber numberWithInt:tempRoom.type] ,tempRoom.gatewaySN,tempRoom.gatewayVC];
    }
    
    [_db commit];
}

- (void)insertDevices:(NSArray *)devices gatewaySN:(NSString *)gatewaySN
{
    [_db beginTransaction];
    
    BOOL b = [_db executeUpdate:@"DELETE  FROM device WHERE gatewaysn = ?",gatewaySN];
    
    for (SHDevice *tempDevice in devices) {
        UpnpService *service = nil;
        if ([tempDevice.serviceList count]) {
            service = [tempDevice.serviceList objectAtIndex:0];
        }
        
        NSString *strRange = @"";
        
        if ([NSJSONSerialization isValidJSONObject:tempDevice.range]) {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tempDevice.range options:0 error:&error];
            if (jsonData) {
                strRange = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
            
        }
        
        b =  [_db executeUpdate:@"INSERT INTO device (sn,udn, name,roomid,gatewaysn,gatewayvc,type,cameraid,ctrlurl,servicetype,serviceId,eventurl,range,icon) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",tempDevice.serialNumber,tempDevice.udn,tempDevice.name,tempDevice.roomId,tempDevice.gatewaySN,tempDevice.gatewayVC,tempDevice.type,tempDevice.cameraId,service.controlUrl,service.type,service.serviceId,service.eventUrl,strRange,tempDevice.icon];
    }
    
    [_db commit];
}

- (void)insertIpcs:(NSArray *)ipcs gatewaySN:(NSString *)gatewaySN
{
    
    [_db beginTransaction];
    
    BOOL b = [_db executeUpdate:@"DELETE FROM ipc WHERE gatewaysn = ?",gatewaySN];
    
    for (SHVideoDevice *tempDevice in ipcs) {
        b =  [_db executeUpdate:@"INSERT INTO ipc (sn,udn,name, user,pswd,ip,port,gatewaysn,gatewayvc,pubuser,pubpswd,pubip,pubport) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",tempDevice.serialNumber,tempDevice.udn,tempDevice.name,tempDevice.user,tempDevice.pswd,tempDevice.ip,[NSNumber numberWithInt:tempDevice.port],tempDevice.gatewaySN,tempDevice.gatewayVC,tempDevice.pubUser,tempDevice.pubPswd,tempDevice.pubIp,[NSNumber numberWithInt:tempDevice.pubPort]];
    }
    
    [_db commit];
}

- (void)insertAlarmZones:(NSArray *)alarmZones gatewaySN:(NSString *)gatewaySN
{
    [_db beginTransaction];
    
    BOOL b = [_db executeUpdate:@"DELETE  FROM alarmzone WHERE gatewaysn = ?",gatewaySN];
    
    for (SHAlarmZone *tempDevice in alarmZones) {
        UpnpService *service = nil;
        if ([tempDevice.serviceList count]) {
            service = [tempDevice.serviceList objectAtIndex:0];
        }
        
        
        b =  [_db executeUpdate:@"INSERT INTO alarmzone (sn,udn, name,roomid,gatewaysn,gatewayvc,type,cameraid,ctrlurl,servicetype,serviceId,eventurl,sensortype,sensormethod) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",tempDevice.serialNumber,tempDevice.udn,tempDevice.name,tempDevice.roomId,tempDevice.gatewaySN,tempDevice.gatewayVC,tempDevice.type,tempDevice.cameraId,service.controlUrl,service.type,service.serviceId,service.eventUrl,tempDevice.sensorType,tempDevice.sensorMethod];
    }
    
    [_db commit];
}

- (void)insertSceneMode:(NSArray *)sceneModes gatewaySN:(NSString *)gatewaySN
{
    [_db beginTransaction];
    
    BOOL b = [_db executeUpdate:@"DELETE  FROM scenemode WHERE gatewaysn = ?",gatewaySN];
    
    for (SHDevice *tempDevice in sceneModes) {
        UpnpService *service = nil;
        if ([tempDevice.serviceList count]) {
            service = [tempDevice.serviceList objectAtIndex:0];
        }
        
        NSString *strRange = @"";
        
        if ([NSJSONSerialization isValidJSONObject:tempDevice.range]) {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tempDevice.range options:0 error:&error];
            if (jsonData) {
                strRange = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
            
        }
        
        b =  [_db executeUpdate:@"INSERT INTO scenemode (sn,udn, name,roomid,gatewaysn,gatewayvc,type,cameraid,ctrlurl,servicetype,serviceId,eventurl,range) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",tempDevice.serialNumber,tempDevice.udn,tempDevice.name,tempDevice.roomId,tempDevice.gatewaySN,tempDevice.gatewayVC,tempDevice.type,tempDevice.cameraId,service.controlUrl,service.type,service.serviceId,service.eventUrl,strRange];
    }
    
    [_db commit];

}

- (void)insertAmmeter:(NSArray *)ammeters gatewaySN:(NSString *)gatewaySN
{
    [_db beginTransaction];
    
    BOOL b = [_db executeUpdate:@"DELETE  FROM ammeter WHERE gatewaysn = ?",gatewaySN];
    
    for (SHDevice *tempDevice in ammeters) {
        UpnpService *service = nil;
        if ([tempDevice.serviceList count]) {
            service = [tempDevice.serviceList objectAtIndex:0];
        }
        
        b =  [_db executeUpdate:@"INSERT INTO ammeter (sn,udn, name,roomid,gatewaysn,gatewayvc,type,cameraid,ctrlurl,servicetype,serviceId,eventurl) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",tempDevice.serialNumber,tempDevice.udn,tempDevice.name,tempDevice.roomId,tempDevice.gatewaySN,tempDevice.gatewayVC,tempDevice.type,tempDevice.cameraId,service.controlUrl,service.type,service.serviceId,service.eventUrl];
    }
    
    [_db commit];
}


- (void)insertEnvMonitors:(NSArray *)envMonitors gatewaySN:(NSString *)gatewaySN
{
    [_db beginTransaction];
    
    BOOL b = [_db executeUpdate:@"DELETE  FROM envmonitor WHERE gatewaysn = ?",gatewaySN];
    
    for (SHDevice *tempDevice in envMonitors) {
        UpnpService *service = nil;
        if ([tempDevice.serviceList count]) {
            service = [tempDevice.serviceList objectAtIndex:0];
        }
        
        b =  [_db executeUpdate:@"INSERT INTO envmonitor (sn,udn, name,roomid,gatewaysn,gatewayvc,type,cameraid,ctrlurl,servicetype,serviceId,eventurl) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",tempDevice.serialNumber,tempDevice.udn,tempDevice.name,tempDevice.roomId,tempDevice.gatewaySN,tempDevice.gatewayVC,tempDevice.type,tempDevice.cameraId,service.controlUrl,service.type,service.serviceId,service.eventUrl];
    }
    
    [_db commit];
}


- (void)insertAuthUsers:(NSArray *)authUsers gatewaySN:(NSString *)gatewaySN
{
    
}

- (void)updateGateway:(SHGateway *)gateway
{
    //    [_db beginTransaction];
    
    [_db executeUpdate:@"UPDATE gateway SET vircode = ? , name = ? ,user = ? ,pswd = ?, addr = ?, port = ?, comm = ? ,changeid = ?, authcode = ?,ipcpublic = ? WHERE sn = ?",gateway.virtualCode,gateway.name,gateway.user,gateway.pswd,gateway.addr,[NSNumber numberWithInt:gateway.port],gateway.commName,gateway.changeId,gateway.authCode,[NSNumber numberWithBool:gateway.IPCPublic],gateway.serialNumber];
    
    //    [_db commit];
}

- (void)removeGateway:(SHGateway *)gateway
{
    [_db beginTransaction];
    
    BOOL b = [_db executeUpdate:@"DELETE  FROM gateway WHERE sn = ?",gateway.serialNumber];
    
    //删除网关对应房间
    b = [_db executeUpdate:@"DELETE  FROM room WHERE gatewayvc = ?",gateway.serialNumber];
    
    //删除网关对应设备
    b = [_db executeUpdate:@"DELETE  FROM device WHERE gatewayvc = ?",gateway.serialNumber];
    
    //删除网关对应ipc
    b = [_db executeUpdate:@"DELETE  FROM ipc WHERE gatewayvc = ?",gateway.serialNumber];
    
    //删除网关对应报警防区
    b = [_db executeUpdate:@"DELETE  FROM alarmzone WHERE gatewayvc = ?",gateway.serialNumber];
    
    //删除网关对应情景模式
    b = [_db executeUpdate:@"DELETE  FROM scenemode WHERE gatewayvc = ?",gateway.serialNumber];
    
    //删除电表
    b = [_db executeUpdate:@"DELETE  FROM ammeter WHERE gatewayvc = ?",gateway.serialNumber];
    
    //删除环境检测器
    b = [_db executeUpdate:@"DELETE  FROM envmonitor WHERE gatewayvc = ?",gateway.serialNumber];
    
    [_db commit];
}


#pragma mark 智能家居查询

- (NSArray *)queryGateways
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM gateway"];
    
    while ([rs next]) {
        
        SHGateway *record = [[SHGateway alloc] init];
        
        record.virtualCode = [rs stringForColumn:@"vircode"];
        record.name = [rs stringForColumn:@"name"];
        record.user = [rs stringForColumn:@"user"];
        record.pswd = [rs stringForColumn:@"pswd"];
        record.addr = [rs stringForColumn:@"addr"];
        record.port = [rs intForColumn:@"port"];
        record.commName = [rs stringForColumn:@"comm"];
        record.serialNumber = [rs stringForColumn:@"sn"];
        record.changeId = [rs stringForColumn:@"changeid"];
        record.position = [rs stringForColumn:@"position"];
        record.authCode = [rs stringForColumn:@"authcode"];
        record.IPCPublic = [rs boolForColumn:@"ipcpublic"];
        record.city = [rs stringForColumn:@"city"];
        record.ISP = [rs stringForColumn:@"isp"];
        record.grade = [rs intForColumn:@"grade"];
        
        [tempArray addObject:record];
        
    }
    
    [rs close];
    
    return tempArray;
}





- (NSArray *)queryRoomsByGatewaySN:(NSString *)gatewaySN
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM room WHERE gatewaysn = ?",gatewaySN];
    
    while ([rs next]) {
        
        SHRoom *record = [[SHRoom alloc] init];
        
        record.layoutId = [rs stringForColumn:@"roomid"];
        record.layoutName = [rs stringForColumn:@"name"];
        record.floorId = [rs stringForColumn:@"floorid"];
        record.type = [rs intForColumn:@"type"];
        record.gatewayVC = [rs stringForColumn:@"gatewayvc"];
        record.gatewaySN = [rs stringForColumn:@"gatewaysn"];

        [tempArray addObject:record];
        
    }
    
    [rs close];
    
    return tempArray;
}

- (NSArray *)queryDevicesByGatewaySN:(NSString *)gatewaySN
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM device WHERE gatewaysn = ?",gatewaySN];
    
    while ([rs next]) {
        
        SHDevice *record = [[SHDevice alloc] init];
        
        record.serialNumber = [rs stringForColumn:@"sn"];
        record.udn = [rs stringForColumn:@"udn"];
        record.name = [rs stringForColumn:@"name"];
        record.roomId = [rs stringForColumn:@"roomid"];
        record.gatewaySN = [rs stringForColumn:@"gatewaysn"];
        record.gatewayVC = [rs stringForColumn:@"gatewayvc"];
        record.type = [rs stringForColumn:@"type"];
        record.cameraId = [rs stringForColumn:@"cameraid"];
        record.icon = [rs stringForColumn:@"icon"];
        NSString *strRange  = [rs stringForColumn:@"range"];
        
        record.range = strRange;
        
        NSError *erro;
        id objRange = [NSJSONSerialization JSONObjectWithData:[strRange dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&erro];
        
        if (objRange) {
             record.range = objRange;
        }
       
        
        UpnpService *service = [[UpnpService alloc] init];
        service.controlUrl = [rs stringForColumn:@"ctrlurl"];
        service.serviceId = [rs stringForColumn:@"serviceId"];
        service.type = [rs stringForColumn:@"servicetype"];
        service.eventUrl = [rs stringForColumn:@"eventurl"];
        
        record.serviceList = [NSMutableArray arrayWithObject:service];
        
        [tempArray addObject:record];
        
    }
    
    [rs close];
    
    return tempArray;
}

- (NSArray *)queryIpcsByGatewaySN:(NSString *)gatewaySN
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM ipc WHERE gatewaysn = ?",gatewaySN];
    
    while ([rs next]) {
        
        SHVideoDevice *record = [[SHVideoDevice alloc] init];
        
        record.serialNumber = [rs stringForColumn:@"sn"];
        record.udn = [rs stringForColumn:@"udn"];
        record.name = [rs stringForColumn:@"name"];
        record.user = [rs stringForColumn:@"user"];
        record.pswd = [rs stringForColumn:@"pswd"];
        record.ip = [rs stringForColumn:@"ip"];
        record.port = [rs intForColumn:@"port"];
        record.gatewaySN = [rs stringForColumn:@"gatewaysn"];
        record.gatewayVC = [rs stringForColumn:@"gatewayvc"];
        record.pubUser = [rs stringForColumn:@"pubuser"];
        record.pubPswd = [rs stringForColumn:@"pubpswd"];
        record.pubIp = [rs stringForColumn:@"pubip"];
        record.pubPort = [rs intForColumn:@"pubport"];
        
        [tempArray addObject:record];
    }
    
    return tempArray;
}

- (NSArray *)queryAlarmZonesByGatewaySN:(NSString *)gatewaySN
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM alarmzone WHERE gatewaysn = ?",gatewaySN];
    
    while ([rs next]) {
        
        SHAlarmZone *record = [[SHAlarmZone alloc] init];
        
        record.serialNumber = [rs stringForColumn:@"sn"];
        record.udn = [rs stringForColumn:@"udn"];
        record.name = [rs stringForColumn:@"name"];
        record.roomId = [rs stringForColumn:@"roomid"];
        record.gatewaySN = [rs stringForColumn:@"gatewaysn"];
        record.gatewayVC = [rs stringForColumn:@"gatewayvc"];
        record.type = [rs stringForColumn:@"type"];
        record.cameraId = [rs stringForColumn:@"cameraid"];
        record.sensorType = [rs stringForColumn:@"sensortype"];
        record.sensorMethod = [rs stringForColumn:@"sensormethod"];
        
        
        
        UpnpService *service = [[UpnpService alloc] init];
        service.controlUrl = [rs stringForColumn:@"ctrlurl"];
        service.serviceId = [rs stringForColumn:@"serviceId"];
        service.type = [rs stringForColumn:@"servicetype"];
        service.eventUrl = [rs stringForColumn:@"eventurl"];
        
        record.serviceList = [NSMutableArray arrayWithObject:service];
        
        [tempArray addObject:record];
        
    }
    
    [rs close];
    
    return tempArray;
}


- (NSArray *)querySceneModesByGatewaySN:(NSString *)gatewaySN
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM scenemode WHERE gatewaysn = ?",gatewaySN];
    
    while ([rs next]) {
        
        SHSceneMode *record = [[SHSceneMode alloc] init];
        
        record.serialNumber = [rs stringForColumn:@"sn"];
        record.udn = [rs stringForColumn:@"udn"];
        record.name = [rs stringForColumn:@"name"];
        record.roomId = [rs stringForColumn:@"roomid"];
        record.gatewaySN = [rs stringForColumn:@"gatewaysn"];
        record.gatewayVC = [rs stringForColumn:@"gatewayvc"];
        record.type = [rs stringForColumn:@"type"];
        record.cameraId = [rs stringForColumn:@"cameraid"];
        
        NSString *strRange  = [rs stringForColumn:@"range"];
        
        record.range = strRange;
        
        NSError *erro;
        id objRange = [NSJSONSerialization JSONObjectWithData:[strRange dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&erro];
        
        if (objRange) {
            record.range = objRange;
        }
        
        
        UpnpService *service = [[UpnpService alloc] init];
        service.controlUrl = [rs stringForColumn:@"ctrlurl"];
        service.serviceId = [rs stringForColumn:@"serviceId"];
        service.type = [rs stringForColumn:@"servicetype"];
        service.eventUrl = [rs stringForColumn:@"eventurl"];
        
        record.serviceList = [NSMutableArray arrayWithObject:service];
        
        [tempArray addObject:record];
        
    }
    
    [rs close];
    
    return tempArray;
}

- (NSArray *)queryAmmetersByGatewaySN:(NSString *)gatewaySN
{
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM ammeter WHERE gatewaysn = ?",gatewaySN];
    
    while ([rs next]) {
        
        SHDevice *record = [[SHDevice alloc] init];
        
        record.serialNumber = [rs stringForColumn:@"sn"];
        record.udn = [rs stringForColumn:@"udn"];
        record.name = [rs stringForColumn:@"name"];
        record.roomId = [rs stringForColumn:@"roomid"];
        record.gatewaySN = [rs stringForColumn:@"gatewaysn"];
        record.gatewayVC = [rs stringForColumn:@"gatewayvc"];
        record.type = [rs stringForColumn:@"type"];
        record.cameraId = [rs stringForColumn:@"cameraid"];
        
        UpnpService *service = [[UpnpService alloc] init];
        service.controlUrl = [rs stringForColumn:@"ctrlurl"];
        service.serviceId = [rs stringForColumn:@"serviceId"];
        service.type = [rs stringForColumn:@"servicetype"];
        service.eventUrl = [rs stringForColumn:@"eventurl"];
        
        record.serviceList = [NSMutableArray arrayWithObject:service];
        
        [tempArray addObject:record];
        
    }
    
    [rs close];
    
    return tempArray;
}

- (NSArray *)queryEnvMonitorsByGatewaySN:(NSString *)gatewaySN
{
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM envmonitor WHERE gatewaysn = ?",gatewaySN];
    
    while ([rs next]) {
        
        SHDevice *record = [[SHDevice alloc] init];
        
        record.serialNumber = [rs stringForColumn:@"sn"];
        record.udn = [rs stringForColumn:@"udn"];
        record.name = [rs stringForColumn:@"name"];
        record.roomId = [rs stringForColumn:@"roomid"];
        record.gatewaySN = [rs stringForColumn:@"gatewaysn"];
        record.gatewayVC = [rs stringForColumn:@"gatewayvc"];
        record.type = [rs stringForColumn:@"type"];
        record.cameraId = [rs stringForColumn:@"cameraid"];
        
        UpnpService *service = [[UpnpService alloc] init];
        service.controlUrl = [rs stringForColumn:@"ctrlurl"];
        service.serviceId = [rs stringForColumn:@"serviceId"];
        service.type = [rs stringForColumn:@"servicetype"];
        service.eventUrl = [rs stringForColumn:@"eventurl"];
        
        record.serviceList = [NSMutableArray arrayWithObject:service];
        
        [tempArray addObject:record];
        
    }
    
    [rs close];
    
    return tempArray;
}




- (NSInteger)numberOfGateways
{
    FMResultSet *rs = [_db executeQuery:@"SELECT count(*) as 'count' FROM gateway"];
    while ([rs next])
    {
        
        NSInteger count = [rs intForColumn:@"count"];
        
        return count;
    }
    
    return 0;
    
    //     NSUInteger count = [_db intForQuery:@"select count(*) from gateway"];
    //
    //    return count;
}

@end
