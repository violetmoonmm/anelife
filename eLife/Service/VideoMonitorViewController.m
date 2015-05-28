//
//  VideoMonitorViewController.m
//  eLife
//
//  Created by mac on 14-5-9.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "VideoMonitorViewController.h"
#import "zw_dssdk.h"
#import "VideoWnd.h"
#import "NetAPIClient.h"
#import "DeviceData.h"
#import "NotificationDefine.h"
#import "Util.h"
#import "VideoChannelView.h"
#import "MBProgressHUD.h"
#import "PublicDefine.h"
#import "PopInputView.h"
#import "BitrateView.h"

#define NAV_TITLE_FONT ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 18 : 24)

#define TAG_VIDEO_BTN 100

#define TAGP_GATEWAY_BTN 300

#define REQ_TIMEOUT 10

#define SIDE_BAR_WIDTH 50

#define HIDE_TIME 5 //5秒后隐藏

@interface VideoMonitorViewController ()

- (void)hideVideoContrl;

@end

@interface VideoMonitorViewController () <VideoChannelViewDelegate,PopInputViewDelegate,BitrateViewDelegate>
{
    IBOutlet VideoWnd *videoWnd;
    
    IBOutlet VideoChannelView *channelView;
    
    IBOutlet UIButton *playBtn;
    
    IBOutlet UIButton *videoCoverBtn;
    
    IBOutlet UIView *videoBgdView;
    
    NSMutableArray *gateways;
    
    UILabel *titleLabel;//标题
    UIButton *expandBtn;//网关选中按钮

    UIView *multiSelectionView;//网关选择视图
    
    MBProgressHUD *hud;
    
    NSInteger selectedIndex;
    
    //temp use
    NSMutableArray *videoDevices;
    NSInteger videoIndex;
    
    UIView *sideBar;
    BOOL landscape;
    UIButton *landscapeBtn;
    CGRect originFrame;
    
    BOOL isPlaying;
    
    BitrateView *bitrateView;
    UIImageView *videoMaxView;//视频转发达到最大数
    UIButton *bitrateBtn;
}

@end

@implementation VideoMonitorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        

        [self registerNotification];
   
        videoDevices = [NSMutableArray arrayWithCapacity:1];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    videoBgdView.backgroundColor = [UIColor colorWithRed:232/255. green:232/255. blue:232/255. alpha:1];
    
    
    [Util unifyStyleOfViewController:self withTitle:@"实时监控"];
    
    
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack:)];
    
    
//    for (SHGateway *gateway in [NetAPIClient sharedClient].gatewayList)
//    {
//        [videoDevices addObjectsFromArray:gateway.ipcArray];
//    }
    
    channelView.delegate = self;

    MBProgressHUD *tempHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:tempHud];
    tempHud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"请稍后...";
    tempHud.mode = MBProgressHUDModeIndeterminate;
    [tempHud show:YES];
    
    
    [[NetAPIClient sharedClient] getIpcList:^(NSArray *ipcList){
        [tempHud hide:YES];
        
        [videoDevices addObjectsFromArray:ipcList];
        [channelView reloadData];
        
         channelView.selectedIndex = videoIndex;
        
        videoIndex = INVALID_INDEX;
        if ([videoDevices count] > 0) {
            videoIndex = 0;
            
            SHVideoDevice *currentVideoDevice = [videoDevices objectAtIndex:videoIndex];
            
            [self showWaitingStatus];
            
            [[NetAPIClient sharedClient] getVideoCover:currentVideoDevice successCallback:^(bool enable){
                
                [self hideWaitingStatus];
                
                NSLog(@"获取视频遮盖成功 enable:%@",enable ? @"yes":@"no");
                [self setVideoCoverImage:currentVideoDevice];
                
            }failureCallback:^{
                [self hideWaitingStatus];
                
                NSLog(@"获取视频遮盖失败");
            }];
            
            
        }
    }];
    
    originFrame = videoWnd.frame;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapVideoWnd)];
    [videoWnd addGestureRecognizer:tap];
    
    //设置锚点
    [self setAnchorPoint:CGPointMake(0, 1) forView:videoWnd];
    
    
    //边栏
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

    //关闭视频按钮
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(0, 10, SIDE_BAR_WIDTH, SIDE_BAR_WIDTH);
    [closeBtn setImage:[UIImage imageNamed:@"VideoCloseNormal"] forState:UIControlStateNormal];
    [closeBtn setImage:[UIImage imageNamed:@"VideoCloseHl"] forState:UIControlStateHighlighted];
    [closeBtn setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    [closeBtn addTarget:self action:@selector(stopPlaying) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:closeBtn];
    
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

    playBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

}

