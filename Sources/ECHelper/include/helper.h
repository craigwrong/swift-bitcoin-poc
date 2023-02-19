#ifndef helper_h
#define helper_h

#include <stdlib.h>

const char* computeInternalKey(const u_char*);
const char* computeOutputKey(const u_char[32], const u_char[32]);
int cSign(u_char*, size_t*, const u_char[32], const u_char secretKey[32], const u_char grind);
const char* signSchnorr(const u_char[32], const u_char[32]);
const int verify(const u_char*, const size_t, const u_char message[32], const u_char secretKey[32]);

#endif /* helper_h */
