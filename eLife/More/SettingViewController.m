//
//  SettingViewController.m
//  eLife
//
//  Created by mac on 14-7-25.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "SettingViewController.h"
#import "Util.h"
#import "NetAPIClient.h"
#import "NotificationDefine.h"
#import "AboutViewController.h"
#import "MBProgressHUD.h"
#import "FtpShareViewController.h"
#import "AppDelegate.h"
#import "LoginViewController.h"
#import "User.h"
#import "UserDBManager.h"
#import "AlarmSettingViewController.h"


#define MAGIN_X 10

#define LOGOUT_TIMEOUT 15

#define CELL_H 44

@interface SettingViewController () <UITableViewDataSource,UITableViewDelegate>
{
    IBOutlet UITableView *tblView;
    MBProgressHUD *hud;
}

@end

@implementation SettingViewController

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
    
    [Util unifyStyleOfViewController:self withTitle:@"设置"];
    

    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    tblView.backgroundColor = [UIColor colorWithRed:230/255. green:230/255. blue:230/255. alpha:1];
    
    tblView.backgroundView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [tblView reloadData];
   
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


- (void)showRefreshFinished
{
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reqTimeout) object:nil];
    
    hud.labelText = @"刷新完成";
	hud.mode = MBProgressHUDModeCustomView;
    
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];

    [hud hide:YES afterDelay:1.5];
}

- (void)swipeRight
{
    [self goBack];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}



- (void)showWaitingStatus
{
    NSLog(@"showWaitingStatus");
    
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"正在刷新...";
    hud.mode = MBProgressHUDModeIndeterminate;
    [self.navigationController.view addSubview:hud];
    
    [hud show:YES];
//    [hud hide:YES afterDelay:2.0];
    
    //[self performSelector:@selector(reqTimeout) withObject:nil afterDelay:LOGOUT_TIMEOUT];
}

- (void)reqTimeout
{
    hud.mode = MBProgressHUDModeText;
	hud.labelText = @"请求超时!";
    
    [hud hide:YES afterDelay:1.5];
    
    //tempHud = nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_H;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
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
    
    NSString *text = nil;
    
 

    if (indexPath.section == 0) {
        text = @"报警通知";
    }
    else if (indexPath.section == 1) {
        text = @"关于安E生活";
    }
    else {
        text = @"退出当前账号";
    }
    
    UIFont *font = [UIFont boldSystemFontOfSize:15];
    CGSize size = [text sizeWithFont:font constrainedToSize:CGSizeMake(220, 44)];
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(8, (44-size.height)/2, size.width, size.height)];
    titleLbl.textColor = [UIColor blackColor];
    titleLbl.highlightedTextColor = [UIColor whiteColor];
    titleLbl.text = text;
    titleLbl.font = font;
    titleLbl.backgroundColor = [UIColor clearColor];
    
    [cell.contentView addSubview:titleLbl];
    
    //箭头
    UIImageView *rightArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Userguide_enter_icon.png"]];
    rightArrow.frame = CGRectMake(0, 0, 20, 20);
    rightArrow.backgroundColor = [UIColor clearColor];
    cell.accessoryView = rightArrow;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];


    if (indexPath.section == 0) {
        
        NSString *nibName = [Util nibNameWithClass:[AlarmSettingViewController class]];
        AlarmSettingViewController *vc = [[AlarmSettingViewController alloc] initWithNibName:nibName bundle:nil];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (indexPath.section == 1) {
        
        NSString *nibName = [Util nibNameWithClass:[AboutViewController class]];
        AboutViewController *vc = [[AboutViewController alloc] initWithNibName:nibName bundle:nil];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (indexPath.section == 2) {
        [self logout];
    }
}



- (void)logout
{
    MBProgressHUD  *tempHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:tempHud];
    tempHud.labelText = @"注销中...";
    tempHud.removeFromSuperViewOnHide = YES;
    [tempHud show:YES];
    
    [self performSelector:@selector(logoutTimeout:) withObject:tempHud afterDelay:LOGOUT_TIMEOUT];
    
    [[NetAPIClient sharedClient] logoutTimeout:LOGOUT_TIMEOUT successCallback:^{
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        [tempHud hide:YES];

        
        [self logoutSucceed];
        
    }failureCallback:^{
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        tempHud.mode = MBProgressHUDModeText;
        tempHud.labelText = @"注销失败!";
        
        [tempHud hide:YES afterDelay:1.0];

    }];
    
}

- (void)logoutSucceed
{
        
    NSString *nibName = [Util nibNameWithClass:[LoginViewController class]];
    LoginViewController *firstViewController = [[LoginViewController alloc] initWithNibName:nibName bundle:nil];
    
    [(AppDelegate*)([UIApplication sharedApplication].delegate) initTabBarController];//重置tabBarController
    
    [((AppDelegate*)([UIApplication sharedApplication].delegate)).mainNavController setViewControllers:[NSArray arrayWithObject:firstViewController] animated:YES];//转到登录视图
}


//登出超时
- (void)logoutTimeout:(MBProgressHUD *)tempHud
{
    [[NetAPIClient sharedClient] cancelLogout];
    
    tempHud.mode = MBProgressHUDModeText;
    tempHud.labelText = @"超时!";
    
    [tempHud hide:YES afterDelay:1.5];
    
    tempHud = nil;
    
}

@end
