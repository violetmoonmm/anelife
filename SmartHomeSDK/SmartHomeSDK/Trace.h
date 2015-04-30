
#ifndef TRACE_H
#define TRACE_H

#define MODULE_NAME "sh_sdk"

#if defined(_WIN32) || defined(_WIN64) || defined(_WIN32_WCE)
#define SEPERATE_CHAR "\\"
#else
#define SEPERATE_CHAR "/" 
#endif

#ifdef NO_LOGLIB
#include <string>
#include <sstream>

#define TRACENAME(mname,lvl,msg)                                                           \
{                                                                                          \
	std::ostringstream ostr;                                                               \
	ostr<<msg; 	                                                                           \
	NSLog(@"%d %s %s",lvl,mname,ostr.str().c_str());                \
}

//#define TRACENAME(mname,lvl,msg)

#define ERROR_TRACE(str) TRACENAME(MODULE_NAME,3,str)
#define WARN_TRACE(str)  TRACENAME(MODULE_NAME,4,str)
#define INFO_TRACE(str)  TRACENAME(MODULE_NAME,6,str)
#define DEBUG_TRACE(str) TRACENAME(MODULE_NAME,7,str)


void log_trace(int level,int line,const char * func,char * module,char * file,std::string msg);
	
#elif defined(ANDROID)
#include <string>
#include <sstream>
#include <android/log.h>

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
//#include "ZWLog.h"

#define ERROR_TRACE(str) TRACENAME(MODULE_NAME,3,str)
#define WARN_TRACE(str)  TRACENAME(MODULE_NAME,4,str)
#define INFO_TRACE(str)  TRACENAME(MODULE_NAME,6,str)
#define DEBUG_TRACE(str) TRACENAME(MODULE_NAME,7,str)
#define SYSEX_TRACE(str) TRACENAME(MODULE_NAME,100,str) // ‰≥ˆµΩ»’÷æ∑˛ŒÒ∆˜
#endif

#pragma warning(disable:4267)
#pragma warning(disable:4018)

#endif



