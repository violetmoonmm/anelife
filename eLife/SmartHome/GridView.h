//
//  GridView.h
//  eLife
//
//  Created by mac on 14-4-1.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BoxView.h"

@class GridView;

@protocol GridViewDelegate <NSObject>

- (void)gridView:(GridView *)gridView didSelectItemAtIndex:(NSInteger)index;

- (void)gridView:(GridView *)gridView expandBox:(BoxView*)box atIndex:(NSInteger)index;

- (NSArray *)deviceListForGridView:(GridView *)gridView atIndex:(NSInteger)index;

- (void)gridView:(GridView *)gridView playVideo:(NSString *)cameraId;

- (void)gridView:(GridView *)gridView changeContentHeight:(CGFloat)absHeight;

- (UIView *)gridView:(GridView *)gridView headerForBoxViewAtIndex:(NSInteger)index;

@end



@interface GridView : UIView 

@property (nonatomic,assign) id<GridViewDelegate> delegate;


- (void)buildWithTitles:(NSArray *)titles subTitles:(NSArray *)subtitles icons:(NSArray *)icons selectedIcons:(NSArray *)selectedIcons  bgdImages:(NSArray *)bgdImages;



- (void)closeBox;


- (void)reloadWholeHouseCtrlView;

@end
