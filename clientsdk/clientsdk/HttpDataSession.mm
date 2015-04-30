#include "HttpDataSession.h"
#include "Trace.h"

int CHttpDataSession::OnDataIn()
{
	//接收数据
	int iDataLen;
	iDataLen = recv(m_sSock,&m_szRecvBuf[m_iWriteIndex],MAX_BUF_LEN-m_iWriteIndex,0);
	if ( iDataLen < 0 )
	{
		ERROR_TRACE("recv failed.err="<<WSAGetLastError());
		OnDisconnect(2);
	}
	else if ( 0 == iDataLen ) //disconnect
	{
		OnDisconnect(0);
	}
	else
	{
		m_iWriteIndex += iDataLen;
	}

	return iDataLen;
}

int CHttpDataSession::OnDataOut()
{
	//return -1;
	CMutexGuardT<CMutexThreadRecursive> theLock(m_senLock);
	if ( _lstSend.size() == 0 ) //缓冲区没有数据
	{
		return 0;
	}
	std::list<SendPacket*>::iterator it;
	int iSendedSize;
	SendPacket *pPack/* = *it*/;
	for(it = _lstSend.begin();it!=_lstSend.end();it++)
	{
		/*SendPacket **/pPack = *it;
		//iSendedSize =_socket.Send((&pPack->_buf[pPack->_sendIndex]),pPack->_bufSize-pPack->_sendIndex);
		iSendedSize = send(m_sSock,&pPack->_buf[pPack->_sendIndex],pPack->_bufSize-pPack->_sendIndex,0);
		if ( iSendedSize != pPack->_bufSize-pPack->_sendIndex )
		{
			if ( iSendedSize > 0 )
			{
				pPack->_sendIndex += iSendedSize;
			}
			break;
		}
		else
		{
			pPack->_sendIndex = pPack->_bufSize;
		}

	}
	//if ( (*it)->_sendIndex == (*it)->_bufSize ) //当前包已经发送完成
	if ( pPack->_sendIndex == pPack->_bufSize ) //当前包已经发送完成
	{
		//return 0;
	}
	else //没有发送完成
	{
		if ( it == _lstSend.begin() )
		{
			return 0;
		}
		it--;
	}
	
	for(std::list<SendPacket*>::iterator it2 = _lstSend.begin();it2!=it;it2++)
	{
		/*SendPacket **/pPack = *it2;
		//it2++;
		//_lstSend.erase(pPack/*it2*/);
		delete pPack;
	}
	_lstSend.erase(_lstSend.begin(),it);
	return 0;
}

