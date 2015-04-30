
#ifndef MULTICAST_H
#define MULTICAST_H

#include "Trace.h"
#include "Platform.h"
#include "DvrApi.h"

class CMultiCastClient
{
public:
    CMultiCastClient(void);
    ~CMultiCastClient();
    
    int Start(char *szMCastIpAddr, unsigned short usMCastPort,fOnIPSearch pFcb,void *pUser);
    int Stop(void);
    int SendMCast_Msg(char *pData,unsigned int Len,unsigned short usRspCode = 0); //发送命令
    
private:
#ifdef _WIN32
    static unsigned long __stdcall MCastThread(void *pParam);
#else
    static void* MCastThread(void *pParam);
#endif
    int MCastTrans(void);
    
    int OnDataRecv(char szBuf[],int iLen);
    //开启组播
    int StartMCast(void);
    //结束组播
    int StopMCast(void);
    
private:
    FCL_SOCKET m_sock;//接收组播数据
    FCL_SOCKET m_sockSend;//用于数据发送
    
    char m_szMCastIpAddr[32];
    unsigned short m_usMCastPort;
    
    fOnIPSearch m_pIPSearchcb;
    void *m_pIPSearchUser;
    
    bool m_bExitThread;
    
    FCL_THREAD_HANDLE m_hMCastThread;
};
#endif