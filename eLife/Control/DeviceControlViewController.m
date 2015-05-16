 //
//  DeviceControlViewController.m
//  eLife
//
//  Created by mac mini on 14/11/11.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "DeviceControlViewController.h"
#import "SliderView.h"
#import "DeviceData.h"
#import "NetAPIClient.h"
#import "NotificationDefine.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "GatewayListViewController.h"

#import "Util.h"
#import "PublicDefine.h"
#import "Reachability.h"

#import "NetReachability.h"
#import "SceneModeView.h"
#import "ProgressView.h"
#import "PopInputView.h"
#import "DisplayStyleView.h"
#import "AddGatewayViewController.h"

#import "RAMCollectionAuxView.h"
#import "RAMCollectionViewCell.h"
#import "RAMCollectionViewFlemishBondLayout.h"
#import "RAMCollectionViewFlemishBondLayoutAttributes.h"

#import "DimmerlightView.h"
#import "DeviceCtrlBgdView.h"
#import "CurtainView.h"
#import "AirConditionView.h"
#import "GroundHeatView.h"
#import "BgdMusicView.h"

#import "HHFullScreenViewController.h"
#import "MultiSelectionView.h"

#define TAG_DISCONNECT_LABEL 100
#define TAG_DISPLAY_STYLE_BTN 200
#define TAGP_GATEWAY_BTN 300

#define TAG_SWITCH 400

#define MENU_HEIGHT 76

#define PROMPT_VIEW_HEIGHT 38

#define ICON_H 34
#define ICON_W 30

#define BUTTON_SIZE 44

#define NAME_FONT_SIZE 16

#define HEADER_H 24
#define ITEM_H 110

#define NORMAL_CELL_HEIGHT 60
#define DETAIL_CELL_HEIGHT 100

#define REQ_TIMEOUT 15 //请求超时时间

#define NAV_TITLE_FONT ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 18 : 24)


#define INVALID_INDEX -1


#define ITEMS_PERROW 4


#define GRAY_COLOR [UIColor colorWithRed:91/255.0 green:91/255.0 blue:91/255.0 alpha:1]
#define GREEN_COLOR [UIColor colorWithRed:67/255.0 green:143/255.0 blue:25/255.0 alpha:1]

enum DisplayStyle
{
    DisplayStyleRoom = 0, //显示为房间
    DisplayStyleDevType = 1 //显示为设备类型

};


enum CtrlType
{
    CtrlTypeScene = 0, //情景模式控制
    CtrlTypeArm = 1, //报警防区布防
    CtrlTypeHouse = 2, //房间控制
    CtrlTypeDevice = 3 //设备控制
};


static  NSString * const kDisplayStyle = @"kDisplayStyle";

static NSString *const CellIdentifier = @"MyCell";
static NSString *const HeaderIdentifier = @"HeaderIdentifier";
static NSString *const FooterIdentifier = @"FooterIdentifier";

@interface DeviceControlViewController () <SliderViewDelegate,UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate,SceneModeViewDelegate,PopInputViewDelegate,DisplayStyleViewDelegate,UICollectionViewDataSource, UICollectionViewDelegate, RAMCollectionViewFlemishBondLayoutDelegate,MultiSelectionViewDelegate>
{
    NSInteger selectedIndex;//当前显示网关index
    
//    BOOL isReachable;
    
    NSMutableArray *gateways;

    IBOutlet SliderView *topView;
    

    UITableView *sceneCtrlView;//情景模式
    UITableView *armCtrlView;//布撤防
    
    UICollectionView *_collectionView;
    
    IBOutlet UIScrollView *containerView;
    
    NSMutableArray *sortDevices;
    NSMutableArray *sortTitles;
    
    MBProgressHUD *hud;
    
    UIView *promptView;
    
    UIView *bgdView;
    
    int displayStyle;
    NSInteger ctrlType;
    
    SceneModeView *sceneModeView;

    UIImageView *portraitView;//头像
    ProgressView *progressView;//网关在线数显示
    
    NSInteger indexOfAlarmZone;//正在布撤防的防区index
    
    UILabel *guideView;
    
    BaseDeviceViewController *deviceController;

}

@end

@implementation DeviceControlViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
        sortDevices = [NSMutableArray arrayWithCapacity:1];
        sortTitles = [NSMutableArray arrayWithCapacity:1];
        gateways = [NSMutableArray arrayWithCapacity:1];
    }
    
    return self;
}

//- (void)test
//{
//    NSLog(@"通知 test");
//}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
//    displayStyle = [[NSUserDefaults standardUserDefaults] integerForKey:kDisplayStyle];
    
    displayStyle = DisplayStyleRoom;
    
    selectedIndex = 0;
    
    [gateways removeAllObjects];
    [gateways addObjectsFromArray:[NetAPIClient sharedClient].gatewayList];
    
    [self customNavigationBar];
    [self setupSubViews];

    [self showOrHideGuideView];
    [self showOrHideWaiting];
    [self showConnectStatus];
    
    [self refreshTable];
  
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableScrolling:) name:NOTIFY_SLIDER_TOUCH_BEGAN object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableScrolling:) name:NOTIFY_SLIDER_TOUCH_ENDED object:nil];
    
    [self registerNotification];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    [navController setNavigationBarHidden:YES];
    
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    

   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"DeviceController didReceiveMemoryWarning");
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    sceneCtrlView.delegate = nil;
    sceneCtrlView.dataSource = nil;
    
    armCtrlView.delegate = nil;
    armCtrlView.dataSource = nil;

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark Private Methods

- (void)registerNotification
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBindGatewayNtf:) name:BindGatewayNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRemoveGatewayNtf:) name:DelGatewayNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEditGatewayNtf:) name:EditGatewayNotication object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGetGatewaysNtf:) name:GetGatewayListNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGetDevicesReadyNtf:) name:DeviceListGetReadyNotifacation object:nil];
    

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGetGatewayConfigStepNtf:) name:GetGatewayConfigStepNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogoutNtf:) name:LogoutNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceStatusChangeNtf:) name:DeviceStatusChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleQueryStatusNtf:) name:QueryDeviceStatusNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMQConnectStatusNtf:) name:MQConnectStatusNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGatewayStatusChangeNtf:) name:GatewayStatusChangeNotification object:nil];
}


- (void)customNavigationBar
{
    
    [Util unifyStyleOfViewController:self withTitle:@"控制"];
    
    //右边按钮
    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    addBtn.frame = CGRectMake(0, 0, 44, 44);
    [addBtn addTarget:self action:@selector(chooseAGateway) forControlEvents:UIControlEventTouchUpInside];
    [addBtn setImage:[UIImage imageNamed:@"EditBtn"] forState:UIControlStateNormal];
    //    [returnBtn setTitle:@"添加" forState:UIControlStateNormal];
    UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithCustomView:addBtn];
    self.navigationItem.rightBarButtonItem = rightBtnItem;
    
    
    //头像边框
    UIImageView *portraitBgdView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 4, 30, 30)];
    portraitBgdView.image = [UIImage imageNamed:@"PortraitFrame"];
    [self.navigationController.navigationBar addSubview:portraitBgdView];
    
    
    //头像
    NSString *portraitName =  [NetAPIClient sharedClient].MQConnected ? @"PortraitBlue" : @"PortraitGray";;
    
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
    for (SHGateway *gateway in gateways)
    {
        if ([gateway isOnline]) {
            onlineNum++;
        }
        
    }
    
    progressView.value = onlineNum;
    progressView.maxValue = [gateways count];
}

