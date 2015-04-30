//
//  EnvironmentalMonitoringController.m
//  eLife
//
//  Created by 陈杰 on 15/1/9.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "EnvironmentalMonitoringController.h"
#import "NetAPIClient.h"
#import "Util.h"
#import "MultiSelectionView.h"
#import "DeviceData.h"
#import "MBProgressHUD.h"

#define CELL_HEIGHT 60
#define REQ_TIMEOUT 10

//正常
#define COLOR_NORMAL [UIColor colorWithRed:219/255. green:153/255. blue:52/255. alpha:1]

//超标
#define COLOR_EXCEEDING [UIColor colorWithRed:194/255. green:0/255. blue:0/255. alpha:1]

//良好
#define COLOR_FINE [UIColor colorWithRed:157/255. green:209/255. blue:0/255. alpha:1]

@interface EnvironmentalMonitoringController () <UITableViewDataSource,UITableViewDelegate,MultiSelectionViewDelegate>
{
    NSUInteger selectedIndex;//选中的网关index
    NSMutableArray *gateways;
    
    MBProgressHUD *_hud;
    
    NSDictionary *dataSource;//读到得环境监测信息
}

@end

@implementation EnvironmentalMonitoringController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        gateways = [NSMutableArray arrayWithCapacity:1];
       
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [gateways addObjectsFromArray:[NetAPIClient sharedClient].gatewayList];
    
    for (SHGateway *gateway in gateways)
    {
        [gateway addObserver:self forKeyPath:@"shFetchingStep" options:0 context:NULL];
    }
    
    if ([gateways count]) {
        SHGateway *firstGateway = [gateways objectAtIndex:0];
        if (firstGateway.shFetchingStep == SHFetchingStepFinished) {
            [self readMeterAtGateway:firstGateway];
        }
        else {
            
            [self showWaitingStatus];
        }
    }
    else {
        [self showNoAmmeterHint];
    }

    
    
    //导航栏
    [Util unifyStyleOfViewController:self withTitle:@"环境监测"];
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
    
    //设置背景
    UIImageView *bgdView = [[UIImageView alloc] initWithFrame:self.tableView.bounds];
    bgdView.image = [UIImage imageNamed:@"env_bgd"];
    self.tableView.backgroundView = bgdView;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    
    for (SHGateway *gateway in gateways)
    {
        [gateway removeObserver:self forKeyPath:@"shFetchingStep"];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)swipeRight
{
    [self goBack];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
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
            [self readMeterAtGateway:tempGateway];
        }
    }
}


