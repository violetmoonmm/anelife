//
//  GroundHeatView.m
//  eLife
//
//  Created by mac on 14-8-20.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "GroundHeatView.h"
#import "NetAPIClient.h"
#import "MBProgressHUD.h"


@interface GroundHeatView ()
{
    
    IBOutlet UILabel *temperatureLbl;
    
    IBOutlet UIActivityIndicatorView *indicator;
    
    IBOutlet UIButton *tempAddBtn;
    IBOutlet UIButton *tempDecBtn;
    
    IBOutlet UILabel *nameLabel;

    
    IBOutlet UIButton *onBtn;
    IBOutlet UIButton *offBtn;
    
    //    MBProgressHUD *hud;
}

@end

@implementation GroundHeatView


- (void)dealloc
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}





- (void)setDevice:(SHDevice *)device
{
    
    [super setDevice:device];
    
    if (self.device.name) {
        nameLabel.text = self.device.name;
    }
    
    
}

- (void)displayDeviceStatus
{
    [self displayPower];
    [self displayTemperature];
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

//状态变化时显示温度
- (void)displayTemperature
{
    temperatureLbl.text = [NSString stringWithFormat:@"%d℃",[(SHGroundHeatState *)self.device.state temperature]];
    
    
    [self setTemperatureBtnEnable:[(SHGroundHeatState *)self.device.state temperature]];
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
    
    
    NSScanner *scanner = [[NSScanner alloc] initWithString:temperatureLbl.text];
    if ([scanner scanInt:&temp]) {
        temp --;
        
        
        __weak GroundHeatView *THIS = self;
        
        if (temp <= self.device.maxRange && temp >= self.device.minRange) {
            
            [[NetAPIClient sharedClient] groundHeatSetTemperature:self.device temperature:temp successCallback:^{
                
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
        
        __weak GroundHeatView *THIS = self;
        if (temp <= self.device.maxRange && temp >= self.device.minRange) {
            
            [[NetAPIClient sharedClient]  groundHeatSetTemperature:self.device temperature:temp successCallback:^{
                
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



- (IBAction)setPowerOn:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] setPowerOn:self.device successCallback:^{
        
        [indicator stopAnimating];
        

        
    }failureCallback:^{
        [indicator stopAnimating];
        
        
        [self showCtrlFailedHint];
    }];
}

- (IBAction)setPowerOff:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] setPowerOff:self.device successCallback:^{
        
        [indicator stopAnimating];

        
    }failureCallback:^{
        [indicator stopAnimating];
        
        
        [self showCtrlFailedHint];
    }];
}





@end

