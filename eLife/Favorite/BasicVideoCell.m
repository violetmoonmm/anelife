//
//  BasicVideoCell.m
//  eLife
//
//  Created by mac on 14-8-25.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "BasicVideoCell.h"
#import "VideoWnd.h"
#import "zw_dssdk.h"
#import "NetAPIClient.h"
#import "NotificationDefine.h"
#import "Util.h"
#import "MBProgressHUD.h"
#import "BitrateView.h"


#define MarginX 4//x轴左右边缘
#define MarginY 4//y轴上下边缘

#define VideoWndMargin 4//视频边缘

#define HIDE_TIME 5 //5秒后隐藏

#define SIDE_BAR_WIDTH 50

#define ARROW_MARGIN 4//箭头离视频边缘距离
#define ARROW_SIZE 37//箭头尺寸

#define PTZBtnW 32
#define PTZBtnH 32

#define ARROW_DISPLAY_TIME 1.0

@interface BasicVideoCell () <BitrateViewDelegate,VideoWndDelegate>
{
    UIImageView *bgdView;
    
    VideoWnd *videoWnd;
    
    UIButton *playBtn;
    UIButton *closeBtn;
    UIButton *landscapeBtn;//横屏按钮
    UIButton *bitrateBtn;
    
    UIView *sideBar;
    
    BOOL landscape;

    CGRect originFrame;//videoWnd的原始frame
    
    BitrateView *bitrateView;
    
    UIButton *ptzBtn;//云台控制按钮
    
    UIImageView *videoMaxView;//视频转发达到最大数
    
    UIImageView *arrowView;
}

@end

@implementation BasicVideoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        //背景
        bgdView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"VideoBgd"]];
        bgdView.frame = CGRectMake(MarginX, MarginY, CGRectGetWidth(frame) - MarginX*2, CGRectGetHeight(frame) - MarginY*2);
        [self addSubview:bgdView];
        bgdView.userInteractionEnabled = YES;

   
        videoWnd = [[VideoWnd alloc] initWithFrame:CGRectMake(VideoWndMargin, VideoWndMargin, CGRectGetWidth(bgdView.frame)-2*VideoWndMargin, CGRectGetHeight(bgdView.frame)-2*VideoWndMargin)];
        videoWnd.backgroundColor = [UIColor blackColor];
        videoWnd.delegate = self;
        [bgdView addSubview:videoWnd];
        videoWnd.autoresizesSubviews = YES;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBgdView)];
        [videoWnd addGestureRecognizer:tap];
        
        originFrame = videoWnd.frame;
        
        //设置锚点
        [self setAnchorPoint:CGPointMake(0, 1) forView:videoWnd];
        
        NSInteger btnWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 80);
        NSInteger btnHeight = btnWidth;
        
        playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        playBtn.frame = CGRectMake((CGRectGetWidth(videoWnd.frame)-btnWidth)/2, (CGRectGetHeight(videoWnd.frame)-btnHeight)/2 , btnWidth, btnHeight);
        [playBtn setImage:[UIImage imageNamed:@"VideoPlayNormal"] forState:UIControlStateNormal];
        [playBtn setImage:[UIImage imageNamed:@"VideoPlayHl"] forState:UIControlStateHighlighted];
        [playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
        [videoWnd addSubview:playBtn];
        //playBtn.backgroundColor = [UIColor redColor];
    
        playBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        

        sideBar = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(videoWnd.frame)-SIDE_BAR_WIDTH, 0, SIDE_BAR_WIDTH, CGRectGetHeight(videoWnd.frame))];
        sideBar.backgroundColor = [UIColor clearColor];
        sideBar.userInteractionEnabled = YES;
        [videoWnd addSubview:sideBar];
       sideBar.hidden = YES;

        sideBar.autoresizingMask = UIViewAutoresizingFlexibleHeight |  UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        sideBar.autoresizesSubviews = YES;
        
        
        CGFloat btnMargin = 4;
        
        //视频质量选择按钮
       bitrateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat bitrateBtnW = 60;
        CGFloat bitrateBtnH = 32;
        bitrateBtn.frame = CGRectMake(CGRectGetMinX(sideBar.frame)-bitrateBtnW-14, btnMargin, bitrateBtnW, bitrateBtnH);
