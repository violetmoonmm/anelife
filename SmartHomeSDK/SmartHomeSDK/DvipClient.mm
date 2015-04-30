#include "json.h"
#include "DvipClient.h"
#include "Trace.h"
#include "DvipMsg.h"
#include "DvrGeneral.h"

CDvipClient::CDvipClient()
{
    m_iTimeout = 15; //��ʱʱ�� ��
    
    m_uiEventObjectId = 0;
    m_uiSid = 0;
    m_uiSubscribeReqId = 0;
    m_bHasSubscrible = false;
}

CDvipClient::~CDvipClient()
{
    Stop();
    ClearSend();
    Clear_Tasks();
}

//CDvipClient * CDvipClient::Instance()
//{
//	static CDvipClient s_instance;
//	return &s_instance;
//}

bool CDvipClient::LoginRequest() //��¼����
{
    dvip_hdr hdr;
    Json::Value jsonContent;
    unsigned int uiReqId;
    unsigned int uiContentLength = 0;
    std::string strContent;
    char szBuf[1024];
    int iPacketLength;
    int iSendLength;
    
    uiReqId = CreateReqId();
    hdr.size = DVIP_HDR_LENGTH;		//hdr����
    //MAGIC
    hdr.magic[0] = 'D';
    hdr.magic[1] = 'H';
    hdr.magic[2] = 'I';
    hdr.magic[3] = 'P';
    hdr.session_id = 0;
    hdr.request_id = uiReqId;
    hdr.packet_length = 0;
    hdr.packet_index = 0;
    hdr.message_length = 0;
    hdr.data_length = 0;
    
    jsonContent["id"] = uiReqId; //����id requstId
    jsonContent["method"] = "global.login"; //���� ��¼����
    ////�����б�
    //jsonContent["params"]["deviceId"] = "Dahua3.0"; //�豸ID��Ψһ��ʶƽ̨�����µ��豸����Ϊ��������λĿ���豸ʱʹ��
    //jsonContent["params"]["proxyToken"] = "Dahua3.0"; //�������ƣ����ڴ����������Ȩʹ��
    jsonContent["params"]["loginType"] = "Direct"; //��¼��ʽ Ϊ�ձ�ʾ"Direct" "Direct" ��Ե��¼ "CMS" ͨ��CMS��������¼ "LDAP" ͨ��LDAP��������¼ "ActiveDirectory" ͨ��AD��������¼
    jsonContent["params"]["userName"] = m_strUsername; //�û���
    jsonContent["params"]["password"] = "******";//m_strPassword; //����
    jsonContent["params"]["clientType"] = "Dahua3.0"; //�ͻ�������
    jsonContent["params"]["ipAddr"] = "127.0.0.1"; //�ͻ���ip��ַ
    jsonContent["params"]["authorityType"] = "Default"; //��Ȩ��ʽ "Default" �C Ĭ�ϼ�Ȩ��ʽ  "HttpDigest" �C HTTP ժҪ��Ȩ��ʽ
    //jsonContent["params"]["authorityInfo"] = "127.0.0.1"; //���Ӽ�Ȩ��Ϣ  "authorityType" Ϊ "Default" ʱ����ֵΪ�ա� "authorityType" Ϊ "HttpDigest" ʱ����ֵΪ��nc:cnonce:qop:ha2���μ�HttpDigest��Ȩ����
    //jsonContent["params"]["stochasticId"] = "127.0.0.1"; //����������ڷ�������֤������һ������ʱ���Ӵ�ֵ
    jsonContent["params"]["userTag"] = "zwan";
    
    strContent = jsonContent.toStyledString();
    uiContentLength = strContent.size();
    hdr.packet_length = uiContentLength;
    hdr.message_length = uiContentLength;
    
    memcpy(szBuf,&hdr,DVIP_HDR_LENGTH);
    memcpy(&szBuf[DVIP_HDR_LENGTH],strContent.c_str(),uiContentLength);
    
    //��������
    iPacketLength = uiContentLength+DVIP_HDR_LENGTH;
    iSendLength = SendData(szBuf,iPacketLength);
    if ( 0 > iSendLength )
    {
        return false;
    }
    
    TransInfo *pTrans = new TransInfo;
    if ( !pTrans )
    {
        ERROR_TRACE("out of memory");
        return false;
    }
    pTrans->type = emRT_Login;
    pTrans->seq = uiReqId;
    AddRequest(uiReqId,pTrans);
    return true;
}
//��¼����(Ȩ����Ϣ)
bool CDvipClient::LoginRequest(unsigned int uiSessId
                               ,const char *pPasswordMd5
                               ,const char *pPasswordType
                               ,const char *pRandom
                               ,const char *pRealm)
{
    dvip_hdr hdr;
    Json::Value jsonContent;
    unsigned int uiReqId;
    unsigned int uiContentLength = 0;
    std::string strContent;
    char szBuf[1024];
    int iPacketLength;
    int iSendLength;
    
    uiReqId = CreateReqId();
    hdr.size = DVIP_HDR_LENGTH;		//hdr����
    //MAGIC
    hdr.magic[0] = 'D';
    hdr.magic[1] = 'H';
    hdr.magic[2] = 'I';
    hdr.magic[3] = 'P';
    hdr.session_id = uiSessId;
    hdr.request_id = uiReqId;
    hdr.packet_length = 0;
    hdr.packet_index = 0;
    hdr.message_length = 0;
    hdr.data_length = 0;
    
    jsonContent["id"] = uiReqId; //����id requstId
    jsonContent["session"] = uiSessId; //session-id
    jsonContent["method"] = "global.login"; //���� ��¼����
    ////�����б�
    //jsonContent["params"]["deviceId"] = "Dahua3.0"; //�豸ID��Ψһ��ʶƽ̨�����µ��豸����Ϊ��������λĿ���豸ʱʹ��
    //jsonContent["params"]["proxyToken"] = "Dahua3.0"; //�������ƣ����ڴ����������Ȩʹ��
    //jsonContent["params"]["loginType"] = "Dahua3.0"; //��¼��ʽ Ϊ�ձ�ʾ"Direct" "Direct" ��Ե��¼ "CMS" ͨ��CMS��������¼ "LDAP" ͨ��LDAP��������¼ "ActiveDirectory" ͨ��AD��������¼
    jsonContent["params"]["userName"] = m_strUsername; //�û���
    jsonContent["params"]["password"] = pPasswordMd5;//m_strPassword; //����
    jsonContent["params"]["passwordType"] = pPasswordType;//m_strPassword; //����
    jsonContent["params"]["random"] = pRandom;//m_strPassword; //����
    jsonContent["params"]["realm"] = pRealm;//m_strPassword; //����
    jsonContent["params"]["clientType"] = "Dahua3.0"; //�ͻ�������
    jsonContent["params"]["ipAddr"] = "127.0.0.1"; //�ͻ���ip��ַ
    //jsonContent["params"]["authorityType"] = "Default"; //��Ȩ��ʽ "Default" �C Ĭ�ϼ�Ȩ��ʽ  "HttpDigest" �C HTTP ժҪ��Ȩ��ʽ
    //jsonContent["params"]["authorityInfo"] = "127.0.0.1"; //���Ӽ�Ȩ��Ϣ  "authorityType" Ϊ "Default" ʱ����ֵΪ�ա� "authorityType" Ϊ "HttpDigest" ʱ����ֵΪ��nc:cnonce:qop:ha2���μ�HttpDigest��Ȩ����
    //jsonContent["params"]["stochasticId"] = pRandom; //����������ڷ�������֤������һ������ʱ���Ӵ�ֵ
    jsonContent["params"]["userTag"] = "zwan";
    
    strContent = jsonContent.toStyledString();
    uiContentLength = strContent.size();
    hdr.packet_length = uiContentLength;
    hdr.message_length = uiContentLength;
    
    memcpy(szBuf,&hdr,DVIP_HDR_LENGTH);
    memcpy(&szBuf[DVIP_HDR_LENGTH],strContent.c_str(),uiContentLength);
    
    //��������
    iPacketLength = uiContentLength+DVIP_HDR_LENGTH;
    iSendLength = SendData(szBuf,iPacketLength);
    if ( 0 > iSendLength )
    {
        //ERROR_TRACE("send data failed");
        return false;
    }
    TransInfo *pTrans = new TransInfo;
    if ( !pTrans )
    {
        ERROR_TRACE("out of memory");
        return false;
    }
    pTrans->type = emRT_Login;
    pTrans->seq = uiReqId;
    AddRequest(uiReqId,pTrans);
    return true;
}
int CDvipClient::KeepAlive() //��������
{
    dvip_hdr hdr;
    Json::Value jsonContent;
    unsigned int uiReqId;
    unsigned int uiContentLength = 0;
    std::string strContent;
    char szBuf[1024];
    int iPacketLength;
    int iSendLength;
    
    uiReqId = CreateReqId();
    hdr.size = DVIP_HDR_LENGTH;		//hdr����
    //MAGIC
    hdr.magic[0] = 'D';
    hdr.magic[1] = 'H';
    hdr.magic[2] = 'I';
    hdr.magic[3] = 'P';
    hdr.session_id = m_uiSessionId;
    hdr.request_id = uiReqId;
    hdr.packet_length = 0;
    hdr.packet_index = 0;
    hdr.message_length = 0;
    hdr.data_length = 0;
    
    jsonContent["id"] = uiReqId; //����id requstId
    jsonContent["session"] = m_uiSessionId; //session-id
    jsonContent["method"] = "global.keepAlive"; //���� ��������
    ////�����б�
    jsonContent["params"]["timeout"] = 60;//m_iTimeout; //��ʱʱ��
    
    strContent = jsonContent.toStyledString();
    uiContentLength = strContent.size();
    hdr.packet_length = uiContentLength;
    hdr.message_length = uiContentLength;
    
    memcpy(szBuf,&hdr,DVIP_HDR_LENGTH);
    memcpy(&szBuf[DVIP_HDR_LENGTH],strContent.c_str(),uiContentLength);
    
    //��������
    iPacketLength = uiContentLength+DVIP_HDR_LENGTH;
    iSendLength = SendData(szBuf,iPacketLength);
    if ( 0 > iSendLength )
    {
        //ERROR_TRACE("send data failed");
        return false;
    }
    TransInfo *pTrans = new TransInfo(uiReqId,emRT_Keepalive,GetCurrentTimeMs(),CBaseClient::GS_HEARTBEAT_INTERVAL);
    if ( !pTrans )
    {
        ERROR_TRACE("out of memory");
        return -1;
    }
    
    AddRequest(uiReqId,pTrans);
    return 0;
}
bool CDvipClient::LogoutRequest() //�ǳ�����
{
    dvip_hdr hdr;
    Json::Value jsonContent;
    unsigned int uiReqId;
    unsigned int uiContentLength = 0;
    std::string strContent;
    char szBuf[1024];
    int iPacketLength;
    int iSendLength;
    
    uiReqId = CreateReqId();
    hdr.size = DVIP_HDR_LENGTH;		//hdr����
    //MAGIC
    hdr.magic[0] = 'D';
    hdr.magic[1] = 'H';
    hdr.magic[2] = 'I';
    hdr.magic[3] = 'P';
    hdr.session_id = m_uiSessionId;
    hdr.request_id = uiReqId;
    hdr.packet_length = 0;
    hdr.packet_index = 0;
    hdr.message_length = 0;
    hdr.data_length = 0;
    
    jsonContent["id"] = uiReqId; //����id requstId
    jsonContent["method"] = "global.logout"; //���� �ǳ�����
    ////�����б�
    //jsonContent["params"]["timeout"] = m_iTimeout; //�û���
    
    strContent = jsonContent.toStyledString();
    uiContentLength = strContent.size();
    hdr.packet_length = uiContentLength;
    hdr.message_length = uiContentLength;
    
    memcpy(szBuf,&hdr,DVIP_HDR_LENGTH);
    memcpy(&szBuf[DVIP_HDR_LENGTH],strContent.c_str(),uiContentLength);
    
    //��������
    iPacketLength = uiContentLength+DVIP_HDR_LENGTH;
    iSendLength = SendData(szBuf,iPacketLength);
    if ( iSendLength  == iPacketLength )
    {
        //���ͳɹ�
        //return true;
    }
    else if ( iSendLength == FCL_SOCKET_ERROR )
    {
        ERROR_TRACE("send logout request failed.err="<<WSAGetLastError());
        return false;
    }
    else// if ( iSendLength < iPacketLength )
    {
        INFO_TRACE("send parital data.total="<<iPacketLength<<" sended="<<iSendLength);
        //��ӵ����ͻ����б���
        //return true;
    }
    TransInfo *pTrans = new TransInfo(uiReqId,emRT_Logout,GetCurrentTimeMs());
    if ( !pTrans )
    {
        ERROR_TRACE("out of memory");
        return false;
    }
    //pTrans->type = emRT_Logout;
    //pTrans->seq = uiReqId;
    AddRequest(uiReqId,pTrans);
    return true;
}

