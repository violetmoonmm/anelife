//
//  main.m
//  eLife
//
//  Created by mac on 14-3-14.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

#include <unistd.h>
#include <signal.h>
#include <setjmp.h>
#include <time.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>


//static sigjmp_buf jmpbuf;
//static void alarm_func(int param)
//{
//    siglongjmp(jmpbuf, 1);
//}
//static struct hostent *gngethostbyname(char *HostName, int timeout)
//{
//    struct hostent *lpHostEnt;
//    signal(SIGALRM, alarm_func);
//    if (sigsetjmp(jmpbuf,1) != 0)
//    {
//        alarm(0);
//        signal(SIGALRM, SIG_IGN);
//        return NULL;
//    }
//    alarm(timeout);
//    lpHostEnt = gethostbyname(HostName);
//    signal(SIGALRM, SIG_IGN);
//    return lpHostEnt;
//}


void had(int sig)
{
    NSLog(@"sig");
}




int main(int argc, char * argv[])
{
#if defined(DEBUG)||defined(_DEBUG)
    NSLog(@"debug模式");
#endif
    
    signal(SIGPIPE,SIG_IGN);

    @autoreleasepool {

        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
