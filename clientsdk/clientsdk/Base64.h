
#ifndef BASE64_H
#define BASE64_H

void Base64Decode(const char *bufcoded, char * dst,int *nbytes = 0);
void Base64Encode(const unsigned char *bufin, unsigned int nbytes, char * dst);

#endif