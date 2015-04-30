#include "MQInstance.h"
#include "MQGeneral.h"
#ifdef _WIN32
#include   <sstream>
#include <winsock2.h>
#endif

#include "Trace.h"
#include "MsgEncDec.h"
#include "PrimitiveValueNode.h"
#include "PrimitiveMap.h"
//#import <CoreFoundation/CoreFoundation.h>
//#import <Foundation/Foundation.h>

const std::string CMQInstance::DEVICE_STATE_CHANE        = "zw.public.all.devicestatus";

////////////////±®æØ//////////////////
///old
const std::string CMQInstance::DEVICE_ALARM              = "zw.public.all.alarm";

///new
///VTMC
const std::string CMQInstance::DEVICE_ALARM_VTMC_TOPIC   = "zw.public.all.alarm.vt";
const std::string CMQInstance::DEVICE_ALARM_VTMC         = "zw.public.all.alarm.vt?consumer.selector=JMSType IN ('33620224') "; //0X02010100
///DSMC
const std::string CMQInstance::DEVICE_ALARM_DSMC         = "zw.public.all.alarm.ds?consumer.selector=JMSType IN ('33685760') "; //0X02020100
///ACMC
const std::string CMQInstance::DEVICE_ALARM_ACMC         = "zw.public.all.alarm.ac?consumer.selector=JMSType IN ('33751296') "; //0X02030100
///UCMC
const std::string CMQInstance::DEVICE_ALARM_UCMC         = "zw.public.all.alarm.uc?consumer.selector=JMSType IN ('33816832') "; //0X02040100
///ICMC
const std::string CMQInstance::DEVICE_ALARM_ICMC         = "zw.public.single.alarm.vtc±‡∫≈"; //0X02050100
////////////////±®æØ//////////////////

//////////////±®æØ∂Ã–≈œ¢////////////////////////
//÷˜Ã‚ 
const std::string CMQInstance::DEVICE_ALARM_SMS_TOPIC_SP = "zw.public.all.sms";
//∂©‘ƒ
const std::string CMQInstance::DEVICE_ALARM_SMS_SP       = "zw.public.all.sms?consumer.selector=JMSType IN ('117506304') "; //0X07010100
//////////////±®æØ∂Ã–≈œ¢////////////////////////

const std::string CMQInstance::DATABASE_CHANGE           = "zw.public.all.db";
//const std::string CMQInstance::DATABASE_DEVICE_DELETE    = "zw.public.all.db?consumer.selector = JMSTYPE = '4.1.1' ";
//–ﬁ∏ƒ£∫VTSΩ” ’…Ë±∏…æ≥˝œ˚œ¢–ﬁ∏ƒŒ™Ω” ’À˘”–…Ë±∏œ˚œ¢
const std::string CMQInstance::DATABASE_DEVICE_DELETE    = "zw.public.all.db?consumer.selector=JMSType IN ('67178496') ";
const std::string CMQInstance::DATABASE_DEVICE_CHANGE    = "zw.public.all.db?consumer.selector=JMSType IN ('67178496','67182592','67186688') ";
const std::string CMQInstance::VEHICLE_PASS_INFO         = "zw.public.all.plate";            //≥µ¡æÕ®π˝Õ®÷™
const std::string CMQInstance::EEC_NOTICE_INFO           = "zw.public.all.visitor";            //≥ˆ»Îø⁄π‹¿Ì…Ë±∏œ˚œ¢Õ®÷™

//VTMC∂©‘ƒœ˚œ¢ 
const std::string CMQInstance::VTMC_JMS_FILTER           = "?consumer.selector=JMSType IN ('16777216',"
                                                           "'33620224','33751296','67178496','67182592',"
														   "'67186688','67244032','67248128','67252224',"
														   "'67309568','67313664','67317760','83951872')";

const std::string CMQInstance::VTHPROXY_TOPIC_SUB        = "zw.public.vthproxy.receive";//VTH¥˙¿Ì∂©‘ƒ÷˜Ã‚
const std::string CMQInstance::VTHPROXY_TOPIC_PUB        = "zw.public.vthproxy.send";//VTH¥˙¿Ì∑¢≤º÷˜Ã‚

const std::string CMQInstance::CALLGROUP_TOPIC_PUB       = "zw.public.single.vts.receive";//∫ÙΩ–∑÷◊È∑¢≤º÷˜Ã‚

const std::string CMQInstance::ACMS_ALARM_TOPIC_PUB      = "zw.public.all.alarm.ac";     //ACMS∆ΩÃ®±®æØ∑¢≤º÷˜Ã‚

#ifdef CONSUME_TOPIC_AUTO_TEST
const std::string CMQInstance::ACTIVE_MQ_TEST_TOPIC      = "zw.mq.test.topic";          //ActiveMQ≤‚ ‘∂©‘ƒ◊¥Ã¨÷˜Ã‚
#endif

typedef enum EmMessageType_t
{
	emMSGDeviceState        = 0X01000000,   //…Ë±∏◊¥Ã¨±‰ªØ
	emMSGAlarm              = 0X02000000,   //…Ë±∏±®æØ
	emMSGAlarmVTMC          = 0X02010100,   //VTMC…Ë±∏∂©‘ƒµƒ±®æØ±®æØ
	emMSGAlarmDSMC          = 0X02020100,   //DSMC…Ë±∏∂©‘ƒµƒ±®æØ±®æØ
	////////////ACMS∆ΩÃ®œ˚œ¢//////////////////
	emMSGAlarmACMC          = 0X02030100,   //ACMC…Ë±∏∂©‘ƒµƒ±®æØ±®æØ
	////////////ACMS∆ΩÃ®œ˚œ¢//////////////////
	emMSGAlarmUCMC          = 0X02040100,   //UCMC…Ë±∏∂©‘ƒµƒ±®æØ±®æØ
	emMSGAlarmICMC          = 0X02050100,   //ICMC…Ë±∏∂©‘ƒµƒ±®æØ±®æØ
	emMSGDatabaseModify     = 0X04000000,   // ˝æ›ø‚±‰ªØ
	emMSGDbDeviceModify     = 0x04010000,   //…Ë±∏±‰ªØ
	emMSGDbDevDelete        = 0x04011000,   //…Ë±∏…æ≥˝
	emMSGDbDevAdd           = 0x04012000,   //…Ë±∏ÃÌº”
	emMSGDbDevUpdate        = 0x04013000,   //…Ë±∏–ﬁ∏ƒ

	emMSGChannelModify      = 0x04020000,   //Õ®µ¿±‰ªØ
	emMSGChannelDelete      = 0x04021000,   //Õ®µ¿…æ≥˝
	emMSGChannelAdd         = 0x04022000,   //Õ®µ¿ÃÌº”
	emMSGChannelUpdate      = 0x04023000,   //Õ®µ¿–ﬁ∏ƒ
	emMSGChannelAppModify   = 0x04030000,   //Õ®µ¿”¶”√±‰ªØ
	emMSGChannelAppDelete   = 0x04031000,   //Õ®µ¿”¶”√…æ≥˝
	emMSGChannelAppAdd      = 0x04032000,   //Õ®µ¿”¶”√ÃÌº”
	emMSGChannelAppUpdate   = 0x04033000,   //Õ®µ¿”¶”√–ﬁ∏ƒ

	emMSGVehPassInfo        = 0x05010100,   //≥µ¡æ≥ˆ»ÎÕ®÷™
	emMSGEecNoticeInfo      = 0x05010200,   //≥ˆ»Îø⁄π‹¿Ì…Ë±∏œ˚œ¢Õ®÷™
	
	emMSGAlarmSMS           = 0x07010100,   //±®æØ∂Ã–≈œ˚œ¢
	emMSGAlarmSMSReply      = 0x07010200,   //∂Ã–≈∑¢ÀÕ∑¥¿°œ˚œ¢

	////////////VTHProxy//////////////////
	emMsgVTHProxyCallRedirectReq     = 0x09010100,  //∫ÙΩ–◊™“∆«Î«Ûœ˚œ¢ 
	emMsgVTHProxyUnlockReq           = 0x09020100,  //ø™À¯√¸¡Óœ˚œ¢ 
	emMsgVTHProxyUnlockPicReq        = 0x09030100,  //ø™À¯Õº∆¨«Î«Ûœ˚œ¢ 
	emMsgVTHProxyCallReDirectResult  = 0x09040100,  //∫ÙΩ–◊™“∆Ω·π˚∑¥¿°œ˚œ¢
	////////////VTHProxy//////////////////

	////////////∫ÙΩ–∑÷◊È//////////////////
	emMsgCallgroupAreaDel            = 0x04050100,  //∫ÙΩ–∑÷◊È«¯”Úπÿœµ…æ≥˝œ˚œ¢ 
	emMsgCallgroupAreaAdd            = 0x04050200,  //∫ÙΩ–∑÷◊È«¯”ÚπÿœµÃÌº”œ˚œ¢ 
	emMsgCallgroupDeviceBindDel      = 0x04040100,  //∫ÙΩ–∑÷◊È…Ë±∏∞Û∂®…æ≥˝œ˚œ¢ 
	emMsgCallgroupDeviceBindAdd      = 0x04040200,  //∫ÙΩ–∑÷◊È…Ë±∏∞Û∂®ÃÌº”œ˚œ¢
	////////////∫ÙΩ–∑÷◊È//////////////////

	//////////////ACMS∆ΩÃ®œ˚œ¢//////////////////
	//emMsgACMSAlarmNotify             =  0X02030100  //ACMS∆ΩÃ®±®æØÕ®÷™
	//////////////ACMS∆ΩÃ®œ˚œ¢//////////////////
}EmMessageType;

unsigned int CMQInstance::s_uiSequence = 0;

long long currentTimeMillis()
{

#ifdef _WIN32

    /* Number of micro-seconds between the beginning of the Windows epoch
     * (Jan. 1, 1601) and the Unix epoch (Jan. 1, 1970)
     */
    static const unsigned long long DELTA_EPOCH_IN_USEC = 116444736000000000ULL;

    unsigned long long time = 0;
    ::GetSystemTimeAsFileTime( (FILETIME*)&time );
    return ( time - DELTA_EPOCH_IN_USEC ) / 10000;

#else

    struct timeval tv;
    gettimeofday( &tv, NULL );
    return ( ( (long long)tv.tv_sec * 1000000 ) + tv.tv_usec ) / 1000;

#endif
}

#ifdef WIN32

BOOL Utf8ToAnsi(LPCSTR lpcszStr, char* lpwszStr, DWORD dwSize)
{
    DWORD dwMinSize;
    WCHAR* strTmp;
    dwMinSize = MultiByteToWideChar(CP_UTF8,0,lpcszStr,-1,NULL,0);
    strTmp = new WCHAR[dwMinSize];
    if( dwSize < dwMinSize )
    {
        return FALSE;
    }
    MultiByteToWideChar(CP_UTF8,0,lpcszStr,-1,strTmp,dwMinSize);

    int targetLen = WideCharToMultiByte(CP_ACP,0,(LPWSTR)strTmp,-1,0,0,NULL,NULL);
    WideCharToMultiByte(CP_ACP,0,(LPWSTR)strTmp,-1,(char*)lpwszStr,targetLen,NULL,NULL); 
    return TRUE;
}

BOOL Utf8ToAnsi(std::string src,char* dst, DWORD dwSize)
{
	int iWSize;
	int iRet;
	iWSize = MultiByteToWideChar(CP_UTF8,0,src.c_str(),-1,NULL,0);

	std::wstring tmp(iWSize ,'\0');  
    iRet = MultiByteToWideChar(CP_UTF8,0,src.c_str(),-1,&tmp[0],iWSize);
	if ( 0 == iRet || ERROR_NO_UNICODE_TRANSLATION == iRet )
	{
		return FALSE;
	}
	int iASize = WideCharToMultiByte(CP_ACP,0,tmp.c_str(),-1,0,0,NULL,NULL);
	if ( dwSize <= iASize ) // ‰≥ˆª∫≥ÂÃ´–°
	{
		return FALSE;
	}
    iRet = WideCharToMultiByte(CP_ACP,0,tmp.c_str(),-1,(char*)dst,iASize,NULL,NULL);
	if ( 0 == iRet )
	{
		return FALSE;
	}
    return TRUE;
}

std::string Utf8ToAnsi(const char *src)
{
	int iASize;
	int iRet;
	iASize = MultiByteToWideChar(CP_UTF8,0,src,-1,NULL,0);
	std::wstring tmp(iASize,'\0');
	iRet = MultiByteToWideChar(CP_UTF8,0,src,-1,&tmp[0],iASize);
	if ( 0 == iRet )
	{
		return "\0";
	}

	int restLen = WideCharToMultiByte(CP_ACP,0,tmp.c_str(),-1,0,0,NULL,NULL); 
	std::string result(restLen,'\0');
	iRet = WideCharToMultiByte(CP_ACP,0,tmp.c_str(),-1,&result[0],restLen,NULL,NULL); 
	return result;
}

std::string AnsiToUtf8(const char *src)
{
	int iASize;
	int iRet;
	iASize = MultiByteToWideChar(CP_ACP,0,src,strlen(src),NULL,0);
	std::wstring tmp(iASize,'\0');
	iRet = MultiByteToWideChar(CP_ACP,0,src,strlen(src),&tmp[0],iASize);
	if ( 0 == iRet )
	{
		return "\0";
	}

	int restLen = WideCharToMultiByte(CP_UTF8,0,tmp.c_str(),wcslen(tmp.c_str()),0,0,NULL,NULL); 
	std::string result(restLen,'\0');
	iRet = WideCharToMultiByte(CP_UTF8,0,tmp.c_str(),wcslen(tmp.c_str()),&result[0],restLen,NULL,NULL); 
	return result;
}
#endif

CMQInstance::CMQInstance(void):m_strBrokerURI(),m_strUsername(),m_strPassword(),m_strClientId(),m_strDestURI()
{
    m_bUseTopic = true; //ƒ¨»œ π”√÷˜Ã‚
    m_bClientAck = true; //ƒ¨»œ◊‘∂Ø»∑»œ

	m_iStatus = emIdle;
	m_fcbStack = NULL;
	m_pUser = NULL;
	m_hInstId = MQ_INVALID_HANDLE;

	m_fcbStackEx = NULL;            //ªÿµ˜
	m_pUserEx = NULL;                    //”√ªß◊‘∂®“Â ˝æ›
	m_bIsCompatibleOld = true;

	m_uiCommandId = 1;
	m_uiFailTime = 0;

}
CMQInstance::CMQInstance(char *pszURI):m_strBrokerURI(pszURI),m_strUsername(),m_strPassword(),m_strClientId(),m_strDestURI()
{
    m_bUseTopic = true; //ƒ¨»œ π”√÷˜Ã‚
    m_bClientAck = true; //ƒ¨»œ◊‘∂Ø»∑»œ

	m_iStatus = emIdle;
	m_fcbStack = NULL;
	m_pUser = NULL;
	m_hInstId = MQ_INVALID_HANDLE;
	m_uiCommandId = 1;
	m_uiFailTime = 0;
}
CMQInstance::CMQInstance(char *pszURI,char *pszUsername,char *pszPassword,char *pszClientId)
:m_strBrokerURI(pszURI),m_strUsername(pszUsername),m_strPassword(pszPassword),m_strClientId(pszClientId)
{
    m_bUseTopic = true; //ƒ¨»œ π”√÷˜Ã‚
    m_bClientAck = true; //ƒ¨»œ◊‘∂Ø»∑»œ

	m_iStatus = emIdle;
	m_fcbStack = NULL;
	m_pUser = NULL;
	m_hInstId = MQ_INVALID_HANDLE;

}

CMQInstance::~CMQInstance(void)
{
	this->Cleanup();
}

//«Â≥˝¡¨Ω”∫Õ◊ ‘¥
int CMQInstance::Cleanup(void)
{
	if ( VT_INVALID_SOCKET != m_sock )
	{

		//Õ£÷ππ§◊˜œﬂ≥Ã
		m_bExitNetThr = true;
#ifdef WIN32
		if ( m_hNetThread == GetCurrentThread() ) //µ±«∞œﬂ≥Ã÷–÷¥––Ω· ¯
		{
		}
		else //∆‰À˚œﬂ≥Ã÷–
		{
			DWORD dwRet = WaitForSingleObject(m_hNetThread,5000);
			if ( dwRet == WAIT_TIMEOUT )
			{
				ERROR_TRACE("force terminate net thread.");
				TerminateThread(m_hNetThread,0);
			}
			if ( 0 != ShuntdwonNornal() )
			{
				shutdown(m_sock,VT_SD_BOTH);
				//∂œø™¡¨Ω”
				VT_CLOSE_SOCKET(m_sock);
			}
		}
#else
		if ( m_hNetThread == pthread_self() ) //µ±«∞œﬂ≥Ã÷–÷¥––Ω· ¯
		{
			//detach œﬂ≥Ã
			pthread_detach(m_hNetThread);
		}
		else //∆‰À˚œﬂ≥Ã÷–
		{
			void *result;
			pthread_join(m_hNetThread,&result);
			if ( 0 != ShuntdwonNornal() )
			{
				shutdown(m_sock,VT_SD_BOTH);
				//∂œø™¡¨Ω”
				VT_CLOSE_SOCKET(m_sock);
			}
		}
#endif

		//ShuntdwonNornal();
	}

	//«Â≥˝∑¢ÀÕª∫≥Â
	ClearSend();

	return MQ_NO_ERROR;
}

//∏˘æ›÷’∂À¿‡–Õ
int CMQInstance::CreateConsumeTopic(void)
{
	m_strDestURI = "";
	switch ( m_iDeviceType ) 
	{
	case MQ_DEVICE_VTS: //VTS
		//–ﬁ∏ƒ£∫VTSΩ” ’…Ë±∏…æ≥˝œ˚œ¢–ﬁ∏ƒŒ™Ω” ’À˘”–…Ë±∏œ˚œ¢
		m_strDestURI += DATABASE_CHANGE; // ˝æ›ø‚±‰ªØœ˚œ¢
		m_strDestURI += ",";
		m_strDestURI += CALLGROUP_TOPIC_PUB; //∫ÙΩ–∑÷◊Èœ˚œ¢
		m_strDestURI += ",";
		m_strDestURI += VTHPROXY_TOPIC_SUB; // ÷ª˙∫ÙΩ–◊™“∆œ˚œ¢
		break;
	case MQ_DEVICE_VTMC: //VTMC
		m_strDestURI += DEVICE_STATE_CHANE; //…Ë±∏◊¥Ã¨±‰ªØ÷˜Ã‚
		m_strDestURI += ",";
		m_strDestURI += DATABASE_CHANGE;   // ˝æ›ø‚±‡∫≈÷˜Ã‚
		m_strDestURI += ",";
		m_strDestURI += VEHICLE_PASS_INFO;  //≥µ¡æÕ®π˝–≈œ¢÷˜Ã‚
		m_strDestURI += ",";
		m_strDestURI += DEVICE_ALARM_VTMC_TOPIC; //VTMC±®æØ÷˜Ã‚
		m_strDestURI += ",";
		m_strDestURI += ACMS_ALARM_TOPIC_PUB; //ACMS±®æØ÷˜Ã‚
		//m_strDestURI += VTMC_JMS_FILTER; //π˝¬À∆˜
		break;
	case MQ_DEVICE_WSC: //WSC
		return MQ_ERROR_UNKNOWN_ENDPOINT;
	case MQ_DEVICE_EEC: //≥ˆ»Îø⁄π‹¿Ì…Ë±∏
		m_strDestURI += EEC_NOTICE_INFO;  //∂©‘ƒ≥µ¡æÕ®π˝–≈œ¢
		break;
	case MQ_DEVICE_SP: //±®æØ∂Ã–≈∆ΩÃ®
		m_strDestURI += DEVICE_ALARM_SMS_SP;  //±®æØ∂Ã–≈∆ΩÃ®
		break;
	case MQ_DEVICE_VTHPROXY: //VTH¥˙¿Ì
		m_strDestURI += VTHPROXY_TOPIC_SUB;
		break;
	case MQ_DEVICE_ACMS: //ACMS∆ΩÃ®,‘› ±≤ª–Ë“™∂©‘ƒ
		m_strDestURI = "";
		break;
	case MQ_DEVICE_PROXY_PRIV: //ÀΩÕ¯
		m_strDestURI += VTHPROXY_TOPIC_PUB; //VT∫ÙΩ–◊™“∆œ˚œ¢
		m_strDestURI += ",";
		m_strDestURI += DEVICE_ALARM_VTMC_TOPIC; //VT±®æØœ˚œ¢
		m_strDestURI += ",";
		m_strDestURI += ACMS_ALARM_TOPIC_PUB; //ACMS±®æØœ˚œ¢
		break;
	case MQ_DEVICE_PROXY_PUB: //π´Õ¯
		m_strDestURI = VTHPROXY_TOPIC_SUB; // ÷ª˙∫ÙΩ–◊™“∆œ˚œ¢
		break;
	//default:
	//	ERROR_TRACE("unknown endpoint=.");
	//	return MQ_ERROR_UNKNOWN_ENDPOINT;
	}
	return MQ_NO_ERROR;
}

void CMQInstance::BrokerUri(std::string strUri)
{
	m_strBrokerURI = strUri;
}

std::string CMQInstance::BrokerUri(void)
{
	return m_strBrokerURI;
}
void CMQInstance::InstHandle(MQ_HANDLE hInst)
{
	m_hInstId = hInst;
}


///////////////////////////Ω”ø⁄//////////////////////////////
//…Ë÷√µ±«∞÷’∂À≤Œ ˝
int CMQInstance::SetEndpoint(MQ_ENDPOINT &stEpInfo)
{
	m_strUsername = stEpInfo.szUserName;
	m_strPassword = stEpInfo.szPassword;
	m_strClientId = stEpInfo.szClientId;
	m_iDeviceType = stEpInfo.iEndpointType;
	m_fcbStack = stEpInfo.cbStack;
	m_pUser = stEpInfo.pUser;
	return MQ_NO_ERROR;
}
int CMQInstance::SetTopic(char **pTopic,int iTopicCount)
{
	m_strDestURI = "";
	bool bFirst = true;
	for(int i=0;i<iTopicCount;i++)
	{
		if ( bFirst )
		{
			bFirst = false;
		}
		else
		{
			m_strDestURI += ",";
		}
		m_strDestURI += pTopic[i]; // ˝æ›ø‚±‰ªØœ˚œ¢
	}
	INFO_TRACE("topic info "<<m_strDestURI<<".");

	return MQ_NO_ERROR;
}

