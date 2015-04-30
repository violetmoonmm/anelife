//
//  BoxView.h
//  eLife
//
//  Created by mac on 14-7-22.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BoxViewDelegate <NSObject>

- (void)boxViewPlayVideo:(NSString *)cameraId;


@end


@interface BoxView : UIView <UITableViewDataSource,UITableViewDelegate>
{
    UIImageView *_arrowView;
    UITableView *_tableView;
}

@property (nonatomic,strong) NSArray *devices;

@property (nonatomic,assign) id<BoxViewDelegate> delegate;

@property (nonatomic,strong) UIView *headerView;

- (void)pointToRect:(CGRect)rect;


@end
