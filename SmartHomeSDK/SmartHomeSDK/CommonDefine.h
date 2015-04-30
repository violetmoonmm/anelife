#ifndef COMMONDEFINE_H
#define COMMONDEFINE_H

#include <string>
#include <vector>
#include <list>
#include <functional>
#include <algorithm>
#include "Platform.h"


///////////////œ˚œ¢¿‡–Õ(«Î«ÛªÚªÿ”¶)///////////////
#define HTTP_TYPE_REQUEST        1        //«Î«Û
#define HTTP_TYPE_RESPONSE       2        //ªÿ”¶

///////////////∑Ω∑®¿‡–Õ///////////////
#define	HTTP_METHOD_GET					 1      // http GET
#define	HTTP_METHOD_POST				 2      // http POST
#define	HTTP_METHOD_EX_NOTIFY			 3		 // ¿©’π NOTIFY    ¬º˛Õ®÷™
#define	HTTP_METHOD_EX_NOTIFYSTAR		 4      // ¿©’π NOTIFY * SSDP
#define	HTTP_METHOD_EX_MSEARCH			 5      // ¿©’π M-SEARCH * SSDP
#define	HTTP_METHOD_EX_SUBSCRIBLE		 6      // ¿©’π SUBSCRIBLE
#define	HTTP_METHOD_EX_UNSUBSCRIBLE		 7      // ¿©’π UNSUBSCRIBLE
#define	HTTP_METHOD_EX_REGISTER			 8      // ¿©’π REGISTER
#define	HTTP_METHOD_EX_SEARCH			 9      // ¿©’π SEARCH

///////////////HTTP¿©’πÕ∑”Ú///////////////
#define HEADER_NAME_FROM      "From"
#define HEADER_NAME_TO        "To"
#define HEADER_MEID			  "meid"
#define HEADER_NAME_TAGS      "Tags"
#define HEADER_NAME_ACTION    "ACT"//"NTS"
#define HEADER_NAME_UPNP_AUTHENTICATE    "Upnp-Authenticate"//"Upnp-Authenticate"
#define HEADER_NAME_UPNP_AUTHORIZATION   "Upnp-Authorization"//"Upnp-Authenticate"
#define HEADER_NAME_VERIFY_CODE			 "VerifyCode"//"VerifyCode"


///////////////≤È—Ø¬∑æ∂///////////////
#define PATH_GATEWAY_QUERY_BASIC	"/gateway/query/basic"			//≤È—ØÕ¯πÿª˘±æ–≈œ¢
#define PATH_MEDIA_APPLY			"/media/apply"					//√ΩÃÂ–≠…Ã
#define PATH_MEDIA_RTSP_CHANNEL		"/media/rtsp/channel"			//RTSPÕ®µ¿…Í«Î
#define PATH_ACTIVE_REGISTER		"/query/activeregister"			//≤È—Ø÷˜∂Ø◊¢≤·–≈œ¢


///////////////¿©’π∂Ø◊˜¿‡–Õ///////////////
#define ACTION_REGISTER_REQ				"register"				//◊¢≤·«Î«Û
#define ACTION_REGISTER_RSP				"registerResponse"		//◊¢≤·ªÿ”¶
#define ACTION_KEEPALIVE_REQ			"keepalive"				//±£ªÓ«Î«Û
#define ACTION_KEEPALIVE_RSP			"keepaliveResponse"		//±£ªÓªÿ”¶
#define ACTION_UNREGISTER_REQ			"unregister"			//◊¢œ˙«Î«Û
#define ACTION_UNREGISTER_RSP			"unregisterResponse"	//◊¢œ˙ªÿ”¶
#define ACTION_SEARCH_REQ				"search"				//À—À˜Õ¯πÿ¡–±Ì«Î«Û
#define ACTION_SEARCH_RSP				"searchResponse"		//À—À˜Õ¯πÿ¡–±Ìªÿ”¶
#define ACTION_GETDEVLIST_REQ			"getDeviceList"			//ªÒ»°…Ë±∏¡–±Ì«Î«Û
#define ACTION_GETDEVLIST_RSP			"getDeviceListResponse"	//ªÒ»°…Ë±∏¡–±Ìªÿ”¶
#define ACTION_ACTION_REQ				"action"				//øÿ÷∆«Î«Û
#define ACTION_ACTION_RSP				"actionResponse"		//øÿ÷∆ªÿ”¶
#define ACTION_QUERY_REQ				"query"					//≤È—Ø∞Ê±æ–≈œ¢«Î«Û
#define ACTION_QUERY_RSP				"queryResponse"			//≤È—Ø∞Ê±æ–≈œ¢ªÿ”¶
#define ACTION_DOWNLOADFILE_REQ			"downloadFile"			//œ¬‘ÿŒƒº˛«Î«Û
#define ACTION_DOWNLOADFILE_RSP			"downloadFileResponse"	//œ¬‘ÿŒƒº˛ªÿ”¶
#define ACTION_GATEWAYAUTH_REQ			"gatewayAuth"			//Õ¯πÿ»œ÷§«Î«Û
#define ACTION_GATEWAYAUTH_RSP			"gatewayAuthResponse"	//Õ¯πÿ»œ÷§ªÿ”¶
#define ACTION_SHBG_NOTIFY_REQ			"shbgNotify"			//÷«ƒ‹º“æ”¥ÛÕ¯πÿÕ®÷™œ˚œ¢«Î«Û
#define ACTION_SHBG_NOTIFY_RSP			"shbgNotifyResponse"	//÷«ƒ‹º“æ”¥ÛÕ¯πÿÕ®÷™œ˚œ¢ªÿ”¶
#define ACTION_ALARM_NOTIFY_REQ			"alarmNotify"			//±®æØÕ®÷™œ˚œ¢«Î«Û
#define ACTION_ALARM_NOTIFY_RSP			"alarmNotifyResponse"	//±®æØÕ®÷™œ˚œ¢ªÿ”¶
#define ACTION_MEDIA_APPLY_REQ			"mediaApply"			//√ΩÃÂ–≠…Ãœ˚œ¢«Î«Û
#define ACTION_MEDIA_APPLY_RSP			"mediaApplyResponse"	//√ΩÃÂ–≠…Ãœ˚œ¢ªÿ”¶
#define ACTION_MEDIA_RTSP_CHANNEL_REQ	"mediaRtspChannel"			//RTSPÕ®µ¿…Í«Îœ˚œ¢«Î«Û
#define ACTION_MEDIA_RTSP_CHANNEL_RSP	"mediaRtspChannelResponse"	//RTSPÕ®µ¿…Í«Îœ˚œ¢ªÿ”¶

