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
    
    //ͨ��
    emMsgType_ConfigManager_getConfig_req,	//��ȡ
    emMsgType_ConfigManager_getConfig_rsp,	//��ȡ
    emMsgType_ConfigManager_setConfig_req,	//����
    emMsgType_ConfigManager_setConfig_rsp,	//����
    
    emMsgType_instance_req,	//��ȡ
    emMsgType_instance_rsp,	//��ȡ
    emMsgType_destroy_req,	//�ͷ�
    emMsgType_destroy_rsp,	//�ͷ�
    
    ///////////���ܼҾ�//////////////
    emMsgType_Smarthome_instance_req,	//��ȡʵ��
    emMsgType_Smarthome_instance_rsp,	//��ȡʵ��
    emMsgType_Smarthome_destroy_req,	//�ͷ�ʵ��
    emMsgType_Smarthome_destroy_rsp,	//�ͷ�ʵ��
    emMsgType_Smarthome_getDeviceList_req,	//��ȡ�豸�б�
    emMsgType_Smarthome_getDeviceList_rsp,	//��ȡ�豸�б�
    
    emMsgType_Smarthome_setDeviceInfo_req,	//�����豸��Ϣ
    emMsgType_Smarthome_setDeviceInfo_rsp,	//�����豸��Ϣ
    
    //�ƹ�
    emMsgType_Light_instance_req,	//��ȡʵ��
    emMsgType_Light_instance_rsp,	//��ȡʵ��
    emMsgType_Light_destroy_req,	//�ͷ�ʵ��
    emMsgType_Light_destroy_rsp,	//�ͷ�ʵ��
    emMsgType_Light_open_req,		//����
    emMsgType_Light_open_rsp,		//����
    emMsgType_Light_close_req,		//�ص�
    emMsgType_Light_close_rsp,		//�ص�
    emMsgType_Light_getState_req,	//��ȡ�ƹ�״̬
    emMsgType_Light_getState_rsp,	//��ȡ�ƹ�״̬
    
    //����
    emMsgType_Curtain_instance_req,	//��ȡʵ��
    emMsgType_Curtain_instance_rsp,	//��ȡʵ��
    emMsgType_Curtain_destroy_req,	//�ͷ�ʵ��
    emMsgType_Curtain_destroy_rsp,	//�ͷ�ʵ��
    emMsgType_Curtain_open_req,		//��
    emMsgType_Curtain_open_rsp,		//��
    emMsgType_Curtain_close_req,	//��
    emMsgType_Curtain_close_rsp,	//��
    emMsgType_Curtain_stop_req,		//ͣ
    emMsgType_Curtain_stop_rsp,		//ͣ
    emMsgType_Curtain_getState_req,	//��ȡ״̬
    emMsgType_Curtain_getState_rsp,	//��ȡ״̬
    
    ///////////���ܼҾ�//////////////
    
    
    //�豸����
    emMsgType_MagicBox_instance_req,
    emMsgType_MagicBox_instance_rsp,
    emMsgType_MagicBox_destroy_req,
    emMsgType_MagicBox_destroy_rsp,
    emMsgType_MagicBox_getDevConfig_req,	//��ȡ�豸��Ϣ
    emMsgType_MagicBox_getDevConfig_rsp,	//��ȡ�豸��Ϣ
    
};

//���ܼҾ��豸��Ϣ
class Smarthome_DeviceInfo
{
public:
    std::string strDeviceType;
    std::string strDeviceId;
    std::string strDeviceName;
    std::string strType;
    int iAreaID;
};

//���ܼҾ��豸��Ϣ
class Smarthome_AreaInfo
{
public:
    std::string strName;
    std::string  strId;
    std::string  strFloorId;
    std::string strType;
};
class Smarthome_HouseInfo
{
public:
    std::string strName;
    std::string  strId;
    std::vector<Smarthome_AreaInfo> vecAreas;
};

//�ƹ�
class Smarthome_Light
{
public:
    std::string strDeviceId;
    std::string strDeviceName;
    std::string strBrand;
    //std::string strType;
    std::vector<int> vecAddress;
    int iPosID;
    int xPos;
    int yPos;
    std::string strState;
    int iRange;
    std::string strType;
    
