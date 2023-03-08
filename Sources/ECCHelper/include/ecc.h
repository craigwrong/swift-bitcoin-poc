#ifndef ecc_h
#define ecc_h

#include <stdlib.h>

#include "secp256k1.h"

void cECCStart(void (*getRandBytes)(u_char*, const size_t));
void cECCStop();

#endif /* ecc_h */
