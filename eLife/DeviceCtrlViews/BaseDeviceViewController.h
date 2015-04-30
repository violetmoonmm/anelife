//
//  BaseDeviceViewController.h
//  eLife
//
//  Created by 陈杰 on 15/4/25.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DeviceData.h"

@interface BaseDeviceViewController : UIViewController

@property (nonatomic,strong) SHDevice *device;

- (void)showCtrlFailedHint;
- (void)displayDeviceStatus;

@end
