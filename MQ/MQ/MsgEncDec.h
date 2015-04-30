#ifndef MSGENCDEC_H
#define MSGENCDEC_H

class ConvertorType
{
public:
	static void Swap(unsigned short &aHostShort)
	{
#if 1 //cpu arch LITTLE_ENDIAN
		Swap2(&aHostShort, &aHostShort);
#endif 
	}

	static void Swap(unsigned int &aHostLong)
	{
#if 1 //cpu arch LITTLE_ENDIAN
		Swap4(&aHostLong, &aHostLong);
#endif
	}


	static void Swap(unsigned long long &aHostLongLong)
	{
#if 1 //cpu arch LITTLE_ENDIAN
		Swap8(&aHostLongLong, &aHostLongLong);
#endif
	}

	// mainly copied from ACE_CDR
	static void Swap2(const void *orig, void* target)
	{
		register unsigned short usrc = * reinterpret_cast<const unsigned short*>(orig);
		register unsigned short* udst = reinterpret_cast<unsigned short*>(target);
		*udst = (usrc << 8) | (usrc >> 8);
	}

	static void Swap4(const void* orig, void* target)
	{
		register unsigned int x = * reinterpret_cast<const unsigned int*>(orig);
		x = (x << 24) | ((x & 0xff00) << 8) | ((x & 0xff0000) >> 8) | (x >> 24);
		* reinterpret_cast<unsigned int*>(target) = x;
	}

	static void Swap8(const void* orig, void* target)
	{
		register unsigned int x = * reinterpret_cast<const unsigned int*>(orig);
		register unsigned int y = * reinterpret_cast<const unsigned int*>(static_cast<const char*>(orig) + 4);
		x = (x << 24) | ((x & 0xff00) << 8) | ((x & 0xff0000) >> 8) | (x >> 24);
		y = (y << 24) | ((y & 0xff00) << 8) | ((y & 0xff0000) >> 8) | (y >> 24);
		* reinterpret_cast<unsigned int*>(target) = y;
		* reinterpret_cast<unsigned int*>(static_cast<char*>(target) + 4) = x;
	}
};

class CByteEncDec
{
public:
	CByteEncDec(char *pBuf,unsigned int len):m_pData(pBuf),m_uiLength(len),
											 m_pEndData(m_pData+len),m_pWritePtr(m_pData),
											 m_pReadPtr(m_pData),m_ResultRead(true),m_ResultWrite(true)
	  {

	  }
	~CByteEncDec()
	{
	
	}

	CByteEncDec& operator<<(char c)
	{
		Write(&c, sizeof(char));
		return *this;
	}

	CByteEncDec& operator<<(unsigned char c)
	{
		Write(&c, sizeof(unsigned char));
		return *this;
	}

	CByteEncDec& operator<<(short n)
	{
		return *this << (unsigned short)n;
	}

	CByteEncDec& operator<<(unsigned short n)
	{
		ConvertorType::Swap(n);
		Write(&n, sizeof(unsigned short));
		return *this;
	}

	CByteEncDec& operator<<(int n)
	{
		return *this << (unsigned int)n;
	}

	CByteEncDec& operator<<(unsigned int n)
	{
		ConvertorType::Swap(n);
		Write(&n, sizeof(unsigned int));
		return *this;
	}

	CByteEncDec& operator<<(long long n)
	{
		return *this << (unsigned long long)n;
	}

	CByteEncDec& operator<<(unsigned long long n)
	{
		ConvertorType::Swap(n);
		Write(&n, sizeof(unsigned long long));
		return *this;
	}


	CByteEncDec& operator<<(const std::string &str)
	{
		return WriteString(str.c_str(), str.length());
	}

	CByteEncDec& operator<<(const char *str)
	{
		unsigned short len = 0;
		if ( str )
		{
			len = strlen(str);
		}
		return WriteString(str, len);
	}

	CByteEncDec& WriteString(const char *str, unsigned int ll)
	{
		unsigned short len = static_cast<unsigned short>(ll);

		(*this) << len;
		if ( len > 0 )
		{
			Write(str, len);
		}
		return *this;
	}

	CByteEncDec& operator>>(char& c)
	{
		Read(&c, sizeof(char));
		return *this;
	}

	CByteEncDec& operator>>(unsigned char& c)
	{
		Read(&c, sizeof(unsigned char));
		return *this;
	}

	CByteEncDec& operator>>(short& n)
	{
		return *this >> (unsigned short&)n;
	}

	CByteEncDec& operator>>(unsigned short& n)
	{
		Read(&n, sizeof(unsigned short));
		ConvertorType::Swap(n);
		return *this;
	}


	CByteEncDec& operator>>(int& n)
	{
		return *this >> (unsigned int&)n;
	}

	CByteEncDec& operator>>(unsigned int& n)
	{
		Read(&n, sizeof(unsigned int));
		ConvertorType::Swap(n);
		return *this;
	}
	CByteEncDec& operator>>(long long& n)
	{
		return *this >> (unsigned long long&)n;
	}

	CByteEncDec& operator>>(unsigned long long& n)
	{
		Read(&n, sizeof(unsigned long long));
		ConvertorType::Swap(n);
		return *this;
	}

	CByteEncDec& operator>>(std::string& str)
	{
		unsigned short len = 0;
		(*this) >> len;

		if (len > 0)
		{
			str.resize(0);
			str.resize(len);
			Read(const_cast<char*>(str.data()), len);
		}
		return *this;
	}

	
	CByteEncDec& Read(void *aDst, unsigned int aCount)
	{
		if ( m_ResultRead )
		{
			unsigned int ulRead = 0;
			//m_ResultRead = m_Block.Read(aDst, aCount, &ulRead);
			::memcpy(aDst,m_pReadPtr,aCount);
			m_pReadPtr += aCount;
			m_ResultRead = m_pReadPtr < m_pEndData ? true : false;
		}
		if ( !m_ResultRead ) //¶ÁÊ§°Ü
		{
		}
		return *this;
	}

	CByteEncDec& Write(const void *aDst, unsigned int aCount)
	{
		if ( m_ResultWrite )
		{
			unsigned int ulWritten = 0;
			::memcpy(m_pWritePtr,aDst,aCount);
			m_pWritePtr += aCount;
			m_ResultWrite = m_pWritePtr < m_pEndData ? true : false;
		}
		if ( !m_ResultWrite ) //Ð´Ê§°Ü
		{
		}
		return *this;
	}
	
	bool IsGood()
	{
		if ( m_ResultWrite && m_ResultRead )
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	unsigned int GetWriteLength()
	{
		return (unsigned int)(m_pWritePtr-m_pData);
	}
	unsigned int GetReadLength()
	{
		return (unsigned int)(m_pReadPtr-m_pData);
	}

private:
	bool m_ResultRead;
	bool m_ResultWrite;

	char *m_pData;
	unsigned int m_uiLength;
	char *m_pEndData;
	char *m_pWritePtr;
	char *m_pReadPtr;

	// Not support bool because its sizeof is not fixed.
	CByteEncDec& operator<<(bool n);
	CByteEncDec& operator>>(bool& n);

	// Not support long double.
	CByteEncDec& operator<<(long double n);
	CByteEncDec& operator>>(long double& n);
};

#endif