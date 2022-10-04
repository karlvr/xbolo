//
//  string.c
//  Mac OS X
//
//  Created by Karl von Randow on 8/04/20.
//  Copyright © 2020 Robert Chrzanowski. All rights reserved.
//

#include "string.h"

#include <string.h>

/**
 A function to copy a limited size from a UTF-8 string, ensuring the result is a valid UTF
 string, not cut-off in the middle of a multi-byte character.
 https://stackoverflow.com/a/27832746/1951952
 */
char* utf8cpy(char* dst, const char* src, size_t sizeDest) {
    if (sizeDest) {
        size_t sizeSrc = strlen(src); // number of bytes not including null
        while (sizeSrc >= sizeDest) {
            const char* lastByte = src + sizeSrc; // Initially, pointing to the null terminator.
            while (lastByte-- > src)
                if ((*lastByte & 0xC0) != 0x80) // Found the initial byte of the (potentially) multi-byte character (or found null).
                    break;

            sizeSrc = lastByte - src;
        }
        memcpy(dst, src, sizeSrc);
        dst[sizeSrc] = '\0';
    }
    return dst;
}
