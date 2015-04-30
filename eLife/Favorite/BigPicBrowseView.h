//
//  BigPicBrowseView.h
//  eLife
//
//  Created by 陈杰 on 15/1/26.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BigPicBrowseView : UIView

- (id)initWithSuperView:(UIView *)superView;

- (void)setFromView:(UIImageView *)fromView  originFrame:(CGRect)originFrame;

- (void)startAnimation;

@end