- (void)initContainerView
{
    
    NSInteger pageWidth = CGRectGetWidth(self.view.bounds);
    
//    containerView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(topView.frame), pageWidth, CGRectGetHeight(self.view.bounds)-CGRectGetMaxY(topView.frame))];
    
    CGSize s = containerView.contentSize;
    s.width = pageWidth*3;
    containerView.contentSize = s;
    containerView.showsHorizontalScrollIndicator = NO;
    containerView.showsVerticalScrollIndicator = NO;
    containerView.pagingEnabled = YES;
    containerView.delegate = self;
    containerView.bounces = NO;
    containerView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    containerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:containerView];
    
    
    sceneCtrlView = [[UITableView alloc] initWithFrame:CGRectMake(0,0, pageWidth, CGRectGetHeight(containerView.bounds)) style:UITableViewStylePlain];
    sceneCtrlView.dataSource = self;
    sceneCtrlView.delegate = self;
    sceneCtrlView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    sceneCtrlView.separatorStyle = UITableViewCellSeparatorStyleNone;
    sceneCtrlView.allowsSelection = NO;
    //sceneCtrlView.backgroundColor = [UIColor greenColor];
    [containerView addSubview:sceneCtrlView];
    
    armCtrlView = [[UITableView alloc] initWithFrame:CGRectMake(pageWidth,0, pageWidth, CGRectGetHeight(containerView.bounds)) style:UITableViewStylePlain];
    armCtrlView.dataSource = self;
    armCtrlView.delegate = self;
    armCtrlView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    armCtrlView.separatorStyle = UITableViewCellSeparatorStyleNone;
    armCtrlView.allowsSelection = NO;
    [containerView addSubview:armCtrlView];
    

    
//    RAMCollectionViewFlemishBondLayout *collectionViewLayout = [[RAMCollectionViewFlemishBondLayout alloc] init];
//    collectionViewLayout.delegate = self;
//    collectionViewLayout.numberOfElements = 4;
//    collectionViewLayout.highlightedCellHeight = 150.f;
//    collectionViewLayout.highlightedCellWidth = 200.f;
//    
    
    UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    collectionViewLayout.itemSize = CGSizeMake(CGRectGetWidth(containerView.bounds)/ITEMS_PERROW, ITEM_H);
    collectionViewLayout.headerReferenceSize = CGSizeMake(CGRectGetWidth(containerView.bounds), HEADER_H);
    collectionViewLayout.minimumInteritemSpacing = 0;
    collectionViewLayout.minimumLineSpacing = 0;
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(pageWidth*2,0, pageWidth, CGRectGetHeight(containerView.bounds)) collectionViewLayout:collectionViewLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [_collectionView registerClass:[RAMCollectionAuxView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:HeaderIdentifier];
    [_collectionView registerClass:[RAMCollectionViewCell class] forCellWithReuseIdentifier:CellIdentifier];
//    [_collectionView registerClass:[RAMCollectionAuxView class] forSupplementaryViewOfKind:RAMCollectionViewFlemishBondHeaderKind withReuseIdentifier:HeaderIdentifier];
//    [_collectionView registerClass:[RAMCollectionAuxView class] forSupplementaryViewOfKind:RAMCollectionViewFlemishBondFooterKind withReuseIdentifier:FooterIdentifier];
    [containerView addSubview:_collectionView];

}


- (void)showOrHideGuideView
{
    
    if ([[NetAPIClient sharedClient] numberOfGateways] > 0) {
        [self hideGuideView];
    }
    else {
        [self showGuideView];
    }
}


//显示添加网关向导
- (void)showGuideView
{
    if (!guideView) {
        
        NSMutableAttributedString *content = [[NSMutableAttributedString alloc] initWithString:@"点击添加网关"];
        UIFont *font = [UIFont systemFontOfSize:19];
        
        CGSize size = CGSizeMake(180, 50);
        
        guideView = [[UILabel alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.view.bounds)-size.width)/2, (CGRectGetHeight(self.view.bounds)-size.height)/2, size.width, size.height)];
        guideView.backgroundColor = [UIColor clearColor];
        //        guideView.text = content;
        guideView.textAlignment = NSTextAlignmentCenter;
        guideView.font = font;
        NSRange contentRange = {0, [content length]};
        [content addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:contentRange];
        
        guideView.attributedText = content;
        guideView.userInteractionEnabled = YES;
        guideView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:guideView];
        
        UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enterGatewayBind)];
        [guideView addGestureRecognizer:gest];
    }
    
    
    guideView.hidden = NO;
    
    
 
    containerView.hidden = YES;
    topView.hidden = YES;
    
    [self displaySHDsiconnectView:NO reason:nil];
}


//隐藏添加网关向导
- (void)hideGuideView
{
    containerView.hidden = NO;
    topView.hidden = NO;
    
    guideView.hidden = YES;
//    [guideView removeFromSuperview];
    
//    guideView.alpha = 0;
}

- (void)enterGatewayBind
{
    NSString *nibName = [Util nibNameWithClass:[GatewayListViewController class]];
    GatewayListViewController *viewController = [[GatewayListViewController alloc] initWithNibName:nibName bundle:nil];
    
    //隐藏主导航栏
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    
    [navController setNavigationBarHidden:NO];
    
    [navController pushViewController:viewController animated:YES];
}




- (void)chooseAGateway
{
    if ([gateways count] > 0)
    {
        NSMutableArray *titles = [NSMutableArray arrayWithCapacity:1];
        
        for (SHGateway *gateway in gateways)
        {
            if (gateway.name) {
                [titles addObject:gateway.name];
            }
            else {
                [titles addObject:gateway.serialNumber];
            }
            
        }
        
        MultiSelectionView *multiSelectionView = [[MultiSelectionView alloc] initWithTitles:titles hlButtonIndex:selectedIndex delegate:self];//网关选择视图
        [multiSelectionView show];
    }
    
}



- (void)switchDisplayType
{
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"aa" object:nil];
    
    [self dismissPopView];
    
    displayStyle = (displayStyle == DisplayStyleDevType ? DisplayStyleRoom : DisplayStyleDevType);
  
//    [[NSUserDefaults standardUserDefaults] setInteger:displayStyle forKey:kDisplayStyle];
    
    [self refreshTable];
}


- (void)editDevice
{
    [self dismissPopView];
    
    NSString *nibName = [Util nibNameWithClass:[GatewayListViewController class]];
    
    GatewayListViewController *viewController = [[GatewayListViewController alloc] initWithNibName:nibName bundle:nil];
    
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    
    [navController setNavigationBarHidden:NO];
    [navController pushViewController:viewController animated:YES];
}

- (void)dismissPopView
{
    bgdView.hidden = YES;
}



- (void)setupSubViews
{
    
    
    NSArray *titleArray = [NSArray arrayWithObjects:@"情景模式", @"布防撤防",@"房间控制",@"设备控制",nil];
    
    NSArray *normalImageArray = [NSArray arrayWithObjects:[UIImage imageNamed:@"SceneMode"],[UIImage imageNamed:@"AlarmSetting"],[UIImage imageNamed:@"HouseCtrl"], [UIImage imageNamed:@"DeviceCtrl"],nil];
    
    NSArray *selectedImageArray = [NSArray arrayWithObjects:[UIImage imageNamed:@"SceneModeSelected"],[UIImage imageNamed:@"AlarmSettingSelected"],[UIImage imageNamed:@"HouseCtrlSelected"],[UIImage imageNamed:@"DeviceCtrlSelected"],nil];

    [topView setBackgroundColor:[UIColor colorWithRed:221/255. green:242/255. blue:255/255. alpha:1]];
    topView.delegate = self;
    topView.selectedIndex = 2;
    topView.maxVisibleNum = 4;
    
    [topView buildWithTitles:titleArray normalImages:normalImageArray selectedImages:selectedImageArray];
    [self.view addSubview:topView];
    
    
    [self initContainerView];
    
    ctrlType = CtrlTypeHouse;

    [self changePageToIndex:2 animated:NO];
    
    [self refreshTable];


}


- (void)refreshTable
{
    NSLog(@"refreshTable");

    [armCtrlView reloadData];
    
    [sceneCtrlView reloadData];
    
    [self categoryDevice];

    
    [_collectionView reloadData];

}

//设备分类
- (void)categoryDevice
{
    if (displayStyle == DisplayStyleDevType) {
        [self categoryDeviceByType];
    }
    else {
        [self categoryDeviceByRoom];
    }
    
}

