#include <stdio.h>
#include <memory.h>
#include "aes.h"
#include "Platform.h"

#define FFSWAP(type,a,b) do{type SWAP_tmp= b; b= a; a= SWAP_tmp;}while(0)
#define FF_ARRAY_ELEMS(a) (sizeof(a) / sizeof((a)[0]))

#define MKTAG(a,b,c,d) ((a) | ((b) << 8) | ((c) << 16) | ((unsigned)(d) << 24))
#define MKBETAG(a,b,c,d) ((d) | ((c) << 8) | ((b) << 16) | ((unsigned)(a) << 24))

#define AV_NE(be, le) (le)

static const uint8_t rcon[10] = {
  0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36
};

static uint8_t     sbox[256];
static uint8_t inv_sbox[256];
#if CONFIG_SMALL
static uint32_t enc_multbl[1][256];
static uint32_t dec_multbl[1][256];
#else
static uint32_t enc_multbl[4][256];
static uint32_t dec_multbl[4][256];
#endif

#define ROT(x, s) ((x << s) | (x >> (32-s)))

static void addkey(av_aes_block *dst, const av_aes_block *src,
                          const av_aes_block *round_key)
{
//    dst->u64[0] = src->u64[0] ^ round_key->u64[0];
//    dst->u64[1] = src->u64[1] ^ round_key->u64[1];
	dst->u64[ 0] = src->u64[ 0] ^ round_key->u64[ 0];
	dst->u64[ 1] = src->u64[ 1] ^ round_key->u64[ 1];
	dst->u64[ 2] = src->u64[ 2] ^ round_key->u64[ 2];
	dst->u64[ 3] = src->u64[ 3] ^ round_key->u64[ 3];
	dst->u64[ 4] = src->u64[ 4] ^ round_key->u64[ 4];
	dst->u64[ 5] = src->u64[ 5] ^ round_key->u64[ 5];
	dst->u64[ 6] = src->u64[ 6] ^ round_key->u64[ 6];
	dst->u64[ 7] = src->u64[ 7] ^ round_key->u64[ 7];
	dst->u64[ 8] = src->u64[ 8] ^ round_key->u64[ 8];
	dst->u64[ 9] = src->u64[ 9] ^ round_key->u64[ 9];
	dst->u64[10] = src->u64[10] ^ round_key->u64[10];
	dst->u64[11] = src->u64[11] ^ round_key->u64[11];
	dst->u64[12] = src->u64[12] ^ round_key->u64[12];
	dst->u64[13] = src->u64[13] ^ round_key->u64[13];
	dst->u64[14] = src->u64[14] ^ round_key->u64[14];
	dst->u64[15] = src->u64[15] ^ round_key->u64[15];
}

static void addkey_s(av_aes_block *dst, const uint8_t *src,
                            const av_aes_block *round_key)
{
//   dst->u64[0] = AV_RN64(src)     ^ round_key->u64[0];
//   dst->u64[1] = AV_RN64(src + 8) ^ round_key->u64[1];
	dst->u64[ 0] = src[ 0] ^ round_key->u64[ 0];
	dst->u64[ 1] = src[ 1] ^ round_key->u64[ 1];
	dst->u64[ 2] = src[ 2] ^ round_key->u64[ 2];
	dst->u64[ 3] = src[ 3] ^ round_key->u64[ 3];
	dst->u64[ 4] = src[ 4] ^ round_key->u64[ 4];
	dst->u64[ 5] = src[ 5] ^ round_key->u64[ 5];
	dst->u64[ 6] = src[ 6] ^ round_key->u64[ 6];
	dst->u64[ 7] = src[ 7] ^ round_key->u64[ 7];
	dst->u64[ 8] = src[ 8] ^ round_key->u64[ 8];
	dst->u64[ 9] = src[ 9] ^ round_key->u64[ 9];
	dst->u64[10] = src[10] ^ round_key->u64[10];
	dst->u64[11] = src[11] ^ round_key->u64[11];
	dst->u64[12] = src[12] ^ round_key->u64[12];
	dst->u64[13] = src[13] ^ round_key->u64[13];
	dst->u64[14] = src[14] ^ round_key->u64[14];
	dst->u64[15] = src[15] ^ round_key->u64[15];
}

