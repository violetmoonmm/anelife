//
//  User.m
//  ihc
//
//  Created by mac on 13-5-18.
//  Copyright (c) 2013年 mac. All rights reserved.
//

#import "User.h"

@implementation User

+ (User *)currentUser
{
    static User *user = nil;
    static dispatch_once_t once;
    dispatch_once(&once,^{
        user = [[User alloc] init];
    });
    
    return user;
}

@end


@implementation VersionInfo


@end

@implementation GatewayUser


@end
