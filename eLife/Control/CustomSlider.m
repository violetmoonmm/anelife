//
//  CustomSlider.m
//  eLife
//
//  Created by 陈杰 on 14/12/3.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "CustomSlider.h"

@implementation CustomSlider

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

//get the location of the thumb
- (CGRect)thumbRect
{
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbRect = [self thumbRectForBounds:self.bounds
                                      trackRect:trackRect
                                          value:self.value];
    return thumbRect;
}

//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
//{
//    CGRect trackRect = [self trackRectForBounds:self.bounds];
//    CGRect thumbRect = [self thumbRectForBounds:self.bounds
//                                      trackRect:trackRect
//                                          value:self.value];
//    
//
//    CGRect respFrame = CGRectMake(CGRectGetMinX(trackRect), CGRectGetMinY(thumbRect), CGRectGetWidth(trackRect), CGRectGetHeight(thumbRect)+20);
//    
//    // check if the point is within the thumb
//    if (CGRectContainsPoint(respFrame, point))
//    {
//        // if so trigger the method of the super class
//        NSLog(@"inside thumb");
//        return [super hitTest:point withEvent:event];
//    }
//    else
//    {
//        // if not just pass the event on to your superview
//        NSLog(@"outside thumb");
//        return [[self superview] hitTest:point withEvent:event];
//    }
//}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    
//}

@end
