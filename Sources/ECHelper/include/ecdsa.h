#ifndef ecdsa_h
#define ecdsa_h

#include <stdlib.h>

int sign(u_char*, size_t*, const u_char[32], const u_char secretKey[32], const u_char grind);
const int verifySignature(const u_char*, const size_t, const u_char message[32], const u_char secretKey[32]);
#endif /* ecdsa_h */