#pragma mark - UITableView

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 120;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 120)];
    header.backgroundColor = [UIColor clearColor];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(tableView.bounds)-160, 60, 160-10, 24)];
    lbl.textColor = [UIColor blackColor];
    lbl.font = [UIFont systemFontOfSize:15];
    lbl.backgroundColor = [UIColor clearColor];
    
    NSString *temp = [dataSource objectForKey:@"Temperature"];
    if (temp) {
        NSInteger vl = [temp integerValue];
        temp = [NSString stringWithFormat:@"温度%d℃",vl];
    }
    else {
        temp = @"温度--";
    }
    
    NSString *humidity = [dataSource objectForKey:@"Humidity"];
    if (humidity) {
        NSInteger vl = [humidity integerValue];
        humidity = [NSString stringWithFormat:@"湿度%d%%",vl];
    }
    else {
        humidity = @"湿度--";
    }
    
    NSString *displayText = [NSString stringWithFormat:@"%@   %@",temp,humidity];
    lbl.text = displayText;
    [header addSubview:lbl];
    
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(lbl.frame), CGRectGetMaxY(lbl.frame), CGRectGetWidth(lbl.frame), 1)];
    sep.backgroundColor = [UIColor grayColor];
    sep.alpha = 0.5;
    [header addSubview:sep];
    
    
    return header;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  5;
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
    
    
    NSString *itemName = nil;
    NSString *itemNameDetail = nil;
    NSString *itemValue = nil;
    NSString *evaluateTxt = nil;
    CGFloat fValue = 0;
    
    if (indexPath.row == 0) {
        itemName = @"空气洁净度";
        itemNameDetail = @"颗粒物PM2.5";
        itemValue = [dataSource objectForKey:@"PM25"];
        if (!itemValue) {
            itemValue = @"--";
            evaluateTxt = @"--";
        }
        else {
            fValue = [itemValue floatValue];
            itemValue = [NSString stringWithFormat:@"%.1fUG",fValue];
            if (fValue > 75) {
                evaluateTxt = @"超标";
            }
            else if (fValue < 35)
            {
                 evaluateTxt = @"很好";
            }
            else {
                evaluateTxt = @"正常";
            }
        }
    }
    else if (indexPath.row == 1) {
        itemName = @"空气安全度";
        itemNameDetail = @"甲醛HCHO";
        itemValue = [dataSource objectForKey:@"HCHO"];
        if (!itemValue) {
            itemValue = @"--";
            evaluateTxt = @"--";
        }
        else {
            fValue = [itemValue floatValue];
            itemValue = [NSString stringWithFormat:@"%.1fPPB",fValue];
            if (fValue > 300) {
                evaluateTxt = @"超标";
            }
            else if (fValue < 100)
            {
                evaluateTxt = @"很好";
            }
            else {
                evaluateTxt = @"正常";
            }
        }
    }
    else if (indexPath.row == 2) {
        itemName = @"空气健康度";
        itemNameDetail = @"挥发性有机物VOC";
        itemValue = [dataSource objectForKey:@"VOC"];
        if (!itemValue) {
            itemValue = @"--";
            evaluateTxt = @"--";
        }
        else {
            fValue = [itemValue floatValue];
            itemValue = [NSString stringWithFormat:@"%.1fPPB",fValue];
            if (fValue > 600) {
                evaluateTxt = @"超标";
            }
            else if (fValue < 300)
            {
                evaluateTxt = @"很好";
            }
            else {
                evaluateTxt = @"正常";
            }
        }
    }
    else if (indexPath.row == 3) {
        itemName = @"空气新鲜度";
        itemNameDetail = @"二氧化碳CO2";
        itemValue = [dataSource objectForKey:@"CO2"];
        if (!itemValue) {
            itemValue = @"--";
            evaluateTxt = @"--";
        }
        else {
            fValue = [itemValue floatValue];
            itemValue = [NSString stringWithFormat:@"%.1fPPM",fValue];
            if (fValue > 2000) {
                evaluateTxt = @"超标";
            }
            else if (fValue < 1000)
            {
                evaluateTxt = @"很好";
            }
            else {
                evaluateTxt = @"正常";
            }
        }
    }
    else if (indexPath.row == 4) {
        itemName = @"光线明亮度";
        itemNameDetail = @"亮度ILLUMINANCE";
        itemValue = [dataSource objectForKey:@"Illuminance"];
        if (!itemValue) {
            itemValue = @"--";
            evaluateTxt = @"--";
        }
        else {
            fValue = [itemValue floatValue];
            itemValue = [NSString stringWithFormat:@"%.1fLX",fValue];
            if (fValue > 60) {
                evaluateTxt = @"太亮";
            }
            else if (fValue < 10) {
                evaluateTxt = @"太暗";
            }
            else if (fValue < 50 && fValue > 20) {
                evaluateTxt = @"很好";
            }
            else {
                evaluateTxt = @"正常";
            }
        }
    }

   
    
    NSInteger nameFontSize = 16;
    NSInteger nameDetailFontSize = 13;
    NSInteger valueFontSize = 16;

    
    NSInteger nameHeight = 24;
    NSInteger nameDetailHeight = 20;
    NSInteger nameOriginY = (CELL_HEIGHT-nameHeight-nameDetailHeight)/2;

    
    UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(16, nameOriginY, 130, nameHeight)];
    nameLbl.text = itemName;
    nameLbl.font = [UIFont systemFontOfSize:nameFontSize];
    nameLbl.textColor = [UIColor blackColor];
    nameLbl.textAlignment = NSTextAlignmentLeft;
    nameLbl.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:nameLbl];
    
    UILabel *detailNameLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(nameLbl.frame), CGRectGetMaxY(nameLbl.frame), CGRectGetWidth(nameLbl.frame), nameDetailHeight)];
    detailNameLbl.text = itemNameDetail;
    detailNameLbl.font = [UIFont systemFontOfSize:nameDetailFontSize];
    detailNameLbl.textColor = [UIColor grayColor];
    detailNameLbl.textAlignment = NSTextAlignmentLeft;
    detailNameLbl.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:detailNameLbl];
    
    UIColor *evaluateColor = COLOR_EXCEEDING;
  
    if ([evaluateTxt isEqualToString:@"正常"]) {
        evaluateColor = COLOR_FINE;
    }
    else if ([evaluateTxt isEqualToString:@"很好"]) {
        evaluateColor = COLOR_FINE;
    }
    
    UILabel *evalLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(tableView.frame)-60, 0, 60, CELL_HEIGHT)];
    evalLbl.text = evaluateTxt;
    evalLbl.font = [UIFont systemFontOfSize:valueFontSize];
    evalLbl.textColor = evaluateColor;
    evalLbl.textAlignment = NSTextAlignmentLeft;
    evalLbl.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:evalLbl];
    
    UILabel *valueLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(evalLbl.frame)-100, 0, 100, CELL_HEIGHT)];
    valueLbl.text = [itemValue stringByAppendingString:@"/"];
    valueLbl.font = [UIFont systemFontOfSize:valueFontSize];
    valueLbl.textColor = [UIColor blackColor];
    valueLbl.textAlignment = NSTextAlignmentRight;
    valueLbl.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:valueLbl];

    
    //自定义分割线
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, CELL_HEIGHT-1, CGRectGetWidth(tableView.frame), 1)];
    sep.backgroundColor = [UIColor grayColor];
    sep.alpha = 0.2;
    [cell.contentView addSubview:sep];
    
    return cell;
    
}

