
#ifndef _VTUTILDEFINE_H
#define _VTUTILDEFINE_H

//////////////////////////////////////////////////////////////////////
// First definition: choose OS
//////////////////////////////////////////////////////////////////////

#ifdef WIN32
  #ifndef VT_WIN32
    #define VT_WIN32
  #endif // VT_WIN32
#endif // WIN32

#ifdef UNIX
  #ifndef VT_UNIX
    #define VT_UNIX
  #endif // VT_UNIX
#endif // UNIX

#ifdef LINUX
  #ifndef VT_LINUX
    #define VT_LINUX
  #endif // VT_LINUX
  #ifndef VT_UNIX
    #define VT_UNIX
  #endif // VT_UNIX
#endif // LINUX

#ifdef MACOS
  #ifndef VT_MACOS
    #define VT_MACOS
  #endif // VT_MACOS
#endif // MACOS

#ifndef VTResult
#define VTResult int
#endif
//////////////////////////////////////////////////////////////////////
// OS API definition
//////////////////////////////////////////////////////////////////////

#ifdef VT_MACOS
	#define	_BSD_TIME_T_	long			/* time() */
	typedef	_BSD_TIME_T_	time_t;
	#ifndef MachOSupport
	# define socklen_t int
	#endif	//MachOSupport
	#define	EINPROGRESS	36		/* Operation now in progress */
	#define EINTR		4
	#define EPERM		1
	typedef int sem_t;
	#define	RLIMIT_NOFILE	8
	//#define VT_HAS_BUILTIN_ATOMIC_OP 1
	enum
	{
	  PTHREAD_MUTEX_TIMED_NP,
	  PTHREAD_MUTEX_RECURSIVE_NP,
	  PTHREAD_MUTEX_ERRORCHECK_NP,
	  PTHREAD_MUTEX_ADAPTIVE_NP
	  
	  , PTHREAD_MUTEX_FAST_NP = PTHREAD_MUTEX_ADAPTIVE_NP
	};

	#ifndef MachOSupport
	#include "ioccom.h"
	#endif	//MachOSupport

	/* Generic file-descriptor ioctl's. */
	#define	FIOCLEX		 _IO('f', 1)		/* set close on exec on fd */
	#define	FIONCLEX	 _IO('f', 2)		/* remove close on exec */
	#define	FIONREAD	_IOR('f', 127, int)	/* get # bytes to read */
	#define	FIONBIO		_IOW('f', 126, int)	/* set/clear non-blocking i/o */
	#define	FIOASYNC	_IOW('f', 125, int)	/* set/clear async i/o */
	#define	FIOSETOWN	_IOW('f', 124, int)	/* set owner */
	#define	FIOGETOWN	_IOR('f', 123, int)	/* get owner */
	#define	FIODTYPE	_IOR('f', 122, int)	/* get d_type */

 //for TCP	
 	#ifndef MachOSupport
	#define	TCP_NODELAY	0x01	/* don't delay send to coalesce packets */
	#endif
	
	#ifndef MachOSupport
	#define	TCP_MAXSEG	0x02	/* set maximum segment size */
	#endif
	
	#define TCP_NOPUSH	0x04	/* don't push last block of write */
	#define TCP_NOOPT	0x08	/* don't use TCP options */
	
	#ifndef MachOSupport
	#define TCP_KEEPALIVE	0x10	/* idle time used when SO_KEEPALIVE is enabled */
	#endif
//pthread
	
	#define PTHREAD_CREATE_JOINABLE      1
	#define PTHREAD_CREATE_DETACHED      2

	#define PTHREAD_INHERIT_SCHED        1
	#define PTHREAD_EXPLICIT_SCHED       2

	#define PTHREAD_CANCEL_ENABLE        0x01  /* Cancel takes place at next cancellation point */
	#define PTHREAD_CANCEL_DISABLE       0x00  /* Cancel postponed */
	#define PTHREAD_CANCEL_DEFERRED      0x02  /* Cancel waits until cancellation point */
	#define PTHREAD_CANCEL_ASYNCHRONOUS  0x00  /* Cancel occurs immediately */

	/* We only support PTHREAD_SCOPE_SYSTEM */
	#define PTHREAD_SCOPE_SYSTEM         1
	#define PTHREAD_SCOPE_PROCESS        2

	/* We only support PTHREAD_PROCESS_PRIVATE */
	#define PTHREAD_PROCESS_SHARED         1
	#define PTHREAD_PROCESS_PRIVATE        2

	//extern CHARSET_INFO *default_charset_info;
	//#define my_ctype	(default_charset_info->ctype)
	//#define	isspace(c)	((my_ctype+1)[(uchar) (c)] & _S)
	// temp define for compiler
	
  	#ifndef MachOSupport
    struct timespec {
			time_t  tv_sec;         /* seconds */
			long    tv_nsec;        /* and nanoseconds */  
	  };

	//#define EAGAIN	  35
	//#define EWOULDBLOCK EAGAIN
	#define EWOULDBLOCK 35
	#endif	//MachOSupport
