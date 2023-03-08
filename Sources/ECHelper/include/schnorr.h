#ifndef schnorr_h
#define schnorr_h

#include <stdlib.h>

//const char* computeInternalKey(const u_char*);
//const char* computeOutputKey(const u_char[32], const u_char[32]);
const int signSchnorr(void (*computeTapTweakHash)(u_char*, const u_char*, const u_char*), u_char* sigOut64, u_char* sigOutLen, const u_char* msg32, const u_char* merkleRoot32, const u_char forceTweak, const u_char* aux32, const u_char* privKey32);
const int verifySchnorr(const u_char* msg32, const u_char* sigBytes64, const u_char* pubKey32);
const int createTapTweak(void (*computeTapTweakHash)(u_char*, const u_char*, const u_char*), u_char* tweakedKeyOut, u_char* tweakedKeyOutLen, int* parityOut, const u_char* pubKey32, const u_char* merkleRoot32);
const int checkTapTweak(void (*computeTapTweakHash)(u_char*, const u_char*, const u_char*), const u_char* pubKey32, const u_char* tweakedKey32, const u_char* merkleRoot32, const u_char parity);
#endif /* schnorr_h */
