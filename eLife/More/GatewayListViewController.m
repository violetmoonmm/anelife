//
//  GatewayListViewController.m
//  eLife
//
//  Created by mac on 14-8-13.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "GatewayListViewController.h"
#import "Util.h"
#import "User.h"
#import "NotificationDefine.h"
#import "NetAPIClient.h"
#import "IPSearchResultViewController.h"
#import "MBProgressHUD.h"
#import "AddGatewayViewController.h"
#import "GatewayInfoViewController.h"

@interface GatewayListViewController () <UITableViewDataSource,UITableViewDelegate>
{
    NSMutableArray *gatewayList;
    IBOutlet UITableView *tblView;
    
    MBProgressHUD *hud;

    UIView *multiSelectionView;
}

@end

@implementation GatewayListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBindGatewayNtf:) name:BindGatewayNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRemoveGatewayNtf:) name:DelGatewayNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEditGatewayNtf:) name:EditGatewayNotication object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGatewayStatusChangeNtf:) name:GatewayStatusChangeNotification object:nil];

        
        gatewayList = [NSMutableArray arrayWithCapacity:1];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    

    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }

    
    [Util unifyStyleOfViewController:self withTitle:@"家居网关"];
    

    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];

    
    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    addBtn.frame = CGRectMake(0, 0, 44, 44);
    [addBtn addTarget:self action:@selector(bindGateway:) forControlEvents:UIControlEventTouchUpInside];
    [addBtn setImage:[UIImage imageNamed:@"add_device.png"] forState:UIControlStateNormal];
//    [returnBtn setTitle:@"添加" forState:UIControlStateNormal];
    UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithCustomView:addBtn];
    self.navigationItem.rightBarButtonItem = rightBtnItem;
    

    [gatewayList addObjectsFromArray:[NetAPIClient sharedClient].gatewayList];
    
    

    
    tblView.backgroundColor = [UIColor colorWithRed:230/255. green:230/255. blue:230/255. alpha:1];
    tblView.backgroundView = nil;

    [tblView reloadData];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"%@",NSStringFromCGRect(tblView.frame));
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

- (void)swipeRight
{
    [self goBack];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}



- (void)bindGateway:(id)sender
{
    if (!multiSelectionView) {
        CGRect frame = [UIScreen mainScreen].bounds;
        
        multiSelectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))];
        multiSelectionView.backgroundColor = [UIColor clearColor];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMultiSelView)];
        [multiSelectionView addGestureRecognizer:tap];
        
        
        NSInteger num = 2;
        NSInteger btnHeight = 44;
        NSInteger btnWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 120 : 160);
        NSInteger lineSpacing = 10;
        NSInteger rightEdge = 12;
        
        UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(frame)-btnWidth)-rightEdge, 64, btnWidth, btnHeight*num)];
        contentView.backgroundColor = [UIColor whiteColor];
        contentView.layer.borderColor = [UIColor blackColor].CGColor;
        contentView.layer.borderWidth = 1.0;
        contentView.layer.cornerRadius = 5.0;
        contentView.layer.shadowColor = [UIColor blackColor].CGColor;
        contentView.layer.shadowOffset = CGSizeMake(0, 0);
        contentView.layer.shadowOpacity = 0.5;
        contentView.layer.shadowRadius = 5.0;
        [multiSelectionView addSubview:contentView];
        
        
        UIColor *titleColor = [UIColor blackColor];
        
        UIButton *scanbtn = [UIButton buttonWithType:UIButtonTypeCustom];
        scanbtn.frame = CGRectMake(0, 0, CGRectGetWidth(contentView.frame), btnHeight);
        scanbtn.titleLabel.font = [UIFont systemFontOfSize:16];
        
        [scanbtn setTitle:@"局域网扫描" forState:UIControlStateNormal];
        [scanbtn setTitleColor:titleColor forState:UIControlStateNormal];
        [scanbtn setAdjustsImageWhenDisabled:YES];
        //            [btn setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [scanbtn addTarget:self action:@selector(scanLAN) forControlEvents:UIControlEventTouchUpInside];
        [contentView addSubview:scanbtn];
        
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(lineSpacing, CGRectGetMaxY(scanbtn.frame), CGRectGetWidth(contentView.frame)-2*lineSpacing, 1)];
        line.backgroundColor = [UIColor grayColor];
        line.alpha = 0.5;
        [contentView addSubview:line];
        
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(0, CGRectGetMaxY(line.frame), CGRectGetWidth(contentView.frame), btnHeight);
        btn.titleLabel.font = [UIFont systemFontOfSize:16];
        
        [btn setTitle:@"手动添加" forState:UIControlStateNormal];
        [btn setTitleColor:titleColor forState:UIControlStateNormal];
        [btn setAdjustsImageWhenDisabled:YES];
        //            [btn setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [btn addTarget:self action:@selector(addManual) forControlEvents:UIControlEventTouchUpInside];
        [contentView addSubview:btn];
        
        [[UIApplication sharedApplication].keyWindow addSubview:multiSelectionView];
    }
    
     multiSelectionView.hidden = NO;
}

