//
//  UserRegisterViewController.m
//  eLife
//
//  Created by mac on 14-6-16.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "ForgetPasswordViewController.h"
#import "NetAPIClient.h"
#import "IcrcHttpClientSdk.h"
#import "MBProgressHUD.h"
#import "Util.h"
#import "AppDelegate.h"
#import <MessageUI/MessageUI.h>

@interface ForgetPasswordViewController () <UIAlertViewDelegate,MFMessageComposeViewControllerDelegate>
{
    IBOutlet UIImageView *pswdBgdView;
    IBOutlet UIImageView *confirmBgdView;
    IBOutlet UIImageView *authCodeBgdView;
    IBOutlet UIImageView *userBgdView;
    
    IBOutlet UITextField *pswdInputView;
    IBOutlet UITextField *confirmInputView;
    IBOutlet UITextField *authCodeInputView;
    IBOutlet UITextField *userInputView;
    
    IBOutlet UIScrollView *scrlView;
    IBOutlet UIButton *okBtn;
    
    
    MBProgressHUD *hud;
    
}

@end

@implementation ForgetPasswordViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    pswdBgdView.image = [UIImage imageNamed:@"input_bgd.png"];
    confirmBgdView.image = [UIImage imageNamed:@"input_bgd.png"];
    authCodeBgdView.image = [UIImage imageNamed:@"input_bgd.png"];
    userBgdView.image = [UIImage imageNamed:@"input_bgd.png"];
    
    
    [Util unifyStyleOfViewController:self withTitle:@"密码重置"];
    
    
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack:)];
    
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [userInputView becomeFirstResponder];
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