- (void)dealloc
{

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self ];
#ifndef INVALID_VIDEO
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
#endif
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}


//注册通知
- (void)registerNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusChangeNtf:) name:DeviceStatusChangeNotification object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogout:) name:LogoutNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayVideoNtf:) name:PlayVideoNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
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
    
    SHVideoDevice *currentVideoDevice = [videoDevices objectAtIndex:videoIndex];
    
    [[NetAPIClient sharedClient] setIpcBitrate:currentVideoDevice quality:index successCallback:^{
        NSLog(@"设置码流 %d 成功",index);
        
        bitrateView.hidden = YES;
    }failureCallback:^{
        [self showCtrlFailedHint];
        
        bitrateView.hidden = YES;
    }];
}

- (void)showCtrlFailedHint
{
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"控制失败！";
    [hud show:YES];
    
    [hud hide:YES afterDelay:1.0];
}


- (void)setAnchorPoint:(CGPoint)anchorpoint forView:(UIView *)view{
    CGRect oldFrame = view.frame;
    view.layer.anchorPoint = anchorpoint;
    view.frame = oldFrame;
}


- (void)goBack:(UIButton *)sender
{
    
    
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)observeIpc:(SHVideoDevice *)ipc
//{
//    [ipc addObserver:self forKeyPath:@"coverEnable" options:0 context:0];
//}
//
//- (void)removeObserveIpc:(SHVideoDevice *)ipc
//{
//    [ipc removeObserver:self forKeyPath:@"coverEnable" context:0];
//}

- (void)swipeRight
{
//    [self goBack:nil];
}


- (IBAction)playVideo:(id)sender
{
    if (videoIndex != INVALID_INDEX) {
        [self playVideoAtIndex:videoIndex];
    }
    
}


- (void)playVideoAtIndex:(NSInteger)index
{
#ifndef INVALID_VIDEO  
    playBtn.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PlayVideoNotification object:self];
    
    float fplayScale = 1.0;
    if ([UIScreen instancesRespondToSelector:@selector(scale)])
    {
        fplayScale = (CGFloat)[[UIScreen mainScreen] scale];
    }
    
    
    if ([videoDevices count] <= 0) {
        return;
    }
    
    SHVideoDevice *device = [videoDevices objectAtIndex:index];
    
    NSString *url = [device videoUrl];//视频地址
    NSString *pubUrl = [device pubVideoUrl];//公网视频地址
    
    
    NSLog(@"play video url:%@ pubUrl:%@",url,pubUrl);


    MBProgressHUD *tempHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:tempHud];
    tempHud.removeFromSuperViewOnHide = YES;
    tempHud.mode = MBProgressHUDModeIndeterminate;
    [tempHud show:YES];
    
    SHVideoDevice *currentVideoDevice = [videoDevices objectAtIndex:videoIndex];
    
    [[NetAPIClient sharedClient] queryIpcVideoCount:currentVideoDevice successCallback:^(BOOL max)
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
    
    [[NetAPIClient sharedClient] getIpcBitrate:currentVideoDevice successCallback:^(VideoQuality grade)
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
        isPlaying = YES;
        playBtn.hidden = YES;
        
        
        //看视频的时候防止锁屏
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
    }
    else {
        NSString *msg = [NSString stringWithFormat:@"%@(错误码:%d)\n%@(错误码:%d)",url,ret,pubUrl,ret1];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"打开视频失败" message:msg delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alert show];
        
        isPlaying = NO;
        playBtn.hidden = NO;
    }
    
    [tempHud hide:YES];
    
    [self showVideoContrl];

   
#endif
}


- (void)stopPlaying
{
    
    //关闭视频可以自动锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
#ifndef INVALID_VIDEO
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
#endif
    
    
    isPlaying = NO;
    
    playBtn.hidden = NO;
    
    [self hideVideoContrl];

    
}


