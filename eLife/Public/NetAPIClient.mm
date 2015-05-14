//
//  NetAPIClient.m
//  eLife
//
//  Created by mac on 14-3-17.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "NetAPIClient.h"
#import "DeviceData.h"
#import "CHKeychain.h"
#import "MessageManager.h"

#import "MQ.h"
#import "IcrcHttpClientSdk.h"
#import "ShApi.h"

#import "DBManager.h"
#import "User.h"
#import "PublicDefine.h"
#import "UserDBManager.h"

#import "Reachability.h"
#import "NetReachability.h"
//#import "AFNetWorking.h"

#import "NotificationDefine.h"

#import "Util.h"
#import <objc/runtime.h>
//#import <libxml2/libxml/parser.h>
//#import <libxml2/libxml/tree.h>
//#import <libxml2/libxml/xmlreader.h>

#define OPERATE_TIME 0.5//操作间隔时间

#define CTRL_TIME_OUT 5000  //智能家居设备控制超时5s

#define LONGER_CTRL_TIME_OUT 10000 //超时10s

#define GET_CONFIG_TIME_OUT 10000//获取智能家居配置超时10s

#define BUFFER_SIZE 102400 //buffer

//#define SERVER_DOMAIN @"www.dahuayun.com"
#define SERVER_DOMAIN @"www.dahuaweb.com"
//#define SERVER_DOMAIN @"www.aesyun.com"

#define MQ_TOPIC_PUBLIC @"zw.public.all.receive.info" //MQ主题 公共消息
#define MQ_TOPIC_ALARM @"zw.public.single.receive" //MQ主题 报警消息

#define MAX_ROOM_NUM    40//最大房间数
#define MAX_DEVICE_NUM  80//最大设备数
#define MAX_FLOOR_NUM   20//最大楼层数

#define BUNDLE_ID @"com.zwan.elife"
#define KUUID @"key_uuid"


//智能家居任务阶段
enum _SHTaskStep
{
    SHTaskStepWaiting = 0,//等待开始
    SHTaskStepDoing = 1,//正在进行中
    SHTaskStepFinished = 2//已经完成
    
};


static bool  OnServerDisconnect(void *icrc_handle, int state, void *pUserData);//客户端与服务器连接断开回调


static int OnCbStackEx(void *pUser,MQ_HANDLE hInst,MQ_HANDLE hSessionId,char *pTopic,char *pJmsType,char *pMsg,int iMsgLen);//mq回调

static int OnCbStack(void *pUser,MQ_HANDLE hInst,MQ_HANDLE hSessionId,LPMQ_CALLBACK_INFO pcbInfo);


#pragma mark - new sdk
static void OnDisconnect(unsigned int hLoginID,emWorkMode mode,
                                       char *pchServIP,int nServPort,int status,int reason,void *pUser);

static void OnEventNotify(unsigned int hLoginID,emEventType type,char * pszEvent,void *pUser);

static void OnIPSearch(char *pDeviceInfo,void *pUser);

@interface NetAPIClient ()
{

    NSString *_meid;
    
    //upnp
    NSString *_upnpServCode;
    NSString *_upnpAddr;
    int _upnpPort;
    UInt32 _mLoginId;//upnp登录id
    
    BOOL _isInternalIp;//是否是内网

    
    //记住上次操作的时间，防止界面在一定时间内连续点击同一按钮(例如，联系点击开，关按钮)
    NSMutableDictionary *_opBuffer;
    
    dispatch_queue_t _serialQueue;//串行队列
    dispatch_queue_t _concurrentQueue;//并行队列
    
    MQ_ENDPOINT m_epInfo;
    
    MQ_HANDLE m_hInstance;
    
    MQ_EXRAINFO m_stExtInfo;
    
    NSString *_serverAddr;
    int _serverPort;
    
    
    BOOL _isLogin;//是否已经成功登录平台，没有的话每隔15秒去重连


    NSOperationQueue *opQueue;
    
    NSInteger _shTaskStep;
    
    
    int tempLoginID;//呼叫转移网关loginid
    NSString *vtoID;//门口机id
}



@end

@implementation NetAPIClient

@synthesize gatewayList = _gatewayList;

@synthesize callId = _callId;




#pragma mark Public Methods

+ (NetAPIClient *)sharedClient
{
    static NetAPIClient *client = nil;
    static dispatch_once_t once;
    dispatch_once(&once,^{
        client = [[NetAPIClient alloc] init];
        
    });
    
    return client;
}

- (id)init
{
    if (self = [super init]) {
        
        
        _serialQueue = dispatch_queue_create("com.zwan.MyQueue", NULL); // 串行queue
        _concurrentQueue = dispatch_get_global_queue(0, 0);//并行队列
        //NSLog(@"obj retainCount=%x",  _objc_rootRetainCount(_concurrentQueue));
        
        
        _gatewayList = [NSMutableArray arrayWithCapacity:1];
        
        icrc_handle = NULL;
        
        _meid = [self uuid];
        
        _opBuffer = [NSMutableDictionary dictionaryWithCapacity:1];
        
        SH_Init(OnDisconnect, (__bridge void *)self);
        SH_SetEventNotify(OnEventNotify,(__bridge void*)self);
        
        
        [[NetReachability getInstance] startWatchNetwork];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        
    }
    
    return self;
}


- (void)beginSHTask
{
    //MQ
    [self connectMQ];
    
    //智能家居服务
    _callId = _callId ?  _callId : @"";
    _meid = _meid ? _meid : @"";
    NSString *clientVC = [User currentUser].virtualCode;//客户端虚号
    clientVC = clientVC ?  clientVC : @"";
    
    _upnpAddr = _upnpAddr ? _upnpAddr : @"";
    _upnpServCode =  _upnpServCode ? _upnpServCode : @"";
    
    UserInfo userInfo;
    strcpy(userInfo.szMeid, [_meid UTF8String]);
    strcpy(userInfo.szPwd, [_callId UTF8String]);
    strcpy(userInfo.szVCode, [clientVC UTF8String]);
    strcpy(userInfo.szPhoneNumber, [[User currentUser].name  UTF8String]);
    strcpy(userInfo.szModel, [[UIDevice currentDevice].model UTF8String]);
    
    UamsInfo uamsInfo;
    strcpy(uamsInfo.szServerIp, [_upnpAddr UTF8String]);
    strcpy(uamsInfo.szServerVCode, [_upnpServCode UTF8String]);
    uamsInfo.iPort = _upnpPort;
    
    //设置服务器信息
    SH_SetServerInfo(userInfo, uamsInfo);
    
    //开启后台获取智能家居设备线程
    [self getSHConfig];

}

- (void)beginTask
{
  
    //消息处理
    [[MessageManager getInstance] dealWithUserMessage];
    
    
    //智能家居服务
    [self beginSHTask];
    

}




- (void)redirect
{
    NSLog(@"redirect");
    
    //先检查keychain里面plugin程序是否有储存ip和port，有的话用，没有则利用服务重定向获取业务服务器ip和port
    NSMutableDictionary *kVPairs = (NSMutableDictionary *)[CHKeychain load:KEY_IP_PORT];
    NSString *ip = [kVPairs objectForKey:KEY_IP];
    NSString *port = [kVPairs objectForKey:KEY_PORT];
    
    if ([ip length] > 0 && [port length] > 0) {
        _serverAddr = ip;
        _serverPort = [port intValue];

    }
    else {
        ICRC_REDIRECT_INFO info;
        
//        char buf[] = "www.dahuayun.com";
        
        NSLog(@"服务器重定向开始");
        
        if (0 == ICRC_Http_Redirect([SERVER_DOMAIN UTF8String],5000,&info)) {
            _serverAddr = [NSString stringWithUTF8String:info.sIp];
            _serverPort = info.iPort;

        }
        
    }
    
    NSLog(@"重定向 ip :%@ port :%d",_serverAddr,_serverPort);
}

- (VersionInfo *)checkVersion
{

    ICRC_VERSION_INFO info;
    
    if (_serverAddr) {
        if (0 == ICRC_Http_CheckVersion([_serverAddr UTF8String], _serverPort, 2, &info)) {
            NSLog(@"最新版本%s support%s %s %s",info.sVersionName,info.sMinVersionName,info.sVersionDesc,info.sUpdateurl);
            VersionInfo *version = [[VersionInfo alloc] init];
            version.versionName = [NSString stringWithUTF8String:info.sVersionName];
            version.versionDesc = [NSString stringWithUTF8String:info.sVersionDesc];
            version.updateUrl = [NSString stringWithUTF8String:info.sUpdateurl];
            version.supportVersion = [NSString stringWithUTF8String:info.sMinVersionName];
            //           version.supportVersion = @"1.0.0";
            version.publishDate = [NSDate dateWithTimeIntervalSince1970:info.iPublishTime];
            
            self->_versionInfo = version;
            
            
            return version;
            
        }
    }

    
    return nil;
    
}

- (void)changeOldPassword:(NSString *)oldPswd newPassword:(NSString *)newPswd successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback
{
    if (!oldPswd || !newPswd) {
        failureCallback(-1);
    }
    
    if (!icrc_handle) {
        failureCallback(-1);
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int ret;
        if (0 == (ret = ICRC_Http_ChangePassword(icrc_handle, [newPswd UTF8String], [oldPswd UTF8String]))) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (successCallback) {
                    successCallback();
                }
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failureCallback) {
                    failureCallback(ret);
                }
            });
        }
    });
    

}

- (void)changeEmail:(NSString *)newEmail successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback
{
    if (!icrc_handle) {
        failureCallback(-1);
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int ret;
        if (0 == (ret = ICRC_Http_ChangeEmail(icrc_handle, [newEmail UTF8String]))) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (successCallback) {
                    successCallback();
                }
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failureCallback) {
                    failureCallback(ret);
                }
            });
        }
    });

}




- (void)checkVersion:(void (^)(VersionInfo *))successCallback failureCallback:(void (^)(void))failureCallback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{

//        [self redirect];
        
        
        ICRC_VERSION_INFO info;
        
        if (_serverAddr) {
            if (0 == ICRC_Http_CheckVersion([_serverAddr UTF8String], _serverPort, 2, &info)) {
                NSLog(@"最新版本%s support%s %s %s",info.sVersionName,info.sMinVersionName,info.sVersionDesc,info.sUpdateurl);
                VersionInfo *version = [[VersionInfo alloc] init];
                version.versionName = [NSString stringWithUTF8String:info.sVersionName];
                version.versionDesc = [NSString stringWithUTF8String:info.sVersionDesc];
                version.updateUrl = [NSString stringWithUTF8String:info.sUpdateurl];
                version.supportVersion = [NSString stringWithUTF8String:info.sMinVersionName];
                //           version.supportVersion = @"1.0.0";
                version.publishDate = [NSDate dateWithTimeIntervalSince1970:info.iPublishTime];
                
                self->_versionInfo = version;

                if (successCallback) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successCallback(version);
                    });
                }
            }
            else if (failureCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureCallback();
                });
            }
        }
        else if (failureCallback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureCallback();
            });
        }

    });
}

- (void)userRegister:(NSString *)user pswd:(NSString *)pswd email:(NSString *)email authCode:(NSString *)authCode  authCodeText:(NSString *)authCodeText successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback
{
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong __typeof(weakSelf) self = weakSelf;
        

        [self redirect];

        
        int ret;
        if (0 ==  (ret = ICRC_Http_RegisterAccount([self->_serverAddr UTF8String], self->_serverPort, [user UTF8String], [email UTF8String], [pswd UTF8String], [authCode UTF8String], [authCodeText UTF8String], "", ""))) {
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (successCallback) {
                    successCallback();
                }
            });
        }
        else if (failureCallback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                failureCallback(ret);
            });
        }
        
    });
    
}


- (void)loginWithUser:(NSString *)user psd:(NSString *)psd successCallback:( void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback
{
    
    
    if ([user length] > 0 && [psd length] > 0 ) {
        
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            
            [self redirect];
         
            
            if (!_serverAddr) {
                
                dispatch_async(dispatch_get_main_queue(),^{
                    failureCallback(ICRC_ERROR_HTTP_NO_RESPONSE);
                });
                
                return;
            }
            
            ICRC_CONNECT_INFO *conn = (ICRC_CONNECT_INFO *)malloc(sizeof(ICRC_CONNECT_INFO));
            
            int netType = [self CheckInternalIP:self->_serverAddr] ? 1 : 2;//1局域网，2公网
            
            NSLog(@"登录开始");
           
            int ret = ICRC_Http_Login(&(self->icrc_handle), [self->_serverAddr UTF8String], self->_serverPort, [user UTF8String], [psd UTF8String], 2, netType, 1, [_meid UTF8String], [CLIENT_VERSION UTF8String], conn, OnServerDisconnect, (__bridge void *)(self));
         
   
                if (0 == ret) {//登录成功
                    
                    NSLog(@"登录成功");
                
                    self->_callId = [NSString stringWithUTF8String:conn->sCallId];
                    self->_upnpServCode = [NSString stringWithUTF8String:conn->sUpnpServCode];
                    self->_upnpAddr = [NSString stringWithUTF8String:conn->sUpnpAddr];
                    self->_upnpPort = conn->iUpnpPort;
                    
                    self->_lastVersion = [NSString stringWithUTF8String:conn->sLastVersion];
  
                    [User currentUser].virtualCode = [NSString stringWithUTF8String:conn->sVirtualCode];
                    [User currentUser].city = [NSString stringWithUTF8String:conn->sCity];
                    [User currentUser].ISP = [NSString stringWithUTF8String:conn->sISP];
                    [User currentUser].authCodeText = [NSString stringWithUTF8String:conn->sAuthCodeText];
                    
                    char *token = conn->sToken;
                    NSLog(@"return token %s",token);
                    
                    free(conn);
                    
                     [self checkVersion];
                    
                    [self sendToken:_meid];
                    
                    _isLogin = YES;
             
                    
                    dispatch_async(dispatch_get_main_queue(), ^{//主线程成功失败回调
                        if (successCallback) {
                            successCallback();
                        }
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:LoginSuccessNotification object:nil userInfo:nil];
                    });
                }
                else {//登录失败
                    
                    NSLog(@"登录失败 %d",ret);
                    
                    free(conn);
                    dispatch_async(dispatch_get_main_queue(), ^{//主线程成功失败回调
                        if (failureCallback) {
                            failureCallback(ret);
                        }
                        
                    });
                
            }
        });
    }
}



- (void)logoutTimeout:(int)timeout successCallback:(void(^)(void))successCallback failureCallback:(void (^)(void))failureCallback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSLog(@"logout start");

        
        //等待智能家居接口调用结束再登出，否则会crash
        BOOL bTimeout = YES;
        for (int i = 0; i < timeout; i++)
        {
            if (_shTaskStep == SHTaskStepFinished)
            {
                bTimeout = NO;
                 break;
                
            }
            
            
            sleep(1);
        }
        
        if (bTimeout) {
            
            NSLog(@"logout timeout");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failureCallback) {
                    failureCallback();
                }
                
            });
            
            return;
        }
        
        if (self->icrc_handle) {
            //不管登出成功失败
            ICRC_Http_Logout(self->icrc_handle);
        }
        
        [self logoutCleanup];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:LogoutNotification object:nil];
            
            if (successCallback) {
                successCallback();
            }
 
            
        });
        
        
        NSLog(@"logout end");
    });
    
}


- (void)queryGatewayListFromDB
{
    
    if ([[DBManager defaultManager] open]) {
        [[DBManager defaultManager] createTables];//创建表
    }
    
    [self.gatewayList removeAllObjects];
    
    //查询数据库网关
    NSArray *dbGateways = [[DBManager defaultManager] queryGateways];
    
    [self.gatewayList addObjectsFromArray:dbGateways];
    
    dispatch_async(dispatch_get_main_queue(),^{
        
        //发送获取到网关列表通知
        [[NSNotificationCenter defaultCenter] postNotificationName:GetGatewayListNotification object:nil userInfo:[NSDictionary dictionaryWithObject:self.gatewayList forKey:GetGatewayListNotificationKey]];
    });
}

- (NSString *)uuid
{
    NSMutableDictionary *kVPairs = (NSMutableDictionary *)[CHKeychain load:BUNDLE_ID];
    NSString *uuid = [kVPairs objectForKey:KUUID];
    
    if (nil == uuid) {
        //产生uuid
        CFUUIDRef uuid_ref=CFUUIDCreate(nil);
        CFStringRef uuid_string_ref=CFUUIDCreateString(nil, uuid_ref);
        CFRelease(uuid_ref);
        uuid=CFBridgingRelease(uuid_string_ref);
        
        //保存到keychain
        NSMutableDictionary *kVPairs = [NSMutableDictionary dictionary];
        [kVPairs setObject:uuid forKey:KUUID];
        [CHKeychain save:BUNDLE_ID data:kVPairs];
        
    }
    
     NSLog(@"_meid %@",uuid);
    
    return uuid;
   
}


- (void)cancelLogin
{

}


//申请重置
- (void)applyResetPasswordWithUser:(NSString *)user successCallback:(void (^)(NSDictionary *))successCallback failureCallback:(void (^)(int errCode))failureCallback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [self redirect];
        
        char authCodeSeed[100] = {0};
        char authCodeIndex[100] = {0};
        char smsNum[100] = {0};
        int err = ICRC_Http_PasswordRestorePrepare([_serverAddr UTF8String], _serverPort, [user UTF8String], authCodeSeed, authCodeIndex, smsNum);
        if (0 == err) {
            NSString *strAuthCodeSeed = [NSString stringWithUTF8String:authCodeSeed];
            NSString *strAuthCodeSeedIndex = [NSString stringWithUTF8String:authCodeIndex];
            NSString *strSmsNum = [NSString stringWithUTF8String:smsNum];
            NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:strAuthCodeSeed,@"AuthCodeSeed",strAuthCodeSeedIndex,@"AuthCodeSeedIndex",strSmsNum,@"SMSNum", nil];
            
            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback(result);
                });
            }
        }
        else if (failureCallback)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                  failureCallback(err);
            });
          
        }
    });
    
}

//发送重置密码
- (void)resetPasswordWithUser:(NSString *)user pswd:(NSString *)pswd successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{

        int err = ICRC_Http_PasswordRestore([_serverAddr UTF8String], _serverPort, [user UTF8String], [pswd UTF8String]);
        
        if (err == 0) {
            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback();
                });
            }
        }
        else if (failureCallback)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureCallback(err);
            });
            
        }
    });
    
}

//重置身份识别码
- (void)resetAuthCodeWithUser:(NSString *)user pswd:(NSString *)pswd  authCode:(NSString *)authCode successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        int err = ICRC_Http_PatchAuthCode([_serverAddr UTF8String], _serverPort, [user UTF8String], [pswd UTF8String],[authCode UTF8String]);
        
        if (err == 0) {
            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback();
                });
            }
        }
        else if (failureCallback)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureCallback(err);
            });
            
        }
    });

}