//按设备类型分类
- (void)categoryDeviceByType
{
    [sortTitles removeAllObjects];
    [sortDevices removeAllObjects];
    
    NSMutableArray *lightArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *curtainArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *airconditionArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *groundHeatArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *socketsArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *bgdMusicArray = [NSMutableArray arrayWithCapacity:1];
    
    SHGateway *gateway = [self selectedGateway];
    
    for (SHDevice *device in gateway.deviceArray)
    {
        
        if ([device.type isEqualToString:SH_DEVICE_COMMLIGHT]) {
            [lightArray addObject:device];
            
        }
        else if ([device.type isEqualToString:SH_DEVICE_LEVELLIGHT]) {
            [lightArray addObject:device];
            
        }
        else if ([device.type isEqualToString:SH_DEVICE_CURTAIN]) {
            [curtainArray addObject:device];
            
        }
        else if ([device.type isEqualToString:SH_DEVICE_AIRCONDITION]) {
            
            [airconditionArray addObject:device];
        }
        else if ([device.type isEqualToString:SH_DEVICE_GROUNDHEAT]) {
            
            [groundHeatArray addObject:device];
        }
        else if ([device.type isEqualToString:SH_DEVICE_SOCKET]) {
            
            [socketsArray addObject:device];
        }
        else if ([device.type isEqualToString:SH_DEVICE_BACKGROUNDMUSIC]) {
            
            [bgdMusicArray addObject:device];
        }
    }
    
    if ([lightArray count] > 0) {
        
        [sortDevices addObject:lightArray];
        [sortTitles addObject:@"灯光"];
        
    }
    
    if ([curtainArray count] > 0) {
        [sortDevices addObject:curtainArray];
        [sortTitles addObject:@"窗帘"];
        
    }
    
    if ([airconditionArray count] > 0) {
        [sortDevices addObject:airconditionArray];
        [sortTitles addObject:@"空调"];
        
    }
    if ([groundHeatArray count] > 0) {
        [sortDevices addObject:groundHeatArray];
        [sortTitles addObject:@"地暖"];
        
    }
    if ([socketsArray count] > 0) {
        [sortDevices addObject:socketsArray];
        [sortTitles addObject:@"插座"];
    }
    if ([bgdMusicArray count] > 0) {
        [sortDevices addObject:bgdMusicArray];
        [sortTitles addObject:@"背景音乐"];
    }



}


//按房间分类
- (void)categoryDeviceByRoom
{
    [sortTitles removeAllObjects];
    [sortDevices removeAllObjects];
    

    
    SHGateway *gateway = [self selectedGateway];
    

    [gateway putDeviceIntoRoom];
    
    NSMutableArray *otherArray = [NSMutableArray arrayWithCapacity:1];
    
    for (SHDevice *device in gateway.deviceArray)
    {
        BOOL positioned = NO;
        for (SHRoom *room in gateway.roomArray)
        {
            if ([device.roomId isEqualToString:room.layoutId]) {
                positioned = YES;
                break;
            }
        }
        
        
        if (!positioned) {
            [otherArray addObject:device];
        }
    }
    
    for (SHRoom *room in gateway.roomArray)
    {
        [sortTitles addObject:room.layoutName];
        [sortDevices addObject:room.deviceArray];
    }
    
    if ([otherArray count]>0) {
        [sortTitles addObject:@"其他"];
        
        [sortDevices addObject:otherArray];
    }
}


- (SHGateway *)selectedGateway
{
    if ([gateways count] && selectedIndex != INVALID_INDEX) {
        return [gateways objectAtIndex:selectedIndex];
    }
    
    return nil;
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


- (void)showConnectStatus
{
    
    if ([NetReachability isNetworkReachable]) {
        SHGateway *gateway = [self selectedGateway];
        
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
            [self displaySHDsiconnectView:NO reason:nil];
        }
    }
    else {
          [self displaySHDsiconnectView:YES reason:@"当前网络不可用，请检查后再试"];
    }
    
    
}




- (void)displaySHDsiconnectView:(BOOL)yesOrNo reason:(NSString *)reason
{
   
    if (yesOrNo) {//显示断线
        
        NSLog(@"显示断线: yes reason:%@",reason);
 
        
        if (!promptView)
        {
            NSLog(@"promptView 初始化");
            
            promptView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), PROMPT_VIEW_HEIGHT)];
            promptView.backgroundColor = [UIColor colorWithRed:255/255. green:243/255. blue:207/255. alpha:1];
            
            NSInteger markSize = 24;
            UIImageView *markView = [[UIImageView alloc] initWithFrame:CGRectMake(10, (PROMPT_VIEW_HEIGHT-markSize)/2, markSize, markSize)];
            markView.image = [UIImage imageNamed:@"operationbox_fail_web"];
            markView.backgroundColor = [UIColor clearColor];
            [promptView addSubview:markView];
            
            
            
            UIFont *font = [UIFont systemFontOfSize:14];
            UILabel *hintText = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(markView.frame)+4, 0, CGRectGetWidth(promptView.frame)-CGRectGetMaxX(markView.frame), PROMPT_VIEW_HEIGHT)];
            hintText.backgroundColor = [UIColor clearColor];
            hintText.numberOfLines = 0;
            hintText.textColor = [UIColor blackColor];
            hintText.font = font;
            hintText.text = reason;
            hintText.tag = TAG_DISCONNECT_LABEL;
            [promptView addSubview:hintText];
      
            [self.view addSubview:promptView];
            
            //添加点击响应
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDisconnectView)];
            [promptView addGestureRecognizer:tapGesture];
        }

        
        
        UILabel *hintText = (UILabel *)[promptView viewWithTag:TAG_DISCONNECT_LABEL];
        hintText.text = reason;

        
        CGRect topViewFrame =  topView.frame;
        topViewFrame.origin.y = PROMPT_VIEW_HEIGHT;
        
        CGRect containerViewFrame = containerView.frame;
        containerViewFrame.origin.y = CGRectGetMaxY(topViewFrame);
        
//        CGRect promptViewFrame = promptView.frame;
//        promptViewFrame.origin.y = 0;
        
        topView.frame = topViewFrame;
        containerView.frame = containerViewFrame;
//        promptView.frame = promptViewFrame;
        promptView.hidden = NO;
        
        CGRect armViewFrame = armCtrlView.frame;
        armViewFrame.size.height = CGRectGetHeight(containerView.bounds) - PROMPT_VIEW_HEIGHT;
        armCtrlView.frame = armViewFrame;

        
        CGRect devViewFrame = _collectionView.frame;
        devViewFrame.size.height = CGRectGetHeight(containerView.bounds) - PROMPT_VIEW_HEIGHT;
        _collectionView.frame = devViewFrame;
        
        CGRect sceneViewFrame = sceneCtrlView.frame;
        sceneViewFrame.size.height = CGRectGetHeight(containerView.bounds) - PROMPT_VIEW_HEIGHT;
        sceneCtrlView.frame = sceneViewFrame;

    }
    else {//隐藏断线连接提示
        
        NSLog(@"显示断线: no");
        
        CGRect topViewFrame =  topView.frame;
        topViewFrame.origin.y = 0;
        
        CGRect containerViewFrame = containerView.frame;
        containerViewFrame.origin.y = CGRectGetMaxY(topViewFrame);
        
//        CGRect promptViewFrame = promptView.frame;
//        promptViewFrame.origin.y = -PROMPT_VIEW_HEIGHT;
//        
//        promptView.frame = promptViewFrame;
        
        promptView.hidden = YES;
        
        topView.frame = topViewFrame;
        containerView.frame = containerViewFrame;

        CGRect armViewFrame = armCtrlView.frame;
        armViewFrame.size.height = CGRectGetHeight(containerView.bounds);
        armCtrlView.frame = armViewFrame;
        

        
        CGRect devViewFrame = _collectionView.frame;
        devViewFrame.size.height = CGRectGetHeight(containerView.bounds);
        _collectionView.frame = devViewFrame;
        
        CGRect sceneViewFrame = sceneCtrlView.frame;
        sceneViewFrame.size.height = CGRectGetHeight(containerView.bounds);
        sceneCtrlView.frame = sceneViewFrame;
        
    }
    
    NSLog(@"显示断线 end");

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


