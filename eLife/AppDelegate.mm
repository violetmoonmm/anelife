//
//  AppDelegate.m
//  eLife
//
//  Created by mac on 14-3-14.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "AppDelegate.h"

#import "DeviceControlViewController.h"

#import "ServiceViewController.h"
#import "MoreViewController.h"
#import "LoginViewController.h"
#import "User.h"
#import "NetAPIClient.h"
#import "DBManager.h"
#import "AlarmViewController.h"
#import "MessageManager.h"
#import "IcrcHttpClientSdk.h"
#import "PublicDefine.h"
#import "NotificationDefine.h"
#import "Util.h"
#import "MBProgressHUD.h"
#import "UserDBManager.h"
#import "zw_dssdk.h"
#import "FavoriteViewController.h"
#import "CallForwardingViewController.h"
#import "LLLCheckPasswordController.h"

//#import "ISClient.h"
//#import "DvipClient.h"

// socket后台运行时间
#define KEEP_ALIVE_SECS 600

static void SoundFinished(SystemSoundID soundID,void* clientData){
    /*播放全部结束，因此释放所有资源 */
    AudioServicesDisposeSystemSoundID(soundID);

}

@interface AppDelegate () <UIAlertViewDelegate,CheckPasswordDelegate>
{
    
    UINavigationController *callNavController;
    
    UINavigationController *alarmNavController;
    
    SystemSoundID callSoundID;
    SystemSoundID alarmSoundID;
    
    BOOL locked;
}

- (NSComparisonResult)versionCompare:(NSString *)version anotherVersion:(NSString *)version1;

//- (void)showVersionForceUpdate;

@end

@implementation AppDelegate
@synthesize window;
@synthesize mainNavController,tabBarController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // 当真机连接Mac调试的时候把这些注释掉，否则log只会输入到文件中，而不能从xcode的监视器中看到。
    
    // 如果是真机就保存到Document目录下的drm.log文件中
    
    UIDevice *device = [UIDevice currentDevice];
    
    if (![[device model] isEqualToString:@"iPad Simulator"] || [[device model] isEqualToString:@"iPhone Simulator"]) {
        
        // 开始保存日志文件
        
        //[self redirectNSlogToDocumentFolder];
        
    }

#ifndef INVALID_VIDEO
    int res = [zw_dssdk dssdk_init];
#endif
    

    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    self.window.backgroundColor = [UIColor whiteColor];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    float sysVersion = [[UIDevice currentDevice]systemVersion].floatValue;
    if (sysVersion >= 8.0) {
        UIUserNotificationType type = UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
        UIUserNotificationSettings *setting = [UIUserNotificationSettings settingsForTypes:type categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:setting];
    }
    else {
    
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert];
    }

    
    //[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [self registerNotification];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    

    [self initTabBarController];
    
    UIViewController *firstViewController = nil;
    
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
  
    
    //user数据库
    if ([[UserDBManager defaultManager] open]) {
        [[UserDBManager defaultManager] createTables];
    }
    
    NSString *lastUserVirCode = [[UserDBManager defaultManager] queryLastLoginUser];
    User *lastUser = [[UserDBManager defaultManager] queryUserInfo:lastUserVirCode];
    
    if (lastUser) {
        [User currentUser].name = lastUser.name;
        [User currentUser].password = lastUser.password;
        [User currentUser].lockPswd = lastUser.lockPswd;
        [User currentUser].enableLockPswd = lastUser.enableLockPswd;
        [User currentUser].haveLogin = lastUser.haveLogin;
        [User currentUser].disableAlarm = lastUser.disableAlarm;
        [User currentUser].city = lastUser.city;
        [User currentUser].ISP = lastUser.ISP;
        [User currentUser].alarmVideo = lastUser.alarmVideo;
        
    }


    
 
    /*
     已经登录没有注销，直接到主界面
     */
    if ([User currentUser].haveLogin) {
        firstViewController = self.tabBarController;
        
        [[NetAPIClient sharedClient] queryGatewayListFromDB];//查询网关列表
        
    }
    else//显示登录界面
    {
        NSString *nibName = [Util nibNameWithClass:[LoginViewController class]];
        firstViewController = [[LoginViewController alloc] initWithNibName:nibName bundle:nil];
    }
    
    
    self.mainNavController = [[UINavigationController alloc] initWithRootViewController:firstViewController];
    [self.mainNavController setNavigationBarHidden:YES];
    
    
    self.window.rootViewController  = self.mainNavController;
    [self.window makeKeyAndVisible];
    


    if ([User currentUser].haveLogin)
    {
        if ([User currentUser].enableLockPswd) {//开启了手势密码
            NSString *nibName = [Util nibNameWithClass:[LLLCheckPasswordController class]];
            
            LLLCheckPasswordController *lockViewController = [[LLLCheckPasswordController alloc] initWithNibName:nibName bundle:nil];
            lockViewController.delegate = self;
            [self.window.rootViewController presentViewController:lockViewController animated:NO completion:NULL];

        }
        else {
            [self login];
        }
        
    }
 
    
    return YES;
}