- (void)retrievePassword:(NSString *)user email:(NSString *)email successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        int retCode = ICRC_Http_GetBackPassword([self->_serverAddr UTF8String], self->_serverPort, [user UTF8String], [email UTF8String]);
        if (0 == retCode) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (successCallback) {
                    successCallback();
                }
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failureCallback) {
                    failureCallback(retCode);
                }
            });
            
        }
    });

}

//域名解析
-(NSString *)getIPWithHostName:(const NSString *)hostName
{
    const char *hostN= [hostName UTF8String];
    struct hostent* phot;
    
    @try {
        phot = gethostbyname(hostN);
        
    }
    @catch (NSException *exception) {
        return nil;
    }
    
    if (phot) {
        struct in_addr ip_addr;
        memcpy(&ip_addr, phot->h_addr_list[0], 4);
        char ip[20] = {0};
        inet_ntop(AF_INET, &ip_addr, ip, sizeof(ip));
        
        NSString* strIPAddress = [NSString stringWithUTF8String:ip];
        return strIPAddress;
    }
    
    return nil;
}

- (BOOL)CheckInternalIP:(NSString *)strIp
{
    
    
    _isInternalIp = NO;
    char *chIp = (char *)[strIp UTF8String];
    
    in_addr_t intIP;
    if(!(intIP = inet_addr(chIp)))
    {
        perror("inet_addr failed./n");
        
    }
    
    uint32_t netIp = htonl(intIP);//先转换为网络字节序再比较
    
    in_addr_t xx = inet_addr("10.0.0.0");
    xx = inet_addr("10.255.255.255");
    /*
     *检查3类地址
     10.0.0.0~10.255.255.255
     172.16.0.0~172.31.255.255
     192.168.0.0~192.168.255.255
     */
    if ((netIp >= 0x0A000000 && netIp <= 0x0AFFFFFF ) ||
        (netIp >= 0xAC100000 && netIp <= 0xAC1FFFFF ) ||
        (netIp >= 0xC0A80000 && netIp <= 0xC0A8FFFF ))
    {
        _isInternalIp = YES;
    }
    
    
    return _isInternalIp;
    
}

- (void)registerPushService:(NSString *)token
{
    if ([token length]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            if (self->icrc_handle != NULL) {
                ICRC_Http_RegisterToken(self->icrc_handle, [token UTF8String]);
            }
            
        });
    }
}



//注销处理
- (void)logoutCleanup
{
    MQ_ReleaseInstance(self->m_hInstance);
    m_hInstance = MQ_INVALID_HANDLE;
    
    
    //主线程发送智能家居服务结束通知
    NSNotification *ntf = [NSNotification notificationWithName:SHTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:ntf waitUntilDone:YES];
    
    for (SHGateway *gateway in self.gatewayList)
    {
        
        SH_DelGateWay(gateway.loginId);
    }

    icrc_handle = NULL;
    _isLogin = NO;
    self.enableReconnect = NO;
    _shTaskStep = SHTaskStepWaiting;
    
    [User currentUser].haveLogin = NO;
    [[UserDBManager defaultManager] updateUser:[User currentUser]];
    
    [[DBManager defaultManager] close];
    
}

- (void)cancelLogout
{
    //    Block_release( self.logoutFailedCb);
    //    Block_release( self.logoutSucceedCb);
    //    self.logoutFailedCb = nil;
    //    self.loginSucceedCb = nil;
    
    NSLog(@"cancelLogout");
}

- (void)SHCleanUp
{
    SH_Cleanup();
}


- (void)sendToken:(NSString *)token
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (self->icrc_handle != NULL /*&& [token length] > 0*/) {
            int i=  ICRC_Http_RegisterToken((void*)self->icrc_handle,(char *)[_meid UTF8String]);
            NSLog(@"sendToken %@ return %d\n",_meid,i);
        }
        
    });
}


- (BOOL)checkCallID
{
    if (0 == ICRC_Http_CheckCallID(icrc_handle))
    {
        return YES;
    }

    return NO;
}


- (void)connectMQ
{
    
    NSLog(@"MQ 连接中...");
    

    __weak NSString *tempServer = _serverAddr;
    
    if ([tempServer length] <= 0)
    {
        return;
    }
    
    if (MQ_INVALID_HANDLE != m_hInstance) {
        MQ_ReleaseInstance(m_hInstance);
        m_hInstance = MQ_INVALID_HANDLE;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        //tcp://10.45.1.70:57676
        char *url = (char*)[[NSString stringWithFormat:@"tcp://%@:%d",tempServer,57676] UTF8String];
        
        if (MQ_NO_ERROR != MQ_InitStack() )
        {
            return;
        }
        
        self->m_epInfo.pUser= (__bridge void*)self;
        self->m_epInfo.iEndpointType = MQ_DEVICE_PROXY_PRIV;
        self->m_epInfo.cbStack = OnCbStack;
        
        self->m_stExtInfo.cbStack = OnCbStackEx;
        self->m_stExtInfo.pUser= (__bridge void*)self;
        self->m_stExtInfo.iTopicCount= 2;
        self->m_stExtInfo.pTopicList= (char **)malloc(self->m_stExtInfo.iTopicCount*sizeof(char*));
        
        //报警主题
        NSString *topicAlarm = [NSString stringWithFormat:@"%@.%@",MQ_TOPIC_ALARM,self->_meid];
        self->m_stExtInfo.pTopicList[0] = (char*)[topicAlarm UTF8String];
        
        //公共消息主题
        NSString *topicPublic = [NSString stringWithFormat:@"%@.%@",MQ_TOPIC_PUBLIC,self->_meid];
        self->m_stExtInfo.pTopicList[1] = (char*)[topicPublic UTF8String];
        
        self->m_stExtInfo.iIsCompatibleOld = 2;
        
        
        while(true)
        {
            int iRet = -1;
            if (MQ_INVALID_HANDLE == (self->m_hInstance = MQ_CreateInstance(url,&iRet)) )
            {
                iRet = -1;
            }
            else
            {
                iRet= MQ_SetEndpoint(self->m_hInstance, self->m_epInfo);
                if ( MQ_NO_ERROR != iRet )
                {
                    iRet = -2;
                }
                else
                {
                    iRet= MQ_SetExtraInfo(self->m_hInstance, &self->m_stExtInfo);
                    if( MQ_NO_ERROR != iRet )
                    {
                    }
                    else
                    {
                        if ( MQ_NO_ERROR != (iRet = MQ_InstanceStart(self->m_hInstance)) )
                        {
                            MQ_ReleaseInstance(self->m_hInstance);
                            iRet = -3;
                        }
                        else
                        {
                            _MQConnected = YES;
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[NSNotificationCenter defaultCenter] postNotificationName:MQConnectStatusNotification object:@"Connected"];
                            });
               
                            NSLog(@"MQ 已连接!");
                            
                            _isLogin = [self checkCallID];
                            if (!_isLogin)
                            {
                                [self connectServer];
                            }
                            
                            break;
                        }
                    }
                }
            }
            sleep(10);
        }
        
    });
    
}

//刷新设备列表
- (void)refreshDeviceListCompleted:(void(^)(void))completedCallback
{
    NSNotification *ntf = [NSNotification notificationWithName:RefreshDeviceListStartNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] performSelector:@selector(postNotification:) onThread:[NSThread mainThread] withObject:ntf waitUntilDone:YES];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        _shTaskStep = SHTaskStepDoing;
        
        NSLog(@"refreshDeviceList start");
        
        
        for (int i=0 ; i<[self.gatewayList count]; i++)
        {
            SHGateway *gateway = [self.gatewayList objectAtIndex:i];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                gateway.shFetchingStep = SHFetchingStepDoing;//正在获取
            });
            
            
            
            [self getConfigOfGateway:gateway];//配置
            
            [self getGatewayChangeId:gateway];//changeid
            
            dispatch_async(dispatch_get_main_queue(), ^{
                gateway.shFetchingStep = SHFetchingStepFinished;
            });
            
            [[DBManager defaultManager] updateGateway:gateway];
            //            //查询设备状态
            //            [self queryDeviceStateOfGateway:gateway];
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completedCallback) {
                completedCallback();
            }
            
        });
        
        
      
        
        NSNotification *ntf = [NSNotification notificationWithName:RefreshDeviceListEndNotification object:nil];
        [[NSNotificationCenter defaultCenter] performSelector:@selector(postNotification:) onThread:[NSThread mainThread] withObject:ntf waitUntilDone:YES];
        
        //查询状态
        for (SHGateway *gateway in self.gatewayList)
        {
            [self queryDeviceStateOfGateway:gateway];
        }
        
        NSLog(@"refreshDeviceList end");
        
        _shTaskStep = SHTaskStepFinished;
        
        
        
    });
    
}


- (NSInteger)numberOfGateways
{
    
    
    return [self.gatewayList count];
}

- (NSInteger)numberOfDevices
{
    NSInteger num = 0;
    
    for (SHGateway *gateway in self.gatewayList)
    {
        num += [gateway.deviceArray count];
        num += [gateway.envMonitorArray count];
        num += [gateway.ammeterArray count];
        num += [gateway.ipcArray count];

    }
    
    return num;
}

//查询ipc列表
- (void)getIpcList:(void(^)(NSArray *))callback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        while (_shTaskStep != SHTaskStepFinished) {
            sleep(1);
        }
        
        NSMutableArray *ipcList = [NSMutableArray arrayWithCapacity:1];
        
        for (SHGateway *gateway in self.gatewayList)
        {
            if (gateway.status.remoteOnline && !gateway.status.localOnline && !gateway.IPCPublic) {
                
                [self queryIPCPublicInfo:gateway];
                [[DBManager defaultManager] insertIpcs:gateway.ipcArray gatewaySN:gateway.serialNumber];
                
                gateway.IPCPublic = YES;
                [[DBManager defaultManager] updateGateway:gateway];
    
            }
            
            [ipcList addObjectsFromArray:gateway.ipcArray];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(ipcList);
        });
        
    });
}


//查询ipc码流
- (void)getIpcBitrate:(SHDevice *)device successCallback:(void (^)(VideoQuality grade))successCallback failureCallback:(void (^)(void))failureCallback
{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        int bitRate = 0;
        VideoQuality grade;
        if (SH_GetExtraBitrate(gateway.loginId, (char *)[device.serialNumber UTF8String], bitRate)) {
            if (bitRate >= 256) {
                grade = VideoQualityClear;
            }
            else {
                grade = VideoQualityFluent;
            }
            
            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback(grade);
                    
                });
            }
        }
        else if (failureCallback)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureCallback();
                
            });
        }
    });
    

}

//设置码流
- (void)setIpcBitrate:(SHDevice *)device quality:(VideoQuality)quality successCallback:(void (^)(void))successCallback failureCallback:(void (^)(void))failureCallback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        int bitrate = 0;
        if (quality == VideoQualityClear) {
            bitrate = 256;
        }
        else {
            bitrate = 100;
        }
        if (SH_SetExtraBitrate(gateway.loginId, (char *)[device.serialNumber UTF8String], bitrate)) {
            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback();
                    
                });
            }
        }
        else if (failureCallback)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                failureCallback();
            });
        }
    });
}



- (void)queryIpcVideoCount:(SHDevice *)device successCallback:(void (^)(BOOL max))successCallback failureCallback:(void (^)(void))failureCallback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        char buf[1024] = {0};
        NSInteger result = -1;
        BOOL max = NO;
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
   
        NSDictionary *param = [NSDictionary dictionaryWithObject:gateway.serialNumber forKey:@"sn"];
        NSError *error;
        NSData *data = [NSJSONSerialization dataWithJSONObject:param options:0 error:&error];
        NSString *strParam = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if (HTTP_SimpleQuery((char *)[gateway.ARMSAddr UTF8String], gateway.ARMSPort, (char *)[[User currentUser].name UTF8String], (char *)[[User currentUser].password UTF8String], "GetRemoteMedia", (char *)[strParam UTF8String], buf, 1024)) {
            
            NSString *str = [NSString stringWithUTF8String:buf];
            NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
            NSError *err;
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
            if (dic) {
                NSLog(@"%@",[dic description]);
                
                result = [[dic objectForKey:@"result"] integerValue];
                if (result == 0) {//0 成功
                    NSInteger maxCount = [[dic objectForKey:@"maxVideoCount"] integerValue];
                    NSInteger currentCount = [[dic objectForKey:@"currentVideoCount"] integerValue];
                    if (currentCount >= maxCount) {
                        max = YES;
                    }
        
                }
            }
            
            
        }
        
        if (result == 0)
        {
            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback(max);
                    
                });
            }
        }
        else if (failureCallback)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                failureCallback();
            });
        }
    });

}

- (void)queryIPCPublicInfo:(SHGateway *)gateway
{
    NSLog(@"queryIPCPublicInfo %@",gateway.serialNumber);
    
    //摄像头
    NSDictionary *ipcDic = [self getConfigByName:@"IPCamera" loginId:gateway.loginId];
    if (ipcDic) {
        id ipcs = [ipcDic objectForKey:@"table"];
        if ([ipcs isKindOfClass:[NSArray class]]) {
            
            
            for (NSDictionary *tempIpc in ipcs) {
                
            
                NSString *sSerialNumber = nil;
                id serialNumber = [tempIpc objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    sSerialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    sSerialNumber = (NSString *)serialNumber;
                }
                
                
                 NSString *sPubIP = [tempIpc objectForKey:@"PublicIp"];
                int iPubPort = [[tempIpc objectForKey:@"PublicPort"] intValue];
                NSString *sPubUser = [tempIpc objectForKey:@"PublicUsername"];
                NSString *sPubPswd = [tempIpc objectForKey:@"PublicPassword"];
                
    
                for (SHVideoDevice *ipc in gateway.ipcArray)
                {
                    if ([ipc.serialNumber isEqualToString:sSerialNumber]) {
                        ipc.pubIp = sPubIP;
                        ipc.pubPort = iPubPort;
                        ipc.pubUser = sPubUser;
                        ipc.pubPswd = sPubPswd;
                    }
                }
                
                
                
            }
        }
        
    }
}

- (void)unlockSuccessCallback:(void(^)(void))successCallback
              failureCallback:(void(^)(void))failureCallback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        

        if (SH_RemoteOpenDoor(tempLoginID, (char *)[vtoID UTF8String])) {
            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback();
                    
                });
            }
        }
        else if (failureCallback)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                failureCallback();
            });
        }
    });
}


#pragma mark 获取配置

//下载共享文件
- (void)downloadShareFile:(NSString *)remotePath toLocalPath:(NSString *)localPath fromGateway:(SHGateway *)gateway successCallback:(void (^)(void))successCallback failureCallback:(void (^)(void))failureCallback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (SH_DownloadShareFile(gateway.loginId, (char *)[remotePath UTF8String], (char *)[localPath UTF8String])) {
            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback();
                });
            }
        }
        else if (failureCallback)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureCallback();
            });
        }
        
    });
}


//批量下载共享文件
- (void)downloadShareFiles:(NSArray *)remotePaths toLocalPaths:(NSArray *)localPaths fromGateway:(SHGateway *)gateway
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        for (int i = 0 ; i<[remotePaths count]; i++)
        {
            NSString *remotePath = [remotePaths objectAtIndex:i];
            NSString *localPath = [localPaths objectAtIndex:i];
            
            SH_DownloadShareFile(gateway.loginId, (char *)[remotePath UTF8String], (char *)[localPath UTF8String]);
        }
        
    });
    
}

//查询共享面板列表
- (void)getShareFileListOfGateway:(SHGateway *)gateway successCallback:(void (^)(NSArray *fileList))successCallback failureCallback:(void (^)(void))failureCallback
{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        
        NSDictionary *shareDic = [self getConfigByName:@"ShareFile" loginId:gateway.loginId];
        if (shareDic) {
            
            NSMutableArray *fileArray = [NSMutableArray arrayWithCapacity:1];
            
            if ([shareDic isKindOfClass:[NSDictionary class]]) {
                id files = [shareDic objectForKey:@"ShareList"];
                if ([files isKindOfClass:[NSArray class]]) {
                    
                    for (NSDictionary *tempFileDic in (NSArray *)files) {
                        NSString *filePath = [tempFileDic objectForKey:@"FilePath"];

                        [fileArray addObject:filePath];
                        
                    }
                    
                }
            }
            
            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback(fileArray);
                });
            }
            
        }
        else if (failureCallback)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureCallback();
            });
        }
    });

    
}


//从数据库获取网关家居配置
- (void)getGatewayConfigFromDB:(SHGateway *)gateway
{
    [gateway.deviceArray removeAllObjects];
    [gateway.alarmZoneArray removeAllObjects];
    [gateway.ipcArray removeAllObjects];
    [gateway.sceneModeArray removeAllObjects];
    [gateway.roomArray removeAllObjects];
    [gateway.ammeterArray removeAllObjects];
    [gateway.envMonitorArray removeAllObjects];
    
    //查询房间列表
    NSArray *roomList = [[DBManager defaultManager] queryRoomsByGatewaySN:gateway.serialNumber];
    [gateway.roomArray addObjectsFromArray:roomList] ;
    
    //查询设备列表
    NSArray *deviceList = [[DBManager defaultManager] queryDevicesByGatewaySN:gateway.serialNumber];
    [gateway.deviceArray addObjectsFromArray: deviceList];
    for (SHDevice *device in deviceList) {
        [self generateDeviceState:device];
    }
    
    
    //查询情景模式列表
    NSArray *sceneList = [[DBManager defaultManager] querySceneModesByGatewaySN:gateway.serialNumber];
    [gateway.sceneModeArray addObjectsFromArray: sceneList];
    
    //查询报警防区列表
    NSArray *alarmZoneList = [[DBManager defaultManager] queryAlarmZonesByGatewaySN:gateway.serialNumber];
    [gateway.alarmZoneArray addObjectsFromArray: alarmZoneList];
    for (SHAlarmZone *device in alarmZoneList) {
        [self generateDeviceState:device];
    }
    
    //查询ipc列表
    NSArray *ipcList = [[DBManager defaultManager] queryIpcsByGatewaySN:gateway.serialNumber];
    [gateway.ipcArray addObjectsFromArray: ipcList];
    for (SHVideoDevice *device in ipcList) {
        [self generateDeviceState:device];
    }
    
    //ammeter表
    NSArray *ammeterList = [[DBManager defaultManager] queryAmmetersByGatewaySN:gateway.serialNumber];
    [gateway.ammeterArray addObjectsFromArray:ammeterList];
    for (SHDevice *device in ammeterList) {
        [self generateDeviceState:device];
    }
    
    //查询环境监测器列表
    NSArray *envMonitorList = [[DBManager defaultManager] queryEnvMonitorsByGatewaySN:gateway.serialNumber];
    [gateway.envMonitorArray addObjectsFromArray:envMonitorList];
}



