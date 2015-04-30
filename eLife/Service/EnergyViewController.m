//
//  UserInfoViewController.m
//  eLife
//
//  Created by mac on 14-7-8.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "EnergyViewController.h"
#import "NetAPIClient.h"
#import "MBProgressHUD.h"
#import "PublicDefine.h"
#import "DeviceData.h"
#import "NotificationDefine.h"
#import "Util.h"
#import "EnergyView.h"
#import "MultiSelectionView.h"

#define REQ_TIMEOUT 10

#define BOTTOM_BAR_H 44

#define TAGP_GATEWAY_BTN 300

@interface EnergyViewController () <UITableViewDataSource,UITableViewDelegate,MultiSelectionViewDelegate>
{
 
    MBProgressHUD *_hud;
    
    BOOL isRefreshing;//正在刷新
    

    NSUInteger selectedIndex;//选中的网关index
    NSMutableArray *_gateways;

    EnergyView *_energyView;

    NSDictionary *_dataDic;
}

@end

@implementation EnergyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGatewayListNtf:) name:GetGatewayListNotification object:nil];
        
        _gateways = [NSMutableArray arrayWithCapacity:1];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
 
    [_gateways addObjectsFromArray:[NetAPIClient sharedClient].gatewayList];
    
    
    
    if ([_gateways count]) {
        SHGateway *firstGateway = [_gateways objectAtIndex:0];
        if (firstGateway.shFetchingStep == SHFetchingStepFinished) {
            [self readMeter:0];
        }
        else {
            
            [self showWaitingStatus];
            
        }
    }
    else {
        [self showNoAmmeterHint];
    }
    
    for (SHGateway *gateway in _gateways)
    {
        [gateway addObserver:self forKeyPath:@"shFetchingStep" options:0 context:NULL];
    }
    
    
    //导航栏
    [Util unifyStyleOfViewController:self withTitle:@"能耗管理"];
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    //右边按钮
    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    addBtn.frame = CGRectMake(0, 0, 44, 44);
    [addBtn addTarget:self action:@selector(chooseAGateway) forControlEvents:UIControlEventTouchUpInside];
    [addBtn setImage:[UIImage imageNamed:@"EditBtn"] forState:UIControlStateNormal];
    UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithCustomView:addBtn];
    self.navigationItem.rightBarButtonItem = rightBtnItem;
    
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    // set header
    [self createHeaderView];
    
    //energyView
    NSString *nibName = [Util nibNameWithClass:[EnergyView class]];
    _energyView = [[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] objectAtIndex:0];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)dealloc
{

    for (SHGateway *gateway in _gateways)
    {
        [gateway removeObserver:self forKeyPath:@"shFetchingStep"];
    }
}

