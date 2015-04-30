//
//  BasicVideoEntryCell.m
//  eLife
//
//  Created by mac on 14-9-9.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "BasicVideoEntryCell.h"

#define MarginX 2//x轴左右边缘
#define MarginY 2//y轴上下边缘

@implementation BasicVideoEntryCell
{
    UIView *bgdView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        
        bgdView = [[UIView alloc] initWithFrame:CGRectMake(MarginX, MarginY, CGRectGetWidth(frame) - MarginX*2, CGRectGetHeight(frame) - MarginY*2)];
        bgdView.backgroundColor = [UIColor colorWithRed:248/255. green:134/255. blue:0/255. alpha:1];
        [self addSubview:bgdView];
        
        NSInteger iconH = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 70 : 120);
        NSInteger iconW = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 72 : 120);
        NSInteger fontSize = CELL_TEXT_FONT;
        NSInteger nameH = 24;
        NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 4 : 12);
        NSInteger originY = (CGRectGetHeight(frame) - iconH - nameH - spacingY)/2;

        
        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(bgdView.frame)-iconW)/2, originY, iconW, iconH)];
        iconView.image  = [UIImage imageNamed:@"CameraWhite"];
        [bgdView addSubview:iconView];
        
        UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(iconView.frame), CGRectGetMaxY(iconView.frame)+spacingY, CGRectGetWidth(iconView.frame), nameH)];
        nameLbl.textColor = [UIColor whiteColor];
        nameLbl.numberOfLines = 1;
        nameLbl.font = [UIFont systemFontOfSize:fontSize];
        nameLbl.text = @"视频监护";
        nameLbl.textAlignment = NSTextAlignmentCenter;
        nameLbl.backgroundColor = [UIColor clearColor];
        [bgdView addSubview:nameLbl];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectVideo)];
        [self addGestureRecognizer:tap];
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

- (void)selectVideo
{
    if ([self.delegate respondsToSelector:@selector(entryVideo)]) {
        [self.delegate entryVideo];
    }
}

@end
