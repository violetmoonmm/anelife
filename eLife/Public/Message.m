//
//  Message.m
//  eLife
//
//  Created by mac on 14-4-12.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "Message.h"
#import "PublicDefine.h"

@implementation Message


@end

@implementation CallRedirect



@end



@implementation AlarmRecord

- (NSString *)description
{

    NSString *state = nil;
    if ([self.alarmStatus isEqualToString:@"Start"]) {
        state = @"发生";
    }
    else {
        state = @"恢复";
    }

    
    NSString *alarmAddr = self.channelName ? self.channelName : [NSString stringWithFormat:@"通道%@",self.channelId];
    NSString *alarmType = self.alarmType ? self.alarmType : @"";
    NSString *content = [NSString stringWithFormat:@"%@%@%@报警",alarmAddr,state,alarmType];
    
    return content;
}

@end

@implementation HomeMsg



@end

@implementation CommunityMsg



@end
@implementation PropertyMsg



@end

@implementation LeaveMsg

- (NSString *)voiceFilePath
{
    NSString *path = nil;

    NSString *userDir = USERDIR;
    
    NSString *voiceDir = [NSString stringWithFormat:@"%@/%@", userDir, VOICE_DIR_NAME];
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:voiceDir isDirectory:&isDir];
    if ( !(isDir == YES && existed == YES) )
    {
        NSError *erro;
        if (![fileManager createDirectoryAtPath:voiceDir withIntermediateDirectories:YES attributes:nil error:&erro]) {
            
            NSLog(@"%@",[erro description]);
        }
    }
    
    
    NSString *fileName = [NSString stringWithFormat:@"%d.%@",self.localId,VOICE_FILE_SUFFIX];
    path = [voiceDir stringByAppendingPathComponent:fileName];

    return path;
}

@end