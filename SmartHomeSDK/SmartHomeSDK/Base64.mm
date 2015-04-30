
#include "Base64.h"

////base64
const int pr2six[256]={
    64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,
    64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,62,64,64,64,63,
    52,53,54,55,56,57,58,59,60,61,64,64,64,64,64,64,64,0,1,2,3,4,5,6,7,8,9,
    10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,64,64,64,64,64,64,26,27,
    28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,
    64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,
    64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,
    64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,
    64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,
    64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,
    64,64,64,64,64,64,64,64,64,64,64,64,64
};

char six2pr[64] = {
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
    'a','b','c','d','e','f','g','h','i','j','k','l','m',
    'n','o','p','q','r','s','t','u','v','w','x','y','z',
    '0','1','2','3','4','5','6','7','8','9','+','/'
};

void Base64Decode(const char *bufcoded, char * dst,int *nbytes)
{
    int nbytesdecoded;
    const char *bufin = bufcoded;
    unsigned char *bufout = (unsigned char*)dst;
    int nprbytes;

    /* Figure out how many characters are in the input buffer.
     * If this would decode into more bytes than would fit into
     * the output buffer, adjust the number of input bytes downwards.
     */
    //bufin = bufcoded;
    while(pr2six[(int)*(bufin++)] <= 63){}
    nprbytes = (int)(bufin - bufcoded - 1);
    nbytesdecoded = ((nprbytes+3)/4) * 3;

    bufin = bufcoded;

    while (nprbytes > 0)
	{
        *(bufout++) =
            (unsigned char) (pr2six[(int)*bufin] << 2 | pr2six[(int)bufin[1]] >> 4);
        *(bufout++) =
            (unsigned char) (pr2six[(int)bufin[1]] << 4 | pr2six[(int)bufin[2]] >> 2);
        *(bufout++) =
            (unsigned char) (pr2six[(int)bufin[2]] << 6 | pr2six[(int)bufin[3]]);
        bufin += 4;
        nprbytes -= 4;
    }

    if(nprbytes & 03)
	{
        if(pr2six[(int)bufin[-2]] > 63)
            nbytesdecoded -= 2;
        else
            nbytesdecoded -= 1;
    }
	dst[nbytesdecoded] = '\0';
	if ( nbytes )
	{
		*nbytes = nbytesdecoded;
	}
}

void Base64Encode(const unsigned char *bufin, unsigned int nbytes, char * dst)
{
   unsigned char *outptr = (unsigned char *)dst;
   unsigned int i;

   for (i=0; i<nbytes; i += 3)
   {
      *(outptr++) = six2pr[*bufin >> 2];            /* c1 */
      *(outptr++) = six2pr[((*bufin << 4) & 060) | ((bufin[1] >> 4) & 017)]; /*c2*/
      *(outptr++) = six2pr[((bufin[1] << 2) & 074) | ((bufin[2] >> 6) & 03)];/*c3*/
      *(outptr++) = six2pr[bufin[2] & 077];         /* c4 */

      bufin += 3;
   }

   /* If nbytes was not a multiple of 3, then we have encoded too
    * many characters.  Adjust appropriately.
    */
   if(i == nbytes+1)
   {
      /* There were only 2 bytes in that last group */
      outptr[-1] = '=';
   } 
   else if(i == nbytes+2)
   {
      /* There was only 1 byte in that last group */
      outptr[-1] = '=';
      outptr[-2] = '=';
   }

   *(outptr++) = '\0';

   //size_t len = outptr - 1 - (unsigned char*)dst;
}