- (void)getSHConfig
{

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        _shTaskStep = SHTaskStepDoing;
        
        NSLog(@"getSHConfig start");
        
//        if (nil == self.gatewayList) {
//            
//            [self queryGatewayListFromDB];
//            
//        }
        

        
//        ICRC_SMARTHOME_DEVICE_DETAIL *pGatewayList = NULL;
//        int num;
//        
//        //获取远程模式下的网关列表(考虑其他其他终端绑定了网关...)
//        int ret = ICRC_Http_GetDeviceList(self->icrc_handle,0,50, &pGatewayList, &num, NULL);
//        
//        if (0 == ret) {
//            
//            NSLog(@"ICRC_Http_GetDeviceList gateway num: %d",num);
//            
//            for (int i=0 ; i<num; i++)
//            {
//                BOOL contain = NO;
//                
//                for (SHGateway *temp in self.gatewayList)
//                {
//                    if ([[NSString stringWithUTF8String:pGatewayList[i].sSN] isEqualToString:temp.serialNumber]) {
//                        contain = YES;
//                        break;
//                    }
//                }
//                
//                if (!contain) {
//                    SHGateway *gateway = [[SHGateway alloc] init];
//                    gateway.virtualCode = [NSString stringWithUTF8String:pGatewayList[i].sVirtualCode];
//                    gateway.serialNumber = [NSString stringWithUTF8String:pGatewayList[i].sSN];
//                    gateway.name = [NSString stringWithUTF8String:pGatewayList[i].sDevName];
//                    gateway.pswd = [NSString stringWithUTF8String:pGatewayList[i].sPasswd];
//                    gateway.type = pGatewayList[i].iDevType;
//                    gateway.typeEx = [NSString stringWithUTF8String:pGatewayList[i].sDevTypeAddtion];
//                    gateway.position = [NSString stringWithUTF8String:pGatewayList[i].sPosition];
//                    gateway.addr = [NSString stringWithUTF8String:pGatewayList[i].sNetAddr];
//                    gateway.port = pGatewayList[i].iNetPort;
//                    gateway.user = @"admin";
//                    
//                    [self->self.gatewayList addObject:gateway];
//                }
//                
//            }
//        }
        


//        dispatch_async(dispatch_get_main_queue(),^{
//            
//            //发送获取到网关列表通知
//            [[NSNotificationCenter defaultCenter] postNotificationName:GetGatewayListNotification object:nil userInfo:[NSDictionary dictionaryWithObject:self.gatewayList forKey:GetGatewayListNotificationKey]];
//        });
        

        for (int i=0; i<[self.gatewayList count]; i++)
        {
            GatewayInfo gwInfo;
            memset(&gwInfo,0,sizeof(GatewayInfo));
            
            SHGateway *gateway = [self.gatewayList objectAtIndex:i];


            
            if (gateway.serialNumber) {
                strcpy(gwInfo.szSn, [gateway.serialNumber UTF8String]);
            }
            

            if (gateway.virtualCode) {
                strcpy(gwInfo.szGwVCode, [gateway.virtualCode UTF8String]) ;
                
            }
            else {
                ICRC_SMARTHOME_DEVICE_DETAIL deviceDetail;
                
                //根据序列号查询设备虚号
                if (0 == ICRC_Http_GetSNDevice(icrc_handle, [gateway.serialNumber UTF8String], &deviceDetail)) {
                    
                    strcpy(gwInfo.szGwVCode, deviceDetail.sVirtualCode) ;
                    
                    gateway.virtualCode = [NSString stringWithUTF8String:deviceDetail.sVirtualCode];
                    gateway.city = [NSString stringWithUTF8String:deviceDetail.sCity];
                    gateway.ISP = [NSString stringWithUTF8String:deviceDetail.sISP];
                    gateway.grade = deviceDetail.iGValue;
                    gateway.ARMSAddr = [NSString stringWithUTF8String:deviceDetail.sARMSNetwork];
                    gateway.ARMSPort = deviceDetail.iARMSPort;
                    
                    [[DBManager defaultManager] updateGateway:gateway];
                }
            }
            
            if (gateway.user) {
                strcpy(gwInfo.szUser, [gateway.user UTF8String]);
            }
            if (gateway.pswd ) {
                strcpy(gwInfo.szPwd, [gateway.pswd UTF8String]);
            }
            if (gateway.addr) {
                strcpy(gwInfo.szIp, [gateway.addr UTF8String]);
            }

            
            gwInfo.iPort = gateway.port;
            
            gateway.loginId = SH_AddGateWay(gwInfo);
            
            if (gateway.loginId == 0) {
                NSLog(@"SH_AddGateWay failed");
            }
            
            if ([gateway.authCode length] == 0) {
                //获取网关授权码
                char buf[200] = {0};
                if (0 == SH_GatewayAuth(gateway.loginId, buf, 200))
                {
                    gateway.authCode = [NSString stringWithUTF8String:buf];
                    
                    NSLog(@"获取授权码成功");
                }
                else {
                    NSLog(@"获取授权码失败");
                }
            }

            if ([gateway.authCode length] > 0) {
                
                //验证授权码
                if (SH_VerifyAuthCode(gateway.loginId, [gateway.authCode UTF8String])) {
                    gateway.authorized = YES;
                    
                    NSLog(@"验证授权码成功：%@",gateway.serialNumber);
                }
                else {
                    gateway.authorized = NO;
                    
                    NSLog(@"验证授权码失败：%@",gateway.serialNumber);
                }
            }
            else {
                gateway.authorized = NO;
            }


            [self queryGatewayState:gateway];
            [self postStatusChangedNtfOfGateway:gateway];
            
            if ([gateway isOnline]) {//登录成功
                
                gateway.status.state = GatewayStatusOnline;
     
                NSString *oldChangeId = gateway.changeId;
                
                [self getGatewayChangeId:gateway];
                
                NSLog(@"oldChangeId:%@ \n newChangeId:%@",oldChangeId,gateway.changeId);
                
                if ([oldChangeId isEqualToString:gateway.changeId] || ([gateway.changeId length] == 0)) {
                    [self getGatewayConfigFromDB:gateway];
                    
                    [self getAuthUsersOfGateway:gateway];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        gateway.shFetchingStep = SHFetchingStepFinished;
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:GetGatewayConfigStepNotification object:gateway userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:SHFetchingStepFinished] forKey:GetGatewayConfigStepNotificationKey]];
                        
                    });
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        gateway.shFetchingStep = SHFetchingStepDoing;//正在获取
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:GetGatewayConfigStepNotification object:gateway userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:SHFetchingStepDoing] forKey:GetGatewayConfigStepNotificationKey]];
                    });
                    
                    
                    [self getConfigOfGateway:gateway];
                    
                    [[DBManager defaultManager] updateGateway:gateway];//获取完配置后去更新数据库的changeid
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        gateway.shFetchingStep = SHFetchingStepFinished;
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:GetGatewayConfigStepNotification object:gateway userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:SHFetchingStepFinished] forKey:GetGatewayConfigStepNotificationKey]];
                    });
                    
                    
                    //                //查询设备状态
                    //                [self queryDeviceStateOfGateway:gateway];
                }
            }
            else {//登录网关失败
                
                gateway.status.state = GatewayStatusLoginFailed;
                
                 [self getGatewayConfigFromDB:gateway];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    gateway.shFetchingStep = SHFetchingStepFinished;
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:GetGatewayConfigStepNotification object:gateway userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:SHFetchingStepFinished] forKey:GetGatewayConfigStepNotificationKey]];
                });
            }
            

        }
        
        
//        [[DBManager defaultManager] insertGateways:self.gatewayList];//数据库插入网关列表
   
        
        
        //发送获取到设备列表通知
        
        NSNotification *ntf = [NSNotification notificationWithName:DeviceListGetReadyNotifacation object:nil];
        [[NSNotificationCenter defaultCenter] performSelector:@selector(postNotification:) onThread:[NSThread mainThread] withObject:ntf waitUntilDone:YES];
        
        //查询状态
        NSArray *tempArray = [NSArray arrayWithArray:self.gatewayList];
        for (SHGateway *gateway in tempArray)
        {
            [self queryDeviceStateOfGateway:gateway];
        }
        
        NSLog(@"getSHConfig end");
        
         _shTaskStep = SHTaskStepFinished;
        
        //订阅网关报警
        [self subGateway];
    });
    
}




- (NSString *)getGatewayChangeId:(SHGateway *)gateway
{
    id changeDic = [self getConfigByName:@"ChangeId" loginId:gateway.loginId];
    
    if ([changeDic isKindOfClass:[NSDictionary class]]) {
        id table = [(NSDictionary *)changeDic objectForKey:@"table"];
        if ([table isKindOfClass:[NSDictionary class]]) {
            
            id changeId = [table objectForKey:@"Version"];
            NSString *strChangeId = nil;
            
            if ([changeId isKindOfClass:[NSString class]]) {
                strChangeId = [NSString stringWithString:changeId];
            }
            else if ([changeId isKindOfClass:[NSNumber class]]) {
                strChangeId = [(NSNumber *)changeId stringValue];
            }
            
            gateway.changeId = strChangeId;
            
            return strChangeId;
        }
    }
    
    return nil;
}

- (NSDictionary *)getConfigByName:(NSString *)configName loginId:(UInt32)loginId
{
    char buffer[BUFFER_SIZE];
    int bufSize = BUFFER_SIZE;
    memset(buffer, 0, BUFFER_SIZE);
    
    NSError *err;
    NSDictionary *dic;
    
    if (SH_GetConfig(loginId, (char *)[configName UTF8String], buffer, &bufSize)) {
        
        NSString *str = [NSString stringWithUTF8String:buffer];
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        
        NSLog(@"getConfigByName %@ : %@",configName,[dic description]);
    }
    else if (bufSize > BUFFER_SIZE) {
        char *buf = (char *)malloc(bufSize);
        
        if (SH_GetConfig(loginId, (char *)[configName UTF8String], buf, &bufSize)) {
            
            NSString *str = [NSString stringWithUTF8String:buf];
            NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
            dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
            
            NSLog(@"getConfigByName too small buffer size:%d configName:%@ data:%@",bufSize,configName,[dic description]);
        }
        
        free(buf);
        
    }
    else {
        NSLog(@"getConfigByName %@ loginId:%d failed",configName,loginId);
    }
    return dic;
}


- (void)getSceneModesOfGateway:(SHGateway *)gateway
{
    //获取情景模式
    NSDictionary *sceneModeDic = [self getConfigByName:@"SceneMode" loginId:gateway.loginId];
    if (sceneModeDic) {
        id table = [sceneModeDic objectForKey:@"table"];
        if ([table isKindOfClass:[NSDictionary class]]) {
            id sceneModes = [table objectForKey:@"Profiles"];
            if ([sceneModes isKindOfClass:[NSArray class]]) {
                NSArray *array = (NSArray *)sceneModes;
                
                for (NSDictionary *tempSceneDic in array) {
                    NSString *sceneName = [tempSceneDic objectForKey:@"Name"];
                    NSString *sceneId = [tempSceneDic objectForKey:@"SceneID"];
                    if (sceneName) {
                        SHSceneMode *sceneMode = [[SHSceneMode alloc] init];
                        sceneMode.name = sceneName;
                        sceneMode.serialNumber = sceneId;
                        sceneMode.gatewaySN = gateway.serialNumber;
                        [gateway.sceneModeArray addObject:sceneMode];
                        
                    }
                    
                }
            }
        }
        
    }
}