    std::string AddrToStr()
    {
        std::string strResult;
        char szBuf[64];
        bool bFirst = true;
        for(size_t i=0;i<vecAddress.size();i++)
        {
            sprintf(szBuf,"%d",vecAddress[i]);
            if ( bFirst )
            {
                strResult += szBuf;
                bFirst = false;
            }
            else
            {
                strResult += ".";
                strResult += szBuf;
            }
        }
        return strResult;
    }
    void AddrFromStr(char *pszAddr)
    {
        int iAddr;
        char szTemp[64];
        int i;
        char *p = pszAddr;
        while ( *p )
        {
            //��ȡһ��
            i = 0;
            while ( *p && *p!= '.' )
            {
                szTemp[i] = *p;
                i++;
                p++;
            }
            szTemp[i] = '\0';
            iAddr = atoi(szTemp);
            vecAddress.push_back(iAddr);
            if ( !(*p) )
            {
                break;
            }
            else
            {
                p++;
            }
        }
    }
};

//����
class Smarthome_Curtain
{
public:
    std::string strDeviceId;
    std::string strDeviceName;
    std::string strBrand;
    //std::string strType;
    std::vector<int> vecAddress;
    int iPosID;
    int xPos;
    int yPos;
    std::string strState;
    int iRange;
    std::string strType;
    
    std::string AddrToStr()
    {
        std::string strResult;
        char szBuf[64];
        bool bFirst = true;
        for(size_t i=0;i<vecAddress.size();i++)
        {
            sprintf(szBuf,"%d",vecAddress[i]);
            if ( bFirst )
            {
                strResult += szBuf;
                bFirst = false;
            }
            else
            {
                strResult += ".";
                strResult += szBuf;
            }
        }
        return strResult;
    }
    void AddrFromStr(char *pszAddr)
    {
        int iAddr;
        char szTemp[64];
        int i;
        char *p = pszAddr;
        while ( *p )
        {
            //��ȡһ��
            i = 0;
            while ( *p && *p!= '.' )
            {
                szTemp[i] = *p;
                i++;
                p++;
            }
            szTemp[i] = '\0';
            iAddr = atoi(szTemp);
            vecAddress.push_back(iAddr);
            if ( !(*p) )
            {
                break;
            }
            else
            {
                p++;
            }
        }
    }
};

//��ů
class Smarthome_GroundHeat
{
public:
    std::string strDeviceId;
    std::string strDeviceName;
    std::string strBrand;
    //std::string strType;
    std::vector<int> vecAddress;
    int iPosID;
    //int xPos;
    //int yPos;
    std::string strState;
    int iRange;
    //std::string strType;
    
    std::string AddrToStr()
    {
        std::string strResult;
        char szBuf[64];
        bool bFirst = true;
        for(size_t i=0;i<vecAddress.size();i++)
        {
            sprintf(szBuf,"%d",vecAddress[i]);
            if ( bFirst )
            {
                strResult += szBuf;
                bFirst = false;
            }
            else
            {
                strResult += ".";
                strResult += szBuf;
            }
        }
        return strResult;
    }
    void AddrFromStr(char *pszAddr)
    {
        int iAddr;
        char szTemp[64];
        int i;
        char *p = pszAddr;
        while ( *p )
        {
            //��ȡһ��
            i = 0;
            while ( *p && *p!= '.' )
            {
                szTemp[i] = *p;
                i++;
                p++;
            }
            szTemp[i] = '\0';
            iAddr = atoi(szTemp);
            vecAddress.push_back(iAddr);
            if ( !(*p) )
            {
                break;
            }
            else
            {
                p++;
            }
        }
    }
};


//�յ�
class Smarthome_AirCondition
{
public:
    std::string strDeviceId;
    std::string strDeviceName;
    std::string strBrand;
    //std::string strType;
    std::vector<int> vecAddress;
    int iPosID;
    int xPos;
    int yPos;
    std::string strState;
    int iRange;
    std::string strType;
    std::string strMode;
    std::string strWindMode;
    
    std::string AddrToStr()
    {
        std::string strResult;
        char szBuf[64];
        bool bFirst = true;
        for(size_t i=0;i<vecAddress.size();i++)
        {
            sprintf(szBuf,"%d",vecAddress[i]);
            if ( bFirst )
            {
                strResult += szBuf;
                bFirst = false;
            }
            else
            {
                strResult += ".";
                strResult += szBuf;
            }
        }
        return strResult;
    }
    void AddrFromStr(char *pszAddr)
    {
        int iAddr;
        char szTemp[64];
        int i;
        char *p = pszAddr;
        while ( *p )
        {
            //��ȡһ��
            i = 0;
            while ( *p && *p!= '.' )
            {
                szTemp[i] = *p;
                i++;
                p++;
            }
            szTemp[i] = '\0';
            iAddr = atoi(szTemp);
            vecAddress.push_back(iAddr);
            if ( !(*p) )
            {
                break;
            }
            else
            {
                p++;
            }
        }
    }
};

