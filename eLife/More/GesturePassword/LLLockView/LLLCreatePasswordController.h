//
//  LLLCreatePasswordController.h
//  eLife
//
//  Created by 陈杰 on 15/1/21.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

// 进入此界面时的不同目的
typedef enum {

    LLLockViewTypeCreate, // 创建手势密码
    LLLockViewTypeModify // 修改

}CreatePasswordType;

@interface LLLCreatePasswordController : UIViewController

@property (nonatomic,assign) CreatePasswordType viewType;

@end
