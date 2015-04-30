//
//  PhotoBrowseController.m
//  eLife
//
//  Created by 陈杰 on 14/12/12.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "PhotoBrowseController.h"

#define ANIMATION_TIME 0.5

@interface PhotoBrowseController ()

@end


@implementation PhotoBrowseController
{
    UIView *_contentView;
    
    UIView *_fromView;
    UIView *_toView;
    CGRect _originFrame;
    
    UIView *_parentView;//fromview 的父view
    CGRect _fromOriginFrame;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */


- (id)initWithSuperView:(UIView *)superView
{
    
    CGRect frame = superView.bounds;
    
    if (self = [super initWithFrame:frame]) {
        
        self.layer.backgroundColor = [UIColor blackColor].CGColor;
        self.layer.opacity = 0;
    }
    
     [superView addSubview:self];
    
    return self;
}

- (void)dismiss
{
    _fromView.frame = _originFrame;
    
    [UIView animateWithDuration:ANIMATION_TIME animations:^{
        
        _toView.frame = _originFrame;
        self.layer.opacity = 0;
        
    }completion:^(BOOL f){
        _fromView.frame = _fromOriginFrame;
        _fromView.hidden = NO;
        
        [_parentView addSubview:_fromView];
        
        [self removeFromSuperview];
        
    }];

    
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self dismiss];
    
//    UITouch *touch = [touches anyObject];
//    
//    CGPoint point = [touch locationInView:self];
//    
//    if (!CGRectContainsPoint(_contentView.frame, point)) {
//        [self hide];
//    }
}

- (void)setFromView:(UIView *)fromView toView:(UIView *)toView originFrame:(CGRect)originFrame
{
    _fromView = fromView;
    _toView = toView;
    _originFrame = originFrame;
    
    _parentView = fromView.superview;
    
    _fromOriginFrame = fromView.frame;
    
    _fromView.frame = originFrame;
    
    [self addSubview:toView];
    [self addSubview:fromView];
    
}


- (void)startAnimation
{
   
    
    CGRect bounds = self.bounds;
    
    CGSize toViewSize = _toView.frame.size;
    _toView.hidden = YES;
    
    
    CGRect toViewFrame = CGRectMake((CGRectGetWidth(bounds)-toViewSize.width)/2, (CGRectGetHeight(bounds)-toViewSize.height)/2, toViewSize.width, toViewSize.height);

    [UIView animateWithDuration:ANIMATION_TIME animations:^{
        
        _fromView.frame = toViewFrame;
       self.layer.opacity = 1;

    }completion:^(BOOL f){
        _fromView.hidden = YES;
        _toView.frame = toViewFrame;

        _toView.hidden = NO;
    }];
}


@end
