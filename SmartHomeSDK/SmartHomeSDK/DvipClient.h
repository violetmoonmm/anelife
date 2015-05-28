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
    
    ////////////////////外部接口///////////////////////
    void SetGateway(unsigned int hLoginId,const char *pServIp
                    ,unsigned short usServPort
                    ,const char *pUsername
                    ,const char *pPassword
                    ,const char *pSn)
    {
        m_uiLoginId = hLoginId;
        //本端信息
        m_strUsername = pUsername;  //用户名
        m_strPassword = pPassword;  //密码
        
        //服务端信息
        m_strServIp = pServIp; //服务端ip
        m_iServPort = (int)usServPort;		 //服务端端口
        
        //INFO_TRACE("ip="<<m_strServIp<<" port="<<m_iServPort
        //	<<" user="<<m_strUsername<<" pwd="<<m_strPassword
        //	<<" sn="<<pSn);
    }
    
    int Login(int waittime);
    int Logout();
    void AutoReconnect();
    int KeepAlive();
    
    //虚接口实现
    int OnDealData();
    void OnDisconnect(int iReason);
    
    int DvipSend(unsigned int id,char *pszMethod, char * pContent,int iContentLength,std::string strGwVCode="",bool bDvip=false);
    
    //读取IPC列表
    int GetIPC(std::string &strConfig,std::string strGwVCode="");
    
    //订阅
    int Subscrible();
    //取消订阅
    int Unsubscrible();
    
    unsigned int GetLoginId()
    {
        return m_uiLoginId;
    }
    
    void AuthCode(std::string strAuthCode)
    {
        m_sAuthCode = strAuthCode;
    }
    
    //验证授权码
    int VerifyAuthCode(const char *sPhoneNumber,const char *sMeid,const char *sAuthCode,std::string strGwVCode="");
    
    void Reconnect();
    
private:
    int Login_Sync();
    
    void OnDataPacket(const char *pData,int pDataLen);
    
    bool LoginRequest(); //登录请求
    bool LoginRequest(unsigned int uiSessId,const char *pPasswordMd5,const char *pPasswordType,const char *pRandom,const char *pRealm); //登录请求(权鉴信息)
    bool LogoutRequest(); //登出请求
    
    //收到注册回应
    void OnLoginResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //收到保活回应
    void OnKeepaliveResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    //收到登出回应
    void OnLogoutResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen);
    
    int m_iTimeout; //超时时间 秒
    
    unsigned int m_uiEventObjectId;
    unsigned int m_uiSubscribeReqId;
    bool m_bHasSubscrible;
    
    std::string m_sAuthCode;
};

#endif