//        [bitrateBtn setBackgroundImage:[UIImage imageNamed:@"VideoCloseNormal"] forState:UIControlStateNormal];
//        [bitrateBtn setBackgroundImage:[UIImage imageNamed:@"VideoCloseHl"] forState:UIControlStateHighlighted];
        [bitrateBtn setTitle:@"清晰" forState:UIControlStateNormal];
        [bitrateBtn addTarget:self action:@selector(changeBitRate:) forControlEvents:UIControlEventTouchUpInside];
        [videoWnd addSubview:bitrateBtn];
        bitrateBtn.hidden = YES;

        [self setBitrateBtnState:UIControlStateNormal];
        bitrateBtn.layer.cornerRadius = 5;
        bitrateBtn.layer.borderWidth = 1;
        bitrateBtn.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;

        
        bitrateView = [[BitrateView alloc] initWithText:@[@"清晰",@"流畅"]];
        CGRect tempFrame = bitrateView.frame;
        tempFrame.origin.x = CGRectGetMinX(bitrateBtn.frame) - (CGRectGetWidth(bitrateView.frame)- CGRectGetWidth(bitrateBtn.frame))/2;
        tempFrame.origin.y = CGRectGetMaxY(bitrateBtn.frame)+10;
        bitrateView.frame = tempFrame;
        bitrateView.delegate = self;
        [videoWnd addSubview:bitrateView];
        bitrateView.hidden = YES;
        bitrateView.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin  | UIViewAutoresizingFlexibleBottomMargin;
        bitrateView.selectedIndex = 0;
        
        //云台控制按钮
        ptzBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        ptzBtn.frame = CGRectMake(CGRectGetMaxX(bitrateBtn.frame)-PTZBtnW, CGRectGetHeight(videoWnd.frame) - btnMargin - PTZBtnH, PTZBtnW, PTZBtnH);
        [ptzBtn setImage:[UIImage imageNamed:@"VideoMoveGray"] forState:UIControlStateNormal];
        [ptzBtn setImage:[UIImage imageNamed:@"VideoMoveGreen"] forState:UIControlStateSelected];
        [ptzBtn addTarget:self action:@selector(setPTZCtrlEnable:) forControlEvents:UIControlEventTouchUpInside];
        [videoWnd addSubview:ptzBtn];
        ptzBtn.hidden = YES;
        
        //关闭视频按钮
        closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        closeBtn.frame = CGRectMake(0, btnMargin, SIDE_BAR_WIDTH, SIDE_BAR_WIDTH);
        [closeBtn setImage:[UIImage imageNamed:@"VideoCloseNormal"] forState:UIControlStateNormal];
        [closeBtn setImage:[UIImage imageNamed:@"VideoCloseHl"] forState:UIControlStateHighlighted];
        [closeBtn setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
        [closeBtn addTarget:self action:@selector(stopPlaying) forControlEvents:UIControlEventTouchUpInside];
        [sideBar addSubview:closeBtn];

        //closeBtn.backgroundColor = [UIColor redColor];
        closeBtn.autoresizingMask = UIViewAutoresizingNone;
        
        
        //全屏按钮
        landscapeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        landscapeBtn.frame = CGRectMake(0, CGRectGetHeight(sideBar.frame)-SIDE_BAR_WIDTH-btnMargin, SIDE_BAR_WIDTH, SIDE_BAR_WIDTH);
        [landscapeBtn setImage:[UIImage imageNamed:@"FullScreenNormal"] forState:UIControlStateNormal];
        [landscapeBtn setImage:[UIImage imageNamed:@"FullScreenHl"] forState:UIControlStateHighlighted];
        [landscapeBtn setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
        [landscapeBtn addTarget:self action:@selector(playFullScreenVideo) forControlEvents:UIControlEventTouchUpInside];
        [sideBar addSubview:landscapeBtn];
        landscapeBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        //landscapeBtn.backgroundColor = [UIColor redColor];
        
        arrowView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(videoWnd.bounds)-ARROW_SIZE)/2, 0, ARROW_SIZE, ARROW_SIZE)];
        arrowView.image = [UIImage imageNamed:@"Arrow"];
        [videoWnd addSubview:arrowView];
        arrowView.alpha = 0;
        
        [self registerNotification];
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
    
