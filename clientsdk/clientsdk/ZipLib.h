#ifndef ZipLib_h
#define ZipLib_h

#include <string>

class ZipLib
{
public:

    /** 
     * Compressed data format
     */
    typedef enum
	{
        ZLIB,
        GZIP
    } Format;
        
    /**
     * Deflate (i.e compress) a buffer
     */
//    static int Deflate(const char * in,
//					   const int inlen,
//                       char *out,
//					   int &outlen,
//                       //int                   compression_level = NPT_ZIP_COMPRESSION_LEVEL_DEFAULT,
//                       Format                format = ZLIB);
    
    /**
     * Inflate (i.e decompress) a buffer
     */
//    static int Inflate(const char * in,
//					   const int inlen,
//                       char *out,
//					   int &outlen);   
 
	//—πÀı
	static bool Compress(const char * in,const int inlen,char *&out,int &outlen,Format format = ZLIB);
      
	//Ω‚—πÀı
    static bool Decompress(const char * in,const int inlen,char *&out,int &outlen);   

};

#endif