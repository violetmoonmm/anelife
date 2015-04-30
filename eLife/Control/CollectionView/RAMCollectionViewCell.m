//
//  RAMCollectionViewCell.m
//  RAMCollectionViewFlemishBondLayoutDemo
//
//  Created by Rafael Aguilar Martín on 20/10/13.
//  Copyright (c) 2013 Rafael Aguilar Martín. All rights reserved.
//

#import "RAMCollectionViewCell.h"
#import "SCGIFImageView.h"

#define ICON_H 47
#define ICON_W 77
#define LBL_H 24

@interface RAMCollectionViewCell ()
{
    SCGIFImageView *iconView;
    UILabel *label;
    UIView *addView;
    UILabel *subLabel;
    
    NSString *gifPath;
    
    UIActivityIndicatorView *indicator;
    UIView *indicatorBgd;
}

@end

@implementation RAMCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - Setup
- (void)setup
{
    
    NSInteger originY = (CGRectGetHeight(self.bounds)-ICON_H-2*LBL_H)/4;
    NSInteger spacingY = originY;
    
    iconView = [[SCGIFImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.bounds)-ICON_W)/2 , originY, 77, 47)];
    iconView.userInteractionEnabled = YES;
    [self addSubview:iconView];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(iconView.frame)+spacingY, CGRectGetWidth(self.bounds), LBL_H)];
    label.backgroundColor = [UIColor clearColor];
    NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 14 : 16);
    label.font = [UIFont systemFontOfSize:fontSize];
    label.textAlignment = NSTextAlignmentCenter;
    
    [self addSubview:label];
    
    subLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(label.frame)+spacingY, CGRectGetWidth(self.bounds), LBL_H)];
    subLabel.backgroundColor = [UIColor clearColor];
    fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 14 : 16);
    subLabel.font = [UIFont systemFontOfSize:fontSize];
    subLabel.textAlignment = NSTextAlignmentCenter;
    
    [self addSubview:subLabel];
    
    
    indicatorBgd = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.bounds)-40)/2, (CGRectGetHeight(self.bounds)-40)/2, 40, 40)];
    indicatorBgd.backgroundColor = [UIColor colorWithRed:157/255. green:146/255. blue:149/255. alpha:1];
    indicatorBgd.layer.opacity = 0.5;
    indicatorBgd.layer.cornerRadius = 5;
    [self addSubview:indicatorBgd];
    [indicatorBgd setHidden:YES];
    
    indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    indicator.frame = CGRectMake((CGRectGetWidth(indicatorBgd.bounds)-20)/2, (CGRectGetHeight(indicatorBgd.bounds)-20)/2, 20, 20);
    indicator.hidesWhenStopped = YES;
    [indicatorBgd addSubview:indicator];
    
    
    
   UIImage *orgImage = [UIImage imageNamed:@"StrLine"];
    UIImage *stImage = [orgImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, orgImage.size.height-2, 2) resizingMode:UIImageResizingModeStretch];
 
//    self.layer.contents = orgImage;
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:self.bounds];
    imgView.image = stImage;
    [self addSubview:imgView];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(0.8, 0.8);
    CGFloat alpha;
    if (highlighted) {

        scaleTransform = CGAffineTransformMakeScale(0.8, 0.8);
        alpha = .7f;
    }else {
        alpha = 1.f;
        scaleTransform = CGAffineTransformIdentity;
    }
    
//    iconView.alpha = alpha;
//    iconView.transform = scaleTransform;
    
    CGFloat duration = [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 ? 0.1 : 0;
    [UIView animateWithDuration:0.1 animations:^{
        iconView.alpha = alpha;
        iconView.transform = scaleTransform;
        
    }completion:^(BOOL f){
        
    }];
}

#pragma mark - Configure
- (void)configureCellWithText:(NSString *)text textColor:(UIColor *)textColor
{
    [indicator stopAnimating];
    [indicatorBgd setHidden:YES];
    
    gifPath = nil;
    
    [label setText:text];
    [label setTextColor:textColor];
    
    [subLabel setText:nil];
    [subLabel setTextColor:nil];
    
    [iconView setImage:nil];
    
    CGRect lblframe = label.frame;
    lblframe.origin.y = (CGRectGetHeight(self.bounds)-LBL_H)/2;
    label.frame = lblframe;
    
}




- (void)configureCellWithIcon:(UIImage *)icon additionView:(UIView *)additionView text:(NSString *)text subText:(NSString *)subText textColor:(UIColor *)textColor
{
    
    [indicator stopAnimating];
    [indicatorBgd setHidden:YES];
    
    [iconView setImage:icon];
    
    [addView removeFromSuperview];
    
    if (additionView) {
        addView = additionView;
        
        CGRect frame = addView.bounds;
        frame.origin.x = (CGRectGetWidth(iconView.bounds)-CGRectGetWidth(addView.bounds))/2;
        frame.origin.y = (CGRectGetHeight(iconView.bounds)-CGRectGetHeight(addView.bounds))/2;
        addView.frame = frame;
        
        [iconView addSubview:addView];
        
    }
    
    
    [label setText:text];
    [label setTextColor:textColor];
    
    [subLabel setText:subText];
    [subLabel setTextColor:textColor];
    
    NSInteger spacingY = (CGRectGetHeight(self.bounds)-ICON_H-LBL_H)/3;
    CGRect lblframe = label.frame;
    lblframe.origin.y = CGRectGetMaxY(iconView.frame)+spacingY;
    label.frame = lblframe;
}

- (void)startAnimating
{
    [indicatorBgd setHidden:NO];
    [indicator startAnimating];
    

}

- (void)stopAnimating
{
    [indicator stopAnimating];
    [indicatorBgd setHidden:YES];
}


@end
