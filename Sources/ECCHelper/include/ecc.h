#ifndef ecc_h
#define ecc_h

#include <stdlib.h>

#include "secp256k1.h"

static const size_t KEY_LEN = 32;
static const size_t PUBKEY_MAX_LEN = 65; // Uncompressed
static const size_t PUBKEY_COMPRESSED_LEN = 33;

void cECCStart(void (*getRandBytes)(u_char*, const size_t));
void cECCStop();
int createPrivKey(void (*getRandBytes)(u_char*, const size_t), u_char *privKeyOut32, size_t* privKeyLenOut);
int getPubKey(u_char *pubKeyOut, size_t* pubKeyLenOut, const u_char *privKey32, const int compress);
#endif /* ecc_h */
