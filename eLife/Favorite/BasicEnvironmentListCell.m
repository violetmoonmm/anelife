//
//  BasicEnvironmentListCell.m
//  eLife
//
//  Created by 陈杰 on 15/4/11.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "BasicEnvironmentListCell.h"
#import "BasicStateCell.h"
#import "NetAPIClient.h"
#import "NotificationDefine.h"

#import "Util.h"

#define MarginX 2//x轴左右边缘
#define MarginY 2//y轴上下边缘

#define PollInterval 30 //轮询间隔

#define TAG_PAGE 100

#define PollIntervalMax 120

#define CELL_HEIGHT 30


@interface EnvQualityCellView : BasicCell
{
    
    NSTimer *timer;

    
    UILabel *nameLbl;
    UILabel *roomLbl;
    UILabel *tempLbl;
    UILabel *humidityLbl;
    UILabel *airValueLbl;
    UILabel *airQualityLbl;
}


@end


@implementation EnvQualityCellView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        

        [self setBackgroundColor:[UIColor clearColor]];
        
        //环境监测
        CGFloat nameFont = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 15 :18;
        nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 6, CGRectGetWidth(frame), 20)];
        nameLbl.text = @"环境监测";
        nameLbl.textColor = [UIColor whiteColor];
        nameLbl.textAlignment = NSTextAlignmentCenter;
        nameLbl.font = [UIFont systemFontOfSize:nameFont];
        nameLbl.backgroundColor = [UIColor clearColor];
        [self addSubview:nameLbl];
        
        //房间
        CGFloat roomFont = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 15 :18;
        roomLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(nameLbl.frame)+4, CGRectGetWidth(frame), 20)];
        roomLbl.text = @"---未知---";
        roomLbl.textColor = [UIColor whiteColor];
        roomLbl.textAlignment = NSTextAlignmentCenter;
        roomLbl.font = [UIFont systemFontOfSize:roomFont];
        roomLbl.backgroundColor = [UIColor clearColor];
        [self addSubview:roomLbl];

        //温度
        CGFloat tempFont = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 15 :18;
        tempLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(roomLbl.frame)+4, CGRectGetWidth(frame)/2, 20)];
        tempLbl.text = @"温度:--";
        tempLbl.textColor = [UIColor whiteColor];
        tempLbl.textAlignment = NSTextAlignmentCenter;
        tempLbl.font = [UIFont systemFontOfSize:tempFont];
        tempLbl.backgroundColor = [UIColor clearColor];
        [self addSubview:tempLbl];
        
        //湿度
        CGFloat humidityFont = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 15 :18;
        humidityLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(tempLbl.frame)+4, CGRectGetWidth(frame)/2, 20)];
        humidityLbl.text = @"湿度:--";
        humidityLbl.textColor = [UIColor whiteColor];
        humidityLbl.textAlignment = NSTextAlignmentCenter;
        humidityLbl.font = [UIFont systemFontOfSize:humidityFont];
        humidityLbl.backgroundColor = [UIColor clearColor];
        [self addSubview:humidityLbl];
        

        //空气质量值
        CGFloat airValueFont = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 15 :18;
        airValueLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(tempLbl.frame)+4, CGRectGetMinY(tempLbl.frame), CGRectGetWidth(frame)/2-4, 20)];
        airValueLbl.text = @"正常";
        airValueLbl.textColor = [UIColor whiteColor];
        airValueLbl.textAlignment = NSTextAlignmentCenter;
        airValueLbl.font = [UIFont systemFontOfSize:airValueFont];
        airValueLbl.backgroundColor = [UIColor clearColor];
        [self addSubview:airValueLbl];
       
        //空气质量
        CGFloat airQualityFont = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 15 :18;
        airQualityLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(airValueLbl.frame), CGRectGetMaxY(airValueLbl.frame)+4, CGRectGetWidth(frame)/2-4, 20)];
        airQualityLbl.text = @"空气质量";
        airQualityLbl.textColor = [UIColor whiteColor];
        airQualityLbl.textAlignment = NSTextAlignmentCenter;
        airQualityLbl.font = [UIFont systemFontOfSize:airQualityFont];
        airQualityLbl.backgroundColor = [UIColor clearColor];
        [self addSubview:airQualityLbl];
        
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
 
    _device = device;

    
    SHGateway *gateway = [[NetAPIClient sharedClient] lookupGatewayById:device.gatewaySN];
    
    roomLbl.text = [gateway roomNameForDevice:device];
    
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
        temp = [NSString stringWithFormat:@"温度: %d℃",vl];
    }
    else {
        temp = @"温度--";
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
        airValueLbl.text = @"很好";
    }
    else if (PM25Normal == 2 ||  HCHONormal == 2 || VOCNormal == 2 || C02Normal == 2) {
         airValueLbl.text = @"差";
    }
    else {
        airValueLbl.text = @"正常";
    }
}