//���ܵ��
class Smarthome_IntelligentAmmeter
{
public:
    std::string strDeviceId;
    std::string strDeviceName;
    std::string strBrand;
    std::vector<int> vecAddress;
    int iPosID;
    int xPos;
    int yPos;
    std::string strState;
    int iRange;
    std::string strType;
    
    std::string AddrToStr()
    {
        std::string strResult;
        char szBuf[64];
        bool bFirst = true;
        for(size_t i=0;i<vecAddress.size();i++)
        {
            sprintf(szBuf,"%d",vecAddress[i]);
            if ( bFirst )
            {
                strResult += szBuf;
                bFirst = false;
            }
            else
            {
                strResult += ".";
                strResult += szBuf;
            }
        }
        return strResult;
    }
    void AddrFromStr(char *pszAddr)
    {
        int iAddr;
        char szTemp[64];
        int i;
        char *p = pszAddr;
        while ( *p )
        {
            //��ȡһ��
            i = 0;
            while ( *p && *p!= '.' )
            {
                szTemp[i] = *p;
                i++;
                p++;
            }
            szTemp[i] = '\0';
            iAddr = atoi(szTemp);
            vecAddress.push_back(iAddr);
            if ( !(*p) )
            {
                break;
            }
            else
            {
                p++;
            }
        }
    }
};

//���ܼҾ��豸��Ϣ
class Smarthome_SceneInfo
{
public:
    //int iCurrent;			//��ǰѡ�г������(��0��ʼ)
    std::string  strBrand;
    std::string  strName;
    std::vector<Smarthome_Light> vecLight;					//�ƹ��豸�б�
    std::vector<Smarthome_Curtain> vecCurtain;				//�����豸�б�
    std::vector<Smarthome_GroundHeat> vecGroundHeat;		//��ů�豸�б�
    std::vector<Smarthome_AirCondition> vecAirCondition;	//�յ��豸�б�
    std::vector<Smarthome_IntelligentAmmeter> vecIntelligentAmmeter;	//���ܵ���б�
};

//��������Ϣ
class IntelligentAmmeter_BasicInfo
{
public:
};

//�����й���Ϣ
class PositiveEnergy
{
public:
    PositiveEnergy()
    {
        iTotalActive = 0;
        iSharpActive = 0;
        iPeakActive = 0;
        iShoulderActive = 0;
        iOffPeakActive = 0;
        
        iTotalReactive = 0;
        iSharpReactive = 0;
        iPeakReactive = 0;
        iShoulderReactive = 0;
        iOffPeakReactive = 0;
    }
    void Init()
    {
        iTotalActive = 0;
        iSharpActive = 0;
        iPeakActive = 0;
        iShoulderActive = 0;
        iOffPeakActive = 0;
        
        iTotalReactive = 0;
        iSharpReactive = 0;
        iPeakReactive = 0;
        iShoulderReactive = 0;
        iOffPeakReactive = 0;
    }
    int iTotalActive;
    int iSharpActive;
    int iPeakActive;
    int iShoulderActive;
    int iOffPeakActive;
    
    int iTotalReactive;
    int iSharpReactive;
    int iPeakReactive;
    int iShoulderReactive;
    int iOffPeakReactive;
};

class InstancePower
{
public:
    InstancePower()
    {
        iActivePower = 0;
        iReactivePower = 0;
    }
    
    int iActivePower;
    int iReactivePower;
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
        //m_iType = emMsgType_Curtain_stop_req;
        m_uiObjectId = 0;
    }
    CMsg_method_v_b_v_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        //m_iType = emMsgType_Curtain_stop_req;
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
        //m_iType = emMsgType_Curtain_stop_req;
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
    virtual ~CMsg_method_v_b_v_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//ʵ��id
    std::string m_strMethod;		//��������
};
//�������������� ����ֵΪbool ��Ӧ
class CMsg_method_v_b_v_rsp : public CDvipMsg
{
public:
    CMsg_method_v_b_v_rsp():CDvipMsg()
    {
        //m_iType = emMsgType_Curtain_stop_rsp;
        m_bResult = false;
    }
    virtual ~CMsg_method_v_b_v_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
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
    virtual ~CMsgDvip_instance_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
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
    virtual ~CMsgDvip_instance_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
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
    virtual ~CMsgDvip_destroy_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
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
    virtual ~CMsgDvip_destroy_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;
};


