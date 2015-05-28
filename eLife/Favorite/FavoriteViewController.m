//
//  FavoriteViewController.m
//  eLife
//
//  Created by mac on 14-8-21.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "FavoriteViewController.h"
#import "NetAPIClient.h"
#import "NotificationDefine.h"
#import "BasicCurtainCell.h"
#import "BasicLampCell.h"
#import "BasicHumitureCell.h"
#import "BasicAirConditionCell.h"
#import "BasicVideoCell.h"
#import "AppDelegate.h"
#import "NetAPIClient.h"
#import "Util.h"
#import "BasicCell.h"
#import "BasicEnvironmentListCell.h"
#import "BasicEnvironmentCell.h"
#import "BasicStateCell.h"
#import "BasicSceneCell.h"
#import "BasicEnergyCell.h"
#import "BasicVideoEntryCell.h"
#import "BasicInfoEntryCell.h"
#import "VideoMonitorViewController.h"
#import "PublicDefine.h"
#import "GatewayListViewController.h"
#import "Reachability.h"
#import "PanelEditViewController.h"
#import "PublicDefine.h"
#import "PanelView.h"
#import "NetReachability.h"
#import "MessageServiceController.h"
#import "EnvironmentalMonitoringController.h"
#import "MessageManager.h"
#import "ProgressView.h"
#import "MBProgressHUD.h"
#import "SceneCell.h"
#import "DBManager.h"


#define PAGE_NUM 2 //页面数


#define PROMPT_VIEW_HEIGHT 38

#define INVALID_INDEX -1

#define TAG_DISCONNECT_LABEL 100


static NSString *const kIconDirPath = @"kIconDirPath";
static NSString *const kIconConfig = @"kIconConfig";


CGRect FrameFromLayout(int column, int columnSpan, int row , int rowSpan, int columnCount, int rowCount);

@interface FavoriteViewController () <UIScrollViewDelegate,BasicVideoEntryCellDelegate,BasicInfoEntryCellDelegate,BasicEnvironmentListCellDelegate>
{
    NSMutableArray *subViews;
    

    UIScrollView *scrlView;
    UIPageControl *pageCtrl;
    
    NSMutableArray *_gateways;
    
    UIView *_promptView;


    UIView *bgdView;
    
    NSMutableArray *panelViews;

    
    MBProgressHUD *hud;

    
    UILabel *guideView;//提示
    
    UIImageView *portraitView;//头像
    ProgressView *progressView;//网关在线数显示
    
    NSMutableDictionary *styleResource;//主题资源

}

- (CGRect)frameFromLayoutCoulumn:(int)column columnSpan:(int)columnSpan row:(int)row rowSpan:(int)rowSpan columnCount:(int)columnCount rowCount:(int)rowCount;

@end

@implementation FavoriteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
      
        
        subViews = [NSMutableArray arrayWithCapacity:1];
        
        _gateways = [NSMutableArray arrayWithCapacity:1];
        
    
        panelViews = [NSMutableArray arrayWithCapacity:1];
       
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    

    if (![Util clientIsLastVersion]) {
        [(CustomTabBarController *)((AppDelegate *)[UIApplication sharedApplication].delegate).tabBarController displayTrackPoint:YES atIndex:3];
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }


    [self readStyleResource];

    
    [_gateways removeAllObjects];
    [_gateways addObjectsFromArray:[NetAPIClient sharedClient].gatewayList];
    
    [self customNavigationBar];
    [self showNumOfOnlineGateways];
    
    [self setupSubviews];
    
    [self readPanelConfigFiles];
    
    [self refreshSubViews];
    
    [self displayConnectStatusForCurrentPanel];
    
    for (SHGateway *gateway in _gateways) {
        
        if (gateway.getConfigStep == GetConfigStepFinished)
        {
            [self associateCellWithGateway:gateway];
        }
        
    }
    
    [self registerNotification];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    NSLog(@"viewWillAppear bounds %@",NSStringFromCGRect(self.view.bounds));
    
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    
    [navController setNavigationBarHidden:YES animated:NO];
    
    
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    CGSize ctsize = scrlView.contentSize;
    ctsize.height = CGRectGetHeight(scrlView.bounds);
    scrlView.contentSize = ctsize;
    
//    NSLog(@"viewDidAppear bounds %@",NSStringFromCGRect(self.view.bounds));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"FavoriteController didReceiveMemoryWarning");
}

- (void)dealloc
{

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark 通知处理



- (void)handleGetGatewayConfigStepNtf:(NSNotification *)ntf
{
    SHGateway *gateway = ntf.object;
    NSDictionary *userInfo = [ntf userInfo];
    NSInteger step = [[userInfo objectForKey:GetGatewayConfigStepNotificationKey] integerValue];
    
    if (step == GetConfigStepFinished) {
        [self associateCellWithGateway:gateway];
    }
}

- (void)handleGatewayStatusChangeNtf:(NSNotification *)ntf
{
    SHGateway *gateway = ntf.object;
    GatewayState preState = [[[ntf userInfo] objectForKey:GatewayPreviousStateKey] integerValue];
    
    
    if ((preState == GatewayStatusOffline || preState == GatewayStatusLoginFailed) && [gateway isOnline]) {
        
        MBProgressHUD *tip = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:tip];
        tip.removeFromSuperViewOnHide = YES;
        tip.labelText = [NSString stringWithFormat:@"网关(%@)连接恢复正常",gateway.name];
        tip.labelFont = [UIFont systemFontOfSize:15];
        tip.mode = MBProgressHUDModeText;
        [tip show:YES];
        [tip hide:YES afterDelay:2.0];
        
    }
    
    
    [self showNumOfOnlineGateways];
    [self displayConnectStatusForCurrentPanel];
}