int CMQInstance::SetExtraInfo(MQ_EXRAINFO &stExtInfo)
{
	int iRet;
	m_fcbStackEx = stExtInfo.cbStack;
	m_pUserEx = stExtInfo.pUser;
	if ( stExtInfo.iIsCompatibleOld == 1 )
	{
		m_bIsCompatibleOld = true;
	}
	else
	{
		m_bIsCompatibleOld = false;
	}
	m_strDestURI = "";
	if ( m_bIsCompatibleOld )
	{
		if ( MQ_NO_ERROR != (iRet=CreateConsumeTopic()) )
		{
			ERROR_TRACE("create consumer failed.Handle="<<m_hInstId<<".");
			return iRet;
		}
	}
	else
	{
	}
	
	bool bFirst = true;
	if ( m_strDestURI.empty() )
	{
		bFirst = true;
	}
	else
	{
		bFirst = false;
	}
	for(int i=0;i<stExtInfo.iTopicCount;i++)
	{
		if ( bFirst )
		{
			bFirst = false;
		}
		else
		{
			m_strDestURI += ",";
		}
		m_strDestURI += stExtInfo.pTopicList[i];
		//m_strDestURI += AnsiToUtf8(stExtInfo.pTopicList[i]);
	}
	INFO_TRACE("topic info "<<m_strDestURI<<".");

	return MQ_NO_ERROR;
}


//∆Ù∂Ø
int CMQInstance::Start(void)
{
	int iRet = MQ_NO_ERROR;

	std::string szBroker;
	szBroker = m_strBrokerURI;

	// Create the destination (Topic or Queue)
	if ( m_bIsCompatibleOld && m_strDestURI.empty() )
	{
		iRet = CreateConsumeTopic();
		if ( MQ_NO_ERROR != iRet )
		{
			ERROR_TRACE("create consumer failed.Handle="<<m_hInstId<<".");
			return iRet;
		}
	}
	//m_iStatus = emStarted;

	if ( m_strDestURI.empty() )
	{
		WARN_TRACE("no any consume topic.");
	}

#ifdef CONSUME_TOPIC_AUTO_TEST
	INFO_TRACE("use topic auto test.");
	if ( m_strDestURI.empty() )
	{
		m_strDestURI += ACTIVE_MQ_TEST_TOPIC;
	}
	else
	{
		m_strDestURI += ",";
		m_strDestURI += ACTIVE_MQ_TEST_TOPIC;
	}
#endif

	//Ω‚Œˆbroker url
	size_t pos = m_strBrokerURI.find_last_of(':');
	if ( std::string::npos == pos || pos < 6 ) //broker–≈œ¢≤ª∂‘ tcp://10.30.4.89:57676"
	{
		ERROR_TRACE("broker url parse failed,please check broker url is valid.");
		iRet = MQ_ERROR_BAD_PARAMETER;
		return iRet;
	}
	m_strIp = m_strBrokerURI.substr(6,pos-6);
	std::string strTemp = m_strBrokerURI.substr(pos+1,m_strBrokerURI.size()-pos-1);
	m_usPort = (unsigned short)atoi(strTemp.c_str());

	INFO_TRACE("mq topic "<<m_strDestURI<<" broker uri "<<m_strBrokerURI);

	//¡¨Ω”÷–º‰º˛∑˛ŒÒ∆˜
	if ( MQ_NO_ERROR != Connect_Sync() ) //¡¨Ω” ß∞‹
	{
		ERROR_TRACE("connect failed.");
		VT_CLOSE_SOCKET(m_sock);
		return -1;
	}

	//…˙≥…ID
	sockaddr_in addr;
	int addLen = sizeof(addr);
#ifdef WIN32
	::getsockname(m_sock,(sockaddr*)&addr,&addLen);
#else
	::getsockname(m_sock,(sockaddr*)&addr,(socklen_t*)&addLen);
#endif
	char localIp[32] = {0};
	strcpy(localIp,inet_ntoa(addr.sin_addr));
	unsigned short usPort = ntohs(addr.sin_port);
	//if ( '\0' == m_szCtrlLocalIpAddr[0] || 0 != strcmp(m_szCtrlLocalIpAddr,localIp) )
	//{
	//	strcpy_s(m_szCtrlLocalIpAddr,31,localIp);
	//}
	long long curTime = currentTimeMillis();

	char szId[128];
#ifdef WIN32
	sprintf(szId,"ID:%s-%d-%I64d-0:%d",localIp,usPort,curTime,s_uiSequence);
#else
	sprintf(szId,"ID:%s-%d-%lld-0:%d",localIp,usPort,curTime,s_uiSequence);
#endif

	m_strConnectionId = szId;
#ifdef WIN32
	sprintf(szId,"ID:%s-%d-%I64d-1:%d",localIp,usPort,curTime,s_uiSequence);
#else
	sprintf(szId,"ID:%s-%d-%lld-1:%d",localIp,usPort,curTime,s_uiSequence);
#endif
	m_strClientId = szId;
	s_uiSequence++;

	//∑¢ÀÕ–≈¡Ó
	char buf[1024];
	int iDataLen =1024;
	EncodeWaveFormatInfo(buf,iDataLen);
	int iSendBytes = send(m_sock,buf,iDataLen,0);
	if ( iSendBytes != iDataLen )
	{
		//∑¢ÀÕ ß∞‹
		ERROR_TRACE("send waveinfo_format failed.");
		VT_CLOSE_SOCKET(m_sock);
		return -1;
	}

	//Ω” ’∂‘∑ΩµƒWAVEFORMAT_INFO
	iDataLen = RecvData(buf,1024,5000);
	if ( iDataLen <= 0 )
	{
		//Ω” ’ ß∞‹
		ERROR_TRACE("recv failed.");
		VT_CLOSE_SOCKET(m_sock);
		return -1;
	}

	//Ω” ’BROKER_INFO
	iDataLen = RecvData(buf,1024,5000);
	if ( iDataLen <= 0 )
	{
		//Ω” ’ ß∞‹
		ERROR_TRACE("recv failed.");
		VT_CLOSE_SOCKET(m_sock);
		return -1;
	}

	//∑¢ÀÕCONNECTION_INFO
	iDataLen = 1024;
	EncodeConnectionInfo(buf,iDataLen);
	iSendBytes = send(m_sock,buf,iDataLen,0);
	if ( iSendBytes != iDataLen )
	{
		//∑¢ÀÕ ß∞‹
		ERROR_TRACE("send CONNECTION_INFO failed.");
		VT_CLOSE_SOCKET(m_sock);
		return -1;
	}

	//Ω” ’RESPONSE
	iDataLen = RecvData(buf,1024,5000);
	if ( iDataLen <= 0 )
	{
		//Ω” ’ ß∞‹
		ERROR_TRACE("recv rsp failed.");
		VT_CLOSE_SOCKET(m_sock);
		return -1;
	}
	
	//Ω‚ŒˆRESPONSE
	unsigned int uiCommandId;
	if ( 0 != DecodeResponse(buf,iDataLen,uiCommandId) )
	{
		// ß∞‹
	}

	//∑¢ÀÕSESSION_INFO
	iDataLen = 1024;
	EncodeSessionInfo(buf,iDataLen);
	iSendBytes = send(m_sock,buf,iDataLen,0);
	if ( iSendBytes != iDataLen )
	{
		//∑¢ÀÕ ß∞‹
		ERROR_TRACE("send SESSION_INFO failed.");
		VT_CLOSE_SOCKET(m_sock);
		return -1;
	}

	//∑¢ÀÕCONSUMER_INFO
	iDataLen = 1024;
	EncodeConsumerInfo(buf,iDataLen);
	iSendBytes = send(m_sock,buf,iDataLen,0);
	if ( iSendBytes != iDataLen )
	{
		//∑¢ÀÕ ß∞‹
		ERROR_TRACE("send CONSUMER_INFO failed.");
		VT_CLOSE_SOCKET(m_sock);
		return -1;
	}

	//Ω” ’RESPONSE
	iDataLen = RecvData(buf,1024,5000);
	if ( iDataLen <= 0 )
	{
		//Ω” ’ ß∞‹
		ERROR_TRACE("recv rsp failed.");
		VT_CLOSE_SOCKET(m_sock);
		return -1;
	}
	
	//Ω‚ŒˆRESPONSE
	uiCommandId;
	if ( 0 != DecodeResponse(buf,iDataLen,uiCommandId) )
	{
		// ß∞‹
	}

	//∑¢ÀÕPRODUCER_INFO
	iDataLen = 1024;
	EncodeProducerInfo(buf,iDataLen);
	iSendBytes = send(m_sock,buf,iDataLen,0);
	if ( iSendBytes != iDataLen )
	{
		//∑¢ÀÕ ß∞‹
		ERROR_TRACE("send PRODUCER_INFO failed.");
		VT_CLOSE_SOCKET(m_sock);
		return -1;
	}

	m_uiFailTime = 0;

	m_iStatus = emStarted;

	//¥¥Ω®º‡Ã˝œﬂ≥Ã
	if ( !CreateProcThread() )
	{
		//¥¥Ω®œﬂ≥Ã ß∞‹
		ERROR_TRACE("create thread failed.");
		VT_CLOSE_SOCKET(m_sock);
		return -1;
	}

	//∂œø™
	//∑¢ÀÕREMOVE_INFO

	//∑¢ÀÕSHUTDOWN_INFO

	DEBUG_TRACE("Instance Start OK.Handle="<<m_hInstId<<".");
	return MQ_NO_ERROR;
}

//Õ£÷π
int CMQInstance::Stop(void)
{
	return this->Cleanup();
}

//∑¢ÀÕ…Ë±∏◊¥Ã¨±‰ªØÕ®÷™œ˚œ¢
int CMQInstance::DeviceStateNotify(MQ_DEVICE_STATE stDevState,int iDeliveryMode )
{
	//œ˚œ¢ÃÂª∫≥Â
	char msg[512];
	int iMsg = 512;

	//œ˚œ¢ÃÂ Ù–‘ª∫≥Â
	char buf[1024];
	int iLen = 1024;

	INFO_TRACE("Enter.");
	if ( emStarted != m_iStatus )
	{
		ERROR_TRACE("invalid status.");
		return MQ_ERROR_UNKNOWN;
	}
	//¥Ú∞¸œ˚œ¢ÃÂ

	int iTotalLen = 0;
	CByteEncDec enc(msg,iMsg);
	
	//enc<<iTotalLen; //◊‹≥§∂»
	enc<<(unsigned int)4; //item count int 4

	//item 1 lDeviceId
	enc<<"lDeviceId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<stDevState.llDeviceId; //item value

	//item 2 iDevType
	enc<<"iDevType"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<stDevState.iDeviceType; //item value

	//item 3 iStatus
	enc<<"iStatus"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<stDevState.iStatus; //item value

	//item 4 iTime
	enc<<"iTime"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<stDevState.iTime; //item value

	iMsg = (int)enc.GetWriteLength();
	
	EncodeMapMsg(buf,iLen,msg,iMsg,(char*)(CMQInstance::DEVICE_STATE_CHANE).c_str(),(char*)ToString(emMSGDeviceState).c_str()/*"16777216"*/);

	//∑¢ÀÕ ˝æ›
	//int iSendBytes = send(m_sock,buf,iLen,0);
	//if ( iSendBytes != iLen )
	int iSendBytes = SendData(buf,iLen);
	if ( iSendBytes < 0 )
	{
		//∑¢ÀÕ ß∞‹
		ERROR_TRACE("send failed.");
		return MQ_ERROR_UNKNOWN;
	}

	INFO_TRACE("send ok.");

	return MQ_NO_ERROR;
}
//∑¢ÀÕ±®æØÕ®÷™œ˚œ¢ VTS
int CMQInstance::AlarmNotify(MQ_ALARM_INFO stAlarmInfo,int iDeliveryMode)
{		
	//œ˚œ¢ÃÂª∫≥Â
	char msg[512];
	int iMsg = 512;

	//œ˚œ¢ÃÂ Ù–‘ª∫≥Â
	char buf[1024];
	int iLen = 1024;

	if ( emStarted != m_iStatus )
	{
		return MQ_ERROR_UNKNOWN;
	}
	//¥Ú∞¸œ˚œ¢ÃÂ

	int iTotalLen = 0;
	CByteEncDec enc(msg,iMsg);
	
	//enc<<iTotalLen; //◊‹≥§∂»
	enc<<(unsigned int)5; //item count int 5

	//item 1 lDeviceId
	enc<<"lDeviceId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<stAlarmInfo.llDeviceId; //item value

	//item 2 iDevType
	enc<<"iDevType"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<stAlarmInfo.iDeviceType; //item value

	//item 3 iAlarmTime
	enc<<"iAlarmTime"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<stAlarmInfo.iAlarmTime; //item value

	//item 4 iAlarmType
	enc<<"iAlarmType"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<stAlarmInfo.iAlarmType; //item value

	//item 5 iAlarmStatus
	enc<<"iAlarmStatus"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<stAlarmInfo.iAlarmStatus; //item value


	iMsg = (int)enc.GetWriteLength();
	
	EncodeMapMsg(buf,iLen,msg,iMsg,(char*)(CMQInstance::DEVICE_ALARM_VTMC_TOPIC).c_str(),(char*)ToString(emMSGAlarmVTMC).c_str()/*"33620224"*/);

	//∑¢ÀÕ ˝æ›
	//int iSendBytes = send(m_sock,buf,iLen,0);
	//if ( iSendBytes != iLen )
	int iSendBytes = SendData(buf,iLen);
	if ( iSendBytes < 0 )
	{
		//∑¢ÀÕ ß∞‹
		return MQ_ERROR_UNKNOWN;
	}


	return MQ_NO_ERROR;
}
//∑¢ÀÕ…Ë±∏…æ≥˝œ˚œ¢
int CMQInstance::DeviceDelNotify(MQ_DEVICE_DELETE stDeviceDel,int iDeliveryMode )
{
	//œ˚œ¢ÃÂª∫≥Â
	char msg[512];
	int iMsg = 512;

	//œ˚œ¢ÃÂ Ù–‘ª∫≥Â
	char buf[1024];
	int iLen = 1024;

	if ( emStarted != m_iStatus )
	{
		return MQ_ERROR_UNKNOWN;
	}
	//¥Ú∞¸œ˚œ¢ÃÂ

	int iTotalLen = 0;
	CByteEncDec enc(msg,iMsg);
	
	//enc<<iTotalLen; //◊‹≥§∂»
	enc<<(unsigned int)1; //item count int 1

	//item 1 lDeviceId
	enc<<"lDeviceId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<stDeviceDel.llDeviceId; //item value

	iMsg = (int)enc.GetWriteLength();
	
	EncodeMapMsg(buf,iLen,msg,iMsg,(char*)(CMQInstance::DATABASE_CHANGE).c_str(),(char*)ToString(emMSGDbDevDelete).c_str()/*"67178496"*/);

	//∑¢ÀÕ ˝æ›
	//int iSendBytes = send(m_sock,buf,iLen,0);
	//if ( iSendBytes != iLen )
	int iSendBytes = SendData(buf,iLen);
	if ( iSendBytes < 0 )
	{
		//∑¢ÀÕ ß∞‹
		return MQ_ERROR_UNKNOWN;
	}

	return MQ_NO_ERROR;
}
//∑¢ÀÕ…Ë±∏ÃÌº”œ˚œ¢
int CMQInstance::DeviceAddNotify(MQ_DEVICE_ADD stDeviceAdd,int iDeliveryMode )
{
	//œ˚œ¢ÃÂª∫≥Â
	char msg[512];
	int iMsg = 512;

	//œ˚œ¢ÃÂ Ù–‘ª∫≥Â
	char buf[1024];
	int iLen = 1024;

	if ( emStarted != m_iStatus )
	{
		return MQ_ERROR_UNKNOWN;
	}
	//¥Ú∞¸œ˚œ¢ÃÂ

	int iTotalLen = 0;
	CByteEncDec enc(msg,iMsg);
	
	//enc<<iTotalLen; //◊‹≥§∂»
	enc<<(unsigned int)4; //item count int 4

	//item 1 lDeviceId
	enc<<"lDeviceId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<stDeviceAdd.llDeviceId; //item value

	//item 2 lAreaCode
	enc<<"lAreaCode"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<stDeviceAdd.llAreaCode; //item value

	//item 3 sDevName
	enc<<"sDevName"; //item name string
	enc<<(unsigned char)9; //item value type string 9
	enc<<stDeviceAdd.szDeviceName; //item value

	//item 4 iDevVideo
	enc<<"iDevVideo"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<stDeviceAdd.iHasVideo; //item value

	iMsg = (int)enc.GetWriteLength();
	//iTotalLen = iMsg-4;

	//CByteEncDec enc2(msg,iLen);
	//enc2<<iTotalLen; //◊‹≥§∂»
	
	EncodeMapMsg(buf,iLen,msg,iMsg,(char*)(CMQInstance::DATABASE_CHANGE).c_str(),(char*)ToString(emMSGDbDevAdd).c_str()/*"67182592"*/);

	//∑¢ÀÕ ˝æ›
	//int iSendBytes = send(m_sock,buf,iLen,0);
	//if ( iSendBytes != iLen )
	int iSendBytes = SendData(buf,iLen);
	if ( iSendBytes < 0 )
	{
		//∑¢ÀÕ ß∞‹
		return MQ_ERROR_UNKNOWN;
	}


	return MQ_NO_ERROR;
}
//∑¢ÀÕ…Ë±∏∏¸–¬œ˚œ¢
int CMQInstance::DeviceUpdateNotify(MQ_DEVICE_UPDATE stDeviceUpdate,int iDeliveryMode )
{
	//œ˚œ¢ÃÂª∫≥Â
	char msg[512];
	int iMsg = 512;

	//œ˚œ¢ÃÂ Ù–‘ª∫≥Â
	char buf[1024];
	int iLen = 1024;

	if ( emStarted != m_iStatus )
	{
		return MQ_ERROR_UNKNOWN;
	}
	//¥Ú∞¸œ˚œ¢ÃÂ

	int iTotalLen = 0;
	CByteEncDec enc(msg,iMsg);
	
	enc<<(unsigned int)4; //item count int 4

	//item 1 lDeviceId
	enc<<"lDeviceId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<stDeviceUpdate.llDeviceId; //item value

	//item 2 lAreaCode
	enc<<"lAreaCode"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<stDeviceUpdate.llAreaCode; //item value

	//item 3 sDevName
	enc<<"sDevName"; //item name string
	enc<<(unsigned char)9; //item value type string 9
	enc<<stDeviceUpdate.szDeviceName; //item value

	//item 4 iDevVideo
	enc<<"iDevVideo"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<stDeviceUpdate.iHasVideo; //item value

	iMsg = (int)enc.GetWriteLength();
	
	EncodeMapMsg(buf,iLen,msg,iMsg,(char*)(CMQInstance::DATABASE_CHANGE).c_str(),(char*)ToString(emMSGDbDevUpdate).c_str()/*"67182592"*/);

	//∑¢ÀÕ ˝æ›
	//int iSendBytes = send(m_sock,buf,iLen,0);
	//if ( iSendBytes != iLen )
	int iSendBytes = SendData(buf,iLen);
	if ( iSendBytes < 0 )
	{
		//∑¢ÀÕ ß∞‹
		return MQ_ERROR_UNKNOWN;
	}

	return MQ_NO_ERROR;
}

//∑¢ÀÕ≥µ¡æ≥ˆ»Îœ˚œ¢
int CMQInstance::VehiclePassInfoNotify(LPMQ_VEHICLE_PASS_INFO pstVehPassInfo,int iDeliveryMode)
{
	//œ˚œ¢ÃÂª∫≥Â
	char msg[512];
	int iMsg = 512;

	//œ˚œ¢ÃÂ Ù–‘ª∫≥Â
	char buf[1024];
	int iLen = 1024;

	if ( emStarted != m_iStatus )
	{
		return MQ_ERROR_UNKNOWN;
	}
	//¥Ú∞¸œ˚œ¢ÃÂ

	int iTotalLen = 0;
	CByteEncDec enc(msg,iMsg);
	
	enc<<(unsigned int)9; //item count int 9

	//item 1 sDevNo
	enc<<"sDevNo"; //item name string
	enc<<(unsigned char)9; //item value type string 9
	enc<<pstVehPassInfo->szDevNo; //item value

	//item 2 iChannel
	enc<<"iChannel"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstVehPassInfo->iChannel; //item value

	//item 3 iOccurTime
	enc<<"iOccurTime"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstVehPassInfo->iOccurTime; //item value

	//item 4 sPlateNum
	enc<<"sPlateNum"; //item name string
	enc<<(unsigned char)9; //item value type string 9
	enc<<pstVehPassInfo->szPlateNum; //item value

	//item 5 sPicUrl
	enc<<"sPicUrl"; //item name string
	enc<<(unsigned char)9; //item value type string 9
	enc<<pstVehPassInfo->szPicUrl; //item value

	//item 6 sVehPlateLocation
	enc<<"sVehPlateLocation"; //item name string
	enc<<(unsigned char)9; //item value type string 9
	enc<<pstVehPassInfo->sVehPlateLocation; //item value

	//item 7 iPlateColor
	enc<<"iPlateColor"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstVehPassInfo->iPlateColor; //item value

	//item 8 iVehColor
	enc<<"iVehColor"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstVehPassInfo->iVehColor; //item value

	/////////////‘› ±√ª”–float¿‡–Õ
	////item 9 fCharge
	//enc<<"fCharge"; //item name string
	//enc<<(unsigned char)8; //item value type float 8
	//enc<<pstVehPassInfo->fCharge; //item value

	iMsg = (int)enc.GetWriteLength();
	
	EncodeMapMsg(buf,iLen,msg,iMsg,(char*)(CMQInstance::DATABASE_CHANGE).c_str(),(char*)ToString(emMSGVehPassInfo).c_str()/*"83951872"*/);

	//∑¢ÀÕ ˝æ›
	//int iSendBytes = send(m_sock,buf,iLen,0);
	//if ( iSendBytes != iLen )
	int iSendBytes = SendData(buf,iLen);
	if ( iSendBytes < 0 )
	{
		//∑¢ÀÕ ß∞‹
		return MQ_ERROR_UNKNOWN;
	}

	return MQ_NO_ERROR;
}