#define ACTION_SUBSCRIBLE_REQ			"subscrible"			//∂©‘ƒ«Î«Û
#define ACTION_SUBSCRIBLE_RSP			"subscribleResponse"	//∂©‘ƒªÿ”¶
#define ACTION_RENEW_REQ				"renew"					//–¯∂©«Î«Û
#define ACTION_RENEW_RSP				"renewResponse"			//–¯∂©ªÿ”¶
#define ACTION_UNSUBSCRIBLE_REQ			"unsubscrible"			//»°œ˚∂©‘ƒ«Î«Û
#define ACTION_UNSUBSCRIBLE_RSP			"unsubscribleResponse"	//»°œ˚∂©‘ƒªÿ”¶
#define ACTION_NOTIFY_REQ				"notification"			// ¬º˛Õ®÷™«Î«Û
#define ACTION_NOTIFY_RSP				"notifyResponse"		// ¬º˛Õ®÷™ªÿ”¶

#define ACTION_DVIPMETHOD_REQ			"dvipMethod"			//”ÎshbgΩªª•«Î«Û
#define ACTION_DVIPMETHOD_RSP			"dvipMethodResponse"	//”ÎshbgΩªª•ªÿ”¶

#define UPNP_STATUS_CODE_REFUSED			801		//√¸¡Ó±ªæ‹æ¯
#define UPNP_STATUS_CODE_NOT_FOUND			802		//’“≤ªµΩ∂‘∂À
#define UPNP_STATUS_CODE_OFFINE				803		//∂‘∂À≤ª‘⁄œﬂ
#define UPNP_STATUS_CODE_BUSY				804		//√¶
#define UPNP_STATUS_CODE_BAD_REQUEST		805		//√¸¡ÓŒﬁ–ß
#define UPNP_STATUS_CODE_AUTH_FAILED		806		//»œ÷§ ß∞‹
#define UPNP_STATUS_CODE_NEED_AUTH			808		//–Ë“™»œ÷§
#define UPNP_STATUS_CODE_HAVE_REGISTERED	809		//“—æ≠µ«¬º
#define UPNP_STATUS_CODE_PASSWORD_INVALID	810		//√‹¬Î¥ÌŒÛ
#define UPNP_STATUS_CODE_NOT_REACH			812		//∂‘∂À≤ªø…¥Ô

#define HTTP_HEADER_NAME_LEN    64      //httpÕ∑”Ú√˚≥∆◊Ó¥Û≥§∂»
#define HTTP_HEADER_VALUE_LEN   256     //httpÕ∑”Úƒ⁄»›◊Ó¥Û≥§∂»
#define HTTP_URI_PATH_LEN       256     //http uri¬∑æ∂◊Ó¥Û≥§∂»
#define USER_VIRT_CODE_LEN      32     //”√ªß(…Ë±∏)–È∫≈◊Ó¥Û≥§∂»
#define HTTP_TAGS_LEN           128    //tags(–≈¡Ó±‡∫≈)◊Ó¥Û≥§∂»

typedef enum EMMethod
{
    emMethod_RegisterReq    = 1,
    emMethod_RegisterRsp    = 2,
    emMethod_KeepaliveReq   = 3,
    emMethod_KeepaliveRsp	= 4,
    emMethod_UnRegisterReq	= 5,
    emMethod_UnRegisterRsp	= 6,
    emMethod_NotifyReq	= 7,
    
    emMethod_DvipMethodReq	= 11,
    emMethod_DvipMethodRsp	= 12,
    
    emMethod_GatewayAuthReq = 13,
    emMethod_GatewayAuthRsp = 14,
    
};

