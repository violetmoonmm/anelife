#include "CommonDefine.h"
#include "Trace.h"
#include "rapidxml.hpp"
#include "HttpDefines.h"
#include "SdkCommonDefine.h"
#include "MD5Inc.h"
#include "Base64.h"

unsigned long long CEventSuscribler::s_id_generator = 0;
unsigned int CEventSuscribler::s_event_key_generator = 0;

//…Ë÷√Ã◊Ω”◊÷◊Ë»˚ƒ£ Ω
int SetBlockMode(FCL_SOCKET sock,bool bIsNoBlock)
{
	int iRet;
	int iBlock;
	if ( bIsNoBlock ) //∑«◊Ë»˚ƒ£ Ω
	{
		iBlock = 1;
	}
	else //◊Ë»˚ƒ£ Ω
	{
		iBlock = 0;
	}

#ifdef PLAT_WIN32
	iRet = ::ioctlsocket(sock,FIONBIO,(u_long FAR *)&iBlock);
	if ( SOCKET_ERROR == iRet ) 
	{
		errno = ::WSAGetLastError();
		iRet = -1;
	}
#else
	iBlock = ::fcntl(sock,F_GETFL,0);
	if ( -1 != iBlock )
	{
		iBlock |= O_NONBLOCK;
		iRet = ::fcntl(sock,F_SETFL,iBlock);
	}
#endif
	if ( -1 == iRet )
	{
		ERROR_TRACE("set noblock mode error,error code="<<errno);
		return -1;
	}
	return 0;
}

bool ParseHttpHeader(char *msg,int len,HttpMessage &httpMsg)
{
	char szTemp[64];
	char *pCur = msg;
	char *pEnd = msg+len;
	std::string strEventPath;
	std::string strVersion;
	char *pLineStart;
	char *pLineEnd;
	char *pHdrEnd = msg+len;
	std::string strTemp;

	httpMsg.iContentLength = 0;

	//Header line
	pLineStart = msg;
	pLineEnd = strstr(pLineStart,"\r\n");
	if ( !pLineEnd )
	{
		ERROR_TRACE("error http start line");
		return false;
	}

	//method
	char *p = msg;
	while ( *p != ' ' && p ) p++;
	if ( !p )
	{
		return false;
	}
	int iMethodLen = (int)(p-msg);
	if ( iMethodLen > 16 )
	{
		ERROR_TRACE("error http method");
		return false;
	}

	memcpy(szTemp,pCur,iMethodLen);
	szTemp[iMethodLen] = '\0';
	httpMsg.strMethod = szTemp;

	if ( 0 == strcmp(szTemp,"HTTP/1.1") )
	{
		httpMsg.iType = 2;
	}
	else if ( 0 == strcmp(szTemp,"HTTP/1.0") )
	{
		httpMsg.iType = 2;
	}
	else if ( 0 == strcmp(szTemp,"GET") )
	{
		httpMsg.iType = 1;
		httpMsg.strMethod = szTemp;
		httpMsg.iMethod = emMethodGet; //http GET
	}
	else if ( 0 == strcmp(szTemp,"POST") )
	{
		httpMsg.iType = 1;
		httpMsg.strMethod = szTemp;
		httpMsg.iMethod = emMethodPost; //http POST
	}
	else if ( 0 == strcmp(szTemp,"NOTIFY") )
	{
		httpMsg.iType = 1;
		httpMsg.strMethod = szTemp;
		httpMsg.iMethod = emMethodNotify; //NOTIFY
	}
	else if ( 0 == strcmp(szTemp,"M-SEARCH") )
	{
		httpMsg.iType = 1;
		httpMsg.strMethod = szTemp;
		httpMsg.iMethod = emMethodMsearch; //M-SEARCH
	}
	else if ( 0 == strcmp(szTemp,"REGISTER") )
	{
		httpMsg.iType = 1;
		httpMsg.strMethod = szTemp;
		httpMsg.iMethod = emMethodRegister; //REGISTER
	}
	else if ( 0 == strcmp(szTemp,"SEARCH") )
	{
		httpMsg.iType = 1;
		httpMsg.strMethod = szTemp;
		httpMsg.iMethod = emMethodSearch; //SEARCH
	}
	else if ( 0 == strcmp(szTemp,"SUBSCRIBLE") )
	{
		httpMsg.iType = 1;
		httpMsg.strMethod = szTemp;
		httpMsg.iMethod = emMethodSubscrible; //SUBSCRIBLE
	}
	else if ( 0 == strcmp(szTemp,"UNSUBSCRIBLE") )
	{
		httpMsg.iType = 1;
		httpMsg.strMethod = szTemp;
		httpMsg.iMethod = emMethodUnSubscrible; //UNSUBSCRIBLE
	}
	else
	{
		ERROR_TRACE("unsupported http method.method="<<szTemp);
		return false;
	}
	
	while ( p&& *p==' ' ) p++;
	strTemp  = "";
	while ( p&&*p!=' ' ) { strTemp += *p;p++; }
	if ( 1 == httpMsg.iType )
	{
		httpMsg.strPath = strTemp;
		if ( httpMsg.iMethod == emMethodNotify && httpMsg.strPath == "*" )
		{
			httpMsg.iMethod = emMethodNotifyStar;
		}
		else if ( httpMsg.iMethod == emMethodMsearch && httpMsg.strPath == "*" )
		{

		}
	}
	else if ( 2 == httpMsg.iType ) //ªÿ”¶
	{
		httpMsg.iStatusCode = atoi(strTemp.c_str());
	}

	pLineStart = pLineEnd+2;
	pLineEnd = strstr(pLineStart,"\r\n");
	if ( !pLineEnd )
	{
		ERROR_TRACE("no other http header");
		return false;
	}

	//while( pLineStart && pLineStart!=pLineEnd && pLineEnd!=pHdrEnd )
	//std::string strTemp;
	while ( pLineStart && pLineEnd && pLineStart!=pLineEnd && pLineEnd!=pHdrEnd )
	{
		std::string strName;
		std::string strValue;
		strTemp = "";
		p = pLineStart;
		while ( p!=pLineEnd&&*p==' ') p++;
		if ( p==pLineEnd )
		{
			return false;
		}
		while(p!=pLineEnd&&*p!=':') { strTemp += *p;p++; }
		if ( p==pLineEnd )
		{
			return false;
		}
		strName = strTemp;
		p++;
		strTemp = "";
		while ( p!=pLineEnd&&*p==' ') p++;
		if ( p==pLineEnd )
		{
			//return false;
			//continue;
		}
		else
		{
			while(p!=pLineEnd) { strTemp += *p;p++; }
			//if ( p==pLineEnd )
			//{
			//	return false;
			//}
		}
		strValue = strTemp;
		std::string strNameUpper = ToUpper(strName);
		//if ( strName == "Content-Length")
		if ( strNameUpper == "CONTENT-LENGTH")
		{
			httpMsg.iContentLength = atoi(strValue.c_str());
		}
		//else
		//{
		//	httpMsg.iContentLength = 0;
		//}

		httpMsg.vecHeaderValues.push_back(NameValue(strName,strValue));
		pLineStart = pLineEnd+2;
		pLineEnd = strstr(pLineStart,"\r\n");
		if ( !pLineEnd )
		{
			ERROR_TRACE("no other http header");
			return false;
		}
	}

	//if ( 
	if ( !httpMsg.GetValueNoCase(std::string("TRANSFER-ENCODING")).empty() )
	{
		INFO_TRACE("TRANSFER-ENCODING chunked");
		httpMsg.bIsChunkMode = true;
	}
	else
	{
		httpMsg.bIsChunkMode = false;
	}
	
	return true;

}

//Ω‚Œˆhttp url(url¿Ô≤ª∞¸∫¨≤Œ ˝)
bool SplitHttpUrl(const std::string url,std::string &strIp,unsigned short &usPort,std::string &strPath)
{
	std::string strScheme; //ƒ£ Ω
	char *pUrl = (char*)url.c_str();
	char *pHost;
	char *pPort;
	char *pPath;

	//Ω‚Œˆbroker url
	if ( url.size() < 7 )
	{
		return false;
	}
	if ( 0 != strncmp(pUrl,"HTTP://",7) && 0 != strncmp(pUrl,"http://",7) )
	{
		return false;
	}
	pHost = pUrl+7;
	char *pTemp = strstr(pHost,":");
	if ( !pTemp )
	{
		return false;
	}
	strIp = std::string(pHost,pTemp);
	pPort = pTemp;
	pPort++;
	if ( !pPort )
	{
		return false;
	}
	pTemp = strstr(pPort,"/");
	if ( !pTemp )
	{
		return false;
	}
	std::string strPort = std::string(pPort,pTemp);
	usPort = atoi(strPort.c_str());
	pPath = pTemp;
	//pPath++;
	if ( !pPath )
	{
		return false;
	}

	strPath = pPath;
	if ( strPath.empty() )
	{
		strPath = "/";
	}
	return true;
}

