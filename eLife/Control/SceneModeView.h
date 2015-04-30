//
//  SceneModeView.h
//  eLife
//
//  Created by 陈杰 on 14/11/26.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>


@class SceneModeView;

@protocol SceneModeViewDelegate <NSObject>

@optional

- (void)sceneModeView:(SceneModeView *)sceneModeView didSelectAtIndex:(NSInteger)index;

@required

- (NSString *)sceneModeView:(SceneModeView *)sceneModeView titleAtIndex:(NSInteger)index;

- (UIImage *)sceneModeView:(SceneModeView *)sceneModeView normalImageAtIndex:(NSInteger)index;

- (UIImage *)sceneModeView:(SceneModeView *)sceneModeView selectedImageAtIndex:(NSInteger)index;

- (NSInteger)numberOfItemsInSceneModeView:(SceneModeView *)sceneModeView;

@end

@interface SceneModeView : UIView


@property (nonatomic,assign) NSInteger selectedIndex;

@property (nonatomic,assign) id<SceneModeViewDelegate> delegate;

@property (nonatomic,assign) NSInteger numOfPerRow;

//@property (nonatomic,readonly) NSInteger height;

- (void)reloadData;

@end