typedef enum EMDevType
{
    emCommLight = 0,
    emLevelLight = 1,
    emCurtain    = 2,
    emAirCondition   = 3,
    emGroudHeat	= 4,
    emIntelligentAmmeter	= 5,
    emAlarmZone	= 6,
    emIPCamera	= 7,
    emSceneMode	= 8,
    emBlanketSocket = 9,
    emEnvironmentMonitor = 10,
    emBackgroundMusic = 11,
    
};


//√˚◊÷-÷µ∂‘
typedef struct
{
    char szName[HTTP_HEADER_NAME_LEN];
    char szValue[HTTP_HEADER_VALUE_LEN];
}NAME_VALUE,*LPNAME_VALUE;

// HTTPÕ∑
typedef struct
{
    int iType;                      //¿‡–Õ  1 «Î«Û 2 ªÿ”¶
    int iProtocolVer;               //http–≠“È∞Ê±æ 1 1.0 2 1.1 µ±«∞÷ª÷ß≥÷1.1∞Ê±æ
    int iMethod;                    //∑Ω∑® ÷ª”–«Î«Û÷–”–“‚“Â
    char szPath[HTTP_URI_PATH_LEN]; //¬∑æ∂ ÷ª”–«Î«Û÷–”–“‚“Â
    int iStatusCode;                //◊¥Ã¨¬Î ÷ª”–ªÿ”¶÷–”–“‚“Â
    int iContentLength;             //–≈œ¢ƒ⁄»›≥§∂»
    char szFrom[USER_VIRT_CODE_LEN];
    char szTo[USER_VIRT_CODE_LEN];
    char szTags[HTTP_TAGS_LEN];
    char szAction[HTTP_TAGS_LEN];
    int iCount;                     //∆‰À˚Õ∑”Ú ˝ƒø
    NAME_VALUE hdrs[1];             //∆‰À˚Õ∑”Ú
}HTTP_HEADER, *LPHTTP_HEADER;

std::string ToUpper(std::string strSrc);
std::string ToLower(std::string strSrc);

#if 0
//trim left space
std::string TrimLeft(std::string &s)
{
    s.erase(s.begin(),std::find_if(s.begin(),s.end(),std::not1(std::ptr_fun<int,int>(std::isspace))));
    return s;
}
//trim right space
std::string TrimRight(std::string &s)
{
    s.erase(std::find_if(s.rbegin(),s.rend(),std::not1(std::ptr_fun<int,int>(std::isspace))).base(),s.end());
    return s;
}
//trim both space
std::string TrimBoth(std::string &s)
{
    return TrimLef(TrimRight(s));
}
#endif


class CIsSpace
{
public:
    int operator() (const char c)
    {
        return c == ' ';
    }
};

class CIsQuote
{
public:
    int operator() (const char c)
    {
        return c == '\"';
    }
};

template<typename IS>
void LTrimString(std::string &aTrim, IS aIs)
{
    LPCSTR pStart = aTrim.c_str();
    LPCSTR pMove = pStart;
    
    for ( ; *pMove; ++pMove)
    {
        if (!aIs(*pMove))
        {
            if (pMove != pStart)
            {
                size_t nLen = strlen(pMove);
                aTrim.replace(0, nLen, pMove, nLen);
                aTrim.resize(nLen);
            }
            return;
        }
    }
};

template<typename IS>
void RTrimString(std::string &aTrim, IS aIs)
{
    if (aTrim.empty())
        return;
    
    LPCSTR pStart = aTrim.c_str();
    LPCSTR pEnd = pStart + aTrim.length() - 1;
    LPCSTR pMove = pEnd;
    
    for ( ; pMove >= pStart; --pMove)
    {
        if (!aIs(*pMove))
        {
            if (pMove != pEnd)
                aTrim.resize(pMove - pStart + 1);
            return;
        }
    }
};

template<typename IS>
void TrimString(std::string &aTrim, IS aIs)
{
    LTrimString(aTrim, aIs);
    RTrimString(aTrim, aIs);
};

class NameValue
{
public:
    NameValue()
    {
    }
    NameValue(const char* name,const char* value)
    {
        m_strArgumentName = name;
        m_strArgumentValue = value;
    }
    NameValue(const std::string name,const std::string value)
    {
        m_strArgumentName = name;
        m_strArgumentValue = value;
    }
    std::string m_strArgumentName;
    std::string m_strArgumentValue;
};

