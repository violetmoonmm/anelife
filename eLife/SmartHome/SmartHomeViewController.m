//
//  SmartHomeViewController.m
//  eLife
//
//  Created by mac on 14-3-17.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "SmartHomeViewController.h"
#import "ExpansiveView.h"
#import "ExpansiveCell.h"
#import "GridView.h"
#import "NetAPIClient.h"
#import "MBProgressHUD.h"
#import "DeviceData.h"
#import "VideoMonitorViewController.h"
#import "AppDelegate.h"
#import "zw_dssdk.h"
#import "VideoWnd.h"
#import "SHLocalControl.h"
#import "SliderView.h"
#import "GatewayListViewController.h"
#import "Util.h"
#import "AlarmSettingView.h"
#import "Reachability.h"

#define REQ_TIMEOUT 10

#define EXP_CELL_WIDTH ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 300 : 748)

#define TAG_VIDEO_BTN 400
#define TAG_ALARMZONE_SWITCH 500

#define NAV_TITLE_FONT ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 18 : 24)

#define VIDEO_VIEW_H ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 150 : 350)


#define PROMPT_VIEW_HEIGHT 32


@interface SmartHomeViewController () <SliderViewDelegate>
{
    ExpansiveView *_expView;
    GridView *_gridView;
    MBProgressHUD *_hud;

    NSMutableArray *_gateways;

    
    UIButton *_leftArrow;
    UIButton *_rightArrow;
    UILabel *_titleLabel;
    
    NSUInteger _selectedGatewayIndex;//当前显示的网关索引
    
    NSMutableArray *_sceneBtns;//情景模式按钮数组
    NSInteger _slctSceneIndex;//选中的情景模式
    
    NSMutableArray *_alarmSwitchs;//报警防区数组
    
    UIView *_videoViewBgd;//背景
    VideoWnd *_videoWnd;//视频窗口
    
    BOOL _isVideoShow;//视频是否已经显示
    
    
    NSMutableDictionary *_catDeviceDic;//分类的设备
    
    NSInteger _catIndex;//选择的类型索引
    
    SliderView *_sliderView;
    
    UIView *_promptView;
}

@end

@implementation SmartHomeViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        //
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGetGatewaysNtf:) name:GetGatewayListNotification object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGetDeviceListNtf:) name:GetDeviceListNotification object:nil];

        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpnpDisconnect:) name:UpnpDisconnectNotification object:nil];
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSHLocalLoginNtf:) name:LoginResultNotification object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSHDisconnectNtf:) name:DisconnectNotification object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSHGetConfigNtf:) name:SHGetConfigNotification object:nil];
        
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBindGatewayNtf:) name:BindGatewayNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRemoveGatewayNtf:) name:DelGatewayNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEditGatewayNtf:) name:EditGatewayNotication object:nil];
        
//          [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

        _gateways = [NSMutableArray arrayWithCapacity:1];
        
        _sceneBtns = [NSMutableArray arrayWithCapacity:1];
        
        _catDeviceDic = [NSMutableDictionary dictionaryWithCapacity:1];
        
        
        _slctSceneIndex = -1;

    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"smarthome viewDidLoad");
    
    [self buildNavigationBarViews];

    _expView = [[ExpansiveView alloc] initWithFrame:self.view.frame];
    _expView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _expView.cellWidth = EXP_CELL_WIDTH;
    _expView.delegate = self;
    _expView.dataSource = self;
    _expView.backgroundColor = [UIColor colorWithRed:128/255. green:178/255. blue:212/255. alpha:1];
    [_expView reloadData];
    [self.view addSubview:_expView];
    

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }


    if ([_gateways count] > 0) {
        SHGateway *gateway = [_gateways objectAtIndex:0];
        if (gateway.shFetchingStep != SHFetchingStepFinished) {
            
            [self showWaitingStatus];
        }
    }
   

    
    

    
//    //just for test
//    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
//    btn.frame = CGRectMake(0, 0, 50, 30);
//    [btn addTarget:self action:@selector(btnTest) forControlEvents:UIControlEventTouchUpInside];
//    [btn setTitle:@"刷新" forState:UIControlStateNormal];
//    UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
//    self.navigationItem.rightBarButtonItem = rightBtnItem;
//    
//    //just for test
//    UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeSystem];
//    btn1.frame = CGRectMake(0, 0, 50, 30);
//    [btn1 addTarget:self action:@selector(btnTest1) forControlEvents:UIControlEventTouchUpInside];
//    [btn1 setTitle:@"返回" forState:UIControlStateNormal];
//    UIBarButtonItem *leftBtnItem = [[UIBarButtonItem alloc] initWithCustomView:btn1];
//    self.navigationItem.leftBarButtonItem = leftBtnItem;
}

//- (void)btnTest1
//{
//    [self displaySHDsiconnectView:NO];
//}
//
//- (void)btnTest
//{
//    [self displaySHDsiconnectView:YES];
//}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    [navController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    for (SHGateway *gateway in _gateways)
    {
        [self removeObserveGateway:gateway];
    }
    
    _expView = nil;
    _gridView = nil;
}

#pragma mark - Private Methods

- (void)appDidEnterBackground:(NSNotification*)ntf
{
    NSLog(@"appDidEnterBackground");
#ifndef SIMULATOR
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(_videoWnd)];
    [zw_dssdk dssdk_talk_stop:(__bridge void *)(_videoWnd)];
#endif
}

- (void)buildNavigationBarViews
{
    UIImage *navImage = [UIImage imageNamed:@"NavigationBar"];
    CGSize size = self.navigationController.navigationBar.frame.size;
    UIGraphicsBeginImageContext(CGSizeMake(size.width, size.height));
    [navImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.navigationController.navigationBar setBackgroundImage:scaledImage forBarMetrics:UIBarMetricsDefault];
    
    
    [self drawTopView];
    
}

