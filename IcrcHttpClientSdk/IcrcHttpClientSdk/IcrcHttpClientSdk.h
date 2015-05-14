#ifndef _ICRCCLIENTSDK_H
#define _ICRCCLIENTSDK_H

#ifdef ICRCHTTPCLIENTSDK_EXPORTS
#	 define ICRC_HTTPCLIENT_API __declspec(dllexport)
#else
#	 define ICRC_HTTPCLIENT_API __declspec(dllimport)
#endif

#define IN     //input parameter
#define OUT    //output parameter

enum EM_ICRC_ERROR_TYPE
{
    ICRC_ERROR_OK = 0,	//执行正确
    ICRC_ERROR_JSON_PARSE_FAIL = 150,	//解析json格式异常
    ICRC_ERROR_HTTP_HEAD_INCORRECT = 151,  //解析http的header的值异常
    ICRC_ERROR_LOGIN_ABNORMAL = 200, //登录异常
    ICRC_ERROR_USER_NOT_EXIST = 201, //用户名称不存在
    ICRC_ERROR_PASSWORD_INCORRECT = 202, //密码错误
    ICRC_ERROR_LOGIN_EXPIRED = 203, //未登录或者登录时间已经过期
    ICRC_ERROR_USER_HAS_LOGIN = 204, //用户已经登录
    ICRC_ERROR_TRIAL_EXPIRED = 205, //试用期满
    ICRC_ERROR_LOW_VERSION = 208, //客户端版本过低
    ICRC_ERROR_NORIGHT_ACCESS = 209, //权限不足，非法访问
    ICRC_ERROR_ACCOUNT_NOACTIVE = 210, //此用户未激活
    ICRC_ERROR_SERVER_ABNORMAL = 500, //服务器异常
    ICRC_ERROR_METHOD_UNSUPPORT = 501, //方法未实现
    ICRC_ERROR_METHOD_INVALID = 502, //method值无效
    ICRC_ERROR_ACTION_INVALID = 504, //action值无效
    ICRC_ERROR_MISS_PARAM = 506, //请求中缺少一个必要的参数
    ICRC_ERROR_VALUE_OUT_RANGE = 512, //请求参数值范围错误
    ICRC_ERROR_PHONENUMBER_HAS_REGISTER = 810, //手机号码已经被注册
    ICRC_ERROR_PHONENUMBER_INVALID = 811, //手机号码非法
    ICRC_ERROR_ASK_ACTIVECODE_TOO_OFTEN = 812, //太过频繁要求发送激活码
    ICRC_ERROR_MESSAGE_SEND_FAIL = 813, //发送短信失败
    ICRC_ERROR_PHONENUMBER_UNACTIVE = 814, //此手机号码未处于激活状态
    ICRC_ERROR_SOMECODE_UNNORMAL = 815, //激活码或验证码错误或者过期
    ICRC_ERROR_PHONENUMBER_ALREADY_ACTIVE = 816, //此手机号码已经激活
    ICRC_ERROR_PHONENUMBER_NOT_EXIST = 817, //此手机号码不存在
    ICRC_ERROR_EMAIL_HAS_REGISTER = 818, //邮箱已经被注册
    ICRC_ERROR_EMAIL_INVALID = 819, //非法邮箱
    ICRC_ERROR_EMAIL_SEND_FAIL = 820, //发送邮件失败
    ICRC_ERROR_EMAIL_NOT_EXIST = 821, //邮箱不存在
    ICRC_ERROR_USR_EMAIL_NOT_MATCH = 822, //用户和邮箱不匹配
    ICRC_ERROR_ASK_EMAIL_TOO_OFTEN = 823, //太过频繁要求发送邮件
    ICRC_ERROR_OTHER_FAULT = 900, //其他错误
    //-----以上错误码由服务端返回-----
    ICRC_ERROR_HTTP_NO_RESPONSE, //服务器无响应
    ICRC_ERROR_HTTP_CONTENT_EMPTY, //http内容为空
    ICRC_ERROR_HTTP_CONTENT_PARSE_FAIL, //http返回内容无法用json解析
    ICRC_ERROR_HTTP_PARAM_NOT_FOUND, //缺少参数
    ICRC_ERROR_HTTP_SERV_NOT_FOUND, //没有找到指定的服务
    ICRC_ERROR_CREATE_THREAD_FAIL,  //创建线程失败
    ICRC_ERROR_INVALID_HANDLE, //无效的句柄
    ICRC_ERROR_TIMEOUT, //超时
};