#pragma mark 下拉刷新
-(void)beginToReloadData:(EGORefreshPos)aRefreshPos{
    [super beginToReloadData:aRefreshPos];
    
    NSLog(@"beginToReloadData");
    
    if (aRefreshPos == EGORefreshHeader) {
        // pull down to refresh data
        
        SHGateway *tempGateway = [self selectedGateway];
        [self readMeterAtGateway:tempGateway];
        
        
    }else if(aRefreshPos == EGORefreshFooter){
        // pull up to load more data
        
    }
}

- (void)finishLoadingData
{
    [self finishReloadingData];
}


#pragma mark 其他方法

- (void)readMeterAtGateway:(SHGateway *)gateway
{
    if ([gateway.envMonitorArray count] > 0) {
        [self showWaitingStatus];
        
        SHDevice *device = [gateway.envMonitorArray objectAtIndex:0];
        
        [[NetAPIClient sharedClient] readEnvironmentMonitor:device successCallback:^(NSDictionary *dataDic){
            
            id data = [dataDic objectForKey:@"EnvironmentQuality"];
            
            if ([data isKindOfClass:[NSDictionary class]]) {
                dataSource = data;
            }
            else {
                dataSource = [NSDictionary dictionary];
            }
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            [_hud hide:YES];
            
            
            [self finishLoadingData];
            
            [self.tableView reloadData];
            
        }failureCallback:^{
            dataSource = nil;
            [self finishLoadingData];
            [self.tableView reloadData];
            
            NSLog(@"readEnvironmentMonitor  failed");
            
            _hud.mode = MBProgressHUDModeText;
            _hud.labelText = @"查询失败!";
            
            [_hud hide:YES afterDelay:1.5];
        }];
    }
    else {
        dataSource = nil;
        [self finishLoadingData];
        [self.tableView reloadData];
        
        [self showNoAmmeterHint];
    }
}

- (void)showNoAmmeterHint
{
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"没有环境检测仪!";
    hud.mode = MBProgressHUDModeText;
    [self.navigationController.view addSubview:hud];
    
    [hud show:YES];
    [hud hide:YES afterDelay:1.0];
    
    
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
    if ([gateways count] ) {
        return [gateways objectAtIndex:selectedIndex];
    }
    
    return nil;
}

@end