#ifndef INVALID_VIDEO
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
#endif
}

//注册通知
- (void)registerNotification
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogout:) name:LogoutNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayVideoNtf:) name:PlayVideoNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}


- (void)handlePlayVideoNtf:(NSNotification *)ntf
{
    if (ntf.object != self) {
        [self stopPlaying];
    }
}

- (void)appDidEnterBackground:(NSNotification*)ntf
{
    
    [self stopPlaying];
}

//登出 停止视频播放
- (void)handleLogout:(NSNotification *)ntf
{
#ifndef INVALID_VIDEO
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
#endif
}


- (void)setPTZCtrlEnable:(UIButton *)sender
{
    ptzBtn.selected = !ptzBtn.selected;
    
    videoWnd.enablePTZCtrl = ptzBtn.selected;
    
    if (ptzBtn.selected) {
        [self hideVideoContrl];
        
        CGRect frame = ptzBtn.frame;
        frame.origin.x = CGRectGetWidth(videoWnd.frame)-SIDE_BAR_WIDTH;
        ptzBtn.frame = frame;
        
        
    }
    else {
        [self showVideoContrl];
        
        CGRect frame = ptzBtn.frame;
        frame.origin.x = CGRectGetMaxX(bitrateBtn.frame)-PTZBtnW;
        ptzBtn.frame = frame;
        
    }
}

//显示视频控件
- (void)showVideoContrl
{
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self performSelector:@selector(hideVideoContrl) withObject:nil afterDelay:HIDE_TIME];
    
    [self setBitrateBtnState:UIControlStateNormal];
    
    sideBar.hidden = NO;
    bitrateBtn.hidden = NO;
    ptzBtn.hidden = NO;

}



//隐藏视频控件
- (void)hideVideoContrl
{
    sideBar.hidden = YES;
    bitrateBtn.hidden = YES;
    bitrateView.hidden = YES;
    [self setBitrateBtnState:UIControlStateNormal];
    

}



- (void)stopPlaying
{
    
    //关闭视频可以自动锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
#ifndef INVALID_VIDEO
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
#endif
    

    self.isPlaying = NO;
    
    [self hideVideoContrl];
    playBtn.hidden = NO;
    
}

//播放
- (void)playVideo
{
#ifndef INVALID_VIDEO
    playBtn.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PlayVideoNotification object:self];
    
    //播放视频
    float fplayScale = 1.0;
    if ([UIScreen instancesRespondToSelector:@selector(scale)])
    {
        fplayScale = (CGFloat)[[UIScreen mainScreen] scale];
    }
    
    NSString *url = [(SHVideoDevice *)_device videoUrl];
    NSString *pubUrl = [(SHVideoDevice *)_device pubVideoUrl];
    
    
    MBProgressHUD *tempHud = [[MBProgressHUD alloc] initWithView:self];
    [self addSubview:tempHud];
    tempHud.removeFromSuperViewOnHide = YES;
    tempHud.mode = MBProgressHUDModeIndeterminate;
    [tempHud show:YES];
    
    
    [[NetAPIClient sharedClient] queryIpcVideoCount:self.device successCallback:^(BOOL max)
     {
         
         if (max) {
             if (!videoMaxView)
             {
                 CGFloat width = 205;
                 CGFloat height = 90;
                 videoMaxView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(videoWnd.bounds)-width)/2, (CGRectGetHeight(videoWnd.bounds)-height)/2, width, height)];
                 videoMaxView.image = [UIImage imageNamed:@"VideoCountMax"];
                 [videoWnd addSubview: videoMaxView];
                 
                 CGFloat tipHeight = 30;
                 UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(0, (height-tipHeight)/2, width, tipHeight)];
                 tip.text = @"远程视频转发资源已满!";
                 [videoMaxView addSubview:tip];
                 tip.font = [UIFont systemFontOfSize:16];
                 tip.textColor = [UIColor whiteColor];
                 tip.backgroundColor = [UIColor clearColor];
                 tip.textAlignment = NSTextAlignmentCenter;
             }
         }
         
     }failureCallback:^{
         NSLog(@"查询视频转发数失败");
     }];
    
    [[NetAPIClient sharedClient] getIpcBitrate:self.device successCallback:^(VideoQuality grade)
     {
         if (grade == VideoQualityClear) {
             [bitrateBtn setTitle:@"清晰" forState:UIControlStateNormal];
             [bitrateView setSelectedIndex:0];
         }
         else {
             [bitrateBtn setTitle:@"流畅" forState:UIControlStateNormal];
             [bitrateView setSelectedIndex:1];
         }
         
     }failureCallback:^{
         NSLog(@"获取视频码流失败");
     }];
    
    
    int ret = -1;
    int ret1 = -1;
    if (url) {
        ret = [zw_dssdk dssdk_rtv_start:(__bridge void *)(videoWnd):(char*)[url UTF8String] :fplayScale];
    }
    
   if (ret != 1 && pubUrl) {
        
        ret1 = [zw_dssdk dssdk_rtv_start:(__bridge void *)(videoWnd):(char*)[pubUrl UTF8String] :fplayScale];
        
    }
    
    
    if (ret == 1 || ret1 == 1) {
        self.isPlaying = YES;
        playBtn.hidden = YES;
        
        
        //看视频的时候防止锁屏
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
    }
    else {
        NSString *msg = [NSString stringWithFormat:@"%@(错误码:%d)\n%@(错误码:%d)",url,ret,pubUrl,ret1];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"打开视频失败" message:msg delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alert show];
        
        self.isPlaying = NO;
        playBtn.hidden = NO;
    }
    
    
    [tempHud hide:YES];
    
    [self showVideoContrl];
    
    
    