- (void)drawTopView
{
    
    
    const NSInteger btn_w = 44;
    const NSInteger btn_h = 44;
    const NSInteger lable_w = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 140 : 320);
    const NSInteger spacing_x = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 2 : 8);
    
    CGSize size = self.navigationController.navigationBar.frame.size;
    
    //elife 图标
    NSInteger iconOrignX = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 4 : 34);
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(iconOrignX, 0, 44, 44)];
    iconView.image = [UIImage imageNamed:@"logo.png"];
    iconView.backgroundColor = [UIColor clearColor];
    [self.navigationController.navigationBar addSubview:iconView];
    
    NSString *title = @"智能家居";
    
    if ([_gateways count]) {
        SHGateway *tempGateway = [_gateways objectAtIndex:0];
        title = [tempGateway name];
        
    }
    
    
    UIFont *font = [UIFont boldSystemFontOfSize:NAV_TITLE_FONT];
    CGSize lblSize = [title sizeWithFont:font constrainedToSize:CGSizeMake(lable_w, 40)];
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake((size.width-lable_w)/2, (size.height-lblSize.height)/2, lable_w, lblSize.height)];
    lbl.text = title;
    lbl.font = font;
    lbl.textColor = [UIColor whiteColor];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textAlignment = NSTextAlignmentCenter;
    _titleLabel = lbl;
    [self.navigationController.navigationBar addSubview:lbl];
    
    _leftArrow = [UIButton buttonWithType:UIButtonTypeCustom];
    _leftArrow.frame = CGRectMake(CGRectGetMinX(lbl.frame)-btn_w-spacing_x, (size.height-btn_h)/2, btn_w, btn_h);
    _leftArrow.imageEdgeInsets = UIEdgeInsetsMake(12, 15, 12, 15);
    [_leftArrow setImage:[UIImage imageNamed:@"left_arrow1.png"] forState:UIControlStateNormal];
    [_leftArrow addTarget:self action:@selector(clickLeftArrow:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationController.navigationBar addSubview:_leftArrow];
    
    _rightArrow = [UIButton buttonWithType:UIButtonTypeCustom];
    _rightArrow.frame = CGRectMake(CGRectGetMaxX(_titleLabel.frame)+spacing_x, (size.height-btn_h)/2, btn_w, btn_h);
    [_rightArrow setImage:[UIImage imageNamed:@"right_arrow1.png"] forState:UIControlStateNormal];
    _rightArrow.imageEdgeInsets = UIEdgeInsetsMake(12, 15, 12, 15);
    //    [_rightArrow setBackgroundImage:[UIImage imageNamed:@"right_arrow.png"] forState:UIControlStateNormal];
    [_rightArrow addTarget:self action:@selector(clickRightArrow:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationController.navigationBar addSubview:_rightArrow];
    
    
    if ([_gateways count]  <=1 ) {
        
        _rightArrow.hidden = YES;
        _leftArrow.hidden = YES;
    }
    else if ([_gateways count] >= 2) {
        _rightArrow.enabled = YES;
        _leftArrow.enabled = NO;
        
    }
}

- (void)refreshTopView
{
    if ([_gateways count]) {
        
        SHGateway *tempGateway = [_gateways objectAtIndex:0];

        _titleLabel.text = [tempGateway name];  

    }
    
    if ([_gateways count]  <=1 ) {//
        
        _rightArrow.hidden = YES;
        _leftArrow.hidden = YES;
    }
    else if ([_gateways count] >= 2) {
        _rightArrow.enabled = YES;
        _leftArrow.enabled = NO;
        
        _rightArrow.hidden = NO;
        _leftArrow.hidden = NO;
        
    }
    else {
        
    }
}

- (void)clickLeftArrow:(UIButton *)sender
{
     NSLog(@"clickLeftArrow");
    
    if (_isVideoShow) {
        [_videoViewBgd removeFromSuperview];
        
        [_expView setContentInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    }

    
    _selectedGatewayIndex--;
    if (_selectedGatewayIndex == 0) {//到了最前面一个
        _leftArrow.enabled = NO;
    }

    if (_selectedGatewayIndex+1 < [_gateways count]) {
        _rightArrow.enabled = YES;
    }
    
    SHGateway *tempGateway = [self selectedGateway];
    _titleLabel.text = tempGateway.name;
    
    if (tempGateway.shFetchingStep != SHFetchingStepFinished ) {
        [self showWaitingStatus];
    }
    else {
        [self catForWholeHouseCtrl];
    }
    
    [_expView reloadData];
    
    [self showCurrentGatewayConnectStatus];
}

- (void)clickRightArrow:(UIButton *)sender
{
    NSLog(@"clickRightArrow");
    
    if (_isVideoShow) {
        [_videoViewBgd removeFromSuperview];
        
        [_expView setContentInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    }

    
    _selectedGatewayIndex++;
    
    if (_selectedGatewayIndex+1 == [_gateways count]) {//到了最后一个
        _rightArrow.enabled = NO;
    }
    
    if (_selectedGatewayIndex > 0) {
        _leftArrow.enabled = YES;
    }
    
    SHGateway *tempGateway = [self selectedGateway];
    _titleLabel.text = tempGateway.name;
    
    if (tempGateway.shFetchingStep != SHFetchingStepFinished ) {
        [self showWaitingStatus];
    }
    else {
        [self catForWholeHouseCtrl];
    }
    
    [_expView reloadData];
    
    [self showCurrentGatewayConnectStatus];
}


- (void)showCurrentGatewayConnectStatus
{
    
    if ([_gateways count]) {
        SHGateway *gateway = [self selectedGateway];
        
        if (gateway.status == GatewayStatusLoginFailed || gateway.status == GatewayStatusOffline) {
            [self displaySHDsiconnectView:YES gateway:gateway];
        }
        else if (gateway.status == GatewayStatusOnline) {
            [self displaySHDsiconnectView:NO gateway:gateway];
        }
    }
    else {
        [self displaySHDsiconnectView:NO gateway:nil];
    }
    

}

- (void)showWaitingStatus
{
    NSLog(@"showWaitingStatus");
    
//    _hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    if (nil == _hud) {
        
        _hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:_hud];
        _hud.removeFromSuperViewOnHide = YES;
        _hud.labelText = @"请稍后...";
        _hud.mode = MBProgressHUDModeIndeterminate;
        [_hud show:YES];
        
        [self performSelector:@selector(reqTimeout) withObject:nil afterDelay:REQ_TIMEOUT];
    }

}

- (void)reqTimeout
{
    _hud.mode = MBProgressHUDModeText;
	_hud.labelText = @"请求超时!";
    
    [_hud hide:YES afterDelay:1.5];
    
    //_hud = nil;
}

- (void)hideHud
{
    NSLog(@"hideHud");
    
    [_hud hide:YES];
//    _hud = nil;
}

- (NSUInteger)numberOfSHDevice
{
    
    SHGateway *gateway = [self selectedGateway];
    
    return [gateway.deviceArray count];
 
}

- (NSUInteger)numberOfAlarmZones
{
    
    SHGateway *gateway  = [self selectedGateway];
    
    return [gateway.alarmZoneArray count];
    
}

- (NSUInteger)numberOfSceneModes
{
    
    SHGateway *gateway  = [self selectedGateway];
    
    return [gateway.sceneModeArray count];
    
}

- (void)displaySHDsiconnectView:(BOOL)yesOrNo gateway:(SHGateway *)gateway
{
//    NSLog(@"displaySHDsiconnectView : %@ begin",yesOrNo ? @"yes" : @"no");
    if (yesOrNo && !_promptView) {//显示断线

        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, -PROMPT_VIEW_HEIGHT, CGRectGetWidth(self.view.frame), PROMPT_VIEW_HEIGHT)];
        header.backgroundColor = [UIColor colorWithRed:255/255. green:243/255. blue:207/255. alpha:1];
        
        UIImageView *markView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 4, 24, 24)];
        markView.image = [UIImage imageNamed:@"operationbox_fail_web"];
        markView.backgroundColor = [UIColor clearColor];
        [header addSubview:markView];
        
        NSString *text = @"未连接";
  
        if (gateway.disconnectReason == ErrorUser) {
            text = [text stringByAppendingString:@",用户名错误。"] ;
        }
        else if (gateway.disconnectReason == ErrorPswd) {
            text = [text stringByAppendingString:@",密码错误。"];
        }
        else if (gateway.disconnectReason == ErrorSn) {
            text = [text stringByAppendingString:@",序列号错误。"];
        }
        else if (gateway.disconnectReason == ErrorNetwork) {
            text = @"网络未连接";
        }
        else {
            
        }
        
        
        UIFont *font = [UIFont boldSystemFontOfSize:14];
        CGSize size = [text sizeWithFont:font constrainedToSize:CGSizeMake(CGRectGetWidth(self.view.frame), PROMPT_VIEW_HEIGHT)];
        UILabel *hintText = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(markView.frame)+4, (CGRectGetHeight(header.frame)-size.height)/2, size.width, size.height)];
        hintText.backgroundColor = [UIColor clearColor];
        hintText.textColor = [UIColor blackColor];
        hintText.font = font;
        hintText.text = text;
        [header addSubview:hintText];
        
        _promptView = header;
        [self.view addSubview:_promptView];
        
        //添加点击响应
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDisconnectView)];
        [_promptView addGestureRecognizer:tapGesture];
        
        CGRect f =  _expView.frame;
        f.origin.y = PROMPT_VIEW_HEIGHT;
        
        [UIView animateWithDuration:0 animations:^{
            
            _promptView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), PROMPT_VIEW_HEIGHT);
            
            _expView.frame = f;

            
        }completion:^(BOOL finished){
            
        }];
    }
    else if (!yesOrNo && _promptView) {//隐藏断线连接提示

        CGRect f =  _expView.frame;
        f.origin.y = 0;
        
        [UIView animateWithDuration:0 animations:^{
            
            _promptView.frame = CGRectMake(0, -PROMPT_VIEW_HEIGHT, CGRectGetWidth(self.view.frame), PROMPT_VIEW_HEIGHT);

            _expView.frame = f;
            
        }completion:^(BOOL finished){
            if (finished) {
                [_promptView removeFromSuperview];
                
                _promptView = nil;
            }
            
        }];
        
    }
    
