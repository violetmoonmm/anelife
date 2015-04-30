#ifndef MQGENERAL_H
#define MQGENERAL_H

#if defined(_MSC_VER) && (_MSC_VER >= 1200)
# pragma once
#endif

#include "MQStackDef.h"
#include <map>

class CMQInstance;

class CMQGeneral
{
public:
	CMQGeneral(void);
	~CMQGeneral(void);
public:
	static CMQGeneral* Instance(void);
    
public:
	//接口定义
	//读取当前线程最后一个错误码
	int GetLastError(void);
	//获取协议栈版本
	unsigned int GetSdkVersion(void);
	//初始化协议栈
	int InitStack(void);
	//反初始化协议栈
	int CleanupStack(void);
	//创建实例
	MQ_HANDLE CreateInstance(char *pszURI,int *pError);
	//销毁实例
	int ReleaseInstance(MQ_HANDLE hInst);
    
	//设置当前终端参数
	int SetEndpoint(MQ_HANDLE hInst,MQ_ENDPOINT &stEpInfo);
    
	//订阅主题
	int SetTopic(MQ_HANDLE hInst,char **pTopic,int iTopicCount);
    
	//设置扩展信息
	int SetExtraInfo(MQ_HANDLE hInst,LPMQ_EXRAINFO pstExtInfo);
    
	////设置当前终端类型
	//int SetDeviceType(MQ_HANDLE hInst,int iDeviceType);
	////设置实例断线回调
	//int SetDisConnectCb(MQ_HANDLE hInst,fMQDisConnect cbDisConnct);
	////设置实例消息通知
	//int SetNotifyCb(MQ_HANDLE hInst,fMQOnMessage cbMsg);
    
	//启动
	int InstanceStart(MQ_HANDLE hInst);
	//停止
	int InstanceStop(MQ_HANDLE hInst);
    
	
	//发送设备状态变化通知消息
	int DeviceStateNotify(MQ_HANDLE hInst,MQ_DEVICE_STATE stDevState,int iDeliveryMode );
	//发送报警通知消息
	int AlarmNotify(MQ_HANDLE hInst,MQ_ALARM_INFO stAlarmInfo,int iDeliveryMode);
	//发送设备删除消息
	int DeviceDelNotify(MQ_HANDLE hInst,MQ_DEVICE_DELETE stDeviceDel,int iDeliveryMode );
	//发送设备添加消息
	int DeviceAddNotify(MQ_HANDLE hInst,MQ_DEVICE_ADD stDeviceAdd,int iDeliveryMode );
	//发送设备更新消息
	int DeviceUpdateNotify(MQ_HANDLE hInst,MQ_DEVICE_UPDATE stDeviceUpdate,int iDeliveryMode );
	//发送车辆出入消息
	int VehiclePassInfoNotify(MQ_HANDLE hInst,LPMQ_VEHICLE_PASS_INFO pstVehPassInfo,int iDeliveryMode);
	//发送出入口管理设备消息通知信息
	int EecNoticeInfoNotify(MQ_HANDLE hInst,LPMQ_EEC_NOTICE_INFO pstEecNoticeInfo,int iDeliveryMode);
    
	//发送短信发送反馈消息
	int SPAlarmSmsReplyInfoNotify(MQ_HANDLE hInst,LPMQ_ALARM_SMS_REPLY_INFO pstSpAlarmSmsReplyNoticeInfo,int iDeliveryMode);
    
	//发送开锁图片消息
	int VTHProxy_UnlockPic(MQ_HANDLE hInst,LPMQ_VTHPROXY_UNLOCK_PIC_INFO pstPicInfo,int iDeliveryMode);
	//发送呼叫转移消息
	int VTHProxy_CallRedirect(MQ_HANDLE hInst,LPMQ_VTHPROXY_CALL_REDIRECT_INFO pstCrInfo,int iDeliveryMode);
	//发送开锁消息
	int VTHProxy_Unlock(MQ_HANDLE hInst,LPMQ_VTHPROXY_UNLOCK_REQ_INFO pstUnlockReq,int iDeliveryMode);
	//发送呼叫转移结果反馈消息
	int VTHProxy_CallRedirectResult(MQ_HANDLE hInst,LPMQ_VTHPROXY_CALL_REDIRECT_RESULT_INFO pstCrResult,int iDeliveryMode);
    
	/////////////////////ACMS平台消息////////////////////////////////
	//发送ACMS平台报警通知消息
	int ACMS_AlarmNotify(MQ_HANDLE hInst,LPMQ_ACMS_ALARM_NOTIFY_INFO pstAlarmInfo,int iDeliveryMode);
	/////////////////////ACMS平台消息////////////////////////////////
    
    //发送消息
	int SendMsg(MQ_HANDLE hInst,char *pszTopic,char *pMsg,int iLen,int iDeliveryMode);
    
	//发送消息 扩展
	int SendMsgEx(MQ_HANDLE hInst,char *pszTopic,char *pCmsType,char *pMsg,int iLen,int iDeliveryMode);
    
private:
	static MQ_HANDLE GenerateHandle(void);
    
	CMQInstance * LookupInstance(MQ_HANDLE hInst);
    
	static CMQGeneral *m_sGeneral;
    
	static MQ_HANDLE m_sGenId;
	std::map<MQ_HANDLE,CMQInstance*> m_instList;
};

#endif
