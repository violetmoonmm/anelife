//
//  BitrateView.h
//  eLife
//
//  Created by 陈杰 on 15/5/13.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BitrateView;
@protocol BitrateViewDelegate <NSObject>

- (void)bitrateView:(BitrateView *)bitrateView didSelectAtIndex:(NSInteger)index;

@end

@interface BitrateView : UIView

@property (nonatomic,assign) id<BitrateViewDelegate> delegate;
@property (nonatomic,assign) NSInteger selectedIndex;

- (id)initWithText:(NSArray *)textArray;


@end
