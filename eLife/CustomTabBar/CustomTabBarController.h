//
//  CustomTabBarController.h
//  eLife
//
//  Created by mac on 14-3-15.
//  Copyright (c) 2014年 mac. All rights reserved.
//


#import <UIKit/UIKit.h>

#import "CustomTabBarView.h"
#import "CustomTabBarItem.h"

@interface CustomTabBarController : UITabBarController <CustomTabBarViewDelegate>

- (void)setBadgeValue:(NSString *)aValue
              atIndex:(int)aIndex;//数字

- (void)displayTrackPoint:(BOOL)yesOrNo atIndex:(int)aIndex;//红点

@property (nonatomic) NSUInteger slctdIndex;
@property (nonatomic,readonly,strong) CustomTabBarView *customTabBar;
@end
