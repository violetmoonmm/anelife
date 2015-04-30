
#include "MuteX.h"
#include "Trace.h"
#include "CommonDefine.h"

//////////////////////////////////////////////////////////////////////
// class CMutexThreadBase
//////////////////////////////////////////////////////////////////////

CMutexThreadBase::CMutexThreadBase()
{
}

CMutexThreadBase::~CMutexThreadBase()
{
#ifdef PLAT_WIN32
	::DeleteCriticalSection(&m_Lock);
#else
	int nRet = ::pthread_mutex_destroy(&m_Lock);
	if (nRet != 0)
	{
		ERROR_TRACE("pthread_mutex_destroy() failed! err=" << nRet);
	}
#endif // PLAT_WIN32
}

int CMutexThreadBase::Lock()
{
#ifdef PLAT_WIN32
	::EnterCriticalSection(&m_Lock);
	return 0;
#else
	int nRet = ::pthread_mutex_lock(&m_Lock);
	if ( nRet == 0 )
	{
		return 0;
	}
	else
	{
		ERROR_TRACE("pthread_mutex_lock() failed! err=" << nRet);
		return -1;
	}
#endif // PLAT_WIN32
}

int CMutexThreadBase::UnLock()
{
#ifdef PLAT_WIN32
	::LeaveCriticalSection(&m_Lock);
	return 0;
#else
	int nRet = ::pthread_mutex_unlock(&m_Lock);
	if ( nRet == 0 )
	{
		return 0;
	}
	else
	{
		ERROR_TRACE("pthread_mutex_unlock() failed! err=" << nRet);
		return -1;
	}
#endif // PLAT_WIN32
}

int CMutexThreadBase::TryLock()
{
#ifdef PLAT_WIN32
	BOOL bRet = ::TryEnterCriticalSection(&m_Lock);
	return bRet ? 0 : -1;
#else
	int nRet = ::pthread_mutex_trylock(&m_Lock);
	return (nRet == 0) ? 0 : -1;
#endif // PLAT_WIN32
}


//////////////////////////////////////////////////////////////////////
// class CMutexThreadRecursive
//////////////////////////////////////////////////////////////////////

CMutexThreadRecursive::CMutexThreadRecursive()
{
#ifdef PLAT_WIN32
	::InitializeCriticalSection(&m_Lock);
#else
	pthread_mutexattr_t mutexattr;
    ::pthread_mutexattr_init(&mutexattr);
    ::pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_NORMAL);

    int nRet = ::pthread_mutex_init(&m_Lock, &mutexattr);
    ::pthread_mutexattr_destroy(&mutexattr);
	if ( nRet != 0 )
	{
		ERROR_TRACE("pthread_mutex_init() failed! err=" << nRet);
	}
#endif // PLAT_WIN32
}

CMutexThreadRecursive::~CMutexThreadRecursive()
{
}


//////////////////////////////////////////////////////////////////////
// class CMutexThread
//////////////////////////////////////////////////////////////////////

CMutexThread::CMutexThread()
{
#ifdef PLAT_WIN32
	::InitializeCriticalSection(&m_Lock);
#else
	pthread_mutexattr_t mutexattr;
    ::pthread_mutexattr_init(&mutexattr);
#ifdef ANDROID //android平台没有PTHREAD_MUTEX_FAST_NP宏
	::pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_NORMAL);
#else
    ::pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_NORMAL);
#endif
    int nRet = ::pthread_mutex_init(&m_Lock, &mutexattr);
    ::pthread_mutexattr_destroy(&mutexattr);
	if (nRet != 0)
	{
		ERROR_TRACE("pthread_mutex_init() failed! err=" << nRet);
	}
#endif // PLAT_WIN32
}

CMutexThread::~CMutexThread()
{
}


//////////////////////////////////////////////////////////////////////
// class CDCSemaphore
//////////////////////////////////////////////////////////////////////

CSemaphore::CSemaphore(LONG aInitialCount, LPCSTR aName, LONG aMaximumCount)
{
#ifdef WIN32
	m_Semaphore = ::CreateSemaphoreA(NULL, aInitialCount, aMaximumCount, aName);
	if ( m_Semaphore == 0)  
	{
		ERROR_TRACE(" CreateSemaphoreA failed! err=" << ::GetLastError());
		//DC_ASSERTE(FALSE);
	}
#else // !WIN32
	if ( ::sem_init(&m_Semaphore, 0, aInitialCount) == -1 ) 
	{
		ERROR_TRACE(" sem_init() failed! err=" << errno);
		//DC_ASSERTE(FALSE);
	}
#endif
}

