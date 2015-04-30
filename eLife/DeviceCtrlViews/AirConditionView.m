//
//  deviceView.m
//  eLife
//
//  Created by mac on 14-6-4.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "AirConditionView.h"
#import "NetAPIClient.h"
#import "MBProgressHUD.h"
#import "NotificationDefine.h"
#import "DeviceData.h"

@interface AirConditionView ()
{
    
    IBOutlet UILabel *temperatureLbl;
    IBOutlet UILabel *environmentTempLbl;
    //IBOutlet UIButton *closeBtn;
    
    IBOutlet UIButton *tempAddBtn;
    IBOutlet UIButton *tempDecBtn;
    IBOutlet UIButton *modeColdBtn;
    IBOutlet UIButton *modeHotBtn;
    IBOutlet UIButton *modeWindBtn;
    IBOutlet UIButton *modeWetBtn;
    IBOutlet UIButton *modeAutoBtn;
    //IBOutlet UIButton *windStopBtn;
    IBOutlet UIButton *windLowBtn;
    IBOutlet UIButton *windMidBtn;
    IBOutlet UIButton *windHightBtn;
    IBOutlet UIButton *windAutoBtn;
    
    IBOutlet UIActivityIndicatorView *indicator;
    
    UIButton *selectedModeBtn;
    UIButton *selectedWindBtn;
   
    IBOutlet UILabel *nameLabel;
 
    
    IBOutlet UIButton *onBtn;
    IBOutlet UIButton *offBtn;
    
//    MBProgressHUD *hud;
}

@end

@implementation AirConditionView


- (void)viewDidLoad
{
    [super viewDidLoad];
}



- (void)dealloc
{
 
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}





- (void)setDevice:(SHDevice *)device
{
    
    [super setDevice:device];
    
    if (device.name) {
        nameLabel.text = device.name;
    }
    
}


//- (void)handleDeviceStatusChangeNtf:(NSNotification *)ntf
//{
//    [self displayDeviceStatus];
//}


//显示设备状态
- (void)displayDeviceStatus
{
    
    [self displayWindspeed];
    [self displayTemperature];
    [self displayMode];
    [self displayEnvironmentTemp];
    [self displayPower];
}

//显示环境温度
- (void)displayEnvironmentTemp
{
    int temp = (int)[(SHAirconditionState *)self.device.state environmentTemp];
    environmentTempLbl.text = [NSString stringWithFormat:@"%d℃",temp];
}

//显示电源开关状态
- (void)displayPower
{
    if (self.device.state.powerOn) {
        onBtn.selected = YES;
        offBtn.selected = NO;
    }
    else {
        onBtn.selected = NO;
        offBtn.selected = YES;
    }
}

//显示温度
- (void)displayTemperature
{
    temperatureLbl.text = [NSString stringWithFormat:@"%d℃",[(SHAirconditionState *)self.device.state temperature]];
    
    
    [self setTemperatureBtnEnable:[(SHAirconditionState *)self.device.state temperature]];
}

//显示模式
- (void)displayMode
{
    NSString *strMode = [(SHAirconditionState *)self.device.state mode];
    
    [selectedModeBtn setSelected:NO];
    
    if ([strMode isEqualToString:@"Cold"]) {//制冷
        [modeColdBtn setSelected:YES];
        selectedModeBtn = modeColdBtn;

    }
    else if ([strMode isEqualToString:@"Hot"]) {//制热
        [modeHotBtn setSelected:YES];
        selectedModeBtn = modeHotBtn;
    }
    else if ([strMode isEqualToString:@"Wind"]) {//通风
        [modeWindBtn setSelected:YES];
        selectedModeBtn = modeWindBtn;
    }
    else if ([strMode isEqualToString:@"Wet"]) {//除湿
        [modeWetBtn setSelected:YES];
        selectedModeBtn = modeWetBtn;
    }
    else if ([strMode isEqualToString:@"Auto"]) {//自动
        [modeAutoBtn setSelected:YES];
        selectedModeBtn = modeAutoBtn;
    }
}

//显示风速
- (void)displayWindspeed
{
    NSString *strWind = [(SHAirconditionState *)self.device.state windSpeed];
    
    [selectedWindBtn setSelected:NO];
    
    if ([strWind isEqualToString:@"Stop"]) {//停止
//        [windStopBtn setSelected:YES];
//        selectedWindBtn = windStopBtn;
    }
    else if ([strWind isEqualToString:@"Low"]) {//低速
        [windLowBtn setSelected:YES];
        selectedWindBtn = windLowBtn;
    }
    else if ([strWind isEqualToString:@"Middle"]) {//中速
        [windMidBtn setSelected:YES];
        selectedWindBtn = windMidBtn;
    }
    else if ([strWind isEqualToString:@"High"]) {//高速
        [windHightBtn setSelected:YES];
        selectedWindBtn = windHightBtn;
    }
    else if ([strWind isEqualToString:@"Auto"]) {//自动
        
        [windAutoBtn setSelected:YES];
        selectedWindBtn = windAutoBtn;
    }
}


