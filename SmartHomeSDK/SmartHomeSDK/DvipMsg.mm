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


////////////////////////ͨ����Ϣ////////////////////////
//�������������� ����ֵΪbool ����

// �����Ϣ
int CMsg_method_v_b_v_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    if ( 0 != m_uiObjectId )
    {
        jsonContent["object"] = m_uiObjectId; //objectid
    }
    jsonContent["method"] = m_strMethod; //����
    ////�����б� �޲���
    
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
// �����Ϣ
int CMsg_method_v_b_v_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//�������������� ����ֵΪbool ��Ӧ
// �����Ϣ
int CMsg_method_v_b_v_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    return 0;
}


///��ȡʵ�� ����
// �����Ϣ
int CMsgDvip_instance_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
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
    jsonContent["method"] = m_strMethod; //���� ��ȡʵ��ID
    ////�����б� �޲���
    
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
// �����Ϣ
int CMsgDvip_instance_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

///��ȡʵ�� ��Ӧ
// �����Ϣ
int CMsgDvip_instance_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || (!jsonContent["result"].isInt() && !jsonContent["result"].isUInt()) ) //���
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

//�ͷ�ʵ�� ����
// �����Ϣ
int CMsgDvip_destroy_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //ʵ��id
    jsonContent["method"] = m_strMethod; //���� �ͷ�ʵ��
    ////�����б� �޲���
    
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
// �����Ϣ
int CMsgDvip_destroy_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//�ͷ�ʵ�� ��Ӧ

// �����Ϣ
int CMsgDvip_destroy_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    return 0;
}

//�������Ϊjson(params : {}),�������ҲΪjson(params : {}) ����ֵΪbool ����
// �����Ϣ
int CMsg_method_json_b_json_req::Encode(char *pData,unsigned int iDataLen)
{
    bool bRet = false;
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //ʵ��id
    jsonContent["method"] = m_strMethod; //����
    ////�����б� �޲���
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
// �����Ϣ
int CMsg_method_json_b_json_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//��ȡ������Ϣ ��Ӧ
// �����Ϣ
int CMsg_method_json_b_json_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
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
///////////////////////ͨ����Ϣ////////////////////////