#endif

#ifdef VT_WIN32
//  #ifndef NOMINMAX
//    #define NOMINMAX
//  #endif // NOMINMAX

  // supports Windows NT 4.0 and later, not support Windows 95.
  // mainly for using winsock2 functions
  #ifndef _WIN32_WINNT
    #define _WIN32_WINNT 0x0400
  #endif // _WIN32_WINNT
  #define    WIN32_LEAN_AND_MEAN

#ifndef   FD_SETSIZE
#define   FD_SETSIZE     256
#endif

  #include <windows.h>
  #include <winsock2.h>

  // The ordering of the fields in this struct is important. 
  // It has to match those in WSABUF.
  struct iovec
  {
    u_long iov_len; // byte count to read/write
    char *iov_base; // data to be read/written
  };

  #define EWOULDBLOCK             WSAEWOULDBLOCK
  #define EINPROGRESS             WSAEINPROGRESS
  #define EALREADY                WSAEALREADY
  #define ENOTSOCK                WSAENOTSOCK
  #define EDESTADDRREQ            WSAEDESTADDRREQ
  #define EMSGSIZE                WSAEMSGSIZE
  #define EPROTOTYPE              WSAEPROTOTYPE
  #define ENOPROTOOPT             WSAENOPROTOOPT
  #define EPROTONOSUPPORT         WSAEPROTONOSUPPORT
  #define ESOCKTNOSUPPORT         WSAESOCKTNOSUPPORT
  #define EOPNOTSUPP              WSAEOPNOTSUPP
  #define EPFNOSUPPORT            WSAEPFNOSUPPORT
  #define EAFNOSUPPORT            WSAEAFNOSUPPORT
  #define EADDRINUSE              WSAEADDRINUSE
  #define EADDRNOTAVAIL           WSAEADDRNOTAVAIL
  #define ENETDOWN                WSAENETDOWN
  #define ENETUNREACH             WSAENETUNREACH
  #define ENETRESET               WSAENETRESET
  #define ECONNABORTED            WSAECONNABORTED
  #define ECONNRESET              WSAECONNRESET
  #define ENOBUFS                 WSAENOBUFS
  #define EISCONN                 WSAEISCONN
  #define ENOTCONN                WSAENOTCONN
  #define ESHUTDOWN               WSAESHUTDOWN
  #define ETOOMANYREFS            WSAETOOMANYREFS
  #define ETIMEDOUT               WSAETIMEDOUT
  #define ECONNREFUSED            WSAECONNREFUSED
  #define ELOOP                   WSAELOOP
  #define EHOSTDOWN               WSAEHOSTDOWN
  #define EHOSTUNREACH            WSAEHOSTUNREACH
  #define EPROCLIM                WSAEPROCLIM
  #define EUSERS                  WSAEUSERS
  #define EDQUOT                  WSAEDQUOT
  #define ESTALE                  WSAESTALE
  #define EREMOTE                 WSAEREMOTE
#endif // VT_WIN32

#ifdef VT_WIN32
  typedef HANDLE VT_HANDLE;
  typedef SOCKET VT_SOCKET;
  #define VT_INVALID_HANDLE INVALID_HANDLE_VALUE
  #define VT_INVALID_SOCKET INVALID_SOCKET
  #define VT_SOCKET_ERROR  SOCKET_ERROR
  #define VT_SD_RECEIVE SD_RECEIVE
  #define VT_SD_SEND SD_SEND
  #define VT_SD_BOTH SD_BOTH
  //typedef unsigned __int64  VTUInt64;
