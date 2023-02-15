#include "include/helper.h"

#include <stdio.h>
#include <stdlib.h>
//#include <stdint.h>
#include <assert.h>
#include <string.h>

#include "secp256k1_schnorrsig.h"

const char* toHex(const unsigned char* bytes, long int count) {
    int i;
    char *converted = malloc(count * 2 + 1);
    for (i = 0; i < count; i++) {
        sprintf(&converted[i * 2], "%02x", bytes[i]);
    }
    converted[count * 2] = '\x00';
    return converted;
}

// Check that the sig has a low R value and will be less than 71 bytes
char SigHasLowR(const secp256k1_ecdsa_signature* sig)
{
    secp256k1_context *context = secp256k1_context_create(SECP256K1_CONTEXT_SIGN);
    unsigned char compact_sig[64];
    secp256k1_ecdsa_signature_serialize_compact(context, compact_sig, sig);

    // In DER serialization, all values are interpreted as big-endian, signed integers. The highest bit in the integer indicates
    // its signed-ness; 0 is positive, 1 is negative. When the value is interpreted as a negative integer, it must be converted
    // to a positive value by prepending a 0x00 byte so that the highest bit is 0. We can avoid this prepending by ensuring that
    // our highest bit is always 0, and thus we must check that the first byte is less than 0x80.
    return compact_sig[0] < 0x80;
}

const char* computeInternalKey(const unsigned char secretKey[32]) {
    // unsigned char sk[32] = "\x41\xf4\x1d\x69\x26\x0d\xf4\xcf\x27\x78\x26\xa9\xb6\x5a\x37\x17\xe4\xee\xdd\xbe\xed\xf6\x37\xf2\x12\xca\x09\x65\x76\x47\x93\x61";
    secp256k1_context *context = secp256k1_context_create(SECP256K1_CONTEXT_NONE);
    secp256k1_keypair keypair;
    secp256k1_xonly_pubkey internalKey;
    unsigned char internalKeyBytes[32];
    if (!secp256k1_keypair_create(context, &keypair, secretKey)) { return NULL; };
    if (!secp256k1_keypair_xonly_pub(context, &internalKey, NULL, &keypair)) { return NULL; };
    if (!secp256k1_xonly_pubkey_serialize(context, internalKeyBytes, &internalKey)) { return NULL; }
    return toHex(internalKeyBytes, 32);
}

uint32_t htobe32(uint32_t x) /* aka bswap_32 */
{
    return (((x & 0xff000000U) >> 24) | ((x & 0x00ff0000U) >>  8) |
            ((x & 0x0000ff00U) <<  8) | ((x & 0x000000ffU) << 24));
}

void WriteLE32(unsigned char* ptr, uint32_t x)
{
    uint32_t v = htobe32(x);
    memcpy(ptr, (char*)&v, 4);
}

const char* sign(const u_char secretKey[32], const u_char message[32], const u_char grind) {
    const size_t SIGNATURE_SIZE = 72;
    // TODO: Create context in the same way as bitcoin core
    secp256k1_context *secp256k1_context_sign = secp256k1_context_create(SECP256K1_CONTEXT_SIGN);
    const unsigned char test_case = 0;
    
    unsigned char extra_entropy[32] = {0};
    WriteLE32(extra_entropy, test_case);
    secp256k1_ecdsa_signature sig;
    uint32_t counter = 0;
    int ret = secp256k1_ecdsa_sign(secp256k1_context_sign, &sig, message, secretKey, secp256k1_nonce_function_rfc6979, (!grind && test_case) ? extra_entropy : NULL);
    
    // Grind for low R
    while (ret && !SigHasLowR(&sig) && grind) {
        WriteLE32(extra_entropy, ++counter);
        ret = secp256k1_ecdsa_sign(secp256k1_context_sign,  &sig, message, secretKey, secp256k1_nonce_function_rfc6979, extra_entropy);
    }
    assert(ret);
    size_t sigLen = SIGNATURE_SIZE;
    unsigned char *signature = malloc(sigLen);
    ret = secp256k1_ecdsa_signature_serialize_der(secp256k1_context_sign, signature, &sigLen, &sig);
    assert(ret);
    // Additional verification step to prevent using a potentially corrupted signature
    secp256k1_pubkey pk;
    ret = secp256k1_ec_pubkey_create(secp256k1_context_sign, &pk, secretKey);
    assert(ret);
    // secp256k1_context_no_precomp should be secp256k1_context_static
    ret = secp256k1_ecdsa_verify(secp256k1_context_no_precomp, &sig, message, &pk);
    assert(ret);
    return toHex(signature, sigLen);
}