//��ȡ������Ϣ ����
class CMsgConfigManager_getConfig_req : public CDvipMsg
{
public:
    CMsgConfigManager_getConfig_req():CDvipMsg()
    {
        m_iType = emMsgType_ConfigManager_getConfig_req;
        m_uiObjecId = 0;
    }
    CMsgConfigManager_getConfig_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_ConfigManager_getConfig_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = 0;
    }
    CMsgConfigManager_getConfig_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjecId,char *cfgPath):CDvipMsg()
    {
        m_iType = emMsgType_ConfigManager_getConfig_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = uiObjecId;
        m_strName = cfgPath;
    }
    virtual ~CMsgConfigManager_getConfig_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjecId;	//ʵ��id
    std::string m_strName;		//��������
};
//��ȡ����������Ϣ ��Ӧ
class CMsgConfigManager_getConfig_rsp : public CDvipMsg
{
public:
    CMsgConfigManager_getConfig_rsp():CDvipMsg()
    {
        m_iType = emMsgType_ConfigManager_getConfig_rsp;
        m_bResult = false;
    }
    virtual ~CMsgConfigManager_getConfig_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;				//���
    std::string m_strConfig;	//������Ϣ
    Json::Value m_jsonConfig;
};

//����������Ϣ ����
class CMsgConfigManager_setConfig_req : public CDvipMsg
{
public:
    CMsgConfigManager_setConfig_req():CDvipMsg()
    {
        m_iType = emMsgType_ConfigManager_setConfig_req;
        m_uiObjecId = 0;
    }
    CMsgConfigManager_setConfig_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_ConfigManager_setConfig_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = 0;
    }
    CMsgConfigManager_setConfig_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjecId,char *cfgPath,Json::Value &jsCfg):CDvipMsg()
    {
        m_iType = emMsgType_ConfigManager_setConfig_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = uiObjecId;
        m_strName = cfgPath;
        m_jsonConfig = jsCfg;
    }
    virtual ~CMsgConfigManager_setConfig_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjecId;	//ʵ��id
    std::string m_strName;		//��������
    std::string m_strConfig;	//������Ϣ
    Json::Value m_jsonConfig;	//������Ϣ
};
//����������Ϣ ��Ӧ
class CMsgConfigManager_setConfig_rsp : public CDvipMsg
{
public:
    CMsgConfigManager_setConfig_rsp():CDvipMsg()
    {
        m_iType = emMsgType_ConfigManager_setConfig_rsp;
        m_bResult = false;
    }
    virtual ~CMsgConfigManager_setConfig_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;				//���
    std::string m_strResult;	//������Ϣ
};


//��ȡ�豸������Ϣ ����
class CMsgMagicBox_getDevConfig_req : public CDvipMsg
{
public:
    CMsgMagicBox_getDevConfig_req():CDvipMsg()
    {
        m_iType = emMsgType_MagicBox_getDevConfig_req;
        m_uiObjecId = 0;
    }
    CMsgMagicBox_getDevConfig_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_MagicBox_getDevConfig_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = 0;
    }
    CMsgMagicBox_getDevConfig_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjecId,char *cfgPath):CDvipMsg()
    {
        m_iType = emMsgType_MagicBox_getDevConfig_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = uiObjecId;
        m_strName = cfgPath;
    }
    virtual ~CMsgMagicBox_getDevConfig_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjecId;	//ʵ��id
    std::string m_strName;		//��������
};
//��ȡ�豸������Ϣ ��Ӧ
class CMsgMagicBox_getDevConfig_rsp : public CDvipMsg
{
public:
    CMsgMagicBox_getDevConfig_rsp():CDvipMsg()
    {
        m_iType = emMsgType_MagicBox_getDevConfig_rsp;
        m_bResult = false;
    }
    virtual ~CMsgMagicBox_getDevConfig_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;				//���
    std::string m_strConfig;	//������Ϣ
    Json::Value m_jsonConfig;
};


//�������Ϊjson(params : {}),�������ҲΪjson(params : {}) ����ֵΪbool ����
class CMsg_method_json_b_json_req : public CDvipMsg
{
public:
    CMsg_method_json_b_json_req():CDvipMsg()
    {
        //m_iType = emMsgType_Curtain_stop_req;
        m_uiObjectId = 0;
    }
    CMsg_method_json_b_json_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        //m_iType = emMsgType_Curtain_stop_req;
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
        //m_iType = emMsgType_Curtain_stop_req;
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
    virtual ~CMsg_method_json_b_json_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
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
        //m_iType = emMsgType_Curtain_stop_rsp;
        m_bResult = false;
    }
    virtual ~CMsg_method_json_b_json_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;			//���
    Json::Value m_jsParams;	//�������
};
///////////////////////ͨ����Ϣ////////////////////////

