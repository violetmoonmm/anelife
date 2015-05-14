//
//  LightCtrlView.m
//  eLife
//
//  Created by mac on 14-8-25.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "BasicAirConditionCell.h"
#import "NetAPIClient.h"
#import "AirConditionView.h"
#import "Util.h"
#import "DeviceCtrlBgdView.h"

#define MarginX 2//x轴左右边缘
#define MarginY 2//y轴上下边缘

@interface BasicAirConditionCell () <DeviceCtrlBgdViewDelegate>
{
    UIImageView *iconView;
    UILabel *nameLbl;
    
    UIImageView *bgdView;
    

    UIImageView *modeView;//模式
    UIImageView *windSpeedView;//风速
    UILabel *tempLabel;//温度
    
    AirConditionView *deviceController;
}

@end

@implementation BasicAirConditionCell


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
        
        NSInteger iconWidth = CGRectGetWidth(bgdView.bounds)-4;
        NSInteger iconHeight = 60;
        if (iconHeight > CGRectGetHeight(bgdView.frame)) {
            iconHeight = CGRectGetHeight(bgdView.frame);
        }
        
        NSInteger orginY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 1 : 20);
        NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? -19 : 8);
        NSInteger labelHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 16 : 22);
        
        NSInteger originX = (CGRectGetWidth(bgdView.frame) - iconWidth)/2;
        
        NSInteger labelSize = CELL_TEXT_FONT_SMALL;
        UIFont *labelFont = [UIFont systemFontOfSize:labelSize];
        
        iconHeight = iconHeight+orginY > CGRectGetHeight(frame) ? CGRectGetHeight(frame)-orginY : iconHeight;
        
        iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AirconditionOffline"]];
        iconView.frame = CGRectMake(originX, orginY, iconWidth, iconHeight);
        
        [bgdView addSubview:iconView];
        
        

        nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(iconView.frame)+spacingY, CGRectGetWidth(bgdView.frame), labelHeight)];
        nameLbl.font = labelFont;
        nameLbl.textColor = [UIColor colorWithRed:82/255. green:157/255. blue:31/255. alpha:1];
        nameLbl.textAlignment = NSTextAlignmentCenter;
        nameLbl.backgroundColor = [UIColor clearColor];
        nameLbl.text = self.name;
        [bgdView addSubview:nameLbl];
//        if (CGRectGetMaxY(nameLbl.frame) > CGRectGetHeight(bgdView.frame)) {
//            [nameLbl setHidden:YES];
//        }
         if ([UIScreen mainScreen].bounds.size.height <= 480) {
             [nameLbl setHidden:YES];
         }
        
        
        
        NSInteger textWidth = 36;
        NSInteger textHeight = 28;
        NSInteger modeWidth = 28;
        NSInteger modeHeight = 28;
        NSInteger speedWidth = modeWidth;
        NSInteger speedHeight = modeHeight;
        
        NSInteger spacingX = (iconWidth -textWidth-modeWidth)/3;
        NSInteger statusY = 10;
        
        tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(spacingX, statusY, textWidth, textHeight)];
        tempLabel.textColor = [UIColor whiteColor];
        tempLabel.font = [UIFont boldSystemFontOfSize:16];
        tempLabel.textAlignment = NSTextAlignmentCenter;
        tempLabel.backgroundColor = [UIColor clearColor];
        [iconView addSubview:tempLabel];
        tempLabel.hidden = YES;
        
        modeView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(tempLabel.frame)+spacingX, statusY, modeWidth, modeHeight)];
        [iconView addSubview:modeView];
        modeView.hidden = YES;
        
//        windSpeedView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(modeView.frame)+spacingX, statusY, speedWidth, speedHeight)];
//        [iconView addSubview:windSpeedView];
//        windSpeedView.hidden = YES;
        

        
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
        [iconView stopAnimating];
        [iconView setImage:[UIImage imageNamed:@"AirconditionOffline"] ];
        
        tempLabel.hidden = YES;
        modeView.hidden = YES;
        windSpeedView.hidden = YES;
    }
    else if ([(SHLightState *)self.device.state powerOn]) {
        [iconView setImage:[UIImage imageNamed:@"AirconditionOn"] ];
        
//        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"AirconditionOnGif" ofType:@"gif"];
//        [iconView setGIFFile:filePath];
//        [iconView setAnimationDuration:1.0];
//        [iconView setAnimationRepeatCount:0];
//        [iconView startAnimating];
        
        tempLabel.hidden = NO;
        modeView.hidden = NO;
        windSpeedView.hidden = NO;
        

        [self displayTemperature];
        [self displayWindspeed];
        [self displayMode];
    }
    else {
        [iconView stopAnimating];
        [iconView setImage:[UIImage imageNamed:@"AirconditionOff"] ];
        
        tempLabel.hidden = YES;
        modeView.hidden = YES;
        windSpeedView.hidden = YES;
    }
}


//状态变化时显示温度
- (void)displayTemperature
{
    tempLabel.text = [NSString stringWithFormat:@"%d℃",[(SHAirconditionState *)self.device.state temperature]];
}

//状态变化时显示模式
- (void)displayMode
{
    NSString *strMode = [(SHAirconditionState *)self.device.state mode];

    NSString *imageName = nil;
    
    if ([strMode isEqualToString:@"Cold"]) {//制冷
 
        imageName = @"ModeColdSelected";
    }
    else if ([strMode isEqualToString:@"Hot"]) {//制热

        imageName = @"ModeHotSelected";
    }
    else if ([strMode isEqualToString:@"Wind"]) {//通风

        imageName = @"ModeWindSelected";
    }
    else if ([strMode isEqualToString:@"Wet"]) {//除湿

        imageName = @"ModeWetSelected";
    }
    else if ([strMode isEqualToString:@"Auto"]) {//除湿
        
        imageName = @"ModeAutoSelected";
    }
    
    modeView.image = [UIImage imageNamed:imageName] ;
}

//状态变化时显示风速
- (void)displayWindspeed
{
    NSString *strWind = [(SHAirconditionState *)self.device.state windSpeed];
  
    NSString *imageName = nil;
    
    if ([strWind isEqualToString:@"Stop"]) {//停止

        imageName = nil;
    }
    else if ([strWind isEqualToString:@"Low"]) {//低速
 
        imageName = @"SpeedLowSelected";
    }
    else if ([strWind isEqualToString:@"Middle"]) {//中速
 
        imageName = @"SpeedMidSelected";
    }
    else if ([strWind isEqualToString:@"High"]) {//高速

        imageName = @"SpeedHighSelected";
    }
    else if ([strWind isEqualToString:@"Auto"]) {//自动
        
        imageName = @"ModeAutoSelected";
    }
    
    windSpeedView.image = [UIImage imageNamed:imageName];
}

- (void)onClick
{
     if ([self.device.state online]) {//在线才可以点击进入控制界面
         
         NSString *nibName = [Util nibNameWithClass:[AirConditionView class]];
         AirConditionView *airConditionView = [[AirConditionView alloc] initWithNibName:nibName bundle:nil];

         deviceController = airConditionView;
         [self showDeviceControlView:airConditionView.view];
      
         [airConditionView setDevice:_device];
     }

}


- (void)deviceCtrlBgdViewWillDismiss
{
    deviceController = nil;
}


@end
