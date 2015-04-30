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
    
    //通用
    emMsgType_ConfigManager_getConfig_req,	//获取
    emMsgType_ConfigManager_getConfig_rsp,	//获取
    emMsgType_ConfigManager_setConfig_req,	//设置
    emMsgType_ConfigManager_setConfig_rsp,	//设置
    
    emMsgType_instance_req,	//获取
    emMsgType_instance_rsp,	//获取
    emMsgType_destroy_req,	//释放
    emMsgType_destroy_rsp,	//释放
    
    ///////////智能家居//////////////
    emMsgType_Smarthome_instance_req,	//获取实例
    emMsgType_Smarthome_instance_rsp,	//获取实例
    emMsgType_Smarthome_destroy_req,	//释放实例
    emMsgType_Smarthome_destroy_rsp,	//释放实例
    emMsgType_Smarthome_getDeviceList_req,	//获取设备列表
    emMsgType_Smarthome_getDeviceList_rsp,	//获取设备列表
    
    emMsgType_Smarthome_setDeviceInfo_req,	//设置设备信息
    emMsgType_Smarthome_setDeviceInfo_rsp,	//设置设备信息
    
    //灯光
    emMsgType_Light_instance_req,	//获取实例
    emMsgType_Light_instance_rsp,	//获取实例
    emMsgType_Light_destroy_req,	//释放实例
    emMsgType_Light_destroy_rsp,	//释放实例
    emMsgType_Light_open_req,		//开灯
    emMsgType_Light_open_rsp,		//开灯
    emMsgType_Light_close_req,		//关灯
    emMsgType_Light_close_rsp,		//关灯
    emMsgType_Light_getState_req,	//获取灯光状态
    emMsgType_Light_getState_rsp,	//获取灯光状态
    
    //窗帘
    emMsgType_Curtain_instance_req,	//获取实例
    emMsgType_Curtain_instance_rsp,	//获取实例
    emMsgType_Curtain_destroy_req,	//释放实例
    emMsgType_Curtain_destroy_rsp,	//释放实例
    emMsgType_Curtain_open_req,		//开
    emMsgType_Curtain_open_rsp,		//开
    emMsgType_Curtain_close_req,	//关
    emMsgType_Curtain_close_rsp,	//关
    emMsgType_Curtain_stop_req,		//停
    emMsgType_Curtain_stop_rsp,		//停
    emMsgType_Curtain_getState_req,	//获取状态
    emMsgType_Curtain_getState_rsp,	//获取状态
    
    ///////////智能家居//////////////
    
    
    //设备配置
    emMsgType_MagicBox_instance_req,
    emMsgType_MagicBox_instance_rsp,
    emMsgType_MagicBox_destroy_req,
    emMsgType_MagicBox_destroy_rsp,
    emMsgType_MagicBox_getDevConfig_req,	//获取设备信息
    emMsgType_MagicBox_getDevConfig_rsp,	//获取设备信息
    
};

//智能家居设备信息
class Smarthome_DeviceInfo
{
public:
    std::string strDeviceType;
    std::string strDeviceId;
    std::string strDeviceName;
    std::string strType;
    int iAreaID;
};

//智能家居设备信息
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

//灯光
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
            //获取一个
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

//窗帘
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
            //获取一个
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

//地暖
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
            //获取一个
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


//空调
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
            //获取一个
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

//智能电表
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
            //获取一个
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

//智能家居设备信息
class Smarthome_SceneInfo
{
public:
    //int iCurrent;			//当前选中场景序号(从0开始)
    std::string  strBrand;
    std::string  strName;
    std::vector<Smarthome_Light> vecLight;					//灯光设备列表
    std::vector<Smarthome_Curtain> vecCurtain;				//窗帘设备列表
    std::vector<Smarthome_GroundHeat> vecGroundHeat;		//地暖设备列表
    std::vector<Smarthome_AirCondition> vecAirCondition;	//空调设备列表
    std::vector<Smarthome_IntelligentAmmeter> vecIntelligentAmmeter;	//智能电表列表
};

//电表基本信息
class IntelligentAmmeter_BasicInfo
{
public:
};

//正向有功信息
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//实例id
    std::string m_strMethod;		//方法名称
};
//无输入和输出参数 返回值为bool 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
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
    virtual ~CMsgDvip_instance_req()
    {
    }
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
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
    virtual ~CMsgDvip_instance_rsp()
    {
    }
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
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
    virtual ~CMsgDvip_destroy_req()
    {
    }
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
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
    virtual ~CMsgDvip_destroy_rsp()
    {
    }
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;
};


//获取配置信息 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjecId;	//实例id
    std::string m_strName;		//配置名称
};
//获取房间配置信息 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;				//结果
    std::string m_strConfig;	//配置信息
    Json::Value m_jsonConfig;
};