///////////////////////�豸����////////////////////////
//��ȡʵ�� ����
class CMsgMagicBox_instance_req : public CDvipMsg
{
public:
    CMsgMagicBox_instance_req();
    CMsgMagicBox_instance_req(unsigned int uiReqId,unsigned int uiSessId);
    virtual ~CMsgMagicBox_instance_req();
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
};
//��ȡʵ�� ��Ӧ
class CMsgMagicBox_instance_rsp : public CDvipMsg
{
public:
    CMsgMagicBox_instance_rsp();
    virtual ~CMsgMagicBox_instance_rsp();
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjectId;
};

//�ͷ�ʵ�� ����
class CMsgMagicBox_destroy_req : public CDvipMsg
{
public:
    CMsgMagicBox_destroy_req():CDvipMsg()
    {
        m_iType = emMsgType_MagicBox_destroy_req;
        m_uiObjecId = 0;
    }
    CMsgMagicBox_destroy_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_MagicBox_destroy_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = 0;
    }
    CMsgMagicBox_destroy_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjectId):CDvipMsg()
    {
        m_iType = emMsgType_MagicBox_destroy_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = uiObjectId;
    }
    virtual ~CMsgMagicBox_destroy_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjecId;
};
//�ͷ�ʵ�� ��Ӧ
class CMsgMagicBox_destroy_rsp : public CDvipMsg
{
public:
    CMsgMagicBox_destroy_rsp():CDvipMsg()
    {
        m_iType = emMsgType_MagicBox_destroy_rsp;
        m_bResult = false;
    }
    virtual ~CMsgMagicBox_destroy_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;
};


/////////////////////���ܼҾ�/////////////////////
//��ȡ���ܼҾӹ���ʵ�� ����
class CMsgSmarthome_instance_req : public CDvipMsg
{
public:
    CMsgSmarthome_instance_req();
    CMsgSmarthome_instance_req(unsigned int uiReqId,unsigned int uiSessId);
    virtual ~CMsgSmarthome_instance_req();
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
};
//��ȡ���ܼҾӹ���ʵ�� ��Ӧ
class CMsgSmarthome_instance_rsp : public CDvipMsg
{
public:
    CMsgSmarthome_instance_rsp();
    virtual ~CMsgSmarthome_instance_rsp();
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjectId;
};

//�ͷ����ܼҾӹ���ʵ�� ����
class CMsgSmarthome_destroy_req : public CDvipMsg
{
public:
    CMsgSmarthome_destroy_req():CDvipMsg()
    {
        m_iType = emMsgType_Smarthome_destroy_req;
        m_uiObjecId = 0;
    }
    CMsgSmarthome_destroy_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_Smarthome_destroy_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = 0;
    }
    CMsgSmarthome_destroy_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjectId):CDvipMsg()
    {
        m_iType = emMsgType_Smarthome_destroy_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = uiObjectId;
    }
    virtual ~CMsgSmarthome_destroy_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjecId;
};
//�ͷ����ܼҾӹ���ʵ�� ��Ӧ
class CMsgSmarthome_destroy_rsp : public CDvipMsg
{
public:
    CMsgSmarthome_destroy_rsp():CDvipMsg()
    {
        m_iType = emMsgType_Smarthome_destroy_rsp;
        m_bResult = false;
    }
    virtual ~CMsgSmarthome_destroy_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;
};