- (void)showOrHideWaiting
{
    SHGateway *gateway = [self selectedGateway];
    
    if (gateway && gateway.getConfigStep != GetConfigStepFinished) {
        
        [self showWaitingStatus];
        
    }
    else {
        [self hideWaitingStatus];
    }
    
    
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
    
    [self performSelector:@selector(reqTimeout) withObject:nil afterDelay:REQ_TIMEOUT];
}

- (void)reqTimeout
{
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"请求超时!";
    
    [hud hide:YES afterDelay:1.5];
    
    
}





- (NSInteger)sectionForDevice:(SHDevice *)device
{
    NSInteger section = NSNotFound;
    
    if (displayStyle == DisplayStyleDevType) {//按设备类型显示
        if ([device.type isEqualToString:SH_DEVICE_COMMLIGHT]) {
            section = [sortTitles indexOfObject:@"灯光"];
            
        }
        else if ([device.type isEqualToString:SH_DEVICE_LEVELLIGHT]) {
            section = [sortTitles indexOfObject:@"灯光"];
            
        }
        else if ([device.type isEqualToString:SH_DEVICE_CURTAIN]) {
            section = [sortTitles indexOfObject:@"窗帘"];
            
        }
        else if ([device.type isEqualToString:SH_DEVICE_AIRCONDITION]) {
            
            section = [sortTitles indexOfObject:@"空调"];
        }
        else if ([device.type isEqualToString:SH_DEVICE_GROUNDHEAT]) {
            
            section = [sortTitles indexOfObject:@"地暖"];
        }
        else if ([device.type isEqualToString:SH_DEVICE_SOCKET]) {
            
            section = [sortTitles indexOfObject:@"插座"];
        }
        else if ([device.type isEqualToString:SH_DEVICE_BACKGROUNDMUSIC]) {
            
            section = [sortTitles indexOfObject:@"背景音乐"];
        }
        else {
            section = NSNotFound;
        }
    }
    else {//按房间显示
        SHGateway *gateway = [self selectedGateway];
        
        for (int i = 0; i<[gateway.roomArray count]; i++)
        {
            SHRoom *room = [gateway.roomArray objectAtIndex:i];
            if ([device.roomId isEqualToString:room.layoutId]) {
                section = i;
                break;
            }
        }
        
        if (section == NSNotFound) {
            section = [gateway.roomArray count];
        }
    }
    
    return section;
}

- (NSIndexPath *)indexPathOfDevice:(SHDevice *)device
{
    SHGateway *gateway = [self selectedGateway];
    
    if (NSOrderedSame == [device.gatewaySN compare:gateway.serialNumber options:NSCaseInsensitiveSearch]) {//是当前显示的网关的设备
        
        NSInteger section = [self sectionForDevice:device];
        NSInteger row;
        
        if (section != NSNotFound && [sortDevices count] > section) {
            row = [[sortDevices objectAtIndex:section] indexOfObject:device];
            if (row != NSNotFound) {
                NSIndexPath *path = [NSIndexPath indexPathForItem:row inSection:section];
                
                return path;
            }
        }
    }
    
    return nil;
}



#pragma mark MultiSelectionViewDelegate

- (void)multiSelectionView:(MultiSelectionView *)multiSelectionView didSelectedAtIndex:(NSInteger)index
{
    if (index != selectedIndex) {
        
        selectedIndex = index;
        
        [self showOrHideWaiting];
        
        [self showConnectStatus];
        
        [self refreshTable];
    }
}

#pragma mark DisplayStyleViewDelegate

- (void)displayStyleView:(DisplayStyleView *)displayStyleView didSelectItemAtIndex:(NSInteger)index
{
    
    displayStyle  = index;
    
//    [[NSUserDefaults standardUserDefaults] setInteger:displayStyle forKey:kDisplayStyle];
    
    [self categoryDevice];
    

}


#pragma mark PopInputViewDelegate

- (void)popInputView:(PopInputView *)popInputView clickOkButtonWithText:(NSString *)inputText
{
    if ([inputText isEqualToString:@"666666"]) {
        SHGateway *gatway = [self selectedGateway];
        
        SHAlarmZone *alarmZone = [gatway.alarmZoneArray objectAtIndex:indexOfAlarmZone];
        
        
        [[NetAPIClient sharedClient] setAlarmMode:alarmZone enable:false password:@"" successCallback:^{
            NSLog(@"set alarmMode success %@",alarmZone.serialNumber);
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexOfAlarmZone inSection:0];
            
            [armCtrlView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            
        }failureCallback:^{
            NSLog(@"set alarmMode failed %@",alarmZone.serialNumber);
            

            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexOfAlarmZone inSection:0];
            
            [armCtrlView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            
            [self showCtrlFailedHint:@"控制失败"];
        }];

    }
    else {
        
        [self showCtrlFailedHint:@"密码错误!"];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexOfAlarmZone inSection:0];
        
        [armCtrlView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];

    }
}

- (void)popInputView:(PopInputView *)popInputView clickCancelButtonWithText:(NSString *)inputText
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexOfAlarmZone inSection:0];
    
    [armCtrlView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}



#pragma mark SceneModeViewDelegate
- (void)sceneModeView:(SceneModeView *)sceneModeView didSelectAtIndex:(NSInteger)index
{
    SHGateway *gateway = [self selectedGateway];
    SHSceneMode *sceneMode = [gateway.sceneModeArray objectAtIndex:index];
    
    
    MBProgressHUD *tempHud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
    tempHud.removeFromSuperViewOnHide = YES;
    tempHud.labelText = @"情景切换中...";
    tempHud.mode = MBProgressHUDModeIndeterminate;
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    [tempHud show:YES];
    
    
    [[NetAPIClient sharedClient] setSceneMode:sceneMode successCallback:^{
        NSLog(@"set scenemode success %@",sceneMode.serialNumber);
        
        [tempHud hide:YES];
        
    }failureCallback:^{
        NSLog(@"set scenemode failed %@",sceneMode.serialNumber);
        
        tempHud.mode = MBProgressHUDModeText;
        tempHud.labelText = @"控制失败";
        
        [tempHud hide:YES afterDelay:1.0];
    }];

    

}

- (NSString *)sceneModeView:(SceneModeView *)sceneModeView titleAtIndex:(NSInteger)index
{
    SHGateway *gateway = [self selectedGateway];
    
    SHSceneMode *sceneMode = [gateway.sceneModeArray objectAtIndex:index];
    
    return sceneMode.name;
}


- (UIImage *)sceneModeView:(SceneModeView *)sceneModeView normalImageAtIndex:(NSInteger)index
{
    SHGateway *gateway = [self selectedGateway];
    
    SHSceneMode *sceneMode = [gateway.sceneModeArray objectAtIndex:index];
    
    NSString *imageName = @"Custom";
    
    if ([sceneMode.name rangeOfString:@"在家"].location != NSNotFound) {
        imageName = @"GoHome";
    }
    else if ([sceneMode.name rangeOfString:@"回家"].location != NSNotFound) {
        imageName = @"GoHome";
    }
    else if ([sceneMode.name rangeOfString:@"离家"].location != NSNotFound) {
        imageName = @"GoOut";
    }
    else if ([sceneMode.name rangeOfString:@"外出"].location != NSNotFound) {
        imageName = @"GoOut";
    }
    else if ([sceneMode.name rangeOfString:@"全开"].location != NSNotFound) {
        imageName = @"AllOpen";
    }
    
    return [UIImage imageNamed:imageName];
}

