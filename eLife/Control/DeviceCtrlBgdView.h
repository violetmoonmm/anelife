//
//  DeviceCtrlBgdView.h
//  eLife
//
//  Created by mac mini on 14/10/23.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum _CtrlViewPosition
{
    CtrlViewPositionBottom = 0,
    CtrlViewPositionCenter = 1
} CtrlViewPosition;


@class DeviceCtrlBgdView;

@protocol DeviceCtrlBgdViewDelegate <NSObject>

- (void)deviceCtrlBgdViewWillDismiss;

@end

@interface DeviceCtrlBgdView : UIView


@property (nonatomic,weak) id<DeviceCtrlBgdViewDelegate> delegate;

- (id)initWithSuperView:(UIView *)superView;

- (void)addDeviceCtrlView:(UIView *)view atPosition:(CtrlViewPosition)position;

- (void)show;

@end