#endif
}



- (void)tapBgdView
{
    if (!ptzBtn.selected) {
        if (self.isPlaying) {
            
            if (sideBar.hidden)
            {
                [self showVideoContrl];
            }
            else {
                [self hideVideoContrl];
            }
            
        }
        else {
            
            [self playVideo];
        }
    }

}

- (void) setAnchorPoint:(CGPoint)anchorpoint forView:(UIView *)view{
    CGRect oldFrame = view.frame;
    view.layer.anchorPoint = anchorpoint;
    view.frame = oldFrame;
}


- (void)playFullScreenVideo
{
     CGRect wndBounds = [UIScreen mainScreen].bounds;
    
    CGAffineTransform transform;
    CGRect videoWndRct;
    
    if (!landscape) {//竖屏
        
        
        CGRect convRect = [[UIApplication sharedApplication].keyWindow convertRect:videoWnd.frame fromView:bgdView];
        

        float scaleX = CGRectGetHeight(wndBounds)/CGRectGetWidth(videoWnd.frame) ;
        
        float scaleY = CGRectGetWidth(wndBounds)/CGRectGetHeight(videoWnd.frame) ;
        
        CGAffineTransform translation = CGAffineTransformMakeTranslation(-CGRectGetMinX(convRect), -CGRectGetHeight(videoWnd.bounds)-CGRectGetMinY(convRect));
        CGAffineTransform rotation = CGAffineTransformRotate(translation, M_PI/2);
        
        //此处没有采用scale而是改变他的bounds，是因为scale后子视图的frame、bounds虽然未变，但确实放大了...
        CGAffineTransform scale = CGAffineTransformScale(rotation, scaleX, scaleY);

        
        //transform =  scale;
        transform =  rotation;
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        
        videoWnd.frame = convRect;
        [[UIApplication sharedApplication].keyWindow addSubview:videoWnd];
        

        videoWndRct = CGRectMake(0, 0, CGRectGetHeight(wndBounds), CGRectGetWidth(wndBounds));
        
    }
    else {
        
        transform = CGAffineTransformIdentity;
        
        videoWndRct = CGRectMake(0, 0, CGRectGetWidth(originFrame), CGRectGetHeight(originFrame));
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }
    
    
    [UIView animateWithDuration:0.5 animations:^{
        videoWnd.transform = transform;
        
         videoWnd.bounds = videoWndRct;
        
    }completion:^(BOOL f){
        
        if (f) {
            if (landscape) {//横屏到竖屏
                [videoWnd removeFromSuperview];
                videoWnd.frame = originFrame;
                [bgdView addSubview:videoWnd];
                [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
                
                [landscapeBtn setImage:[UIImage imageNamed:@"FullScreenNormal"] forState:UIControlStateNormal];
                [landscapeBtn setImage:[UIImage imageNamed:@"FullScreenHl"] forState:UIControlStateHighlighted];
                
                
            }
            else {//竖屏到全屏横屏
                [landscapeBtn setImage:[UIImage imageNamed:@"QuitFullScreenNormal"] forState:UIControlStateNormal];
                [landscapeBtn setImage:[UIImage imageNamed:@"QuitFullScreenHl"] forState:UIControlStateHighlighted];
                
            }
            
            landscape = !landscape;

        }
    }];

}


- (void)resetSideBar
{
//    if (landscape) {//横屏
//        sideBar.frame = CGRectMake(CGRectGetWidth(videoWnd.frame)-SIDE_BAR_WIDTH, 0, SIDE_BAR_WIDTH, CGRectGetHeight(videoWnd.frame));
//        landscapeBtn.frame = CGRectMake(0, CGRectGetHeight(sideBar.frame)-SIDE_BAR_WIDTH-10, SIDE_BAR_WIDTH, SIDE_BAR_WIDTH);
//        closeBtn.frame = CGRectMake(0, 10, SIDE_BAR_WIDTH, SIDE_BAR_WIDTH);
//    }
//    else {
//        sideBar.frame = CGRectMake(CGRectGetHeight(videoWnd.frame)-SIDE_BAR_WIDTH, 0, SIDE_BAR_WIDTH, CGRectGetWidth(videoWnd.frame));
//        landscapeBtn.frame = CGRectMake(0, CGRectGetWidth(sideBar.frame)-SIDE_BAR_WIDTH-10, SIDE_BAR_WIDTH, SIDE_BAR_WIDTH);
//        closeBtn.frame = CGRectMake(0, 10, SIDE_BAR_WIDTH, SIDE_BAR_WIDTH);
//    }
    
    CGRect landscapeBtnF = landscapeBtn.frame;
    landscapeBtnF.size = CGSizeMake(SIDE_BAR_WIDTH, SIDE_BAR_WIDTH);
    landscapeBtn.frame = landscapeBtnF;
    
    CGRect closeBtnF = closeBtn.frame;
    closeBtnF.size = CGSizeMake(SIDE_BAR_WIDTH, SIDE_BAR_WIDTH);
    closeBtn.frame = closeBtnF;

}


- (void)changeBitRate:(UIButton *)sender
{

    [self setBitrateBtnState:UIControlStateSelected];
    
//    bitrateView.selectedIndex = VideoQualityClear;
    bitrateView.hidden = NO;
    

}

- (void)setBitrateBtnState:(UIControlState)state
{
    if (state == UIControlStateNormal) {
        [bitrateBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        bitrateBtn.backgroundColor = [UIColor colorWithRed:127/255. green:127/255. blue:127/255. alpha:1];
        bitrateBtn.layer.borderColor = [UIColor colorWithRed:166/255. green:166/255. blue:166/255. alpha:1].CGColor;
    }
    else if (state == UIControlStateSelected) {
        [bitrateBtn setTitleColor:[UIColor colorWithRed:84/255. green:193/255. blue:12/255. alpha:1] forState:UIControlStateNormal];
        bitrateBtn.backgroundColor = [UIColor colorWithRed:38/255. green:38/255. blue:38/255. alpha:1];
        bitrateBtn.layer.borderColor = [UIColor colorWithRed:84/255. green:193/255. blue:12/255. alpha:1].CGColor;
    }
    
}



- (void)bitrateView:(BitrateView *)brView didSelectAtIndex:(NSInteger)index
{

    if (index == VideoQualityClear) {
        [bitrateBtn setTitle:@"清晰" forState:UIControlStateNormal];
    }
    else {
        [bitrateBtn setTitle:@"流畅" forState:UIControlStateNormal];
    }
    
    [self setBitrateBtnState:UIControlStateNormal];
    
    
    [[NetAPIClient sharedClient] setIpcBitrate:self.device quality:index successCallback:^{
        NSLog(@"设置码流 %d 成功",index);
        
        bitrateView.hidden = YES;
    }failureCallback:^{
        [self showCtrlFailedHint];
        
        bitrateView.hidden = YES;
    }];
}


#pragma mark VideoWndDelegate

- (void)videoWndBeginTouch
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self hideArrowAnimated:[NSNumber numberWithBool:NO]];
}