- (void)handleGetDevicesReadyNtf:(NSNotification *)ntf
{
//    for (SHGateway *gateway in _gateways) {
//        [self associateCellWithGateway:gateway];
//    }
    

}



- (void)reachabilityChanged:(NSNotification *)ntf
{
    
//    Reachability *reach = ntf.object;
//    
//    
//    isReachable = reach.isReachable;
    

    [self displayConnectStatusForCurrentPanel];
}

- (void)appDidEnterBackground:(NSNotification*)ntf
{

}

- (void)handleGetGatewaysNtf:(NSNotification *)ntf
{
    
//    //先移除
//
//    [_gateways removeAllObjects];
//    
//    //再添加
//    
//    [_gateways addObjectsFromArray:[NetAPIClient sharedClient].gatewayList];
//    
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
}


- (void)handleBindGatewayNtf:(NSNotification *)ntf
{

    SHGateway *gateway = [[ntf userInfo] objectForKey:BindGatewayNotificationKey];
    
    [_gateways addObject:gateway];
    
    
    [self refreshSubViews];
    

    [self displayConnectStatusForCurrentPanel];
    
    [self showNumOfOnlineGateways];
}

- (void)handleEditGatewayNtf:(NSNotification *)ntf
{
    BOOL needRefresh = [[[ntf userInfo] objectForKey:NeedRefreshGatewayKey] boolValue];
    
    if (needRefresh) {
        [self refreshSubViews];
        
        [self displayConnectStatusForCurrentPanel];
        
        [self showNumOfOnlineGateways];
    }
    
}

- (void)handleRemoveGatewayNtf:(NSNotification *)ntf
{
    SHGateway *gateway = [[ntf userInfo] objectForKey:DelGatewayNotificationKey];

    [self removeAssociateCellWithGateway:gateway];
    
  
    [_gateways removeObject:gateway];
    
    
    [self refreshSubViews];
    
    [self showNumOfOnlineGateways];
}

- (void)handleMQConnectStatusNtf:(NSNotification *)ntf
{
    NSString *obj = [ntf object];
    
    if ([obj isEqualToString:@"Connected"]) {
        portraitView.image = [UIImage imageNamed:@"PortraitBlue"];
    }
    else {
        portraitView.image = [UIImage imageNamed:@"PortraitGray"];
    }
}


- (void)handleQueryDeviceStatusNtf:(NSNotification *)ntf
{
    
}

#pragma mark 其他方法

- (void)registerNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBindGatewayNtf:) name:BindGatewayNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRemoveGatewayNtf:) name:DelGatewayNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEditGatewayNtf:) name:EditGatewayNotication object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGetGatewaysNtf:) name:GetGatewayListNotification object:nil];
    
    //        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDownloadConfigNtf:) name:FtpDownloadConfigNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGetGatewayConfigStepNtf:) name:GetGatewayConfigStepNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMQConnectStatusNtf:) name:MQConnectStatusNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGatewayStatusChangeNtf:) name:GatewayStatusChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleQueryDeviceStatusNtf:) name:QueryDeviceStatusNotification object:nil];
}

- (void)readStyleResource
{
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *styleDir = [docDir stringByAppendingPathComponent:STYLE_DIR];
    NSError *error;
    
    NSArray *subDirArray =  [[NSFileManager defaultManager] contentsOfDirectoryAtPath:styleDir error:&error];
    
    if (error) {
        NSLog(@"readStyleResource error %@",[error description]);
    }
    
    styleResource = [NSMutableDictionary dictionaryWithCapacity:1];
    
    for (NSString *subDirName in subDirArray)
    {
    
        NSString *subDir = [styleDir stringByAppendingPathComponent:subDirName];
        
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:subDir error:&error];
        
        for (NSString *fileName in files) {
            
            if ([fileName hasSuffix:@"txt"]) {//配置文件
                
                NSString *filePath = [subDir stringByAppendingPathComponent:fileName];
                
                NSDictionary *dataDic = [self readConfigFileAtPath:filePath];
                
                if (dataDic) {
                    
                    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:subDir,kIconDirPath,dataDic,kIconConfig, nil];
                    
                    [styleResource setObject:dic forKey:subDirName];
                }

                
            }
        }
        
    }

}


