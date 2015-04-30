//
//  LLLCheckPasswordController.h
//  eLife
//
//  Created by 陈杰 on 15/1/21.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>


@class LLLCheckPasswordController;

@protocol CheckPasswordDelegate <NSObject>

- (void)checkPasswordSuccessfully;

@end

@interface LLLCheckPasswordController : UIViewController

@property (nonatomic,assign) id<CheckPasswordDelegate> delegate;

@end