//    NSLog(@"displaySHDsiconnectView end");
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

- (void)observeGateway:(SHGateway *)gateway
{
    NSLog(@"%s %@",__func__,gateway.serialNumber);
    
    [gateway addObserver:self forKeyPath:@"shFetchingStep" options:0 context:NULL];
    [gateway addObserver:self forKeyPath:@"status" options:0 context:NULL];
}

- (void)removeObserveGateway:(SHGateway *)gateway
{
    NSLog(@"%s %@",__func__,gateway.serialNumber);
    
    [gateway removeObserver:self forKeyPath:@"shFetchingStep"];
    [gateway removeObserver:self forKeyPath:@"status"];
}

#pragma mark - Notification


//- (void)reachabilityChanged:(NSNotification *)ntf
//{
//    Reachability *reach = ntf.object;
//    
//    if (reach.isReachable) {
//        
//    }
//    else {
//        [self dis]
//    }
//}



- (void)handleEditGatewayNtf:(NSNotification *)ntf
{
    SHGateway *gateway = [[ntf userInfo] objectForKey:EditGatewayNoticationKey];
    
    NSInteger index = [_gateways indexOfObject:gateway];
    
    if (index == _selectedGatewayIndex) {
        _titleLabel.text = gateway.name;//刷新网关名称
        
        if (gateway.shFetchingStep != SHFetchingStepFinished ) {
            [self showWaitingStatus];
        }
        else {
            [self catForWholeHouseCtrl];
        }
        
        [_expView reloadData];//刷新界面
        
        [self showCurrentGatewayConnectStatus];//显示网关连接状态
    }
}

