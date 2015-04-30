//
//  AirconditionModeView.h
//  eLife
//
//  Created by 陈杰 on 14/11/20.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ACModeViewDelegate ;


@interface ACModeView : UIView

@property (nonatomic,assign) id<ACModeViewDelegate> delegate;
@property (nonatomic,assign) NSInteger selectedIndex;

- (void)buildWithTitles:(NSArray *)titles normalImages:(NSArray *)images selectedImages:(NSArray *)selectedImages;

@end

@protocol ACModeViewDelegate <NSObject>

- (void)ACModeView:(ACModeView *)modeView didSelectItemAtIndex:(NSInteger)index;;

@end