- (void)tapVideoWnd
{
    if (isPlaying) {

        if (sideBar.hidden)
        {
            [self showVideoContrl];
        }
        else {
            [self hideVideoContrl];
        }
    }
    else {
            
        [self playVideo:nil];
    }
}

- (void)showVideoContrl
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideVideoContrl) object:nil];
    
    [self performSelector:@selector(hideVideoContrl) withObject:nil afterDelay:HIDE_TIME];
    
    [self setBitrateBtnState:UIControlStateNormal];
    
    sideBar.hidden = NO;
    bitrateBtn.hidden = NO;

}

- (void)hideVideoContrl
{
    sideBar.hidden = YES;
    bitrateBtn.hidden = YES;
    bitrateView.hidden = YES;
    
}

- (void)playFullScreenVideo
{
    CGRect wndBounds = [UIScreen mainScreen].bounds;
    
    CGAffineTransform transform;
    CGRect videoWndRct;
    
    if (!landscape) {//竖屏
        
        
        CGRect convRect = [[UIApplication sharedApplication].keyWindow convertRect:videoWnd.frame fromView:videoBgdView];
        
        
        float scaleX = CGRectGetHeight(wndBounds)/CGRectGetWidth(videoWnd.frame) ;
        
        float scaleY = CGRectGetWidth(wndBounds)/CGRectGetHeight(videoWnd.frame) ;
        
        CGAffineTransform translation = CGAffineTransformMakeTranslation(-CGRectGetMinX(convRect), -CGRectGetHeight(videoWnd.bounds)-CGRectGetMinY(convRect));
        CGAffineTransform rotation = CGAffineTransformRotate(translation, M_PI/2);
        
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
                [videoBgdView addSubview:videoWnd];
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


//- (void)observeValueForKeyPath:(NSString *)keyPath
//                      ofObject:(id)object
//                        change:(NSDictionary *)change
//                       context:(void *)context
//{
//    if ([keyPath isEqualToString:@"coverEnable"]) {
//        NSInteger index = [videoDevices indexOfObject:object];
//        
//        if (index == videoIndex) {
//            [self setVideoCoverImage:(SHVideoDevice *)object];
//        }
//    }
//}

#pragma mark delegate

- (void)channelView:(VideoChannelView *)channelView didSelectAtIndex:(NSInteger)index
{
    
    SHVideoDevice *currentVideoDevice = [videoDevices objectAtIndex:index];
    [self setVideoCoverImage:currentVideoDevice];
    
    videoIndex = index;
    
    if (currentVideoDevice.state.online)
    {
        
        [self showWaitingStatus];
        
        
        [[NetAPIClient sharedClient] getVideoCover:currentVideoDevice successCallback:^(bool enable){
            
            [self hideWaitingStatus];
            
            NSLog(@"获取视频遮盖成功 enable:%@",enable ? @"yes":@"no");
            [self setVideoCoverImage:currentVideoDevice];
            
        }failureCallback:^{
            [self hideWaitingStatus];
            
            NSLog(@"获取视频遮盖失败");
        }];
        
        
        [self playVideoAtIndex:videoIndex];
    }
    else {
        [self stopPlaying];
    }

    
}

- (UIImage *)channelView:(VideoChannelView *)channelView imageAtIndex:(NSInteger)index
{
    return [UIImage imageNamed:@"Camera"];
}

- (NSString *)channelView:(VideoChannelView *)channelView titleAtIndex:(NSInteger)index
{
    SHVideoDevice *device = [videoDevices objectAtIndex:index];
    
    return device.name;
}

- (UIView *)channelView:(VideoChannelView *)channelView contentViewAtIndex:(NSInteger)index
{
    SHVideoDevice *device = [videoDevices objectAtIndex:index];
    
    
    if (device.state.online) {
        NSInteger iconWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 35 : 35);
        NSInteger iconHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 19 : 19);
        
        //摄像头
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, iconWidth, iconHeight)];
        imageView.image = [UIImage imageNamed:@"Camera"];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.userInteractionEnabled = YES;
        
        return imageView;
    }
    
    NSInteger fontSize = 16;
    UIFont *font = [UIFont boldSystemFontOfSize:fontSize];
    CGSize s = [@"摄像机离线" sizeWithFont:font];
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, s.width, s.height)];
    lbl.text = @"摄像机离线";
    lbl.font = font;
    lbl.textColor = [UIColor whiteColor];
    lbl.backgroundColor = [UIColor clearColor];
    
    return lbl;
}

