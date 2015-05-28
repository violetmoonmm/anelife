#ifdef WIN32
# include <winsock.h>
#else
# include <sys/socket.h>
# include <signal.h>
# include <pthread.h>
# include <netdb.h>
# include <arpa/inet.h>
#endif
#include <stdio.h>
#include <time.h>
#include <sstream>
#include <string>
#include "ghttp.h"
#include "json.h"
#include "IcrcHttpClientSdk.h"
#include "MD5Inc.h"

#ifdef WIN32
#  pragma comment(lib,"ws2_32.lib")
#endif

using namespace std;

class DHMutex
{
public:
    DHMutex()
    {
#ifdef WIN32
        InitializeCriticalSection(&m_critclSection);
#else
        pthread_mutex_init(&m_mutex, NULL);
#endif
    }
    ~DHMutex()
    {
#ifdef WIN32
        DeleteCriticalSection(&m_critclSection);
#else
        pthread_mutex_destroy(&m_mutex);
#endif
    }
    void Lock()
    {
#ifdef WIN32
        EnterCriticalSection(&m_critclSection);
#else
        pthread_mutex_lock(&m_mutex);
#endif
    }
    void UnLock()
    {
#ifdef WIN32
        LeaveCriticalSection(&m_critclSection);
#else
        pthread_mutex_unlock(&m_mutex);
#endif
    }
private:
#ifdef WIN32
    CRITICAL_SECTION m_critclSection;
#else
    pthread_mutex_t m_mutex;
#endif
};

class CLock
{
public:
    CLock(DHMutex* pMtx) { m_pMtx = pMtx; m_pMtx->Lock(); }
    ~CLock() { m_pMtx->UnLock(); }
private:
    DHMutex* m_pMtx;
};

DHMutex g_dhmtx;

typedef struct
{
    bool m_runflag;
    std::string m_sIpAddr;
    int					m_iPort;
    std::string m_sUserName;
    std::string m_sPassWord;
    int         m_iClientType;
    int         m_iNetType;
    int         m_iForce;
    std::string m_sMeid;
    std::string m_sVersion;
    std::string m_sCallid;
    fIcrcDisConnect m_cb;
    void*       m_pUserData;
    ICRC_CONNECT_INFO m_conInfo;
    std::string m_sLastVersion; //最新的客户端版本
    std::string m_sUpdateUrl;   //软件版本升级的URL
    std::string m_sToken;  //手机端上次在服务端注册的toke值，如果没有，则此值为空
    std::string m_sVirtualCode;  //用户虚号
    int         m_iEmailCheck;   //邮箱是否已经验证
    std::string	m_sPhone;
    std::string	m_sCity;
    std::string	m_sISP;
    std::string m_seed1;
    std::string m_seed2;
    std::string m_sAuthCodeText;
    std::map<string,string> m_servlist;
} ICRC_HTTP_HANDLE;

static int _http_getservicelist(void *icrc_handle);
static int _Http_KeepAlive(void *icrc_handle);
static int _http_login(void *icrc_handle);

static int _http_process(
                         ICRC_HTTP_HANDLE *phandle,
                         const char *resoure,
                         const char *action,
                         const char *bodystr,
                         unsigned int bodysize,
                         bool needcallid,
                         Json::Value &retval
                         )
{
    std::map<string,string>::iterator iter = phandle->m_servlist.find(resoure);
    if (iter == phandle->m_servlist.end())
        return ICRC_ERROR_HTTP_SERV_NOT_FOUND;
    //
    std::ostringstream uri;
    uri <<"http://"<<phandle->m_sIpAddr<<":"<<phandle->m_iPort<<iter->second;
    //
    ghttp_request *request = ghttp_request_new();
    ghttp_set_uri(request, (char*)uri.str().c_str());
    ghttp_set_sync(request, ghttp_sync);
    ghttp_set_type(request, ghttp_type_post);
    ghttp_set_header(request, "Action", action);
    if (needcallid) {
        ghttp_set_header(request, "CallId", phandle->m_sCallid.c_str());
    }
    ghttp_set_header(request, http_hdr_Content_Type, "text/json; charset=utf-8");
    ghttp_set_body(request, (char*)bodystr, bodysize);
    ghttp_prepare(request);
    //
    if (ghttp_done!=ghttp_process(request))
    {
        ghttp_request_destroy(request);
        return ICRC_ERROR_HTTP_NO_RESPONSE;
    }
    //
    const char *http_result = ghttp_get_body(request);
    int http_result_len = ghttp_get_body_len(request);
    if (!http_result || http_result_len==0)
    {
        ghttp_request_destroy(request);
        return ICRC_ERROR_HTTP_CONTENT_EMPTY;
    }
    //if (!strcmp(resoure,"keepAlive"))
    
    //
    Json::Reader reader;
    if (!reader.parse(http_result, retval))
    {
        ghttp_request_destroy(request);
        return ICRC_ERROR_HTTP_CONTENT_PARSE_FAIL;
    }
    ghttp_request_destroy(request);
    return ICRC_ERROR_OK;
}

static int _http_process_v2(
                            const char *ip,
                            int port,
                            const char *resoure,
                            const char *action,
                            const char *bodystr,
                            unsigned int bodysize,
                            Json::Value &retval
                            )
{
    std::ostringstream uri;
    uri <<"http://"<<ip<<":"<<port<<resoure;
    //
    ghttp_request *request = ghttp_request_new();
    ghttp_set_uri(request, (char*)uri.str().c_str());
    ghttp_set_sync(request, ghttp_sync);
    ghttp_set_type(request, ghttp_type_post);
    ghttp_set_header(request, "Action", action);
    ghttp_set_header(request, http_hdr_Content_Type, "text/json; charset=utf-8");
    ghttp_set_body(request, (char*)bodystr, bodysize);
    ghttp_prepare(request);
    //
    if (ghttp_done!=ghttp_process(request))
    {
        ghttp_request_destroy(request);
        return ICRC_ERROR_HTTP_NO_RESPONSE;
    }
    //
    const char *http_result = ghttp_get_body(request);
    int http_result_len = ghttp_get_body_len(request);
    if (!http_result || http_result_len==0)
    {
        ghttp_request_destroy(request);
        return ICRC_ERROR_HTTP_CONTENT_EMPTY;
    }
    //
    Json::Reader reader;
    if (!reader.parse(http_result, retval))
    {
        ghttp_request_destroy(request);
        return ICRC_ERROR_HTTP_CONTENT_PARSE_FAIL;
    }
    ghttp_request_destroy(request);
    return ICRC_ERROR_OK;
}

void *ThreadRun(void* param)
{
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)param;
    pHandle->m_runflag = true;
    pHandle->m_iForce = 0;
    
    int i = 0;
    int errcnt = 0;
    bool disconnect = false;
    while (pHandle->m_runflag)
    {
        if (i%20==19)
        {
            if (!disconnect)
            {
                int err = _Http_KeepAlive(pHandle);
                if (err!=ICRC_ERROR_OK)
                {
                    errcnt++;
                    if (errcnt==3)
                    {
                        errcnt = 0;
                        disconnect = true;
                        if (pHandle->m_cb)
                        {
                            pHandle->m_cb(pHandle, 1, pHandle->m_pUserData);
                        }
                    }
                }
            }
            else
            {
                int err = _http_login(pHandle);
                {
                    if (err==ICRC_ERROR_OK)
                    {
                        disconnect = false;
                        if (pHandle->m_cb)
                        {
                            pHandle->m_cb(pHandle, 2, pHandle->m_pUserData);
                            pHandle->m_iForce = 0;
                        }
                    }
                    else if (err==ICRC_ERROR_USER_HAS_LOGIN)
                    {
                        if (pHandle->m_cb)
                        {
                            if (true == pHandle->m_cb(pHandle, 3, pHandle->m_pUserData))
                            {
                                pHandle->m_iForce = 1;
                            }
                        }
                    }
                }
            }
        }
#ifdef WIN32
        Sleep(1000);
#else
        usleep(1000*1000);
#endif
        i++;
    }
    
    return NULL;
}

ICRC_HTTPCLIENT_API int ICRC_Http_Login(
                                        void**      icrc_handle, //句柄(传入地址，由内部分配空间)
                                        const char* sIpAddr, //服务器ip地址
                                        int         iPort,   //服务器端口
                                        const char* sUserName, //用户名称
                                        const char* sPassWord, //用户密码
                                        int         iClientType, //客户端类型。1 Android; 2苹果
                                        int         iNetType, //网路类型。1局域网，2公网
                                        int         iForce,  //0:普通登录，1:强制登录
                                        const char* sMeid,    //MEID码
                                        const char* sVersion, //客户端版本号
                                        ICRC_CONNECT_INFO *pConInfo, //服务器返回信息
                                        fIcrcDisConnect cbDisconnect, //服务器断线回调通知
                                        void*       pUserData  //用户数据
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = NULL;
    *icrc_handle = new ICRC_HTTP_HANDLE;
    pHandle = (ICRC_HTTP_HANDLE *)(*icrc_handle);
    pHandle->m_sIpAddr = sIpAddr;
    pHandle->m_iPort = iPort;
    pHandle->m_sUserName = sUserName;
    pHandle->m_sPassWord = sPassWord;
    pHandle->m_iClientType = iClientType;
    pHandle->m_iNetType = iNetType;
    pHandle->m_iForce = iForce;
    pHandle->m_sMeid = sMeid;
    pHandle->m_sVersion = sVersion;
    pHandle->m_cb = cbDisconnect;
    pHandle->m_pUserData = pUserData;
    pHandle->m_servlist.insert(pair<string,string>("regist","/app/zwelife/regist"));
    //
    int err = _http_login(pHandle);
    if (err!=ICRC_ERROR_OK)
        return err;
    strncpy(pConInfo->sCallId, pHandle->m_sCallid.c_str(), sizeof(pConInfo->sCallId));
    strncpy(pConInfo->sLastVersion, pHandle->m_sLastVersion.c_str(), sizeof(pConInfo->sLastVersion));
    strncpy(pConInfo->sToken, pHandle->m_sToken.c_str(), sizeof(pConInfo->sToken));
    strncpy(pConInfo->sUpdateUrl, pHandle->m_sUpdateUrl.c_str(), sizeof(pConInfo->sUpdateUrl));
    strncpy(pConInfo->sVirtualCode, pHandle->m_sVirtualCode.c_str(), sizeof(pConInfo->sVirtualCode));
    strncpy(pConInfo->sPhone, pHandle->m_sPhone.c_str(), sizeof(pConInfo->sPhone));
    strncpy(pConInfo->sCity, pHandle->m_sCity.c_str(), sizeof(pConInfo->sCity));
    strncpy(pConInfo->sISP, pHandle->m_sISP.c_str(), sizeof(pConInfo->sISP));
    strncpy(pConInfo->sAuthCodeText, pHandle->m_sAuthCodeText.c_str(), sizeof(pConInfo->sAuthCodeText));
    pConInfo->iEmailCheck = pHandle->m_iEmailCheck;
    //
    err = _http_getservicelist(pHandle);
    if (err!=ICRC_ERROR_OK)
        return err;
    
    strcpy(pConInfo->sMqBroker, "");
    strcpy(pConInfo->sPushAddr, "");
    std::map<string,string>::iterator iter = pHandle->m_servlist.find("rtms");
    if (iter != pHandle->m_servlist.end())
    {
        const char *rtms = iter->second.c_str();
        if (!strncmp(rtms, "MQ#", strlen("MQ#")))
            strncpy(pConInfo->sMqBroker, rtms+strlen("MQ#"), sizeof(pConInfo->sMqBroker));
        else if (!strncmp(rtms, "APN#", strlen("APN#")))
            strncpy(pConInfo->sPushAddr, rtms+strlen("APN#"), sizeof(pConInfo->sPushAddr));
    }
    
    strcpy(pConInfo->sUpnpServCode, "");
    strcpy(pConInfo->sUpnpAddr, "");
    pConInfo->iUpnpPort = 0;
    std::map<string,string>::iterator iter2 = pHandle->m_servlist.find("remoteUPNP");
    if (iter2 != pHandle->m_servlist.end())
    {
        const char *upnp = iter2->second.c_str();
        sscanf(upnp, "%[^:]:%d?name=%s", pConInfo->sUpnpAddr, &pConInfo->iUpnpPort, pConInfo->sUpnpServCode);
    }
    
#ifdef WIN32
    //	DWORD dwThreadID;
    //	HANDLE thread_h = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)ThreadRun, (LPVOID)pHandle, 0, &dwThreadID);
    //	if(NULL == thread_h)
    //	{
    //		return ICRC_ERROR_CREATE_THREAD_FAIL;
    //	}
#else
    //	pthread_t tid;
    //	int iRet = pthread_create(&tid, NULL, ThreadRun, (void *)pHandle);
    //	if(iRet != 0)
    //	{
    //		return ICRC_ERROR_CREATE_THREAD_FAIL;
    //	}
#endif
    //
    return ICRC_ERROR_OK;
}

