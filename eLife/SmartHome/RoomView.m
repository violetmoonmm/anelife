//
//  RoomView.m
//  eLife
//
//  Created by mac on 14-4-17.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "RoomView.h"
@interface RoomView()
{
    UIImageView *iconView;
    UIImageView *bgdView;
    UILabel *titleLabel;
    UILabel *subtitleLabel;
    
    UIImage *_normalImage;
    UIImage *_selectedImage;
    UIImage *_bgdImage;
}
@end

@implementation RoomView

@synthesize selected = _selected;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
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
- (void)buildIcon:(UIImage *)icon selectedIcon:(UIImage *)sIcon title:(NSString *)title subtitle:(NSString *)subtitle backgroundImage:(UIImage *)bgdImage
{
    bgdView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
    bgdView.image = nil;
    bgdView.userInteractionEnabled = YES;
    [self addSubview:bgdView];

    CGFloat iconW  = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? 25 : 32;
    CGFloat iconX = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? 6 : 12;
    iconView = [[UIImageView alloc] initWithFrame:CGRectMake(iconX, (CGRectGetHeight(self.frame)-iconW)/2, iconW, iconW)];
    iconView.image = icon;
    [bgdView addSubview:iconView];
    
    
    NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? 12 : 13;
    
    CGRect titleLblFrame = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ?  CGRectMake(CGRectGetMaxX(iconView.frame)+1, 4, 54, 18) : CGRectMake(CGRectGetMaxX(iconView.frame)+3, 10, 86, 20);
    
    titleLabel = [[UILabel alloc] initWithFrame:titleLblFrame];
    titleLabel.text = title;
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:fontSize];
    titleLabel.backgroundColor = [UIColor clearColor];
    [bgdView addSubview:titleLabel];
    
    
    CGRect subTitleFrame = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? CGRectMake(CGRectGetMinX(titleLabel.frame), CGRectGetMaxY(titleLabel.frame)+1, 54, 18) : CGRectMake(CGRectGetMinX(titleLabel.frame), CGRectGetMaxY(titleLabel.frame)+2, 86, 20);
    subtitleLabel = [[UILabel alloc] initWithFrame:subTitleFrame];
    subtitleLabel.text = subtitle;
    subtitleLabel.textColor = [UIColor blackColor];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font = [UIFont systemFontOfSize:fontSize];
    subtitleLabel.backgroundColor = [UIColor clearColor];
    [bgdView addSubview:subtitleLabel];
    
    _selectedImage = sIcon;
    _normalImage = icon;
    _bgdImage = bgdImage;
//    _bgdImage = [bgdImage resizableImageWithCapInsets:UIEdgeInsetsMake(17, 50, 17, 50)];

}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    if (_selected) {
        titleLabel.textColor = [UIColor whiteColor];
        subtitleLabel.textColor = [UIColor whiteColor];
        bgdView.image = _bgdImage;
        iconView.image = _selectedImage;
    }
    else {
        titleLabel.textColor = [UIColor blackColor];
        subtitleLabel.textColor = [UIColor blackColor];
        bgdView.image = nil;
        iconView.image = _normalImage;
    }
}

@end
