//
//  BasicEnvironmentListCell.h
//  eLife
//
//  Created by 陈杰 on 15/4/11.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BasicCell.h"

@protocol BasicEnvironmentListCellDelegate <NSObject>

- (void)entryEnvironmentService;

@end

@interface BasicEnvironmentListCell : BasicCell

@property (nonatomic,assign) id<BasicEnvironmentListCellDelegate> delegate;

@end