void CDvipClient::OnDisconnect(int iReason)
{
    m_uiEventObjectId = 0;
    m_uiSid = 0;
    m_bHasSubscrible = false;
    
    if ( m_cbOnDisConnect )
    {
        m_cbOnDisConnect(m_uiLoginId,emLocal,
                         (char*)m_strServIp.c_str(),(unsigned short)m_iServPort,0,iReason,m_pUser);
        INFO_TRACE("m_cbOnDisConnect end");
    }
}

int CDvipClient::OnDealData() //��������
{
    int iCurIndex = 0;
    dvip_hdr hdr;
    bool bHavePacket = true;
    
    if ( m_iRecvIndex <= DVIP_HDR_LENGTH )
    {
        return 0;
    }
    do
    {
        if ( m_iRecvIndex-iCurIndex >= DVIP_HDR_LENGTH )
        {
            memcpy(&hdr,&m_szRecvBuf[iCurIndex],DVIP_HDR_LENGTH);
            if ( hdr.packet_length+DVIP_HDR_LENGTH <= m_iRecvIndex-iCurIndex )
            {
                //��������
                OnDataPacket(&m_szRecvBuf[iCurIndex],(int)(hdr.packet_length+DVIP_HDR_LENGTH));
                iCurIndex += (hdr.packet_length+DVIP_HDR_LENGTH);
            }
            else //����һ������
            {
                bHavePacket = false;
            }
        }
        else
        {
            bHavePacket = false;
        }
    } while ( bHavePacket );
    
    if ( iCurIndex != 0 )
    {
        if ( m_iRecvIndex == iCurIndex ) //����ȫ��������
        {
            m_iRecvIndex = 0;
        }
        else
        {
            memmove(m_szRecvBuf,&m_szRecvBuf[iCurIndex],m_iRecvIndex-iCurIndex);
            m_iRecvIndex -= iCurIndex;
        }
    }
    
    return 0;
}

