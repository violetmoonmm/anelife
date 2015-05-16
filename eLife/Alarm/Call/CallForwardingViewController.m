//
//  CallForwardingViewController.m
//  eLife
//
//  Created by mac on 14-5-26.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "CallForwardingViewController.h"
#import "VideoWnd.h"
#import "zw_dssdk.h"
#import "AppDelegate.h"
#import "NetAPIClient.h"
#import "DeviceData.h"
#import "Util.h"
#import "NotificationDefine.h"

@interface CallForwardingViewController ()
{
   
    IBOutlet VideoWnd *videoWnd;

    IBOutlet UIView *bottomView;
    IBOutlet UIView *bgdView;

}

@end

@implementation CallForwardingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
  
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    


    [Util unifyStyleOfViewController:self withTitle:@"呼叫转移"];
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];

    [self initSubViews];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self playVideo];

}

- (void)viewWillDisappear:(BOOL)animated
{
   
    [super viewWillDisappear:animated];
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

#ifndef INVALID_VIDEO
    [zw_dssdk dssdk_talk_stop:(__bridge void *)(videoWnd)];
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
    
#endif
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)appDidEnterBackground:(NSNotification*)ntf
{
    NSLog(@"appDidEnterBackground");
#ifndef INVALID_VIDEO
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
    [zw_dssdk dssdk_talk_stop:(__bridge void *)(videoWnd)];
#endif
}

- (void)handleRcvGetVtoNtf:(NSNotification *)ntf
{
    
    [self playVideo];
}

- (void)initSubViews
{
    
    CGRect btmFrame = bottomView.frame;
    CGRect bgdFrame = bgdView.frame;
    
    bgdFrame.origin.y =0;
    bgdFrame.size.height = CGRectGetHeight(self.view.frame) - CGRectGetHeight(btmFrame);
    bgdView.frame = bgdFrame;
}

- (void)goBack
{

    [(AppDelegate *)[UIApplication sharedApplication].delegate dismissCallView];
    
}

- (void)playVideo
{
#ifndef INVALID_VIDEO
    //播放门口机视频
    float fplayScale = 1.0;
    if ([UIScreen instancesRespondToSelector:@selector(scale)])
    {
        fplayScale = (CGFloat)[[UIScreen mainScreen] scale];
    }
    
    NSString *url = [self.video videoUrl];
    NSString *pubUrl = [self.video pubVideoUrl];
    
    NSLog(@"url:%@  pubUrl:%@",url,pubUrl);

    int ret = -1;
    int ret1 = -1;
    if (url) {
        ret = [zw_dssdk dssdk_rtv_start:(__bridge void *)(videoWnd):(char*)[url UTF8String] :fplayScale];
    }
    
    if (ret != 1 && pubUrl) {
        
        ret1 = [zw_dssdk dssdk_rtv_start:(__bridge void *)(videoWnd):(char*)[pubUrl UTF8String] :fplayScale];
        
    }
    
    
    if (ret == 1 || ret1 == 1) {
//        isPlaying = YES;
//        playBtn.hidden = YES;
        
        
        //看视频的时候防止锁屏
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
    }
    else {
        NSString *msg = [NSString stringWithFormat:@"%@(错误码:%d)\n%@(错误码:%d)",url,ret,pubUrl,ret1];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"打开视频失败" message:msg delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alert show];
        
//        isPlaying = NO;
//        playBtn.hidden = NO;
    }

    
    [[NSNotificationCenter defaultCenter] postNotificationName:PlayVideoNotification object:self];
    
#endif
    
    
}


//挂断
- (IBAction)hungup:(id)sender
{
    
    [self goBack];
}

//开锁
- (IBAction)unlock:(id)sender
{
   
    [[NetAPIClient sharedClient] unlockSuccessCallback:^{
        NSLog(@"开锁成功");
    }failureCallback:^{
        NSLog(@"开锁失败");
    }];
}

//接听
- (IBAction)answer:(id)sender
{

#ifndef INVALID_VIDEO
        int i =  [zw_dssdk dssdk_talk_start:(__bridge void *)(videoWnd)];
#endif

}

@end
