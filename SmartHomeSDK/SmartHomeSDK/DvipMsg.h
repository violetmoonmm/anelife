#ifndef DvipMsg_h
#define DvipMsg_h

#include "Platform.h"
#include <string>
#include <vector>
#include "json.h"


/////////////////大华三代协议格式//////////////////////
///////固定二进制头 固定32字节二进制头
//////扩展头  当前没有
//////json格式消息
//////扩展二进制数据

#define DVIP_HDR_LENGTH  32   //二进制头长度

//消息类型定义
enum EmMsgType
{
    emMsgType_Base,	//基本消息 抽象消息,没有具体实例
    
    emMsgType_instance_req,	//获取
    emMsgType_instance_rsp,	//获取
    emMsgType_destroy_req,	//释放
    emMsgType_destroy_rsp,	//释放
};

////////////////////协议头///////////////////
////所有数据字段采用little endian格式
struct dvip_hdr
{
    unsigned int size; //头长度 默认32字节
    char magic[4]; //magic 'D' 'H' 'I' 'P'
    unsigned int session_id; //会话id 非0的无符号数字 登录成功时由服务端返回,此后整个连接过程唯一,登录请求时应传0
    unsigned int request_id; //请求id 非0的无符号数字 标识一个请求
    unsigned int packet_length; //包长度 非0的无符号数字 登录成功时由服务端返回,此后整个连接过程唯一,登录请求时应传0
    unsigned int packet_index; //包索引 表示分包序号,如果没有分包则为0
    unsigned int message_length; //消息长度 json格式消息内容长度
    unsigned int data_length; //数据长度 扩展二进制数据长度
};

class CDvipMsg
{
public:
    CDvipMsg();
    virtual ~CDvipMsg();
    
    EmMsgType Type()
    {
        return m_iType;
    }
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen) = 0;
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen) = 0;
    
    
    int EncodeHeader(unsigned char *pData,int iDataLen);
    int DecodeHeader(unsigned char *pData,int iDataLen);
    
    dvip_hdr hdr;
    EmMsgType m_iType;
};


////////////////////////通用消息////////////////////////
//无输入和输出参数 返回值为bool 请求
class CMsg_method_v_b_v_req : public CDvipMsg
{
public:
    CMsg_method_v_b_v_req():CDvipMsg()
    {
        m_uiObjectId = 0;
    }
    CMsg_method_v_b_v_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = 0;
    }
    CMsg_method_v_b_v_req(unsigned int uiReqId
                          ,unsigned int uiSessId
                          ,unsigned int uiObjectId
                          ,char *pszMethod)
    :CDvipMsg()
    {
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = uiObjectId;
        m_strMethod = pszMethod;
    }
    CMsg_method_v_b_v_req(unsigned int uiReqId
                          ,unsigned int uiSessId
                          ,EmMsgType emType
                          ,unsigned int uiObjectId
                          ,char *pszMethod)
    :CDvipMsg()
    {
        m_iType = emType;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = uiObjectId;
        m_strMethod = pszMethod;
    }
    ~CMsg_method_v_b_v_req()
    {
    }
    
    // 打包消息
    int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//实例id
    std::string m_strMethod;		//方法名称
};
//无输入和输出参数 返回值为bool 回应
class CMsg_method_v_b_v_rsp : public CDvipMsg
{
public:
    CMsg_method_v_b_v_rsp():CDvipMsg()
    {
        m_bResult = false;
    }
    ~CMsg_method_v_b_v_rsp()
    {
    }
    
    // 打包消息
    int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//结果
};