//∑¢ÀÕ≥ˆ»Îø⁄π‹¿Ì…Ë±∏œ˚œ¢Õ®÷™–≈œ¢
int CMQInstance::EecNoticeInfoNotify(LPMQ_EEC_NOTICE_INFO pstEecNoticeInfo,int iDeliveryMode)
{
	//œ˚œ¢ÃÂª∫≥Â
	char msg[512];
	int iMsg = 512;

	//œ˚œ¢ÃÂ Ù–‘ª∫≥Â
	char buf[1024];
	int iLen = 1024;

	if ( emStarted != m_iStatus )
	{
		return MQ_ERROR_UNKNOWN;
	}
	//¥Ú∞¸œ˚œ¢ÃÂ

	int iTotalLen = 0;
	CByteEncDec enc(msg,iMsg);
	
	enc<<(unsigned int)3; //item count int 3

	//item 1 sPlateNum
	enc<<"sPlateNum"; //item name string
	enc<<(unsigned char)9; //item value type string 9
	enc<<pstEecNoticeInfo->szPlateNum; //item value

	//item 2 sVisitorName
	enc<<"sVisitorName"; //item name string
	enc<<(unsigned char)9; //item value type string 9
	enc<<pstEecNoticeInfo->szVisitorName; //item value

	//item 3 iVisitorTime
	enc<<"iVisitorTime"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstEecNoticeInfo->iVisitorTime; //item value

	iMsg = (int)enc.GetWriteLength();
	
	EncodeMapMsg(buf,iLen,msg,iMsg,(char*)(CMQInstance::EEC_NOTICE_INFO).c_str(),(char*)ToString(emMSGEecNoticeInfo).c_str()/*"83952128"*/);

	//∑¢ÀÕ ˝æ›
	//int iSendBytes = send(m_sock,buf,iLen,0);
	//if ( iSendBytes != iLen )
	int iSendBytes = SendData(buf,iLen);
	if ( iSendBytes < 0 )
	{
		//∑¢ÀÕ ß∞‹
		return MQ_ERROR_UNKNOWN;
	}

	return MQ_NO_ERROR;
}

//∑¢ÀÕ∂Ã–≈∑¢ÀÕ∑¥¿°œ˚œ¢
int CMQInstance::SPAlarmSmsReplyInfoNotify(LPMQ_ALARM_SMS_REPLY_INFO pstSpAlarmSmsReplyNoticeInfo,int iDeliveryMode)
{
	//œ˚œ¢ÃÂª∫≥Â
	char msg[512];
	int iMsg = 512;

	//œ˚œ¢ÃÂ Ù–‘ª∫≥Â
	char buf[1024];
	int iLen = 1024;

	if ( emStarted != m_iStatus )
	{
		return MQ_ERROR_UNKNOWN;
	}
	//¥Ú∞¸œ˚œ¢ÃÂ

	int iTotalLen = 0;
	CByteEncDec enc(msg,iMsg);
	
	enc<<(unsigned int)2; //item count int 2

	//item 1 sPlateNum
	enc<<"iSmsRecord"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstSpAlarmSmsReplyNoticeInfo->iSmsRecord; //item value

	//item 2 iSendStatus
	enc<<"iSendStatus"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstSpAlarmSmsReplyNoticeInfo->iSendStatus; //item value

	iMsg = (int)enc.GetWriteLength();
	
	EncodeMapMsg(buf,iLen,msg,iMsg,(char*)(CMQInstance::DEVICE_ALARM_SMS_TOPIC_SP).c_str(),(char*)ToString(emMSGAlarmSMSReply).c_str()/*"117506560"*/);

	//∑¢ÀÕ ˝æ›
	//int iSendBytes = send(m_sock,buf,iLen,0);
	//if ( iSendBytes != iLen )
	int iSendBytes = SendData(buf,iLen);
	if ( iSendBytes < 0 )
	{
		//∑¢ÀÕ ß∞‹
		return MQ_ERROR_UNKNOWN;
	}

	return MQ_NO_ERROR;
}

//∑¢ÀÕ∫ÙΩ–◊™“∆œ˚œ¢
int CMQInstance::VTHProxy_CallRedirect(LPMQ_VTHPROXY_CALL_REDIRECT_INFO pstCrInfo,int iDeliveryMode)
{
	//œ˚œ¢ÃÂª∫≥Â
	char msg[512];
	int iMsg = 512;

	//œ˚œ¢ÃÂ Ù–‘ª∫≥Â
	char buf[1024];
	int iLen = 1024;

	if ( emStarted != m_iStatus )
	{
		return MQ_ERROR_UNKNOWN;
	}
	//¥Ú∞¸œ˚œ¢ÃÂ

	int iTotalLen = 0;
	CByteEncDec enc(msg,iMsg);
	
	enc<<(unsigned int)6; //item count int 6

	//item 1 lVtoId
	enc<<"lVtoId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<pstCrInfo->llVtoId; //item value

	//item 2 iMidVthId
	enc<<"iMidVthId"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstCrInfo->iMidVthId; //item value

	//item 3 lVirVthId
	enc<<"lVirVthId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<pstCrInfo->llVirVthId; //item value

	//item 4 iInviteTime
	enc<<"iInviteTime"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstCrInfo->iInviteTime; //item value

	//item 5 sUrl1
	enc<<"sUrl1"; //item name string
	enc<<(unsigned char)9; //item value type string 9
#ifdef WIN32
	enc<<AnsiToUtf8(pstCrInfo->szPicUrl).c_str(); //item value
#else
	enc<<pstCrInfo->szPicUrl; //item value
#endif

	//item 6 iStage
	enc<<"iStage"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstCrInfo->iStage; //item value

	iMsg = (int)enc.GetWriteLength();
	
	EncodeMapMsg(buf,iLen,msg,iMsg,(char*)(CMQInstance::VTHPROXY_TOPIC_PUB).c_str(),(char*)ToString(emMsgVTHProxyCallRedirectReq).c_str()/*"151060736"*/);

	//∑¢ÀÕ ˝æ›
	//int iSendBytes = send(m_sock,buf,iLen,0);
	//if ( iSendBytes != iLen )
	int iSendBytes = SendData(buf,iLen);
	if ( iSendBytes < 0 )
	{
		//∑¢ÀÕ ß∞‹
		return MQ_ERROR_UNKNOWN;
	}

	return MQ_NO_ERROR;
}

//∑¢ÀÕø™À¯Õº∆¨œ˚œ¢
int CMQInstance::VTHProxy_UnlockPic(LPMQ_VTHPROXY_UNLOCK_PIC_INFO pstPicInfo,int iDeliveryMode)
{
	//œ˚œ¢ÃÂª∫≥Â
	char msg[512];
	int iMsg = 512;

	//œ˚œ¢ÃÂ Ù–‘ª∫≥Â
	char buf[1024];
	int iLen = 1024;

	if ( emStarted != m_iStatus )
	{
		return MQ_ERROR_UNKNOWN;
	}
	//¥Ú∞¸œ˚œ¢ÃÂ

	int iTotalLen = 0;
	CByteEncDec enc(msg,iMsg);
	
	enc<<(unsigned int)9; //item count int 9

	//item 1 lVtoId
	enc<<"lVtoId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<pstPicInfo->llVtoId; //item value

	//item 2 iMidVthId
	enc<<"iMidVthId"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstPicInfo->iMidVthId; //item value

	//item 3 lVirVthId
	enc<<"lVirVthId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<pstPicInfo->llVirVthId; //item value

	//item 4 iInviteTime
	enc<<"iInviteTime"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstPicInfo->iInviteTime; //item value

	//item 5 lAccountId
	enc<<"lAccountId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<pstPicInfo->llAccountId; //item value

	//item 6 sAccountName
	enc<<"sAccountName"; //item name string
	enc<<(unsigned char)9; //item value type string 9
#ifdef WIN32
	enc<<(AnsiToUtf8(pstPicInfo->szAccountName)).c_str(); //item value
#else
	enc<<pstPicInfo->szAccountName; //item value
#endif

	//item 7 iUnLockTime
	enc<<"iUnLockTime"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstPicInfo->iUnLockTime; //item value

	//item 8 iUnLockResult
	enc<<"iUnLockResult"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstPicInfo->iUnLockResult; //item value

	//item 9 sUrl2
	enc<<"sUrl2"; //item name string
	enc<<(unsigned char)9; //item value type string 9
#ifdef WIN32
	enc<<AnsiToUtf8(pstPicInfo->szPicUrl).c_str(); //item value
#else
	enc<<pstPicInfo->szPicUrl; //item value
#endif

	iMsg = (int)enc.GetWriteLength();
	
	EncodeMapMsg(buf,iLen,msg,iMsg,(char*)(CMQInstance::VTHPROXY_TOPIC_PUB).c_str(),(char*)ToString(emMsgVTHProxyUnlockPicReq).c_str()/*"151191808"*/);

	//∑¢ÀÕ ˝æ›
	//int iSendBytes = send(m_sock,buf,iLen,0);
	//if ( iSendBytes != iLen )
	int iSendBytes = SendData(buf,iLen);
	if ( iSendBytes < 0 )
	{
		//∑¢ÀÕ ß∞‹
		return MQ_ERROR_UNKNOWN;
	}

	return MQ_NO_ERROR;
}

//∑¢ÀÕø™À¯œ˚œ¢
int CMQInstance::VTHProxy_Unlock(LPMQ_VTHPROXY_UNLOCK_REQ_INFO pstUnlockReq,int iDeliveryMode)
{
	//œ˚œ¢ÃÂª∫≥Â
	char msg[512];
	int iMsg = 512;

	//œ˚œ¢ÃÂ Ù–‘ª∫≥Â
	char buf[1024];
	int iLen = 1024;

	if ( emStarted != m_iStatus )
	{
		return MQ_ERROR_UNKNOWN;
	}
	//¥Ú∞¸œ˚œ¢ÃÂ

	int iTotalLen = 0;
	CByteEncDec enc(msg,iMsg);
	
	enc<<(unsigned int)6; //item count int 6

	//item 1 lVtoId
	enc<<"lVtoId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<pstUnlockReq->llVtoId; //item value

	//item 2 iMidVthId
	enc<<"iMidVthId"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstUnlockReq->iMidVthId; //item value

	//item 3 lVirVthId
	enc<<"lVirVthId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<pstUnlockReq->llVirVthId; //item value

	//item 4 iInviteTime
	enc<<"iInviteTime"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstUnlockReq->iInviteTime; //item value

	//item 5 lAccountId
	enc<<"lAccountId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<pstUnlockReq->llAccountId; //item value

	//item 6 sAccountName
	enc<<"sAccountName"; //item name string
	enc<<(unsigned char)9; //item value type string 9
#ifdef WIN32
	enc<<(AnsiToUtf8(pstUnlockReq->szAccountName)).c_str(); //item value
#else
	enc<<pstUnlockReq->szAccountName; //item value
#endif

	iMsg = (int)enc.GetWriteLength();
	
	EncodeMapMsg(buf,iLen,msg,iMsg,(char*)(CMQInstance::VTHPROXY_TOPIC_SUB).c_str(),(char*)ToString(emMsgVTHProxyUnlockReq).c_str()/*"151126272"*/);

	//∑¢ÀÕ ˝æ›
	//int iSendBytes = send(m_sock,buf,iLen,0);
	//if ( iSendBytes != iLen )
	int iSendBytes = SendData(buf,iLen);
	if ( iSendBytes < 0 )
	{
		//∑¢ÀÕ ß∞‹
		return MQ_ERROR_UNKNOWN;
	}

	return MQ_NO_ERROR;
}
//∑¢ÀÕ∫ÙΩ–◊™“∆Ω·π˚∑¥¿°œ˚œ¢
int CMQInstance::VTHProxy_CallRedirectResult(LPMQ_VTHPROXY_CALL_REDIRECT_RESULT_INFO pstCrResult,int iDeliveryMode)
{
	//œ˚œ¢ÃÂª∫≥Â
	char msg[512];
	int iMsg = 512;

	//œ˚œ¢ÃÂ Ù–‘ª∫≥Â
	char buf[1024];
	int iLen = 1024;

	if ( emStarted != m_iStatus )
	{
		return MQ_ERROR_UNKNOWN;
	}
	//¥Ú∞¸œ˚œ¢ÃÂ

	int iTotalLen = 0;
	CByteEncDec enc(msg,iMsg);
	
	enc<<(unsigned int)5; //item count int 5

	//item 1 lVtoId
	enc<<"lVtoId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<pstCrResult->llVtoId; //item value

	//item 2 iMidVthId
	enc<<"iMidVthId"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstCrResult->iMidVthId; //item value

	//item 3 lVirVthId
	enc<<"lVirVthId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<pstCrResult->llVirVthId; //item value

	//item 4 iInviteTime
	enc<<"iInviteTime"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstCrResult->iInviteTime; //item value

	//item 5 iResult
	enc<<"iResult"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstCrResult->iResult; //item value

	iMsg = (int)enc.GetWriteLength();
	
	EncodeMapMsg(buf,iLen,msg,iMsg,(char*)(CMQInstance::VTHPROXY_TOPIC_SUB).c_str(),(char*)ToString(emMsgVTHProxyCallReDirectResult).c_str()/*"151257344"*/);

	//∑¢ÀÕ ˝æ›
	//int iSendBytes = send(m_sock,buf,iLen,0);
	//if ( iSendBytes != iLen )
	int iSendBytes = SendData(buf,iLen);
	if ( iSendBytes < 0 )
	{
		//∑¢ÀÕ ß∞‹
		return MQ_ERROR_UNKNOWN;
	}

	return MQ_NO_ERROR;
}

/////////////////////ACMS∆ΩÃ®œ˚œ¢////////////////////////////////
//∑¢ÀÕACMS∆ΩÃ®±®æØÕ®÷™œ˚œ¢
int CMQInstance::ACMS_AlarmNotify(LPMQ_ACMS_ALARM_NOTIFY_INFO pstAlarmInfo,int iDeliveryMode)
{
	//œ˚œ¢ÃÂª∫≥Â
	char msg[512];
	int iMsg = 512;

	//œ˚œ¢ÃÂ Ù–‘ª∫≥Â
	char buf[1024];
	int iLen = 1024;

	if ( emStarted != m_iStatus )
	{
		return MQ_ERROR_UNKNOWN;
	}
	//¥Ú∞¸œ˚œ¢ÃÂ

	int iTotalLen = 0;
	CByteEncDec enc(msg,iMsg);
	
	enc<<(unsigned int)8; //item count int 8

	//item 1 lChanId
	enc<<"lChanId"; //item name string
	enc<<(unsigned char)6; //item value type long 6
	enc<<pstAlarmInfo->llChannelId; //item value

	//item 2 iAlarmTime
	enc<<"iAlarmTime"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstAlarmInfo->iAlarmTime; //item value

	//item 3 iAlarmType
	enc<<"iAlarmType"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstAlarmInfo->iAlarmType; //item value

	//item 4 sAlarmType
	enc<<"sAlarmType"; //item name string
	enc<<(unsigned char)9; //item value type string 9
#ifdef WIN32
	enc<<(AnsiToUtf8(pstAlarmInfo->szAlarmType)).c_str(); //item value
#else
	enc<<pstAlarmInfo->szAlarmType; //item value
#endif

	//item 5 iAlarmStatus
	enc<<"iAlarmStatus"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstAlarmInfo->iAlarmStatus; //item value

	//item 6 sAlarmStatus
	enc<<"sAlarmStatus"; //item name string
	enc<<(unsigned char)9; //item value type string 9
#ifdef WIN32
	enc<<(AnsiToUtf8(pstAlarmInfo->szAlarmStatus)).c_str(); //item value
#else
	enc<<pstAlarmInfo->szAlarmStatus; //item value
#endif

	//item 7 iReserve1
	enc<<"iReserve1"; //item name string
	enc<<(unsigned char)5; //item value type int 5
	enc<<pstAlarmInfo->iReserv1; //item value

	//item 8 sReserve2
	enc<<"sReserve2"; //item name string
	enc<<(unsigned char)9; //item value type string 9
#ifdef WIN32
	enc<<(AnsiToUtf8(pstAlarmInfo->szReserv2)).c_str(); //item value
#else
	enc<<pstAlarmInfo->szReserv2; //item value
#endif

	iMsg = (int)enc.GetWriteLength();
	
	EncodeMapMsg(buf,iLen,msg,iMsg,(char*)(CMQInstance::ACMS_ALARM_TOPIC_PUB).c_str(),(char*)ToString(emMSGAlarmACMC).c_str()/*"33751296"*/);

	//∑¢ÀÕ ˝æ›
	//int iSendBytes = send(m_sock,buf,iLen,0);
	//if ( iSendBytes != iLen )
	int iSendBytes = SendData(buf,iLen);
	if ( iSendBytes < 0 )
	{
		//∑¢ÀÕ ß∞‹
		return MQ_ERROR_UNKNOWN;
	}

	return MQ_NO_ERROR;
}
/////////////////////ACMS∆ΩÃ®œ˚œ¢////////////////////////////////

//∑¢ÀÕœ˚œ¢
int CMQInstance::SendMessage(char *pszDest,char *pMsg,int iLen,int iDeliveryMode)
{
	//√ª”– µœ÷
	return MQ_ERROR_NOT_IMPL;
}

//∑¢ÀÕœ˚œ¢ ¿©’π
int CMQInstance::SendMessageEx(char *pszTopic,char *pCmsType,char *pMsg,int iLen,int iDeliveryMode)
{
	//œ˚œ¢ÃÂ Ù–‘ª∫≥Â
	char buf[4096];
	int iBufLen = 4096;
	//if ( iLen > 1024 )
	//{

	//}
	if ( emStarted != m_iStatus )
	{
		ERROR_TRACE("Invalid status");
		return MQ_ERROR_UNKNOWN;
	}
	//¥Ú∞¸œ˚œ¢ÃÂ
	
#ifdef WIN32
	//œ˚œ¢ÃÂ∂‡◊÷Ω⁄◊™ªªŒ™UTF-8∏Ò Ω
	std::string strMsg = AnsiToUtf8(pMsg);
	EncodeTextMsg(buf,iBufLen,(char*)strMsg.c_str(),strMsg.size(),pszTopic,pCmsType);
#else
	EncodeTextMsg(buf,iBufLen,pMsg,iLen,pszTopic,pCmsType);
#endif

	//∑¢ÀÕ ˝æ›
	//int iSendBytes = send(m_sock,buf,iBufLen,0);
	//if ( iSendBytes != iBufLen )
	int iSendBytes = SendData(buf,iBufLen);
	if ( iSendBytes < 0 )
	{
		//∑¢ÀÕ ß∞‹
#ifdef WIN32
		ERROR_TRACE("send failed.err="<<WSAGetLastError());
#else
		ERROR_TRACE("send failed.err="<<errno);
#endif
		return MQ_ERROR_UNKNOWN;
	}

	return MQ_NO_ERROR;
}
///////////////////////////Ω”ø⁄//////////////////////////////


//Ω” ’œﬂ≥Ã
#ifdef VT_WIN32
unsigned long CMQInstance::NetTransThread(void *pParam)
#else
void* CMQInstance::NetTransThread(void *pParam)
#endif
{
	CMQInstance *pUser = (CMQInstance*)pParam;
	pUser->NetTransTcp();
	return 0;
}

#define VT_MAKEDW(b3,b2,b1,b0)        ((unsigned int)( (((unsigned int)(b3))&0xFF)<<24 |  \
									  (((unsigned int)(b2))&0xFF)<<16 |  \
									  (((unsigned int)(b1))&0xFF)<<8 |   \
									  (((unsigned int)(b0))&0xFF) ) )

