//
//  LightCtrlView.m
//  eLife
//
//  Created by mac on 14-8-25.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "BasicHumitureCell.h"
#import "NetAPIClient.h"

#define MarginX 2//x轴左右边缘
#define MarginY 2//y轴上下边缘

@interface BasicHumitureCell ()
{
    UIImageView *icon;
    UILabel *nameLbl;
    
    UIImageView *bgdView;
}

@end

@implementation BasicHumitureCell


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        UIImage *orgImage = [UIImage imageNamed:@"SDeviceCtrlBgd"];
        UIImage *stImage = [orgImage resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
        
        bgdView = [[UIImageView alloc] initWithImage:stImage];
        bgdView.frame = CGRectMake(MarginX, MarginY, CGRectGetWidth(frame) - MarginX*2, CGRectGetHeight(frame) - MarginY*2);
        bgdView.userInteractionEnabled = YES;
        [self addSubview:bgdView];
        
        NSInteger iconWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 84);
        NSInteger iconHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 40 : 60);
        
        NSInteger orginY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 1 : 20);
        NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 1 : 8);
        
        NSInteger labelHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 16 : 22);
        NSInteger labelSize = CELL_TEXT_FONT_SMALL;
        UIFont *labelFont = [UIFont systemFontOfSize:labelSize];
        
        icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Thermometer"]];
        icon.frame = CGRectMake((CGRectGetWidth(bgdView.frame)-iconWidth)/2, orginY, iconWidth, iconHeight);
        [bgdView addSubview:icon];
        
        nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(icon.frame)+spacingY, CGRectGetWidth(bgdView.frame), labelHeight)];
        nameLbl.font = labelFont;
        nameLbl.text = self.name;
        nameLbl.textColor = [UIColor colorWithRed:82/255. green:157/255. blue:31/255. alpha:1];
        nameLbl.textAlignment = NSTextAlignmentCenter;
        nameLbl.backgroundColor = [UIColor clearColor];
        [bgdView addSubview:nameLbl];
        if (CGRectGetMaxY(nameLbl.frame) > CGRectGetHeight(bgdView.frame)) {
            [nameLbl setHidden:YES];
        }
    }
    return self;
}

- (void)dealloc
{
    
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */


- (void)setName:(NSString *)name
{
    nameLbl.text = name;
}

- (void)setDevice:(SHDevice *)device
{
    _device = device;
 
    nameLbl.text = @"24℃";

}




- (void)layoutSubviews
{
    
    
}

@end
