//
//  LLLCheckPasswordController.m
//  eLife
//
//  Created by 陈杰 on 15/1/21.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "LLLCheckPasswordController.h"
#import "LLLockIndicator.h"
#import "Util.h"
#import "LoginViewController.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import "LLLockView.h"
#import "LLLockPassword.h"
#import "User.h"
#import "UserDBManager.h"

#define kTipColorNormal [UIColor blackColor]
#define kTipColorError [UIColor redColor]

#define LLLockRetryTimes 5 // 最多重试几次

@interface LLLCheckPasswordController () <LLLockDelegate>
{
    int nRetryTimesRemain; // 剩余几次输入机会

    IBOutlet LLLockView* lockView; // 触摸田字控件
    NSString* savedPassword; // 本地存储的密码
    NSString* passwordConfirm; // 确认密码

    IBOutlet UILabel *tipLable; //提示
    IBOutlet UIImageView *profileView;//头像


}

@end

@implementation LLLCheckPasswordController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = [UIColor colorWithRed:230/255. green:230/255. blue:230/255. alpha:1];
   
    lockView.backgroundColor = [UIColor clearColor];
    lockView.delegate = self;
    
    nRetryTimesRemain = LLLockRetryTimes;

    // 本地保存的手势密码
    savedPassword = [LLLockPassword loadLockPassword];
    
    [User currentUser].locked = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    if ([UIScreen mainScreen].bounds.size.height <= 480) {
        CGRect headFrame = profileView.frame;
        CGRect tipFrame = tipLable.frame;
        CGRect lockViewFrame = lockView.frame;
        
        tipFrame.origin.y = CGRectGetMaxY(headFrame)+4;
        lockViewFrame.origin.y = CGRectGetMaxY(tipFrame)+4;
        
        tipLable.frame = tipFrame;
        lockView.frame = lockViewFrame;
    }
    
   
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
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

- (void)checkPassword:(NSString*)string
{
    // 验证密码正确
    if ([string isEqualToString:savedPassword]) {
        
        if ([self.delegate respondsToSelector:@selector(checkPasswordSuccessfully)]) {
            [self.delegate checkPasswordSuccessfully];
        }
        
        [User currentUser].locked = NO;
        
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    else if (string.length > 0) {
        
        nRetryTimesRemain--;
        
        if (nRetryTimesRemain > 0) {
            
            [self setErrorTip:[NSString stringWithFormat:@"密码错误，还可以再输入%d次", nRetryTimesRemain]
                    errorPswd:string];
            
        } else {
            

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"请重新登录" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [alert show];
   
            
            [self gotoLoginView];
        }
        
    } else {
        NSAssert(YES, @"意外情况");
    }
}

- (void)gotoLoginView
{
    
    [self dismissViewControllerAnimated:NO completion:NULL];

    [User currentUser].locked = NO;
    
    [User currentUser].haveLogin = NO;
    [[UserDBManager defaultManager] updateUser:[User currentUser]];
    
    
    NSString *nibName = [Util nibNameWithClass:[LoginViewController class]];
    LoginViewController *firstViewController = [[LoginViewController alloc] initWithNibName:nibName bundle:nil];
    
    [(AppDelegate*)([UIApplication sharedApplication].delegate) initTabBarController];//重置tabBarController
    
    [((AppDelegate*)([UIApplication sharedApplication].delegate)).mainNavController setViewControllers:[NSArray arrayWithObject:firstViewController] animated:YES];//转到登录视图
}


// 错误
- (void)setErrorTip:(NSString*)tip errorPswd:(NSString*)string
{
    // 显示错误点点
    [lockView showErrorCircles:string];
    

    [tipLable setText:tip];
    [tipLable setTextColor:kTipColorError];
    
    [self shakeAnimationForView:tipLable];
    

}




- (IBAction)forgetLockPassword:(id)sender
{
    [self gotoLoginView];
}

#pragma mark 抖动动画
- (void)shakeAnimationForView:(UIView *)view
{
    CALayer *viewLayer = view.layer;
    CGPoint position = viewLayer.position;
    CGPoint left = CGPointMake(position.x - 10, position.y);
    CGPoint right = CGPointMake(position.x + 10, position.y);
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [animation setFromValue:[NSValue valueWithCGPoint:left]];
    [animation setToValue:[NSValue valueWithCGPoint:right]];
    [animation setAutoreverses:YES]; // 平滑结束
    [animation setDuration:0.08];
    [animation setRepeatCount:3];
    
    [viewLayer addAnimation:animation forKey:nil];
}



#pragma mark  LLLockDelegate 
- (void)lockString:(NSString *)string
{
    
    [self checkPassword:string];
    
}




@end
