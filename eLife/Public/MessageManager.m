//
//  MessageManager.m
//  eLife
//
//  Created by mac on 14-6-11.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "MessageManager.h"
#import "Message.h"
#import "DBManager.h"
#import "PublicDefine.h"
#import "NetAPIClient.h"
#import "User.h"

#define MAX_MSG_NUM 99


NSString *const MessageReadyNotification = @"MessageReadyNotification";
NSString *const CommMsgReadNotification = @"CommMsgReadNotification";

@interface MessageManager ()


@end

@implementation MessageManager


+ (MessageManager *)getInstance
{
    static MessageManager *obj = nil;
    static dispatch_once_t once;
    dispatch_once(&once,^{
        obj = [[MessageManager alloc] init];
        
    });
    
    return obj;
}

- (id)init
{
    if (self = [super init]) {
        
        _msgArray = [NSMutableArray arrayWithCapacity:1];
        
        _homeMsgArray = [NSMutableArray arrayWithCapacity:1];//家庭
        _leaveMsgArray = [NSMutableArray arrayWithCapacity:1];//留言
        _alarmMsgArray = [NSMutableArray arrayWithCapacity:1];//报警
        _propertyMsgArray = [NSMutableArray arrayWithCapacity:1];//物业
        _commMsgArray = [NSMutableArray arrayWithCapacity:1];//社区
        
        _msgArray = [NSMutableArray arrayWithObjects:_homeMsgArray,_leaveMsgArray,_alarmMsgArray,_propertyMsgArray,_commMsgArray, nil];
        
        _contactList = [NSMutableArray arrayWithCapacity:1];//联系人
    }

    return self;
}

- (void)dealWithUserMessage
{
    NSLog(@"dealWithUserMessage");
    
    [self cleanup];
    
    [_homeMsgArray addObjectsFromArray:[[DBManager defaultManager] queryHomeMsg:1]];
    [_leaveMsgArray addObjectsFromArray:[[DBManager defaultManager] queryLeaveMsg:1]];
    [_alarmMsgArray addObjectsFromArray:[[DBManager defaultManager] queryAlarmRecord:1]];
    [_commMsgArray addObjectsFromArray:[[DBManager defaultManager] queryCommunityMsg:1]];
    [_propertyMsgArray addObjectsFromArray:[[DBManager defaultManager] queryPropertyMsg:1]];
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MessageReadyNotification object:nil];
}

- (void)cleanup
{
    [_homeMsgArray removeAllObjects];
    [_leaveMsgArray removeAllObjects];
    [_alarmMsgArray removeAllObjects];
    [_commMsgArray removeAllObjects];
    [_propertyMsgArray removeAllObjects];
    
    [_contactList removeAllObjects];
}

- (NSInteger)unreadHomeMsgNum
{
    NSInteger num = 0;
    for (HomeMsg *msg in _homeMsgArray)
    {
        if (msg.msgStatus == MessageStatusUnread) {
            num++;
        }
    }
    
    if (num > MAX_MSG_NUM) {
        num = MAX_MSG_NUM;
    }
    return num;
}

- (NSInteger)unreadLeaveMsgNum
{
    NSInteger num = 0;
    for (LeaveMsg *msg in _leaveMsgArray)
    {
        if (msg.msgStatus == MessageStatusUnread) {
            num++;
        }
    }
    
    if (num > MAX_MSG_NUM) {
        num = MAX_MSG_NUM;
    }
    
    return num;
}

- (NSInteger)unreadAlarmMsgNum
{
 
    NSInteger num = 0;
    for (AlarmRecord *msg in _alarmMsgArray)
    {
        if (msg.msgStatus == MessageStatusUnread) {
            num++;
        }
    }
    
    if (num > MAX_MSG_NUM) {
        num = MAX_MSG_NUM;
    }
    
    return num;
}

- (NSInteger)unreadPropertyMsgNum
{
 
    NSInteger num = 0;
    for (PropertyMsg *msg in _propertyMsgArray)
    {
        if (msg.msgStatus == MessageStatusUnread) {
            num++;
        }
    }
    
    if (num > MAX_MSG_NUM) {
        num = MAX_MSG_NUM;
    }
    
    return num;
}

- (NSInteger)unreadCommMsgNum
{
 
    NSInteger num = 0;
    for (CommunityMsg *msg in _commMsgArray)
    {
        if (msg.msgStatus == MessageStatusUnread) {
            num++;
        }
    }
    
    if (num > MAX_MSG_NUM) {
        num = MAX_MSG_NUM;
    }
    
    return num;
}