int CHttpDataSession::Process_Data()
{
	int iDataRecv;

	if ( 0 >= m_iWriteIndex ) //no data
	{
		//ERROR_TRACE("no data to process");
		return 0;
	}

	bool bHasPack = true;
	do
	{
		if ( m_emParseStatus == emStageIdle || m_emParseStatus == emStageHeader ) //http头没有接收完整
		{
			//查找http头结束
			char *pHdrTail = NULL;
			if ( m_iWriteIndex < 4 ) //not enough data to hold http header
			{
				return 0;
			}
			for(int i=0;i<=m_iWriteIndex-4;i++)
			{
				if ( m_szRecvBuf[i] == '\r'
					&& m_szRecvBuf[i+1] == '\n'
					&& m_szRecvBuf[i+2] == '\r'
					&& m_szRecvBuf[i+3] == '\n' )
				{
					pHdrTail = m_szRecvBuf+i;
					break;
				}
			}
			//pHdrTail = strstr(m_szRecvBuf,"\r\n\r\n"));
			if ( NULL == pHdrTail ) //头没有结束
			{
				bHasPack = false;
				return 0;
			}

			int iHdrLen = (int)(pHdrTail-m_szRecvBuf+4);

			if ( !ParseHttpHeader(m_szRecvBuf,iHdrLen+4,m_curMsg) )
			{
				ERROR_TRACE("Parse http header failed");

				//跳过
				if ( m_iWriteIndex > iHdrLen ) //剩余的数据前移
				{
					memmove(m_szRecvBuf,&m_szRecvBuf[iHdrLen],m_iWriteIndex-iHdrLen);
					m_iWriteIndex -= iHdrLen;
				}
				else //已经没有数据可以处理
				{
					bHasPack = false;
					m_iWriteIndex = 0;
				}
				m_emParseStatus = emStageIdle;
				continue;
			}

			int iContentLength = m_curMsg.iContentLength;
			if ( m_curMsg.bIsChunkMode ) //chuncked mode 
			{
				ERROR_TRACE("not support current");
				return -1;
			}
			if ( iContentLength == 0 ) //没有消息体
			{
				//回调上层
				OnHttpMsg(m_curMsg,NULL,0);

				m_curMsg.Clear();

				//清空http
				if ( m_iWriteIndex > iHdrLen+iContentLength ) //剩余的数据前移
				{
					memmove(m_szRecvBuf,&m_szRecvBuf[iHdrLen+iContentLength],m_iWriteIndex-iHdrLen-iContentLength);
					m_iWriteIndex -= (iHdrLen+iContentLength);
				}
				else
				{
					bHasPack = false;
					m_iWriteIndex = 0;
				}
				m_emParseStatus = emStageIdle;


				//continue;
			}
			else
			{
				if ( m_iWriteIndex >= iHdrLen+iContentLength ) //已经完成
				{
					//回调上层
					OnHttpMsg(m_curMsg,&m_szRecvBuf[iHdrLen],iContentLength);

					m_curMsg.Clear();

					if ( m_iWriteIndex > iHdrLen+iContentLength ) //仍然有剩余数据
					{
						ERROR_TRACE("Still left some data not handled");
						memmove(m_szRecvBuf,&m_szRecvBuf[iHdrLen+iContentLength],m_iWriteIndex-iHdrLen-iContentLength);
						m_iWriteIndex -= (iHdrLen+iContentLength);
						m_emParseStatus = emStageIdle;
						//continue;
					}
					else //已经没有可以处理的数据
					{
						m_iWriteIndex = 0;
						m_emParseStatus = emStageIdle;
						bHasPack = false;
					}

				}
				else //内容没有接收完成
				{
					m_iContentWriteIndex = 0;
					m_pContent = new char[iContentLength];
					if ( !m_pContent )
					{
						ERROR_TRACE("out of memory");
						return -2;
					}
					m_iContentWriteIndex = m_iWriteIndex-iHdrLen;
					m_iWriteIndex = 0;
					memcpy(m_pContent,&m_szRecvBuf[iHdrLen],m_iContentWriteIndex);
					m_emParseStatus = emStageContent;

					//m_pContent = NULL;
					bHasPack = false;
					//return 0;
				}

			}
		}
		else if ( m_emParseStatus == emStageContent ) //http头部已经完成,等待内容接收完成
		{
			if ( m_curMsg.iContentLength > m_iContentWriteIndex+m_iWriteIndex ) //仍然没有完成content接收
			{
				memcpy(m_pContent+m_iContentWriteIndex,m_szRecvBuf,m_iWriteIndex);
				m_iContentWriteIndex += m_iWriteIndex;
				m_iWriteIndex = 0;
				bHasPack = false;
				//return 0;
			}
			else
			{
				memcpy(m_pContent+m_iContentWriteIndex,m_szRecvBuf,m_curMsg.iContentLength-m_iContentWriteIndex);

				//回调上层
				OnHttpMsg(m_curMsg,m_pContent,m_curMsg.iContentLength);

				//重置状态
				m_emParseStatus = emStageIdle;
				if ( m_curMsg.iContentLength == m_iContentWriteIndex+m_iWriteIndex )
				{
					m_iWriteIndex = 0;
					bHasPack = false;
				}
				else
				{
					memmove(m_szRecvBuf,&m_szRecvBuf[m_curMsg.iContentLength-m_iContentWriteIndex],m_iWriteIndex-(m_curMsg.iContentLength-m_iContentWriteIndex));
					m_iWriteIndex = m_curMsg.iContentLength-m_iContentWriteIndex;
				}
				//m_iWriteIndex = 0;
				m_iContentWriteIndex = 0;
				m_pContent = NULL;
				m_curMsg.Clear();

				//return 1;
			}
		}
	}
	while( bHasPack );

	return 0;
}

