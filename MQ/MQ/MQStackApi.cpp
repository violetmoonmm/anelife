#include "MQStackApi.h"
#include "MQGeneral.h"

//��ʼ��Э��ջ
int MQ_InitStack(void)
{
	return CMQGeneral::Instance()->InitStack();
}
//����ʼ��Э��ջ
int MQ_CleanupStack(void)
{
	return CMQGeneral::Instance()->CleanupStack();
}
//����ʵ��
MQ_HANDLE MQ_CreateInstance(char *pszURI,int *pError)
{
	return CMQGeneral::Instance()->CreateInstance(pszURI,pError);
}
//�ͷ�ʵ��
int MQ_ReleaseInstance(MQ_HANDLE hInst)
{
	return CMQGeneral::Instance()->ReleaseInstance(hInst);
}

//���õ�ǰ�ն˲���
int MQ_SetEndpoint(MQ_HANDLE hInst,MQ_ENDPOINT stEpInfo)
{
	return CMQGeneral::Instance()->SetEndpoint(hInst,stEpInfo);
}

////���õ�ǰ�ն�����
//int MQ_SetDeviceType(MQ_HANDLE hInst,int iDeviceType)
//{
//	return CMQGeneral::Instance()->SetDeviceType(hInst,iDeviceType);
//}
//
////����ʵ�����߻ص�
//int MQ_SetDisConnectCb(MQ_HANDLE hInst,fMQDisConnect cbDisConnct)
//{
//	//return MQ_ERROR_NOT_IMPL;
//	return CMQGeneral::Instance()->SetDisConnectCb(hInst,cbDisConnct);
//}
////����ʵ����Ϣ֪ͨ
//int MQ_SetNotifyCb(MQ_HANDLE hInst,fMQOnMessage cbMsg)
//{
//	//return MQ_ERROR_NOT_IMPL;
//	return CMQGeneral::Instance()->SetNotifyCb(hInst,cbMsg);
//}
//��������
//int MQ_SetTopic(MQ_HANDLE hInst,char **pTopic,int iTopicCount)
//{
//	return CMQGeneral::Instance()->SetTopic(hInst,pTopic,iTopicCount);	 
//}
//������չ��Ϣ
int MQ_SetExtraInfo(MQ_HANDLE hInst,LPMQ_EXRAINFO pstExtInfo)
{
	return CMQGeneral::Instance()->SetExtraInfo(hInst,pstExtInfo);	 
}
//����
int MQ_InstanceStart(MQ_HANDLE hInst)
{
	//return MQ_ERROR_NOT_IMPL;
	return CMQGeneral::Instance()->InstanceStart(hInst);
}
//ֹͣ
int MQ_InstanceStop(MQ_HANDLE hInst)
{
	//return MQ_ERROR_NOT_IMPL;
	return CMQGeneral::Instance()->InstanceStop(hInst);
}

//�����豸״̬�仯֪ͨ��Ϣ
int MQ_DeviceStateNotify(MQ_HANDLE hInst,MQ_DEVICE_STATE stDevState,int iDeliveryMode )
{
	return CMQGeneral::Instance()->DeviceStateNotify(hInst,stDevState,iDeliveryMode);
}
//���ͱ���֪ͨ��Ϣ
int MQ_AlarmNotify(MQ_HANDLE hInst,MQ_ALARM_INFO stAlarmInfo,int iDeliveryMode )
{
	return CMQGeneral::Instance()->AlarmNotify(hInst,stAlarmInfo,iDeliveryMode);
}
//�����豸ɾ����Ϣ
int MQ_DeviceDelNotify(MQ_HANDLE hInst,MQ_DEVICE_DELETE stDeviceDel,int iDeliveryMode )
{
	return CMQGeneral::Instance()->DeviceDelNotify(hInst,stDeviceDel,iDeliveryMode);
}
//�����豸�����Ϣ
int MQ_DeviceAddNotify(MQ_HANDLE hInst,MQ_DEVICE_ADD stDeviceAdd,int iDeliveryMode )
{
	return CMQGeneral::Instance()->DeviceAddNotify(hInst,stDeviceAdd,iDeliveryMode);
}
//�����豸������Ϣ
int MQ_DeviceUpdateNotify(MQ_HANDLE hInst,MQ_DEVICE_UPDATE stDeviceUpdate,int iDeliveryMode )
{
	return CMQGeneral::Instance()->DeviceUpdateNotify(hInst,stDeviceUpdate,iDeliveryMode);
}

