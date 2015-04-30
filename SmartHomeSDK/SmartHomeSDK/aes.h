#ifndef AVUTIL_AES_H
#define AVUTIL_AES_H

#ifndef uint64_t
	typedef unsigned long long     uint64_t;
#endif

#ifndef uint32_t
	typedef unsigned int           uint32_t;
#endif

#ifndef uint8_t
	typedef unsigned char          uint8_t;
#endif

typedef union {
//    uint64_t u64[2];
		uint8_t  u64[16];
    uint32_t u32[4];
    uint8_t u8x4[4][4];
    uint8_t u8[16];
} av_aes_block;

typedef struct AVAES {
    // Note: round_key[16] is accessed in the init code, but this only
    // overwrites state, which does not matter (see also commit ba554c0).
    av_aes_block round_key[15];
    av_aes_block state[2];
    int rounds;
} AVAES;

/**
 * Initialize an AVAES context.
 * @param key_bits 128, 192 or 256
 * @param decrypt 0 for encryption, 1 for decryption
 */
int av_aes_init(struct AVAES *a, const uint8_t *key, int key_bits, int decrypt);

/**
 * Encrypt or decrypt a buffer using a previously initialized context.
 * @param count number of 16 byte blocks
 * @param dst destination array, can be equal to src
 * @param src source array, can be equal to dst
 * @param iv initialization vector for CBC mode, if NULL then ECB will be used
 * @param decrypt 0 for encryption, 1 for decryption
 */
void av_aes_crypt(struct AVAES *a, uint8_t *dst, const uint8_t *src, int count, uint8_t *iv, int decrypt);

#endif /* AVUTIL_AES_H */