- (void)enterPanelEdit
{
    NSString *nibName = [Util nibNameWithClass:[PanelEditViewController class]];
    
    PanelEditViewController *viewController = [[PanelEditViewController alloc] initWithNibName:nibName bundle:nil];
    viewController.delegate = self;
    
    NSArray *panelsArray = [self panelNames];
    
    [viewController setPanels:panelsArray];
    
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    
    [navController setNavigationBarHidden:NO];
    [navController pushViewController:viewController animated:YES];

}


- (void)enterBindGateway
{
    NSString *nibName = [Util nibNameWithClass:[GatewayListViewController class]];
    GatewayListViewController *viewController = [[GatewayListViewController alloc] initWithNibName:nibName bundle:nil];
    
    //隐藏主导航栏
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    
    [navController setNavigationBarHidden:NO];
    
    [navController pushViewController:viewController animated:YES];
}

- (int)indexForPanel:(NSString *)panel
{
    
    NSDictionary *config = [[DBManager defaultManager] queryPanelConfig];
    
    NSMutableDictionary *dic = [config objectForKey:panel];
    
    id indexObj = [dic objectForKey:KEY_INDEX];
    if ([indexObj isKindOfClass:[NSNumber class]]) {
        
        return [indexObj intValue];
    }
    
    return INVALID_INDEX;
}



- (void)refreshSubViews
{
    
    NSInteger pageNum = [self numberOfPanels];
    
    scrlView.contentSize = CGSizeMake(CGRectGetWidth(scrlView.bounds)*pageNum, CGRectGetHeight(scrlView.bounds));
    pageCtrl.numberOfPages = pageNum;
    
    if (pageNum > 0 && [[NetAPIClient sharedClient] numberOfGateways] > 0) {
         [self hideGuideView];
    }
    else if ([[NetAPIClient sharedClient] numberOfGateways] == 0) {
        [self showGuideViewWithText:@"点击添加网关"];
    }
    else {
        [self showGuideViewWithText:@"点击添加面板"];
    }
}


- (void)showGuideViewWithText:(NSString *)text
{
    if (!guideView) {
        
        UIFont *font = [UIFont systemFontOfSize:19];
    
        CGSize size = CGSizeMake(180, 50);
        
        guideView = [[UILabel alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.view.bounds)-size.width)/2, (CGRectGetHeight(self.view.bounds)-size.height)/2, size.width, size.height)];
        guideView.backgroundColor = [UIColor clearColor];
        guideView.textAlignment = NSTextAlignmentCenter;
        guideView.font = font;
     
        guideView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        guideView.userInteractionEnabled = YES;
        [self.view addSubview:guideView];
        
        UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(linkGuidView:)];
        [guideView addGestureRecognizer:gest];
    }
    
    guideView.hidden = NO;
    pageCtrl.hidden = YES;
    scrlView.hidden = YES;
    
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] initWithString:text];
    NSRange contentRange = {0, [content length]};
   
    [content addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:contentRange];
     guideView.attributedText = content;
    

    [self displaySHDsiconnectView:NO reason:nil];
}

- (void)hideGuideView
{
    pageCtrl.hidden = NO;
    scrlView.hidden = NO;

    guideView.hidden = YES;

}

- (void)linkGuidView:(id)sender
{
    if ([[NetAPIClient sharedClient] numberOfGateways] == 0) {
        [self enterBindGateway];
    }
    else {
        [self enterPanelEdit];
    }
}





- (void)associateCellWithGateway:(SHGateway *)gateway
{
    NSLog(@"associateCellWithDevice subView count:%d",[subViews count]);
    
    for (BasicCell *cell in subViews)
    {
        if ((NSOrderedSame == [cell.gatewayId compare:gateway.serialNumber options:NSCaseInsensitiveSearch])) {
            
            if ([cell isKindOfClass:[BasicVideoCell class]]) {
                
                [cell associateWithDevices:gateway.ipcArray];

            }
            else if ([cell isKindOfClass:[BasicSceneCell class]]) {
                [cell associateWithDevices:gateway.sceneModeArray];
            }
            else if ([cell isKindOfClass:[SceneCell class]]) {
                [cell associateWithDevices:gateway.sceneModeArray];
            }
            else if ([cell isKindOfClass:[BasicEnvironmentListCell class]]) {
                [cell associateWithDevices:gateway.envMonitorArray];
            }
            else if ([cell isKindOfClass:[BasicEnvironmentCell class]]) {
                [cell associateWithDevices:gateway.envMonitorArray];
            }
            else if ([cell isKindOfClass:[BasicEnergyCell class]]) {
                [cell associateWithDevices:gateway.ammeterArray];
                
                NSArray *commLight = [gateway devicesForType:SH_DEVICE_COMMLIGHT];
                NSArray *levelLight = [gateway devicesForType:SH_DEVICE_LEVELLIGHT];
                NSArray *curtain = [gateway devicesForType:SH_DEVICE_CURTAIN];
                NSArray *ac = [gateway devicesForType:SH_DEVICE_AIRCONDITION];
                NSArray *sokect = [gateway devicesForType:SH_DEVICE_SOCKET];
                NSArray *groundHeat = [gateway devicesForType:SH_DEVICE_GROUNDHEAT];
                
                NSMutableArray *arr = [NSMutableArray arrayWithArray:commLight];
                [arr addObjectsFromArray:levelLight];
                [arr addObjectsFromArray:curtain];
                [arr addObjectsFromArray:ac];
                [arr addObjectsFromArray:sokect];
                [arr addObjectsFromArray:groundHeat];
 
                [(BasicEnergyCell *)cell setDisplayDevices:arr];
                
            }
            else if ([cell isKindOfClass:[BasicStateCell class]]) {
//                [(BasicStateCell *)cell associateWithDevices:gateway.ammeterArray];
                
                NSArray *commLight = [gateway devicesForType:SH_DEVICE_COMMLIGHT];
                NSArray *levelLight = [gateway devicesForType:SH_DEVICE_LEVELLIGHT];
                NSMutableArray *arr = [NSMutableArray arrayWithArray:commLight];
                [arr addObjectsFromArray:levelLight];
                [(BasicStateCell *)cell setDisplayDevices:arr];
                
            }
            
            else {
                [cell associateWithDevices:gateway.deviceArray];
                
            }
        }
    }
}


