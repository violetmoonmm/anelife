#include "UcApi.h"
#include "IcmsUpnpStack.h"
#include "Trace.h"

// SDK初始化
int CALL_METHOD ZW_SH_Init(fDisConnect cbDisConnect,void *pUser)
{
	int iRet;
	//设置回调
	CIcmsUpnpStack::Instance()->SetDisconnectCallback(cbDisConnect,pUser);
	//设置本端类型
	CIcmsUpnpStack::Instance()->SetLocalType(emEpType_ControlPint);
	iRet = CIcmsUpnpStack::Instance()->Init();
	return iRet;
}

// SDK退出清理
void CALL_METHOD ZW_SH_Cleanup()
{
	CIcmsUpnpStack::Instance()->UnInit();
	return ;
}

// 设置报警回调函数
void CALL_METHOD ZW_SH_SetMessCallBack(fMessCallBack cbMessage,void * pUser)
{
	CIcmsUpnpStack::Instance()->SetMessageCallback(cbMessage,pUser);
}

// 设置是否断线重连
void CALL_METHOD ZW_SH_SetAutoReconnect(bool bReconnect)
{
	CIcmsUpnpStack::Instance()->SetAutoReconnect(bReconnect);
}

// 注册
UInt32 CALL_METHOD ZW_SH_Login(char *pchServIP,UInt16 wServPort,char *pchServVirtcode,char *pchVirtCode,char *pchPassword,Int32 *error)
{
	//int iRet = 0;
	UInt32 hLoginId = 0;

	hLoginId = CIcmsUpnpStack::Instance()->Login(pchServIP,wServPort,pchServVirtcode,pchVirtCode,pchPassword,error);

	if ( 0 == hLoginId )
	{
		//hLoginId = CShControPoint::Instance()->GetId();
	}
	else
	{
	}
	return hLoginId;
}

// 注销
int CALL_METHOD ZW_SH_Logout(UInt32 hLoginID)
{
	int iRet = 0;

	iRet = CIcmsUpnpStack::Instance()->Logout(hLoginID);

	return iRet;
}

// 强制释放一个实例
int CALL_METHOD ZW_SH_Release(UInt32 hLoginID)
{
	int iRet = 0;

	iRet = CIcmsUpnpStack::Instance()->Force_Release(hLoginID);

	return iRet;
}

// 执行动作
int CALL_METHOD ZW_SH_SendMessage(UInt32 hLoginID,LPHTTP_HEADER pHdr,void * pContent,int iContentLength)
{
	int iRet = 0;

	iRet = CIcmsUpnpStack::Instance()->SendMessage(hLoginID,pHdr,pContent,iContentLength);


	return iRet;
}

// 获取本端ip地址 登录成功后,本端的ip
char * CALL_METHOD ZW_SH_GetLocalIp(UInt32 hLoginID)
{
	int iRet = 0;
	static char s_local_ip[32] = {0};
	std::string strIp;

	strIp = CIcmsUpnpStack::Instance()->GetLocalIp(hLoginID);
	if ( strIp.empty() )
	{
		s_local_ip[0] = '\0';
	}
	else
	{
		strcpy(s_local_ip,strIp.c_str());
	}

	return s_local_ip;
}