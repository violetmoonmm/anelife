#ifndef HttpDataSession_h
#define HttpDataSession_h

#include "Platform.h"
#include "CommonDefine.h"
#include "MuteX.h"

class IHttpDataSessionSinker
{
public:
	virtual ~IHttpDataSessionSinker()
	{
	}

	virtual int OnHttpMsgIn(HttpMessage &msg,const char *pContent,int iContentLength) = 0;
	virtual int OnDisconnect(int iReason) = 0;
};

class SendPacket
{
public:
	SendPacket()
	{
		_buf = 0;
		_bufSize = 0;
		_sendIndex = 0;
	}
	SendPacket(char *&buf,int len)
	{
		_buf = buf;
		_bufSize = len;
		_sendIndex = 0;
	}
	~SendPacket()
	{
		if ( _buf )
		{
			delete []_buf;
			_buf = 0;
		}
	}
	char *_buf;
	int _bufSize;
	int _sendIndex;
};

class CHttpDataSession
{
public:
	CHttpDataSession():m_sSock(FCL_INVALID_SOCKET),
								m_emParseStatus(emStageIdle),
								m_iWriteIndex(0),
								m_pContent(NULL),
								m_iContentWriteIndex(0),
								m_pSinker(NULL)
	{
	}
	CHttpDataSession(IHttpDataSessionSinker *pSink):m_sSock(FCL_INVALID_SOCKET),
													m_emParseStatus(emStageIdle),
													m_iWriteIndex(0),
													m_pContent(NULL),
													m_iContentWriteIndex(0),
													m_pSinker(pSink)
	{
	}
	CHttpDataSession(FCL_SOCKET sock):m_sSock(sock),
									m_emParseStatus(emStageIdle),
									m_iWriteIndex(0),
									m_pContent(NULL),
									m_iContentWriteIndex(0),
									m_pSinker(NULL)
	{
	}
	CHttpDataSession(FCL_SOCKET sock,IHttpDataSessionSinker *pSink):m_sSock(sock),
									m_emParseStatus(emStageIdle),
									m_iWriteIndex(0),
									m_pContent(NULL),
									m_iContentWriteIndex(0),
									m_pSinker(pSink)
	{
	}
	~CHttpDataSession()
	{
		ClearSend();
	}

	enum HttpParseStatus
	{
		emStageIdle,
		emStageHeader,
		emStageContent,

	};

	void SetSinker(IHttpDataSessionSinker *pSink)
	{
		m_pSinker = pSink;
	}
	void SetSocket(FCL_SOCKET sock)
	{
		m_sSock = sock;
	}

	bool IsWaitForSend()
	{
		return _lstSend.size() > 0 ? true : false;
	}

	//新数据通知
	int OnDataIn();
	int OnDataOut();

	int SendData(char *pData,int iLen);
	int SendHttpMsg(HttpMessage &msg,const char *pContent,int iContentLength);

	FCL_SOCKET Socket()
	{
		return m_sSock;
	}

	int Process_Data();
	
	int OnHttpMsg(HttpMessage &msg,const char *pContent,int iContentLength);
	int OnDisconnect(int iReason);

	int Release();

private:
	FCL_SOCKET m_sSock;
	IHttpDataSessionSinker *m_pSinker;
public:
	const static  int MAX_BUF_LEN = 1024*64;

private:
	HttpParseStatus m_emParseStatus;
	char m_szRecvBuf[MAX_BUF_LEN];
	int m_iWriteIndex;
	HttpMessage m_curMsg;
	char *m_pContent;
	int m_iContentWriteIndex;

	std::list<SendPacket*> _lstSend;   //发送缓冲
	CMutexThreadRecursive m_senLock;
	void ClearSend();//清空发送缓冲

};

#endif