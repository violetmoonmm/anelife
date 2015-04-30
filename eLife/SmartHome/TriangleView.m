//
//  TriangleView.m
//  eLife
//
//  Created by mac on 14-4-14.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "TriangleView.h"

@implementation TriangleView
@synthesize arrowColor;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextBeginPath (context);
    
    CGContextSaveGState(context);
    [self.arrowColor setStroke];
    
	CGContextMoveToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, rect.size.width/2, 0);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    //CGContextAddLineToPoint(context, rect.size.width/2, rect.size.height);
    CGContextStrokePath(context);
    
    //CGContextClosePath(context);
    
    //
    CGContextRestoreGState(context);
    [[UIColor redColor] setStroke];
    CGContextBeginPath (context);

    CGContextMoveToPoint(context, rect.size.width, rect.size.height);
    CGContextAddLineToPoint(context, 0, rect.size.height);

    CGContextClosePath(context);

    


}


@end
