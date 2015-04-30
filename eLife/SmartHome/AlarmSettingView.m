//
//  AlarmSettingView.m
//  eLife
//
//  Created by mac on 14-10-17.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "AlarmSettingView.h"
#import "NetApiClient.h"
#import "MBProgressHUD.h"

@implementation AlarmSettingView
{
    UILabel *_nameLbl;
    UISwitch *_switch;
    MBProgressHUD *hud;
}


- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor clearColor];
        
        NSInteger nameWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 70);
        NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 13 : 14);
        NSInteger switchGap = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 2 : 4);
        
        CGRect nameFrame = CGRectMake(0, 0, nameWidth, CGRectGetHeight(frame));
        
        _nameLbl = [[UILabel alloc] initWithFrame:nameFrame];
//        nameLbl.text = alarmZone.name;
        _nameLbl.font = [UIFont systemFontOfSize:fontSize];
        _nameLbl.backgroundColor = [UIColor clearColor];
        [self addSubview:_nameLbl];
        
        CGRect switchFrame = CGRectMake(CGRectGetMaxX(nameFrame)+switchGap, CGRectGetMinY(nameFrame), 80, 30);
        _switch = [[UISwitch alloc] initWithFrame:switchFrame];
        [_switch addTarget:self action:@selector(switchAlarmZone:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:_switch];
    }
    
    return self;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (void)dealloc
{
    [self removeObserveDevice:_alarmZone];
}

//注册观察
- (void)observeDevice:(SHDevice *)device
{
    [device addObserver:self forKeyPath:@"state.mode" options:NSKeyValueObservingOptionNew context:NULL];

}

//移除观察
- (void)removeObserveDevice:(SHDevice *)device
{
    [device removeObserver:self forKeyPath:@"state.mode"];

}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    [self displayStatus];
}


- (void)setAlarmZone:(SHDevice *)alarmZone
{
    [self removeObserveDevice:_alarmZone];
    
    _alarmZone = alarmZone;
    
    [self observeDevice:_alarmZone];
    
    
    _nameLbl.text = alarmZone.name;
    
    [self displayStatus];
}


- (void)displayStatus
{
    
    BOOL bOn = [((SHAlarmZoneState *)_alarmZone.state).mode isEqualToString:@"Arming"] ? YES : NO;
    
    _switch.on = bOn;
}

- (void)switchAlarmZone:(UISwitch *)sender
{
    
//    UISwitch *theSwitch = (UISwitch *)sender;
//    
//    NSInteger index = theSwitch.tag - TAG_ALARMZONE_SWITCH;
//    
//    
//    SHGateway *gateway = [self selectedGateway];
    
//    SHAlarmZone *alarmZone = [gateway.alarmZoneArray objectAtIndex:index];
    
    //    NSString *mode = [(SHAlarmZoneState *)alarmZone.state mode];
    //    if ([mode isEqualToString:@"Arming"]) {
    //        mode = @"Disarming";
    //    }
    //    else {
    //        mode = @"Arming";
    //    }
    
    NSString *strMode = sender.on ? @"Arming" : @"Disarming";
    
    [[NetAPIClient sharedClient] setAlarmMode:_alarmZone.deviceId gatewayId:_alarmZone.gatewayId mode:strMode successCallback:^{
        NSLog(@"set alarmMode success %@",_alarmZone.deviceId);
        
    }failureCallback:^{
        NSLog(@"set alarmMode failed %@",_alarmZone.deviceId);
        
        sender.on = !sender.on;
        
        [self showCtrlFailedHint];
    }];
    
}

- (void)showCtrlFailedHint
{
    
    hud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"设置失败！";
    [hud show:YES];
    
    [self performSelector:@selector(hideHint) withObject:nil afterDelay:1.0];
}

- (void)hideHint
{
    [hud hide:YES];
    hud = nil;
}

@end