- (void)showTempOutOfRangHint
{
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
    
    [self.view addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"温度超出范围！";
    [hud show:YES];
    
    [hud hide:YES afterDelay:1.0];
}



- (IBAction)temperatureDec:(id)sender
{
    
    [indicator startAnimating];
    
    int temp;
    //    NSString *strTemp = [temperatureLbl.text stringByReplacingOccurrencesOfString:@"℃" withString:@""];
    //    temp = [strTemp intValue] - 1;
    
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:temperatureLbl.text];
    if ([scanner scanInt:&temp]) {
        temp --;
        
        
        __weak AirConditionView *THIS = self;
        
        if (temp <= self.device.maxRange && temp >= self.device.minRange) {
            
            [[NetAPIClient sharedClient] airConditionSetTemperature:self.device temperature:temp successCallback:^{
                
                NSLog(@"set temperature dec success");
                
                [indicator stopAnimating];
 
                
            }failureCallback:^{
                NSLog(@"set temperature dec failed");
                
                [indicator stopAnimating];
                
                
                [THIS showCtrlFailedHint];
            }];
        }
        else {
            [THIS showTempOutOfRangHint];
        }
    }
}


- (IBAction)temperatureAdd:(id)sender
{
    
    [indicator startAnimating];
    
    int temp;
    //    NSString *strTemp = [temperatureLbl.text stringByReplacingOccurrencesOfString:@"℃" withString:@""];
    //    temp = [strTemp intValue] + 1;
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:temperatureLbl.text];
    if ([scanner scanInt:&temp]) {
        temp ++;

        __weak AirConditionView *THIS = self;
        if (temp <= self.device.maxRange && temp >= self.device.minRange) {

            [[NetAPIClient sharedClient] airConditionSetTemperature:self.device temperature:temp successCallback:^{
                
                NSLog(@"set temperature add success");
                
                [indicator stopAnimating];

                
            }failureCallback:^{
                NSLog(@"set temperature add failed");
                
                 [indicator stopAnimating];
                
                [THIS showCtrlFailedHint];
            }];
        }
        else {
            [THIS showTempOutOfRangHint];
        }
    }
    
}


- (void)setTemperatureBtnEnable:(int)temp
{
    if (temp <= self.device.minRange) {
        [tempDecBtn setEnabled:NO];
    }
    else if (temp >= self.device.maxRange) {
        [tempAddBtn setEnabled:NO];
    }
    else {
        [tempDecBtn setEnabled:YES];
        [tempAddBtn setEnabled:YES];
    }
}

- (IBAction)setMode:(id)sender
{
    
    UIButton *modeBtn = (UIButton *)sender;
    
    __weak AirConditionView *THIS = self;
    
    //成功回调block
    void (^ successCallback)() = ^{
         NSLog(@"device set mode success");
        
         [indicator stopAnimating];

    };
    
    //失败回调block
    void (^ failureCallback)() = ^{
        NSLog(@"device set mode failed");
        
         [indicator stopAnimating];
        
        [THIS showCtrlFailedHint];
    };
    
    NSString *strMode = nil;
    
    if (modeBtn == modeColdBtn) {
        strMode = @"Cold";
    }
    else if (modeBtn == modeHotBtn) {
        strMode = @"Hot";
        
    }
    else if (modeBtn == modeWindBtn) {
        strMode = @"Wind";
        
    }
    else if (modeBtn == modeWetBtn) {
        strMode = @"Wet";
        
    }
    else if (modeBtn == modeAutoBtn) {
        strMode = @"Auto";
    }
    
    if (strMode) {
    
         [indicator startAnimating];
        [[NetAPIClient sharedClient] airConditionSetMode:self.device mode:strMode temperature:[(SHAirconditionState *)self.device.state temperature] successCallback:successCallback failureCallback:failureCallback];
    }

    
}



- (IBAction)setWindSpeed:(id)sender
{
    
    
    UIButton *windSpeedBtn = (UIButton *)sender;
    
    __weak AirConditionView *THIS = self;
    
    //成功回调block
    void (^ successCallback)() = ^{
        NSLog(@"device set windSpeed success");
        
        [indicator stopAnimating];
        
    };
    
    //失败回调block
    void (^ failureCallback)() = ^{
        NSLog(@"device set windSpeed failed");
        
         [indicator stopAnimating];
        
        [THIS showCtrlFailedHint];
    };
    
    NSString *strWind = nil;
    
    if (windSpeedBtn == windAutoBtn) {
        
        strWind = @"Auto";
        
    }
    else if (windSpeedBtn == windLowBtn) {
        strWind = @"Low";
        
    }
    else if (windSpeedBtn == windMidBtn) {
        strWind = @"Middle";
        
    }
    else if (windSpeedBtn == windHightBtn) {
        strWind = @"High";
        
    }

    
    if (strWind) {
        [indicator startAnimating];
        
        [[NetAPIClient sharedClient] airConditionSetWindMode:self.device windMode:strWind successCallback:successCallback failureCallback:failureCallback];
    }
    
}


- (IBAction)setPowerOn:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] setPowerOn:self.device successCallback:^{
        
        [indicator stopAnimating];
        
        NSLog(@"deviceOpen success");
        
    }failureCallback:^{
        [indicator stopAnimating];
        
        NSLog(@"deviceOpen failed");
        
        
        [self showCtrlFailedHint];
    }];
}

- (IBAction)setPowerOff:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] setPowerOff:self.device successCallback:^{
        
        [indicator stopAnimating];
        
        NSLog(@"deviceClose success");
        
    }failureCallback:^{
        [indicator stopAnimating];
        
        NSLog(@"deviceClose failed");
        
        
        [self showCtrlFailedHint];
    }];
}



@end
