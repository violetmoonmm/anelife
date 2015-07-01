//
//  Util.h
//  eLife
//
//  Created by mac on 14-5-17.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _SwipeDirection
{
    SwipeDirectionNone      = 0,
    SwipeDirectionUp        = 1,
    SwipeDirectionDown      = 2,
    SwipeDirectionLeft      = 3,
    SwipeDirectionRight     = 4,
    SwipeDirectionLeftUp    = 5,
    SwipeDirectionRightUp   = 6,
    SwipeDirectionLeftDown  = 7,
    SwipeDirectionRightDown = 8
    
} SwipeDirection;

@interface Util : NSObject


+ (NSString *)nibNameWithClass:(Class)cls;

//统一导航栏风格
+ (void)unifyStyleOfViewController:(UIViewController *)controller withTitle:(NSString *)title;

+ (void)unifyGoBackButtonWithTarget:(UIViewController *)target selector:(SEL)selector;

+ (BOOL)clientIsLastVersion;


+(NSString *)md5:(NSString *)str;

@end