//��ȡ�豸�б� ����
class CMsgSmarthome_getDeviceList_req : public CDvipMsg
{
public:
    CMsgSmarthome_getDeviceList_req():CDvipMsg()
    {
        m_iType = emMsgType_Smarthome_getDeviceList_req;
        m_uiObjecId = 0;
        m_strDeviceType = "All";
    }
    CMsgSmarthome_getDeviceList_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_Smarthome_getDeviceList_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = 0;
        m_strDeviceType = "All";
    }
    CMsgSmarthome_getDeviceList_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjecId,char *pszType):CDvipMsg()
    {
        m_iType = emMsgType_Smarthome_getDeviceList_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = uiObjecId;
        if ( pszType )
        {
            m_strDeviceType = pszType;
        }
        else
        {
            m_strDeviceType = "All";
        }
    }
    virtual ~CMsgSmarthome_getDeviceList_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjecId;	//ʵ��id
    std::string m_strDeviceType;//��Ҫ��ȡ���豸���� "All" ȫ���豸
    //"AirCondition" �յ�
    //"Light" �ƹ�
    //"GroundHeat" ��ů
    //"BackgroundMusic" ��������
    //"Curtain" ����
    //"FreshAir" �·�
    //"SequencePower" ��Դ������
    //"Projector" ͶӰ��
    
};
//��ȡ�豸�б� ��Ӧ
class CMsgSmarthome_getDeviceList_rsp : public CDvipMsg
{
public:
    CMsgSmarthome_getDeviceList_rsp():CDvipMsg()
    {
        m_iType = emMsgType_Smarthome_getDeviceList_rsp;
        m_bResult = false;
    }
    virtual ~CMsgSmarthome_getDeviceList_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;							//���
    std::vector<Smarthome_DeviceInfo> m_vecDevice;	//�豸�б�
};


//�����豸��Ϣ ����
class CMsgSmarthome_setDeviceInfo_req : public CDvipMsg
{
public:
    CMsgSmarthome_setDeviceInfo_req():CDvipMsg()
    {
        m_iType = emMsgType_Smarthome_setDeviceInfo_req;
        m_uiObjecId = 0;
    }
    CMsgSmarthome_setDeviceInfo_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_Smarthome_setDeviceInfo_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = 0;
    }
    CMsgSmarthome_setDeviceInfo_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjecId,Json::Value &jsCfg):CDvipMsg()
    {
        m_iType = emMsgType_Smarthome_setDeviceInfo_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjecId = uiObjecId;
        m_jsonConfig = jsCfg;
    }
    virtual ~CMsgSmarthome_setDeviceInfo_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjecId;	//ʵ��id
    //std::string m_strName;		//��������
    std::string m_strConfig;	//������Ϣ
    Json::Value m_jsonConfig;	//������Ϣ
};
//����������Ϣ ��Ӧ
class CMsgSmarthome_setDeviceInfo_rsp : public CDvipMsg
{
public:
    CMsgSmarthome_setDeviceInfo_rsp():CDvipMsg()
    {
        m_iType = emMsgType_Smarthome_setDeviceInfo_rsp;
        m_bResult = false;
    }
    virtual ~CMsgSmarthome_setDeviceInfo_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;				//���
    std::string m_strResult;	//������Ϣ
};


//////////////�ƹ�//////////////
//��ȡ�ƹ��豸ʵ�� ����
class CMsgLight_instance_req : public CDvipMsg
{
public:
    CMsgLight_instance_req():CDvipMsg()
    {
        m_iType = emMsgType_Light_instance_req;
    }
    CMsgLight_instance_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_Light_instance_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
    }
    CMsgLight_instance_req(unsigned int uiReqId,unsigned int uiSessId,char *pszDeviceId):CDvipMsg()
    {
        m_iType = emMsgType_Light_instance_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_strDeviceId = pszDeviceId;
    }
    virtual ~CMsgLight_instance_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    std::string m_strDeviceId;//�豸id
};
//��ȡ�ƹ��豸ʵ�� ��Ӧ
class CMsgLight_instance_rsp : public CDvipMsg
{
public:
    CMsgLight_instance_rsp():CDvipMsg()
    {
        m_iType = emMsgType_Light_instance_rsp;
        m_uiObjectId = 0;
    }
    virtual ~CMsgLight_instance_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjectId;		//ʵ��id
};

//�ͷŵƹ��豸ʵ�� ����
class CMsgLight_destroy_req : public CDvipMsg
{
public:
    CMsgLight_destroy_req():CDvipMsg()
    {
        m_iType = emMsgType_Light_destroy_req;
        m_uiObjectId = 0;
    }
    CMsgLight_destroy_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_Light_destroy_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = 0;
    }
    CMsgLight_destroy_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjectId):CDvipMsg()
    {
        m_iType = emMsgType_Light_destroy_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = uiObjectId;
    }
    virtual ~CMsgLight_destroy_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//ʵ��id
};
//�ͷŵƹ��豸ʵ�� ��Ӧ
class CMsgLight_destroy_rsp : public CDvipMsg
{
public:
    CMsgLight_destroy_rsp():CDvipMsg()
    {
        m_iType = emMsgType_Light_destroy_rsp;
        m_bResult = false;
    }
    virtual ~CMsgLight_destroy_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//���
};

