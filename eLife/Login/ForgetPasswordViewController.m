//
//  ForgetPasswordViewController.m
//  eLife
//
//  Created by mac on 14-7-4.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "ForgetPasswordViewController.h"
#import "NetAPIClient.h"
#import "MBProgressHUD.h"
#import "IcrcHttpClientSdk.h"
#import "Util.h"
#import <MessageUI/MessageUI.h>
#import "ResetPasswordViewController.h"


@interface ForgetPasswordViewController () <UIAlertViewDelegate,MFMessageComposeViewControllerDelegate>
{
    IBOutlet UITextField *userText;

    IBOutlet UIImageView *userBgdView;
    
    MBProgressHUD *hud;

}

@end

@implementation ForgetPasswordViewController

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
  
    userBgdView.image = [UIImage imageNamed:@"input_bgd"];
    

    [Util unifyStyleOfViewController:self withTitle:@"忘记密码"];
    

    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)hideKeyboard
{
  
    if ([userText isFirstResponder]) {
        [userText resignFirstResponder];
    }
    
}


- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)validateEmail:(NSString *)aEmail
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:aEmail];
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

- (IBAction)send:(id)sender
{
   
    if (![self validateMobile:userText.text]) {
        [self showAlertMsg:@"请输入正确的手机号"];
    }
    else {
        
        [self showWaitingStatus];

        
        __weak typeof (self) weakSelf = self;
        [[NetAPIClient sharedClient] applyResetPasswordWithUser:userText.text successCallback:^(NSDictionary *result){

            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            [NSObject cancelPreviousPerformRequestsWithTarget:strongSelf];
            [strongSelf->hud hide:YES];
            strongSelf->hud = nil;
            
            NSString *phone = [result objectForKey:@"SMSNum"];
            NSString *resetCode = [result objectForKey:@"ResetCode"];


            [self sendSMSWithPhoneNum:phone content:resetCode];
            
            
        }failureCallback:^(int err){

            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            [NSObject cancelPreviousPerformRequestsWithTarget:strongSelf];
            [strongSelf->hud hide:YES];
            strongSelf->hud = nil;
            
            [self showAlertMsg:@"重置请求失败"];
        }];
    }

}

- (void)sendSMSWithPhoneNum:(NSString *)phoneNum content:(NSString *)content
{
    BOOL canSendSMS = [MFMessageComposeViewController canSendText];
  
    if (canSendSMS) {
        
        MFMessageComposeViewController *picker =
        [[MFMessageComposeViewController alloc] init];
        picker.messageComposeDelegate = self;
        picker.navigationBar.tintColor = [UIColor blackColor];
        picker.body = content;
        picker.recipients = [NSArray arrayWithObject:phoneNum];
        [self presentViewController:picker animated:YES completion:^{
            
        }];
        
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    switch (result) {
        case MessageComposeResultCancelled:
           NSLog(@"Result: canceled");
            
            [self dismissViewControllerAnimated:YES completion:NULL];
            break;
        case MessageComposeResultSent:
        {
            
             NSLog(@"Result: Sent");
            
            [self dismissViewControllerAnimated:YES completion:NULL];
            
            NSString *nibName = [Util nibNameWithClass:[ResetPasswordViewController class]];
            
            ResetPasswordViewController *vc = [[ResetPasswordViewController alloc] initWithNibName:nibName bundle:nil];
            [self.navigationController pushViewController:vc animated:YES];
        }
            
            break;
        case MessageComposeResultFailed:
            NSLog(@"Result: Failed");
            
            [self dismissViewControllerAnimated:YES completion:NULL];
            
            break;
        default:
            break;
    }
}

//失败处理
- (void)reqFailed:(int)error
{
    NSString *errMsg = [NSString stringWithFormat:@"发送请求失败，错误码%d",error];
    switch (error) {
        case ICRC_ERROR_USER_NOT_EXIST:
            errMsg = @"用户不存在";
            break;
        case ICRC_ERROR_SERVER_ABNORMAL:
            errMsg = @"服务器异常";
            break;
        case ICRC_ERROR_EMAIL_INVALID:
            errMsg = @"非法的邮箱";
            break;
        case ICRC_ERROR_EMAIL_SEND_FAIL:
            errMsg = @"发送邮件失败";
            break;
        case ICRC_ERROR_EMAIL_NOT_EXIST:
            errMsg = @"邮箱不存在";
            break;
        case ICRC_ERROR_ASK_EMAIL_TOO_OFTEN:
            errMsg = @"发送邮件太频繁";
            break;
            case ICRC_ERROR_USR_EMAIL_NOT_MATCH:
            errMsg = @"用户和邮箱不匹配";
            
        default:
            break;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:errMsg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alert show];
    
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
    
    hud = nil;
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

@end