//登录
- (void)login
{
    [[NetAPIClient sharedClient] loginWithUser:[User currentUser].name psd: [User currentUser].password successCallback:^{
        
        //登录成功向服务器注册推送服务
        [[NetAPIClient sharedClient] sendToken:[User currentUser].devToken];
        
        //检查版本
        [[NetAPIClient sharedClient] checkVersion:^(VersionInfo *version){
            if (version.versionName && ![version.versionName isEqualToString:CLIENT_VERSION]) {//当前版本不是最新版本
                if (NSOrderedDescending ==  [self versionCompare:version.supportVersion anotherVersion:CLIENT_VERSION]) {//强制更新
                    [self showVersionForceUpdate:version];
                    
                }
                else {//登录并提示可选更新
                    
                    [self showVersionUpdateInfo:version];
                    
                }
            }
        }failureCallback:^{
            NSLog(@"检查版本失败");
        }];
        
        //开启服务
        [[NetAPIClient sharedClient] beginTask];
        
        
    }failureCallback:^(int err){
        
        [self loginFailed:err];
        
        
        //密码错误转到登录界面
        if (err == ICRC_ERROR_PASSWORD_INCORRECT)
        {
            
            [User currentUser].haveLogin = NO;
            [[UserDBManager defaultManager] updateUser:[User currentUser]];
            
            
            NSString *nibName = [Util nibNameWithClass:[LoginViewController class]];
            LoginViewController *firstViewController = [[LoginViewController alloc] initWithNibName:nibName bundle:nil];
            
            [self initTabBarController];//重置tabBarController
            
            [self.mainNavController setViewControllers:[NSArray arrayWithObject:firstViewController] animated:YES];//转到登录视图
            
        }
        else {//其他原因，开始任务
            
            [[NetAPIClient sharedClient] beginTask];
            
            [NetAPIClient sharedClient].enableReconnect = YES;//开启后台重连
        }
        
        
    }];
}


- (void)checkPasswordSuccessfully
{

    [self login];
}


//检查锁屏设置
- (void)checkLockPswdSetting
{
    if ([User currentUser].enableLockPswd && [User currentUser].haveLogin && ![User currentUser].locked)
    {
        
        NSString *nibName = [Util nibNameWithClass:[LLLCheckPasswordController class]];
        
        LLLCheckPasswordController *lockViewController = [[LLLCheckPasswordController alloc] initWithNibName:nibName bundle:nil];
        
        [self.window.rootViewController presentViewController:lockViewController animated:NO completion:NULL];
      
    }
}


// 将NSlog打印信息保存到Document目录下的文件中

- (void)redirectNSlogToDocumentFolder
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [paths objectAtIndex:0];
    
    NSString *fileName = [NSString stringWithFormat:@"dr.log"];// 注意不是NSData!
    
    NSString *logFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
    
    // 先删除已经存在的文件
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    BOOL bDir;
    if ([defaultManager fileExistsAtPath:logFilePath isDirectory:&bDir]) {
         [defaultManager removeItemAtPath:logFilePath error:nil];
    }
   

    // 将log输入到文件
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
    
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
    
}

