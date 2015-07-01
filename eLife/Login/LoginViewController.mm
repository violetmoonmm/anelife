//
//  LoginViewController.m
//  eLife
//
//  Created by mac on 14-3-17.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "LoginViewController.h"

#import "NetAPIClient.h"
#import "AppDelegate.h"
//#import "ServerSettingViewController.h"
#import "MBProgressHUD.h"
#import "User.h"
#import "MessageManager.h"
#import "UserRegisterViewController.h"
#import "DBManager.h"
#import "IcrcHttpClientSdk.h"
#import "PublicDefine.h"
#import "NotificationDefine.h"
#import "ForgetPasswordViewController.h"
#import "Util.h"
#import "UserDBManager.h"
#import "ServiceContractViewController.h"

#define LOGIN_TIMEOUT 10


@interface LoginViewController () <UIAlertViewDelegate>
{
    IBOutlet UITextField *_userText;
    IBOutlet UITextField *_psdText;
    
    IBOutlet UIView *_userInputView;
    IBOutlet UIView *_pswdInputView;
    
    IBOutlet UIButton *_loginBtn;
    
    IBOutlet UIImageView *_profileView;
    
    IBOutlet UIScrollView *_scrlView;

    IBOutlet UIView *_displayView;
    
    IBOutlet UILabel *_versionLbl;
    
    MBProgressHUD *_hud;
    
    UILabel *_userNameLbl;
    
}

//登录
- (IBAction)login:(id)sender;


//用户注册
- (IBAction)userRegister:(id)sender;

//切换账号
- (IBAction)switchAccount:(id)sender;

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSHLocalLoginNtf:) name:LoginResultNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    

    _userInputView.backgroundColor = [UIColor clearColor];
    _pswdInputView.backgroundColor = [UIColor clearColor];
    
    _versionLbl.text = [NSString stringWithFormat:@"v%@",CLIENT_VERSION];
    

    if ([User currentUser].virtualCode && [User currentUser].name) {

        
        NSString *name = [User currentUser].name;

        NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 16 : 24);
        NSInteger spacing = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 4 : 10);
        UIFont *font = [UIFont boldSystemFontOfSize:fontSize];
        CGSize size = [name sizeWithFont:font constrainedToSize:CGSizeMake(CGRectGetWidth(self.view.bounds), 40)];
        _userNameLbl = [[UILabel alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.view.frame)-size.width)/2, CGRectGetMaxY(_profileView.frame)+spacing, size.width, size.height)];
        _userNameLbl.text = name;
        _userNameLbl.font = font;
        _userNameLbl.textColor = [UIColor whiteColor];
        _userNameLbl.backgroundColor = [UIColor clearColor];
        [_scrlView addSubview:_userNameLbl];
        
        CGRect displayViewFrame = _displayView.frame;
        displayViewFrame.origin.y -= ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 32 : 80);
        _displayView.frame = displayViewFrame;
        
        _userInputView.hidden = YES;
        
    }
    
    _userText.text = [User currentUser].name;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    
    self.view.layer.contents = (id)[UIImage imageNamed:@"LoginBgd.png"].CGImage;
    


}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
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

- (void)hideKeyboard
{
    if ([_userText isFirstResponder]) {
        [_userText resignFirstResponder];
    }
    if ([_psdText isFirstResponder]) {
        [_psdText resignFirstResponder];
    }
    
}

- (IBAction)login:(id)sender
{
    [self hideKeyboard];
  
    
    NSString *name = _userText.text;
    NSString *psd = _psdText.text;
    
    if (!_userInputView.hidden) {
        [User currentUser].name = _userText.text;
        
    }
    else {
        [User currentUser].name = _userNameLbl.text;
    }
    
    [User currentUser].password = _psdText.text;
    
    if (_userInputView.hidden) {
        name = [User currentUser].name;
    }
    
    if (0 == [name length] || 0 == [psd length]) {
        
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
        
        [[UIApplication sharedApplication].keyWindow addSubview:hud];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"用户名或密码不能为空";
        hud.margin = 10.f;
        //        hud.yOffset = 90.f;
        hud.removeFromSuperViewOnHide = YES;
        [hud show:YES];
        [hud hide:YES afterDelay:1.5];
        
        return;
    }
    
    
    _hud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:_hud];
    _hud.removeFromSuperViewOnHide = YES;
    _hud.labelText = @"登录中...";
    _hud.mode = MBProgressHUDModeIndeterminate;
    [_hud show:YES];
    
    [self performSelector:@selector(loginTimeout) withObject:nil afterDelay:LOGIN_TIMEOUT];
    
    [[NetAPIClient sharedClient] loginWithUser:name psd:psd successCallback:^{
        [self loginSuccessful];
    }failureCallback:^(int err){
        [self loginFailed:err];
    }];
    
    
    
}

