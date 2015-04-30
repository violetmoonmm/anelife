#include "HttpDataSession.h"
#include "Trace.h"

int CHttpDataSession::OnDataIn()
{
	//��������
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
	if ( _lstSend.size() == 0 ) //������û������
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
	//if ( (*it)->_sendIndex == (*it)->_bufSize ) //��ǰ���Ѿ��������
	if ( pPack->_sendIndex == pPack->_bufSize ) //��ǰ���Ѿ��������
	{
		//return 0;
	}
	else //û�з������
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
		if ( m_emParseStatus == emStageIdle || m_emParseStatus == emStageHeader ) //httpͷû�н�������
		{
			//����httpͷ����
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
			if ( NULL == pHdrTail ) //ͷû�н���
			{
				bHasPack = false;
				return 0;
			}

			int iHdrLen = (int)(pHdrTail-m_szRecvBuf+4);

			if ( !ParseHttpHeader(m_szRecvBuf,iHdrLen+4,m_curMsg) )
			{
				ERROR_TRACE("Parse http header failed");

				//����
				if ( m_iWriteIndex > iHdrLen ) //ʣ�������ǰ��
				{
					memmove(m_szRecvBuf,&m_szRecvBuf[iHdrLen],m_iWriteIndex-iHdrLen);
					m_iWriteIndex -= iHdrLen;
				}
				else //�Ѿ�û�����ݿ��Դ���
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
			if ( iContentLength == 0 ) //û����Ϣ��
			{
				//�ص��ϲ�
				OnHttpMsg(m_curMsg,NULL,0);

				m_curMsg.Clear();

				//���http
				if ( m_iWriteIndex > iHdrLen+iContentLength ) //ʣ�������ǰ��
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
				if ( m_iWriteIndex >= iHdrLen+iContentLength ) //�Ѿ����
				{
					//�ص��ϲ�
					OnHttpMsg(m_curMsg,&m_szRecvBuf[iHdrLen],iContentLength);

					m_curMsg.Clear();

					if ( m_iWriteIndex > iHdrLen+iContentLength ) //��Ȼ��ʣ������
					{
						ERROR_TRACE("Still left some data not handled");
						memmove(m_szRecvBuf,&m_szRecvBuf[iHdrLen+iContentLength],m_iWriteIndex-iHdrLen-iContentLength);
						m_iWriteIndex -= (iHdrLen+iContentLength);
						m_emParseStatus = emStageIdle;
						//continue;
					}
					else //�Ѿ�û�п��Դ��������
					{
						m_iWriteIndex = 0;
						m_emParseStatus = emStageIdle;
						bHasPack = false;
					}

				}
				else //����û�н������
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
		else if ( m_emParseStatus == emStageContent ) //httpͷ���Ѿ����,�ȴ����ݽ������
		{
			if ( m_curMsg.iContentLength > m_iContentWriteIndex+m_iWriteIndex ) //��Ȼû�����content����
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

				//�ص��ϲ�
				OnHttpMsg(m_curMsg,m_pContent,m_curMsg.iContentLength);

				//����״̬
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
	if ( iDataLen == iLen ) //ȫ���������
	{
		return iDataLen;
	}
	else if ( iDataLen == FCL_SOCKET_ERROR ) //����ʧ��
	{
		ERROR_TRACE("send failed.err="<<WSAGetLastError()<<" send len="<<iLen);
		return iDataLen;
	}
	else //���ַ������,ʣ��δ���Ͳ��ִ���:��ʱû�д���
	{
		WARN_TRACE("send partly data.total="<<iLen<<" send="<<iDataLen);
		return iDataLen;
	}
#endif
	CMutexGuardT<CMutexThreadRecursive> theLock(m_senLock);
	if ( _lstSend.size() != 0 ) //���ͻ������Ѿ�������,ֱ�����뷢�ͻ���
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
		else //û�з�����ȫ
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
		//_lastActionTime = time(NULL); //�ϴλ�Ծʱ��
	}
	return 0;
}
int CHttpDataSession::SendHttpMsg(HttpMessage &msg,const char *pContent,int iContentLength)
{
	return -1;
}
void CHttpDataSession::ClearSend()//��շ��ͻ���
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