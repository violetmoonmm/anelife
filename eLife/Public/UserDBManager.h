//
//  UserDBManager.h
//  eLife
//
//  Created by mac on 14-7-25.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@interface UserDBManager : NSObject

+ (UserDBManager *)defaultManager;

- (BOOL)open;

- (void)close;

- (void)createTables;

#pragma mark 用户

//更新上次登录用户
- (void)updateLastLoginUser:(User *)user;

//查询上次登录用户虚号
- (NSString *)queryLastLoginUser;

//根据用户虚号查询用户信息
- (User *)queryUserInfo:(NSString *)virCode;

//更新用户信息
- (void)updateUser:(User *)user;

@end