- (void)getAlarmZonesOfGateway:(SHGateway *)gateway
{
    //报警防区
    NSDictionary *alarmZoneDic = [self getConfigByName:@"AlarmZone" loginId:gateway.loginId];
    if (alarmZoneDic) {
        id alarmZones = [alarmZoneDic objectForKey:@"table"];
        if ([alarmZones isKindOfClass:[NSArray class]]) {
            NSArray *array = (NSArray *)alarmZones;
            
            for (NSDictionary *tempAlarmZone in array) {
                
                SHAlarmZone *device = [[SHAlarmZone alloc] init];
                
                id serialNumber = [tempAlarmZone objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                }
                
                device.name = [tempAlarmZone objectForKey:@"Name"];
                device.type = SH_DEVICE_ALARMZONE;
                device.sensorType = [tempAlarmZone objectForKey:@"SensorType"];
                device.sensorMethod = [tempAlarmZone objectForKey:@"SenseMethod"];
                device.gatewaySN = gateway.serialNumber;
                
                
                SHAlarmZoneState *state = [[SHAlarmZoneState alloc] init];
                device.state = state;
                
                
                id posId = [tempAlarmZone objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                [gateway.alarmZoneArray addObject:device];
            }
        }
        
    }
}


- (void)getIPCsOfGateway:(SHGateway *)gateway
{
   
    //摄像头
    NSDictionary *ipcDic = [self getConfigByName:@"IPCamera" loginId:gateway.loginId];
    if (ipcDic) {
        id ipcs = [ipcDic objectForKey:@"table"];
        if ([ipcs isKindOfClass:[NSArray class]]) {
         
            [gateway.ipcArray removeAllObjects];
            
            for (NSDictionary *tempIpc in ipcs) {
                
                SHVideoDevice *device = [[SHVideoDevice alloc] init];
                SHStateBase *state = [[SHStateBase alloc] init];
                device.state = state;
                
                id serialNumber = [tempIpc objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                }
                
                device.name = [tempIpc objectForKey:@"Name"];
                device.type = SH_DEVICE_IPC;
                device.ip = [tempIpc objectForKey:@"Ip"];
                device.port = [[tempIpc objectForKey:@"Port"] intValue];
                device.user = [tempIpc objectForKey:@"Username"];
                device.pswd = [tempIpc objectForKey:@"Password"];
                device.gatewaySN = gateway.serialNumber;
                
                device.pubIp = [tempIpc objectForKey:@"PublicIp"];
                device.pubPort = [[tempIpc objectForKey:@"PublicPort"] intValue];
                device.pubUser = [tempIpc objectForKey:@"PublicUsername"];
                device.pubPswd = [tempIpc objectForKey:@"PublicPassword"];
                
                id posId = [tempIpc objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                [gateway.ipcArray addObject:device];
            
                
                
            }
        }
        
    }

}


- (void)getHouseInfoOfGateway:(SHGateway *)gateway
{
    //房间
    
    NSDictionary *houseDic = [self getConfigByName:@"HouseTypeInfo" loginId:gateway.loginId];
    if (houseDic) {
        id house = [houseDic objectForKey:@"table"];
        if ([house isKindOfClass:[NSDictionary class]]) {
            int floorNumber = [[house objectForKey:@"FloorNumber"] intValue];
            NSArray *floors = [house objectForKey:@"Floors"];
            
            for (int i=0 ;i<floorNumber; i++) {
                NSArray *areas = [[floors objectAtIndex:i] objectForKey:@"Areas"];
                NSString *floorId =  [[[floors objectAtIndex:i] objectForKey:@"ID"] stringValue];
                for (NSDictionary *area in areas) {
                    SHRoom *room = [[SHRoom alloc] init];
                    
                    id layoutId = [area objectForKey:@"ID"];
                    if ([layoutId isKindOfClass:[NSNumber class]]) {
                      
                        room.layoutId = [(NSNumber *)layoutId stringValue];
                    }
                    else if ([layoutId isKindOfClass:[NSString class]]) {
                        room.layoutId = (NSString *)layoutId;
                       
                    }
                    
                    room.layoutId = [[area objectForKey:@"ID"] stringValue];
                    room.layoutName = [area objectForKey:@"Name"];
                    room.type = [[area objectForKey:@"Type"] intValue];
                    room.floorId = floorId;
                    room.gatewaySN = gateway.serialNumber;
                    
                    [gateway.roomArray addObject:room];
                }
            }
        }
    }
}


- (void)getAmmetersOfGateway:(SHGateway *)gateway
{
    //电表
    NSDictionary *ammeterDic = [self getConfigByName:@"IntelligentAmmeter" loginId:gateway.loginId];
    if (ammeterDic) {
        id ammeters = [ammeterDic objectForKey:@"table"];
        if ([ammeters isKindOfClass:[NSArray class]]) {
            for (NSDictionary *tempAmmeter in (NSArray *)ammeters) {
                
                SHDevice *device = [[SHDevice alloc] init];
                
                id serialNumber = [tempAmmeter objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                }
                
                device.name = [tempAmmeter objectForKey:@"Name"];
                device.type = SH_DEVICE_AMMETER;
                device.state = [[SHAmmeterState alloc] init];
                
                id posId = [tempAmmeter objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                device.gatewaySN = gateway.serialNumber;
                
                [gateway.ammeterArray addObject:device];
            }
        }
        
    }
}


- (void)getEnvMonitorsOfGateway:(SHGateway *)gateway
{
    //电表
    NSDictionary *ammeterDic = [self getConfigByName:@"EnvironmentMonitor" loginId:gateway.loginId];
    if (ammeterDic) {
        id ammeters = [ammeterDic objectForKey:@"table"];
        if ([ammeters isKindOfClass:[NSArray class]]) {
            for (NSDictionary *tempAmmeter in (NSArray *)ammeters) {
                
                SHDevice *device = [[SHDevice alloc] init];
                
                id serialNumber = [tempAmmeter objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                }
                
                device.name = [tempAmmeter objectForKey:@"Name"];
                device.type = SH_DEVICE_ENVMONITOR;
                device.state = [[SHAmmeterState alloc] init];
                
                id posId = [tempAmmeter objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                device.gatewaySN = gateway.serialNumber;
                
                [gateway.envMonitorArray addObject:device];
            }
        }
        
    }
}

//可控设备（灯光、窗帘、空调、地暖等）
- (void)getCtrlDevicesOfGateway:(SHGateway *)gateway
{
    NSMutableArray *deviceArray = [NSMutableArray arrayWithCapacity:1];
    
    //灯光
    NSDictionary *lightDic = [self getConfigByName:@"Light" loginId:gateway.loginId];
    if (lightDic) {
        id lights = [lightDic objectForKey:@"table"];
        if ([lights isKindOfClass:[NSArray class]]) {
            NSArray *array = (NSArray *)lights;
            
            for (NSDictionary *tempLight in array) {
                
                SHDevice *device = [[SHDevice alloc] init];
                
                id serialNumber = [tempLight objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                   
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                    
                }
                
                device.name = [tempLight objectForKey:@"Name"];
                
                device.type  = [tempLight objectForKey:@"Type"];
                if ([device.type isEqualToString:SH_DEVICE_LEVELLIGHT]) {
                    device.state = [[SHDimmerLightState alloc] init];
                }
                else {
                    device.state = [[SHLightState alloc] init];
                }
                
                
                id range = [tempLight objectForKey:@"Range"];
                
                device.range = range;
                
                
                id posId = [tempLight objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                device.gatewaySN = gateway.serialNumber;
                
                [deviceArray addObject:device];
            }
        }
        
    }
    
    
    //通用插座
    NSDictionary *socketDic = [self getConfigByName:@"BlanketSocket" loginId:gateway.loginId];
    if (socketDic) {
        id sockets = [socketDic objectForKey:@"table"];
        if ([sockets isKindOfClass:[NSArray class]]) {
            NSArray *array = (NSArray *)sockets;
            
            for (NSDictionary *tempLight in array) {
                
                SHDevice *device = [[SHDevice alloc] init];
                
                id serialNumber = [tempLight objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                  
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                   
                }
                
                device.name = [tempLight objectForKey:@"Name"];
                
                device.type = SH_DEVICE_SOCKET;

                id posId = [tempLight objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                device.gatewaySN = gateway.serialNumber;
                
                [deviceArray addObject:device];
            }
        }
        
    }

    
    //窗帘
    NSDictionary *curtainDic = [self getConfigByName:@"Curtain" loginId:gateway.loginId];
    if (curtainDic) {
        id curtains = [curtainDic objectForKey:@"table"];
        if ([curtains isKindOfClass:[NSArray class]]) {
            NSArray *array = (NSArray *)curtains;
            
            for (NSDictionary *tempCurtain in array) {
                
                SHDevice *device = [[SHDevice alloc] init];
                
                id serialNumber = [tempCurtain objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                }
                
                device.name = [tempCurtain objectForKey:@"Name"];
                device.type  = SH_DEVICE_CURTAIN;
                device.state = [[SHCurtainState alloc] init];
                
                id range = [tempCurtain objectForKey:@"Range"];
                device.range = range;
                
                id posId = [tempCurtain objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                device.gatewaySN = gateway.serialNumber;
                
                [deviceArray addObject:device];
            }
        }
        
    }
    
    //空调
    NSDictionary *airconditionDic = [self getConfigByName:@"AirCondition" loginId:gateway.loginId];
    if (airconditionDic) {
        id airconditions = [airconditionDic objectForKey:@"table"];
        if ([airconditions isKindOfClass:[NSArray class]]) {
            NSArray *array = (NSArray *)airconditions;
            for (NSDictionary *tempAircondition in array) {
                
                SHDevice *device = [[SHDevice alloc] init];
                
                id serialNumber = [tempAircondition objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                }
                
                device.name = [tempAircondition objectForKey:@"Name"];
                device.type = SH_DEVICE_AIRCONDITION;
                device.state = [[SHAirconditionState alloc] init];
                
                id range = [tempAircondition objectForKey:@"Range"];
                device.range = range;
                
                
                id posId = [tempAircondition objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                device.gatewaySN = gateway.serialNumber;
                
                [deviceArray addObject:device];
            }
        }
        
    }
    
    
    //地暖
    NSDictionary *groundHeatDic = [self getConfigByName:@"GroundHeat" loginId:gateway.loginId];
    if (groundHeatDic) {
        id groundHeats = [groundHeatDic objectForKey:@"table"];
        if ([groundHeats isKindOfClass:[NSArray class]]) {
            for (NSDictionary *tempGroundHeat in (NSArray *)groundHeats) {
                
                SHDevice *device = [[SHDevice alloc] init];
                
                id serialNumber = [tempGroundHeat objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                }
                
                device.name = [tempGroundHeat objectForKey:@"Name"];
                device.type = SH_DEVICE_GROUNDHEAT;
                device.state = [[SHGroundHeatState alloc] init];
                
                id range = [tempGroundHeat objectForKey:@"Range"];
                device.range = range;
                
                id posId = [tempGroundHeat objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                device.gatewaySN = gateway.serialNumber;
                
                [deviceArray addObject:device];
            }
        }
        
    }
    
    [gateway.deviceArray addObjectsFromArray:deviceArray];
}

- (void)getAllDeviceOfGateway:(SHGateway *)gateway
{
    NSDictionary *devicesDic = [self getConfigByName:@"All" loginId:gateway.loginId];
    
    NSDictionary *dataDic = [devicesDic objectForKey:@"Devices"];
    
    if ([dataDic isKindOfClass:[NSDictionary class]]) {
        
        //灯光
        id lights = [dataDic objectForKey:@"Light"];
        if ([lights isKindOfClass:[NSArray class]]) {
            for (NSDictionary *light in lights)
            {
                SHDevice *device = [[SHDevice alloc] init];
                
                id serialNumber = [light objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                   
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                    
                }
                
                device.name = [light objectForKey:@"Name"];
                device.icon = [light objectForKey:@"Icon"];
                
                device.type  = [light objectForKey:@"Type"];
                if ([device.type isEqualToString:SH_DEVICE_LEVELLIGHT]) {
                    device.state = [[SHDimmerLightState alloc] init];
                    
                    int level = [[light objectForKey:@"Level"] integerValue];
                    device.range = [NSArray arrayWithObjects:@0,[NSNumber numberWithInt:level], nil];
                    
                }
                else {
                    device.state = [[SHLightState alloc] init];
                }
                
                
//                id range = [light objectForKey:@"Range"];
//                
//                device.range = range;
                
                
                id posId = [light objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                device.gatewaySN = gateway.serialNumber;
                
                [gateway.deviceArray addObject:device];

            }
        }
        
        
        //窗帘
        id curtains = [dataDic objectForKey:@"Curtain"];
        
        if ([curtains isKindOfClass:[NSArray class]]) {
            for (NSDictionary *curtain in curtains)
            {
                SHDevice *device = [[SHDevice alloc] init];
                
                id serialNumber = [curtain objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                }
                
                device.name = [curtain objectForKey:@"Name"];
                device.type  = SH_DEVICE_CURTAIN;
                device.icon = [curtain objectForKey:@"Icon"];
                device.state = [[SHCurtainState alloc] init];
                
                
                
                NSInteger level = [[curtain objectForKey:@"Level"] integerValue];
                if (level > 0) {
                     device.range = [NSArray arrayWithObjects:@0,[NSNumber numberWithInt:level], nil];
                }
               
                
                id posId = [curtain objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                device.gatewaySN = gateway.serialNumber;
                
                [gateway.deviceArray addObject:device];

            }
        }
        
        //空调
        id airConditions = [dataDic objectForKey:@"AirCondition"];
        
        if ([airConditions isKindOfClass:[NSArray class]]) {
            for (NSDictionary *ac in airConditions)
            {
                SHDevice *device = [[SHDevice alloc] init];
                
                id serialNumber = [ac objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                }
                
                device.name = [ac objectForKey:@"Name"];
                device.type = SH_DEVICE_AIRCONDITION;
                device.icon = [ac objectForKey:@"Icon"];
                device.state = [[SHAirconditionState alloc] init];
                
                id range = [ac objectForKey:@"Range"];
                device.range = range;
                
                
                id posId = [ac objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                device.gatewaySN = gateway.serialNumber;
                
                [gateway.deviceArray addObject:device];
            }
        }
        
        //地暖
        id groundHeats = [dataDic objectForKey:@"GroundHeat"];
        if ([groundHeats isKindOfClass:[NSArray class]]) {
            for (NSDictionary *groundHeat in (NSArray *)groundHeats) {
                
                SHDevice *device = [[SHDevice alloc] init];
                
                id serialNumber = [groundHeat objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                }
                
                device.name = [groundHeat objectForKey:@"Name"];
                device.type = SH_DEVICE_GROUNDHEAT;
                device.icon = [groundHeat objectForKey:@"Icon"];
                device.state = [[SHGroundHeatState alloc] init];
                
                id range = [groundHeat objectForKey:@"Range"];
                device.range = range;
                
                id posId = [groundHeat objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                device.gatewaySN = gateway.serialNumber;
                
                [gateway.deviceArray addObject:device];
            }
        }
        
        //通用插座
        id sockets = [dataDic objectForKey:@"BlanketSocket"];
        if ([sockets isKindOfClass:[NSArray class]]) {
            
            for (NSDictionary *socket in sockets) {
                
                SHDevice *device = [[SHDevice alloc] init];
                device.state = [[SHStateBase alloc] init];
                
                id serialNumber = [socket objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                    
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                    
                }
                
                device.name = [socket objectForKey:@"Name"];
                device.type = SH_DEVICE_SOCKET;
                device.icon = [socket objectForKey:@"Icon"];
                
                id posId = [socket objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                device.gatewaySN = gateway.serialNumber;
                
                [gateway.deviceArray addObject:device];
            }
            
        }
        
//        //ipc
//        id ipcs = [dataDic objectForKey:@"IPCamera"];
//        if ([ipcs isKindOfClass:[NSArray class]]) {
//            for (NSDictionary *ipc in ipcs) {
//                
//                SHVideoDevice *device = [[SHVideoDevice alloc] init];
//                device.state = [[SHStateBase alloc] init];
//                
//                id serialNumber = [ipc objectForKey:@"DeviceID"];
//                if ([serialNumber isKindOfClass:[NSNumber class]]) {
//                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
//                }
//                else if ([serialNumber isKindOfClass:[NSString class]]) {
//                    device.serialNumber = (NSString *)serialNumber;
//                }
//                
//                device.name = [ipc objectForKey:@"Name"];
//                device.type = SH_DEVICE_IPC;
//                device.ip = [ipc objectForKey:@"Ip"];
//                device.port = [[ipc objectForKey:@"Port"] intValue];
//                device.user = [ipc objectForKey:@"Username"];
//                device.pswd = [ipc objectForKey:@"Password"];
//                device.gatewaySN = gateway.serialNumber;
//                
//                device.pubIp = [ipc objectForKey:@"PublicIp"];
//                device.pubPort = [[ipc objectForKey:@"PublicPort"] intValue];
//                device.pubUser = [ipc objectForKey:@"PublicUsername"];
//                device.pubPswd = [ipc objectForKey:@"PublicPassword"];
//                
//                id posId = [ipc objectForKey:@"AreaID"];
//                if ([posId isKindOfClass:[NSNumber class]]) {
//                    device.roomId = [(NSNumber *)posId stringValue];
//                }
//                else if ([posId isKindOfClass:[NSString class]]) {
//                    device.roomId = (NSString *)posId;
//                }
//                
//                [gateway.ipcArray addObject:device];
//            }
//        }
        
        //电表
        id ammeters = [dataDic objectForKey:@"IntelligentAmmeter"];
        if ([ammeters isKindOfClass:[NSArray class]]) {
            for (NSDictionary *ammeter in (NSArray *)ammeters) {
                
                SHDevice *device = [[SHDevice alloc] init];
                
                id serialNumber = [ammeter objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                }
                
                device.name = [ammeter objectForKey:@"Name"];
                device.type = SH_DEVICE_AMMETER;
                device.state = [[SHAmmeterState alloc] init];
                
                id posId = [ammeter objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                device.gatewaySN = gateway.serialNumber;
                
                [gateway.ammeterArray addObject:device];
            }
        }
        
        //环境监测器
        id environmentMonitors = [dataDic objectForKey:@"EnvironmentMonitor"];
        if ([environmentMonitors isKindOfClass:[NSArray class]]) {
            for (NSDictionary *ev in (NSArray *)environmentMonitors) {
                
                SHDevice *device = [[SHDevice alloc] init];
                
                id serialNumber = [ev objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                }
                
                device.name = [ev objectForKey:@"Name"];
                device.type = SH_DEVICE_ENVMONITOR;
                device.state = [[SHStateBase alloc] init];
                
                id posId = [ev objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                device.gatewaySN = gateway.serialNumber;
                
                [gateway.envMonitorArray addObject:device];
            }
        }

        //报警防区
        id alarmZones = [dataDic objectForKey:@"AlarmZone"];
        if ([alarmZones isKindOfClass:[NSArray class]]) {
      
            for (NSDictionary *alarmZone in alarmZones) {
                
                SHAlarmZone *device = [[SHAlarmZone alloc] init];
                
                id serialNumber = [alarmZone objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                }
                
                device.name = [alarmZone objectForKey:@"Name"];
                device.type = SH_DEVICE_ALARMZONE;
                device.sensorType = [alarmZone objectForKey:@"SensorType"];
                device.sensorMethod = [alarmZone objectForKey:@"SenseMethod"];
                device.gatewaySN = gateway.serialNumber;
                
                
                SHAlarmZoneState *state = [[SHAlarmZoneState alloc] init];
                device.state = state;
                
                
                id posId = [alarmZone objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                [gateway.alarmZoneArray addObject:device];
            }
        }

        
        //背景音乐
        id bgdMscs = [dataDic objectForKey:@"BackgroundMusic"];
        if ([bgdMscs isKindOfClass:[NSArray class]]) {
            
            for (NSDictionary *bgdMsc in bgdMscs) {
                
                SHDevice *device = [[SHAlarmZone alloc] init];
                
                id serialNumber = [bgdMsc objectForKey:@"DeviceID"];
                if ([serialNumber isKindOfClass:[NSNumber class]]) {
                    device.serialNumber = [(NSNumber *)serialNumber stringValue];
                }
                else if ([serialNumber isKindOfClass:[NSString class]]) {
                    device.serialNumber = (NSString *)serialNumber;
                }
                
                device.name = [bgdMsc objectForKey:@"Name"];
                device.type = SH_DEVICE_BACKGROUNDMUSIC;
                device.gatewaySN = gateway.serialNumber;
                
                
                SHBgdMusicState *state = [[SHBgdMusicState alloc] init];
                device.state = state;
                
                
                id posId = [bgdMsc objectForKey:@"AreaID"];
                if ([posId isKindOfClass:[NSNumber class]]) {
                    device.roomId = [(NSNumber *)posId stringValue];
                }
                else if ([posId isKindOfClass:[NSString class]]) {
                    device.roomId = (NSString *)posId;
                }
                
                [gateway.deviceArray addObject:device];
            }
        }
        
    }
    

}


- (void)getAuthUsersOfGateway:(SHGateway *)gateway
{
    [gateway.authUserArray removeAllObjects];
    
    //获取情景模式
    NSDictionary *authUsersDic = [self getConfigByName:@"AuthUser" loginId:gateway.loginId];
    if (authUsersDic) {
        if ([authUsersDic isKindOfClass:[NSDictionary class]]) {
            id users = [authUsersDic objectForKey:@"authList"];
            if ([users isKindOfClass:[NSArray class]]) {
                NSArray *array = (NSArray *)users;

                for (NSDictionary *tempUserDic in array) {
 
                    GatewayUser *user = [[GatewayUser alloc] init];
                    user.authID = [tempUserDic objectForKey:@"AuthID"];
                    user.phoneNumber = [tempUserDic objectForKey:@"PhoneNumber"];
                    user.meid = [tempUserDic objectForKey:@"MEID"];
                    user.deviceModel = [tempUserDic objectForKey:@"Model"];
                    user.enable = [[tempUserDic objectForKey:@"Enable"] boolValue];
                    user.online = [[tempUserDic objectForKey:@"Online"] boolValue];
                    
                    [gateway.authUserArray addObject:user];
                    
                }
                
                
            }
        }
        
    }

}

- (void)getConfigOfGateway:(SHGateway *)gateway
{
    
    NSLog(@"getConfigOfGateway %@",gateway.serialNumber);
    
    [gateway.deviceArray removeAllObjects];
    [gateway.alarmZoneArray removeAllObjects];
    [gateway.ipcArray removeAllObjects];
    [gateway.sceneModeArray removeAllObjects];
    [gateway.roomArray removeAllObjects];
    [gateway.ammeterArray removeAllObjects];
    [gateway.envMonitorArray removeAllObjects];
    [gateway.authUserArray removeAllObjects];
    
    
//    [self getAlarmZonesOfGateway:gateway];
    [self getSceneModesOfGateway:gateway];
    
    //ipc
    [self getIPCsOfGateway:gateway];

//    [self getAmmetersOfGateway:gateway];
    [self getHouseInfoOfGateway:gateway];
//    [self getCtrlDevicesOfGateway:gateway];
//    [self getEnvMonitorsOfGateway:gateway];
    
    [self getAllDeviceOfGateway:gateway];
    [self getAuthUsersOfGateway:gateway];
    
    [[DBManager defaultManager] insertSceneMode:gateway.sceneModeArray gatewaySN:gateway.serialNumber];
    
    
    [[DBManager defaultManager] insertAlarmZones:gateway.alarmZoneArray gatewaySN:gateway.serialNumber];
    
    
    [[DBManager defaultManager] insertIpcs:gateway.ipcArray gatewaySN:gateway.serialNumber];
    if (gateway.status.remoteOnline && !gateway.status.localOnline) {
        gateway.IPCPublic = YES;
      
    }
    else {
        gateway.IPCPublic = NO;
    }
    [[DBManager defaultManager] updateGateway:gateway];
    
    
    [[DBManager defaultManager] insertRooms:gateway.roomArray gatewaySN:gateway.serialNumber];
    

    [[DBManager defaultManager] insertAmmeter:gateway.ammeterArray gatewaySN:gateway.serialNumber];
    
    
    [[DBManager defaultManager] insertDevices:gateway.deviceArray gatewaySN:gateway.serialNumber];
    
    [[DBManager defaultManager] insertEnvMonitors:gateway.envMonitorArray gatewaySN:gateway.serialNumber];
    
    
}









#pragma mark 网络通知

- (void)connectServer
{
    
    [self redirect];
    
    if (_serverAddr) {
        
        ICRC_CONNECT_INFO *conn = (ICRC_CONNECT_INFO *)malloc(sizeof(ICRC_CONNECT_INFO));
        
        int netType = [self CheckInternalIP:self->_serverAddr] ? 1 : 2;//1局域网，2公网
        
        
        int ret = ICRC_Http_Login(&icrc_handle, [_serverAddr UTF8String], _serverPort, [[User currentUser].name UTF8String], [[User currentUser].password UTF8String], 2, netType, 1, [_meid UTF8String], [CLIENT_VERSION UTF8String], conn, OnServerDisconnect, (__bridge void *)(self));
        
        if (ret == 0) {
            
            NSLog(@"登录成功");
            
            self->_callId = [NSString stringWithUTF8String:conn->sCallId];
            self->_upnpServCode = [NSString stringWithUTF8String:conn->sUpnpServCode];
            self->_upnpAddr = [NSString stringWithUTF8String:conn->sUpnpAddr];
            self->_upnpPort = conn->iUpnpPort;
            self->_lastVersion = [NSString stringWithUTF8String:conn->sLastVersion];
            
            [User currentUser].virtualCode = [NSString stringWithUTF8String:conn->sVirtualCode];
            free(conn);
            
            [self checkVersion];
            
            [self sendToken:_meid];
            
            
            //主线程发送智能家居服务结束通知
            NSNotification *ntf = [NSNotification notificationWithName:SHTerminateNotification object:nil];
            [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:ntf waitUntilDone:YES];
            
            for (SHGateway *gateway in self.gatewayList)
            {
                
                SH_DelGateWay(gateway.loginId);
            }
            
            [self beginSHTask];//智能家居任务
            
            _isLogin = YES;

            
        }
        else {
            
            NSLog(@"登录失败");
            
            free(conn);
        }
        
    }
}


- (void)reachabilityChanged:(NSNotification *)ntf
{
   
    Reachability *reach = ntf.object;
    
    if (reach.isReachable) {
        
        NSLog(@"网络可用");
        
        if (self.enableReconnect && !_isLogin) {
            NSLog(@"重新登录平台中..");

            [self connectServer];
        }
        else {
            SH_ManuelReconnect();
        }

    }
    else {
        NSLog(@"网络不可用");
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[NSNotificationCenter defaultCenter] postNotificationName:MQConnectStatusNotification object:@"Disconnected"];
//        });
//        
//        for (SHGateway *gateway in self.gatewayList)
//        {
//            gateway.status.localOnline = NO;
//            gateway.status.remoteOnline = NO;
//            
//            gateway.disconnectReason = DisRe_ConnectFailed;
//            
//            [self postStatusChangedNtfOfGateway:gateway];
//            
//            for (SHDevice *device in gateway.deviceArray)
//            {
//                device.state.online = NO;
//                
//                [self postStatusChangeNtfOfDevice:device];
//            }
//        }
    }
    
}

#pragma mark Private Methods

//重新登录
- (void)loginInBackground
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        while (!_isLogin) {
            
            sleep(15);
            
            [self redirect];
            
            if (_serverAddr) {
                
                ICRC_CONNECT_INFO *conn = (ICRC_CONNECT_INFO *)malloc(sizeof(ICRC_CONNECT_INFO));
                
                int netType = [self CheckInternalIP:self->_serverAddr] ? 1 : 2;//1局域网，2公网
                
                
                int ret = ICRC_Http_Login(&icrc_handle, [_serverAddr UTF8String], _serverPort, [[User currentUser].name UTF8String], [[User currentUser].password UTF8String], 2, netType, 1, [_meid UTF8String], [CLIENT_VERSION UTF8String], conn, OnServerDisconnect, (__bridge void *)(self));
                
                if (ret == 0) {
                    self->_callId = [NSString stringWithUTF8String:conn->sCallId];
                    self->_upnpServCode = [NSString stringWithUTF8String:conn->sUpnpServCode];
                    self->_upnpAddr = [NSString stringWithUTF8String:conn->sUpnpAddr];
                    self->_upnpPort = conn->iUpnpPort;
                    self->_lastVersion = [NSString stringWithUTF8String:conn->sLastVersion];
                    
                    [User currentUser].virtualCode = [NSString stringWithUTF8String:conn->sVirtualCode];
                    free(conn);
                    
                    [self checkVersion];
                    
                    [self sendToken:_meid];
                    
                    
                    //主线程发送智能家居服务结束通知
                    NSNotification *ntf = [NSNotification notificationWithName:SHTerminateNotification object:nil];
                    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:ntf waitUntilDone:YES];
                    
                    for (SHGateway *gateway in self.gatewayList)
                    {
                        
                        SH_DelGateWay(gateway.loginId);
                    }
                    
                    [self beginSHTask];//智能家居任务
                    
                    _isLogin = YES;
                    break;
                }
                else {
                    free(conn);
                }
                
            }
        }
        
        
    });
}


- (void)subGateway
{
    if (icrc_handle) {
        
        dispatch_async(dispatch_get_global_queue(0, 0),^{
            NSMutableArray *subArray = [NSMutableArray arrayWithCapacity:1];
            
            NSArray *tempArray = [NSArray arrayWithArray:self.gatewayList];
            for (SHGateway *gateway in tempArray)
            {
                //                if (!gateway.status.remoteOnline) {//远程在线的不去订阅网关报警
                //                    [subArray addObject:gateway];
                //                }
                if ([gateway.virtualCode length] > 0)
                {
                    [subArray addObject:gateway];
                    
                }
                
            }
            
            const char* buf[10] = {0};
            int count = [subArray count];
            for (int i=0; i<count; i++)
            {
                SHGateway *gateway = [subArray objectAtIndex:i];
                buf[i] = [gateway.virtualCode UTF8String] ;
            }
            
            if (0 ==  ICRC_Http_SubscribeGateway(icrc_handle, buf, count)) {
                NSLog(@"ICRC_Http_SubscribeGateway ok num :%d",count);
            }
            
        });
        
    }
    
    
}

//查询网关状态
- (void)queryGatewayState:(SHGateway *)gateway
{
    
    bool bLocal;
    bool bRemote;
    int localError;
    int remoteError;
    
    if (SH_GateWayStatus(gateway.loginId, bLocal, localError, bRemote, remoteError)) {
        
        gateway.status.remoteOnline = bRemote;
        gateway.status.localOnline = bLocal;
        
        gateway.disconnectReason = localError > 0 ? localError : remoteError;
        
        
//        [self postStatusChangedNtfOfGateway:gateway];
        
        
        NSLog(@"获取网关状态:%@ 本地:%@ 远程:%@",gateway.serialNumber,bLocal ? @"yes" : @"no",bRemote ? @"yes":@"no");
    }

}




- (void)generateDeviceState:(SHDevice *)device
{
    if ([device.type isEqualToString:SH_DEVICE_COMMLIGHT]) {
        
        device.state = [[SHLightState alloc] init];
    }
    else if ([device.type isEqualToString:SH_DEVICE_LEVELLIGHT]) {
        
        device.state = [[SHDimmerLightState alloc] init];
    }
    else if ([device.type isEqualToString:SH_DEVICE_CURTAIN]) {
        
        device.state = [[SHCurtainState alloc] init];
    }
    else if ([device.type isEqualToString:SH_DEVICE_AIRCONDITION]) {
        device.state = [[SHAirconditionState alloc] init];
    }
    else if ([device.type isEqualToString:SH_DEVICE_BACKGROUNDMUSIC]) {
        device.state = [[SHBgdMusicState alloc] init];
    }
    else if ([device.type isEqualToString:SH_DEVICE_ALARMZONE]) {
        device.state = [[SHAlarmZoneState alloc] init];
    }
    else if ([device.type isEqualToString:SH_DEVICE_AMMETER]) {
        device.state = [[SHAmmeterState alloc] init];
    }
    else if ([device.type isEqualToString:SH_DEVICE_GROUNDHEAT]) {
        device.state = [[SHGroundHeatState alloc] init];
    }
    else {
        device.state = [[SHStateBase alloc] init];
    }
    
}





- (BOOL)checkOperationTime:(NSString *)udn operation:(NSString *)operation
{
    
    NSString *key = nil;
    if (udn) {
        key = [NSString stringWithFormat:@"%@_%@",udn,operation];
    }
    else {
        key = [NSString stringWithFormat:@"%@",operation];
    }
    
    
    NSDate *preDate = [_opBuffer objectForKey: key];
    
    
    [_opBuffer setObject:[NSDate date] forKey:key];
    
    if (preDate == nil) {
        return YES;
    }
    else if ([[NSDate date] timeIntervalSinceDate:preDate] >= OPERATE_TIME) {
        return YES;
    }
    
    
    return NO;
}

- (BOOL)checkOperationTime:(NSString *)udn operation:(NSString *)operation params:(NSString *)params
{
    
    if ([udn length] && [operation length] && [params length]) {
        NSString *key = [NSString stringWithFormat:@"%@_%@_%@",udn,operation,params];
        
        
        
        NSDate *preDate = [_opBuffer objectForKey: key];
        
        
        [_opBuffer setObject:[NSDate date] forKey:key];
        
        if (preDate == nil) {
            return YES;
        }
        else if ([[NSDate date] timeIntervalSinceDate:preDate] >= OPERATE_TIME) {
            return YES;
        }
    }
    
    return NO;
}


- (SHGateway *)lookupGatewayById:(NSString *)gatewaySN
{
    for (SHGateway *gateway in self.gatewayList)
    {
        if (NSOrderedSame == [gateway.serialNumber compare:gatewaySN options:NSCaseInsensitiveSearch]) {
            return gateway;
        }
    }
    
    return nil;
}

- (SHGateway *)lookupGatewayByLoginId:(unsigned int)loginId
{
    for (SHGateway *gateway in self.gatewayList)
    {
        if (gateway.loginId == loginId) {
            return gateway;
        }
    }
    
    
    return nil;
}

- (void)IPCGetState:(SHDevice *)device gateway:(SHGateway *)gateway
{
    char buf[1024];
    
    bool bRet = SH_GetState(gateway.loginId,(char *)[SH_DEVICE_IPC UTF8String],(char*)[device.serialNumber UTF8String],buf,1024);
    
    
    if (bRet) {
        
        NSString *str = [NSString stringWithUTF8String:buf];
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        NSDictionary *state = [dic objectForKey:@"State"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            SHLightState *tempState = (SHLightState *)device.state;
            tempState.online = [[state objectForKey:@"Online"] boolValue];
            tempState.powerOn = [[state objectForKey:@"On"] boolValue];
            
            NSLog(@"IPCGetState success id: %@ online:%@ power: %@",device.serialNumber,device.state.online ? @"yes" : @"no",device.state.powerOn ? @"on" : @"off");
            
            [self postStatusChangeNtfOfDevice:device];
        });
        
    }
    else {
        NSLog(@"IPCGetState failed id: %@ online:%@ power: %@",device.serialNumber,device.state.online ? @"yes" : @"no",device.state.powerOn ? @"on" : @"off");
    }
    
}

- (void)queryDeviceStateOfGateway:(SHGateway *)gateway
{
    NSLog(@"查询设备状态:%@",gateway.serialNumber);
    
    char buf[BUFFER_SIZE];
    
    bool bRet = SH_GetState(gateway.loginId,(char *)[@"All" UTF8String],(char*)[@"" UTF8String],buf,BUFFER_SIZE);
    
    NSString *str = [NSString stringWithUTF8String:buf];
    
    if (bRet) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
            NSError *err;
            NSArray *statusArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
            
            for (id dic in statusArray)
            {
                if ([dic isKindOfClass:[NSDictionary class]]) {
                    NSString *deviceId = [dic objectForKey:@"DeviceID"];
                    NSString *deviceType = [dic objectForKey:@"DeviceType"];
                    id state = [dic objectForKey:@"State"];
                    
                    SHDevice *tempDevice = nil;
     
                    //先找到设备对象
                    if ([deviceType isEqualToString:SH_DEVICE_ALARMZONE]) {
                        for (SHAlarmZone *device in gateway.alarmZoneArray)
                        {
                            if ([device.serialNumber isEqualToString:deviceId]) {
                                
                                tempDevice = device;
                                break;
                            }
                        }
                    }
                    else  if ([deviceType isEqualToString:SH_DEVICE_IPC]) {
                        for (SHVideoDevice *device in gateway.ipcArray)
                        {
                            if ([device.serialNumber isEqualToString:deviceId]) {
                                
                                tempDevice = device;
                                break;
                            }
                        }
                        
                    }
                    else {
                        for (SHDevice *device in gateway.deviceArray)
                        {
                            if ([device.serialNumber isEqualToString:deviceId]) {
                                
                                tempDevice = device;
                                break;
                            }
                        }
                    }
 
                    
                    if (tempDevice) {
                        
                        id objOn = [state objectForKey:@"On"];//电源开关状态
                        
                        if ([objOn isKindOfClass:[NSNumber class]]) {
                            tempDevice.state.powerOn = [(NSNumber *)objOn boolValue] ? YES : NO;
                        }
                        else if ([objOn isKindOfClass:[NSString class]])
                        {
                            tempDevice.state.powerOn = [objOn isEqualToString:@"true"] ? YES : NO;
                            
                        }
                        
                        id objOnline = [state objectForKey:@"Online"];//设备在线状态
                        if ([objOnline isKindOfClass:[NSNumber class]]) {
                            tempDevice.state.online = [(NSNumber *)objOnline boolValue] ? YES : NO;
                        }
                        else if ([objOnline isKindOfClass:[NSString class]])
                        {
                            tempDevice.state.online = [objOnline isEqualToString:@"true"] ? YES : NO;
                            
                        }
                        
                        
                        if ([deviceType isEqualToString:SH_DEVICE_AIRCONDITION]) {//空调
                            SHAirconditionState *ariState = (SHAirconditionState *)tempDevice.state;
                            
                            id objEnvTemp = [state objectForKey:@"ActualTemperature"];//环境温度
                            
                            if ([objEnvTemp isKindOfClass:[NSNumber class]]) {
                                ariState.environmentTemp = [(NSNumber *)objEnvTemp floatValue];
                            }
                            else if ([objEnvTemp isKindOfClass:[NSString class]])
                            {
                                ariState.environmentTemp = [(NSString *)objEnvTemp floatValue];
                                
                            }
                            
                            NSString *strMode = [state objectForKey:@"Mode"];//模式
                            ariState.mode = strMode;
                            
                            id objTemp = [state objectForKey:@"Temperature"];//设置温度
                            if ([objTemp isKindOfClass:[NSNumber class]]) {
                                ariState.temperature = [(NSNumber *)objTemp intValue];
                            }
                            else if ([objTemp isKindOfClass:[NSString class]])
                            {
                                ariState.temperature = [(NSString *)objTemp intValue];
                                
                            }
                            
                            NSString *strWind = [state objectForKey:@"WindMode"];//风速
                            ariState.windSpeed = strWind;
                        }
                        else if ([deviceType isEqualToString:SH_DEVICE_CURTAIN]) {//窗帘
                            
                            SHCurtainState *curtainState = (SHCurtainState *)tempDevice.state;
                            
                            id objShading = [state objectForKey:@"Shading"];//遮光率
                            curtainState.shading = [objShading intValue];
                            
                        }
                        else if ([deviceType isEqualToString:SH_DEVICE_LEVELLIGHT]) {//调光型灯光
                            SHDimmerLightState *dimmerLightState = (SHDimmerLightState *)tempDevice.state;
                            
                            id objBrightness = [state objectForKey:@"Bright"];
                            
                            dimmerLightState.brightness = [objBrightness intValue];
                        }
                        else if ([deviceType isEqualToString:SH_DEVICE_ALARMZONE]) {//报警防区
                            SHAlarmZoneState *alarmZoneState = (SHAlarmZoneState *)tempDevice.state;
                            
                            alarmZoneState.enable = [[state objectForKey:@"Enable"] boolValue];
                        }
                        else if ([deviceType isEqualToString:SH_DEVICE_GROUNDHEAT]) {//地暖
                            SHGroundHeatState *groundHeatState = (SHGroundHeatState *)tempDevice.state;
                            
                            id objTemp = [state objectForKey:@"Temperature"];//温度
                            if ([objTemp isKindOfClass:[NSNumber class]]) {
                                groundHeatState.temperature = [(NSNumber *)objTemp intValue];
                            }
                            else if ([objTemp isKindOfClass:[NSString class]])
                            {
                                groundHeatState.temperature = [(NSString *)objTemp intValue];
                                
                            }
                            
                        }
                        else if ([deviceType isEqualToString:SH_DEVICE_BACKGROUNDMUSIC]) {//背景音乐
                            SHBgdMusicState *bgdMusicState = (SHBgdMusicState *)tempDevice.state;
                            
                            bgdMusicState.mute = [[state objectForKey:@"Mute"] boolValue];
                            bgdMusicState.name = [state objectForKey:@"Name"];
                            bgdMusicState.song = [state objectForKey:@"Song"];
                            bgdMusicState.playState = [state objectForKey:@"State"];
                            bgdMusicState.volume = [[state objectForKey:@"Volume"] integerValue];
                        }
                        
                    }
                    
                }
            }
            
            
            [[NSNotificationCenter defaultCenter] postNotificationName:QueryDeviceStatusNotification object:gateway];
        });
        
    }
    else {
         NSLog(@"查询设备状态失败");
    }
    
    
}


#pragma mark 情景模式 & 报警防区

- (void)setSceneMode:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        
        if (SH_SetSceneMode(gateway.loginId,(char *)[device.serialNumber UTF8String])) {
            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(),^{
                    
                    successCallback();
                    
                });
            }
        }
        else {
            if (failureCallback) {
                dispatch_async(dispatch_get_main_queue(),^{
                    
                    failureCallback();
                    
                });
            }
        }
        
    });
    
}





//布撤防
- (void)setAlarmMode:(SHDevice *)device enable:(bool)enable password:(NSString *)password successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
 
    
    dispatch_async(_serialQueue, ^{

        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        
            bool bRet = SH_SetArmMode(gateway.loginId, (char *)[device.serialNumber UTF8String], enable, (char *)[password UTF8String]);
            
            dispatch_async(dispatch_get_main_queue(),^{
                if (bRet) {//控制成功
                    
                    [(SHAlarmZoneState *)device.state setEnable:enable];

                    
                    if (successCallback) {
                        successCallback();
                    }
                }
                else {//控制失败
                    if (failureCallback) {
                        failureCallback();
                    }
                }
            });
        
    });
}






#pragma mark 其他方法

- (void)postStatusChangedNtfOfGateway:(SHGateway *)gateway
{
    NSNotification *ntf = [NSNotification notificationWithName:GatewayStatusChangeNotification object:gateway userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:gateway.status.state] forKey:GatewayPreviousStateKey]];
    
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:ntf waitUntilDone:YES];
}

