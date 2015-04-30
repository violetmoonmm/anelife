//
//  HeaderView.h
//  eLife
//
//  Created by mac on 14-3-31.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HeaderView;

@protocol HeaderViewDelegate <NSObject>

- (void)tapHeaderView:(HeaderView *)headerView;

@end

@interface HeaderView : UIView

@property (nonatomic) BOOL open;
@property (nonatomic,assign) id<HeaderViewDelegate> delegate;

- (void)setIcon:(UIImage *)icon title:(NSString *)title status:(NSString *)status indicator:(UIImage *)indicator;

@end
