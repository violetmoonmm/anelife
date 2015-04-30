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

//��ȡ������Ϣ ����
// �����Ϣ
int CMsgConfigManager_getConfig_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //ʵ��id
    jsonContent["method"] = "configManager.getConfig"; //���� ���ò���
    ////�����б� �޲���
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
// �����Ϣ
int CMsgConfigManager_getConfig_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//��ȡ������Ϣ ��Ӧ
// �����Ϣ
int CMsgConfigManager_getConfig_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
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

//����������Ϣ ����
// �����Ϣ
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
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //ʵ��id
    jsonContent["method"] = "configManager.setConfig"; //���� ���ò���
    ////�����б� �޲���
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
// �����Ϣ
int CMsgConfigManager_setConfig_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//��ȡ������Ϣ ��Ӧ
// �����Ϣ
int CMsgConfigManager_setConfig_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
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
// �����Ϣ
int CMsgMagicBox_instance_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["method"] = "magicBox.factory.instance"; //���� ��ȡ�豸���ù���ʵ��ID
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
int CMsgMagicBox_instance_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

/// ��Ӧ
CMsgMagicBox_instance_rsp::CMsgMagicBox_instance_rsp():CDvipMsg()
{
    m_iType = emMsgType_MagicBox_instance_rsp;
    m_uiObjectId = 0;
}
CMsgMagicBox_instance_rsp::~CMsgMagicBox_instance_rsp()
{
}
// �����Ϣ
int CMsgMagicBox_instance_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isInt() && !jsonContent["result"].isUInt() ) //���
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
    
    //if ( 0 == uiObjectId ) //ʧ��
    //{
    //	INFO_TRACE("get failed.server failed");
    //}
    //else //�ɹ�
    //{
    //	INFO_TRACE("get ok.id="<<m_uiObjecId);
    //}
    return 0;
}

// �����Ϣ
int CMsgMagicBox_destroy_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //ʵ��id
    jsonContent["method"] = "magicBox.destroy"; //���� �ͷ�ʵ��
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
int CMsgMagicBox_destroy_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

// �����Ϣ
int CMsgMagicBox_destroy_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    return 0;
}

//��ȡ�豸������Ϣ ����
// �����Ϣ
int CMsgMagicBox_getDevConfig_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //ʵ��id
    jsonContent["method"] = "magicBox."+m_strName; //���� ���ò���
    ////�����б� �޲���
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
// �����Ϣ
int CMsgMagicBox_getDevConfig_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//��ȡ������Ϣ ��Ӧ
// �����Ϣ
int CMsgMagicBox_getDevConfig_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
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
    if ( m_bResult )
    {
        m_jsParams = jsonContent["params"];
    }
    
    return 0;
}
///////////////////////ͨ����Ϣ////////////////////////

///��ȡ���ܼҾӹ���ʵ�� ����
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
// �����Ϣ
int CMsgSmarthome_instance_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["method"] = "SmartHomeManager.factory.instance"; //���� ��ȡ���ܼҾӹ���ʵ��ID
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
int CMsgSmarthome_instance_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

///��ȡ���ܼҾӹ���ʵ�� ��Ӧ
CMsgSmarthome_instance_rsp::CMsgSmarthome_instance_rsp():CDvipMsg()
{
    m_iType = emMsgType_Smarthome_instance_rsp;
    m_uiObjectId = 0;
}
CMsgSmarthome_instance_rsp::~CMsgSmarthome_instance_rsp()
{
}
// �����Ϣ
int CMsgSmarthome_instance_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isInt() && !jsonContent["result"].isUInt() ) //���
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
    
    //if ( 0 == uiObjectId ) //ʧ��
    //{
    //	INFO_TRACE("get failed.server failed");
    //}
    //else //�ɹ�
    //{
    //	INFO_TRACE("get ok.id="<<m_uiObjecId);
    //}
    return 0;
}

//�ͷ����ܼҾӹ���ʵ�� ����


// �����Ϣ
int CMsgSmarthome_destroy_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //ʵ��id
    jsonContent["method"] = "SmartHomeManager.destroy"; //���� �ͷ����ܼҾӹ���ʵ��
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
int CMsgSmarthome_destroy_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//�ͷ����ܼҾӹ���ʵ�� ��Ӧ

// �����Ϣ
int CMsgSmarthome_destroy_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    return 0;
}

