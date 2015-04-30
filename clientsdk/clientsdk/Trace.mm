#include "Trace.h"


const static std::string gs_LOG_LEVEL[9] = { "FATAL",
											 "CRITICAL",
											 "ERROR",
											 "WARNING",
											 "NOTICE",
											 "INFO",
											 "DEBUG",
											 "TRACE",
											 "NOTSET"};

void log_trace(int level,int line,const char * func,char * module,char * file,std::string msg)
{
	std::ostringstream ostr;

	ostr<<"["<<gs_LOG_LEVEL[level-1]<<"] "
		<<"["<<module<<"] "
		<<file<<" "
		<<line<<" "
		<<func<<" "
		<<msg;

	printf("%s\r\n",msg.c_str()/*ostr.str().c_str()*/);
}