- (void)handleRemoveGatewayNtf:(NSNotification *)ntf
{
    SHGateway *gateway = [[ntf userInfo] objectForKey:DelGatewayNotificationKey];
    
    if (gateway) {
        
        NSInteger removeIndex = [_gateways indexOfObject:gateway];
        
        [self removeObserveGateway:gateway];
        [_gateways removeObject:gateway];
        
        
        if (removeIndex < _selectedGatewayIndex) {//删除的是当前网关的前面的
            _selectedGatewayIndex--;
            
            if (_selectedGatewayIndex == 0) {//到了最前面一个
                _leftArrow.enabled = NO;
            }
            
        }
        else if (removeIndex > _selectedGatewayIndex) {//删除的是当前网关的后面的
            if (_selectedGatewayIndex+1 == [_gateways count]) {//到了最后一个
                _rightArrow.enabled = NO;
            }
            

        }
        else {//删除的是当前的网关，显示第一个网关
            _selectedGatewayIndex = 0;
            
            //左右箭头
            if ([_gateways count]  <=1 ) {
                
                _rightArrow.hidden = YES;
                _leftArrow.hidden = YES;
            }
            else if ([_gateways count] >= 2) {
                _rightArrow.enabled = YES;
                _leftArrow.enabled = NO;
                
            }
            
            //标题
            if ([_gateways count] == 0) {
                _titleLabel.text = @"智能家居";
            }
            else {
                 SHGateway *displayGateway = [self selectedGateway];
                _titleLabel.text = displayGateway.name;
                
               
            }
            
            //刷新
            [_expView reloadData];
            
            [self showCurrentGatewayConnectStatus];
            
        }
       
    }
    
}

- (void)handleBindGatewayNtf:(NSNotification *)ntf
{
    SHGateway *gateway = [[ntf userInfo] objectForKey:BindGatewayNotificationKey];
    
    if (gateway) {
        
        //当前没有网关
        if ([_gateways count] == 0) {
            _titleLabel.text = gateway.name;
            _selectedGatewayIndex = 0;
        }
        
        [_gateways addObject:gateway];
        

        //左右按钮是否显示
        if ([_gateways count] > 1) {
            _rightArrow.hidden = NO;
            _leftArrow.hidden = NO;
        }
        
        //右边按钮使能
        if (_selectedGatewayIndex == [_gateways count] - 1) {
            _rightArrow.enabled = NO;
            
        }
        else {
            _rightArrow.enabled = YES;
        }
        
        //左边按钮使能
        if (_selectedGatewayIndex == 0) {
            _leftArrow.enabled = NO;
        }
        else {
            _leftArrow.enabled = YES;
        }

        //注册观察者
        [self observeGateway:gateway];
    }
}



- (void)handleUpnpDisconnect:(NSNotification *)ntf
{
    NSLog(@"handleUpnpDisconnect");
    
    [self displaySHDsiconnectView:YES gateway:nil];
}




