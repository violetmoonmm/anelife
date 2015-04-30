//
//  BasicVideoEntryCell.h
//  eLife
//
//  Created by mac on 14-9-9.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BasicCell.h"

@protocol BasicVideoEntryCellDelegate <NSObject>

- (void)entryVideo;

@end

@interface BasicVideoEntryCell : BasicCell

@property (nonatomic,assign) id<BasicVideoEntryCellDelegate>delegate;

@end
