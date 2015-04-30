//
//  UIBadgeViewEx.m
//  eLife
//
//  Created by mac on 14-4-14.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "UIBadgeViewEx.h"

#define HEXCOLOR(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation UIBadgeViewEx

@synthesize badgeString;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _font = [UIFont systemFontOfSize:14];
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    NSString *countString = badgeString;
	
	CGSize numberSize = [countString sizeWithFont: _font];

	
	CGRect bounds = CGRectMake(0 , 0, numberSize.width + 13 , 21);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	UIColor *col = [UIColor redColor];
		
	CGContextSaveGState(context);
	//CGContextClearRect(context, bounds);
	CGContextSetAllowsAntialiasing(context, true);
	CGContextSetLineWidth(context, 0.0);
	CGContextSetAlpha(context, 1.0);
	
	CGContextSetLineWidth(context, 2.0);
	
	
	
	CGContextSetStrokeColorWithColor(context, [HEXCOLOR(0xffffffff) CGColor]);
	CGContextSetFillColorWithColor(context, [col CGColor]);
    
	// Draw background
	//红色背景
	CGFloat backOffset = 2;
	CGRect backRect = CGRectMake(bounds.origin.x + backOffset,
								 bounds.origin.y + backOffset,
								 bounds.size.width - backOffset*2,
								 bounds.size.height - backOffset*2);
    
    
    [self drawRoundedRect:backRect inContext:context withRadius:8];
    
    
    
	CGContextDrawPath(context, kCGPathFillStroke);
	/*
     // Clip Context
     CGRect clipRect = CGRectMake(backRect.origin.x + backOffset-1,
     backRect.origin.y + backOffset-1,
     backRect.size.width - (backOffset-1)*2,
     backRect.size.height - (backOffset-1)*2);
     
     [self drawRoundedRect:clipRect inContext:context withRadius:8];
     CGContextClip (context);
     
     CGContextSetBlendMode(context, kCGBlendModeClear);*/
    
	CGContextRestoreGState(context);
    
	
	CGRect ovalRect = CGRectMake(2, 1, bounds.size.width-4,
								 bounds.size.height /2);
    
	bounds.origin.x = (bounds.size.width - numberSize.width) / 2 + 0.5;
	bounds.origin.y++;
	
	CGContextSetFillColorWithColor(context, [HEXCOLOR(0xffffffff)  CGColor]);
	
    //数字
	[countString drawInRect:bounds withFont:_font];
	
	CGContextSaveGState(context);
    
	
	//Draw highlight
	CGGradientRef glossGradient;
	CGColorSpaceRef rgbColorspace;
	size_t num_locations = 9;
	CGFloat locations[9] = { 0.0, 0.10, 0.25, 0.40, 0.45, 0.50, 0.65, 0.75, 1.00 };
    //	CGFloat components[8] = { 1.0, 1.0, 1.0, 0.40, 1.0, 1.0, 1.0, 0.06 };
	CGFloat components[36] = {
		1.0, 1.0, 1.0, 1.00,
		1.0, 1.0, 1.0, 0.55,
		1.0, 1.0, 1.0, 0.20,
		1.0, 1.0, 1.0, 0.20,
		1.0, 1.0, 1.0, 0.15,
		1.0, 1.0, 1.0, 0.10,
		1.0, 1.0, 1.0, 0.10,
		1.0, 1.0, 1.0, 0.05,
		1.0, 1.0, 1.0, 0.05 };
	rgbColorspace = CGColorSpaceCreateDeviceRGB();
	glossGradient = CGGradientCreateWithColorComponents(rgbColorspace,
														components, locations, num_locations);
	
	
	CGPoint start = CGPointMake(bounds.origin.x, bounds.origin.y);
	CGPoint end = CGPointMake(bounds.origin.x, bounds.size.height*2);
	
	CGContextSetAlpha(context, 1.0);
    
	//[self drawRoundedRect:ovalRect inContext:context withRadius:4];
	
	CGContextBeginPath (context);
	
	CGFloat minx = CGRectGetMinX(ovalRect), midx = CGRectGetMidX(ovalRect),
	maxx = CGRectGetMaxX(ovalRect);
	
	CGFloat miny = CGRectGetMinY(ovalRect), midy = CGRectGetMidY(ovalRect),
	maxy = CGRectGetMaxY(ovalRect);
	
	CGContextMoveToPoint(context, minx, midy);
	CGContextAddArcToPoint(context, minx, miny, midx, miny, 8);
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, 8);
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, 4);
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, 4);
	CGContextClosePath(context);
    
	CGContextClip (context);
	
    //	CGContextDrawLinearGradient(context, glossGradient, start, end, 0);
	CGContextDrawLinearGradient(context, glossGradient, start, end, 0);
	
	CGGradientRelease(glossGradient);
	CGColorSpaceRelease(rgbColorspace);
    
	CGContextSetFillColorWithColor(context, [HEXCOLOR(0x000000ff) CGColor]);
	
	
	CGContextRestoreGState(context);

}


- (void) drawRoundedRect:(CGRect) rrect inContext:(CGContextRef) context
			  withRadius:(CGFloat) radius
{
	CGContextBeginPath (context);
	
	CGFloat minx = CGRectGetMinX(rrect), midx = CGRectGetMidX(rrect),
	maxx = CGRectGetMaxX(rrect);
	
	CGFloat miny = CGRectGetMinY(rrect), midy = CGRectGetMidY(rrect),
	maxy = CGRectGetMaxY(rrect);
	
	CGContextMoveToPoint(context, minx, midy);
	CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
	CGContextClosePath(context);
}

@end
