#ifndef DvrClient_h
#define DvrClient_h
#include "BaseClient.h"
using namespace std;

#define MAX_CHANNEL 1


class CDvipClient: public CBaseClient
{
public:
    CDvipClient();
    ~CDvipClient();
    
    ////////////////////�ⲿ�ӿ�///////////////////////
    void SetGateway(unsigned int hLoginId,const char *pServIp
                    ,unsigned short usServPort
                    ,const char *pUsername
                    ,const char *pPassword
                    ,const char *pSn)
    {
        m_uiLoginId = hLoginId;
        //������Ϣ
        m_strUsername = pUsername;  //�û���
        m_strPassword = pPassword;  //����
        
        //�������Ϣ
        m_strServIp = pServIp; //�����ip
        m_iServPort = (int)usServPort;		 //����˶˿�
        
        //INFO_TRACE("ip="<<m_strServIp<<" port="<<m_iServPort
        //	<<" user="<<m_strUsername<<" pwd="<<m_strPassword
        //	<<" sn="<<pSn);
    }
    
    int Login(int waittime);
    int Logout();
    void AutoReconnect();
    int KeepAlive();
    
    //��ӿ�ʵ��
    int OnDealData();
    void OnDisconnect(int iReason);
    
    int DvipSend(unsigned int id,char *pszMethod, char * pContent,int iContentLength,std::string strGwVCode="",bool bDvip=false);
    
    //��ȡIPC�б�
    int GetIPC(std::string &strConfig,std::string strGwVCode="");
    
    //����
    int Subscrible();
    //ȡ������
    int Unsubscrible();
    
    unsigned int GetLoginId()
    {
        return m_uiLoginId;
    }
    
    void AuthCode(std::string strAuthCode)
    {
        m_sAuthCode = strAuthCode;
    }
    
    //��֤��Ȩ��
    int VerifyAuthCode(const char *sPhoneNumber,const char *sMeid,const char *sAuthCode,std::string strGwVCode="");
    
    void Reconnect();
    
private:
    int Login_Sync();
    
    void OnDataPacket(const char *pData,int pDataLen);
    
    bool LoginRequest(); //��¼����
    bool LoginRequest(unsigned int uiSessId,const char *pPasswordMd5,const char *pPasswordType,const char *pRandom,const char *pRealm); //��¼����(Ȩ����Ϣ)
    bool LogoutRequest(); //�ǳ�����
    
    //�յ�ע���Ӧ
    void OnLoginResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //�յ������Ӧ
    void OnKeepaliveResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //�յ��ǳ���Ӧ
    void OnLogoutResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    
    int m_iTimeout; //��ʱʱ�� ��
    
    unsigned int m_uiEventObjectId;
    unsigned int m_uiSubscribeReqId;
    bool m_bHasSubscrible;
    
    std::string m_sAuthCode;
};

#endif