static std::string HexToBinary(const std::string &src)
{
    std::string dst;
    int count = src.size() >> 1;
    for (int i = 0; i < count; i++)
    {
        unsigned char hi = src.at(2*i+0);
        unsigned char lo = src.at(2*i+1);
        if      (hi>='0'&&hi<='9') hi = hi-'0';
        else if (hi>='a'&&hi<='f') hi = hi-'a'+10;
        else if (hi>='A'&&hi<='F') hi = hi-'A'+10;
        else    hi = 0;
        if      (lo>='0'&&lo<='9') lo = lo-'0';
        else if (lo>='a'&&lo<='f') lo = lo-'a'+10;
        else if (lo>='A'&&lo<='F') lo = lo-'A'+10;
        else    lo = 0;
        unsigned char hex = (hi<<4) + lo;
        dst.append(1,(char)hex);
    }
    return dst;
}

static std::string BinaryToHex(const std::string &src)
{
    std::string dst;
    int count = src.size();
    for (int i = 0; i < count; i++)
    {
        unsigned char hex = src.at(i);
        unsigned char hi = hex >> 4;
        unsigned char lo = src[i] & 15;
        hi = (hi<10) ? (hi+'0') : (hi-10+'A');
        lo = (lo<10) ? (lo+'0') : (lo-10+'A');
        dst.append(1,(char)hi);
        dst.append(1,(char)lo);
    }
    return dst;
}

static int _http_login(void *icrc_handle)
{
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    // 第一步: 获取种子
    {
        Json::Value root;
        root["req"]["sUserName"  ] = pHandle->m_sUserName;
        root["req"]["sPassWord"  ] = "";
        root["req"]["iClientType"] = pHandle->m_iClientType;
        root["req"]["iNetType"   ] = pHandle->m_iNetType;
        root["req"]["sMeid"      ] = pHandle->m_sMeid;
        root["req"]["sVersion"   ] = pHandle->m_sVersion;
        root["req"]["iForce"     ] = pHandle->m_iForce;
        std::string body = root.toUnStyledString();
        //
        Json::Value jsonObject;
        int err = _http_process(pHandle, "regist", "1#1", body.c_str(), body.size(), false, jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        Json::Value code = jsonObject["code"];
        Json::Value objs = jsonObject["objs"];
        if (!code.isInt())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
        if (!objs.isArray() || !objs.size())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        std::string sSeed = objs[0]["sSeed"].asString();
        int pos = sSeed.find(',');
        if (pos==std::string::npos)
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        pHandle->m_seed1 = sSeed.substr(0, pos);
        pHandle->m_seed2 = sSeed.substr(pos+1);
        

    }
    // 第二步: md5加密
    std::string strMD5Password;
    {
        struct MD5Context md5c;
        unsigned char ucResult[16];
        std::string strTemp;
        
        strMD5Password.assign(pHandle->m_seed1);
        strMD5Password.append(pHandle->m_sPassWord);
        
        MD5Init(&md5c);
        MD5Update(&md5c, (unsigned char*)strMD5Password.data(), strMD5Password.size());
        MD5Final(ucResult, &md5c);
        
        strTemp.assign((char*)ucResult, 16);
        strTemp = BinaryToHex(strTemp);
        strMD5Password.assign(pHandle->m_seed2);
        strMD5Password.append(strTemp);
        
        MD5Init(&md5c);
        MD5Update(&md5c, (unsigned char*)strMD5Password.data(), strMD5Password.size());
        MD5Final(ucResult, &md5c);
        
        strMD5Password.assign((char*)ucResult, 16);
        strMD5Password = BinaryToHex(strMD5Password);
    }
    // 第三步: 登录
    {
        Json::Value root;
        root["req"]["sUserName"  ] = pHandle->m_sUserName;
        root["req"]["sPassWord"  ] = strMD5Password;
        root["req"]["iClientType"] = pHandle->m_iClientType;
        root["req"]["iNetType"   ] = pHandle->m_iNetType;
        root["req"]["sMeid"      ] = pHandle->m_sMeid;
        root["req"]["sVersion"   ] = pHandle->m_sVersion;
        root["req"]["iForce"     ] = pHandle->m_iForce;
        std::string body = root.toUnStyledString();
        //
        Json::Value jsonObject;
        int err = _http_process(pHandle, "regist", "1#1", body.c_str(), body.size(), false, jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        Json::Value code = jsonObject["code"];
        Json::Value objs = jsonObject["objs"];
        if (!code.isInt() || !objs.isArray())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        //
        Json::Value lastver, upurl, callid, token, virno, echk, phone, city, isp, acode;
        lastver = objs[0]["sLastversion"];
        err = code.asInt();
        if (err==0) {
            callid = objs[0]["sCallId"       ];
            token  = objs[0]["sToken"        ];
            virno  = objs[0]["sUserVirtualNo"];
            echk   = objs[0]["iEmailCheck"   ];
            phone  = objs[0]["sPhone"        ];
            city   = objs[0]["sCity"         ];
            isp    = objs[0]["sISP"          ];
            acode  = objs[0]["sAuthCodeText" ];
            pHandle->m_sCallid = callid.asString();
        } else if (err==208) {
            upurl = objs[0]["sUpdateurl"];
        }
        pHandle->m_sLastVersion = lastver.asString();
        pHandle->m_sUpdateUrl = upurl.asString();
        pHandle->m_sToken = token.asString();
        pHandle->m_sVirtualCode = virno.asString();
        pHandle->m_iEmailCheck = echk.asInt();
        pHandle->m_sPhone = phone.asString();
        pHandle->m_sCity = city.asString();
        pHandle->m_sISP = isp.asString();
        pHandle->m_sAuthCodeText = acode.asString();
        return err;
    }
}

ICRC_HTTPCLIENT_API int ICRC_Http_Logout(void *icrc_handle)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    pHandle->m_runflag = false;
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "regist", "1#2", NULL, 0, true, jsonObject);
    delete pHandle;
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code"];
    if (!code.isInt())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    err = code.asInt();
    return err;
}

static int _http_getservicelist(void *icrc_handle)
{
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "regist", "10#9", NULL, 0, true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code"];
    Json::Value objs = jsonObject["objs"];
    if (!code.isInt() || !objs.isArray())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    err = code.asInt();
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    for (unsigned int i = 0; i < objs.size(); i++)
    {
        Json::Value vtype = objs[i]["serviceType"];
        Json::Value vurl  = objs[i]["serviceUrl" ];
        const char *stype = vtype.asCString();
        const char *surl  = vurl.asCString();
        pHandle->m_servlist.insert(pair<string,string>(stype,surl));
    }
    return ICRC_ERROR_OK;
}

ICRC_HTTPCLIENT_API int ICRC_Http_RegisterToken(
                                                void *icrc_handle, //句柄
                                                const char *sToken //token值
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    //
    std::string body;
    Json::Value root, req;
    req["sToken"] = sToken;
    root["req"] = req;
    body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "regist", "11#9", body.c_str(), body.size(), true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code"];
    if (!code.isInt())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    err = code.asInt();
    return err;
}

static int _Http_KeepAlive(void *icrc_handle)
{
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "keepAlive", NULL, NULL, 0, true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code"];
    if (!code.isInt())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    err = code.asInt();
    return err;
}

