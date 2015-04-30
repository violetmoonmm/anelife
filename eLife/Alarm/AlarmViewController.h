//
//  AlarmViewController.h
//  eLife
//
//  Created by 陈杰 on 14/11/22.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol AlarmViewControllerDelegate <NSObject>

- (void)cancelAlarm;

@end

@interface AlarmViewController : UIViewController


@property (nonatomic,strong) NSMutableArray *alarmRecords;
@property (nonatomic,assign) id<AlarmViewControllerDelegate> delegate;

@end
