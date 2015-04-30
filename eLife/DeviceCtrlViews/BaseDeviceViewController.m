//
//  BaseDeviceViewController.m
//  eLife
//
//  Created by 陈杰 on 15/4/25.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "BaseDeviceViewController.h"
#import "NotificationDefine.h"
#import "MBProgressHUD.h"

@interface BaseDeviceViewController ()
{
    
}

@end

@implementation BaseDeviceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        //
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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



//注册观察
- (void)observeDevice:(SHDevice *)device
{
    if (device) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceStatusChangeNtf:) name:DeviceStatusChangeNotification object:device];
    }
    
}

//移除观察
- (void)removeObserveDevice:(SHDevice *)device
{
    if (device) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:DeviceStatusChangeNotification object:device];
    }
}

- (void)handleDeviceStatusChangeNtf:(NSNotification *)ntf
{
    [self displayDeviceStatus];
}


- (void)displayDeviceStatus
{
    
}

- (void)setDevice:(SHDevice *)device
{
    
    [self removeObserveDevice:_device];
    
    _device = device;
    
    [self observeDevice:_device];
    
    [self displayDeviceStatus];
    
}

- (void)showCtrlFailedHint
{
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"控制失败！";
    [hud show:YES];
    
    [hud hide:YES afterDelay:1.0];
}

@end