void CDvipClient::OnDataPacket(const char *pData,int iDataLen)
{
    int iMsgIndex = 0;
    dvip_hdr hdr;
    int iRet = 0;
    
    memcpy(&hdr,pData,DVIP_HDR_LENGTH);
    if ( hdr.size != DVIP_HDR_LENGTH ) //ͷ������
    {
        if ( hdr.size < DVIP_HDR_LENGTH )
        {
            ERROR_TRACE("invalid msg hdr,too short.");
            return ;
        }
        else
        {
            ERROR_TRACE("msg hdr have extend data,not support now.");
            return ;
        }
    }
    else
    {
        iMsgIndex += DVIP_HDR_LENGTH;
    }
    
    if ( hdr.message_length == 0 )
    {
        ERROR_TRACE("invalid msg no msg body.");
        return ;
    }
    
    if (hdr.data_length>0)//����չ���ݣ����
    {
        iRet = OnPackage(m_uiLoginId,hdr,pData+DVIP_HDR_LENGTH,iDataLen-DVIP_HDR_LENGTH);
        if (iRet<0)//���ʧ�ܻ��������������ģʽ
        {
        }
    }
    else
    {
        TransInfo *pTrans;
        //idΪ0��attech��idʱ��ʾ��ǰ��Ϊ֪ͨ��
        if ( 0 == hdr.request_id || (m_bHasSubscrible&&m_uiSubscribeReqId == hdr.request_id))
        {
            //����IDΪ��,notification��Ϣ
            OnNotification(m_uiLoginId,hdr,pData+DVIP_HDR_LENGTH,iDataLen-DVIP_HDR_LENGTH);
            return ;
        }
        else{
            pTrans = FetchRequest(hdr.request_id);
            if ( !pTrans )
            {
                ERROR_TRACE("not find request.reqid="<<hdr.request_id);
                return ;
            }
        }
        
        if ( emRT_Login != pTrans->type )
        {
            if ( m_uiSessionId != hdr.session_id )//�������������󣬳���Ῠס
            {
                ERROR_TRACE("session id invalid.cur="<<hdr.session_id<<"my="<<m_uiSessionId);
                return ;
            }
        }
        CDvipMsg *pMsg = NULL;
        
        switch ( pTrans->type )
        {
            case emRT_Login: //��¼
                return OnLoginResponse(hdr,pTrans,pData+DVIP_HDR_LENGTH,iDataLen-DVIP_HDR_LENGTH);
                break;
            case emRT_Keepalive: //����
                return OnKeepaliveResponse(hdr,pTrans,pData+DVIP_HDR_LENGTH,iDataLen-DVIP_HDR_LENGTH);
                break;
            case emRT_Logout: //�ǳ�
                return OnLogoutResponse(hdr,pTrans,pData+DVIP_HDR_LENGTH,iDataLen-DVIP_HDR_LENGTH);
                break;
            default:
                pMsg = CreateMsg(pTrans->type);
                break;
        }
        
        if ( !pMsg )
        {
            ERROR_TRACE("Create msg failed")
            pTrans->result = TransInfo::emTaskStatus_Failed;
        }
        else
        {
            iRet = pMsg->Decode((char*)pData,(unsigned int)iDataLen);
            if ( 0 != iRet )
            {
                ERROR_TRACE("decode msg failed");
                delete pMsg;
                pTrans->result = TransInfo::emTaskStatus_Failed;
            }
            else
            {
                pTrans->result = TransInfo::emTaskStatus_Success;
                pTrans->pRspMsg = pMsg;
            }
        }
        
        pTrans->hEvent.Signal();
    }
    
    return ;
}

