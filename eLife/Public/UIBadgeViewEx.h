//
//  UIBadgeViewEx.h
//  eLife
//
//  Created by mac on 14-4-14.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBadgeViewEx : UIView
{
    UIFont *_font;
}

@property (nonatomic, retain) NSString *badgeString;

- (void)drawRoundedRect:(CGRect) rrect
               inContext:(CGContextRef) context
			  withRadius:(CGFloat) radius;

@end
