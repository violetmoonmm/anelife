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

//获取配置信息 请求
// 打包消息
int CMsgConfigManager_getConfig_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //实例id
    jsonContent["method"] = "configManager.getConfig"; //方法 配置参数
    ////参数列表 无参数
    jsonContent["params"]["name"] = m_strName;
    
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
int CMsgConfigManager_getConfig_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//获取配置信息 回应
// 打包消息
int CMsgConfigManager_getConfig_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgConfigManager_getConfig_rsp::Decode(char *pData,unsigned int iDataLen)
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
    if ( m_bResult )
    {
        if ( !jsonContent["params"].isNull() )
        {
            m_jsonConfig = jsonContent["params"];
            m_strConfig = jsonContent["params"].toStyledString();
        }
    }
    
    return 0;
}

//设置配置信息 请求
// 打包消息
int CMsgConfigManager_setConfig_req::Encode(char *pData,unsigned int iDataLen)
{
    bool bRet = false;
    //Json::Reader jsonParser;
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    //Json::Value jsonConfig;
    std::string strContent;
    
    //bRet = jsonParser.parse(m_strConfig,jsonConfig);
    //if ( !bRet )
    //{
    //	ERROR_TRACE("parse msg body failed");
    //	return -1;
    //}
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //实例id
    jsonContent["method"] = "configManager.setConfig"; //方法 配置参数
    ////参数列表 无参数
    jsonContent["params"]["name"] = m_strName;
    //jsonContent["params"]["channel"] = 0;
    //jsonContent["params"]["onlyLocal"] = false;
    jsonContent["params"]["table"] = m_jsonConfig;
    
    strContent = jsonContent.toUnStyledString();
    uiContentLength = strContent.size();
    hdr.packet_length = uiContentLength;
    hdr.message_length = uiContentLength;
    
    if ( iDataLen < uiContentLength+DVIP_HDR_LENGTH )
    {
        ERROR_TRACE("buffer too small");
        return -(uiContentLength+DVIP_HDR_LENGTH);
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
int CMsgConfigManager_setConfig_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//获取配置信息 回应
// 打包消息
int CMsgConfigManager_setConfig_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgConfigManager_setConfig_rsp::Decode(char *pData,unsigned int iDataLen)
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
    //{
    //	if ( !jsonContent["params"].isNull() )
    //	{
    //		m_strConfig = jsonContent["params"].toStyledString();
    //	}
    //}
    
    return 0;
}

//magicbox
CMsgMagicBox_instance_req::CMsgMagicBox_instance_req():CDvipMsg()
{
    m_iType = emMsgType_MagicBox_instance_req;
}

CMsgMagicBox_instance_req::CMsgMagicBox_instance_req(unsigned int uiReqId,unsigned int uiSessId)
{
    m_iType = emMsgType_MagicBox_instance_req;
    hdr.request_id = uiReqId;
    hdr.session_id = uiSessId;
}
CMsgMagicBox_instance_req::~CMsgMagicBox_instance_req()
{
}
// 打包消息
int CMsgMagicBox_instance_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["method"] = "magicBox.factory.instance"; //方法 获取设备配置管理实例ID
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
int CMsgMagicBox_instance_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

/// 回应
CMsgMagicBox_instance_rsp::CMsgMagicBox_instance_rsp():CDvipMsg()
{
    m_iType = emMsgType_MagicBox_instance_rsp;
    m_uiObjectId = 0;
}
CMsgMagicBox_instance_rsp::~CMsgMagicBox_instance_rsp()
{
}
// 打包消息
int CMsgMagicBox_instance_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgMagicBox_instance_rsp::Decode(char *pData,unsigned int iDataLen)
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
        || !jsonContent["result"].isInt() && !jsonContent["result"].isUInt() ) //结果
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
    
    //if ( 0 == uiObjectId ) //失败
    //{
    //	INFO_TRACE("get failed.server failed");
    //}
    //else //成功
    //{
    //	INFO_TRACE("get ok.id="<<m_uiObjecId);
    //}
    return 0;
}

// 打包消息
int CMsgMagicBox_destroy_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //实例id
    jsonContent["method"] = "magicBox.destroy"; //方法 释放实例
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
int CMsgMagicBox_destroy_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

// 打包消息
int CMsgMagicBox_destroy_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgMagicBox_destroy_rsp::Decode(char *pData,unsigned int iDataLen)
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

