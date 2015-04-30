//
//  LLLCreatePasswordController.m
//  eLife
//
//  Created by 陈杰 on 15/1/21.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "LLLCreatePasswordController.h"
#import "LLLockIndicator.h"
#import "Util.h"
#import "LoginViewController.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import "LLLockView.h"
#import "LLLockPassword.h"
#import "SetGesturePasswordController.h"

#define kTipColorNormal [UIColor blackColor]
#define kTipColorError [UIColor redColor]

@interface LLLCreatePasswordController () <LLLockDelegate>
{
    IBOutlet LLLockIndicator* indicator; // 九点指示图
    IBOutlet LLLockView* lockView; // 触摸田字控件
    NSString* passwordConfirm; // 确认密码
    NSString* passwordNew; //新密码
    IBOutlet UILabel *tipLable;
}

@end

@implementation LLLCreatePasswordController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    [Util unifyStyleOfViewController:self withTitle:@"手势密码"];
    
    self.view.backgroundColor = [UIColor colorWithRed:230/255. green:230/255. blue:230/255. alpha:1];
    
    lockView.backgroundColor = [UIColor clearColor];
    lockView.delegate = self;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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


- (void)showAlert:(NSString*)string
{
    //    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
    //                                                    message:string
    //                                                   delegate:nil
    //                                          cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
    //    [alert show];
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    hud.labelText = string;
    hud.mode = MBProgressHUDModeText;
    hud.removeFromSuperViewOnHide = YES;
    [hud show:YES];
    
    
    [hud hide:YES afterDelay:1.0];
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

- (void)setTip:(NSString*)tip
{
    [tipLable setText:tip];
    [tipLable setTextColor:kTipColorNormal];
    
    tipLable.alpha = 0;
    [UIView animateWithDuration:0.5
                     animations:^{
                         tipLable.alpha = 1;
                     }completion:^(BOOL finished){
                     }
     ];
}

- (void)createPassword:(NSString*)string
{
    // 输入密码
    if (!passwordNew && !passwordConfirm) {
        
       
        passwordNew = string;
        
        [self setTip:@"请再次绘制解锁图案"];
    }
    else if (passwordNew && !passwordConfirm) {  // 确认输入密码
        
        passwordConfirm = string;
        
        if ([passwordNew isEqualToString:passwordConfirm]) {
            // 成功
            LLLog(@"两次密码一致");
            
            [LLLockPassword saveLockPassword:string];
            
            [self showAlert:@"设置成功"];
            
            if(self.viewType == LLLockViewTypeCreate)
            {
                NSString *nibName = [Util nibNameWithClass:[SetGesturePasswordController class]];
                SetGesturePasswordController *vc = [[SetGesturePasswordController alloc] initWithNibName:nibName bundle:nil];
                [self.navigationController pushViewController:vc animated:YES];
            }
            else {
                [self.navigationController popViewControllerAnimated:YES];
            }
            
            
        } else {
            
            passwordNew = nil;
            passwordConfirm = nil;
            [self setTip:@""];
            [self setErrorTip:@"与上一次绘制不一致，请重新设置" errorPswd:string];
            
        }
    } else {
        NSAssert(1, @"设置密码意外");
    }
}

- (void)updateIndicatorStatus
{
    [indicator setPasswordString:passwordNew];
}

#pragma mark - LLLockDelegate
- (void)lockString:(NSString *)string
{
    [self createPassword:string];
    

    [self updateIndicatorStatus];
}

@end
