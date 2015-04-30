
#include "VTMutex.h"
//#include "VTDebug.h"

//////////////////////////////////////////////////////////////////////
// class CVTMutexThreadBase
//////////////////////////////////////////////////////////////////////

CVTMutexThreadBase::CVTMutexThreadBase()
{
}

CVTMutexThreadBase::~CVTMutexThreadBase()
{
#ifdef VT_WIN32
	::DeleteCriticalSection(&m_Lock);
#else
	int nRet = ::pthread_mutex_destroy(&m_Lock);
	if (nRet != 0)
	{
		//VT_ERROR_TRACE("CVTMutexThreadBase::~CVTMutexThreadBase, pthread_mutex_destroy() failed! err=" << nRet);
	}
#endif // VT_WIN32
}

int CVTMutexThreadBase::Lock()
{
#ifdef VT_WIN32
	::EnterCriticalSection(&m_Lock);
	return 0;
#else
	int nRet = ::pthread_mutex_lock(&m_Lock);
	if (nRet == 0)
		return 0;
	else
	{
		//VT_ERROR_TRACE("CVTMutexThreadBase::Lock, pthread_mutex_lock() failed! err=" << nRet);
		return -1;
	}
#endif // VT_WIN32
}

int CVTMutexThreadBase::UnLock()
{
#ifdef VT_WIN32
	::LeaveCriticalSection(&m_Lock);
	return 0;
#else
	int nRet = ::pthread_mutex_unlock(&m_Lock);
	if (nRet == 0)
		return 0;
	else
	{
		//VT_ERROR_TRACE("CVTMutexThreadBase::UnLock, pthread_mutex_unlock() failed! err=" << nRet);
		return -1;
	}
#endif // VT_WIN32
}

int CVTMutexThreadBase::TryLock()
{
#ifdef VT_WIN32
	BOOL bRet = ::TryEnterCriticalSection(&m_Lock);
	return bRet ? 0 : -1;
#else
	int nRet = ::pthread_mutex_trylock(&m_Lock);
	return (nRet == 0) ? 0 : -1;
#endif // VT_WIN32
}


//////////////////////////////////////////////////////////////////////
// class CVTMutexThreadRecursive
//////////////////////////////////////////////////////////////////////

CVTMutexThreadRecursive::CVTMutexThreadRecursive()
{
#ifdef VT_WIN32
	::InitializeCriticalSection(&m_Lock);
#else
	pthread_mutexattr_t mutexattr;
    ::pthread_mutexattr_init(&mutexattr);
    ::pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_NORMAL);

    int nRet = ::pthread_mutex_init(&m_Lock, &mutexattr);
    ::pthread_mutexattr_destroy(&mutexattr);
	if (nRet != 0)
	{
		//VT_ERROR_TRACE("CVTMutexThreadRecursive::CVTMutexThreadRecursive, pthread_mutex_init() failed! err=" << nRet);
	}
#endif // VT_WIN32
}

CVTMutexThreadRecursive::~CVTMutexThreadRecursive()
{
}


//////////////////////////////////////////////////////////////////////
// class CVTMutexThreadRecursive
//////////////////////////////////////////////////////////////////////

CVTMutexThread::CVTMutexThread()
{
#ifdef VT_WIN32
	::InitializeCriticalSection(&m_Lock);
#else
	pthread_mutexattr_t mutexattr;
    ::pthread_mutexattr_init(&mutexattr);
#ifdef ANDROID //android平台没有PTHREAD_MUTEX_FAST_NP宏
	::pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_NORMAL);
#else
    ::pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_FAST_NP);
#endif
    int nRet = ::pthread_mutex_init(&m_Lock, &mutexattr);
    ::pthread_mutexattr_destroy(&mutexattr);
	if (nRet != 0)
	{
		//VT_ERROR_TRACE("CVTMutexThread::CVTMutexThread, pthread_mutex_init() failed! err=" << nRet);
	}
#endif // VT_WIN32
}

CVTMutexThread::~CVTMutexThread()
{
}