//设置配置信息 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjecId;	//实例id
    std::string m_strName;		//配置名称
    std::string m_strConfig;	//配置信息
    Json::Value m_jsonConfig;	//配置信息
};
//设置配置信息 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;				//结果
    std::string m_strResult;	//配置信息
};


//获取设备配置信息 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjecId;	//实例id
    std::string m_strName;		//配置名称
};
//获取设备配置信息 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;				//结果
    std::string m_strConfig;	//配置信息
    Json::Value m_jsonConfig;
};


//输入参数为json(params : {}),输出参数也为json(params : {}) 返回值为bool 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
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
        //m_iType = emMsgType_Curtain_stop_rsp;
        m_bResult = false;
    }
    virtual ~CMsg_method_json_b_json_rsp()
    {
    }
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;			//结果
    Json::Value m_jsParams;	//输出参数
};
///////////////////////通用消息////////////////////////

///////////////////////设备操作////////////////////////
//获取实例 请求
class CMsgMagicBox_instance_req : public CDvipMsg
{
public:
    CMsgMagicBox_instance_req();
    CMsgMagicBox_instance_req(unsigned int uiReqId,unsigned int uiSessId);
    virtual ~CMsgMagicBox_instance_req();
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
};
//获取实例 回应
class CMsgMagicBox_instance_rsp : public CDvipMsg
{
public:
    CMsgMagicBox_instance_rsp();
    virtual ~CMsgMagicBox_instance_rsp();
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjectId;
};

//释放实例 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjecId;
};
//释放实例 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;
};


/////////////////////智能家居/////////////////////
//获取智能家居管理实例 请求
class CMsgSmarthome_instance_req : public CDvipMsg
{
public:
    CMsgSmarthome_instance_req();
    CMsgSmarthome_instance_req(unsigned int uiReqId,unsigned int uiSessId);
    virtual ~CMsgSmarthome_instance_req();
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
};
//获取智能家居管理实例 回应
class CMsgSmarthome_instance_rsp : public CDvipMsg
{
public:
    CMsgSmarthome_instance_rsp();
    virtual ~CMsgSmarthome_instance_rsp();
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjectId;
};

//释放智能家居管理实例 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjecId;
};
//释放智能家居管理实例 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;
};

//获取设备列表 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjecId;	//实例id
    std::string m_strDeviceType;//需要获取的设备类型 "All" 全部设备
    //"AirCondition" 空调
    //"Light" 灯光
    //"GroundHeat" 地暖
    //"BackgroundMusic" 背景音乐
    //"Curtain" 窗帘
    //"FreshAir" 新风
    //"SequencePower" 电源序列器
    //"Projector" 投影仪
    
};
//获取设备列表 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;							//结果
    std::vector<Smarthome_DeviceInfo> m_vecDevice;	//设备列表
};


//设置设备信息 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjecId;	//实例id
    //std::string m_strName;		//配置名称
    std::string m_strConfig;	//配置信息
    Json::Value m_jsonConfig;	//配置信息
};
//设置配置信息 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;				//结果
    std::string m_strResult;	//配置信息
};


//////////////灯光//////////////
//获取灯光设备实例 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    std::string m_strDeviceId;//设备id
};
//获取灯光设备实例 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjectId;		//实例id
};

//释放灯光设备实例 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//实例id
};
//释放灯光设备实例 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//结果
};

//开灯 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//实例id
};
//开灯 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//结果
};

//关灯 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//实例id
};
//关灯 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//结果
};


//获取灯光状态 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//实例id
};
//获取灯光状态 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//结果
    bool m_bIsOnline;
    bool m_bIsOn;
    int m_iLevel;
};


/////////////////////////窗帘////////////////////////////
//获取窗帘设备实例 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    std::string m_strDeviceId;//设备id
};
//获取窗帘设备实例 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    unsigned int m_uiObjectId;		//实例id
};

//释放窗帘设备实例 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//实例id
};
//释放窗帘设备实例 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//结果
};

//打开 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//实例id
};
//打开 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//结果
};

//关闭 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//实例id
};
//关闭 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//结果
};

//停止 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//实例id
};
//停止 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//结果
};

//获取窗帘状态 请求
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    
    unsigned int m_uiObjectId;		//实例id
};
//获取窗帘状态 回应
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
    
    // 打包消息
    virtual int Encode(char *pData,unsigned int iDataLen);
    // 解包消息
    virtual int Decode(char *pData,unsigned int iDataLen);
    
    bool m_bResult;		//结果
    bool m_bIsOnline;
    bool m_bIsOn;
    int m_iLevel;
};

/////////////////////////窗帘////////////////////////////


#endif