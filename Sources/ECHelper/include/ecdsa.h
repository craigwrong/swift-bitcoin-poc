#ifndef ecdsa_h
#define ecdsa_h

#include <stdlib.h>

const int sign(u_char* signatureOut, size_t* signatureOutLength,const u_char* msg32, const u_char* secretKey32, const u_char grind);
const int verifySignatureWithPubKey(const u_char *signature, const size_t signatureLen, const u_char* msg32, const u_char* pubKey, const size_t pubKeyLen);
const int verifySignatureWithSecretKey(const u_char *signature, const size_t signatureLen, const u_char* msg32, const u_char* secretKey32);
#endif /* ecdsa_h */
