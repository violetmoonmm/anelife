//
//  DeviceCtrlBgdView.m
//  eLife
//
//  Created by mac mini on 14/10/23.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "DeviceCtrlBgdView.h"

@implementation DeviceCtrlBgdView
{
    UIView *_superView;
    UIView *_ctrlView;
    CALayer *opacityLayer;
    CtrlViewPosition _position;
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
    
    _superView = superView;
    
    CGRect frame = superView.bounds;
    if (self = [super initWithFrame:frame]) {

//        self.layer.backgroundColor = [UIColor blackColor].CGColor;
//        self.layer.opacity = 0.0;
        
        opacityLayer = [CALayer layer];
        opacityLayer.backgroundColor = [UIColor blackColor].CGColor;
        opacityLayer.frame = [UIScreen mainScreen].bounds;
        opacityLayer.opacity  = 0.0;
        opacityLayer.transform = CATransform3DScale(CATransform3DMakeTranslation(0.0,0.0,-200),2,2,1);
        [self.layer insertSublayer:opacityLayer atIndex:0];
    }
    
    return self;
}

- (void)addDeviceCtrlView:(UIView *)view atPosition:(CtrlViewPosition)position
{
    _position = position;
    
    if (_position == CtrlViewPositionCenter) {
        CGRect frame = view.frame;
        frame.origin.x = (CGRectGetWidth(self.frame) - CGRectGetWidth(view.frame))/2;
        frame.origin.y = (CGRectGetHeight(self.frame) - CGRectGetHeight(view.frame))/2;
        view.frame = frame;
    }
    else {
        CGRect frame = view.frame;
        frame.origin.x = (CGRectGetWidth(self.frame) - CGRectGetWidth(view.frame))/2;
        frame.origin.y = CGRectGetMaxY(self.frame);
        view.frame = frame;
    }

    [self addSubview:view];
    
    _ctrlView = view;
    _ctrlView.backgroundColor = [UIColor colorWithWhite:1. alpha:0.9];
    _ctrlView.layer.cornerRadius = 6.0;
    _ctrlView.clipsToBounds = YES;
    _ctrlView.layer.borderColor = [UIColor colorWithRed:161/255. green:174/255. blue:149/255. alpha:1].CGColor;
    _ctrlView.layer.borderWidth = 1.0;
    
//    _ctrlView.layer.shadowColor = [UIColor blackColor].CGColor;
//    _ctrlView.layer.shadowOffset = CGSizeMake(4, 4);
//    _ctrlView.layer.shadowOpacity = 0.5;
//    _ctrlView.layer.shadowRadius = 5.0;

}

- (void)show
{
    
    [_superView addSubview:self];
    
    if (_position == CtrlViewPositionCenter) {//中间弹出
        _ctrlView.transform =  CGAffineTransformMakeScale(1.1f, 1.1f);
        _ctrlView.alpha = 0.3;
        
//        [[UIApplication sharedApplication].keyWindow addSubview:self];
        
        [UIView animateWithDuration:0.2 animations:^{
            //        self.layer.opacity = 0.3;
            opacityLayer.opacity = 0.3;
            _ctrlView.alpha = 1.0;
            _ctrlView.transform = CGAffineTransformIdentity;
        }completion:NULL];
    }
    else {//从下往上
        CGRect frame = _ctrlView.frame;
        frame.origin.x = (CGRectGetWidth(self.frame) - CGRectGetWidth(_ctrlView.frame))/2;
        frame.origin.y = CGRectGetHeight(self.frame)-CGRectGetHeight(frame);
        
        [UIView animateWithDuration:0.2 animations:^{
            _ctrlView.frame = frame;
        }completion:NULL];
        
    }


}

- (void)dismiss
{
    
    if (_position == CtrlViewPositionCenter) {
        [UIView animateWithDuration:0.2 animations:^{
            //        self.layer.opacity = 0.0;
            opacityLayer.opacity = 0;
            _ctrlView.transform = CGAffineTransformMakeScale(0.9f, 0.9f);
            _ctrlView.alpha = 0.1;
        }completion:^(BOOL f){
            
            if (f) {
                if ([self.delegate respondsToSelector:@selector(deviceCtrlBgdViewWillDismiss)]) {
                    [self.delegate deviceCtrlBgdViewWillDismiss];
                }
                
                [self removeFromSuperview];
            }
            
        }];
    }
    else {
        CGRect frame = _ctrlView.frame;
        frame.origin.x = (CGRectGetWidth(self.frame) - CGRectGetWidth(_ctrlView.frame))/2;
        frame.origin.y = CGRectGetHeight(self.frame);
        
        [UIView animateWithDuration:0.2 animations:^{
            _ctrlView.frame = frame;
        }completion:^(BOOL f){

            if (f) {
                if ([self.delegate respondsToSelector:@selector(deviceCtrlBgdViewWillDismiss)]) {
                    [self.delegate deviceCtrlBgdViewWillDismiss];
                }
                
                [self removeFromSuperview];
            }
        }];
    }

}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    UITouch *touch = [touches anyObject];

    CGPoint point = [touch locationInView:self];
    
    if (!CGRectContainsPoint(_ctrlView.frame, point)) {
        [self dismiss];
    }
}


@end
