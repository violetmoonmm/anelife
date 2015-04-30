#include "MQStackApi.h"
#include "MQGeneral.h"

//初始化协议栈
int MQ_InitStack(void)
{
	return CMQGeneral::Instance()->InitStack();
}
//反初始化协议栈
int MQ_CleanupStack(void)
{
	return CMQGeneral::Instance()->CleanupStack();
}
//创建实例
MQ_HANDLE MQ_CreateInstance(char *pszURI,int *pError)
{
	return CMQGeneral::Instance()->CreateInstance(pszURI,pError);
}
//释放实例
int MQ_ReleaseInstance(MQ_HANDLE hInst)
{
	return CMQGeneral::Instance()->ReleaseInstance(hInst);
}

//设置当前终端参数
int MQ_SetEndpoint(MQ_HANDLE hInst,MQ_ENDPOINT stEpInfo)
{
	return CMQGeneral::Instance()->SetEndpoint(hInst,stEpInfo);
}

////设置当前终端类型
//int MQ_SetDeviceType(MQ_HANDLE hInst,int iDeviceType)
//{
//	return CMQGeneral::Instance()->SetDeviceType(hInst,iDeviceType);
//}
//
////设置实例断线回调
//int MQ_SetDisConnectCb(MQ_HANDLE hInst,fMQDisConnect cbDisConnct)
//{
//	//return MQ_ERROR_NOT_IMPL;
//	return CMQGeneral::Instance()->SetDisConnectCb(hInst,cbDisConnct);
//}
////设置实例消息通知
//int MQ_SetNotifyCb(MQ_HANDLE hInst,fMQOnMessage cbMsg)
//{
//	//return MQ_ERROR_NOT_IMPL;
//	return CMQGeneral::Instance()->SetNotifyCb(hInst,cbMsg);
//}
//订阅主题
//int MQ_SetTopic(MQ_HANDLE hInst,char **pTopic,int iTopicCount)
//{
//	return CMQGeneral::Instance()->SetTopic(hInst,pTopic,iTopicCount);	 
//}
//设置扩展信息
int MQ_SetExtraInfo(MQ_HANDLE hInst,LPMQ_EXRAINFO pstExtInfo)
{
	return CMQGeneral::Instance()->SetExtraInfo(hInst,pstExtInfo);	 
}
//启动
int MQ_InstanceStart(MQ_HANDLE hInst)
{
	//return MQ_ERROR_NOT_IMPL;
	return CMQGeneral::Instance()->InstanceStart(hInst);
}
//停止
int MQ_InstanceStop(MQ_HANDLE hInst)
{
	//return MQ_ERROR_NOT_IMPL;
	return CMQGeneral::Instance()->InstanceStop(hInst);
}

//发送设备状态变化通知消息
int MQ_DeviceStateNotify(MQ_HANDLE hInst,MQ_DEVICE_STATE stDevState,int iDeliveryMode )
{
	return CMQGeneral::Instance()->DeviceStateNotify(hInst,stDevState,iDeliveryMode);
}
//发送报警通知消息
int MQ_AlarmNotify(MQ_HANDLE hInst,MQ_ALARM_INFO stAlarmInfo,int iDeliveryMode )
{
	return CMQGeneral::Instance()->AlarmNotify(hInst,stAlarmInfo,iDeliveryMode);
}
//发送设备删除消息
int MQ_DeviceDelNotify(MQ_HANDLE hInst,MQ_DEVICE_DELETE stDeviceDel,int iDeliveryMode )
{
	return CMQGeneral::Instance()->DeviceDelNotify(hInst,stDeviceDel,iDeliveryMode);
}
//发送设备添加消息
int MQ_DeviceAddNotify(MQ_HANDLE hInst,MQ_DEVICE_ADD stDeviceAdd,int iDeliveryMode )
{
	return CMQGeneral::Instance()->DeviceAddNotify(hInst,stDeviceAdd,iDeliveryMode);
}
//发送设备更新消息
int MQ_DeviceUpdateNotify(MQ_HANDLE hInst,MQ_DEVICE_UPDATE stDeviceUpdate,int iDeliveryMode )
{
	return CMQGeneral::Instance()->DeviceUpdateNotify(hInst,stDeviceUpdate,iDeliveryMode);
}