- (void)postStatusChangeNtfOfDevice:(SHDevice *)device
{
    NSNotification *ntf = [NSNotification notificationWithName:DeviceStatusChangeNotification object:device];
    
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:ntf waitUntilDone:YES];
}





#pragma mark 智能家居控制
- (void)setPowerOn:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"setPowerOn"]) {
        NSLog(@"in time");
        return;
    }
    
    
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"open" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[device.type UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                device.state.powerOn = YES;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });

    
}

- (void)setPowerOff:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"setPowerOff"]) {
        NSLog(@"in time");
        return;
    }
    
    
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"close" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[device.type UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                device.state.powerOn = NO;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
    
}

/*
 *灯光控制
 */
- (void)lightOpen:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"lightOpen"]) {
        NSLog(@"in time");
        return;
    }
    

    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"open" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_COMMLIGHT UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                device.state.powerOn = YES;//使用kvo机制，在主线程发送通知，其它地方一样道理
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}

- (void)lightClose:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"lightClose"]) {
        NSLog(@"in time");
        return;
    }
    

    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"close" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_COMMLIGHT UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                device.state.powerOn = NO;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}

- (void)lightSetBrightness:(SHDevice *)device level:(int)level successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"setBrightLevel",@"action",[NSNumber numberWithInt:level],@"Level", nil];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_LEVELLIGHT UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                [(SHDimmerLightState *)device.state setBrightness:level];
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });

}



/*
 *窗帘控制
 */
- (void)curtainOpen:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"curtainOpen"]) {
        NSLog(@"in time");
        return;
    }
    
    if (nil == device.serialNumber) {
        failureCallback();
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"open" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_CURTAIN UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
//                device.state.powerOn = YES;
                
                if (successCallback) {
                    successCallback();
                }
                
//                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}

- (void)curtainClose:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"curtainClose"]) {
        NSLog(@"in time");
        return;
    }
    

    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"close" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_CURTAIN UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
//                device.state.powerOn = NO;//使用kvo机制，在主线程发送通知，其它地方一样道理
                
                if (successCallback) {
                    successCallback();
                }
                
//                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}

- (void)curtainStop:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"curtainStop"]) {
        NSLog(@"in time");
        return;
    }
    

    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"stop" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_CURTAIN UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                //                device.state.powerOn = NO;//使用kvo机制，在主线程发送通知，其它地方一样道理
                
                if (successCallback) {
                    successCallback();
                }
                
//                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}


