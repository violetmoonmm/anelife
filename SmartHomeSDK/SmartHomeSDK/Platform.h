
#ifndef PLATFORM_H
#define PLATFORM_H


#ifdef WIN32
  #ifndef PLAT_WIN32
    #define PLAT_WIN32
  #endif // PLAT_WIN32
#endif // WIN32

#ifdef UNIX
  #ifndef PLAT_UNIX
    #define PLAT_UNIX
  #endif // PLAT_UNIX
#endif // UNIX

#ifdef LINUX
  #ifndef PLAT_LINUX
    #define PLAT_LINUX
  #endif // PLAT_LINUX
  #ifndef PLAT_UNIX
    #define PLAT_UNIX
  #endif // PLAT_UNIX
#endif // LINUX

#ifdef PLAT_WIN32

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
#endif // PLAT_WIN32

#ifdef PLAT_WIN32
  typedef HANDLE FCL_HANDLE;
  typedef SOCKET FCL_SOCKET;
  #define FCL_INVALID_HANDLE INVALID_HANDLE_VALUE
  #define FCL_INVALID_SOCKET INVALID_SOCKET
  #define FCL_SOCKET_ERROR SOCKET_ERROR
  #define FCL_SD_RECEIVE SD_RECEIVE
  #define FCL_SD_SEND SD_SEND
  #define FCL_SD_BOTH SD_BOTH
#else // !PLAT_WIN32
  typedef int FCL_HANDLE;
  typedef FCL_HANDLE FCL_SOCKET;
  #define FCL_INVALID_HANDLE -1
  #define FCL_INVALID_SOCKET -1
  #define FCL_SOCKET_ERROR -1
  #define FCL_SD_RECEIVE 0
  #define FCL_SD_SEND 1
  #define FCL_SD_BOTH 2
  #define closesocket close 
#endif // PLA_WIN32

#ifdef PLAT_UNIX 
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
  typedef BOOL                 *LPBOOL;
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

#ifdef _MSC_VER
  #ifndef _MT
    #error Error: please use multithread version of C runtime library.
  #endif // _MT

  #pragma warning(disable: 4786) // identifier was truncated to '255' characters in the browser information(mainly brought by stl)
  #pragma warning(disable: 4355) // disable 'this' used in base member initializer list
  #pragma warning(disable: 4275) // deriving exported class from non-exported
  #pragma warning(disable: 4251) // using non-exported as public in exported
#endif // _MSC_VER

#ifdef PLAT_WIN32
  #if defined (_LIB) || (FCL_OS_BUILD_LIB) 
    #define FCL_OS_EXPORT
  #else 
    #if defined (_USRDLL) || (FCL_OS_BUILD_DLL)
      #define FCL_OS_EXPORT __declspec(dllexport)
    #else 
      #define FCL_OS_EXPORT __declspec(dllimport)
    #endif // _USRDLL || FCL_OS_BUILD_DLL
  #endif // _LIB || FCL_OS_BUILD_LIB
#else
  #define FCL_OS_EXPORT 
#endif // !PLAT_WIN32

#if defined (PLAT_WIN32)
  #define FCL_OS_SEPARATE '\\'
#elif defined (PLAT_UNIX)
  #define FCL_OS_SEPARATE '/'
#endif

#define FCL_CLOSE_SOCKET(s) { closesocket(s); s = FCL_INVALID_SOCKET; }

#ifdef PLAT_WIN32
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
#endif // PLAT_WIN32

#ifdef PLAT_UNIX
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

#ifdef PLAT_WIN32
#define VT_IOV_MAX 64
#else
// This is defined by XOPEN to be a minimum of 16.  POSIX.1g
// also defines this value.  platform-specific config.h can
// override this if need be.
#if !defined (IOV_MAX)
#define IOV_MAX 16
#endif // !IOV_MAX
#define VT_IOV_MAX IOV_MAX
#endif // PLAT_WIN32

#ifdef PLAT_WIN32
	typedef DWORD FCL_THREAD_ID;
	typedef HANDLE FCL_THREAD_HANDLE;
	typedef HANDLE FCL_SEMAPHORE_T;
	typedef CRITICAL_SECTION FCL_THREAD_MUTEX_T;
#else // !PLAT_WIN32
	typedef pthread_t FCL_THREAD_ID;
	typedef FCL_THREAD_ID FCL_THREAD_HANDLE;
	typedef sem_t FCL_SEMAPHORE_T;
	typedef pthread_mutex_t FCL_THREAD_MUTEX_T;
#endif // PLAT_WIN32


#define FCL_ERROR_MODULE_BASE      10000

#define	FCL_NO_ERROR           (0)
#define	FCL_ERROR_UNKNOWN      (-1)

#define	FCL_ERROR_TIMEOUT      (VT_ERROR_MODULE_BASE+8)  //超时

#ifdef PLAT_WIN32
#else
#define _abs64 llabs 
#endif

#if 1
#define DEFAULT_WRBSERVICE_URL "http://10.30.4.89:7777/ICRC/services/ICRC?wsdl"
#else
#define DEFAULT_WRBSERVICE_URL "http://127.0.0.1:7777/CSHIA/services/CSHIA?wsdl"
#endif

#pragma warning(disable:4996)
#pragma warning(disable:4244)

#endif // !PLATFORM_H

