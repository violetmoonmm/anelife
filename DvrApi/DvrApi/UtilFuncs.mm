#include "UtilFuncs.h"
#include "Trace.h"

//设置套接字阻塞模式
int SetBlockMode(FCL_SOCKET sock,bool bIsNoBlock)
{
	int iRet;
	int iBlock;
	if ( bIsNoBlock ) //非阻塞模式
	{
		iBlock = 1;
	}
	else //阻塞模式
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

int SetTcpKeepalive(FCL_SOCKET sock) //设置TCP保活
{
	int iRet = 0;
#ifdef PLAT_WIN32
#include <mstcpip.h>  
	BOOL bKeepAlive = TRUE;  
	iRet = setsockopt(sock,SOL_SOCKET,SO_KEEPALIVE,(char*)&bKeepAlive,sizeof(bKeepAlive));  
	if ( iRet == SOCKET_ERROR )  
	{  
		ERROR_TRACE("setsockopt SO_KEEPALIVE failed.err="<<WSAGetLastError());  
		return -1;  
	}  
	// set KeepAlive parameter  
	tcp_keepalive alive_in;  
	tcp_keepalive alive_out;  
	alive_in.keepalivetime		= 5000; //5s  
	alive_in.keepaliveinterval  = 1000;	//1s  
	alive_in.onoff              = TRUE;  
	unsigned long ulBytesReturn = 0;  
	iRet = WSAIoctl(sock,SIO_KEEPALIVE_VALS,&alive_in,sizeof(alive_in),  
					&alive_out,sizeof(alive_out),&ulBytesReturn,NULL,NULL);  
	if ( iRet == SOCKET_ERROR )  
	{  
		ERROR_TRACE("WSAIoctl failed.err"<<WSAGetLastError());  
		return -1;  
	}  
  

#else
//	int keepalive = 1;        // 打开探测
//	int keepidle = 60;        // 开始探测前的空闲等待时间
//	int keepintvl = 10;       // 发送探测分节的时间间隔
//	int keepcnt = 3;			 // 发送探测分节的次数
//	iRet = setsockopt(sock,SOL_SOCKET,SO_KEEPALIVE,(void *)&keepalive,sizeof(keepalive));
//	if ( iRet < 0 )
//	{
//		ERROR_TRACE("set SO_KEEPALIVE failed,error code="<<errno);
//		return -1;
//	}
//	iRet = setsockopt(sock,SOL_TCP,TCP_KEEPIDLE,(void *)&keepidle,sizeof(keepidle));
//	if ( iRet < 0 )
//	{
//		ERROR_TRACE("set TCP_KEEPIDLE failed,error code="<<errno);
//		return -1;
//	}
//	iRet = setsockopt(sock,SOL_TCP,TCP_KEEPINTVL,(void *) &keepintvl,sizeof(keepintvl));
//	if ( iRet < 0 )
//	{
//		ERROR_TRACE("set TCP_KEEPINTVL failed,error code="<<errno);
//		return -1;
//	}
//	iRet = setsockopt(sock,SOL_TCP,TCP_KEEPCNT,(void *) &keepcnt,sizeof(keepcnt));
//	if ( iRet < 0 )
//	{
//		ERROR_TRACE("set TCP_KEEPCNT failed,error code="<<errno);
//		return -1;
//	}
#endif
	return 0;
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



#ifdef PLAT_WIN32
#else
unsigned int WSAGetLastError()
{
	return errno;
}
#endif



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

int DHTimr2Utc(const char *szDHTime)
{
	int iTime;

	if ( !szDHTime )
	{
		return -1;
	}
	struct tm tmTime;
	if ( EOF == sscanf(szDHTime,"%d-%d-%d %d:%d:%d",&tmTime.tm_year,
		&tmTime.tm_mon,&tmTime.tm_mday,&tmTime.tm_hour,&tmTime.tm_min,
		&tmTime.tm_sec) )
	{
		//printf("Decode time failed\n");
		//ERROR_TRACE("Decode time failed");
		return -1;
	}

	tmTime.tm_year -= 1900;
	tmTime.tm_mon--;

	tmTime.tm_isdst = 0;
	tmTime.tm_wday = 0;
	tmTime.tm_yday = 0;

	//utc时间 去除时区
	iTime = mktime(&tmTime);//_mkgmtime32(&tmTime);
	if ( -1 == iTime )
	{
		//printf("time scope out of range\n");
		//ERROR_TRACE("time scope out of range");
		return -1;
	}
	return iTime;
}