- (void)curtainSetShading:(SHDevice *)device level:(int)level successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"setShading",@"action",[NSNumber numberWithInt:level],@"Scale", nil];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_CURTAIN UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
//              [(SHCurtainState *)device.state setShading:level];
                
                if (successCallback) {
                    successCallback();
                }
                
//                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
    
}

/*
 *空调控制
 */
- (void)airConditionOpen:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"airConditionOpen"]) {
        NSLog(@"in time");
        return;
    }
    
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"open" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_AIRCONDITION UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                device.state.powerOn = YES;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}

- (void)airConditionClose:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"airConditionClose"]) {
        NSLog(@"in time");
        return;
    }
    
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"close" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_AIRCONDITION UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                device.state.powerOn = NO;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}

- (void)airConditionSetTemperature:(SHDevice *)device temperature:(int)temperature successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"setTemperature",@"action",[NSNumber numberWithInt:temperature],@"Temperature", nil];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_AIRCONDITION UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                ((SHAirconditionState *)device.state).temperature = temperature;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
    
}



- (void)airConditionSetMode:(SHDevice *)device mode:(NSString *)mode temperature:(int)temperature successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"airConditionSetMode" params:mode]) {
        NSLog(@"in time");
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"setMode",@"action",mode,@"Mode",[NSNumber numberWithInt:0],@"Temperature", nil];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_AIRCONDITION UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                ((SHAirconditionState *)device.state).mode = mode;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}

- (void)airConditionSetWindMode:(SHDevice *)device windMode:(NSString *)windMode successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"airConditionSetWindMode" params:windMode]) {
        NSLog(@"in time");
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"setWindMode",@"action",windMode,@"WindMode", nil];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_AIRCONDITION UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                ((SHAirconditionState *)device.state).windSpeed = windMode;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}


- (void)groundHeatOpen:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"groundHeatOpen"]) {
        NSLog(@"in time");
        return;
    }
    
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"open" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_GROUNDHEAT UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                device.state.powerOn = YES;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });

}

- (void)groundHeatClose:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback{
    
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"groundHeatClose"]) {
        NSLog(@"in time");
        return;
    }
    
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"close" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_GROUNDHEAT UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                device.state.powerOn = NO;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });

}

- (void)groundHeatSetTemperature:(SHDevice *)device temperature:(int)temperature successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"setTemperature",@"action",[NSNumber numberWithInt:temperature],@"Temperature", nil];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_GROUNDHEAT UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                ((SHAirconditionState *)device.state).temperature = temperature;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}


- (void)socketOpen:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"socketOpen"]) {
        NSLog(@"in time");
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"open" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_SOCKET UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                device.state.powerOn = YES;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });

}


- (void)socketClose:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"socketClose"]) {
        NSLog(@"in time");
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"close" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_SOCKET UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                device.state.powerOn = NO;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}

/*
 *背景音乐
 */
- (void)bgdMusicOpen:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"bgdMusicOpen"]) {
        NSLog(@"in time");
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"open" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_BACKGROUNDMUSIC UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                device.state.powerOn = YES;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });

}

- (void)bgdMusicClose:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"bgdMusicClose"]) {
        NSLog(@"in time");
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"close" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_BACKGROUNDMUSIC UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                device.state.powerOn = NO;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}

- (void)bgdMusicSetMute:(SHDevice *)device mute:(BOOL)mute successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"bgdMusicSetMute"]) {
        NSLog(@"in time");
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSString *strEnable = mute ?  @"true" : @"false";
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"mute",@"action",strEnable,@"Enable", nil];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_BACKGROUNDMUSIC UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                ((SHBgdMusicState *)device.state).mute = mute;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });

}

- (void)bgdMusicSetVolume:(SHDevice *)device volume:(NSInteger)volume successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback;
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:@"setVolume",@"action",[NSNumber numberWithInt:volume],@"Volume", nil];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_BACKGROUNDMUSIC UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                ((SHBgdMusicState *)device.state).volume = volume;
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });

}

- (void)bgdMusicPause:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"bgdMusicPause"]) {
        NSLog(@"in time");
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"pause" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_BACKGROUNDMUSIC UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                ((SHBgdMusicState *)device.state).playState = @"Pause";
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}

- (void)bgdMusicResume:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"bgdMusicResume"]) {
        NSLog(@"in time");
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        //NSDictionary *params = [NSDictionary dictionaryWithObject:@"resume" forKey:@"action"];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"pause" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_BACKGROUNDMUSIC UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                
                ((SHBgdMusicState *)device.state).playState = @"Play";
                
                if (successCallback) {
                    successCallback();
                }
                
                [self postStatusChangeNtfOfDevice:device];
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}

- (void)bgdMusicPlayLast:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"bgdMusicPlayLast"]) {
        NSLog(@"in time");
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"lastPiece" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_BACKGROUNDMUSIC UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                

                if (successCallback) {
                    successCallback();
                }
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}

- (void)bgdMusicPlayNext:(SHDevice *)device successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    if (nil == device.serialNumber) {
        failureCallback();
        return;
    }
    
    if (![self checkOperationTime:device.serialNumber operation:@"bgdMusicPlayNext"]) {
        NSLog(@"in time");
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        NSDictionary *params = [NSDictionary dictionaryWithObject:@"nextPiece" forKey:@"action"];
        NSError *error;
        NSString *strParams  = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
        if (jsonData) {
            strParams = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        bool bRet = SH_Control(gateway.loginId, (char *)[SH_DEVICE_BACKGROUNDMUSIC UTF8String], (char *)[device.serialNumber UTF8String], (char *)[strParams UTF8String], [strParams length]);
        
        dispatch_async(dispatch_get_main_queue(),^{
            if (bRet) {//控制成功
                

                
                if (successCallback) {
                    successCallback();
                }
            }
            else {//控制失败
                if (failureCallback) {
                    failureCallback();
                }
            }
        });
    });
}


#pragma mark 视频遮盖


- (void)setVideoCover:(SHVideoDevice *)videoDevice enable:(bool)enable successCallback:(void(^)(void))successCallback failureCallback:(void(^)(void))failureCallback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        
         SHGateway *gateway = [self lookupGatewayById:videoDevice.gatewaySN];
        
        bool bRet = SH_SetVideoCovers(gateway.loginId, (char *)[videoDevice.serialNumber UTF8String], enable);
        if (bRet) {
            
            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    videoDevice.coverEnable = enable;
                    
                    successCallback();
                });
            }
            
        }
        else {
            if (failureCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureCallback();
                });
            }
        }
    });
}






- (void)getVideoCover:(SHVideoDevice *)videoDevice successCallback:(void(^)(bool enable))successCallback failureCallback:(void(^)(void))failureCallback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{

        
        SHGateway *gateway = [self lookupGatewayById:videoDevice.gatewaySN];
        
        bool bEnable;

        bool bRet = SH_GetVideoCovers(gateway.loginId,(char *)[videoDevice.serialNumber UTF8String], bEnable);
        if (bRet) {

            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    videoDevice.coverEnable = bEnable;

                    successCallback(bEnable);
                });
            }

        }
        else {
            if (failureCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureCallback();
                });
            }
        }
    });
}

#pragma mark IP 搜索

- (bool)startSearch
{
    return SH_StartDevFinder(OnIPSearch,(__bridge void *)self);
}

- (bool)searchDevice
{
    return SH_IPSearch(NULL);
}

- (bool)stopSearch
{
    return SH_StopDevFinder();
}

#pragma mark 回调处理

- (void)onCallRedirectCallBack:(unsigned int )loginId params:(NSDictionary *)params
{
     NSLog(@"onCallRedirectCallBack params %@",[params description]);
    
    tempLoginID = loginId;
    
    SHGateway *gateway = [self lookupGatewayByLoginId:loginId];
    
    NSString *strData = [params objectForKey:@"Data"];
    
    NSError *erro;
    NSDictionary *dataDic = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:[strData dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&erro];
    
    vtoID = [dataDic objectForKey:@"RemoteID"];
    
    NSString *target = [dataDic objectForKey:@"Target"];

    id ipc = nil;//门口机对应的ipc
    
    for (SHVideoDevice *device in gateway.ipcArray)
    {
        if ([device.ip isEqualToString:target]) {
            ipc = device;
            break;
        }
    }
    
    if (!ipc) {
    
        ipc = [NSNull null];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CallRedirectNotification object:nil userInfo:[NSDictionary dictionaryWithObject:ipc forKey:CallRedirectIPCKey]];
}


- (void)onFileDownloadCallBack:(unsigned int )loginId params:(NSDictionary *)params
{
    NSLog(@"onFileDownloadCallBack params %@",[params description]);
    
    NSDictionary *dataDic = [params objectForKey:@"Data"];
//    
//    NSString *remotePath = [dataDic objectForKey:@"FilePath"];
//    NSString *localPath = [dataDic objectForKey:@"LocalPath"];
//    BOOL result = [[dataDic objectForKey:@"Result"] boolValue];
    

    [[NSNotificationCenter defaultCenter] postNotificationName:FileDownloadNotification object:nil userInfo:dataDic];
}


- (void)onEventCallBack:(unsigned int )loginId params:(NSDictionary *)params
{
    NSLog(@"onEventCallBack params %@",[params description]);
    
    NSString *deviceId = [params objectForKey:@"DeviceID"];
    NSString *deviceType = [params objectForKey:@"Type"];
    NSDictionary *tempDic = [params objectForKey:@"Data"];
 
    
    SHGateway *gateway = [self lookupGatewayByLoginId:loginId];
    
    SHDevice *tempDevice = nil;
    //先找到设备对象
    if ([deviceType isEqualToString:SH_DEVICE_ALARMZONE]) {
        for (SHAlarmZone *device in gateway.alarmZoneArray)
        {
            if ([device.serialNumber isEqualToString:deviceId]) {
                
                tempDevice = device;
                break;
            }
        }
    }
    else  if ([deviceType isEqualToString:SH_DEVICE_IPC]) {
        for (SHVideoDevice *device in gateway.ipcArray)
        {
            if ([device.serialNumber isEqualToString:deviceId]) {
                
                tempDevice = device;
                break;
            }
        }
        
    }
    else {
        for (SHDevice *device in gateway.deviceArray)
        {
            if ([device.serialNumber isEqualToString:deviceId]) {//先找到通知设备对象
                
                tempDevice = device;
                break;
            }
        }
    }
    
    if (tempDevice) {
        
        id objOn = [tempDic objectForKey:@"On"];//电源开关状态
        
        if ([objOn isKindOfClass:[NSNumber class]]) {
            tempDevice.state.powerOn = [(NSNumber *)objOn boolValue] ? YES : NO;
        }
        else if ([objOn isKindOfClass:[NSString class]])
        {
            tempDevice.state.powerOn = [objOn isEqualToString:@"true"] ? YES : NO;
            
        }
        
        id objOnline = [tempDic objectForKey:@"Online"];//设备在线状态
        if ([objOnline isKindOfClass:[NSNumber class]]) {
            tempDevice.state.online = [(NSNumber *)objOnline boolValue] ? YES : NO;
        }
        else if ([objOnline isKindOfClass:[NSString class]])
        {
            tempDevice.state.online = [objOnline isEqualToString:@"true"] ? YES : NO;
            
        }
        
        
        if ([deviceType isEqualToString:SH_DEVICE_AIRCONDITION]) {//空调
            SHAirconditionState *ariState = (SHAirconditionState *)tempDevice.state;
            
            id objEnvTemp = [tempDic objectForKey:@"ActualTemperature"];//环境温度
            
            if ([objEnvTemp isKindOfClass:[NSNumber class]]) {
                ariState.environmentTemp = [(NSNumber *)objEnvTemp floatValue];
            }
            else if ([objEnvTemp isKindOfClass:[NSString class]])
            {
                ariState.environmentTemp = [(NSString *)objEnvTemp floatValue];
                
            }
            
            NSString *strMode = [tempDic objectForKey:@"Mode"];//模式
            ariState.mode = strMode;
            
            id objTemp = [tempDic objectForKey:@"Temperature"];//设置温度
            if ([objTemp isKindOfClass:[NSNumber class]]) {
                ariState.temperature = [(NSNumber *)objTemp intValue];
            }
            else if ([objTemp isKindOfClass:[NSString class]])
            {
                ariState.temperature = [(NSString *)objTemp intValue];
                
            }
            
            NSString *strWind = [tempDic objectForKey:@"WindMode"];//风速
            ariState.windSpeed = strWind;
        }
        else if ([deviceType isEqualToString:SH_DEVICE_CURTAIN]) {//窗帘
            
            SHCurtainState *curtainState = (SHCurtainState *)tempDevice.state;
            
            id objShading = [tempDic objectForKey:@"Shading"];//遮光率
            curtainState.shading = [objShading intValue];
            
        }
        else if ([deviceType isEqualToString:SH_DEVICE_LEVELLIGHT]) {//调光型灯光
            SHDimmerLightState *dimmerLightState = (SHDimmerLightState *)tempDevice.state;
            
            id objBrightness = [tempDic objectForKey:@"Bright"];
            
            dimmerLightState.brightness = [objBrightness intValue];
        }
        else if ([deviceType isEqualToString:SH_DEVICE_GROUNDHEAT]) {//地暖
            SHGroundHeatState *groundHeatState = (SHGroundHeatState *)tempDevice.state;
            
            id objTemp = [tempDic objectForKey:@"Temperature"];//温度
            if ([objTemp isKindOfClass:[NSNumber class]]) {
                groundHeatState.temperature = [(NSNumber *)objTemp intValue];
            }
            else if ([objTemp isKindOfClass:[NSString class]])
            {
                groundHeatState.temperature = [(NSString *)objTemp intValue];
                
            }
            
        }
        else if ([deviceType isEqualToString:SH_DEVICE_ALARMZONE]) {//报警防区
            SHAlarmZoneState *alarmZoneState = (SHAlarmZoneState *)tempDevice.state;
            
            alarmZoneState.enable = [[tempDic objectForKey:@"Enable"] boolValue];
        }
        else if ([deviceType isEqualToString:SH_DEVICE_BACKGROUNDMUSIC]) {//背景音乐
            SHBgdMusicState *bgdMusicState = (SHBgdMusicState *)tempDevice.state;
            
            bgdMusicState.mute = [[tempDic objectForKey:@"Mute"] boolValue];
            bgdMusicState.name = [tempDic objectForKey:@"Name"];
            bgdMusicState.song = [tempDic objectForKey:@"Song"];
            bgdMusicState.playState = [tempDic objectForKey:@"State"];
            bgdMusicState.volume = [[tempDic objectForKey:@"Volume"] integerValue];
        }
        
        [self postStatusChangeNtfOfDevice:tempDevice];
       
    }
}

- (void)onAlarmCallBack:(unsigned int )loginId params:(NSDictionary *)params
{
    SHGateway *gateway = [self lookupGatewayByLoginId:loginId];
    
    NSLog(@"onAlarmCallBack gateway:%@ params:%@",gateway.serialNumber,[params description]);
    
    NSString *deviceId = [params objectForKey:@"DeviceID"];
    NSString *deviceType = [params objectForKey:@"Type"];
    NSString *strState = [params objectForKey:@"Action"];
    NSString *strData = [params objectForKey:@"Data"];
    
    NSError *erro;
    NSDictionary *dataDic = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:[strData dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&erro];
    
    
    AlarmRecord *alarm = [[AlarmRecord alloc] init];
    alarm.channelId = deviceId;
    alarm.alarmStatus = strState;
    alarm.recordID = [dataDic objectForKey:@"RecordID"];
    

    SHAlarmZone *alarmZone = nil;
    for (SHAlarmZone *aZone in gateway.alarmZoneArray) {
        if ([aZone.serialNumber isEqualToString:alarm.channelId]) {
            
            alarmZone = aZone;
            
            NSLog(@"报警 id:%@, name:%@, AreaID:%@ sensorMethod:%@ ",alarmZone.serialNumber,alarmZone.name,alarmZone.roomId,alarmZone.sensorMethod);
            
            
            break;
        }
    }
    
    NSString *alarmType = alarmZone.sensorMethod;
    
    
    NSDate *date = [NSDate date];
    NSTimeInterval time = [date timeIntervalSince1970];
    alarm.alarmTime = time;
    
    alarm.channelName = alarmZone.name;
    
    NSString *strType = nil;
    
    if ([alarmType isEqualToString:@"Infrared"]) {
        strType = @"红外线";
    }
    else if ([alarmType isEqualToString:@"DoorMagnetism"]) {
        strType = @"门磁";
    }
    else if ([alarmType isEqualToString:@"PassiveInfrared"]) {
        strType = @"被动红外";
    }
    else if ([alarmType isEqualToString:@"GasSensor"]) {
        strType = @"气感";
    }
    else if ([alarmType isEqualToString:@"SmokingSensor"]) {
        strType = @"烟感";
    }
    else if ([alarmType isEqualToString:@"WaterSensor"]) {
        strType = @"水感";
    }
    else if ([alarmType isEqualToString:@"ActiveInfrared"]) {
        strType = @"主动红外";
    }
    else if ([alarmType isEqualToString:@"CallButton"]) {
        strType = @"呼叫按钮";
    }
    else if ([alarmType isEqualToString:@"Emergency"]) {
        strType = @"紧急";
    }
    else if ([alarmType isEqualToString:@"OtherSensor"]) {
        strType = @"其他";
    }
    else if ([alarmType isEqualToString:@"UrgencyButton"]) {
        strType = @"紧急按钮";
    }
    else if ([alarmType isEqualToString:@"Steal"]) {
        strType = @"盗警";
    }
    else if ([alarmType isEqualToString:@"Perimeter"]) {
        strType = @"周界";
    }
    
    alarm.alarmType = strType;
    
    if ([gateway.ipcArray count] > 0) {
        SHVideoDevice *ipc = [gateway.ipcArray objectAtIndex:0];
        alarm.videoAddr = ipc.videoUrl;
        alarm.pubVideoAddr = ipc.pubVideoUrl;
    }
    else {
        alarm.videoAddr = @"";
        alarm.pubVideoAddr = @"";
    }
    
    
    [[MessageManager getInstance] addAlarmMsg:alarm];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OnAlarmNotification object:gateway userInfo:[NSDictionary dictionaryWithObject:alarm forKey:OnAlarmNotificationKey]];
    
}


- (void)onConnectStatusCallBack:(int)loginId workMode:(emWorkMode)mode status:(int)status reason:(int)reason
{
    SHGateway *gateway = [self lookupGatewayByLoginId:loginId];
    
    if (gateway)
    {
        switch (status) {
            case 0://连接断开
                
                [self onDisconnect:gateway workMode:mode reason:reason];
                break;
            case 1://登录成功通知

                [self onLoginSuccess:gateway workMode:mode reason:reason];
 
                break;
            case 2://登录失败
                
                [self onLoginFailed:gateway workMode:mode reason:reason];
                break;
            default:
                break;
        }
        
//        //订阅网关报警
//        [self subGateway];
    }
}

