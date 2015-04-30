#ifndef DvrClient_h
#define DvrClient_h

#include "Platform.h"
#include <string>
#include <map>
#include <vector>
#include "DvipMsg.h"
#include "MuteX.h"
#include "UtilFuncs.h"
#include "json.h"
#include "Trace.h"
#include "DvrApi.h"
#include "UserConn.h"

using namespace std;

#define MAX_CHANNEL 1

typedef struct _EventInfo
{
    std::string Code;
    int Index;
    std::string Action;
    int UTC;
    int EventID;
    std::string SourceDevice;
}EventInfo;

typedef struct _FileProcessInfo
{
    bool bSOF;
    bool bEOF;
    int Channel;
    int Length;
    
    std::string Time;
    std::string FilePath;
    std::string FTPPath;
    
    EventInfo _event;
}FileProcessInfo;

typedef struct _RealPlayTag
{
    int iChannel;
    unsigned int uRealHandle;
    
    CUserConn *subConn;
}RealPlayTag;

class CDvrClient
{
public:
    CDvrClient();
    ~CDvrClient();
    
    enum EmStatus
    {
        emIdle,
        emConnecting,
        emConnected,
        emRegistering,
        emRegistered
    };
    
    enum EmDisConnectReason
    {
        emDisRe_None,					//����Ҫ
        emDisRe_ConnectFailed,          //����ʧ��
        emDisRe_Disconnected,           //����
        emDisRe_ConnectTimeout,			//���ӳ�ʱ
        emDisRe_RegistedFailed,			//ע��ʧ��
        emDisRe_RegistedTimeout,		//ע�ᳬʱ
        emDisRe_RegistedRefused,		//ע�ᱻ�ܾ�
        emDisRe_Keepalivetimeout,		//����ʧ��
        emDisRe_UnRegistered,			//ע��
        
        emDisRe_UserNotValid,			//�û�����Ч
        emDisRe_PasswordNotValid,		//������Ч
        
        emDisRe_Unknown,                //δ֪ԭ��
    };
    
    
    //static CDvrClient * Instance();
    
    ////////////////////�ⲿ�ӿ�///////////////////////
    void SetDisConnectCb(fOnDisConnect pFcb,void *pUser)
    {
        m_cbOnDisConnect = pFcb;
        m_pUser = pUser;
    }
    void SetDisConnectCbEx(fOnDisConnectEx pFcb,void *pUser)
    {
        m_cbOnDisConnectEx = pFcb;
        m_pUserEx = pUser;
    }
    void SetEventNotifyCb(fOnEventNotify pFcb,void *pUser)
    {
        m_cbOnEventNotify = pFcb;
        m_pEventNotifyUser = pUser;
    }
    void SetAlarmNotifyCb(fOnAlarmNotify pFcb,void *pUser)
    {
        m_cbOnAlarmNotify = pFcb;
        m_pAlarmNotifyUser = pUser;
    }
    void SetAutoReconnect(bool bAuto)
    {
        m_bAutoReConnect = bAuto;
    }
    //int Login_Sync(const char *pServIp,unsigned short usServPort,const char *pUsername,const char *pPassword);
    int CLIENT_Login(const char *pServIp,unsigned short usServPort,const char *pUsername,const char *pPassword);
    int Login_Sync();
    int Login_Asyc();
    int Logout_Sync(int iTimeout = 5000);
    
    //ɾ������ ����
    int ConfigManager_deleteFile(int iTimeout);
    //ɾ������ �ض�����
    int ConfigManager_deleteConfig(std::string &strName,int iTimeout);
    //��ȡ���� �ض�����
    int ConfigManager_getConfig(const std::string &strName,std::string &strConfig,int iTimeout);
    //�����豸��Ϣ
    int SetDeviceInfo_Sync(char *pszDeviceId,char * pszName,int iTimeout);
    
    //��ȡ�豸���� �ض�����
    int MagicBox_getDevConfig(const std::string &strName,std::string &strConfig,int iTimeout);
    