//获取设备配置信息 请求
// 打包消息
int CMsgMagicBox_getDevConfig_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //实例id
    jsonContent["method"] = "magicBox."+m_strName; //方法 配置参数
    ////参数列表 无参数
    //jsonContent["params"]["name"] = m_strName;
    
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
int CMsgMagicBox_getDevConfig_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//获取配置信息 回应
// 打包消息
int CMsgMagicBox_getDevConfig_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgMagicBox_getDevConfig_rsp::Decode(char *pData,unsigned int iDataLen)
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
    if ( m_bResult )
    {
        if ( !jsonContent["params"].isNull() )
        {
            m_jsonConfig = jsonContent["params"];
            m_strConfig = jsonContent["params"].toStyledString();
        }
    }
    
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
    if ( m_bResult )
    {
        m_jsParams = jsonContent["params"];
    }
    
    return 0;
}
///////////////////////通用消息////////////////////////

///获取智能家居管理实例 请求
CMsgSmarthome_instance_req::CMsgSmarthome_instance_req():CDvipMsg()
{
    m_iType = emMsgType_Smarthome_instance_req;
}
CMsgSmarthome_instance_req::CMsgSmarthome_instance_req(unsigned int uiReqId,unsigned int uiSessId)
{
    m_iType = emMsgType_Smarthome_instance_req;
    hdr.request_id = uiReqId;
    hdr.session_id = uiSessId;
}
CMsgSmarthome_instance_req::~CMsgSmarthome_instance_req()
{
}
// 打包消息
int CMsgSmarthome_instance_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["method"] = "SmartHomeManager.factory.instance"; //方法 获取智能家居管理实例ID
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
int CMsgSmarthome_instance_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

///获取智能家居管理实例 回应
CMsgSmarthome_instance_rsp::CMsgSmarthome_instance_rsp():CDvipMsg()
{
    m_iType = emMsgType_Smarthome_instance_rsp;
    m_uiObjectId = 0;
}
CMsgSmarthome_instance_rsp::~CMsgSmarthome_instance_rsp()
{
}
// 打包消息
int CMsgSmarthome_instance_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgSmarthome_instance_rsp::Decode(char *pData,unsigned int iDataLen)
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
        || !jsonContent["result"].isInt() && !jsonContent["result"].isUInt() ) //结果
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
    
    //if ( 0 == uiObjectId ) //失败
    //{
    //	INFO_TRACE("get failed.server failed");
    //}
    //else //成功
    //{
    //	INFO_TRACE("get ok.id="<<m_uiObjecId);
    //}
    return 0;
}

//释放智能家居管理实例 请求


// 打包消息
int CMsgSmarthome_destroy_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //实例id
    jsonContent["method"] = "SmartHomeManager.destroy"; //方法 释放智能家居管理实例
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
int CMsgSmarthome_destroy_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//释放智能家居管理实例 回应

// 打包消息
int CMsgSmarthome_destroy_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgSmarthome_destroy_rsp::Decode(char *pData,unsigned int iDataLen)
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

