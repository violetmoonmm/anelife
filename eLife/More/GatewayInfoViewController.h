//
//  GatewayInfoViewController.h
//  eLife
//
//  Created by 陈杰 on 15/3/21.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SHGateway;

@interface GatewayInfoViewController : UITableViewController

@property (nonatomic,strong) SHGateway *gateway;

@end
