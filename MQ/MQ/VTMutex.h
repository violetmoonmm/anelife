/*------------------------------------------------------*/

#ifndef _VTMUTEX_H
#define _VTMUTEX_H

#include "VTUtilDefine.h"


class CVTMutexThreadBase
{
protected:
	CVTMutexThreadBase();
	~CVTMutexThreadBase();

public:
	int Lock();
	int UnLock();
	int TryLock();

	VT_THREAD_MUTEX_T& GetMutexType() { return m_Lock;}

protected:
	VT_THREAD_MUTEX_T m_Lock;
};

/**
 * Mainly copyed from <ACE_Recursive_Thread_Mutex>.
 * <CVTMutexThreadRecursive> allows mutex locking many times in the same threads.
 */
class CVTMutexThreadRecursive : public CVTMutexThreadBase
{
public:
	CVTMutexThreadRecursive();
	~CVTMutexThreadRecursive();

private:
	// = Prevent assignment and initialization.
	void operator = (const CVTMutexThreadRecursive&);
	CVTMutexThreadRecursive(const CVTMutexThreadRecursive&);
};

class CVTMutexThread : public CVTMutexThreadBase
{
public:
	CVTMutexThread();
	~CVTMutexThread();

private:
	// = Prevent assignment and initialization.
	void operator = (const CVTMutexThread&);
	CVTMutexThread(const CVTMutexThread&);
};

template <class MutexType>
class CVTMutexGuardT
{
public:
	CVTMutexGuardT(MutexType& aMutex)
		: m_Mutex(aMutex)
		, m_bLocked(FALSE)
	{
		Lock();
	}

	~CVTMutexGuardT()
	{
		UnLock();
	}

	int Lock() 
	{
		int rv = m_Mutex.Lock();
		m_bLocked = (0 == (rv)) ? TRUE : FALSE;
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
	int m_bLocked;

private:
	// = Prevent assignment and initialization.
	void operator = (const CVTMutexGuardT&);
	CVTMutexGuardT(const CVTMutexGuardT&);
};

#endif // !VTMUTEX_H
