//
//  BasicCell.h
//  eLife
//
//  Created by mac on 14-9-9.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DeviceData.h"

#define CELL_TEXT_FONT ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 15 :18)

#define CELL_TEXT_FONT_SMALL ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 12 :15)

#define CELL_TEXT_FONT_BIG ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 20 :24)

@interface BasicCell : UIView
{
@protected
    
    SHDevice *_device;
    NSString *_deviceId;
    NSString *_gatewayId;
    NSString *_name;
}

@property (nonatomic,strong) SHDevice *device;

@property (nonatomic,strong) NSString *deviceId;
@property (nonatomic,strong) NSString *gatewayId;

@property (nonatomic,strong) NSString *name;

@property (nonatomic,strong) NSArray *elements;

@property (nonatomic,strong) NSDictionary *styleIcons;//主题风格图标
@property (nonatomic,strong) NSString *styleDirPath;//图标资源文件夹路径

- (void)associateWithDevices:(NSArray *)deviceArray;

- (void)showCtrlFailedHint;
- (void)displayDeviceStatus;
- (void)showDeviceControlView:(UIView *)deviceControlView;

@end
