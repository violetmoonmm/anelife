#include "DvipMsg.h"
#include "Platform.h"
#include "json.h"
#include "Trace.h"

CDvipMsg::CDvipMsg()
{
    m_iType = emMsgType_Base;
    memset(&hdr,0,sizeof(hdr));
    hdr.size = DVIP_HDR_LENGTH;
    hdr.magic[0] = 'D';
    hdr.magic[1] = 'H';
    hdr.magic[2] = 'I';
    hdr.magic[3] = 'P';
}
CDvipMsg::~CDvipMsg()
{
}

int CDvipMsg::EncodeHeader(unsigned char *pData,int iDataLen)
{
    if ( !pData || iDataLen < DVIP_HDR_LENGTH )
    {
        return -1;
    }
    memset(pData,0,DVIP_HDR_LENGTH);
    
    memcpy(pData,(char*)&hdr,sizeof(hdr));
    
    return 0;
}
int CDvipMsg::DecodeHeader(unsigned char *pData,int iDataLen)
{
    if ( !pData || iDataLen < DVIP_HDR_LENGTH )
    {
        return -1;
    }
    
    memcpy((char*)&hdr,pData,sizeof(hdr));
    
    return 0;
}


////////////////////////通用消息////////////////////////
//无输入和输出参数 返回值为bool 请求

// 打包消息
int CMsg_method_v_b_v_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    if ( 0 != m_uiObjectId )
    {
        jsonContent["object"] = m_uiObjectId; //objectid
    }
    jsonContent["method"] = m_strMethod; //方法
    ////参数列表 无参数
    
    strContent = jsonContent.toStyledString();
    uiContentLength = strContent.size();
    hdr.packet_length = uiContentLength;
    hdr.message_length = uiContentLength;
    
    if ( iDataLen < uiContentLength+DVIP_HDR_LENGTH )
    {
        ERROR_TRACE("buffer too small");
        return -1;
    }
    
    int iRet = CDvipMsg::EncodeHeader((unsigned char*)pData,iDataLen);
    if ( 0 != iRet )
    {
        ERROR_TRACE("encode header failed");
        return -1;
    }
    memcpy(pData+DVIP_HDR_LENGTH,strContent.c_str(),uiContentLength);
    
    return (int)(DVIP_HDR_LENGTH+uiContentLength);
}
// 解包消息
int CMsg_method_v_b_v_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//无输入和输出参数 返回值为bool 回应
// 打包消息
int CMsg_method_v_b_v_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsg_method_v_b_v_rsp::Decode(char *pData,unsigned int iDataLen)
{
    int iRet;
    Json::Reader jsonParser;
    Json::Value jsonContent;
    bool bRet;
    
    iRet = CDvipMsg::DecodeHeader((unsigned char*)pData,iDataLen);
    if ( 0 != iRet )
    {
        ERROR_TRACE("decode header failed");
        return -1;
    }
    
    if ( hdr.message_length == 0 )
    {
        ERROR_TRACE("invalid msg no msg body.");
        return -1;
    }
    
    bRet = jsonParser.parse(pData+DVIP_HDR_LENGTH,pData+DVIP_HDR_LENGTH+hdr.message_length,jsonContent);
    if ( !bRet )
    {
        ERROR_TRACE("parse msg body failed");
        return -1;
    }
    
    unsigned int uiReqId = jsonContent["id"].asUInt();
    unsigned int uiSessionId = jsonContent["session"].asUInt();
    if ( uiReqId != hdr.request_id || uiSessionId != hdr.session_id )
    {
        ERROR_TRACE("reqid or sessid not same with hdr");
        return -1;
    }
    
    //
    if ( jsonContent["result"].isNull()
        || !jsonContent["result"].isBool() ) //结果
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    return 0;
}