static void addkey_d(uint8_t *dst, const av_aes_block *src,
                            const av_aes_block *round_key)
{
//   AV_WN64(dst,     src->u64[0] ^ round_key->u64[0]);
//   AV_WN64(dst + 8, src->u64[1] ^ round_key->u64[1]);
	dst[ 0] = src->u64[ 0] ^ round_key->u64[ 0];
	dst[ 1] = src->u64[ 1] ^ round_key->u64[ 1];
	dst[ 2] = src->u64[ 2] ^ round_key->u64[ 2];
	dst[ 3] = src->u64[ 3] ^ round_key->u64[ 3];
	dst[ 4] = src->u64[ 4] ^ round_key->u64[ 4];
	dst[ 5] = src->u64[ 5] ^ round_key->u64[ 5];
	dst[ 6] = src->u64[ 6] ^ round_key->u64[ 6];
	dst[ 7] = src->u64[ 7] ^ round_key->u64[ 7];
	dst[ 8] = src->u64[ 8] ^ round_key->u64[ 8];
	dst[ 9] = src->u64[ 9] ^ round_key->u64[ 9];
	dst[10] = src->u64[10] ^ round_key->u64[10];
	dst[11] = src->u64[11] ^ round_key->u64[11];
	dst[12] = src->u64[12] ^ round_key->u64[12];
	dst[13] = src->u64[13] ^ round_key->u64[13];
	dst[14] = src->u64[14] ^ round_key->u64[14];
	dst[15] = src->u64[15] ^ round_key->u64[15];
}

static void subshift(av_aes_block s0[2], int s, const uint8_t *box)
{
    av_aes_block *s1 = (av_aes_block *) (s0[0].u8 - s);
    av_aes_block *s3 = (av_aes_block *) (s0[0].u8 + s);

    s0[0].u8[ 0] = box[s0[1].u8[ 0]];
    s0[0].u8[ 4] = box[s0[1].u8[ 4]];
    s0[0].u8[ 8] = box[s0[1].u8[ 8]];
    s0[0].u8[12] = box[s0[1].u8[12]];
    s1[0].u8[ 3] = box[s1[1].u8[ 7]];
    s1[0].u8[ 7] = box[s1[1].u8[11]];
    s1[0].u8[11] = box[s1[1].u8[15]];
    s1[0].u8[15] = box[s1[1].u8[ 3]];
    s0[0].u8[ 2] = box[s0[1].u8[10]];
    s0[0].u8[10] = box[s0[1].u8[ 2]];
    s0[0].u8[ 6] = box[s0[1].u8[14]];
    s0[0].u8[14] = box[s0[1].u8[ 6]];
    s3[0].u8[ 1] = box[s3[1].u8[13]];
    s3[0].u8[13] = box[s3[1].u8[ 9]];
    s3[0].u8[ 9] = box[s3[1].u8[ 5]];
    s3[0].u8[ 5] = box[s3[1].u8[ 1]];
}

static int mix_core(uint32_t multbl[][256], int a, int b, int c, int d){
#if CONFIG_SMALL
    return multbl[0][a] ^ ROT(multbl[0][b], 8) ^ ROT(multbl[0][c], 16) ^ ROT(multbl[0][d], 24);
#else
    return multbl[0][a] ^ multbl[1][b] ^ multbl[2][c] ^ multbl[3][d];
#endif
}

static void mix(av_aes_block state[2], uint32_t multbl[][256], int s1, int s3){
    uint8_t (*src)[4] = state[1].u8x4;
    state[0].u32[0] = mix_core(multbl, src[0][0], src[s1  ][1], src[2][2], src[s3  ][3]);
    state[0].u32[1] = mix_core(multbl, src[1][0], src[s3-1][1], src[3][2], src[s1-1][3]);
    state[0].u32[2] = mix_core(multbl, src[2][0], src[s3  ][1], src[0][2], src[s1  ][3]);
    state[0].u32[3] = mix_core(multbl, src[3][0], src[s1-1][1], src[1][2], src[s3-1][3]);
}

static void crypt(AVAES *a, int s, const uint8_t *sbox,
                         uint32_t multbl[][256])
{
    int r;

    for (r = a->rounds - 1; r > 0; r--) {
        mix(a->state, multbl, 3 - s, 1 + s);
        addkey(&a->state[1], &a->state[0], &a->round_key[r]);
    }

    subshift(&a->state[0], s, sbox);
}