    //��ȡ�����б�
    int GetHouseInfo_Sync(std::vector<Smarthome_HouseInfo> &vecHouse,int iTimeout);
    //���÷����б�
    int SetHouseInfo_Sync(std::vector<Smarthome_HouseInfo> &vecHouse,int iTimeout);
    //��ȡ�龰ģʽ
    int Get_SceneMode_Sync(int &iCurrentId,std::vector<Smarthome_SceneInfo> &vecScenes,int iTimeout);
    //�����龰ģʽ
    int Set_SceneMode_Sync(int iCurrentId,std::vector<Smarthome_SceneInfo> &vecScenes,int iTimeout);
    //��ȡ�豸�б�
    int GetDeviceList_Sync(std::vector<Smarthome_DeviceInfo> &vecDevice,int iTimeout);
    //��ȡ�豸�б�
    int GetDeviceList_Sync(std::string &strType,std::string &strDevices,int iTimeout);
    
    //��ȡ�豸�б���ϢժҪ
    int GetDeviceDigest_Sync(std::string &strType,std::string &strDigest,int iTimeout);
    //��ȡ�龰ģʽ
    int Get_SceneMode_Sync(std::string &strMode,int iTimeout);
    //�����龰ģʽ
    int Set_SceneMode_Sync(std::string &strMode,int iTimeout);
    // �����龰ģʽ
    int Save_SceneMode_Sync(std::string &strName,std::vector<Smarthome_DeviceInfo> vecDevice,int iTimeout);
    // �޸��龰ģʽ����
    int Modify_SceneMode_Sync(std::string &strMode,std::string &strName,int iTimeout);
    // ɾ���龰ģʽ
    int Remove_SceneMode_Sync(std::string &strMode,int iTimeout);
    
    
    //��ȡ�ƹ�����
    int Light_getConfig_Sync(std::vector<Smarthome_Light> &vecHouse,int iTimeout);
    //���õƹ�����
    int Light_setConfig_Sync(std::vector<Smarthome_Light> &vecHouse,int iTimeout);
    
    //�ƹ���� ��
    int SetPowerOn_Sync(char *pszDeviceId,int iTimeout);
    //�ƹ���� ��
    int SetPowerOff_Sync(char *pszDeviceId,int iTimeout);
    