CSemaphore::~CSemaphore()
{
#ifdef WIN32
	if ( !::CloseHandle(m_Semaphore) ) 
	{
		ERROR_TRACE(" CloseHandle() failed! err=" << ::GetLastError());
	}
#else // !WIN32
	if ( ::sem_destroy(&m_Semaphore) == -1 ) 
	{
		ERROR_TRACE(" sem_destroy() failed! err=" << errno);
	}
#endif // WIN32
}

int CSemaphore::Lock()
{
#ifdef WIN32
	DWORD dwRet = ::WaitForSingleObject(m_Semaphore,INFINITE);
	switch (dwRet) 
	{
	case WAIT_OBJECT_0:
		return 0;
	default:
		ERROR_TRACE(" WaitForSingleObject() failed! dwRet=" << dwRet <<" err=" << ::GetLastError());
		return -1;
	}
#else // !WIN32
	if ( ::sem_wait(&m_Semaphore) == -1 ) 
	{
		ERROR_TRACE(" sem_wait() failed! err=" << errno);
		return -1;
	}
	else
		return 0;
#endif // WIN32
}

int CSemaphore::UnLock()
{
	return PostN(1);
}

int CSemaphore::PostN(LONG aCount)
{
	//DC_ASSERTE(aCount >= 1);
#ifdef WIN32
	if ( !::ReleaseSemaphore(m_Semaphore, aCount, NULL) ) 
	{
		ERROR_TRACE(" ReleaseSemaphore failed! err=" << ::GetLastError());
		return -1;
	}
	else
		return 0;
#else // !WIN32
	for (LONG i = 0; i < aCount; i++) 
	{
		if ( ::sem_post(&m_Semaphore) == -1 ) 
		{
			ERROR_TRACE(" sem_post failed! err=" << errno);
			return -1;
		}
	}
	return 0;
#endif // WIN32
}


//////////////////////////////////////////////////////////////////////
// class CConditionVariableThread
//////////////////////////////////////////////////////////////////////

CConditionVariableThread::CConditionVariableThread(CMutexThread &aMutex)
	: m_MutexExternal(aMutex)
#ifdef WIN32
	, sema_(0)
#endif // WIN32
{
#ifdef WIN32
	waiters_ = 0;
	was_broadcast_ = 0;
	waiters_done_= ::CreateEventA(NULL, 0, 0, NULL);
	if ( waiters_done_ == 0 ) 
	{
		ERROR_TRACE(" CreateEventA() failed! err=" << ::GetLastError());
		//DC_ASSERTE(FALSE);
	}
#else // !WIN32
	int nRet = ::pthread_cond_init(&m_Condition, NULL);
	if ( nRet != 0 ) 
	{
		ERROR_TRACE(" pthread_cond_init() failed! err=" << nRet);
		//DC_ASSERTE(FALSE);
	}
#endif // WIN32
}

CConditionVariableThread::~CConditionVariableThread()
{
#ifdef WIN32
	if ( !::CloseHandle(waiters_done_) ) 
	{
		ERROR_TRACE(" CloseHandle() failed! err=" << ::GetLastError());
	}
#else // !WIN32
	int nRet = ::pthread_cond_destroy(&m_Condition);
	if ( nRet != 0 ) 
	{
		ERROR_TRACE(" pthread_cond_destroy() failed! err=" << nRet);
	}
#endif // WIN32
}

int CConditionVariableThread::Signal()
{
#ifdef WIN32
	waiters_lock_.Lock();
	int have_waiters = waiters_ > 0;
	waiters_lock_.UnLock();

	if ( have_waiters != 0 )
	{
		return sema_.UnLock();
	}
	else
	{
		return 0;
	}
#else // !WIN32
	int nRet = ::pthread_cond_signal(&m_Condition);
	if ( nRet != 0 ) 
	{
		ERROR_TRACE(" pthread_cond_signal() failed! err=" << nRet);
		return -1;
	}
	else
	{
		return 0;
	}
#endif // WIN32
}

