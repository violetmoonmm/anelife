//
//  Util.h
//  eLife
//
//  Created by mac on 14-5-17.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Util : NSObject


+ (NSString *)nibNameWithClass:(Class)cls;

//统一导航栏风格
+ (void)unifyStyleOfViewController:(UIViewController *)controller withTitle:(NSString *)title;

+ (void)unifyGoBackButtonWithTarget:(UIViewController *)target selector:(SEL)selector;

+ (BOOL)clientIsLastVersion;



+(NSString *)md5:(NSString *)str;

@end





