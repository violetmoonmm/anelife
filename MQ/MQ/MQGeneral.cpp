#include "MQGeneral.h"
#include "MQInstance.h"
#ifdef _WIN32
#include   <sstream>
#endif

#include "Trace.h"

///版本信息定义
#define  SDK_VERSION_MAJOR   1
#define  SDK_VERSION_MINOR   0
#define  SDK_VERSION_BUILD   0001

#define  SDK_VERSION   (SDK_VERSION_MAJOR<<24 | SDK_VERSION_MINOR<<16 | SDK_VERSION_BUILD)

#define SDK_NAME  "MQ_STACK"

//静态变量初始化
CMQGeneral* CMQGeneral::m_sGeneral = NULL; 
MQ_HANDLE CMQGeneral::m_sGenId = MQ_INVALID_HANDLE;

CMQGeneral::CMQGeneral(void)
{
//#ifdef WIN32 //windows平台,需要
//	zwan::Logger::Logger::Instance()->SetOutput(zwan::Logger::emOutVsDbg
//		                                        | zwan::Logger::emOutWindowsConsole
//												| zwan::Logger::emOutFile, 
//												"max_size=1M;expire=30");
//#endif

	INFO_TRACE("stack : "<<SDK_NAME<<" version : "<<SDK_VERSION_MAJOR<<"."<<((SDK_VERSION_MINOR&0XF0)>>4)<<(SDK_VERSION_MINOR&0X0F)<<"."<<std::hex<<((SDK_VERSION_BUILD&0XFF00)>>8)<<std::hex<<(SDK_VERSION_BUILD&0X00FF)<<" compile : "<<__DATE__<< " "<<__TIME__);

#ifdef WIN32
	WSADATA wsaData;
	WSAStartup(MAKEWORD(2,2),&wsaData);
#endif
}

CMQGeneral::~CMQGeneral(void)
{
	if ( m_sGeneral )
	{
		delete m_sGeneral;
		m_sGeneral = NULL;
	}
#ifdef WIN32
	WSACleanup();
#endif
}

CMQGeneral* CMQGeneral::Instance(void)
{
	if ( NULL == m_sGeneral )
	{
		m_sGeneral = new CMQGeneral();
	}
	return m_sGeneral;
}
MQ_HANDLE CMQGeneral::GenerateHandle(void)
{
	MQ_HANDLE tmp;
	tmp = ++CMQGeneral::m_sGenId;
	if ( MQ_INVALID_HANDLE == tmp )
	{
		tmp = ++CMQGeneral::m_sGenId;
	}
	return tmp;
}

CMQInstance * CMQGeneral::LookupInstance(MQ_HANDLE hInst)
{
	std::map<MQ_HANDLE,CMQInstance*>::iterator it;
	CMQInstance *pIns = NULL;
	it = m_instList.find(hInst);
	if ( m_instList.end() != it )
	{
		return it->second;
	}
	return NULL;
}

////////////接口实现/////////////////////////
//读取当前线程最后一个错误码
int CMQGeneral::GetLastError(void)
{
	return MQ_ERROR_NOT_IMPL;
}

//获取协议栈版本
unsigned int CMQGeneral::GetSdkVersion(void)
{
	return SDK_VERSION;
}

////////////////接口实现/////////////////////////
//初始化协议栈
int CMQGeneral::InitStack(void)
{
	DEBUG_TRACE("Init Stack.");
	return MQ_NO_ERROR;
}

//反初始化协议栈
int CMQGeneral::CleanupStack(void)
{
	DEBUG_TRACE("Cleanup Stack.");
	return MQ_NO_ERROR;
}

//创建实例
MQ_HANDLE CMQGeneral::CreateInstance(char *pszURI,int *pError)
{
	int iRet = MQ_NO_ERROR;
	if ( !pszURI )
	{
		if ( pError )
		{
			*pError = MQ_ERROR_BAD_PARAMETER;
			ERROR_TRACE("Invalid broker uri.");
		}
		return MQ_INVALID_HANDLE;
	}
	MQ_HANDLE hInst = CMQGeneral::GenerateHandle();
	//}
	CMQInstance *pIns = new CMQInstance(pszURI);
	if ( NULL == pIns )
	{
		if ( pError )
		{
			*pError = MQ_ERROR_OUT_OF_MEMORY;
		}
		return MQ_INVALID_HANDLE;
	}
	m_instList[hInst] = pIns;
	pIns->InstHandle(hInst);
	if ( pError )
	{
		*pError = MQ_NO_ERROR;
	}
	DEBUG_TRACE("Create Instance OK.BrokerUri="<<pszURI<<" Handle="<<hInst<<".");
	return hInst;
}

