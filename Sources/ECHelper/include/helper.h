#ifndef helper_h
#define helper_h

#include <stdlib.h>

const char* computeInternalKey(const unsigned char secretKey[32]);
const char* computeOutputKey(const unsigned char internalKeyBytes[32], unsigned char tweak[32]);
const char* sign(const unsigned char secretKey[32], const unsigned char message[32], const unsigned char grind);
const char* signSchnorr(const unsigned char secretKey[32], const unsigned char message[32]);
const int verify(const u_char secretKey[32], const u_char message[32], const u_char *signature, const size_t signatureLen);
#endif /* helper_h */
