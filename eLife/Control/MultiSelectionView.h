//
//  MultiSelectionView.h
//  eLife
//
//  Created by 陈杰 on 15/1/9.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>


@class MultiSelectionView;

@protocol MultiSelectionViewDelegate <NSObject>

- (void)multiSelectionView:(MultiSelectionView *)multiSelectionView didSelectedAtIndex:(NSInteger)index;

@end

@interface MultiSelectionView : UIView


- (id)initWithTitles:(NSArray *)buttonTitles hlButtonIndex:(NSInteger)hlButtonIndex delegate:(id<MultiSelectionViewDelegate>)delegate;


- (void)show;

@end
