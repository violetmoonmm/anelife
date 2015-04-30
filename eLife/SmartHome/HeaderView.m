//
//  HeaderView.m
//  eLife
//
//  Created by mac on 14-3-31.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "HeaderView.h"

#define INDICATOR_H ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 16 : 20)
#define INDICATOR_W INDICATOR_H

#define ICON_W ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 44 : 80)


#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

@interface HeaderView ()
{
    UIImageView *_indicatorView;
    UIImageView *_iconView;
    UILabel *_stLbl;
    UILabel *_titleLbl;
}

@end

@implementation HeaderView
@synthesize open = _open;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHeader:)];
        [self addGestureRecognizer:tap];
        
        _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self addSubview:_iconView];

        _titleLbl = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLbl.backgroundColor = [UIColor clearColor];
        [self addSubview:_titleLbl];
        
        _indicatorView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self addSubview:_indicatorView];
        
        _stLbl = [[UILabel alloc] initWithFrame:CGRectZero];
        _stLbl.textColor = [UIColor grayColor];
        _stLbl.textAlignment = NSTextAlignmentRight;
        _stLbl.backgroundColor = [UIColor clearColor];
        [self addSubview:_stLbl];
        

        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"sh_header.png"]];
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

- (void)layoutSubviews
{
    _indicatorView.frame = CGRectMake(CGRectGetWidth(self.frame) - INDICATOR_W -10, (CGRectGetHeight(self.frame) - INDICATOR_H)/2, INDICATOR_W, INDICATOR_H);
    
    _iconView.frame = CGRectMake(5, (CGRectGetHeight(self.frame) - ICON_W)/2, ICON_W, ICON_W);
    
    //状态
    NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 14 : 16);
    UIFont *stFont = [UIFont systemFontOfSize:fontSize];
    CGSize stSize = [_stLbl.text sizeWithFont:stFont constrainedToSize:CGSizeMake(100, CGRectGetHeight(self.frame))];
    _stLbl.frame = CGRectMake(CGRectGetMinX(_indicatorView.frame) - 10 - stSize.width, (CGRectGetHeight(self.frame) - stSize.height)/2, stSize.width, stSize.height);
    _stLbl.font = stFont;
    
    //标题
    fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 16 : 20);
    UIFont *titleFont = [UIFont boldSystemFontOfSize:fontSize];
    CGSize titleSize = [_titleLbl.text sizeWithFont:titleFont constrainedToSize:CGSizeMake(100, CGRectGetHeight(self.frame))];
    _titleLbl.frame = CGRectMake(CGRectGetMaxX(_iconView.frame) + 14, (CGRectGetHeight(self.frame) - titleSize.height)/2, titleSize.width, titleSize.height);
    _titleLbl.font = titleFont;
    
    [super layoutSubviews];
    
}

- (void)setIcon:(UIImage *)icon title:(NSString *)title status:(NSString *)status indicator:(UIImage *)indicator
{

    _iconView.image = icon;
    _titleLbl.text = title;
    _stLbl.text = status;
    _indicatorView.image = indicator;

}

- (void)tapHeader:(UITapGestureRecognizer *)gesture
{
    _open = !_open;
    CGFloat angle = DEGREES_TO_RADIANS(self.open ? 180 : 0 );
    
     [UIView animateWithDuration:0.2 animations:^{
            CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
          _indicatorView.transform = transform;
    }];

    if ([self.delegate respondsToSelector:@selector(tapHeaderView:)]) {
        [self.delegate tapHeaderView:self];
    }
}

- (void)setOpen:(BOOL)open
{
    _open = open;
    CGFloat angle = DEGREES_TO_RADIANS(self.open ? 180 : 0 );
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
    _indicatorView.transform = transform;
}

@end
