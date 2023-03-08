#include "schnorr.h"
#include "ecc.h"

#include <stdio.h>
#include <assert.h>
#include <string.h>

#include <secp256k1_schnorrsig.h>

const size_t KEY_LEN = 32;
const size_t HASH_LEN = 32;
const size_t SIG_LEN = 64;

extern secp256k1_context* secp256k1_context_static;
extern secp256k1_context* secp256k1_context_sign;

const int signSchnorr(void (*computeTapTweakHash)(u_char*, const u_char*, const u_char*), u_char* sigOut64, u_char* sigLenOut, const u_char* msg32, const u_char* merkleRoot32, const u_char forceTweak, const u_char* aux32, const u_char* privKey32) {
    secp256k1_keypair keypair;
    assert(secp256k1_context_sign != NULL);
    if (!secp256k1_keypair_create(secp256k1_context_sign, &keypair, privKey32)) return 0;

    if (merkleRoot32 != NULL || forceTweak) {
        secp256k1_xonly_pubkey pubKey;
        if (!secp256k1_keypair_xonly_pub(secp256k1_context_sign, &pubKey, NULL, &keypair)) return 0;
        
        u_char* pubKey32 = malloc(KEY_LEN);
        if (!secp256k1_xonly_pubkey_serialize(secp256k1_context_sign, pubKey32, &pubKey)) return 0;
        
        u_char* tweak32 = malloc(HASH_LEN);
        computeTapTweakHash(tweak32, pubKey32, merkleRoot32);

        if (!secp256k1_keypair_xonly_tweak_add(secp256k1_context_static, &keypair, tweak32)) return 0;
    }
    
    // Do the signing.
    u_char* sigOutTmp64 = malloc(SIG_LEN);
    int result = /* secp256k1_schnorrsig_sign32() */ secp256k1_schnorrsig_sign(secp256k1_context_sign, sigOutTmp64, msg32, &keypair, aux32);

    // Additional verification step to prevent using a potentially corrupted signature
    secp256k1_xonly_pubkey pubKeyVerify;
    if (result) {
        result = secp256k1_keypair_xonly_pub(secp256k1_context_static, &pubKeyVerify, NULL, &keypair);
    }
    if (result) {
        result = secp256k1_schnorrsig_verify(secp256k1_context_static, sigOutTmp64, msg32, HASH_LEN, &pubKeyVerify);
    }
    if (result) {
        memcpy(sigOut64, sigOutTmp64, SIG_LEN);
        *sigLenOut = SIG_LEN;
    }
    memset(sigOutTmp64, 0, SIG_LEN);
    memset(&keypair, 0, sizeof(keypair));
    return result;
}

const int createTapTweak(void (*computeTapTweakHash)(u_char*, const u_char*, const u_char*), u_char* tweakedKeyOut, u_char* tweakedKeyOutLen, int* parityOut, const u_char* pubKey32, const u_char* merkleRoot32) {
    secp256k1_xonly_pubkey base_point;
    if (!secp256k1_xonly_pubkey_parse(secp256k1_context_static, &base_point, pubKey32)) return 0;
    secp256k1_pubkey out;
    u_char* tweak = malloc(32);
    computeTapTweakHash(tweak, pubKey32, merkleRoot32);
    if (!secp256k1_xonly_pubkey_tweak_add(secp256k1_context_static, &out, &base_point, tweak)) return 0;
    int parity = -1;
    secp256k1_xonly_pubkey out_xonly;
    if (!secp256k1_xonly_pubkey_from_pubkey(secp256k1_context_static, &out_xonly, &parity, &out)) return 0;
    u_char pubkey_bytes[32];
    secp256k1_xonly_pubkey_serialize(secp256k1_context_static, pubkey_bytes, &out_xonly);
    assert(parity == 0 || parity == 1);
        
    // Result output
    memcpy(tweakedKeyOut, pubkey_bytes, KEY_LEN);
    *tweakedKeyOutLen = KEY_LEN;
    *parityOut = parity;
    return 1;
}

const int checkTapTweak(void (*computeTapTweakHash)(u_char*, const u_char*, const u_char*), const u_char* pubKey32, const u_char* tweakedKey32, const u_char* merkleRoot32, const u_char parity) {
    const secp256k1_context *secp256k1_context_static = secp256k1_context_no_precomp;
    
    secp256k1_xonly_pubkey pubKey;
    if (!secp256k1_xonly_pubkey_parse(secp256k1_context_static, &pubKey, pubKey32)) return 0;
    u_char* tweak = malloc(32);
    computeTapTweakHash(tweak, pubKey32, merkleRoot32);
    
    const int result = secp256k1_xonly_pubkey_tweak_add_check(secp256k1_context_static, tweakedKey32, parity, &pubKey, tweak);
    return result;
}

const char* toHex(const u_char* bytes, long int count) {
    int i;
    char *converted = malloc(count * 2 + 1);
    for (i = 0; i < count; i++) {
        sprintf(&converted[i * 2], "%02x", bytes[i]);
    }
    converted[count * 2] = '\x00';
    return converted;
}

const char* computeInternalKey(const u_char privKey[32]) {
    // u_char privKey32 = "\x41\xf4\x1d\x69\x26\x0d\xf4\xcf\x27\x78\x26\xa9\xb6\x5a\x37\x17\xe4\xee\xdd\xbe\xed\xf6\x37\xf2\x12\xca\x09\x65\x76\x47\x93\x61";
    const secp256k1_context *context = secp256k1_context_static;
    secp256k1_keypair keypair;
    secp256k1_xonly_pubkey internalKey;
    u_char internalKeyBytes[32];
    if (!secp256k1_keypair_create(context, &keypair, privKey)) { return NULL; };
    if (!secp256k1_keypair_xonly_pub(context, &internalKey, NULL, &keypair)) { return NULL; };
    if (!secp256k1_xonly_pubkey_serialize(context, internalKeyBytes, &internalKey)) { return NULL; }
    return toHex(internalKeyBytes, 32);
}

const char* computeOutputKey(const u_char internalKeyBytes[32], const u_char tweak[32]) {
    const secp256k1_context *context = secp256k1_context_static;
    secp256k1_xonly_pubkey internalKey;
    secp256k1_pubkey outputKey; // Used for non keypair flow
    secp256k1_xonly_pubkey outputKeyXOnly;
    u_char outputKeyBytes[32];
    int keyParity;
    if (!secp256k1_xonly_pubkey_parse(context, &internalKey, internalKeyBytes)) { return NULL; };
    if (!secp256k1_xonly_pubkey_tweak_add(context, &outputKey, &internalKey, tweak)) { return NULL; };
    if (!secp256k1_xonly_pubkey_from_pubkey(context, &outputKeyXOnly, &keyParity, &outputKey)) { return NULL; };
    if (!secp256k1_xonly_pubkey_serialize(context, outputKeyBytes, &outputKeyXOnly)) { return NULL; };
    return toHex(outputKeyBytes, 32);
}

const int verifySchnorr(const u_char* msg32, const u_char* sigBytes64, const u_char* pubKey32) {

    secp256k1_xonly_pubkey pubkey;
    if (!secp256k1_xonly_pubkey_parse(secp256k1_context_static, &pubkey, pubKey32)) return 0;
    
    return secp256k1_schnorrsig_verify(secp256k1_context_static, sigBytes64, msg32, 32, &pubkey);
}
