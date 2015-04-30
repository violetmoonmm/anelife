//
//  BasicInfoEntryCell.h
//  eLife
//
//  Created by mac on 14-9-9.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BasicCell.h"

@protocol BasicInfoEntryCellDelegate <NSObject>

- (void)entryMessage;

@end

@interface BasicInfoEntryCell : BasicCell


@property (nonatomic,assign) id<BasicInfoEntryCellDelegate> delegate;

@end
