#ifndef SDKCOMMONDEFINE_H
#define SDKCOMMONDEFINE_H


#if (defined(WIN32) || defined(WIN64))
#define CALL_METHOD  __stdcall
#else
#define CALL_METHOD
#endif

///////////////////���Ͷ���////////////////////////
#define Int16 short
#define UInt16 unsigned short

#define Int32 int
#define UInt32 unsigned int

#define Int64 long long
#define UInt64 unsigned long long

#ifdef __cplusplus
extern "C" {
#endif

///////////////��Ϣ����(������Ӧ)///////////////
#define HTTP_TYPE_REQUEST        1        //����
#define HTTP_TYPE_RESPONSE       2        //��Ӧ

///////////////��������///////////////
#define	HTTP_METHOD_GET					 1      // http GET
#define	HTTP_METHOD_POST				 2      // http POST
#define	HTTP_METHOD_EX_NOTIFY			 3		 // ��չ NOTIFY   �¼�֪ͨ
#define	HTTP_METHOD_EX_NOTIFYSTAR		 4      // ��չ NOTIFY * SSDP
#define	HTTP_METHOD_EX_MSEARCH			 5      // ��չ M-SEARCH * SSDP
#define	HTTP_METHOD_EX_SUBSCRIBLE		 6      // ��չ SUBSCRIBLE
#define	HTTP_METHOD_EX_UNSUBSCRIBLE		 7      // ��չ UNSUBSCRIBLE
#define	HTTP_METHOD_EX_REGISTER			 8      // ��չ REGISTER
#define	HTTP_METHOD_EX_SEARCH			 9      // ��չ SEARCH

///////////////HTTP��չͷ��///////////////
#define HEADER_NAME_FROM      "From"
#define HEADER_NAME_TO        "To"
#define HEADER_NAME_TAGS      "Tags"
#define HEADER_NAME_ACTION    "ACT"//"NTS"
#define HEADER_NAME_UPNP_AUTHENTICATE    "Upnp-Authenticate"//"Upnp-Authenticate"
#define HEADER_NAME_UPNP_AUTHORIZATION   "Upnp-Authorization"//"Upnp-Authenticate"
#define HEADER_NAME_VERIFY_CODE			 "VerifyCode"//"VerifyCode"

///////////////��չ��������///////////////
#define ACTION_REGISTER_REQ				"register"				//ע������
#define ACTION_REGISTER_RSP				"registerResponse"		//ע���Ӧ
#define ACTION_KEEPALIVE_REQ			"keepalive"				//��������
#define ACTION_KEEPALIVE_RSP			"keepaliveResponse"		//�����Ӧ
#define ACTION_UNREGISTER_REQ			"unregister"			//ע������
#define ACTION_UNREGISTER_RSP			"unregisterResponse"	//ע����Ӧ
#define ACTION_SEARCH_REQ				"search"				//���������б�����
#define ACTION_SEARCH_RSP				"searchResponse"		//���������б��Ӧ
#define ACTION_GETDEVLIST_REQ			"getDeviceList"			//��ȡ�豸�б�����
#define ACTION_GETDEVLIST_RSP			"getDeviceListResponse"	//��ȡ�豸�б��Ӧ
#define ACTION_ACTION_REQ				"action"				//��������
#define ACTION_ACTION_RSP				"actionResponse"		//���ƻ�Ӧ
#define ACTION_QUERY_REQ				"query"					//��ѯ�汾��Ϣ����
#define ACTION_QUERY_RSP				"queryResponse"			//��ѯ�汾��Ϣ��Ӧ
#define ACTION_DOWNLOADFILE_REQ			"downloadFile"			//�����ļ�����
#define ACTION_DOWNLOADFILE_RSP			"downloadFileResponse"	//�����ļ���Ӧ
#define ACTION_GATEWAYAUTH_REQ			"gatewayAuth"			//������֤����
#define ACTION_GATEWAYAUTH_RSP			"gatewayAuthResponse"	//������֤��Ӧ
#define ACTION_SHBG_NOTIFY_REQ			"shbgNotify"			//���ܼҾӴ�����֪ͨ��Ϣ����
#define ACTION_SHBG_NOTIFY_RSP			"shbgNotifyResponse"	//���ܼҾӴ�����֪ͨ��Ϣ��Ӧ
#define ACTION_ALARM_NOTIFY_REQ			"alarmNotify"			//����֪ͨ��Ϣ����
#define ACTION_ALARM_NOTIFY_RSP			"alarmNotifyResponse"	//����֪ͨ��Ϣ��Ӧ

#define ACTION_SUBSCRIBLE_REQ			"subscrible"			//��������
#define ACTION_SUBSCRIBLE_RSP			"subscribleResponse"	//���Ļ�Ӧ
#define ACTION_RENEW_REQ				"renew"					//��������
#define ACTION_RENEW_RSP				"renewResponse"			//������Ӧ
#define ACTION_UNSUBSCRIBLE_REQ			"unsubscrible"			//ȡ����������
#define ACTION_UNSUBSCRIBLE_RSP			"unsubscribleResponse"	//ȡ�����Ļ�Ӧ
#define ACTION_NOTIFY_REQ				"notify"				//�¼�֪ͨ����
#define ACTION_NOTIFY_RSP				"notifyResponse"		//�¼�֪ͨ��Ӧ


#define UPNP_STATUS_CODE_REFUSED			801		//����ܾ�
#define UPNP_STATUS_CODE_NOT_FOUND			802		//�Ҳ����Զ�
#define UPNP_STATUS_CODE_OFFINE				803		//�Զ˲�����
#define UPNP_STATUS_CODE_BUSY				804		//æ
#define UPNP_STATUS_CODE_BAD_REQUEST		805		//������Ч
#define UPNP_STATUS_CODE_AUTH_FAILED		806		//��֤ʧ��
#define UPNP_STATUS_CODE_NEED_AUTH			808		//��Ҫ��֤
#define UPNP_STATUS_CODE_HAVE_REGISTERED	809		//�Ѿ���¼
#define UPNP_STATUS_CODE_PASSWORD_INVALID	810		//�������
#define UPNP_STATUS_CODE_NOT_REACH			812		//�Զ˲��ɴ�


///�ն�����
#define ENDPOINT_TYPE_UC			1		//uc
#define ENDPOINT_TYPE_DEVICE		2		//�豸
#define ENDPOINT_TYPE_PROXY			3		//����
#define ENDPOINT_TYPE_FDMS			4		//fdms �豸���������
#define ENDPOINT_TYPE_SHBG			5		//shbg ��ͥ������

#define HTTP_HEADER_NAME_LEN    64      //httpͷ��������󳤶�
#define HTTP_HEADER_VALUE_LEN   256     //httpͷ��������󳤶�
#define HTTP_URI_PATH_LEN       256     //http uri·����󳤶�
#define USER_VIRT_CODE_LEN      32     //�û�(�豸)�����󳤶�
#define HTTP_TAGS_LEN           128    //tags(������)��󳤶�

//����-ֵ��
typedef struct
{
	char szName[HTTP_HEADER_NAME_LEN];
	char szValue[HTTP_HEADER_VALUE_LEN];
}NAME_VALUE,*LPNAME_VALUE;

// HTTPͷ
typedef struct
{
	int iType;                      //����  1 ���� 2 ��Ӧ
	int iProtocolVer;               //httpЭ��汾 1 1.0 2 1.1 ��ǰֻ֧��1.1�汾
	int iMethod;                    //���� ֻ��������������
	char szPath[HTTP_URI_PATH_LEN]; //·�� ֻ��������������
	int iStatusCode;                //״̬�� ֻ�л�Ӧ��������
	int iContentLength;             //��Ϣ���ݳ���
	char szFrom[USER_VIRT_CODE_LEN];
	char szTo[USER_VIRT_CODE_LEN];
	char szTags[HTTP_TAGS_LEN];
	char szAction[HTTP_TAGS_LEN];
	int iCount;                     //����ͷ����Ŀ
	NAME_VALUE hdrs[1];             //����ͷ��
}HTTP_HEADER, *LPHTTP_HEADER;

typedef struct
{
	int iUserType;			//�ն�����(���ն����Ͷ���)
	char szUser[64];		//�û�(���)
	char szPassword[64];	//����
	int iResult;			//��� 0 ���� -1 �û�������
}REGISTER_VERIFY_INFO,*LPREGISTER_VERIFY_INFO;

/************************************************************************
 ** �ص���������
 ***********************************************************************/

// ��¼�ɹ���Ͽ��ص�����ԭ��
//iStatus 0 �Ͽ� 1 ��¼�ɹ� 2 ��¼ʧ��
typedef void (CALL_METHOD *fDisConnect)(UInt32 lLoginID,int iStatus,int iReason,void *pUser);

// ��Ϣ�ص�����ԭ��
typedef void (CALL_METHOD *fMessCallBack)(UInt32 lLoginID,LPHTTP_HEADER pHdr,void * pContent,int iContentLength,void *pUser);

// ��¼�û���֤�ص�����ԭ�� ֻ�д�����Ҫ���������ն�ע��ʱ�õ�
typedef void (CALL_METHOD *fOnLogin)(UInt32 lLoginID,LPREGISTER_VERIFY_INFO pInfo,void *pUser);

#ifdef __cplusplus
}
#endif

#endif