///获取实例 请求
// 打包消息
int CMsgDvip_instance_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    //if ( m_bNeedObjecId )
    //{
    //	jsonContent["object"] = m_uiObjecId; //objectid
    //}
    //if ( m_bNeedDeviceId )
    //{
    //	jsonContent["params"]["DeviceID"] = m_strDeviceID; //DeviceID
    //}
    //else
    if ( !m_jsParams.isNull() )
    {
        jsonContent["params"] = m_jsParams;
    }
    jsonContent["method"] = m_strMethod; //方法 获取实例ID
    ////参数列表 无参数
    
    strContent = jsonContent.toStyledString();
    uiContentLength = strContent.size();
    hdr.packet_length = uiContentLength;
    hdr.message_length = uiContentLength;
    
    if ( iDataLen < uiContentLength+DVIP_HDR_LENGTH )
    {
        ERROR_TRACE("buffer too small");
        return -1;
    }
    
    int iRet = CDvipMsg::EncodeHeader((unsigned char*)pData,iDataLen);
    if ( 0 != iRet )
    {
        ERROR_TRACE("encode header failed");
        return -1;
    }
    memcpy(pData+DVIP_HDR_LENGTH,strContent.c_str(),uiContentLength);
    
    return (int)(DVIP_HDR_LENGTH+uiContentLength);
}
// 解包消息
int CMsgDvip_instance_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

///获取实例 回应
// 打包消息
int CMsgDvip_instance_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgDvip_instance_rsp::Decode(char *pData,unsigned int iDataLen)
{
    int iRet;
    Json::Reader jsonParser;
    Json::Value jsonContent;
    bool bRet;
    
    iRet = CDvipMsg::DecodeHeader((unsigned char*)pData,iDataLen);
    if ( 0 != iRet )
    {
        ERROR_TRACE("decode header failed");
        return -1;
    }
    
    if ( hdr.message_length == 0 )
    {
        ERROR_TRACE("invalid msg no msg body.");
        return -1;
    }
    
    bRet = jsonParser.parse(pData+DVIP_HDR_LENGTH,pData+DVIP_HDR_LENGTH+hdr.message_length,jsonContent);
    if ( !bRet )
    {
        ERROR_TRACE("parse msg body failed");
        return -1;
    }
    
    unsigned int uiReqId = jsonContent["id"].asUInt();
    unsigned int uiSessionId = jsonContent["session"].asUInt();
    if ( uiReqId != hdr.request_id || uiSessionId != hdr.session_id )
    {
        ERROR_TRACE("reqid or sessid not same with hdr");
        return -1;
    }
    
    //
    if ( jsonContent["result"].isNull()
        || (!jsonContent["result"].isInt() && !jsonContent["result"].isUInt()) ) //结果
    {
        ERROR_TRACE("no result or result type is not int.");
        return -1;
    }
    
    if ( jsonContent["result"].isInt() )
    {
        m_uiObjectId = (unsigned int)jsonContent["result"].asInt();
    }
    else
    {
        m_uiObjectId = (unsigned int)jsonContent["result"].asUInt();
    }
    
    return 0;
}

//释放实例 请求
// 打包消息
int CMsgDvip_destroy_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //实例id
    jsonContent["method"] = m_strMethod; //方法 释放实例
    ////参数列表 无参数
    
    strContent = jsonContent.toStyledString();
    uiContentLength = strContent.size();
    hdr.packet_length = uiContentLength;
    hdr.message_length = uiContentLength;
    
    if ( iDataLen < uiContentLength+DVIP_HDR_LENGTH )
    {
        ERROR_TRACE("buffer too small");
        return -1;
    }
    
    int iRet = CDvipMsg::EncodeHeader((unsigned char*)pData,iDataLen);
    if ( 0 != iRet )
    {
        ERROR_TRACE("encode header failed");
        return -1;
    }
    memcpy(pData+DVIP_HDR_LENGTH,strContent.c_str(),uiContentLength);
    
    return (int)(DVIP_HDR_LENGTH+uiContentLength);
}
// 解包消息
int CMsgDvip_destroy_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//释放实例 回应

