//
//  RAMCollectionAuxView.m
//  RAMCollectionViewFlemishBondLayoutDemo
//
//  Created by Rafael Aguilar Martín on 20/10/13.
//  Copyright (c) 2013 Rafael Aguilar Martín. All rights reserved.
//

#import "RAMCollectionAuxView.h"

@implementation RAMCollectionAuxView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        UIView *bgdView = [[UIView alloc] initWithFrame:self.bounds];
        bgdView.backgroundColor = [UIColor colorWithRed:214/255. green:214/255. blue:214/255. alpha:1];
        [self addSubview:bgdView];
        
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, CGRectGetWidth(bgdView.bounds)-10, CGRectGetHeight(bgdView.bounds))];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textAlignment = NSTextAlignmentLeft;
        self.label.font = [UIFont boldSystemFontOfSize:15.0f];
        self.label.textColor = [UIColor blackColor];
        
        [bgdView addSubview:self.label];
    }
    
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.label.text = nil;
}

@end