//�յ�ע���Ӧ
void CDvipClient::OnLoginResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen)
{
    int iMsgIndex = 0;
    Json::Reader jsonParser;
    Json::Value jsonContent;
    bool bRet;
    
    if ( hdr.message_length == 0 )
    {
        ERROR_TRACE("invalid msg no msg body.");
        return ;
    }
    
    bRet = jsonParser.parse(pData,pData+hdr.message_length,jsonContent);
    if ( !bRet )
    {
        ERROR_TRACE("parse msg body failed");
        return ;
    }
    
    //
    if ( jsonContent["result"].isNull()
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return ;
    }
    
    bool bIsResultOk = jsonContent["result"].asBool();
    
    unsigned int uiReqId = jsonContent["id"].asUInt();
    unsigned int uiSessionId = jsonContent["session"].asUInt();
    if ( uiReqId != hdr.request_id/* || uiSessionId != hdr.session_id*/ )
    {
        ERROR_TRACE("reqid or sessid not same with hdr");
        return ;
    }
    
    if ( emRegistering != m_emStatus ) //��������ע��
    {
        ERROR_TRACE("status ivalid,not in logining.status="<<(int)m_emStatus);
        return ;
    }
    if ( bIsResultOk ) //��¼�ɹ�
    {
        m_uiSessionId = (unsigned int)uiSessionId;
        OnRegisterSuccess(emDisRe_None);
        return ;
    }
    
    if ( !jsonContent["error"].isNull()
        && !jsonContent["error"]["code"].isNull()
        && jsonContent["error"]["code"].isInt() )
    {
        int iErrorCode = jsonContent["error"]["code"].asInt();
        if ( 0x1003000f == iErrorCode || 401 == iErrorCode) //�û���ѯ
        {
            //���·����¼,Я����֤��Ϣ
            INFO_TRACE("login resonse,need auth");
            
            std::string strMac;
            std::string strRealm;
            std::string strEncryption;
            std::string strAuthorization;
            std::string strRandom;
            
            strRealm		=	jsonContent["params"]["realm"].asString();
            strMac			=	jsonContent["params"]["mac"].asString();
            strEncryption	=	jsonContent["params"]["encryption"].asString();
            strAuthorization=	jsonContent["params"]["authorization"].asString();
            strRandom		=	jsonContent["params"]["random"].asString();
            
            //�����¼����
            std::string strMd5String;
            std::string strMd5Password;
            strMd5String = m_strUsername;
            strMd5String += ":";
            //strMd5String += " ";
            strMd5String += strRealm;
            strMd5String += ":";
            //strMd5String += " ";
            strMd5String += m_strPassword;
            struct MD5Context md5c;
            unsigned char ucResult[16];
            char szTemp[16];
            MD5Init(&md5c);
            MD5Update(&md5c,(unsigned char*)strMd5String.c_str(),strMd5String.size());
            MD5Final(ucResult,&md5c);
            for(int i=0; i<16; i++ )
            {
                sprintf(szTemp,"%02X",ucResult[i]);
                strMd5Password += szTemp;
            }
            //�����Ȩ
            strMd5String = m_strUsername;
            strMd5String += ":";
            strMd5String += strRandom;
            strMd5String += ":";
            strMd5String += strMd5Password;
            MD5Init(&md5c);
            MD5Update(&md5c,(unsigned char*)strMd5String.c_str(),strMd5String.size());
            MD5Final(ucResult,&md5c);
            strMd5Password = "";
            for(int i=0; i<16; i++ )
            {
                sprintf(szTemp,"%02X",ucResult[i]);
                strMd5Password += szTemp;
            }
            
            //�ٴη���ע����(��Ȩ����Ϣ)
            bRet = LoginRequest(uiSessionId,strMd5Password.c_str(),"Default",strRandom.c_str(),strRealm.c_str());
            if ( !bRet )
            {
                ERROR_TRACE("send Authenticate failed.");
                OnRegisterFailed(emDisRe_RegistedFailed);
            }
        }
        else //��¼ʧ��
        {
            switch (iErrorCode)
            {
                case 0x10030006:
                    iErrorCode = emDisRe_UserInvalid;
                    break;
                case 0x10030007:
                    iErrorCode = emDisRe_PasswordInvalid;
                    break;
            }
            
            OnRegisterFailed(iErrorCode);
            return ;
        }
    }
    
}
//�յ������Ӧ
void CDvipClient::OnKeepaliveResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen)
{
    Json::Reader jsonParser;
    Json::Value jsonContent;
    bool bRet;
    
    if ( hdr.message_length == 0 )
    {
        ERROR_TRACE("invalid msg no msg body.");
        return ;
    }
    
    
    bRet = jsonParser.parse(pData,pData+hdr.message_length,jsonContent);
    if ( !bRet )
    {
        ERROR_TRACE("parse msg body failed");
        return ;
    }
    
    //
    if ( jsonContent["result"].isNull()
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return ;
    }
    
    bool bIsResultOk = jsonContent["result"].asBool();
    
    unsigned int uiReqId = jsonContent["id"].asUInt();
    unsigned int uiSessionId = jsonContent["session"].asUInt();
    if ( uiReqId != hdr.request_id || uiSessionId != hdr.session_id )
    {
        ERROR_TRACE("reqid or sessid not same with hdr");
        return ;
    }
    
    if ( emRegistered != m_emStatus ) //��û��ע��ɹ�
    {
        ERROR_TRACE("status ivalid,not in logining.status="<<(int)m_emStatus);
        return ;
    }
    if ( bIsResultOk ) //����ɹ�
    {
        m_llLastTime= GetCurrentTimeMs();
        int iTimeout =  jsonContent["params"]["timeout"].asInt();
        if ( iTimeout > 0 && iTimeout < m_iTimeout )
        {
            m_iTimeout = iTimeout;
        }
    }
    
}
//�յ��ǳ���Ӧ
void CDvipClient::OnLogoutResponse(dvip_hdr &hdr,TransInfo *pTrans,const char *pData,int pDataLen)
{
    Json::Reader jsonParser;
    Json::Value jsonContent;
    bool bRet;
    
    if ( hdr.message_length == 0 )
    {
        ERROR_TRACE("invalid msg no msg body.");
        return ;
    }
    
    
    bRet = jsonParser.parse(pData,pData+hdr.message_length,jsonContent);
    if ( !bRet )
    {
        ERROR_TRACE("parse msg body failed");
        return ;
    }
    
    if ( jsonContent["result"].isNull()
        || !jsonContent["result"].isBool() ) //���
    {
        ERROR_TRACE("no result or result type is not bool.");
        return ;
    }
    
    bool bIsResultOk = jsonContent["result"].asBool();
    
    unsigned int uiReqId = jsonContent["id"].asUInt();
    unsigned int uiSessionId = jsonContent["session"].asUInt();
    if ( uiReqId != hdr.request_id || uiSessionId != hdr.session_id )
    {
        ERROR_TRACE("reqid or sessid not same with hdr");
        return ;
    }
    
    if ( emRegistered != m_emStatus ) //��û��ע��ɹ�
    {
        ERROR_TRACE("status ivalid,not in logining.status="<<(int)m_emStatus);
        return ;
    }
    if ( bIsResultOk ) //�ǳ��ɹ�
    {
        INFO_TRACE("logout OK.");
    }
}