#else // !VT_WIN32
  typedef int VT_HANDLE;
  typedef VT_HANDLE VT_SOCKET;
  #define VT_INVALID_HANDLE -1
  #define VT_INVALID_SOCKET -1
  #define VT_SOCKET_ERROR  -1
  #define VT_SD_RECEIVE 0
  #define VT_SD_SEND 1
  #define VT_SD_BOTH 2
  #define closesocket close 
  //typedef unsigned long long  VTUInt64;
#endif // VT_WIN32

#ifdef VT_UNIX 
  typedef long long           LONGLONG;
  typedef unsigned int       DWORD;
  typedef int                 LONG;
//  typedef int                 BOOL;
  typedef int                   INT;
  typedef unsigned int          UINT;
  typedef int                 *LPLONG;
  typedef int                  *LPINT;
  typedef unsigned int         *LPUINT;
  typedef float                 FLOAT;
  typedef FLOAT                *PFLOAT;
  typedef short				SHORT;
  typedef unsigned char       BYTE;
  typedef unsigned short        WORD;
//  typedef BOOL                 *LPBOOL;
  typedef WORD                 *LPWORD;
  typedef DWORD                *LPDWORD;
  typedef void                 *LPVOID;
  typedef const void           *LPCVOID;
  typedef char                  CHAR;
  typedef char                  TCHAR;
  typedef unsigned short        WCHAR;
  typedef const char           *LPCSTR;
  typedef LPCSTR				LPCTSTR;
  typedef char                 *LPSTR;
  typedef LPSTR					LPTSTR;
  typedef const unsigned short *LPCWSTR;
  typedef unsigned short       *LPWSTR;
  typedef BYTE                 *LPBYTE;
  typedef const BYTE           *LPCBYTE;
  
  #ifndef FALSE
    #define FALSE 0
  #endif // FALSE
  #ifndef TRUE
    #define TRUE 1
  #endif // TRUE
#endif // !VT_UNIX

class VTUInt64
{
public:
	VTUInt64();
	~VTUInt64();
	
	VTUInt64(const VTUInt64 & a);
	VTUInt64(const unsigned int & a);
	
	unsigned int Low();
	unsigned int High();
	void SetLow(unsigned int ui);
	void SetHigh(unsigned int ui);

	bool IsZero();
	friend bool operator==(VTUInt64 &a1,VTUInt64 &a2);
	friend bool operator!=(VTUInt64 &a1,VTUInt64 &a2);
private:
	unsigned int uiLow;
	unsigned int uiHigh;
};

bool operator==(VTUInt64 &a1,VTUInt64 &a2);

bool operator!=(VTUInt64 &a1,VTUInt64 &a2);

#ifdef VT_SOLARIS
  #define INADDR_NONE             0xffffffff
#endif

#ifdef _MSC_VER
  #ifndef _MT
    #error Error: please use multithread version of C runtime library.
  #endif // _MT

  #pragma warning(disable: 4786) // identifier was truncated to '255' characters in the browser information(mainly brought by stl)
  #pragma warning(disable: 4355) // disable 'this' used in base member initializer list
  #pragma warning(disable: 4275) // deriving exported class from non-exported
  #pragma warning(disable: 4251) // using non-exported as public in exported
#endif // _MSC_VER

#ifdef VT_WIN32
  #if defined (_LIB) || (VT_OS_BUILD_LIB) 
    #define VT_OS_EXPORT
  #else 
    #if defined (_USRDLL) || (VT_OS_BUILD_DLL)
      #define VT_OS_EXPORT __declspec(dllexport)
    #else 
      #define VT_OS_EXPORT __declspec(dllimport)
    #endif // _USRDLL || VT_OS_BUILD_DLL
  #endif // _LIB || VT_OS_BUILD_LIB
#else
  #define VT_OS_EXPORT 
#endif // !VT_WIN32

#if defined (VT_WIN32)
  #define VT_OS_SEPARATE '\\'
#elif defined (VT_UNIX) || defined(VT_MACOS)
  #define VT_OS_SEPARATE '/'
#endif

#define VT_CLOSE_SOCKET(s) { closesocket(s); s = VT_INVALID_SOCKET; }

#define VT_BIT_ENABLED(dword, bit) (((dword) & (bit)) != 0)
#define VT_BIT_DISABLED(dword, bit) (((dword) & (bit)) == 0)
#define VT_BIT_CMP_MASK(dword, bit, mask) (((dword) & (bit)) == mask)
#define VT_SET_BITS(dword, bits) (dword |= (bits))
#define VT_CLR_BITS(dword, bits) (dword &= ~(bits))

