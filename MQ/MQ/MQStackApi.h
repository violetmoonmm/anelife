#ifndef MQSTACKAPI_H
#define MQSTACKAPI_H

#if defined(_MSC_VER) && (_MSC_VER >= 1200)
# pragma once
#endif

#ifdef _WIN32
#if defined(_LIB)
#define MQ_EXPORT
#else
#if defined(_USRDLL)
#define MQ_EXPORT __declspec(dllexport)
#else
#define MQ_EXPORT __declspec(dllimport)
#endif
#endif
#else
#define MQ_EXPORT
#endif

#ifdef __cplusplus
extern "C"
{
#endif
    
#include "MQStackDef.h"
    
    //初始化协议栈
    MQ_EXPORT int MQ_InitStack(void);
    //反初始化协议栈
    MQ_EXPORT int MQ_CleanupStack(void);
    //创建实例
    MQ_EXPORT MQ_HANDLE MQ_CreateInstance(char *pszURI,int *pError);
    //释放实例
    MQ_EXPORT int MQ_ReleaseInstance(MQ_HANDLE hInst);
    
    
    ////实例参数配置
    //设置当前终端参数
    MQ_EXPORT int MQ_SetEndpoint(MQ_HANDLE hInst,MQ_ENDPOINT stEpInfo);
    
    //订阅主题
    //MQ_EXPORT int MQ_SetTopic(MQ_HANDLE hInst,char **pTopic,int iTopicCount);
    
    //设置扩展信息
    MQ_EXPORT int MQ_SetExtraInfo(MQ_HANDLE hInst,LPMQ_EXRAINFO pstExtInfo);
    
    //启动
    MQ_EXPORT int MQ_InstanceStart(MQ_HANDLE hInst);
    //停止
    MQ_EXPORT int MQ_InstanceStop(MQ_HANDLE hInst);
    
    //发送设备状态变化通知消息
    MQ_EXPORT int MQ_DeviceStateNotify(MQ_HANDLE hInst,MQ_DEVICE_STATE stDevState,int iDeliveryMode );
    //发送报警通知消息
    MQ_EXPORT int MQ_AlarmNotify(MQ_HANDLE hInst,MQ_ALARM_INFO stAlarmInfo,int iDeliveryMode );
    //发送设备删除消息
    MQ_EXPORT int MQ_DeviceDelNotify(MQ_HANDLE hInst,MQ_DEVICE_DELETE stDeviceDel,int iDeliveryMode );
    //发送设备添加消息
    MQ_EXPORT int MQ_DeviceAddNotify(MQ_HANDLE hInst,MQ_DEVICE_ADD stDeviceAdd,int iDeliveryMode );
    //发送设备更新消息
    MQ_EXPORT int MQ_DeviceUpdateNotify(MQ_HANDLE hInst,MQ_DEVICE_UPDATE stDeviceUpdate,int iDeliveryMode );
    //发送车辆出入消息
    MQ_EXPORT int MQ_VehiclePassInfoNotify(MQ_HANDLE hInst,LPMQ_VEHICLE_PASS_INFO pstVehPassInfo,int iDeliveryMode );
    //发送出入口管理设备消息通知信息
    MQ_EXPORT int MQ_EecNoticeInfoNotify(MQ_HANDLE hInst,LPMQ_EEC_NOTICE_INFO pstEecNoticeInfo,int iDeliveryMode );
    
    //发送短信发送反馈消息
    MQ_EXPORT int MQ_SPAlarmSmsReplyInfoNotify(MQ_HANDLE hInst,LPMQ_ALARM_SMS_REPLY_INFO pstSpAlarmSmsReplyNoticeInfo,int iDeliveryMode );
    
    //发送开锁图片消息
    MQ_EXPORT int MQ_VTHProxy_UnlockPic(MQ_HANDLE hInst,LPMQ_VTHPROXY_UNLOCK_PIC_INFO pstPicInfo,int iDeliveryMode );
    //发送呼叫转移消息
    MQ_EXPORT int MQ_VTHProxy_CallRedirect(MQ_HANDLE hInst,LPMQ_VTHPROXY_CALL_REDIRECT_INFO pstCrInfo,int iDeliveryMode );
    
    //发送开锁消息
    MQ_EXPORT int MQ_VTHProxy_Unlock(MQ_HANDLE hInst,LPMQ_VTHPROXY_UNLOCK_REQ_INFO pstUnlockReq,int iDeliveryMode );
    //发送呼叫转移结果反馈消息
    MQ_EXPORT int MQ_VTHProxy_CallRedirectResult(MQ_HANDLE hInst,LPMQ_VTHPROXY_CALL_REDIRECT_RESULT_INFO pstCrResult,int iDeliveryMode );
    
    /////////////////////ACMS平台消息////////////////////////////////
    //发送ACMS平台报警通知消息
    MQ_EXPORT int MQ_ACMS_AlarmNotify(MQ_HANDLE hInst,LPMQ_ACMS_ALARM_NOTIFY_INFO pstAlarmInfo,int iDeliveryMode );
    /////////////////////ACMS平台消息////////////////////////////////
    
    //发送一般消息
    MQ_EXPORT int MQ_SendMsg(MQ_HANDLE hInst,char *pszTopic,char *pMsg,int iLen,int iDeliveryMode );
    
    //发送一般消息
    MQ_EXPORT int MQ_SendMsgEx(MQ_HANDLE hInst,char *pszTopic,char *pCmsType,char *pMsg,int iLen,int iDeliveryMode);
    
#ifdef __cplusplus
}
#endif

#endif
