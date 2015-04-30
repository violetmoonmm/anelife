//
//  LightCtrlView.m
//  eLife
//
//  Created by mac on 14-8-25.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "BasicPlugCell.h"
#import "NetAPIClient.h"
#import "DeviceCtrlBgdView.h"
#import "Util.h"
#import "MBProgressHUD.h"


#define MarginX 2//x轴左右边缘
#define MarginY 2//y轴上下边缘

@interface BasicPlugCell ()
{
    UIImageView *iconView;
    UILabel *nameLbl;
    
    UIImageView *bgdView;
    
    UIView *indicatorBgd;
    UIActivityIndicatorView *indicator;
    
}

@end

@implementation BasicPlugCell


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
        
        NSInteger iconWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 84);
        NSInteger iconHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 40 : 60);
        
        NSInteger orginY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 1 : 20);
        NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 1 : 8);
        
        NSInteger labelHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 16 : 22);
        NSInteger labelSize = CELL_TEXT_FONT_SMALL;
        UIFont *labelFont = [UIFont systemFontOfSize:labelSize];
        
        iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SocketOffline"]];
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

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */



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

- (void)switchPower
{
    [self startAnimating];
    
    if (self.device.state.powerOn) {
        [[NetAPIClient sharedClient] setPowerOff:self.device successCallback:^{
            
            [self stopAnimating];
            
            NSLog(@"socketClose: %@ gatewayId:%@ success",self.device.serialNumber,self.device.gatewaySN);
            
        }failureCallback:^{
            
            [self stopAnimating];
            
            [self showCtrlFailedHint];
            
            NSLog(@"socketClose: %@ gatewayId:%@ failed",self.device.serialNumber,self.device.gatewaySN);
            
            
        }];
    }
    else {
 
        [[NetAPIClient sharedClient] setPowerOn:self.device successCallback:^{
            [self stopAnimating];
            
            NSLog(@"socketOpen: %@ gatewayId:%@ success",self.device.serialNumber,self.device.gatewaySN);
        }failureCallback:^{
            [self stopAnimating];
            
            [self showCtrlFailedHint];
            
            NSLog(@"socketOpen: %@ gatewayId:%@ failed",self.device.serialNumber,self.device.gatewaySN);
        }];
    }
}




- (void)onClick
{
    
    if (self.device.state.online) {
        [self switchPower];
    }
    
}





- (void)setDevice:(SHDevice *)device
{
    
    [super setDevice:device];
    
}



- (void)setName:(NSString *)name
{
    nameLbl.text = name;
}


- (void)displayDeviceStatus
{
    
    if (!self.device.state.online) {
 
        [iconView setImage:[UIImage imageNamed:@"SocketOffline"]];
    }
    else if (self.device.state.powerOn) {
        

        [iconView setImage:[UIImage imageNamed:@"SocketOn"]];
        
    }
    else {
    
        [iconView setImage:[UIImage imageNamed:@"SocketOff"]];
    }
}



@end
