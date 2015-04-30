#ifndef PROXYAPI_H
#define PROXYAPI_H

#include "SdkCommonDefine.h"

#if (defined(WIN32) || defined(WIN64))

#ifdef ZW_ICMS_UPNP_EXPORTS

#ifndef ZW_UPNP_API
#define ZW_UPNP_API  __declspec(dllexport) 
#endif

#else

#ifndef ZW_UPNP_API
#define ZW_UPNP_API  __declspec(dllimport)
#endif

#endif

//#define CALL_METHOD  __stdcall

#else

#define ZW_UPNP_API	extern "C"
//#define CALL_METHOD

#endif


#ifdef __cplusplus
extern "C" {
#endif


/************************************************************************
 ** 接口定义
 ***********************************************************************/

// SDK初始化
ZW_UPNP_API int CALL_METHOD ZW_SH_Init(fDisConnect cbDisConnect,void *pUser);

// SDK退出清理
ZW_UPNP_API void CALL_METHOD ZW_SH_Cleanup();


// 设置报警回调函数
ZW_UPNP_API void CALL_METHOD ZW_SH_SetMessCallBack(fMessCallBack cbMessage,void * pUser);

// 设置是否断线重连
ZW_UPNP_API void CALL_METHOD ZW_SH_SetAutoReconnect(bool bReconnect);

// 注册
ZW_UPNP_API UInt32 CALL_METHOD ZW_SH_Login(char *pchServIP,UInt16 wServPort,char *pchServVirtcode,char *pchVirtCode,char *pchPassword,Int32 *error=0);

// 注销
ZW_UPNP_API int CALL_METHOD ZW_SH_Logout(UInt32 hLoginID);

// 强制释放一个实例
ZW_UPNP_API int CALL_METHOD ZW_SH_Release(UInt32 hLoginID);

// 执行动作
ZW_UPNP_API int CALL_METHOD ZW_SH_SendMessage(UInt32 hLoginID,LPHTTP_HEADER pHdr,void * pContent,int iContentLength);


// 获取本端ip地址 登录成功后,本端的ip
ZW_UPNP_API char * CALL_METHOD ZW_SH_GetLocalIp(UInt32 hLoginID);

#ifdef __cplusplus
}
#endif

#endif