int CConditionVariableThread::Wait(long aTimeout)
{
#ifdef WIN32
	// Prevent race conditions on the <waiters_> count.
	waiters_lock_.Lock();
	waiters_++;
	waiters_lock_.UnLock();

	int msec_timeout;
	if ( aTimeout <= 0 )
	{
		msec_timeout = INFINITE;
	}
	else 
	{
		msec_timeout = aTimeout;
		//msec_timeout = aTimeout->GetMsec();
		//if ( msec_timeout < 0 )
		//{
		//	msec_timeout = 0;
		//}
	}

	// We keep the lock held just long enough to increment the count of
	// waiters by one.  Note that we can't keep it held across the call
	// to WaitForSingleObject since that will deadlock other calls to
	// ACE_OS::cond_signal().
	int rv = m_MutexExternal.UnLock();
	//DC_ASSERTE_RETURN(CM_SUCCEEDED(rv), rv);

	// <CCmSemaphore> has not time wait function due to pthread restriction,
	// so we have to use WaitForSingleObject() directly.
	DWORD result = ::WaitForSingleObject(sema_.GetSemaphoreType(), msec_timeout);

	waiters_lock_.Lock();
	waiters_--;
	int last_waiter = was_broadcast_ && waiters_ == 0;
	waiters_lock_.UnLock();

	switch (result) 
	{
	case WAIT_OBJECT_0:
		rv = 0;
		break;
	case WAIT_TIMEOUT:
		rv = 1; //timeout
		break;
	default:
		ERROR_TRACE(" WaitForSingleObject() failed! result=" << result << " err=" << ::GetLastError());
		rv = -1;
		break;
	}

	if (last_waiter) 
	{
		if ( !::SetEvent(waiters_done_) ) 
		{
			ERROR_TRACE(" SetEvent() failed! err=" << ::GetLastError());
		}
	}

	// We must always regain the <external_mutex>, even when errors
	// occur because that's the guarantee that we give to our callers.
	m_MutexExternal.Lock();
	return rv;
#else // !WIN32
	if ( aTimeout <= 0 ) 
	{
		int nRet = ::pthread_cond_wait(&m_Condition, &(m_MutexExternal.GetMutexType()));
		if ( nRet != 0 ) 
		{
			ERROR_TRACE("CDCConditionVariableThread::Wait() pthread_cond_wait() failed! err=" << nRet);
			return -1;
		}
	}
	else 
	{
		struct timespec tsBuf;
		long long /*CDCTimeValue*/ curTime; 
		//CDCTimeValue::GetTimeOfDay(curTime);
		curTime = GetCurrentTimeMs();
		long long /*CDCTimeValue*/ tvAbs;
		//tvAbs.Set(curTime.GetSec()+aTimeout->GetSec(),curTime.GetUsec()+aTimeout->GetUsec());
		tvAbs = curTime*1000;
		tvAbs += aTimeout*1000;
		tsBuf.tv_sec = tvAbs/(1000*1000);//tvAbs.GetSec();
		tsBuf.tv_nsec = tvAbs%(1000*1000)*1000;//tvAbs.GetUsec() * 1000;
		int nRet = ::pthread_cond_timedwait(&m_Condition, &(m_MutexExternal.GetMutexType()),&tsBuf);

		if ( nRet != 0 ) 
		{
			if ( nRet == ETIMEDOUT )
			{
				return 1; //timeout
			}
			// EINTR is OK.
			else if ( nRet == EINTR )
			{
				return 0;
			}
			else 
			{
				ERROR_TRACE(" pthread_cond_timedwait() failed! err=" << nRet);
				return -1;
			}
		}
	}
	return 0;
#endif // WIN32
}

int CConditionVariableThread::Broadcast()
{
	// The <external_mutex> must be locked before this call is made.
#ifdef WIN32
	// This is needed to ensure that <waiters_> and <was_broadcast_> are
	// consistent relative to each other.
	waiters_lock_.Lock();
	int have_waiters = 0;
	if ( waiters_ > 0 ) 
	{
		// We are broadcasting, even if there is just one waiter...
		// Record the fact that we are broadcasting.  This helps the
		// cond_wait() method know how to optimize itself.  Be sure to
		// set this with the <waiters_lock_> held.
		was_broadcast_ = 1;
		have_waiters = 1;
	}
	waiters_lock_.UnLock();

	int rv = 0;
	if ( have_waiters ) 
	{
		int rv1 = sema_.PostN(waiters_);
		if ( 0 != rv1 )
		{
			rv = rv1;
		}
		
		DWORD result = ::WaitForSingleObject(waiters_done_, INFINITE);
		if ( result != WAIT_OBJECT_0 ) 
		{
			ERROR_TRACE(" WaitForSingleObject() failed! result=" << result << " err=" << ::GetLastError());
			rv = -1;
		}
		was_broadcast_ = 0;
	}
	return rv;
#else // !WIN32
	int nRet = ::pthread_cond_broadcast(&m_Condition);
	if ( nRet != 0 ) 
	{
		ERROR_TRACE(" pthread_cond_broadcast() failed! err=" << nRet);
		return -1;
	}
	else
		return 0;
#endif // WIN32
}