- (void)removeAssociateCellWithGateway:(SHGateway *)gateway
{
    for (BasicCell *cell in subViews)
    {
        if (cell.device && (NSOrderedSame ==  [cell.gatewayId compare:gateway.serialNumber options:NSCaseInsensitiveSearch])) {
            cell.device = nil;
            
            NSLog(@"removeAssociateCell devid %@",cell.deviceId);

        }
    }
}




//显示连接状态
- (void)displayConnectStatusForCurrentPanel
{
    
    if ([NetReachability isNetworkReachable]) {
        
        int page = pageCtrl.currentPage;
        NSString *gatewaySn = nil;
        for (PanelView *view in panelViews)
        {
            if (view.index == page) {
                gatewaySn = view.gatewayId;
                break;
            }
        }
        
        SHGateway *gateway = nil;
        
        for (SHGateway *temGateway in _gateways)
        {
            if (NSOrderedSame == [temGateway.serialNumber compare:gatewaySn options:NSCaseInsensitiveSearch]) {
                gateway = temGateway;
                break;
            }
        }

        if ([panelViews count] > 0 && !scrlView.hidden) {
            if (gateway) {
                if (gateway.status.state != GatewayStatusInit) {
                    if (![gateway isOnline]) {
                        NSString *msg = [self errorMsgForGateway:gateway];
                        
                        [self displaySHDsiconnectView:YES reason:msg];
                    }
                    else if (!gateway.authorized) {
                        
                        [self displaySHDsiconnectView:YES reason:[NSString stringWithFormat:@"网关(%@)认证无效,请重新认证后再试",gateway.name]];
                        
                    }
                    else {
                        [self displaySHDsiconnectView:NO reason:nil];
                    }
                }
            }
            else {//没有网关
                [self displaySHDsiconnectView:YES reason:[NSString stringWithFormat:@"网关(%@)不存在,请添加网关或删除此常用界面",gatewaySn]];
            }
        }
        else {
            [self displaySHDsiconnectView:NO reason:nil];
        }
  
    }
    else {
        [self displaySHDsiconnectView:YES reason:@"当前网络不可用，请检查后再试"];
    }
    
    
}

- (NSString *)errorMsgForGateway:(SHGateway *)gateway
{
    NSString *msg = nil;
    NSInteger errorCode = gateway.disconnectReason;


    if (DisRe_UserInvalid == errorCode || DisRe_PasswordInvalid == errorCode)
    {
        msg = [NSString stringWithFormat:@"网关(%@)离线,请检查网关设置后再试",gateway.name];
    }
    else if (DisRe_SerialNoInvalid == errorCode || DisRe_AuthCodeInvalid == errorCode
             || DisRe_AuthFailed == errorCode || DisRe_NotAuthMode == errorCode
             || DisRe_OutOfAuthLimit == errorCode)
    {
        msg = [NSString stringWithFormat:@"网关(%@)认证无效,请重新认证后再试",gateway.name];
    }
    else {
        msg = [NSString stringWithFormat:@"网关(%@)离线,请检查网络后再试",gateway.name];
    }
    
    return msg;
}




- (void)displaySHDsiconnectView:(BOOL)yesOrNo reason:(NSString *)reason
{
    
    if (yesOrNo) {//显示断线

        
        if (!_promptView) {
            _promptView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), PROMPT_VIEW_HEIGHT)];
            _promptView.backgroundColor = [UIColor colorWithRed:255/255. green:243/255. blue:207/255. alpha:1];
            
            NSInteger markSize = 24;
            UIImageView *markView = [[UIImageView alloc] initWithFrame:CGRectMake(10, (PROMPT_VIEW_HEIGHT-markSize)/2, markSize, markSize)];
            markView.image = [UIImage imageNamed:@"operationbox_fail_web"];
            markView.backgroundColor = [UIColor clearColor];
            [_promptView addSubview:markView];
            
            NSString *text = reason;
            UIFont *font = [UIFont systemFontOfSize:14];
            
            UILabel *hintText = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(markView.frame)+4, 0, CGRectGetWidth(_promptView.frame)-CGRectGetMaxX(markView.frame), PROMPT_VIEW_HEIGHT)];
            hintText.backgroundColor = [UIColor clearColor];
            hintText.numberOfLines = 0;
            hintText.textColor = [UIColor blackColor];
            hintText.font = font;
            hintText.text = text;
            hintText.tag = TAG_DISCONNECT_LABEL;
            [_promptView addSubview:hintText];
        
            [self.view addSubview:_promptView];
            
            //添加点击响应
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDisconnectView)];
            [_promptView addGestureRecognizer:tapGesture];
        }
        
        UILabel *hintText = (UILabel *)[_promptView viewWithTag:TAG_DISCONNECT_LABEL];
        hintText.text = reason;
        
        CGRect f =  scrlView.frame;
        f.origin.y = PROMPT_VIEW_HEIGHT;
        scrlView.frame = f;
        