- (void)onDisconnect:(SHGateway *)gateway workMode:(emWorkMode)mode reason:(int)reason
{
    
    NSLog(@"onDisconnect:%@ workMode:%d reason:%d",gateway.serialNumber,mode,reason);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [self queryGatewayState:gateway];
        gateway.disconnectReason = reason;//错误码
    
 
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self postStatusChangedNtfOfGateway:gateway];
            
            if (![gateway isOnline])
            {
                gateway.status.state = GatewayStatusOffline;
                
                gateway.disconnectReason = reason;
                
                for (SHDevice *device in gateway.deviceArray)
                {
                    device.state.online = NO;
                    
                    [self postStatusChangeNtfOfDevice:device];
                }
            }
            
        });
        
        
    });
    
}

- (void)onLoginFailed:(SHGateway *)gateway workMode:(emWorkMode)mode reason:(int)reason
{
    
   NSLog(@"onLoginFailed:%@ workMode:%d reason:%d",gateway.serialNumber,mode,reason);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [self queryGatewayState:gateway];
        gateway.disconnectReason = reason;//错误码
 
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self postStatusChangedNtfOfGateway:gateway];
            
            if (![gateway isOnline])
            {
                gateway.status.state = GatewayStatusLoginFailed;
                
                gateway.disconnectReason = reason;
                
                for (SHDevice *device in gateway.deviceArray)
                {
                    device.state.online = NO;
                    
                    [self postStatusChangeNtfOfDevice:device];
                }
            }
            
        });
        
        
    });
}

- (void)onLoginSuccess:(SHGateway *)gateway workMode:(emWorkMode)mode reason:(int)reason
{
     NSLog(@"onLoginSuccess:%@ workMode:%d reason:%d",gateway.serialNumber,mode,reason);
    
    if (reason == emDisRe_AuthOK) {
        gateway.authorized = YES;

    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (mode == emLocal) {
            gateway.status.localOnline = YES;
        }
        else {
            gateway.status.remoteOnline = YES;
        }

        [self postStatusChangedNtfOfGateway:gateway];
        
        if (gateway.status.state == GatewayStatusOffline) {
            //断线后重连成功,重新查询设备状态
            [self queryDeviceStateOfGateway:gateway];//重新查询设备状态
            
            [self getAuthUsersOfGateway:gateway];//查询网关授权用户
        }
        else if (gateway.status.state == GatewayStatusLoginFailed) {
            //之前登录失败，现在重连成功
            
            [self getAuthUsersOfGateway:gateway];//查询网关授权用户
           
            NSString *oldChangeId = gateway.changeId;
            
            [self getGatewayChangeId:gateway];
            
            NSLog(@"oldid:%@ newid:%@",oldChangeId,gateway.changeId);
            
            if (![oldChangeId isEqualToString:gateway.changeId]) { //是否要重新获取配置
                dispatch_async(dispatch_get_main_queue(), ^{
                    gateway.shFetchingStep = SHFetchingStepDoing;//正在获取
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:GetGatewayConfigStepNotification object:gateway userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:SHFetchingStepDoing] forKey:GetGatewayConfigStepNotificationKey]];
                });
                
                
                [self getConfigOfGateway:gateway];
                
                [[DBManager defaultManager] updateGateway:gateway];//获取完配置后去更新数据库的changeid
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    gateway.shFetchingStep = SHFetchingStepFinished;
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:GetGatewayConfigStepNotification object:gateway userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:SHFetchingStepDoing] forKey:GetGatewayConfigStepNotificationKey]];
                });
                
            }
            
            [self queryDeviceStateOfGateway:gateway];//重新查询设备状态
        }
        else {
            NSLog(@"先前网关状态在线或者初始化!");
        }
        
         gateway.status.state = GatewayStatusOnline;
  
    });
    
}



- (void)notifyIpSearchInfo:(NSString *)info
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSError *erro;
        id objInfo = [NSJSONSerialization JSONObjectWithData:[info dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&erro];
        
        
        
        if ([objInfo isKindOfClass:[NSDictionary class]]) {
            
            SHGateway *gateway = [[SHGateway alloc] init];
            
            
            id IPV4Addr = [objInfo objectForKey:@"IPv4Address"];
            if ([IPV4Addr isKindOfClass:[NSDictionary class]]) {
                NSString *ipAddr = [IPV4Addr objectForKey:@"IPAddress"];
                gateway.addr = ipAddr;
            }
            
            NSString *sn = [objInfo objectForKey:@"SerialNo"];
            gateway.serialNumber = sn;
            
            
            [[NSNotificationCenter defaultCenter] postNotificationName:IPSearchNotification object:nil userInfo:[NSDictionary dictionaryWithObject:gateway forKey:IPSearchNotificationDataKey]];
        }
        
        
    });
}

#pragma mark 抄表 & 环境监测


- (void)readEnvironmentMonitor:(SHDevice *)device successCallback:(void(^)(NSDictionary *))successCallback failureCallback:(void(^)(void))failureCallback
{
    
    dispatch_async(_concurrentQueue, ^{
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        
        
        char buffer[1024] = {0};
        
        bool bRet = SH_ReadDevice(gateway.loginId, (char *)[@"EnvironmentMonitor" UTF8String], (char *)[device.serialNumber UTF8String], (char *)[@"readMeter" UTF8String], buffer, 1024);//

        
        if (bRet) {
            
            NSError *err;
            
            NSString *str = [NSString stringWithUTF8String:buffer];
            NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
            
             NSLog(@"readEnvironmentMonitor %@ ok %@",device.serialNumber,[dataDic description]);
            
            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(),^{
                    
                    successCallback(dataDic);

                });
            }

        }
        else {
             NSLog(@"readEnvironmentMonitor %@ failed",device.serialNumber);
            
            if (failureCallback) {
                dispatch_async(dispatch_get_main_queue(),^{
                    
                    failureCallback();
  
                });
            }

        }
    });
}

- (void)readAmmeterMeter:(SHDevice *)device successCallback:(void(^)(NSDictionary *))successCallback failureCallback:(void(^)(void))failureCallback
{
    
    dispatch_async(_concurrentQueue, ^{
        SHGateway *gateway = [self lookupGatewayById:device.gatewaySN];
        
        
        char buffer[1024] = {0};
        
        bool bRet = SH_ReadDevice(gateway.loginId, (char *)[@"IntelligentAmmeter" UTF8String], (char *)[device.serialNumber UTF8String], (char *)[@"readMeter" UTF8String], buffer, 1024);//读本期
        
        NSMutableDictionary *retDic = [NSMutableDictionary dictionaryWithCapacity:1];
        
        if (bRet) {
            
            NSError *err;
            
            NSString *str = [NSString stringWithUTF8String:buffer];
            NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableDictionary *curDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
            
            if (curDic) {
                [retDic setObject:curDic forKey:CurrentPeriodKey];
            }
            
            
            memset(buffer, 0, 1024);
            
            bRet = SH_ReadDevice(gateway.loginId, (char *)[@"IntelligentAmmeter" UTF8String], (char *)[device.serialNumber UTF8String], (char *)[@"readMeterPrev" UTF8String], buffer, 1024);//读上期
            
            if (bRet) {
                NSString *str = [NSString stringWithUTF8String:buffer];
                NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
                NSMutableDictionary *priorDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
                
                if (priorDic) {
                    [retDic setObject:priorDic forKey:PriorPeriodKey];
                }

            }
            
            NSLog(@"readAmmeterMeter  %@ ok %@",device.serialNumber,[retDic description]);
            
            dispatch_async(dispatch_get_main_queue(),^{
                
                ((SHAmmeterState *)device.state).data = retDic;
                
                if (successCallback) {
                    
                    successCallback(retDic);
                    
                }
                
            });

        }
        else {
             NSLog(@"readAmmeterMeter %@ failed",device.serialNumber);
            
            if (failureCallback) {
                dispatch_async(dispatch_get_main_queue(),^{
                    
                    failureCallback();
                    
                });
            }
        }

    });
    
}





#pragma mark 网关操作


- (void)bindGateway:(SHGateway *)gateway successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback
{
    
    for (SHGateway *tempGateway in self.gatewayList)
    {
        if (NSOrderedSame == [tempGateway.serialNumber compare:gateway.serialNumber options:NSCaseInsensitiveSearch]) {
            failureCallback(ErrorAdded);//该网关序列号已经绑定过
            return;
        }
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        GatewayInfo gwInfo;
        memset(&gwInfo,0,sizeof(GatewayInfo));
        
        ICRC_SMARTHOME_DEVICE_DETAIL deviceDetail;
        
        
        if (gateway.serialNumber) {
            strcpy(gwInfo.szSn, [gateway.serialNumber UTF8String]);
        }
        if (gateway.user) {
            strcpy(gwInfo.szUser, [gateway.user UTF8String]);
        }
        if (gateway.pswd) {
            strcpy(gwInfo.szPwd, [gateway.pswd UTF8String]);
        }
        
        if (gateway.addr) {
            strcpy(gwInfo.szIp,[gateway.addr UTF8String]);
        }
        
        gwInfo.iPort = gateway.port;

        //先根据序列号查询设备虚号
        if (0 == ICRC_Http_GetSNDevice(icrc_handle, [gateway.serialNumber UTF8String], &deviceDetail)) {
            
            strcpy(gwInfo.szGwVCode, deviceDetail.sVirtualCode) ;
            gateway.virtualCode = [NSString stringWithUTF8String:deviceDetail.sVirtualCode];
            gateway.city = [NSString stringWithUTF8String:deviceDetail.sCity];
            gateway.ISP = [NSString stringWithUTF8String:deviceDetail.sISP];
            gateway.grade = deviceDetail.iGValue;
            gateway.ARMSAddr = [NSString stringWithUTF8String:deviceDetail.sARMSNetwork];
            gateway.ARMSPort = deviceDetail.iARMSPort;
            
            NSString *strAddr = [NSString stringWithUTF8String:deviceDetail.sNetAddr];
            if ([strAddr length] > 0) {
                gateway.addr = strAddr;
                strcpy(gwInfo.szIp, deviceDetail.sNetAddr);
            }


        }
        
        gateway.loginId = SH_AddGateWay(gwInfo);
        
        int errorCode = DisRe_None;
        
        //获取网关授权码
        char buf[200] = {0};
        if (0 == SH_GatewayAuth(gateway.loginId, buf, 200))
        {
            gateway.authCode = [NSString stringWithUTF8String:buf];
            
            NSLog(@"获取授权码成功 code :%@",gateway.authCode);
            
            
            //验证授权码
            if (SH_VerifyAuthCode(gateway.loginId, [gateway.authCode UTF8String])) {
                gateway.authorized = YES;
                
                NSLog(@"验证授权码成功");
                
                [self queryGatewayState:gateway];
                [self postStatusChangedNtfOfGateway:gateway];
                
                if (![gateway isOnline]) {
                    
                    errorCode = gateway.disconnectReason;
                    
                }
                
            }
            else {
                
                NSLog(@"验证授权码失败");
                
                errorCode = DisRe_AuthFailed;
                
            }
        }
        else {
            NSLog(@"获取授权码失败");
            
            errorCode = DisRe_NotAuthMode;
            
        }
        
        
        if (errorCode == DisRe_None) {
            gateway.status.state = GatewayStatusOnline;

            [self.gatewayList addObject:gateway];
            
            [[DBManager defaultManager] addGateway:gateway];

            dispatch_async(dispatch_get_main_queue(), ^{

                if (successCallback) {
                    
                    successCallback();
                    
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:BindGatewayNotification object:nil userInfo:[NSDictionary dictionaryWithObject:gateway forKey:BindGatewayNotificationKey]];
                
            });
            
            //获取配置
            dispatch_async(dispatch_get_main_queue(), ^{
                gateway.shFetchingStep = SHFetchingStepDoing;//正在获取
                
                [[NSNotificationCenter defaultCenter] postNotificationName:GetGatewayConfigStepNotification object:gateway userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:SHFetchingStepDoing] forKey:GetGatewayConfigStepNotificationKey]];
            });
            
            [self getConfigOfGateway:gateway];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                gateway.shFetchingStep = SHFetchingStepFinished;//获取完成
                
                [[NSNotificationCenter defaultCenter] postNotificationName:GetGatewayConfigStepNotification object:gateway userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:SHFetchingStepFinished] forKey:GetGatewayConfigStepNotificationKey]];
            });
            
            
            [self getGatewayChangeId:gateway];//获取changeid
            
            [[DBManager defaultManager] updateGateway:gateway];//更新changeid
            
            [self queryDeviceStateOfGateway:gateway];
            
            //订阅网关报警
            [self subGateway];
        }
        else {
            
            //删除loginId
            SH_DelGateWay(gateway.loginId);
            
            if (failureCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureCallback(errorCode);
                });
            }
        }

    });
    
}

- (void)editGateway:(SHGateway *)gateway withName:(NSString *)name user:(NSString *)user pswd:(NSString *)pswd ip:(NSString *)ip port:(NSString *)port timeout:(int)timeout successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback
{
    NSString *oldIp = gateway.addr;
    NSInteger oldPort = gateway.port;
    NSString *oldUser = gateway.user;
    NSString *oldPswd = gateway.pswd;
    

    
    //配置变更了，是否要重新去登录、获取配置信息
    if (!([ip isEqualToString:oldIp] && ([port intValue] == oldPort) && [oldUser isEqualToString:user] && [oldPswd isEqualToString:pswd])) {
        
        dispatch_async(_concurrentQueue, ^{
            
            
            //等待智能家居接口调用结束再删除，否则会crash
            BOOL bTimeout = YES;
            for (int i = 0; i < timeout; i++)
            {
                if (_shTaskStep == SHTaskStepFinished)
                {
                    bTimeout = NO;
                    break;
                    
                }
                
                
                sleep(1);
            }
            
            if (bTimeout) {
                
                NSLog(@"editGateway timeout");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failureCallback) {
                        failureCallback(ErrorTimeout);
                    }
                    
                });
                
                return;
            }
            
        
            //记住之前的网关信息，修改失败的时候改回来
            UInt32 preLoginId = gateway.loginId;
            BOOL preLocal = gateway.status.localOnline;
            BOOL preRemote = gateway.status.remoteOnline;
            int preError = gateway.disconnectReason;
            GatewayInfo preGwInfo;//先前信息
            memset(&preGwInfo,0,sizeof(GatewayInfo));
            if (gateway.serialNumber) {
                strcpy(preGwInfo.szSn, [gateway.serialNumber UTF8String]);
            }
            if (gateway.user) {
                strcpy(preGwInfo.szUser, [gateway.user UTF8String]);
            }
            if (gateway.pswd) {
                strcpy(preGwInfo.szPwd, [gateway.pswd UTF8String]);
            }
            
            if (gateway.addr) {
                strcpy(preGwInfo.szIp,[gateway.addr UTF8String]);
            }
            preGwInfo.iPort = gateway.port;
            SH_DelGateWay(preLoginId);//先删除
            
            
            
            GatewayInfo gwInfo;//修改后的信息
            memset(&gwInfo,0,sizeof(GatewayInfo));
            if (gateway.serialNumber) {
                strcpy(gwInfo.szSn, [gateway.serialNumber UTF8String]);
            }
            if (user) {
                strcpy(gwInfo.szUser, [user UTF8String]);
            }
            if (pswd) {
                strcpy(gwInfo.szPwd, [pswd UTF8String]);
            }
            
            if (ip) {
                strcpy(gwInfo.szIp,[ip UTF8String]);
            }
            gwInfo.iPort = [port intValue];
            
            
            //根据序列号查询设备远程信息
            ICRC_SMARTHOME_DEVICE_DETAIL deviceDetail;
            if (0 == ICRC_Http_GetSNDevice(icrc_handle, [gateway.serialNumber UTF8String], &deviceDetail)) {
                
                strcpy(gwInfo.szGwVCode, deviceDetail.sVirtualCode) ;
                
                gateway.virtualCode = [NSString stringWithUTF8String:deviceDetail.sVirtualCode];
                gateway.city = [NSString stringWithUTF8String:deviceDetail.sCity];
                gateway.ISP = [NSString stringWithUTF8String:deviceDetail.sISP];
                gateway.grade = deviceDetail.iGValue;
                gateway.ARMSAddr = [NSString stringWithUTF8String:deviceDetail.sARMSNetwork];
                gateway.ARMSPort = deviceDetail.iARMSPort;
            }
            
            gateway.loginId = SH_AddGateWay(gwInfo);
            
            int errorCode = DisRe_None;
            
            
            char buf[200] = {0};
            if ( 0 == SH_GatewayAuth(gateway.loginId, buf, 200))
            {//获取网关授权码
                gateway.authCode = [NSString stringWithUTF8String:buf];
                
                if (SH_VerifyAuthCode(gateway.loginId, [gateway.authCode UTF8String])) {//验证网关授权码
                    gateway.authorized = YES;
                    
                    NSLog(@"验证授权码成功：%@",gateway.serialNumber);

                    [self queryGatewayState:gateway];
                    
                    if (![gateway isOnline]) {//是否在线
                        errorCode = gateway.disconnectReason;
                        
                    }

                }
                else {
                    gateway.authorized = NO;
                    
                    NSLog(@"验证授权码失败：%@",gateway.serialNumber);
                    
                    errorCode = DisRe_AuthFailed;
                    
                }
            }
            else {
                NSLog(@"获取授权码失败");
                
                errorCode = DisRe_NotAuthMode;
     
            }
            
            
            
            if (errorCode == DisRe_None) {//成功
                [self postStatusChangedNtfOfGateway:gateway];
                
                gateway.status.state = GatewayStatusOnline;
                
                
                gateway.name = name;
                gateway.user = user;
                gateway.pswd = pswd;
                gateway.addr = ip;
                gateway.port = [port intValue];
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    
                    if (successCallback) {
                        
                        successCallback();
                        
                    }
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:EditGatewayNotication object:gateway userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NeedRefreshGatewayKey]];
                    
                });
                
                //获取配置
                dispatch_async(dispatch_get_main_queue(), ^{
                    gateway.shFetchingStep = SHFetchingStepDoing;//正在获取
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:GetGatewayConfigStepNotification object:gateway userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:SHFetchingStepDoing] forKey:GetGatewayConfigStepNotificationKey]];
                });
                
                [self getConfigOfGateway:gateway];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    gateway.shFetchingStep = SHFetchingStepFinished;//获取完成
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:GetGatewayConfigStepNotification object:gateway userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:SHFetchingStepFinished] forKey:GetGatewayConfigStepNotificationKey]];
                });
                
                
                [self getGatewayChangeId:gateway];//获取changeid
                
                [[DBManager defaultManager] updateGateway:gateway];//更新changeid
                
                [self queryDeviceStateOfGateway:gateway];

            }
            else {//失败
                //删除
                SH_DelGateWay(gateway.loginId);
                
                //还原之前的
                gateway.loginId = SH_AddGateWay(preGwInfo);;
                gateway.status.localOnline = preLocal;
                gateway.status.remoteOnline = preRemote;
                gateway.disconnectReason = preError;
                
                
                if (failureCallback) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failureCallback(gateway.disconnectReason);
                    });
                }
            }
            
        });

    }
    else {//只是修改了名称
        
        gateway.name = name;
        gateway.user = user;
        gateway.pswd = pswd;
        gateway.addr = ip;
        gateway.port = [port intValue];
        
        
        [[NSNotificationCenter defaultCenter] postNotificationName:EditGatewayNotication object:gateway userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NeedRefreshGatewayKey]];
        
         [[DBManager defaultManager] updateGateway:gateway];//更新changeid
        
        if (successCallback)
        {
            successCallback();
        }
    }
    
}