//- (void)dismissPopView
//{
//    
//    multiSelectionView.hidden = YES;
//}

- (void)dismissMultiSelView
{
    [multiSelectionView removeFromSuperview];
    multiSelectionView = nil;
}


- (void)addManual
{
    [self dismissMultiSelView];

    
    NSString *nibName = [Util nibNameWithClass:[AddGatewayViewController class]];
    AddGatewayViewController *viewController = [[AddGatewayViewController alloc] initWithNibName:nibName bundle:nil];
    viewController.ip = @"192.168.1.110";

    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)scanLAN
{
    [self dismissMultiSelView];
    
//    [self showWaitingStatus];
    
    NSString *nibName = [Util nibNameWithClass:[IPSearchResultViewController class]];
    
    IPSearchResultViewController *viewController = [[IPSearchResultViewController alloc] initWithNibName:nibName bundle:nil];
    
    [self.navigationController pushViewController:viewController animated:YES];
    
  
}




- (void)reqTimeout
{
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"请求超时!";
    
    [hud hide:YES afterDelay:1.5];
}

- (void)showWaitingStatus
{
    hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    hud.labelText = @"扫描中...";
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.removeFromSuperViewOnHide = YES;
    [hud show:YES];
    
    [self performSelector:@selector(reqTimeout) withObject:nil afterDelay:10];
}



- (void)handleGatewayStatusChangeNtf:(NSNotification *)ntf
{
    [tblView reloadData];
}

- (void)handleEditGatewayNtf:(NSNotification *)ntf
{
    [tblView reloadData];
    
}

- (void)handleRemoveGatewayNtf:(NSNotification *)ntf
{
    SHGateway *gateway = [[ntf userInfo] objectForKey:DelGatewayNotificationKey];
    
    if (gateway) {
       
        
        [gatewayList removeObject:gateway];
        
        
        [tblView reloadData];
    }
    
}

- (void)handleBindGatewayNtf:(NSNotification *)ntf
{
    SHGateway *gateway = [[ntf userInfo] objectForKey:BindGatewayNotificationKey];
    
    if (gateway) {
        
        [gatewayList addObject:gateway];
 
        [tblView reloadData];
    }
}



