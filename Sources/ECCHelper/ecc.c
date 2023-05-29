#include "ecc.h"

#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include <secp256k1.h>

//static
const secp256k1_context *secp256k1_context_static; // This is included in newer versions of lib secp256k1
secp256k1_context* secp256k1_context_sign = NULL;

void cECCStart(void (*getRandBytes)(u_char*, const size_t)) {
    secp256k1_context_static = secp256k1_context_no_precomp;

    assert(secp256k1_context_sign == NULL);

    secp256k1_context *ctx = secp256k1_context_create(SECP256K1_CONTEXT_NONE);
    assert(ctx != NULL);

    {
        u_char* vseed32 = malloc(32);
        getRandBytes(vseed32, 32);
        int ret = secp256k1_context_randomize(ctx, vseed32);
        assert(ret);
    }

    secp256k1_context_sign = ctx;
}

void cECCStop() {
    secp256k1_context *ctx = secp256k1_context_sign;
    secp256k1_context_sign = NULL;

    if (ctx) {
        secp256k1_context_destroy(ctx);
    }
}

int createPrivKey(void (*getRandBytes)(u_char*, const size_t), u_char *privKeyOut32, size_t* privKeyLenOut) {
    u_char* privKey32 = malloc(KEY_LEN);
    do {
        getRandBytes(privKey32, KEY_LEN);
    } while (!secp256k1_ec_seckey_verify(secp256k1_context_sign, privKey32));
    memcpy(privKeyOut32, privKey32, KEY_LEN);
    *privKeyLenOut = KEY_LEN;
    return 1;
}

int getPubKey(u_char *pubKeyOut, size_t* pubKeyLenOut, const u_char *privKey32, const int compress) {
    assert(secp256k1_context_static != NULL);
    secp256k1_pubkey pubKey;
    if (!secp256k1_ec_pubkey_create(secp256k1_context_sign, &pubKey, privKey32)) return 0;
    size_t pubKeyLen = PUBKEY_MAX_LEN;
    u_char* pubKeyData = malloc(pubKeyLen);
    int result = secp256k1_ec_pubkey_serialize(secp256k1_context_static, pubKeyData, &pubKeyLen, &pubKey, compress ? SECP256K1_EC_COMPRESSED : SECP256K1_EC_UNCOMPRESSED);
    if (!result) return 0;
    memcpy(pubKeyOut, pubKeyData, pubKeyLen);
    *pubKeyLenOut = pubKeyLen;
    return result;
}