int CHttpDataSession::OnHttpMsg(HttpMessage &msg,const char *pContent,int iContentLength)
{
	if ( m_pSinker )
	{
		return m_pSinker->OnHttpMsgIn(msg,pContent,iContentLength);
	}
	else
	{
		ERROR_TRACE("no handler");
		return -1;
	}
}
int CHttpDataSession::OnDisconnect(int iReason)
{
	if ( m_pSinker )
	{
		return m_pSinker->OnDisconnect(iReason);
	}
	else
	{
		ERROR_TRACE("no handler");
		return -1;
	}
}

int CHttpDataSession::Release()
{
	return -1;
}

int CHttpDataSession::SendData(char *pData,int iLen)
{
#if 0
	int iDataLen;
	iDataLen = send(m_sSock,pData,iLen,0);
	if ( iDataLen == iLen ) //全部发送完成
	{
		return iDataLen;
	}
	else if ( iDataLen == FCL_SOCKET_ERROR ) //发送失败
	{
		ERROR_TRACE("send failed.err="<<WSAGetLastError()<<" send len="<<iLen);
		return iDataLen;
	}
	else //部分发送完成,剩余未发送部分处理:暂时没有处理
	{
		WARN_TRACE("send partly data.total="<<iLen<<" send="<<iDataLen);
		return iDataLen;
	}
#endif
	CMutexGuardT<CMutexThreadRecursive> theLock(m_senLock);
	if ( _lstSend.size() != 0 ) //发送缓冲中已经有数据,直接填入发送缓冲
	{
		SendPacket *pPack = new SendPacket();
		if ( !pPack )
		{
			return 0;
		}
		pPack->_buf = new char[iLen];
		if ( !pPack->_buf )
		{
			return 0;
		}
		pPack->_bufSize = iLen;
		memcpy(pPack->_buf,pData,iLen);
		_lstSend.push_back(pPack);
		return 0;
	}
	
	int iSendedSize;
	iSendedSize = send(m_sSock,pData,iLen,0);
	if ( iSendedSize != iLen )
	{
		if ( iSendedSize <= 0 )
		{
			bool bIsBlocked = false;
			DWORD dwErr;

#ifdef PLAT_WIN32
			dwErr = WSAGetLastError();
			if ( SOCKET_ERROR == iSendedSize && dwErr == WSAEWOULDBLOCK )
			{
				bIsBlocked = true;
			}
#else
			dwErr = errno;
			if ( -1 == iSendedSize && EINPROGRESS == dwErr )
			{
				//errno = EWOULDBLOCK;
				bIsBlocked = true;
			}
#endif

			if ( !bIsBlocked )
			{
				ERROR_TRACE("send failed.err="<<dwErr);
				return -1;
			}
			SendPacket *pPack = new SendPacket();
			if ( !pPack )
			{
				return 0;
			}
			pPack->_buf = new char[iLen];
			if ( !pPack->_buf )
			{
				return 0;
			}
			pPack->_bufSize = iLen;
			memcpy(pPack->_buf,pData,iLen);
			_lstSend.push_back(pPack);
			return 0;
		}
		else //没有发送完全
		{
			SendPacket *pPack = new SendPacket();
			if ( !pPack )
			{
				return 0;
			}
			pPack->_buf = new char[iLen-iSendedSize];
			if ( !pPack->_buf )
			{
				return 0;
			}
			pPack->_bufSize = iLen-iSendedSize;
			memcpy(pPack->_buf,pData+iSendedSize,iLen-iSendedSize);
			_lstSend.push_back(pPack);
			return 0;

		}
	}
	else
	{
		//_lastActionTime = time(NULL); //上次活跃时间
	}
	return 0;
}
int CHttpDataSession::SendHttpMsg(HttpMessage &msg,const char *pContent,int iContentLength)
{
	return -1;
}
void CHttpDataSession::ClearSend()//清空发送缓冲
{
	CMutexGuardT<CMutexThreadRecursive> theLock(m_senLock);
	std::list<SendPacket*>::iterator it;
	SendPacket *pTemp;
	for(it=_lstSend.begin();it!=_lstSend.end();it++)
	{
		pTemp = *it;
		if ( pTemp )
		{
			delete pTemp;
			pTemp = NULL;
		}
	}
	_lstSend.clear();
}