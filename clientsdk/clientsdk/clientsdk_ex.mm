#include "clientsdk.h"
#include "EndpointUc.h"
#include "Trace.h"

//CShControPoint g_cp;

// SDK初始化
bool CALL_METHOD CLIENT_Init(fOnDisConnect cbDisConnect,void *pUser)
{
	int iRet = 0;

	CEndpointUc::Instance()->SetDisConnectCb(cbDisConnect,pUser);
	iRet = CEndpointUc::Instance()->Start();

	return true;
}

// SDK退出清理
void CALL_METHOD CLIENT_Cleanup()
{
	int iRet =0;
	iRet = CEndpointUc::Instance()->Stop();
}

// 设置状态通知回调
void CALL_METHOD CLIENT_SetEventNotify(bool bEnable,fOnEventNotify cbEventNotify,void *pUser)
{
	CEndpointUc::Instance()->SetEventNotifyCb(bEnable,cbEventNotify,pUser);
}

// 设置自动重连
void CALL_METHOD CLIENT_SetAutoReconnect(bool bEnable)
{
	CEndpointUc::Instance()->SetAutoReconnect(bEnable);
}


// 向设备注册
UInt32 CALL_METHOD CLIENT_Login(char *pchServIP
								,UInt16 wServPort
								,char *pchServVirtcode
								,char *pchVirtCode
								,char *pchPassword
								,Int32 *error)
{
	int iRet = 0;
	UInt32 hLoginId = 0;

	iRet = CEndpointUc::Instance()->CLIENT_Login(pchServIP,wServPort,pchServVirtcode,pchVirtCode,pchPassword);
	if ( 0 == iRet )
	{
		hLoginId = CEndpointUc::Instance()->GetId();
	}
	if ( error )
	{
		*error = iRet;
	}
	return hLoginId;
}

// 向设备注销
bool CALL_METHOD CLIENT_Logout(UInt32 hLoginID)
{
	int iRet = 0;

	iRet = CEndpointUc::Instance()->CLIENT_Logout();

	return iRet == 0 ? true : false;
}
//------------------------------------------------------------------------

// 查询客户端可以控制的UPNP网关列表
bool CALL_METHOD CLIENT_QueryGatewayList(UInt32 hLoginID
										 ,LPUPNP_GATEWAY pUpnpGateway
										 ,Int32 maxlen
										 ,Int32 *devicecount
										 ,Int32 waittime)
{
	bool bRet = false;

	if ( hLoginID != CEndpointUc::Instance()->GetId() )
	{
		ERROR_TRACE("invalid login-id");
		return false;
	}
	if ( !pUpnpGateway || maxlen <= 0 || !devicecount )
	{
		ERROR_TRACE("invalid args");
		return false;
	}
	bRet = CEndpointUc::Instance()->CLIENT_QueryGatewayList(pUpnpGateway,maxlen,devicecount,waittime);
	return bRet;
}

// 获取UPNP设备列表
bool CALL_METHOD CLIENT_GetDeviceList(UInt32 hLoginID
									  ,char *pDeviceUdn
									  ,char *pDeviceLocation
									  ,LPUPNP_DEVICE pUpnpDevice
									  ,Int32 maxlen
									  ,Int32 *devicecount
									  ,Int32 waittime
									  ,Int32 *pError)
{
	bool bRet = false;
	int iRet;

	if ( hLoginID != CEndpointUc::Instance()->GetId() )
	{
		ERROR_TRACE("invalid login-id");
		if ( pError )
		{
			*pError = UPCL_ERROR_INVALID_ARG;
		}
		return false;
	}
	if ( !pDeviceUdn || !pDeviceLocation || !pUpnpDevice || maxlen <= 0 || !devicecount )
	{
		ERROR_TRACE("invalid args");
		if ( pError )
		{
			*pError = UPCL_ERROR_INVALID_ARG;
		}
		return false;
	}
	iRet = CEndpointUc::Instance()->CLIENT_GetDeviceList(pDeviceUdn
														,pDeviceLocation
														,pUpnpDevice
														,maxlen
														,devicecount
														,waittime
														);
	if ( iRet != UPCL_NO_ERROR )
	{
		bRet = false;
		if ( pError )
		{
			*pError = iRet;
		}
	}
	else
	{
		bRet = true;
	}
	return bRet;
}