#define VT_LOWORD(l) ((unsigned short)((unsigned int)(l) & 0xffff))
#define VT_HIWORD(l) ((unsigned short)((unsigned int)(l) >> 16))
#define VT_MAKEDWORD(l,h) ((unsigned int)(((unsigned short)((unsigned int)(l) & 0xffff)) | ((unsigned int)((unsigned short)((unsigned int)(h) & 0xffff))) << 16))

inline unsigned short VT_STRTO_USHORT(unsigned char *str)
{
	return ((unsigned short)(*(str))) | (((unsigned short)(*((str)+1)))<<8);
}

inline unsigned int VT_STRTO_UINT(unsigned char *str)
{
	return ((unsigned int)(*(str))) | (((unsigned int)(*((str)+1)))<<8) | 
		   (((unsigned int)(*((str)+2)))<<16) | (((unsigned int)(*((str)+3)))<<24);
}

inline unsigned char * VT_USHORT_TOSTR(unsigned char *str,unsigned short d)
{
	*str = (unsigned char)(d&0xFF);
	*(str+1) = (unsigned char)(d>>8);
	return str+2;
}

inline unsigned char * VT_UINT_TOSTR(unsigned char *str,unsigned int d)
{
	*str = (unsigned char)(d&0xFF);
	*(str+1) = (unsigned char)((d&0xFF00)>>8);
	*(str+2) = (unsigned char)((d&0xFF0000)>>16);
	*(str+3) = (unsigned char)(d>>24);
	return str+4;
}

//////////////////////////////////////////////////////////////////////
// C definition
//////////////////////////////////////////////////////////////////////

#ifdef VT_WIN32
  #include <string.h>
  #include <stdio.h>
  #include <stdlib.h>
  #include <time.h>
  #include <limits.h>
  #include <stddef.h>
  #include <stdarg.h>
  #include <signal.h>
  #include <errno.h>
  #include <wchar.h>

  #include <crtdbg.h>
  #include <process.h>
  #define getpid _getpid
  #define snprintf _snprintf
  #define strcasecmp _stricmp
  #define strncasecmp _strnicmp
  #define vsnprintf _vsnprintf
#endif // VT_WIN32

#ifdef VT_UNIX
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <unistd.h>
  #include <errno.h>
  #include <limits.h>
  #include <stdarg.h>
  #include <time.h>
  #include <signal.h>
  #include <sys/stat.h>
  #ifdef ANDROID //Android平台头文件位置变动
  #include <fcntl.h>
  #else
  #include <sys/fcntl.h>
  #endif
  #include <pthread.h>
  #include <fcntl.h>
  #include <sys/types.h>
  #include <sys/ioctl.h>
  #include <sys/socket.h>
  #include <sys/time.h>
  #include <netinet/in.h>
  #include <arpa/inet.h>
  #include <netdb.h>
  #include <ctype.h>
  
  #define EWOULDBLOCK EAGAIN
 
  #include <assert.h>

  #include <netinet/tcp.h>
  #include <semaphore.h>
#endif // VT_UNIX

#ifdef VT_SOLARIS
  #include <sys/filio.h>
#endif//VT_SOLARIS


#ifdef VT_WIN32
#define VT_IOV_MAX 64
#else
// This is defined by XOPEN to be a minimum of 16.  POSIX.1g
// also defines this value.  platform-specific config.h can
// override this if need be.
#if !defined (IOV_MAX)
#define IOV_MAX 16
#endif // !IOV_MAX
#define VT_IOV_MAX IOV_MAX
#endif // VT_WIN32

#ifdef VT_WIN32
	typedef DWORD VT_THREAD_ID;
	typedef HANDLE VT_THREAD_HANDLE;
	typedef HANDLE VT_SEMAPHORE_T;
	typedef CRITICAL_SECTION VT_THREAD_MUTEX_T;
#else // !VT_WIN32
	typedef pthread_t VT_THREAD_ID;
	typedef VT_THREAD_ID VT_THREAD_HANDLE;
	typedef sem_t VT_SEMAPHORE_T;
	typedef pthread_mutex_t VT_THREAD_MUTEX_T;
#endif // VT_WIN32