//��ȡ�豸�б� ����
// �����Ϣ
int CMsgSmarthome_getDeviceList_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //ʵ��id
    jsonContent["method"] = "SmartHomeManager.getDeviceList"; //���� ��ȡ�豸�б�
    ////�����б� �޲���
    jsonContent["params"]["Type"] = m_strDeviceType; //�豸����
    
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
int CMsgSmarthome_getDeviceList_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//��ȡ�豸�б� ��Ӧ
// �����Ϣ
int CMsgSmarthome_getDeviceList_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    
    if ( m_bResult )
    {
        //�豸�б�
        //DeviceInfo dev;
        if ( jsonContent["params"].isNull()
            || jsonContent["params"]["Devices"].isNull()
            )
        {
            //û���豸
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
                        if(dev.strDeviceType == "Light")//�ƹ��豸��Ҫ��һ�����������
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

//����������Ϣ ����
// �����Ϣ
int CMsgSmarthome_setDeviceInfo_req::Encode(char *pData,unsigned int iDataLen)
{
    bool bRet = false;
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjecId; //ʵ��id
    jsonContent["method"] = "SmartHomeManager.setDeviceInfo"; //���� ���ò���
    ////�����б� �޲���
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
// �����Ϣ
int CMsgSmarthome_setDeviceInfo_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//�����豸��Ϣ ��Ӧ
// �����Ϣ
int CMsgSmarthome_setDeviceInfo_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = (unsigned int)jsonContent["result"].asBool();
    
    return 0;
}


//////////////�ƹ�//////////////
//��ȡ�ƹ��豸ʵ�� ����
// �����Ϣ
int CMsgLight_instance_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["method"] = "Light.factory.instance"; //���� ��ȡ�ƹ�ʵ��
    ////�����б�
    jsonContent["params"]["DeviceID"] = m_strDeviceId; //�豸id
    
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
int CMsgLight_instance_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//��ȡ�ƹ��豸ʵ�� ��Ӧ
// �����Ϣ
int CMsgLight_instance_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isInt() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_uiObjectId = (unsigned int)jsonContent["result"].asInt();
    
    return 0;
}

//�ͷŵƹ��豸ʵ�� ����
// �����Ϣ
int CMsgLight_destroy_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Light.destroy"; //���� �ͷŵƹ�ʵ��
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
int CMsgLight_destroy_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//�ͷŵƹ��豸ʵ�� ��Ӧ
// �����Ϣ
int CMsgLight_destroy_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    
    return 0;
}

//���� ����
// �����Ϣ
int CMsgLight_open_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Light.open"; //���� ����
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
int CMsgLight_open_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//���� ��Ӧ
// �����Ϣ
int CMsgLight_open_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    
    return 0;
}

//�ص� ����
// �����Ϣ
int CMsgLight_close_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Light.close"; //���� �ص�
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
int CMsgLight_close_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}
//�ص� ��Ӧ


// �����Ϣ
int CMsgLight_close_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    
    return 0;
}


//��ȡ�ƹ�״̬ ����
// �����Ϣ
int CMsgLight_getState_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Light.getState"; //���� ��ȡ�ƹ�״̬
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
int CMsgLight_getState_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//��ȡ�ƹ�״̬ ��Ӧ


// �����Ϣ
int CMsgLight_getState_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    
    if ( !m_bResult )
    {
        //��ȡʧ��
        return 0;
    }
    
    if ( jsonContent["params"].isNull() )
    {
        //û�в���
        return 0;
    }
    if ( jsonContent["params"]["State"].isNull() )
    {
        //û��״̬����
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


/////////////////////////����////////////////////////////
//��ȡ�����豸ʵ�� ����

// �����Ϣ
int CMsgCurtain_instance_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["method"] = "Curtain.factory.instance"; //���� ��ȡ����ʵ��
    ////�����б�
    jsonContent["params"]["DeviceID"] = m_strDeviceId; //�豸id
    
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
int CMsgCurtain_instance_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//��ȡ�����豸ʵ�� ��Ӧ
// �����Ϣ
int CMsgCurtain_instance_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isInt() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_uiObjectId = (unsigned int)jsonContent["result"].asInt();
    
    return 0;
}


//�ͷŴ����豸ʵ�� ����
// �����Ϣ
int CMsgCurtain_destroy_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Curtain.destroy"; //���� �ͷŴ���ʵ��
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
int CMsgCurtain_destroy_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}


//�ͷŴ����豸ʵ�� ��Ӧ

// �����Ϣ
int CMsgCurtain_destroy_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    
    return 0;
}

//�� ����
// �����Ϣ
int CMsgCurtain_open_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Curtain.open"; //���� ��
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
int CMsgCurtain_open_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//�� ��Ӧ
// �����Ϣ
int CMsgCurtain_open_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    
    return 0;
}

//�ر� ����
// �����Ϣ
int CMsgCurtain_close_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Curtain.close"; //���� �ر�
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
int CMsgCurtain_close_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//�ر� ��Ӧ
// �����Ϣ
int CMsgCurtain_close_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    
    return 0;
}

//ֹͣ ����
// �����Ϣ
int CMsgCurtain_stop_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Curtain.stop"; //���� ֹͣ
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
int CMsgCurtain_stop_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//ֹͣ ��Ӧ
// �����Ϣ
int CMsgCurtain_stop_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    
    return 0;
}

//��ȡ����״̬ ����
// �����Ϣ
int CMsgCurtain_getState_req::Encode(char *pData,unsigned int iDataLen)
{
    unsigned int uiContentLength = 0;
    Json::Value jsonContent;
    std::string strContent;
    
    jsonContent["id"] = hdr.request_id; //����id requstId
    jsonContent["session"] = hdr.session_id; //sessionId
    jsonContent["object"] = m_uiObjectId; //objectid
    jsonContent["method"] = "Curtain.getState"; //���� ��ȡ����״̬
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
int CMsgCurtain_getState_req::Decode(char *pData,unsigned int iDataLen)
{
    return -1;
}

//��ȡ����״̬ ��Ӧ
// �����Ϣ
int CMsgCurtain_getState_rsp::Encode(char *pData,unsigned int iDataLen)
{
    return -1;
}
// �����Ϣ
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
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return -1;
    }
    
    m_bResult = jsonContent["result"].asBool();
    
    if ( !m_bResult )
    {
        //��ȡʧ��
        return 0;
    }
    
    if ( jsonContent["params"].isNull() )
    {
        //û�в���
        return 0;
    }
    if ( jsonContent["params"]["State"].isNull() )
    {
        //û��״̬����
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
/////////////////////////����////////////////////////////