//���ͳ���������Ϣ
int MQ_VehiclePassInfoNotify(MQ_HANDLE hInst,LPMQ_VEHICLE_PASS_INFO pstVehPassInfo,int iDeliveryMode)
{
	return CMQGeneral::Instance()->VehiclePassInfoNotify(hInst,pstVehPassInfo,iDeliveryMode);
}
//���ͳ���ڹ����豸��Ϣ֪ͨ��Ϣ
int MQ_EecNoticeInfoNotify(MQ_HANDLE hInst,LPMQ_EEC_NOTICE_INFO pstEecNoticeInfo,int iDeliveryMode)
{
	return CMQGeneral::Instance()->EecNoticeInfoNotify(hInst,pstEecNoticeInfo,iDeliveryMode);
}

//������Ϣ
int MQ_SendMsg(MQ_HANDLE hInst,char *pszTopic,char *pMsg,int iLen,int iDeliveryMode)
{
	//return MQ_ERROR_NOT_IMPL;
	return CMQGeneral::Instance()->SendMsg(hInst,pszTopic,pMsg,iLen,iDeliveryMode);
}

//����һ����Ϣ
int MQ_SendMsgEx(MQ_HANDLE hInst,char *pszTopic,char *pCmsType,char *pMsg,int iLen,int iDeliveryMode)
{
	//return MQ_ERROR_NOT_IMPL;
	return CMQGeneral::Instance()->SendMsgEx(hInst,pszTopic,pCmsType,pMsg,iLen,iDeliveryMode);
}

//���Ͷ��ŷ��ͷ�����Ϣ
int MQ_SPAlarmSmsReplyInfoNotify(MQ_HANDLE hInst,LPMQ_ALARM_SMS_REPLY_INFO pstSpAlarmSmsReplyNoticeInfo,int iDeliveryMode)
{
	//return MQ_ERROR_NOT_IMPL;
	return CMQGeneral::Instance()->SPAlarmSmsReplyInfoNotify(hInst,pstSpAlarmSmsReplyNoticeInfo,iDeliveryMode);
}

//���Ϳ���ͼƬ��Ϣ
int MQ_VTHProxy_UnlockPic(MQ_HANDLE hInst,LPMQ_VTHPROXY_UNLOCK_PIC_INFO pstPicInfo,int iDeliveryMode)
{
	return CMQGeneral::Instance()->VTHProxy_UnlockPic(hInst,pstPicInfo,iDeliveryMode);
}
//���ͺ���ת����Ϣ
int MQ_VTHProxy_CallRedirect(MQ_HANDLE hInst,LPMQ_VTHPROXY_CALL_REDIRECT_INFO pstCrInfo,int iDeliveryMode)
{
	return CMQGeneral::Instance()->VTHProxy_CallRedirect(hInst,pstCrInfo,iDeliveryMode);
}

//���Ϳ�����Ϣ
int MQ_VTHProxy_Unlock(MQ_HANDLE hInst,LPMQ_VTHPROXY_UNLOCK_REQ_INFO pstUnlockReq,int iDeliveryMode)
{
	return CMQGeneral::Instance()->VTHProxy_Unlock(hInst,pstUnlockReq,iDeliveryMode);
}
//���ͺ���ת�ƽ��������Ϣ
int MQ_VTHProxy_CallRedirectResult(MQ_HANDLE hInst,LPMQ_VTHPROXY_CALL_REDIRECT_RESULT_INFO pstCrResult,int iDeliveryMode)
{
	return CMQGeneral::Instance()->VTHProxy_CallRedirectResult(hInst,pstCrResult,iDeliveryMode);
}
/////////////////////ACMSƽ̨��Ϣ////////////////////////////////
//����ACMSƽ̨����֪ͨ��Ϣ
int MQ_ACMS_AlarmNotify(MQ_HANDLE hInst,LPMQ_ACMS_ALARM_NOTIFY_INFO pstAlarmInfo,int iDeliveryMode)
{
	return CMQGeneral::Instance()->ACMS_AlarmNotify(hInst,pstAlarmInfo,iDeliveryMode);
}
/////////////////////ACMSƽ̨��Ϣ////////////////////////////////
