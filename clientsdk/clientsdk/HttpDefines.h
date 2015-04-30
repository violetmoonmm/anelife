#ifndef HTTPDEFINES_H
#define HTTPDEFINES_H

//////////////http头域定义////////////
/////////////自定义部分
//#define MY_FROM      "From"
//#define MY_TO        "To"
//#define MY_TAGS      "Tags"
//#define MY_ACTION    "NTS"
//
//#define METHOD_REGISTER_REQ		"register"
//#define METHOD_REGISTER_RSP		"registerResponse"
//#define METHOD_KEEPALIVE_REQ	"keepalive"
//#define METHOD_KEEPALIVE_RSP	"keepaliveResponse"
//#define METHOD_UNREGISTER_REQ	"unregister"
//#define METHOD_UNREGISTER_RSP	"unregisterResponse"

typedef enum EMMethod
{
	emMethod_RegisterReq    = 1,
	emMethod_RegisterRsp    = 2,
	emMethod_KeepaliveReq   = 3,
	emMethod_KeepaliveRsp	= 4,
	emMethod_UnRegisterReq	= 5,
	emMethod_UnRegisterRsp	= 6,

};
#endif