#ifdef VT_MACOS
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <unistd.h>
  #ifndef MachOSupport
  #include <DateTimeUtils.h>
  	#include <CGBase.h>
  #else
  	#include <pthread.h>
  	#include <unistd.h>
  	#include <sys/uio.h>
  	#include <netinet/in.h>
  	#include <arpa/inet.h>
  	#include <sys/types.h>
  	#include <sys/socket.h>
  	#include <netdb.h>
  	#include <semaphore.h>
  	#include <sys/resource.h>
  	#include <sys/ioctl.h>
    #include <sys/stat.h>
    #include <sys/fcntl.h>
  #endif	//MachOSupport
  #include <utime.h>
  #include <cstdint>

  
  
  #ifndef MachOSupport	
  #include "CFMCallSysBundle.h"
  #include "sys-socket.h"
  #include "netinet-in.h"
  #include "netdb.h"
  #include "fcntl.h"
  #endif	//MachOSupport
#endif // VT_MACOS

 
//////////////////////////////////////////////////////////////////////
// Assert
//////////////////////////////////////////////////////////////////////

#ifdef VT_WIN32
  #include <crtdbg.h>
  #ifdef _DEBUG
    #define VT_DEBUG
  #endif // _DEBUG

  #if defined (VT_DEBUG)
    #define VT_ASSERTE _ASSERTE
  #endif // VT_DEBUG
#endif // VT_WIN32

#ifdef VT_UNIX
  #include <assert.h>
  #if defined (VT_DEBUG) && !defined (VT_DISABLE_ASSERTE)
    #define VT_ASSERTE assert
  #endif // VT_DEBUG
#endif //VT_UNIX

#ifdef VT_DISABLE_ASSERTE
  #include "VTDebug.h"
  #ifdef VT_ASSERTE
	#undef VT_ASSERTE
  #endif
  #define VT_ASSERTE(expr) \
	do { \
		if (!(expr)) { \
			VT_ERROR_TRACE(__FILE__ << ":" << __LINE__ << " Assert failed: " << #expr); \
		} \
	} while (0)
#endif // VT_DISABLE_ASSERTE

#ifndef VT_ASSERTE
  #define VT_ASSERTE(expr) 
#endif // VT_ASSERTE

//#define VT_ASSERTE_THROW VT_ASSERTE

#ifdef VT_DISABLE_ASSERTE
  #define VT_ASSERTE_RETURN(expr, rv) \
	do { \
		if (!(expr)) { \
			VT_ERROR_TRACE(__FILE__ << ":" << __LINE__ << " Assert failed: " << #expr); \
			return rv; \
		} \
	} while (0)

  #define VT_ASSERTE_RETURN_VOID(expr) \
	do { \
		if (!(expr)) { \
			VT_ERROR_TRACE(__FILE__ << ":" << __LINE__ << " Assert failed: " << #expr); \
			return; \
		} \
	} while (0)
#else
  #define VT_ASSERTE_RETURN(expr, rv) \
	do { \
		VT_ASSERTE((expr)); \
		if (!(expr)) { \
			VT_ERROR_TRACE(__FILE__ << ":" << __LINE__ << " Assert failed: " << #expr); \
			return rv; \
		} \
	} while (0)

  #define VT_ASSERTE_RETURN_VOID(expr) \
	do { \
		VT_ASSERTE((expr)); \
		if (!(expr)) { \
			VT_ERROR_TRACE(__FILE__ << ":" << __LINE__ << " Assert failed: " << #expr); \
			return; \
		} \
	} while (0)

#endif // VT_DISABLE_ASSERTE


//#if 0
#ifdef WIN32 //winsock bug http://support.microsoft.com/kb/263823/
#define SIO_UDP_CONNRESET _WSAIOW(IOC_VENDOR,12)
#define VT_UDP_ICMP_PACK(sock)    \
do                                 \
{                                  \
	BOOL bNewBehavior = FALSE;     \
	DWORD dwBytesReturned = 0;     \
	WSAIoctl(sock,SIO_UDP_CONNRESET,&bNewBehavior,sizeof(bNewBehavior),NULL,0,&dwBytesReturned,NULL,NULL); \
}                                  \
while (0)
#else
#define VT_UDP_ICMP_PACK(sock)    
#endif

#ifdef WIN32
__int64 CURRENTTIME_MS(void);
#else
#define CURRENTTIME_MS 0
#define _abs64 llabs
#endif

#define PROCESS_MSG_PER      (10)    //处理线程每次最大处理消息数目

#endif // !_VTDEFINE_H
