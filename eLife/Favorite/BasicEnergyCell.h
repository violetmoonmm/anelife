//
//  BasicEnergyCell.h
//  eLife
//
//  Created by mac on 14-9-9.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BasicCell.h"

@interface BasicEnergyCell : BasicCell

@property (nonatomic) int devNum;


- (void)setDisplayDevices:(NSArray *)devices;

@end
