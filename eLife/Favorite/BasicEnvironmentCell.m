//
//  BasicEnvironmentCell.m
//  eLife
//
//  Created by 陈杰 on 15/4/27.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "BasicEnvironmentCell.h"
#import "NetAPIClient.h"
#import "NotificationDefine.h"

#define PollIntervalMax 120

#define MarginX 2//x轴左右边缘
#define MarginY 2//y轴上下边缘

@interface BasicEnvironmentCell ()
{
    NSTimer *timer;

    UILabel *tempLbl;
    UILabel *humidityLbl;

    UILabel *airQualityLbl;
}

@end

@implementation BasicEnvironmentCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        
        [self setBackgroundColor:[UIColor clearColor]];


        //背景
        UIImage *orgImage = [UIImage imageNamed:@"SDeviceCtrlBgd"];
        UIImage *stImage = [orgImage resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
        UIImageView *bgdView = [[UIImageView alloc] initWithImage:stImage];
        bgdView.frame = CGRectMake(MarginX, MarginY, CGRectGetWidth(frame) - MarginX*2, CGRectGetHeight(frame) - MarginY*2);
        bgdView.userInteractionEnabled = YES;
        [self addSubview:bgdView];

        
    
        CGFloat tempH = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 20 :26;
        CGFloat humidityH = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 18 :20;
        CGFloat airH = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 18 :20;
        
                CGFloat tempFont = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 16 :20;
                CGFloat humidityFont = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 12 :15;
                CGFloat airQualityFont = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 12 :15;
        
        CGFloat spacingY = (CGRectGetHeight(bgdView.bounds) - tempH - humidityH - airH)/4;
        
        //温度
        tempLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, spacingY, CGRectGetWidth(frame), tempH)];
        tempLbl.text = @"--";
        tempLbl.textColor = [UIColor colorWithRed:82/255. green:157/255. blue:31/255. alpha:1];
        tempLbl.textAlignment = NSTextAlignmentCenter;
        tempLbl.font = [UIFont systemFontOfSize:tempFont];
        tempLbl.backgroundColor = [UIColor clearColor];
        [bgdView addSubview:tempLbl];
        
        //湿度
        humidityLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(tempLbl.frame)+spacingY, CGRectGetWidth(frame), humidityH)];
        humidityLbl.text = @"湿度: --";
        humidityLbl.textColor = [UIColor colorWithRed:82/255. green:157/255. blue:31/255. alpha:1];
        humidityLbl.textAlignment = NSTextAlignmentLeft;
        humidityLbl.font = [UIFont systemFontOfSize:humidityFont];
        humidityLbl.backgroundColor = [UIColor clearColor];
        [bgdView addSubview:humidityLbl];
        
        
        
        //空气质量
        airQualityLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(humidityLbl.frame), CGRectGetMaxY(humidityLbl.frame)+spacingY, CGRectGetWidth(frame), airH)];
        airQualityLbl.text = @"空气: --";
        airQualityLbl.textColor = [UIColor colorWithRed:82/255. green:157/255. blue:31/255. alpha:1];
        airQualityLbl.textAlignment = NSTextAlignmentLeft;
        airQualityLbl.font = [UIFont systemFontOfSize:airQualityFont];
        airQualityLbl.backgroundColor = [UIColor clearColor];
        [bgdView addSubview:airQualityLbl];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSHTerminationNtf:) name:SHTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRemoveGatewayNtf:) name:DelGatewayNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEditGatewayNtf:) name:EditGatewayNotication object:nil];
        
    }
    return self;
}



- (void)dealloc
{
    
    [timer invalidate];
    timer = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //    [self removeObserveDevice:_device];
    
    
}

- (void)handleSHTerminationNtf:(NSNotification *)ntf
{
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
}

- (void)handleRemoveGatewayNtf:(NSNotification *)ntf
{
    NSDictionary *userInfo = [ntf userInfo];
    
    SHGateway *gateway = [userInfo objectForKey:DelGatewayNotificationKey];
    
    if ([gateway.serialNumber isEqualToString:self.gatewayId]) {
        if (timer) {
            [timer invalidate];
            timer = nil;
        }
    }
}