typedef struct
{
    char sCallId[64];
    char sLastVersion[256]; //最新的客户端版本
    char sUpdateUrl[256];   //软件版本升级的URL
    char sToken[64];        //手机端上次在服务端注册的toke值，如果没有，则此值为空
    char sVirtualCode[32];  //用户虚号
    char sMqBroker[256];    //MQ地址
    char sPushAddr[256];    //推送地址
    char sUpnpServCode[32]; //upnp服务器虚号
    char sUpnpAddr[256];    //upnp服务ip
    int  iUpnpPort;         //upnp服务端口
    int  iEmailCheck;       //邮箱是否已经验证
    char sPhone[32];        //电话号码
    char sCity[64];         //城市
    char sISP[64];          //运营商
    char sAuthCodeText[256]; //半明文，中间4位用*表示
} ICRC_CONNECT_INFO;

typedef struct
{
    char sIp[20]; //登录服务器的ip地址
    int  iPort;   //登录服务器的端口
} ICRC_REDIRECT_INFO;

typedef struct
{
    char sVersionName[256];    //最新的客户端版本名称
    char sVersionDesc[1024];   //版本更新说明
    char sMinVersionName[256]; //最小支持版本
    char sUpdateurl[256];      //软件版本升级的URL
    char sUpdateurl2[256];     //软件版本升级的URL2
    char sUpdateurl3[256];     //软件版本升级的URL3
    char sUpdateurl4[256];     //软件版本升级的URL4
    char sUpdateurl5[256];     //软件版本升级的URL5
    int  iPublishTime;         //发布日期
} ICRC_VERSION_INFO;

typedef struct
{
    char sVirtualCode[32]; //设备虚号
    char sDevName[64];     //设备名称
    char sPasswd[32];      //密码
    char sNetAddr[20];     //网路ip
    int  iNetPort;         //端口
    int  iDevType;         //设备类型, 0:室内机(数字), 20：智能家居网关设备 21大网关
    char sDevTypeAddtion[256]; // 类型补充
    char sPosition[256];   //位置
    char sParam1[64];      //UDN值
    char sCommunityName[256]; //小区名称
    int  iStatus;          //状态
    char sSN[64];          //序列号
    char sAddIP[64];       //外部IP
    char sCity[64];        //城市
    char sISP[64];         //运营商
    int  iGValue;          //G值
    char sARMSNetwork[64]; //ARMS访问地址
    int  iARMSPort;        //ARMS访问端口
} ICRC_SMARTHOME_DEVICE_DETAIL;

typedef struct
{
    char sVirtualCode[32]; //设备虚号
    int  status;
} ICRC_SMARTHOME_DEVICE_STATUS;

typedef struct
{
    int  iAlarmId;      //报警id
    int  iAlarmTime;    //报警时间
    int  iAlarmStatus;  //报警状态
    char sAlarmType[64];//报警类型名称
    char sDevName[64];  //设备名称
    char sAreaAddr[256];//设备地址
    char sDevVirtualCode[256];//设备虚号
    char sRecordID[256];
} ICRC_ALARM_RECORD;

typedef struct
{
    int  iHisId;        //记录id
    int  iHisType;      //记录类型1:刷卡记录2:对讲记录3:报警记录4:过车记录
    int  iOcurTime;     //发生时间
    char sReVirtualCode[32]; //关联设备虚号
    char sContent[512]; //内容
    char sPic[256];     //图片
    char sPicSmall[256];//缩略图1
} ICRC_HOME_MESSAGE;

typedef struct
{
    int  iInfoId;      //记录id
    int  iInfoType;    //类型2:健康消息3:娱乐消息4:购物消息5:餐饮消息6:旅游消息
    int  iSendTime;    //发送时间
    char sTitle[256];  //主题
    char sContent[512];//内容
    char sPicUrl[256]; //图片
    char sPicUrlSmall[256]; //缩略图
    char sDes[256];    //备注
} ICRC_COMMUNITY_MESSAGE;

typedef ICRC_COMMUNITY_MESSAGE ICRC_PROPERTY_MESSAGE;

typedef struct
{
    int  iMsgId;     //主键
    int  iType;      //类型 1文字短信2图片短信20留言
    int  iSendTime;  //发送时间
    char sFromVirutualNo[32]; //发送者虚号
    char sToVirutualNo[32];   //接收者者虚号
    char sTitle[256];     //标题 只需要填语音时长(秒)
    char sContent[512];  //内容
    char sPic[256];      //图片地址
    char sPicSmall[256]; //图片缩略图地址
} ICRC_LEAVE_MESSAGE;

