//
//  ChangeEmailViewController.m
//  eLife
//
//  Created by mac on 14-7-9.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "ChangeEmailViewController.h"
#import "NetAPIClient.h"
#import "IcrcHttpClientSdk.h"
#import "MBProgressHUD.h"
#import "Util.h"

@interface ChangeEmailViewController ()
{
    IBOutlet UITextField *emailInput;
    
    IBOutlet UIImageView *emailBgdView;
    
    MBProgressHUD *hud;
}

@end

@implementation ChangeEmailViewController

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
    
    emailBgdView.image = [UIImage imageNamed:@"input_bgd.png"];
    

    [Util unifyStyleOfViewController:self withTitle:@"修改邮箱"];
    
 
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
    if ([emailInput isFirstResponder]) {
        [emailInput resignFirstResponder];
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

- (BOOL)validateEmail:(NSString *)aEmail
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:aEmail];
}

- (void)showAlertMsg:(NSString *)msg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alert show];
}

- (IBAction)change:(id)sender
{
    NSString *emailText = emailInput.text;

    
    if (![self validateEmail:emailText]) {
        
        [self showAlertMsg:@"邮箱格式不正确"];
    }
    else {
        
        [self showWaitingStatus];
        
        [[NetAPIClient sharedClient] changeEmail:emailText successCallback:^{
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"修改成功";
            [hud hide:YES afterDelay:1.5];
            
            [self goBack];
            
        }failureCallback:^(int err){
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            NSString *errMsg = nil;
            switch (err) {
                case ICRC_ERROR_EMAIL_HAS_REGISTER:
                    errMsg = @"邮箱已经被注册";
                    break;
                case ICRC_ERROR_SERVER_ABNORMAL:
                    errMsg = @"服务器异常";
                    break;
                case ICRC_ERROR_EMAIL_INVALID:
                    errMsg = @"非法邮箱";
                    break;
                case ICRC_ERROR_EMAIL_SEND_FAIL:
                    errMsg = @"发送邮件失败";
                    break;
                case ICRC_ERROR_EMAIL_NOT_EXIST:
                    errMsg = @"邮箱不存在";
                    break;
                case ICRC_ERROR_ASK_EMAIL_TOO_OFTEN:
                    errMsg = @"太过频繁发送邮件";
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


@end
