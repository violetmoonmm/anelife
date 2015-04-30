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


#define NAV_TITLE_FONT ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 18 : 24)

#define TAG_VIDEO_BTN 100

#define TAGP_GATEWAY_BTN 300

#define REQ_TIMEOUT 10

#define SIDE_BAR_WIDTH 50

#define HIDE_TIME 5 //5秒后隐藏

@interface VideoMonitorViewController ()

- (void)hideSideBar;

@end

@interface VideoMonitorViewController () <VideoChannelViewDelegate,PopInputViewDelegate>
{
    IBOutlet VideoWnd *videoWnd;
    
    IBOutlet VideoChannelView *channelView;
    
    IBOutlet UIButton *playView;
    
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
}

@end

@implementation VideoMonitorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusChangeNtf:) name:DeviceStatusChangeNotification object:nil];
   
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
    sideBar.alpha = 0;
    sideBar.autoresizingMask = UIViewAutoresizingFlexibleHeight |  UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
    sideBar.autoresizesSubviews = YES;
    

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

    playView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    
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
#ifndef SIMULATOR
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
#endif
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
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
  
    playView.hidden = YES;
    
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
    
    
#ifndef SIMULATOR
    MBProgressHUD *tempHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:tempHud];
    tempHud.removeFromSuperViewOnHide = YES;
    tempHud.mode = MBProgressHUDModeIndeterminate;
    [tempHud show:YES];
    
    if (url) {
        int ret = [zw_dssdk dssdk_rtv_start:(__bridge void *)(videoWnd):(char*)[url UTF8String]:fplayScale];
        if (ret == 1) {//播放成功
            
            
            isPlaying = YES;
            
            [[UIApplication sharedApplication] setIdleTimerDisabled:YES];//防止自动锁屏
            
            NSLog(@"playingUrl:%@",url);
            
        }
        else if (pubUrl) {
            
            int ret1 = [zw_dssdk dssdk_rtv_start:(__bridge void *)(videoWnd):(char*)[pubUrl UTF8String]:fplayScale];
            
            if (ret1 == 1)
            {
                
                isPlaying = YES;
                
                [[UIApplication sharedApplication] setIdleTimerDisabled:YES];//防止自动锁屏
                
                NSLog(@"playingUrl:%@",pubUrl);
            }
            else  {
                NSString *msg = [NSString stringWithFormat:@"%@(错误码:%d)\n%@(错误码:%d)",url,ret,pubUrl,ret1];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"打开视频失败" message:msg delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                [alert show];
                
                playView.hidden = NO;
                isPlaying = NO;
            }
            
        }

    }
    
    [tempHud hide:YES];
    
#endif
    
    [self showSideBar];

}


- (void)stopPlaying
{
    
    //关闭视频可以自动锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
#ifndef SIMULATOR
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
#endif
    
    
    isPlaying = NO;
    
    playView.hidden = NO;
    
}


- (void)tapVideoWnd
{
    if (isPlaying) {

        if (sideBar.alpha == 0)
        {
            [self showSideBar];
            
            if(sideBar.hidden)
            {
                NSLog(@"side bar hidden when alpha == 1");
            }
        }
        else {
            [self hideSideBar];
        }
    }
    else {
            
        [self playVideo:nil];
    }
}

- (void)showSideBar
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideSideBar) object:nil];
    
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
#ifndef SIMULATOR
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
    
#endif
    
    playView.hidden = NO;
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

@end