int CDvipClient::Login(int waittime)
{
    m_waittime = waittime;
    m_emStatus = emNone;
    
    int iRet = 0;
    int error = emDisRe_None;
    if (!IsConnected())
    {
        iRet = Connect((char*)m_strServIp.c_str(),m_iServPort);
        if ( iRet < 0 )
        {
            OnRegisterFailed(emDisRe_ConnectFailed);
            error = emDisRe_ConnectFailed;
            return error;
        }
    }
    iRet = Login_Sync();
    if ( 0 != iRet ) //ʧ��
    {
        error = iRet;
    }
    else
    {
        error  = 0;
        Subscrible();
    }
    
    return error;
}
int CDvipClient::Login_Sync()
{
    int iRet = 0;
    bool bResult = false;
    long long llStart = GetCurrentTimeMs();
    long long llEnd;
    
    bool bRet = LoginRequest();
    if ( !bRet )
    {
        OnRegisterFailed(emDisRe_RegistedFailed);
        return emDisRe_RegistedFailed;
    }
    
    m_emStatus = emRegistering;
    
    //�ȴ���¼���
    do
    {
        if ( m_emStatus == emRegistered ) //ע��ɹ�
        {
            bResult = true;
        }
        else if (emIdle == m_emStatus ) //ע��ʧ��
        {
            bResult = true;
        }
        else
        {
            FclSleep(1);
        }
        llEnd = GetCurrentTimeMs();
        
    }while( _abs64(llEnd-llStart) < m_waittime && !bResult );
    
    if ( bResult == true )
    {
        if (emRegistered == m_emStatus)
        {
            iRet  = 0;
        }
        else
        {
            iRet = m_error;
        }
    }
    else //ע��ʧ��
    {
        OnRegisterFailed(emDisRe_RegistedFailed);
        iRet = emDisRe_RegistedFailed;
    }
    
    return iRet;
}

