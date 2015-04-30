//
//  NetReachability.h
//  eLife
//
//  Created by 陈杰 on 14/11/24.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetReachability : NSObject

+ (NetReachability *)getInstance;

- (void)startWatchNetwork;

//- (BOOL)isNetworkReachable;


// 是否本地wifi（未连接到互联网）
+ (BOOL)isEnableLocalWIFI;

// 是否连接到互联网
+ (BOOL)isEnableInternetConnection;

//网络可达
+ (BOOL)isNetworkReachable;

//通过3G/4G 连接
+ (BOOL)isReachableViaWWAN;

@end
