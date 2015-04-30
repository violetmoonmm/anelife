/*------------------------------------------------------*/

#ifndef MUTEX_H
#define MUTEX_H

#include "Platform.h"
//#include "VTError.h"

class CMutexThreadBase
{
protected:
	CMutexThreadBase();
	~CMutexThreadBase();

public:
	int Lock();
	int UnLock();
	int TryLock();

	FCL_THREAD_MUTEX_T& GetMutexType() { return m_Lock; }

protected:
	FCL_THREAD_MUTEX_T m_Lock;
};

/**
 * Mainly copyed from <ACE_Recursive_Thread_Mutex>.
 * <CMutexThreadRecursive> allows mutex locking many times in the same threads.
 */
class CMutexThreadRecursive : public CMutexThreadBase
{
public:
	CMutexThreadRecursive();
	~CMutexThreadRecursive();

private:
	// = Prevent assignment and initialization.
	void operator = (const CMutexThreadRecursive&);
	CMutexThreadRecursive(const CMutexThreadRecursive&);
};

class CMutexThread : public CMutexThreadBase
{
public:
	CMutexThread();
	~CMutexThread();

private:
	// = Prevent assignment and initialization.
	void operator = (const CMutexThread&);
	CMutexThread(const CMutexThread&);
};

template <class MutexType>
class CMutexGuardT
{
public:
	CMutexGuardT(MutexType& aMutex)
		: m_Mutex(aMutex)
		, m_bLocked(FALSE)
	{
		Lock();
	}

	~CMutexGuardT()
	{
		UnLock();
	}

	int Lock() 
	{
		int rv = m_Mutex.Lock();
		m_bLocked = (rv ==0) ? TRUE : FALSE;
		return rv;
	}

	int UnLock() 
	{
		if (m_bLocked)
		{
			m_bLocked = FALSE;
			return m_Mutex.UnLock();
		}
		else
		{
			return 0;
		}
	}

private:
	MutexType& m_Mutex;
	BOOL m_bLocked;

private:
	// = Prevent assignment and initialization.
	void operator = (const CMutexGuardT&);
	CMutexGuardT(const CMutexGuardT&);
};

/**
 * Mainly copied from <ACE_Semaphore>
 * Wrapper for Dijkstra style general semaphores.
 */
class  CSemaphore
{
public:
	CSemaphore(LONG aInitialCount = 0, 
		LPCSTR aName = NULL, 
		LONG aMaximumCount = 0x7fffffff);

	~CSemaphore();

	/// Block the thread until the semaphore count becomes
	/// greater than 0, then decrement it.
	int Lock();

	/// Increment the semaphore by 1, potentially unblocking a waiting thread.
	int UnLock();

	/// Not supported yet.
//	CmResult TryLock();

	// No time wait function due to pthread restriction.
//	CmResult Wait(CCmTimeValue *aTimeout = NULL);

	/// Increment the semaphore by <aCount>, potentially
	/// unblocking waiting threads.
	int PostN(LONG aCount);

	//DC_SEMAPHORE_T& GetSemaphoreType() { return m_Semaphore; }
	#ifdef WIN32
	HANDLE& GetSemaphoreType() { return m_Semaphore; }
#else
	sem_t& GetSemaphoreType() { return m_Semaphore; }
#endif

private:
	//DC_SEMAPHORE_T m_Semaphore;
#ifdef WIN32
	HANDLE m_Semaphore;
#else
	sem_t m_Semaphore;
#endif
};

//class CDCTimeValue;

/**
 * Mainly copyed from <ACE_Condition>.
 * <CCmConditionVariableThread> allows threads to block until shared 
 * data changes state.
 */
class CConditionVariableThread  
{
public:
	CConditionVariableThread(CMutexThread &aMutex);
	~CConditionVariableThread();

	/// Block on condition.
	/// <aTimeout> is relative time.
	int Wait(long aTimeout);

	/// Signal one waiting hread.
	int Signal();

	/// Signal all waiting thread.
	int Broadcast();

	/// Return the underlying mutex.
	CMutexThread& GetUnderlyingMutex() { return m_MutexExternal; }

private:
	CMutexThread &m_MutexExternal;

#ifdef WIN32
	/// Number of waiting threads.
	long waiters_;
	/// Serialize access to the waiters count.
	CMutexThread waiters_lock_;
	/// Queue up threads waiting for the condition to become signaled.
	CSemaphore sema_;
	/**
	 * An auto reset event used by the broadcast/signal thread to wait
	 * for the waiting thread(s) to wake up and get a chance at the
	 * semaphore.
	 */
	HANDLE waiters_done_;
	/// Keeps track of whether we were broadcasting or just signaling.
	size_t was_broadcast_;
#else
	pthread_cond_t m_Condition;
#endif // WIN32
};

/**
 * Mainly copied from <ACE_Event>
 *
 * @brief A wrapper around the Win32 event locking mechanism.
 *
 * Portable implementation of an Event mechanism, which is
 * native to Win32, but must be emulated on UNIX.  Note that
 * this only provides global naming support on Win32.  
 */
class CEventThread
{
public:
	CEventThread(BOOL aManualReset = FALSE,
             BOOL aInitialState = FALSE,
             LPCSTR aName = NULL);

	~CEventThread();

	/**
	 * if MANUAL reset
	 *    sleep till the event becomes signaled
	 *    event remains signaled after wait() completes.
	 * else AUTO reset
	 *    sleep till the event becomes signaled
	 *    event resets wait() completes.
	 * <aTimeout> is relative time.
	 */
	int Wait(long aTimeout);

	/**
	 * if MANUAL reset
	 *    wake up all waiting threads
	 *    set to signaled state
	 * else AUTO reset
	 *    if no thread is waiting, set to signaled state
	 *    if thread(s) are waiting, wake up one waiting thread and
	 *    reset event
	 */
	int Signal();

	/// Set to nonsignaled state.
	int Reset();

	/**
	 * if MANUAL reset
	 *    wakeup all waiting threads and
	 *    reset event
	 * else AUTO reset
	 *    wakeup one waiting thread (if present) and
	 *    reset event
	 */
	int Pulse();

private:
#ifdef WIN32
	HANDLE handle_;
#else
	/// Protect critical section.
	CMutexThread lock_;

	/// Keeps track of waiters.
	CConditionVariableThread condition_;

	/// Specifies if this is an auto- or manual-reset event.
	int manual_reset_;

	/// "True" if signaled.
	int is_signaled_;

	/// Number of waiting threads.
	u_long waiting_threads_;
#endif
};

#endif // !MUTEX_H
