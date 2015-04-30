//
//  FtpResourceViewController.h
//  eLife
//
//  Created by mac on 14-9-22.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>


@class SHGateway;

@interface FtpResourceViewController : UIViewController

//- (void)setIp:(NSString *)ip port:(NSUInteger)port user:(NSString *)user pswd:(NSString *)pswd;

@property (nonatomic,strong) SHGateway *gateway;

@end