typedef enum _tagHttpMethod
{
    emMethodGet           = 1,        // http get
    emMethodPost          = 2,        // http post
    emMethodNotify        = 3,      // ¿©’π NOTIFY    ¬º˛Õ®÷™
    emMethodNotifyStar    = 4,      // ¿©’π NOTIFY * SSDP
    emMethodMsearch       = 5,      // ¿©’π M-SEARCH * SSDP
    emMethodSubscrible    = 6,      // ¿©’π SUBSCRIBLE
    emMethodUnSubscrible  = 7,      // ¿©’π UNSUBSCRIBLE
    emMethodRegister      = 8,      // ¿©’π REGISTER
    emMethodSearch        = 9,      // ¿©’π SEARCH
    
}HttpMethod;

class HttpMessage
{
public:
    HttpMessage()
    {
        iType = 0;
        iMethod = 0;
        iStatusCode = 0;
        iContentLength = 0;
        bIsChunkMode = false;
    }
    
    std::string GetValue(const std::string strName)
    {
        for(size_t i=0;i<vecHeaderValues.size();i++)
        {
            if ( vecHeaderValues[i].m_strArgumentName == strName )
            {
                return vecHeaderValues[i].m_strArgumentValue;
            }
        }
        return std::string();
    }
    std::string GetValue(const char* strName)
    {
        return GetValue(std::string(strName));
    }
    std::string GetValueNoCase(const std::string strName)
    {
        std::string strNameUpper = ToUpper(strName);
        std::string strTempUpper;
        
        for(size_t i=0;i<vecHeaderValues.size();i++)
        {
            strTempUpper = ToUpper(vecHeaderValues[i].m_strArgumentName);
            if ( strTempUpper == strNameUpper )
                //if ( vecHeaderValues[i].m_strArgumentName == strName )
            {
                return vecHeaderValues[i].m_strArgumentValue;
            }
        }
        return std::string();
    }
    std::string GetValueNoCase(const char* strName)
    {
        return GetValueNoCase(std::string(strName));
    }
    
    void SetValue(std::string strName,std::string strValue)
    {
        std::string strNameUpper = ToUpper(strName);
        std::string strTempUpper;
        for(size_t i=0;i<vecHeaderValues.size();i++)
        {
            strTempUpper = ToUpper(vecHeaderValues[i].m_strArgumentName);
            if ( strTempUpper == strNameUpper )
            {
                vecHeaderValues[i].m_strArgumentValue = strValue;
                return ;
            }
            //if ( vecHeaderValues[i].m_strArgumentName == strName )
            //{
            //	 vecHeaderValues[i].m_strArgumentValue = strValue;
            //	 return ;
            //}
        }
        vecHeaderValues.push_back(NameValue(strName,strValue));
        return ;
        
    }
    
    void RemoveValueNoCase(std::string strName)
    {
        std::string strNameUpper = ToUpper(strName);
        std::string strTempUpper;
        
        for(size_t i=0;i<vecHeaderValues.size();i++)
        {
            strTempUpper = ToUpper(vecHeaderValues[i].m_strArgumentName);
            if ( strTempUpper == strNameUpper )
            {
                vecHeaderValues.erase(vecHeaderValues.begin()+i);
                return ;
            }
        }
    }
    std::string ToHttpheader()
    {
        std::string strTemp;
        if ( 1 == iType ) //request
        {
            switch ( iMethod )
            {
                case emMethodGet:   //GET
                    strTemp += "GET ";
                    break;
                case emMethodPost:   //POST
                    strTemp += "POST ";
                    break;
                case emMethodNotify:   //NOTIFY
                    strTemp += "NOTIFY ";
                    break;
                case emMethodNotifyStar:   //NOTIFY *
                    strTemp += "NOTIFY * ";
                    break;
                case emMethodMsearch:   //M-SEARCH *
                    strTemp += "M-SEARCH * ";
                    break;
                case emMethodSubscrible:   //SUBSCRIBLE
                    strTemp += "SUBSCRIBLE ";
                    break;
                case emMethodUnSubscrible:   //UNSUBSCRIBLE
                    strTemp += "UNSUBSCRIBLE ";
                    break;
                case emMethodRegister:   //REGISTER
                    strTemp += "REGISTER ";
                    break;
                case emMethodSearch:   //SEARCH
                    strTemp += "SEARCH ";
                    break;
                default:
                    return strTemp;
            }
            strTemp += strPath;
            strTemp += " HTTP/1.1\r\n";
            
        }
        else if ( 2 == iType ) //response
        {
            strTemp += "HTTP/1.1 ";
            switch ( iStatusCode )
            {
                case 200:
                    strTemp += "200 OK";
                    break;
                case 401:
                    strTemp += "401 Unauthorited";
                    break;
                default:
                {
                    char szTemp[64];
                    sprintf(szTemp,"%d Unknown",iStatusCode);
                    strTemp += szTemp;
                    break;
                }
            }
            strTemp += "\r\n";
        }
        else //Œ¥÷™,≤ª”¶∏√≥ˆœ÷
        {
            return strTemp;
        }
        
        char szTemp[64];
        sprintf(szTemp,"%d",iContentLength);
        this->SetValue("Content-Length",szTemp);
        //strTemp += szTemp;
        //strTemp += "\r\n";
        for(size_t i=0;i<vecHeaderValues.size();i++)
        {
            strTemp += vecHeaderValues[i].m_strArgumentName;
            strTemp += ":";
            strTemp += vecHeaderValues[i].m_strArgumentValue;
            strTemp += "\r\n";
        }
        
        //char szTemp[64];
        //sprintf(szTemp,"Content-Length: %d",iContentLength);
        //strTemp += szTemp;
        //strTemp += "\r\n";
        //strTemp += "Server: Windows Xp\r\n";
        
        strTemp += "\r\n";
        return strTemp;
        
    }
    
