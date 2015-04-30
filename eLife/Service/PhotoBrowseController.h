//
//  PhotoBrowseController.h
//  eLife
//
//  Created by 陈杰 on 14/12/12.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoBrowseController : UIView

- (id)initWithSuperView:(UIView *)superView;

- (void)setFromView:(UIView *)fromView toView:(UIView *)toView originFrame:(CGRect)originFrame;

- (void)startAnimation;

@end