- (UIImage *)sceneModeView:(SceneModeView *)sceneModeView selectedImageAtIndex:(NSInteger)index
{
    SHGateway *gateway = [self selectedGateway];
    
    SHSceneMode *sceneMode = [gateway.sceneModeArray objectAtIndex:index];
    
    NSString *imageName = @"CustomSelected";
    
    if ([sceneMode.name rangeOfString:@"在家"].location != NSNotFound) {
        imageName = @"GoHomeSelected";
    }
    else if ([sceneMode.name rangeOfString:@"回家"].location != NSNotFound) {
        imageName = @"GoHomeSelected";
    }
    else if ([sceneMode.name rangeOfString:@"离家"].location != NSNotFound) {
        imageName = @"GoOutSelected";
    }
    else if ([sceneMode.name rangeOfString:@"外出"].location != NSNotFound) {
        imageName = @"GoOutSelected";
    }
    else if ([sceneMode.name rangeOfString:@"全开"].location != NSNotFound) {
        imageName = @"AllOpenSelected";
    }
    
    return [UIImage imageNamed:imageName];
}

- (NSInteger)numberOfItemsInSceneModeView:(SceneModeView *)sceneModeView
{
    SHGateway *gateway = [self selectedGateway];
    
    return [gateway.sceneModeArray count];
}

#pragma mark Handle Notification

- (void)handleQueryStatusNtf:(NSNotification *)ntf
{
    SHGateway *gateway = [ntf object];
    SHGateway *slcGateway = [self selectedGateway];
    
    if ([gateway isEqual:slcGateway]) {
        [self refreshTable];
    }
    
}


