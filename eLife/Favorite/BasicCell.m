//
//  BasicCell.m
//  eLife
//
//  Created by mac on 14-9-9.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "BasicCell.h"
#import "NotificationDefine.h"
#import "MBProgressHUD.h"
#import "DeviceCtrlBgdView.h"

@interface BasicCell () <DeviceCtrlBgdViewDelegate>

@end

@implementation BasicCell

@synthesize device = _device;
@synthesize deviceId = _deviceId;
@synthesize gatewayId = _gatewayId;
@synthesize name = _name;
@synthesize elements = _elements;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceStatusChangeNtf:) name:QueryDeviceStatusNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
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

- (void)setDeviceId:(NSString *)deviceId
{
    _deviceId = deviceId;
}

- (void)setGatewayId:(NSString *)gatewayId
{
    _gatewayId = gatewayId;
}

- (void)showCtrlFailedHint
{
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"控制失败！";
    [hud show:YES];
    
    [hud hide:YES afterDelay:1.0];
}


- (void)showDeviceControlView:(UIView *)deviceControlView
{
    
    DeviceCtrlBgdView *devCtlBgdView = [[DeviceCtrlBgdView alloc] initWithSuperView:[UIApplication sharedApplication].keyWindow];
    devCtlBgdView.delegate = self;
    [devCtlBgdView addDeviceCtrlView:deviceControlView atPosition:CtrlViewPositionBottom];
    [devCtlBgdView show];
    
}

- (void)associateWithDevices:(NSArray *)deviceArray
{
    for (SHDevice *device in deviceArray) {
        if ([_deviceId isEqualToString:device.serialNumber] && NSOrderedSame == [_gatewayId compare:device.gatewaySN options:NSCaseInsensitiveSearch]) {
            
            [self setDevice:device];
            
            break;
        }
    }
    
}


- (void)setElements:(NSArray *)elements
{
    if ([elements count]) {
        
        NSDictionary *params = [elements objectAtIndex:0];
        
        _deviceId = [params objectForKey:@"dev_id"];
        _gatewayId = [params objectForKey:@"gateway_sn"];
    }
}

@end