// 设备控制
bool CALL_METHOD CLIENT_Control(UInt32 hLoginID
								,char *pDeviceVCode
								,char *pControlUrl
								,char *pServiceType
								,char *pActionName
								,LPACTION_PARAM pInParam
								,Int32 incount
								,LPACTION_PARAM pOutParam
								,Int32 maxlen
								,Int32 *outcount
								,Int32 waittime
								,Int32 *pError)
{
	int iRet;
	bool bRet = false;
	if ( hLoginID != CEndpointUc::Instance()->GetId() )
	{
		ERROR_TRACE("invalid login-id");
		if ( pError )
		{
			*pError = UPCL_ERROR_INVALID_ARG;
		}
	}
	if ( !pDeviceVCode || !pControlUrl || !pServiceType || !pActionName )
	{
		ERROR_TRACE("invalid args");
		if ( pError )
		{
			*pError = UPCL_ERROR_INVALID_ARG;
		}
	}
	
	if ( incount > 0 && !pInParam || maxlen > 0 && !pOutParam || !outcount )
	{
		ERROR_TRACE("invalid args");
		if ( pError )
		{
			*pError = UPCL_ERROR_INVALID_ARG;
		}
	}

	iRet = CEndpointUc::Instance()->CLIENT_Control(pDeviceVCode
													,pControlUrl
													,pServiceType
													,pActionName
													,pInParam
													,incount
													,pOutParam
													,maxlen
													,outcount
													,waittime
													);
	if ( iRet != UPCL_NO_ERROR )
	{
		bRet = false;
		if ( pError )
		{
			*pError = iRet;
		}
	}
	else
	{
		bRet = true;
	}
	return bRet;
}

// 查询配置文件版本信息
bool CALL_METHOD CLIENT_GetConfigVerion(UInt32 hLoginID,char *pDeviceVCode,LPCONFIG_VERSION pVer,Int32 waittime)
{
	int iRet = 0;
	if ( hLoginID != CEndpointUc::Instance()->GetId() )
	{
		ERROR_TRACE("invalid login-id");
		return false;
	}
	if ( !pDeviceVCode || !pVer )
	{
		ERROR_TRACE("invalid args");
		return false;
	}
	iRet = CEndpointUc::Instance()->CLIENT_GetConfigVerion(pDeviceVCode,pVer,waittime);
	if ( 0 == iRet )
	{
		return true;
	}
	else
	{
		return false;
	}
}

// 查询配置文件版本信息
bool CALL_METHOD CLIENT_DownloadConfigFile(UInt32 hLoginID,char *pDeviceVCode,char *pFileUrl,char *pszSaveFile,Int32 waittime)
{
	int iRet = 0;
	if ( hLoginID != CEndpointUc::Instance()->GetId() )
	{
		ERROR_TRACE("invalid login-id");
		return false;
	}
	if ( !pDeviceVCode || !pFileUrl || !pszSaveFile )
	{
		ERROR_TRACE("invalid args");
		return false;
	}
	iRet = CEndpointUc::Instance()->CLIENT_DownloadConfigFile(pDeviceVCode,pFileUrl,pszSaveFile,waittime);
	if ( 0 == iRet )
	{
		return true;
	}
	else
	{
		return false;
	}
}