- (void)handleGetGatewaysNtf:(NSNotification *)ntf
{
    //先移除
    for (SHGateway *gateway in _gateways)
    {
        [self removeObserveGateway:gateway];
    }
    [_gateways removeAllObjects];
    
    //再添加
    if ([User currentUser].isLocalMode) {
        [_gateways addObjectsFromArray:[SHLocalControl getInstance].gatewayList];
    }
    else {
        [_gateways addObjectsFromArray:[NetAPIClient sharedClient].gatewayList];

    }
    
    [self refreshTopView];
    
    for (SHGateway *gateway in _gateways)
    {
        [self observeGateway:gateway];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
   
    SHGateway *gateway = (SHGateway *)object;
    NSInteger index = [_gateways indexOfObject:gateway];
    
//    NSLog(@"%s %@ change fstep: %d sn: %@",__FUNCTION__,keyPath,gateway.shFetchingStep,gateway.serialNumber);
    
    if (index == _selectedGatewayIndex) {//当前显示的网关
        if ([keyPath isEqualToString:@"shFetchingStep"]) {
            if (gateway.shFetchingStep == SHFetchingStepFinished) {//获取配置完成
                
  
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                
                [self hideHud];
                
                //全宅控制分类
                [self catForWholeHouseCtrl];
                
                //            //刷新顶部网关列表
                //             [self refreshTopView];
                
                //刷新_expView
                [_expView reloadData];
            }
            else {
                [self showWaitingStatus];
            }
        }
        else if([keyPath isEqualToString:@"status"]) {
            if (gateway.status == GatewayStatusLoginFailed || gateway.status == GatewayStatusOffline) {
                [self displaySHDsiconnectView:YES gateway:gateway];
            }
            else if (gateway.status == GatewayStatusOnline) {
                [self displaySHDsiconnectView:NO gateway:gateway];
            }
        }

    }
    
}



#pragma mark ExpansiveViewDataSource
- (NSInteger)numberOfRowsInExpansiveView:(ExpansiveView *)expansiveView
{
    return 3;
}

- (ExpansiveCell *)expansiveView:(ExpansiveView *)expansiveView cellForRow:(NSInteger)row
{
    ExpansiveCell *cell = [[ExpansiveCell alloc] initWithFrame:CGRectZero];
    
    NSString *iconName = nil;
    NSString *title = nil;
    NSString *status = nil;
    NSString *indicator = @"";
    
    UIView *contentView = nil;
    
    switch (row) {
        case 0:
        {
            iconName = @"scene.png";
            title = @"情景模式";
            
            NSUInteger tmpCount = [self numberOfSceneModes];
            
            status = [NSString stringWithFormat:@"%d/%d",tmpCount,tmpCount];
            
            
            indicator = @"down_arrow.png";
            contentView = [self viewForSceneMode];
            
            [self setSceneSelected];
        }
            
            break;

        case 1:
        {

            iconName = @"alarm_setting.png";
            title = @"报警设置";
            
            NSUInteger tmpCount = [self numberOfAlarmZones];
            status = [NSString stringWithFormat:@"%d/%d",tmpCount,tmpCount];
            indicator = @"down_arrow.png";
            contentView = [self viewForAlarmSetting];
        }
            
            break;
            
        case 2:
        {
            iconName = @"sh.png";
            title = @"单点控制";
            
            
            NSUInteger tmpCount = [self numberOfSHDevice];
            
            status = [NSString stringWithFormat:@"%d/%d",tmpCount,tmpCount];
            indicator = @"down_arrow.png";
            contentView = [self viewForDeviceCtrl];
            
        }
            
            break;
        default:
            break;
    }
    
    HeaderView *header = [[HeaderView alloc]  initWithFrame:CGRectZero];
    [header setIcon:[UIImage imageNamed:iconName] title:title status:status indicator:[UIImage imageNamed:indicator]];
    
    cell.headerView = header;
    
    cell.contentView = contentView;
    
    return cell;
}

#pragma mark ExpansiveViewDelegate

- (NSUInteger)expansiveView:(ExpansiveView *)expansiveView heightForHeaderAtRow:(NSUInteger)row
{
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 100);
}

- (NSUInteger)expansiveView:(ExpansiveView *)expansiveView heightForContentAtRow:(NSUInteger)row
{
   
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 100);
}

- (void)expansiveView:(ExpansiveView *)expansiveView openHeader:(BOOL)yesOrNo atRow:(NSInteger)row
{
    
    
    if (row == 2 && !yesOrNo) {
        
        [_gridView closeBox];
        
    }
    else {
        // [[NSNotificationCenter defaultCenter] postNotificationName:DisconnectNotification object:nil];
    }
    
}

#pragma  BoxViewDelegate
- (void)boxViewPlayVideo:(NSString *)cameraId
{

}



#pragma mark SliderViewDelegate

- (void)sliderView:(SliderView *)sliderView didSelectItemAtIndex:(NSInteger)index
{
    _catIndex = index;
    
    SHGateway *gateway = [self selectedGateway];
    
//    [_gridView reloadBoxViewAtIndex:[gateway.roomArray count]];
    
    [_gridView reloadWholeHouseCtrlView];
}

#pragma mark GridViewDelegate

- (UIView *)gridView:(GridView *)gridView headerForBoxViewAtIndex:(NSInteger)index
{
    SHGateway *gateway = [self selectedGateway];
    
    if (index == [gateway.roomArray count]) {//全宅
        
//        if (!_sliderView) {
        
            NSInteger width = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 298 : 700;
            _sliderView = [[SliderView alloc] initWithFrame:CGRectMake(0, 0, width, 40)];
            
            [_sliderView buildWithTitles:[_catDeviceDic allKeys]];
            _sliderView.selectedIndex = 0;
            _sliderView.delegate = self;
        
        _catIndex = 0;
//        }

        
        return _sliderView;
    }
    
    return nil;
}

- (void)gridView:(GridView *)gridView didSelectItemAtIndex:(NSInteger)index
{
    SHGateway *gateway = [self selectedGateway];
    
//    if (index != [gateway.roomArray count]) {
//        _catIndex = 0;
//        _sliderView = nil;
//    }
}

- (void)gridView:(GridView *)gridView playVideo:(NSString *)cameraId
{
    NSArray *videoDevices = nil;
    if ([User currentUser].isLocalMode) {
        //videoDevices = [[SHLocalControl getInstance] getVideoDeviceList];
    }
    else {
        SHGateway *gateway = [self selectedGateway];
        videoDevices = gateway.ipcArray;
    }
    
    for ( SHVideoDevice *tempDevice in videoDevices)
    {
        if ([cameraId isEqualToString:tempDevice.deviceId]) {
            [self playVideo:[tempDevice videoUrl]];
            break;
        }
    }

}



- (void)gridView:(GridView *)gridView changeContentHeight:(CGFloat)absHeight
{
    CGSize contentSize = [_expView contentSize];
    contentSize.height += absHeight;
    [_expView resizeContent:contentSize];
}

- (NSArray *)deviceListForGridView:(GridView *)gridView atIndex:(NSInteger)index
{
    SHGateway *gateway = [self selectedGateway];
    
    if (index == [gateway.roomArray count]) {//全宅
        NSArray *catDeviceArray = [_catDeviceDic allValues];
        if ([catDeviceArray count]) {
             return [catDeviceArray objectAtIndex:_catIndex];
        }
        else {
            NSLog(@"no cat device");
            return nil;
        }
       
    }
    
    
    
    return [self deviceListInRoom: (SHRoom *)[gateway.roomArray objectAtIndex:index]];
}