//发送车辆出入消息
int MQ_VehiclePassInfoNotify(MQ_HANDLE hInst,LPMQ_VEHICLE_PASS_INFO pstVehPassInfo,int iDeliveryMode)
{
	return CMQGeneral::Instance()->VehiclePassInfoNotify(hInst,pstVehPassInfo,iDeliveryMode);
}
//发送出入口管理设备消息通知信息
int MQ_EecNoticeInfoNotify(MQ_HANDLE hInst,LPMQ_EEC_NOTICE_INFO pstEecNoticeInfo,int iDeliveryMode)
{
	return CMQGeneral::Instance()->EecNoticeInfoNotify(hInst,pstEecNoticeInfo,iDeliveryMode);
}

//发送消息
int MQ_SendMsg(MQ_HANDLE hInst,char *pszTopic,char *pMsg,int iLen,int iDeliveryMode)
{
	//return MQ_ERROR_NOT_IMPL;
	return CMQGeneral::Instance()->SendMsg(hInst,pszTopic,pMsg,iLen,iDeliveryMode);
}

//发送一般消息
int MQ_SendMsgEx(MQ_HANDLE hInst,char *pszTopic,char *pCmsType,char *pMsg,int iLen,int iDeliveryMode)
{
	//return MQ_ERROR_NOT_IMPL;
	return CMQGeneral::Instance()->SendMsgEx(hInst,pszTopic,pCmsType,pMsg,iLen,iDeliveryMode);
}

//发送短信发送反馈消息
int MQ_SPAlarmSmsReplyInfoNotify(MQ_HANDLE hInst,LPMQ_ALARM_SMS_REPLY_INFO pstSpAlarmSmsReplyNoticeInfo,int iDeliveryMode)
{
	//return MQ_ERROR_NOT_IMPL;
	return CMQGeneral::Instance()->SPAlarmSmsReplyInfoNotify(hInst,pstSpAlarmSmsReplyNoticeInfo,iDeliveryMode);
}

//发送开锁图片消息
int MQ_VTHProxy_UnlockPic(MQ_HANDLE hInst,LPMQ_VTHPROXY_UNLOCK_PIC_INFO pstPicInfo,int iDeliveryMode)
{
	return CMQGeneral::Instance()->VTHProxy_UnlockPic(hInst,pstPicInfo,iDeliveryMode);
}
//发送呼叫转移消息
int MQ_VTHProxy_CallRedirect(MQ_HANDLE hInst,LPMQ_VTHPROXY_CALL_REDIRECT_INFO pstCrInfo,int iDeliveryMode)
{
	return CMQGeneral::Instance()->VTHProxy_CallRedirect(hInst,pstCrInfo,iDeliveryMode);
}

//发送开锁消息
int MQ_VTHProxy_Unlock(MQ_HANDLE hInst,LPMQ_VTHPROXY_UNLOCK_REQ_INFO pstUnlockReq,int iDeliveryMode)
{
	return CMQGeneral::Instance()->VTHProxy_Unlock(hInst,pstUnlockReq,iDeliveryMode);
}
//发送呼叫转移结果反馈消息
int MQ_VTHProxy_CallRedirectResult(MQ_HANDLE hInst,LPMQ_VTHPROXY_CALL_REDIRECT_RESULT_INFO pstCrResult,int iDeliveryMode)
{
	return CMQGeneral::Instance()->VTHProxy_CallRedirectResult(hInst,pstCrResult,iDeliveryMode);
}
/////////////////////ACMS平台消息////////////////////////////////
//发送ACMS平台报警通知消息
int MQ_ACMS_AlarmNotify(MQ_HANDLE hInst,LPMQ_ACMS_ALARM_NOTIFY_INFO pstAlarmInfo,int iDeliveryMode)
{
	return CMQGeneral::Instance()->ACMS_AlarmNotify(hInst,pstAlarmInfo,iDeliveryMode);
}
/////////////////////ACMS平台消息////////////////////////////////
