//
//  Header.h
//  eLife
//
//  Created by mac on 14-5-22.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "User.h"

#ifndef eLife_PublicDefine_h
#define eLife_PublicDefine_h

#define FTP_ENCODING NSUTF8StringEncoding

//#define FTP_ENCODING 0x80000632

#define BABYSITTER @"babaysitter" //儿童看护
#define COMMONUSER @"commonuse"  //常用


#define INVALID_INDEX -1

#define PANEL_CONFIG @"PanelConfig"
#define KEY_INDEX @"key_index"

#define STYLE_DIR @"style"
#define PANEL_DIR @"panel"
#define THUMBNAIL @"thumbnail.png"

//远程模式
#define KEY_IP_PORT  @"com.zwan.elife.ipport"
#define KEY_IP  @"com.zwan.elife.ip"
#define KEY_PORT  @"com.zwan.elife.port"

//本地模式
#define KEY_IP_PORT_LOCAL  @"com.zwan.elife.ipport.local"
#define KEY_IP_LOCAL  @"com.zwan.elife.ip.local"
#define KEY_PORT_LOCAL  @"com.zwan.elife.port.local"

#define CurrentPeriodKey @"CurrentPeriodKey"
#define PriorPeriodKey @"PriorPeriodKey"

#define VOICE_DIR_NAME @"Voices"

#define IMAGE_DIR_NAME @"Images"

#define VOICE_FILE_SUFFIX @"pcm"
#define IMAGE_FILE_SUFFIX @"jpg"

#define REFRESH_HIDE_DELAY 0.15


//用户目录
#define USERDIR [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[User currentUser].name]



#define CLIENT_VERSION @"1.0.2" //客户端当前版本号

#define APPID @"986634147" //iTunes connect应用id

#define APP_URL @"http://itunes.apple.com/cn/app/id986634147"




#endif
