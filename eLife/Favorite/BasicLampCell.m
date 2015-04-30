//
//  LightCtrlView.m
//  eLife
//
//  Created by mac on 14-8-25.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "BasicLampCell.h"
#import "NetAPIClient.h"
#import "SCGIFImageView.h"
#import "DimmerlightView.h"
#import "DeviceCtrlBgdView.h"
#import "Util.h"
#import "MBProgressHUD.h"
#import "NotificationDefine.h"


#define MarginX 2//x轴左右边缘
#define MarginY 2//y轴上下边缘

@interface BasicLampCell () <DeviceCtrlBgdViewDelegate>
{
    SCGIFImageView *iconView;
    UILabel *nameLbl;
    
    UIImageView *bgdView;
    
    UIView *indicatorBgd;
    UIActivityIndicatorView *indicator;
    
    DimmerlightView *deviceController;
}

@end

@implementation BasicLampCell


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
        
        //菊花
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
        
        NSInteger iconWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 84);
        NSInteger iconHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 40 : 60);

        NSInteger orginY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 1 : 20);
        NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 1 : 8);
        
        NSInteger labelHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 16 : 22);
        NSInteger labelSize = CELL_TEXT_FONT_SMALL;
        UIFont *labelFont = [UIFont systemFontOfSize:labelSize];
        
        iconView = [[SCGIFImageView alloc] initWithImage:[UIImage imageNamed:@"LightOffline"]];
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


- (void)switchPower
{
    [self startAnimating];
    
    if (self.device.state.powerOn) {
        [[NetAPIClient sharedClient] setPowerOff:self.device successCallback:^{
            [self stopAnimating];
            
            NSLog(@"lightClose: %@ gatewayId:%@ success",self.device.serialNumber,self.device.gatewaySN);
            
        }failureCallback:^{
            [self stopAnimating];
            
            [self showCtrlFailedHint];
            
             NSLog(@"lightClose: %@ gatewayId:%@ failed",self.device.serialNumber,self.device.gatewaySN);
        }];
    }
    else {
        

//        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"LightOnGif" ofType:@"gif"];
//        [iconView setGIFFile:filePath];
//        
//        [iconView setAnimationDuration:0.5];
//        [iconView setAnimationRepeatCount:1];
//        [iconView startAnimating];
        
        [[NetAPIClient sharedClient] setPowerOn:self.device successCallback:^{

             NSLog(@"lightOpen: %@ gatewayId:%@ success",self.device.serialNumber,self.device.gatewaySN);
            
            [self stopAnimating];
            
        }failureCallback:^{
            
            [self stopAnimating];
            
            [self showCtrlFailedHint];
            
            NSLog(@"lightOpen: %@ gatewayId:%@ failed",self.device.serialNumber,self.device.gatewaySN);
        }];
    }
}




- (void)onClick
{
    if (self.device.state.online) {
        if ([self.device.type isEqualToString:SH_DEVICE_LEVELLIGHT]) {//调光性灯光
            
            NSString *nibName = [Util nibNameWithClass:[DimmerlightView class]];
            DimmerlightView *ctrlView = [[DimmerlightView alloc] initWithNibName:nibName bundle:nil];
     
            deviceController = ctrlView;
            [self showDeviceControlView:ctrlView.view];
         
            [ctrlView setDevice:_device];
            
        }
        else {
            
            [self switchPower];
        }
    }
    
}




- (void)deviceCtrlBgdViewWillDismiss
{
    deviceController = nil;
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
        [iconView stopAnimating];
//        [iconView setImage:[UIImage imageNamed:@"LightOffline"]];
        [self setOfflineIcon];
    }
    else if (self.device.state.powerOn) {
 
 
        [iconView stopAnimating];
        
//        [iconView setImage:[UIImage imageNamed:@"LightOn"]];
        [self setPowerOnIcon];
        
    }
    else {
        [iconView stopAnimating];
//        [iconView setImage:[UIImage imageNamed:@"LightOff"]];
        
        [self setPowerOffIcon];
    }
}

- (void)setOfflineIcon
{
    if (self.styleDirPath && self.styleIcons) {

        NSString *filePath = [self.styleDirPath stringByAppendingPathComponent:[self.styleIcons objectForKey:@"offline"]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            UIImage *img = [UIImage imageWithContentsOfFile:filePath];
            
            [iconView setImage:img];
        }
        else {
            [iconView setImage:[UIImage imageNamed:@"LightOffline"]];
        }
    }
    else {
        [iconView setImage:[UIImage imageNamed:@"LightOffline"]];
    }
}


- (void)setPowerOnIcon
{
    if (self.styleDirPath && self.styleIcons) {
        
        NSString *filePath = [self.styleDirPath stringByAppendingPathComponent:[self.styleIcons objectForKey:@"powerOn"]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            UIImage *img = [UIImage imageWithContentsOfFile:filePath];
            
            [iconView setImage:img];
        }
        else {
            [iconView setImage:[UIImage imageNamed:@"LightOn"]];
        }
    }
    else {
        [iconView setImage:[UIImage imageNamed:@"LightOn"]];
    }
}

- (void)setPowerOffIcon
{
    if (self.styleDirPath && self.styleIcons) {
        
        NSString *filePath = [self.styleDirPath stringByAppendingPathComponent:[self.styleIcons objectForKey:@"powerOff"]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            UIImage *img = [UIImage imageWithContentsOfFile:filePath];
            
            [iconView setImage:img];
        }
        else {
            [iconView setImage:[UIImage imageNamed:@"LightOff"]];
        }
    }
    else {
        [iconView setImage:[UIImage imageNamed:@"LightOff"]];
    }
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
