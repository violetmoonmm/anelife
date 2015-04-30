//
//  ServiceViewController.m
//  eLife
//
//  Created by mac on 14-3-17.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "ServiceViewController.h"
#import "VideoMonitorViewController.h"
#import "AppDelegate.h"
#import "EnergyViewController.h"
#import "Util.h"
//#import "MessageViewController.h"
#import "MessageServiceController.h"
#import "AlarmServiceController.h"
#import "MessageManager.h"
#import "NetAPIClient.h"
#import "NotificationDefine.h"
#import "DotView.h"
#import "ProgressView.h"
#import "EnvironmentalMonitoringController.h"


#define TAG_REDPOINT_ALARM 100
#define TAG_REDPOINT_MSG 101

@interface ServiceViewController ()
{
    IBOutlet UIView *iconView;
    IBOutlet UIScrollView *scrlView;
    
    IBOutlet UIButton *alarmBtn;
    IBOutlet UIButton *msgBtn;
    
    UIImageView *portraitView;//头像
    ProgressView *progressView;//网关在线数显示
   
}

@end

@implementation ServiceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
   
    [Util unifyStyleOfViewController:self withTitle:@"服务"];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    scrlView.contentSize = iconView.frame.size;
    
    [self registerNotification];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    [navController setNavigationBarHidden:YES];
    
    [self showUnreadAlarmMsg];
    [self showUnreadCommMsg];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


//#pragma mark 通知处理
//
//- (void)handleGetGatewaysNtf:(NSNotification *)ntf
//{
//    //先移除
//    for (SHGateway *gateway in _gateways)
//    {
//        [self removeObserveGateway:gateway];
//    }
//    [_gateways removeAllObjects];
//    
//    //再添加
//    if ([User currentUser].isLocalMode) {
//        [_gateways addObjectsFromArray:[SHLocalControl getInstance].gatewayList];
//    }
//    else {
//        [_gateways addObjectsFromArray:[NetAPIClient sharedClient].gatewayList];
//        
//    }
//    
//    [self refreshSubViews];
//    
//    for (SHGateway *gateway in _gateways)
//    {
//        [self observeGateway:gateway];
//    }
//    
//    
//    [self showNumOfOnlineGateways];
//}
//
//
//- (void)handleBindGatewayNtf:(NSNotification *)ntf
//{
//    
//    SHGateway *gateway = [[ntf userInfo] objectForKey:BindGatewayNotificationKey];
//    
//    [_gateways addObject:gateway];
//    
//    //注册观察者
//    [self observeGateway:gateway];
//    
//    [self refreshSubViews];
//    
//    [self associateCellWithGateway:gateway];
//    [self displayConnectStatusForCurrentPanel];
//    
//    [self showNumOfOnlineGateways];
//}
//
//- (void)handleEditGatewayNtf:(NSNotification *)ntf
//{
//    
//}
//
//- (void)handleRemoveGatewayNtf:(NSNotification *)ntf
//{
//    SHGateway *gateway = [[ntf userInfo] objectForKey:DelGatewayNotificationKey];
//    
//    [self removeAssociateCellWithGateway:gateway];
//    
//    
//    [_gateways removeObject:gateway];
//    [self removeObserveGateway:gateway];
//    
//    [self refreshSubViews];
//    
//    [self showNumOfOnlineGateways];
//}
//
//
//- (void)handleRefreshGatewaysNtf:(NSNotification *)ntf
//{
//    for (SHGateway *gateway in _gateways)
//    {
//        
//        [self removeAssociateCellWithGateway:gateway];
//    }
//}


//- (void)customNavigationBar
//{
//    
//    [Util unifyStyleOfViewController:self withTitle:@"服务"];
//    
////    //右边按钮
////    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
////    addBtn.frame = CGRectMake(0, 0, 44, 44);
////    [addBtn addTarget:self action:@selector(chooseAGateway) forControlEvents:UIControlEventTouchUpInside];
////    [addBtn setImage:[UIImage imageNamed:@"EditBtn"] forState:UIControlStateNormal];
////    //    [returnBtn setTitle:@"添加" forState:UIControlStateNormal];
////    UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithCustomView:addBtn];
////    self.navigationItem.rightBarButtonItem = rightBtnItem;
//    
//    
//    //头像边框
//    UIImageView *portraitBgdView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 4, 30, 30)];
//    portraitBgdView.image = [UIImage imageNamed:@"PortraitFrame"];
//    [self.navigationController.navigationBar addSubview:portraitBgdView];
//    
//    
//    //头像
//    NSString *portraitName = [User currentUser].isLogin ? @"PortraitBlue" : @"PortraitGray";
//    
//    portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
//    portraitView.image = [UIImage imageNamed:portraitName];
//    [portraitBgdView addSubview:portraitView];
//    
//    
//    //线条
//    progressView  = [[ProgressView alloc] initWithFrame:CGRectMake(CGRectGetMinX(portraitBgdView.frame)-4, CGRectGetMaxY(portraitBgdView.frame)+2, CGRectGetWidth(portraitBgdView.frame)+8, 4)];
//    
//    [self.navigationController.navigationBar addSubview:progressView];
//    
//    [self showNumOfOnlineGateways];
//}

//- (void)showNumOfOnlineGateways
//{
//    NSInteger onlineNum = 0;
//    for (SHGateway *gateway in gateway)
//    {
//        if (gateway.status == GatewayStatusOnline) {
//            onlineNum++;
//        }
//        
//    }
//    
//    progressView.value = onlineNum;
//    progressView.maxValue = [gateways count];
//}