#pragma mark - 其他方法

- (NSArray *)deviceListInRoom:(SHRoom *)room
{
    SHGateway *gateway = [self selectedGateway];
    
    NSMutableArray *roomDevices = [NSMutableArray arrayWithCapacity:1];
    
    for (SHDevice *device in gateway.deviceArray)
    {
        if ([device.roomId isEqualToString:room.layoutId]) {
            [roomDevices addObject:device];
        }
    }
    
    return roomDevices;
}

- (void)playVideo:(NSString *)url
{
    if (!_videoViewBgd) {
        _videoViewBgd = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.view.frame)-EXP_CELL_WIDTH)/2, 0, EXP_CELL_WIDTH, VIDEO_VIEW_H)];
        
        _videoWnd = [[VideoWnd alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_videoViewBgd.frame), CGRectGetHeight(_videoViewBgd.frame))];
        _videoWnd.backgroundColor = [UIColor blackColor];
        [_videoViewBgd addSubview:_videoWnd];
        
        NSInteger originX = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 260 : 600);
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        closeBtn.frame = CGRectMake(originX, 0, 40, 40);
        [closeBtn setImage:[UIImage imageNamed:@"video_close_normal.png"] forState:UIControlStateNormal];
        [closeBtn setImage:[UIImage imageNamed:@"video_close_hl.png"] forState:UIControlStateHighlighted];
        [closeBtn addTarget:self action:@selector(closeVideo) forControlEvents:UIControlEventTouchUpInside];
        [_videoViewBgd addSubview:closeBtn];
        
    }
    
    if (!_isVideoShow) {
        [self.view addSubview:_videoViewBgd];
        _isVideoShow = YES;
        
        [_expView setContentInsets:UIEdgeInsetsMake(VIDEO_VIEW_H, 0, 0, 0)];
        
    }
    
    
    
    [self performSelector:@selector(startVideo:) withObject:url afterDelay:0.3];//先显示
}

- (void)startVideo:(NSString *)url
{
#ifndef SIMULATOR
    
    float fplayScale = 1.0;
    if ([UIScreen instancesRespondToSelector:@selector(scale)])
    {
        fplayScale = (CGFloat)[[UIScreen mainScreen] scale];
    }
    
    
    int ret = [zw_dssdk dssdk_rtv_start:(__bridge void *)(_videoWnd):(char*)[url UTF8String]:fplayScale];
    if (ret != 1) {
        NSString *msg = [NSString stringWithFormat:@"%@(错误码:%d)",url,ret];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"打开视频失败" message:msg delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alert show];
    }
    
    
#endif
}

- (void)closeVideo
{
#ifndef SIMULATOR
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(_videoWnd)];
#endif
    
    [_videoViewBgd removeFromSuperview];
    _isVideoShow = NO;
    
    [_expView setContentInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    
}

- (void)catForWholeHouseCtrl
{
    
    [_catDeviceDic removeAllObjects];
    
    NSMutableArray *lightArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *curtainArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *airconditionArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *groundHeatArray = [NSMutableArray arrayWithCapacity:1];
    
    SHGateway *gateway = [self selectedGateway];
    
    for (SHDevice *device in gateway.deviceArray)
    {
        
        if ([device.type isEqualToString:CSHIA_DEVICE_LIGHT_SWITCH] || [device.type isEqualToString:SH_DEVICE_COMMLIGHT]) {
            [lightArray addObject:device];

        }
        else if ([device.type isEqualToString:CSHIA_DEVICE_LIGHT_DIMMER] || [device.type isEqualToString:SH_DEVICE_LEVELLIGHT]) {
            [lightArray addObject:device];

        }
        else if ([device.type isEqualToString:CSHIA_DEVICE_CURTAIN_SWITCH] || [device.type isEqualToString:SH_DEVICE_CURTAIN]) {
            [curtainArray addObject:device];

        }
        else if ([device.type isEqualToString:CSHIA_DEVICE_AIRCONDITION_GENERAL] || [device.type isEqualToString:SH_DEVICE_AIRCONDITION]) {

            [airconditionArray addObject:device];
        }
        else if ([device.type isEqualToString:CSHIA_DEVICE_GROUNDHEAT] || [device.type isEqualToString:SH_DEVICE_GROUNDHEAT]) {
            
            [groundHeatArray addObject:device];
        }
    }
    
    
    if ([airconditionArray count] > 0) {

        [_catDeviceDic setObject:airconditionArray forKey:@"空调"];
    }
    if ([groundHeatArray count] > 0) {
     
        [_catDeviceDic setObject:groundHeatArray forKey:@"地暖"];
    }
    if ([curtainArray count] > 0) {
        

        [_catDeviceDic setObject:curtainArray forKey:@"窗帘"];
    }
    if ([lightArray count] > 0) {
 
        [_catDeviceDic setObject:lightArray forKey:@"灯光"];
    }

    if ([_catDeviceDic count] > 0) {
        
        [_catDeviceDic setObject:[NSArray arrayWithArray:gateway.deviceArray] forKey:@"所有"];
    }
    
}

