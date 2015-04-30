//
//  ExpansiveCell.m
//  eLife
//
//  Created by mac on 14-3-31.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "ExpansiveCell.h"

@implementation ExpansiveCell
@synthesize headerView = _headerView;
@synthesize contentView = _contentView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];
        self.layer.borderWidth = 1.2;
        self.layer.cornerRadius = 7.0;
        self.layer.borderColor = [UIColor colorWithRed:133/255. green:173/255. blue:210/255. alpha:1].CGColor;
        self.clipsToBounds = YES;
        
        self.userInteractionEnabled = YES;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)setHeaderView:(HeaderView *)headerView
{
    _headerView = headerView;
    [self addSubview:headerView];
}

- (void)setContentView:(UIView *)contentView
{
    _contentView = contentView;
    [self addSubview:contentView];
}

@end