// 打包消息
int CMsgDvip_destroy_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgDvip_destroy_rsp::Decode(char *pData,unsigned int iDataLen)
{
    int iRet;
    Json::Reader jsonParser;
    Json::Value jsonContent;
    bool bRet;
    
    iRet = CDvipMsg::DecodeHeader((unsigned char*)pData,iDataLen);
    if ( 0 != iRet )
    {
        ERROR_TRACE("decode header failed");
        return -1;
    }
    
    if ( hdr.message_length == 0 )
    {
        ERROR_TRACE("invalid msg no msg body.");
        return -1;
    }
    
    bRet = jsonParser.parse(pData+DVIP_HDR_LENGTH,pData+DVIP_HDR_LENGTH+hdr.message_length,jsonContent);
    if ( !bRet )
    {
        ERROR_TRACE("parse msg body failed");
        return -1;
    }
    
    unsigned int uiReqId = jsonContent["id"].asUInt();
    unsigned int uiSessionId = jsonContent["session"].asUInt();
    if ( uiReqId != hdr.request_id || uiSessionId != hdr.session_id )
    {
        ERROR_TRACE("reqid or sessid not same with hdr");
        return -1;
    }
    
    //
    if ( jsonContent["result"].isNull()
        || !jsonContent["result"].isBool() ) //结果
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    return 0;
}

//输入参数为json(params : {}),输出参数也为json(params : {}) 返回值为bool 请求
// 打包消息
int CMsg_method_json_b_json_req::Encode(char *pData,unsigned int iDataLen)
{
    bool bRet = false;
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //实例id
    jsonContent["method"] = m_strMethod; //方法
    ////参数列表 无参数
    jsonContent["params"] = m_jsParams;
    
    strContent = jsonContent.toStyledString();
    uiContentLength = strContent.size();
    hdr.packet_length = uiContentLength;
    hdr.message_length = uiContentLength;
    
    if ( iDataLen < uiContentLength+DVIP_HDR_LENGTH )
    {
        ERROR_TRACE("buffer too small");
        return -1;
    }
    
    int iRet = CDvipMsg::EncodeHeader((unsigned char*)pData,iDataLen);
    if ( 0 != iRet )
    {
        ERROR_TRACE("encode header failed");
        return -1;
    }
    memcpy(pData+DVIP_HDR_LENGTH,strContent.c_str(),uiContentLength);
    
    return (int)(DVIP_HDR_LENGTH+uiContentLength);
}
// 解包消息
int CMsg_method_json_b_json_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//获取配置信息 回应
// 打包消息
int CMsg_method_json_b_json_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsg_method_json_b_json_rsp::Decode(char *pData,unsigned int iDataLen)
{
    int iRet;
    Json::Reader jsonParser;
    Json::Value jsonContent;
    bool bRet;
    
    iRet = CDvipMsg::DecodeHeader((unsigned char*)pData,iDataLen);
    if ( 0 != iRet )
    {
        ERROR_TRACE("decode header failed");
        return -1;
    }
    
    if ( hdr.message_length == 0 )
    {
        ERROR_TRACE("invalid msg no msg body.");
        return -1;
    }
    
    bRet = jsonParser.parse(pData+DVIP_HDR_LENGTH,pData+DVIP_HDR_LENGTH+hdr.message_length,jsonContent);
    if ( !bRet )
    {
        ERROR_TRACE("parse msg body failed");
        return -1;
    }
    
    unsigned int uiReqId = jsonContent["id"].asUInt();
    unsigned int uiSessionId = jsonContent["session"].asUInt();
    if ( uiReqId != hdr.request_id || uiSessionId != hdr.session_id )
    {
        ERROR_TRACE("reqid or sessid not same with hdr");
        return -1;
    }
    
    //
    if ( jsonContent["result"].isNull() 
        || !jsonContent["result"].isBool() ) //结果
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = (unsigned int)jsonContent["result"].asBool();
    //if ( m_bResult )
    {
        m_jsParams = jsonContent["params"];
    }
    
    return 0;
}
///////////////////////通用消息////////////////////////
