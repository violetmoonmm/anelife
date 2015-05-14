//
//  ResetPasswordViewController.m
//  eLife
//
//  Created by 陈杰 on 15/1/28.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "ResetPasswordViewController.h"

#import "NetApiClient.h"
#import "Util.h"
#import "MBProgressHUD.h"

@interface ResetPasswordViewController ()
{
    IBOutlet UIImageView *userBgdView;
    IBOutlet UIImageView *resetCodeBgdView;
    IBOutlet UIImageView *pswdBgdView;
    IBOutlet UIImageView *confirmBgdView;
    
    IBOutlet UITextField *userInput;
    IBOutlet UITextField *pswdInput;
    IBOutlet UITextField *resetCodeInput;
    IBOutlet UITextField *confirmInput;
    
    MBProgressHUD *hud;
}

@end

@implementation ResetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    userBgdView.image = [UIImage imageNamed:@"input_bgd"];
    resetCodeBgdView.image = [UIImage imageNamed:@"input_bgd"];
    pswdBgdView.image = [UIImage imageNamed:@"input_bgd"];
    confirmBgdView.image = [UIImage imageNamed:@"input_bgd"];
    
    
    [Util unifyStyleOfViewController:self withTitle:@"密码重置"];
    
    
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)hideKeyboard
{
    
    if ([userInput isFirstResponder]) {
        [userInput resignFirstResponder];
    }
    else if ([resetCodeInput isFirstResponder]) {
        [resetCodeInput resignFirstResponder];
    }
    else if ([pswdInput isFirstResponder]) {
        [pswdInput resignFirstResponder];
    }
    else if ([confirmInput isFirstResponder]) {
        [confirmInput resignFirstResponder];
    }
    
}


- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}


- (BOOL)validateMobile:(NSString *)mobileNum
{
    /**
     * 手机号码
     * 移动：134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
     * 联通：130,131,132,152,155,156,185,186
     * 电信：133,1349,153,180,189
     */
    NSString * MOBILE = @"^1(3[0-9]|5[0-35-9]|8[025-9])\\d{8}$";
    /**
     10         * 中国移动：China Mobile
     11         * 134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
     12         */
    NSString * CM = @"^1(34[0-8]|(3[5-9]|5[017-9]|8[278])\\d)\\d{7}$";
    /**
     15         * 中国联通：China Unicom
     16         * 130,131,132,152,155,156,185,186
     17         */
    NSString * CU = @"^1(3[0-2]|5[256]|8[56])\\d{8}$";
    /**
     20         * 中国电信：China Telecom
     21         * 133,1349,153,180,189
     22         */
    NSString * CT = @"^1((33|53|8[09])[0-9]|349)\\d{7}$";
    /**
     25         * 大陆地区固话及小灵通
     26         * 区号：010,020,021,022,023,024,025,027,028,029
     27         * 号码：七位或八位
     28         */
    // NSString * PHS = @"^0(10|2[0-5789]|\\d{3})\\d{7,8}$";
    
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    NSPredicate *regextestcm = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM];
    NSPredicate *regextestcu = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU];
    NSPredicate *regextestct = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT];
    
    if (([regextestmobile evaluateWithObject:mobileNum] == YES)
        || ([regextestcm evaluateWithObject:mobileNum] == YES)
        || ([regextestct evaluateWithObject:mobileNum] == YES)
        || ([regextestcu evaluateWithObject:mobileNum] == YES))
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)showAlertMsg:(NSString *)msg
{
    
    MBProgressHUD *tempHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:tempHud];
    tempHud.labelText = msg;
    tempHud.mode = MBProgressHUDModeText;
    tempHud.removeFromSuperViewOnHide = YES;
    [tempHud show:YES];
    
    [tempHud hide:YES afterDelay:1.5];
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
    
    //_hud = nil;
}

- (IBAction)resetPassword:(id)sender
{
    NSString *userName = userInput.text;
    NSString *pswd = pswdInput.text;
    NSString *pswdConfirm = confirmInput.text;
    NSString *resetCode = resetCodeInput.text;
    
    
    if (![self validateMobile:userName]) {
        [self showAlertMsg:@"请输入正确的手机号码"];
    }
    else if (!resetCode) {
        [self showAlertMsg:@"请输入收到的短信验证码"];
    }
    else if (!pswd) {
        [self showAlertMsg:@"密码不能为空"];
    }
    else if ([pswd length] < 6) {
        [self showAlertMsg:@"密码长度不能短于6位"];
    }
    else if (![pswd isEqualToString:pswdConfirm]) {
        [self showAlertMsg:@"前后密码输入不一致"];
    }
    else {//提示
        
        
        [self showWaitingStatus];
        
        [[NetAPIClient sharedClient] resetPasswordWithUser:userName pswd:pswd successCallback:^{
            
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"密码重置成功!";
            
            [hud hide:YES afterDelay:1.5];
            
            
            [self.navigationController popToRootViewControllerAnimated:YES];
            
        }failureCallback:^(int err){
            
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"密码重置失败!";
            
            [hud hide:YES afterDelay:1.5];
            
        }];
        
    }
    
}

@end