- (NSInteger)numberOfItemsInVideoChannelView:(VideoChannelView *)channelView
{
    return [videoDevices count];
}



- (void)hideWaitingStatus
{
    
    [hud hide:YES];
    hud = nil;
}

- (void)showWaitingStatus
{
    NSLog(@"showWaitingStatus");
    
    [hud hide:YES];
    
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
//    hud.labelText = @"请稍后...";
    hud.mode = MBProgressHUDModeIndeterminate;
    [hud show:YES];
    
    [hud hide:YES afterDelay:REQ_TIMEOUT];
    
    
}





- (IBAction)onClickVideoCover:(UIButton *)sender
{
    if (videoIndex == INVALID_INDEX)
    {
        return;
    }
    
    SHVideoDevice *device = [videoDevices objectAtIndex:videoIndex];
    
    BOOL setCoverEnable = !device.coverEnable;//设置是否使能
    
    if (!setCoverEnable)
    {
        PopInputView *inputView = [[PopInputView alloc] initWithTitle:@"退出隐私保护模式" placeholder:@"请输入安全密码" delegate:self];
        [inputView show];
    }
    else {
        
        [[NetAPIClient sharedClient] setVideoCover:device enable:setCoverEnable successCallback:^{
            NSLog(@"设置视频遮盖成功");
            
            [self setVideoCoverImage:device];
            
        }failureCallback:^{
             NSLog(@"设置视频遮盖失败");
        }];
        
    }

}


- (void)setVideoCoverImage:(SHVideoDevice *)device
{
    if (device.coverEnable) {

        [videoCoverBtn setImage:[UIImage imageNamed:@"PrivacyOn"] forState:UIControlStateNormal];
        [videoCoverBtn setImage:[UIImage imageNamed:@"PrivacyOnHl"] forState:UIControlStateHighlighted];
    }
    else {
   
        [videoCoverBtn setImage:[UIImage imageNamed:@"PrivacyOff"] forState:UIControlStateNormal];
        [videoCoverBtn setImage:[UIImage imageNamed:@"PrivacyOffHl"] forState:UIControlStateHighlighted];
    }
}



- (void)showCtrlFailedHint:(NSString *)info
{
    
    MBProgressHUD *tempHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:tempHud];
    tempHud.removeFromSuperViewOnHide = YES;
    tempHud.mode = MBProgressHUDModeText;
    tempHud.labelText = info;
    [tempHud show:YES];
    
    [tempHud hide:YES afterDelay:1.0];
}


#pragma mark PopInputViewDelegate

- (void)popInputView:(PopInputView *)popInputView clickOkButtonWithText:(NSString *)inputText
{
    if ([inputText isEqualToString:@"666666"]) {
 
        SHVideoDevice *device = [videoDevices objectAtIndex:videoIndex];

        [[NetAPIClient sharedClient] setVideoCover:device enable:false successCallback:^{
            
            [self setVideoCoverImage:device];
            
        }failureCallback:^{
            
        }];
    }
    else {
        
        [self showCtrlFailedHint:@"密码错误!"];
    }
}

- (void)popInputView:(PopInputView *)popInputView clickCancelButtonWithText:(NSString *)inputText
{
   
    
}

#pragma mark 通知处理
- (void)appDidEnterBackground:(NSNotification*)ntf
{
    NSLog(@"appDidEnterBackground");
#ifndef INVALID_VIDEO
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
    
#endif
    
    playBtn.hidden = NO;
}

- (void)handleStatusChangeNtf:(NSNotification *)ntf
{
    SHDevice *device = [ntf object];
    
    if ([device.type isEqualToString:SH_DEVICE_IPC]) {
        NSInteger index = [videoDevices indexOfObject:device];
        
        if (index != NSNotFound) {
            [channelView reloadItemAtIndex:index];
        }
    }
}


- (void)handlePlayVideoNtf:(NSNotification *)ntf
{
    if (ntf.object != self) {
        [self stopPlaying];
    }
}

@end
