//
//  AppDelegate.h
//  eLife
//
//  Created by mac on 14-3-14.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "CustomTabBarController.h"
#import "FavoriteViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *mainNavController;//主导航控制器
@property (strong, nonatomic) CustomTabBarController *tabBarController;


- (void)initTabBarController;

- (void)dismissCallView;

- (void)dismissAlarmView;

@end
