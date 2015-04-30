#ifndef MQINSTANCE_H

#define MQINSTANCE_H



#if defined(_MSC_VER) && (_MSC_VER >= 1200)
# pragma once
#endif

#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <memory>
#include <list>




#include <map>

#include "MQStackDef.h"

#include "VTUtilDefine.h"

#include "VTMutex.h"



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



class CMQInstance
{
public:
	CMQInstance(void);
	CMQInstance(char *pszURI);
	CMQInstance(char *pszURI,char *pszUsername,char *pszPassword,char *pszClientID);
	~CMQInstance(void);
    
public:
	void BrokerUri(std::string strUri);
	std::string BrokerUri(void);
	void InstHandle(MQ_HANDLE hInst);
    
public:
	//设置当前终端参数
    
	int SetEndpoint(MQ_ENDPOINT &stEpInfo);
    
	
    
	int SetTopic(char **pTopic,int iTopicCount);
    
    
    
	int SetExtraInfo(MQ_EXRAINFO &stExtInfo);
    
    
    
	//启动
    
	int Start(void);
	//停止
	int Stop(void);
    
	//发送设备状态变化通知消息
    
	int DeviceStateNotify(MQ_DEVICE_STATE stDevState,int iDeliveryMode );
    
	//发送报警通知消息
    
	int AlarmNotify(MQ_ALARM_INFO stAlarmInfo,int iDeliveryMode);
    
	//发送设备删除消息
    
	int DeviceDelNotify(MQ_DEVICE_DELETE stDeviceDel,int iDeliveryMode );
    
	//发送设备添加消息
    
	int DeviceAddNotify(MQ_DEVICE_ADD stDeviceAdd,int iDeliveryMode );
    
	//发送设备更新消息
    
	int DeviceUpdateNotify(MQ_DEVICE_UPDATE stDeviceUpdate,int iDeliveryMode );
    
	//发送车辆出入消息
    
	int VehiclePassInfoNotify(LPMQ_VEHICLE_PASS_INFO pstVehPassInfo,int iDeliveryMode);
    
	//发送出入口管理设备消息通知信息
    
	int EecNoticeInfoNotify(LPMQ_EEC_NOTICE_INFO pstEecNoticeInfo,int iDeliveryMode);
    
	
    
	//发送短信发送反馈消息
    
	int SPAlarmSmsReplyInfoNotify(LPMQ_ALARM_SMS_REPLY_INFO pstSpAlarmSmsReplyNoticeInfo,int iDeliveryMode);
    
    
	//发送开锁图片消息
    
	int VTHProxy_UnlockPic(LPMQ_VTHPROXY_UNLOCK_PIC_INFO pstPicInfo,int iDeliveryMode);
	//发送呼叫转移消息
    
	int VTHProxy_CallRedirect(LPMQ_VTHPROXY_CALL_REDIRECT_INFO pstCrInfo,int iDeliveryMode);
    
	//发送开锁消息
    
	int VTHProxy_Unlock(LPMQ_VTHPROXY_UNLOCK_REQ_INFO pstUnlockReq,int iDeliveryMode);
	//发送呼叫转移结果反馈消息
    
	int VTHProxy_CallRedirectResult(LPMQ_VTHPROXY_CALL_REDIRECT_RESULT_INFO pstCrResult,int iDeliveryMode);
    
    
    
	/////////////////////ACMS平台消息////////////////////////////////
    
	//发送ACMS平台报警通知消息
    
	int ACMS_AlarmNotify(LPMQ_ACMS_ALARM_NOTIFY_INFO pstAlarmInfo,int iDeliveryMode);
    
	/////////////////////ACMS平台消息////////////////////////////////
    
    
    
	//发送消息
    
    int SendMessage(char *pszDest,char *pMsg,int iLen,int iDeliveryMode);
    
	//发送消息 扩展
    
	int SendMessageEx(char *pszTopic,char *pCmsType,char *pMsg,int iLen,int iDeliveryMode);
    
    
public:
    
private:
	//清除连接和资源
	int Cleanup(void);
	//根据终端类型
	int CreateConsumeTopic(void);
    
	//void ProcessMessageText(const cms::Message* message);
    
private:
	//默认主题列表
	static const std::string DEVICE_STATE_CHANE;           //设备状态变化主题
	static const std::string DEVICE_ALARM;                 //设备报警主题
	static const std::string DEVICE_ALARM_VTMC_TOPIC;      //设备报警主题 VTMC
	static const std::string DEVICE_ALARM_VTMC;            //设备报警主题 VTMC
	static const std::string DEVICE_ALARM_DSMC;            //设备报警主题 DSMC
	static const std::string DEVICE_ALARM_ACMC;            //设备报警主题 ACMC
	static const std::string DEVICE_ALARM_UCMC;            //设备报警主题 UCMC
	static const std::string DEVICE_ALARM_ICMC;            //设备报警主题 ICMC
	static const std::string DATABASE_CHANGE;              //设备变化主题
	static const std::string DATABASE_DEVICE_DELETE;       //设备删除
	static const std::string DATABASE_DEVICE_CHANGE;       //设备变化
	static const std::string VEHICLE_PASS_INFO;            //车辆通过通知
	static const std::string EEC_NOTICE_INFO;              //车辆出入口管理设备消息通知
	
