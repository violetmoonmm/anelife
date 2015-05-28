//
//  BasicStateCell.h
//  eLife
//
//  Created by mac on 14-9-9.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BasicCell.h"

@interface BasicStateCell : UIView

//@property (nonatomic,strong) NSString *deviceId;
@property (nonatomic,strong) NSString *gatewayId;

- (void)setDisplayDevices:(NSArray *)devices;


@end