int CDvipClient::Logout()
{
    int iRet = 0;
    bool bRet = true;
    //int iTimeout = 5000;
    
    iRet = Dvip_method_v_b_v_no_rsp("global.logout",0,bRet,m_waittime);
    if ( 0 != iRet )
    {
        ERROR_TRACE("logout failed.err="<<iRet);
        //return iRet;
    }
    if ( bRet )
    {
        INFO_TRACE("logout OK.");
    }
    else
    {
        ERROR_TRACE("logout failed,server return false.");
        iRet = -1;
    }
    
    m_emStatus = emIdle;
    m_bAutoConnect = false;
    return iRet;
}

void CDvipClient::AutoReconnect()
{
    int iRet = Login_Sync();
    if ( 0 != iRet ) //ʧ��
    {
    }
    else
    {
        int nError = 0;
        if (!m_sAuthCode.empty())//��֤
        {
            iRet = VerifyAuthCode(CDvrGeneral::Instance()->PhoneNo(),CDvrGeneral::Instance()->MEID(),
                                  (char*)m_sAuthCode.c_str(),"");
            if (iRet  == 0 )
                nError = emDisRe_AuthOK;
            else
                nError = emDisRe_AuthFailed;
        }
        
        //�ص�֪ͨ
        if ( m_cbOnDisConnect )
        {
            INFO_TRACE("m_cbOnDisConnect emLocal m_uiLoginId="<<m_uiLoginId<<" nError="<<nError);
            m_cbOnDisConnect(m_uiLoginId,emLocal,
                             (char*)m_strServIp.c_str(),(unsigned short)m_iServPort,1,nError,m_pUser);
            INFO_TRACE("m_cbOnDisConnect end");
        }
        
        Subscrible();
    }
}


