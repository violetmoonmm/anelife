//
//  LightCtrlView.m
//  eLife
//
//  Created by mac on 14-8-25.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "BasicCurtainCell.h"
#import "NetAPIClient.h"
#import "CurtainView.h"
#import "Util.h"
#import "DeviceCtrlBgdView.h"

#define MarginX 2//x轴左右边缘
#define MarginY 2//y轴上下边缘

@interface BasicCurtainCell () <DeviceCtrlBgdViewDelegate>
{
    UIImageView *iconView;
    UILabel *nameLbl;
    
    UIImageView *bgdView;
    
    CurtainView *deviceController;

}

@end

@implementation BasicCurtainCell


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
        
        //添加点击手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClick)];
        [bgdView addGestureRecognizer:tap];
        
        NSInteger iconWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 34 : 50);
        NSInteger iconHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 40 : 60);
        
        NSInteger orginY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 1 : 20);
        NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 1 : 8);
        
        NSInteger labelHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 16 : 22);
        NSInteger labelSize = CELL_TEXT_FONT_SMALL;
        UIFont *labelFont = [UIFont systemFontOfSize:labelSize];
        
        iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CurtainOffline"]];
        iconView.frame = CGRectMake((CGRectGetWidth(bgdView.frame)-iconWidth)/2, orginY, iconWidth, iconHeight);
        [bgdView addSubview:iconView];
        
        nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(iconView.frame)+spacingY, CGRectGetWidth(bgdView.frame), labelHeight)];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}



- (void)setName:(NSString *)name
{
    nameLbl.text = name;
}




- (void)setDevice:(SHDevice *)device
{

    
    [super setDevice:device];
    

}





- (void)displayDeviceStatus
{
    if (!self.device.state.online) {
        [iconView setImage:[UIImage imageNamed:@"CurtainOffline"] ];
    }
    else {
        
        NSString *iconImage = @"CommonCurtain";
        
        
        id components = _device.range;
        if ([components isKindOfClass:[NSArray class]]) {
            if ([components count] == 2) {//可调行程窗帘
                
            
                NSInteger min = _device.minRange;
                NSInteger max = _device.maxRange;
                
                int currentValue = [(SHCurtainState *)self.device.state shading];
                
                if (currentValue == max) {
                    iconImage = @"StepCurtainMax";
                }
                else if (currentValue == min) {
                    iconImage = @"StepCurtainMin";
                }
                else {
                    iconImage = @"StepCurtainMid";
                }
                
                //iconImage = @"StepCurtainMid";
                
            }
        }
        
        [iconView setImage:[UIImage imageNamed:iconImage] ];
    }
}



- (void)onClick
{
    if ([self.device.state online]) {//在线才可以点击进入控制界面
        NSString *nibName = [Util nibNameWithClass:[CurtainView class]];
        CurtainView *ctrlView = [[CurtainView alloc] initWithNibName:nibName bundle:nil];

         deviceController = ctrlView;
        [self showDeviceControlView:ctrlView.view];
      
        [ctrlView setDevice:_device];
    }
}



- (void)deviceCtrlBgdViewWillDismiss
{
    deviceController = nil;
}


@end