typedef struct
{
    int  iVerify;        //是否已经通过验证
    int  iType;          //类型
    char sFriVirtualCode[32]; //好友虚号
    char sFriName[64];   //好友昵称
    char sPic[256];      //头像
} ICRC_FRIEND_INFO;

typedef struct
{
    int  iFriend;  //是否已经是好友 0不是 1是
    int  iType;    //类型
    char sFriVirtualCode[32]; //好友虚号
    char sFriName[64]; //昵称
} ICRC_FRIEND_PREVIEW;

typedef struct
{
    char sPic[256];      //图片地址
    char sPicSmall[256]; //图片缩略图地址
} ICRC_UPLOAD_RESULT;

typedef struct
{
    char sDevVirtualCode[32]; //设备虚号
    int  iDevChan;      //设备通道号
    char sUserName[64]; //用户
    char sPasswd[64];   //密码
    char sNetwork[20];  //网路ip
    int  iNetPort;      //端口
    int  iDevType;      //设备类型
} ICRC_VIDEO_DEVICE;

// state, 1:断开连接 2:重连成功 3:客户端在其它地方登录,此时回调函数返回true将使用强制登录，返回false继续尝试普通登录
typedef bool (*fIcrcDisConnect)(void *icrc_handle, int state, void *pUserData);

/************************** 登录ICRC ***************************/
ICRC_HTTPCLIENT_API int ICRC_Http_Login(
                                        IN  void**      icrc_handle, //句柄(传入地址，由内部分配空间)
                                        IN  const char* sIpAddr,     //服务器ip地址
                                        IN  int         iPort,       //服务器端口
                                        IN  const char* sUserName,   //用户名称
                                        IN  const char* sPassWord,   //用户密码
                                        IN  int         iClientType, //客户端类型。1 Android; 2苹果
                                        IN  int         iNetType,    //网路类型。1局域网，2公网
                                        IN  int         iForce,      //0:普通登录，1:强制登录
                                        IN  const char* sMeid,       //MEID码
                                        IN  const char* sVersion,    //客户端版本号
                                        OUT ICRC_CONNECT_INFO *pConInfo,  //服务器返回信息
                                        IN  fIcrcDisConnect cbDisconnect, //服务器断线回调通知
                                        IN  void*       pUserData    //用户数据
);

/************************** 登出ICRC ***************************/
ICRC_HTTPCLIENT_API int ICRC_Http_Logout(
                                         IN  void*       icrc_handle
                                         );

/******************* 注册推送服务的token值 *********************/
ICRC_HTTPCLIENT_API int ICRC_Http_RegisterToken(
                                                IN  void*       icrc_handle, //句柄
                                                IN  const char* sToken //token值
);

/************ 用于释放获取设备列表和状态时申请的内存 ***********/
ICRC_HTTPCLIENT_API int ICRC_Http_FreeMemory(
                                             IN  void*       pMemAddr //内存地址
);

