#include "ZipLib.h"
#include "zlib.h"
#include <string.h>



/*----------------------------------------------------------------------
|   ZipLib::Deflate
+---------------------------------------------------------------------*/
//int ZipLib::Deflate(const char * in,
//					const int inlen,
//                    char *out,
//					int &outlen,
//                    //int                   compression_level = NPT_ZIP_COMPRESSION_LEVEL_DEFAULT,
//                    Format format
//					)
//{
//	unsigned int outsize;
//
//    // setup the stream
//	z_stream stream = {0};
//    //NPT_SetMemory(&stream, 0, sizeof(stream));
//    stream.next_in   = (Bytef*)in;
//    stream.avail_in  = (uInt)inlen;
//    
//    // setup the memory functions
//    stream.zalloc = (alloc_func)0;
//    stream.zfree = (free_func)0;
//    stream.opaque = (voidpf)0;
//
//    // initialize the compressor
//    int err = deflateInit2(&stream, 
//                           -1,
//                           Z_DEFLATED,
//                           15 + (format == GZIP ? 16 : 0),
//                           8,
//                           Z_DEFAULT_STRATEGY);
//    if ( err != Z_OK )
//	{
//		return err;
//	}
//
//    // reserve an output buffer known to be large enough
// //   outsize = deflateBound(&stream, stream.avail_in) + (format==GZIP?10:0);
//	//if ( outlen < outsize ) //»º³åÇøÌ«Ð¡
//	//{
//	//	return -1;
//	//}
//
//	outsize = outlen;
//    stream.next_out  = (Bytef*)out;
//    stream.avail_out = (uInt)outsize;
//
//    // decompress
//    err = deflate(&stream, Z_FINISH);
//    if ( err != Z_STREAM_END )
//	{
//        deflateEnd(&stream);
//        return err;
//    }
//    
//    // update the output size
//    outlen = stream.total_out;
//
//    // cleanup
//    err = deflateEnd(&stream);
//
//    return err;
//}

/*----------------------------------------------------------------------
|   ZipLib::Inflate
+---------------------------------------------------------------------*/                              
//int ZipLib::Inflate(const char * in,
//					const int inlen,
//                    char *out,
//					int &outlen
//					)
//{
//    // assume an output buffer twice the size of the input plus a bit
//    //NPT_CHECK_WARNING(out.Reserve(32+2*in.GetDataSize()));
//    
//    // setup the stream
//    z_stream stream;
//    stream.next_in   = (Bytef*)in;
//    stream.avail_in  = (uInt)inlen;
//    stream.next_out  = (Bytef*)out;
//    stream.avail_out = (uInt)outlen;
//
//    // setup the memory functions
//    stream.zalloc = (alloc_func)0;
//    stream.zfree = (free_func)0;
//    stream.opaque = (voidpf)0;
//
//    // initialize the decompressor
//    int err = inflateInit2(&stream, 15+32); // 15 = default window bits, +32 = automatic header
//    if ( err != Z_OK )
//	{
//		return err;
//	}
//
//    // decompress until the end
//    do
//	{
//        err = inflate(&stream, Z_SYNC_FLUSH);
//        if (err == Z_STREAM_END || err == Z_OK || err == Z_BUF_ERROR)
//		{
//			if ( outlen < stream.total_out )
//			{
//				return Z_BUF_ERROR;
//			}
//			outlen = stream.total_out;
//            //out.SetDataSize(stream.total_out);
//            if ((err == Z_OK && stream.avail_out == 0) || err == Z_BUF_ERROR)
//			{
//				return Z_BUF_ERROR;
//                //// grow the output buffer
//                //out.Reserve(out.GetBufferSize()*2);
//                //stream.next_out = out.UseData()+stream.total_out;
//                //stream.avail_out = out.GetBufferSize()-stream.total_out;
//            }
//        }
//    } while ( err == Z_OK );
//    
//    // check for errors
//    if ( err != Z_STREAM_END )
//	{
//        inflateEnd(&stream);
//        return err;
//    }
//    
//    // cleanup
//    err = inflateEnd(&stream);
//
//    return err;
//}