//        CGRect promptViewFrame = _promptView.frame;
//        promptViewFrame.origin.y = 0;
//        _promptView.frame = promptViewFrame;
        

        _promptView.hidden = NO;
        
    }
    else  {//隐藏断线连接提示
        
        
        CGRect f =  scrlView.frame;
        f.origin.y = 0;
        scrlView.frame = f;

        
//        CGRect promptViewFrame = _promptView.frame;
//        promptViewFrame.origin.y = -PROMPT_VIEW_HEIGHT;
//        _promptView.frame = promptViewFrame;
        
        _promptView.hidden = YES;
        
    }

}


- (void)tapDisconnectView
{
    NSString *nibName = [Util nibNameWithClass:[GatewayListViewController class]];
    GatewayListViewController *viewController = [[GatewayListViewController alloc] initWithNibName:nibName bundle:nil];
    
    //隐藏主导航栏
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    
    [navController setNavigationBarHidden:NO];
    
    [navController pushViewController:viewController animated:YES];
}







- (void)customNavigationBar
{
    
    [Util unifyStyleOfViewController:self withTitle:@"常用"];
    
    
    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    addBtn.frame = CGRectMake(0, 0, 44, 44);
    [addBtn addTarget:self action:@selector(enterPanelEdit) forControlEvents:UIControlEventTouchUpInside];
    [addBtn setImage:[UIImage imageNamed:@"EditBtn"] forState:UIControlStateNormal];
    //    [returnBtn setTitle:@"添加" forState:UIControlStateNormal];
    UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithCustomView:addBtn];
    self.navigationItem.rightBarButtonItem = rightBtnItem;
    
    
     //头像边框
    UIImageView *portraitBgdView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 4, 30, 30)];
    portraitBgdView.image = [UIImage imageNamed:@"PortraitFrame"];
    [self.navigationController.navigationBar addSubview:portraitBgdView];
    
   
    //头像
    NSString *portraitName =  [NetAPIClient sharedClient].MQConnected ? @"PortraitBlue" : @"PortraitGray";
    
    portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    portraitView.image = [UIImage imageNamed:portraitName];
    [portraitBgdView addSubview:portraitView];
    
    
    //线条
    progressView  = [[ProgressView alloc] initWithFrame:CGRectMake(CGRectGetMinX(portraitBgdView.frame)-4, CGRectGetMaxY(portraitBgdView.frame)+2, CGRectGetWidth(portraitBgdView.frame)+8, 4)];
   
    [self.navigationController.navigationBar addSubview:progressView];

    [self showNumOfOnlineGateways];
}




- (void)showNumOfOnlineGateways
{
    NSInteger onlineNum = 0;
    for (SHGateway *gateway in _gateways)
    {
        if ([gateway isOnline]) {
            onlineNum++;
        }
        
    }
    
    progressView.value = onlineNum;
    progressView.maxValue = [_gateways count];
}

- (NSDictionary *)readConfigFileAtPath:(NSString *)filePath
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return nil;
    }
    
    NSDictionary *dic = nil;
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:&error];
    NSString *str = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (data) {
        dic = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        
        
    }
    
    return dic;
}

- (NSInteger)numberOfPanels
{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    
//    NSString *documentDirectory = [paths objectAtIndex:0];
    
    NSString *panelDir = [USERDIR stringByAppendingPathComponent:PANEL_DIR];//panel 目录
    
    NSError *error;
    
    NSArray *subDirArray =  [[NSFileManager defaultManager] contentsOfDirectoryAtPath:panelDir error:&error];
    
    return [subDirArray count];
}

- (void)setupSubviews
{
    
    NSInteger pageNum = [self numberOfPanels];
    
    if (!scrlView) {
        scrlView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
        scrlView.backgroundColor = [UIColor clearColor];
       
        scrlView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds)*pageNum, CGRectGetHeight(self.view.bounds));
        scrlView.showsHorizontalScrollIndicator = NO;
        scrlView.showsVerticalScrollIndicator = NO;
        scrlView.pagingEnabled = YES;
        scrlView.delegate = self;
        scrlView.bounces = NO;
        scrlView.autoresizesSubviews = YES;
        scrlView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:scrlView];
    }
    

    if (!pageCtrl) {
        pageCtrl = [[UIPageControl alloc] initWithFrame: CGRectMake(0.0f, CGRectGetHeight(self.view.bounds)-30.0f, CGRectGetWidth(self.view.bounds), 20.0f)];
        pageCtrl.hidesForSinglePage = YES;
        pageCtrl.numberOfPages = pageNum;
        pageCtrl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:pageCtrl];
        [pageCtrl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventTouchUpInside];
    }


}


