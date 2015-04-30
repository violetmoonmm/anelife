#ifndef MQSTACKDEF_H
#define MQSTACKDEF_H

#if defined(_MSC_VER) && (_MSC_VER >= 1200)
# pragma once
#endif

#ifdef __cplusplus
extern "C"
{
#endif
    
    //VC6版本c++不支持long long类型
    #if defined(_MSC_VER) && (_MSC_VER <= 1200)
        typedef __int64 INT64_t;
#else
    typedef long long INT64_t;
#endif
    
    //错误码
    typedef enum MQErrorCode_t
    {
        MQ_NO_ERROR                         = 0,    //成功
        MQ_ERROR_UNKNOWN                    = -1,   //未知错误
        MQ_ERROR_NOT_IMPL                   = -2,   //没有实现
        MQ_ERROR_OUT_OF_MEMORY              = -3,   //没有足够的内存
        MQ_ERROR_BAD_PARAMETER              = -4,   //参数错误
        MQ_ERROR_INSTANCE_NON_EXIST         = -5,   //实例不存在
        MQ_ERROR_UNKNOWN_ENDPOINT           = -6    //未知终端类型
    }MQErrorCode;
    
    //句柄定义
    typedef unsigned int MQ_HANDLE;
#define MQ_INVALID_HANDLE 0
    
    //设备类型
    typedef enum MQDeviceType_t
    {
        MQ_DEVICE_UNKNOWN      =  0,           //未知设备
        MQ_DEVICE_VTS          =  1,           //VTS
        MQ_DEVICE_VTMC         =  2,           //VTMC
        MQ_DEVICE_WSC          =  3,           //WSC
        MQ_DEVICE_EEC          =  4,           //出入口管理设备
        
        MQ_DEVICE_SP           =  5,           //报警短信平台
        MQ_DEVICE_VTHPROXY     =  6,           //VTH代理
        
        MQ_DEVICE_ACMS         =  7,            //ACMS
        
        MQ_DEVICE_PROXY_PRIV   =  8,           //私网
        MQ_DEVICE_PROXY_PUB    =  9            //公网
    }MQDeviceType;
    
    //数据在服务器端处理模式
    typedef enum MQDeliveryMode_t
    {
        MQ_DMODE_NON_PERSISTENT = 0,           //消息不需存入数据库
        MQ_DMODE_PERSISTENT     = 1            //消息需要存入数据库
    }MQDeliveryMode;
    
    //通知消息定义
    typedef enum MQMsgType_t
    {
        emMqMsgDisConnect       = 0x0000,       //断线通知
        emMqMsgDeviceState      = 0x0101,       //设备状态通知
        emMqMsgDeviceAlarm      = 0x0201,       //设备报警通知
        emMqMsgDeviceDelete     = 0x0401,       //设备删除通知
        emMqMsgDeviceAdd        = 0x0403,       //设备添加通知
        emMqMsgDeviceUpdate     = 0x0405,       //设备更新通知
        
        emMqMsgChannelDelete     = 0x0407,       //通道删除通知
        emMqMsgChannelAdd        = 0x0409,       //通道添加通知
        emMqMsgChannelUpdate     = 0x040B,       //通道更新通知
        
        emMqMsgChannelAppDelete  = 0x040D,       //通道应用删除通知
        emMqMsgChannelAppAdd     = 0x040F,       //通道应用添加通知
        emMqMsgChannelAppUpdate  = 0x0411,       //通道应用更新通知
        
        emMqMsgVehiclePassInfo  = 0x0501,        //车辆通过信息通知
        emMqMsgEecNoticeInfo    = 0x0503,        //出入口管理设备消息通知
        
        emMqMsgAlarmSmsInfo     = 0x0701,        //报警短信消息
        emMqMsgAlarmSmsReplyInfo= 0x0703,        //短信发送反馈消息
        
        emMqMsgVTHProxyUnlock             = 0x0901,  //开锁消息
        emMqMsgVTHProxyCallReDirectResult = 0x0903,  //呼叫转移结果反馈消息
        
        emMqMsgVTHProxyCallReDirect       = 0x0905,  //呼叫转移消息
        emMqMsgVTHProxyCUnlockPicInfo     = 0x0907,  //开锁图片消息
        
        //呼叫分组//
        emMqMsgCallgroupAreaDel           = 0x0911,        //呼叫分组区域关系删除消息
        emMqMsgCallgroupAreaAdd           = 0x0912,        //呼叫分组区域关系添加消息
        
        emMqMsgCallgroupDeviceBindDel     = 0x0915,        //呼叫分组设备绑定删除消息
        emMqMsgCallgroupDeviceBindAdd     = 0x0916,        //呼叫分组设备绑定添加消息
        //呼叫分组//
        
        //ACMS报警平台//
        emMqMsgAcmsAlarmNotify            = 0x1001         //ACMS平台报警通知消息
        //ACMS报警平台//
        
    }MQMsgType;
    
#define MAX_DEVICE_NAME_LENGTH   64   //设备名称长度
    #define MAX_USER_NAME_LENGTH   64     //设备名称长度
    #define MAX_USER_PASSWORD_LENGTH  64  //设备名称长度
    #define MAX_CLIENTID_LENGTH   64      //设备名称长度
    
    //设备状态变化信息
    typedef struct MQ_DEVICE_STATE_t
    {
        INT64_t llDeviceId;                    //设备编号
        int iDeviceType;                         //设备类型
        int iStatus;                             //设备当前状态
        int iTime;                               //设备状态变化时间
    }MQ_DEVICE_STATE,*LPMQ_DEVICE_STATE;
    
    //设备报警信息
    typedef struct MQ_ALARM_INFO_t
    {
        INT64_t llDeviceId;                    //设备编号
        int iDeviceType;                         //设备类型
        int iAlarmTime;                          //报警时间
        int iAlarmType;                          //报警类型
        int iAlarmStatus;                        //报警状态
    }MQ_ALARM_INFO,*LPMQ_ALARM_INFO;
    
    //数据库设备变化信息
    //设备删除
    typedef struct MQ_DEVICE_DELETE_t
    {
        INT64_t llDeviceId;                    //设备编号
    }MQ_DEVICE_DELETE,*LPMQ_DEVICE_DELETE;
    //设备添加
    typedef struct MQ_DEVICE_ADD_t
    {
        INT64_t llDeviceId;                          //设备编号
        INT64_t llAreaCode;                         //区域编码
        char szDeviceName[MAX_DEVICE_NAME_LENGTH+1];  //设备名称
        int iHasVideo;                                //是否拥有视频
    }MQ_DEVICE_ADD,*LPMQ_DEVICE_ADD;
    //设备修改
    typedef struct MQ_DEVICE_UPDATE_t
    {
        INT64_t llDeviceId;                         //设备编号
        INT64_t llAreaCode;                         //区域编码
        char szDeviceName[MAX_DEVICE_NAME_LENGTH+1];  //设备名称
        int iHasVideo;                                //是否拥有视频
    }MQ_DEVICE_UPDATE,*LPMQ_DEVICE_UPDATE;
    
    
    //车辆出入信息
    typedef struct MQ_VEHICLE_PASS_INFO_t
    {
        //INT64_t llDeviceId;               //设备长号
        char szDevNo[32];                 //设备唯一标识
        //char szNetAddr[32];                 //设备IP
        //int  iNetPort;                      //端口号
        int  iChannel;                      //通道号
        
        int iOccurTime;                   //发生日期
        char szPlateNum[32];              //车牌号
        char szPicUrl[512];               //图片访问路径
        char sVehPlateLocation[128];      //车牌在车辆图片上的位置
        int iPlateColor;                  //车牌颜色
        int iVehColor;                    //车颜色
        float fCharge;                     //费用
    }MQ_VEHICLE_PASS_INFO,*LPMQ_VEHICLE_PASS_INFO;
    
    //出入口管理设备消息通知
    typedef struct MQ_EEC_NOTICE_INFO_t
    {
        char szPlateNum[32];              //车牌号
        char szVisitorName[64];           //贵宾名称
        int iVisitorTime;                 //访问时间
    }MQ_EEC_NOTICE_INFO,*LPMQ_EEC_NOTICE_INFO;
    
    //通道信息
    typedef struct MQ_CHANNEL_INFO_t
    {
        INT64_t llChannelId;                         //通道编号
        INT64_t llAreaCode;                          //区域编码
        char szChanName[64];                         //通道名称
        int iAppProperties;                          //通道功能
    }MQ_CHANNEL_INFO,*LPMQ_CHANNEL_INFO;
    
    //通道删除
    typedef struct MQ_CHANNEL_DELETE_t
    {
        INT64_t llChannelId;                         //通道编号
    }MQ_CHANNEL_DELETE,*LPMQ_CHANNEL_DELETE;
    
    typedef struct MQ_CHANNEL_INFO_t MQ_CHANNEL_ADD_t;
    typedef MQ_CHANNEL_INFO MQ_CHANNEL_ADD;
    typedef LPMQ_CHANNEL_INFO LPMQ_CHANNEL_ADD;
    
    typedef struct MQ_CHANNEL_INFO_t MQ_CHANNEL_UPDATE_t;
    typedef MQ_CHANNEL_INFO MQ_CHANNEL_UPDATE;
    typedef LPMQ_CHANNEL_INFO LPMQ_CHANNEL_UPDATE;
    
    //通道应用信息
    typedef struct MQ_CHANNEL_APP_INFO_t
    {
        int iAppId;                                  //通道应用编号
        INT64_t llChannelId;                         //通道编号
        INT64_t llDeviceId;                          //设备编号
        int iDevChan;                                //通道号
        int iAppType;                                //应用类型
        int iAppDetailProperties;                    //应用类型详细信息值
    }MQ_CHANNEL_APP_INFO,*LPMQ_CHANNEL_APP_INFO;
    
    //通道应用删除
    typedef struct MQ_CHANNEL_APP_DELETE_t
    {
        int iAppId;                                  //通道应用编号
    }MQ_CHANNEL_APP_DELETE,*LPMQ_CHANNEL_APP_DELETE;
    
    typedef struct MQ_CHANNEL_APP_INFO_t MQ_CHANNEL_APP_APP_ADD_t;
    typedef MQ_CHANNEL_APP_INFO MQ_CHANNEL_APP_ADD;
    typedef LPMQ_CHANNEL_APP_INFO LPMQ_CHANNEL_APP_ADD;
    
    typedef struct MQ_CHANNEL_APP_INFO_t MQ_CHANNEL_APP_UPDATE_t;
    typedef MQ_CHANNEL_APP_INFO MQ_CHANNEL_APP_UPDATE;
    typedef LPMQ_CHANNEL_APP_INFO LPMQ_CHANNEL_APP_UPDATE;
    
    /////////////////报警平台短信消息//////////////////////
    //报警短信消息
    typedef struct MQ_ALARM_SMS_INFO_t
    {
        int iSmsRecord;                         //编号
        char szReceivePhone[20];                //接受者号码
        char szSmsContent[256];                 //短信内容
        int iSendTime;                          //发送时间
        char szResv[64];                        //预留
    }MQ_ALARM_SMS_INFO,*LPMQ_ALARM_SMS_INFO;
    
    //短信发送反馈消息
    typedef struct MQ_ALARM_SMS_REPLY_INFO_t
    {
        int iSmsRecord;                         //编号
        int iSendStatus;                        //发送状态 0 未发送 1 发送成功 2 发送失败
    }MQ_ALARM_SMS_REPLY_INFO,*LPMQ_ALARM_SMS_REPLY_INFO;
    /////////////////报警平台短信消息//////////////////////
    
    /////////////////VTH代理消息//////////////////////
    //呼叫转移消息
    typedef struct MQ_VTHPROXY_CALL_REDIRECT_INFO_t
    {
        INT64_t llVtoId;//门口机编号
        int iMidVthId;//室内机编号
        INT64_t llVirVthId;//虚拟VTH编号
        int iInviteTime;//时间
        char szPicUrl[256];//VTHProxy接到呼叫抓拍一张图片位置
        int iStage; //呼叫所处阶段 1 VTO呼叫发起VTH；2 VTH接听；3 VTH开锁；4 VTO或VTH挂断；
    }MQ_VTHPROXY_CALL_REDIRECT_INFO,*LPMQ_VTHPROXY_CALL_REDIRECT_INFO;
    //开锁图片消息
    typedef struct MQ_VTHPROXY_UNLOCK_PIC_INFO_t
    {
        INT64_t llVtoId;//门口机编号
        int iMidVthId;//室内机编号
        INT64_t llVirVthId;//虚拟VTH编号
        int iInviteTime;//时间
        INT64_t llAccountId;//开锁人编号
        char szAccountName[64];//开锁人名称
        int iUnLockTime;//开锁时间
        int iUnLockResult;//开锁结果0：未开锁1：开锁
        char szPicUrl[256];//VTHProxy接到呼叫抓拍一张图片位置
    }MQ_VTHPROXY_UNLOCK_PIC_INFO,*LPMQ_VTHPROXY_UNLOCK_PIC_INFO;
    //开锁请求消息
    typedef struct MQ_VTHPROXY_UNLOCK_REQ_INFO_t
    {
        INT64_t llVtoId;//门口机编号
        int iMidVthId;//室内机编号
        INT64_t llVirVthId;//虚拟VTH编号
        int iInviteTime;//时间
        INT64_t llAccountId;//开锁人编号
        char szAccountName[64];//开锁人名称
    }MQ_VTHPROXY_UNLOCK_REQ_INFO,*LPMQ_VTHPROXY_UNLOCK_REQ_INFO;
    //呼叫转移结果通知消息
    typedef struct MQ_VTHPROXY_CALL_REDIRECT_RESULT_INFO_t
    {
        INT64_t llVtoId;//门口机编号
        int iMidVthId;//室内机编号
        INT64_t llVirVthId;//虚拟VTH编号
        int iInviteTime;//时间
        int iResult;//结果 0 短信通过 1 无此账号
    }MQ_VTHPROXY_CALL_REDIRECT_RESULT_INFO,*LPMQ_VTHPROXY_CALL_REDIRECT_RESULT_INFO;
    /////////////////VTH代理消息//////////////////////
    
    /////////////////////呼叫分组处理消息////////////////////////////////
    //呼叫分组区域关系删除消息
    typedef struct MQ_CALLGROUP_AREA_DELETE_INFO_t
    {
        int iCallGroupAreaId;              //呼叫分组区域关系编号
    }MQ_CALLGROUP_AREA_DELETE_INFO,*LPMQ_CALLGROUP_AREA_DELETE_INFO;
    //呼叫分组区域关系添加消息
    typedef struct MQ_CALLGROUP_AREA_ADD_INFO_t
    {
        int iCallGroupAreaId;              //呼叫分组区域关系编号
        int iCallGroupId;                  //呼叫分组编号
        INT64_t llAreaCode;                //区域编号
    }MQ_CALLGROUP_AREA_ADD_INFO,*LPMQ_CALLGROUP_AREA_ADD_INFO;
    //呼叫分组设备绑定删除消息
    typedef struct MQ_CALLDROUP_DEVICE_BIND_DELETE_INFO_t
    {
        int iCallGroupDeviceBindId;        //呼叫分组设备绑定编号
    }MQ_CALLGROUP_DEVICE_BIND_DELETE_INFO,*LPMQ_CALLGROUP_DEVICE_BIND_DELETE_INFO;
    //呼叫分组设备绑定添加消息
    typedef struct MQ_CALLDROUP_DEVICE_BIND_ADD_INFO_t
    {
        int iCallGroupDeviceBindId;        //呼叫分组设备绑定编号
        int iCallGroupId;                  //呼叫分组编号
        INT64_t llDeviceId;                //设备长号
        int iPrority;                      //优先级
    }MQ_CALLGROUP_DEVICE_BIND_ADD_INFO,*LPMQ_CALLGROUP_DEVICE_BIND_ADD_INFO;
    /////////////////////呼叫分组处理消息////////////////////////////////
    
    
    /////////////////////ACMS平台消息////////////////////////////////
    //ACMS平台报警通知消息
    typedef struct MQ_ACMS_ALARM_NOTIFY_INFO_t
    {
        //int iChannelType;                  //通道类型
        INT64_t llChannelId;               //通道编号
        int iAlarmTime;                    //报警发生时间
        int iAlarmType;                    //报警类型
        char szAlarmType[64];              //报警类型
        int iAlarmStatus;                  //报警状态
        char szAlarmStatus[64];            //报警状态
        int iReserv1;                      //保留字段
        char szReserv2[256];               //保留字段
    }MQ_ACMS_ALARM_NOTIFY_INFO,*LPMQ_ACMS_ALARM_NOTIFY_INFO;
    /////////////////////ACMS平台消息////////////////////////////////
    
    
    //消息结构
    typedef struct MQ_CALLBACK_INFO_t
    {
        int iType;
        union
        {
            int iReason;                       //掉线原因
            LPMQ_DEVICE_STATE pstDevState;     //设备状态信息
            LPMQ_ALARM_INFO   pstAlarmInfo;    //报警信息
            LPMQ_DEVICE_DELETE pstDevDelete;   //设备删除
            LPMQ_DEVICE_ADD    pstDevAdd;      //设备添加
            LPMQ_DEVICE_UPDATE pstDevUpdate;   //设备更新
            LPMQ_VEHICLE_PASS_INFO pstVehPassInfo;   //车辆出入信息
            LPMQ_EEC_NOTICE_INFO pstEecNoticeInfo;   //出入口管理设备消息通知信息
            LPMQ_CHANNEL_DELETE pstChannelDelete;          //通道删除
            LPMQ_CHANNEL_ADD pstChannelAdd;                //通道添加
            LPMQ_CHANNEL_UPDATE pstChannelUpdate;          //通道更新
            LPMQ_CHANNEL_APP_DELETE pstChannelAppDelete;   //通道应用删除
            LPMQ_CHANNEL_APP_ADD pstChannelAppAdd;         //通道应用添加
            LPMQ_CHANNEL_APP_UPDATE pstChannelAppUpdate;   //通道应用更新
            
            LPMQ_ALARM_SMS_INFO pstAlarmSmsInfo;           //报警短信消息
            
            LPMQ_VTHPROXY_UNLOCK_REQ_INFO pstUlockReq; //开锁请求
            LPMQ_VTHPROXY_CALL_REDIRECT_RESULT_INFO pstCallRedirectResult; //呼叫转移结果
            LPMQ_VTHPROXY_CALL_REDIRECT_INFO pstCallRedirctReq; //呼叫转移消息
            LPMQ_VTHPROXY_UNLOCK_PIC_INFO pstUnlockPicReq; //开锁图片消息
            
            //呼叫分组消息//
            LPMQ_CALLGROUP_AREA_DELETE_INFO pstCallgroupAreaDelReq;           //呼叫分组区域关系删除消息
            LPMQ_CALLGROUP_AREA_ADD_INFO pstCallgroupAreaAddReq;              //呼叫分组区域关系添加消息
            LPMQ_CALLGROUP_DEVICE_BIND_DELETE_INFO pstCallgroupDevBindDelReq; //呼叫分组设备绑定删除消息
            LPMQ_CALLGROUP_DEVICE_BIND_ADD_INFO pstCallgroupDevBindAddReq;    //呼叫分组设备绑定添加消息
            //呼叫分组消息//
            
            //ACMS报警平台//
            LPMQ_ACMS_ALARM_NOTIFY_INFO pstAcmsAlarmNotify;        //ACMS平台报警通知
            //ACMS报警平台//
            
            void *pMessage;                                //通用消息,由外层处理
        };
    }MQ_CALLBACK_INFO,*LPMQ_CALLBACK_INFO;
    
    
    //回调
    typedef int (*fcbStack)(void *pUser,MQ_HANDLE hInst,MQ_HANDLE hSessionId,LPMQ_CALLBACK_INFO pcbInfo);
    
    //终端信息
    typedef struct MQ_ENDPOINT_t
    {
        char szUserName[MAX_USER_NAME_LENGTH+1];      //用户名
        char szPassword[MAX_USER_PASSWORD_LENGTH+1];  //密码
        char szClientId[MAX_CLIENTID_LENGTH+1];       //客户端Id
        int iEndpointType;                            //终端类型
        fcbStack cbStack;                             //回调接口
        void *pUser;                                  //用户自定义数据
    }MQ_ENDPOINT,*LPMQ_ENDPOINT;
    
    typedef int (*fcbStackEx)(void *pUser,MQ_HANDLE hInst,MQ_HANDLE hSessionId,char *pTopic,char *pJmsType,char *pMsg,int iMsgLen);
    
    typedef struct MQ_EXRAINFO_t
    {
        fcbStackEx cbStack;                          //回调接口，透明通道
        void *pUser;                                 //用户自定义数据,透明通道
        char **pTopicList;                            //主题列表
        int iTopicCount;                             //主题数目
        int iIsCompatibleOld;                        //是否兼容以前版本 1 兼容 2 不兼容
    }MQ_EXRAINFO,*LPMQ_EXRAINFO;
    
#ifdef __cplusplus
}
#endif

#endif