int CMQInstance::NetTransTcp()
{
	int fds;
	timeval tv;
	int iTotal;
	fd_set fd_send;
	fd_set fd_recv;
	FD_ZERO(&fd_recv);
	FD_ZERO(&fd_send);
	sockaddr_in addr;
	int iAddrSize = sizeof(addr);
	char szBuf[1024*16];
	int iDataLen;
	int iRecvIndex = 0;
	long long/*time_t*/ tmPrev;
	long long/*time_t*/ tmCur;
	//CDCTimeValue::GetTimeOfDay(tmPrev);
	tmPrev = currentTimeMillis();//time(NULL);
	char szKeepalive[] = {0X00,0X00,0X00,0X06,0X0A,0X00,0X00,0X00,0X00,0X00};
#ifdef CONSUME_TOPIC_AUTO_TEST
#define TOPIC_TEST_INTERVAL        (15*1000)  //15√Î
#define TOPIC_TEST_FAILED_TIMES    3 //3¥Œ
	long long tmPrevTest = tmPrev;
	unsigned int m_uiTestFailedTimes = 0;
#endif

	while ( true )
	{
		if ( m_bExitNetThr ) //ÕÀ≥ˆœﬂ≥Ã
		{
			break;
		}

		switch ( m_iStatus )
		{
		case emIdle: //ø’œ–◊¥Ã¨
			{
#ifdef VT_WIN32
			Sleep(10);
#else
			sleep(1);
#endif
			break;
			}
		case emConnecting: //’˝‘⁄¡¨Ω”
			{
				//¥¶¿Ì¡¨Ω”
				break;
			}
		case emLogining: //’˝‘⁄µ«¬º
			{
				break;
			}
		case emStarted: //‘À––◊¥Ã¨
			{
				tmCur = currentTimeMillis();//time(NULL);
				//CDCTimeValue::GetTimeOfDay(tmCur);
				if ( _abs64(tmCur - tmPrev) >= 10*1000 )  //±£ªÓº‰∏Ù10√Î“ª¥Œ,¡¨–¯5¥Œ ß∞‹»œŒ™Ω· ¯
				{
					tmPrev = tmCur;
					m_uiFailTime++;
					if ( m_uiFailTime >= 5 )
					{
						//±£ªÓ ß∞‹,∂œœﬂÕ®÷™
						INFO_TRACE("keepalive timeout.");
						OnDisConnect(1);
						return 0;
					}
					else
					{

					}
					//∑¢ÀÕ±£ªÓœ˚œ¢
					::send(m_sock,szKeepalive,sizeof(szKeepalive),0);
				}

#ifdef CONSUME_TOPIC_AUTO_TEST
				if ( _abs64(tmCur - tmPrevTest) >= TOPIC_TEST_INTERVAL )  //º‰∏Ù30√Î≤‚ ‘“ª¥Œ
				{
					tmPrevTest = tmCur;
					m_uiTestFailedTimes++;
					if ( m_uiTestFailedTimes >= TOPIC_TEST_FAILED_TIMES )
					{
						//±£ªÓ ß∞‹,∂œœﬂÕ®÷™
						INFO_TRACE("topic test failed timeout.");
						OnDisConnect(1);
						return 0;
					}

					//∑¢ÀÕ≤‚ ‘œ˚œ¢
					if ( MQ_NO_ERROR != SendMessageEx((char*)CMQInstance::ACTIVE_MQ_TEST_TOPIC.c_str(),
						                              "tpoic_test","topic_rest",
													  strlen("topic_rest"),
													  MQ_DMODE_NON_PERSISTENT) )
					{
						ERROR_TRACE("send test topic failed");
					}
				}
#endif

				//Ω” ’Õ¯¬Á ˝æ›
				tv.tv_sec = 0;
				tv.tv_usec = 200*1000;
				fds = 0;
				FD_ZERO(&fd_recv);
				FD_ZERO(&fd_send);

				FD_SET(m_sock,&fd_recv);
				if ( _lstSend.size() > 0 )
				{
					FD_SET(m_sock,&fd_send);
				}
				fds = (int)m_sock;
				if ( fds <= 0 )
				{
#ifdef VT_WIN32
					Sleep(1);
#else
					sleep(1);
#endif
					continue;
				}

				iTotal = select(fds+1,&fd_recv,&fd_send,0,&tv);
				if ( VT_SOCKET_ERROR == iTotal )
				{
					//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
					//DC_ERROR_TRACE("CDCStack::NetTransTcp() socket errno="<<DCNGetSocketError()<<" error string="<<DCNSocketErrorString(DCNGetSocketError()));
				}

				if ( iTotal == 0 ) //≥¨ ± √ª”– ˝æ›
				{
					continue;
				}

				if ( FD_ISSET(m_sock,&fd_send) )
				{
					OnSendData();
				}
				if ( !FD_ISSET(m_sock,&fd_recv) )
				{
					//√ª”– ˝æ›ø… ’
					continue;
				}
				//iDataLen = recv(m_sock,szBuf,4095,0);
				iDataLen = recv(m_sock,&szBuf[iRecvIndex],1024*16-iRecvIndex,0);
				
				if ( 0 == iDataLen ) //disconnect
				{
					//¡¨Ω”∂œø™
					//OnDisConnect(emDisConnectNormal);
					//break;
					INFO_TRACE("remote disconect");
					OnDisConnect(0);
					return 0;
				}
				if ( VT_SOCKET_ERROR == iDataLen )
				{
					//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
					//DC_ERROR_TRACE("CDCStack::NetTransTcp() socket errno="<<DCNGetSocketError()<<" error string="<<DCNSocketErrorString(DCNGetSocketError()));
					//OnDisConnect(emDisConnectUnknown);
					//Ω” ’“Ï≥£
					ERROR_TRACE("remote disconect");
					OnDisConnect(-1);
					return 0;
				}
				iRecvIndex += iDataLen;
				bool bHaveMsg = true;
				do
				{
					int iMsgLen;
				if ( iDataLen > 4 )
				{
					unsigned int uiCmdExt = VT_MAKEDW(szBuf[0],szBuf[1],szBuf[2],szBuf[3]);
					if ( iRecvIndex/*iDataLen*/ >= (uiCmdExt+4) ) //¬˙◊„“ª∞¸ ˝æ›
					{
						switch ( szBuf[4] ) //œ˚œ¢¿‡–Õ
						{
						//case 1: //WIREFORMAT_INFO
						//case 2: //BROKER_INFO
						//case 3: //CONNECTION_INFO øÕªß∂À≤ªª· ’µΩ
						case 10: //KEEP_ALIVE_INFO
							{
								//±£ªÓ
								m_uiFailTime = 0;
								break;
							}
						case 21:
							{
								iMsgLen = uiCmdExt+4;
#ifdef CONSUME_TOPIC_AUTO_TEST
								int iRet = DecodeDispatchtMsg(szBuf,iMsgLen/*iDataLen*/);
								if ( iRet == 11 ) // «≤‚ ‘÷˜Ã‚
								{
									tmPrevTest = tmCur;
									m_uiTestFailedTimes = 0;
								}
								else
								{
									tmPrevTest = tmCur;
									m_uiTestFailedTimes = 0;
								}
#else
								DecodeDispatchtMsg(szBuf,iMsgLen/*iDataLen*/);
#endif
								//tmCur = currentTimeMillis();//time(NULL);
								//tmPrev = tmCur;
								m_uiFailTime = 0;
								break;
							}
						case 22: //MESSAGE_ACK
							{
								m_uiFailTime = 0;
							}
						case 25: //ACTIVEMQ_MAP_MESSAGE
							{
								//DecodeDispatchtMsg(szBuf,iDataLen);
								m_uiFailTime = 0;
								break;
							}
						case 28: //ACTIVEMQ_TEXT_MESSAGE
							{
								//DecodeDispatchtMsg(szBuf,iDataLen);
								m_uiFailTime = 0;
								break;
							}
						default:
							INFO_TRACE("msg type:"<<(int)szBuf[4]);
							break;
						}
						if ( (uiCmdExt+4) < iRecvIndex ) //»‘»ª”– £”‡ ˝æ›
						{
							memmove(szBuf,&szBuf[uiCmdExt+4],iRecvIndex-(uiCmdExt+4));
							iRecvIndex -= (uiCmdExt+4);
						}
						else if ( (uiCmdExt+4) == iRecvIndex ) //∏’∫√
						{
							iRecvIndex = 0;
							bHaveMsg = false;
						}
						else //¥ÌŒÛ,≤ª”¶∏√≥ˆœ÷
						{
							ERROR_TRACE("parse error");
						}
					}
					else // ˝æ›Ω” ’
					{
						bHaveMsg = false;
						// ˝æ›∞¸π˝∂Ã,∂™∆˙
					}
				}
				else
				{
					bHaveMsg = false;
				}
				}while ( bHaveMsg );


				break;
			}
		case emLogouting: //’˝‘⁄µ«≥ˆ
			{
				break;
			}
		default: //¥ÌŒÛ,Œ¥÷™◊¥Ã¨
			break;
		}
	}
	
	return 0;
}

//void DvrTranport::OnRecv()
//{
//	static char hdr[32]; //∞¸Õ∑ ˝æ›
//	static int iRecvIndex = 0;
//	static unsigned int uiExtLen = 0;
//	static char *pExtData = NULL;
//	static int status = 0; //Ω” ’◊¥Ã¨ 0 IDLE 1 ’˝‘⁄Ω” ’Õ∑ 2 ’˝‘⁄Ω” ’ƒ⁄»›
//	int iRecvLen;
//
//	bool bCanRecv = true;
//	while ( bCanRecv )
//	{
//		switch ( status )
//		{
//		case 0: //Ω” ’œ˚œ¢Õ∑Õ∑,ø™ º
//			{
//				iRecvLen = _socket.Recv(hdr,4);
//				if ( 4 == iRecvLen )
//				{
//					//Ω‚ŒˆÕ∑≤ø,Ω” ’contenƒ⁄»› little endian
//					uiExtLen = VT_MAKEDW(hdr[0],hdr[1],hdr[2],hdr[3]);
//					if ( uiExtLen > 0 ) //”–¿©’π◊÷∂Œ
//					{
//						//Ω” ’¿©’π◊÷∂Œ
//						pExtData = new char[uiExtLen];
//						if ( !pExtData ) //∑÷≈‰ƒ⁄¥Ê ß∞‹
//						{
//							///???
//							//ERROR_TRACE("out of memory.");
//						}
//						status = 2;
//					}
//					else //Œﬁ¿©’π◊÷∂Œ,÷±Ω”…˙≥…“ªÃıDVRœ˚œ¢
//					{
//						//œ˚œ¢¥ÌŒÛ£ø
//
//					}
//					break;
//				}
//				else  if ( 0 < iRecvLen && 4 > iRecvLen )
//				{
//					iRecvIndex = iRecvLen;
//					bCanRecv = false;
//					status = 1;
//					break;
//				}
//				else if ( 0 == iRecvLen ) //socket disconnect
//				{
//					//Õ®÷™¡¨Ω”∂œø™
//
//					// Õ∑≈◊‘º∫
//					//INFO_TRACE("Logot OK. session id "<<_sessionId);
//					//_dvrDevice.RemoveTranport(this);
//					return ;
//				}
//#ifdef VT_WIN32
//				else if ( SOCKET_ERROR == iRecvLen && WSAEWOULDBLOCK == WSAGetLastError() )
//				{
//					bCanRecv = false;
//					break;
//				}
//				else //¥ÌŒÛ
//				{
//					bCanRecv = false;
//					break;
//				}
//#else
//				else if ( -1 == iRecvLen && EAGAIN == errno )
//				{
//					bCanRecv = false;
//					break;
//				}
//				else //¥ÌŒÛ
//				{
//					bCanRecv = false;
//					break;
//				}
//#endif
//
//			}
//
//		case 1: //Ω” ’DVRÕ∑,≤ø∑÷
//			{
//				iRecvLen = _socket.Recv(&hdr[iRecvIndex],4-iRecvIndex);
//				if ( (32-iRecvIndex) == iRecvLen )
//				{
//					//Ω‚ŒˆÕ∑≤ø,Ω” ’contenƒ⁄»› little endian
//					uiExtLen = VT_MAKEDW(hdr[0],hdr[1],hdr[2],hdr[3]);
//					if ( uiExtLen > 0 ) //”–¿©’π◊÷∂Œ
//					{
//						//Ω” ’¿©’π◊÷∂Œ
//						status = 2;
//						pExtData = new char[uiExtLen];
//						if ( !pExtData ) //∑÷≈‰ƒ⁄¥Ê ß∞‹
//						{
//							///???
//							//ERROR_TRACE("out of memory.");
//						}
//						status = 2;
//					}
//					else //Œﬁ¿©’π◊÷∂Œ,÷±Ω”…˙≥…“ªÃıDVRœ˚œ¢
//					{
//						//œ˚œ¢¥ÌŒÛ£ø
//
//					}
//					break;
//				}
//				else  if ( 0 < iRecvLen && (4-iRecvIndex) > iRecvLen )
//				{
//					iRecvIndex += iRecvLen;
//					bCanRecv = false;
//					//status = 1;
//					break;
//				}
//				else if ( 0 == iRecvLen ) //socket disconnect
//				{
//					//Õ®÷™¡¨Ω”∂œø™
//
//					// Õ∑≈◊‘º∫
//					//_dvrDevice.RemoveTranport(this);
//					return ;
//				}
//#ifdef VT_WIN32
//				else if ( SOCKET_ERROR == iRecvLen && WSAEWOULDBLOCK == WSAGetLastError() )
//				{
//					bCanRecv = false;
//					break;
//				}
//				else //¥ÌŒÛ
//				{
//					bCanRecv = false;
//					break;
//				}
//#else
//				else if ( -1 == iRecvLen && EAGAIN == errno )
//				{
//					bCanRecv = false;
//					break;
//				}
//				else //¥ÌŒÛ
//				{
//					bCanRecv = false;
//					break;
//				}
//#endif
//
//			}
//
//		case 2: //Ω” ’œ˚œ¢ÃÂ,ø™ º
//			{
//				iRecvIndex = 0;
//				iRecvLen = _socket.Recv(pExtData,uiExtLen);
//				if ( uiExtLen == iRecvLen ) //œ˚œ¢ÕÍ’˚
//				{
//					///???
//					//Õ®÷™DVRœ˚œ¢
//					//DvrMessage msg;
//					//msg.cmd = hdr[0];
//					//msg.dvrip_r0 = hdr[1];
//					//msg.dvrip_r1 = hdr[2];
//					//msg.dvrip_v = ((unsigned char)hdr[3] &0XF0)>>4;
//					//msg.dvrip_hl = ((unsigned char)hdr[3] &0X0F);
//					//msg.dvrip_extlen = uiExtLen;
//					//memcpy(msg.dvrip_p,&hdr[8],24);
//					//msg.SetContent(pExtData,(int)uiExtLen);
//					//OnRecv(msg);
//					status = 0;
//					break;
//				}
//				else  if ( 0 < iRecvLen && uiExtLen > iRecvLen )
//				{
//					iRecvIndex += iRecvLen;
//					bCanRecv = false;
//					status = 3;
//					break;
//				}
//				else if ( 0 == iRecvLen ) //socket disconnect
//				{
//					//Õ®÷™¡¨Ω”∂œø™
//
//					// Õ∑≈◊‘º∫
//					//INFO_TRACE("Logot OK. session id "<<_sessionId);
//					//_dvrDevice.RemoveTranport(this);
//					return ;
//				}
//#ifdef VT_WIN32
//				else if ( SOCKET_ERROR == iRecvLen && WSAEWOULDBLOCK == WSAGetLastError() )
//				{
//					bCanRecv = false;
//					break;
//				}
//				else //¥ÌŒÛ
//				{
//					bCanRecv = false;
//					break;
//				}
//#else
//				else if ( -1 == iRecvLen && EAGAIN == errno )
//				{
//					bCanRecv = false;
//					break;
//				}
//				else //¥ÌŒÛ
//				{
//					bCanRecv = false;
//					break;
//				}
//#endif
//			}
//		case 3:
//			{
//				iRecvLen = _socket.Recv(&pExtData[iRecvIndex],uiExtLen-iRecvIndex);
//				if ( (uiExtLen-iRecvIndex) == iRecvLen ) //œ˚œ¢ÕÍ’˚
//				{
//					///???
//					//Õ®÷™DVRœ˚œ¢
//					//DvrMessage msg;
//					//msg.cmd = hdr[0];
//					//msg.dvrip_r0 = hdr[1];
//					//msg.dvrip_r1 = hdr[2];
//					//msg.dvrip_v = ((unsigned char)hdr[3] &0XF0)>>4;
//					//msg.dvrip_hl = ((unsigned char)hdr[3] &0X0F);
//					//msg.dvrip_extlen = uiExtLen;
//					//memcpy(msg.dvrip_p,&hdr[8],24);
//					//msg.SetContent(pExtData,(int)uiExtLen);
//					//OnRecv(msg);
//					status = 0;
//					break;
//				}
//				else  if ( 0 < iRecvLen && (uiExtLen-iRecvIndex) > iRecvLen )
//				{
//					iRecvIndex += iRecvLen;
//					bCanRecv = false;
//					status = 3;
//					break;
//				}
//				else if ( 0 == iRecvLen ) //socket disconnect
//				{
//					//Õ®÷™¡¨Ω”∂œø™
//
//					// Õ∑≈◊‘º∫
//					//INFO_TRACE("Logot OK. session id "<<_sessionId);
//					//_dvrDevice.RemoveTranport(this);
//					return ;
//				}
//#ifdef VT_WIN32
//				else if ( SOCKET_ERROR == iRecvLen && WSAEWOULDBLOCK == WSAGetLastError() )
//				{
//					bCanRecv = false;
//					break;
//				}
//				else //¥ÌŒÛ
//				{
//					bCanRecv = false;
//					break;
//				}
//#else
//				else if ( -1 == iRecvLen && EAGAIN == errno )
//				{
//					bCanRecv = false;
//					break;
//				}
//				else //¥ÌŒÛ
//				{
//					bCanRecv = false;
//					break;
//				}
//#endif
//			}
//		default:
//			break;
//		}
//	}
//
//}

bool CMQInstance::CreateProcThread()
{
	m_bExitNetThr = false;
#ifdef VT_WIN32
	m_hNetThread = CreateThread(NULL,0,CMQInstance::NetTransThread,this,0,&m_dwNetThreadID);
#else
	pthread_attr_t attr;
	int nRet;
	if ((nRet = ::pthread_attr_init(&attr)) != 0) 
	{
		//VT_ERROR_TRACE("CVTStack::InitStack() : pthread_attr_init() failed! errno="<<nRet<<".");
		//return VTSTA_ERROR_SYSTEM;
		return false;
	}

	int dstate = PTHREAD_CREATE_JOINABLE;

	if ((nRet = ::pthread_attr_setdetachstate(&attr, dstate)) != 0) 
	{
		//VT_ERROR_TRACE("CVTStack::InitStack() : pthread_attr_setdetachstate() failed! errno="<<nRet<<".");
		::pthread_attr_destroy(&attr);
		//return VTSTA_ERROR_SYSTEM;
		return false;
	}

	if ((nRet = ::pthread_create(&m_dwNetThreadID, &attr,NetTransThread, this)) != 0) 
	{
		//VT_ERROR_TRACE("CVTStack::InitStack() : pthread_create() failed! errno="<<nRet<<".");
		::pthread_attr_destroy(&attr);
		//return VTSTA_ERROR_SYSTEM;
		return false;
	}
	::pthread_attr_destroy(&attr);
	m_hNetThread = m_dwNetThreadID;
#endif
	return true;
}