- (void)loginFailed:(int)error
{

    NSString *errorInfo = nil;
    switch (error) {
        case ICRC_ERROR_LOGIN_ABNORMAL:
            errorInfo = @"登录异常";
            [self showLoginFailedInfo:errorInfo];
            break;
        case ICRC_ERROR_USER_NOT_EXIST:
            errorInfo = @"用户名不存在";
            [self showLoginFailedInfo:errorInfo];
            break;
        case ICRC_ERROR_PASSWORD_INCORRECT:
            errorInfo = @"密码错误";
            [self showLoginFailedInfo:errorInfo];
            break;
        case ICRC_ERROR_ACCOUNT_NOACTIVE:
            errorInfo = @"账号未激活";
            [self showLoginFailedInfo:errorInfo];
            break;
        case ICRC_ERROR_SERVER_ABNORMAL:
            errorInfo = @"服务器异常";
            [self showLoginFailedInfo:errorInfo];
            break;
        case ICRC_ERROR_LOW_VERSION:
            errorInfo = @"版本过低";
            [self showLoginFailedInfo:errorInfo];
            break;
        case ICRC_ERROR_HTTP_NO_RESPONSE:
            
            errorInfo = @"服务器无响应";
            [self showLoginFailedInfo:errorInfo];
            
            break;
        case ICRC_ERROR_HTTP_PARAM_NOT_FOUND:
            
            errorInfo = @"服务器返回错误";
            [self showLoginFailedInfo:errorInfo];
            
            break;
            
        default:
            errorInfo = [NSString stringWithFormat:@"登录失败,错误码%d",error];
            [self showLoginFailedInfo:errorInfo];
            break;
    }
    
}



- (void)showLoginFailedInfo:(NSString *)errorInfo
{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"登录失败" message:errorInfo delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
}

- (NSComparisonResult)versionCompare:(NSString *)version anotherVersion:(NSString *)version1
{
    NSArray *components = [version componentsSeparatedByString:@"."];
    NSArray *components1 = [version1 componentsSeparatedByString:@"."];
    
    if ([components count] == 3 && [components1 count] == 3) {
        NSInteger header = [[components objectAtIndex:0] integerValue];
        NSInteger header1 = [[components1 objectAtIndex:0] integerValue];
        
        if (header > header1) {
            return NSOrderedDescending;
        }
        else if (header < header1) {
            return NSOrderedAscending;
        }
        else {
            NSInteger mid = [[components objectAtIndex:1] integerValue];
            NSInteger mid1 = [[components1 objectAtIndex:1] integerValue];
            
            if (mid > mid1) {
                return NSOrderedDescending;
            }
            else if (mid < mid1) {
                return NSOrderedAscending;
            }
            else {
                NSInteger tail = [[components objectAtIndex:2] integerValue];
                NSInteger tail1 = [[components1 objectAtIndex:2] integerValue];
                
                if (tail > tail1) {
                    return NSOrderedDescending;
                }
                else if (tail < tail1) {
                    return NSOrderedAscending;
                }
            }
        }
    }
    
    return NSOrderedSame;
}

- (void)showVersionForceUpdate:(VersionInfo *)versionInfo
{
    NSString *title = @"版本过低，请先升级再使用";
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY年MM月dd日"];
    NSString *strDate = [formatter stringFromDate:versionInfo.publishDate];
    
    NSString *msg = [NSString stringWithFormat:@"新版本:%@\n发布日期:%@",versionInfo.versionName,strDate];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"前往下载", nil];
    [alert show];
    
}

- (void)showVersionUpdateInfo:(VersionInfo *)versionInfo
{
    NSString *title = [NSString stringWithFormat:@"新版本%@",versionInfo.versionName];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY年MM月dd日"];
    NSString *strDate = [formatter stringFromDate:versionInfo.publishDate];
    
    NSString *msg = [NSString stringWithFormat:@"发布日期:%@",strDate];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"前往下载", nil];
    [alert show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"前往下载"]) {
        

        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:APP_URL]];
        
    }
    else {
 
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
    }
}

- (void)registerNotification
{

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAlarmNtf:)
                                                 name:OnAlarmNotification
                                               object:nil];
    
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCallRedirectNtf:) name:CallRedirectNotification object:nil];
}




- (void)playAlarmSound
{
    //    if (_plFinished) {
    //        _plFinished = NO;
    
    
    // 获取文件所在的路径
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Alarm" ofType:@"aif"];
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"call" ofType:@"mp3"];
    
    // 定义一个系统SystemSoundID的对象
//    SystemSoundID soundID;
    
    // 获取文件URL
    NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
    
    // 利用打开的文件创建一个soundID
    OSStatus st = AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &alarmSoundID);
    
    /*添加音频结束时的回调*/
    st = AudioServicesAddSystemSoundCompletion(alarmSoundID, NULL, NULL, SoundFinished,(__bridge void*)self);
    
    // 通过创建的音频文件ID打开对应的音频文件
    AudioServicesPlaySystemSound(alarmSoundID);
    //    }
    
    
}

- (void)playRingSound
{
    // 获取文件所在的路径
    NSString *path = [[NSBundle mainBundle] pathForResource:@"call" ofType:@"caf"];
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"call" ofType:@"mp3"];
    