//获取设备列表 请求
// 打包消息
int CMsgSmarthome_getDeviceList_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //实例id
    jsonContent["method"] = "SmartHomeManager.getDeviceList"; //方法 获取设备列表
    ////参数列表 无参数
    jsonContent["params"]["Type"] = m_strDeviceType; //设备类型
    
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
int CMsgSmarthome_getDeviceList_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//获取设备列表 回应
// 打包消息
int CMsgSmarthome_getDeviceList_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgSmarthome_getDeviceList_rsp::Decode(char *pData,unsigned int iDataLen)
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
    
    if ( m_bResult )
    {
        //设备列表
        //DeviceInfo dev;
        if ( jsonContent["params"].isNull()
            || jsonContent["params"]["Devices"].isNull()
            )
        {
            //没有设备
            return 0;
        }
        std::vector<std::string> devices;
        devices = jsonContent["params"]["Devices"].getMemberNames();
        for(size_t i=0;i<devices.size();i++)
        {
            Smarthome_DeviceInfo dev;
            dev.strDeviceType = devices[i];
            if ( !jsonContent["params"]["Devices"][devices[i]].isNull()
                && jsonContent["params"]["Devices"][devices[i]].isArray()
                && jsonContent["params"]["Devices"][devices[i]].size() > 0 )
            {
                for(unsigned int j=0;j<jsonContent["params"]["Devices"][devices[i]].size();j++)
                {
                    if ( !jsonContent["params"]["Devices"][devices[i]][j]["DeviceID"].isNull() )
                    {
                        dev.strDeviceId = jsonContent["params"]["Devices"][devices[i]][j]["DeviceID"].asString();
                    }
                    else
                    {
                        dev.strDeviceId = "";
                    }
                    if ( !jsonContent["params"]["Devices"][devices[i]][j]["Name"].isNull() )
                    {
                        dev.strDeviceName = jsonContent["params"]["Devices"][devices[i]][j]["Name"].asString();
                    }
                    else
                    {
                        dev.strDeviceName = "";
                    }
                    if ( !jsonContent["params"]["Devices"][devices[i]][j]["AreaID"].isNull() )
                    {
                        dev.iAreaID = jsonContent["params"]["Devices"][devices[i]][j]["AreaID"].asInt();
                    }
                    else
                    {
                        dev.iAreaID = 0;
                    }
                    if ( !jsonContent["params"]["Devices"][devices[i]][j]["Type"].isNull() )
                    {
                        dev.strDeviceType = jsonContent["params"]["Devices"][devices[i]][j]["Type"].asString();
                        if(dev.strDeviceType == "Light")//灯光设备需要进一步检测子类型
                        {
                            if ( !jsonContent["params"]["Devices"][devices[i]][j]["SubType"].isNull() )
                            {
                                dev.strDeviceType = jsonContent["params"]["Devices"][devices[i]][j]["SubType"].asString();
                            }
                        }
                    }
                    else
                    {
                        dev.strDeviceType = "";
                    }
                    m_vecDevice.push_back(dev);
                }
            }
            
        }
    }
    return 0;
}

//设置配置信息 请求
// 打包消息
int CMsgSmarthome_setDeviceInfo_req::Encode(char *pData,unsigned int iDataLen)
{
    bool bRet = false;
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //实例id
    jsonContent["method"] = "SmartHomeManager.setDeviceInfo"; //方法 配置参数
    ////参数列表 无参数
    jsonContent["params"] = m_jsonConfig;
    
    strContent = jsonContent.toUnStyledString();
    uiContentLength = strContent.size();
    hdr.packet_length = uiContentLength;
    hdr.message_length = uiContentLength;
    
    if ( iDataLen < uiContentLength+DVIP_HDR_LENGTH )
    {
        ERROR_TRACE("buffer too small");
        return -(uiContentLength+DVIP_HDR_LENGTH);
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
int CMsgSmarthome_setDeviceInfo_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//设置设备信息 回应
// 打包消息
int CMsgSmarthome_setDeviceInfo_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgSmarthome_setDeviceInfo_rsp::Decode(char *pData,unsigned int iDataLen)
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
    
    return 0;
}


//////////////灯光//////////////
//获取灯光设备实例 请求
// 打包消息
int CMsgLight_instance_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["method"] = "Light.factory.instance"; //方法 获取灯光实例
    ////参数列表
    jsonContent["params"]["DeviceID"] = m_strDeviceId; //设备id
    
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
int CMsgLight_instance_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//获取灯光设备实例 回应
// 打包消息
int CMsgLight_instance_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgLight_instance_rsp::Decode(char *pData,unsigned int iDataLen)
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
        || !jsonContent["result"].isInt() ) //结果
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_uiObjectId = (unsigned int)jsonContent["result"].asInt();
    
    return 0;
}

//释放灯光设备实例 请求
// 打包消息
int CMsgLight_destroy_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Light.destroy"; //方法 释放灯光实例
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
int CMsgLight_destroy_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//释放灯光设备实例 回应
// 打包消息
int CMsgLight_destroy_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgLight_destroy_rsp::Decode(char *pData,unsigned int iDataLen)
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

//开灯 请求
// 打包消息
int CMsgLight_open_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Light.open"; //方法 开灯
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
int CMsgLight_open_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//开灯 回应
// 打包消息
int CMsgLight_open_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgLight_open_rsp::Decode(char *pData,unsigned int iDataLen)
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

//关灯 请求
// 打包消息
int CMsgLight_close_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Light.close"; //方法 关灯
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
int CMsgLight_close_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}
//关灯 回应


// 打包消息
int CMsgLight_close_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgLight_close_rsp::Decode(char *pData,unsigned int iDataLen)
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


//获取灯光状态 请求
// 打包消息
int CMsgLight_getState_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Light.getState"; //方法 获取灯光状态
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
int CMsgLight_getState_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//获取灯光状态 回应