- (NSInteger)totalUnreadMsgNum
{
    NSInteger total = 0;
    total = [self unreadCommMsgNum] + [self unreadLeaveMsgNum] +[self unreadAlarmMsgNum] + [self unreadPropertyMsgNum] + [self unreadHomeMsgNum];
    
    if (total > MAX_MSG_NUM) {
        total = MAX_MSG_NUM;
    }
    
    return total;
}

- (void)setAllHomeMsgRead
{
    for (HomeMsg *msg in _homeMsgArray)
    {
        msg.msgStatus = MessageStatusRead;
    }
    [[DBManager defaultManager] setHomeMsgRead];
}

- (void)setAllLeaveMsgRead:(NSString *)fromId
{
    //把消息设为已读
    for (LeaveMsg *msg in _leaveMsgArray)
    {
        if (msg.msgStatus == MessageStatusUnread && [msg.fromId isEqualToString:fromId]) {
            if (msg.type == 20) {
                msg.msgStatus = MessageStatusVoiceUnread;
            }
            else {
                msg.msgStatus = MessageStatusRead;
            }
            
        }
    }
    
    [[DBManager defaultManager] setLeaveMsgsRead:fromId];
}

- (void)setAllAlarmMsgRead
{
    for (AlarmRecord *msg in _alarmMsgArray)
    {
        msg.msgStatus = MessageStatusRead;
    }
    [[DBManager defaultManager] setAlarmMsgRead];
}

- (void)setAllCommMsgRead
{
    for (CommunityMsg *msg in _commMsgArray)
    {
        msg.msgStatus = MessageStatusRead;
    }
    [[DBManager defaultManager] setCommunityMsgRead];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CommMsgReadNotification object:nil];
}

- (void)setAllPropertyMsgRead
{
    for (PropertyMsg *msg in _propertyMsgArray)
    {
        msg.msgStatus = MessageStatusRead;
    }
    [[DBManager defaultManager] setPropertyMsgRead];
}

- (void)addHomeMsg:(HomeMsg *)msg
{
    [_homeMsgArray addObject:msg];
    
    [self scheduleLocalNotification:msg.fullContent];
    
    [[DBManager defaultManager] insertHomeMsg:msg];
}

- (void)addLeaveMsg:(LeaveMsg *)leaveMsg
{
    [_leaveMsgArray addObject:leaveMsg];
    
    [self addContact:leaveMsg.fromId name:@""];
    
    /* 本地通知start */
    NSString *name = nil;
    for (SHGateway *gateway in _contactList)
    {
        if ([gateway.virtualCode isEqualToString:leaveMsg.fromId]) {
            name = gateway.name;
            break;
        }
    }
    
    if (!name) {
        name = leaveMsg.fromId;
    }
    
    NSString *info = nil;
    if (leaveMsg.type == 20) {
        info = [NSString stringWithFormat:@"%@发来一段语音",name];
    }
    else {
        info = [NSString stringWithFormat:@"%@:%@",name,leaveMsg.fullContent];
    }
    
    [self scheduleLocalNotification:info];
    /* 本地通知end */
    
    int localId = [[DBManager defaultManager] insertLeaveMsg:leaveMsg];
    leaveMsg.localId = localId;
    

    //下载文件，图片，语音
    [self downloadMsgFile:leaveMsg];


}


- (void)downloadMsgFile:(LeaveMsg *)leaveMsg
{
    //文件下载并保存到本地
    if (leaveMsg.type == 20 || leaveMsg.type == 2) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            NSLog(@"receive leave msg file path %@",leaveMsg.picPath);
            
            NSURL *url = [NSURL URLWithString:leaveMsg.picPath];
            NSData *data = [NSData dataWithContentsOfURL:url];
            
            
            NSArray *folders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDir = [folders objectAtIndex:0];
            
            NSString *suffix = nil;
            NSString *dirName = nil;
            NSString *fileName = [NSString stringWithFormat:@"%d",leaveMsg.localId];
            
            if (leaveMsg.type == 2) {//图片
                dirName = IMAGE_DIR_NAME;
                suffix = IMAGE_FILE_SUFFIX;
            }
            else if (leaveMsg.type == 20) {
                dirName = VOICE_DIR_NAME;
                suffix = VOICE_FILE_SUFFIX;
            }
            
            NSString *fileDir = [documentsDir stringByAppendingPathComponent:dirName];
            
            BOOL isDir = NO;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            BOOL existed = [fileManager fileExistsAtPath:fileDir isDirectory:&isDir];
            if ( !(isDir == YES && existed == YES) )
            {
                NSError *erro;
                if (![fileManager createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:&erro]) {
                    
                    NSLog(@"%@",[erro description]);
                }
            }
            
            NSString *name = [NSString stringWithFormat:@"%@.%@",fileName,suffix];//文件全名
            NSString *path = [fileDir stringByAppendingPathComponent:name];//文件路径
            
            if ([data writeToFile:path atomically:NO]) {
                NSLog(@"writeToFile ok :%@",path);
            }//写到磁盘
            
            leaveMsg.fDownloadStatus = FileDownloadFinished;
        });
        
    }
}

