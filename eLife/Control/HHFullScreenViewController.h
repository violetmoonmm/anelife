//
//  HHFullScreenViewController.h
//  Here
//
//  Created by here004 on 11-12-30.
//  Copyright (c) 2011年 Tian Tian Tai Mei Net Tech (Bei Jing) Lt.d. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <QuartzCore/QuartzCore.h>

@interface HHFullScreenViewController : UIViewController
{
    BOOL isHorizontal ;
    CGFloat _width;
    CGFloat _height;
    CGFloat startX;
    CGFloat startY;
    
    CGPoint cerr;
    
    UIView *fromView;
    UIView *toView;
    
    CGSize toViewSize;
    CGSize fromViewSize;
    
    CGFloat scaleX;
    CGFloat scaleY;
    CGFloat translationX;
    CGFloat translationY;
    CGFloat translationZ;
    
    CALayer *opacityLayer;
    
    CGRect OriginalFrame;
    UIView *superView;
    
    int animationSyte;
}
@property (nonatomic, retain) UIView *fromView;
@property (nonatomic, retain) UIView *toView;
-(IBAction)viewDismiss:(id)sender;
-(void)setShowImage:(UIImage *)image withOrgImage:(UIImage *)orgImage  withX:(float)x withY:(float)y;
- (void)setFromView:(UIView *)fromView toView:(UIView *)toView withX:(float)x withY:(float)y;
- (void)startFirstAnimation;
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
                 fromRotation:(float)fromRotation
                   toRotation:(float)toRotation
          removedOnCompletion:(BOOL)isRemove;
- (CAAnimation *)getOpacityAnimation:(CGFloat)fromOpacity
                           toOpacity:(CGFloat)toOpacity;
- (void)dismiss;

- (void)startAnimation;

@end
