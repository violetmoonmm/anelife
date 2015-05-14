//
//  AuthCodeViewController.m
//  eLife
//
//  Created by 陈杰 on 15/5/12.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "AuthCodeViewController.h"
#import "NetAPIClient.h"
#import "MBProgressHUD.h"
#import "IcrcHttpClientSdk.h"
#import "Util.h"

@interface AuthCodeViewController ()
{
    IBOutlet UITextField *authCodeText;
    IBOutlet UITextField *pswdText;
    IBOutlet UIImageView *pswdBgdView;
    IBOutlet UIImageView *authCodeBgdView;
    MBProgressHUD *hud;
}

@end

@implementation AuthCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
    pswdBgdView.image = [UIImage imageNamed:@"input_bgd.png"];
    authCodeBgdView.image = [UIImage imageNamed:@"input_bgd.png"];
    
    
    
    [Util unifyStyleOfViewController:self withTitle:@"身份认证码修改"];
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }


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

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)hideKeyboard
{
    if ([pswdText isFirstResponder]) {
        [pswdText resignFirstResponder];
    }
    else if ([authCodeText isFirstResponder]) {
        [authCodeText resignFirstResponder];
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




- (void)reqTimeout
{
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"请求超时!";
    
    [hud hide:YES afterDelay:1.5];
}



- (IBAction)retsetAuthCode:(id)sender
{
    
    NSString *pswd = pswdText.text;
    NSString *authCode = authCodeText.text;
   if (!pswd) {
        [self showAlertMsg:@"密码不能为空"];
    }
    else if ([authCode length] < 8) {
        [self showAlertMsg:@"请输入8位数字的身份认证码"];
    }
    else {
        
        MBProgressHUD *tempHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        hud = tempHud;
        [self.navigationController.view addSubview:tempHud];
        tempHud.labelText = @"请稍后...";
        tempHud.mode = MBProgressHUDModeIndeterminate;
        tempHud.removeFromSuperViewOnHide = YES;
        [tempHud show:YES];
        [self performSelector:@selector(reqTimeout) withObject:nil afterDelay:10];
        
        [[NetAPIClient sharedClient] resetAuthCodeWithUser:[User currentUser].name pswd:pswd authCode:authCode successCallback:^{
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            tempHud.mode = MBProgressHUDModeText;
            tempHud.labelText = @"修改成功";
            [tempHud hide:YES afterDelay:1.5];
            
            [self goBack];
                
        }failureCallback:^(int err){
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            NSString *errMsg = nil;
            switch (err) {
                case ICRC_ERROR_PASSWORD_INCORRECT:
                    errMsg = @"密码错误";
                    break;
                case ICRC_ERROR_LOGIN_EXPIRED:
                    errMsg = @"登录已过期";
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
            
            tempHud.mode = MBProgressHUDModeText;
            tempHud.labelText = errMsg;
            [tempHud hide:YES afterDelay:1.5];
            
        }];
        
    }
}


@end
