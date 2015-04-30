//
//  LLLockPassword.m
//  LockSample
//
//  Created by Lugede on 14/11/12.
//  Copyright (c) 2014年 lugede.cn. All rights reserved.
//

#import "LLLockPassword.h"

#import "User.h"
#import "UserDBManager.h"

@implementation LLLockPassword

#pragma mark - 锁屏密码读写
+ (NSString*)loadLockPassword
{
    return [User currentUser].lockPswd;
}

+ (void)saveLockPassword:(NSString*)pswd
{
    [User currentUser].enableLockPswd = YES;
    
    [User currentUser].lockPswd = pswd;
    
    [[UserDBManager defaultManager] updateUser:[User currentUser]];
}


+ (BOOL)isEnableLockPassword
{
  
    return [User currentUser].enableLockPswd;
}


+ (void)setEnableLockPassword:(BOOL)yesOrNo
{

    [User currentUser].enableLockPswd = yesOrNo;
    
    [[UserDBManager defaultManager] updateUser:[User currentUser]];
}


@end
