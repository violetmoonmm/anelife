#ifndef CLIENTSDK_H
#define CLIENTSDK_H


#if (defined(WIN32) || defined(WIN64))

#ifdef CLIENTSDK_EXPORTS

#ifndef CLIENT_API
#define CLIENT_API  __declspec(dllexport)
#endif

#else

#ifndef CLIENT_API
#define CLIENT_API  __declspec(dllimport)
#endif

#endif

#define CALLBACK __stdcall
#define CALL_METHOD  __stdcall  //__cdecl



#else	//linux

#define CLIENT_API	extern "C"
#define CALL_METHOD
#define CALLBACK


#endif


#define Int16 short
#define UInt16 unsigned short

#define Int32 int
#define UInt32 unsigned int

#define Int64 long long
#define UInt64 unsigned long long

#ifdef __cplusplus
extern "C" {
#endif
    
    /************************************************************************
     ** 常量定义
     ***********************************************************************/
#define VIRT_CODE_LEN 			    64			// 虚号最大长度
    #define UDN_LEN 				    256			// UDN最大长度
    #define LOCATION_LEN 				512			// Location最大长度
    #define DEVICETYPE_LEN 				256			// 设备类型最大长度
    #define DEVICENAME_LEN 				256			// 设备名称最大长度
    #define PARAM_LEN 				    64			// 参数最大长度
    #define MAX_SERVICE_LEN 		    256			// 最大长度
    #define MAX_SERVICE_NUM 		    32			// 一个设备拥有最大服务数目
    #define MAX_PATH_LEN 		        260			// 文件路径最大长度
    
#define MAX_LAYOUT_NAME				64
    
    ///错误码
    #define UPCL_NO_ERROR					0		//成功
    #define UPCL_ERROR_UNKNOWN				-1		//未知
    #define UPCL_ERROR_NOT_REGISTER			-101	//没有注册
    #define UPCL_ERROR_NO_MORE_RESOURCE		-102	//系统资源不足
    #define UPCL_ERROR_SYSTEM_FAULT			-103	//系统错误
    #define UPCL_ERROR_NETWORK				-104	//系统错误
    #define UPCL_ERROR_TIMEOUT				-105	//超时
    
#define UPCL_ERROR_REFUSED				-106	//命令被拒绝
    #define UPCL_ERROR_NOT_FOUND			-107	//用户(或设备)不存在
    #define UPCL_ERROR_OFFINE				-108	//用户(或设备)不在线
    #define UPCL_ERROR_PASSWORD_INVALID		-109	//密码无效
    #define UPCL_ERROR_DUPLICATE_REGISTER	-110	//重复登录
    #define UPCL_ERROR_NOT_REACH			-111	//对端不可达
    #define UPCL_ERROR_INVALID_ARG			-112	//参数非法
    #define UPCL_ERROR_BUFFER_TOO_SMALL		-113	//缓冲区太小
    
    /************************************************************************
     ** 枚举定义
     ***********************************************************************/
    
    /************************************************************************
     ** 结构体定义
     ***********************************************************************/
    // 网关信息
    typedef struct
    {
        char          szVirtCode[VIRT_CODE_LEN];	    // 虚号
        char          szUdn[UDN_LEN];					// udn
        char		  szLocation[LOCATION_LEN];			// path
    } UPNP_GATEWAY,*LPUPNP_GATEWAY;
    
    // 服务信息
    typedef struct
    {
        char          szType[MAX_SERVICE_LEN];	       // 服务类型
        char          szId[MAX_SERVICE_LEN];		   // 服务ID
        char          szControlUrl[MAX_SERVICE_LEN];   // 服务控制url
        char          szEventUrl[MAX_SERVICE_LEN];     // 服务事件订阅url
        bool          bCanSubscrible;                  // 服务是否支持订阅
    }UPNP_SERVICE,*LPUPNP_SERVICE;
    
    // 设备信息
    typedef struct
    {
        char          szUdn[UDN_LEN];					// udn
        char          szDeviceType[DEVICETYPE_LEN];		// 设备类型
        char          szFriendlyName[DEVICENAME_LEN];   // 设备名称
        char          szRoomId[MAX_LAYOUT_NAME];		// 设备所在房间
        char		  szCameraId[DEVICENAME_LEN];		//
        int           iServiceCount;                    // 服务数目
        UPNP_SERVICE  stServiceList[MAX_SERVICE_NUM];   //服务列表
        
    }UPNP_DEVICE, *LPUPNP_DEVICE;
    
    // 楼层信息
    typedef struct
    {
        char szId[MAX_LAYOUT_NAME];		//编号
        char szName[MAX_LAYOUT_NAME];	//名称
    }LAYOUT_FLOOR,*LPLAYOUT_FLOOR;
    
    // 房间信息
    typedef struct
    {
        char szId[MAX_LAYOUT_NAME];		//编号
        char szFloor[MAX_LAYOUT_NAME];	//楼层
        int iType;						//节点类型: 0 未定义 1 厨房 2 客厅 3 餐厅 4 卧室 5 卫生间 6 书房
        char szName[MAX_LAYOUT_NAME];  //名称
    }LAYOUT_ROOM,*LPLAYOUT_ROOM;
    
    // 参数信息
    typedef struct
    {
        char          szName[PARAM_LEN];				// udn
        char          szValue[PARAM_LEN];				// 设备类型
    }ACTION_PARAM, *LPACTION_PARAM;
    
    // 配置文件版本信息
    typedef struct
    {
        char          szCfgType[64];				// 配置文件类型 1|2|3
        char          szCfgVersion[64];				// 配置文件版本号 11|23|1
        char		  szFileUrl[MAX_PATH_LEN];      //文件路径
    }CONFIG_VERSION, *LPCONFIG_VERSION;
    
    // 订阅信息
    typedef struct
    {
        char          szVcode[VIRT_CODE_LEN];			//设备所属网关
        char          szUdn[UDN_LEN];					// 设备UDN
        char		  szServiceType[MAX_SERVICE_LEN];   //服务类型
        char		  szServiceId[MAX_SERVICE_LEN];		//服务Id
        char		  szEventSubUrl[MAX_SERVICE_LEN];   //服务订阅url
    }SUBSCRIBLE_INFO, *LPSUBSCRIBLE_INFO;
    
    
    //绑定网关用户
    typedef struct
    {
        char szVcode[VIRT_CODE_LEN];	//网关虚号
        char szSn[64];					//网关设备序列号
        char szUser[64];				//用户名
        char szPassword[64];			//密码
    }GATEWAY_USER,*LPGATEWAY_USER;
    
    /************************************************************************
     ** 回调函数定义
     ***********************************************************************/
    
    // 网络连接断开回调函数原形
    typedef void (CALLBACK *fOnDisConnect)(UInt32 lLoginID, char *pchServIP, UInt16 nServPort, void *pUser);
    
    // 设备状态变化通知回调函数原形
    typedef void (CALLBACK *fOnEventNotify)(UInt32 lLoginID, char *pszUdn, char *pszServiceType,char *pszEventUrl,LPACTION_PARAM pParams,int iCount,void *pUser);
    
    /************************************************************************
     ** 接口定义
     ***********************************************************************/
    
    // SDK初始化
    CLIENT_API bool CALL_METHOD CLIENT_Init(fOnDisConnect cbDisConnect,void *pUser);
    
    // SDK退出清理
    CLIENT_API void CALL_METHOD CLIENT_Cleanup();
    
    // 设置状态通知回调
    CLIENT_API void CALL_METHOD CLIENT_SetEventNotify(bool bEnable,fOnEventNotify cbEventNotify,void *pUser);
    
    // 设置自动重连
    //CLIENT_API void CALL_METHOD CLIENT_SetAutoReconnect(bool bEnable);
    
    //------------------------------------------------------------------------
    
    
    //------------------------------------------------------------------------
    
    // 向设备注册
    CLIENT_API UInt32 CALL_METHOD CLIENT_Login(char *pchServIP,UInt16 wServPort,char *pchServVirtcode,char *pchVirtCode,char *pchPassword,Int32 *error=0);
    
    
    // 向设备注销
    CLIENT_API bool CALL_METHOD CLIENT_Logout(UInt32 hLoginID);
    
    //------------------------------------------------------------------------
    
    //// 查询客户端可以控制的UPNP网关列表
    //CLIENT_API bool CALL_METHOD CLIENT_QueryGatewayList(UInt32 hLoginID,LPUPNP_GATEWAY pUpnpGateway,Int32 maxlen,Int32 *devicecount,Int32 waittime=1000);
    
    // 获取UPNP设备列表
    CLIENT_API bool CALL_METHOD CLIENT_GetDeviceList(UInt32 hLoginID,char *pDeviceVirtCode,char *pDeviceLocation,LPUPNP_DEVICE pUpnpDevice,Int32 maxlen,Int32 *devicecount,Int32 waittime=1000,Int32 *pError=0);
    
    // 设备控制
    CLIENT_API bool CALL_METHOD CLIENT_Control(UInt32 hLoginID,char *pDeviceVCode,char *pControlUrl,char *pServiceType,char *pActionName,LPACTION_PARAM pInParam,Int32 incount,LPACTION_PARAM pOutParam,Int32 maxlen,Int32 *outcount,Int32 waittime=1000,Int32 *pError=0);
    
    //// 查询配置文件版本信息
    //CLIENT_API bool CALL_METHOD CLIENT_GetConfigVerion(UInt32 hLoginID,char *pDeviceVCode,LPCONFIG_VERSION pVer,Int32 waittime=1000);
    //
    //// 查询配置文件版本信息
    //CLIENT_API bool CALL_METHOD CLIENT_DownloadConfigFile(UInt32 hLoginID,char *pDeviceVCode,char *pFileUrl,char *pszSaveFile,Int32 waittime=1000);
    
    
    // 获取房间信息
    CLIENT_API bool CALL_METHOD CLIENT_GetLayout(UInt32 hLoginID
                                                 ,char *pDeviceVCode
                                                 ,LPLAYOUT_FLOOR pFloors
                                                 ,Int32 maxFloors
                                                 ,Int32 *floors
                                                 ,LPLAYOUT_ROOM pRooms
                                                 ,Int32 maxRooms
                                                 ,Int32 *rooms
                                                 ,Int32 waittime=1000
                                                 ,Int32 *pError=0);
    
    //批量订阅服务
    CLIENT_API bool CLIENT_Subscrible_Batch(UInt32 hLoginID,LPSUBSCRIBLE_INFO pSubList,Int32 iCount);
    
    //设备认证
    CLIENT_API bool CLIENT_DeviceAuth(UInt32 hLoginID,char *pszDeviceVcode,char *pszUser,char *pszPassword,char *pszDeviceSn,Int32 waittime=1000,Int32 *pError=0);
    //设备配置变更查询
    CLIENT_API bool CLIENT_QueryDeviceConfigChange(UInt32 hLoginID,char *pszDeviceVcode,char *pszChangeId,Int32 bufferlen,Int32 waittime=1000,Int32 *pError=0);
    
    //设置用户网关绑定关系信息,设置时清除以前的所有信息,因此必须调用该接口因此设置所有用户网关绑定信息
    CLIENT_API bool CLIENT_SetGatewayUserList(UInt32 hLoginID,LPGATEWAY_USER pUserList,Int32 count);
    
    // 获取UPNP设备列表 返回为UPNP的设备描述Xml文件
    CLIENT_API bool CALL_METHOD CLIENT_GetDeviceListEx(UInt32 hLoginID,char *pDeviceVirtCode,char *pDeviceLocation,char **pDevices,int *iLen,Int32 waittime=1000,Int32 *pError=0);
    
    // 获取UPNP设备列表 返回为UPNP的设备描述Xml文件
    CLIENT_API void CALL_METHOD CLIENT_FreeBuf(char *pBuf);
    
#ifdef __cplusplus
}
#endif

#endif // CLIENTSDK_H
