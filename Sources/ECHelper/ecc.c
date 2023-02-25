#include "ecc.h"

#include <stdlib.h>
#include <assert.h>

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