//Ñ¹Ëõ
bool ZipLib::Compress(const char * in,const int inlen,char *&out,int &outlen,Format format)
{
	unsigned int outsize;
	z_stream stream = {0};
	int iRet = 0;

    // setup the stream
    stream.next_in   = (Bytef*)in;
	stream.avail_in  = (uInt)inlen;
    
    // setup the memory functions
    stream.zalloc = (alloc_func)0;
    stream.zfree = (free_func)0;
    stream.opaque = (voidpf)0;

    // initialize the compressor
    iRet = deflateInit2(&stream, 
                           -1,
                           Z_DEFLATED,
                           15 + (format == GZIP ? 16 : 0),
                           8,
                           Z_DEFAULT_STRATEGY);
    if ( iRet != Z_OK )
	{
		return false;
	}

    // reserve an output buffer known to be large enough
    outsize = deflateBound(&stream, stream.avail_in) + (format==GZIP?10:0);
	out = new char[outsize];
	if ( !out )
	{
		return false;
	}

    stream.next_out  = (Bytef*)out;
    stream.avail_out = (uInt)outsize;

    //compress
    iRet = deflate(&stream, Z_FINISH);
    if ( iRet != Z_STREAM_END )
	{
        deflateEnd(&stream);
		delete []out;
		out = NULL;
        return false;
    }
    
    // update the output size
    outlen = stream.total_out;

    // cleanup
    iRet = deflateEnd(&stream);
	if ( iRet != Z_OK )
	{
		delete []out;
		out = NULL;
        return false;
    }

    return true;
}

//½âÑ¹Ëõ
bool ZipLib::Decompress(const char * in,const int inlen,char *&out,int &outlen)
{
    // assume an output buffer twice the size of the input plus a bit
    //NPT_CHECK_WARNING(out.Reserve(32+2*in.GetDataSize()));
    
    // setup the stream
	int iRet = 0;
	bool bRet = true;
	int outbuf;
	int bufindex = 0;
	char *buftemp = NULL;
	z_stream stream = {0};

	out = NULL;
	outbuf = 32+inlen*2;
	out = new char[outbuf];
	if ( !out )
	{
		return false;
	}
    stream.next_in   = (Bytef*)in;
    stream.avail_in  = (uInt)inlen;
    stream.next_out  = (Bytef*)out;
    stream.avail_out = (uInt)outbuf;

    // setup the memory functions
    stream.zalloc = (alloc_func)0;
    stream.zfree = (free_func)0;
    stream.opaque = (voidpf)0;

    // initialize the decompressor
    iRet = inflateInit2(&stream, 15+32); // 15 = default window bits, +32 = automatic header
    if ( iRet != Z_OK )
	{
		return false;
	}

    // decompress until the end
    do
	{
        iRet = inflate(&stream, Z_SYNC_FLUSH);
        if (iRet == Z_STREAM_END || iRet == Z_OK || iRet == Z_BUF_ERROR)
		{
			//if ( outlen < stream.total_out )
			//{
			//	return Z_BUF_ERROR;
			//}
			outlen = stream.total_out;
            //out.SetDataSize(stream.total_out);
            if ((iRet == Z_OK && stream.avail_out == 0) || iRet == Z_BUF_ERROR)
			{
				bufindex = outbuf;

				buftemp = out; 
				//delete []out;
				outbuf += outbuf;
				out = new char[outbuf];
				if ( !out )
				{
					delete []buftemp;
					return false;
				}
				memcpy(out,buftemp,bufindex);
                stream.next_out = (Bytef*)out+stream.total_out;
                stream.avail_out = (uInt)outbuf-stream.total_out;
				delete []buftemp;
				//return Z_BUF_ERROR;
                //// grow the output buffer
                //out.Reserve(out.GetBufferSize()*2);
                //stream.next_out = out.UseData()+stream.total_out;
                //stream.avail_out = out.GetBufferSize()-stream.total_out;
            }
        }
    } while ( iRet == Z_OK );
    
    // check for errors
    if ( iRet != Z_STREAM_END )
	{
		bRet = false;
        inflateEnd(&stream);
		delete []out;
		out = NULL;
        return bRet;
    }
    
    // cleanup
    iRet = inflateEnd(&stream);

	bRet = true;
    return bRet;
}