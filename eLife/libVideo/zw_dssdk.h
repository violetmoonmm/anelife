
//
//  zw_dssdk.h
//  zw_dssdk
//
//  Created by jh c on 13-5-6.
//  Copyright (c) 2013年 __DH_ZWAN__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface zw_dssdk : NSObject
{
    
}

+ (int)  dssdk_init;
+ (void) dssdk_uninit;
+ (int)  dssdk_rtv_start: (void*)playView: (char*)playUrl :(float) fplayScale;
+ (int)  dssdk_rtv_stop: (void*)playView;
+ (int)  dssdk_talk_start: (void*)playView;
+ (int)  dssdk_talk_stop: (void*)playView;

@end