// 获取房间信息
bool CALL_METHOD CLIENT_GetLayout(UInt32 hLoginID
								  ,char *pDeviceVCode
								  ,LPLAYOUT_FLOOR pFloors
								  ,Int32 maxFloors
								  ,Int32 *floors
								  ,LPLAYOUT_ROOM pRooms
								  ,Int32 maxRooms
								  ,Int32 *rooms
								  ,Int32 waittime
								  ,Int32 *pError)
{
	bool bRet = false;
	int iRet;

	if ( hLoginID != CEndpointUc::Instance()->GetId() )
	{
		ERROR_TRACE("invalid login-id");
		if ( pError )
		{
			*pError = UPCL_ERROR_INVALID_ARG;
		}
		return false;
	}
	if ( !pDeviceVCode || !floors || !rooms )
	{
		ERROR_TRACE("invalid args");
		if ( pError )
		{
			*pError = UPCL_ERROR_INVALID_ARG;
		}
		return false;
	}
	if ( !pFloors && maxFloors>0 || !pRooms && maxRooms>0 )
	{
		ERROR_TRACE("invalid param.");
		if ( pError )
		{
			*pError = UPCL_ERROR_INVALID_ARG;
		}
		return false;
	}

	iRet = CEndpointUc::Instance()->CLIENT_GetLayout(pDeviceVCode
														,pFloors
														,maxFloors
														,floors
														,pRooms
														,maxRooms
														,rooms
														,waittime
														);
	if ( iRet != UPCL_NO_ERROR )
	{
		bRet = false;
		if ( pError )
		{
			*pError = iRet;
		}
	}
	else
	{
		bRet = true;
	}
	return bRet;
}

//批量订阅服务
bool CLIENT_Subscrible_Batch(UInt32 hLoginID,LPSUBSCRIBLE_INFO pSubList,Int32 iCount)
{
	int iRet = 0;
	bool bRet = false;
	if ( hLoginID != CEndpointUc::Instance()->GetId() )
	{
		ERROR_TRACE("invalid login-id");
		return false;
	}
	if ( !pSubList )
	{
		ERROR_TRACE("invalid args");
		return false;
	}

	iRet = CEndpointUc::Instance()->CLIENT_Subscrible_Batch(pSubList,iCount,5000);
	if ( 0 == iRet )
	{
		return true;
	}
	else
	{
		return false;
	}
}

//设备认证
bool CLIENT_DeviceAuth(UInt32 hLoginID
					   ,char *pszDeviceVcode
					   ,char *pszUser
					   ,char *pszPassword
					   ,char *pszDeviceSn
					   ,Int32 waittime
					   ,Int32 *pError
					   )
{
	int iRet = 0;
	bool bRet = false;
	if ( hLoginID != CEndpointUc::Instance()->GetId() )
	{
		ERROR_TRACE("invalid login-id");
		if ( pError )
		{
			*pError = UPCL_ERROR_INVALID_ARG;
		}
		return false;
	}
	if ( !pszDeviceVcode || !pszUser || !pszDeviceSn )
	{
		ERROR_TRACE("invalid args");
		if ( pError )
		{
			*pError = UPCL_ERROR_INVALID_ARG;
		}
		return false;
	}

	iRet = CEndpointUc::Instance()->CLIENT_DeviceAuth(pszDeviceVcode,pszUser,pszPassword,pszDeviceSn,waittime);
	if ( iRet != UPCL_NO_ERROR )
	{
		bRet = false;
		if ( pError )
		{
			*pError = iRet;
		}
	}
	else
	{
		bRet = true;
	}
	return bRet;
}

//设备配置变更查询
bool CLIENT_QueryDeviceConfigChange(UInt32 hLoginID
									,char *pszDeviceVcode
									,char *pszChangeId
									,Int32 bufferlen
									,Int32 waittime
									,Int32 *pError
									)
{
	int iRet = 0;
	bool bRet = false;
	std::string strChangeId;

	if ( hLoginID != CEndpointUc::Instance()->GetId() )
	{
		ERROR_TRACE("invalid login-id");
		if ( pError )
		{
			*pError = UPCL_ERROR_INVALID_ARG;
		}
		return false;
	}
	if ( !pszChangeId )
	{
		ERROR_TRACE("invalid args");
		if ( pError )
		{
			*pError = UPCL_ERROR_INVALID_ARG;
		}
		return false;
	}

	iRet = CEndpointUc::Instance()->CLIENT_QueryDeviceConfigChange(pszDeviceVcode,strChangeId,waittime);
	if ( 0 == iRet )
	{
		if ( strChangeId.size() > bufferlen )
		{
			ERROR_TRACE("buffer is too small.");
			if ( pError )
			{
				*pError = UPCL_ERROR_BUFFER_TOO_SMALL;
			}
			return false;
		}
		strcpy(pszChangeId,strChangeId.c_str());
		return true;
	}
	else
	{
		if ( pError )
		{
			*pError = iRet;
		}
		return false;
	}
}

