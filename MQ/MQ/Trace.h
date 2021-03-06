
#ifndef TRACE_H
#define TRACE_H

#ifdef NON_LOGLIB
#include <string>
#include <sstream>


#define MODULE_NAME "upnp_sh"

#if defined(_WIN32) || defined(_WIN64) || defined(_WIN32_WCE)
#define SEPERATE_CHAR "\\"
#else
#define SEPERATE_CHAR "/" 
#endif

//#define TRACENAME(mname,lvl,msg)                                                           \
//{                                                                                          \
//	std::ostringstream ostr;                                                               \
//	ostr<<msg; 	                                                                           \
//	log_trace(lvl,__LINE__,__FUNCTION__,__FILE__,mname,ostr.str().c_str());                \
//}

#define TRACENAME(mname,lvl,msg)

#define ERROR_TRACE(str) TRACENAME(MODULE_NAME,3,str)
#define WARN_TRACE(str)  TRACENAME(MODULE_NAME,4,str)
#define INFO_TRACE(str)  TRACENAME(MODULE_NAME,6,str)
#define DEBUG_TRACE(str) TRACENAME(MODULE_NAME,7,str)


void log_trace(int level,int line,const char * func,char * module,char * file,std::string msg);
#elif defined(ANDROID)
#include <string>
#include <sstream>
#include <android/log.h>

#define MODULE_NAME "upnp_sh"

#if defined(_WIN32) || defined(_WIN64) || defined(_WIN32_WCE)
#define SEPERATE_CHAR "\\"
#else
#define SEPERATE_CHAR "/" 
#endif

#define TRACENAME(lvl,msg)																		\
{																									\
	std::ostringstream ostr;																		\
	ostr<<msg; 	                                                                       \
   __android_log_print(lvl, MODULE_NAME,ostr.str().c_str());									\
}

#define ERROR_TRACE(str) TRACENAME(ANDROID_LOG_ERROR,str)
#define WARN_TRACE(str)  TRACENAME(ANDROID_LOG_WARN,str)
#define INFO_TRACE(str)  TRACENAME(ANDROID_LOG_INFO,str)
#define DEBUG_TRACE(str) TRACENAME(ANDROID_LOG_DEBUG ,str)
#else
#include "ZWLog.h"

#define MODULE_NAME      "sh"
#define MODULE_NAME_EN   "sh"
#define MODULE_NAME_CHN  "智能家居"
#define MODULE_VERSION   "1.0.0.0"
#define MODULE_BUILD     __DATE__" "__TIME__    
#define MODULE_OID       "1.1.2.1"
#define MODULE_DESC      "智能家居"

#define ERROR_TRACE(str) TRACENAME(MODULE_NAME,3,str)
#define WARN_TRACE(str)  TRACENAME(MODULE_NAME,4,str)
#define INFO_TRACE(str)  TRACENAME(MODULE_NAME,6,str)
#define DEBUG_TRACE(str) TRACENAME(MODULE_NAME,7,str)
#define SYSEX_TRACE(str) TRACENAME(MODULE_NAME,100,str) //输出到日志服务器
#endif

#endif