    // �ƹ���� ���õƹ�����
    int Light_setBrightLevel_Sync(char *pszDeviceId,int iLevel,int iTimeout);
    // �ƹ���� ���ڵƹ�����
    int Light_adjustBright_Sync(char *pszDeviceId,int iLevel,int iTimeout);
    // �ƹ���� ��ʱ�ص�
    int Light_keepOn_Sync(char *pszDeviceId,int iTime,int iTimeout);
    // �ƹ���� ����˸
    int Light_blink_Sync(char *pszDeviceId,int iTime,int iTimeout);
    // �ƹ���� ��ָ���ٶȴ�һ���
    int Light_openGroup_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout);
    // �ƹ���� ��ָ���ٶȹر�һ���
    int Light_closeGroup_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout);
    // �ƹ���� ��ָ���ٶȵ����ƹ�
    int Light_brightLevelUp_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout);
    // �ƹ���� ��ָ���ٶȵ����ƹ�
    int Light_brightLevelDown_Sync(char *pszDeviceId,int iType,int iSpeed,int iTimeout);
    //��ȡ�ƹ�״̬
    int GetPowerStatus_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iBright,int iTimeout);
    
    ///����
    // ��ȡ��������
    int Curtain_getConfig_Sync(std::vector<Smarthome_Curtain> &vecCurtains,int iTimeout);
    // ���ô�������
    int  Curtain_setConfig_Sync(std::vector<Smarthome_Curtain> &vecCurtains,int iTimeout);
    
    //��
    int Curtain_open_Sync(char *pszDeviceId,int iTimeout);
    //�ر�
    int Curtain_close_Sync(char *pszDeviceId,int iTimeout);
    //ֹͣ
    int Curtain_stop_Sync(char *pszDeviceId,int iTimeout);
    //���������ڹ��
    int Curtain_adjustShading_Sync(char *pszDeviceId,int iScale,int iTimeout);
    //���������ڹ��
    int Curtain_setShading_Sync(char *pszDeviceId,int iScale,int iTimeout);
    
    //��ȡ״̬
    int Curtain_getState_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iShading,int iTimeout);
    
    
    ///��ů
    // ��ȡ��ů����
    int GroundHeat_getConfig_Sync(std::vector<Smarthome_GroundHeat> &vecDevices,int iTimeout);
    // ���õ�ů����
    int GroundHeat_setConfig_Sync(std::vector<Smarthome_GroundHeat> &vecDevices,int iTimeout);
    
    // ��
    int GroundHeat_open_Sync(char *pszDeviceId,int iTimeout);
    // ��
    int GroundHeat_close_Sync(char *pszDeviceId,int iTimeout);
    // �趨��ů�¶�
    int GroundHeat_setTemperature_Sync(char *pszDeviceId,int iTemperture,int iTimeout);
    // ���ڵ�ů�¶�
    int GroundHeat_adjustTemperature_Sync(char *pszDeviceId,int iScale,int iTimeout);
    // ��ȡ��ů״̬
    int GroundHeat_getState_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iTemperture,int iTimeout);
    
    
    // ��ȡ�յ�����
    int AirCondition_getConfig_Sync(std::vector<Smarthome_AirCondition> &vecDevices,int iTimeout);
    // ���ÿյ�����
    int AirCondition_setConfig_Sync(std::vector<Smarthome_AirCondition> &vecDevices,int iTimeout);
    // ��
    int AirCondition_open_Sync(char *pszDeviceId,int iTimeout);
    // ��
    int AirCondition_close_Sync(char *pszDeviceId,int iTimeout);
    // �趨�յ��¶�
    int AirCondition_setTemperature_Sync(char *pszDeviceId,int iTemperture,int iTimeout);
    // �����¶�
    int AirCondition_adjustTemperature_Sync(char *pszDeviceId,int iScale,int iTimeout);
    // ���ù���ģʽ
    int AirCondition_setMode_Sync(char *pszDeviceId,std::string strMode,int iTemperture,int iTimeout);
    // �����ͷ�ģʽ
    int AirCondition_setWindMode_Sync(char *pszDeviceId,std::string strWindMode,int iTimeout);
    // һ������
    int AirCondition_oneKeyControl(char *pszDeviceId,bool bIsOn,std::string strMode,
                                   int iTemperature,std::string strWindMode,int iTimeout);
    
    // ȡ�ÿյ�״̬
    int AirCondition_getState_Sync(char *pszDeviceId,bool &bIsOnline,bool &bIsOn,int &iTemperture,std::string &strMode,std::string &strWindMode,float &fActTemperture,int iTimeout);
    
    
    //���ܵ��
    // ��ȡ���ܵ������
    int IntelligentAmmeter_getConfig_Sync(std::vector<Smarthome_IntelligentAmmeter> &vecDevices,int iTimeout);
    // �������ܵ������
    int IntelligentAmmeter_setConfig_Sync(std::vector<Smarthome_IntelligentAmmeter> &vecDevices,int iTimeout);
    // ��ȡ���ܵ���豸������Ϣ
    int IntelligentAmmeter_getBasicInfo(char *pszDeviceId,IntelligentAmmeter_BasicInfo &stInfo,int waittime);
    // ��ȡ�������
    int IntelligentAmmeter_readMeter(char *pszDeviceId,PositiveEnergy &stPositive,InstancePower &stInst,int waittime);
    // ��ȡ����ϴν�������
    int IntelligentAmmeter_readMeterPrev(char *pszDeviceId,int &iTime,PositiveEnergy &stPositive,int waittime);
    
    //����
    // ������
    int Alarm_setArmMode(const char *pszDeviceId,const char *mode,const char *password,int waittime);
    // ȡ�ñ�������״̬
    int Alarm_getArmMode_Sync(char *pszDeviceId,std::string &strMode,int iTimeout);
    
    // ��Ƶ�ڵ�����
    int GetVideoCovers(bool &bEnable,int iTimeout);
    int SetVideoCovers(bool bEnable,int iTimeout);
    
    //IPCamera
    // ȡ��IPC״̬
    int IPC_getState_Sync(char *pszDeviceId,bool &bIsOnline,int iTimeout);
    
    //����
    int Subscrible_Sync(int iTimeout);
    //ȡ������
    int Unsubscrible_Sync(int iTimeout);
    
    // ʵʱ�ϴ����ݣ�ͼƬ
    int RealLoadPicture(int iTimeout);
    
    // ֹͣ�ϴ����ݣ�ͼƬ
    int StopLoadPic(int iTimeout);
    
    // ץͼ����
    int SnapPicture(char *pszDeviceId,int iTimeout);
    
    
    ///////////////�Ž�����
    int AccessControl_modifyPassword(char *type,char *user,char *oldPassword,char *newPassword,int waittime);
    ////////////////////�ⲿ�ӿ�///////////////////////
    
    
    //������ʹ�ܿ���
    bool EnableSubConnect(bool bEnable);
    bool StartListen();
    bool StopListen();
    
    //ʵʱ����
    unsigned int StartRealPlay(int iChannel,fRealDataCallBack pCb,void * pUser);
    //ֹͣ����
    int StopRealPlay(unsigned int uiRealHandle);
    
    unsigned int GetLoginId()
    {
        return m_uiLoginId;
    }
    
    int Start();
    int Stop();
    int Login();
    int Logout();
    
    unsigned int CreateReqId()
    {
        unsigned int uiRet = 0;
        uiRet = ++s_ui_RequestId;
        if ( uiRet == 0 )
        {
            uiRet = ++s_ui_RequestId;
        }
        return uiRet;
    }
    void CreateLoginId()
    {
        //unsigned int uiRet = 0;
        m_uiLoginId = ++s_ui_LoginId;
        if ( m_uiLoginId == 0 )
        {
            m_uiLoginId = ++s_ui_LoginId;
        }
        //return uiRet;
    }
    unsigned int CreateRealHandle()
    {
        unsigned int uiRealHandle = ++s_ui_RealHandle;
        if ( uiRealHandle == 0 )
        {
            uiRealHandle = ++s_ui_RealHandle;
        }
        return uiRealHandle;
    }
    
    bool HasRealHandle(unsigned int uiRealHandle);
    bool IsRealPlay();
    