//删除网关绑定
- (void)removeGateway:(SHGateway *)gateway timeout:(int)timeout successCallback:(void (^)(void))successCallback failureCallback:(void (^)(int errCode))failureCallback
{
    
    if (gateway) {

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            //等待智能家居接口调用结束再删除，否则会crash
            BOOL bTimeout = YES;
            for (int i = 0; i < timeout; i++)
            {
                if (_shTaskStep == SHTaskStepFinished)
                {
                    bTimeout = NO;
                    break;
                    
                }
                
                
                sleep(1);
            }
            
            if (bTimeout) {
                
                NSLog(@"removeGateway timeout");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failureCallback) {
                        failureCallback(ErrorTimeout);
                    }
                    
                });
                
                return;
            }

       
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (successCallback) {
                    successCallback();
                }
                
            });
            
            NSNotification *ntf = [NSNotification notificationWithName:DelGatewayNotification object:nil userInfo:[NSDictionary dictionaryWithObject:gateway forKey:DelGatewayNotificationKey]];
            [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:ntf waitUntilDone:YES];
            
            
            [self.gatewayList removeObject:gateway];
            [[DBManager defaultManager] removeGateway:gateway];
            
            SH_DelGateWay(gateway.loginId);
            
            //订阅网关报警
            [self subGateway];
            
        });
       
    }
    else {
        failureCallback(-1);
    }

}

- (void)reauthGateway:(SHGateway *)gateway successCallback:(void (^)(void))successCallback failureCallback:(void (^)(NSString *error))failureCallback
{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        //获取网关授权码
        char buf[200] = {0};
        if (0 == SH_GatewayAuth(gateway.loginId, buf, 200))
        {
            gateway.authCode = [NSString stringWithUTF8String:buf];
            
            
            //验证授权码
            if (SH_VerifyAuthCode(gateway.loginId, [gateway.authCode UTF8String])) {
                NSLog(@"认证授权码成功：%@",gateway.serialNumber);
                
            
                [[DBManager defaultManager] updateGateway:gateway];
                
                gateway.authorized = YES;
                
                [self postStatusChangedNtfOfGateway:gateway];
                
                if (successCallback) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successCallback();
                    });
                }
                
                return ;
            }
            
        }
        
        if (failureCallback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureCallback(@"认证失败");
            });
        }
        
        
    });
    
}

//删除网关授权用户
- (void)removeAuthUser:(GatewayUser *)user fromGateway:(SHGateway *)gateway successCallback:(void (^)(void))successCallback failureCallback:(void (^)(void))failureCallback
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if( SH_DelAuth(gateway.loginId, (char *)[user.phoneNumber UTF8String], (char *)[user.meid UTF8String]))
        {
            [gateway.authUserArray removeObject:user];
            
            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback();
                });
            }
        }
        else if (failureCallback)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureCallback();
            });
        }
    });
}


#pragma mark 信息查询

//- (void)queryLeaveMsg:(LeaveMsg *)leaveMsg
//{
//    if (!icrc_handle) {
//        return;
//    }
//
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        ICRC_LEAVE_MESSAGE  *pLeaveMsg = NULL;
//        int msgNum;
//        if (0 == ICRC_Http_GetLeaveMessage(self->icrc_handle, 0, 1, &pLeaveMsg, &msgNum, leaveMsg.msgId))
//        {
//            leaveMsg.fullContent = [NSString stringWithUTF8String:pLeaveMsg->sContent] ;
//            leaveMsg.title = [NSString stringWithUTF8String:pLeaveMsg->sTitle] ;
//            leaveMsg.picPath = [NSString stringWithFormat:@"http://%@:%d%s",self->_serverAddr,self->_serverPort,pLeaveMsg->sPic];
//            leaveMsg.thumbnailPath = [NSString stringWithFormat:@"http://%@:%d%s",self->_serverAddr,self->_serverPort,pLeaveMsg->sPicSmall];
//            leaveMsg.sendTime = pLeaveMsg->iSendTime;
//            leaveMsg.type = pLeaveMsg->iType;
//            leaveMsg.fromId = [NSString stringWithUTF8String:pLeaveMsg->sFromVirutualNo] ;
//            leaveMsg.toId = [NSString stringWithUTF8String:pLeaveMsg->sToVirutualNo] ;
//            
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                
//                [[MessageManager getInstance] addLeaveMsg:leaveMsg];
//                
//                [[NSNotificationCenter defaultCenter] postNotificationName:MQRecvLeaveMsgNotification object:nil userInfo:[NSDictionary dictionaryWithObject:leaveMsg forKey:MQRecvLeaveMsgNotificationKey]];
//                
//            });
//        }
//    });
//}
//
//- (void)queryHomeMsg:(HomeMsg *)homeMsg
//{
//    if (!icrc_handle) {
//        return;
//    }
//    
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        ICRC_HOME_MESSAGE *pHomeMsg = NULL;
//        int msgNum;
//        
//        if ( 0 == ICRC_Http_GetHomeMessage(self->icrc_handle, 0, 1, &pHomeMsg, &msgNum, homeMsg.msgId))
//        {
//            
//            homeMsg.fullContent = [NSString stringWithUTF8String:pHomeMsg->sContent] ;
//            homeMsg.pic = [NSString stringWithFormat:@"http://%@:%d%s",self->_serverAddr,self->_serverPort,pHomeMsg->sPic];
//            homeMsg.thumbnail = [NSString stringWithFormat:@"http://%@:%d%s",self->_serverAddr,self->_serverPort,pHomeMsg->sPicSmall];
//            homeMsg.time = pHomeMsg->iOcurTime;
//            homeMsg.type = pHomeMsg->iHisType;
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[MessageManager getInstance] addHomeMsg:homeMsg];
//                
//                [[NSNotificationCenter defaultCenter] postNotificationName:MQRecvHomeMsgNotification object:nil userInfo:[NSDictionary dictionaryWithObject:homeMsg forKey:MQRecvHomeMsgNotificationKey]];
//            });
//        }
//        
//    });
//}

- (void)queryAlarmMsg:(AlarmRecord *)alarm
{
    if (!icrc_handle) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        ICRC_ALARM_RECORD *pAlarm = NULL;
        int msgNum;
        
        if (0 == ICRC_Http_GetAlarmRecord(self->icrc_handle, 0, 1, &pAlarm, &msgNum, alarm.msgId))
        {
            
            //alarm.alarmTime = pAlarm->iAlarmTime;
            NSDate *date = [NSDate date];
            NSTimeInterval time = [date timeIntervalSince1970];
            alarm.alarmTime = time;
            alarm.recordID = [NSString stringWithUTF8String:pAlarm->sRecordID];
            alarm.alarmStatus = (pAlarm->iAlarmStatus == 1 ? @"Start" : @"Stop");
      
            NSString *devSn = [NSString stringWithUTF8String:pAlarm->sAreaAddr];
            
            SHGateway *gateway = nil;
            SHAlarmZone *alarmZone = nil;
            
            NSString *gatewayVC = [NSString stringWithUTF8String:pAlarm->sDevVirtualCode];
            
            for (SHGateway *tempGateway in self.gatewayList)
            {
                if ([tempGateway.virtualCode isEqualToString:gatewayVC]) {
                    
                    gateway = tempGateway;
                    break;
                }
            }
            
            
            for (SHAlarmZone *tempAlarmZone in gateway.alarmZoneArray)
            {
                if ([tempAlarmZone.serialNumber isEqualToString:devSn]) {
                    alarmZone = tempAlarmZone;
                    break;
                }
            }
            
            if (alarmZone) {
                NSString *alarmType = alarmZone.sensorMethod;
                alarm.channelName = alarmZone.name;
                
                NSString *strType = nil;
                if ([alarmType isEqualToString:@"Infrared"]) {
                    strType = @"红外线";
                }
                else if ([alarmType isEqualToString:@"DoorMagnetism"]) {
                    strType = @"门磁";
                }
                else if ([alarmType isEqualToString:@"PassiveInfrared"]) {
                    strType = @"被动红外";
                }
                else if ([alarmType isEqualToString:@"GasSensor"]) {
                    strType = @"气感";
                }
                else if ([alarmType isEqualToString:@"SmokingSensor"]) {
                    strType = @"烟感";
                }
                else if ([alarmType isEqualToString:@"WaterSensor"]) {
                    strType = @"水感";
                }
                else if ([alarmType isEqualToString:@"ActiveInfrared"]) {
                    strType = @"主动红外";
                }
                else if ([alarmType isEqualToString:@"CallButton"]) {
                    strType = @"呼叫按钮";
                }
                else if ([alarmType isEqualToString:@"Emergency"]) {
                    strType = @"紧急";
                }
                else if ([alarmType isEqualToString:@"OtherSensor"]) {
                    strType = @"其他";
                }
                else if ([alarmType isEqualToString:@"UrgencyButton"]) {
                    strType = @"紧急按钮";
                }
                else if ([alarmType isEqualToString:@"Steal"]) {
                    strType = @"盗警";
                }
                else if ([alarmType isEqualToString:@"Perimeter"]) {
                    strType = @"周界";
                }
                
                alarm.alarmType = strType;
                
                if ([gateway.ipcArray count] > 0) {
                    SHVideoDevice *ipc = [gateway.ipcArray objectAtIndex:0];
                    alarm.videoAddr = ipc.videoUrl;
                    alarm.pubVideoAddr = ipc.pubVideoUrl;
                }
                else {
                    alarm.videoAddr = @"";
                    alarm.pubVideoAddr = @"";
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [[MessageManager getInstance] addAlarmMsg:alarm];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:OnAlarmNotification object:nil userInfo:[NSDictionary dictionaryWithObject:alarm forKey:OnAlarmNotificationKey]];
                    
                });
            }
            
           
        }
    });
}

//- (void)queryPropertyMsgs
//{
//    if (!icrc_handle) {
//        return;
//    }
//    
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        ICRC_PROPERTY_MESSAGE *pPropertyMsg = NULL;
//        int msgNum;
//        
//        if (0 == ICRC_Http_GetPropertyMessage(self->icrc_handle, 0, 20, &pPropertyMsg, &msgNum, 0))
//        {
//            NSMutableArray *msgArray = [NSMutableArray arrayWithCapacity:msgNum];
//            for (int i=0 ; i<msgNum; i++)
//            {
//                PropertyMsg *propertyMsg = [[PropertyMsg alloc] init];
//                propertyMsg.msgId = pPropertyMsg[i].iInfoId;
//                propertyMsg.fullContent = [NSString stringWithUTF8String:pPropertyMsg->sContent] ;
//                propertyMsg.pic = [NSString stringWithFormat:@"http://%@:%d%s",self->_serverAddr,self->_serverPort,pPropertyMsg->sPicUrl];
//                propertyMsg.thumbnail = [NSString stringWithFormat:@"http://%@:%d%s",self->_serverAddr,self->_serverPort,pPropertyMsg->sPicUrlSmall];
//                propertyMsg.title = [NSString stringWithUTF8String:pPropertyMsg->sTitle] ;
//                propertyMsg.time = pPropertyMsg->iSendTime;
//                propertyMsg.type = pPropertyMsg->iInfoType;
//                
//                propertyMsg.msgStatus = MessageStatusRead;
//
//
//                [msgArray addObject:propertyMsg];
//            }
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[MessageManager getInstance] addPropertyMsgs:msgArray];
//                
//                [[NSNotificationCenter defaultCenter] postNotificationName:queryPropertyMsgNotification object:nil userInfo:nil];
//                
//            });
//            
//        }
//    });
//}
//
//
//- (void)queryPropertyMsg:(PropertyMsg *)propertyMsg
//{
//    if (!icrc_handle) {
//        return;
//    }
//    
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        ICRC_PROPERTY_MESSAGE *pPropertyMsg = NULL;
//        int msgNum;
//        
//        if (0 == ICRC_Http_GetPropertyMessage(self->icrc_handle, 0, 1, &pPropertyMsg, &msgNum, propertyMsg.msgId))
//        {
//            propertyMsg.fullContent = [NSString stringWithUTF8String:pPropertyMsg->sContent] ;
//            propertyMsg.pic = [NSString stringWithFormat:@"http://%@:%d%s",self->_serverAddr,self->_serverPort,pPropertyMsg->sPicUrl];
//            propertyMsg.thumbnail = [NSString stringWithFormat:@"http://%@:%d%s",self->_serverAddr,self->_serverPort,pPropertyMsg->sPicUrlSmall];
//            propertyMsg.title = [NSString stringWithUTF8String:pPropertyMsg->sTitle] ;
//            propertyMsg.time = pPropertyMsg->iSendTime;
//            propertyMsg.type = pPropertyMsg->iInfoType;
//            
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[MessageManager getInstance] addPropertyMsg:propertyMsg];
//                
//                [[NSNotificationCenter defaultCenter] postNotificationName:MQRecvPropertyMsgNotification object:[NSNumber numberWithInt:2] userInfo:[NSDictionary dictionaryWithObject:propertyMsg forKey:MQRecvPropertyMsgNotificationKey]];
//                
//            });
//        }
//    });
//    
//}





- (void)queryCommunityMsg:(CommunityMsg *)comMsg
{
    if (!icrc_handle) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        ICRC_COMMUNITY_MESSAGE *pCommMsg = NULL;
        int msgNum;
        int ret = ICRC_Http_GetCommunityMessage(self->icrc_handle, 0, 1, &pCommMsg, &msgNum, comMsg.msgId);
        
        if (0 == ret)
        {
            comMsg.fullContent = [NSString stringWithUTF8String:pCommMsg->sContent] ;
            comMsg.pic = [NSString stringWithFormat:@"http://%@:%d%s",self->_serverAddr,self->_serverPort,pCommMsg->sPicUrl];
            comMsg.thumbnail = [NSString stringWithFormat:@"http://%@:%d%s",self->_serverAddr,self->_serverPort,pCommMsg->sPicUrlSmall];
            comMsg.title = [NSString stringWithUTF8String:pCommMsg->sTitle] ;
            comMsg.time = pCommMsg->iSendTime;
            comMsg.type = pCommMsg->iInfoType;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[MessageManager getInstance] addCommMsg:comMsg];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:MQRecvCommunityMsgNotification object:[NSNumber numberWithInt:2] userInfo:[NSDictionary dictionaryWithObject:comMsg forKey:MQRecvCommunityMsgNotificationKey]];
                
            });
        }
    });
    
}

#pragma mark 回调函数


//ip 搜索回调
void OnIPSearch(char *pDeviceInfo,void *pUser)
{
    NSLog(@"OnIPSearch %s",pDeviceInfo);
    
    NetAPIClient *client = (__bridge NetAPIClient*)pUser;
    
    NSString *deviceInfo = [NSString stringWithUTF8String:pDeviceInfo];
    
    [client notifyIpSearchInfo:deviceInfo];
}

void OnEventNotify(unsigned int hLoginID,emEventType type,char * eventInfo,void *pUser)
{
  
    NetAPIClient *client = (__bridge NetAPIClient *)pUser;
    
    NSError *erro;
    NSDictionary *dic = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:[[NSString stringWithUTF8String:eventInfo] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&erro];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (type == emDeviceState) {

            [client onEventCallBack:hLoginID params:dic];
            
        }
        else if (type == emAlarm) {
            [client onAlarmCallBack:hLoginID params:dic];
        }
        else if (type == emDownFile) {
            [client onFileDownloadCallBack:hLoginID params:dic];
        }
        else if (type == emRequestOpenDoor) {
            [client onCallRedirectCallBack:hLoginID params:dic];
        }
    });
    
    
}

void OnDisconnect(unsigned int hLoginID,emWorkMode mode,
                  char *pchServIP,int nServPort,int status,int reason,void *pUser)
{
    NSLog(@"SDK OnDisconnect hLoginID:%d mode:%d ip:%s port:%d status:%d reason:%d",hLoginID,mode,pchServIP,nServPort,status,reason);
    
      NetAPIClient *client = (__bridge NetAPIClient*)pUser;
    
     dispatch_async(dispatch_get_main_queue(), ^{
         
         [client onConnectStatusCallBack:hLoginID workMode:mode status:status reason:reason];
     });
}


static int OnCbStack(void *pUser,MQ_HANDLE hInst,MQ_HANDLE hSessionId,LPMQ_CALLBACK_INFO pcbInfo)
{
    
    NSLog(@"OnCbStack info type %d", pcbInfo->iType);

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MQConnectStatusNotification object:@"Disconnected"];
    });
    
    NetAPIClient *client = (__bridge NetAPIClient*)pUser;
    
    client.MQConnected = NO;
    
    if (emMqMsgDisConnect == pcbInfo->iType) {//mq 断线重连
        NSLog(@"MQ 断线");
        
        [client connectMQ];
    }
    
    
    return MQ_NO_ERROR;
}



static int OnCbStackEx(void *pUser,MQ_HANDLE hInst,MQ_HANDLE hSessionId,char *pTopic,char *pJmsType,char *pMsg,int iMsgLen)
{
    
    NetAPIClient *user = (__bridge NetAPIClient*)pUser;
    
    NSString *jsonStr = [NSString stringWithUTF8String:pMsg];
    
    NSError *err = nil;
    NSDictionary *dic = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&err];
    NSLog(@"OnCbStackEx: %@",[dic description]);
    
    NSString *title = [dic objectForKey:@"title"];
    NSString *fullContent = [dic objectForKey:@"fullContent"];
    NSString *ring = [dic objectForKey:@"ring"];
    
    NSDictionary *json = [dic objectForKey:@"json"];
    
    NSNumber *type = [json objectForKey:@"type"];
    NSString *strtype = [json objectForKey:@"type"];
    NSNumber *ack = [json objectForKey:@"ack"];//应答 0 不需要 1需要
    
    NSInteger t = [type intValue];
    long msgId = [(NSNumber*)[json objectForKey:@"id"] longValue];
    
    
    
    
    switch (t) {
        case 1://家庭信息
        {
            
            CommunityMsg *msg = [[CommunityMsg alloc] init];
            msg.msgId = msgId;
    
            [user queryCommunityMsg:msg];
            
        }
            
            break;
        case 2://报警信息
        {
            
            AlarmRecord *msg = [[AlarmRecord alloc] init];
            msg.msgId = msgId;
    
            [user queryAlarmMsg:msg];
        }
            
            break;
 
            
        default:
            break;
    }
    
    
    return 1;
}



bool OnServerDisconnect(void *icrc_handle, int state, void *pUserData)
{
    NSLog(@"与服务器连接断开");
    
    return true;
}



@end