/******************* 获取智能家居设备列表 **********************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetDeviceList(
                                                IN  void*       icrc_handle, //句柄
                                                IN  int         start_index, //起始索引号, 从0开始，最多一次查询50条，例如start=0,end=50表示查前50条
                                                IN  int         end_index,   //结束索引号
                                                OUT ICRC_SMARTHOME_DEVICE_DETAIL **ppDeviceList, //设备详细信息
                                                OUT int*        numDevs, //设备数量
                                                IN  const char* sVirtualCode //虚号为空时查询所有设备
);

/******************* 获取智能家居设备状态 **********************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetDeviceState(
                                                 IN  void*       icrc_handle, //句柄
                                                 IN  int         start_index, //起始索引号
                                                 IN  int         end_index,   //结束索引号
                                                 OUT ICRC_SMARTHOME_DEVICE_STATUS **ppDeviceStatus, //状态(0:不在线,1:在线,2:检测中)
                                                 OUT int*        numDevs,     //设备数量
                                                 IN  const char* sVirtualCode //虚号为空时查询所有设备
);

/****************** 查询当前用户的报警记录 *********************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetAlarmRecord(
                                                 IN  void*       icrc_handle, //句柄
                                                 IN  int         start_index, //起始索引号
                                                 IN  int         end_index,   //结束索引号
                                                 OUT ICRC_ALARM_RECORD **ppAlarmRecord, //报警记录
                                                 OUT int*        numRecords, //报警数量
                                                 IN  int         iAlarmId    // id=0查询所有报警记录
);

/****************** 查询当前用户的家庭信息 *********************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetHomeMessage(
                                                 IN  void*       icrc_handle, //句柄
                                                 IN  int         start_index, //起始索引号
                                                 IN  int         end_index,   //结束索引号
                                                 OUT ICRC_HOME_MESSAGE **ppHomeMessage, //家庭信息
                                                 OUT int*        numMessages, //信息数量
                                                 IN  int         iHisId       //id=0查询所有信息
);

/****************** 查询当前用户的社区信息 *********************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetCommunityMessage(
                                                      IN  void*       icrc_handle, //句柄
                                                      IN  int         start_index, //起始索引号
                                                      IN  int         end_index,   //结束索引号
                                                      OUT ICRC_COMMUNITY_MESSAGE **ppCommunityMessage, //社区信息
                                                      OUT int*        numMessages, //信息数量
                                                      IN  int         iInfoId      //id=0查询所有信息
);

/****************** 查询当前用户的物业信息 *********************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetPropertyMessage(
                                                     IN  void*       icrc_handle, //句柄
                                                     IN  int         start_index, //起始索引号
                                                     IN  int         end_index,   //结束索引号
                                                     OUT ICRC_PROPERTY_MESSAGE **ppPropertyMessage, //物业信息
                                                     OUT int*        numMessages, //信息数量
                                                     IN  int         iInfoId      //id=0查询所有信息
);

/*************** 查询当前用户的留影留言信息 ********************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetLeaveMessage(
                                                  IN  void*       icrc_handle, //句柄
                                                  IN  int         start_index, //起始索引号
                                                  IN  int         end_index,   //结束索引号
                                                  OUT ICRC_LEAVE_MESSAGE **ppLeaveMessage, //留言信息
                                                  OUT int*        numMessages, //信息数量
                                                  IN  int         iMsgId       //id=0查询所有信息
);

/*************** 添加当前用户的留言留影信息 ********************/
ICRC_HTTPCLIENT_API int ICRC_Http_WriteLeaveMessage(
                                                    IN  void*       icrc_handle, //句柄
                                                    OUT ICRC_LEAVE_MESSAGE *pLeaveMessage //留言信息，iMsgId,iSendTime,sFromVirutualNo不用填
);

/***************** 查询当前用户好友列表 ************************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetFriendInfo(
                                                IN  void*       icrc_handle, //句柄
                                                IN  int         start_index, //起始索引号
                                                IN  int         end_index,   //结束索引号
                                                OUT ICRC_FRIEND_INFO **ppFriendInfo, //好友信息
                                                OUT int*        numFriends   //
);

/**************** 查询预备添加好友的信息 ***********************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetFriendPreview(
                                                   IN  void*       icrc_handle,     //句柄
                                                   IN  const char* sFriVirtualCode, //好友虚号
                                                   OUT ICRC_FRIEND_PREVIEW *pFriendPreview //好友信息
);

/****************** 当前用户添加好友 ***************************/
ICRC_HTTPCLIENT_API int ICRC_Http_AddFriend(
                                            IN  void*       icrc_handle,     //句柄
                                            IN  const char* sFriVirtualCode, //好友虚号
                                            IN  int         iType            //类型 1设备 2用户
);

/***************** 删除当前用户添加好友 ************************/
ICRC_HTTPCLIENT_API int ICRC_Http_DelFriend(
                                            IN  void*       icrc_handle,    //句柄
                                            IN  const char* sFriVirtualCode //好友虚号
);

/***************** 修改当前用户好友信息 ************************/
ICRC_HTTPCLIENT_API int ICRC_Http_EditFriend(
                                             IN  void*       icrc_handle,     //句柄
                                             IN  const char* sFriVirtualCode, //好友虚号
                                             IN  const char* sFriName         //昵称
);

/****************** 上传留言留影信息 ***************************/
ICRC_HTTPCLIENT_API int ICRC_Http_Upload(
                                         IN  void*       icrc_handle, //句柄
                                         IN  int         type,        // 2图片短信 20留言短信
                                         IN  const char* extension,   //文件格式(扩展名)
                                         IN  const char* bytestream,  //二进制数据
                                         IN  int         bytelen,     //数据长度
                                         OUT ICRC_UPLOAD_RESULT *pUploadResult //上传结果
);

/****************** 获取视频设备信息 ***************************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetVideoDevice(
                                                 IN  void*       icrc_handle, //句柄
                                                 OUT ICRC_VIDEO_DEVICE **ppVideoDevice, //设备列表
                                                 OUT int*        numDevs //设备数量
);

/******************** 重定向服务 *******************************/
ICRC_HTTPCLIENT_API int ICRC_Http_Redirect(
                                           IN  const char* domain, //域名"www.dahuayun.com"
                                           IN unsigned int timeout, //超时时间ms
                                           OUT ICRC_REDIRECT_INFO *pRedirect //登录服务器信息
);

