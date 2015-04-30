#ifndef DvipMsg_h
#define DvipMsg_h

#include "Platform.h"
#include <string>
#include <vector>
#include "json.h"


/////////////////������Э���ʽ//////////////////////
///////�̶�������ͷ �̶�32�ֽڶ�����ͷ
//////��չͷ  ��ǰû��
//////json��ʽ��Ϣ
//////��չ����������

#define DVIP_HDR_LENGTH  32   //������ͷ����

//��Ϣ���Ͷ���
enum EmMsgType
{
    emMsgType_Base,	//������Ϣ ������Ϣ,û�о���ʵ��
    
    emMsgType_instance_req,	//��ȡ
    emMsgType_instance_rsp,	//��ȡ
    emMsgType_destroy_req,	//�ͷ�
    emMsgType_destroy_rsp,	//�ͷ�
};

////////////////////Э��ͷ///////////////////
////���������ֶβ���little endian��ʽ
struct dvip_hdr
{
    unsigned int size; //ͷ���� Ĭ��32�ֽ�
    char magic[4]; //magic 'D' 'H' 'I' 'P'
    unsigned int session_id; //�Ựid ��0���޷������� ��¼�ɹ�ʱ�ɷ���˷���,�˺��������ӹ���Ψһ,��¼����ʱӦ��0
    unsigned int request_id; //����id ��0���޷������� ��ʶһ������
    unsigned int packet_length; //������ ��0���޷������� ��¼�ɹ�ʱ�ɷ���˷���,�˺��������ӹ���Ψһ,��¼����ʱӦ��0
    unsigned int packet_index; //������ ��ʾ�ְ����,���û�зְ���Ϊ0
    unsigned int message_length; //��Ϣ���� json��ʽ��Ϣ���ݳ���
    unsigned int data_length; //���ݳ��� ��չ���������ݳ���
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
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen) = 0;
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen) = 0;
    
    
    int EncodeHeader(unsigned char *pData,int iDataLen);
    int DecodeHeader(unsigned char *pData,int iDataLen);
    
    dvip_hdr hdr;
    EmMsgType m_iType;
};


////////////////////////ͨ����Ϣ////////////////////////
//�������������� ����ֵΪbool ����
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
    
    // �����Ϣ
    int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//ʵ��id
    std::string m_strMethod;		//��������
};
//�������������� ����ֵΪbool ��Ӧ
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
    
    // �����Ϣ
    int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//���
};

////////////////////////ʵ���������ͷ�/////////////////////
//��ȡʵ�� ����
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
    
    // �����Ϣ
    int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    int Decode(char *pData,unsigned int iDataLen);
    
    //bool m_bNeedDeviceId;		//�Ƿ���Ҫ�豸ID,һ���ڴ�����ʵ��ʱ�õ�,Ĭ��Ϊfalse
    //unsigned int m_uiObjecId;	//ʵ��id
    std::string m_strMethod;	//��������
    //std::string m_strDeviceID;	//�豸ID
    Json::Value m_jsParams;
};
//��ȡʵ�� ��Ӧ
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
    
    // �����Ϣ
    int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjectId;
};

//�ͷ�ʵ�� ����
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
    
    // �����Ϣ
    int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjecId;
    std::string m_strMethod;
};
//�ͷ����ܼҾӹ���ʵ�� ��Ӧ
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
    
    // �����Ϣ
    int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;
};

//�������Ϊjson(params : {}),�������ҲΪjson(params : {}) ����ֵΪbool ����
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
    
    // �����Ϣ
    int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//ʵ��id
    std::string m_strMethod;		//��������
    Json::Value m_jsParams;			//�������
};
//�������Ϊjson(params : {}),�������ҲΪjson(params : {}) ����ֵΪbool ��Ӧ
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
    
    // �����Ϣ
    int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;			//���
    Json::Value m_jsParams;	//�������
};
///////////////////////ͨ����Ϣ////////////////////////

#endif
