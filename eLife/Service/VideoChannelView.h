//
//  VideoChannelView.h
//  eLife
//
//  Created by 陈杰 on 14/11/27.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VideoChannelViewDelegate ;


@interface VideoChannelView : UIView

@property (nonatomic,assign) id<VideoChannelViewDelegate> delegate;
@property (nonatomic,assign) NSInteger selectedIndex;


- (void)reloadData;
- (void)reloadItemAtIndex:(NSInteger)index;

@end

@protocol VideoChannelViewDelegate <NSObject>


@optional

- (void)channelView:(VideoChannelView *)channelView didSelectAtIndex:(NSInteger)index;

@required

- (NSString *)channelView:(VideoChannelView *)channelView titleAtIndex:(NSInteger)index;

//- (UIImage *)channelView:(VideoChannelView *)channelView imageAtIndex:(NSInteger)index;

- (UIView *)channelView:(VideoChannelView *)channelView contentViewAtIndex:(NSInteger)index;

- (NSInteger)numberOfItemsInVideoChannelView:(VideoChannelView *)channelView;

@end