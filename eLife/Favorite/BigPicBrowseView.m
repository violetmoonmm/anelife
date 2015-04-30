//
//  BigPicBrowseView.m
//  eLife
//
//  Created by 陈杰 on 15/1/26.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "BigPicBrowseView.h"

#define ANIMATION_TIME 0.5

@implementation BigPicBrowseView
{

    UIView *_contentView;
    
    UIView *_fromView;
 
    CGRect _originFrame;
    
    UIView *_parentView;//fromview 的父view
    CGRect _fromOriginFrame;
    
    CALayer *opacityLayer;
    
    CGFloat scaleX;
    CGFloat scaleY;
    CGFloat translationX;
    CGFloat translationY;
    CGFloat translationZ;
    
    NSInteger animationSyte;
    
    CGSize toViewSize;
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
        
//        self.layer.backgroundColor = [UIColor blackColor].CGColor;
//        self.layer.opacity = 0;
    }

    [superView addSubview:self];
    
    return self;
}

- (void)dismiss
{
    animationSyte = 2;
    
    [_fromView.layer addAnimation:[self getAnimation:1.0 toScaleX:1.0/scaleX fromScaleY:1.0 tofromScaleY:1.0/scaleY fromTranslationX:translationX toTranslationX:0.0 fromTranslationY:translationY toTranslationY:0.0 fromTranslationZ:0.0 toTranslationZ:1.0] forKey:@"endtoView"];
    
    [opacityLayer addAnimation:[self getOpacityAnimation:1.0
                                               toOpacity:0.0] forKey:@"opacity"];

    
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




- (void)setFromView:(UIImageView *)fromView originFrame:(CGRect)originFrame
{
    _fromView = fromView;

    _originFrame = originFrame;
    
    _parentView = fromView.superview;
    
    _fromOriginFrame = fromView.frame;
    
    _fromView.frame = originFrame;
    

    [self addSubview:fromView];
    
   
    //计算缩放、平移
    toViewSize = fromView.image.size;
    CGSize fromViewSize = fromView.frame.size;
    
    scaleX = toViewSize.width/fromViewSize.width;
    scaleY = toViewSize.height/fromViewSize.height;
    
    CGRect bounds = self.bounds;
    CGFloat startX = CGRectGetMinX(originFrame);
    CGFloat startY = CGRectGetMinY(originFrame);
    
    translationX =  (CGRectGetWidth(bounds) - toViewSize.width)/2.0 - startX + (scaleX - 1) * fromViewSize.width/2.0;
    translationY =  (CGRectGetHeight(bounds) - toViewSize.height)/2.0 - startY+ (scaleY - 1) * fromViewSize.height/2.0;
    
    
    opacityLayer = [CALayer layer];
    opacityLayer.backgroundColor = [UIColor blackColor].CGColor;
    opacityLayer.frame = CGRectMake(0.0, 0.0,CGRectGetWidth(bounds), CGRectGetHeight(bounds));
    opacityLayer.opacity  = 0.0;
    [self.layer insertSublayer:opacityLayer atIndex:0];
    
    _fromView.center = self.center;
    
}

- (void)startAnimation
{
    
    animationSyte = 1;
    
//    [_fromView.layer addAnimation:[self getAnimation:1.0 toScaleX:scaleX fromScaleY:1.0 tofromScaleY:scaleY fromTranslationX:0 toTranslationX:translationX fromTranslationY:0 toTranslationY:translationY fromTranslationZ:0.0 toTranslationZ:1.0] forKey:@"startfromView"];
    
        [_fromView.layer addAnimation:[self getAnimation:1.0 toScaleX:scaleX fromScaleY:1.0 tofromScaleY:scaleY fromTranslationX:-translationX toTranslationX:0 fromTranslationY:-translationY toTranslationY:0 fromTranslationZ:0.0 toTranslationZ:1.0] forKey:@"startfromView"];

    [opacityLayer addAnimation:[self getOpacityAnimation:0.0
                                               toOpacity:1.0] forKey:@"opacity"];

}


- (CAAnimation *)getOpacityAnimation:(CGFloat)fromOpacity
                           toOpacity:(CGFloat)toOpacity
{
    CABasicAnimation *pulseAnimationx = [CABasicAnimation animationWithKeyPath:@"opacity"];
    pulseAnimationx.duration = 1.0;
    pulseAnimationx.fromValue = [NSNumber numberWithFloat:fromOpacity];
    pulseAnimationx.toValue = [NSNumber numberWithFloat:toOpacity];
    
    pulseAnimationx.autoreverses = NO;
    pulseAnimationx.fillMode=kCAFillModeForwards;
    pulseAnimationx.removedOnCompletion = NO;
    pulseAnimationx.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    return pulseAnimationx;
    
}

- (CAAnimation *)getAnimation:(float)fromScaleX
                     toScaleX:(float)toScaleX
                   fromScaleY:(float)fromScaleY
                 tofromScaleY:(float)toScaleY
             fromTranslationX:(float)fromTranslationX
               toTranslationX:(float)toTranslationX
             fromTranslationY:(float)fromTranslationY
               toTranslationY:(float)toTranslationY
             fromTranslationZ:(float)fromTranslationZ
               toTranslationZ:(float)toTranslationZ
{
    
    CAAnimationGroup *anim;
    
    CABasicAnimation *pulseAnimationx = [CABasicAnimation animationWithKeyPath:@"transform.scale.x"];
    //  CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.z"];
    pulseAnimationx.duration = 1.0;
    pulseAnimationx.fromValue = [NSNumber numberWithFloat:fromScaleX];
    pulseAnimationx.toValue = [NSNumber numberWithFloat:toScaleX];
    
    CABasicAnimation *pulseAnimationy = [CABasicAnimation animationWithKeyPath:@"transform.scale.y"];
    //  CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.z"];
    pulseAnimationy.duration = 1.0;
    pulseAnimationy.fromValue = [NSNumber numberWithFloat:fromScaleY];
    pulseAnimationy.toValue = [NSNumber numberWithFloat:toScaleY];
    
    CABasicAnimation *translationx = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    translationx.duration = 1.0;
    translationx.fromValue = [NSNumber numberWithFloat:fromTranslationX];
    translationx.toValue = [NSNumber numberWithFloat:toTranslationX];
    
    CABasicAnimation *translationy = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    translationy.duration = 1.0;
    translationy.fromValue = [NSNumber numberWithFloat:fromTranslationY];
    translationy.toValue = [NSNumber numberWithFloat:toTranslationY];
    
    CABasicAnimation *pulseAnimationz = [CABasicAnimation animationWithKeyPath:@"transform.translation.z"];
    pulseAnimationz.duration = 1.0;
    pulseAnimationz.beginTime = 0.5;
    pulseAnimationz.fromValue = [NSNumber numberWithFloat:fromTranslationZ];
    pulseAnimationz.toValue = [NSNumber numberWithFloat:toTranslationZ];
    
    

    
    anim = [CAAnimationGroup animation];
    anim.animations = [NSArray arrayWithObjects:pulseAnimationx,pulseAnimationy,translationx,translationy,pulseAnimationz, nil];

    anim.duration = 1.0;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    anim.autoreverses = NO;
    anim.fillMode=kCAFillModeForwards;
    anim.removedOnCompletion = YES;
    anim.delegate = self;
    //[self.view bringSubviewToFront:faceView];
    return anim;
    
}


- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (/*flag &&*/ animationSyte == 1)
    {
        //        [self bringSubviewToFront:_toView];
        
        //        _fromView.hidden = YES;
        //        _toView.hidden = NO;
        
        //_fromView.layer.transform = CATransform3DIdentity;
        _fromView.frame = CGRectMake((CGRectGetWidth(self.bounds)-toViewSize.width)/2, (CGRectGetHeight(self.bounds)-toViewSize.height)/2, toViewSize.width, toViewSize.height);
    }
    else if(flag && animationSyte == 2)
    {
        //        _fromView.hidden = NO;
        //        _toView.hidden = NO;
        _fromView.frame = _fromOriginFrame;
        [_parentView addSubview:_fromView];
        
        [self removeFromSuperview];
    }
    
}

@end