#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 124;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    return [gatewayList count];
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
    
    SHGateway *gateway = [gatewayList objectAtIndex:indexPath.row];
    
    NSInteger spacingY = 4;
    NSInteger originY = 2;
    NSInteger originX = 10;
    NSInteger lblHeight = 20;
    
    //网关名
    NSString *titleTxt = gateway.name;
    NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 16 : 18);
    CGSize size = [titleTxt sizeWithFont:[UIFont systemFontOfSize:fontSize] constrainedToSize:CGSizeMake(200, 30)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(originX, originY, size.width, 24)];
    titleLabel.text = titleTxt;
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.highlightedTextColor = [UIColor whiteColor];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [cell.contentView addSubview:titleLabel];
    
    NSInteger smallFontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 14: 16);
    UIFont *smallTxtFont = [UIFont systemFontOfSize:smallFontSize];
    
    //网关序列号
    NSString *snTxt = [NSString stringWithFormat:@"序列号: %@", gateway.serialNumber];
    size = [snTxt sizeWithFont:smallTxtFont constrainedToSize:CGSizeMake(200, 24)];
    UILabel *snLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(titleLabel.frame), CGRectGetMaxY(titleLabel.frame)+spacingY, size.width, lblHeight)];
    snLabel.text = snTxt;
    snLabel.textColor = [UIColor darkGrayColor];
    snLabel.highlightedTextColor = [UIColor whiteColor];
    snLabel.backgroundColor = [UIColor clearColor];
    snLabel.font = smallTxtFont;
    [cell.contentView addSubview:snLabel];
    
    //网关所在地
    NSString *cityTxt = gateway.city ? gateway.city : @"未知";
    cityTxt = [NSString stringWithFormat:@"所在地: %@",cityTxt];
    size = [cityTxt sizeWithFont:smallTxtFont constrainedToSize:CGSizeMake(200, 24)];
    UILabel *cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(titleLabel.frame), CGRectGetMaxY(snLabel.frame)+spacingY, size.width, lblHeight)];
    cityLabel.text = cityTxt;
    cityLabel.textColor = [UIColor darkGrayColor];
    cityLabel.highlightedTextColor = [UIColor whiteColor];
    cityLabel.backgroundColor = [UIColor clearColor];
    cityLabel.font = smallTxtFont;
    [cell.contentView addSubview:cityLabel];
    
    //网关运营商
    NSString *ispTxt = gateway.ISP ? gateway.ISP : @"未知";
    ispTxt = [NSString stringWithFormat:@"运营商: %@",ispTxt];
    fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 13: 14);
    size = [ispTxt sizeWithFont:smallTxtFont constrainedToSize:CGSizeMake(200, 24)];
    UILabel *ispLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(titleLabel.frame), CGRectGetMaxY(cityLabel.frame)+spacingY, size.width, lblHeight)];
    ispLabel.text = ispTxt;
    ispLabel.textColor = [UIColor darkGrayColor];
    ispLabel.highlightedTextColor = [UIColor whiteColor];
    ispLabel.backgroundColor = [UIColor clearColor];
    ispLabel.font = smallTxtFont;
    [cell.contentView addSubview:ispLabel];
    
    //本地在线状态
    NSString *statusTxt = [NSString stringWithFormat:@"本地:%@",gateway.status.localOnline ? @"在线" : @"离线"];
    NSInteger limitWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 300 : 758);
    NSInteger statusWidth = 70;
    NSInteger spacingX = 4;//右边间隔
    UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(limitWidth - statusWidth - spacingX, CGRectGetMinY(titleLabel.frame), statusWidth, lblHeight)];
    statusLabel.text = statusTxt;
    statusLabel.textColor = [UIColor darkGrayColor];
    statusLabel.textAlignment = NSTextAlignmentRight;
    statusLabel.highlightedTextColor = [UIColor whiteColor];
    statusLabel.backgroundColor = [UIColor clearColor];
    statusLabel.font = smallTxtFont;
    [cell.contentView addSubview:statusLabel];
    
    //远程在线状态
    NSString *remoteTxt = [NSString stringWithFormat:@"远程:%@",gateway.status.remoteOnline ? @"在线" : @"离线"];
    UILabel *remoteLabel = [[UILabel alloc] initWithFrame:CGRectMake(limitWidth - statusWidth - spacingX, CGRectGetMinY(snLabel.frame), statusWidth, lblHeight)];
    remoteLabel.text = remoteTxt;
    remoteLabel.textColor = [UIColor darkGrayColor];
    remoteLabel.textAlignment = NSTextAlignmentRight;
    remoteLabel.highlightedTextColor = [UIColor whiteColor];
    remoteLabel.backgroundColor = [UIColor clearColor];
    remoteLabel.font = smallTxtFont;
    [cell.contentView addSubview:remoteLabel];
    
    
    //认证是否成功
    NSString *authTxt = gateway.authorized ? @"认证成功" : @"认证失败";
    UILabel *authLabel = [[UILabel alloc] initWithFrame:CGRectMake(limitWidth - statusWidth - spacingX, CGRectGetMinY(cityLabel.frame), statusWidth, lblHeight)];
    authLabel.text = authTxt;
    authLabel.textColor = [UIColor darkGrayColor];
    authLabel.textAlignment = NSTextAlignmentRight;
    authLabel.highlightedTextColor = [UIColor whiteColor];
    authLabel.backgroundColor = [UIColor clearColor];
    authLabel.font = smallTxtFont;
    [cell.contentView addSubview:authLabel];
    

    //远程服务等级
    size = [@"远程服务等级:" sizeWithFont:smallTxtFont constrainedToSize:CGSizeMake(200, 24)];
    UILabel *gradeLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(titleLabel.frame), CGRectGetMaxY(ispLabel.frame)+spacingY, size.width, lblHeight)];
    gradeLbl.text = @"远程服务等级:";
    gradeLbl.textColor = [UIColor darkGrayColor];
    gradeLbl.highlightedTextColor = [UIColor whiteColor];
    gradeLbl.backgroundColor = [UIColor clearColor];
    gradeLbl.font = smallTxtFont;
    [cell.contentView addSubview:gradeLbl];
    
    //图标
    NSString *imgName = @"G00";
    switch (gateway.grade) {
        case 0:
            imgName = @"G00";
            break;
        case 1:
            imgName = @"G10";
            break;
        case 2:
            imgName = @"G20";
            break;
        case 3:
            imgName = @"G30";
            break;
            
        default:
            break;
    }
    UIImage *img = [UIImage imageNamed:imgName];
    UIImageView *gradeIcon = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(gradeLbl.frame)+5, CGRectGetMinY(gradeLbl.frame)+(lblHeight-img.size.height)/2, img.size.width, img.size.height)];
    gradeIcon.image = img;
    [cell.contentView addSubview:gradeIcon];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SHGateway *gateway = [gatewayList objectAtIndex:indexPath.row];
    
//    NSString *nibName = [Util nibNameWithClass:[EditGatewayViewController class]];
//    EditGatewayViewController *viewController = [[EditGatewayViewController alloc] initWithNibName:nibName bundle:nil];
//    
//    viewController.gateway = gateway;
    
    NSString *nibName = [Util nibNameWithClass:[GatewayInfoViewController class]];
    GatewayInfoViewController *viewController = [[GatewayInfoViewController alloc] initWithNibName:nibName bundle:nil];
    
    viewController.gateway = gateway;
    [self.navigationController pushViewController:viewController animated:YES];
}


@end