    void Clear()
    {
        iType = 0;
        strMethod = "";
        iMethod = 0;
        strPath = "";
        iStatusCode = 0;
        iContentLength = 0;
        bIsChunkMode = false;
        strHeader = "";
        vecHeaderValues.clear();
    }
    
    int iType; //1 request 2 response
    std::string strMethod; //∑Ω∑® «Î«Û
    int iMethod; //∑Ω∑®
    std::string strPath; //path «Î«Û
    int iStatusCode; //◊¥Ã¨¬Î ªÿ”¶
    int iContentLength; //ƒ⁄»›≥§∂»
    bool bIsChunkMode;  // «∑Òchunkedƒ£ Ω
    std::string strHeader; //httpÕ∑
    std::vector<NameValue> vecHeaderValues;
    
};

class EventSub
{
public:
    std::string strEventSubUrl;
    std::string strCallback;
    std::string strSid;
    std::string strDeviceId;
    std::string strServiceType;
    int iStatus; //0 Œ¥∂©‘ƒ 1 “—æ≠∂©‘ƒ
    long long llLastSubTime;
};


class StateVariable
{
public:
    std::string strName;
    std::string strDataType;
    std::string strValue;
    bool bSendEvents;
    std::string strDefaultValue; //ƒ¨»œ÷µ
};

class Argument
{
public:
    std::string strName;
    std::string strValue;
    int iDirection;
    StateVariable * pRelatedStateVariable;
};

class Action
{
public:
    std::string strName;
    std::vector<Argument*> vecArgs;
};

class CEventSuscribler
{
public:
    CEventSuscribler()
    {
        m_ullId = CreateId();
        m_llLastUpDate = 0;
        m_llTimeout = 0;
        m_uiEventId = 0;
        m_bFirst = true;
    }
    ~CEventSuscribler()
    {
    }
    unsigned long long CreateId()
    {
        return ++s_id_generator;
    }
    unsigned int CreateEventSeq()
    {
        //return ++s_event_key_generator;
        if ( m_bFirst )
        {
            m_bFirst = false;
            m_uiEventId = 0;
            return m_uiEventId;
        }
        m_uiEventId++;
        if ( 0 == m_uiEventId )
        {
            m_uiEventId++;
        }
        return m_uiEventId;
    }
    unsigned long long m_ullId; //∂©‘ƒId
    std::string m_strSid; //SID
    std::string m_strCallbackUrl; //ªÿµ˜
    std::string m_strUserId; //∂©‘ƒ’ﬂ±Í ∂–≈œ¢ –È∫≈
    long long m_llLastUpDate; //…œ¥Œ∏¸–¬ ±º‰
    long long m_llTimeout; //≥¨ ± ±º‰
    
    unsigned int m_uiEventId; //Õ®÷™id,µ⁄“ª¥Œ±ÿ–ÎŒ™0,¥À∫Û¥”1ø™ º—≠ª∑(≤ªƒ‹‘ŸŒ™0)
    bool m_bFirst;
    static unsigned long long s_id_generator;
    static unsigned int s_event_key_generator;
};

class Service;

class CEventTask
{
public:
    CEventTask(CEventSuscribler *aUser);
    
    CEventTask(StateVariable *aVar,CEventSuscribler *aUser);
    
    CEventTask(Service *aService,CEventSuscribler *aUser);
    
    void AddVar(StateVariable *aVar);
    
    ~CEventTask();
    
    
    //StateVariable *var;
    CEventSuscribler *user;
    
    std::string strCallback;        //ªÿµ˜µÿ÷∑
    std::string strSid;             //SID
    std::string strUserId;          //–È∫≈
    unsigned int uiSeq;             //SEQ
    std::vector<NameValue> vecArgs; //≤Œ ˝¡–±Ì
    std::list<NameValue*> vecArgs2; //≤Œ ˝¡–±Ì
    
};

class Service
{
public:
    Service()
    {
    }
    Service(std::string type,std::string id,std::string scpdUrl,std::string controlUrl,std::string subUrl)
    {
        m_strServiceType = type;
        m_strServiceId = id;
        m_strSPDUrl = scpdUrl;
        m_strControlUrl = controlUrl;
        m_strEventSubUrl = subUrl;
    }
    
    
    StateVariable *GetStateVariable(std::string name)
    {
        for(size_t i=0;i<vecStateVariables.size();i++)
        {
            if ( vecStateVariables[i]->strName == name )
            {
                return vecStateVariables[i];
            }
        }
        return 0;
    }
    
