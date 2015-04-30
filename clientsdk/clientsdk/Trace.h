
#ifndef TRACE_H
#define TRACE_H

#if defined(UAMS)
#define CURRENT_MODULE_NAME "UAMS"
#elif defined(FDMS)
#define CURRENT_MODULE_NAME "FDMS"
#elif defined(SHBG)
#define CURRENT_MODULE_NAME "SHBG"
#elif defined(UPNP_STACK_SVR)
#define CURRENT_MODULE_NAME "UPNP_STACK_SVR"
#elif defined(UPNP_STACK_CLI)
#define CURRENT_MODULE_NAME "UPNP_STACK_CLI"
#elif defined(UPNP_STACK_DEV)
#define CURRENT_MODULE_NAME "UPNP_STACK_DEV"
#elif defined(UPNP_CLI_LOGIC)
#define CURRENT_MODULE_NAME "UPNP_CLI_LOGIC"
#else
#define CURRENT_MODULE_NAME "JNI_WAPPER"
#endif
#ifdef NO_LOGLIB
#include <string>
#include <sstream>


#define MODULE_NAME CURRENT_MODULE_NAME

#if defined(_WIN32) || defined(_WIN64) || defined(_WIN32_WCE)
#define SEPERATE_CHAR "\\"
#else
#define SEPERATE_CHAR "/" 
#endif

#define TRACENAME(mname,lvl,msg)                                                           \
{                                                                                          \
	std::ostringstream ostr;                                                               \
	ostr<<msg; 	                                                                           \
	log_trace(lvl,__LINE__,__FUNCTION__,__FILE__,mname,ostr.str().c_str());                \
}

//#define TRACENAME(mname,lvl,msg)                                                           \
//{                                                                                          \
//	std::ostringstream ostr;                                                               \
//	ostr<<msg; 	                                                                           \
//	NSLog(@"%d %d %s %s %s %s",lvl,__LINE__,__FUNCTION__,__FILE__,mname,ostr.str().c_str());                \
//}

#define ERROR_TRACE(str) TRACENAME(MODULE_NAME,3,str)
#define WARN_TRACE(str)  TRACENAME(MODULE_NAME,4,str)
#define INFO_TRACE(str)  TRACENAME(MODULE_NAME,6,str)
#define DEBUG_TRACE(str) TRACENAME(MODULE_NAME,7,str)


void log_trace(int level,int line,const char * func,char * module,char * file,std::string msg);
#elif defined(ANDROID)
#include <string>
#include <sstream>
#include <android/log.h>

#define MODULE_NAME CURRENT_MODULE_NAME

#if defined(_WIN32) || defined(_WIN64) || defined(_WIN32_WCE)
#define SEPERATE_CHAR "\\"
#else
#define SEPERATE_CHAR "/" 
#endif

#define TRACENAME(lvl,msg)																		\
{																								\
	std::ostringstream ostr;																	\
	ostr<<msg; 	                                                                       			\
   __android_log_print(lvl, MODULE_NAME,ostr.str().c_str());									\
}

#define ERROR_TRACE(str) TRACENAME(ANDROID_LOG_ERROR,str)
#define WARN_TRACE(str)  TRACENAME(ANDROID_LOG_WARN,str)
#define INFO_TRACE(str)  TRACENAME(ANDROID_LOG_INFO,str)
#define DEBUG_TRACE(str) TRACENAME(ANDROID_LOG_DEBUG,str)
#else
#include "ZWLog.h"

#define MODULE_NAME      CURRENT_MODULE_NAME
#define MODULE_NAME_EN   CURRENT_MODULE_NAME
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