////////////////////////实例创建、释放/////////////////////
//获取实例 请求
class CMsgDvip_instance_req : public CDvipMsg
{
public:
    CMsgDvip_instance_req():CDvipMsg()
    {
        m_iType = emMsgType_instance_req;
        //m_bNeedDeviceId = false;
        //m_uiObjecId = 0;
    }
    CMsgDvip_instance_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_instance_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        //m_bNeedDeviceId = false;
        //m_uiObjecId = 0;
    }
    CMsgDvip_instance_req(unsigned int uiReqId,unsigned int uiSessId,char *method/*,char *pszDeviceId = 0,bool bNeedId = false*/):CDvipMsg()
    {
        m_iType = emMsgType_instance_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        //m_uiObjecId = uiObjectId;
        //m_bNeedDeviceId = bNeedId;
        m_strMethod = method;
        //if ( pszDeviceId )
        //{
        //	m_strDeviceID = pszDeviceId;
        //}
    }
    CMsgDvip_instance_req(unsigned int uiReqId,unsigned int uiSessId,char *method,const Json::Value &jsParams/*,bool bNeedId = false*/):CDvipMsg()
    {
        m_iType = emMsgType_instance_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        //m_uiObjecId = uiObjectId;
        //m_bNeedDeviceId = bNeedId;
        m_strMethod = method;
        //if ( pszDeviceId )
        //{
        //	m_strDeviceID = pszDeviceId;
        //}
        m_jsParams = jsParams;
    }
    ~CMsgDvip_instance_req()
    {
    }
    
    // 打包消息
    int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    int Decode(char *pData,unsigned int iDataLen);
    
    //bool m_bNeedDeviceId;		//是否需要设备ID,一般在创建子实例时用到,默认为false
    //unsigned int m_uiObjecId;	//实例id
    std::string m_strMethod;	//方法名称
    //std::string m_strDeviceID;	//设备ID
    Json::Value m_jsParams;
};
//获取实例 回应
class CMsgDvip_instance_rsp : public CDvipMsg
{
public:
    CMsgDvip_instance_rsp():CDvipMsg()
    {
        m_iType = emMsgType_instance_rsp;
        m_uiObjectId = 0;
    }
    ~CMsgDvip_instance_rsp()
    {
    }
    
    // 打包消息
    int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjectId;
};

//释放实例 请求
class CMsgDvip_destroy_req : public CDvipMsg
{
public:
    CMsgDvip_destroy_req():CDvipMsg()
    {
        m_iType = emMsgType_destroy_req;
        m_uiObjecId = 0;
    }
    CMsgDvip_destroy_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_destroy_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = 0;
    }
    CMsgDvip_destroy_req(unsigned int uiReqId,unsigned int uiSessId,char *method,unsigned int uiObjectId):CDvipMsg()
    {
        m_iType = emMsgType_destroy_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = uiObjectId;
        m_strMethod = method;
    }
    ~CMsgDvip_destroy_req()
    {
    }
    
    // 打包消息
    int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjecId;
    std::string m_strMethod;
};
//释放智能家居管理实例 回应
class CMsgDvip_destroy_rsp : public CDvipMsg
{
public:
    CMsgDvip_destroy_rsp():CDvipMsg()
    {
        m_iType = emMsgType_destroy_rsp;
        m_bResult = false;
    }
    ~CMsgDvip_destroy_rsp()
    {
    }
    
    // 打包消息
    int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;
};

//输入参数为json(params : {}),输出参数也为json(params : {}) 返回值为bool 请求
class CMsg_method_json_b_json_req : public CDvipMsg
{
public:
    CMsg_method_json_b_json_req():CDvipMsg()
    {
        m_uiObjectId = 0;
    }
    CMsg_method_json_b_json_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = 0;
    }
    CMsg_method_json_b_json_req(unsigned int uiReqId
                                ,unsigned int uiSessId
                                ,unsigned int uiObjectId
                                ,char *pszMethod)
    :CDvipMsg()
    {
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = uiObjectId;
        m_strMethod = pszMethod;
    }
    CMsg_method_json_b_json_req(unsigned int uiReqId
                                ,unsigned int uiSessId
                                ,unsigned int uiObjectId
                                ,char *pszMethod
                                ,Json::Value &params)
    :CDvipMsg()
    {
        //m_iType = emType;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = uiObjectId;
        m_strMethod = pszMethod;
        m_jsParams = params;
    }
    CMsg_method_json_b_json_req(unsigned int uiReqId
                                ,unsigned int uiSessId
                                ,EmMsgType emType
                                ,unsigned int uiObjectId
                                ,char *pszMethod
                                ,Json::Value &params)
    :CDvipMsg()
    {
        m_iType = emType;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = uiObjectId;
        m_strMethod = pszMethod;
        m_jsParams = params;
    }
    ~CMsg_method_json_b_json_req()
    {
    }
    
    // 打包消息
    int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//实例id
    std::string m_strMethod;		//方法名称
    Json::Value m_jsParams;			//输入参数
};
//输入参数为json(params : {}),输出参数也为json(params : {}) 返回值为bool 回应
class CMsg_method_json_b_json_rsp : public CDvipMsg
{
public:
    CMsg_method_json_b_json_rsp():CDvipMsg()
    {
        m_bResult = false;
    }
    ~CMsg_method_json_b_json_rsp()
    {
    }
    
    // 打包消息
    int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;			//结果
    Json::Value m_jsParams;	//输出参数
};
///////////////////////通用消息////////////////////////

#endif