- (NSArray *)panelNames
{
    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    
//    NSString *documentDirectory = [paths objectAtIndex:0];
    
    NSString *panelDir = [USERDIR stringByAppendingPathComponent:PANEL_DIR];//panel 目录
    
    NSError *error;
    
    NSArray *subDirArray =  [[NSFileManager defaultManager] contentsOfDirectoryAtPath:panelDir error:&error];
    
    return subDirArray;
    
}

- (void)readPanelConfigFiles
{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    
//    NSString *documentDirectory = [paths objectAtIndex:0];
    
    
    NSString *panelDir = [USERDIR stringByAppendingPathComponent:PANEL_DIR];//panel 目录
    
    NSError *error;
    
    NSArray *subDirArray =  [[NSFileManager defaultManager] contentsOfDirectoryAtPath:panelDir error:&error];
    
    if (error) {
        NSLog(@"readPanelConfigFiles error %@",[error description]);
    }
    

    
    for (NSString *subDirName in subDirArray)
    {
        NSString *subDir = [panelDir stringByAppendingPathComponent:subDirName];
        
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:subDir error:&error];
        
        for (NSString *fileName in files) {
            
            if ([fileName hasSuffix:@"txt"]) {
                
                NSString *filePath = [subDir stringByAppendingPathComponent:fileName];
                
                NSDictionary *dataDic = [self readConfigFileAtPath:filePath];
                
                if (dataDic) {

                    [self drawPanelViewWithData:dataDic dirName:subDirName];
        
                }
                
            }
        }

    }
   
}


- (void)drawPanelViewWithData:(NSDictionary *)dataDic dirName:(NSString *)dirName
{
    
    int index = [self indexForPanel:dirName];
   
    [self drawPanelViewWithData:dataDic dirName:dirName atIndex:index];
}

- (void)drawPanelViewWithData:(NSDictionary *)dataDic dirName:(NSString *)dirName atIndex:(NSInteger)index
{
    NSLog(@"drawPanelViewWithData %@",dirName);
    
    NSNumber *columnCount = [dataDic objectForKey:@"columnCount"];
    NSNumber *rowCount = [dataDic objectForKey:@"rowCount"];
    NSString *gatewayId = [dataDic objectForKey:@"gatewaySn"];
    
    NSDictionary *panel = [dataDic objectForKey:@"panel"];
    NSNumber *nId = [panel objectForKey:@"id"];
    NSString *name = [panel objectForKey:@"name"];
    NSString *bgdImg = [panel objectForKey:@"background"];

    
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(scrlView.bounds), CGRectGetHeight(scrlView.bounds));
    frame.origin.x = CGRectGetWidth(frame) * index;


    
    UIImage *image = [UIImage imageNamed:bgdImg];

    PanelView *panelView = [[PanelView alloc] initWithFrame:frame];
    panelView.index = index;
    panelView.name = dirName;
    panelView.gatewayId = gatewayId;
    panelView.image = image;
    panelView.userInteractionEnabled = YES;
    panelView.backgroundColor = [UIColor clearColor];
    panelView.autoresizesSubviews = YES;
    panelView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [panelViews addObject:panelView];
    
    [scrlView addSubview:panelView];
    
    
    NSArray *cells = [panel objectForKey:@"cells"];
    
    for (NSDictionary *cell in cells)
    {
        NSNumber *column = [cell objectForKey:@"layout_column"];
        NSNumber *columnSpan = [cell objectForKey:@"layout_columnSpan"];
        NSNumber *row = [cell objectForKey:@"layout_row"];
        NSNumber *rowSpan = [cell objectForKey:@"layout_rowSpan"];
        NSString *devName = [cell objectForKey:@"name"];
        
        NSString *className = [cell objectForKey:@"class_path"];
        Class cls = NSClassFromString(className);
        
        NSString *iconDirPath = nil;
        NSDictionary *iconConfig = nil;
        
        NSString *icon = [cell objectForKey:@"icon"];
        NSArray *comps = [icon componentsSeparatedByString:@"."];
        if ([comps count] == 2) {
            NSString *styleName = [comps objectAtIndex:0];
            NSString *iconName = [comps objectAtIndex:1];
            
            NSDictionary *tempDic = [styleResource objectForKey:styleName];
            
            iconDirPath = [tempDic objectForKey:kIconDirPath];
            iconConfig = [[tempDic objectForKey:kIconConfig] objectForKey:iconName];
        }
        
        
        CGRect frame = [self frameFromLayoutCoulumn:[column intValue] columnSpan:[columnSpan intValue] row:[row intValue] rowSpan:[rowSpan intValue] columnCount:[columnCount intValue] rowCount:[rowCount intValue]];
        
        
        NSMutableArray *elements = [NSMutableArray arrayWithCapacity:1];
        
        id params = [cell objectForKey:@"params"];
        if ([params isKindOfClass:[NSArray class]]) {
            
            for (NSDictionary *tempParam in params)
            {
                NSArray *pairs = [tempParam objectForKey:@"pairs"];
                
                NSMutableDictionary *paramDic = [NSMutableDictionary dictionaryWithCapacity:1];
                [elements addObject:paramDic];
                
                for (NSDictionary *paramPair in pairs)
                {
                    
                    NSString *name = [paramPair objectForKey:@"name"];
                    NSString *value = [paramPair objectForKey:@"value"];
                    
                    [paramDic setObject:value forKey:name];
                    
                }
                
            }

        }
        
        
        if ([[cls class] isSubclassOfClass:[BasicCell class]]) {
            id subView = [[cls alloc] initWithFrame:frame];
            
            [(BasicCell *)subView setName:devName];
            [(BasicCell *)subView setElements:elements];
            [(BasicCell *)subView setStyleIcons:iconConfig];
            [(BasicCell *)subView setStyleDirPath:iconDirPath];
            
            [panelView addSubview:subView];
            
            [subViews addObject:subView];
            

            if ([subView isKindOfClass:[BasicVideoEntryCell class]]) {
                [(BasicVideoEntryCell *)subView setDelegate:self];
            }
            else if ([subView isKindOfClass:[BasicInfoEntryCell class]]) {
                [(BasicInfoEntryCell *)subView setDelegate:self];
            }
            else if ([subView isKindOfClass:[BasicEnvironmentListCell class]]) {
                [(BasicEnvironmentListCell *)subView setDelegate:self];
            }
        }
    }
    
    
    //NSLog(@"drawPanelViewWithData end %@",name);
    
    
}