- (void)handleDeviceStatusChangeNtf:(NSNotification *)ntf
{
    id object = [ntf object];
    
    if ([[(SHDevice *)object type] isEqualToString:SH_DEVICE_ALARMZONE]) {
        [armCtrlView reloadData];

    }
    else {
        SHDevice *device = (SHDevice *)object;
        
        NSIndexPath *indexPath =  [self indexPathOfDevice:device];
        
        if (indexPath) {

            
            [_collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
        }
    }
}

- (void)handleLogoutNtf:(NSNotification *)ntf
{

}

- (void)handleGetDevicesReadyNtf:(NSNotification *)ntf
{
    
    NSLog(@"handleGetDevicesReadyNtf");
    
    [self hideWaitingStatus];
    
    
    //[self refreshTable];

}




- (void)reachabilityChanged:(NSNotification *)ntf
{

    
    [self showConnectStatus];
}

- (void)handleGatewayStatusChangeNtf:(NSNotification *)ntf
{
    SHGateway *gateway = ntf.object;
    GatewayState preState = [[[ntf userInfo] objectForKey:GatewayPreviousStateKey] integerValue];//先前状态
    
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
    
    SHGateway *slcGateway = [self selectedGateway];
    
    if ([gateway isEqual:slcGateway]) {
        [self showConnectStatus];
    }
    
    [self showNumOfOnlineGateways];
}


- (void)handleGetGatewayConfigStepNtf:(NSNotification *)ntf
{
    SHGateway *gateway = ntf.object;
    NSDictionary *userInfo = [ntf userInfo];
    NSInteger step = [[userInfo objectForKey:GetGatewayConfigStepNotificationKey] integerValue];
    
     SHGateway *slcGateway = [self selectedGateway];
    
     if ([gateway isEqual:slcGateway]) {
         
         if (step == GetConfigStepFinished) {
             [self hideWaitingStatus];
             
             [self refreshTable];
         }
         else {
             [self showWaitingStatus];
         }
     }

}




- (void)handleGetGatewaysNtf:(NSNotification *)ntf
{
//    //先移除
//    [gateways removeAllObjects];
//    
//    //再添加
//    [gateways addObjectsFromArray:[NetAPIClient sharedClient].gatewayList];
//
//    
//    for (SHGateway *gateway in gateways)
//    {
//        [self observeGateway:gateway];
//    }
//    
//
//    [self showOrHideGuideView];
//    
//    [self showNumOfOnlineGateways];
    
    
}

- (void)handleEditGatewayNtf:(NSNotification *)ntf
{
    BOOL needRefresh = [[[ntf userInfo] objectForKey:NeedRefreshGatewayKey] boolValue];
    
    if (needRefresh) {
        
        SHGateway *gateway = [ntf object];
        
        NSInteger index = [gateways indexOfObject:gateway];
        
        if (index == selectedIndex) {
            
            if (gateway.getConfigStep != GetConfigStepFinished ) {
                [self showWaitingStatus];
            }
            else {
                [self refreshTable];
            }
            
            
            [self showConnectStatus];//显示网关连接状态
        }
        
        [self showNumOfOnlineGateways];
        
    }
    
}

- (void)handleRemoveGatewayNtf:(NSNotification *)ntf
{
    SHGateway *gateway = [[ntf userInfo] objectForKey:DelGatewayNotificationKey];
    
    if (gateway) {
        
        NSInteger removeIndex = [gateways indexOfObject:gateway];
        
        [gateways removeObject:gateway];
        
        if ([gateways count] > 0) {
            
            //显示第一个
            selectedIndex = 0;
            [self showOrHideWaiting];
            [self refreshTable];
            
        }
        else {//没有了网关

            [self showGuideView];
            
            [self refreshTable];
        }
        
        
        [self showConnectStatus];
    }
    
    
    [self showNumOfOnlineGateways];
}

- (void)handleBindGatewayNtf:(NSNotification *)ntf
{
    SHGateway *gateway = [[ntf userInfo] objectForKey:BindGatewayNotificationKey];

    
    [gateways addObject:gateway];
    
    if ([gateways count] == 1) {//之前没有网关
    
        //显示第一个
        selectedIndex = 0;
        
        [self hideGuideView];
    }
    
    
    [self showNumOfOnlineGateways];
}


//- (void)handleRefreshGatewaysNtf:(NSNotification *)ntf
//{
//    NSLog(@"handleRefreshGatewaysNtf");
//    
//    @synchronized(gateways)
//    {
//        NSLog(@"refresh start");
//        for (SHGateway *gateway in gateways)
//        {
//            [self removeObserveDeviceOfGateway:gateway];
//            
//        }
//        NSLog(@"refresh end");
//    }
//
//}



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


#pragma mark SliderViewDelegate

- (void)sliderView:(SliderView *)sliderView didSelectItemAtIndex:(NSInteger)index
{
    
//    switch (index) {
//        case 0:
//            [sceneCtrlView reloadData];
//            break;
//        case 1:
//            [armCtrlView reloadData];
//            break;
//        case 2:
//            [devCtrlView reloadData];
//            break;
//        default:
//            break;
//    }
    
    if (index >= CtrlTypeHouse)
    {
        if (index == CtrlTypeHouse) {
            displayStyle  = DisplayStyleRoom;

        }
        else {
             displayStyle  = DisplayStyleDevType;
        }
        
        
//        [[NSUserDefaults standardUserDefaults] setInteger:displayStyle forKey:kDisplayStyle];
        
        [self categoryDevice];
        
        
        [_collectionView reloadData];
        
        ctrlType = index;
        
        index = 2;
    }

    [self changePageToIndex:index animated:YES];

        
    ctrlType = index;
    

}


#pragma mark  UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == containerView) {
        CGFloat pageWidth = containerView.frame.size.width;
        int page = floor((containerView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        
        if (page >= 2) {
            if ( displayStyle  == DisplayStyleRoom) {
                topView.selectedIndex = 2;
            }
            else {
                topView.selectedIndex = 3;
            }
        }
        else {
            topView.selectedIndex = page;
        }
        
    }
  
}


#pragma mark UITableViewDataSource & UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect f = cell.contentView.frame;

    f.size = cell.frame.size;
    
    cell.contentView.frame = f;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (tableView == sceneCtrlView)
    {
        [[self sceneView] reloadData];
        
        return CGRectGetHeight(sceneModeView.bounds);
    }
    
    return NORMAL_CELL_HEIGHT;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{

    
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{

    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    if (tableView == sceneCtrlView) {
        
        return 1;
    }
    else if (tableView == armCtrlView) {
  
        
        SHGateway *gateway = [self selectedGateway];
        return [gateway.alarmZoneArray count];
    }
    
    
    return [[sortDevices objectAtIndex:section] count] > 0 ? [[sortDevices objectAtIndex:section] count] : 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (tableView == armCtrlView) {
        
        static NSString *identifier = @"ArmTableViewCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        // Configure the cell...
        if (nil == cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
        

        for (UIView *v in cell.contentView.subviews)
        {
            [v removeFromSuperview];
        }
        
        [self configArmCtrlViewCell:cell atIndexPath:indexPath];
        
        
        return cell;
        
    }


    static NSString *identifier = @"sceneTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    // Configure the cell...
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    
    for (UIView *v in cell.contentView.subviews)
    {
        [v removeFromSuperview];
    }
    
    [self configSceneViewCell:cell atIndexPath:indexPath];
    
    return cell;

}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    

    
}


#pragma mark - UICollectionViewDataSource & Deleagte
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [sortDevices count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[sortDevices objectAtIndex:section] count] > 0 ? [[sortDevices objectAtIndex:section] count] : 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    RAMCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if ([[sortDevices objectAtIndex:indexPath.section] count] > 0) {
        SHDevice *device = [[sortDevices objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        
        [self configCollectionViewCell:cell withDevice:device];
    }
    else {
        [cell configureCellWithText:@"没有设备" textColor:[UIColor grayColor]];
    }

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;
{
    UICollectionReusableView *titleView = nil;
    
      NSString *title = [sortTitles objectAtIndex:indexPath.section];
    
    if (kind == UICollectionElementKindSectionHeader) {
        titleView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:HeaderIdentifier forIndexPath:indexPath];
        ((RAMCollectionAuxView *)titleView).label.text = title;
    }
    
    return titleView;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    RAMCollectionViewCell *cell = (RAMCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
 
    if ([[sortDevices objectAtIndex:indexPath.section] count] > 0) {
        SHDevice *device = [[sortDevices objectAtIndex:indexPath.section] objectAtIndex:indexPath.item];
        
        NSString *displayType = nil;
        if ([device.icon length] > 0) {
            
            displayType = device.icon;
        }
        else {
            displayType = device.type;
            
        }
        
        //在线才能操作
        if (device.state.online) {
            
            if ([displayType isEqualToString:SH_DEVICE_COMMLIGHT]) {//开关型灯光

                [cell startAnimating];
                
                if (device.state.powerOn) {
                    [[NetAPIClient sharedClient] setPowerOff:device successCallback:^{
                        [cell stopAnimating];
                        
                        [collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
                
                    }failureCallback:^{
                        [cell stopAnimating];
                
                        
                        [self showCtrlFailedHint:@"控制失败"];
                    }];
                }
                else {
                    
                    [[NetAPIClient sharedClient] setPowerOn:device successCallback:^{
                        
                        [cell stopAnimating];
                        
                        [collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
                        
                
                    }failureCallback:^{
                        
                        [cell stopAnimating];
                        
              
                        [self showCtrlFailedHint:@"控制失败"];
                    }];
                }
            }
            
            else if ([displayType isEqualToString:SH_DEVICE_LEVELLIGHT]) {//调光型灯光
                
                NSString *nibName = [Util nibNameWithClass:[DimmerlightView class]];
                DimmerlightView *ctrller = [[DimmerlightView alloc] initWithNibName:nibName bundle:nil];

                deviceController = ctrller;
                [self showDeviceControlView:ctrller.view];
                [ctrller setDevice:device];
                
            }
            
            else if ([displayType isEqualToString:SH_DEVICE_CURTAIN]) {//窗帘
                
                NSString *nibName = [Util nibNameWithClass:[CurtainView class]];
                CurtainView *ctrller = [[CurtainView alloc] initWithNibName:nibName bundle:nil];
    
                deviceController = ctrller;
                [self showDeviceControlView:ctrller.view];

                [ctrller setDevice:device];

              
                
            }
            else if ([displayType isEqualToString:SH_DEVICE_AIRCONDITION])
            {//空调
                
                NSString *nibName = [Util nibNameWithClass:[AirConditionView class]];
                AirConditionView *ctrller = [[AirConditionView alloc] initWithNibName:nibName bundle:nil];

                deviceController = ctrller;
                [self showDeviceControlView:ctrller.view];
                [ctrller setDevice:device];
            }
            else if ([displayType isEqualToString:SH_DEVICE_GROUNDHEAT])
            {//地暖
                
                NSString *nibName = [Util nibNameWithClass:[GroundHeatView class]];
                GroundHeatView *ctrller = [[GroundHeatView alloc] initWithNibName:nibName bundle:nil];

                deviceController = ctrller;
                [self showDeviceControlView:ctrller.view];
                [ctrller setDevice:device];
                
                
            }
            else if ([displayType isEqualToString:SH_DEVICE_SOCKET]) {//普通插座
                
                [cell startAnimating];
                
                if (device.state.online) {
                    if (device.state.powerOn) {
                        [[NetAPIClient sharedClient] setPowerOff:device successCallback:^{
                            
                            [cell stopAnimating];
                            
                            [collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
               
                            
                        }failureCallback:^{
                   
                             [cell stopAnimating];
                            
                            [self showCtrlFailedHint:@"控制失败"];
                        }];
                    }
                    else {
                        
                        [[NetAPIClient sharedClient] setPowerOn:device successCallback:^{
                            
                             [cell stopAnimating];
                            [collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
                        
                        }failureCallback:^{
                      
                             [cell stopAnimating];
                            
                            [self showCtrlFailedHint:@"控制失败"];
                        }];
                    }
                }
                
            }
            else if ([displayType isEqualToString:SH_DEVICE_BACKGROUNDMUSIC])
            {//背景音乐
                
                NSString *nibName = [Util nibNameWithClass:[BgdMusicView class]];
                BgdMusicView *ctrller = [[BgdMusicView alloc] initWithNibName:nibName bundle:nil];
                deviceController = ctrller;
                [self showDeviceControlView:ctrller.view];
                [ctrller setDevice:device];
                
            }
            
        }
    }
}

- (void)showDeviceControlView:(UIView *)toView fromView:(UIView *)fromView
{
    CGRect frame =[self.view.window convertRect:self.view.window.frame
                                       fromView:toView];
    
    NSString *nibName = [Util nibNameWithClass:[HHFullScreenViewController class]];
    HHFullScreenViewController *viewController = [[HHFullScreenViewController alloc]
                      initWithNibName:nibName bundle:nil];
    
    [[toView layer] setShadowOffset:CGSizeMake(4, 4)];
    [[toView layer] setShadowRadius:4];
    [[toView layer] setShadowOpacity:1.0];
    [[toView layer] setShadowColor:[UIColor blackColor].CGColor];
    
    [viewController setFromView:fromView toView:toView withX:frame.origin.x withY:frame.origin.y];
    [viewController startFirstAnimation];
    [self.view.window addSubview:viewController.view];


}

- (void)showDeviceControlView:(UIView *)deviceControlView
{
    
    DeviceCtrlBgdView *devCtlBgdView = [[DeviceCtrlBgdView alloc] initWithSuperView:[UIApplication sharedApplication].keyWindow];
    [devCtlBgdView addDeviceCtrlView:deviceControlView atPosition:CtrlViewPositionBottom];
    [devCtlBgdView show];
    
}

#pragma mark - RAMCollectionViewVunityLayoutDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(RAMCollectionViewFlemishBondLayout *)collectionViewLayout estimatedSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(CGRectGetWidth(_collectionView.frame), HEADER_H);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(RAMCollectionViewFlemishBondLayout *)collectionViewLayout estimatedSizeForFooterInSection:(NSInteger)section
{
    return CGSizeZero;
}

- (RAMCollectionViewFlemishBondLayoutGroupDirection)collectionView:(UICollectionView *)collectionView layout:(RAMCollectionViewFlemishBondLayout *)collectionViewLayout highlightedCellDirectionForGroup:(NSInteger)group atIndexPath:(NSIndexPath *)indexPath
{
    RAMCollectionViewFlemishBondLayoutGroupDirection direction;
    
    if (indexPath.row % 2) {
        direction = RAMCollectionViewFlemishBondLayoutGroupDirectionRight;
    } else {
        direction = RAMCollectionViewFlemishBondLayoutGroupDirectionLeft;
    }
    
    return direction;
}


#pragma mark Cell Config

- (NSString *)roomNameForDevice:(SHDevice *)device
{
    
    SHGateway *gateway = [self selectedGateway];
    
    
    return [gateway roomNameForDevice:device];

}


- (NSString *)imageNameForType:(NSString *)type online:(BOOL)online powerOn:(BOOL)powerOn
{
    NSString *imgName = nil;
 
    if ([type isEqualToString:SH_DEVICE_COMMLIGHT] || [type isEqualToString:SH_DEVICE_LEVELLIGHT]) {//灯光
        if (!online) {
            imgName = @"BigLightOffline";
        }
        else if (powerOn) {
            imgName = @"BigLightOn";
           
        }
        else {
            imgName = @"BigLightOff";
        }

    }
    else if ([type isEqualToString:SH_DEVICE_CURTAIN]) {//窗帘
  
        if (!online) {
            imgName = @"BigCurtainOffline";
        }
        else {
            
            imgName = @"BigCurtainOn";
        }
    }
    else if ([type isEqualToString:SH_DEVICE_AIRCONDITION]) {//空调
        
        if (!online) {
            imgName = @"BigACOffline";
        }
        else if (powerOn) {
            imgName = @"BigACOn";
        }
        else {
            imgName = @"BigACOff";
        }
    }
    else if ([type isEqualToString:SH_DEVICE_SOCKET]) {//插座
        if (!online) {
            imgName = @"BigSocketOffline";
        }
        else if (powerOn) {
            imgName = @"BigSocketOn";
        }
        else {
            imgName = @"BigSocketOff";
        }
    }
    else if ([type isEqualToString:SH_DEVICE_GROUNDHEAT]) {//地暖
        if (!online) {
            imgName = @"BigGroundHeatOffline";
        }
        else if (powerOn) {
            imgName = @"BigGroundHeatOn";
        }
        else {
            imgName = @"BigGroundHeatOff";
        }
    }
    else if ([type isEqualToString:SH_DEVICE_GROUNDHEAT]) {//背景音乐
        if (!online) {
            imgName = @"BigBgdMusicOffline";
        }
        else if (powerOn) {
            imgName = @"BigBgdMusicOn";
        }
        else {
            imgName = @"BigBgdMusicOff";
        }
    }

    
    return imgName;
}

- (UIColor *)textColorForType:(NSString *)type online:(BOOL)online powerOn:(BOOL)powerOn
{
     UIColor *textColor = GRAY_COLOR;
    
    if ((online && powerOn) || ([type isEqualToString:SH_DEVICE_CURTAIN] && online))
    {
        textColor = GREEN_COLOR;
    }
    
    return textColor;
}

- (void)configCollectionViewCell:(RAMCollectionViewCell *)cell withDevice:(SHDevice *)device
{
    
    NSString *imgName = nil;
    UIColor *textColor = GRAY_COLOR;
    NSString *displayType = nil;
    UIView *addView = nil;
    NSString *name = device.name;
    NSString *roomName = [self roomNameForDevice:device];
    
    if ([device.icon length] > 0) {

        displayType = device.icon;
    }
    else {
        displayType = device.type;

    }
    
    
    if ([displayType isEqualToString:SH_DEVICE_COMMLIGHT]) {//开关型灯光
        if (!device.state.online) {
            imgName = @"BigLightOffline";
        }
        else if (device.state.powerOn) {
            imgName = @"BigLightOn";
            textColor = GREEN_COLOR;
        }
        else {
            imgName = @"BigLightOff";
        }

    }
    else if ([displayType isEqualToString:SH_DEVICE_LEVELLIGHT]) {//调光型灯光
        
        if (!device.state.online) {
            imgName = @"BigLightOffline";
        }
        else if (device.state.powerOn) {
            imgName = @"BigLightOn";
            textColor = GREEN_COLOR;
        }
        else {
            imgName = @"BigLightOff";
        }

    }
    else if ([displayType isEqualToString:SH_DEVICE_CURTAIN]) {//窗帘
        
        
        if (!device.state.online) {
            imgName = @"BigCurtainOffline";
        }
        else {
            textColor = GREEN_COLOR;
            
            imgName = @"BigCurtainOn";
            
            if ([displayType isEqualToString:device.type]) {
                id components = device.range;
                if ([components isKindOfClass:[NSArray class]]) {
                    if ([components count] == 2) {//可调行程窗帘
                        
                        
                        NSInteger min = device.minRange;
                        NSInteger max = device.maxRange;
                        
                        int currentValue = [(SHCurtainState *)device.state shading];
                        
                        if (currentValue == max) {
                            imgName = @"BigStepCurtainMax";
                        }
                        else if (currentValue == min) {
                            imgName = @"BigStepCurtainMin";
                        }
                        else {
                            imgName = @"BigStepCurtainMid";
                        }
                        
                    }
                }
            }

            
        }

    }
    else if ([displayType isEqualToString:SH_DEVICE_AIRCONDITION]) {//空调
        
        
        if (!device.state.online) {
            imgName = @"BigACOffline";
        }
        else if (device.state.powerOn) {
            imgName = @"BigACOn";
            textColor = GREEN_COLOR;
            
            if ([displayType isEqualToString:device.type]) {
                addView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 77, 47)];
                
                NSInteger textWidth = 30;
                NSInteger textHeight = 28;
                NSInteger modeWidth = 22;
                NSInteger modeHeight = 22;
                NSInteger speedWidth = modeWidth;
                NSInteger speedHeight = modeHeight;
                
                NSInteger spacingX = (CGRectGetWidth(addView.bounds) -textWidth-modeWidth-speedWidth)/4;
                NSInteger statusY = 5;
                
                
                //显示温度
                UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(spacingX, statusY, textWidth, textHeight)];
                tempLabel.textColor = [UIColor whiteColor];
                tempLabel.font = [UIFont systemFontOfSize:13];
                tempLabel.textAlignment = NSTextAlignmentCenter;
                tempLabel.backgroundColor = [UIColor clearColor];
                tempLabel.text = [NSString stringWithFormat:@"%d℃",[(SHAirconditionState *)device.state temperature]];
                
                [addView addSubview:tempLabel];
                
                //显示模式
                UIImageView *modeView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(tempLabel.frame)+spacingX, statusY, modeWidth, modeHeight)];
                [addView addSubview:modeView];
                
                NSString *strMode = [(SHAirconditionState *)device.state mode];
                
                NSString *imageName = nil;
                
                if ([strMode isEqualToString:@"Cold"]) {//制冷
                    
                    imageName = @"ModeColdSelected";
                }
                else if ([strMode isEqualToString:@"Hot"]) {//制热
                    
                    imageName = @"ModeHotSelected";
                }
                else if ([strMode isEqualToString:@"Wind"]) {//通风
                    
                    imageName = @"ModeWindSelected";
                }
                else if ([strMode isEqualToString:@"Wet"]) {//除湿
                    
                    imageName = @"ModeWetSelected";
                }
                else if ([strMode isEqualToString:@"Auto"]) {//除湿
                    
                    imageName = @"ModeAutoSelected";
                }
                
                modeView.image = [UIImage imageNamed:imageName] ;
                
                
                //显示风速
                UIImageView *windSpeedView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(modeView.frame)+spacingX, statusY, speedWidth, speedHeight)];
                [addView addSubview:windSpeedView];
                NSString *strWind = [(SHAirconditionState *)device.state windSpeed];
                
                NSString *windImageName = nil;
                
                if ([strWind isEqualToString:@"Stop"]) {//停止
                    
                    windImageName = nil;
                }
                else if ([strWind isEqualToString:@"Low"]) {//低速
                    
                    windImageName = @"SpeedLowSelected";
                }
                else if ([strWind isEqualToString:@"Middle"]) {//中速
                    
                    windImageName = @"SpeedMidSelected";
                }
                else if ([strWind isEqualToString:@"High"]) {//高速
                    
                    windImageName = @"SpeedHighSelected";
                }
                else if ([strWind isEqualToString:@"Auto"]) {//自动
                    
                    windImageName = @"ModeAutoSelected";
                }
                
                windSpeedView.image = [UIImage imageNamed:windImageName];
                
            }
           
        }
        else {
            imgName = @"BigACOff";
        }

    }
    else if ([displayType isEqualToString:SH_DEVICE_SOCKET]) {//插座
          if (!device.state.online) {
              imgName = @"BigSocketOffline";
          }
          else if (device.state.powerOn) {
              imgName = @"BigSocketOn";
              textColor = GREEN_COLOR;
          }
          else {
              imgName = @"BigSocketOff";
          }
      }
    else if ([displayType isEqualToString:SH_DEVICE_GROUNDHEAT]) {//地暖
        if (!device.state.online) {
            imgName = @"BigGroundHeatOffline";
        }
        else if (device.state.powerOn) {
            imgName = @"BigGroundHeatOn";
            textColor = GREEN_COLOR;
        }
        else {
            imgName = @"BigGroundHeatOff";
        }
    }
    else if ([displayType isEqualToString:SH_DEVICE_BACKGROUNDMUSIC]) {//背景音乐
        if (!device.state.online) {
            imgName = @"BigBgdMusicOffline";
        }
        else if (device.state.powerOn) {
            imgName = @"BigBgdMusicOn";
        }
        else {
            imgName = @"BigBgdMusicOff";
        }
    }
    
    [cell configureCellWithIcon:[UIImage imageNamed:imgName] additionView:addView text:name subText:roomName textColor:textColor];
}


- (void)configArmCtrlViewCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    
    SHGateway *gateway = [self selectedGateway];
    SHAlarmZone *alarmZone = [gateway.alarmZoneArray objectAtIndex:indexPath.row];

    NSInteger switchWidth = 80;
    NSInteger switchHeight = 28;
    NSInteger originX = 10;
    NSInteger rightMargin = 8;
    NSInteger orginY = 6;
    NSInteger titleH = 24;
    NSInteger statusH = 24;
    
    NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 14 : 16);
    
    CGSize txtSize = [alarmZone.name sizeWithFont:[UIFont systemFontOfSize:fontSize] constrainedToSize:CGSizeMake(CGRectGetWidth(armCtrlView.bounds)-originX-switchWidth-rightMargin, NORMAL_CELL_HEIGHT)];
    
    //防区名
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(originX, orginY, txtSize.width, titleH)];
    lbl.text = alarmZone.name;
    lbl.font = [UIFont systemFontOfSize:fontSize];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor blackColor];
    [cell.contentView addSubview:lbl];
    
    //状态
    NSString *mode = [(SHAlarmZoneState *)alarmZone.state enable] ? @"布防" : @"撤防";
    mode = [NSString stringWithFormat:@"状态 : %@",mode];
    
    UILabel *statusLbl = [[UILabel alloc] initWithFrame:CGRectMake(originX, CGRectGetMaxY(lbl.frame), 120, statusH)];
    statusLbl.text = mode;
    statusLbl.font = [UIFont systemFontOfSize:fontSize];
    statusLbl.backgroundColor = [UIColor clearColor];
    statusLbl.textColor = [UIColor grayColor];
    [cell.contentView addSubview:statusLbl];
    
    UISwitch *aswitch = [[UISwitch alloc] initWithFrame:CGRectMake(CGRectGetWidth(armCtrlView.bounds)-rightMargin-switchWidth, (NORMAL_CELL_HEIGHT-switchHeight)/2, switchWidth, switchHeight)];
    aswitch.on = ((SHAlarmZoneState *)alarmZone.state).enable  ? YES : NO;
    [aswitch addTarget:self action:@selector(setAlarmZoneArm:) forControlEvents:UIControlEventValueChanged];
    aswitch.tag = TAG_SWITCH + indexPath.row;
    [cell.contentView addSubview:aswitch];
    
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, NORMAL_CELL_HEIGHT-1, CGRectGetWidth(armCtrlView.bounds), 1)];
    sep.backgroundColor = [UIColor grayColor];
    sep.alpha = 0.4;
    [cell.contentView addSubview:sep];
}