//////////////////////////////////////////////////////////////////////
// class CEventThread
//////////////////////////////////////////////////////////////////////

CEventThread::CEventThread(BOOL aManualReset, BOOL aInitialState, LPCSTR aName)
#ifndef WIN32
	: condition_(lock_)
#endif // !WIN32
{
#ifdef WIN32
	handle_ = ::CreateEventA(NULL, aManualReset, aInitialState, aName);
	if ( handle_ == 0 ) 
	{
		ERROR_TRACE(" CreateEventA() failed! err=" << ::GetLastError());
		//DC_ASSERTE(FALSE);
	}
#else // !WIN32
	manual_reset_ = aManualReset;
	is_signaled_ = aInitialState;
	waiting_threads_ = 0;
#endif // WIN32
}

CEventThread::~CEventThread()
{
#ifdef WIN32
	if ( !::CloseHandle(handle_) ) 
	{
		ERROR_TRACE(" CloseHandle() failed! err=" << ::GetLastError());
	}
#else // !WIN32
	// not need do cleanup.
#endif // WIN32
}

int CEventThread::Wait(long aTimeout)
{
	int rv;
	//INFO_TRACE("wait");
#ifdef WIN32
	int msec_timeout;
	if ( aTimeout <= 0 )
	{
		msec_timeout = INFINITE;
	}
	else 
	{
		msec_timeout = aTimeout;
		//msec_timeout = aTimeout->GetMsec();
		//if ( msec_timeout < 0 )
		//{
		//	msec_timeout = 0;
		//}
	}

	DWORD result = ::WaitForSingleObject(handle_, msec_timeout);
	switch ( result ) 
	{
	case WAIT_OBJECT_0:
		rv = 0;
		break;
	case WAIT_TIMEOUT:
		rv = 1;
		break;
	default:
		ERROR_TRACE(" failed! result=" << result << " err=" << ::GetLastError());
		rv = -1;
		break;
	}
#else // !WIN32
	rv = lock_.Lock();
	//DC_ASSERTE_RETURN(CM_SUCCEEDED(rv), rv);

	if ( is_signaled_ == 1 ) 
	{
		// event is currently signaled
		if ( manual_reset_ == 0 )
			// AUTO: reset state
		{
			is_signaled_ = 0;
		}
	}
	else 
	{
		// event is currently not signaled
		waiting_threads_++;
		rv = condition_.Wait(aTimeout);
		waiting_threads_--;
	}

	lock_.UnLock();
#endif // WIN32
	return rv;
}

int CEventThread::Signal()
{
#ifdef WIN32
	if ( !::SetEvent(handle_) ) 
	{
		ERROR_TRACE(" SetEvent failed! err=" << ::GetLastError());
		return -1;
	}
	else
	{
		return 0;
	}
#else // !WIN32
	int rv;
	rv = lock_.Lock();
	//DC_ASSERTE_RETURN(CM_SUCCEEDED(rv), rv);

	if ( manual_reset_ == 1 ) 
	{
		// Manual-reset event.
		is_signaled_ = 1;
		rv = condition_.Broadcast();
	}
	else 
	{
		// Auto-reset event
		if ( waiting_threads_ == 0 )
		{
			is_signaled_ = 1;
		}
		else
		{
			rv = condition_.Signal();
		}
	}

	lock_.UnLock();
	//INFO_TRACE("signal");
	return rv;
#endif // WIN32
}
	/// Set to nonsignaled state.
int CEventThread::Reset()
{
#ifdef WIN32
	::ResetEvent(handle_);
	return 0;
#else
	return 0;
#endif
}

int CEventThread::Pulse()
{
#ifdef WIN32
	if ( !::PulseEvent(handle_) ) 
	{
		ERROR_TRACE(" PulseEvent() failed! err=" << ::GetLastError());
		return -1;
	}
	else
	{
		return 0;
	}
#else // !DC_WIN32
	int rv;
	rv = lock_.Lock();
	//DC_ASSERTE_RETURN(CM_SUCCEEDED(rv), rv);

	if ( manual_reset_ == 1 ) 
	{
		// Manual-reset event: Wakeup all waiters.
		rv = condition_.Broadcast();
	}
	else 
	{
		// Auto-reset event: wakeup one waiter.
		rv = condition_.Signal();
	}
	
	is_signaled_ = 0;
	lock_.UnLock();
	return rv;
#endif // WIN32
}