- (CGRect)frameFromLayoutCoulumn:(int)column columnSpan:(int)columnSpan row:(int)row rowSpan:(int)rowSpan columnCount:(int)columnCount rowCount:(int)rowCount
{
    if (columnCount > 0 && rowCount > 0) {
        CGRect bounds = self.view.bounds;
        CGSize size = bounds.size;
        size.height = [UIScreen mainScreen].bounds.size.height - 20 - 44 - 48;//由于主导航栏隐藏显示的原因，self.view.bounds会随着改变，绘制cell高度可能不准，故通过计算得来高度
        
        
        CGFloat xUnit = size.width/columnCount;//x轴单元格宽度
        
        CGFloat yUnit = size.height/rowCount;//y轴单元格宽度
        
        CGRect frame = CGRectMake(xUnit*column, yUnit*row,xUnit*columnSpan, yUnit*rowSpan);
        //NSLog(@"frame %@",NSStringFromCGRect(frame));
        
        return frame;
    }
    
    return CGRectZero;
}


- (void)hideWaitingStatus
{
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [hud hide:YES];
}

- (void)showWaitingStatus
{
    NSLog(@"showWaitingStatus");
    
    
    [hud hide:YES];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"请稍后...";
    hud.mode = MBProgressHUDModeIndeterminate;
    [hud show:YES];
    
    [self performSelector:@selector(reqTimeout) withObject:nil afterDelay:8];
    
    
}

- (void)reqTimeout
{
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"请求超时!";
    

    [hud hide:YES afterDelay:1.5];
    
    
}


#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat pageWidth = scrlView.frame.size.width;
    int page = floor((scrlView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    pageCtrl.currentPage = page;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    NSLog(@"%s",__FUNCTION__);
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"%s",__FUNCTION__);
    
//    int page = ceil(scrollView.contentOffset.x/CGRectGetWidth(scrollView.frame)) ;
//
//    NSString *panelName = [self titleForIndex:page];
//
//    if (panelName) {
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//
//        NSString *documentDirectory = [paths objectAtIndex:0];
//
//        NSString *panelDir = [documentDirectory stringByAppendingPathComponent:PANEL_DIR];//panel 目录
//
//        NSString *configDir = [panelDir stringByAppendingPathComponent:panelName];
//
//        NSString *thumbnailPath = [configDir stringByAppendingPathComponent:THUMBNAIL];
//
//        if (![[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath]) {
//            UIImage *image = [self captureScreen];
//
//            NSData *data = UIImagePNGRepresentation(image);
//
//            [data writeToFile:thumbnailPath atomically:NO];
//        }
//        
//        
//        
//    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"%s",__FUNCTION__);
    
    int page = ceil(scrollView.contentOffset.x/CGRectGetWidth(scrollView.frame)) ;
   
    [self displayConnectStatusForCurrentPanel];
    
    [self captureScreenForIndex:page];

}


- (void)captureScreenForCurrentIndex
{
    int index = pageCtrl.currentPage;
    
    [self captureScreenForIndex:index];
}