//设置用户网关绑定关系信息,设置时清除以前的所有信息,因此必须调用该接口因此设置所有
bool CLIENT_SetGatewayUserList(UInt32 hLoginID,LPGATEWAY_USER pUserList,Int32 count)
{
	int iRet = 0;
	bool bRet = false;
	std::string strCahngeId;

	if ( hLoginID != CEndpointUc::Instance()->GetId() )
	{
		ERROR_TRACE("invalid login-id");
		return false;
	}
	if ( !pUserList || count <= 0 )
	{
		ERROR_TRACE("invalid args");
		return false;
	}

	iRet = CEndpointUc::Instance()->CLIENT_SetGatewayUserList(pUserList,count);
	if ( 0 == iRet )
	{
		return true;
	}
	else
	{
		return false;
	}
}

// 获取UPNP设备列表 返回为UPNP的设备描述Xml文件
bool CALL_METHOD CLIENT_GetDeviceListEx(UInt32 hLoginID
										,char *pDeviceVirtCode
										,char *pDeviceLocation
										,char **pDevices
										,int *iLen,Int32 waittime
										,Int32 *pError)
{
	int iRet;
	bool bRet = false;
	std::string strDeviceList;

	if ( hLoginID != CEndpointUc::Instance()->GetId() )
	{
		ERROR_TRACE("invalid login-id");
		if ( pError )
		{
			*pError = UPCL_ERROR_INVALID_ARG;
		}
		return false;
	}
	if ( !pDeviceVirtCode || !pDeviceLocation || !pDevices || !iLen )
	{
		ERROR_TRACE("invalid args");
		if ( pError )
		{
			*pError = UPCL_ERROR_INVALID_ARG;
		}
		return false;
	}
	iRet = CEndpointUc::Instance()->CLIENT_GetDeviceList(pDeviceVirtCode,pDeviceLocation,strDeviceList,waittime);
	if ( bRet )
	{
		if ( strDeviceList.empty() )
		{
			*pDevices = NULL;
			*iLen = 0;
		}
		else
		{
			//char *pBuf;
			//int iBufLen;
			*iLen = strDeviceList.size()+1;
			//iBufLen = *iLen;
			*pDevices = (char*)malloc(*iLen);
			if ( !(*pDevices) )
			{
				ERROR_TRACE("out of memory");
				return false;
			}
			memcpy(*pDevices,strDeviceList.c_str(),strDeviceList.size());
			(*pDevices)[(*iLen)-1] = '\0';
		}
	}
	if ( iRet != UPCL_NO_ERROR )
	{
		bRet = false;
		if ( pError )
		{
			*pError = iRet;
		}
	}
	else
	{
		if ( strDeviceList.empty() )
		{
			*pDevices = NULL;
			*iLen = 0;
			bRet = true;
		}
		else
		{
			*iLen = strDeviceList.size()+1;
			*pDevices = (char*)malloc(*iLen);
			if ( !(*pDevices) )
			{
				ERROR_TRACE("out of memory");
				if ( pError )
				{
					*pError = UPCL_ERROR_NO_MORE_RESOURCE;
				}
				bRet = false;
			}
			else
			{
				memcpy(*pDevices,strDeviceList.c_str(),strDeviceList.size());
				(*pDevices)[(*iLen)-1] = '\0';
				bRet = true;
			}
		}
	}
	return bRet;
}

// 获取UPNP设备列表 返回为UPNP的设备描述Xml文件
void CALL_METHOD CLIENT_FreeBuf(char *pBuf)
{
	if ( pBuf == NULL )
	{
		return ;
	}
	free(pBuf);
	pBuf = NULL;
}