//    // 定义一个系统SystemSoundID的对象
//    SystemSoundID soundID;
    
    // 获取文件URL
    NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
    
    // 利用打开的文件创建一个soundID
   OSStatus st = AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &callSoundID);
    
    /*添加音频结束时的回调*/
   st = AudioServicesAddSystemSoundCompletion(callSoundID, NULL, NULL, SoundFinished,(__bridge void*)self);
    
    // 通过创建的音频文件ID打开对应的音频文件
    AudioServicesPlaySystemSound(callSoundID);
}


- (void)stopPlayCallSound
{
    if (callSoundID > 0 ) {
        OSStatus st = AudioServicesDisposeSystemSoundID(callSoundID);
        callSoundID = 0;
    }

}

- (void)stopPlayAlarmSound
{
    if (alarmSoundID > 0) {
        OSStatus st = AudioServicesDisposeSystemSoundID(alarmSoundID);
        alarmSoundID = 0;
    }

}

- (NSString *)dateStringFrom:(int)time
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM-dd HH:mm"];
    NSString *str = nil;
    
    str = [formatter stringFromDate:date];
    
    return str;
}


- (void)handleCallRedirectNtf:(NSNotification *)ntf
{
    [self dismissCallView];//如果先前有present callview ，则dismiss
    
    [self playRingSound];//播放呼叫声音
    
    
    NSString *nibName = [Util nibNameWithClass:[CallForwardingViewController class]];
    
    CallForwardingViewController *callVC = [[CallForwardingViewController alloc] initWithNibName:nibName bundle:nil];
    
    id ipc = [[ntf userInfo] objectForKey:CallRedirectIPCKey];
    if (![ipc isEqual:[NSNull null]]) {
        callVC.video = ipc;
    }
   
    
    callNavController = [[UINavigationController alloc] initWithRootViewController:callVC];
//    callNavController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
     [[UIApplication sharedApplication].keyWindow addSubview:callNavController.view];
}

- (void)handleAlarmNtf:(NSNotification *)notification
{
    if (![User currentUser].disableAlarm) {
        AlarmRecord *alarmInfo = [[notification userInfo] objectForKey:OnAlarmNotificationKey];
        
        //发生
        if ([alarmInfo.alarmStatus isEqualToString:@"Start"])
        {
            [self playAlarmSound];//播放报警声音
            
            
            if (!alarmNavController)
            {
                UIViewController *viewController = self.mainNavController ;
                
                
                NSString *nibName = [Util nibNameWithClass:[AlarmViewController class]];
                AlarmViewController *alarmVC = [[AlarmViewController alloc] initWithNibName:nibName bundle:nil];
                
                alarmInfo.msgStatus = MessageStatusRead;
                alarmVC.alarmRecords = [NSMutableArray arrayWithObject:alarmInfo];
          
                alarmNavController = [[UINavigationController alloc] initWithRootViewController:alarmVC];
                
                //alarmNavController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                
                
                //            [viewController presentViewController:alarmNavController animated:YES completion:NULL];
                
                [[UIApplication sharedApplication].keyWindow addSubview:alarmNavController.view];
            }
        }
        else {
            NSString *state = @"恢复";
            
            NSString *alarmAddr = alarmInfo.channelName ? alarmInfo.channelName : [NSString stringWithFormat:@"通道%@",alarmInfo.channelId];
            NSString *alarmType = alarmInfo.alarmType ? alarmInfo.alarmType : @"";
            NSString *content = [NSString stringWithFormat:@"%@%@%@报警",alarmAddr,state,alarmType];
            
            MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
            
            hud.removeFromSuperViewOnHide = YES;
            hud.labelText = content;
            hud.mode = MBProgressHUDModeText;
            [[UIApplication sharedApplication].keyWindow addSubview:hud];
            
            [hud show:YES];
            [hud hide:YES afterDelay:2.0];
            
        }

    }

}




- (void)dismissAlarmView
{
//    if (alarmNavController) {
//        [self stopPlayAlarmSound];
//        
//        [alarmNavController dismissViewControllerAnimated:NO completion:^{
//
//        }];
//        
//        alarmNavController = nil;
//    }
    
    [self stopPlayAlarmSound];
    
    [alarmNavController.view removeFromSuperview];
    
    alarmNavController = nil;
}