    //∂¡»°±‰¡ø◊¥Ã¨÷µ
    bool GetStateVariableValue(const std::string &name,std::string &value)
    {
        for(size_t i=0;i<vecStateVariables.size();i++)
        {
            if ( vecStateVariables[i]->strName == name )
            {
                value = vecStateVariables[i]->strValue;
                return true;
            }
        }
        return false;
        
    }
    //…Ë÷√±‰¡ø◊¥Ã¨÷µ
    bool SetStateVariableValue(const std::string &name,std::string &value)
    {
        for(size_t i=0;i<vecStateVariables.size();i++)
        {
            if ( vecStateVariables[i]->strName == name )
            {
                if ( value != vecStateVariables[i]->strValue ) //◊¥Ã¨÷µ∏ƒ±‰
                {
                    vecStateVariables[i]->strValue = value;
                    //–¥ ¬º˛Õ®÷™
                    if ( m_lstSubscribler.size() > 0 )
                    {
                        AddEvent(vecStateVariables[i]);
                    }
                }
                
                return true;
            }
        }
        return false;
    }
    
    bool AddEvent(StateVariable *var)
    {
        std::list<CEventSuscribler*>::iterator it;
        for(it=m_lstSubscribler.begin();it!=m_lstSubscribler.end();it++)
        {
            m_lstTask.push_back(CEventTask(var,*it));
        }
        return true;
    }
    
    CEventSuscribler *FindSubscribler(const std::string &strCallbackUrl)
    {
        CEventSuscribler *pTemp;
        std::list<CEventSuscribler*>::iterator it;
        for(it=m_lstSubscribler.begin();it!=m_lstSubscribler.end();it++)
        {
            pTemp = *it;
            if ( pTemp->m_strCallbackUrl == strCallbackUrl )
            {
                return pTemp;
            }
            
        }
        return NULL;
        
    }
    CEventSuscribler *FindSubscribler2(const std::string &strSid)
    {
        CEventSuscribler *pTemp;
        std::list<CEventSuscribler*>::iterator it;
        for(it=m_lstSubscribler.begin();it!=m_lstSubscribler.end();it++)
        {
            pTemp = *it;
            if ( pTemp->m_strSid == strSid )
            {
                return pTemp;
            }
            
        }
        return NULL;
        
    }
    
    CEventSuscribler *FindSubscribler(const std::string &strUserId,const std::string &strCallbackUrl)
    {
        CEventSuscribler *pTemp;
        std::list<CEventSuscribler*>::iterator it;
        for(it=m_lstSubscribler.begin();it!=m_lstSubscribler.end();it++)
        {
            pTemp = *it;
            if ( pTemp->m_strUserId == strUserId
                && pTemp->m_strCallbackUrl == strCallbackUrl )
            {
                return pTemp;
            }
            
        }
        return NULL;
        
    }
    
    CEventSuscribler *FindSubscribler2(const std::string &strUserId,const std::string &strSid)
    {
        CEventSuscribler *pTemp;
        std::list<CEventSuscribler*>::iterator it;
        for(it=m_lstSubscribler.begin();it!=m_lstSubscribler.end();it++)
        {
            pTemp = *it;
            if ( pTemp->m_strUserId == strUserId
                && pTemp->m_strSid == strSid )
            {
                return pTemp;
            }
            
        }
        return NULL;
        
    }
    bool RemoveSubscribler(CEventSuscribler *pSub)
    {
        CEventSuscribler *pTemp = NULL;
        std::list<CEventSuscribler*>::iterator it;
        for(it=m_lstSubscribler.begin();it!=m_lstSubscribler.end();it++)
        {
            pTemp = *it;
            if ( pTemp == pSub )
            {
                m_lstSubscribler.erase(it);
                break;
            }
            
        }
        if ( !pTemp ) //√ª”–’“µΩ
        {
            return false;
        }
        
        //«Â≥˝»ŒŒÒ
        std::list<CEventTask>::iterator it2=m_lstTask.begin();
        std::list<CEventTask>::iterator itTemp;
        //CEventTask *pEvt;
        for(std::list<CEventTask>::iterator it2=m_lstTask.begin();it2!=m_lstTask.end();it2++)
        {
            //pEvt = *it2;
            if ( it2->user == pTemp )
            {
                itTemp = it2;
                it2++;
                m_lstTask.erase(itTemp);
                //delete pEvt;
            }
            else
            {
                it2++;
            }
        }
        delete pTemp;
        pTemp = NULL;
        return true;
    }
    
    std::string m_strServiceType;
    std::string m_strServiceId;
    std::string m_strSPDUrl;
    std::string m_strControlUrl;
    std::string m_strEventSubUrl;
    
    std::string m_strDescDoc;
    std::vector<Action*> vecActions;
    std::vector<StateVariable*> vecStateVariables;
    EventSub m_eventSub; // ¬º˛∂©‘ƒ–≈œ¢
    std::list<CEventSuscribler*> m_lstSubscribler; //∑˛ŒÒ∂©‘ƒ’ﬂ¡–±Ì
    std::list<CEventTask> m_lstTask;
    