- (void)handleEditGatewayNtf:(NSNotification *)ntf
{
    BOOL needRefresh = [[[ntf userInfo] objectForKey:NeedRefreshGatewayKey] boolValue];
    
    if (needRefresh) {
        SHGateway *gateway = [ntf object];
        
        if ([gateway.serialNumber isEqualToString:self.gatewayId]) {
            [timer invalidate];
            timer = nil;
        }
    }
}

- (void)setDevice:(SHDevice *)device
{
    //    [self removeObserveDevice:_device];
    
    _device = device;
    
    //    [self observeDevice:device];

    
    [self performSelector:@selector(pollMeter) withObject:nil afterDelay:1.0];
}


//定时查
- (void)pollMeter
{
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    
    if (_device) {
        timer = [NSTimer scheduledTimerWithTimeInterval:PollIntervalMax target:self selector:@selector(readAmmeter) userInfo:nil repeats:YES];
        [timer fire];
    }
    
}

- (void)readAmmeter
{
    
    [[NetAPIClient sharedClient] readEnvironmentMonitor:self.device successCallback:^(NSDictionary *dataDic){
        
        NSDictionary *dataSource = [dataDic objectForKey:@"EnvironmentQuality"];
        
        [self displayEnvironmentData:dataSource];
        
    }failureCallback:^{
        
    }];
}

- (void)displayEnvironmentData:(NSDictionary *)data
{
    NSString *temp = [data objectForKey:@"Temperature"];
    if (temp) {
        NSInteger vl = [temp integerValue];
        temp = [NSString stringWithFormat:@"%d℃",vl];
    }
    else {
        temp = @"--";
    }
    
    tempLbl.text = temp;
    
    NSString *humidity = [data objectForKey:@"Humidity"];
    if (humidity) {
        NSInteger vl = [humidity integerValue];
        humidity = [NSString stringWithFormat:@"湿度: %d%%",vl];
    }
    else {
        humidity = @"湿度--";
    }
    
    humidityLbl.text = humidity;
    
    NSString *itemValue = nil;
    CGFloat fValue = 0;
    
    //空气质量评测 0：正常 1：很好 2：超标/差
    NSInteger PM25Normal = 0;
    NSInteger HCHONormal = 0;
    NSInteger VOCNormal = 0;
    NSInteger C02Normal = 0;
    
    itemValue = [data objectForKey:@"PM25"];
    fValue = [itemValue floatValue];
    if (fValue < 35) {
        PM25Normal = 1;
    }
    else if (fValue > 75) {
        PM25Normal = 2;
    }
    
    itemValue = [data objectForKey:@"HCHO"];
    fValue = [itemValue floatValue];
    if (fValue < 100) {
        HCHONormal = 1;
    }
    else if (fValue > 300) {
        HCHONormal = 2;
    }
    
    itemValue = [data objectForKey:@"VOC"];
    fValue = [itemValue floatValue];
    if (fValue < 300) {
        VOCNormal = 1;
    }
    else if (fValue > 300) {
        VOCNormal = 2;
    }
    
    itemValue = [data objectForKey:@"CO2"];
    fValue = [itemValue floatValue];
    if (fValue < 1000) {
        C02Normal = 1;
    }
    else if (fValue > 2000) {
        C02Normal = 2;
    }
    
    
    if (PM25Normal == 1 && HCHONormal == 1 && VOCNormal == 1 && C02Normal == 1) {
        airQualityLbl.text = [NSString stringWithFormat:@"空气: %@",@"很好"];
    }
    else if (PM25Normal == 2 ||  HCHONormal == 2 || VOCNormal == 2 || C02Normal == 2) {
        airQualityLbl.text = [NSString stringWithFormat:@"空气: %@",@"差"];
    }
    else {
        airQualityLbl.text = [NSString stringWithFormat:@"空气: %@",@"正常"];
    }
}

@end
