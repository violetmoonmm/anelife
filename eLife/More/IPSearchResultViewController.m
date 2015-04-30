//
//  IPSearchResultViewController.m
//  eLife
//
//  Created by mac mini on 14/10/23.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "IPSearchResultViewController.h"
#import "DeviceData.h"
#import "Util.h"
#import "GatewayListViewController.h"
#import "AddGatewayViewController.h"
#import "NotificationDefine.h"
#import "MBProgressHUD.h"
#import "User.h"
#import "NetAPIClient.h"
#import "MBProgressHUD.h"
#import "NetReachability.h"


#define SCAN_SEC 5

@interface IPSearchResultViewController () <UITableViewDataSource,UITableViewDelegate>
{
    IBOutlet UITableView *tblView;
    
    NSMutableArray *dataSource;
    
    NSMutableArray *gatewayList;
    
    MBProgressHUD *hud;
}

@end

@implementation IPSearchResultViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIpSearchNtf:) name:IPSearchNotification object:nil];
        
        dataSource = [NSMutableArray arrayWithCapacity:1];
        gatewayList = [NSMutableArray arrayWithCapacity:1];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    [Util unifyStyleOfViewController:self withTitle:@"局域网网关"];
    
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    UIButton *refreshBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    refreshBtn.frame = CGRectMake(0, 0, 44, 44);
    [refreshBtn addTarget:self action:@selector(searchDevice) forControlEvents:UIControlEventTouchUpInside];
    [refreshBtn setImage:[UIImage imageNamed:@"RefreshBtn.png"] forState:UIControlStateNormal];
    refreshBtn.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    //    [returnBtn setTitle:@"`返回" forState:UIControlStateNormal];
    UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithCustomView:refreshBtn];
    self.navigationItem.rightBarButtonItem = rightBtnItem;
    
    tblView.backgroundView = nil;
    tblView.backgroundColor = [UIColor clearColor];


    [gatewayList addObjectsFromArray:[NetAPIClient sharedClient].gatewayList];
    

    if (![self startSearch]) {
        [self showStartFailedHint:@"开始扫描失败"];
    }
    else {
        [self searchDevice];
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    tblView.dataSource = nil;
    tblView.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
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
    [[NetAPIClient sharedClient] stopSearch];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)rescan
{
    [[NetAPIClient sharedClient] stopSearch];
    
    if (![self startSearch]) {
        [self showStartFailedHint:@"开始扫描失败"];
    }
    else {
        [self searchDevice];
    }
}

- (BOOL)startSearch
{
    return [[NetAPIClient sharedClient] startSearch];
    
}


- (void)searchDevice
{
    
    [dataSource removeAllObjects];
    [tblView reloadData];
    
    if (![NetReachability isNetworkReachable]) {
        [self showStartFailedHint:@"未连接到网络!"];
    }
    else if ([NetReachability isReachableViaWWAN]) {
        [self showStartFailedHint:@"3G/4G模式下无法使用此功能!"];
    }
    else if (![[NetAPIClient sharedClient] searchDevice]) {
        [self showStartFailedHint:@"扫描失败！"];
    }
    else {
        
        
        hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:hud];
        hud.removeFromSuperViewOnHide = YES;
        hud.labelText = @"扫描中...";
        hud.mode = MBProgressHUDModeIndeterminate;
        [hud show:YES];
        
        [self performSelector:@selector(stopScan) withObject:nil afterDelay:SCAN_SEC];
        
    }
}


- (void)stopScan
{
//    [[NetAPIClient sharedClient] stopSearch];
    
    if ([dataSource count] > 0)
    {
        hud.mode = MBProgressHUDModeCustomView;
        
        hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
        
        hud.labelText = @"扫描完成";
        
        [hud hide:YES afterDelay:1.0];
        
    }
    else {
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"未扫描到设备";
        
        [hud hide:YES afterDelay:1.0];
    }
    

}

- (void)showStartFailedHint:(NSString *)info
{
    
    hud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeText;
    hud.labelText = info;
    [hud show:YES];
    
    [hud hide:YES afterDelay:1.5];
}

- (void)handleIpSearchNtf:(NSNotification *)ntf
{
    //[NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    SHGateway *device = [[ntf userInfo] objectForKey:IPSearchNotificationDataKey];
    
    if (device) {
        
        BOOL isContained = NO;//是否已经添加过了该网关
        for (SHGateway *gateway in dataSource) {
            if (NSOrderedSame == [gateway.serialNumber compare:device.serialNumber options:NSCaseInsensitiveSearch]) {
                isContained = YES;
                break;
            }
        }
        
        if (!isContained) {
            [dataSource addObject:device];
            
            [tblView reloadData];
        }

    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return [dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *identifier = @"gatewaylist";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    // Configure the cell...
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    for (UIView *v in [cell.contentView subviews])
    {
        [v removeFromSuperview];
    }
    
    SHGateway *gateway = [dataSource objectAtIndex:indexPath.row];
    
    //序列号
    NSString *titleTxt = gateway.serialNumber;
    NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 15 : 16);
    CGSize size = [titleTxt sizeWithFont:[UIFont systemFontOfSize:fontSize] constrainedToSize:CGSizeMake(200, 30)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 2, size.width, size.height)];
    titleLabel.text = titleTxt;
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.highlightedTextColor = [UIColor whiteColor];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [cell.contentView addSubview:titleLabel];
    
    //地址
    NSString *detailTxt = gateway.addr;
    NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 4 : 4);
    fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 13: 13);
    size = [detailTxt sizeWithFont:[UIFont systemFontOfSize:fontSize] constrainedToSize:CGSizeMake(200, 24)];
    UILabel *detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(titleLabel.frame), CGRectGetMaxY(titleLabel.frame)+spacingY, size.width, size.height)];
    detailLabel.text = detailTxt;
    detailLabel.textColor = [UIColor blackColor];
    detailLabel.highlightedTextColor = [UIColor whiteColor];
    detailLabel.backgroundColor = [UIColor clearColor];
    detailLabel.font = [UIFont systemFontOfSize:fontSize];
    [cell.contentView addSubview:detailLabel];

    
    //是否已经添加
    BOOL haveAdded = NO;
    for (SHGateway *tempGateway in gatewayList) {
        if (NSOrderedSame == [tempGateway.serialNumber compare:gateway.serialNumber options:NSCaseInsensitiveSearch]) {
            haveAdded = YES;
            break;
        }
    }
    
    if (haveAdded) {
        NSInteger cellWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 300 : 768);
        fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 13 : 13);
        NSInteger spacingX = 4;
        NSString *infoText = @"已添加";
        size = [infoText sizeWithFont:[UIFont systemFontOfSize:fontSize] constrainedToSize:CGSizeMake(60, 24)];
        
        UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(cellWidth - size.width - spacingX, CGRectGetMinY(titleLabel.frame), size.width, 22)];
        
        statusLabel.text = infoText;
        statusLabel.textColor = [UIColor blackColor];
        statusLabel.textAlignment = NSTextAlignmentRight;
        statusLabel.highlightedTextColor = [UIColor whiteColor];
        statusLabel.backgroundColor = [UIColor clearColor];
        statusLabel.font = [UIFont systemFontOfSize:fontSize];
        [cell.contentView addSubview:statusLabel];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SHGateway *gateway = [dataSource objectAtIndex:indexPath.row];
    
    NSString *nibName = [Util nibNameWithClass:[AddGatewayViewController class]];
    AddGatewayViewController *viewController = [[AddGatewayViewController alloc] initWithNibName:nibName bundle:nil];

    viewController.sn = gateway.serialNumber;
    viewController.ip = gateway.addr;
    
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
