//
//  ProgressView.m
//  eLife
//
//  Created by 陈杰 on 14/12/18.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "ProgressView.h"

@interface ProgressView ()
{
    UIView *colorView;//彩色
    UIView *grayView;//灰色
    
   
}

@end


@implementation ProgressView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        colorView = [[UIView alloc] initWithFrame:CGRectZero];
        colorView.backgroundColor = [UIColor colorWithRed:33/255. green:245/255. blue:99/255. alpha:1];
        [self addSubview:colorView];
        
        grayView = [[UIView alloc] initWithFrame:CGRectZero];
        grayView.backgroundColor = [UIColor colorWithRed:238/255. green:255/255. blue:255/255. alpha:1];
        [self addSubview:grayView];
        
        self.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}


- (void)setMaxValue:(NSInteger)maxValue
{
    _maxValue = maxValue;
    
    [self setNeedsLayout];
}


- (void)setValue:(NSInteger)value
{
    _value = value;
    
    [self setNeedsLayout];
}


- (void)layoutSubviews
{
    NSInteger colorWidth = CGRectGetWidth(self.bounds)*_value/_maxValue;
    NSInteger grayWith = CGRectGetWidth(self.bounds)*(_maxValue-_value)/_maxValue;
    
    CGRect colorFrame = CGRectMake(0, 0, colorWidth, CGRectGetHeight(self.bounds));
    
    CGRect grayFrame = CGRectMake(CGRectGetMaxX(colorFrame), 0, grayWith, CGRectGetHeight(self.bounds));
    
    colorView.frame = colorFrame;
    grayView.frame = grayFrame;
}

@end
