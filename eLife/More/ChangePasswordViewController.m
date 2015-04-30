//
//  ChangePasswordViewController.m
//  eLife
//
//  Created by mac on 14-7-9.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import "NetAPIClient.h"
#import "IcrcHttpClientSdk.h"
#import "MBProgressHUD.h"
#import "Util.h"
#import "LoginViewController.h"
#import "AppDelegate.h"

#define LOGOUT_TIMEOUT 15

@interface ChangePasswordViewController () <UIAlertViewDelegate>
{
    IBOutlet UITextField *oldPswd;
    IBOutlet UITextField *newPswd;
    IBOutlet UITextField *pswdConfirm;
    
    IBOutlet UIImageView *pswdBgdView;
    IBOutlet UIImageView *confirmBgdView;
    IBOutlet UIImageView *oldPswdBgdView;
    
    MBProgressHUD *hud;
}

@end

@implementation ChangePasswordViewController

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
    
    pswdBgdView.image = [UIImage imageNamed:@"input_bgd.png"];
    confirmBgdView.image = [UIImage imageNamed:@"input_bgd.png"];
    oldPswdBgdView.image = [UIImage imageNamed:@"input_bgd.png"];
    

    [Util unifyStyleOfViewController:self withTitle:@"修改密码"];
    

    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
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

- (void)hideKeyboard
{
    if ([oldPswd isFirstResponder]) {
        [oldPswd resignFirstResponder];
    }
    else if ([pswdConfirm isFirstResponder]) {
        [pswdConfirm resignFirstResponder];
    }
    else if ([newPswd isFirstResponder]) {
        [newPswd resignFirstResponder];
    }
    
}

- (void)showInputAlertMsg:(NSString *)msg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alert show];
}



- (IBAction)change:(id)sender
{
    NSString *oldPswdText = oldPswd.text;
    NSString *newPswdText = newPswd.text;
    NSString *confirmPswdText = pswdConfirm.text;
    

    if (!oldPswdText) {

        [self showInputAlertMsg:@"请输入原密码"];
    }
    else if (!newPswdText) {
   
        [self showInputAlertMsg:@"请输入新密码"];
    }
    else if (![confirmPswdText isEqualToString:newPswdText]) {

        [self showInputAlertMsg:@"前后密码不一致"];
    }
    else {
        
        
        [self showWaitingStatus];
        
        [[NetAPIClient sharedClient] changeOldPassword:oldPswdText newPassword:newPswdText successCallback:^{

            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            [hud hide:YES];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"身份过期" message:@"账号身份已过期，请重新登录。" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
            [alert show];
            
//            hud.mode = MBProgressHUDModeText;
//            hud.labelText = @"修改成功";
//            [hud hide:YES afterDelay:1.5];
//            
//            
//            [self goBack];
            
        }failureCallback:^(int err){
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            NSString *errMsg = nil;
            switch (err) {
                case ICRC_ERROR_PASSWORD_INCORRECT:
                    errMsg = @"原密码错误";
                    break;
                case ICRC_ERROR_SERVER_ABNORMAL:
                    errMsg = @"服务器异常";
                    break;
                case ICRC_ERROR_OTHER_FAULT:
                    errMsg = @"其他错误";
                    break;
                default:
                    errMsg = [NSString stringWithFormat:@"修改失败,错误码%d",err];
                    break;
            }
            
            hud.mode = MBProgressHUDModeText;
            hud.labelText = errMsg;
            [hud hide:YES afterDelay:1.5];

        }];
    }
}

- (void)showWaitingStatus
{
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.labelText = @"请稍后...";
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.removeFromSuperViewOnHide = YES;
    [hud show:YES];
    
    [self performSelector:@selector(reqTimeout) withObject:nil afterDelay:10];
}

- (void)reqTimeout
{
    hud.mode = MBProgressHUDModeText;
	hud.labelText = @"请求超时!";
    
    [hud hide:YES afterDelay:1.5];
}

- (void)logout
{
    MBProgressHUD  *tempHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:tempHud];
    tempHud.labelText = @"注销中...";
    tempHud.removeFromSuperViewOnHide = YES;
    [tempHud show:YES];
    
//    [self performSelector:@selector(logoutTimeout:) withObject:tempHud afterDelay:LOGOUT_TIMEOUT];
    
    [[NetAPIClient sharedClient] logoutTimeout:LOGOUT_TIMEOUT successCallback:^{
        
//        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self logout];
}

- (void)alertViewCancel:(UIAlertView *)alertView
{
    
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
}

@end
