//
//  NetReachability.m
//  eLife
//
//  Created by 陈杰 on 14/11/24.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "NetReachability.h"
#import "Reachability.h"

@implementation NetReachability
{
    Reachability *wifiReach;
}


+ (NetReachability *)getInstance
{
    static NetReachability *model = nil;
    
    @synchronized(self){
        if (model == nil) {
            model = [[NetReachability alloc] init];
            
            
        }
    }
    return model;
}


- (void)startWatchNetwork
{
    if (!wifiReach) {
        wifiReach= [Reachability reachabilityForLocalWiFi];
        
        
        [wifiReach startNotifier];
        
        
        if (wifiReach.isReachable) {
            NSLog(@"开始监听 isReachable:yes");
        }
        else {
            NSLog(@"开始监听 isReachable:no");
        }
        
//        [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:wifiReach];
    }
    
    
}




- (BOOL)isNetworkReachable
{
    return wifiReach.isReachable;
}


// 是否本地wifi（未连接到互联网）
+ (BOOL)isEnableLocalWIFI
{
    NetworkStatus st = [[Reachability reachabilityForLocalWiFi] currentReachabilityStatus];
    
    return (st != NotReachable);
}

// 是否连接到互联网
+ (BOOL)isEnableInternetConnection
{
    
    NetworkStatus st = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    
    return (st != NotReachable);
}

//网络可达
+ (BOOL)isNetworkReachable
{
    return [NetReachability getInstance].isNetworkReachable;
    
//    if ([self isEnableInternetConnection] || [self isEnableLocalWIFI]) {
//        NSLog(@"%s yes",__func__);
//        
//        return YES;
//    }
//    
//    NSLog(@"%s no",__func__);
//    return NO;
}


//通过3G/4G 连接
+ (BOOL)isReachableViaWWAN
{
     NetworkStatus st = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    
    return (st == ReachableViaWWAN);
    
}

@end