- (void)loginTimeout
{
    [[NetAPIClient sharedClient] cancelLogin];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    _hud.mode = MBProgressHUDModeText;
	_hud.labelText = @"登录超时!";
    
    [_hud hide:YES afterDelay:1.5];
    
//    _hud = nil;
}


- (IBAction)userRegister:(id)sender
{
    NSString *nibName = [Util nibNameWithClass:[ServiceContractViewController class]];
    ServiceContractViewController *viewController = [[ServiceContractViewController alloc] initWithNibName:nibName bundle:nil];
    viewController.registering = YES;
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)switchAccount:(id)sender
{
    
    if (!_userNameLbl.hidden && _userInputView.hidden) {
        
        _userNameLbl.hidden = YES;
        
        _userInputView.hidden = NO;
        
        //    //prepare for animation
        _userNameLbl.alpha = 1.0;
        _userInputView.alpha = 0.0;
        
        CGRect displayViewFrame = _displayView.frame;
        displayViewFrame.origin.y = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 155 : 332);//xib 上displayView的原始y坐标
        
        [UIView animateWithDuration:0.3 animations:^{
            
            _userNameLbl.alpha = 0.0;
            _userInputView.alpha = 1.0;
            
            _displayView.frame = displayViewFrame;
            
        }completion:NULL];
    }
    
    
}

- (IBAction)forgetPswd:(id)sender
{
    NSString *nibName = [Util nibNameWithClass:[ForgetPasswordViewController class]];
    ForgetPasswordViewController *viewController = [[ForgetPasswordViewController alloc] initWithNibName:nibName bundle:nil];
    
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}


- (void)loginSuccessful
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [_hud hide:YES];
    _hud = nil;
    
    
    //查询用户配置
    User *lastUser = [[UserDBManager defaultManager] queryUserInfo:[User currentUser].virtualCode];
    [User currentUser].lockPswd = lastUser.lockPswd;
    [User currentUser].enableLockPswd = lastUser.enableLockPswd;
    [User currentUser].haveLogin = YES;
    
    //更新上次登录用户
    [[UserDBManager defaultManager] updateLastLoginUser:[User currentUser]];
    
    //插入用户
    [[UserDBManager defaultManager] updateUser:[User currentUser]];
    

    //查询网关列表
    [[NetAPIClient sharedClient] queryGatewayListFromDB];
    
    //登录成功向服务器注册推送服务
    [[NetAPIClient sharedClient] sendToken:[User currentUser].devToken];
    
    //检查版本
    [[NetAPIClient sharedClient] checkVersion:^(VersionInfo *version){
        
        if (![Util clientIsLastVersion]) {
            [self showVersionUpdateInfo:version];
        }

    }failureCallback:^{
        NSLog(@"检查版本失败");
    }];
    
    
    [[NetAPIClient sharedClient] beginTask];

    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [appDelegate.mainNavController setViewControllers:[NSArray arrayWithObject:appDelegate.tabBarController] animated:YES];
    [appDelegate.mainNavController setNavigationBarHidden:YES];
    
    appDelegate.tabBarController.slctdIndex = 0;
    
    
}

- (void)showVersionForceUpdate:(VersionInfo *)versionInfo
{
    NSString *title = @"版本过低，请先升级再使用";
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY年MM月dd日"];
    NSString *strDate = [formatter stringFromDate:versionInfo.publishDate];
    
    NSString *msg = [NSString stringWithFormat:@"新版本:%@\n发布日期:%@",versionInfo.versionName,strDate];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"前往下载", nil];
    [alert show];
    
}

