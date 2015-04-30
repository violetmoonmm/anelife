#ifndef SDKCOMMONDEFINE_H
#define SDKCOMMONDEFINE_H


#if (defined(WIN32) || defined(WIN64))
#define CALL_METHOD  __stdcall
#else
#define CALL_METHOD
#endif

///////////////////类型定义////////////////////////
#define Int16 short
#define UInt16 unsigned short

#define Int32 int
#define UInt32 unsigned int

#define Int64 long long
#define UInt64 unsigned long long

#ifdef __cplusplus
extern "C" {
#endif

///////////////消息类型(请求或回应)///////////////
#define HTTP_TYPE_REQUEST        1        //请求
#define HTTP_TYPE_RESPONSE       2        //回应

///////////////方法类型///////////////
#define	HTTP_METHOD_GET					 1      // http GET
#define	HTTP_METHOD_POST				 2      // http POST
#define	HTTP_METHOD_EX_NOTIFY			 3		 // 扩展 NOTIFY   事件通知
#define	HTTP_METHOD_EX_NOTIFYSTAR		 4      // 扩展 NOTIFY * SSDP
#define	HTTP_METHOD_EX_MSEARCH			 5      // 扩展 M-SEARCH * SSDP
#define	HTTP_METHOD_EX_SUBSCRIBLE		 6      // 扩展 SUBSCRIBLE
#define	HTTP_METHOD_EX_UNSUBSCRIBLE		 7      // 扩展 UNSUBSCRIBLE
#define	HTTP_METHOD_EX_REGISTER			 8      // 扩展 REGISTER
#define	HTTP_METHOD_EX_SEARCH			 9      // 扩展 SEARCH

///////////////HTTP扩展头域///////////////
#define HEADER_NAME_FROM      "From"
#define HEADER_NAME_TO        "To"
#define HEADER_NAME_TAGS      "Tags"
#define HEADER_NAME_ACTION    "ACT"//"NTS"
#define HEADER_NAME_UPNP_AUTHENTICATE    "Upnp-Authenticate"//"Upnp-Authenticate"
#define HEADER_NAME_UPNP_AUTHORIZATION   "Upnp-Authorization"//"Upnp-Authenticate"
#define HEADER_NAME_VERIFY_CODE			 "VerifyCode"//"VerifyCode"

///////////////扩展动作类型///////////////
#define ACTION_REGISTER_REQ				"register"				//注册请求
#define ACTION_REGISTER_RSP				"registerResponse"		//注册回应
#define ACTION_KEEPALIVE_REQ			"keepalive"				//保活请求
#define ACTION_KEEPALIVE_RSP			"keepaliveResponse"		//保活回应
#define ACTION_UNREGISTER_REQ			"unregister"			//注销请求
#define ACTION_UNREGISTER_RSP			"unregisterResponse"	//注销回应
#define ACTION_SEARCH_REQ				"search"				//搜索网关列表请求
#define ACTION_SEARCH_RSP				"searchResponse"		//搜索网关列表回应
#define ACTION_GETDEVLIST_REQ			"getDeviceList"			//获取设备列表请求
#define ACTION_GETDEVLIST_RSP			"getDeviceListResponse"	//获取设备列表回应
#define ACTION_ACTION_REQ				"action"				//控制请求
#define ACTION_ACTION_RSP				"actionResponse"		//控制回应
#define ACTION_QUERY_REQ				"query"					//查询版本信息请求
#define ACTION_QUERY_RSP				"queryResponse"			//查询版本信息回应
#define ACTION_DOWNLOADFILE_REQ			"downloadFile"			//下载文件请求
#define ACTION_DOWNLOADFILE_RSP			"downloadFileResponse"	//下载文件回应
#define ACTION_GATEWAYAUTH_REQ			"gatewayAuth"			//网关认证请求
#define ACTION_GATEWAYAUTH_RSP			"gatewayAuthResponse"	//网关认证回应
#define ACTION_SHBG_NOTIFY_REQ			"shbgNotify"			//智能家居大网关通知消息请求
#define ACTION_SHBG_NOTIFY_RSP			"shbgNotifyResponse"	//智能家居大网关通知消息回应
#define ACTION_ALARM_NOTIFY_REQ			"alarmNotify"			//报警通知消息请求
#define ACTION_ALARM_NOTIFY_RSP			"alarmNotifyResponse"	//报警通知消息回应

#define ACTION_SUBSCRIBLE_REQ			"subscrible"			//订阅请求
#define ACTION_SUBSCRIBLE_RSP			"subscribleResponse"	//订阅回应
#define ACTION_RENEW_REQ				"renew"					//续订请求
#define ACTION_RENEW_RSP				"renewResponse"			//续订回应
#define ACTION_UNSUBSCRIBLE_REQ			"unsubscrible"			//取消订阅请求
#define ACTION_UNSUBSCRIBLE_RSP			"unsubscribleResponse"	//取消订阅回应
#define ACTION_NOTIFY_REQ				"notify"				//事件通知请求
#define ACTION_NOTIFY_RSP				"notifyResponse"		//事件通知回应


#define UPNP_STATUS_CODE_REFUSED			801		//命令被拒绝
#define UPNP_STATUS_CODE_NOT_FOUND			802		//找不到对端
#define UPNP_STATUS_CODE_OFFINE				803		//对端不在线
#define UPNP_STATUS_CODE_BUSY				804		//忙
#define UPNP_STATUS_CODE_BAD_REQUEST		805		//命令无效
#define UPNP_STATUS_CODE_AUTH_FAILED		806		//认证失败
#define UPNP_STATUS_CODE_NEED_AUTH			808		//需要认证
#define UPNP_STATUS_CODE_HAVE_REGISTERED	809		//已经登录
#define UPNP_STATUS_CODE_PASSWORD_INVALID	810		//密码错误
#define UPNP_STATUS_CODE_NOT_REACH			812		//对端不可达


///终端类型
#define ENDPOINT_TYPE_UC			1		//uc
#define ENDPOINT_TYPE_DEVICE		2		//设备
#define ENDPOINT_TYPE_PROXY			3		//代理
#define ENDPOINT_TYPE_FDMS			4		//fdms 设备管理服务器
#define ENDPOINT_TYPE_SHBG			5		//shbg 家庭大网关

#define HTTP_HEADER_NAME_LEN    64      //http头域名称最大长度
#define HTTP_HEADER_VALUE_LEN   256     //http头域内容最大长度
#define HTTP_URI_PATH_LEN       256     //http uri路径最大长度
#define USER_VIRT_CODE_LEN      32     //用户(设备)虚号最大长度
#define HTTP_TAGS_LEN           128    //tags(信令编号)最大长度

//名字-值对
typedef struct
{
	char szName[HTTP_HEADER_NAME_LEN];
	char szValue[HTTP_HEADER_VALUE_LEN];
}NAME_VALUE,*LPNAME_VALUE;

// HTTP头
typedef struct
{
	int iType;                      //类型  1 请求 2 回应
	int iProtocolVer;               //http协议版本 1 1.0 2 1.1 当前只支持1.1版本
	int iMethod;                    //方法 只有请求中有意义
	char szPath[HTTP_URI_PATH_LEN]; //路径 只有请求中有意义
	int iStatusCode;                //状态码 只有回应中有意义
	int iContentLength;             //信息内容长度
	char szFrom[USER_VIRT_CODE_LEN];
	char szTo[USER_VIRT_CODE_LEN];
	char szTags[HTTP_TAGS_LEN];
	char szAction[HTTP_TAGS_LEN];
	int iCount;                     //其他头域数目
	NAME_VALUE hdrs[1];             //其他头域
}HTTP_HEADER, *LPHTTP_HEADER;

typedef struct
{
	int iUserType;			//终端类型(见终端类型定义)
	char szUser[64];		//用户(虚号)
	char szPassword[64];	//密码
	int iResult;			//结果 0 接受 -1 用户不存在
}REGISTER_VERIFY_INFO,*LPREGISTER_VERIFY_INFO;

/************************************************************************
 ** 回调函数定义
 ***********************************************************************/

// 登录成功或断开回调函数原形
//iStatus 0 断开 1 登录成功 2 登录失败
typedef void (CALL_METHOD *fDisConnect)(UInt32 lLoginID,int iStatus,int iReason,void *pUser);

// 消息回调函数原形
typedef void (CALL_METHOD *fMessCallBack)(UInt32 lLoginID,LPHTTP_HEADER pHdr,void * pContent,int iContentLength,void *pUser);

// 登录用户验证回调函数原形 只有代理需要接受其它终端注册时用到
typedef void (CALL_METHOD *fOnLogin)(UInt32 lLoginID,LPREGISTER_VERIFY_INFO pInfo,void *pUser);

#ifdef __cplusplus
}
#endif

#endif