    //øÿ÷∆ µº ƒø±ÍŒª÷√
    std::string m_strScpdIp;
    unsigned short m_usScpdPort;
    std::string m_strScpdlPath;
    
    //øÿ÷∆ µº ƒø±ÍŒª÷√
    std::string m_strControlIp;
    unsigned short m_usControlPort;
    std::string m_strControlPath;
    
    //∂©‘ƒ µº ƒø±ÍŒª÷√
    std::string m_strEventSubIp;
    unsigned short m_usEventSubPort;
    std::string m_strEventSubPath;
};

class DeviceData
{
public:
    DeviceData()
    {
    }
    DeviceData(std::string type,std::string name,std::string udn)
    {
        m_strDeviceType = type;
        m_strFriendlyName = name;
        m_strUDN = udn;
    }
    
    std::string m_strDeviceType;
    std::string m_strFriendlyName;
    std::string m_strUDN;
    std::string m_strManufacturer;
    std::string m_strSerialNumber;
    std::string m_strPresentationURL;
    std::string m_strControlMode; //÷–π˙÷«ƒ‹º“æ”¡™√ÀÃÿ”–◊÷∂Œ ∂Ø◊˜¥¶¿Ìƒ£ Ω upnp_soap http_post
    std::string m_strLayoutId;
    std::string m_strCameraId;
    //std::string m_strUpperId;
    std::vector<Service*> m_vecSericeList;
    std::vector<DeviceData*> m_vecEmbededDeviceList;
    
    std::string m_strDescDoc; //…Ë±∏√Ë ˆŒƒµµµƒxmlª∫¥Ê
    std::string m_strIp;      //…Ë±∏øÿ÷∆°¢∂©‘ƒip
    unsigned short m_usPort;  //…Ë±∏øÿ÷∆°¢∂©‘ƒ∂Àø⁄
    std::string m_strPath;    //∏˘¬∑æ∂
    
    long long m_llLastActive; //…œ¥ŒªÓ‘æ ±º‰
};

class InspectDeviceTask
{
public:
    InspectDeviceTask():usPort(0)
    {
    }
    InspectDeviceTask(std::string loc,std::string uuid)
    {
        strLocation = loc;
        strUuid = uuid;
    }
    
    std::string strLocation;
    std::string strIp;
    unsigned short usPort;
    std::string strPath;
    std::string strUuid;
};

class HttpPostRespAction
{
public:
    std::string strName;
    std::vector<NameValue> args;
};

bool ParseHttpHeader(char *msg,int len,HttpMessage &httpMsg);
//Ω‚ŒˆHTTPÕ∑£®Õ∑≤ø≤ª∞¸∫¨ ◊––£©
bool ParseHttpHeader_NoFirstLine(char *msg,int len,HttpMessage &httpMsg);
//Ω‚Œˆ“ª∏ˆÕ∑”Ú£¨Õ∑”Úø…ƒ‹–Ø¥¯ Ù–‘£¨µ´ «√ª”–∂‡Ãı£¨±»»Á text/xml;boundary=111 ∂¯√ª”–a,b’‚—˘µƒ
bool ParseHttpHeaderField(char *msg,int len,std::string &strValue,std::vector<NameValue> &vecAttributes);


int connect_sync(char *ip,unsigned short port,FCL_SOCKET & sock); //Õ¨≤Ω¡¨Ω”
int RecvHttpResponse(FCL_SOCKET sock,char **ppContent,int *pContentLength,
                     int iTimeout,HttpMessage &httpMessage);
bool ParseGetDeviceListResp(char *pXml,unsigned int uiLen,DeviceData &deviceData);
bool ParseGetServiceResp(char *pXml,unsigned int uiLen,Service &service);


//Ω‚Œˆhttp url(url¿Ô≤ª∞¸∫¨≤Œ ˝)
bool SplitHttpUrl(const std::string url,std::string &strIp,unsigned short &usPort,std::string &strPath);

std::string MakeJsessionId();

//std::string ToUpper(std::string strSrc);

bool ParseNotifyBody(char *msg,int len,std::vector<NameValue*> &args);

void FclSleep(int iMillSec);
long long GetCurrentTimeMs();
int SetBlockMode(FCL_SOCKET sock,bool bIsNoBlock); //…Ë÷√Ã◊Ω”◊÷◊Ë»˚ƒ£ Ω
int SetTcpKeepalive(FCL_SOCKET sock); //…Ë÷√TCP±£ªÓ

#ifdef PLAT_WIN32
#else
unsigned int WSAGetLastError();
#endif


int DHTimr2Utc(const char *szDHTime);

bool ParseAction(char *pXml,unsigned int uiLen,char *action,char *serviceType,std::vector<NameValue> &outArgs);

bool http_post_parse_action_resp(char *pXml,unsigned int uiLen,std::vector<HttpPostRespAction> &outArgs);
std::string gen_soap_action_resp(std::string strServiceType,Action *pAction,std::vector<HttpPostRespAction> &outArgs);

