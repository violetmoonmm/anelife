//
//  MessageManager.h
//  eLife
//
//  Created by mac on 14-6-11.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

extern NSString *const MessageReadyNotification;//从数据库查询消息完毕
extern NSString *const CommMsgReadNotification;//公共消息已读

@interface MessageManager : NSObject

@property (nonatomic,strong,readonly) NSMutableArray *msgArray;
@property (nonatomic,strong,readonly) NSMutableArray *homeMsgArray;
@property (nonatomic,strong,readonly) NSMutableArray *leaveMsgArray;
@property (nonatomic,strong,readonly) NSMutableArray *alarmMsgArray;
@property (nonatomic,strong,readonly) NSMutableArray *commMsgArray;
@property (nonatomic,strong,readonly) NSMutableArray *propertyMsgArray;

@property (nonatomic,strong,readonly) NSMutableArray *contactList;

+ (MessageManager *)getInstance;//单例

- (void)dealWithUserMessage;//初始化

- (void)cleanup;//清除

- (NSInteger)unreadHomeMsgNum;//未读家庭消息数

- (NSInteger)unreadLeaveMsgNum;//未读留言留影消息数

- (NSInteger)unreadAlarmMsgNum;//未读报警消息数

- (NSInteger)unreadPropertyMsgNum;//未读物业消息数

- (NSInteger)unreadCommMsgNum;//未读社区消息数

- (NSInteger)totalUnreadMsgNum;//总的未读消息数

- (void)setAllHomeMsgRead;//设置所有家庭消息为已读

- (void)setAllLeaveMsgRead:(NSString *)fromId;//设置所有fromId的留言消息为已读

- (void)setAllAlarmMsgRead;//设置所有报警消息为已读

- (void)setAllCommMsgRead;//设置所有社区消息为已读

- (void)setAllPropertyMsgRead;//设置所有物业消息为已读

- (void)addHomeMsg:(HomeMsg *)msg;//收到家庭消息时，内存以及数据库添加一条记录

- (void)addLeaveMsg:(LeaveMsg *)msg;//收到留言消息时，内存以及数据库添加一条记录

- (void)addAlarmMsg:(AlarmRecord *)msg;//收到报警消息时，内存以及数据库添加一条记录

- (void)addPropertyMsg:(PropertyMsg *)msg;//收到物业消息时，内存以及数据库添加一条记录

//for temp use
- (void)addPropertyMsgs:(NSArray *)msgs;
- (void)addCommMsgs:(NSArray *)msgs;

- (void)addCommMsg:(CommunityMsg *)msg;//收到物业消息时，内存以及数据库添加一条记录

- (void)addContact:(NSString *)contactId name:(NSString *)name;//添加联系人

- (void)scheduleLocalNotification:(NSString *)content;//预定本地通知

- (void)setHomeMsgRead:(HomeMsg *)msg;//将消息在内存以及数据库中设为已读

- (void)setLeaveMsg:(LeaveMsg *)msg status:(MessgaeStatus)status;//将消息在内存以及数据库中设为已读

- (void)setAlarmMsgRead:(AlarmRecord *)msg;//将消息在内存以及数据库中设为已读

- (void)setCommMsgRead:(CommunityMsg *)msg;//将消息在内存以及数据库中设为已读

- (void)setPropertyMsgRead:(PropertyMsg *)msg;//将消息在内存以及数据库中设为已读

- (void)sendTextLeaveMsg:(LeaveMsg *)msg successCallback:(void (^)(void))successCallback failureCallback:(void (^)(void))failureCallback;//发送文字留言消息

- (NSInteger)addVoiceLeaveMsg:(LeaveMsg *)msg;

- (void)sendVoiceLeaveMsg:(LeaveMsg *)msg filePath:(NSString *)filePath successCallback:(void (^)(void))successCallback failureCallback:(void (^)(void))failureCallback;//发送语音留言消息

- (void)updateVoiceMsg:(LeaveMsg *)msg;
@end
