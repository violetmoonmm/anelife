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

#define MarginX 4//x轴左右边缘
#define MarginY 4//y轴上下边缘

#define VideoWndMargin 4//视频边缘

#define HIDE_TIME 5 //5秒后隐藏

#define SIDE_BAR_WIDTH 50

@interface BasicVideoCell ()
{
    UIImageView *bgdView;
    
    VideoWnd *videoWnd;
    
    UIButton *playBtn;
    UIButton *closeBtn;
    UIButton *landscapeBtn;//横屏按钮
    
    UIView *sideBar;
    
    BOOL landscape;

    CGRect originFrame;//videoWnd的原始frame
    
    
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
        
        //注册登出通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogout:) name:LogoutNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];

        sideBar = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(videoWnd.frame)-SIDE_BAR_WIDTH, 0, SIDE_BAR_WIDTH, CGRectGetHeight(videoWnd.frame))];
        sideBar.backgroundColor = [UIColor clearColor];
        sideBar.userInteractionEnabled = YES;
        [videoWnd addSubview:sideBar];
//        sideBar.hidden = YES;
        sideBar.alpha = 0.0;
        sideBar.autoresizingMask = UIViewAutoresizingFlexibleHeight |  UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
        sideBar.autoresizesSubviews = YES;

        
        //关闭视频按钮
        closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        closeBtn.frame = CGRectMake(0, 10, SIDE_BAR_WIDTH, SIDE_BAR_WIDTH);
        [closeBtn setImage:[UIImage imageNamed:@"VideoCloseNormal"] forState:UIControlStateNormal];
        [closeBtn setImage:[UIImage imageNamed:@"VideoCloseHl"] forState:UIControlStateHighlighted];
        [closeBtn setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
        [closeBtn addTarget:self action:@selector(stopPlaying) forControlEvents:UIControlEventTouchUpInside];
        [sideBar addSubview:closeBtn];

        //closeBtn.backgroundColor = [UIColor redColor];
        closeBtn.autoresizingMask = UIViewAutoresizingNone;
        
        
        //全屏按钮
        landscapeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        landscapeBtn.frame = CGRectMake(0, CGRectGetHeight(sideBar.frame)-SIDE_BAR_WIDTH-10, SIDE_BAR_WIDTH, SIDE_BAR_WIDTH);
        [landscapeBtn setImage:[UIImage imageNamed:@"FullScreenNormal"] forState:UIControlStateNormal];
        [landscapeBtn setImage:[UIImage imageNamed:@"FullScreenHl"] forState:UIControlStateHighlighted];
        [landscapeBtn setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
        [landscapeBtn addTarget:self action:@selector(playFullScreenVideo) forControlEvents:UIControlEventTouchUpInside];
        [sideBar addSubview:landscapeBtn];
        landscapeBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        //landscapeBtn.backgroundColor = [UIColor redColor];
        
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
    
#ifndef SIMULATOR
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
#endif
}




- (void)appDidEnterBackground:(NSNotification*)ntf
{
    
    [self stopPlaying];
}

//登出 停止视频播放
- (void)handleLogout:(NSNotification *)ntf
{
#ifndef SIMULATOR
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
#endif
}

- (void)showSideBar
{
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self performSelector:@selector(hideSideBar) withObject:nil afterDelay:HIDE_TIME];
    
    sideBar.alpha = 0.0;
    
    [UIView animateWithDuration:0.2 animations:^{
        sideBar.alpha = 1.0;
    }completion:^(BOOL f){
//        sideBar.hidden = NO;
    }];
    
    

}

- (void)hideSideBar
{
    sideBar.alpha = 1.0;
    
    [UIView animateWithDuration:0.2 animations:^{
        sideBar.alpha = 0.0;
    }completion:^(BOOL f){
//        sideBar.hidden = YES;
    }];
}

- (void)showPlay
{
    sideBar.alpha = 0.0;
    
    playBtn.hidden = NO;
}

- (void)stopPlaying
{
    
    //关闭视频可以自动锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
#ifndef SIMULATOR
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
#endif
    

    self.isPlaying = NO;
    
    [self showPlay];
    
}

//播放
- (void)playVideo
{
    
    playBtn.hidden = YES;
    
    //播放视频
    float fplayScale = 1.0;
    if ([UIScreen instancesRespondToSelector:@selector(scale)])
    {
        fplayScale = (CGFloat)[[UIScreen mainScreen] scale];
    }
    
    NSString *url = [(SHVideoDevice *)_device videoUrl];
    NSString *pubUrl = [(SHVideoDevice *)_device pubVideoUrl];
    
    
#ifndef SIMULATOR
    
    MBProgressHUD *tempHud = [[MBProgressHUD alloc] initWithView:self];
    [self addSubview:tempHud];
    tempHud.removeFromSuperViewOnHide = YES;
    tempHud.mode = MBProgressHUDModeIndeterminate;
    [tempHud show:YES];
    
    if (url) {
        int ret = [zw_dssdk dssdk_rtv_start:(__bridge void *)(videoWnd):(char*)[url UTF8String] :fplayScale];
        if (ret == 1) {//打开视频成功
            
            self.isPlaying = YES;
            playBtn.hidden = YES;
            
            
            //看视频的时候防止锁屏
            [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
            
            
        }
        else if (pubUrl) {//失败
            
            int ret1 = [zw_dssdk dssdk_rtv_start:(__bridge void *)(videoWnd):(char*)[pubUrl UTF8String] :fplayScale];
            
            if (ret1 == 1) {
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
            
        }
        
    }
    
    [tempHud hide:YES];
    
#endif
    
    [self showSideBar];
}



- (void)tapBgdView
{
    if (self.isPlaying) {
//        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideSideBar) object:nil];
        if (sideBar.alpha == 0)
        {
            [self showSideBar];
        }
        else {
            [self hideSideBar];
        }
        
    }
    else {
        
        [self playVideo];
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

@end