ICRC_HTTPCLIENT_API int ICRC_Http_GetDeviceList(
                                                void *icrc_handle, //句柄
                                                int start_index, //起始索引号, 从0开始，最多一次查询50条，例如start=0,end=50表示查前50条
                                                int end_index,   //结束索引号
                                                ICRC_SMARTHOME_DEVICE_DETAIL **ppDeviceList, //设备详细信息
                                                int *numDevs, //设备数量
                                                const char *sVirtualCode //虚号为空时查询所有设备
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    std::vector<ICRC_SMARTHOME_DEVICE_DETAIL> vecDevList;
    //
    std::string body;
    Json::Value root, req;
    if (sVirtualCode && sVirtualCode[0])
        req["sDevVirtualCode"] = sVirtualCode;
    root["start"] = start_index;
    root["end"  ] = end_index;
    root["req"  ] = req;
    body = root.toUnStyledString();
    //
    //	while (1)
    {
        Json::Value jsonObject;
        int err = _http_process(pHandle, "smartHome", "10#8", body.c_str(), body.size(), true, jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        Json::Value code = jsonObject["code" ];
        Json::Value start= jsonObject["start"];
        Json::Value end  = jsonObject["end"  ];
        Json::Value objs = jsonObject["objs" ];
        if (!code.isInt() || !start.isInt() || !end.isInt() || !objs.isArray())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        //
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        for (unsigned int i = 0; i < objs.size(); i++)
        {
            Json::Value vVirCode = objs[i]["sDevVirtualCode"];
            Json::Value vDevName = objs[i]["sDevName"       ];
            Json::Value vPasswd  = objs[i]["sPasswd"        ];
            Json::Value vNetAddr = objs[i]["sNetwork"       ];
            Json::Value vNetPort = objs[i]["iNetPort"       ];
            Json::Value vDevType = objs[i]["iDevType"       ];
            Json::Value vAddtion = objs[i]["sDevTypeAddtion"];
            Json::Value vPosition= objs[i]["sPosition"      ];
            Json::Value vParma   = objs[i]["sPar1"          ];
            Json::Value vComName = objs[i]["sCommunityName" ];
            Json::Value vStatus  = objs[i]["iStatus"        ];
            Json::Value vSN      = objs[i]["sSn"            ];
            
            ICRC_SMARTHOME_DEVICE_DETAIL dev = {0};
            strncpy(dev.sVirtualCode, vVirCode.asCString(), sizeof(dev.sVirtualCode));
            strncpy(dev.sDevName, vDevName.asCString(), sizeof(dev.sDevName));
            strncpy(dev.sPasswd, vPasswd.asCString(), sizeof(dev.sPasswd));
            strncpy(dev.sNetAddr, vNetAddr.asCString(), sizeof(dev.sNetAddr));
            strncpy(dev.sDevTypeAddtion, vAddtion.asCString(), sizeof(dev.sDevTypeAddtion));
            strncpy(dev.sPosition, vPosition.asCString(), sizeof(dev.sPosition));
            strncpy(dev.sParam1, vParma.asCString(), sizeof(dev.sParam1));
            strncpy(dev.sCommunityName, vComName.asCString(), sizeof(dev.sCommunityName));
            strncpy(dev.sSN, vSN.asCString(), sizeof(dev.sSN));
            dev.iNetPort = vNetPort.asInt();
            dev.iDevType = vDevType.asInt();
            dev.iStatus = vStatus.asInt();
            vecDevList.push_back(dev);
        }
        //
        //		if (end.asInt()-start.asInt() < 50)
        //			break;
    }
    
    *numDevs = vecDevList.size();
    *ppDeviceList = (ICRC_SMARTHOME_DEVICE_DETAIL*)malloc((*numDevs)*sizeof(ICRC_SMARTHOME_DEVICE_DETAIL));
    for (int i = 0; i < *numDevs; i++) {
        memcpy(&(*ppDeviceList)[i], &vecDevList[i], sizeof(ICRC_SMARTHOME_DEVICE_DETAIL));
    }
    
    return ICRC_ERROR_OK;
}

ICRC_HTTPCLIENT_API int ICRC_Http_GetDeviceState(
                                                 void *icrc_handle, //句柄
                                                 int start_index, //起始索引号
                                                 int end_index,   //结束索引号
                                                 ICRC_SMARTHOME_DEVICE_STATUS **ppDeviceStatus, //状态(0:不在线,1:在线,2:检测中)
                                                 int *numDevs, //设备数量
                                                 const char *sVirtualCode //虚号为空时查询所有设备
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    std::vector<ICRC_SMARTHOME_DEVICE_STATUS> vecDevStatus;
    //
    std::string body;
    Json::Value root, req;
    if (sVirtualCode && sVirtualCode[0])
        req["sDevVirtualCode"] = sVirtualCode;
    root["start"] = start_index;
    root["end"  ] = end_index;
    root["req"  ] = req;
    body = root.toUnStyledString();
    //
    //	while (1)
    {
        Json::Value jsonObject;
        int err = _http_process(pHandle, "smartHome", "10#108", body.c_str(), body.size(), true, jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        Json::Value code = jsonObject["code" ];
        Json::Value start= jsonObject["start"];
        Json::Value end  = jsonObject["end"  ];
        Json::Value objs = jsonObject["objs" ];
        if (!code.isInt() || !start.isInt() || !end.isInt() || !objs.isArray())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        //
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        for (unsigned int i = 0; i < objs.size(); i++)
        {
            Json::Value vVirCode = objs[i]["sDevVirtualCode"];
            Json::Value vStatus  = objs[i]["iStatus"        ];
            
            ICRC_SMARTHOME_DEVICE_STATUS stat = {0};
            strncpy(stat.sVirtualCode, vVirCode.asCString(), sizeof(stat.sVirtualCode));
            stat.status = vStatus.asInt();
            vecDevStatus.push_back(stat);
        }
        //
        //		if (end.asInt()-start.asInt() < 50)
        //			break;
    }
    
    *numDevs = vecDevStatus.size();
    *ppDeviceStatus = (ICRC_SMARTHOME_DEVICE_STATUS*)malloc((*numDevs)*sizeof(ICRC_SMARTHOME_DEVICE_STATUS));
    for (int i = 0; i < *numDevs; i++) {
        memcpy(&(*ppDeviceStatus)[i], &vecDevStatus[i], sizeof(ICRC_SMARTHOME_DEVICE_STATUS));
    }
    
    return ICRC_ERROR_OK;
}

ICRC_HTTPCLIENT_API int ICRC_Http_FreeMemory(
                                             void *pMemAddr //用于释放获取设备列表和状态时申请的内存，
)
{
    free(pMemAddr);
    
    return ICRC_ERROR_OK;
}

ICRC_HTTPCLIENT_API int ICRC_Http_GetAlarmRecord(
                                                 void *icrc_handle, //句柄
                                                 int start_index, //起始索引号
                                                 int end_index,   //结束索引号
                                                 ICRC_ALARM_RECORD **ppAlarmRecord, //报警记录
                                                 int *numRecords, //报警数量
                                                 int iAlarmId  // id=0查询所有报警记录
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    std::vector<ICRC_ALARM_RECORD> vecAlarmRecord;
    //
    std::string body;
    Json::Value root, req;
    if (iAlarmId)
        req["iAlarmId"] = iAlarmId;
    root["start"] = start_index;
    root["end"  ] = end_index;
    root["req"  ] = req;
    body = root.toUnStyledString();
    //
    //	while (1)
    {
        Json::Value jsonObject;
        int err = _http_process(pHandle, "info", "10#14", body.c_str(), body.size(), true, jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        Json::Value code = jsonObject["code" ];
        Json::Value start= jsonObject["start"];
        Json::Value end  = jsonObject["end"  ];
        Json::Value objs = jsonObject["objs" ];
        if (!code.isInt() || !start.isInt() || !end.isInt() || !objs.isArray())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        //
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        for (unsigned int i = 0; i < objs.size(); i++)
        {
            Json::Value vId   = objs[i]["iAlarmId"    ];
            Json::Value vTime = objs[i]["iAlarmTime"  ];
            Json::Value vStat = objs[i]["iAlarmStatus"];
            Json::Value vType = objs[i]["sAlarmType"  ];
            Json::Value vName = objs[i]["sDevName"    ];
            Json::Value vAddr = objs[i]["sAlarmZone"  ];
            Json::Value vVirt = objs[i]["sDevVirtualCode"];
            Json::Value vRcdID= objs[i]["sRecordID"   ];
            
            ICRC_ALARM_RECORD record = {0};
            record.iAlarmId = vId.asInt();
            record.iAlarmTime = vTime.asInt();
            record.iAlarmStatus = vStat.asInt();
            strncpy(record.sAlarmType, vType.asCString(), sizeof(record.sAlarmType));
            strncpy(record.sDevName, vName.asCString(), sizeof(record.sDevName));
            strncpy(record.sAreaAddr, vAddr.asCString(), sizeof(record.sAreaAddr));
            strncpy(record.sDevVirtualCode, vVirt.asCString(), sizeof(record.sDevVirtualCode));
            strncpy(record.sRecordID, vRcdID.asCString(), sizeof(record.sRecordID));
            vecAlarmRecord.push_back(record);
        }
        //
        //		if (end.asInt()-start.asInt() < 50)
        //			break;
    }
    
    *numRecords = vecAlarmRecord.size();
    *ppAlarmRecord = (ICRC_ALARM_RECORD*)malloc((*numRecords)*sizeof(ICRC_ALARM_RECORD));
    for (int i = 0; i < *numRecords; i++) {
        memcpy(&(*ppAlarmRecord)[i], &vecAlarmRecord[i], sizeof(ICRC_ALARM_RECORD));
    }
    
    return ICRC_ERROR_OK;
}

ICRC_HTTPCLIENT_API int ICRC_Http_GetHomeMessage(
                                                 void *icrc_handle, //句柄
                                                 int start_index, //起始索引号
                                                 int end_index,   //结束索引号
                                                 ICRC_HOME_MESSAGE **ppHomeMessage, //家庭信息
                                                 int *numMessages, //信息数量
                                                 int iHisId //id=0查询所有信息
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    std::vector<ICRC_HOME_MESSAGE> vecHomeMessage;
    //
    std::string body;
    Json::Value root, req;
    if (iHisId)
        req["iHisId"] = iHisId;
    root["start"] = start_index;
    root["end"  ] = end_index;
    root["req"  ] = req;
    body = root.toUnStyledString();
    //
    //	while (1)
    {
        Json::Value jsonObject;
        int err = _http_process(pHandle, "info", "10#16", body.c_str(), body.size(), true, jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        Json::Value code = jsonObject["code" ];
        Json::Value start= jsonObject["start"];
        Json::Value end  = jsonObject["end"  ];
        Json::Value objs = jsonObject["objs" ];
        if (!code.isInt() || !start.isInt() || !end.isInt() || !objs.isArray())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        //
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        for (unsigned int i = 0; i < objs.size(); i++)
        {
            Json::Value vId   = objs[i]["iHisId"    ];
            Json::Value vType = objs[i]["iHisType"  ];
            Json::Value vTime = objs[i]["iOcurTime" ];
            Json::Value vCont = objs[i]["sContent"  ];
            Json::Value vPic  = objs[i]["sPic"      ];
            Json::Value vPicS = objs[i]["sPicSmall" ];
            Json::Value vCode = objs[i]["sReVirtualCode"];
            
            ICRC_HOME_MESSAGE message = {0};
            message.iHisId = vId.asInt();
            message.iHisType = vType.asInt();
            message.iOcurTime = vTime.asInt();
            strncpy(message.sContent, vCont.asCString(), sizeof(message.sContent));
            strncpy(message.sPic, vPic.asCString(), sizeof(message.sPic));
            strncpy(message.sPicSmall, vPicS.asCString(), sizeof(message.sPicSmall));
            strncpy(message.sReVirtualCode, vCode.asCString(), sizeof(message.sReVirtualCode));
            vecHomeMessage.push_back(message);
        }
        //
        //		if (end.asInt()-start.asInt() < 50)
        //			break;
    }
    
    *numMessages = vecHomeMessage.size();
    *ppHomeMessage = (ICRC_HOME_MESSAGE*)malloc((*numMessages)*sizeof(ICRC_HOME_MESSAGE));
    for (int i = 0; i < *numMessages; i++) {
        memcpy(&(*ppHomeMessage)[i], &vecHomeMessage[i], sizeof(ICRC_HOME_MESSAGE));
    }
    
    return ICRC_ERROR_OK;
}

ICRC_HTTPCLIENT_API int ICRC_Http_GetCommunityMessage(
                                                      void *icrc_handle, //句柄
                                                      int start_index, //起始索引号
                                                      int end_index,   //结束索引号
                                                      ICRC_COMMUNITY_MESSAGE **ppCommunityMessage, //社区信息
                                                      int *numMessages, //信息数量
                                                      int iInfoId //id=0查询所有信息
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    std::vector<ICRC_COMMUNITY_MESSAGE> vecCommunityMessage;
    //
    std::string body;
    Json::Value root, req;
    if (iInfoId)
        req["iInfoId"] = iInfoId;
    root["start"] = start_index;
    root["end"  ] = end_index;
    root["req"  ] = req;
    body = root.toUnStyledString();
    //
    //	while (1)
    {
        Json::Value jsonObject;
        int err = _http_process(pHandle, "info", "10#17", body.c_str(), body.size(), true, jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        Json::Value code = jsonObject["code" ];
        Json::Value start= jsonObject["start"];
        Json::Value end  = jsonObject["end"  ];
        Json::Value objs = jsonObject["objs" ];
        if (!code.isInt() || !start.isInt() || !end.isInt() || !objs.isArray())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        //
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        for (unsigned int i = 0; i < objs.size(); i++)
        {
            Json::Value vId    = objs[i]["iInfoId"     ];
            Json::Value vType  = objs[i]["iInfoType"   ];
            Json::Value vTime  = objs[i]["iSendTime"   ];
            Json::Value vTitle = objs[i]["sTitle"      ];
            Json::Value vCont  = objs[i]["sContent"    ];
            Json::Value vPic   = objs[i]["sPicUrl"     ];
            Json::Value vPicS  = objs[i]["sSmallPicUrl"];
            //			Json::Value vDesc  = objs[i]["sDes"        ];
            
            ICRC_COMMUNITY_MESSAGE message = {0};
            message.iInfoId = vId.asInt();
            message.iInfoType = vType.asInt();
            message.iSendTime = vTime.asInt();
            strncpy(message.sTitle, vTitle.asCString(), sizeof(message.sTitle));
            strncpy(message.sContent, vCont.asCString(), sizeof(message.sContent));
            strncpy(message.sPicUrl, vPic.asCString(), sizeof(message.sPicUrl));
            strncpy(message.sPicUrlSmall, vPicS.asCString(), sizeof(message.sPicUrlSmall));
            //			strncpy(message.sDes, vDesc.asCString(), sizeof(message.sDes));
            vecCommunityMessage.push_back(message);
        }
        //
        //		if (end.asInt()-start.asInt() < 50)
        //			break;
    }
    
    *numMessages = vecCommunityMessage.size();
    *ppCommunityMessage = (ICRC_COMMUNITY_MESSAGE*)malloc((*numMessages)*sizeof(ICRC_COMMUNITY_MESSAGE));
    for (int i = 0; i < *numMessages; i++) {
        memcpy(&(*ppCommunityMessage)[i], &vecCommunityMessage[i], sizeof(ICRC_COMMUNITY_MESSAGE));
    }
    
    return ICRC_ERROR_OK;
}

ICRC_HTTPCLIENT_API int ICRC_Http_GetPropertyMessage(
                                                     void *icrc_handle, //句柄
                                                     int start_index, //起始索引号
                                                     int end_index,   //结束索引号
                                                     ICRC_PROPERTY_MESSAGE **ppPropertyMessage, //物业信息
                                                     int *numMessages, //信息数量
                                                     int iInfoId //id=0查询所有信息
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    std::vector<ICRC_PROPERTY_MESSAGE> vecPropertyMessage;
    //
    std::string body;
    Json::Value root, req;
    if (iInfoId)
        req["iInfoId"] = iInfoId;
    root["start"] = start_index;
    root["end"  ] = end_index;
    root["req"  ] = req;
    body = root.toUnStyledString();
    //
    //	while (1)
    {
        Json::Value jsonObject;
        int err = _http_process(pHandle, "info", "10#18", body.c_str(), body.size(), true, jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        Json::Value code = jsonObject["code" ];
        Json::Value start= jsonObject["start"];
        Json::Value end  = jsonObject["end"  ];
        Json::Value objs = jsonObject["objs" ];
        if (!code.isInt() || !start.isInt() || !end.isInt() || !objs.isArray())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        //
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        for (unsigned int i = 0; i < objs.size(); i++)
        {
            Json::Value vId    = objs[i]["iInfoId"     ];
            Json::Value vType  = objs[i]["iInfoType"   ];
            Json::Value vTime  = objs[i]["iSendTime"   ];
            Json::Value vTitle = objs[i]["sTitle"      ];
            Json::Value vCont  = objs[i]["sContent"    ];
            Json::Value vPic   = objs[i]["sPicUrl"     ];
            Json::Value vPicS  = objs[i]["sPicUrlSmall"];
            Json::Value vDesc  = objs[i]["sDesc"       ];
            
            ICRC_PROPERTY_MESSAGE message;
            message.iInfoId = vId.asInt();
            message.iInfoType = vType.asInt();
            message.iSendTime = vTime.asInt();
            strncpy(message.sTitle, vTitle.asCString(), sizeof(message.sTitle));
            strncpy(message.sContent, vCont.asCString(), sizeof(message.sContent));
            strncpy(message.sPicUrl, vPic.asCString(), sizeof(message.sPicUrl));
            strncpy(message.sPicUrlSmall, vPicS.asCString(), sizeof(message.sPicUrlSmall));
            strncpy(message.sDes, vDesc.asCString(), sizeof(message.sDes));
            vecPropertyMessage.push_back(message);
        }
        //
        //		if (end.asInt()-start.asInt() < 50)
        //			break;
    }
    
    *numMessages = vecPropertyMessage.size();
    *ppPropertyMessage = (ICRC_PROPERTY_MESSAGE*)malloc((*numMessages)*sizeof(ICRC_PROPERTY_MESSAGE));
    for (int i = 0; i < *numMessages; i++) {
        memcpy(&(*ppPropertyMessage)[i], &vecPropertyMessage[i], sizeof(ICRC_PROPERTY_MESSAGE));
    }
    
    return ICRC_ERROR_OK;
}

/*************** 查询当前用户的留影留言信息 ********************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetLeaveMessage(
                                                  void *icrc_handle, //句柄
                                                  int start_index, //起始索引号
                                                  int end_index,   //结束索引号
                                                  ICRC_LEAVE_MESSAGE **ppLeaveMessage, //留言信息
                                                  int *numMessages, //信息数量
                                                  int iMsgId //id=0查询所有信息
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    std::vector<ICRC_LEAVE_MESSAGE> vecLeaveMessage;
    //
    std::string body;
    Json::Value root, req;
    if (iMsgId)
        req["iMsgId"] = iMsgId;
    root["start"] = start_index;
    root["end"  ] = end_index;
    root["req"  ] = req;
    body = root.toUnStyledString();
    //
    //	while (1)
    {
        Json::Value jsonObject;
        int err = _http_process(pHandle, "info", "10#19", body.c_str(), body.size(), true, jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        Json::Value code = jsonObject["code" ];
        Json::Value start= jsonObject["start"];
        Json::Value end  = jsonObject["end"  ];
        Json::Value objs = jsonObject["objs" ];
        if (!code.isInt() || !start.isInt() || !end.isInt() || !objs.isArray())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        //
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        for (unsigned int i = 0; i < objs.size(); i++)
        {
            Json::Value vId    = objs[i]["iMsgId"         ];
            Json::Value vFrom  = objs[i]["sFromVirutualNo"];
            Json::Value vTo    = objs[i]["sToVirutualNo"  ];
            Json::Value vType  = objs[i]["iType"          ];
            Json::Value vTime  = objs[i]["iSendTime"      ];
            Json::Value vTitle = objs[i]["sTitle"         ];
            Json::Value vCont  = objs[i]["sContent"       ];
            Json::Value vPic   = objs[i]["sPic"           ];
            Json::Value vPicS  = objs[i]["sPicSmall"      ];
            
            ICRC_LEAVE_MESSAGE message = {0};
            message.iMsgId = vId.asInt();
            message.iType = vType.asInt();
            message.iSendTime = vTime.asInt();
            strncpy(message.sFromVirutualNo, vFrom.asCString(), sizeof(message.sFromVirutualNo));
            strncpy(message.sToVirutualNo, vTo.asCString(), sizeof(message.sToVirutualNo));
            strncpy(message.sTitle, vTitle.asCString(), sizeof(message.sTitle));
            strncpy(message.sContent, vCont.asCString(), sizeof(message.sContent));
            strncpy(message.sPic, vPic.asCString(), sizeof(message.sPic));
            strncpy(message.sPicSmall, vPicS.asCString(), sizeof(message.sPicSmall));
            vecLeaveMessage.push_back(message);
        }
        //
        //		if (end.asInt()-start.asInt() < 50)
        //			break;
    }
    
    *numMessages = vecLeaveMessage.size();
    *ppLeaveMessage = (ICRC_LEAVE_MESSAGE*)malloc((*numMessages)*sizeof(ICRC_LEAVE_MESSAGE));
    for (int i = 0; i < *numMessages; i++) {
        memcpy(&(*ppLeaveMessage)[i], &vecLeaveMessage[i], sizeof(ICRC_LEAVE_MESSAGE));
    }
    
    return ICRC_ERROR_OK;
}

/*************** 添加当前用户的留言留影信息 ********************/
ICRC_HTTPCLIENT_API int ICRC_Http_WriteLeaveMessage(
                                                    void *icrc_handle, //句柄
                                                    ICRC_LEAVE_MESSAGE *pLeaveMessage //留言信息
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    //
    std::string body;
    Json::Value root, req;
    req["sToVirutualNo"] = pLeaveMessage->sToVirutualNo;
    req["iType"        ] = pLeaveMessage->iType;
    req["sTitle"       ] = pLeaveMessage->sTitle;
    req["sContent"     ] = pLeaveMessage->sContent;
    req["sPic"         ] = pLeaveMessage->sPic;
    req["sPicSmall"    ] = pLeaveMessage->sPicSmall;
    root["req"] = req;
    body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "info", "11#19", body.c_str(), body.size(), true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code"];
    if (!code.isInt())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    err = code.asInt();
    return err;
}

/***************** 查询当前用户好友列表 ************************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetFriendInfo(
                                                void *icrc_handle, //句柄
                                                int start_index, //起始索引号
                                                int end_index,   //结束索引号
                                                ICRC_FRIEND_INFO **ppFriendInfo, //好友信息
                                                int *numFriends //
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    std::vector<ICRC_FRIEND_INFO> vecFriendInfo;
    //
    std::string body;
    Json::Value root, req;
    root["start"] = start_index;
    root["end"  ] = end_index;
    root["req"  ] = req;
    body = root.toUnStyledString();
    //
    //	while (1)
    {
        Json::Value jsonObject;
        int err = _http_process(pHandle, "info", "10#20", body.c_str(), body.size(), true, jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        Json::Value code = jsonObject["code" ];
        Json::Value start= jsonObject["start"];
        Json::Value end  = jsonObject["end"  ];
        Json::Value objs = jsonObject["objs" ];
        if (!code.isInt() || !start.isInt() || !end.isInt() || !objs.isArray())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        //
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
        //
        for (unsigned int i = 0; i < objs.size(); i++)
        {
            Json::Value vVCode = objs[i]["sFriVirtualCode"];
            Json::Value vVeri  = objs[i]["iVerify"        ];
            Json::Value vName  = objs[i]["sFriName"       ];
            Json::Value vPic   = objs[i]["sPic"           ];
            Json::Value vType  = objs[i]["iType"          ];
            
            ICRC_FRIEND_INFO _friend = {0};
            _friend.iVerify = vVeri.asInt();
            _friend.iType = vType.asInt();
            strncpy(_friend.sFriVirtualCode, vVCode.asCString(), sizeof(_friend.sFriVirtualCode));
            strncpy(_friend.sFriName, vName.asCString(), sizeof(_friend.sFriName));
            strncpy(_friend.sPic, vPic.asCString(), sizeof(_friend.sPic));
            vecFriendInfo.push_back(_friend);
        }
        //
        //		if (end.asInt()-start.asInt() < 50)
        //			break;
    }
    
    *numFriends = vecFriendInfo.size();
    *ppFriendInfo = (ICRC_FRIEND_INFO*)malloc((*numFriends)*sizeof(ICRC_FRIEND_INFO));
    for (int i = 0; i < *numFriends; i++) {
        memcpy(&(*ppFriendInfo)[i], &vecFriendInfo[i], sizeof(ICRC_FRIEND_INFO));
    }
    
    return ICRC_ERROR_OK;
}

/**************** 查询预备添加好友的信息 ***********************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetFriendPreview(
                                                   void *icrc_handle, //句柄
                                                   const char *sFriVirtualCode, //好友虚号
                                                   ICRC_FRIEND_PREVIEW *pFriendPreview //好友信息
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    //
    std::string body;
    Json::Value root, req;
    req["sFriVirtualCode"] = sFriVirtualCode;
    root["req"] = req;
    body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "info", "10#120", body.c_str(), body.size(), true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code"];
    Json::Value objs = jsonObject["objs"];
    if (!code.isInt() && !objs.isArray())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    err = code.asInt();
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value vVCode = objs[0]["sFriVirtualCode"];
    Json::Value vName  = objs[0]["sFriName"       ];
    Json::Value vIsFri = objs[0]["iFriend"        ];
    Json::Value vType  = objs[0]["iType"          ];
    //
    pFriendPreview->iFriend = vIsFri.asInt();
    pFriendPreview->iType = vType.asInt();
    strncpy(pFriendPreview->sFriVirtualCode, vVCode.asCString(), sizeof(pFriendPreview->sFriVirtualCode));
    strncpy(pFriendPreview->sFriName, vName.asCString(), sizeof(pFriendPreview->sFriName));
    //
    return ICRC_ERROR_OK;
}

/****************** 当前用户添加好友 ***************************/
ICRC_HTTPCLIENT_API int ICRC_Http_AddFriend(
                                            void *icrc_handle, //句柄
                                            const char *sFriVirtualCode, //好友虚号
                                            int iType //类型
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    //
    std::string body;
    Json::Value root, req;
    req["sFriVirtualCode"] = sFriVirtualCode;
    req["iType"          ] = iType;
    root["req"] = req;
    body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "info", "11#20", body.c_str(), body.size(), true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code"];
    if (!code.isInt())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    err = code.asInt();
    return err;
}

/***************** 删除当前用户添加好友 ************************/
ICRC_HTTPCLIENT_API int ICRC_Http_DelFriend(
                                            void *icrc_handle, //句柄
                                            const char *sFriVirtualCode //好友虚号
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    //
    std::string body;
    Json::Value root, req;
    req["sFriVirtualCode"] = sFriVirtualCode;
    root["req"] = req;
    body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "info", "12#20", body.c_str(), body.size(), true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code"];
    if (!code.isInt())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    err = code.asInt();
    return err;
}

/***************** 修改当前用户好友信息 ************************/
ICRC_HTTPCLIENT_API int ICRC_Http_EditFriend(
                                             void *icrc_handle, //句柄
                                             const char *sFriVirtualCode, //好友虚号
                                             const char *sFriName //昵称
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    //
    std::string body;
    Json::Value root, req;
    req["sFriVirtualCode"] = sFriVirtualCode;
    req["sFriName"       ] = sFriName;
    root["req"] = req;
    body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "info", "13#20", body.c_str(), body.size(), true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code"];
    if (!code.isInt())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    err = code.asInt();
    return err;
}

/****************** 上传留言留影信息 ***************************/
ICRC_HTTPCLIENT_API int ICRC_Http_Upload(
                                         void *icrc_handle, //句柄
                                         int type, // 2图片短信 20留言短信
                                         const char *extension, //文件格式(扩展名)
                                         const char *bytestream, //二进制数据
                                         int bytelen, //数据长度
                                         ICRC_UPLOAD_RESULT *pUploadResult //上传结果
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *phandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!phandle) return ICRC_ERROR_INVALID_HANDLE;
    //
    std::map<string,string>::iterator iter = phandle->m_servlist.find("upload");
    if (iter == phandle->m_servlist.end())
        return ICRC_ERROR_HTTP_SERV_NOT_FOUND;
    //
    std::ostringstream uri;
    uri <<"http://"<<phandle->m_sIpAddr<<":"<<phandle->m_iPort<<iter->second<<"?subType="<<type<<"&suf="<<extension<<"&ope=1";
    //
    ghttp_request *request = ghttp_request_new();
    ghttp_set_uri(request, (char*)uri.str().c_str());
    ghttp_set_sync(request, ghttp_sync);
    ghttp_set_type(request, ghttp_type_post);
    ghttp_set_header(request, "Action", "1");
    ghttp_set_header(request, "CallId", phandle->m_sCallid.c_str());
    ghttp_set_header(request, http_hdr_Content_Type, "application/octet-stream");
    ghttp_set_body(request, (char*)bytestream, bytelen);
    ghttp_prepare(request);
    //
    if (ghttp_done!=ghttp_process(request))
    {
        ghttp_request_destroy(request);
        return ICRC_ERROR_HTTP_NO_RESPONSE;
    }
    //
    const char *http_result = ghttp_get_body(request);
    int http_result_len = ghttp_get_body_len(request);
    if (!http_result || http_result_len==0)
    {
        ghttp_request_destroy(request);
        return ICRC_ERROR_HTTP_CONTENT_EMPTY;
    }
    //
    Json::Value jsonObject;
    Json::Reader reader;
    if (!reader.parse(http_result, jsonObject))
    {
        ghttp_request_destroy(request);
        return ICRC_ERROR_HTTP_CONTENT_PARSE_FAIL;
    }
    ghttp_request_destroy(request);
    //
    Json::Value code = jsonObject["code"    ];
    Json::Value pic  = jsonObject["url"     ];
    Json::Value picS = jsonObject["urlSmall"];
    if (!code.isInt() && !pic.isString() && !picS.isString())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    int err = code.asInt();
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    strncpy(pUploadResult->sPic, pic.asCString(), sizeof(pUploadResult->sPic));
    strncpy(pUploadResult->sPicSmall, picS.asCString(), sizeof(pUploadResult->sPicSmall));
    return ICRC_ERROR_OK;
}

/****************** 获取视频设备信息 ***************************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetVideoDevice(
                                                 void *icrc_handle, //句柄
                                                 ICRC_VIDEO_DEVICE **ppVideoDevice, //设备列表
                                                 int *numDevs //设备数量
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    std::vector<ICRC_VIDEO_DEVICE> vecVideoDevice;
    //
    std::string body;
    Json::Value root, req;
    root["req"] = req;
    body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "smartHome", "10#208", body.c_str(), body.size(), true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code" ];
    Json::Value start= jsonObject["start"];
    Json::Value end  = jsonObject["end"  ];
    Json::Value objs = jsonObject["objs" ];
    if (!code.isInt() || !start.isInt() || !end.isInt() || !objs.isArray())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    err = code.asInt();
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    for (unsigned int i = 0; i < objs.size(); i++)
    {
        Json::Value vVirCode = objs[i]["sDevVirtualCode"];
        Json::Value vDevChan = objs[i]["iDevChan"       ];
        Json::Value vUsr     = objs[i]["sUserName"      ];
        Json::Value vPwd     = objs[i]["sPasswd"        ];
        Json::Value vIp      = objs[i]["sNetwork"       ];
        Json::Value vPort    = objs[i]["iNetPort"       ];
        Json::Value vDevType = objs[i]["iDevType"       ];
        
        ICRC_VIDEO_DEVICE dev = {0};
        strncpy(dev.sDevVirtualCode, vVirCode.asCString(), sizeof(dev.sDevVirtualCode));
        strncpy(dev.sUserName, vUsr.asCString(), sizeof(dev.sUserName));
        strncpy(dev.sPasswd, vPwd.asCString(), sizeof(dev.sPasswd));
        strncpy(dev.sNetwork, vIp.asCString(), sizeof(dev.sNetwork));
        dev.iDevChan = vDevChan.asInt();
        dev.iNetPort = vPort.asInt();
        dev.iDevType = vDevType.asInt();
        vecVideoDevice.push_back(dev);
    }
    
    *numDevs = vecVideoDevice.size();
    *ppVideoDevice = (ICRC_VIDEO_DEVICE*)malloc((*numDevs)*sizeof(ICRC_VIDEO_DEVICE));
    for (int i = 0; i < *numDevs; i++) {
        memcpy(&(*ppVideoDevice)[i], &vecVideoDevice[i], sizeof(ICRC_VIDEO_DEVICE));
    }
    
    return ICRC_ERROR_OK;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static void DH_Sleep(int timems)
{
#ifdef WIN32
    Sleep(timems);
#else
    usleep(timems*1000);
#endif
}
static bool DH_BeginThread(void *startAddress, void *parameter)
{
#ifdef WIN32
    HANDLE handle = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)startAddress, (LPVOID)parameter, 0, NULL);
    if (handle == NULL)
    {
        fprintf(stderr, "pthread_create() fail : %s\n", strerror(GetLastError()));
        return false;
    }
#else
    int err;
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setstacksize(&attr, 1024*1024); //设置堆栈大小1M
    pthread_t ntid;
    err = pthread_create(&ntid, &attr, (void* (*)(void*))startAddress, (void*)parameter);
    pthread_attr_destroy(&attr);
    if (err != 0)
    {
        fprintf(stderr, "pthread_create() fail : %s\n", strerror(err));
        return false;
    }
#endif
    return true;
}
static bool g_bThreadRun = false;
static bool g_bResultOk = false;
static char g_sIpAddr[32] = {0};
static void *thread_DNS(void *parameter)
{
    struct hostent *host = gethostbyname((char*)parameter);
    if ( host )
    {
        strcpy(g_sIpAddr, inet_ntoa(*((struct in_addr*)host->h_addr)));
        g_bResultOk = true;
    }
    
    g_bThreadRun = false;
    
    return NULL;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/******************** 重定向服务 *******************************/
ICRC_HTTPCLIENT_API int ICRC_Http_Redirect(
                                           IN  const char *domain, //域名"www.dahuayun.com"
                                           IN unsigned int timeout, //超时时间ms
                                           OUT ICRC_REDIRECT_INFO *pRedirect //返回服务器信息
)
{
    CLock lock(&g_dhmtx);
    
#ifdef WIN32
    WSADATA wsaData;
    WSAStartup(MAKEWORD(1,1), &wsaData);
#endif
    
    int err = ICRC_ERROR_OK;
    
    do {
        {
            if ( !g_bThreadRun )
            {
                g_bThreadRun = true;
                g_bResultOk = false;
                DH_BeginThread((void *)thread_DNS, (void*)domain);
            }
            int timeslice = 100; //
            for (int i = 0; i < timeout/timeslice; i++)
            {
                if (g_bResultOk==true || !g_bThreadRun)
                    break;
                DH_Sleep(timeslice);
            }
            if ( !g_bResultOk )
                return ICRC_ERROR_TIMEOUT;
        }
        
        //hostent *host = gethostbyname((char*)domain);
        //if (host==NULL)
        //	break;
        char *pszIp = g_sIpAddr;//inet_ntoa(*((struct in_addr*)host->h_addr));
        //
        std::string body;
        Json::Value root, req;
        req["sUserName"     ] = "abc";
        req["sServerAddress"] = pszIp;
        root["req"] = req;
        body = root.toUnStyledString();
        //
        std::ostringstream uri;
        uri <<"http://"<<pszIp<<":"<<9090<<"/app/zwelife/redirect";
        //
        ghttp_request *request = ghttp_request_new();
        ghttp_set_uri(request, (char*)uri.str().c_str());
        ghttp_set_sync(request, ghttp_sync);
        ghttp_set_type(request, ghttp_type_post);
        ghttp_set_header(request, "Action", "1#3");
        ghttp_set_header(request, http_hdr_Content_Type, "text/json; charset=utf-8");
        ghttp_set_body(request, (char*)body.c_str(), body.size());
        ghttp_prepare(request);
        //
        if (ghttp_done!=ghttp_process(request)) {
            ghttp_request_destroy(request);
            err = ICRC_ERROR_HTTP_NO_RESPONSE;
            break;
        }
        //
        const char *http_result = ghttp_get_body(request);
        int http_result_len = ghttp_get_body_len(request);
        if (!http_result || http_result_len==0) {
            ghttp_request_destroy(request);
            err = ICRC_ERROR_HTTP_CONTENT_EMPTY;
            break;
        }
        //
        Json::Reader reader;
        Json::Value jsonObject;
        if (!reader.parse(http_result, jsonObject)) {
            ghttp_request_destroy(request);
            err = ICRC_ERROR_HTTP_CONTENT_PARSE_FAIL;
            break;
        }
        ghttp_request_destroy(request);
        //
        Json::Value code = jsonObject["code" ];
        Json::Value objs = jsonObject["objs" ];
        if (!code.isInt() || !objs.isArray()) {
            err = ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
            break;
        }
        //
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            break;
        //
        Json::Value ip   = objs[0]["sIp"];
        Json::Value port = objs[0]["iPort"];
        if (!ip.isString() || !port.isInt()) {
            err = ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
            break;
        }
        //
        if (pRedirect) {
            strncpy(pRedirect->sIp, ip.asCString(), sizeof(pRedirect->sIp));
            pRedirect->iPort = port.asInt();
        }
    } while (0);
    
#ifdef WIN32
    WSACleanup();
#endif
    
    return err;
}

/***************** 检查最新的版本信息 **************************/
ICRC_HTTPCLIENT_API int ICRC_Http_CheckVersion(
                                               IN  const char*  sIpAddr,     //服务器ip地址
                                               IN  int          iPort,       //服务器端口
                                               IN  int          iClientType, //客户端类型。1 Android; 2苹果
                                               OUT ICRC_VERSION_INFO *pVersion //最新版本的信息
)
{
    CLock lock(&g_dhmtx);
    
    int err = ICRC_ERROR_OK;
    
    do {
        //
        std::string body;
        Json::Value root, req;
        req["iClientType"] = iClientType;
        root["req"] = req;
        body = root.toUnStyledString();
        //
        std::ostringstream uri;
        uri <<"http://"<<sIpAddr<<":"<<iPort<<"/app/zwelife/regist";
        //
        ghttp_request *request = ghttp_request_new();
        ghttp_set_uri(request, (char*)uri.str().c_str());
        ghttp_set_sync(request, ghttp_sync);
        ghttp_set_type(request, ghttp_type_post);
        ghttp_set_header(request, "Action", "1#4");
        ghttp_set_header(request, http_hdr_Content_Type, "text/json; charset=utf-8");
        ghttp_set_body(request, (char*)body.c_str(), body.size());
        ghttp_prepare(request);
        //
        if (ghttp_done!=ghttp_process(request)) {
            ghttp_request_destroy(request);
            err = ICRC_ERROR_HTTP_NO_RESPONSE;
            break;
        }
        //
        const char *http_result = ghttp_get_body(request);
        int http_result_len = ghttp_get_body_len(request);
        if (!http_result || http_result_len==0) {
            ghttp_request_destroy(request);
            err = ICRC_ERROR_HTTP_CONTENT_EMPTY;
            break;
        }
        //
        Json::Reader reader;
        Json::Value jsonObject;
        if (!reader.parse(http_result, jsonObject)) {
            ghttp_request_destroy(request);
            err = ICRC_ERROR_HTTP_CONTENT_PARSE_FAIL;
            break;
        }
        ghttp_request_destroy(request);
        //
        Json::Value code = jsonObject["code"];
        Json::Value objs = jsonObject["objs"];
        if (!code.isInt() || !objs.isArray()) {
            err = ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
            break;
        }
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            break;
        //
        Json::Value vname = objs[0]["sVersionName"   ];
        Json::Value vdesc = objs[0]["sVersionDesc"   ];
        Json::Value vmin  = objs[0]["sMinVersionName"];
        Json::Value upurl = objs[0]["sUpdateurl"     ];
        Json::Value upurl2= objs[0]["sUpdateurl2"    ];
        Json::Value upurl3= objs[0]["sUpdateurl3"    ];
        Json::Value upurl4= objs[0]["sUpdateurl4"    ];
        Json::Value upurl5= objs[0]["sUpdateurl5"    ];
        Json::Value time  = objs[0]["iPublishTime"   ];
        if (!vname.isString() || !vdesc.isString() || !vmin.isString() || !upurl.isString() || !time.isInt()
            || !upurl2.isString() || !upurl3.isString() || !upurl4.isString() || !upurl5.isString()) {
            err = ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
            break;
        }
        //
        if (pVersion) {
            strncpy(pVersion->sVersionName, vname.asCString(), sizeof(pVersion->sVersionName));
            strncpy(pVersion->sVersionDesc, vdesc.asCString(), sizeof(pVersion->sVersionDesc));
            strncpy(pVersion->sMinVersionName, vmin.asCString(), sizeof(pVersion->sMinVersionName));
            strncpy(pVersion->sUpdateurl, upurl.asCString(), sizeof(pVersion->sUpdateurl));
            strncpy(pVersion->sUpdateurl2, upurl2.asCString(), sizeof(pVersion->sUpdateurl2));
            strncpy(pVersion->sUpdateurl3, upurl3.asCString(), sizeof(pVersion->sUpdateurl3));
            strncpy(pVersion->sUpdateurl4, upurl4.asCString(), sizeof(pVersion->sUpdateurl4));
            strncpy(pVersion->sUpdateurl5, upurl5.asCString(), sizeof(pVersion->sUpdateurl5));
            pVersion->iPublishTime = time.asInt();
        }
    } while (0);
    
    return err;
}

/*************** 注册账号, 会发送邮箱验证邮件 ******************/
ICRC_HTTPCLIENT_API int ICRC_Http_RegisterAccount(
                                                  IN  const char* sIpAddr,     //服务器ip地址
                                                  IN  int         iPort,       //服务器端口
                                                  IN  const char* sUserName,   //手机号码
                                                  IN  const char* sEmail,      //邮箱
                                                  IN  const char* sPassWord,   //登录密码
                                                  IN  const char* sAuthCode,   //身份识别码
                                                  IN  const char* sAuthCodeText, //半明文，中间4位用*表示
                                                  IN  const char* sPhone,      //手机号码(可选)
                                                  IN  const char* sActiveCode  //激活码(可选)
)
{
    CLock lock(&g_dhmtx);
    
    // step1: 获取种子
    std::string sSeed, sSeed2;
    {
        Json::Value root;
        root["req"]["sUserName"] = sUserName;
        root["req"]["sEmail"   ] = sEmail;
        root["req"]["sPassWord"] = "";
        std::string body = root.toUnStyledString();
        //
        Json::Value jsonObject;
        int err = _http_process_v2(sIpAddr, iPort, "/app/zwelife/regist", "1#6", body.c_str(), body.size(), jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        Json::Value code = jsonObject["code"];
        Json::Value objs = jsonObject["objs"];
        if (!code.isInt())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
        if (!objs.isArray() || !objs.size())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        sSeed = objs[0]["sSeed"].asString();
        sSeed2 = objs[0]["sAuthCodeSeed"].asString();
    }
    
    // step2: 计算MD5
    std::string strMD5Password;
    {
        struct MD5Context md5c;
        unsigned char ucResult[16];
        std::string strTemp;
        
        strMD5Password.assign(sSeed);
        strMD5Password.append(sPassWord);
        
        MD5Init(&md5c);
        MD5Update(&md5c, (unsigned char*)strMD5Password.data(), strMD5Password.size());
        MD5Final(ucResult, &md5c);
        
        strMD5Password.assign((char*)ucResult, 16);
        strMD5Password = BinaryToHex(strMD5Password);
    }
    
    std::string strMD5AuthCode;
    {
        struct MD5Context md5c;
        unsigned char ucResult[16];
        std::string strTemp;
        
        strMD5AuthCode.assign(sSeed2);
        strMD5AuthCode.append(sAuthCode);
        
        MD5Init(&md5c);
        MD5Update(&md5c, (unsigned char*)strMD5AuthCode.data(), strMD5AuthCode.size());
        MD5Final(ucResult, &md5c);
        
        strMD5AuthCode.assign((char*)ucResult, 16);
        strMD5AuthCode = BinaryToHex(strMD5AuthCode);
    }
    
    // step3: 注册
    {
        Json::Value root;
        root["req"]["sUserName"    ] = sUserName;
        root["req"]["sEmail"       ] = sEmail;
        root["req"]["sPassWord"    ] = strMD5Password;
        root["req"]["sAuthCode"    ] = strMD5AuthCode;
        root["req"]["sAuthCodeText"] = sAuthCodeText;
        root["req"]["sPhone"       ] = sPhone;
        root["req"]["sActiveCode"  ] = sActiveCode;
        std::string body = root.toUnStyledString();
        //
        Json::Value jsonObject;
        int err = _http_process_v2(sIpAddr, iPort, "/app/zwelife/regist", "1#6", body.c_str(), body.size(), jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        Json::Value code = jsonObject["code"];
        if (!code.isInt())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
    }
    
    return ICRC_ERROR_OK;
}

/******************** 通过邮箱找回密码 *************************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetBackPassword(
                                                  IN  const char* sIpAddr,     //服务器ip地址
                                                  IN  int         iPort,       //服务器端口
                                                  IN  const char* sUserName,   //手机号码
                                                  IN  const char* sEmail       //邮箱
)
{
    CLock lock(&g_dhmtx);
    
    int err = ICRC_ERROR_OK;
    
    do {
        //
        std::string body;
        Json::Value root, req;
        req["sUserName"] = sUserName;
        req["sEmail"   ] = sEmail;
        root["req"] = req;
        body = root.toUnStyledString();
        //
        std::ostringstream uri;
        uri <<"http://"<<sIpAddr<<":"<<iPort<<"/app/zwelife/regist";
        //
        ghttp_request *request = ghttp_request_new();
        ghttp_set_uri(request, (char*)uri.str().c_str());
        ghttp_set_sync(request, ghttp_sync);
        ghttp_set_type(request, ghttp_type_post);
        ghttp_set_header(request, "Action", "1#9");
        ghttp_set_header(request, http_hdr_Content_Type, "text/json; charset=utf-8");
        ghttp_set_body(request, (char*)body.c_str(), body.size());
        ghttp_prepare(request);
        //
        if (ghttp_done!=ghttp_process(request)) {
            ghttp_request_destroy(request);
            err = ICRC_ERROR_HTTP_NO_RESPONSE;
            break;
        }
        //
        const char *http_result = ghttp_get_body(request);
        int http_result_len = ghttp_get_body_len(request);
        if (!http_result || http_result_len==0) {
            ghttp_request_destroy(request);
            err = ICRC_ERROR_HTTP_CONTENT_EMPTY;
            break;
        }
        //
        Json::Reader reader;
        Json::Value jsonObject;
        if (!reader.parse(http_result, jsonObject)) {
            ghttp_request_destroy(request);
            err = ICRC_ERROR_HTTP_CONTENT_PARSE_FAIL;
            break;
        }
        ghttp_request_destroy(request);
        //
        Json::Value code = jsonObject["code"];
        if (!code.isInt()) {
            err = ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
            break;
        }
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            break;
    } while (0);
    
    return err;
}

/*********************** 修改密码 ******************************/
ICRC_HTTPCLIENT_API int ICRC_Http_ChangePassword(
                                                 IN  void*       icrc_handle, //句柄
                                                 IN  const char* sPassWord,   //新密码
                                                 IN  const char* sOldPassWord //旧密码
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    
    std::string strMD5Password;
    {
        struct MD5Context md5c;
        unsigned char ucResult[16];
        std::string strTemp;
        
        strMD5Password.assign(pHandle->m_seed1);
        strMD5Password.append(sPassWord);
        
        MD5Init(&md5c);
        MD5Update(&md5c, (unsigned char*)strMD5Password.data(), strMD5Password.size());
        MD5Final(ucResult, &md5c);
        
        strTemp.assign((char*)ucResult, 16);
        strTemp = BinaryToHex(strTemp);
        
        strMD5Password = strTemp;
    }
    
    std::string strMD5PasswordOld;
    {
        struct MD5Context md5c;
        unsigned char ucResult[16];
        std::string strTemp;
        
        strMD5PasswordOld.assign(pHandle->m_seed1);
        strMD5PasswordOld.append(sOldPassWord);
        
        MD5Init(&md5c);
        MD5Update(&md5c, (unsigned char*)strMD5PasswordOld.data(), strMD5PasswordOld.size());
        MD5Final(ucResult, &md5c);
        
        strTemp.assign((char*)ucResult, 16);
        strTemp = BinaryToHex(strTemp);
        
        strMD5PasswordOld = strTemp;
    }
    //
    std::string body;
    Json::Value root, req;
    req["sPassWord"   ] = strMD5Password;
    req["sOldPassWord"] = strMD5PasswordOld;
    root["req"] = req;
    body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "regist", "11#109", body.c_str(), body.size(), true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code"];
    if (!code.isInt())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    err = code.asInt();
    return err;
}

/******************* 发送邮箱验证邮件 **************************/
ICRC_HTTPCLIENT_API int ICRC_Http_EmailVerify(
                                              IN  void*       icrc_handle //句柄
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    //
    std::string body;
    Json::Value root, req;
    root["req"] = req;
    body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "regist", "11#209", body.c_str(), body.size(), true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code"];
    if (!code.isInt())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    err = code.asInt();
    return err;
}

/*************** 修改邮箱地址，发送邮箱验证邮件 ****************/
ICRC_HTTPCLIENT_API int ICRC_Http_ChangeEmail(
                                              IN  void*       icrc_handle, //句柄
                                              IN  const char* sEmail       //邮箱
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    //
    std::string body;
    Json::Value root, req;
    req["sEmail"] = sEmail;
    root["req"] = req;
    body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "regist", "11#309", body.c_str(), body.size(), true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code"];
    if (!code.isInt())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    err = code.asInt();
    return err;
}

/******************** 查询SN获取设备的信息 *********************/
ICRC_HTTPCLIENT_API int ICRC_Http_GetSNDevice(
                                              IN  void*       icrc_handle, //句柄
                                              IN  const char* sSN,      //设备序列号，不能为空
                                              OUT ICRC_SMARTHOME_DEVICE_DETAIL *pSnDevice //设备详细信息
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    //
    std::string body;
    Json::Value root, req;
    req["sSn"] = sSN;
    root["req"] = req;
    body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "smartHome", "10#308", body.c_str(), body.size(), true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code" ];
    Json::Value start= jsonObject["start"];
    Json::Value end  = jsonObject["end"  ];
    Json::Value objs = jsonObject["objs" ];
    if (!code.isInt() || !start.isInt() || !end.isInt() || !objs.isArray())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    err = code.asInt();
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    for (unsigned int i = 0; i < objs.size(); i++)
    {
        Json::Value vVirCode = objs[i]["sDevVirtualCode"];
        Json::Value vDevName = objs[i]["sDevName"       ];
        Json::Value vPasswd  = objs[i]["sPasswd"        ];
        Json::Value vNetAddr = objs[i]["sNetwork"       ];
        Json::Value vNetPort = objs[i]["iNetPort"       ];
        Json::Value vDevType = objs[i]["iDevType"       ];
        Json::Value vAddtion = objs[i]["sDevTypeAddtion"];
        Json::Value vPosition= objs[i]["sPosition"      ];
        Json::Value vParma   = objs[i]["sPar1"          ];
        Json::Value vComName = objs[i]["sCommunityName" ];
        Json::Value vStatus  = objs[i]["iStatus"        ];
        Json::Value vSN      = objs[i]["sSn"            ];
        Json::Value vAddIP   = objs[i]["sAddIp"         ];
        Json::Value vCity    = objs[i]["sCity"          ];
        Json::Value vISP     = objs[i]["sISP"           ];
        Json::Value vGrade   = objs[i]["iGValue"        ];
        Json::Value vARMSNetwork = objs[i]["sARMSNetwork"   ];
        Json::Value vARMSPort    = objs[i]["iARMSPort"      ];
        
        strncpy(pSnDevice->sVirtualCode, vVirCode.asCString(), sizeof(pSnDevice->sVirtualCode));
        strncpy(pSnDevice->sDevName, vDevName.asCString(), sizeof(pSnDevice->sDevName));
        strncpy(pSnDevice->sPasswd, vPasswd.asCString(), sizeof(pSnDevice->sPasswd));
        strncpy(pSnDevice->sNetAddr, vNetAddr.asCString(), sizeof(pSnDevice->sNetAddr));
        strncpy(pSnDevice->sDevTypeAddtion, vAddtion.asCString(), sizeof(pSnDevice->sDevTypeAddtion));
        strncpy(pSnDevice->sPosition, vPosition.asCString(), sizeof(pSnDevice->sPosition));
        strncpy(pSnDevice->sParam1, vParma.asCString(), sizeof(pSnDevice->sParam1));
        strncpy(pSnDevice->sCommunityName, vComName.asCString(), sizeof(pSnDevice->sCommunityName));
        strncpy(pSnDevice->sSN, vSN.asCString(), sizeof(pSnDevice->sSN));
        strncpy(pSnDevice->sAddIP, vAddIP.asCString(), sizeof(pSnDevice->sAddIP));
        strncpy(pSnDevice->sCity, vCity.asCString(), sizeof(pSnDevice->sCity));
        strncpy(pSnDevice->sISP, vISP.asCString(), sizeof(pSnDevice->sISP));
        strncpy(pSnDevice->sARMSNetwork, vARMSNetwork.asCString(), sizeof(pSnDevice->sARMSNetwork));
        pSnDevice->iARMSPort = vARMSPort.asInt();
        pSnDevice->iNetPort = vNetPort.asInt();
        pSnDevice->iDevType = vDevType.asInt();
        pSnDevice->iStatus  = vStatus.asInt();
        pSnDevice->iGValue = vGrade.asInt();
        break;
    }
    return ICRC_ERROR_OK;
}

/*********************** 删除绑定设备 **************************/
ICRC_HTTPCLIENT_API int ICRC_Http_UnbindDevice(
                                               IN  void*       icrc_handle, //句柄
                                               IN  const char* sDevVirtualCode  //设备虚号
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    //
    Json::Value root;
    root["req"]["sDevVirtualCode"] = sDevVirtualCode;
    std::string body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "smartHome", "12#108", body.c_str(), body.size(), true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code"];
    if (!code.isInt())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    return code.asInt();
}

/*********************** 密码重置申请 **************************/
ICRC_HTTPCLIENT_API int ICRC_Http_PasswordRestorePrepare(
                                                         IN	const char* sIpAddr,     //服务器ip地址
                                                         IN	int         iPort,       //服务器端口
                                                         IN	const char* sUserName,   //用户名称
                                                         OUT char*       sAuthCodeSeed, //身份识别码种子
                                                         OUT char*       sAuthCodeSeedIndex, //种子编号
                                                         OUT char*       sSmsNum  //短信发送号码
)
{
    CLock lock(&g_dhmtx);
    
    Json::Value root;
    root["req"]["sUserName"] = sUserName;
    std::string body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process_v2(sIpAddr, iPort, "/app/zwelife/regist", "1#509", body.c_str(), body.size(), jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    Json::Value code = jsonObject["code"];
    Json::Value objs = jsonObject["objs"];
    if (!code.isInt() || !objs.isArray() || !objs.size())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    err = code.asInt();
    if (err!=ICRC_ERROR_OK)
        return err;
    strcpy(sAuthCodeSeed, objs[0]["sAuthCodeSeed"].asCString());
    strcpy(sAuthCodeSeedIndex, objs[0]["sAuthCodeSeedIndex"].asCString());
    strcpy(sSmsNum, objs[0]["sSmsNum"].asCString());
    //
    return ICRC_ERROR_OK;
}

/************************ 密码重置 *****************************/
ICRC_HTTPCLIENT_API int ICRC_Http_PasswordRestore(
                                                  IN	const char* sIpAddr,     //服务器ip地址
                                                  IN	int         iPort,       //服务器端口
                                                  IN	const char* sUserName,   //用户名称
                                                  IN	const char*	sPassWordNew //新密码
)
{
    CLock lock(&g_dhmtx);
    
    // step1: 获取种子
    std::string sSeed;
    {
        Json::Value root;
        root["req"]["sUserName"] = sUserName;
        std::string body = root.toUnStyledString();
        //
        Json::Value jsonObject;
        int err = _http_process_v2(sIpAddr, iPort, "/app/zwelife/regist", "1#609", body.c_str(), body.size(), jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        Json::Value code = jsonObject["code"];
        if (!code.isInt())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
        Json::Value objs = jsonObject["objs"];
        if (!objs.isArray() || !objs[0]["sSeed"].isString())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        sSeed = objs[0]["sSeed"].asString();
    }
    
    // step2: 计算MD5
    std::string strMD5Password;
    {
        struct MD5Context md5c;
        unsigned char ucResult[16];
        std::string strTemp;
        
        strMD5Password.assign(sSeed);
        strMD5Password.append(sPassWordNew);
        
        MD5Init(&md5c);
        MD5Update(&md5c, (unsigned char*)strMD5Password.data(), strMD5Password.size());
        MD5Final(ucResult, &md5c);
        
        strMD5Password.assign((char*)ucResult, 16);
        strMD5Password = BinaryToHex(strMD5Password);
    }
    
    // step3: 重置
    {
        Json::Value root;
        root["req"]["sUserName" ] = sUserName;
        root["req"]["sPassWord" ] = strMD5Password;
        std::string body = root.toUnStyledString();
        //
        Json::Value jsonObject;
        int err = _http_process_v2(sIpAddr, iPort, "/app/zwelife/regist", "1#609", body.c_str(), body.size(), jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        Json::Value code = jsonObject["code"];
        if (!code.isInt())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
    }
    
    return ICRC_ERROR_OK;
}

/********************** 补充身份识别码 *************************/
ICRC_HTTPCLIENT_API int ICRC_Http_PatchAuthCode(
                                                IN  const char* sIpAddr,     //服务器ip地址
                                                IN  int         iPort,       //服务器端口
                                                IN  const char* sUserName, //用户名称
                                                IN  const char* sPassWord, //登录密码
                                                IN  const char* sAuthCode  //身份识别码
)
{
    CLock lock(&g_dhmtx);
    
    // step1: 获取种子
    std::string sSeed, sSeed2;
    {
        Json::Value root;
        root["req"]["sUserName"] = sUserName;
        std::string body = root.toUnStyledString();
        //
        Json::Value jsonObject;
        int err = _http_process_v2(sIpAddr, iPort, "/app/zwelife/regist", "11#709", body.c_str(), body.size(), jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        Json::Value code = jsonObject["code"];
        if (!code.isInt())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
        Json::Value objs = jsonObject["objs"];
        if (!objs.isArray() || !objs[0]["sSeed"].isString() || !objs[0]["sAuthCodeSeed"].isString())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        sSeed = objs[0]["sSeed"].asString();
        sSeed2 = objs[0]["sAuthCodeSeed"].asString();
    }
    
    // step2: 计算MD5
    std::string strMD5Password;
    {
        struct MD5Context md5c;
        unsigned char ucResult[16];
        std::string strTemp;
        
        strMD5Password.assign(sSeed);
        strMD5Password.append(sPassWord);
        
        MD5Init(&md5c);
        MD5Update(&md5c, (unsigned char*)strMD5Password.data(), strMD5Password.size());
        MD5Final(ucResult, &md5c);
        
        strMD5Password.assign((char*)ucResult, 16);
        strMD5Password = BinaryToHex(strMD5Password);
    }
    
    std::string strMD5AuthCode;
    {
        struct MD5Context md5c;
        unsigned char ucResult[16];
        std::string strTemp;
        
        strMD5AuthCode.assign(sSeed2);
        strMD5AuthCode.append(sAuthCode);
        
        MD5Init(&md5c);
        MD5Update(&md5c, (unsigned char*)strMD5AuthCode.data(), strMD5AuthCode.size());
        MD5Final(ucResult, &md5c);
        
        strMD5AuthCode.assign((char*)ucResult, 16);
        strMD5AuthCode = BinaryToHex(strMD5AuthCode);
    }
    
    // step3: 添加身份识别码
    {
        Json::Value root;
        root["req"]["sUserName"    ] = sUserName;
        root["req"]["sPassWord"    ] = strMD5Password;
        root["req"]["sAuthCode"    ] = strMD5AuthCode;
        std::string body = root.toUnStyledString();
        //
        Json::Value jsonObject;
        int err = _http_process_v2(sIpAddr, iPort, "/app/zwelife/regist", "11#709", body.c_str(), body.size(), jsonObject);
        if (err!=ICRC_ERROR_OK)
            return err;
        Json::Value code = jsonObject["code"];
        if (!code.isInt())
            return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
        err = code.asInt();
        if (err!=ICRC_ERROR_OK)
            return err;
    }
    
    return ICRC_ERROR_OK;
}

/********************** 添加用户订阅网关 ***********************/
ICRC_HTTPCLIENT_API int ICRC_Http_SubscribeGateway(
                                                   IN  void*       icrc_handle, //句柄
                                                   IN	const char* sGwVirtCode[], //网关虚号列表
                                                   IN unsigned int iCount   //订阅网关的数量
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    //
    Json::Value gwarray;
    for (unsigned int i = 0; i < iCount; i++)
    {
        Json::Value virc;
        virc["sDevVirtualCode"] = sGwVirtCode[i];
        gwarray.append(virc);
    }
    Json::Value root;
    root["req"]["iCount"] = iCount;
    root["req"]["objs"  ] = gwarray;
    std::string body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "smartHome", "11#108", body.c_str(), body.size(), true, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    //
    Json::Value code = jsonObject["code"];
    if (!code.isInt())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    //
    return code.asInt();
}

/************************* 查询callid **************************/
ICRC_HTTPCLIENT_API int ICRC_Http_CheckCallID(
                                              IN  void*       icrc_handle //句柄
)
{
    CLock lock(&g_dhmtx);
    
    ICRC_HTTP_HANDLE *pHandle = (ICRC_HTTP_HANDLE *)(icrc_handle);
    if (!pHandle) return ICRC_ERROR_INVALID_HANDLE;
    
    Json::Value root;
    root["req"]["sUserVirtualNo"] = pHandle->m_sVirtualCode;
    root["req"]["sMeid"         ] = pHandle->m_sMeid;
    root["req"]["sCallId"       ] = pHandle->m_sCallid;
    std::string body = root.toUnStyledString();
    //
    Json::Value jsonObject;
    int err = _http_process(pHandle, "regist", "1#0012", body.c_str(), body.size(), false, jsonObject);
    if (err!=ICRC_ERROR_OK)
        return err;
    Json::Value code = jsonObject["code"];
    if (!code.isInt())
        return ICRC_ERROR_HTTP_PARAM_NOT_FOUND;
    err = code.asInt();
    return err;
}