////////////////////�ⲿ�ӿ�///////////////////////

int CDvipClient::DvipSend(unsigned int id,char *pszMethod, char * pContent,int iContentLength,std::string strGwVCode,bool bDvip)
{
    return SendData(pContent,iContentLength);
}


//����
int CDvipClient::Subscrible()
{
    int iRet = 0;
    unsigned int uiObjectId = 0;
    bool bRet = true;
    int iReturn = 0;
    unsigned int uiSID = 0;
    bool bNeedDestroy = false;
    
    if ( m_bHasSubscrible )
    {
        //�Ѿ�����
        WARN_TRACE("have subscribled.");
        iReturn = 0;
        return iReturn;
    }
    //����ʵ��
    iRet = Dvip_instance("eventManager.factory.instance",uiObjectId,m_waittime);
    if ( 0 != iRet )
    {
        ERROR_TRACE("eventManager instance failed.");
        return -1;
    }
    if ( 0 == uiObjectId )
    {
        ERROR_TRACE("eventManager instance from server failed.objectid=0");
        return -1;
    }
    
    //���������Ϣ
    Json::Value jsonInParams;
    Json::Value jsonOutParams;
    jsonInParams["codes"][0] = "DeviceState";
    jsonInParams["codes"][1] = "AlarmLocal";
    jsonInParams["codes"][2] = "AlarmExtended";
    jsonInParams["codes"][3] = "VideoTalk";
    
    //jsonInParams["codes"][2] = "ArmModeChange";
    //jsonInParams["codes"][0] = "*";
    
    //attach
    iRet = Dvip_method_json_b_json("eventManager.attach",uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime);
    if ( 0 > iRet )
    {
        ERROR_TRACE("eventManager.attach failed.");
        iReturn = -1;
        bNeedDestroy = true;
        //return -1;
    }
    else
    {
        if ( bRet )
        {
            INFO_TRACE("eventManager.attach OK.");
            if ( !jsonOutParams.isNull() && !jsonOutParams["SID"].isNull() )
            {
                uiSID = jsonOutParams["SID"].asUInt();
                m_uiEventObjectId = uiObjectId;
                m_uiSid = uiSID;
                m_uiSubscribeReqId = iRet;
                m_bHasSubscrible = true;
                iReturn = 0;
            }
            else
            {
                ERROR_TRACE("response no SID");
                bNeedDestroy = true;
                iReturn = -1;
            }
        }
        else
        {
            ERROR_TRACE("eventManager.attach failed.");
            bNeedDestroy = true;
            iReturn = -1;
        }
    }
    
    if ( bNeedDestroy )
    {
        //��Ҫ�ͷ�ʵ�� �ͷ�ʵ��
        iRet = Dvip_destroy("eventManager.destroy",m_uiEventObjectId,m_waittime);
        if ( 0 != iRet )
        {
            ERROR_TRACE("eventManager destroy failed.");
        }
    }
    
    return iReturn;
}
//ȡ������
int CDvipClient::Unsubscrible()
{
    int iRet = 0;
    bool bRet = true;;
    int iReturn = 0;
    
    if ( !m_bHasSubscrible )
    {
        ERROR_TRACE("not subscrible,no need cancel.");
        return -1;
    }
    //���������Ϣ
    Json::Value jsonInParams;
    Json::Value jsonOutParams;
    jsonInParams["codes"][0] = "DeviceState";
    jsonInParams["SID"] = m_uiSid;
    
    //detach
    iRet = Dvip_method_json_b_json("eventManager.detach",m_uiEventObjectId,jsonInParams,bRet,jsonOutParams,m_waittime);
    if ( 0 > iRet )
    {
        ERROR_TRACE("eventManager.detach failed.");
        iReturn = -1;
        //return -1;
    }
    else
    {
        if ( bRet )
        {
            INFO_TRACE("eventManager.detach OK.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("eventManager.detach failed.");
            iReturn = -1;
        }
    }
    
    //�ͷ�ʵ��
    iRet = Dvip_destroy("eventManager.destroy",m_uiEventObjectId,m_waittime);
    if ( 0 != iRet )
    {
        ERROR_TRACE("eventManager destroy failed.");
        //return -1;
    }
    
    m_bHasSubscrible = false;
    m_uiEventObjectId = 0;
    m_uiSid = 0;
    m_uiSubscribeReqId = 0;
    
    return iReturn;
}

void CDvipClient::Reconnect()
{
    if ( !IsLogin())
    {
        m_llLastTime  = GetCurrentTimeMs() - CDvipClient::GS_RECONNECT_INTEVAL;
    }
}


int CDvipClient::VerifyAuthCode(const char *sPhoneNumber,const char *sMeid,const char *sAuthCode,std::string strGwVCode)
{
    int iRet = 0;
    unsigned int uiObjectId = 0;
    bool bRet = true;
    int iReturn = 0;
    
    //����ʵ��
    iRet = Dvip_instance("Authorize.factory.instance",uiObjectId,m_waittime,strGwVCode);
    if ( 0 != iRet )
    {
        ERROR_TRACE("Authorize instance failed.");
        return -1;
    }
    if ( 0 == uiObjectId )
    {
        ERROR_TRACE("Authorize instance from server failed.objectid=0");
        return -1;
    }
    
    char md5buffer[32+1];
    // ��һ����֤
    {
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        iRet = Dvip_method_json_b_json("Authorize.verify",uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
        if ( 0 > iRet )
        {
            ERROR_TRACE("Authorize.verify exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            const char *realm  = jsonOutParams["realm" ].asCString();
            const char *random = jsonOutParams["random"].asCString();
            if ( !strcmp(realm,"") || !strcmp(random,"") )
            {
                ERROR_TRACE("realm or random is null.");
                iReturn = -1;
            }
            else
            {
                std::string stringToBeEncode;
                stringToBeEncode += sPhoneNumber;
                stringToBeEncode += ':';
                stringToBeEncode += sMeid;
                stringToBeEncode += ':';
                stringToBeEncode += realm;
                stringToBeEncode += ':';
                stringToBeEncode += sAuthCode;
                
                unsigned char ucResult[16];
                struct MD5Context md5c;
                MD5Init(&md5c);
                MD5Update(&md5c,(unsigned char*)stringToBeEncode.c_str(),stringToBeEncode.size());
                MD5Final(ucResult,&md5c);
                
                BinaryToHex(md5buffer, (char*)ucResult, 16);
                
                stringToBeEncode = sPhoneNumber;
                stringToBeEncode += ':';
                stringToBeEncode += sMeid;
                stringToBeEncode += ':';
                stringToBeEncode += random;
                stringToBeEncode += ':';
                stringToBeEncode += md5buffer;
                
                MD5Init(&md5c);
                MD5Update(&md5c,(unsigned char*)stringToBeEncode.c_str(),stringToBeEncode.size());
                MD5Final(ucResult,&md5c);
                
                BinaryToHex(md5buffer, (char*)ucResult, 16);
                
                iReturn = 0;
            }
        }
        else
        {
            ERROR_TRACE("Authorize.verify failed.");
            iReturn = -1;
        }
    }
    
    // �ڶ�����֤
    if (iReturn == 0)
    {
        Json::Value jsonInParams;
        Json::Value jsonOutParams;
        jsonInParams["PhoneNumber"] = sPhoneNumber;
        jsonInParams["MEID"       ] = sMeid;
        jsonInParams["AuthCode"   ] = md5buffer;
        iRet = Dvip_method_json_b_json("Authorize.verify",uiObjectId,jsonInParams,bRet,jsonOutParams,m_waittime,strGwVCode);
        if ( 0 > iRet )
        {
            ERROR_TRACE("Authorize.verify exec failed.");
            iReturn = -1;
        }
        if ( bRet )
        {
            INFO_TRACE("Authorize.verify ok.");
            iReturn = 0;
        }
        else
        {
            ERROR_TRACE("Authorize.verify failed.");
            iReturn = -1;
        }
    }
    
    //�ͷ�ʵ��
    iRet = Dvip_destroy("Authorize.destroy",uiObjectId,m_waittime,strGwVCode);
    if ( 0 != iRet )
    {
        ERROR_TRACE("Authorize.destroy failed.");
    }
    
    return iReturn;
}

//��ȡIPC�б�
int CDvipClient::GetIPC(std::string &strConfig,std::string strGwVCode)
{
    return GetConfig("IPCamera",strConfig,strGwVCode);
}

