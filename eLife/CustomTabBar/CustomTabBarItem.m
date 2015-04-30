//
//  CustomTabBarItem.m
//  eLife
//
//  Created by mac on 14-3-15.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "CustomTabBarItem.h"
#import "UIBadgeView.h"
#import "DotView.h"

#define NORMAL_COLOR [UIColor colorWithRed:91/255.0 green:91/255.0 blue:91/255.0 alpha:1]
#define SELECTED_COLOR [UIColor colorWithRed:1/255.0 green:168/255.0 blue:255/255.0 alpha:1]

@implementation CustomTabBarItem
{
    UILabel		*_titleLabel;
	UIImageView	*_imageView;
    UIBadgeView *_badgeView;
    
    UIImage		*_normalImage;
	UIImage		*_selectedImage;
    
    DotView     *_trackPoint;
}

@synthesize badgeValue = _badgeValue;


- (id)initWithFrame:(CGRect)frame
			  title:(NSString *)aTitle
			  image:(UIImage *)aImage
       hightedImage:(UIImage *)ahightedImage
{
    if (self = [super initWithFrame:frame]) {
        _normalImage = aImage;
        _selectedImage = ahightedImage;
        
        NSInteger iconWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 30 : 38);
        NSInteger iconHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 25 : 32);
        
        _imageView	= [[UIImageView alloc] initWithFrame:CGRectMake( (frame.size.width - iconWidth ) /2, 4, iconWidth, iconHeight)];
        _imageView.backgroundColor	= [UIColor clearColor];
        _imageView.image = _normalImage;
        [self addSubview:_imageView];
        
        NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 11 : 14);
        _titleLabel	= [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height - 21, frame.size.width, 20)];
        _titleLabel.textAlignment	= NSTextAlignmentCenter;
        _titleLabel.text = aTitle;
        _titleLabel.numberOfLines = 0;
        _titleLabel.font = [UIFont systemFontOfSize:fontSize];
        _titleLabel.backgroundColor	= [UIColor clearColor];
        _titleLabel.textColor		= NORMAL_COLOR;
        [self addSubview:_titleLabel];
        
        _badgeView = [[UIBadgeView alloc] initWithFrame:CGRectMake(frame.size.width/2, 0, 60, 20)];
        _badgeView.badgeString = nil;
        _badgeView.badgeColor = [UIColor redColor];
        
        _trackPoint = [[DotView alloc] initWithFrame:CGRectMake(CGRectGetWidth(_imageView.frame)-10, 0, 10, 10)];
        _trackPoint.hidden = YES;
        //_trackPoint.backgroundColor = [UIColor redColor];
        [_imageView addSubview:_trackPoint];
        //[self bringSubviewToFront:_trackPoint];
        
    }
    
    return self;
}

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

- (void)setBadgeValue:(NSString *)aValue
{
    if (aValue == nil || [aValue isEqualToString:@"0"])
    {
        [_badgeView removeFromSuperview];
    }
    else
    {
        [self addSubview:_badgeView];
        [_badgeView setBadgeString:aValue];
    }
}

- (void)displayTrackPoint:(BOOL)yesOrNo
{
   
    _trackPoint.hidden = yesOrNo ? NO : YES;
    
}

- (void)setSelected:(BOOL)b
{
    if (b)
	{
		_imageView.image = _selectedImage;
		_titleLabel.textColor = SELECTED_COLOR;
	}
	else {
		_imageView.image = _normalImage;
		_titleLabel.textColor = NORMAL_COLOR;
	}
}

@end
