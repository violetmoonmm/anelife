//
//  Util.m
//  eLife
//
//  Created by mac on 14-5-17.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "Util.h"
#import "NetAPIClient.h"
#import "PublicDefine.h"

#define TITLE_FONT 17

@interface UINavigationController (Ext)

@end

@implementation UINavigationController (Ext)

- (BOOL)shouldAutorotate

{
    
    return NO;
    
}

@end


@implementation Util

+ (NSString *)nibNameWithClass:(Class)cls
{
    NSMutableString *nibName = [NSMutableString stringWithString:NSStringFromClass(cls)];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [nibName appendString:@"_iPad"];
    }
    
    return nibName;
}


+ (void)unifyStyleOfViewController:(UIViewController *)controller withTitle:(NSString *)title
{
    
    UIImage *navImage = [UIImage imageNamed:@"NavigationBar"];
    CGSize size = controller.navigationController.navigationBar.frame.size;
    UIGraphicsBeginImageContext(CGSizeMake(size.width, size.height));
    [navImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [controller.navigationController.navigationBar setBackgroundImage:navImage forBarMetrics:UIBarMetricsDefault];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor];
    
    [dict setObject:[UIFont boldSystemFontOfSize:18] forKey:UITextAttributeFont];
    controller.navigationController.navigationBar.titleTextAttributes = dict;
    controller.title = title;
}


+ (void)unifyGoBackButtonWithTarget:(UIViewController *)target selector:(SEL)selector
{
    UIButton *returnBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    returnBtn.frame = CGRectMake(0, 0, 44, 44);
    [returnBtn addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    [returnBtn setImage:[UIImage imageNamed:@"back_arrow.png"] forState:UIControlStateNormal];
    
    UIBarButtonItem *leftBtnItem = [[UIBarButtonItem alloc] initWithCustomView:returnBtn];
    target.navigationItem.leftBarButtonItem = leftBtnItem;
}

+ (BOOL)clientIsLastVersion
{
    if (![NetAPIClient sharedClient].versionInfo.versionName) {
        return YES;
    }
    
    return [[NetAPIClient sharedClient].versionInfo.versionName isEqualToString:CLIENT_VERSION];
}

//- (NSComparisonResult)versionCompare:(NSString *)version anotherVersion:(NSString *)version1
//{
//    NSArray *components = [version componentsSeparatedByString:@"."];
//    NSArray *components1 = [version1 componentsSeparatedByString:@"."];
//    
//    if ([components count] == 3 && [components1 count] == 3) {
//        NSInteger header = [[components objectAtIndex:0] integerValue];
//        NSInteger header1 = [[components1 objectAtIndex:0] integerValue];
//        
//        if (header > header1) {
//            return NSOrderedDescending;
//        }
//        else if (header < header1) {
//            return NSOrderedAscending;
//        }
//        else {
//            NSInteger mid = [[components objectAtIndex:1] integerValue];
//            NSInteger mid1 = [[components1 objectAtIndex:1] integerValue];
//            
//            if (mid > mid1) {
//                return NSOrderedDescending;
//            }
//            else if (mid < mid1) {
//                return NSOrderedAscending;
//            }
//            else {
//                NSInteger tail = [[components objectAtIndex:2] integerValue];
//                NSInteger tail1 = [[components1 objectAtIndex:2] integerValue];
//                
//                if (tail > tail1) {
//                    return NSOrderedDescending;
//                }
//                else if (tail < tail1) {
//                    return NSOrderedAscending;
//                }
//            }
//        }
//    }
//    
//    return NSOrderedSame;
//}

/*
 * 将字符串str进行md5编码后返回
 */
+(NSString *)md5:(NSString *)str
{
    
//    @try {
//        if(str){
//            const char *cStr = [str UTF8String];
//            unsigned char result[16];
//            CC_MD5(cStr, strlen(cStr), result);
//            
//            return [NSString stringWithFormat:
//                    @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
//                    result[0], result[1], result[2], result[3],
//                    result[4], result[5], result[6], result[7],
//                    result[8], result[9], result[10], result[11],
//                    result[12], result[13], result[14], result[15]
//                    ];
//        }
//    }
//    @catch (NSException *exception) {
//        NSLog(@"FileHelperAPI md5 error...please check: %@", str);
//    }
//    
//    return str;
    
    return nil;
    
}

@end