//���� ����
class CMsgLight_open_req : public CDvipMsg
{
public:
    CMsgLight_open_req():CDvipMsg()
    {
        m_iType = emMsgType_Light_open_req;
        m_uiObjectId = 0;
    }
    CMsgLight_open_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_Light_open_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = 0;
    }
    CMsgLight_open_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjectId):CDvipMsg()
    {
        m_iType = emMsgType_Light_open_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = uiObjectId;
    }
    virtual ~CMsgLight_open_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//ʵ��id
};
//���� ��Ӧ
class CMsgLight_open_rsp : public CDvipMsg
{
public:
    CMsgLight_open_rsp():CDvipMsg()
    {
        m_iType = emMsgType_Light_open_rsp;
        m_bResult = false;
    }
    virtual ~CMsgLight_open_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//���
};

//�ص� ����
class CMsgLight_close_req : public CDvipMsg
{
public:
    CMsgLight_close_req():CDvipMsg()
    {
        m_iType = emMsgType_Light_close_req;
        m_uiObjectId = 0;
    }
    CMsgLight_close_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_Light_close_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = 0;
    }
    CMsgLight_close_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjectId):CDvipMsg()
    {
        m_iType = emMsgType_Light_close_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = uiObjectId;
    }
    virtual ~CMsgLight_close_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//ʵ��id
};
//�ص� ��Ӧ
class CMsgLight_close_rsp : public CDvipMsg
{
public:
    CMsgLight_close_rsp():CDvipMsg()
    {
        m_iType = emMsgType_Light_close_rsp;
        m_bResult = false;
    }
    virtual ~CMsgLight_close_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//���
};


//��ȡ�ƹ�״̬ ����
class CMsgLight_getState_req : public CDvipMsg
{
public:
    CMsgLight_getState_req():CDvipMsg()
    {
        m_iType = emMsgType_Light_close_req;
        m_uiObjectId = 0;
    }
    CMsgLight_getState_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_Light_close_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = 0;
    }
    CMsgLight_getState_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjectId):CDvipMsg()
    {
        m_iType = emMsgType_Light_close_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = uiObjectId;
    }
    virtual ~CMsgLight_getState_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//ʵ��id
};
//��ȡ�ƹ�״̬ ��Ӧ
class CMsgLight_getState_rsp : public CDvipMsg
{
public:
    CMsgLight_getState_rsp():CDvipMsg()
    {
        m_iType = emMsgType_Light_close_rsp;
        m_bResult = false;
    }
    virtual ~CMsgLight_getState_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//���
    bool m_bIsOnline;
    bool m_bIsOn;
    int m_iLevel;
};


/////////////////////////����////////////////////////////
//��ȡ�����豸ʵ�� ����
class CMsgCurtain_instance_req : public CDvipMsg
{
public:
    CMsgCurtain_instance_req():CDvipMsg()
    {
        m_iType = emMsgType_Curtain_instance_req;
    }
    CMsgCurtain_instance_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_Curtain_instance_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
    }
    CMsgCurtain_instance_req(unsigned int uiReqId,unsigned int uiSessId,char *pszDeviceId):CDvipMsg()
    {
        m_iType = emMsgType_Curtain_instance_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_strDeviceId = pszDeviceId;
    }
    virtual ~CMsgCurtain_instance_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    std::string m_strDeviceId;//�豸id
};
//��ȡ�����豸ʵ�� ��Ӧ
class CMsgCurtain_instance_rsp : public CDvipMsg
{
public:
    CMsgCurtain_instance_rsp():CDvipMsg()
    {
        m_iType = emMsgType_Curtain_instance_rsp;
        m_uiObjectId = 0;
    }
    virtual ~CMsgCurtain_instance_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjectId;		//ʵ��id
};

//�ͷŴ����豸ʵ�� ����
class CMsgCurtain_destroy_req : public CDvipMsg
{
public:
    CMsgCurtain_destroy_req():CDvipMsg()
    {
        m_iType = emMsgType_Curtain_destroy_req;
        m_uiObjectId = 0;
    }
    CMsgCurtain_destroy_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_Curtain_destroy_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = 0;
    }
    CMsgCurtain_destroy_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjectId):CDvipMsg()
    {
        m_iType = emMsgType_Curtain_destroy_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = uiObjectId;
    }
    virtual ~CMsgCurtain_destroy_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//ʵ��id
};
//�ͷŴ����豸ʵ�� ��Ӧ
class CMsgCurtain_destroy_rsp : public CDvipMsg
{
public:
    CMsgCurtain_destroy_rsp():CDvipMsg()
    {
        m_iType = emMsgType_Curtain_destroy_rsp;
        m_bResult = false;
    }
    virtual ~CMsgCurtain_destroy_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//���
};