//视频监控
- (IBAction)viewVideoMonitor:(id)sender
{
    NSString *nibName = [Util nibNameWithClass:[VideoMonitorViewController class]];
    VideoMonitorViewController *viewController = [[VideoMonitorViewController alloc] initWithNibName:nibName bundle:nil];
    
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    
    [navController setNavigationBarHidden:NO];
    [navController pushViewController:viewController animated:YES];
    
}



//能耗管理
- (IBAction)energyConsumption:(id)sender
{
    NSString *nibName = [Util nibNameWithClass:[EnergyViewController class]];
    EnergyViewController *viewController = [[EnergyViewController alloc] initWithNibName:nibName bundle:nil];
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    
    [navController pushViewController:viewController animated:YES];
    [navController setNavigationBarHidden:NO];
}


//信息服务
- (IBAction)messageService:(id)sender
{
    NSString *nibName = [Util nibNameWithClass:[MessageServiceController class]];
    MessageServiceController *vc = [[MessageServiceController alloc] initWithNibName:nibName bundle:nil];
    
    vc.records = [MessageManager getInstance].commMsgArray;
    [[MessageManager getInstance] setAllCommMsgRead];
    
    [self showUnreadMsgOnTabBar];
    
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    [navController pushViewController:vc animated:YES];
    [navController setNavigationBarHidden:NO];
}


//报警服务
- (IBAction)alarmService:(id)sender
{
    NSString *nibName = [Util nibNameWithClass:[AlarmServiceController class]];
    AlarmServiceController *vc = [[AlarmServiceController alloc] initWithNibName:nibName bundle:nil];
    
    vc.records = [MessageManager getInstance].alarmMsgArray;
    [[MessageManager getInstance] setAllAlarmMsgRead];
    
    [self showUnreadMsgOnTabBar];
    
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    [navController pushViewController:vc animated:YES];
    [navController setNavigationBarHidden:NO];
}

//环境监测
- (IBAction)environmentMonitoring:(id)sender
{
    NSString *nibName = [Util nibNameWithClass:[EnvironmentalMonitoringController class]];
    EnvironmentalMonitoringController *viewController = [[EnvironmentalMonitoringController alloc] initWithNibName:nibName bundle:nil];
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    
    [navController pushViewController:viewController animated:YES];
    [navController setNavigationBarHidden:NO];
}

#pragma mark 通知处理

- (void)handleAlarmMsgNtf:(NSNotification *)ntf
{
    //AlarmRecord *msg = [[ntf userInfo] objectForKey:OnAlarmNotificationKey];
    

//    [self playMsgSound];
    
    [self showUnreadAlarmMsg];
    
    [self showUnreadMsgOnTabBar];
}


- (void)handleCommMsgNtf:(NSNotification *)ntf
{
//    CommunityMsg *msg = [[ntf userInfo] objectForKey:MQRecvCommunityMsgNotificationKey];
    
    [self playMsgSound];

    [self showUnreadCommMsg];
    
    [self showUnreadMsgOnTabBar];
}


- (void)handleCommMsgReadNtf:(NSNotification *)nft
{
    [self showUnreadCommMsg];
    
    [self showUnreadMsgOnTabBar];
}

- (void)handleMsgReadyNtf:(NSNotification *)ntf
{
    [self showUnreadMsgOnTabBar];
}

- (void)showUnreadMsgOnTabBar
{
    if ([[MessageManager getInstance] totalUnreadMsgNum] > 0) {
        [(CustomTabBarController *)((AppDelegate *)[UIApplication sharedApplication].delegate).tabBarController displayTrackPoint:YES atIndex:2];
    }
    else {
        [(CustomTabBarController *)((AppDelegate *)[UIApplication sharedApplication].delegate).tabBarController displayTrackPoint:NO atIndex:2];
    }
    
}

- (void)showUnreadAlarmMsg
{
    
    UIView *point = [alarmBtn viewWithTag:TAG_REDPOINT_ALARM];
    
    if ([[MessageManager getInstance] unreadAlarmMsgNum] > 0) {
        
        if (!point) {
            point = [[DotView alloc] initWithFrame:CGRectMake(CGRectGetWidth(alarmBtn.frame)+1, -8, 10, 10)];

            point.tag = TAG_REDPOINT_ALARM;
        }
        
        [alarmBtn addSubview:point];

    }
    else {
        [point removeFromSuperview];
    }
    
//    [self showUnreadMsgOnTabBar];
}


- (void)showUnreadCommMsg
{
    UIView *point = [msgBtn viewWithTag:TAG_REDPOINT_MSG];
    
    if ([[MessageManager getInstance] unreadCommMsgNum] > 0) {
        
        if (!point) {
            point = [[DotView alloc] initWithFrame:CGRectMake(CGRectGetWidth(msgBtn.frame)+1, -8, 10, 10)];

            
            point.tag = TAG_REDPOINT_MSG;
        }
        
        [msgBtn addSubview:point];
        
    }
    else {
        [point removeFromSuperview];
    }
    
//     [self showUnreadMsgOnTabBar];
}

- (void)playMsgSound
{
    
    AudioServicesPlaySystemSound(1007);
}

- (void)registerNotification
{
    //报警信息通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAlarmMsgNtf:) name:OnAlarmNotification object:nil];
    
    //社区信息通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCommMsgNtf:) name:MQRecvCommunityMsgNotification object:nil];
    
    //消息数据ready
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMsgReadyNtf:) name:MessageReadyNotification object:nil];
    
    //公共消息已读
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCommMsgReadNtf:) name:CommMsgReadNotification object:nil];
}

@end