long long GetCurrentTimeMs()
{
#ifdef PLAT_WIN32

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

void FclSleep(int iMillSec)
{
#ifdef PLAT_WIN32
	::Sleep(iMillSec);
#else
	usleep(iMillSec*1000);
#endif
}

std::string MakeJsessionId()
{
	static long long llBegin = 0;
	llBegin++;
	char szId[64] = {0};
	sprintf(szId,"JSESSIONID=ID%lld",llBegin);
	return std::string(szId);
}

std::string ToUpper(std::string strSrc)
{
	std::string strTemp;
	char cTemp;
	for(size_t i=0;i<strSrc.size();i++)
	{
		if ( isalpha(strSrc[i]) )
		{
			if ( islower(strSrc[i]) )
			{
				cTemp = strSrc[i];
				cTemp += 'A'-'a';
				//strTemp.append(cTemp);
				strTemp += (strSrc[i]+'A'-'a');
			}
			else
			{
				strTemp += strSrc[i];
				//strTemp.append(strSrc[i]);
			}
		}
		else
		{
			strTemp += strSrc[i];
			//strTemp.append(strSrc[i]);
		}
	}
	return strTemp;
}
std::string ToLowwer(std::string strSrc)
{
	std::string strTemp;
	char cTemp;
	for(size_t i=0;i<strSrc.size();i++)
	{
		if ( isalpha(strSrc[i]) )
		{
			if ( isupper(strSrc[i]) )
			{
				strTemp += (strSrc[i]+'a'-'A');
			}
			else
			{
				strTemp += strSrc[i];
			}
		}
		else
		{
			strTemp += strSrc[i];
		}
	}
	return strTemp;
}

bool ParseNotifyBody(char *msg,int len,std::vector<NameValue*> &args)
{
	rapidxml::xml_document<> xmlDoc; 
	rapidxml::xml_node<> *pPropertySet;
	rapidxml::xml_node<> *pProperty;
	rapidxml::xml_node<> *pNode;
	
	std::string strXml;
	try
	{
		strXml = std::string(msg,len);
		xmlDoc.parse<0>((char*)strXml.c_str()/*msg*/);
	}
	catch (...)
	{
		ERROR_TRACE("parse Notify msg failed");
		ERROR_TRACE("<<<<TRACE xml  "<<msg);
		return false;
	}
	pPropertySet = xmlDoc.first_node("e:propertyset");

	if ( pPropertySet )
	{
		//∂¡»°∑˛ŒÒ¡–±Ì
		for(pProperty = pPropertySet->first_node();pProperty!=0;pProperty=pProperty->next_sibling())
		{
			if ( 0 == strcmp("e:property",pProperty->name()) )
			{
				pNode = pProperty->first_node();
				if ( pNode && pNode->name() && pNode->value() )
				{
					std::string strName = pNode->name();
					std::string strValue = pNode->value();
					NameValue *pArg = new NameValue(strName,strValue);
					args.push_back(pArg);
				}
				
			}
			else //¥ÌŒÛ,≤ª”¶∏√”–∆‰À˚Ω⁄µ„
			{
				ERROR_TRACE("have other node");
				return false;
			}
		}
	}
	return true;
}

#ifdef PLAT_WIN32
#else
unsigned int WSAGetLastError()
{
	return errno;
}
#endif

bool ParseAction(char *pXml,unsigned int uiLen,char *action,char *serviceType,std::vector<NameValue> &outArgs)
{
	rapidxml::xml_document<> xmlDoc; 
	rapidxml::xml_node<> *pRoot;
	rapidxml::xml_node<> *pBody;
	rapidxml::xml_node<> *pAction;
	rapidxml::xml_node<> *pNode;

	std::string strActionDesc;

	std::string strXml;
	try
	{
		strXml = std::string(pXml,uiLen);
		xmlDoc.parse<0>((char*)strXml.c_str()/*pXml*/);
	}
	catch (...)
	{
		ERROR_TRACE("parse Action(Response) msg failed");
		ERROR_TRACE("<<<<TRACE xml  "<<pXml);
		return false;
	}
	//∏˘
	pRoot = xmlDoc.first_node("s:Envelope");

	if ( !pRoot ) //√ª”–
	{
		ERROR_TRACE("not find s:Envelope node");
		return false;
	}

	//ƒ⁄»›
	pBody = pRoot->first_node("s:Body");
	if ( !pBody ) //√ª”–
	{
		//INFO_TRACE("not find s:Body node,no resp body params");
		return true;
	}

	strActionDesc = "u:";
	strActionDesc += action;
	//strActionResponse = "u:"+action+"Response";
	//∂Ø◊˜
	pAction = pBody->first_node(strActionDesc.c_str());
	if ( !pAction ) //√ª”–
	{
		//ERROR_TRACE("not find "<<strActionDesc<<" node");
		return true;
	}
	if ( !pAction->first_attribute("xmlns:u") 
		 || !pAction->first_attribute("xmlns:u")->value()
		 || 0 != strcmp(pAction->first_attribute("xmlns:u")->value(),serviceType) )
	{
		//ERROR_TRACE("not find xmlns:u attribute");
		return true;
	}

	//∂¡»°∑˛ŒÒ¡–±Ì
	for(pNode=pAction->first_node();pNode!=0;pNode=pNode->next_sibling())
	{
		std::string strName;
		std::string strValue;

		if ( pNode->name() && pNode->value() )
		{
			strName = pNode->name();
			strValue = pNode->value();
			outArgs.push_back(NameValue(strName,strValue));
		}

		else //¥ÌŒÛ,≤ª”¶∏√”–∆‰À˚Ω⁄µ„
		{
		}
	}
	

	return true;
}



bool http_post_parse_action_resp(char *pXml,unsigned int uiLen,std::vector<HttpPostRespAction> &outArgs)
{
	rapidxml::xml_document<> xmlDoc; 
	rapidxml::xml_node<> *pRoot;
	rapidxml::xml_node<> *pAction;
	rapidxml::xml_node<> *pNode;

	xmlDoc.parse<0>(pXml);

	//∏˘
	pRoot = xmlDoc.first_node("resp");

	if ( !pRoot ) //√ª”–
	{
		ERROR_TRACE("not find root node");
		return false;
	}


	//∂¡»°∑˛ŒÒ¡–±Ì
	for(pAction=pRoot->first_node();pAction!=0;pAction=pAction->next_sibling())
	{
		HttpPostRespAction actionInfo;
		if ( pAction->name() ) //action name
		{
			INFO_TRACE("action "<<pAction->name());
			actionInfo.strName = pAction->name();
			//argument list
			for(pNode=pAction->first_node();pNode!=0;pNode=pNode->next_sibling())
			{
				if ( pNode->name() && pNode->value() )
				{
					std::string strName;
					std::string strValue;
					strName = pNode->name();
					strValue = pNode->value();
					actionInfo.args.push_back(NameValue(strName,strValue));
					INFO_TRACE("arg name "<<strName<<" value "<<strValue);
				}
			}
			outArgs.push_back(actionInfo);
		}

		else //¥ÌŒÛ,≤ª”¶∏√”–∆‰À˚Ω⁄µ„
		{
		}
	}
	

	return true;
}

std::string gen_soap_action_resp(std::string strServiceType,Action *pAction,std::vector<HttpPostRespAction> &outArgs)
{
	std::string strResp;
	strResp +=   "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r\n"                              
				  "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" "  
				  "xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">\r\n"                  
				  "\t<s:Body>\r\n"                                                              
				  "\t\t<u:";
	strResp +=   pAction->strName;
	strResp +=   "Response xmlns:u=\"";
	strResp +=   strServiceType;
	strResp +=   "\">\r\n";
	strResp +=   "\t\t\t";

	
	//≤È’“∂Ø◊˜√˚≥∆
	for(size_t i=0;i<outArgs.size();i++)
	{
		INFO_TRACE("action "<<pAction->strName<< " cur action "<<outArgs[i].strName);
		if ( outArgs[i].strName == pAction->strName )
		{
			for(size_t j=0;j<pAction->vecArgs.size();j++)
			{
				if ( pAction->vecArgs[j]->iDirection == 2 ) // ‰≥ˆ≤Œ ˝
				{
					for(size_t k=0;k<outArgs[i].args.size();k++)
					{
						std::string strTempName = outArgs[i].args[k].m_strArgumentName;
						if ( outArgs[i].args[k].m_strArgumentName.size() > 3 )
						{
							if ( outArgs[i].args[k].m_strArgumentName[0] == 'c'
								&& outArgs[i].args[k].m_strArgumentName[1] == 'u'
								&& outArgs[i].args[k].m_strArgumentName[2] == 'r' )
							{
								strTempName = outArgs[i].args[k].m_strArgumentName.substr(3,-1);
							}
							else
							{
								strTempName = "";
							}
						}
						else
						{
							strTempName = "";
						}
						//ºÊ»›¡Ω÷÷∏Ò Ω: ±‰¡øº”cur«∞◊∫ªÚ≤ªº”«∞◊∫
						if ( outArgs[i].args[k].m_strArgumentName == pAction->vecArgs[j]->strName 
							 || strTempName == pAction->vecArgs[j]->strName )
						{
								strResp += "<";
								strResp += pAction->vecArgs[j]->strName;//outArgs[i].args[k].m_strArgumentName;
								strResp += ">";
								strResp += outArgs[i].args[k].m_strArgumentValue;
								strResp += "</";
								strResp += pAction->vecArgs[j]->strName;//outArgs[i].args[k].m_strArgumentName;
								strResp += ">";
						}
					}
				}
			}
		}
		else
		{
		}
	}
	strResp +=	 "\t\t</u:";
	strResp +=   pAction->strName;
	strResp +=   "Response>\r\n";
	strResp +=   "\t</s:Body>\r\n"
				 "</s:Envelope>";

	//√ª”–’“µΩ∑˛ŒÒ√˚≥∆
	return strResp;
}

bool ParseGetDeviceListResp(char *pXml,unsigned int uiLen,DeviceData &deviceData)
{
	rapidxml::xml_document<> xmlDoc; 
	rapidxml::xml_node<> *pRoot;
	rapidxml::xml_node<> *pRootDevice;
	rapidxml::xml_node<> *pNode;

	std::string strDeviceType;
	std::string strFriendlyName;
	std::string strUdn;
	rapidxml::xml_node<> *pServiceList;
	rapidxml::xml_node<> *pService;
	rapidxml::xml_node<> *pDeviceList;
	rapidxml::xml_node<> *pDevice;
	//rapidxml::xml_node<> *pIconList;
	//rapidxml::xml_node<> *pIcon;
	std::string strServiceType;
	std::string strServiceId;
	std::string strScpdUrl;
	std::string strControlUrl;
	std::string strEventSubUrl;
	std::string strIconMimeType;
	//int iIconWidth;
	//int iIconHeight;
	//int iIconDepth;
	//std::string strIconUrl;

	Service *pServ;
	std::string strIp;
	unsigned short usPort;
	std::string strPath;

	deviceData.m_strDescDoc = std::string(pXml,uiLen);

	std::string strXml;
	try
	{
		strXml = std::string(pXml,uiLen);
		xmlDoc.parse<0>((char*)strXml.c_str()/*pXml*/);
	}
	catch ( ... )
	{
		ERROR_TRACE("parse device list xml failed.xml="<<pXml);
		ERROR_TRACE("<<<<TRACE xml  "<<deviceData.m_strDescDoc);
		return false;
	}
	//Ω‚ŒˆÕ∑≤ø
	pRoot = xmlDoc.first_node("root");

	if ( !pRoot ) //√ª”–
	{
		ERROR_TRACE("not find root node");
		return false;
	}

	//Ω‚Œˆƒ⁄»›
	pRootDevice = pRoot->first_node("device");
	if ( !pRootDevice ) //√ª”–
	{
		ERROR_TRACE("not find device node");
		return true;
	}

	pNode = pRootDevice->first_node("deviceType");
	if ( pNode && pNode->value() )
	{
		strDeviceType = pNode->value();
		deviceData.m_strDeviceType = strDeviceType;
	}

	pNode = pRootDevice->first_node("friendlyName");
	if ( pNode && pNode->value() )
	{
		strFriendlyName = pNode->value();
		deviceData.m_strFriendlyName = strFriendlyName;
	}

	pNode = pRootDevice->first_node("UDN");
	if ( pNode && pNode->value() )
	{
		if ( 0 == strncmp(pNode->value(),"uuid:",5) )
		{
			strUdn = pNode->value()+5;
			deviceData.m_strUDN = strUdn;
		}
		else
		{
			strUdn = pNode->value();
			deviceData.m_strUDN = strUdn;
		}
	}

	pNode = pRootDevice->first_node("manufacturer");
	if ( pNode && pNode->value() )
	{
		deviceData.m_strManufacturer = pNode->value();
	}
	pNode = pRootDevice->first_node("serialNumber");
	if ( pNode && pNode->value() )
	{
		deviceData.m_strSerialNumber = pNode->value();
	}
	pNode = pRootDevice->first_node("presentationURL");
	if ( pNode && pNode->value() )
	{
		deviceData.m_strPresentationURL = pNode->value();
	}
	pNode = pRootDevice->first_node("roomId");
	if ( pNode && pNode->value() )
	{
		deviceData.m_strLayoutId = pNode->value();
	}
	pNode = pRootDevice->first_node("cameraId");
	if ( pNode && pNode->value() )
	{
		deviceData.m_strCameraId = pNode->value();
	}
	else
	{
		//deviceData.m_iCameraId = -1;
	}
	pNode = pRootDevice->first_node("actionMode");   //÷–π˙÷«ƒ‹º“æ”¡™√ÀÃÿ”–◊÷∂Œ,±Ì æ∂Ø◊˜¥¶¿Ìƒ£ Ω
	if ( pNode && pNode->value() )
	{
		deviceData.m_strControlMode = pNode->value();
	}
	else
	{
		deviceData.m_strControlMode = "upnp_soap";
	}


	pServiceList = pRootDevice->first_node("serviceList");

	if ( pServiceList )
	{
		//∂¡»°∑˛ŒÒ¡–±Ì
		for(pService = pServiceList->first_node();pService!=0;pService=pService->next_sibling())
		{
			if ( 0 == strcmp("service",pService->name()) )
			{
				pNode = pService->first_node("serviceType");
				if ( pNode && pNode->value() )
				{
					strServiceType = pNode->value();
				}
				pNode = pService->first_node("serviceId");
				if ( pNode && pNode->value() )
				{
					strServiceId = pNode->value();
				}
				pNode = pService->first_node("SCPDURL");
				if ( pNode && pNode->value() )
				{
					strScpdUrl = pNode->value();
				}
				pNode = pService->first_node("controlURL");
				if ( pNode && pNode->value() )
				{
					strControlUrl = pNode->value();
				}
				pNode = pService->first_node("eventSubURL");
				if ( pNode && pNode->value() )
				{
					strEventSubUrl = pNode->value();
				}
				pServ = new Service(strServiceType,strServiceId,strScpdUrl,strControlUrl,strEventSubUrl);
				if ( SplitHttpUrl(strControlUrl,strIp,usPort,strPath) )
				{
					pServ->m_strControlIp = strIp;
					pServ->m_usControlPort = usPort;
					pServ->m_strControlPath = strPath;
				}
				if ( SplitHttpUrl(strScpdUrl,strIp,usPort,strPath) )
				{
					pServ->m_strScpdIp = strIp;
					pServ->m_usScpdPort = usPort;
					pServ->m_strScpdlPath = strPath;
				}
				if ( SplitHttpUrl(strControlUrl,strIp,usPort,strPath) )
				{
					pServ->m_strControlIp = strIp;
					pServ->m_usControlPort = usPort;
					pServ->m_strControlPath = strPath;
				}
				deviceData.m_vecSericeList.push_back(pServ);
			}
			else //¥ÌŒÛ,≤ª”¶∏√”–∆‰À˚Ω⁄µ„
			{
			}
		}
	}


	DeviceData *pEmbededDeviceData = 0;
	pDeviceList = pRootDevice->first_node("deviceList");
	if ( pDeviceList )
	{
		//∂¡»°∑˛ŒÒ¡–±Ì
		for(pDevice=pDeviceList->first_node();pDevice!=0;pDevice=pDevice->next_sibling())
		{
			if ( 0 == strcmp("device",pDevice->name()) )
			{
				pEmbededDeviceData = new DeviceData();
				deviceData.m_vecEmbededDeviceList.push_back(pEmbededDeviceData);
				pNode = pDevice->first_node("deviceType");
				if ( pNode && pNode->value() )
				{
					strDeviceType = pNode->value();
					pEmbededDeviceData->m_strDeviceType = strDeviceType;
				}

				pNode = pDevice->first_node("friendlyName");
				if ( pNode && pNode->value() )
				{
					strFriendlyName = pNode->value();
					pEmbededDeviceData->m_strFriendlyName = strFriendlyName;
				}

				pNode = pDevice->first_node("UDN");
				if ( pNode && pNode->value() )
				{
					if ( 0 == strncmp(pNode->value(),"uuid:",5) )
					{
						strUdn = pNode->value()+5;
						pEmbededDeviceData->m_strUDN = strUdn;
					}
					else
					{
						strUdn = pNode->value();
						pEmbededDeviceData->m_strUDN = strUdn;
					}
				}

				pNode = pDevice->first_node("roomId");
				if ( pNode && pNode->value() )
				{
					pEmbededDeviceData->m_strLayoutId = pNode->value();
				}
				pNode = pDevice->first_node("cameraId");
				if ( pNode && pNode->value() )
				{
					pEmbededDeviceData->m_strCameraId = pNode->value();
				}
				else
				{
					//pEmbededDeviceData->m_iCameraId = -1;
				}

				pNode = pDevice->first_node("manufacturer");
				if ( pNode && pNode->value() )
				{
					pEmbededDeviceData->m_strManufacturer = pNode->value();
				}
				pNode = pDevice->first_node("serialNumber");
				if ( pNode && pNode->value() )
				{
					pEmbededDeviceData->m_strSerialNumber = pNode->value();
				}
				pNode = pDevice->first_node("presentationURL");
				if ( pNode && pNode->value() )
				{
					pEmbededDeviceData->m_strPresentationURL = pNode->value();
				}

				pServiceList = pDevice->first_node("serviceList");
				if ( pServiceList )
				{
					//∂¡»°∑˛ŒÒ¡–±Ì
					for(pService = pServiceList->first_node();pService!=0;pService=pService->next_sibling())
					{
						if ( 0 == strcmp("service",pService->name()) )
						{
							pNode = pService->first_node("serviceType");
							if ( pNode && pNode->value() )
							{
								strServiceType = pNode->value();
							}
							pNode = pService->first_node("serviceId");
							if ( pNode && pNode->value() )
							{
								strServiceId = pNode->value();
							}
							pNode = pService->first_node("SCPDURL");
							if ( pNode && pNode->value() )
							{
								strScpdUrl = pNode->value();
							}
							pNode = pService->first_node("controlURL");
							if ( pNode && pNode->value() )
							{
								strControlUrl = pNode->value();
							}
							pNode = pService->first_node("eventSubURL");
							if ( pNode && pNode->value() )
							{
								strEventSubUrl = pNode->value();
							}
							pServ = new Service(strServiceType,strServiceId,strScpdUrl,strControlUrl,strEventSubUrl);
							if ( SplitHttpUrl(strControlUrl,strIp,usPort,strPath) )
							{
								pServ->m_strControlIp = strIp;
								pServ->m_usControlPort = usPort;
								pServ->m_strControlPath = strPath;
							}
							if ( SplitHttpUrl(strScpdUrl,strIp,usPort,strPath) )
							{
								pServ->m_strScpdIp = strIp;
								pServ->m_usScpdPort = usPort;
								pServ->m_strScpdlPath = strPath;
							}
							if ( SplitHttpUrl(strControlUrl,strIp,usPort,strPath) )
							{
								pServ->m_strControlIp = strIp;
								pServ->m_usControlPort = usPort;
								pServ->m_strControlPath = strPath;
							}
							pEmbededDeviceData->m_vecSericeList.push_back(pServ);
						}
						else //¥ÌŒÛ,≤ª”¶∏√”–∆‰À˚Ω⁄µ„
						{
						}
					}
				}


			}
			else //¥ÌŒÛ,≤ª”¶∏√”–∆‰À˚Ω⁄µ„
			{
			}
		}
	}

	return true;
}

bool ParseGetServiceResp(char *pXml,unsigned int uiLen,Service &service)
{
	rapidxml::xml_document<> xmlDoc; 
	rapidxml::xml_node<> *pRoot;
	rapidxml::xml_node<> *pNode;

	rapidxml::xml_node<> *pActionList;
	rapidxml::xml_node<> *pAction;
	rapidxml::xml_node<> *pStateVariableList;
	rapidxml::xml_node<> *pStateVariable;
	rapidxml::xml_node<> *pArgumentList;
	rapidxml::xml_node<> *pArgument;

	service.m_strDescDoc = pXml;

	xmlDoc.parse<0>(pXml);

	//Ω‚ŒˆÕ∑≤ø
	pRoot = xmlDoc.first_node("scpd");

	if ( !pRoot ) //√ª”–
	{
		ERROR_TRACE("not find root node");
		return false;
	}


	StateVariable *pVar;
	pStateVariableList = pRoot->first_node("serviceStateTable");
	if ( pStateVariableList )
	{
		//∂¡»°∑˛ŒÒ¡–±Ì
		for(pStateVariable=pStateVariableList->first_node();pStateVariable!=0;pStateVariable=pStateVariable->next_sibling())
		{

			if ( 0 == strcmp("stateVariable",pStateVariable->name()) )
			{
				pVar = new StateVariable;
				if ( pStateVariable->first_attribute("sendEvents") && pStateVariable->first_attribute("sendEvents")->value() )
				{
					if ( 0 == strcmp(pStateVariable->first_attribute("sendEvents")->value(),"yes") )
					{
						pVar->bSendEvents = true;
					}
					else
					{
						pVar->bSendEvents = false;
					}
				}
				else
				{
					pVar->bSendEvents = false;
				}

				pNode = pStateVariable->first_node("name");
				if ( pNode && pNode->value() )
				{
					pVar->strName = pNode->value();
				}

				pNode = pStateVariable->first_node("dataType");
				if ( pNode && pNode->value() )
				{
					pVar->strDataType = pNode->value();
				}
				pNode = pStateVariable->first_node("defaultValue");
				if ( pNode && pNode->value() )
				{
					pVar->strDefaultValue = pNode->value();
					pVar->strValue = pVar->strDefaultValue;
				}

				service.vecStateVariables.push_back(pVar);
			}
		}

	}

	pActionList = pRoot->first_node("actionList");
	Action *pAct;

	if ( pActionList )
	{
		//∂¡»°∑˛ŒÒ¡–±Ì
		for(pAction = pActionList->first_node();pAction!=0;pAction=pAction->next_sibling())
		{
			pAct = new Action;
			pNode = pAction->first_node("name");
			if ( pNode && pNode->value() )
			{
				pAct->strName = pNode->value();
			}

			pArgumentList = pAction->first_node("argumentList");

			Argument *pArg;
			if ( pArgumentList )
			{
				for(pArgument=pArgumentList->first_node();pArgument!=0;pArgument=pArgument->next_sibling())
				{
					rapidxml::xml_node<> *pTemp;
					pArg = new Argument;

					pTemp = pArgument->first_node("name");
					if ( pTemp && pTemp->value() )
					{
						pArg->strName = pTemp->value();
					}
					pTemp = pArgument->first_node("direction");
					if ( pTemp && pTemp->value() )
					{
						if ( 0 == strcmp(pTemp->value(),"in") )
						{
							pArg->iDirection = 1;
						}
						else if ( 0 == strcmp(pTemp->value(),"out") )
						{
							pArg->iDirection = 2;
						}
					}
					pTemp = pArgument->first_node("relatedStateVariable");
					if ( pTemp && pTemp->value() )
					{
						pArg->pRelatedStateVariable = service.GetStateVariable(std::string(pTemp->value()));
					}
					pAct->vecArgs.push_back(pArg);
				}
			}

			service.vecActions.push_back(pAct);
		}

	}

	return true;
}

#ifndef PLAT_WIN32
unsigned int GetTickCount()
{
	unsigned int   ret;
	struct  timeval time_val;
	
	gettimeofday(&time_val, NULL);
	ret = time_val.tv_sec * 1000 + time_val.tv_usec / 1000;
	
	return ret;
}
#endif //PLAT_WIN32


unsigned long long GetSysTime100ns()
#ifdef PLAT_WIN32
{
	ULARGE_INTEGER time;
	unsigned long long sysTime;
	/* NT keeps time in FILETIME format which is 100ns ticks since
	Jan 1, 1601. UUIDs use time in 100ns ticks since Oct 15, 1582.
	The difference is 17 Days in Oct + 30 (Nov) + 31 (Dec)
	+ 18 years and 5 leap days. */
	GetSystemTimeAsFileTime((FILETIME *)&time);
	time.QuadPart += (unsigned __int64) (1000*1000*10)       // seconds
					* (unsigned __int64) (60 * 60 * 24)       // days
					* (unsigned __int64) (17+30+31+365*18+5); // # of days
	sysTime = time.QuadPart;
	return sysTime;
}
#else
{
	struct timeval tp;
	unsigned long long sysTime;
	gettimeofday(&tp,(struct timezone *)0); 
	/* Offset between UUID formatted times and Unix formatted times.
	UUID UTC base time is October 15, 1582.
	Unix base time is January 1, 1970.*/
	sysTime = ((unsigned long long)tp.tv_sec * 10000000)
			 + ((unsigned long long)tp.tv_usec * 10)
			 + /*I64*/(0x01B21DD213814000ULL);
	return sysTime;
} 
#endif

//…˙≥…bytes ˝ƒøµƒÀÊª˙ ˝
void GenerateRand(unsigned char *buf,int bytes)
{
	static bool bIsFirst = true;
	if ( bIsFirst )
	{
		srand(time(NULL));
		bIsFirst = false;
	}
	for(int i=0;i<bytes;i++)
	{
		buf[i] = (unsigned char)(rand()/255);
	}
	return ;
}
//…˙≥…uuid,ÀÊª˙ ˝ƒ£ Ω
std::string GeterateGuid()
{
	unsigned char buf[16];
	unsigned char node[6];
	unsigned char cs[2];
	unsigned long long mac_addr;
	static unsigned short clock_seq = 0;
	unsigned long long sys_time;

	//ªÒ»°µ±«∞ ±º‰
	sys_time = GetSysTime100ns();
	//ªÒ»°macµÿ÷∑
	mac_addr = GetMacAddrEx();
	if ( 0 == mac_addr )
	{
		GenerateRand(node,6);
		//∑«ieee macµÿ÷∑±ÿ–Î…Ë÷√,“‘√‚Õ¨ŒÔ¿Ìmacµÿ÷∑≥ÂÕª
		node[0] |= 0x01; //∂‡≤•µÿ÷∑∂Œ 01:00:5E:00:00:00--01:00:5E:7F:FF:FF
		node[1] |= 0x00; //∂‡≤•µÿ÷∑
		node[2] |= 0x5E; //∂‡≤•µÿ÷∑
		node[3] &= 0x7F; //∂‡≤•µÿ÷∑
	}
	else // π”√macµÿ÷∑
	{
		node[0] = ((mac_addr & 0X0000FF0000000000ULL)>>40);
		node[1] = ((mac_addr & 0X000000FF00000000ULL)>>32);
		node[2] = ((mac_addr & 0X00000000FF000000ULL)>>24);
		node[3] = ((mac_addr & 0X0000000000FF0000ULL)>>16);
		node[4] = ((mac_addr & 0X000000000000FF00ULL)>>8);
		node[5] = ((mac_addr & 0X00000000000000FFULL)>>0);
		
		//ieee macŒﬁ–Ë…Ë÷√
		//node[0] |= 0x01; //∂‡≤•µÿ÷∑ 
	}
	if ( 0 == clock_seq )
	{
		//µ⁄“ª¥Œ,…˙≥…ÀÊª˙÷µ
		GenerateRand(cs,2);
		
		clock_seq = cs[0];
		clock_seq <<= 8;
		clock_seq |= cs[1];
	}
	else
	{
	}

	//…˙≥…uuid
	//time_low
	buf[0] = (unsigned char)((sys_time &0X00000000FF000000ULL )>>24);
	buf[1] = (unsigned char)((sys_time &0X0000000000FF0000ULL )>>16);
	buf[2] = (unsigned char)((sys_time &0X000000000000FF00ULL )>>8);
	buf[3] = (unsigned char)((sys_time &0X00000000000000FFULL )>>0);

	//time_mid
	buf[4] = (unsigned char)((sys_time &0X0000FF0000000000ULL )>>40);
	buf[5] = (unsigned char)((sys_time &0X000000FF00000000ULL )>>32);

	//time_hi_and_version bit0--bit3
	buf[6] = (unsigned char)((sys_time &0X0F00000000000000ULL )>>56);
	buf[7] = (unsigned char)((sys_time &0X00FF000000000000ULL )>>48);
	//version 1 bit4--bit7
	buf[6] |= ((unsigned char)1<<4);

	//clk_seq_hi_res bit0--bit5
	buf[8] = (unsigned char)((clock_seq &0X3F00 )>>8);
	//clk_seq_lo
	buf[9] = (unsigned char)((clock_seq &0X00FF )>>0);

	//reserved bit7=1,bit6=0
	buf[8] |= 0X80;

	//node
	buf[10] = node[0];
	buf[11] = node[1];
	buf[12] = node[2];
	buf[13] = node[3];
	buf[14] = node[4];
	buf[15] = node[5];
	
	//…˙≥…◊÷∑˚¥Æ∏Ò Ωµƒuuid
	char tempbuf[8];
	std::string strUuid;
	for(int i=0;i<16;i++)
	{
		sprintf(tempbuf,"%02X",buf[i]);
		strUuid += tempbuf;
		if ( i == 3 || i == 5 || i == 7 || i == 9 /*|| i == 11*/ )
		{
			strUuid += "-";
		}
	}
	return strUuid;
}

#ifdef PLAT_WIN32
#include <iphlpapi.h>
#include <ws2tcpip.h>
#else
#include<net/if.h>
//#include <net/if_arp.h>
#endif

unsigned int GetMacAddr()
#ifdef PLAT_WIN32
{
	unsigned int uiMac = 0;

    IP_ADAPTER_ADDRESSES* iface_list = NULL;
    ULONG size = sizeof(IP_ADAPTER_INFO);

	//DEBUG_TRACE("Enter");

	// get the interface table
    for(;;)
	{
        iface_list = (IP_ADAPTER_ADDRESSES*)malloc(size);
        DWORD result = GetAdaptersAddresses(AF_INET,
                                            0,
                                            NULL,
                                            iface_list, &size);
        if ( NO_ERROR == result )
		{
            break;
        }
		else
		{
            // free and try again
            free(iface_list);
            if ( ERROR_BUFFER_OVERFLOW != result )
			{
				ERROR_TRACE("GetAdapterAddress failed,err="<<result<<".");
                return uiMac;
            }
        }
    }

    // iterate over the interfaces
    for (IP_ADAPTER_ADDRESSES* iface = iface_list; iface; iface = iface->Next)
	{
        // skip this interface if it is not up
        if ( IfOperStatusUp != iface->OperStatus )
		{
			DEBUG_TRACE("iface is not up skip : IF_TYPE_ETHERNET_CSMACD");
			continue;
		}

        // get the interface type and mac address
        //NPT_MacAddress::Type mac_type;
        switch ( iface->IfType )
		{
            case IF_TYPE_ETHERNET_CSMACD:
				//mac_type = NPT_MacAddress::TYPE_ETHERNET;
				DEBUG_TRACE("iface type : IF_TYPE_ETHERNET_CSMACD");
				break;
            case IF_TYPE_SOFTWARE_LOOPBACK:
				//mac_type = NPT_MacAddress::TYPE_LOOPBACK;
				DEBUG_TRACE("iface type : IF_TYPE_SOFTWARE_LOOPBACK");
				continue;
				//break;
            case IF_TYPE_PPP:
				//mac_type = NPT_MacAddress::TYPE_PPP;
				DEBUG_TRACE("iface type : IF_TYPE_PPP");
				continue;
				//break;
            default:
				//mac_type = NPT_MacAddress::TYPE_UNKNOWN;
				DEBUG_TRACE("iface type : UNKNOWN");
				continue;
				//break;
        }
       // NPT_MacAddress mac(mac_type, iface->PhysicalAddress, iface->PhysicalAddressLength);
		if ( 0 < iface->PhysicalAddressLength )
		{
			char szMac[3*8];
			const char hex[17] = "0123456789abcdef";

			for(int i=0;i<iface->PhysicalAddressLength;i++)
			{
				szMac[i*3  ] = hex[iface->PhysicalAddress[i]>>4];
				szMac[i*3+1] = hex[iface->PhysicalAddress[i]&0xf];
				szMac[i*3+2] = ':';
			}
			szMac[3*iface->PhysicalAddressLength-1] = '\0';
			DEBUG_TRACE("mac addr "<<szMac);
			uiMac = (unsigned int)( (unsigned int)iface->PhysicalAddress[0]<<24
				                   | (unsigned int)iface->PhysicalAddress[1]<<16
								   | (unsigned int)iface->PhysicalAddress[2]<<8);
			break;
		}

		


    }

    free(iface_list);

    return uiMac;
}
#else
{
	unsigned int uiMac = 0;
	//DEBUG_TRACE("Enter");

	int net = socket(AF_INET,SOCK_DGRAM,0);

	// Try to get the config until we have enough memory for it
	// According to "Unix Network Programming", some implementations
	// do not return an error when the supplied buffer is too small
	// so we need to try, increasing the buffer size every time, 
	// until we get the same size twice. We cannot assume success when
	// the returned size is smaller than the supplied buffer, because
	// some implementations can return less that the buffer size if
	// another structure does not fit.
	unsigned int buffer_size = 4096; // initial guess
	unsigned int last_size = 0;
	struct ifconf config;
	unsigned char* buffer;
	for (;buffer_size < 65536;)
	{
		buffer = new unsigned char[buffer_size];
		config.ifc_len = buffer_size;
		config.ifc_buf = (char*)buffer;
		if (ioctl(net,SIOCGIFCONF,&config) < 0)
		{
			if (errno != EINVAL || last_size != 0)
			{
				ERROR_TRACE("ioctl SIOCGIFCONF failed,err="<<errno);
				return uiMac;
			}
		}
		else
		{
			if ((unsigned int)config.ifc_len == last_size)
			{
				// same size, we can use the buffer
				break;
			}
			// different size, we need to reallocate
			last_size = config.ifc_len;
		} 

		// supply 4096 more bytes more next time around
		buffer_size += 4096;
		delete[] buffer;
	}

	// iterate over all objects
	unsigned char *entries;
	for (entries = (unsigned char*)config.ifc_req; entries < (unsigned char*)config.ifc_req+config.ifc_len;)
	{
		struct ifreq* entry = (struct ifreq*)entries;

		// point to the next entry
		entries += sizeof(struct ifreq);

		// ignore anything except AF_INET and AF_LINK addresses
		if (entry->ifr_addr.sa_family != AF_INET )
		{
			DEBUG_TRACE("not AF_INET type.");
			continue;
		}


		// get the mac address        
#if defined(SIOCGIFHWADDR)
		struct ifreq query = *entry;
		if (ioctl(net, SIOCGIFHWADDR, &query) == 0)
		{
			//NPT_MacAddress::Type mac_addr_type;
			unsigned int mac_addr_length = IFHWADDRLEN;
			switch (query.ifr_addr.sa_family)
			{
#if defined(ARPHRD_ETHER)
		case ARPHRD_ETHER:
			//mac_addr_type = NPT_MacAddress::TYPE_ETHERNET;
			DEBUG_TRACE("if type ARPHRD_ETHER.");
			break;
#endif

#if defined(ARPHRD_LOOPBACK)
		case ARPHRD_LOOPBACK:
			//mac_addr_type = NPT_MacAddress::TYPE_LOOPBACK;
			//length = 0;
			DEBUG_TRACE("if type ARPHRD_LOOPBACK.");
			continue;
			break;
#endif

#if defined(ARPHRD_PPP)
		case ARPHRD_PPP:
			//mac_addr_type = NPT_MacAddress::TYPE_PPP;
			mac_addr_length = 0;
			DEBUG_TRACE("if type ARPHRD_PPP.");
			break;
#endif

#if defined(ARPHRD_IEEE80211)
		case ARPHRD_IEEE80211:
			//mac_addr_type = NPT_MacAddress::TYPE_IEEE_802_11;
			DEBUG_TRACE("if type ARPHRD_IEEE80211.");
			break;
#endif

		default:
			//mac_addr_type = NPT_MacAddress::TYPE_UNKNOWN;
			mac_addr_length = sizeof(query.ifr_addr.sa_data);
			DEBUG_TRACE("if type UNKNOWN.");
			break;
			}

			if ( 0 < mac_addr_length )
			{
				char szMac[3*8];
				const char hex[17] = "0123456789abcdef";
				unsigned char *mac_addr_ii = (unsigned char*)query.ifr_ifru.ifru_hwaddr.sa_data;

				for(int i=0;i<mac_addr_length;i++)
				{
					szMac[i*3  ] = hex[mac_addr_ii[i]>>4];
					szMac[i*3+1] = hex[mac_addr_ii[i]&0xf];
					szMac[i*3+2] = ':';
				}
				szMac[3*mac_addr_length-1] = '\0';
				DEBUG_TRACE("mac addr "<<szMac);
				uiMac = (unsigned int)( (unsigned int)mac_addr_ii[0]<<24
											| (unsigned int)mac_addr_ii[1]<<16
											| (unsigned int)mac_addr_ii[2]<<8);
				break;
			}

		}
#endif

	}

	// free resources
	delete[] buffer;
	close(net);

	return 0;
}
#endif

unsigned long long GetMacAddrEx()
#ifdef PLAT_WIN32
{
	static unsigned long long s_ullMac = 0;

	if ( s_ullMac != 0 ) //≤ª «µ⁄“ª¥Œ∂¡»°,÷±Ω”∑µªÿmacµÿ÷∑
	{
		return s_ullMac;
	}

    IP_ADAPTER_ADDRESSES* iface_list = NULL;
    ULONG size = sizeof(IP_ADAPTER_INFO);

	//DEBUG_TRACE("Enter");

	// get the interface table
    for(;;)
	{
        iface_list = (IP_ADAPTER_ADDRESSES*)malloc(size);
        DWORD result = GetAdaptersAddresses(AF_INET,
                                            0,
                                            NULL,
                                            iface_list, &size);
        if ( NO_ERROR == result )
		{
            break;
        }
		else
		{
            // free and try again
            free(iface_list);
            if ( ERROR_BUFFER_OVERFLOW != result )
			{
				ERROR_TRACE("GetAdapterAddress failed,err="<<result<<".");
                return s_ullMac;
            }
        }
    }

    // iterate over the interfaces
    for (IP_ADAPTER_ADDRESSES* iface = iface_list; iface; iface = iface->Next)
	{
        // skip this interface if it is not up
        if ( IfOperStatusUp != iface->OperStatus )
		{
			DEBUG_TRACE("iface is not up skip : IF_TYPE_ETHERNET_CSMACD");
			continue;
		}

        // get the interface type and mac address
        //NPT_MacAddress::Type mac_type;
        switch ( iface->IfType )
		{
            case IF_TYPE_ETHERNET_CSMACD:
				//mac_type = NPT_MacAddress::TYPE_ETHERNET;
				DEBUG_TRACE("iface type : IF_TYPE_ETHERNET_CSMACD");
				break;
            case IF_TYPE_SOFTWARE_LOOPBACK:
				//mac_type = NPT_MacAddress::TYPE_LOOPBACK;
				DEBUG_TRACE("iface type : IF_TYPE_SOFTWARE_LOOPBACK");
				continue;
				//break;
            case IF_TYPE_PPP:
				//mac_type = NPT_MacAddress::TYPE_PPP;
				DEBUG_TRACE("iface type : IF_TYPE_PPP");
				continue;
				//break;
            default:
				//mac_type = NPT_MacAddress::TYPE_UNKNOWN;
				DEBUG_TRACE("iface type : UNKNOWN");
				continue;
				//break;
        }
       // NPT_MacAddress mac(mac_type, iface->PhysicalAddress, iface->PhysicalAddressLength);
		if ( 0 < iface->PhysicalAddressLength )
		{
			char szMac[3*8];
			const char hex[17] = "0123456789abcdef";

			for(int i=0;i<iface->PhysicalAddressLength;i++)
			{
				szMac[i*3  ] = hex[iface->PhysicalAddress[i]>>4];
				szMac[i*3+1] = hex[iface->PhysicalAddress[i]&0xf];
				szMac[i*3+2] = ':';
			}
			szMac[3*iface->PhysicalAddressLength-1] = '\0';
			DEBUG_TRACE("mac addr "<<szMac);
			s_ullMac = (unsigned long long)( (unsigned long long)iface->PhysicalAddress[0]<<40
											| (unsigned long long)iface->PhysicalAddress[1]<<32
											| (unsigned long long)iface->PhysicalAddress[2]<<24
											| (unsigned long long)iface->PhysicalAddress[3]<<16
											| (unsigned long long)iface->PhysicalAddress[4]<<8
											| (unsigned long long)iface->PhysicalAddress[5]<<0);
			break;
		}

		


    }

    free(iface_list);

    return s_ullMac;
}
#else
{
	static unsigned long long s_ullMac = 0;
	if ( s_ullMac != 0 ) //≤ª «µ⁄“ª¥Œ∂¡»°,÷±Ω”∑µªÿmacµÿ÷∑
	{
		return s_ullMac;
	}

	//DEBUG_TRACE("Enter");

	int net = socket(AF_INET,SOCK_DGRAM,0);

	// Try to get the config until we have enough memory for it
	// According to "Unix Network Programming", some implementations
	// do not return an error when the supplied buffer is too small
	// so we need to try, increasing the buffer size every time, 
	// until we get the same size twice. We cannot assume success when
	// the returned size is smaller than the supplied buffer, because
	// some implementations can return less that the buffer size if
	// another structure does not fit.
	unsigned int buffer_size = 4096; // initial guess
	unsigned int last_size = 0;
	struct ifconf config;
	unsigned char* buffer;
	for (;buffer_size < 65536;)
	{
		buffer = new unsigned char[buffer_size];
		config.ifc_len = buffer_size;
		config.ifc_buf = (char*)buffer;
		if (ioctl(net,SIOCGIFCONF,&config) < 0)
		{
			if (errno != EINVAL || last_size != 0)
			{
				ERROR_TRACE("ioctl SIOCGIFCONF failed,err="<<errno);
				return s_ullMac;
			}
		}
		else
		{
			if ((unsigned int)config.ifc_len == last_size)
			{
				// same size, we can use the buffer
				break;
			}
			// different size, we need to reallocate
			last_size = config.ifc_len;
		} 

		// supply 4096 more bytes more next time around
		buffer_size += 4096;
		delete[] buffer;
	}

	// iterate over all objects
	unsigned char *entries;
	for (entries = (unsigned char*)config.ifc_req; entries < (unsigned char*)config.ifc_req+config.ifc_len;)
	{
		struct ifreq* entry = (struct ifreq*)entries;

		// point to the next entry
		entries += sizeof(struct ifreq);

		// ignore anything except AF_INET and AF_LINK addresses
		if (entry->ifr_addr.sa_family != AF_INET )
		{
			DEBUG_TRACE("not AF_INET type.");
			continue;
		}


		// get the mac address        
#if defined(SIOCGIFHWADDR)
		struct ifreq query = *entry;
		if (ioctl(net, SIOCGIFHWADDR, &query) == 0)
		{
			//NPT_MacAddress::Type mac_addr_type;
			unsigned int mac_addr_length = IFHWADDRLEN;
			switch (query.ifr_addr.sa_family)
			{
#if defined(ARPHRD_ETHER)
		case ARPHRD_ETHER:
			//mac_addr_type = NPT_MacAddress::TYPE_ETHERNET;
			DEBUG_TRACE("if type ARPHRD_ETHER.");
			break;
#endif

#if defined(ARPHRD_LOOPBACK)
		case ARPHRD_LOOPBACK:
			//mac_addr_type = NPT_MacAddress::TYPE_LOOPBACK;
			//length = 0;
			DEBUG_TRACE("if type ARPHRD_LOOPBACK.");
			continue;
			break;
#endif

#if defined(ARPHRD_PPP)
		case ARPHRD_PPP:
			//mac_addr_type = NPT_MacAddress::TYPE_PPP;
			mac_addr_length = 0;
			DEBUG_TRACE("if type ARPHRD_PPP.");
			break;
#endif

#if defined(ARPHRD_IEEE80211)
		case ARPHRD_IEEE80211:
			//mac_addr_type = NPT_MacAddress::TYPE_IEEE_802_11;
			DEBUG_TRACE("if type ARPHRD_IEEE80211.");
			break;
#endif

		default:
			//mac_addr_type = NPT_MacAddress::TYPE_UNKNOWN;
			mac_addr_length = sizeof(query.ifr_addr.sa_data);
			DEBUG_TRACE("if type UNKNOWN.");
			break;
			}

			if ( 0 < mac_addr_length )
			{
				char szMac[3*8];
				const char hex[17] = "0123456789abcdef";
				unsigned char *mac_addr_ii = (unsigned char*)query.ifr_ifru.ifru_hwaddr.sa_data;

				for(int i=0;i<mac_addr_length;i++)
				{
					szMac[i*3  ] = hex[mac_addr_ii[i]>>4];
					szMac[i*3+1] = hex[mac_addr_ii[i]&0xf];
					szMac[i*3+2] = ':';
				}
				szMac[3*mac_addr_length-1] = '\0';
				DEBUG_TRACE("mac addr "<<szMac);
				s_ullMac = (unsigned long long)( (unsigned long long)mac_addr_ii[0]<<40
												 | (unsigned long long)mac_addr_ii[1]<<32
												 | (unsigned long long)mac_addr_ii[2]<<24
												 | (unsigned long long)mac_addr_ii[3]<<16
												 | (unsigned long long)mac_addr_ii[4]<<8
												 | (unsigned long long)mac_addr_ii[5]<<0);
				break;
			}

		}
#endif

	}

	// free resources
	delete[] buffer;
	close(net);

	return s_ullMac;
}
#endif

////////////////class CEventTask///////////////////
CEventTask::CEventTask(CEventSuscribler *aUser)
{
	user = aUser;
	if ( user )
	{
		strCallback = user->m_strCallbackUrl;
		strSid = user->m_strSid;
		strUserId = user->m_strUserId;
		uiSeq = user->CreateEventSeq();
	}
	else
	{
		uiSeq = 0;
	}
}
CEventTask::CEventTask(StateVariable *aVar,CEventSuscribler *aUser)
{
	//var = aVar;
	user = aUser;
	if ( aVar && aUser )
	{
		strCallback = user->m_strCallbackUrl;
		strSid = user->m_strSid;
		strUserId = user->m_strUserId;
		uiSeq = user->CreateEventSeq();
		vecArgs.push_back(NameValue(aVar->strName,aVar->strValue));
	}
	else
	{
		uiSeq = 0;
	}
}
CEventTask::CEventTask(Service *aService,CEventSuscribler *aUser)
{
	//var = aVar;
	user = aUser;
	if ( aService && aUser )
	{
		strCallback = user->m_strCallbackUrl;
		strSid = user->m_strSid;
		strUserId = user->m_strUserId;
		uiSeq = user->CreateEventSeq();

		for(size_t i=0;i<aService->vecStateVariables.size();i++)
		{
			if ( aService->vecStateVariables[i]->bSendEvents )
			{
				//vecArgs.push_back(NameValue(aService->vecStateVariables[i]->strName
				//							,aService->vecStateVariables[i]->strValue));
				AddVar(aService->vecStateVariables[i]);
			}
		}
	
	}
	else
	{
		uiSeq = 0;
	}
}
void CEventTask::AddVar(StateVariable *aVar)
{
	vecArgs.push_back(NameValue(aVar->strName,aVar->strValue));
}
CEventTask::~CEventTask()
{
}

typedef struct
{
	char szmethod[256];
	int iId;
}method_list;
method_list g_method_list[] = 
{
	{ /*METHOD_REGISTER_REQ*/ACTION_REGISTER_REQ,		emMethod_RegisterReq },
	{ /*METHOD_REGISTER_RSP*/ACTION_REGISTER_RSP,		emMethod_RegisterRsp },
	{ /*METHOD_KEEPALIVE_REQ*/ACTION_KEEPALIVE_REQ,		emMethod_KeepaliveReq },
	{ /*METHOD_KEEPALIVE_RSP*/ACTION_KEEPALIVE_RSP,		emMethod_KeepaliveRsp },
	{ /*METHOD_UNREGISTER_REQ*/ACTION_UNREGISTER_REQ,	emMethod_UnRegisterReq },
	{ /*METHOD_UNREGISTER_RSP*/ACTION_UNREGISTER_RSP,	emMethod_UnRegisterRsp },
};

int LookupMethod(const char *method)
{
	int iSize = sizeof(g_method_list)/sizeof(g_method_list[0]);
	for(int i=0;i<iSize;i++)
	{
		if ( 0 == strncmp(method,g_method_list[i].szmethod,strlen(method)) )
		{
			return g_method_list[i].iId;
		}
	}
	return -1;
}

//»’∆⁄
char rfc1123_wkday[7][4] =
{
	"Mon",
	"Tue",
	"Wed",
	"Thu",
	"Fri",
	"Sat",
	"Sun"
};
//‘¬∑›
char rfc1123_month[12][4] =
{
	"Jan",
	"Feb",
	"Mar",
	"Apr",
	"May",
	"Jun",
	"Jul",
	"Aug",
	"Sep",
	"Oct",
	"Nov",
	"Dec"
};
//ªÒ»°µ±«∞ ±º‰ rfc1123÷–∂®“Âµƒ∏Ò Ω wkday "," SP 2DIGIT SP month SP 4DIGIT SP 2DIGIT ":" 2DIGIT ":" 2DIGIT
char *GetIso1123Date()
{
	static char s_rfc1123_time[64] = {0};
	struct tm *pTm;
	int iYear,iMonth,iDay,iWeek,iHour,iMinute,iSecond;

	time_t ltime;
	ltime = time(NULL);
	pTm =gmtime(&ltime);

//#ifdef PLAT_WIN32
//	time_t ltime;
//	ltime = time(NULL);
//	pTm =gmtime(&ltime);
//#else
//	iTime = time(NULL);
//	pTm = gmtime(&iTime);
//#endif
	if ( !pTm )
	{
		return s_rfc1123_time;
	}
	iWeek = pTm->tm_wday;
	iYear = pTm->tm_year+1900;
	iMonth = pTm->tm_mon;
	iDay = pTm->tm_mday;
	iHour = pTm->tm_hour;
	iMinute = pTm->tm_min;
	iSecond = pTm->tm_sec;

	sprintf(s_rfc1123_time,"%s,%02d %s %04d %02d:%02d:%02d GMT",rfc1123_wkday[iWeek],iDay,rfc1123_month[iMonth],iYear,iHour,iMinute,iSecond);
	return s_rfc1123_time;
}

std::string HttpAuth::ToString()
{
	std::string strResult;
	if ( strScheme.empty() ) //»œ÷§∑Ω Ω,≤ªƒ‹Œ™ø’
	{
		return strResult;
	}
	if ( strScheme == "Basic" )
	{
		strResult = strScheme;
		if ( bIsResponse )
		{
			strResult += " ";
			strResult += strResponse;
		}
		else
		{
			strResult += " ";
			strResult += "realm=\"";
			strResult += strRealm;
			strResult += "\"";
		}
		return strResult;
	}
	else if ( strScheme != "Digest" )
	{
		//¥ÌŒÛ,≤ªƒ‹ ∂±µƒ»œ÷§À„∑®
		return strResult;
	}
	strResult = strScheme;
	bool bFirstParam = true;
	if ( !strUsername.empty() )
	{
		if ( bFirstParam )
		{
			strResult += " ";
			bFirstParam = false;
		}
		else
		{
			strResult += ",";
		}
		strResult += "username=\"";
		strResult += strUsername;
		strResult += "\"";
	}
	if ( !strRealm.empty() ) //∏√◊÷∂Œ≤ªƒ‹Œ™ø’
	{
		if ( bFirstParam )
		{
			strResult += " ";
			bFirstParam = false;
		}
		else
		{
			strResult += ",";
		}
		strResult += "realm=\"";
		strResult += strRealm;
		strResult += "\"";
	}
	else
	{
		return std::string("");
	}
	if ( !strNonce.empty() ) //∏√◊÷∂Œ≤ªƒ‹Œ™ø’
	{
		if ( bFirstParam )
		{
			strResult += " ";
			bFirstParam = false;
		}
		else
		{
			strResult += ",";
		}
		strResult += "nonce=\"";
		strResult += strNonce;
		strResult += "\"";
	}
	else
	{
		return std::string("");
	}
	if ( !strUri.empty() )
	{
		if ( bFirstParam )
		{
			strResult += " ";
			bFirstParam = false;
		}
		else
		{
			strResult += ",";
		}
		strResult += "uri=\"";
		strResult += strUri;
		strResult += "\"";
	}
	if ( !strResponse.empty() )
	{
		if ( bFirstParam )
		{
			strResult += " ";
			bFirstParam = false;
		}
		else
		{
			strResult += ",";
		}
		strResult += "response=\"";
		strResult += strResponse;
		strResult += "\"";
	}

	//∆‰À˚◊÷∂Œ
	for(size_t i=0;i<params.size();i++)
	{
		strResult += ",";
		strResult += params[i].m_strArgumentName;
		strResult += "=";
		strResult += params[i].m_strArgumentValue;
	}
	return strResult;
}

//Ω‚ŒˆWWW-Authenticate
bool ParseHttpAuthParams(const std::string &strAuth,HttpAuth &auth,bool bIsResponse)
{
	bool bRet = false;
	std::string strSchme;
	std::string strName;
	std::string strValue;

	if ( strAuth.empty() )
	{
		return false;
	}
	
	char *pstart = (char*)strAuth.c_str();
	char *pend = (char*)strAuth.c_str()+strAuth.size();
	char *pcur = pstart;
	char *pnode;
	//Ω‚ŒˆÕ∑≤ø
	while( pcur!=pend&&*pcur==' ' ) pcur++;
	if ( pcur == pend )
	{
		return false;
	}
	pnode=pcur;
	while( pcur!=pend&&*pcur!=' ' ) pcur++;
	if ( pcur == pend )
	{
		return false;
	}
	strSchme = std::string(pnode,pcur);
	auth.strScheme = strSchme;
	if ( strSchme == "Basic" )
	{
		if ( bIsResponse )
		{
			while( pcur!=pend&&*pcur==' ' ) pcur++;
			if ( pcur == pend )
			{
				return false;
			}
			auth.strResponse = pcur;
			return true;
		}
	}
	else if ( strSchme == "Digest" )
	{
	}
	else
	{
		return false;
	}
	bool bFinish = false;
	do
	{
		while( pcur!=pend&&*pcur==' ' ) pcur++;
		if ( pcur == pend )
		{
			bFinish = true;
			break;
		}
		pnode=pcur;
		while( pcur!=pend&&*pcur!='=' ) pcur++;
		if ( pcur == pend )
		{
			bFinish = true;
			return false;
			//break;
		}
		strName = std::string(pnode,pcur);
		pcur++;
		pnode=pcur;
		while( pcur!=pend&&*pcur!=',' ) pcur++;
		if ( pcur == pend )
		{
			bFinish = true;
			//return false;
			//break;
			strValue = std::string(pnode,pcur);
			TrimString<CIsSpace>(strValue,CIsSpace());
			if ( strValue.size() > 0 && strValue[0] == '\"' )
			{
				TrimString<CIsQuote>(strValue,CIsQuote());
			}
			if ( ToLowwer(strName) == "username" )
			{
				auth.strUsername = strValue;
			}
			else if ( ToLowwer(strName) == "realm" )
			{
				auth.strRealm = strValue;
			}
			else if ( ToLowwer(strName) == "nonce" )
			{
				auth.strNonce = strValue;
			}
			else if ( ToLowwer(strName) == "uri" )
			{
				auth.strUri = strValue;
			}
			else if ( ToLowwer(strName) == "response" )
			{
				auth.strResponse = strValue;
			}
			else
			{
				auth.params.push_back(NameValue(strName,strValue));
			}
		}
		else
		{
			strValue = std::string(pnode,pcur);
			TrimString<CIsSpace>(strValue,CIsSpace());
			if ( strValue.size() > 0 && strValue[0] == '\"' )
			{
				TrimString<CIsQuote>(strValue,CIsQuote());
			}
			if ( ToLowwer(strName) == "username" )
			{
				auth.strUsername = strValue;
			}
			else if ( ToLowwer(strName) == "realm" )
			{
				auth.strRealm = strValue;
			}
			else if ( ToLowwer(strName) == "nonce" )
			{
				auth.strNonce = strValue;
			}
			else if ( ToLowwer(strName) == "uri" )
			{
				auth.strUri = strValue;
			}
			else if ( ToLowwer(strName) == "response" )
			{
				auth.strResponse = strValue;
			}
			else
			{
				auth.params.push_back(NameValue(strName,strValue));
			}
			pcur++;
		}

	}while(!bFinish);

	return true;
}

std::string CalcAuthMd5(const std::string &strUsername,const std::string &strPassword,const std::string &strRealm,const std::string &strNonce,const std::string &strMethod,const std::string &strUri)
{
	std::string strMd5String;
	std::string strA1;
	std::string strA2;
	struct MD5Context md5c;
	unsigned char ucResult[16];
	char szTemp[16];

	//º∆À„A1 A1 = MD5(username:realm:password)
	strMd5String = strUsername;
	strMd5String += ":";
	strMd5String = strRealm;
	strMd5String += ":";
	strMd5String = strPassword;

	MD5Init(&md5c);
	MD5Update(&md5c,(unsigned char*)strMd5String.c_str(),strMd5String.size());
	MD5Final(ucResult,&md5c);
	for(int i=0; i<16; i++ )
	{
		sprintf(szTemp,"%02x",ucResult[i]);
		strA1 += szTemp;
	}

	//º∆À„A2 A2 = MD5(method:uri)
	strMd5String = strMethod;
	strMd5String += ":";
	strMd5String = strUri;
	MD5Init(&md5c);
	MD5Update(&md5c,(unsigned char*)strMd5String.c_str(),strMd5String.size());
	MD5Final(ucResult,&md5c);
	for(int i=0; i<16; i++ )
	{
		sprintf(szTemp,"%02x",ucResult[i]);
		strA2 += szTemp;
	}

	//º∆À„Ω·π˚ MD5(H(A1):nonce:H(A2))
	strMd5String = strA1;
	strMd5String += ":";
	strMd5String = strNonce;
	strMd5String += ":";
	strMd5String = strA2;
	MD5Init(&md5c);
	MD5Update(&md5c,(unsigned char*)strMd5String.c_str(),strMd5String.size());
	MD5Final(ucResult,&md5c);
	strMd5String = "";
	for(int i=0; i<16; i++ )
	{
		sprintf(szTemp,"%02x",ucResult[i]);
		strMd5String += szTemp;
	}

	// ‰≥ˆ
	return strMd5String;
}

//…˙≥…ÀÊª˙÷÷◊”  ±º‰+mac+ÀÊª˙ ˝
std::string MakeNonce()
{
	unsigned char buf[16];
	unsigned char node[6];
	unsigned char cs[2];
	unsigned long long mac_addr;
	static unsigned short clock_seq = 0;
	unsigned long long sys_time;

	//ªÒ»°µ±«∞ ±º‰
	sys_time = GetSysTime100ns();
	//ªÒ»°macµÿ÷∑
	mac_addr = GetMacAddrEx();
	if ( 0 == mac_addr )
	{
		GenerateRand(node,6);
		node[0] |= 0x01; //∂‡≤•µÿ÷∑ 
	}
	else // π”√macµÿ÷∑
	{
		node[0] = ((mac_addr & 0X0000FF0000000000ULL)>>40);
		node[1] = ((mac_addr & 0X000000FF00000000ULL)>>32);
		node[2] = ((mac_addr & 0X00000000FF000000ULL)>>24);
		node[3] = ((mac_addr & 0X0000000000FF0000ULL)>>16);
		node[4] = ((mac_addr & 0X000000000000FF00ULL)>>8);
		node[5] = ((mac_addr & 0X00000000000000FFULL)>>0);

		node[0] |= 0x01; //∂‡≤•µÿ÷∑ 
	}
	if ( 0 == clock_seq )
	{
		//µ⁄“ª¥Œ,…˙≥…ÀÊª˙÷µ
		GenerateRand(cs,2);
		
		clock_seq = cs[0];
		clock_seq <<= 8;
		clock_seq |= cs[1];
	}
	else
	{
	}

	//…˙≥…uuid
	//time_low
	buf[0] = (unsigned char)((sys_time &0X00000000FF000000ULL )>>24);
	buf[1] = (unsigned char)((sys_time &0X0000000000FF0000ULL )>>16);
	buf[2] = (unsigned char)((sys_time &0X000000000000FF00ULL )>>8);
	buf[3] = (unsigned char)((sys_time &0X00000000000000FFULL )>>0);

	//time_mid
	buf[4] = (unsigned char)((sys_time &0X0000FF0000000000ULL )>>40);
	buf[5] = (unsigned char)((sys_time &0X000000FF00000000ULL )>>32);

	//time_hi_and_version bit0--bit3
	buf[6] = (unsigned char)((sys_time &0X0F00000000000000ULL )>>56);
	buf[7] = (unsigned char)((sys_time &0X00FF000000000000ULL )>>48);
	//version 1 bit4--bit7
	buf[6] |= ((unsigned char)1<<4);

	//clk_seq_hi_res bit0--bit5
	buf[8] = (unsigned char)((clock_seq &0X3F00 )>>8);
	//clk_seq_lo
	buf[9] = (unsigned char)((clock_seq &0X00FF )>>0);

	//reserved bit7=1,bit6=0
	buf[8] |= 0X80;

	//node
	buf[10] = node[0];
	buf[11] = node[1];
	buf[12] = node[2];
	buf[13] = node[3];
	buf[14] = node[4];
	buf[15] = node[5];
	
	//…˙≥…◊÷∑˚¥Æ∏Ò Ωµƒuuid
	char tempbuf[8];
	std::string strUuid;
	for(int i=0;i<16;i++)
	{
		sprintf(tempbuf,"%02x",buf[i]);
		strUuid += tempbuf;
		if ( i == 3 || i == 5 || i == 7 || i == 9 || i == 11 )
		{
			//strUuid += "-";
		}
	}

	//ÀÊª˙…˙≥…≤ª∂®≥§µƒ¥Æ(1-16)
	unsigned char ucRdBuf[16];
	int iRdBytes;
	GenerateRand(ucRdBuf,1);
	iRdBytes = (ucRdBuf[0]%16)+1;

	GenerateRand(ucRdBuf,iRdBytes);
	for(int i=0;i<iRdBytes;i++)
	{
		sprintf(tempbuf,"%02x",ucRdBuf[i]);
		strUuid += tempbuf;
		//if ( i == 3 || i == 5 || i == 7 || i == 9 || i == 11 )
		//{
		//	//strUuid += "-";
		//}
	}

	return strUuid;
}

std::string CalcAuthVerifyMd5(const std::string &strPassword,const std::string &strNonce,const std::string &strDeviceSerial)
{
	std::string strMd5String;
	std::string strA1;
	std::string strA2;
	struct MD5Context md5c;
	unsigned char ucResult[16];
	char szTemp[16];

	strMd5String = strDeviceSerial;
	strMd5String += ":";
	strMd5String = strNonce;
	strMd5String += ":";
	strMd5String = strPassword;

	MD5Init(&md5c);
	MD5Update(&md5c,(unsigned char*)strMd5String.c_str(),strMd5String.size());
	MD5Final(ucResult,&md5c);
	for(int i=0; i<16; i++ )
	{
		sprintf(szTemp,"%02x",ucResult[i]);
		strMd5String += szTemp;
	}

	// ‰≥ˆ
	return strMd5String;
}

std::string CalcBasic(const std::string &strUsername,const std::string &strPassword)
{
	std::string strString;
	std::string strBase64String;
	char szBuf[256] = {0};

	strString = strUsername;
	strString += ":";
	strString = strPassword;
	if ( strString.size() > 128 ) //Ã´≥§
	{
		return std::string("");
	}

	// ‰≥ˆ
	Base64Encode((unsigned char*)strString.c_str(),(unsigned int)strString.size(),szBuf);
	strBase64String = szBuf;
	return strBase64String;
}