//情景模式视图
- (UIView *)viewForSceneMode
{
    [_sceneBtns removeAllObjects];
    //_slctSceneIndex = 0;
    
    const NSInteger btn_w = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 36 : 48);
    const NSInteger btn_h = btn_w;
    const NSInteger gap_x = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 150);//两个button之间距离
    const NSInteger gap_y = 20;//两行之间垂直距离
    const NSInteger origin_x = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 10 : 16);
    const NSInteger origin_y = 12;

    UIView *content = [[UIView alloc] initWithFrame:CGRectZero];
    
    SHGateway *gateway = [self selectedGateway];

    
    NSArray *sceneNames = gateway.sceneModeArray;

    
    NSInteger itemNum = [sceneNames count];
    NSInteger numOfPerRow = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 3 : 4);//每行显示多少个
    
    for (NSUInteger i=0; i<itemNum; i++) {
        
        NSString *sceneName = ((SHSceneMode *)[sceneNames objectAtIndex:i]).name;
 
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setImage:[UIImage imageNamed:@"scene_rect.png"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"scene_selected.png"] forState:UIControlStateSelected];
        [btn setImageEdgeInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
        btn.frame = CGRectMake(origin_x+(i%numOfPerRow)*(btn_w+gap_x), origin_y+(i/numOfPerRow)* (gap_y+btn_h), btn_w, btn_h);
        [btn addTarget:self action:@selector(selectScene:) forControlEvents:UIControlEventTouchUpInside];
        [content addSubview:btn];
        
        [_sceneBtns addObject:btn];
        
        NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 13 : 14);
        UIFont *font = [UIFont systemFontOfSize:fontSize];
        NSString *name = sceneName;
        CGSize size = [name sizeWithFont:font constrainedToSize:CGSizeMake(60, btn_h)];
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(btn.frame) , CGRectGetMinY(btn.frame) + (CGRectGetHeight(btn.frame) - size.height)/2, size.width, size.height)];
        lbl.text = name;
        lbl.font = font;
        lbl.textColor = [UIColor blackColor];
        lbl.backgroundColor = [UIColor clearColor];
        [content addSubview:lbl];
        
    }
    
    CGRect frame =  content.frame;
    NSInteger rowNum = itemNum/numOfPerRow + ((itemNum%numOfPerRow) > 0 ? 1 :0);//多少行
    frame.size.height = 2*origin_y+(rowNum-1)*gap_y +rowNum*btn_h;

    content.frame = frame;
    
    return content;
}

- (void)setSceneSelected
{
    if ([_sceneBtns count] > 0 && _slctSceneIndex >= 0) {
        UIButton *btn = [_sceneBtns objectAtIndex:_slctSceneIndex];
        
        btn.selected = YES;
    }
}


- (UIView *)viewForAlarmSetting
{
    
    UIView *content = [[UIView alloc] initWithFrame:CGRectZero];
    
    NSInteger numOfPerRow = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 2 : 4);//每行显示多少个
    
    SHGateway *gateway  = [self selectedGateway];

    NSArray *alarmZones = gateway.alarmZoneArray;
    
    NSInteger numOfZones = [alarmZones count];
    
    if (numOfZones > 0) {
        const NSInteger gap_y = 20;
        const NSInteger gap_x = 10;
        const NSInteger origin_x = 10;
        const NSInteger origin_y = 12;
        NSInteger itemWidth = (EXP_CELL_WIDTH-(numOfPerRow+1)*gap_x)/numOfPerRow;
        NSInteger itemHeight = 30;
        NSInteger nameWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 70);
        NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 13 : 14);
        NSInteger switchGap = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 2 : 4);
        
        for (int i = 0 ; i < numOfZones ; i++) {
            SHAlarmZone *alarmZone = [alarmZones objectAtIndex:i];
            
            AlarmSettingView *alarmView = [[AlarmSettingView alloc] initWithFrame:CGRectMake(origin_x+(i%numOfPerRow)*(itemWidth+gap_x), origin_y+(i/numOfPerRow)* (gap_y+itemHeight), itemWidth, itemHeight)];
            alarmView.alarmZone = alarmZone;
            
//            CGRect nameFrame = CGRectMake(origin_x+(i%numOfPerRow)*(itemWidth+gap_x), origin_y+(i/numOfPerRow)* (gap_y+itemHeight), nameWidth, itemHeight);
//            
//            //NSString *name = [NSString stringWithFormat:@"防区%@",alarmZone.channelId];
//            UILabel *nameLbl = [[UILabel alloc] initWithFrame:nameFrame];
//            nameLbl.text = alarmZone.name;
//            nameLbl.font = [UIFont systemFontOfSize:fontSize];
//            nameLbl.backgroundColor = [UIColor clearColor];
//            [content addSubview:nameLbl];
//            
//            CGRect switchFrame = CGRectMake(CGRectGetMaxX(nameFrame)+switchGap, CGRectGetMinY(nameFrame), 80, 30);
//            UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:switchFrame];
//            aSwitch.tag = TAG_ALARMZONE_SWITCH + i;
//            [aSwitch addTarget:self action:@selector(switchAlarmZone:) forControlEvents:UIControlEventValueChanged];
//            
//            BOOL bOn = [((SHAlarmZoneState *)alarmZone.state).mode isEqualToString:@"Arming"] ? YES : NO;
//            
//            aSwitch.on = bOn;
            [content addSubview:alarmView];
        }
        
        CGRect frame =  content.frame;
        NSInteger rowNum = numOfZones/numOfPerRow + ((numOfZones%numOfPerRow) > 0 ? 1 :0);//多少行
        frame.size.height = 2*origin_y+(rowNum-1)*gap_y +rowNum*itemHeight;
        
        content.frame = frame;
    }

    
    return content;
}


- (SHGateway *)selectedGateway
{
    if ([_gateways count]) {
        return [_gateways objectAtIndex:_selectedGatewayIndex];
    }
    
    return nil;
}