void av_aes_crypt(AVAES *a, uint8_t *dst, const uint8_t *src,
                  int count, uint8_t *iv, int decrypt)
{
    while (count--) {
        addkey_s(&a->state[1], src, &a->round_key[a->rounds]);
        if (decrypt) {
            crypt(a, 0, inv_sbox, dec_multbl);
            if (iv) {
                addkey_s(&a->state[0], iv, &a->state[0]);
                memcpy(iv, src, 16);
            }
            addkey_d(dst, &a->state[0], &a->round_key[0]);
        } else {
            if (iv)
                addkey_s(&a->state[1], iv, &a->state[1]);
            crypt(a, 2, sbox, enc_multbl);
            addkey_d(dst, &a->state[0], &a->round_key[0]);
            if (iv)
                memcpy(iv, dst, 16);
        }
        src += 16;
        dst += 16;
    }
}

static void init_multbl2(uint32_t tbl[][256], const int c[4],
                         const uint8_t *log8, const uint8_t *alog8,
                         const uint8_t *sbox)
{
    int i;

    for (i = 0; i < 256; i++) {
        int x = sbox[i];
        if (x) {
            int k, l, m, n;
            x = log8[x];
            k = alog8[x + log8[c[0]]];
            l = alog8[x + log8[c[1]]];
            m = alog8[x + log8[c[2]]];
            n = alog8[x + log8[c[3]]];
            tbl[0][i] = AV_NE(MKBETAG(k,l,m,n), MKTAG(k,l,m,n));
#if !CONFIG_SMALL
            tbl[1][i] = ROT(tbl[0][i], 8);
            tbl[2][i] = ROT(tbl[0][i], 16);
            tbl[3][i] = ROT(tbl[0][i], 24);
#endif
        }
    }
}

// this is based on the reference AES code by Paulo Barreto and Vincent Rijmen
int av_aes_init(AVAES *a, const uint8_t *key, int key_bits, int decrypt)
{
		static const int c1[4] = { 0xe, 0x9, 0xd, 0xb };
		static const int c2[4] = { 0x2, 0x1, 0x1, 0x3 };

    int i, j, t, rconpointer = 0;
    uint8_t tk[8][4];
    int KC = key_bits >> 5;
    int rounds = KC + 6;
    uint8_t log8[256];
    uint8_t alog8[512];

    if (!enc_multbl[FF_ARRAY_ELEMS(enc_multbl)-1][FF_ARRAY_ELEMS(enc_multbl[0])-1]) {
        j = 1;
        for (i = 0; i < 255; i++) {
            alog8[i] = alog8[i + 255] = j;
            log8[j] = i;
            j ^= j + j;
            if (j > 255)
                j ^= 0x11B;
        }
        for (i = 0; i < 256; i++) {
            j = i ? alog8[255 - log8[i]] : 0;
            j ^= (j << 1) ^ (j << 2) ^ (j << 3) ^ (j << 4);
            j = (j ^ (j >> 8) ^ 99) & 255;
            inv_sbox[j] = i;
            sbox[i] = j;
        }
        init_multbl2(dec_multbl, c1, log8, alog8, inv_sbox);
        init_multbl2(enc_multbl, c2, log8, alog8, sbox);
    }

    if (key_bits != 128 && key_bits != 192 && key_bits != 256)
        return -1;

    a->rounds = rounds;

    memcpy(tk, key, KC * 4);
    memcpy(a->round_key[0].u8, key, KC * 4);

    for (t = KC * 4; t < (rounds + 1) * 16; t += KC * 4) {
        for (i = 0; i < 4; i++)
            tk[0][i] ^= sbox[tk[KC - 1][(i + 1) & 3]];
        tk[0][0] ^= rcon[rconpointer++];

        for (j = 1; j < KC; j++) {
            if (KC != 8 || j != KC >> 1)
                for (i = 0; i < 4; i++)
                    tk[j][i] ^= tk[j - 1][i];
            else
                for (i = 0; i < 4; i++)
                    tk[j][i] ^= sbox[tk[j - 1][i]];
        }

        memcpy(a->round_key[0].u8 + t, tk, KC * 4);
    }

    if (decrypt) {
        for (i = 1; i < rounds; i++) {
            av_aes_block tmp[3];
            tmp[2] = a->round_key[i];
            subshift(&tmp[1], 0, sbox);
            mix(tmp, dec_multbl, 1, 3);
            a->round_key[i] = tmp[0];
        }
    } else {
        for (i = 0; i < (rounds + 1) >> 1; i++) {
            FFSWAP(av_aes_block, a->round_key[i], a->round_key[rounds-i]);
        }
    }

    return 0;
}