private:
    
    int Connect_Async(); //���� �첽
    int PollData(); //��ѯ����
    int Process_Data(); //��������
    int SendData(char *pData,int iDataLen); //��������
    void OnDataPacket(const char *pData,int pDataLen);
    bool LoginRequest(); //��¼����
    bool LoginRequest(unsigned int uiSessId,const char *pPasswordMd5,const char *pPasswordType,const char *pRandom,const char *pRealm); //��¼����(Ȩ����Ϣ)
    bool KeepaliveRequest(); //��������
    bool LogoutRequest(); //�ǳ�����
    
    struct TransInfo;
    //�յ�ע���Ӧ
    void OnLoginResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //�յ������Ӧ
    void OnKeepaliveResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //�յ��ǳ���Ӧ
    void OnLogoutResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    
    //�յ�֪ͨ��Ϣ
    void OnNotification(dvip_hdr &hdr,const char *pData,int pDataLen);
    
    //�յ��ְ�����
    int OnPackage(dvip_hdr &hdr,const char *pData,int pDataLen);
    
    //�յ���ȡ���ܼҾӹ���ʵ����Ӧ
    void OnSmarthome_instance_rsp(TransInfo *pTrans,const char *pData,int pDataLen);
    //�յ��ͷ����ܼҾӹ���ʵ����Ӧ
    void OnSmarthome_destroy_rsp(TransInfo *pTrans,const char *pData,int pDataLen);
    //�յ���ȡ�豸�б��Ӧ
    void OnSmarthome_getDeviceList_rsp(TransInfo *pTrans,const char *pData,int pDataLen);
    
    void OnConnect(); //���ӳɹ�֪ͨ
    void OnDataRecv(); //��������֪ͨ
    void OnDataSend(); //���Է�������֪ͨ
    
    void OnDisConnected(int iReason);
    void OnRegisterSuccess(int iReason);
    void OnRegisterFailed(int iReason);
    
    
    //��ȡ���ܼҾ�ʵ��
    bool Smarthome_instance_Req();
    //�յ���Ӧ
    void OnSmarthome_instance_Rsp(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //�ͷ����ܼҾ�ʵ��
    bool Smarthome_destory_Req(unsigned int uiObject);
    //�յ���Ӧ
    void OnSmarthome_destroy_Rsp(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //��ȡ���ܼҾ��豸�б�
    bool Smarthome_getDeviceList_Req(unsigned int uiObject,int iType);
    //�յ���Ӧ
    void OnSmarthome_getDeviceList_Rsp(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    
    //��������ʵ�� ȫ��ʵ��
    int Dvip_instance(char *pszMethod,unsigned &uiObject,int iTimeout=5000);
    //��������ʵ�� ͨ���豸id
    int Dvip_instance(char *pszMethod,char *pszDeviceId,unsigned &uiObject,int iTimeout=5000);
    //��������ʵ�� ȫ��ʵ��
    int Dvip_instance(char *pszMethod,const Json::Value &jsParams,unsigned &uiObject,int iTimeout=5000);
    //�ͷ�ʵ��
    int Dvip_destroy(char *pszMethod,unsigned uiObject,int iTimeout=5000);
    
    //���÷��� �����������Ϊ��,��������ֵΪbool һ�㺯��ԭ�� bool call(void)
    int Dvip_method_v_b_v(char *pszMethod,unsigned uiObject,bool &bResult,int iTimeout=5000);
    
    //���÷��� �������Ϊjson(params : {}),�������ҲΪjson(params : {}),��������ֵΪbool һ�㺯��ԭ�� bool call(void)
    int Dvip_method_json_b_json(char *pszMethod,unsigned uiObject,Json::Value &inParams,bool &bResult,Json::Value &outParams,int iTimeout=5000);
    
    //���÷��� �������Ϊ��,�������Ϊ��,��������ֵΪbool һ�㺯��ԭ�� bool call(void)
    //int Dvip_method_v_b_bbi(char *pszMethod,unsigned uiObject,bool &bReturn,bool &bOutParam1,bool &bOutParam2,int &iOutParam3,int iTimeout=5000);
    //��ȡ����״̬
    int Dvip_Light_getState(char *pszMethod,unsigned uiObject,bool &bReturn,bool &bIsOnline,bool &bIsOn,int &iBright,int iTimeout=5000);
    //��ȡ����״̬
    int Dvip_Curtain_getState(char *pszMethod,unsigned uiObject,bool &bReturn,bool &bIsOnline,bool &bIsOn,int &iShading,int iTimeout=5000);
    
    //��ȡ������Ϣ
    int Dvip_getConfig(unsigned uiObject,char *pszConfigPath,bool &bResult,Json::Value &jsonCfg,int iTimeout=5000);
    //����������Ϣ
    int Dvip_setConfig(unsigned uiObject,char *pszConfigPath,Json::Value &jsonCfg,bool &bResult,int iTimeout=5000);
    
    //����������Ϣ
    int Dvip_setDeviceInfo(unsigned uiObject,Json::Value &jsonCfg,bool &bResult,int iTimeout=5000);
    
    //����������Ϣ
    bool ParseScence(Json::Value &jsonConfig,std::vector<Smarthome_SceneInfo> &vecScenes);
    //���������Ϣ
    bool EncodeScence(Json::Value &jsonConfig,std::vector<Smarthome_SceneInfo> &vecScenes);
    
    //��ȡ�豸������Ϣ
    int Dvip_getDevConfig(unsigned uiObject,char *pszConfigPath,bool &bResult,Json::Value &jsonCfg,int iTimeout=5000);
    
    //�����˳���������
    void Clear_Tasks();
    
    /////////�̴߳���////////////
#ifdef WIN32
    static unsigned long __stdcall ThreadProc(void *pParam);
#else
    static void* ThreadProc(void *pParam);
#endif
    void ThreadProc(void);
    void Thread_Process();
    
    //���������߳�
    int StartThread();
    //���������߳�
    int StopThread();
    
    //������
    void Process_Task();
    
    FCL_THREAD_HANDLE m_hThread;
    bool m_bExitThread;
    
    
    //������Ϣ
    std::string m_strUsername;  //�û���
    std::string m_strPassword;  //����
    
    //�������Ϣ
    std::string m_strServIp; //�����ip
    int m_iServPort;		 //����˶˿�
    
    FCL_SOCKET m_sSock; //�����׽���
    EmStatus m_emStatus; //����״̬
    int m_error;//������
    unsigned int m_uiSessionId; //��¼�Ựid
    int m_iTimeout; //��ʱʱ�� ��
    int m_iFailedTimes; //����ʧ�ܴ���
    bool m_bAutoReConnect;	//�Ƿ��Զ�����
    bool m_bIsFirstConnect;	//�Ƿ��һ������
    unsigned int m_uiLoginId;
    long long m_llLastTime;
    
    //��������
    enum EmRequestType
    {
        emRT_Unknown,		//δ֪����
        
        
        emRT_method_v_b_v,	//ͨ�÷��� void call(void)
        emRT_method_json_b_json,	//ͨ�÷��� bool call([IN] json,[OUT] json)
        
        emRT_instance,		//��ȡʵ��
        emRT_destroy,		//����ʵ��
        
        emRT_getConfig,		//��ȡ����
        emRT_setConfig,		//��������
        
        emRT_Login,			//��¼����
        emRT_Keepalive,		//��������
        emRT_Logout,		//�ǳ�����
        
        ////////////////���ܼҾ�////////////////
        emRT_Smarthome_instance,		//��ȡʵ��
        emRT_Smarthome_destroy,			//����ʵ��
        emRT_Smarthome_getDeviceList,	//��ȡ�豸�б�
        
        emRT_Smarthome_setDeviceInfo,	//�����豸��Ϣ
        
        //�ƹ�
        emRT_Light_instance,			//��ȡʵ��
        emRT_Light_destroy,				//�ͷ�ʵ��
        emRT_Light_open,				//����
        emRT_Light_close,				//�ص�
        emRT_Light_getState,			//��ȡ״̬
        
        //����
        emRT_Curtain_instance,			//��ȡʵ��
        emRT_Curtain_destroy,			//�ͷ�ʵ��
        emRT_Curtain_open,				//��
        emRT_Curtain_close,				//�ر�
        emRT_Curtain_stop,				//ֹͣ
        emRT_Curtain_getState,			//��ȡ״̬
        ////////////////���ܼҾ�////////////////
        //emRT_Login,			//��¼����
        
        ////////////////�豸����////////////////
        emRT_MagicBox_instance,		//��ȡʵ��
        emRT_MagicBox_destroy,			//����ʵ��
        emRT_MagicBox_getDevConfig,		//��ѯ�豸����
        
    };
    
    struct TransInfo
    {
        enum EmTaskStatus
        {
            emTaskStatus_Failed = -1001,
            emTaskStatus_Timeout = -1002,
            emTaskStatus_Cancel = -1003,
            
            emTaskStatus_Idle = 0,
            emTaskStatus_Success,
            
        };
        EmRequestType type;
        unsigned int seq;
        long long	start; //������ʱ��
        unsigned int timeout; //��ʱʱ��
        int result;
        CDvipMsg *pRspMsg;
        CEventThread hEvent;
        
        TransInfo()
        {
            type = emRT_Unknown;
            seq = 0;
            start = 0;
            timeout = 10000;
            result = emTaskStatus_Idle;
            pRspMsg = 0;
        }
        TransInfo(unsigned int id,long long llBegin,unsigned int uiTimeout=10000)
        {
            type = emRT_Unknown;
            seq = id;
            start = llBegin;
            timeout = uiTimeout;
            result = emTaskStatus_Idle;
            pRspMsg = 0;
        }
        TransInfo(unsigned int id,EmRequestType tp,long long llBegin,unsigned int uiTimeout=10000)
        {
            type = tp;
            seq = id;
            start = llBegin;
            timeout = uiTimeout;
            result = emTaskStatus_Idle;
            pRspMsg = 0;
        }
        ~TransInfo()
        {
        }
        bool IsTimeOut()
        {
            return ( _abs64(GetCurrentTimeMs()-start) >= timeout ) ? true : false;
        }
    };
    //�����б�
    typedef std::map<unsigned int,TransInfo*> RequestList;
    RequestList m_reqList;
    CMutexThreadRecursive m_lockReqList;
    void AddRequest(unsigned int uiReq,TransInfo *trans)
    {
        CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
        //INFO_TRACE("[TEST] add seq "<<uiReq);
        m_reqList[uiReq] = trans;
    }
    TransInfo * FindRequest(unsigned int uiReq)
    {
        CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
        RequestList::iterator it = m_reqList.find(uiReq);
        if ( m_reqList.end() == it )
        {
            return NULL;
        }
        return it->second;
    }
    TransInfo * FetchRequest(unsigned int uiReq) //���б���ȡ��
    {
        CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
        TransInfo *pTrans = NULL;
        RequestList::iterator it = m_reqList.find(uiReq);
        if ( m_reqList.end() == it )
        {
            return NULL;
        }
        pTrans = it->second;
        m_reqList.erase(it);
        return pTrans;
    }
    int RemoveRequest(unsigned int uiReq)
    {
        CMutexGuardT<CMutexThreadRecursive> theLock(m_lockReqList);
        RequestList::iterator it = m_reqList.find(uiReq);
        if ( m_reqList.end() == it )
        {
            return 0;
        }
        //INFO_TRACE("[TEST] remove seq "<<uiReq);
        TransInfo *pTrans = it->second;
        m_reqList.erase(it);
        delete pTrans;
        return 1;
    }
    
    CDvipMsg *CreateMsg(EmRequestType emType);
    
    // �������ӶϿ��ص�
    fOnDisConnect m_cbOnDisConnect;
    void *m_pUser;
    
    // ��������״̬�仯�ص�
    fOnDisConnectEx m_cbOnDisConnectEx;
    void *m_pUserEx;
    
    //������Ϣ
    // ״̬�仯�ص�����ԭ��
    fOnEventNotify m_cbOnEventNotify;
    void *m_pEventNotifyUser;
    
    unsigned int m_uiEventObjectId;
    unsigned int m_uiSid;
    unsigned int m_uiSubscribeReqId;
    bool m_bHasSubscrible;
    
    //����֪ͨ
    fOnAlarmNotify m_cbOnAlarmNotify;
    void *m_pAlarmNotifyUser;
    
    unsigned int m_uiSnapObjectId;
    //unsigned int m_uiSnapSid;
    
    const static  int MAX_BUF_LEN = 1024*128;
    //������ջ���
    char m_szRecvBuf[MAX_BUF_LEN];
    int m_iRecvIndex; //���ջ�������
    
    static unsigned int s_ui_RequestId; 
    static unsigned int s_ui_LoginId; 
    static unsigned int s_ui_RealHandle; 
    
    const static unsigned int GS_LOGIN_TIMEOUT = 15000;			//��¼��ʱʱ��
    const static unsigned int GS_KEEPALIVE_INTEVAL = 15000;		//������
    const static unsigned int GS_TIMEOUT = 30000;				//��ʱʱ��
    
    enum emIdle{
        IDLE_NORMAL=0,
        IDLE_PACKAGE,
    };
    int m_idle;
    FileProcessInfo m_fileinfo;
    const static  int MAX_PIC_LEN = 1024*128;
    char m_filebuffer[MAX_PIC_LEN];
    int m_pos;
    int m_packet_index;
    
    bool m_hasMainConn;
    CUserConn * m_pMainConn;
    RealPlayTag m_RealPlayArray[MAX_CHANNEL];
    unsigned int m_uRealHandle;
};

#endif