//
//  BasicEnergyCell.m
//  eLife
//
//  Created by mac on 14-9-9.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "BasicEnergyCell.h"
#import "PublicDefine.h"
#import "NetAPIClient.h"
#import "NotificationDefine.h"
#import "BasicStateCell.h"

#define MarginX 2//x轴左右边缘
#define MarginY 2//y轴上下边缘

#define PollInterval 30 //轮询间隔

#define TAG_PAGE 100

#define PollIntervalMax 120

#define CELL_HEIGHT 30

@interface EnergyCellView : BasicCell
{
    UILabel *valueLbl;
    UILabel *devNumLbl;
    
    NSTimer *timer;
}



@end


@implementation EnergyCellView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        UIImageView *bgdView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))];
        bgdView.image = [UIImage imageNamed:@"PageFlipOrange"];
        [self addSubview:bgdView];
        
        
        NSInteger nameH = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 72 : 100);
        NSInteger valueH = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 30 : 40);
        NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 6 : 12);
        NSInteger devNumH = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 22 : 30);
        NSInteger originY = (CGRectGetHeight(frame) - nameH - devNumH - spacingY)/2;
        NSInteger valueY = originY+(nameH - valueH)/2;
        
        NSInteger spacingX = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 14 : 20);
        
        
        UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, originY, 22, nameH)];
        nameLbl.textColor = [UIColor whiteColor];
        nameLbl.numberOfLines = 0;
        nameLbl.font = [UIFont systemFontOfSize:CELL_TEXT_FONT];
        nameLbl.text = @"即时能耗";
        nameLbl.backgroundColor = [UIColor clearColor];
        [bgdView addSubview:nameLbl];
        
        NSInteger valueX = CGRectGetMaxX(nameLbl.frame) + spacingX;
        valueLbl = [[UILabel alloc] initWithFrame:CGRectMake(valueX, valueY, 100, valueH)];
        valueLbl.text = @"--";
        valueLbl.textColor = [UIColor whiteColor];
        valueLbl.backgroundColor = [UIColor clearColor];
        valueLbl.font = [UIFont systemFontOfSize:CELL_TEXT_FONT_BIG];
        [bgdView addSubview:valueLbl];
        
        
        devNumLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(nameLbl.frame), CGRectGetMaxY(nameLbl.frame)+spacingY, 140, devNumH)];
        devNumLbl.text =  @"能耗电器数量 : --";
        devNumLbl.textColor = [UIColor whiteColor];
        devNumLbl.backgroundColor = [UIColor clearColor];
        devNumLbl.font = [UIFont systemFontOfSize:CELL_TEXT_FONT];
        [bgdView addSubview:devNumLbl];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSHTerminationNtf:) name:SHTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRemoveGatewayNtf:) name:DelGatewayNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEditGatewayNtf:) name:EditGatewayNotication object:nil];
        
        
    }
    return self;
}



- (void)dealloc
{
    
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    

    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

    [super setDevice:device];

    [self performSelector:@selector(pollMeter) withObject:nil afterDelay:1.0];
}



- (void)setDevNum:(int)devNum
{
    devNumLbl.text = [NSString stringWithFormat:@"能耗电器数量: %d",devNum];
}







//定时查
- (void)pollMeter
{
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    
    if (_device) {
        timer = [NSTimer scheduledTimerWithTimeInterval:PollInterval target:self selector:@selector(readAmmeter) userInfo:nil repeats:YES];
        [timer fire];
    }

}

- (void)readAmmeter
{
    
    [[NetAPIClient sharedClient] readAmmeterMeter:_device successCallback:^(NSDictionary *dataDic){
        
        NSDictionary *currentEnergys = [dataDic objectForKey:@"InstantPower"];
        
        NSString *actviePower = [currentEnergys objectForKey:@"ActivePower"];
        NSString *ap = [NSString stringWithFormat:@"%.2f",[actviePower floatValue]/10];
        
        valueLbl.text = [ap stringByAppendingString:@"瓦"];//当前能耗值（/10 瓦）
        
    }failureCallback:NULL];
}





@end




@implementation BasicEnergyCell
{
    NSMutableArray *itemArray;
    
    UIView *containerView;
    
    NSInteger selIndx;
    
    EnergyCellView *energyView;
    BasicStateCell *stateView;
}




- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        containerView = [[UIView alloc] initWithFrame:CGRectMake(MarginX, MarginY, CGRectGetWidth(frame) - MarginX*2, CGRectGetHeight(frame) - MarginY*2)];
        containerView.backgroundColor = [UIColor colorWithRed:56/255. green:191/255. blue:182/255. alpha:1];
        [self addSubview:containerView];
        
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipPage:)];
        [containerView addGestureRecognizer:tap];

        itemArray = [NSMutableArray arrayWithCapacity:1];
        
        [self setupSubviews];
    }
    return self;
}


- (void)dealloc
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)setupSubviews
{
    energyView = [[EnergyCellView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds))];
//    item.deviceId = devId;
//    item.gatewayId = gatewayId;
    [containerView addSubview:energyView];
    [itemArray addObject:energyView];
    
   stateView = [[BasicStateCell alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds))];
//    stateView.backgroundColor = [UIColor grayColor];
    [containerView addSubview:stateView];
    [itemArray addObject:stateView];
    
    [self flipToPage:0 animated:NO];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


- (void)flipPage:(UITapGestureRecognizer *)gesRec
{


    if ([itemArray count] > 1) {
        NSInteger nextPage = selIndx+1;
        if (nextPage == [itemArray count]) {
            nextPage = 0;
        }
        
        [self flipToPage:nextPage animated:YES];
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



- (void)associateWithDevices:(NSArray *)ammeters
{
    
    [energyView associateWithDevices:ammeters];
    

    
}

- (void)setDisplayDevices:(NSArray *)devices
{
    [stateView setDisplayDevices:devices];
}



@end