@end




@implementation BasicEnvironmentListCell
{
    NSMutableArray *itemArray;
    
    UIScrollView *containerView;
    
    NSInteger selIndx;
    
    
}




- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        
        containerView = [[UIScrollView alloc] initWithFrame:CGRectMake(MarginX, MarginY, CGRectGetWidth(frame) - MarginX*2, CGRectGetHeight(frame) - MarginY*2)];
        containerView.backgroundColor = [UIColor colorWithRed:56/255. green:191/255. blue:182/255. alpha:1];
        containerView.pagingEnabled = YES;
        containerView.showsHorizontalScrollIndicator = NO;
        containerView.showsVerticalScrollIndicator = NO;
        [self addSubview:containerView];
        
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGest:)];
        [containerView addGestureRecognizer:tap];
        
        itemArray = [NSMutableArray arrayWithCapacity:1];
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



- (void)tapGest:(UITapGestureRecognizer *)gesRec
{
    if ([self.delegate respondsToSelector:@selector(entryEnvironmentService)]) {
        [self.delegate entryEnvironmentService];
    }
}


- (void)flipToPage:(NSInteger)page animated:(BOOL)animated
{
    
    UIView *fromView = nil;
    UIView *toView = nil;
    
    if (selIndx < [itemArray count]) {
        fromView = [itemArray objectAtIndex:selIndx];
    }
    
    if (page < [itemArray count]) {
        toView = [itemArray objectAtIndex:page];
    }
    
    if (toView) {
        if (!animated) {
            CGRect frame = fromView.frame;
            frame.origin.y = -CGRectGetHeight(frame);
            fromView.frame = frame;
            fromView.hidden = YES;
            
            CGRect toFrame = toView.frame;
            toFrame.origin.y = 0;
            toView.frame = toFrame;
            toView.hidden = NO;
            [containerView bringSubviewToFront:toView];
        }
        else {
            toView.hidden = NO;
            fromView.hidden = NO;
            
            CGRect toFrame = toView.frame;
            toFrame.origin.y = -CGRectGetHeight(toFrame);
            toView.frame = toFrame;
            
            [UIView animateWithDuration:0.2 animations:^{
                
                CGRect frame = fromView.frame;
                frame.origin.y = CGRectGetHeight(containerView.bounds)+MarginY;
                fromView.frame = frame;
                
                CGRect toFrame = toView.frame;
                toFrame.origin.y = 0;
                toView.frame = toFrame;
                
            }completion:^(BOOL f){
                if (f) {
                    fromView.hidden = YES;
                }
            }];
        }
    }
    
    selIndx = page;
}


- (void)setElements:(NSArray *)elements
{
    if ([itemArray count]) {
        for (UIView *v in itemArray)
        {
            [v removeFromSuperview];
        }
    }
    
    
    for (int i = 0; i<[elements count]; i++) {
        NSDictionary *dic = [elements objectAtIndex:i];
        
        NSString *devId = [dic objectForKey:@"dev_id"];
        NSString *gatewayId = [dic objectForKey:@"gateway_sn"];
       
        
        CGRect frame = CGRectMake(0, i*CGRectGetHeight(containerView.frame), CGRectGetWidth(containerView.frame), CGRectGetHeight(containerView.frame));
        EnvQualityCellView *item = [[EnvQualityCellView alloc] initWithFrame:frame];
        item.deviceId = devId;
        item.gatewayId = gatewayId;
        
        [itemArray addObject:item];
        [containerView addSubview:item];
        
    }
    
    containerView.contentSize = CGSizeMake(CGRectGetWidth(containerView.frame), [elements count]*CGRectGetHeight(containerView.frame));
}

- (void)associateWithDevices:(NSArray *)devices
{
    
    for (EnvQualityCellView *item in itemArray)
    {
        [item associateWithDevices:devices];
        
    }
    
}




@end