int CMQInstance::Connect()
{
	return -1;
}
int CMQInstance::Connect_Sync() //Õ¨≤Ω¡¨Ω”
{
	fd_set fds;
	timeval tv;
	int iTotal;
	int iRet;
	//VT_SOCKET sock = VT_INVALID_SOCKET;
	//iError = DCN_NO_ERROR;

	if ( VT_INVALID_SOCKET != m_sock ) //“—æ≠≥ı ºªØ
	{
        VT_CLOSE_SOCKET(m_sock);
	}
    
    printf("%s socket=%d\n",__FUNCTION__,m_sock);

	m_sock = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
    
    printf("%s create socket=%d\n",__FUNCTION__,m_sock);
    
    int nosigpipe = 1;
	setsockopt(m_sock, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe, sizeof(nosigpipe));
    
    
	if( VT_INVALID_SOCKET == m_sock )
	{
		//DC_ERROR_TRACE("CDCStack::ConnectTo() create socket failed,errno="<<DCNGetSocketError()<<",error string="<<DCNSocketErrorString(DCNGetSocketError()));
		//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
		//iError = DCN_ERROR_SOCKET;
        
        printf("mq_sdk create socket failed errno=%d\n",errno);
		return -1;
	}
    
#ifdef RUN_BACKGROUND
    //后台voip支持
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocket(NULL, m_sock,  &readStream, &writeStream);
    
    NSInputStream *miStream = (__bridge_transfer NSInputStream *)readStream;
    NSOutputStream *moStream = (__bridge_transfer NSOutputStream *)writeStream;
    
    [miStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
    [moStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
    
    //    [miStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    //    [moStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [miStream open];
    [moStream open];
#endif
    
	int iBlock = 1;
#ifdef VT_WIN32
	iRet = ::ioctlsocket(m_sock,FIONBIO,(u_long FAR *)&iBlock);
	if ( SOCKET_ERROR == iRet )
	{
		//DC_ERROR_TRACE("CDCStack::ConnectTo() set socket opt failed,errno="<<DCNGetSocketError()<<",error string="<<DCNSocketErrorString(DCNGetSocketError()));
		//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
		VT_CLOSE_SOCKET(m_sock);
		//iError = DCN_ERROR_SOCKET;
		return -1;
	}
#else
	iBlock = ::fcntl(m_sock, F_GETFL, 0);
	if ( -1 != iBlock )
	{
		iBlock |= O_NONBLOCK;
		iRet = ::fcntl(m_sock, F_SETFL, iBlock);
		if ( -1 == iRet )
		{
			//DC_ERROR_TRACE("CDCStack::ConnectTo() set socket opt failed,errno="<<DCNGetSocketError()<<",error string="<<DCNSocketErrorString(DCNGetSocketError()));
			//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
			VT_CLOSE_SOCKET(m_sock);
			//iError = DCN_ERROR_SOCKET;
			return -1;
		}
	}
#endif

	////…Ë÷√ Ù–‘ πÿ±’NagleÀ„∑®
	//iRet = setsockopt(m_sock, IPPROTO_TCP, TCP_NODELAY, (char*)&iBlock, sizeof(iBlock));


	sockaddr_in servAddr;
	servAddr.sin_family = AF_INET;
	servAddr.sin_addr.s_addr = inet_addr(m_strIp.c_str());
	servAddr.sin_port = htons(m_usPort);
	iRet = connect(m_sock,(struct sockaddr*) &servAddr,sizeof(servAddr));
#ifdef VT_WIN32
	if ( SOCKET_ERROR == iRet && (errno = WSAGetLastError()) == WSAEWOULDBLOCK )
	{
#else
	if ( -1 == iRet && EINPROGRESS == errno )
	{
		errno = EWOULDBLOCK; 
#endif
		FD_ZERO(&fds);
		FD_SET(m_sock,&fds);
		tv.tv_sec = 5;   //µ»¥˝ªÿ”¶œÏ”¶ ±º‰ 5√Î÷”
		tv.tv_usec = 0;
		iTotal = select((int)m_sock+1,0,&fds,0,&tv);
		if ( VT_SOCKET_ERROR == iTotal )
		{
			//DC_ERROR_TRACE("CDCStack::ConnectTo() select failed,errno="<<DCNGetSocketError()<<",error string="<<DCNSocketErrorString(DCNGetSocketError()));
			//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
			VT_CLOSE_SOCKET(m_sock);
			//iError = DCN_ERROR_SOCKET;
			return -1;
		}

		if ( 0 == iTotal ) // connect timeout
		{
			//DC_ERROR_TRACE("CDCStack::ConnectTo() select timeout.");
			//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
			VT_CLOSE_SOCKET(m_sock);
			//iError = DCN_ERROR_CONNECT_TIMEOUT;
			return -1;
		}

	}
	else
	{
		//DC_ERROR_TRACE("CDCStack::ConnectTo() connect failed,errno="<<DCNGetSocketError()<<",error string="<<DCNSocketErrorString(DCNGetSocketError()));
		//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
		VT_CLOSE_SOCKET(m_sock);
		//iError = DCN_ERROR_SOCKET;
		return -1;
	}

	return 0;
}

int CMQInstance::RecvData(char szBuf[],int iBufLen,int iTimeout)
{
	fd_set fds;
	timeval tv;
	int iTotal;
	int iAddrSize = sizeof(struct sockaddr);
	int iDataLen;
	//int iRet;

	FD_ZERO(&fds);
	FD_SET(m_sock,&fds);
	tv.tv_sec = iTimeout/1000;   //µ»¥˝ªÿ”¶œÏ”¶ ±º‰
	tv.tv_usec = iTimeout%1000;
	iTotal = select((int)m_sock+1,&fds,0,0,&tv);
#ifdef VT_WIN32
	if ( SOCKET_ERROR == iTotal && (errno = WSAGetLastError()) == WSAEWOULDBLOCK )
	{
#else
	if ( -1 == iTotal && EINPROGRESS == errno )
	{
		errno = EWOULDBLOCK; 
#endif
		if ( VT_SOCKET_ERROR == iTotal )
		{
			//DC_ERROR_TRACE("CDCStack::RecvData() select failed,errno="<<DCNGetSocketError()<<" error string="<<DCNSocketErrorString(DCNGetSocketError()));
			//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
			//return DCN_ERROR_SOCKET;
			ERROR_TRACE("select failed,op blocked");
			return -1;
		}


	}
		if ( 0 == iTotal ) //timeout
		{
			//DC_ERROR_TRACE("CDCStack::RecvData() select timeout.");
			//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
			//return DCN_ERROR_SOCKET;
			ERROR_TRACE("select failed,timeout");
			return -1;
		}

	if ( VT_SOCKET_ERROR == iTotal )
	{
		//DC_ERROR_TRACE("CDCStack::RecvData() select failed,errno="<<DCNGetSocketError()<<" error string="<<DCNSocketErrorString(DCNGetSocketError()));
		//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
		//return DCN_ERROR_SOCKET;
#ifdef VT_WIN32
		ERROR_TRACE("select failed,errno="<<WSAGetLastError());
#else
		ERROR_TRACE("select failed,errno="<<errno);
#endif
		return -1;
	}

       
	iDataLen = recv(m_sock,szBuf,iBufLen,0);
    printf("socket recv %d\n",iDataLen);

	if ( VT_SOCKET_ERROR == iDataLen )
	{
		//DC_ERROR_TRACE("CDCStack::RecvData() select failed,errno="<<DCNGetSocketError()<<" error string="<<DCNSocketErrorString(DCNGetSocketError()));
		//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
		//return DCN_ERROR_SOCKET;
#ifdef VT_WIN32
		ERROR_TRACE("recv failed,errno="<<WSAGetLastError());
#else
		ERROR_TRACE("recv failed,errno="<<errno);
#endif
		return -1;
	}

	//ºÏ≤È ˝æ›≥§∂»
	if ( iDataLen < 4 )
	{
		//DC_ERROR_TRACE("CDCStack::RecvData() socket error.");
		//CDCGeneral::Instance()->DCNSetLastError(DCN_ERROR_SOCKET);
		//return DCN_ERROR_SOCKET;
		ERROR_TRACE("recv failed,data too short=");
		return -1;
	}
	return iDataLen;
}

//class ConvertorType
//{
//public:
//	static void Swap(unsigned short &aHostShort)
//	{
//#if 1 //cpu arch LITTLE_ENDIAN
//		Swap2(&aHostShort, &aHostShort);
//#endif 
//	}
//
//	static void Swap(unsigned int &aHostLong)
//	{
//#if 1 //cpu arch LITTLE_ENDIAN
//		Swap4(&aHostLong, &aHostLong);
//#endif
//	}
//
//
//	static void Swap(unsigned long long &aHostLongLong)
//	{
//#if 1 //cpu arch LITTLE_ENDIAN
//		Swap8(&aHostLongLong, &aHostLongLong);
//#endif
//	}
//
//	// mainly copied from ACE_CDR
//	static void Swap2(const void *orig, void* target)
//	{
//		register unsigned short usrc = * reinterpret_cast<const unsigned short*>(orig);
//		register unsigned short* udst = reinterpret_cast<unsigned short*>(target);
//		*udst = (usrc << 8) | (usrc >> 8);
//	}
//
//	static void Swap4(const void* orig, void* target)
//	{
//		register unsigned int x = * reinterpret_cast<const unsigned int*>(orig);
//		x = (x << 24) | ((x & 0xff00) << 8) | ((x & 0xff0000) >> 8) | (x >> 24);
//		* reinterpret_cast<unsigned int*>(target) = x;
//	}
//
//	static void Swap8(const void* orig, void* target)
//	{
//		register unsigned int x = * reinterpret_cast<const unsigned int*>(orig);
//		register unsigned int y = * reinterpret_cast<const unsigned int*>(static_cast<const char*>(orig) + 4);
//		x = (x << 24) | ((x & 0xff00) << 8) | ((x & 0xff0000) >> 8) | (x >> 24);
//		y = (y << 24) | ((y & 0xff00) << 8) | ((y & 0xff0000) >> 8) | (y >> 24);
//		* reinterpret_cast<unsigned int*>(target) = y;
//		* reinterpret_cast<unsigned int*>(static_cast<char*>(target) + 4) = x;
//	}
//};
//
//class CByteEncDec
//{
//public:
//	CByteEncDec(char *pBuf,unsigned int len):m_pData(pBuf),m_uiLength(len),
//											 m_pEndData(m_pData+len),m_pWritePtr(m_pData),
//											 m_pReadPtr(m_pData),m_ResultRead(true),m_ResultWrite(true)
//	  {
//
//	  }
//	~CByteEncDec()
//	{
//	
//	}
//
//	CByteEncDec& operator<<(char c)
//	{
//		Write(&c, sizeof(char));
//		return *this;
//	}
//
//	CByteEncDec& operator<<(unsigned char c)
//	{
//		Write(&c, sizeof(unsigned char));
//		return *this;
//	}
//
//	CByteEncDec& operator<<(short n)
//	{
//		return *this << (unsigned short)n;
//	}
//
//	CByteEncDec& operator<<(unsigned short n)
//	{
//		ConvertorType::Swap(n);
//		Write(&n, sizeof(unsigned short));
//		return *this;
//	}
//
//	CByteEncDec& operator<<(int n)
//	{
//		return *this << (unsigned int)n;
//	}
//
//	CByteEncDec& operator<<(unsigned int n)
//	{
//		ConvertorType::Swap(n);
//		Write(&n, sizeof(unsigned int));
//		return *this;
//	}
//
//	CByteEncDec& operator<<(long long n)
//	{
//		return *this << (unsigned long long)n;
//	}
//
//	CByteEncDec& operator<<(unsigned long long n)
//	{
//		ConvertorType::Swap(n);
//		Write(&n, sizeof(unsigned long long));
//		return *this;
//	}
//
//
//	CByteEncDec& operator<<(const std::string &str)
//	{
//		return WriteString(str.c_str(), str.length());
//	}
//
//	CByteEncDec& operator<<(const char *str)
//	{
//		unsigned short len = 0;
//		if ( str )
//		{
//			len = strlen(str);
//		}
//		return WriteString(str, len);
//	}
//
//	CByteEncDec& WriteString(const char *str, unsigned int ll)
//	{
//		unsigned short len = static_cast<unsigned short>(ll);
//
//		(*this) << len;
//		if ( len > 0 )
//		{
//			Write(str, len);
//		}
//		return *this;
//	}
//
//	CByteEncDec& operator>>(char& c)
//	{
//		Read(&c, sizeof(char));
//		return *this;
//	}
//
//	CByteEncDec& operator>>(unsigned char& c)
//	{
//		Read(&c, sizeof(unsigned char));
//		return *this;
//	}
//
//	CByteEncDec& operator>>(short& n)
//	{
//		return *this >> (unsigned short&)n;
//	}
//
//	CByteEncDec& operator>>(unsigned short& n)
//	{
//		Read(&n, sizeof(unsigned short));
//		ConvertorType::Swap(n);
//		return *this;
//	}
//
//
//	CByteEncDec& operator>>(int& n)
//	{
//		return *this >> (unsigned int&)n;
//	}
//
//	CByteEncDec& operator>>(unsigned int& n)
//	{
//		Read(&n, sizeof(unsigned int));
//		ConvertorType::Swap(n);
//		return *this;
//	}
//	CByteEncDec& operator>>(long long& n)
//	{
//		return *this >> (unsigned long long&)n;
//	}
//
//	CByteEncDec& operator>>(unsigned long long& n)
//	{
//		Read(&n, sizeof(unsigned long long));
//		ConvertorType::Swap(n);
//		return *this;
//	}
//
//	CByteEncDec& operator>>(std::string& str)
//	{
//		unsigned short len = 0;
//		(*this) >> len;
//
//		if (len > 0)
//		{
//			str.resize(0);
//			str.resize(len);
//			Read(const_cast<char*>(str.data()), len);
//		}
//		return *this;
//	}
//
//	
//	CByteEncDec& Read(void *aDst, unsigned int aCount)
//	{
//		if ( m_ResultRead )
//		{
//			unsigned int ulRead = 0;
//			//m_ResultRead = m_Block.Read(aDst, aCount, &ulRead);
//			::memcpy(aDst,m_pReadPtr,aCount);
//			m_pReadPtr += aCount;
//			m_ResultRead = m_pReadPtr < m_pEndData ? true : false;
//		}
//		if ( !m_ResultRead ) //∂¡ ß∞‹
//		{
//		}
//		return *this;
//	}
//
//	CByteEncDec& Write(const void *aDst, unsigned int aCount)
//	{
//		if ( m_ResultWrite )
//		{
//			unsigned int ulWritten = 0;
//			::memcpy(m_pWritePtr,aDst,aCount);
//			m_pWritePtr += aCount;
//			m_ResultWrite = m_pWritePtr < m_pEndData ? true : false;
//		}
//		if ( !m_ResultWrite ) //–¥ ß∞‹
//		{
//		}
//		return *this;
//	}
//	
//	bool IsGood()
//	{
//		if ( m_ResultWrite && m_ResultRead )
//		{
//			return true;
//		}
//		else
//		{
//			return false;
//		}
//	}
//	unsigned int GetWriteLength()
//	{
//		return (unsigned int)(m_pWritePtr-m_pData);
//	}
//
//private:
//	bool m_ResultRead;
//	bool m_ResultWrite;
//
//	char *m_pData;
//	unsigned int m_uiLength;
//	char *m_pEndData;
//	char *m_pWritePtr;
//	char *m_pReadPtr;
//
//	// Not support bool because its sizeof is not fixed.
//	CByteEncDec& operator<<(bool n);
//	CByteEncDec& operator>>(bool& n);
//
//	// Not support long double.
//	CByteEncDec& operator<<(long double n);
//	CByteEncDec& operator>>(long double& n);
//};

int CMQInstance::EncodeWaveFormatInfo(char buf[],int &iLen) //¥Ú∞¸WAVEFORMAT_INFO–≈¡Ó
{
	CByteEncDec enc(buf,iLen);
	
	enc<<(unsigned int)217; //◊‹≥§∂»
	enc<<(unsigned char)1; //type
	enc.Write("ActiveMQ",8);
	//enc<<"ActiveMQ"; //magic
	enc<<(int)6; //version
	enc<<(unsigned char)1; //”– Ù–‘
	enc<<(unsigned int)199; // Ù–‘◊‹≥§∂»
	enc<<(unsigned int)8; // Ù–‘◊‹ ˝ƒø
	//for(int i=0;i<8;i++)
	std::string temp;
	
	temp = "CacheEnabled";
	enc<<temp;
	enc<<(unsigned char)1; //bool¿‡–Õ
	enc<<(unsigned char)0; //÷µŒ™false
	
	temp = "CacheSize";
	enc<<temp;
	enc<<(unsigned char)5; //int¿‡–Õ
	enc<<(unsigned int)1024; //ƒ¨»œ÷µŒ™1024
	
	temp = "MaxInactivityDuration";
	enc<<temp;
	enc<<(unsigned char)6; //long long¿‡–Õ
	enc<<(unsigned long long)30000; //ƒ¨»œ÷µŒ™30000

	temp = "MaxInactivityDurationInitalDelay";
	enc<<temp;
	enc<<(unsigned char)6; //long long¿‡–Õ
	enc<<(unsigned long long)10000; //ƒ¨»œ÷µŒ™30000

	temp = "SizePrefixDisabled";
	enc<<temp;
	enc<<(unsigned char)1; //bool¿‡–Õ
	enc<<(unsigned char)0; //ƒ¨»œ÷µŒ™false

	temp = "StackTraceEnabled";
	enc<<temp;
	enc<<(unsigned char)1; //bool¿‡–Õ
	enc<<(unsigned char)1; //ƒ¨»œ÷µŒ™true

	temp = "TcpNoDelayEnabled";
	enc<<temp;
	enc<<(unsigned char)1; //bool¿‡–Õ
	enc<<(unsigned char)0;//1; //ƒ¨»œ÷µŒ™true  πƒ‹NagleÀ„∑®,»∑±£◊Ó¥Û ’∑¢ÀŸ∂»

	temp = "TightEncodingEnabled";
	enc<<temp;
	enc<<(unsigned char)1; //bool¿‡–Õ
	enc<<(unsigned char)0; //ƒ¨»œ÷µŒ™false

	iLen = (int)enc.GetWriteLength();

	return 217;
}

int CMQInstance::EncodeConnectionInfo(char buf[],int &iLen) //¥Ú∞¸CONNECTION_INFO–≈¡Ó
{
	//std::string connectId = "ID:win12955-24867-1370570147688-0:0";
	//std::string clientId = "ID:win12955-24867-1370570147688-1:0";
	//std::string password = "123456";
	//std::string username = "123456";
	int iTotalLen = 0;
	CByteEncDec enc(buf,iLen);
	
	enc<<iTotalLen; //◊‹≥§∂»
	enc<<(unsigned char)3; //type CONNECTION_INFO
	enc<<m_uiCommandId; //command id 1
	m_uiCommandId++;
	enc<<(unsigned char)1; //need response true

	//nest command CONNECTION_ID
	enc<<(unsigned char)1; //CONNECTION_ID exist ? true
	enc<<(unsigned char)120; //CONNECTION_ID type 120
	enc<<(unsigned char)1; //CONNECTION_ID not null true
	enc<<m_strConnectionId/*connectId*/; //CONNECTION_ID 

	enc<<(unsigned char)1; //clientId not null ? true
	enc<<m_strClientId/*clientId*/; //clientId

	enc<<(unsigned char)1; //password not null ? true
	enc<<m_strPassword/*password*/; //password

	enc<<(unsigned char)1; //username not null ? true
	enc<<m_strUsername/*username*/; //username

	enc<<(unsigned char)0; //BrokerPath byte array not null ? false

	enc<<(unsigned char)0; //isBrokerMasterConnector bool  false

	enc<<(unsigned char)0; //isManageable bool  false

	enc<<(unsigned char)0; //isClientMaster bool  false

	enc<<(unsigned char)0; //isFaultTolerant bool  false

	enc<<(unsigned char)0; //isFailoverReconnect bool  false

	//enc<<(unsigned char)0; //ClientIp String   false  version > 8

	iLen = (int)enc.GetWriteLength();
	iTotalLen = iLen-4;

	CByteEncDec enc3(buf,iLen);
	enc3<<iTotalLen; //◊‹≥§∂»

	return iLen;

}

int CMQInstance::DecodeResponse(char buf[],int iLen,unsigned int &uiCommandId) //Ω‚ŒˆResponse√¸¡Ó
{
	int iTotalLen = 0;
	unsigned char ucType;
	unsigned int commandId;
	unsigned char ucNeedAck;
	CByteEncDec enc(buf,iLen);
	
	enc>>iTotalLen;         //◊‹≥§∂»
	enc>>ucType;            //¿‡–Õ
	enc>>commandId;         //command id
	enc>>ucNeedAck;         //need ack false
	enc>>uiCommandId;       //correlation id 

	return 0;
}

int CMQInstance::EncodeSessionInfo(char buf[],int &iLen) //¥Ú∞¸SESSION_INFO–≈¡Ó
{
	//std::string sessiontId = "ID:win12955-24867-1370570147688-0:0";
	//std::string clientId = "123456";
	//std::string password = "123456";
	//std::string username = "123456";
	int iTotalLen = 0;
	CByteEncDec enc(buf,iLen);
	
	enc<<iTotalLen; //◊‹≥§∂»
	enc<<(unsigned char)4; //type SESSION_INFO
	enc<<m_uiCommandId; //command id 1
	m_uiCommandId++;
	enc<<(unsigned char)0; //need response false

	//nest command SESSION_ID
	enc<<(unsigned char)1; //SESSION_ID exist ? true
	enc<<(unsigned char)121; //SESSION_ID type 121
	enc<<(unsigned char)1; //SESSION_ID not null true
	enc<<m_strConnectionId/*sessiontId*/; //SESSION_ID 

	enc<<(unsigned long long)0; //session value long long

	iLen = (int)enc.GetWriteLength();
	iTotalLen = iLen-4;

	CByteEncDec enc3(buf,iLen);
	enc3<<iTotalLen; //◊‹≥§∂»

	return iLen;
}

int CMQInstance::EncodeConsumerInfo(char buf[],int &iLen) //¥Ú∞¸CONSUMER_INFO–≈¡Ó
{
	//std::string consumerId = "ID:win12955-24867-1370570147688-0:0";
	//std::string topic = "zw.public.all.db,zw.public.single.vts.receive,zw.public.vthproxy.receive,test12,test13";
	//std::string clientId = "123456";
	//std::string password = "123456";
	//std::string username = "123456";
	int iTotalLen = 0;
	CByteEncDec enc(buf,iLen);
	
	enc<<iTotalLen; //◊‹≥§∂»
	enc<<(unsigned char)5; //type CONSUMER_INFO
	enc<<m_uiCommandId; //command id 1
	m_uiCommandId++;
	enc<<(unsigned char)1; //need response true

	//nest command CONSUMER_ID
	enc<<(unsigned char)1; //CONSUMER_ID exist ? true
	enc<<(unsigned char)122; //CONSUMER_ID type 122
	enc<<(unsigned char)1; //CONSUMER_ID not null true
	enc<<m_strConnectionId;/*consumerId*/; //CONSUMER_ID 
	enc<<(unsigned long long)0; //session id long long 
	enc<<(unsigned long long)0; //value long long 

	enc<<(unsigned char)0; //is browser false

	//enc<<(unsigned char)0; //connection id exist ? false

	//destination
	enc<<(unsigned char)1; //destination  exist ? true
	enc<<(unsigned char)101; //ACTIVEMQ_TOPIC  type  101
	enc<<(unsigned char)1; //ACTIVEMQ_TOPIC  is not null true
	enc<<m_strDestURI/*topic*/; //ACTIVEMQ_TOPIC

	enc<<(int)32766; //PrefetchSize  int

	enc<<(int)0; //MaximumPendingMessageLimit  0

	enc<<(unsigned char)1; //isDispatchAsync  bool true

	enc<<(unsigned char)0; //Selector  string is not null false

	enc<<(unsigned char)0; //SubscriptionName  string is not null false

	enc<<(unsigned char)0; //isNoLocal  bool false

	enc<<(unsigned char)0; //isExclusive  bool  false

	enc<<(unsigned char)0; //isRetroactive  bool false

	enc<<(unsigned char)0; //Priority  unsigned char 0

	enc<<(unsigned char)0; //BrokerPath byte array is not null false

	enc<<(unsigned char)0; //AdditionalPredicate not exist

	enc<<(unsigned char)0; //isNetworkSubscription bool false

	enc<<(unsigned char)0; //isOptimizedAcknowledge bool false

	enc<<(unsigned char)0; //isNoRangeAcks bool false

	enc<<(unsigned char)0; //NetworkConsumerPathbyte array is not null false version > 4

	iLen = (int)enc.GetWriteLength();
	iTotalLen = iLen-4;

	CByteEncDec enc3(buf,iLen);
	enc3<<iTotalLen; //◊‹≥§∂»

	return iLen;

}

int CMQInstance::EncodeProducerInfo(char buf[],int &iLen) //¥Ú∞¸PRODUCER_INFO–≈¡Ó
{
	//std::string producerId = "ID:win12955-24867-1370570147688-0:0";
	//std::string clientId = "123456";
	//std::string password = "123456";
	//std::string username = "123456";
	int iTotalLen = 0;
	CByteEncDec enc(buf,iLen);
	
	enc<<iTotalLen; //◊‹≥§∂»
	enc<<(unsigned char)6; //type PRODUCER_INFO
	enc<<m_uiCommandId; //command id 1
	m_uiCommandId++;
	enc<<(unsigned char)0; //need response false

	//nest command PRODUCER_ID
	enc<<(unsigned char)1; //PRODUCER_ID exist ? true
	enc<<(unsigned char)123; //PRODUCER_ID type 123
	enc<<(unsigned char)1; //PRODUCER_ID not null true
	enc<<m_strConnectionId/*producerId*/; //connection id
	enc<<(unsigned long long)0; //value long long
	enc<<(unsigned long long)0; //session id long long

	//destination
	enc<<(unsigned char)0; //destination  exist ? false

	//BrokerPath
	enc<<(unsigned char)0; //BrokerPath  exist ? false

	enc<<(unsigned char)0; //isDispatchAsync  bool  false

	enc<<(int)0; //WindowSize  int


	iLen = (int)enc.GetWriteLength();
	iTotalLen = iLen-4;

	CByteEncDec enc3(buf,iLen);
	enc3<<iTotalLen; //◊‹≥§∂»

	return iLen;

}



int CMQInstance::EncodeMapMsg(char buf[],int &iLen,char msg[],int msgLen,char topic[],char cmsType[]) //¥Ú∞¸ACTIVEMQ_MAP_MESSAGE–≈¡Ó
{
	//std::string producerId = "ID:win12955-24867-1370570147688-0:0";
	//std::string topic = "zw.public.all.devicestatus";
	unsigned long long timestamp = currentTimeMillis();
	//std::string msgType = "16777216";

	//int msgSize =0;
	//char msgContent[32] = {0};

	//int propertiesSize =0;
	//char propertiesContent[32] = {0};

	//std::string clientId = "123456";
	//std::string password = "123456";
	//std::string username = "123456";
	int iTotalLen = 0;
	CByteEncDec enc(buf,iLen);
	
	enc<<iTotalLen; //◊‹≥§∂»
	enc<<(unsigned char)25; //type ACTIVEMQ_MAP_MESSAGE
	enc<<m_uiCommandId; //command id 1
	m_uiCommandId++;
	enc<<(unsigned char)0; //need response false

	//nest command PRODUCER_ID
	enc<<(unsigned char)1; //PRODUCER_ID exist ? true
	enc<<(unsigned char)123; //PRODUCER_ID type 123
	enc<<(unsigned char)1; //PRODUCER_ID not null true
	enc<<m_strConnectionId/*producerId*/; //connection id
	enc<<(unsigned long long)0; //value long long
	enc<<(unsigned long long)0; //session id long long

	//ACTIVEMQ_TOPIC
	enc<<(unsigned char)1; //destination  exist ? true
	enc<<(unsigned char)101; //ACTIVEMQ_TOPIC type 101
	enc<<(unsigned char)1; //ACTIVEMQ_TOPIC not null true
	enc<<topic; //topic PhysicalName

	//TransactionId
	enc<<(unsigned char)0; //TransactionId  exist ? false
	//enc<<(unsigned char)101; //ACTIVEMQ_TOPIC type 101
	//enc<<(unsigned char)1; //ACTIVEMQ_TOPIC not null true
	//enc<<topic; //topic PhysicalName

	//OriginalDestination
	enc<<(unsigned char)0; //OriginalDestination  exist ? false

	//MESSAGE_ID
	enc<<(unsigned char)1; //OriginalDestination  exist ? true
	enc<<(unsigned char)110; //MESSAGE_ID type 110
	//enc<<(unsigned char)1; //ACTIVEMQ_TOPIC not null true
	//enc<<topic; //topic PhysicalName

	//ProducerId
	enc<<(unsigned char)1; //PRODUCER_ID  exist ? true
	enc<<(unsigned char)123; //PRODUCER_ID type 123
	enc<<(unsigned char)1; //PRODUCER_ID  not null true
	enc<<m_strConnectionId/*producerId*/; //PRODUCER_ID
	enc<<(unsigned long long)0; //value long long
	enc<<(unsigned long long)0; //session id long long
	enc<<(unsigned long long)0; //ProducerSequenceId long long
	enc<<(unsigned long long)0; //BrokerSequenceId long long


	//OriginalTransactionId
	enc<<(unsigned char)0; //OriginalTransactionId  exist ? false

	//GroupID
	enc<<(unsigned char)0; //GroupID  exist ? false

	//GroupSequence
	enc<<(unsigned int)0; //GroupSequence  int

	//CorrelationId
	enc<<(unsigned char)0; //CorrelationId  string not null false

	//isPersistent
	enc<<(unsigned char)0; //isPersistent  bool false


	//Expiration
	enc<<(unsigned long long)0; //Expiration  long long

	//Priority
	enc<<(unsigned char)4; //Priority  unsigned char 4

	//ReplyTo
	enc<<(unsigned char)0; //ReplyTo  exist ? false

	//Timestamp
	enc<<(unsigned long long)timestamp; //Timestamp  long long

	//type
	enc<<(unsigned char)1; //type  string is not null ? true
	enc<<cmsType/*msgType*/; //msg type  string 

	//msg content
	enc<<(unsigned char)1; //msg content  is not null ? true
	enc<<(unsigned int)msgLen; //msg content  size int
	enc.Write(msg,msgLen); //msg content œ˚œ¢ÃÂ

	//msg properties
	enc<<(unsigned char)0; //msg properties  is not null ? false
	//enc<<(unsigned int)propertiesSize; //msg properties  size int
	//enc.Write(propertiesContent,propertiesSize); //msg properties œ˚œ¢Õ∑

	enc<<(unsigned char)0; //DataStructure  is not null ? false

	//TargetConsumerId
	enc<<(unsigned char)0; //TargetConsumerId  is not null ? false

	enc<<(unsigned char)0; //isCompressed  bool false

	//RedeliveryCounter
	enc<<(unsigned int)0; //RedeliveryCounter  int

	//BrokerPath
	enc<<(unsigned char)0; //BrokerPath  is not null ? false

	//Arrival
	enc<<(unsigned long long)0; //Arrival  long long

	//UserID
	enc<<(unsigned char)0; //UserID  string is not null ? false

	//isRecievedByDFBridge
	enc<<(unsigned char)0; //isRecievedByDFBridge  bool false

	//isDroppable
	enc<<(unsigned char)0; //isDroppable  bool false

	//Cluster
	enc<<(unsigned char)0; //Cluster  ObjecrArray is not null ? false

	//BrokerInTime
	enc<<(unsigned long long)0; //BrokerInTime  long long

	//BrokerOutTime
	enc<<(unsigned long long)0; //BrokerOutTime  long long

	iLen = (int)enc.GetWriteLength();
	iTotalLen = iLen-4;

	CByteEncDec enc3(buf,iLen);
	enc3<<iTotalLen; //◊‹≥§∂»

	return iLen;
}

int CMQInstance::EncodeTextMsg(char buf[],int &iLen,char msg[],int msgLen,char topic[],char cmsType[]) //¥Ú∞¸ACTIVEMQ_TEXT_MESSAGE–≈¡Ó
{
	//std::string producerId = "ID:win12955-24867-1370570147688-0:0";
	//std::string topic = "zw.public.all.devicestatus";
	unsigned long long timestamp = currentTimeMillis();
	//std::string msgType = "16777216";

	//int msgSize =0;
	//char msgContent[32] = {0};

	//int propertiesSize =0;
	//char propertiesContent[32] = {0};

	//std::string clientId = "123456";
	//std::string password = "123456";
	//std::string username = "123456";
	int iTotalLen = 0;
	CByteEncDec enc(buf,iLen);
	
	enc<<iTotalLen; //◊‹≥§∂»
	enc<<(unsigned char)28; //type ACTIVEMQ_TEXT_MESSAGE
	enc<<m_uiCommandId; //command id 1
	m_uiCommandId++;
	enc<<(unsigned char)0; //need response false

	//nest command PRODUCER_ID
	enc<<(unsigned char)1; //PRODUCER_ID exist ? true
	enc<<(unsigned char)123; //PRODUCER_ID type 123
	enc<<(unsigned char)1; //PRODUCER_ID not null true
	enc<<m_strConnectionId/*producerId*/; //connection id
	enc<<(unsigned long long)0; //value long long
	enc<<(unsigned long long)0; //session id long long

	//ACTIVEMQ_TOPIC
	enc<<(unsigned char)1; //destination  exist ? true
	enc<<(unsigned char)101; //ACTIVEMQ_TOPIC type 101
	enc<<(unsigned char)1; //ACTIVEMQ_TOPIC not null true
	enc<<topic; //topic PhysicalName

	//TransactionId
	enc<<(unsigned char)0; //TransactionId  exist ? false
	//enc<<(unsigned char)101; //ACTIVEMQ_TOPIC type 101
	//enc<<(unsigned char)1; //ACTIVEMQ_TOPIC not null true
	//enc<<topic; //topic PhysicalName

	//OriginalDestination
	enc<<(unsigned char)0; //OriginalDestination  exist ? false

	//MESSAGE_ID
	enc<<(unsigned char)1; //OriginalDestination  exist ? true
	enc<<(unsigned char)110; //MESSAGE_ID type 110
	//enc<<(unsigned char)1; //ACTIVEMQ_TOPIC not null true
	//enc<<topic; //topic PhysicalName

	//ProducerId
	enc<<(unsigned char)1; //PRODUCER_ID  exist ? true
	enc<<(unsigned char)123; //PRODUCER_ID type 123
	enc<<(unsigned char)1; //PRODUCER_ID  not null true
	enc<<m_strConnectionId/*producerId*/; //PRODUCER_ID
	enc<<(unsigned long long)0; //value long long
	enc<<(unsigned long long)0; //session id long long
	enc<<(unsigned long long)0; //ProducerSequenceId long long
	enc<<(unsigned long long)0; //BrokerSequenceId long long


	//OriginalTransactionId
	enc<<(unsigned char)0; //OriginalTransactionId  exist ? false

	//GroupID
	enc<<(unsigned char)0; //GroupID  exist ? false

	//GroupSequence
	enc<<(unsigned int)0; //GroupSequence  int

	//CorrelationId
	enc<<(unsigned char)0; //CorrelationId  string not null false

	//isPersistent
	enc<<(unsigned char)0; //isPersistent  bool false


	//Expiration
	enc<<(unsigned long long)0; //Expiration  long long

	//Priority
	enc<<(unsigned char)4; //Priority  unsigned char 4

	//ReplyTo
	enc<<(unsigned char)0; //ReplyTo  exist ? false

	//Timestamp
	enc<<(unsigned long long)timestamp; //Timestamp  long long

	//type
	enc<<(unsigned char)1; //type  string is not null ? true
	enc<<cmsType/*msgType*/; //msg type  string 

	//msg content
	enc<<(unsigned char)1; //msg content  is not null ? true
	enc<<(unsigned int)(msgLen+4); //msg content  size int
	enc<<(unsigned int)msgLen; //msg content  size int
	enc.Write(msg,msgLen); //msg content œ˚œ¢ÃÂ

	//msg properties
	enc<<(unsigned char)0; //msg properties  is not null ? false
	//enc<<(unsigned int)propertiesSize; //msg properties  size int
	//enc.Write(propertiesContent,propertiesSize); //msg properties œ˚œ¢Õ∑

	enc<<(unsigned char)0; //DataStructure  is not null ? false

	//TargetConsumerId
	enc<<(unsigned char)0; //TargetConsumerId  is not null ? false

	enc<<(unsigned char)0; //isCompressed  bool false

	//RedeliveryCounter
	enc<<(unsigned int)0; //RedeliveryCounter  int

	//BrokerPath
	enc<<(unsigned char)0; //BrokerPath  is not null ? false

	//Arrival
	enc<<(unsigned long long)0; //Arrival  long long

	//UserID
	enc<<(unsigned char)0; //UserID  string is not null ? false

	//isRecievedByDFBridge
	enc<<(unsigned char)0; //isRecievedByDFBridge  bool false

	//isDroppable
	enc<<(unsigned char)0; //isDroppable  bool false

	//Cluster
	enc<<(unsigned char)0; //Cluster  ObjecrArray is not null ? false

	//BrokerInTime
	enc<<(unsigned long long)0; //BrokerInTime  long long

	//BrokerOutTime
	enc<<(unsigned long long)0; //BrokerOutTime  long long

	iLen = (int)enc.GetWriteLength();
	iTotalLen = iLen-4;

	CByteEncDec enc3(buf,iLen);
	enc3<<iTotalLen; //◊‹≥§∂»

	return iLen;
}

class BasicValue
{
public:
	BasicValue()
	{
		type = -1;
		v.str = 0;
	}
	BasicValue(int value)
	{
		type = 5;
		v.i = value;
	}
	BasicValue(long long value)
	{
		type = 6;
		v.l = value;
	}
	BasicValue(std::string value)
	{
		type = 9;
		//value.str = value;
		//v.str = new std::string( value );
		v.str = 0;
	}
	~BasicValue()
	{
		if ( 9 == type && v.str )
		{
			delete v.str;
		}
	}
	//BasicValue& BasicValue::operator =( const BasicValue& node )
	//{
	//	clear();
	//	this->setValue( node.getValue(), node.getType() );
	//	return *this;
	//}

	char type;
	union Value
	{
		//bool b;
		//char c;
		//unsigned char b;
		//short s;
		int i;
		long long l;
		float f;
		std::string *str;
	};
	Value v;
};

class MapMessage
{
public:
	
	std::map<std::string,BasicValue> mapValue;

	int getInt(const std::string name)
	{
		//if ( mapValue.find(name) )
		{
			return mapValue[name].v.i;
		}
	}
	//int getInt(const char name[])
	//{
	//}
	long long getLong(const std::string name)
	{
		if ( mapValue.find(name) != mapValue.end() )
		{
			return mapValue[name].v.l;
		}
		return 0;
		//return mapValue[name].v.l;
	}
	//long long int getLong(const char name[])
	//{
	//	//return 0;
	//	//return mapValue[name].v.l;
	//}
	std::string getString(const std::string name)
	{
		std::string strTemp;
		if ( mapValue[name].v.str )
		{
			strTemp = *mapValue[name].v.str;
			return strTemp;
		}
		else
		{
			return std::string();
		}
		//return mapValue[name].v.str == 0 ? std::string() : *mapValue[name].v.str;
	}

	void setInt(const std::string name,const int value)
	{
		mapValue[name] = BasicValue(value);
	}
	void setLong(const std::string name,const long long value)
	{
		mapValue[name] = BasicValue(value);
	}
	void setString(const std::string name,const std::string value)
	{
		mapValue[name] = BasicValue(value);
		mapValue[name].v.str = new std::string( value );
	}
};


int CMQInstance::DecodeDispatchtMsg(char buf[],int &iLen) //Ω‚∞¸MESSAGE_DISPATCH–≈¡Ó
{
	//MQ_CALLBACK_INFO msgInfo2;
	//MQ_DEVICE_ADD devInfo2;
	////LPMQ_DEVICE_ADD pAdd = new MQ_DEVICE_ADD;
	//devInfo2.llDeviceId =123;           //…Ë±∏±‡∫≈
	////long long temp_111 = mapde.getLong("lAreaCode");
	//devInfo2.llAreaCode = 456;//mapde.getLong("lAreaCode");           //◊È÷Ø±‡¬Î
	////pAdd->llAreaCode = 123;
	////printf("lAreaCode %lld\n",devInfo.llAreaCode);
	//strcpy(devInfo2.szDeviceName,"123");  //…Ë±∏±‡∫≈
	//devInfo2.iHasVideo = 0;            // «∑Ò”µ”– ”∆µ
	////MQ_CALLBACK_INFO msgInfo2;
	//if ( m_fcbStack )
	//{
	//	msgInfo2.iType = emMqMsgDeviceAdd; //…Ë±∏ÃÌº”Õ®÷™
	//	msgInfo2.pstDevAdd = &devInfo2;
	//	m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo2);
	//	//msgInfo2.iType = emMqMsgDeviceAdd; //…Ë±∏ÃÌº”Õ®÷™
	//	//msgInfo2.pstDevAdd = &devInfo;
	//	//m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo2);
	//}
	//return 0;
	
	//INFO_TRACE("Enter");

	int iTotalLen = 0;
	unsigned char ucType;
	unsigned int commandId;
	unsigned char ucNeedAck;
	unsigned char ucIsNotNull;
	std::string topic;
	char msgType;
	std::string consumerId;
	unsigned long long value;
	unsigned long long sessionId;
	unsigned long long ProducerSequenceId,BrokerSequenceId;

	CByteEncDec enc(buf,iLen);
	//unsigned char ucIsNorNull;

	enc>>iTotalLen;         //◊‹≥§∂»
	enc>>ucType;            //¿‡–Õ
	if ( 21 != ucType ) //≤ª « MESSAGE_DISPATCHœ˚œ¢
	{
		ERROR_TRACE("msg type invalid");
		return -1;
	}
	enc>>commandId;         //command id
	enc>>ucNeedAck;         //need ack false

	//ConsumerId
	enc>>ucIsNotNull;       //ConsumerId is not null true 
	if ( 1 == ucIsNotNull )
	{
		enc>>ucType;       //type CONSUMER_ID 122 unsigned char 
		if ( 122 != ucType ) //≤ª «CONSUMER_ID
		{
			//¥ÌŒÛ
		}
		enc>>ucIsNotNull;       //CONSUMER_ID is not null bool true
		if ( 1 != ucIsNotNull ) //CONSUMER_IDƒ⁄»›Œ™ø’
		{
			//¥ÌŒÛ
		}
		enc>>consumerId;       //CONSUMER_ID is string
		enc>>value;              //value long long 
		enc>>sessionId;       //sessionId long long

	}

	//ACTIVEMQ_TOPIC
	enc>>ucIsNotNull;       //ACTIVEMQ_TOPIC is not null true 
	if ( 1 == ucIsNotNull )
	{
		enc>>ucType;       //type ACTIVEMQ_TOPIC 101 unsigned char 
		if ( 101 != ucType ) //≤ª «ACTIVEMQ_TOPIC
		{
			//¥ÌŒÛ
		}
		enc>>ucIsNotNull;       //CONSUMER_ID is not null bool true
		if ( 1 != ucIsNotNull ) //CONSUMER_IDƒ⁄»›Œ™ø’
		{
			//¥ÌŒÛ
		}
		enc>>topic;       //topic string
	}

	//msg
	enc>>ucIsNotNull;       //msg is not null true 
	if ( 1 != ucIsNotNull ) //œ˚œ¢Œ™ø’
	{
		//¥ÌŒÛ
	}

	//msg type
	enc>>ucType;       //msg type
	if ( 25 == ucType ) //ACTIVEMQ_MAP_MESSAGE
	{
		msgType = 25;
	}
	else if ( 28 == ucType ) //ACTIVEMQ_TEXT_MESSAGE
	{
		msgType = 28;
	}
	else if ( 24 == ucType ) //ACTIVEMQ_BYTES_MESSAGE
	{
		msgType = 24;
	}
	else //∆‰À˚œ˚œ¢¿‡–Õ,µ±«∞≤ª¥¶¿Ì
	{
		INFO_TRACE("msg type not consider");
		return 0;
	}

	enc>>commandId; //command if int
	enc>>ucNeedAck; //need ack

	//nest command PRODUCER_ID
	enc>>ucIsNotNull; //PRODUCER_ID exist ? true
	enc>>ucType; //PRODUCER_ID type 123
	enc>>ucIsNotNull; //PRODUCER_ID not null true
	std::string producerId;
	//unsigned long long value;
	//unsigned long long sessionid;
	enc>>producerId; //connection id
	enc>>value; //value long long
	enc>>sessionId; //session id long long

	//ACTIVEMQ_TOPIC
	enc>>ucIsNotNull; //destination  exist ? true
	enc>>ucType; //ACTIVEMQ_TOPIC type 101
	enc>>ucIsNotNull; //ACTIVEMQ_TOPIC not null true
	enc>>topic; //topic PhysicalName

	//TransactionId
	enc>>ucIsNotNull; //TransactionId  exist ? false
	//enc<<(unsigned char)101; //ACTIVEMQ_TOPIC type 101
	//enc<<(unsigned char)1; //ACTIVEMQ_TOPIC not null true
	//enc<<topic; //topic PhysicalName

	//OriginalDestination
	enc>>ucIsNotNull; //OriginalDestination  exist ? false

	//MESSAGE_ID
	enc>>ucIsNotNull; //OriginalDestination  exist ? true
	enc>>ucType; //MESSAGE_ID type 110
	//enc<<(unsigned char)1; //ACTIVEMQ_TOPIC not null true
	//enc<<topic; //topic PhysicalName

	//nested ProducerId
	enc>>ucIsNotNull; //PRODUCER_ID  exist ? true
	enc>>ucType; //PRODUCER_ID type 123
	enc>>ucIsNotNull; //PRODUCER_ID  not null true
	enc>>producerId; //PRODUCER_ID
	enc>>value; //value long long
	enc>>sessionId; //session id long long
	enc>>ProducerSequenceId; //ProducerSequenceId long long
	enc>>BrokerSequenceId; //BrokerSequenceId long long


	//OriginalTransactionId
	enc>>ucIsNotNull; //OriginalTransactionId  exist ? false

	//GroupID
	enc>>ucIsNotNull; //GroupID  exist ? false

	//GroupSequence
	int GroupSequence;
	enc>>GroupSequence; //GroupSequence  int

	//CorrelationId
	//int CorrelationId;
	enc>>ucIsNotNull; //CorrelationId  string not null false

	//isPersistent
	unsigned char isPersistent;
	enc>>isPersistent; //isPersistent  bool false


	//Expiration
	unsigned long long Expiration;
	enc>>Expiration; //Expiration  long long

	//Priority
	unsigned char Priority;
	enc>>Priority; //Priority  unsigned char 4

	//ReplyTo
	enc>>ucIsNotNull; //ReplyTo  exist ? false

	//Timestamp
	unsigned long long Timestamp;
	enc>>Timestamp; //Timestamp  long long

	//type
	std::string cmsType;
	enc>>ucIsNotNull; //type  string is not null ? true
	enc>>cmsType/*msgType*/; //msg type  string 

#if 1  //‘› ±≤ª–Ë“™∑¢ÀÕ»∑»œ÷°
	//∑¢ÀÕœ˚œ¢»∑»œ÷°
	//if ( m_bClientAck ) //–Ë“™»∑»œ
	{
		char buf2[1024];
		int iDataLen2 =1024;
		int iAckLen;
		iAckLen = EncodeMsgAck(buf2,iDataLen2,producerId,consumerId,topic,ProducerSequenceId,BrokerSequenceId);
		int iSendLen = SendData(buf2,iAckLen);
	}
#endif

	//msg content
	unsigned int msgLen;
	enc>>ucIsNotNull; //msg content  is not null ? true
	enc>>msgLen; //msg content  size int
	if ( 25 == msgType ) //ACTIVEMQ_MAP_MESSAGE
	{
		//if ( == iMsgType )
		//{
		//}

		int iItems;
		enc>>iItems; //item count
		PrimitiveMap/*MapMessage*/ mapde;
		int iValue;
		long long llValue;
		std::string strValue;
		//Ω‚Œˆ∫Õ¥¶¿Ìmapœ˚œ¢
		for(int i=0;i<iItems;i++)
		{
			std::string name;
			enc>>name; //item name
			enc>>ucType; //item value type
			//item value
			if ( 5 == ucType ) //int
			{
				enc>>iValue;
				mapde.setInt(name,iValue);
			}
			else if ( 6 == ucType ) //long
			{
				enc>>llValue;
				mapde.setLong(name,llValue);
			}
			else if ( 9 == ucType ) //string
			{
				enc>>strValue;
				mapde.setString(name,strValue);
			}
			
		}

		//
		int iMsgType = atoi(cmsType.c_str());
		MQ_CALLBACK_INFO msgInfo;
		switch ( iMsgType )
		{
		case emMSGDeviceState:   //…Ë±∏◊¥Ã¨±‰ªØ
			{
				MQ_DEVICE_STATE devState;
				devState.llDeviceId = mapde.getLong("lDeviceId"); //…Ë±∏±‡∫≈
				devState.iDeviceType = mapde.getInt("iDevType");  //…Ë±∏¿‡–Õ
				devState.iStatus = mapde.getInt("iStatus");       //…Ë±∏◊¥Ã¨
				devState.iTime = mapde.getInt("iTime");           //∑¢…˙ ±º‰

				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgDeviceState; //…Ë±∏◊¥Ã¨Õ®÷™
					msgInfo.pstDevState = &devState;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		//case emMSGAlarm:         //…Ë±∏±®æØ
		case emMSGAlarmVTMC:   //VTMC…Ë±∏∂©‘ƒµƒ±®æØ±®æØ
			{
				MQ_ALARM_INFO alarmInfo;
				alarmInfo.llDeviceId = mapde.getLong("lDeviceId");      //…Ë±∏±‡∫≈
				alarmInfo.iDeviceType = mapde.getInt("iDevType");       //…Ë±∏¿‡–Õ
				alarmInfo.iAlarmTime = mapde.getInt("iAlarmTime");     //±®æØ ±º‰
				alarmInfo.iAlarmType = mapde.getInt("iAlarmType");     //±®æØ¿‡–Õ
				alarmInfo.iAlarmStatus = mapde.getInt("iAlarmStatus"); //±®æØ◊¥Ã¨
				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgDeviceAlarm; //±®æØÕ®÷™
					msgInfo.pstAlarmInfo = &alarmInfo;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		//case emMSGAlarmDSMC:   //DSMC…Ë±∏∂©‘ƒµƒ±®æØ±®æØ
			////////////ACMS∆ΩÃ®œ˚œ¢//////////////////
		case emMSGAlarmACMC:   //ACMC…Ë±∏∂©‘ƒµƒ±®æØ±®æØ
			{
				MQ_ACMS_ALARM_NOTIFY_INFO alarmInfo;

				alarmInfo.llChannelId = mapde.getLong("lChanId");    //Õ®µ¿±‡∫≈
				alarmInfo.iAlarmTime = mapde.getInt("iAlarmTime");   //±®æØ∑¢…˙ ±º‰
				alarmInfo.iAlarmType = mapde.getInt("iAlarmType");   //±®æØ¿‡–Õ
#ifdef WIN32
				Utf8ToAnsi(mapde.getString("sAlarmType").c_str(),
					alarmInfo.szAlarmType,
					mapde.getString("sAlarmType").size()+1);//±®æØ¿‡–Õ
#else
				strcpy(alarmInfo.szAlarmType,mapde.getString("sAlarmType").c_str());  //±®æØ¿‡–Õ
#endif
				alarmInfo.iAlarmStatus = mapde.getInt("iAlarmStatus");//±®æØ◊¥Ã¨
#ifdef WIN32
				Utf8ToAnsi(mapde.getString("sAlarmStatus").c_str(),
					alarmInfo.szAlarmStatus,
					mapde.getString("sAlarmStatus").size()+1);//±®æØ◊¥Ã¨
#else
				strcpy(alarmInfo.szAlarmStatus,mapde.getString("sAlarmStatus").c_str());  //±®æØ◊¥Ã¨
#endif
				alarmInfo.iReserv1 = mapde.getInt("iReserve1");      //±£¡Ù◊÷∂Œ
#ifdef WIN32
				Utf8ToAnsi(mapde.getString("sReserve2").c_str(),
					alarmInfo.szReserv2,mapde.getString("sReserve2").size()+1);//±£¡Ù◊÷∂Œ
#else
				strcpy(alarmInfo.szReserv2,mapde.getString("sReserve2").c_str());  //±£¡Ù◊÷∂Œ
#endif

				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgAcmsAlarmNotify; //ACMS∆ΩÃ®±®æØÕ®÷™
					msgInfo.pstAcmsAlarmNotify = &alarmInfo;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
			////////////ACMS∆ΩÃ®œ˚œ¢//////////////////
		//case emMSGAlarmUCMC:   //UCMC…Ë±∏∂©‘ƒµƒ±®æØ±®æØ
		//case emMSGAlarmICMC:   //ICMC…Ë±∏∂©‘ƒµƒ±®æØ±®æØ
		//case emMSGDatabaseModify:   // ˝æ›ø‚±‰ªØ

		//case emMSGDbDeviceModify:   //…Ë±∏±‰ªØ
		case emMSGDbDevDelete:   //…Ë±∏…æ≥˝
			{
				MQ_DEVICE_DELETE devInfo;
				devInfo.llDeviceId = mapde.getLong("lDeviceId");      //…Ë±∏±‡∫≈
				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgDeviceDelete; //…Ë±∏…æ≥˝Õ®÷™
					msgInfo.pstDevDelete = &devInfo;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		case emMSGDbDevAdd:   //…Ë±∏ÃÌº”
			{
				MQ_DEVICE_ADD devInfo;
				//LPMQ_DEVICE_ADD pAdd = new MQ_DEVICE_ADD;
				devInfo.llDeviceId = mapde.getLong("lDeviceId");           //…Ë±∏±‡∫≈
				//long long temp_111 = mapde.getLong("lAreaCode");
				devInfo.llAreaCode = mapde.getLong("lAreaCode");           //◊È÷Ø±‡¬Î
				//pAdd->llAreaCode = 123;
				//printf("lAreaCode %lld\n",devInfo.llAreaCode);
				strcpy(devInfo.szDeviceName,mapde.getString("sDevName").c_str());  //…Ë±∏±‡∫≈
				devInfo.iHasVideo = mapde.getInt("iDevVideo");            // «∑Ò”µ”– ”∆µ
				//MQ_CALLBACK_INFO msgInfo2;
				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgDeviceAdd; //…Ë±∏ÃÌº”Õ®÷™
					msgInfo.pstDevAdd = &devInfo;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
					//msgInfo2.iType = emMqMsgDeviceAdd; //…Ë±∏ÃÌº”Õ®÷™
					//msgInfo2.pstDevAdd = &devInfo;
					//m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo2);
				}
				break;
			}
		case emMSGDbDevUpdate:   //…Ë±∏–ﬁ∏ƒ
			{
				MQ_DEVICE_UPDATE devInfo;
				devInfo.llDeviceId = mapde.getLong("lDeviceId");           //…Ë±∏±‡∫≈
				devInfo.llAreaCode = mapde.getLong("lAreaCode");           //◊È÷Ø±‡¬Î
				strcpy(devInfo.szDeviceName,mapde.getString("sDevName").c_str());  //…Ë±∏±‡∫≈
				devInfo.iHasVideo = mapde.getInt("iDevVideo");            // «∑Ò”µ”– ”∆µ
				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgDeviceUpdate; //…Ë±∏–ﬁ∏ƒÕ®÷™
					msgInfo.pstDevUpdate = &devInfo;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}

		//case emMSGChannelModify:   //Õ®µ¿±‰ªØ
		case emMSGChannelDelete:   //Õ®µ¿…æ≥˝
			{
				MQ_CHANNEL_DELETE info;
				info.llChannelId = mapde.getLong("lChanId");               //Õ®µ¿±‡∫≈
				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgChannelDelete; //Õ®µ¿…æ≥˝Õ®÷™
					msgInfo.pstChannelDelete = &info;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		case emMSGChannelAdd:   //Õ®µ¿ÃÌº”
			{
				MQ_CHANNEL_ADD info;
				info.llChannelId = mapde.getLong("lChanId");                     //Õ®µ¿±‡∫≈
				info.llAreaCode = mapde.getLong("lAreaCode");                    //◊È÷Ø±‡¬Î
#ifdef WIN32
				Utf8ToAnsi(mapde.getString("sChanName").c_str(),info.szChanName,mapde.getString("sChanName").size()+1);//Õ®µ¿√˚≥∆
#else
				strcpy(info.szChanName,mapde.getString("sChanName").c_str());  //Õ®µ¿√˚≥∆
#endif
				info.iAppProperties = mapde.getInt("iAppProperties");           //Õ®µ¿π¶ƒ‹
				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgChannelAdd; //Õ®µ¿ÃÌº”Õ®÷™
					msgInfo.pstChannelAdd = &info;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		case emMSGChannelUpdate:   //Õ®µ¿–ﬁ∏ƒ
			{
				MQ_CHANNEL_UPDATE info;
				info.llChannelId = mapde.getLong("lChanId");                     //Õ®µ¿±‡∫≈
				info.llAreaCode = mapde.getLong("lAreaCode");                    //◊È÷Ø±‡¬Î
#ifdef WIN32
				Utf8ToAnsi(mapde.getString("sChanName").c_str(),info.szChanName,mapde.getString("sChanName").size()+1);//Õ®µ¿√˚≥∆
#else
				strcpy(info.szChanName,mapde.getString("sChanName").c_str());  //Õ®µ¿√˚≥∆
#endif
				info.iAppProperties = mapde.getInt("iAppProperties");           //Õ®µ¿π¶ƒ‹
				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgChannelUpdate; //Õ®µ¿∏¸–¬Õ®÷™
					msgInfo.pstChannelUpdate = &info;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		//case emMSGChannelAppModify:   //Õ®µ¿”¶”√±‰ªØ
		case emMSGChannelAppDelete:   //Õ®µ¿”¶”√…æ≥˝
			{
				MQ_CHANNEL_APP_DELETE info;
				info.iAppId = mapde.getInt("iAppId");                       //Õ®µ¿”¶”√±‡∫≈
				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgChannelAppDelete; //Õ®µ¿”¶”√…æ≥˝Õ®÷™
					msgInfo.pstChannelAppDelete = &info;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		case emMSGChannelAppAdd:   //Õ®µ¿”¶”√ÃÌº”
			{
				MQ_CHANNEL_APP_ADD info;
				info.iAppId = mapde.getInt("iAppId");                            //Õ®µ¿”¶”√±‡∫≈
				info.llChannelId = mapde.getLong("lChanId");                     //Õ®µ¿±‡∫≈
				info.llDeviceId = mapde.getLong("lDeviceId");                    //…Ë±∏±‡∫≈
				info.iDevChan = mapde.getInt("iDevChan");                        //Õ®µ¿∫≈
				info.iAppType = mapde.getInt("iAppType");                        //”¶”√¿‡–Õ
				info.iAppDetailProperties = mapde.getInt("iAppDetailProperties");//”¶”√¿‡–ÕœÍœ∏÷µ
				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgChannelAppAdd; //Õ®µ¿ÃÌº”Õ®÷™
					msgInfo.pstChannelAppAdd = &info;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		case emMSGChannelAppUpdate:   //Õ®µ¿”¶”√–ﬁ∏ƒ
			{
				MQ_CHANNEL_APP_UPDATE info;
				info.iAppId = mapde.getInt("iAppId");                            //Õ®µ¿”¶”√±‡∫≈
				info.llChannelId = mapde.getLong("lChanId");                     //Õ®µ¿±‡∫≈
				info.llDeviceId = mapde.getLong("lDeviceId");                    //…Ë±∏±‡∫≈
				info.iDevChan = mapde.getInt("iDevChan");                        //Õ®µ¿∫≈
				info.iAppType = mapde.getInt("iAppType");                        //”¶”√¿‡–Õ
				info.iAppDetailProperties = mapde.getInt("iAppDetailProperties");//”¶”√¿‡–ÕœÍœ∏÷µ
				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgChannelAppUpdate; //Õ®µ¿ÃÌº”Õ®÷™
					msgInfo.pstChannelAppUpdate = &info;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}

		case emMSGVehPassInfo:   //≥µ¡æ≥ˆ»ÎÕ®÷™
			{
				MQ_VEHICLE_PASS_INFO vehInfo;

				strcpy(vehInfo.szDevNo,mapde.getString("sDevNo").c_str());                         //…Ë±∏Œ®“ª±Í ∂
				vehInfo.iChannel = mapde.getInt("iChannel");                                       //Õ®µ¿∫≈

				vehInfo.iOccurTime = mapde.getInt("iOccurTime");                                   //∑¢…˙»’∆⁄
				strcpy(vehInfo.szPlateNum,mapde.getString("sPlateNum").c_str());                   //≥µ≈∆∫≈
				strcpy(vehInfo.szPicUrl,mapde.getString("sPicUrl").c_str());                       //Õº∆¨µƒ∑√Œ ¬∑æ∂
				strcpy(vehInfo.sVehPlateLocation,mapde.getString("sVehPlateLocation").c_str());    //≥µ≈∆‘⁄≥µ¡æÕº∆¨…œµƒŒª÷√
				vehInfo.iPlateColor = mapde.getInt("iPlateColor");                                 //≥µ≈∆—’…´
				vehInfo.iVehColor = mapde.getInt("iVehColor");                                     //≥µ¡æ—’…´

				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgVehiclePassInfo; //≥µ¡æÕ®π˝Õ®÷™
					msgInfo.pstVehPassInfo = &vehInfo;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		case emMSGEecNoticeInfo:   //≥ˆ»Îø⁄π‹¿Ì…Ë±∏œ˚œ¢Õ®÷™
			{
				MQ_EEC_NOTICE_INFO eecInfo;
#ifdef WIN32
				Utf8ToAnsi(mapde.getString("sPlateNum").c_str(),eecInfo.szPlateNum,mapde.getString("sPlateNum").size()+1);
#else
				strcpy(eecInfo.szPlateNum,mapde.getString("sPlateNum").c_str());                //≥µ≈∆∫≈
#endif
#ifdef WIN32
				Utf8ToAnsi(mapde.getString("sVisitorName").c_str(),eecInfo.szVisitorName,mapde.getString("sVisitorName").size()+1); //πÛ±ˆ√˚≥∆
#else
				strcpy(eecInfo.szVisitorName,mapde.getString("sVisitorName").c_str());  //πÛ±ˆ√˚≥∆
#endif
				eecInfo.iVisitorTime = mapde.getInt("iVisitorTime");      //∑√Œ  ±º‰

				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgEecNoticeInfo; //…Ë±∏…æ≥˝Õ®÷™
					msgInfo.pstEecNoticeInfo = &eecInfo;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}

		case emMSGAlarmSMS:   //±®æØ∂Ã–≈œ˚œ¢
			{
				MQ_ACMS_ALARM_NOTIFY_INFO alarmInfo;

				alarmInfo.llChannelId = mapde.getLong("lChanId");    //Õ®µ¿±‡∫≈
				alarmInfo.iAlarmTime = mapde.getInt("iAlarmTime");   //±®æØ∑¢…˙ ±º‰
				alarmInfo.iAlarmType = mapde.getInt("iAlarmType");   //±®æØ¿‡–Õ
#ifdef WIN32
				Utf8ToAnsi(mapde.getString("sAlarmType").c_str(),
					alarmInfo.szAlarmType,
					mapde.getString("sAlarmType").size()+1);//±®æØ¿‡–Õ
#else
				strcpy(alarmInfo.szAlarmType,mapde.getString("sAlarmType").c_str());    //±®æØ¿‡–Õ
#endif
				alarmInfo.iAlarmStatus = mapde.getInt("iAlarmStatus");//±®æØ◊¥Ã¨
#ifdef WIN32
				Utf8ToAnsi(mapde.getString("sAlarmStatus").c_str(),
					alarmInfo.szAlarmStatus,
					mapde.getString("sAlarmStatus").size()+1);//±®æØ◊¥Ã¨
#else
				strcpy(alarmInfo.szAlarmStatus,mapde.getString("sAlarmStatus").c_str());    //±®æØ◊¥Ã¨
#endif
				alarmInfo.iReserv1 = mapde.getInt("iReserve1");      //±£¡Ù◊÷∂Œ
#ifdef WIN32
				Utf8ToAnsi(mapde.getString("sReserve2").c_str(),
					alarmInfo.szReserv2,mapde.getString("sReserve2").size()+1);//±£¡Ù◊÷∂Œ
#else
				strcpy(alarmInfo.szReserv2,mapde.getString("sReserve2").c_str());    //±£¡Ù◊÷∂Œ
#endif

				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgAcmsAlarmNotify; //ACMS∆ΩÃ®±®æØÕ®÷™
					msgInfo.pstAcmsAlarmNotify = &alarmInfo;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		//case emMSGAlarmSMSReply:   //∂Ã–≈∑¢ÀÕ∑¥¿°œ˚œ¢

			////////////VTHProxy//////////////////
		case emMsgVTHProxyCallRedirectReq:  //∫ÙΩ–◊™“∆«Î«Ûœ˚œ¢ 
			{
				MQ_VTHPROXY_CALL_REDIRECT_INFO callRe;

				callRe.llVtoId = mapde.getLong("lVtoId");         //√≈ø⁄ª˙±‡∫≈
				callRe.iMidVthId = mapde.getInt("iMidVthId");     // “ƒ⁄ª˙±‡∫≈
				callRe.llVirVthId = mapde.getLong("lVirVthId");   //–Èƒ‚VTH±‡∫≈
				callRe.iInviteTime = mapde.getInt("iInviteTime"); // ±º‰
				memset(callRe.szPicUrl,0,sizeof(callRe.szPicUrl));
#ifdef WIN32
				Utf8ToAnsi(mapde.getString("sUrl1").c_str(),callRe.szPicUrl,sizeof(callRe.szPicUrl)-1); //∫ÙΩ–◊•≈ƒµƒµ⁄“ª’≈Õº∆¨¬∑æ∂
#else
				strcpy(callRe.szPicUrl,mapde.getString("sUrl1").c_str());    //∫ÙΩ–◊•≈ƒµƒµ⁄“ª’≈Õº∆¨¬∑æ∂
#endif
				callRe.iStage = mapde.getInt("iStage");          //∫ÙΩ–À˘¥¶Ω◊∂Œ

				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgVTHProxyCallReDirect; //∫ÙΩ–◊™“∆œ˚œ¢
					msgInfo.pstCallRedirctReq = &callRe;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		case emMsgVTHProxyUnlockReq:  //ø™À¯√¸¡Óœ˚œ¢ 
			{
				MQ_VTHPROXY_UNLOCK_REQ_INFO unlockInfo;

				unlockInfo.llVtoId = mapde.getLong("lVtoId");         //√≈ø⁄ª˙±‡∫≈
				unlockInfo.iMidVthId = mapde.getInt("iMidVthId");     // “ƒ⁄ª˙±‡∫≈
				unlockInfo.llVirVthId = mapde.getLong("lVirVthId");   //–Èƒ‚VTH±‡∫≈
				unlockInfo.iInviteTime = mapde.getInt("iInviteTime"); // ±º‰
				unlockInfo.llAccountId = mapde.getLong("lAccountId"); //ø™À¯»À±‡∫≈
				memset(unlockInfo.szAccountName,0,sizeof(unlockInfo.szAccountName));
#ifdef WIN32
				Utf8ToAnsi(mapde.getString("sAccountName").c_str(),unlockInfo.szAccountName,sizeof(unlockInfo.szAccountName)-1); //ø™À¯»À’À∫≈√˚≥∆
#else
				strcpy(unlockInfo.szAccountName,mapde.getString("sAccountName").c_str());    //ø™À¯»À’À∫≈√˚≥∆
#endif

				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgVTHProxyUnlock; //ø™À¯Õ®÷™
					msgInfo.pstUlockReq = &unlockInfo;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		case emMsgVTHProxyUnlockPicReq:  //ø™À¯Õº∆¨«Î«Ûœ˚œ¢ 
			{
				MQ_VTHPROXY_UNLOCK_PIC_INFO upInfo;

				upInfo.llVtoId = mapde.getLong("lVtoId");         //√≈ø⁄ª˙±‡∫≈
				upInfo.iMidVthId = mapde.getInt("iMidVthId");     // “ƒ⁄ª˙±‡∫≈
				upInfo.llVirVthId = mapde.getLong("lVirVthId");   //–Èƒ‚VTH±‡∫≈
				upInfo.iInviteTime = mapde.getInt("iInviteTime"); // ±º‰
				upInfo.llAccountId = mapde.getLong("lAccountId");   //ø™À¯»À±‡∫≈
				memset(upInfo.szAccountName,0,sizeof(upInfo.szAccountName));
#ifdef WIN32
				Utf8ToAnsi(mapde.getString("sAccountName").c_str(),upInfo.szAccountName,sizeof(upInfo.szAccountName)-1); //ø™À¯»À√˚≥∆
#else
				strcpy(upInfo.szAccountName,mapde.getString("sAccountName").c_str());    //ø™À¯»À√˚≥∆
#endif
				upInfo.iUnLockTime = mapde.getInt("iUnLockTime");         //ø™À¯ ±º‰
				upInfo.iUnLockResult = mapde.getLong("iUnLockResult");   //ø™À¯Ω·π˚ 0 Œ¥ø™À¯ 1 ø™À¯
				memset(upInfo.szPicUrl,0,sizeof(upInfo.szPicUrl));
#ifdef WIN32
				Utf8ToAnsi(mapde.getString("sUrl2").c_str(),upInfo.szPicUrl,sizeof(upInfo.szPicUrl)-1); //∫ÙΩ–◊•≈ƒµƒµ⁄∂˛’≈Õº∆¨¬∑æ∂
#else
				strcpy(upInfo.szPicUrl,mapde.getString("sUrl2").c_str());    //∫ÙΩ–◊•≈ƒµƒµ⁄∂˛’≈Õº∆¨¬∑æ∂
#endif

				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgVTHProxyCUnlockPicInfo; //ø™À¯Õº∆¨œ˚œ¢
					msgInfo.pstUnlockPicReq = &upInfo;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		case emMsgVTHProxyCallReDirectResult:  //∫ÙΩ–◊™“∆Ω·π˚∑¥¿°œ˚œ¢
			{
				MQ_VTHPROXY_CALL_REDIRECT_RESULT_INFO crrInfo;

				crrInfo.llVtoId = mapde.getLong("lVtoId");         //√≈ø⁄ª˙±‡∫≈
				crrInfo.iMidVthId = mapde.getInt("iMidVthId");     // “ƒ⁄ª˙±‡∫≈
				crrInfo.llVirVthId = mapde.getLong("lVirVthId");   //–Èƒ‚VTH±‡∫≈
				crrInfo.iInviteTime = mapde.getInt("iInviteTime"); // ±º‰
				crrInfo.iResult = mapde.getInt("iResult");         //Ω·π˚ 0∂Ã–≈Õ®π˝£ª 1Œﬁ¥À’À∫≈

				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgVTHProxyCallReDirectResult; //∫ÙΩ–◊™“∆Ω·π˚Õ®÷™
					msgInfo.pstCallRedirectResult = &crrInfo;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
			////////////VTHProxy//////////////////

			////////////∫ÙΩ–∑÷◊È//////////////////
		case emMsgCallgroupAreaDel:  //∫ÙΩ–∑÷◊È«¯”Úπÿœµ…æ≥˝œ˚œ¢ 
			{
				MQ_CALLGROUP_AREA_DELETE_INFO info;
				info.iCallGroupAreaId = mapde.getInt("iInviteGroupDetialId"); //∫ÙΩ–∑÷◊È«¯”Úπÿœµ±‡∫≈
				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgCallgroupAreaDel; //∫ÙΩ–∑÷◊È«¯”Úπÿœµ…æ≥˝œ˚œ¢
					msgInfo.pstCallgroupAreaDelReq = &info;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		case emMsgCallgroupAreaAdd:  //∫ÙΩ–∑÷◊È«¯”ÚπÿœµÃÌº”œ˚œ¢ 
			{
				MQ_CALLGROUP_AREA_ADD_INFO info;
				info.iCallGroupAreaId = mapde.getInt("iInviteGroupDetialId"); //∫ÙΩ–∑÷◊È«¯”Úπÿœµ±‡∫≈
				info.iCallGroupId     = mapde.getInt("iInviteGroupId");       //∫ÙΩ–∑÷◊È±‡∫≈
				info.llAreaCode       = mapde.getLong("lAreaCode");           //«¯”Ú±‡∫≈
				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgCallgroupAreaAdd; //∫ÙΩ–∑÷◊È«¯”ÚπÿœµÃÌº”œ˚œ¢
					msgInfo.pstCallgroupAreaAddReq = &info;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		case emMsgCallgroupDeviceBindDel:  //∫ÙΩ–∑÷◊È…Ë±∏∞Û∂®…æ≥˝œ˚œ¢ 
			{
				MQ_CALLGROUP_DEVICE_BIND_DELETE_INFO info;
				info.iCallGroupDeviceBindId = mapde.getInt("iInviteGroupBindingId"); //∫ÙΩ–∑÷◊È…Ë±∏∞Û∂®±‡∫≈
				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgCallgroupDeviceBindDel; //∫ÙΩ–∑÷◊È…Ë±∏∞Û∂®…æ≥˝œ˚œ¢
					msgInfo.pstCallgroupDevBindDelReq = &info;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		case emMsgCallgroupDeviceBindAdd:  //∫ÙΩ–∑÷◊È…Ë±∏∞Û∂®ÃÌº”œ˚œ¢
			{
				MQ_CALLGROUP_DEVICE_BIND_ADD_INFO info;
				info.iCallGroupDeviceBindId = mapde.getInt("iInviteGroupBindingId"); //∫ÙΩ–∑÷◊È…Ë±∏∞Û∂®±‡∫≈
				info.iCallGroupId = mapde.getInt("iInviteGroupId"); //∫ÙΩ–∑÷◊È±‡∫≈
				info.llDeviceId = mapde.getLong("lDeviceId"); //…Ë±∏≥§∫≈
				info.iPrority = mapde.getInt("iInvitePriority"); //”≈œ»º∂
				if ( m_fcbStack )
				{
					msgInfo.iType = emMqMsgCallgroupDeviceBindAdd; //∫ÙΩ–∑÷◊È…Ë±∏∞Û∂®ÃÌº”œ˚œ¢
					msgInfo.pstCallgroupDevBindAddReq = &info;
					m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
				}
				break;
			}
		default:
			break;
			////////////∫ÙΩ–∑÷◊È//////////////////

		}
	}
	else if ( 28 == msgType ) //ACTIVEMQ_TEXT_MESSAGE
	{
		//÷±Ω”∂¡»° ˝æ›
		//std::string msgContent(msgLen);
		//enc.Read(&msgContent[0],msgLen); //msg content œ˚œ¢ÃÂ
		enc>>msgLen; //msg content  size int

#ifdef CONSUME_TOPIC_AUTO_TEST
		if ( topic == ACTIVE_MQ_TEST_TOPIC ) // «≤‚ ‘÷˜Ã‚
		{
			return 11;
		}
#endif
		//text = textMessage->getText();
		if ( m_fcbStackEx )
		{
			//char 
			std::string strText(&buf[enc.GetReadLength()],msgLen);
			INFO_TRACE("recv text msg.topic="<<topic<<" cmsType="<<cmsType<<" msg="<<strText);
#ifdef WIN32
	//UTF8◊™ªªŒ™∂‡◊÷Ω⁄
			std::string strText2 = Utf8ToAnsi(strText.c_str()); 

			m_fcbStackEx(m_pUserEx,m_hInstId,MQ_INVALID_HANDLE,(char*)Utf8ToAnsi(topic.c_str()).c_str(),(char*)Utf8ToAnsi(cmsType.c_str()).c_str(),(char*)strText2.c_str(),strlen(strText2.c_str()));
#else
			m_fcbStackEx(m_pUserEx,m_hInstId,MQ_INVALID_HANDLE,(char*)topic.c_str(),(char*)cmsType.c_str(),(char*)strText.c_str(),strlen(strText.c_str()));
#endif
			//std::string strText = Utf8ToAnsi(textMessage->getText().c_str()); 
			////m_fcbStackEx(m_pUserEx,m_hInstId,MQ_INVALID_HANDLE,(char*)strtopic.c_str(),(char*)strCmsType.c_str(),(char*)textMessage->getText().c_str(),strlen(textMessage->getText().c_str()));
			//m_fcbStackEx(m_pUserEx,m_hInstId,MQ_INVALID_HANDLE,(char*)Utf8ToAnsi(strtopic.c_str()).c_str(),(char*)Utf8ToAnsi(strCmsType.c_str()).c_str(),(char*)strText.c_str(),strlen(strText.c_str()));
		}
		else
		{
			ERROR_TRACE("Invalid callback,not process.");
		}

	}
	else if ( 24 == msgType ) //ACTIVEMQ_BYTES_MESSAGE
	{
		//Ω‚ŒˆByteArray
		unsigned char ucArrayIsNull;
		enc>>ucArrayIsNull; //msg content  size int
		if ( 1 == ucArrayIsNull ) //not null
		{
			enc>>msgLen; //msg content  size int

			if ( m_fcbStackEx )
			{
				//char 
				std::string strText(&buf[enc.GetReadLength()],msgLen);
#ifdef WIN32
				//UTF8◊™ªªŒ™∂‡◊÷Ω⁄
				std::string strText2 = Utf8ToAnsi(strText.c_str()); 

				m_fcbStackEx(m_pUserEx,m_hInstId,MQ_INVALID_HANDLE,(char*)Utf8ToAnsi(topic.c_str()).c_str(),(char*)Utf8ToAnsi(cmsType.c_str()).c_str(),(char*)strText2.c_str(),strlen(strText2.c_str()));
#else
				m_fcbStackEx(m_pUserEx,m_hInstId,MQ_INVALID_HANDLE,(char*)topic.c_str(),(char*)cmsType.c_str(),(char*)strText.c_str(),strlen(strText.c_str()));
#endif
			}
			else
			{
				ERROR_TRACE("Invalid callback,not process.");
			}

		}

	}
	//∫Û√Êµƒƒ⁄»›‘› ±≤ªΩ‚Œˆ

	//enc.Write(msg,msgLen); //msg content œ˚œ¢ÃÂ
	//INFO_TRACE("Exit");

	return 0;
}

int CMQInstance::EncodeMsgAck(char buf[],int iLen,std::string &producerId,std::string &consumerId,std::string topic,unsigned long long ProducerSequenceId,unsigned long long BrokerSequenceId) //¥Ú∞¸MESSAGE_ACK√¸¡Ó
{
	//std::string producerId = "ID:win12955-24867-1370570147688-0:0";
	//std::string consumerId = "ID:win12955-24867-1370570147688-0:0";
	//std::string topic = "zw.public.all.devicestatus";
	//unsigned long long timestamp = currentTimeMillis();
	//unsigned long long ProducerSequenceId;
	//unsigned long long BrokerSequenceId;

	int iTotalLen = 0;
	CByteEncDec enc(buf,iLen);
	
	enc<<iTotalLen; //◊‹≥§∂»
	enc<<(unsigned char)22; //type MESSAGE_ACK
	enc<<m_uiCommandId; //command id 1
	m_uiCommandId++;
	enc<<(unsigned char)0; //need response false

	//ACTIVEMQ_TOPIC
	enc<<(unsigned char)1; //destination  exist ? true
	enc<<(unsigned char)101; //ACTIVEMQ_TOPIC type 101
	enc<<(unsigned char)1; //ACTIVEMQ_TOPIC not null true
	enc<<topic; //topic PhysicalName

	//TransactionId
	enc<<(unsigned char)0; //TransactionId  exist ? false


	//CONSUMER_ID
	enc<<(unsigned char)1; //CONSUMER_ID  exist ? true
	enc<<(unsigned char)122; //CONSUMER_ID  type unsigned char 122
	enc<<(unsigned char)1; //CONSUMER_ID  not null bool true
	enc<<m_strConnectionId/*consumerId*/; //CONSUMER_ID  string
	enc<<(unsigned long long)0; //sessionId  long 
	enc<<(unsigned long long)0; //value  long 

	enc<<(unsigned char)2; //AckType  unsigned char 2 


	//first messageId
	enc<<(unsigned char)1; //MESSAGE_ID  exist ? false
	enc<<(unsigned char)110; //MESSAGE_ID  type unsignec ahr 110
	enc<<(unsigned char)1; //MESSAGE_ID  not null bool true
	enc<<(unsigned char)123; //PRODUCER_ID  type unsigned char 123
	enc<<(unsigned char)1; //PRODUCER_ID  not null bool true
	enc<<m_strConnectionId/*producerId*/; //PRODUCER_ID  string
	enc<<(unsigned long long)0; //value  long
	enc<<(unsigned long long)0; //sessionId  long
	enc<<(unsigned long long)ProducerSequenceId; //ProducerSequenceId  long
	enc<<(unsigned long long)BrokerSequenceId; //BrokerSequenceId  long

	//last messageId
	enc<<(unsigned char)1; //MESSAGE_ID  exist ? false
	enc<<(unsigned char)110; //MESSAGE_ID  type unsignec ahr 110
	enc<<(unsigned char)1; //MESSAGE_ID  not null bool true
	enc<<(unsigned char)123; //PRODUCER_ID  type unsigned char 123
	enc<<(unsigned char)1; //PRODUCER_ID  not null bool true
	enc<<m_strConnectionId/*producerId*/; //PRODUCER_ID  string
	enc<<(unsigned long long)0; //value  long
	enc<<(unsigned long long)0; //sessionId  long
	enc<<(unsigned long long)ProducerSequenceId; //ProducerSequenceId  long
	enc<<(unsigned long long)BrokerSequenceId; //BrokerSequenceId  long



	//MessageCount
	enc<<(unsigned int)1; //MessageCount  int


	iLen = (int)enc.GetWriteLength();
	iTotalLen = iLen-4;

	CByteEncDec enc3(buf,iLen);
	enc3<<iTotalLen; //◊‹≥§∂»

	return iLen;
}

void CMQInstance::OnDisConnect(int iReason) //∂œœﬂÕ®÷™
{
	MQ_CALLBACK_INFO msgInfo;
	if ( m_fcbStack )
	{
		INFO_TRACE("onDisconnect.instId="<<m_hInstId);
		msgInfo.iType = emMqMsgDisConnect; //…Ë±∏…æ≥˝Õ®÷™
		msgInfo.iReason = MQ_ERROR_UNKNOWN;
		m_fcbStack(m_pUser,m_hInstId,MQ_INVALID_HANDLE,&msgInfo);
	}
	CMQGeneral::Instance()->ReleaseInstance(m_hInstId);

}

std::string CMQInstance::ToString(int value)
{
	std::string strValue;
	char szBuf[64];
	sprintf(szBuf,"%d",value);
	strValue = szBuf;
	return strValue;
}

int CMQInstance::EncoderRemovalInfo(char buf[],int &iLen,int type) //
{
	int iTotalLen = 0;
	CByteEncDec enc(buf,iLen);
	
	enc<<iTotalLen; //◊‹≥§∂»
	enc<<(unsigned char)12; //type REMOVE_INFO
	enc<<m_uiCommandId; //command id 1
	m_uiCommandId++;
	if ( 4 == type ) //CONNECTION_ID–≈¡Ó–Ë“™ªÿ∏¥
	{
		enc<<(unsigned char)1; //need response true
	}
	else
	{
		enc<<(unsigned char)0; //need response false
	}

	if ( 1 == type ) //PRODUCER_ID
	{
		//nest command PRODUCER_ID
		enc<<(unsigned char)1; //PRODUCER_ID exist ? true
		enc<<(unsigned char)123; //PRODUCER_ID type 123
		enc<<(unsigned char)1; //PRODUCER_ID not null true
		enc<<m_strConnectionId/*producerId*/; //connection id
		enc<<(unsigned long long)0; //value long long
		enc<<(unsigned long long)0; //session id long long
	}
	else if ( 2 == type ) //CONSUMER_ID
	{
		//nest command CONSUMER_ID
		enc<<(unsigned char)1; //CONSUMER_ID exist ? true
		enc<<(unsigned char)122; //CONSUMER_ID type 122
		enc<<(unsigned char)1; //CONSUMER_ID not null true
		enc<<m_strConnectionId/*consumerId*/; //connection id
		enc<<(unsigned long long)0; //session id long long
		enc<<(unsigned long long)0; //value long long
	}
	else if ( 3 == type ) //SESSION_ID
	{
		//nest command SESSION_ID
		enc<<(unsigned char)1; //SESSION_ID exist ? true
		enc<<(unsigned char)121; //SESSION_ID type 121
		enc<<(unsigned char)1; //SESSION_ID not null true
		enc<<m_strConnectionId/*consumerId*/; //connection id
		//enc<<(unsigned long long)0; //session id long long
		enc<<(unsigned long long)0; //value long long
	}
	else if ( 4 == type ) //CONNECTION_ID ¥À–≈¡Ó–Ë“™ACK
	{
		//nest command CONNECTION_ID
		enc<<(unsigned char)1; //CONNECTION_ID exist ? true
		enc<<(unsigned char)120; //CONNECTION_ID type 120
		enc<<(unsigned char)1; //CONNECTION_ID not null true
		enc<<m_strConnectionId/*consumerId*/; //connection id
		//enc<<(unsigned long long)0; //session id long long
		enc<<(unsigned long long)0; //value long long
	}

	enc<<(unsigned long long)0; //LastDeliveredSequenceId long long

	iLen = (int)enc.GetWriteLength();
	iTotalLen = iLen-4;

	CByteEncDec enc3(buf,iLen);
	enc3<<iTotalLen; //◊‹≥§∂»

	return iTotalLen;
}

int CMQInstance::EncoderShuntdownInfo(char buf[],int &iLen) //
{
	int iTotalLen = 0;
	CByteEncDec enc(buf,iLen);
	
	enc<<iTotalLen; //◊‹≥§∂»
	enc<<(unsigned char)11; //type SHUTDOWN_INFO 11
	enc<<m_uiCommandId; //command id 1
	m_uiCommandId++;
	enc<<(unsigned char)0; //need response false


	iLen = (int)enc.GetWriteLength();
	iTotalLen = iLen-4;

	CByteEncDec enc3(buf,iLen);
	enc3<<iTotalLen; //◊‹≥§∂»
	
	return iTotalLen;

}

int CMQInstance::ShuntdwonNornal() //’˝≥£Ω· ¯Õ¨¥˙¿Ì∂Àµƒ¡¨–¯
{
	//∑¢ÀÕ–≈¡Ó
	char buf[1024];
	int iDataLen = 1024;

	//1 ∑¢ÀÕ“∆≥˝PRODUCER_ID–≈¡Ó
	EncoderRemovalInfo(buf,iDataLen,1);
	int iSendBytes = send(m_sock,buf,iDataLen,0);
	if ( iSendBytes != iDataLen )
	{
		//∑¢ÀÕ ß∞‹
		ERROR_TRACE("send REMOVE_INFO PRODUCER_ID failed.");
		return -1;
	}

	//2 ∑¢ÀÕ“∆≥˝CONSUMER_ID–≈¡Ó
	iDataLen = 1024;
	EncoderRemovalInfo(buf,iDataLen,2);
	iSendBytes = send(m_sock,buf,iDataLen,0);
	if ( iSendBytes != iDataLen )
	{
		//∑¢ÀÕ ß∞‹
		ERROR_TRACE("send REMOVE_INFO CONSUMER_ID failed.");
		return -1;
	}

	//3 ∑¢ÀÕ“∆≥˝SESSION_ID–≈¡Ó
	iDataLen = 1024;
	EncoderRemovalInfo(buf,iDataLen,3);
	iSendBytes = send(m_sock,buf,iDataLen,0);
	if ( iSendBytes != iDataLen )
	{
		//∑¢ÀÕ ß∞‹
		ERROR_TRACE("send REMOVE_INFO SESSION_ID failed.");
		return -1;
	}

	//4 ∑¢ÀÕ“∆≥˝CONNECTION_ID–≈¡Ó ¥”–≈¡Ó–Ë“™»∑»œ÷°
	iDataLen = 1024;
	EncoderRemovalInfo(buf,iDataLen,4);
	iSendBytes = send(m_sock,buf,iDataLen,0);
	if ( iSendBytes != iDataLen )
	{
		//∑¢ÀÕ ß∞‹
		ERROR_TRACE("send REMOVE_INFO CONNECTION_ID failed.");
		return -1;
	}

	//Ω” ’RESPONSE
	iDataLen = RecvData(buf,1024,5000);
	if ( iDataLen <= 0 )
	{
		//Ω” ’ ß∞‹
		ERROR_TRACE("recv data failed.");
		return -1;
	}
	
	//Ω‚ŒˆRESPONSE
	unsigned int uiCommandId;
	if ( 0 != DecodeResponse(buf,iDataLen,uiCommandId) )
	{
		// ß∞‹
		ERROR_TRACE("decode failed.");
	}

	//5 ∑¢ÀÕ“∆≥˝SHUTDOWN_INFO–≈¡Ó
	iDataLen = 1024;
	EncoderShuntdownInfo(buf,iDataLen);
	iSendBytes = send(m_sock,buf,iDataLen,0);
	if ( iSendBytes != iDataLen )
	{
		//∑¢ÀÕ ß∞‹
		ERROR_TRACE("send SHUTDOWN_INFO failed.");
		return -1;
	}

	shutdown(m_sock,VT_SD_BOTH);
	//∂œø™¡¨Ω”
	VT_CLOSE_SOCKET(m_sock);

	return 0;
}

int CMQInstance::SendData(char buf[],int iLen) //∑¢ÀÕ ˝æ›»Áπ˚ ˝æ›≤ªƒ‹“ª¥Œ∑¢ÀÕ£¨∂¯¥Ê»Î∑¢ÀÕª∫≥Â
{
	CVTMutexGuardT<CVTMutexThreadRecursive> theLock(m_senLock);
	if ( _lstSend.size() != 0 ) //∑¢ÀÕª∫≥Â÷–“—æ≠”– ˝æ›,÷±Ω”ÃÓ»Î∑¢ÀÕª∫≥Â
	{
		SendPacket *pPack = new SendPacket();
		if ( !pPack )
		{
			return 0;
		}
		pPack->_buf = new char[iLen];
		if ( !pPack->_buf )
		{
			return 0;
		}
		pPack->_bufSize = iLen;
		memcpy(pPack->_buf,buf,iLen);
		_lstSend.push_back(pPack);
		return 0;
	}
	
	int iSendedSize;
	iSendedSize = send(m_sock,buf,iLen,0);
	if ( iSendedSize != iLen )
	{
		if ( iSendedSize <= 0 )
		{
			bool bIsBlocked = false;
			DWORD dwErr;

#ifdef VT_WIN32
			dwErr = WSAGetLastError();
			if ( SOCKET_ERROR == iSendedSize && dwErr == WSAEWOULDBLOCK )
			{
				bIsBlocked = true;
			}
#else
			dwErr = errno;
			if ( -1 == iSendedSize && EINPROGRESS == dwErr )
			{
				//errno = EWOULDBLOCK;
				bIsBlocked = true;
			}
#endif

			if ( !bIsBlocked )
			{
				ERROR_TRACE("send failed.err="<<dwErr);
				return -1;
			}
			SendPacket *pPack = new SendPacket();
			if ( !pPack )
			{
				return 0;
			}
			pPack->_buf = new char[iLen];
			if ( !pPack->_buf )
			{
				return 0;
			}
			pPack->_bufSize = iLen;
			memcpy(pPack->_buf,buf,iLen);
			_lstSend.push_back(pPack);
			return 0;
		}
		else //√ª”–∑¢ÀÕÕÍ»´
		{
			SendPacket *pPack = new SendPacket();
			if ( !pPack )
			{
				return 0;
			}
			pPack->_buf = new char[iLen-iSendedSize];
			if ( !pPack->_buf )
			{
				return 0;
			}
			pPack->_bufSize = iLen-iSendedSize;
			memcpy(pPack->_buf,buf,iLen-iSendedSize);
			_lstSend.push_back(pPack);
			return 0;

		}
	}
	else
	{
		//_lastActionTime = time(NULL); //…œ¥ŒªÓ‘æ ±º‰
	}
	return 0;
}
int CMQInstance::OnSendData() //±ªreactorµ˜”√,∑¢ÀÕª∫≥Â«¯÷–µƒ ˝æ›
{
	CVTMutexGuardT<CVTMutexThreadRecursive> theLock(m_senLock);
	if ( _lstSend.size() == 0 ) //ª∫≥Â«¯√ª”– ˝æ›
	{
		return 0;
	}
	std::list<SendPacket*>::iterator it;
	int iSendedSize;
	SendPacket *pPack = NULL/* = *it*/;
	for(it = _lstSend.begin();it!=_lstSend.end();it++)
	{
		/*SendPacket **/pPack = *it;
		//iSendedSize =_socket.Send((&pPack->_buf[pPack->_sendIndex]),pPack->_bufSize-pPack->_sendIndex);
		iSendedSize = send(m_sock,&pPack->_buf[pPack->_sendIndex],pPack->_bufSize-pPack->_sendIndex,0);
		if ( iSendedSize != pPack->_bufSize-pPack->_sendIndex )
		{
			if ( iSendedSize > 0 )
			{
				pPack->_sendIndex += iSendedSize;
			}
			break;
		}
		else
		{
			pPack->_sendIndex = pPack->_bufSize;
		}

	}
	//if ( (*it)->_sendIndex == (*it)->_bufSize ) //µ±«∞∞¸“—æ≠∑¢ÀÕÕÍ≥…
	if ( pPack->_sendIndex == pPack->_bufSize ) //µ±«∞∞¸“—æ≠∑¢ÀÕÕÍ≥…
	{
		//return 0;
	}
	else //√ª”–∑¢ÀÕÕÍ≥…
	{
		if ( it == _lstSend.begin() )
		{
			return 0;
		}
		it--;
	}
	
	for(std::list<SendPacket*>::iterator it2 = _lstSend.begin();it2!=it;it2++)
	{
		/*SendPacket **/pPack = *it2;
		//it2++;
		//_lstSend.erase(pPack/*it2*/);
		delete pPack;
	}
	_lstSend.erase(_lstSend.begin(),it);
	return 0;
}
void CMQInstance::ClearSend()//«Âø’∑¢ÀÕª∫≥Â
{
	CVTMutexGuardT<CVTMutexThreadRecursive> theLock(m_senLock);
	std::list<SendPacket*>::iterator it;
	SendPacket *pTemp;
	for(it=_lstSend.begin();it!=_lstSend.end();it++)
	{
		pTemp = *it;
		if ( pTemp )
		{
			delete pTemp;
			pTemp = NULL;
		}
	}
	_lstSend.clear();
}