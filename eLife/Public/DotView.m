//
//  DotView.m
//  eLife
//
//  Created by mac on 14-4-12.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "DotView.h"


@implementation DotView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:232/255. green:76/255. blue:52/255. alpha:1] CGColor]);
    CGContextSetFillColorWithColor(context, [[UIColor redColor] CGColor]);
    CGContextFillEllipseInRect(context,rect);

}


@end