- (void)dismissCallView
{
//    if (callNavController) {
//        [self stopPlayCallSound];
//        
//        [callNavController dismissViewControllerAnimated:NO completion:^{
//
//        }];
//        
//        callNavController = nil;
//
//    }
    
    [self stopPlayCallSound];
    [callNavController.view removeFromSuperview];
    callNavController = nil;
}

- (void)initTabBarController
{
    CustomTabBarController *controller = [[CustomTabBarController alloc] init];
    self.tabBarController = controller;
    
    NSString *nibName = nil;
    
//    nibName = [Util nibNameWithClass:[MessageViewController class]];
//    UINavigationController *navMsgController = [[UINavigationController alloc] initWithRootViewController:[[MessageViewController alloc] initWithNibName:nibName bundle:nil]];//信息导航控制器
    
    nibName = [Util nibNameWithClass:[FavoriteViewController class]];
    
    FavoriteViewController *favController = [[FavoriteViewController alloc] initWithNibName:nibName bundle:nil];
    UINavigationController *navFavoriteController = [[UINavigationController alloc] initWithRootViewController:favController];//服务导航控制器
    
    nibName = [Util nibNameWithClass:[ServiceViewController class]];
    UINavigationController *navServiceController = [[UINavigationController alloc] initWithRootViewController:[[ServiceViewController alloc] initWithNibName:nibName bundle:nil]];//服务导航控制器
    
    nibName = [Util nibNameWithClass:[DeviceControlViewController class]];
    UINavigationController *navSHController = [[UINavigationController alloc] initWithRootViewController:[[DeviceControlViewController alloc] initWithNibName:nibName bundle:nil]];//家居导航控制器
    
    nibName = [Util nibNameWithClass:[MoreViewController class]];
    UINavigationController *navMoreController = [[UINavigationController alloc] initWithRootViewController:[[MoreViewController alloc] initWithNibName:nibName bundle:nil]];//更多导航控制器
    
    [self.tabBarController setViewControllers:[NSArray arrayWithObjects:navFavoriteController, navSHController, navServiceController, navMoreController, nil]];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"applicationDidReceiveRemoteNotification");
    
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	NSString *newToken = [deviceToken description];
	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
	NSLog(@"apns return token is: %@", newToken);
    [User currentUser].devToken = newToken;
    
    [[NSUserDefaults standardUserDefaults] setObject:newToken forKey:@"token"];
    
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    NSLog(@"applicationWillResignActive");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    NSLog(@"applicationDidEnterBackground");
    
//    [UIApplication sharedApplication].applicationIconBadgeNumber = [[MessageManager getInstance] totalUnreadMsgNum];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    

    [self checkLockPswdSetting];
    
    
    //后台voip
    [[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^{ //todo send keep live
        
    }];
    
    
    __block UIBackgroundTaskIdentifier bgTask = 0;
    bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];

    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        // Do the work associated with the task, preferably in chunks.

        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    });


    
}


- (void)backgroundHandler {
    
    
//    bgTask = [application beginBackgroundTaskWithName:@"MyTask" expirationHandler:^{
//        // Clean up any unfinished task business by marking where you
//        // stopped or ending the task outright.
//        [application endBackgroundTask:bgTask];
//        bgTask = UIBackgroundTaskInvalid;
//    }];
//    
//    // Start the long-running task and return immediately.
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        
//        // Do the work associated with the task, preferably in chunks.
//        
//        [application endBackgroundTask:bgTask];
//        bgTask = UIBackgroundTaskInvalid;
//    });

//    UIApplication* app = [UIApplication sharedApplication];
//    __block UIBackgroundTaskIdentifier bgTask = 0;
//    
//    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
//        
//        [app endBackgroundTask:bgTask];
//        bgTask = UIBackgroundTaskInvalid;
//    }];
//    
//    NSLog(@"backgroundinghandler--> %d",bgTask);
//
//    
//    // Start the long-running task
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        NSInteger counter = 0;
//        while (1) {
//            
//            //NSLog(@"counter:%d", counter++);
//            
//            sleep(1);
//            
//        }
//        
//    });
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    NSLog(@"applicationWillEnterForeground");
    
    //清除keep alive句柄
    [[UIApplication sharedApplication] clearKeepAliveTimeout];
    

    
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return UIInterfaceOrientationMaskPortrait;
}



- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    NSLog(@"applicationDidBecomeActive");

   
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    NSLog(@"applicationWillTerminate");
    
    [[NetAPIClient sharedClient] SHCleanUp];
}






@end