//�� ����
class CMsgCurtain_open_req : public CDvipMsg
{
public:
    CMsgCurtain_open_req():CDvipMsg()
    {
        m_iType = emMsgType_Curtain_open_req;
        m_uiObjectId = 0;
    }
    CMsgCurtain_open_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_Curtain_open_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = 0;
    }
    CMsgCurtain_open_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjectId):CDvipMsg()
    {
        m_iType = emMsgType_Curtain_open_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = uiObjectId;
    }
    virtual ~CMsgCurtain_open_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//ʵ��id
};
//�� ��Ӧ
class CMsgCurtain_open_rsp : public CDvipMsg
{
public:
    CMsgCurtain_open_rsp():CDvipMsg()
    {
        m_iType = emMsgType_Curtain_open_rsp;
        m_bResult = false;
    }
    virtual ~CMsgCurtain_open_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//���
};

//�ر� ����
class CMsgCurtain_close_req : public CDvipMsg
{
public:
    CMsgCurtain_close_req():CDvipMsg()
    {
        m_iType = emMsgType_Curtain_close_req;
        m_uiObjectId = 0;
    }
    CMsgCurtain_close_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_Curtain_close_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = 0;
    }
    CMsgCurtain_close_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjectId):CDvipMsg()
    {
        m_iType = emMsgType_Curtain_close_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = uiObjectId;
    }
    virtual ~CMsgCurtain_close_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//ʵ��id
};
//�ر� ��Ӧ
class CMsgCurtain_close_rsp : public CDvipMsg
{
public:
    CMsgCurtain_close_rsp():CDvipMsg()
    {
        m_iType = emMsgType_Curtain_close_rsp;
        m_bResult = false;
    }
    virtual ~CMsgCurtain_close_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//���
};

//ֹͣ ����
class CMsgCurtain_stop_req : public CDvipMsg
{
public:
    CMsgCurtain_stop_req():CDvipMsg()
    {
        m_iType = emMsgType_Curtain_stop_req;
        m_uiObjectId = 0;
    }
    CMsgCurtain_stop_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_Curtain_stop_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = 0;
    }
    CMsgCurtain_stop_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjectId):CDvipMsg()
    {
        m_iType = emMsgType_Curtain_stop_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = uiObjectId;
    }
    virtual ~CMsgCurtain_stop_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//ʵ��id
};
//ֹͣ ��Ӧ
class CMsgCurtain_stop_rsp : public CDvipMsg
{
public:
    CMsgCurtain_stop_rsp():CDvipMsg()
    {
        m_iType = emMsgType_Curtain_stop_rsp;
        m_bResult = false;
    }
    virtual ~CMsgCurtain_stop_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//���
};

//��ȡ����״̬ ����
class CMsgCurtain_getState_req : public CDvipMsg
{
public:
    CMsgCurtain_getState_req():CDvipMsg()
    {
        m_iType = emMsgType_Curtain_getState_req;
        m_uiObjectId = 0;
    }
    CMsgCurtain_getState_req(unsigned int uiReqId,unsigned int uiSessId):CDvipMsg()
    {
        m_iType = emMsgType_Curtain_getState_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = 0;
    }
    CMsgCurtain_getState_req(unsigned int uiReqId,unsigned int uiSessId,unsigned int uiObjectId):CDvipMsg()
    {
        m_iType = emMsgType_Curtain_getState_req;
        hdr.request_id = uiReqId;
        hdr.session_id = uiSessId;
        m_uiObjectId = uiObjectId;
    }
    virtual ~CMsgCurtain_getState_req()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//ʵ��id
};
//��ȡ����״̬ ��Ӧ
class CMsgCurtain_getState_rsp : public CDvipMsg
{
public:
    CMsgCurtain_getState_rsp():CDvipMsg()
    {
        m_iType = emMsgType_Curtain_close_rsp;
        m_bResult = false;
    }
    virtual ~CMsgCurtain_getState_rsp()
    {
    }
    
    // �����Ϣ
    virtual int Encode(char *pData,unsigned int iDataLen);
    // �����Ϣ
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//���
    bool m_bIsOnline;
    bool m_bIsOn;
    int m_iLevel;
};

/////////////////////////����////////////////////////////


#endif