// 打包消息
int CMsgLight_getState_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgLight_getState_rsp::Decode(char *pData,unsigned int iDataLen)
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
    
    if ( !m_bResult )
    {
        //获取失败
        return 0;
    }
    
    if ( jsonContent["params"].isNull() )
    {
        //没有参数
        return 0;
    }
    if ( jsonContent["params"]["State"].isNull() )
    {
        //没有状态参数
        return 0;
    }
    if ( !jsonContent["params"]["State"]["Online"].isNull() && jsonContent["params"]["State"]["Online"].isBool() )
    {
        m_bIsOnline = jsonContent["params"]["State"]["Online"].asBool();
    }
    if ( !jsonContent["params"]["State"]["On"].isNull() && jsonContent["params"]["State"]["On"].isBool() )
    {
        m_bIsOn = jsonContent["params"]["State"]["On"].asBool();
    }
    if ( !jsonContent["params"]["State"]["Bright"].isNull() && jsonContent["params"]["State"]["Bright"].isInt() )
    {
        m_iLevel = jsonContent["params"]["State"]["Bright"].asInt();
    }
    return 0;
}


/////////////////////////窗帘////////////////////////////
//获取窗帘设备实例 请求

// 打包消息
int CMsgCurtain_instance_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["method"] = "Curtain.factory.instance"; //方法 获取窗帘实例
    ////参数列表
    jsonContent["params"]["DeviceID"] = m_strDeviceId; //设备id
    
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
int CMsgCurtain_instance_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//获取窗帘设备实例 回应
// 打包消息
int CMsgCurtain_instance_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgCurtain_instance_rsp::Decode(char *pData,unsigned int iDataLen)
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
        || !jsonContent["result"].isInt() ) //结果
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_uiObjectId = (unsigned int)jsonContent["result"].asInt();
    
    return 0;
}


//释放窗帘设备实例 请求
// 打包消息
int CMsgCurtain_destroy_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Curtain.destroy"; //方法 释放窗帘实例
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
int CMsgCurtain_destroy_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}


//释放窗帘设备实例 回应

// 打包消息
int CMsgCurtain_destroy_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgCurtain_destroy_rsp::Decode(char *pData,unsigned int iDataLen)
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

//打开 请求
// 打包消息
int CMsgCurtain_open_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Curtain.open"; //方法 打开
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
int CMsgCurtain_open_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//打开 回应
// 打包消息
int CMsgCurtain_open_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgCurtain_open_rsp::Decode(char *pData,unsigned int iDataLen)
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

//关闭 请求
// 打包消息
int CMsgCurtain_close_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Curtain.close"; //方法 关闭
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
int CMsgCurtain_close_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//关闭 回应
// 打包消息
int CMsgCurtain_close_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgCurtain_close_rsp::Decode(char *pData,unsigned int iDataLen)
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

//停止 请求
// 打包消息
int CMsgCurtain_stop_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Curtain.stop"; //方法 停止
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
int CMsgCurtain_stop_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//停止 回应
// 打包消息
int CMsgCurtain_stop_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgCurtain_stop_rsp::Decode(char *pData,unsigned int iDataLen)
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

//获取窗帘状态 请求
// 打包消息
int CMsgCurtain_getState_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //请求id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Curtain.getState"; //方法 获取窗帘状态
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
int CMsgCurtain_getState_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//获取窗帘状态 回应
// 打包消息
int CMsgCurtain_getState_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// 解包消息
int CMsgCurtain_getState_rsp::Decode(char *pData,unsigned int iDataLen)
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
    
    if ( !m_bResult )
    {
        //获取失败
        return 0;
    }
    
    if ( jsonContent["params"].isNull() )
    {
        //没有参数
        return 0;
    }
    if ( jsonContent["params"]["State"].isNull() )
    {
        //没有状态参数
        return 0;
    }
    if ( !jsonContent["params"]["State"]["Online"].isNull() && jsonContent["params"]["State"]["Online"].isBool() )
    {
        m_bIsOnline = jsonContent["params"]["State"]["Online"].asBool();
    }
    if ( !jsonContent["params"]["State"]["On"].isNull() && jsonContent["params"]["State"]["On"].isBool() )
    {
        m_bIsOn = jsonContent["params"]["State"]["On"].asBool();
    }
    if ( !jsonContent["params"]["State"]["Shading"].isNull() && jsonContent["params"]["State"]["Shading"].isInt() )
    {
        m_iLevel = jsonContent["params"]["State"]["Shading"].asInt();
    }
    return 0;
}
/////////////////////////窗帘////////////////////////////