//销毁实例
int CMQGeneral::ReleaseInstance(MQ_HANDLE hInst)
{
	int iRet;
	CMQInstance *pIns = NULL;
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Release Instance failed.Handle not find. Handle="<<hInst<<".");
//#ifdef _WIN32
//	std::ostringstream   ostrDbg;
//	ostrDbg<<"[mq] Release Instance "<<hInst<<" not find."<<std::endl;
//	OutputDebugStringA(ostrDbg.str().c_str());
//#endif
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	m_instList.erase(hInst);
	iRet = pIns->Stop();
	DEBUG_TRACE("Release Instance OK.Handle="<<hInst<<".");
	delete pIns;
	return iRet;
}

//设置当前终端参数
int CMQGeneral::SetEndpoint(MQ_HANDLE hInst,MQ_ENDPOINT &stEpInfo)
{
	CMQInstance *pIns = NULL;
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("SetEndpoint failed.Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->SetEndpoint(stEpInfo);
}

//订阅主题
int CMQGeneral::SetTopic(MQ_HANDLE hInst,char **pTopic,int iTopicCount)
{
	CMQInstance *pIns = NULL;
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("SetTopic failed.Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->SetTopic(pTopic,iTopicCount);
}

//设置扩展信息
int CMQGeneral::SetExtraInfo(MQ_HANDLE hInst,LPMQ_EXRAINFO pstExtInfo)
{
	CMQInstance *pIns = NULL;
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("SetExtraInfo failed.Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	if ( pstExtInfo == NULL )
	{
		ERROR_TRACE("invalid parameter. Handle="<<hInst<<".");
		return MQ_ERROR_BAD_PARAMETER;
	}
	return pIns->SetExtraInfo(*pstExtInfo);
}

//启动
int CMQGeneral::InstanceStart(MQ_HANDLE hInst)
{
	CMQInstance *pIns = NULL;
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Start Instance failed.Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->Start();
}

//停止
int CMQGeneral::InstanceStop(MQ_HANDLE hInst)
{
	CMQInstance *pIns = NULL;
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Stop Instance failed.Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->Stop();
}

//发送设备状态变化通知消息
int CMQGeneral::DeviceStateNotify(MQ_HANDLE hInst,MQ_DEVICE_STATE stDevState,int iDeliveryMode )
{
	CMQInstance *pIns = NULL;
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->DeviceStateNotify(stDevState,iDeliveryMode);
}
//发送报警通知消息
int CMQGeneral::AlarmNotify(MQ_HANDLE hInst,MQ_ALARM_INFO stAlarmInfo,int iDeliveryMode)
{
	CMQInstance *pIns = NULL;
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->AlarmNotify(stAlarmInfo,iDeliveryMode);
}
//发送设备删除消息
int CMQGeneral::DeviceDelNotify(MQ_HANDLE hInst,MQ_DEVICE_DELETE stDeviceDel,int iDeliveryMode )
{
	CMQInstance *pIns = NULL;
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->DeviceDelNotify(stDeviceDel,iDeliveryMode);
}
//发送设备添加消息
int CMQGeneral::DeviceAddNotify(MQ_HANDLE hInst,MQ_DEVICE_ADD stDeviceAdd,int iDeliveryMode )
{
	CMQInstance *pIns = NULL;
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->DeviceAddNotify(stDeviceAdd,iDeliveryMode);
}
//发送设备更新消息
int CMQGeneral::DeviceUpdateNotify(MQ_HANDLE hInst,MQ_DEVICE_UPDATE stDeviceUpdate,int iDeliveryMode )
{
	CMQInstance *pIns = NULL;
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->DeviceUpdateNotify(stDeviceUpdate,iDeliveryMode);
}

//发送车辆出入消息
int CMQGeneral::VehiclePassInfoNotify(MQ_HANDLE hInst,LPMQ_VEHICLE_PASS_INFO pstVehPassInfo,int iDeliveryMode)
{
	CMQInstance *pIns = NULL;
	if ( !pstVehPassInfo )
	{
		ERROR_TRACE("Invalid parm. Handle="<<hInst<<".");
		return MQ_ERROR_BAD_PARAMETER;
	}
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->VehiclePassInfoNotify(pstVehPassInfo,iDeliveryMode);
}

//发送出入口管理设备消息通知信息
int CMQGeneral::EecNoticeInfoNotify(MQ_HANDLE hInst,LPMQ_EEC_NOTICE_INFO pstEecNoticeInfo,int iDeliveryMode)
{
	CMQInstance *pIns = NULL;
	if ( !pstEecNoticeInfo )
	{
		ERROR_TRACE("Invalid parm. Handle="<<hInst<<".");
		return MQ_ERROR_BAD_PARAMETER;
	}
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->EecNoticeInfoNotify(pstEecNoticeInfo,iDeliveryMode);
}

//发送短信发送反馈消息
int CMQGeneral::SPAlarmSmsReplyInfoNotify(MQ_HANDLE hInst,LPMQ_ALARM_SMS_REPLY_INFO pstSpAlarmSmsReplyNoticeInfo,int iDeliveryMode)
{
	CMQInstance *pIns = NULL;
	if ( !pstSpAlarmSmsReplyNoticeInfo )
	{
		ERROR_TRACE("Invalid parm. Handle="<<hInst<<".");
		return MQ_ERROR_BAD_PARAMETER;
	}
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->SPAlarmSmsReplyInfoNotify(pstSpAlarmSmsReplyNoticeInfo,iDeliveryMode);
}


//发送开锁图片消息
int CMQGeneral::VTHProxy_UnlockPic(MQ_HANDLE hInst,LPMQ_VTHPROXY_UNLOCK_PIC_INFO pstPicInfo,int iDeliveryMode)
{
	CMQInstance *pIns = NULL;
	if ( !pstPicInfo )
	{
		ERROR_TRACE("Invalid parm. Handle="<<hInst<<".");
		return MQ_ERROR_BAD_PARAMETER;
	}
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->VTHProxy_UnlockPic(pstPicInfo,iDeliveryMode);
}
//发送呼叫转移消息
int CMQGeneral::VTHProxy_CallRedirect(MQ_HANDLE hInst,LPMQ_VTHPROXY_CALL_REDIRECT_INFO pstCrInfo,int iDeliveryMode)
{
	CMQInstance *pIns = NULL;
	if ( !pstCrInfo )
	{
		ERROR_TRACE("Invalid parm. Handle="<<hInst<<".");
		return MQ_ERROR_BAD_PARAMETER;
	}
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->VTHProxy_CallRedirect(pstCrInfo,iDeliveryMode);
}

	//发送开锁消息
int CMQGeneral::VTHProxy_Unlock(MQ_HANDLE hInst,LPMQ_VTHPROXY_UNLOCK_REQ_INFO pstUnlockReq,int iDeliveryMode)
{
	CMQInstance *pIns = NULL;
	if ( !pstUnlockReq )
	{
		ERROR_TRACE("Invalid parm. Handle="<<hInst<<".");
		return MQ_ERROR_BAD_PARAMETER;
	}
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->VTHProxy_Unlock(pstUnlockReq,iDeliveryMode);
}
//发送呼叫转移结果反馈消息
int CMQGeneral::VTHProxy_CallRedirectResult(MQ_HANDLE hInst,LPMQ_VTHPROXY_CALL_REDIRECT_RESULT_INFO pstCrResult,int iDeliveryMode)
{
	CMQInstance *pIns = NULL;
	if ( !pstCrResult )
	{
		ERROR_TRACE("Invalid parm. Handle="<<hInst<<".");
		return MQ_ERROR_BAD_PARAMETER;
	}
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->VTHProxy_CallRedirectResult(pstCrResult,iDeliveryMode);
}

/////////////////////ACMS平台消息////////////////////////////////
//发送ACMS平台报警通知消息
int CMQGeneral::ACMS_AlarmNotify(MQ_HANDLE hInst,LPMQ_ACMS_ALARM_NOTIFY_INFO pstAlarmInfo,int iDeliveryMode)
{
	CMQInstance *pIns = NULL;
	if ( !pstAlarmInfo )
	{
		ERROR_TRACE("Invalid parm. Handle="<<hInst<<".");
		return MQ_ERROR_BAD_PARAMETER;
	}
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	return pIns->ACMS_AlarmNotify(pstAlarmInfo,iDeliveryMode);
}
/////////////////////ACMS平台消息////////////////////////////////

//发送消息
int CMQGeneral::SendMsg(MQ_HANDLE hInst,char *pszTopic,char *pMsg,int iLen,int iDeliveryMode)
{
	CMQInstance *pIns = NULL;
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	if ( !pszTopic || !pMsg || iLen <= 0 )
	{
		ERROR_TRACE("Invalid parm. Handle="<<hInst<<".");
		return MQ_ERROR_BAD_PARAMETER;
	}
	return pIns->SendMessage(pszTopic,pMsg,iLen,iDeliveryMode);
}

//发送消息 扩展
int CMQGeneral::SendMsgEx(MQ_HANDLE hInst,char *pszTopic,char *pCmsType,char *pMsg,int iLen,int iDeliveryMode)
{
	CMQInstance *pIns = NULL;
	if ( NULL == (pIns = LookupInstance(hInst)) )
	{
		ERROR_TRACE("Handle not find. Handle="<<hInst<<".");
		return MQ_ERROR_INSTANCE_NON_EXIST;
	}
	if ( !pszTopic || !pMsg || iLen <= 0 )
	{
		ERROR_TRACE("Invalid parm. Handle="<<hInst<<".");
		return MQ_ERROR_BAD_PARAMETER;
	}
	return pIns->SendMessageEx(pszTopic,pCmsType,pMsg,iLen,iDeliveryMode);
}
////////////////接口实现/////////////////////////