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
 ** �ӿڶ���
 ***********************************************************************/

// SDK��ʼ��
ZW_UPNP_API int CALL_METHOD ZW_SH_Init(fDisConnect cbDisConnect,void *pUser);

// SDK�˳�����
ZW_UPNP_API void CALL_METHOD ZW_SH_Cleanup();


// ���ñ����ص�����
ZW_UPNP_API void CALL_METHOD ZW_SH_SetMessCallBack(fMessCallBack cbMessage,void * pUser);

// �����Ƿ��������
ZW_UPNP_API void CALL_METHOD ZW_SH_SetAutoReconnect(bool bReconnect);

// ע��
ZW_UPNP_API UInt32 CALL_METHOD ZW_SH_Login(char *pchServIP,UInt16 wServPort,char *pchServVirtcode,char *pchVirtCode,char *pchPassword,Int32 *error=0);

// ע��
ZW_UPNP_API int CALL_METHOD ZW_SH_Logout(UInt32 hLoginID);

// ǿ���ͷ�һ��ʵ��
ZW_UPNP_API int CALL_METHOD ZW_SH_Release(UInt32 hLoginID);

// ִ�ж���
ZW_UPNP_API int CALL_METHOD ZW_SH_SendMessage(UInt32 hLoginID,LPHTTP_HEADER pHdr,void * pContent,int iContentLength);


// ��ȡ����ip��ַ ��¼�ɹ���,���˵�ip
ZW_UPNP_API char * CALL_METHOD ZW_SH_GetLocalIp(UInt32 hLoginID);

#ifdef __cplusplus
}
#endif

#endif