- (void)addAlarmMsg:(AlarmRecord *)msg
{
    NSLog(@"try lock");
    @synchronized(_alarmMsgArray)
    {
        NSLog(@"lock");
        
        for (AlarmRecord *record in _alarmMsgArray)
        {
            if ([record.recordID isEqualToString:msg.recordID]) {//本地远程相同记录
                return;
            }
        }
        
        [_alarmMsgArray addObject:msg];
        
        [[DBManager defaultManager] insertAlarmRecord:msg];
        
        [self scheduleLocalNotification:[msg description]];
        
        NSLog(@"unlock");
    }

}

- (void)addPropertyMsgs:(NSArray *)msgs
{
    [_propertyMsgArray addObjectsFromArray:msgs];
}

- (void)addCommMsgs:(NSArray *)msgs
{
    [_commMsgArray addObjectsFromArray:msgs];
}

- (void)addPropertyMsg:(PropertyMsg *)msg
{
    [_propertyMsgArray addObject:msg];
    
    [self scheduleLocalNotification:msg.fullContent];
    
    [[DBManager defaultManager] insertPropertyMsg:msg];
}

- (void)addCommMsg:(CommunityMsg *)msg
{
    [_commMsgArray addObject:msg];
    
    [self scheduleLocalNotification:msg.fullContent];
    
    [[DBManager defaultManager] insertCommunityMsg:msg];
}

- (void)addContact:(NSString *)contactId name:(NSString *)name
{
    SHGateway *tempGtw = [[SHGateway alloc] init];
    tempGtw.virtualCode = contactId;
    tempGtw.name = name;
    
    
    if (![_contactList containsObject:tempGtw]) {//
        
        NSLog(@"!添加联系人了");
        
        [_contactList addObject:tempGtw];
        
        dispatch_async(dispatch_get_main_queue(),^{
            [[DBManager defaultManager] insertContact:tempGtw];
        });
        
    }
    
}

- (void)scheduleLocalNotification:(NSString *)content
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        NSDate *now = [NSDate date];
        notification.fireDate=now;//秒后通知
        //notification.repeatInterval=0.1;//循环次数，kCFCalendarUnitWeekday一周一次
        notification.timeZone=[NSTimeZone defaultTimeZone];
        //notification.applicationIconBadgeNumber = [self totalUnreadMsgNum]; //应用的红色数字
        notification.soundName = nil;//声音，可以换成alarm.soundName = @"myMusic.caf"
        //去掉下面2行就不会弹出提示框
        notification.alertBody = content;//提示信息 弹出提示框
        notification.alertAction = @"查看";  //提示框按钮
        //notification.hasAction = NO; //是否显示额外的按钮，为no时alertAction消失
        
        // NSDictionary *infoDict = [NSDictionary dictionaryWithObject:@"someValue" forKey:@"someKey"];
        //notification.userInfo = infoDict; //添加额外的信息
        
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

- (void)setHomeMsgRead:(HomeMsg *)msg
{
    msg.msgStatus = MessageStatusRead;
    [[DBManager defaultManager] setHomeMsgRead:msg];
}

- (void)setLeaveMsg:(LeaveMsg *)msg status:(MessgaeStatus)status
{
    msg.msgStatus = status;
    
    [[DBManager defaultManager] setLeaveMsg:msg status:status];
    
}

- (void)setAlarmMsgRead:(AlarmRecord *)msg
{
    msg.msgStatus = MessageStatusRead;
    [[DBManager defaultManager] setAlarmMsgRead:msg];
}

- (void)setCommMsgRead:(CommunityMsg *)msg
{
    msg.msgStatus = MessageStatusRead;
    [[DBManager defaultManager] setCommunityMsgRead:msg];
}

- (void)setPropertyMsgRead:(PropertyMsg *)msg
{
    msg.msgStatus = MessageStatusRead;
    [[DBManager defaultManager] setPropertyMsgRead:msg];
}



@end
