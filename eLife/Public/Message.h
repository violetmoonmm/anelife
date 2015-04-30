//
//  Message.h
//  eLife
//
//  Created by mac on 14-4-12.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

//消息状态
typedef enum _MessgaeStatus{
    MessageStatusUnread = 0,//消息未读
    MessageStatusRead = 1,//消息已读
    MessageStatusVoiceUnread = 2,//语音消息未播放
    MessageStatusSending = 3,//消息正在发送
    MessageStatusSent = 4,//消息已经发送
    MessageStatusSendFailed //消息发送失败
    
} MessgaeStatus;

typedef enum _FileDownloadStatus {
    FileDownloadInit = 0,//未开始下载
    FileDownloadDoing = 1,//正在下载
    FileDownloadFinished//下载完成
} FileDownloadStatus;

@interface Message : NSObject

@property (nonatomic) int localId;//对应本地数据库的id
@property (nonatomic) long msgId;//对应服务器的记录id
@property (nonatomic) MessgaeStatus msgStatus;//记录状态

@end

@interface AlarmRecord : Message


@property (nonatomic) NSInteger alarmTime;//报警时间
@property (nonatomic,strong) NSString *alarmStatus;//报警状态 （Start:报警发生,Stop:恢复）
@property (nonatomic,strong) NSString *alarmType;//报警类型
@property (nonatomic,strong) NSString *channelName;//报警通道名
@property (nonatomic,strong) NSString *channelId;//报警通道id
@property (nonatomic,strong) NSString *eventInfo;//报警信息
@property (nonatomic,strong) NSString *videoAddr;//视频地址
@property (nonatomic,strong) NSString *pubVideoAddr;//公网视频地址
@property (nonatomic,strong) NSString *areaAddr;//设备地址
@property (nonatomic,strong) NSString *recordID;//报警记录id

@property (nonatomic,readonly,strong) NSString *fullContent;

- (NSString *)description;

@end

//MQ发送的呼叫转移信息
@interface CallRedirect: NSObject

@property (nonatomic,strong) NSString *vtoId;////门口机编号
@property (nonatomic,strong) NSString *midVthId;//室内机编号(中号)
@property (nonatomic,strong) NSString *virVthId;//虚拟VTH编号
@property (nonatomic,strong) NSString *inviteTime;//时间
@property (nonatomic,strong) NSString *picUrl;//VTHProxy接到呼叫抓拍一张图片位置
@property (nonatomic) int stage;////呼叫所处阶段1 VTO呼叫发起VTH；VTH接听；VTH开锁；VTO或VTH挂断；

@end

@interface HomeMsg : Message


@property (nonatomic) NSInteger type;
@property (nonatomic) NSInteger time;
//@property (nonatomic,strong) NSString *content;
@property (nonatomic,strong) NSString *pic;
@property (nonatomic,strong) NSString *thumbnail;
@property (nonatomic,strong) NSString *fullContent;
@end


@interface CommunityMsg : Message


@property (nonatomic) NSInteger type;
@property (nonatomic) NSInteger time;
@property (nonatomic,strong) NSString *title;
//@property (nonatomic,strong) NSString *content;
@property (nonatomic,strong) NSString *pic;
@property (nonatomic,strong) NSString *thumbnail;
@property (nonatomic,strong) NSString *fullContent;

@end

@interface PropertyMsg : Message


@property (nonatomic) NSInteger type;
@property (nonatomic) NSInteger time;
@property (nonatomic,strong) NSString *title;
//@property (nonatomic,strong) NSString *content;
@property (nonatomic,strong) NSString *pic;
@property (nonatomic,strong) NSString *thumbnail;
@property (nonatomic,strong) NSString *fullContent;

@end

@interface LeaveMsg : Message

@property (nonatomic) NSInteger type;//类型 1文字短信 2图片短信 20留言
@property (nonatomic) NSInteger sendTime;//发送时间
@property (nonatomic,strong) NSString *fromId;//发送者虚号
@property (nonatomic,strong) NSString *toId;//接收者者虚号
@property (nonatomic,strong) NSString *title;//标题 只需要填语音时长(秒)
@property (nonatomic,strong) NSString *fullContent;//内容
@property (nonatomic,strong) NSString *picPath;//图片地址
@property (nonatomic,strong) NSString *thumbnailPath;//图片缩略图地址

@property (nonatomic,strong) UIImage *picImage;
@property (nonatomic,strong) UIImage *thumbnailImage;

@property (nonatomic,strong) NSString *voiceDuration;//语音时长

@property (nonatomic) FileDownloadStatus fDownloadStatus;//文件下载状态

- (NSString *)voiceFilePath;

@end