bool ParseGetDeviceListResp(char *pXml,unsigned int uiLen,DeviceData &deviceData);
bool ParseGetServiceResp(char *pXml,unsigned int uiLen,Service &service);

typedef enum EndpointTypeEm
{
    emEpTypeUnknown,
    emEpType_ControlPint,
    emEpType_Device,
    emEpType_Proxy,
    emEpType_Fdms,
    emEpType_Shbg,
};

#ifndef PLAT_WIN32
unsigned int GetTickCount();
#endif //PLAT_WIN32

//…˙≥…uuid,ÀÊª˙ ˝ƒ£ Ω
std::string GeterateGuid();
unsigned int GetMacAddr();
unsigned long long GetMacAddrEx();
unsigned long long GetSysTime100ns();
//…˙≥…bytes ˝ƒøµƒÀÊª˙ ˝
void GenerateRand(unsigned char *buf,int bytes);

int LookupMethod(const char *method);

int LookupDeviceType(const char *szDeviceType);

//ªÒ»°µ±«∞ ±º‰ rfc1123÷–∂®“Âµƒ∏Ò Ω wkday "," SP 2DIGIT SP month SP 4DIGIT SP 2DIGIT ":" 2DIGIT ":" 2DIGIT
char *GetIso1123Date();

///http’™“™À„∑®
//http’™“™ªÿ”¶–≈œ¢
//class HttpAuthenticate
//{
//public:
//	std::string strScheme;	//ƒ£ Ω,±ÿ–ÎŒ™’™“™ƒ£ Ω
//	std::string strRealm;	//∑˛ŒÒ∂À◊ ‘¥±£ª§”Ú,µ±«∞∂‘”⁄Õ¯πÿ≤…”√”Ú@Õ¯πÿsnƒ£ Ω,±»»ÁªÒ»°…Ë±∏¡–±ÌŒ™config@12345678,∆‰÷–configŒ™≤È—Ø…Ë±∏¡–±ÌÀ˘ Ù±£ª§”Ú,12345678Œ™…Ë±∏sn
//	std::string strNonce;	//ÀÊª˙¥Æ
//	std::vector<NameValue> params;
//};

class HttpAuth;

////http’™“™«Î«Û–≈œ¢
class HttpAuth
{
public:
    HttpAuth():bIsResponse(false)
    {
    }
    
    HttpAuth & operator=(const HttpAuth & auth)
    {
        if(this == &auth)
            return *this;
        
        this->strUsername = auth.strUsername;
        this->strScheme = auth.strScheme;
        this->strRealm = auth.strRealm;
        this->strNonce = auth.strNonce;
        this->strUri = auth.strUri;
        this->strResponse = auth.strResponse;
        this->bIsResponse = auth.bIsResponse;
        
        for(size_t i=0;i<auth.params.size();i++)
        {
            NameValue tmp = NameValue(params[i].m_strArgumentName,params[i].m_strArgumentValue);
            this->params.push_back(tmp);
        }
        
        return *this;
    }
    
    std::string ToString();
    
public:
    std::string strUsername;//”√ªß√˚
    std::string strScheme;	//ƒ£ Ω,±ÿ–ÎŒ™’™“™ƒ£ Ω
    std::string strRealm;	//∑˛ŒÒ∂À◊ ‘¥±£ª§”Ú,µ±«∞∂‘”⁄Õ¯πÿ≤…”√”Ú@Õ¯πÿsnƒ£ Ω,±»»ÁªÒ»°…Ë±∏¡–±ÌŒ™config@12345678,∆‰÷–configŒ™≤È—Ø…Ë±∏¡–±ÌÀ˘ Ù±£ª§”Ú,12345678Œ™…Ë±∏sn
    std::string strNonce;	//ÀÊª˙¥Æ
    std::string strUri;		//√¸¡Ó¬∑æ∂
    std::string strResponse;//
    std::vector<NameValue> params;
    
    bool bIsResponse;
};


//Ω‚ŒˆWWW-AuthenticateªÚAuthorization
bool ParseHttpAuthParams(const std::string &strAuth,HttpAuth &auth,bool bIsResponse = false);
////Ω‚ŒˆAuthorization
//bool ParseHttpAuthorizationParams(const std::string &strAuth,HttpAuthorization &auth);

std::string CalcAuthMd5(const std::string &strUsername,const std::string &strPassword,const std::string &strRealm,const std::string &strNonce,const std::string &strMethod,const std::string &strUri);

//…˙≥…ÀÊª˙÷÷◊”  ±º‰+mac+ÀÊª˙ ˝
std::string MakeNonce();

std::string CalcAuthVerifyMd5(const std::string &strPassword,const std::string &strNonce,const std::string &strDeviceSerial);

std::string CalcBasic(const std::string &strUsername,const std::string &strPassword);

int GetRandomInteger();
const char* GenerateRandomString(char *pbuf, int len);

#endif
