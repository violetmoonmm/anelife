//
//  LightCtrlView.m
//  eLife
//
//  Created by mac on 14-8-25.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "SceneCell.h"
#import "NetAPIClient.h"
#import "SCGIFImageView.h"
#import "DimmerlightView.h"
#import "DeviceCtrlBgdView.h"
#import "Util.h"
#import "MBProgressHUD.h"

#define MarginX 2//x轴左右边缘
#define MarginY 2//y轴上下边缘


#define SINGLE_SCENE_SELECTED_NTF @"SINGLE_SCENE_SELECTED_NTF"

@interface SceneCell ()
{
    UIImageView *iconView;
    UILabel *nameLbl;
    
    UIImageView *bgdView;
    
    BOOL selected;
    
    NSString *imgName;
    
    SCGIFImageView *animateView;
}

@end

@implementation SceneCell


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
        
        
        //动画
        animateView = [[SCGIFImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bgdView.frame), CGRectGetHeight(bgdView.frame))];
        animateView.hidden = YES;
        [bgdView addSubview:animateView];
        
        //添加点击手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClick)];
        [bgdView addGestureRecognizer:tap];
        
        NSInteger iconWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 84);
        NSInteger iconHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 40 : 60);
        
        NSInteger orginY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 1 : 20);
        NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 1 : 8);
        
        NSInteger labelHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 16 : 22);
        NSInteger labelSize = CELL_TEXT_FONT_SMALL;
        UIFont *labelFont = [UIFont systemFontOfSize:labelSize];
        
        iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LightOffline"]];
        iconView.frame = CGRectMake((CGRectGetWidth(bgdView.frame)-iconWidth)/2, orginY, iconWidth, iconHeight);
        [bgdView addSubview:iconView];
        
        nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(iconView.frame)+spacingY, CGRectGetWidth(bgdView.frame), labelHeight)];
        nameLbl.font = labelFont;
        nameLbl.textColor = [UIColor colorWithRed:82/255. green:157/255. blue:31/255. alpha:1];
        nameLbl.textAlignment = NSTextAlignmentCenter;
        nameLbl.backgroundColor = [UIColor clearColor];
        [bgdView addSubview:nameLbl];
        if (CGRectGetMaxY(nameLbl.frame) > CGRectGetHeight(bgdView.frame)) {
            [nameLbl setHidden:YES];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSceneCellSlctNtf:) name:SINGLE_SCENE_SELECTED_NTF object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

- (void)handleSceneCellSlctNtf:(NSNotification *)ntf
{
    if (ntf.object != self) {
        selected = NO;
        
        iconView.image = [self imageForIcon];
    }
}



- (void)onClick
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SINGLE_SCENE_SELECTED_NTF object:self];
    
    animateView.hidden = NO;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"SSceneSwitching" ofType:@"gif"];
    [animateView setGIFFile:filePath];
    [animateView setAnimationDuration:2.0];
    [animateView setAnimationRepeatCount:0];
    [animateView startAnimating];
    
    [[NetAPIClient sharedClient] setSceneMode:_device successCallback:^{
        
        [animateView stopAnimating];
        animateView.hidden = YES;
        
        selected = YES;
        
        iconView.image = [self imageForIcon];
        
    }failureCallback:^{
        
        [animateView stopAnimating];
        animateView.hidden = YES;
        
        [self showCtrlFailedHint];
    }];
}

- (UIImage *)imageForIcon
{
    NSString *name = nil;
    if (selected) {
        name = [imgName stringByAppendingString:@"_green"];
    }
    else {
        name = [imgName stringByAppendingString:@"_gray"];
    }
    
    return [UIImage imageNamed:name];
}


- (void)setElements:(NSArray *)elements
{
    if ([elements count]) {
        
        NSDictionary *params = [elements objectAtIndex:0];
        
        _deviceId = [params objectForKey:@"dev_id"];
        _gatewayId = [params objectForKey:@"gateway_sn"];
        imgName = [params objectForKey:@"background"];
        
        iconView.image = [self imageForIcon];
    }
}




- (void)setDevice:(SHDevice *)device
{
    _device = device;
    
    nameLbl.text = _device.name;
    
}



- (void)setName:(NSString *)name
{
    nameLbl.text = name;
}



@end