- (void)chooseAGateway
{
    if ([_gateways count] > 0)
    {
        NSMutableArray *titles = [NSMutableArray arrayWithCapacity:1];
        
        for (SHGateway *gateway in _gateways)
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





- (void)readMeter:(NSUInteger)index
{
  
    if ([_gateways count] > 0) {
        
        [self hideHud];

        SHGateway *gateway = [_gateways objectAtIndex:index];
        
        if ([gateway.ammeterArray count] > 0) {
            
            [self showWaitingStatus];
            
            SHDevice *device = [gateway.ammeterArray objectAtIndex:0];
            
            [[NetAPIClient sharedClient] readAmmeterMeter:device successCallback:^(NSDictionary *retDic){
                
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                
                [_hud hide:YES];
                
                _dataDic = retDic;
        
                [self finishLoadingData];
                [self.tableView reloadData];
                
            }failureCallback:^(void){
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                
                _dataDic = nil;
                [self finishLoadingData];
                [self.tableView reloadData];
                
                NSLog(@"finished read meter failed");
                
                _hud.mode = MBProgressHUDModeText;
                _hud.labelText = @"查询失败!";
                
                [_hud hide:YES afterDelay:1.5];
            }];
        }
        else {
            _dataDic = nil;
            [self finishLoadingData];
            [self.tableView reloadData];
            
            [self showNoAmmeterHint];
        }
        
    }
        
}



- (void)showNoAmmeterHint
{
    
    _hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    
    _hud.removeFromSuperViewOnHide = YES;
    _hud.labelText = @"没有电表!";
    _hud.mode = MBProgressHUDModeText;
    [self.navigationController.view addSubview:_hud];
    
    [_hud show:YES];
    [_hud hide:YES afterDelay:1.0];
    
    
}

- (void)displayEnergyData:(NSDictionary *)retDic
{
    
    NSLog(@"read meter data:%@",[retDic description]);
    
    
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY年MM月dd日  HH:mm:ss"];
    NSString *strDate = [formatter stringFromDate:date];
    _energyView.curTime.text = strDate;
 
    NSDictionary *currentDic = [retDic objectForKey:CurrentPeriodKey];
    NSDictionary *currentEnergys = [currentDic objectForKey:@"PositiveEnergys"];
    
    
    NSDictionary *priorDic = [retDic objectForKey:PriorPeriodKey];
    NSDictionary *priorEnergys = [priorDic objectForKey:@"PositiveEnergys"];
    

    float lastDis =  [[priorEnergys objectForKey:@"PositiveActiveEnergy"] floatValue];//上期总示度
    float curDis = [[currentEnergys objectForKey:@"PositiveActiveEnergy"] floatValue];//本期当前总示度
    float curTot = (curDis - lastDis);
    NSString *strCurTotal = [NSString stringWithFormat:@"%.2f度",curTot/100];
    _energyView.curTotal.text = strCurTotal;//本期用电量
    

    

    /*当前显示*/
    
    float posAct = [[currentEnergys objectForKey:@"PositiveActiveEnergy"] floatValue];
    NSString *strPosAct = [NSString stringWithFormat:@"%.2f度",posAct/100];
    _energyView.curDisplay.text = strPosAct;
    
    //本期
    NSString *actviePower = [[currentDic objectForKey:@"InstantPower"] objectForKey:@"ActivePower"];
    NSString *ap = [NSString stringWithFormat:@"%.2f",[actviePower floatValue]/10];
    _energyView.curPower.text = [ap stringByAppendingString:@"瓦"];//当前能耗值（/10 瓦）
    
    //当前总示度尖
    float disSharp = [[currentEnergys objectForKey:@"SharpPositiveActiveEnergy"] floatValue];
    NSString *strDisSharp = [NSString stringWithFormat:@"%.2f度",disSharp/100];
    _energyView.displaySharp.text = strDisSharp;
    
    //峰
    float disPeak = [[currentEnergys objectForKey:@"PeakPositiveActiveEnergy"] floatValue];
    NSString *strDisPeak = [NSString stringWithFormat:@"%.2f度",disPeak/100];
    _energyView.displayPeak.text = strDisPeak;
    
    
    //平
    float disShoulder = [[currentEnergys objectForKey:@"ShoulderPositiveActiveEnergy"] floatValue];
    NSString *strDisShoulder = [NSString stringWithFormat:@"%.2f度",disShoulder/100];
    _energyView.displayShoulder.text = strDisShoulder;
    
    
    //谷
    float disTroughs = [[currentEnergys objectForKey:@"OffPeakPositiveActiveEnergy"] floatValue];
    NSString *strDisTroughs = [NSString stringWithFormat:@"%.2f度",disTroughs/100];
    _energyView.displayTroughs.text = strDisTroughs;

    /*上期*/
    //上期抄表时间
    NSString *strLastTime = [priorEnergys objectForKey:@"LastTime"];
    int iTime = [strLastTime intValue];
    NSDate *lastDate = [NSDate dateWithTimeIntervalSince1970:iTime];
    NSString *formatStrTime = [formatter stringFromDate:lastDate];
    _energyView.lastTime.text = @"上期";
    
    
    //上期总示度尖
    float lastSharp = [[priorEnergys objectForKey:@"SharpPositiveActiveEnergy"] floatValue];
    NSString *strLastSharp = [NSString stringWithFormat:@"%.2f度",lastSharp/100];
    _energyView.lastSharp.text = strLastSharp;
    
    //峰
    float lastPeak = [[priorEnergys objectForKey:@"PeakPositiveActiveEnergy"] floatValue];
    NSString *strLastPeak = [NSString stringWithFormat:@"%.2f度",lastPeak/100];
    _energyView.lastPeak.text = strLastPeak;
    
    
    //平
    float lastShoulder = [[priorEnergys objectForKey:@"ShoulderPositiveActiveEnergy"] floatValue];
    NSString *strLastShoulder = [NSString stringWithFormat:@"%.2f度",lastShoulder/100];
    _energyView.lastShoulder.text = strLastShoulder;
    
    
    //谷
    float lastTroughs = [[priorEnergys objectForKey:@"OffPeakPositiveActiveEnergy"] floatValue];
    NSString *strLastTroughs = [NSString stringWithFormat:@"%.2f度",lastTroughs/100];
    _energyView.lastTroughs.text = strLastTroughs;
    
    //上期总示度
    NSString *strLastDis = [NSString stringWithFormat:@"%.2f度",lastDis/100];
    _energyView.lastDisplay.text = strLastDis;
    
    _energyView.lastTotal.text = @"--";
    
    
    /*本期用电*/
    
    //本期尖
    float curPeriodSharp = disSharp-lastSharp;
     _energyView.curPeriodSharp.text = [NSString stringWithFormat:@"%.2f度",curPeriodSharp/100];
    
    //本期峰
    float curPeriodPeak = disPeak-lastPeak ;
    _energyView.curPeriodPeak.text = [NSString stringWithFormat:@"%.2f度",curPeriodPeak/100];
    
    //本期平
    float curPeriodShoulder =  disShoulder-lastShoulder;
    _energyView.curPeriodShoulder.text = [NSString stringWithFormat:@"%.2f度",curPeriodShoulder/100];
    
    //本期谷
    float curPeriodTrough = disTroughs - lastTroughs ;
    _energyView.curPeriodTroughs.text = [NSString stringWithFormat:@"%.2f度",curPeriodTrough/100];
   
}





- (void)swipeRight
{
    [self goBack];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark MultiSelectionViewDelegate

- (void)multiSelectionView:(MultiSelectionView *)multiSelectionView didSelectedAtIndex:(NSInteger)index
{
    if (index != selectedIndex) {
        selectedIndex = index;
        
        SHGateway *tempGateway = [self selectedGateway];
        
        if (tempGateway.shFetchingStep != SHFetchingStepFinished ) {
            [self showWaitingStatus];
        }
        else {
            [self readMeter:selectedIndex];
        }
    }
}


#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CGRectGetHeight(_energyView.bounds);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    for (UIView *v in [cell.contentView subviews]) {
        [v removeFromSuperview];
    }
    
//    CGRect frame = _energyView.frame;
//    frame.origin.x = (CGRectGetWidth(self.view.frame) - CGRectGetWidth(frame))/2;
//    _energyView.frame = frame;
    
    [cell.contentView addSubview:_energyView];
    
    [self displayEnergyData:_dataDic];
    
    return cell;
    
}

#pragma mark 下拉刷新
-(void)beginToReloadData:(EGORefreshPos)aRefreshPos{
	[super beginToReloadData:aRefreshPos];
    
    NSLog(@"beginToReloadData");
    
    if (aRefreshPos == EGORefreshHeader) {
        // pull down to refresh data

        [self readMeter:selectedIndex];

        
    }else if(aRefreshPos == EGORefreshFooter){
        // pull up to load more data
        
    }
}

- (void)finishLoadingData
{
    [self finishReloadingData];
}




- (void)showWaitingStatus
{
    NSLog(@"showWaitingStatus");
    
    [_hud hide:YES];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    _hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    
    _hud.removeFromSuperViewOnHide = YES;
    _hud.labelText = @"请稍后...";
    _hud.mode = MBProgressHUDModeIndeterminate;
    [self.navigationController.view addSubview:_hud];
    
    [_hud show:YES];
    [self performSelector:@selector(reqTimeout) withObject:nil afterDelay:REQ_TIMEOUT];
    
//    [self beginToReloadData:EGORefreshHeader];
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
    [_hud hide:YES];
    _hud = nil;
}

- (SHGateway *)selectedGateway
{
    if ([_gateways count] ) {
        return [_gateways objectAtIndex:selectedIndex];
    }
    
    return nil;
}

#pragma mark 通知处理

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    SHGateway *gateway = (SHGateway *)object;
    NSInteger index = [_gateways indexOfObject:gateway];
    
    if (index == selectedIndex) {//当前显示的网关
        if (gateway.shFetchingStep == SHFetchingStepFinished) {//获取配置完成
            
            [self readMeter:selectedIndex];
            
            
        }
    }
    
}





- (void)handleGetDeviceListNtf:(NSNotification *)ntf
{
   
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [_hud hide:YES];
    _hud = nil;
  
    [_gateways removeAllObjects];
    NSArray *tempArray = [NetAPIClient sharedClient].gatewayList;
    [_gateways addObjectsFromArray:tempArray];
    
    
}


@end
