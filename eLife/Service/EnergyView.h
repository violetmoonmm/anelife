//
//  EnergyView.h
//  eLife
//
//  Created by mac on 14-7-30.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EnergyView : UIView

@property (nonatomic,strong) IBOutlet UILabel *curPower;//当前功耗
@property (nonatomic,strong) IBOutlet UILabel *curTotal;//本期用电量
@property (nonatomic,strong) IBOutlet UILabel *curDisplay;//当前总示度

@property (nonatomic,strong) IBOutlet UILabel *curPeriodPeak;//本期用电峰
@property (nonatomic,strong) IBOutlet UILabel *curPeriodTroughs;//本期用电谷
@property (nonatomic,strong) IBOutlet UILabel *curPeriodShoulder;//本期用电平
@property (nonatomic,strong) IBOutlet UILabel *curPeriodSharp;//本期用电尖

@property (nonatomic,strong) IBOutlet UILabel *displayPeak;//当前总示度峰
@property (nonatomic,strong) IBOutlet UILabel *displayTroughs;//总示度谷
@property (nonatomic,strong) IBOutlet UILabel *displayShoulder;//总示度平
@property (nonatomic,strong) IBOutlet UILabel *displaySharp;//总示度尖

@property (nonatomic,strong) IBOutlet UILabel *lastDisplay;//上期总示度
@property (nonatomic,strong) IBOutlet UILabel *lastPeak;//上期总示度峰
@property (nonatomic,strong) IBOutlet UILabel *lastTroughs;//上期总示度谷
@property (nonatomic,strong) IBOutlet UILabel *lastShoulder;//上期总示度平
@property (nonatomic,strong) IBOutlet UILabel *lastSharp;//上期总示度尖

@property (nonatomic,strong) IBOutlet UILabel *lastTotal;//上期用电量

@property (nonatomic,strong) IBOutlet UILabel *curTime;
@property (nonatomic,strong) IBOutlet UILabel *lastTime;

@end
