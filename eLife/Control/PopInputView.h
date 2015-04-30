//
//  PopInputView.h
//  eLife
//
//  Created by 陈杰 on 14/12/18.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PopInputView;

@protocol PopInputViewDelegate <NSObject>

- (void)popInputView:(PopInputView *)popInputView clickOkButtonWithText:(NSString *)inputText;

- (void)popInputView:(PopInputView *)popInputView clickCancelButtonWithText:(NSString *)inputText;

@end

@interface PopInputView : UIView


- (id)initWithTitle:(NSString *)title placeholder:(NSString *)placeholder delegate:(id<PopInputViewDelegate>)delegate;

- (void)show;


@end