- (void)showVersionUpdateInfo:(VersionInfo *)versionInfo
{
    NSString *title = [NSString stringWithFormat:@"新版本%@",versionInfo.versionName];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY年MM月dd日"];
    NSString *strDate = [formatter stringFromDate:versionInfo.publishDate];
    
    NSString *msg = [NSString stringWithFormat:@"发布日期:%@",strDate];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"前往下载", nil];
    [alert show];
    
}


- (void)loginFailed:(int)error
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    
    NSString *errorInfo = nil;
    switch (error) {
        case ICRC_ERROR_LOGIN_ABNORMAL:
            errorInfo = @"登录异常";
            [self showLoginFailedInfo:errorInfo];
            break;
        case ICRC_ERROR_USER_NOT_EXIST:
            errorInfo = @"用户不存在";
            [self showLoginFailedInfo:errorInfo];
            break;
        case ICRC_ERROR_PASSWORD_INCORRECT:
            errorInfo = @"密码错误";
            [self showLoginFailedInfo:errorInfo];
            break;
        case ICRC_ERROR_ACCOUNT_NOACTIVE:
            errorInfo = @"账号未激活";
            [self showLoginFailedInfo:errorInfo];
            break;
        case ICRC_ERROR_SERVER_ABNORMAL:
            errorInfo = @"服务器异常";
            [self showLoginFailedInfo:errorInfo];
            break;
        case ICRC_ERROR_LOW_VERSION:
            //版本过低
            [self showVersionUpdateInfo];
            break;
        case ICRC_ERROR_HTTP_NO_RESPONSE:
            
            errorInfo = @"服务器无响应";
            [self showLoginFailedInfo:errorInfo];
            
            break;
        case ICRC_ERROR_HTTP_PARAM_NOT_FOUND:
            
            errorInfo = @"服务器返回错误";
            [self showLoginFailedInfo:errorInfo];
            
            break;
        default:
            errorInfo = [NSString stringWithFormat:@"登录失败,错误码%d",error];
            [self showLoginFailedInfo:errorInfo];
            
            break;
    }

    
}

- (void)showVersionUpdateInfo
{
    
    [_hud hide:YES];
    _hud = nil;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"当前版本过低" message:@"点击确定前往AppStore下载" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alert show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"确定"]) {
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:APP_URL]];
        
    }
    else {
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
    }
}
- (void)showLoginFailedInfo:(NSString *)errorInfo
{
    
    _hud.mode = MBProgressHUDModeText;
    _hud.labelText = errorInfo;
    
    [_hud hide:YES afterDelay:1.5];
    
//    _hud = nil;
}



- (void)handleKeyboardWillShow:(NSNotification *)ntf
{
    
    _scrlView.contentSize = _scrlView.frame.size;
    
    NSDictionary *userInfo = [ntf userInfo];
    NSValue *rectValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [rectValue CGRectValue];
    NSInteger keyboardHeight = keyboardRect.size.height;
    
    NSNumber *duration = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    NSInteger offY = 0;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        CGRect frame = [_scrlView convertRect:_loginBtn.frame
                                     fromView:_displayView];
        
        NSInteger spacing = CGRectGetHeight(_scrlView.frame) - CGRectGetMaxY(frame);
        
        offY  = keyboardHeight - spacing;
    }
    else {
        NSInteger btSpacing = CGRectGetHeight(_scrlView.frame) - CGRectGetMaxY(_loginBtn.frame);
        
        offY = keyboardHeight - btSpacing;
    }
    
    
    if (offY > 0) {
        [_scrlView setContentInset:UIEdgeInsetsMake(0, 0, keyboardHeight, 0)];
        
        [UIView animateWithDuration:[duration floatValue] animations:^{
            [_scrlView setContentOffset:CGPointMake(0, offY)];
            
            
        }completion:NULL];
    }
    
}

- (void)handleKeyboardWillHide:(NSNotification *)ntf
{
    NSDictionary *userInfo = [ntf userInfo];
    NSNumber *duration = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    _scrlView.contentSize = CGSizeMake(0, 0);
    _scrlView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    [UIView animateWithDuration:[duration floatValue] animations:^{
        [self->_scrlView setContentOffset:CGPointMake(0, 0)];
        
        
    }completion:NULL];
    
}



@end