- (IBAction)userResetPassword:(id)sender
{
    NSString *userName = userInputView.text;
    NSString *pswd = pswdInputView.text;
    NSString *pswdConfirm = confirmInputView.text;
    NSString *authCode = authCodeInputView.text;
    
    
    
    if (![self validateMobile:userName]) {
        [self showAlertMsg:@"请输入正确的手机号码"];
    }
    else if (!pswd) {
        [self showAlertMsg:@"密码不能为空"];
    }
    else if ([authCode length] < 8) {
        [self showAlertMsg:@"请输入8位数字的身份认证码"];
    }
    else if ([pswd length] < 6) {
        [self showAlertMsg:@"密码长度不能短于6位"];
    }
    else if (![pswd isEqualToString:pswdConfirm]) {
        [self showAlertMsg:@"前后密码输入不一致"];
    }
    else {
        
        NSString *authCodeText = [authCode stringByReplacingCharactersInRange:NSMakeRange(2, 4) withString:@"*"];
        
        [self showWaitingStatus];
        
        __weak typeof (self) weakSelf = self;
        [[NetAPIClient sharedClient] applyResetPasswordWithUser:userName successCallback:^(NSDictionary *result){
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            [NSObject cancelPreviousPerformRequestsWithTarget:strongSelf];
            [strongSelf->hud hide:YES];
            strongSelf->hud = nil;
    
            
            [self sendSMSWithInfo:result];
            
            
        }failureCallback:^(int err){
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            [NSObject cancelPreviousPerformRequestsWithTarget:strongSelf];
            [strongSelf->hud hide:YES];
            strongSelf->hud = nil;
            
            [self showAlertMsg:@"重置请求失败"];
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

- (void)regFailed:(int)err
{
    NSString *errMsg = [NSString stringWithFormat:@"注册失败，错误码%d",err];
    switch (err) {
        case ICRC_ERROR_EMAIL_HAS_REGISTER:
            errMsg = @"该邮箱已经被注册";
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
        case ICRC_ERROR_HTTP_NO_RESPONSE:
            errMsg = @"服务器无响应";
            break;
        case ICRC_ERROR_PHONENUMBER_ALREADY_ACTIVE:
            errMsg = @"此手机号码已经激活";
            break;
        case ICRC_ERROR_PHONENUMBER_NOT_EXIST:
            errMsg = @"此手机号码不存在";
            break;
        case ICRC_ERROR_PHONENUMBER_HAS_REGISTER:
            errMsg = @"此手机号码已经被注册";
            break;
        case ICRC_ERROR_PHONENUMBER_INVALID:
            errMsg = @"此手机号码非法";
            break;
            
        default:
            break;
    }
    
    hud.mode = MBProgressHUDModeText;
    hud.labelText = errMsg;
    
    [hud hide:YES afterDelay:1.5];
    
}


- (void)reqTimeout
{
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"请求超时!";
    
    [hud hide:YES afterDelay:1.5];
    
    //_hud = nil;
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

- (BOOL)validateEmail:(NSString *)aEmail
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:aEmail];
}

- (void)goBack:(UIButton *)sender
{
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    
    //    [self.navigationController popViewControllerAnimated:YES];
}

- (void)hideKeyboard
{
    //    if ([nicknameInputView isFirstResponder]) {
    //        [nicknameInputView resignFirstResponder];
    //    }
    if ([pswdInputView isFirstResponder]) {
        [pswdInputView resignFirstResponder];
    }
    else if ([confirmInputView isFirstResponder]) {
        [confirmInputView resignFirstResponder];
    }
    else if ([userInputView isFirstResponder]) {
        [userInputView resignFirstResponder];
    }
    
}

- (void)handleKeyboardWillShow:(NSNotification *)ntf
{
    
    scrlView.contentSize = CGSizeMake(scrlView.bounds.size.width, CGRectGetMaxY(okBtn.frame)+10) ;
    
    
    
    NSDictionary *userInfo = [ntf userInfo];
    NSValue *rectValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [rectValue CGRectValue];
    NSInteger keyboardHeight = keyboardRect.size.height;
    
    NSNumber *duration = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    NSInteger spacing = CGRectGetHeight(scrlView.frame) - CGRectGetMaxY(okBtn.frame);
    
    NSInteger offY = keyboardHeight - spacing;
    
    
    
    if (offY > 0) {
        [scrlView setContentInset:UIEdgeInsetsMake(0, 0, keyboardHeight, 0)];
        //        [UIView animateWithDuration:[duration floatValue] animations:^{
        //            [scrlView setContentOffset:CGPointMake(0, offY)];
        //
        //
        //        }completion:NULL];
    }
    
}

- (void)handleKeyboardWillHide:(NSNotification *)ntf
{
    NSDictionary *userInfo = [ntf userInfo];
    NSNumber *duration = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    scrlView.contentSize = CGSizeMake(0, 0);
    scrlView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    [UIView animateWithDuration:[duration floatValue] animations:^{
        [scrlView setContentOffset:CGPointMake(0, 0)];
        
        
    }completion:NULL];
    
}


- (void)sendSMSWithInfo:(NSDictionary *)info
{
    BOOL canSendSMS = [MFMessageComposeViewController canSendText];
    
    if (canSendSMS) {
        
        NSString *phoneNum = [info objectForKey:@"SMSNum"];
        NSString *authCodeSeed = [info objectForKey:@"AuthCodeSeed"];
        NSString *authCodeSeedIndex = [info objectForKey:@"AuthCodeSeedIndex"];
        NSString *content = [NSString stringWithFormat:@"mmcz#%@#%@#%@",userInputView.text,authCodeInputView.text,authCodeSeedIndex];
        
        MFMessageComposeViewController *picker =
        [[MFMessageComposeViewController alloc] init];
        picker.messageComposeDelegate = self;
        picker.navigationBar.tintColor = [UIColor blackColor];
        picker.body = content;
        picker.recipients = [NSArray arrayWithObject:phoneNum];
        [self presentViewController:picker animated:YES completion:^{
            
        }];
        
    }
    else {
//        MBProgressHUD *tempHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
//        [self.navigationController.view addSubview:tempHud];
//        tempHud.labelText = @"请使用具有短信发送功能的设备来重置密码";
//        tempHud.mode = MBProgressHUDModeText;
//        tempHud.removeFromSuperViewOnHide = YES;
//        [tempHud show:YES];
//        [tempHud hide:YES afterDelay:2.0];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请使用具有短信发送功能的设备来重置密码" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
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
            

            [self showWaitingStatus];
            [[NetAPIClient sharedClient] resetPasswordWithUser:userInputView.text pswd:pswdInputView.text successCallback:^{
                
                
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
            
            break;
        case MessageComposeResultFailed:
            NSLog(@"Result: Failed");
            
            [self dismissViewControllerAnimated:YES completion:NULL];
            
            break;
        default:
            break;
    }
}




@end