const int verify(const u_char secretKey[32], const u_char message[32], const u_char *signature, const size_t signatureLen) {
    // TODO: Create context in the same way as bitcoin core
    secp256k1_context *secp256k1_context_sign = secp256k1_context_create(SECP256K1_CONTEXT_SIGN);
    secp256k1_context *secp256k1_context_verify = secp256k1_context_create(SECP256K1_CONTEXT_VERIFY);

    secp256k1_ecdsa_signature sig;
    int ret = secp256k1_ecdsa_signature_parse_der(secp256k1_context_no_precomp, &sig, signature, signatureLen);
    assert(ret);
    
    secp256k1_pubkey pk;
    ret = secp256k1_ec_pubkey_create(secp256k1_context_sign, &pk, secretKey);
    assert(ret);
    // secp256k1_context_no_precomp should be secp256k1_context_static
    ret = secp256k1_ecdsa_verify(secp256k1_context_verify, &sig, message, &pk);
    return ret;
}

const char* signSchnorr(const unsigned char secretKey[32], const unsigned char message[32]) {
    
    secp256k1_context *context = secp256k1_context_create(SECP256K1_CONTEXT_SIGN);
    secp256k1_keypair keypair;
    unsigned char sig[64];
    secp256k1_schnorrsig_extraparams extraparams = SECP256K1_SCHNORRSIG_EXTRAPARAMS_INIT;
    if (secp256k1_keypair_create(context, &keypair, secretKey) == 0) {
        return NULL;
    }

    int result = secp256k1_schnorrsig_sign(context, sig, message, &keypair, NULL);
    if (!result) {
        return NULL;
    }
    return toHex(sig, 64);
}

/*
 bool CKey::SignSchnorr(const uint256& hash, Span<unsigned char> sig, const uint256* merkle_root, const uint256& aux) const
 {
     assert(sig.size() == 64);
     secp256k1_keypair keypair;
     if (!secp256k1_keypair_create(secp256k1_context_sign, &keypair, begin())) return false;
     if (merkle_root) {
         secp256k1_xonly_pubkey pubkey;
         if (!secp256k1_keypair_xonly_pub(secp256k1_context_sign, &pubkey, nullptr, &keypair)) return false;
         unsigned char pubkey_bytes[32];
         if (!secp256k1_xonly_pubkey_serialize(secp256k1_context_sign, pubkey_bytes, &pubkey)) return false;
         uint256 tweak = XOnlyPubKey(pubkey_bytes).ComputeTapTweakHash(merkle_root->IsNull() ? nullptr : merkle_root);
         if (!secp256k1_keypair_xonly_tweak_add(secp256k1_context_static, &keypair, tweak.data())) return false;
     }
     bool ret = secp256k1_schnorrsig_sign32(secp256k1_context_sign, sig.data(), hash.data(), &keypair, aux.data());
     if (ret) {
         // Additional verification step to prevent using a potentially corrupted signature
         secp256k1_xonly_pubkey pubkey_verify;
         ret = secp256k1_keypair_xonly_pub(secp256k1_context_static, &pubkey_verify, nullptr, &keypair);
         ret &= secp256k1_schnorrsig_verify(secp256k1_context_static, sig.data(), hash.begin(), 32, &pubkey_verify);
     }
     if (!ret) memory_cleanse(sig.data(), sig.size());
     memory_cleanse(&keypair, sizeof(keypair));
     return ret;
 }
 */

const char* computeOutputKey(const unsigned char internalKeyBytes[32], unsigned char tweak[32]) {
    secp256k1_context *context = secp256k1_context_create(SECP256K1_CONTEXT_NONE);
    secp256k1_xonly_pubkey internalKey;
    secp256k1_pubkey outputKey; // Used for non keypair flow
    secp256k1_xonly_pubkey outputKeyXOnly;
    unsigned char outputKeyBytes[32];
    int keyParity;
    if (!secp256k1_xonly_pubkey_parse(context, &internalKey, internalKeyBytes)) { return NULL; };
    if (!secp256k1_xonly_pubkey_tweak_add(context, &outputKey, &internalKey, tweak)) { return NULL; };
    if (!secp256k1_xonly_pubkey_from_pubkey(context, &outputKeyXOnly, &keyParity, &outputKey)) { return NULL; };
    if (!secp256k1_xonly_pubkey_serialize(context, outputKeyBytes, &outputKeyXOnly)) { return NULL; };
    return toHex(outputKeyBytes, 32);
}