	static const std::string DEVICE_ALARM_SMS_TOPIC_SP;    //报警平台主题
	static const std::string DEVICE_ALARM_SMS_SP;          //报警短信平台消息通知
	
	static const std::string VTMC_JMS_FILTER;              //VTMC端过滤器
    
	static const std::string VTHPROXY_TOPIC_SUB;           //VTH代理订阅主题
	static const std::string VTHPROXY_TOPIC_PUB;           //VTH代理发布主题
    
	static const std::string CALLGROUP_TOPIC_PUB;          //呼叫分组发布主题
    
    
	static const std::string ACMS_ALARM_TOPIC_PUB;          //ACMS平台报警发布主题
    
    
#ifdef CONSUME_TOPIC_AUTO_TEST
	static const std::string ACTIVE_MQ_TEST_TOPIC;          //ActiveMQ测试订阅状态主题
    
#endif
    
	bool m_bUseTopic;
    bool m_bClientAck;
    std::string m_strBrokerURI; //中间件服务器信息
    std::string m_strDestURI;   //主题
	
	std::string m_strIp;       //中间件服务器IP地址
	unsigned short m_usPort;   //中间件服务器端口
    
	std::map<int,std::string> m_lstConsumer; //订阅主题列表
	std::map<int,std::string> m_lstProducer; //发布主题列表
    
	MQ_HANDLE m_hInstId;            //实例句柄
	int m_iDeviceType;              //终端类型
	fcbStack m_fcbStack;            //回调
	void *m_pUser;                  //用户自定义数据
    std::string m_strUsername;      //用户名
    std::string m_strPassword;      //密码
    std::string m_strClientId;      //客户端ID
    
	enum EmEndpointStatus
	{
		emIdle       = 0,  //初始状态
		emConnecting = 1,  //连接中
		emLogining   = 2,  //登陆中
		emStarted    = 16, //运行状态
		emLogouting  = 32  //登出中
	};
	int m_iStatus;                  //当前客户端状态
    
	fcbStackEx m_fcbStackEx;            //回调
	void *m_pUserEx;                    //用户自定义数据
	bool m_bIsCompatibleOld;
    
	std::list<SendPacket*> _lstSend;   //发送缓冲
    
	CVTMutexThreadRecursive m_senLock;
    
    
#ifdef VT_WIN32
    
	static unsigned long __stdcall NetTransThread(void *pParam);
    
#else
    
	static void* NetTransThread(void *pParam);
    
#endif
    
	int NetTransTcp();
    
    
	bool m_bExitNetThr; //线程退出标识
    
	VT_THREAD_ID m_dwNetThreadID;
    
	VT_THREAD_HANDLE m_hNetThread;
    
    
	VT_SOCKET m_sock;   //连接套接字
    
	unsigned int m_uiFailTime;
    
	bool CreateProcThread();
	int Connect();
	int Connect_Sync(); //同步连接
	int RecvData(char szBuf[],int iBufLen,int iTimeout);
    
    
	void OnDisConnect(int iReason); //断线通知
    
	int SendData(char buf[],int iLen); //发送数据如果数据不能一次发送，而存入发送缓冲
    
	int OnSendData(); //被reactor调用,发送缓冲区中的数据
    
	void ClearSend();//清空发送缓冲
    
	int ShuntdwonNornal(); //正常结束同代理端的连续
    
	int EncodeWaveFormatInfo(char buf[],int &iLen); //打包WAVEFORMAT_INFO信令
	
	int EncodeConnectionInfo(char buf[],int &iLen); //打包CONNECTION_INFO信令
    
	int EncodeSessionInfo(char buf[],int &iLen); //打包SESSION_INFO信令
    
	int EncodeConsumerInfo(char buf[],int &iLen); //打包CONSUMER_INFO信令
    
	int EncodeProducerInfo(char buf[],int &iLen); //打包PRODUCER_INFO信令
    
	int DecodeResponse(char buf[],int iLen,unsigned int &uiCommandId); //解析Response命令
    
	int EncodeMapMsg(char buf[],int &iLen,char msg[],int msgLen,char topic[],char cmsType[]); //打包ACTIVEMQ_MAP_MESSAGE信令
    
	int EncodeTextMsg(char buf[],int &iLen,char msg[],int msgLen,char topic[],char cmsType[]); //打包ACTIVEMQ_TEXT_MESSAGE信令
    
	int DecodeDispatchtMsg(char buf[],int &iLen); //解包MESSAGE_DISPATCH信令
    
	int EncodeMsgAck(char buf[],int iLen,std::string &producerId,std::string &consumerId,std::string topic,unsigned long long ProducerSequenceId,unsigned long long BrokerSequenceId); //打包MESSAGE_ACK命令
    
	int EncoderRemovalInfo(char buf[],int &iLen,int type); //打包REMOVE_INFO信令 type 1 PRODUCER_ID 2 CONSUMER_ID 3 SESSION_ID 4 CONNECTION_ID
    
	int	EncoderShuntdownInfo(char buf[],int &iLen); //打包SHUTDOWN_INFO信令
    
	unsigned int m_uiCommandId;
	std::string m_strConnectionId; //连接ID
	static unsigned int s_uiSequence;
    
	std::string ToString(int value);
};



#endif