/***************** 检查最新的版本信息 **************************/
ICRC_HTTPCLIENT_API int ICRC_Http_CheckVersion(
                                               IN  const char* sIpAddr,     //服务器ip地址
                                               IN  int         iPort,       //服务器端口
                                               IN  int         iClientType, //客户端类型。1 Android; 2苹果
                                               OUT ICRC_VERSION_INFO *pVersion //最新版本的信息
);

/*************** 注册账号, 会发送邮箱验证邮件 ******************/
ICRC_HTTPCLIENT_API int ICRC_Http_RegisterAccount(
                                                  IN  const char* sIpAddr,     //服务器ip地址
                                                  IN  int         iPort,       //服务器端口
                                                  IN  const char* sUserName,   //手机号码
                                                  IN  const char* sEmail,      //邮箱
                                                  IN  const char* sPassWord,   //登录密码
                                                  IN  const char* sAuthCode,   //身份识别码
                                                  IN  const char* sAuthCodeText, //半明文，中间4位用*表示
                                                  IN  const char* sPhone,      //手机号码(可选)
                                                  IN  const char* sActiveCode  //激活码(可选)
);

/******************** 通过邮箱找回密码 *************************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetBackPassword(
                                                  IN  const char* sIpAddr,     //服务器ip地址
                                                  IN  int         iPort,       //服务器端口
                                                  IN  const char* sUserName,   //手机号码
                                                  IN  const char* sEmail       //邮箱
);

/*********************** 修改密码 ******************************/
ICRC_HTTPCLIENT_API int ICRC_Http_ChangePassword(
                                                 IN  void*       icrc_handle, //句柄
                                                 IN  const char* sPassWord,   //新密码
                                                 IN  const char* sOldPassWord //旧密码
);

/******************** 发送邮箱验证邮件 *************************/
ICRC_HTTPCLIENT_API int ICRC_Http_EmailVerify(
                                              IN  void*       icrc_handle  //句柄
);

/*************** 修改邮箱地址，发送邮箱验证邮件 ****************/
ICRC_HTTPCLIENT_API int ICRC_Http_ChangeEmail(
                                              IN  void*       icrc_handle, //句柄
                                              IN  const char* sEmail       //邮箱
);

/******************** 查询SN获取设备的信息 *********************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetSNDevice(
                                              IN  void*       icrc_handle, //句柄
                                              IN  const char* sSN,      //设备序列号，不能为空
                                              OUT ICRC_SMARTHOME_DEVICE_DETAIL *pSnDevice //设备详细信息
);

/*********************** 删除绑定设备 **************************/
ICRC_HTTPCLIENT_API int ICRC_Http_UnbindDevice(
                                               IN  void*       icrc_handle, //句柄
                                               IN  const char* sDevVirtualCode  //设备虚号
);

/*********************** 密码重置申请 **************************/
ICRC_HTTPCLIENT_API int ICRC_Http_PasswordRestorePrepare(
                                                         IN	const char* sIpAddr,     //服务器ip地址
                                                         IN	int         iPort,       //服务器端口
                                                         IN	const char* sUserName,   //用户名称
                                                         OUT char*       sAuthCodeSeed, //身份识别码种子
                                                         OUT char*       sAuthCodeSeedIndex, //种子编号
                                                         OUT char*       sSmsNum  //短信发送号码
);

/************************ 密码重置 *****************************/
ICRC_HTTPCLIENT_API int ICRC_Http_PasswordRestore(
                                                  IN	const char* sIpAddr,     //服务器ip地址
                                                  IN	int         iPort,       //服务器端口
                                                  IN	const char* sUserName, //用户名称
                                                  IN	const char*	sPassWordNew //新密码
);

/********************** 补充身份识别码 *************************/
ICRC_HTTPCLIENT_API int ICRC_Http_PatchAuthCode(
                                                IN  const char* sIpAddr,     //服务器ip地址
                                                IN  int         iPort,       //服务器端口
                                                IN  const char* sUserName, //用户名称
                                                IN  const char* sPassWord, //登录密码
                                                IN  const char* sAuthCode  //身份识别码
);

/********************** 添加用户订阅网关 ***********************/
ICRC_HTTPCLIENT_API int ICRC_Http_SubscribeGateway(
                                                   IN  void*       icrc_handle, //句柄
                                                   IN	const char* sGwVirtCode[], //网关虚号列表
                                                   IN unsigned int iCount   //订阅网关的数量
);

/************************* 查询callid **************************/
ICRC_HTTPCLIENT_API int ICRC_Http_CheckCallID(
                                              IN  void*       icrc_handle //句柄
);

#endif
