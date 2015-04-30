//
//  DisplayStyleView.h
//  eLife
//
//  Created by 陈杰 on 14/12/19.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DisplayStyleView;

@protocol DisplayStyleViewDelegate <NSObject>

- (void)displayStyleView:(DisplayStyleView *)displayStyleView didSelectItemAtIndex:(NSInteger)index;

@end

@interface DisplayStyleView : UIView


@property (nonatomic,assign) id<DisplayStyleViewDelegate>delegate;

@property (nonatomic) NSInteger selectedIndex;

- (void)setTitles:(NSArray *)titles;

@end
