//
//  WholeHouseView.h
//  eLife
//
//  Created by mac on 14-7-22.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SliderViewDelegate ;


@interface SliderView : UIView

@property (nonatomic,assign) id<SliderViewDelegate> delegate;
@property (nonatomic,assign) NSInteger selectedIndex;
@property (nonatomic,assign) NSInteger maxVisibleNum;

- (void)buildWithTitles:(NSArray *)titles normalImages:(NSArray *)images selectedImages:(NSArray *)selectedImages;

@end

@protocol SliderViewDelegate <NSObject>

- (void)sliderView:(SliderView *)sliderView didSelectItemAtIndex:(NSInteger)index;

@end