- (void)configSceneViewCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{

    [cell.contentView addSubview:[self sceneView]];
}


- (SceneModeView *)sceneView
{
    if (!sceneModeView) {
        sceneModeView = [[SceneModeView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(sceneCtrlView.bounds), NORMAL_CELL_HEIGHT)];
        sceneModeView.numOfPerRow = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 3 : 4);
        sceneModeView.delegate = self;
    }
    
    return sceneModeView;
}

- (void)setAlarmZoneArm:(UISwitch *)sender
{
    NSInteger row = sender.tag - TAG_SWITCH;
    
    indexOfAlarmZone = row;
    
    SHGateway *gatway = [self selectedGateway];
    
    SHAlarmZone *alarmZone = [gatway.alarmZoneArray objectAtIndex:row];
    
    if (!sender.on)
    {
        PopInputView *inputView = [[PopInputView alloc] initWithTitle:@"撤防操作" placeholder:@"请输入安全密码" delegate:self];
        [inputView show];
    }
    else {
        bool enable = sender.on ? true : false;
        
        [[NetAPIClient sharedClient] setAlarmMode:alarmZone enable:enable password:@"" successCallback:^{
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexOfAlarmZone inSection:0];
            
            [armCtrlView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];

            
            NSLog(@"set alarmMode success %@",alarmZone.serialNumber);
            
        }failureCallback:^{
            NSLog(@"set alarmMode failed %@",alarmZone.serialNumber);
            
            sender.on = !sender.on;
            
            [self showCtrlFailedHint:@"控制失败"];
        }];
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

- (void)changePageToIndex:(NSInteger)page animated:(BOOL)annimated
{
    
    CGRect frame = containerView.frame;
    //frame.origin.x = frame.size.width * page;
 
    [containerView setContentOffset:CGPointMake(frame.size.width * page, 0) animated:annimated];
}


#pragma mark other



- (UIImage *)iconForDevice:(SHDevice *)device
{
    NSString *imgName = nil;
    if ([device.type isEqualToString:SH_DEVICE_COMMLIGHT]) {//开关型灯光
        if (!device.state.online) {
            imgName = @"LightOffline";
        }
        else if (device.state.powerOn) {
            imgName = @"LightOn";
        }
        else {
            imgName = @"LightOff";
        }
        
    }
    else if ([device.type isEqualToString:SH_DEVICE_LEVELLIGHT]) {
        
        if (!device.state.online) {
            imgName = @"LightOffline";
        }
        else if (device.state.powerOn) {
            imgName = @"LightOn";
        }
        else {
            imgName = @"LightOff";
        }
    }
    else if ([device.type isEqualToString:SH_DEVICE_CURTAIN]) {//窗帘
        
        if (!device.state.online) {
            imgName = @"CurtainOffline";
        }
        else if (device.state.powerOn) {
            imgName = @"CommonCurtain";
        }
        else {
            imgName = @"CommonCurtain";
        }

    }
    else if ([device.type isEqualToString:SH_DEVICE_AIRCONDITION]) {
        if (!device.state.online) {
            imgName = @"AirconditionOffline";
        }
        else if (device.state.powerOn) {
            //imgName = @"CommonCurtain";
        }
        else {
            imgName = @"CommonCurtain";
        }
    }
    
    
    return [UIImage imageNamed:imgName];
}




//- (void)disableScrolling:(NSNotification *)notify
//{
//    containerView.scrollEnabled = NO;
//}
//
//- (void)enableScrolling:(NSNotification *)notify
//{
//    containerView.scrollEnabled = YES;
//}



@end