- (void)videoWnd:(VideoWnd *)videoWnd swipeToDirection:(SwipeDirection)direction
{

    [self rotateArrowTo:direction];
    
    [[NetAPIClient sharedClient] PTZControlMove:self.device direction:direction successCallback:^{
        
        NSLog(@"swipeToDirection %d success",direction);
        
    }failureCallback:^{
        NSLog(@"swipeToDirection %d failed",direction);
    }];
}

- (void)videoWnd:(VideoWnd *)videoWnd scale:(CGFloat)scaleFactor
{
  
    [[NetAPIClient sharedClient] PTZControlScale:self.device factor:scaleFactor successCallback:^{
        
        NSLog(@"scale %f success",scaleFactor);
        
    }failureCallback:^{
        NSLog(@"scale %f failed",scaleFactor);
    }];
}

- (void)hideArrowAnimated:(NSNumber *)bNumber
{
    if ([bNumber boolValue]) {
        [UIView animateWithDuration:0.2 animations:^{
            arrowView.alpha = 0.0;
        }completion:^(BOOL f){
            
            
        }];
    }
    else {
        arrowView.alpha = 0.0;
    }
    
    
}


- (void)rotateArrowTo:(SwipeDirection)direction
{
    CGFloat angle = 0;
    CGFloat x = 0;
    CGFloat y = 0;
    
    switch (direction) {
        case SwipeDirectionUp:
            angle = 0;
            x = (CGRectGetWidth(videoWnd.bounds) - ARROW_SIZE)/2;
            y = 0;
            break;
        case SwipeDirectionLeft:
            angle = -M_PI/2;
            x = 0;
            y = (CGRectGetHeight(videoWnd.bounds) - ARROW_SIZE)/2;
            break;
        case SwipeDirectionDown:
            angle = M_PI;
            x = (CGRectGetWidth(videoWnd.bounds) - ARROW_SIZE)/2;
            y = CGRectGetHeight(videoWnd.bounds) - ARROW_SIZE;
            break;
        case SwipeDirectionRight:
            angle = M_PI/2;
            x = CGRectGetWidth(videoWnd.bounds) - ARROW_SIZE;
            y = (CGRectGetHeight(videoWnd.bounds) - ARROW_SIZE)/2;
            break;
        case SwipeDirectionLeftUp:
            angle = -M_PI/4;
            x = 0;
            y = 0;
            break;
        case SwipeDirectionRightUp:
            angle = M_PI/4;
            x = CGRectGetWidth(videoWnd.bounds) - ARROW_SIZE;
            y = 0;
            break;
        case SwipeDirectionLeftDown:
            angle = -M_PI*3/4;
            x = 0;
            y = CGRectGetHeight(videoWnd.bounds) - ARROW_SIZE;
            break;
        case SwipeDirectionRightDown:
            angle = M_PI*3/4;
            x = CGRectGetWidth(videoWnd.bounds) - ARROW_SIZE;
            y = CGRectGetHeight(videoWnd.bounds) - ARROW_SIZE;
            break;
            
        default:
            break;
    }
    
    arrowView.transform = CGAffineTransformIdentity;
    
    
    CGRect frame = arrowView.frame;
    frame.origin.x = x;
    frame.origin.y = y;
    arrowView.frame = frame;
    
    CGAffineTransform rotation = CGAffineTransformMakeRotation(angle);
    arrowView.transform = rotation;
    
    arrowView.alpha = 0.0;
    [UIView animateWithDuration:0.2 animations:^{
        arrowView.alpha = 1.0;
    }completion:^(BOOL f){
        
        if (f) {
            [self performSelector:@selector(hideArrowAnimated:) withObject:[NSNumber numberWithBool:YES] afterDelay:ARROW_DISPLAY_TIME];
        }
    }];
}



@end