- (void)captureScreenForIndex:(NSInteger)index
{
    NSString *panelName = [self titleForIndex:index];
    
    if (panelName) {
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        
//        NSString *documentDirectory = [paths objectAtIndex:0];
        
        NSString *panelDir = [USERDIR stringByAppendingPathComponent:PANEL_DIR];//panel 目录
        
        NSString *configDir = [panelDir stringByAppendingPathComponent:panelName];
        
        NSString *thumbnailPath = [configDir stringByAppendingPathComponent:THUMBNAIL];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath]) {
            UIImage *image = [self captureScreen];
            
            NSData *data = UIImagePNGRepresentation(image);
            
            [data writeToFile:thumbnailPath atomically:NO];
        }
        
        
        
    }
}

- (NSString *)titleForIndex:(NSInteger)index
{
    
    for (PanelView *view in panelViews)
    {
        if (view.index ==  index) {
            return view.name;
        }
    }
    
    return nil;
}

- (UIImage *)captureScreen
{
    UIGraphicsBeginImageContext(self.view.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:context];
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return theImage;
}

- (void)changePage:(id)sender
{
    int page = pageCtrl.currentPage;

    [scrlView setContentOffset:CGPointMake(CGRectGetWidth(scrlView.bounds)*page, 0)  animated:YES];
}


#pragma mark BasicVideoEntryCellDelegate

- (void)entryVideo
{
    NSString *nibName = [Util nibNameWithClass:[VideoMonitorViewController class]];
    VideoMonitorViewController *viewController = [[VideoMonitorViewController alloc] initWithNibName:nibName bundle:nil];
    
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    
    [navController setNavigationBarHidden:NO];
    [navController pushViewController:viewController animated:YES];
}

#pragma mark BasicInfoEntryCellDelegate

- (void)entryMessage
{
    NSString *nibName = [Util nibNameWithClass:[MessageServiceController class]];
    MessageServiceController *vc = [[MessageServiceController alloc] initWithNibName:nibName bundle:nil];
    
    vc.records = [MessageManager getInstance].commMsgArray;
    [[MessageManager getInstance] setAllCommMsgRead];
    
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    [navController pushViewController:vc animated:YES];
    [navController setNavigationBarHidden:NO];
}


- (void)entryEnvironmentService
{
//    NSString *nibName = [Util nibNameWithClass:[EnvironmentalMonitoringController class]];
//    EnvironmentalMonitoringController *viewController = [[EnvironmentalMonitoringController alloc] initWithNibName:nibName bundle:nil];
//    
//    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
//    
//    [navController setNavigationBarHidden:NO];
//    [navController pushViewController:viewController animated:YES];
}


#pragma mark PanelEditViewControllerDelegate

- (void)panelEditViewController:(PanelEditViewController *)panelEditViewController deleteItemAtIndex:(NSInteger)index
{
  
    UIView *removeView = nil;
    
    for (PanelView *panelView in panelViews)
    {
        if (panelView.index > index) {
            CGRect frame = panelView.frame;
            frame.origin.x -= CGRectGetWidth(scrlView.frame);
            panelView.frame = frame;
            
            panelView.index -= 1;
        }
        else if (panelView.index == index) {
            removeView = panelView;
        }
    }
    
    [panelViews removeObject:removeView];
    [removeView removeFromSuperview];

   
    [self refreshSubViews];
}




- (void)panelEditViewController:(PanelEditViewController *)panelEditViewController downloadFile:(NSString *)dirName path:(NSString *)filePath overwritten:(BOOL)overwritten
{
    
    
    NSError *error;
    
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:&error];
    
    for (NSString *fileName in files) {
        
        if ([fileName hasSuffix:@"txt"]) {
            
            NSString *txtFilePath = [filePath stringByAppendingPathComponent:fileName];
            
            NSDictionary *dataDic = [self readConfigFileAtPath:txtFilePath];
            
            if (dataDic) {
                
                [self refreshSubViews];
                
                [self displayConnectStatusForCurrentPanel];
                
                if (overwritten) {//覆盖旧的
   
                    PanelView *oldView = nil;
                    
                    for (PanelView *panelView in panelViews)
                    {
                        if ([panelView.name isEqualToString:dirName])
                        {
                            oldView = panelView;
                            break;
                        }
                    }
                    
                    if (oldView) {
      
                        [self drawPanelViewWithData:dataDic dirName:dirName atIndex:oldView.index];
                        
                        [oldView removeFromSuperview];
                        [panelViews removeObject:oldView];
                    }

                }
                else {//添加新的
                     [self drawPanelViewWithData:dataDic dirName:dirName];
                }
 
                
                NSInteger pageNum = [self numberOfPanels];
                
                if (pageNum > 0 && [_gateways count] > 0) {
                    [self captureScreenForCurrentIndex];
                }
                
       
                for (SHGateway *gateway in _gateways) {
                    [self associateCellWithGateway:gateway];
                }

            }

        }
    }
}

- (void)panelEditViewControllerReorder
{

    for (PanelView *panelView in panelViews)
    {
        NSInteger index = [self indexForPanel:panelView.name];
        CGRect frame = panelView.frame;
        frame.origin.x = index * CGRectGetWidth(scrlView.frame);
        panelView.frame = frame;
        
        panelView.index = index;
    }

}



@end
