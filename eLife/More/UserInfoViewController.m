//
//  UserInfoViewController.m
//  eLife
//
//  Created by mac on 14-7-8.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "UserInfoViewController.h"
#import "User.h"
#import "MBProgressHUD.h"
#import "NetAPIClient.h"
#import "AppDelegate.h"
#import "LoginViewController.h"
#import "User.h"
#import "ChangeEmailViewController.h"
#import "ChangePasswordViewController.h"
#import "Util.h"
#import "GatewayListViewController.h"
#import "CreatGesturePasswordController.h"
#import "SetGesturePasswordController.h"
#import "NotificationDefine.h"
#import "DotView.h"
#import "AuthCodeViewController.h"

#define BOTTOM_BAR_H 44
#define MAGIN_Y 8
#define MAGIN_X 10
#define CELL_H 44

#define REQ_TIMEOUT 10

@interface UserInfoViewController () <UITableViewDataSource,UITableViewDelegate>
{
    IBOutlet UITableView *tblView;

    MBProgressHUD *_hud;
}

@end

@implementation UserInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLockPasswordGobackNtf:) name:SetLockPasswordGobackNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    [Util unifyStyleOfViewController:self withTitle:@"用户信息"];
    

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

- (void)swipeRight
{
    [self goBack];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleLockPasswordGobackNtf:(NSNotification *)ntf
{
    [self.navigationController popToViewController:self animated:YES];
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_H;
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
    
    switch (indexPath.section) {
        case 0:
            text = @"密码修改";
            
            break;
        case 1:
            text = @"身份认证码修改";
            
            break;
        case 2:
            text = @"手势密码";
            
            break;
   
        default:
            break;
    }
    
    //标题
    UIFont *font = [UIFont boldSystemFontOfSize:15];
    CGSize size = [text sizeWithFont:font constrainedToSize:CGSizeMake(120, CELL_H)];
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(8, (CELL_H-size.height)/2, size.width, size.height)];
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
    
    
    if (indexPath.section == 1)
    {
        if ([[User currentUser].authCodeText length] == 0) {
            DotView *dot = [[DotView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(titleLbl.frame)+4, (CELL_H-10)/2, 10, 10)];
            [cell.contentView addSubview:dot];
        }
        
    }
    else if (indexPath.section == 2)
    {
        UILabel *gestPswdLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(tableView.bounds)-100, 0, 50, CELL_H)];
        gestPswdLbl.backgroundColor = [UIColor clearColor];
        gestPswdLbl.textColor = [UIColor grayColor];
        gestPswdLbl.font = [UIFont systemFontOfSize:15];
        gestPswdLbl.textAlignment = NSTextAlignmentRight;
        if ([User currentUser].enableLockPswd) {
            gestPswdLbl.text = @"开启";
            
        }
        else {
            gestPswdLbl.text = @"关闭";
        }
        [cell.contentView addSubview:gestPswdLbl];
    }

    
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tblView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIViewController *viewController = nil;
    
    switch (indexPath.section) {

        case 0:
        {
            NSString *nibName = [Util nibNameWithClass:[ChangePasswordViewController class]];
            viewController = [[ChangePasswordViewController alloc] initWithNibName:nibName bundle:nil];
            
        }
            
            break;
        case 1:
        {
            NSString *nibName = [Util nibNameWithClass:[AuthCodeViewController class]];
            viewController = [[AuthCodeViewController alloc] initWithNibName:nibName bundle:nil];
            
        }
            
            break;
        case 2:
        {
            if (![User currentUser].enableLockPswd && [[User currentUser].lockPswd length] == 0) {
                NSString *nibName = [Util nibNameWithClass:[CreatGesturePasswordController class]];
                CreatGesturePasswordController *vc = [[CreatGesturePasswordController alloc] initWithNibName:nibName bundle:nil];
                [self.navigationController pushViewController:vc animated:YES];
                
            }
            else {
                NSString *nibName = [Util nibNameWithClass:[SetGesturePasswordController class]];
                SetGesturePasswordController *vc = [[SetGesturePasswordController alloc] initWithNibName:nibName bundle:nil];
                [self.navigationController pushViewController:vc animated:YES];
            }
        }
 
            break;
        default:
            break;
    }
    
    if (viewController) {
        //UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
        
        //[navController setNavigationBarHidden:NO];
        [self.navigationController pushViewController:viewController animated:YES];
        
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


@end
