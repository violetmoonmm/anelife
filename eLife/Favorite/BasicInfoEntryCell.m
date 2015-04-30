//
//  BasicInfoEntryCell.m
//  eLife
//
//  Created by mac on 14-9-9.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "BasicInfoEntryCell.h"
#import "NetAPIClient.h"
#import "NotificationDefine.h"
#import "DotView.h"
#import "MessageManager.h"


#define MarginX 2//x轴左右边缘
#define MarginY 2//y轴上下边缘

@implementation BasicInfoEntryCell
{
    UIView *bgdView;
    
    DotView *dotView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code

        
        bgdView = [[UIView alloc] initWithFrame:CGRectMake(MarginX, MarginY, CGRectGetWidth(frame) - MarginX*2, CGRectGetHeight(frame) - MarginY*2)];
       // bgdView.backgroundColor = [UIColor colorWithRed:161/255. green:196/255. blue:0/255. alpha:1];
                bgdView.backgroundColor = [UIColor colorWithRed:94/255. green:221/255. blue:0/255. alpha:1];
        [self addSubview:bgdView];
        
        
        NSInteger iconH = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 70 : 120);
        NSInteger iconW = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 72 : 120);
        NSInteger fontSize = CELL_TEXT_FONT;
        NSInteger nameH = 24;
        NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 4 : 12);
        NSInteger originY = (CGRectGetHeight(frame) - iconH - nameH - spacingY)/2;
        
        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(bgdView.frame)-iconW)/2, originY, iconW, iconH)];
        iconView.image  = [UIImage imageNamed:@"MessageWhite"];
        [bgdView addSubview:iconView];
        
        UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(iconView.frame), CGRectGetMaxY(iconView.frame)+spacingY, CGRectGetWidth(iconView.frame), nameH)];
        nameLbl.textColor = [UIColor whiteColor];
        nameLbl.numberOfLines = 1;
        nameLbl.font = [UIFont systemFontOfSize:fontSize];
        nameLbl.text = @"信息";
        nameLbl.textAlignment = NSTextAlignmentCenter;
        nameLbl.backgroundColor = [UIColor clearColor];
        [bgdView addSubview:nameLbl];
        
        //红点
        dotView = [[DotView alloc] initWithFrame:CGRectMake(CGRectGetWidth(bgdView.frame)-14, 0, 10, 10)];
        [bgdView addSubview:dotView];
        dotView.hidden = ([[MessageManager getInstance] unreadCommMsgNum] > 0) ? YES : NO;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectMessage)];
        [self addGestureRecognizer:tap];
        
        //公共消息已读
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCommMsgReadNtf:) name:CommMsgReadNotification object:nil];
     
//        //报警信息通知
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAlarmMsgNtf:) name:OnAlarmNotification object:nil];
        
        //社区信息通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCommMsgNtf:) name:MQRecvCommunityMsgNotification object:nil];
        
        //消息数据ready
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMsgReadyNtf:) name:MessageReadyNotification object:nil];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//通知处理
- (void)handleCommMsgNtf:(NSNotification *)ntf
{
    dotView.hidden = NO;
}

- (void)handleAlarmMsgNtf:(NSNotification *)ntf
{
    dotView.hidden = NO;
}


- (void)handleCommMsgReadNtf:(NSNotification *)ntf
{
    dotView.hidden = YES;
}


- (void)handleMsgReadyNtf:(NSNotification *)ntf
{
    if ([[MessageManager getInstance] unreadCommMsgNum] > 0) {
        dotView.hidden = NO;
    }
    else {
        dotView.hidden = YES;
    }
}

- (void)selectMessage
{
    if ([self.delegate respondsToSelector:@selector(entryMessage)]) {
        [self.delegate entryMessage];
    }
}

@end