- (void)switchAlarmZone:(UISwitch *)sender
{

    UISwitch *theSwitch = (UISwitch *)sender;
    
    NSInteger index = theSwitch.tag - TAG_ALARMZONE_SWITCH;
    
    
    SHGateway *gateway = [self selectedGateway];
    
    SHAlarmZone *alarmZone = [gateway.alarmZoneArray objectAtIndex:index];
    
//    NSString *mode = [(SHAlarmZoneState *)alarmZone.state mode];
//    if ([mode isEqualToString:@"Arming"]) {
//        mode = @"Disarming";
//    }
//    else {
//        mode = @"Arming";
//    }
    
    NSString *strMode = sender.on ? @"Arming" : @"Disarming";
    
    [[SHLocalControl getInstance] setAlarmMode:alarmZone.deviceId gatewayId:gateway.serialNumber mode:strMode successCallback:^{
        NSLog(@"set alarmMode success %@",alarmZone.deviceId);

    }failureCallback:^{
        NSLog(@"set alarmMode failed %@",alarmZone.deviceId);
    }];
    
}

//家居控制视图
- (UIView *)viewForDeviceCtrl
{
    
    NSMutableArray *roomNameArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *roomIconArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *selectedIconArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *statusArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *bgdImageArray = [NSMutableArray arrayWithCapacity:1];
    
    NSString *name = nil;
    UIImage *icon = nil;
    UIImage *selectedIcon = nil;
    UIImage *bgdImage = [UIImage imageNamed:@"room_selected.png"];
    NSString *status = nil;
    
    SHGateway *gateway = [self selectedGateway];
    
    for (SHRoom *layout in gateway.roomArray)
    {
        
        if ([layout.layoutName length]>0) {
            
            name = layout.layoutName;
        }
        else
        {
            name = @"未知";
        }
        
        icon = [self iconForRoom:layout];
        selectedIcon = [self selectedIconForRoom:layout];
        
        NSArray *deviceList = [self deviceListInRoom:layout];
        
        status = [NSString stringWithFormat:@"(%lu/%lu)",(unsigned long)[deviceList count],(unsigned long)[deviceList count]];
        
        [roomNameArray addObject:name];
        [roomIconArray addObject:icon];
        [selectedIconArray addObject:selectedIcon];
        [statusArray addObject:status];
    }
    
    if ([gateway.roomArray count] > 0) {
        //全宅
        [roomNameArray addObject:@"全宅"];
        [roomIconArray addObject:[UIImage imageNamed:@"whole_house"]];
        [selectedIconArray addObject:[UIImage imageNamed:@"whole_house_selected"]];
        NSInteger devCount = [gateway.deviceArray count];
        [statusArray addObject:[NSString stringWithFormat:@"(%d/%d)",devCount,devCount]];
    }

    
    _gridView = [[GridView alloc] initWithFrame:CGRectZero];
    _gridView.delegate = self;
    _gridView.backgroundColor = [UIColor clearColor];
    
    [_gridView buildWithTitles:roomNameArray subTitles:statusArray icons:roomIconArray selectedIcons:selectedIconArray bgdImages:nil];
    return _gridView;
}

//节点类型: 0 未定义 1 厨房 2 客厅 3 餐厅 4 卧室 5 卫生间 6 书房
- (UIImage *)iconForRoom:(SHRoom *)room
{
    NSString *name = @"parlor1";
    switch (room.type) {
        case 0:
            name = @"bedroom1";
            break;
        case 1:
            name = @"kitchen1.png";
            break;
        case 2:
            name = @"parlor1.png";
            break;
        case 3:
            name = @"dining_room1.png";
            break;
        case 4:
            name = @"bedroom1.png";
            break;
        case 5:
            name = @"washroom1.png";
            break;
        case 6:
            name = @"study1.png";
            break;
        default:
            break;
    }
    
    return [UIImage imageNamed:name];
}

- (UIImage *)selectedIconForRoom:(SHRoom *)room
{
    NSString *name = @"parlor2";
    switch (room.type) {
        case 0:
            name = @"bedroom2";
            break;
        case 1:
            name = @"kitchen2.png";
            break;
        case 2:
            name = @"parlor2.png";
            break;
        case 3:
            name = @"dining_room2.png";
            break;
        case 4:
            name = @"bedroom2.png";
            break;
        case 5:
            name = @"washroom2.png";
            break;
        case 6:
            name = @"study2.png";
            break;
        default:
            break;
    }
    
    return [UIImage imageNamed:name];
}

- (void)selectScene:(UIButton*)sender
{
    if (_slctSceneIndex >= 0 ) {
        UIButton *btn = [_sceneBtns objectAtIndex:_slctSceneIndex];
        btn.selected = NO;
    }
    
    
    sender.selected = YES;
    _slctSceneIndex = [_sceneBtns indexOfObject:sender];
    
    
    [self waitSceneModeCtrl];
    
    SHGateway *gateway = [self selectedGateway];
    
    SHSceneMode *sceneMode = [gateway.sceneModeArray objectAtIndex:_slctSceneIndex];
    [[NetAPIClient sharedClient] setSceneMode:sceneMode.name deviceId:sceneMode.deviceId gatewayId:gateway.serialNumber successCallback:^{
        NSLog(@"set scenemode success %@",sceneMode.deviceId);
    }failureCallback:^{
        NSLog(@"set scenemode failed %@",sceneMode.deviceId);
    }];
    
}

- (void)waitSceneModeCtrl
{
    _hud = [[MBProgressHUD alloc] initWithView:self.view];
    
    _hud.removeFromSuperViewOnHide = YES;
    _hud.labelText = @"情景切换中...";
    _hud.mode = MBProgressHUDModeIndeterminate;
    [self.view addSubview:_hud];
    
    [_hud show:YES];
    [self performSelector:@selector(enableSceneCtrl) withObject:nil afterDelay:3.0];
}

- (void)enableSceneCtrl
{
    
    [_hud hide:YES];
}

@end
