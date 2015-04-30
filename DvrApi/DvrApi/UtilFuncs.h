#ifndef UtilFuncs_h
#define UtilFuncs_h

#include "Platform.h"

void FclSleep(int iMillSec);
long long GetCurrentTimeMs();
int SetBlockMode(FCL_SOCKET sock,bool bIsNoBlock); //设置套接字阻塞模式
int SetTcpKeepalive(FCL_SOCKET sock); //设置TCP保活

#ifdef PLAT_WIN32
#else
unsigned int WSAGetLastError();
#endif

#ifndef PLAT_WIN32
unsigned int GetTickCount();
#endif //PLAT_WIN32

int DHTimr2Utc(const char *szDHTime);

#endif