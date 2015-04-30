
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
    int SendMCast_Msg(char *pData,unsigned int Len,unsigned short usRspCode = 0); //��������
    
private:
#ifdef _WIN32
    static unsigned long __stdcall MCastThread(void *pParam);
#else
    static void* MCastThread(void *pParam);
#endif
    int MCastTrans(void);
    
    int OnDataRecv(char szBuf[],int iLen);
    //�����鲥
    int StartMCast(void);
    //�����鲥
    int StopMCast(void);
    
private:
    FCL_SOCKET m_sock;//�����鲥����
    FCL_SOCKET m_sockSend;//�������ݷ���
    
    char m_szMCastIpAddr[32];
    unsigned short m_usMCastPort;
    
    fOnIPSearch m_pIPSearchcb;
    void *m_pIPSearchUser;
    
    bool m_bExitThread;
    
    FCL_THREAD_HANDLE m_hMCastThread;
};
#endif