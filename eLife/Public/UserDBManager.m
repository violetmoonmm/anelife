//
//  UserDBManager.m
//  eLife
//
//  Created by mac on 14-7-25.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "UserDBManager.h"
#import "FMDatabase.h"

@implementation UserDBManager
{
    FMDatabase *_db;
}

+ (UserDBManager *)defaultManager
{
    static UserDBManager *manager = nil;
    static dispatch_once_t once;
    dispatch_once(&once,^{
        manager = [[UserDBManager alloc] init];
        
    });
    
    return manager;
}

- (id)init
{
    if (self = [super init]) {
        
    }
    
    return self;
}

- (BOOL)open
{
    NSString *dbDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

    NSString *dbPath = [dbDir stringByAppendingPathComponent:@"user.db"];
    //创建数据库实例 db  这里说明下:如果路径中不存在"Database.db"的文件,sqlite会自动创建"Database.db"
    _db = [FMDatabase databaseWithPath:dbPath] ;
    
    return [_db open];
}

- (void)close
{
    [_db close];
}

- (void)createTables
{
    NSLog(@"user db createTables");
    
    //用户表
    NSString *const USER_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS user (vircode text primary key, username text,  password text, blockpswd bit,lockpswd text,blogin bit,disableAlarm bit, city text, isp text, alarmVideo integer); ";
    
    //上次登录用户表
    NSString *const LAST_USER_TABLE_CREATE_SQL = @" CREATE TABLE IF NOT EXISTS lastuser (id integer primary key autoincrement,  vircode text); ";
    
    if (![_db executeUpdate:USER_TABLE_CREATE_SQL]) {
        NSLog(@"user db can not create table");
    }
    if (![_db executeUpdate:LAST_USER_TABLE_CREATE_SQL]) {
        NSLog(@"user db can not create table");
    }
}

#pragma mark 用户

//更新上次登录用户
- (void)updateLastLoginUser:(User *)user
{
    BOOL b = [_db executeUpdate:@"DELETE FROM lastuser"];
    
    b =  [_db executeUpdate:@"INSERT INTO lastuser (vircode) VALUES (?)",user.virtualCode];
}

//查询上次登录用户虚号
- (NSString *)queryLastLoginUser
{
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM lastuser"];
 
    if ([rs next]) {
        return [rs stringForColumn:@"vircode"];
    }
    
    return nil;
}

//根据用户虚号查询用户信息
- (User *)queryUserInfo:(NSString *)virCode
{
    FMResultSet *rs = [_db executeQuery:@"SELECT * FROM user WHERE vircode = ?",virCode];
   
    if ([rs next]) {
         User *user = [[User alloc] init];
        user.name = [rs stringForColumn:@"username"];
        user.password = [rs stringForColumn:@"password"];
        user.virtualCode = [rs stringForColumn:@"vircode"];
        user.enableLockPswd = [rs boolForColumn:@"blockpswd"];
        user.lockPswd = [rs stringForColumn:@"lockpswd"];
        user.haveLogin = [rs boolForColumn:@"blogin"];
        user.disableAlarm = [rs boolForColumn:@"disableAlarm"];
        user.city = [rs stringForColumn:@"city"];
        user.ISP = [rs stringForColumn:@"isp"];
        user.alarmVideo = [rs intForColumn:@"alarmVideo"];
        
        return user;
    }
    
    return nil;
}

//更新用户信息
- (void)updateUser:(User *)user
{
    
   [_db executeUpdate:@"INSERT OR REPLACE INTO user (username, password,vircode,blockpswd,lockpswd,blogin,disableAlarm,city,isp,alarmVideo) VALUES (?,?,?,?,?,?,?,?,?,?)",user.name,user.password,user.virtualCode,[NSNumber numberWithBool:user.enableLockPswd],user.lockPswd,[NSNumber numberWithBool:user.haveLogin],[NSNumber numberWithBool:user.disableAlarm],user.city,user.ISP,[NSNumber numberWithInt:user.alarmVideo] ];
}



@end
