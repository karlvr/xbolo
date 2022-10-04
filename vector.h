/*
 *  vector.h
 *  XBolo
 *
 *  Created by Robert Chrzanowski.
 *  Copyright 2004 Robert Chrzanowski. All rights reserved.
 *
 */

#ifndef __VECTOR__
#define __VECTOR__

#include <stdint.h>
#include <stdbool.h>
#include <math.h>
#if defined(USE_SIMD_H) && USE_SIMD_H
#include <simd/simd.h>
#endif

#define INT16RADIX     (256)
#define INT32RADIX     (65536)

#if !(defined(USE_SIMD_H) && USE_SIMD_H)
struct Vec2f {
  float x;
  float y;
} ;

struct Vec2i32 {
  int32_t x;
  int32_t y;
} ;
#endif

struct Vec2i16 {
  int16_t x;
  int16_t y;
} ;

struct Vec2i8 {
  int8_t x;
  int8_t y;
} ;

struct Vec2u8 {
  uint8_t x;
  uint8_t y;
} ;

#if defined(USE_SIMD_H) && USE_SIMD_H
typedef simd_packed_float2 Vec2f;
typedef simd_packed_int2 Vec2i32;
#else
typedef struct Vec2f Vec2f;
typedef struct Vec2i32 Vec2i32;
#endif
typedef struct Vec2i16 Vec2i16;
typedef struct Vec2i8 Vec2i8;

float u16tof(uint16_t s);
uint16_t ftou16(float s);
float i16tof(int16_t s);
int16_t ftoi16(float s);

Vec2f make2f(float x, float y);
#if defined(USE_SIMD_H) && USE_SIMD_H
#define neg2f(v) -(v)
#define add2f(v1, v2) ((v1) + (v2))
#define sub2f(v1, v2) ((v1) - (v2))
#define mul2f(v1, s) ((v1) * (s))
#define div2f(v1, s) ((v1) / (s))
#define dot2f vector_dot
#define mag2f vector_length
#define unit2f vector_normalize
#else
Vec2f neg2f(Vec2f v);
Vec2f add2f(Vec2f v1, Vec2f v2);
Vec2f sub2f(Vec2f v1, Vec2f v2);
Vec2f mul2f(Vec2f v, float s);
Vec2f div2f(Vec2f v, float s);
float mag2f(Vec2f v);
Vec2f unit2f(Vec2f v);
float dot2f(Vec2f v1, Vec2f v2);
#endif
Vec2f prj2f(Vec2f v1, Vec2f v2);
float cmp2f(Vec2f v1, Vec2f v2);
bool isequal2f(Vec2f v1, Vec2f v2);
Vec2f tan2f(float theta);
float _atan2f(Vec2f dir);

Vec2i32 make2i32(int32_t x, int32_t y);
#if defined(USE_SIMD_H) && USE_SIMD_H
#define neg2i32(v) -(v)
#define add2i32(v1, v2) ((v1) + (v2))
#define sub2i32(v1, v2) ((v1) - (v2))
#define mul2i32(v1, s) ((v1) * (s))
#define div2i32(v1, s) ((v1) / (s))
#else
Vec2i32 neg2i32(Vec2i32 v);
Vec2i32 add2i32(Vec2i32 v1, Vec2i32 v2);
Vec2i32 sub2i32(Vec2i32 v1, Vec2i32 v2);
Vec2i32 mul2i32(Vec2i32 v, int32_t s);
Vec2i32 div2i32(Vec2i32 v, int32_t s);
#endif
int32_t dot2i32(Vec2i32 v1, Vec2i32 v2);
int32_t mag2i32(Vec2i32 v);
Vec2i32 prj2i32(Vec2i32 v1, Vec2i32 v2);
int32_t cmp2i32(Vec2i32 v1, Vec2i32 v2);
bool isequal2i32(Vec2i32 v1, Vec2i32 v2);
Vec2i32 tan2i32(uint8_t dir);
Vec2i32 scale2i32(uint8_t dir, int32_t scale);
Vec2i16 c2i32to2i16(Vec2i32 v);

Vec2i16 make2i16(int16_t x, int16_t y);
Vec2i16 neg2i16(Vec2i16 v);
Vec2i16 add2i16(Vec2i16 v1, Vec2i16 v2);
Vec2i16 sub2i16(Vec2i16 v1, Vec2i16 v2);
Vec2i16 mul2i16(Vec2i16 v, int16_t s);
Vec2i16 div2i16(Vec2i16 v, int16_t s);
int16_t dot2i16(Vec2i16 v1, Vec2i16 v2);
int16_t mag2i16(Vec2i16 v);
Vec2i16 prj2i16(Vec2i16 v1, Vec2i16 v2);
int16_t cmp2i16(Vec2i16 v1, Vec2i16 v2);
bool isequal2i16(Vec2i16 v1, Vec2i16 v2);
Vec2i16 tan2i16(uint8_t dir);
Vec2i16 scale2i16(uint8_t dir, int16_t scale);
Vec2i8 c2i16to2i8(Vec2i16 v);

Vec2i8 make2i8(int8_t x, int8_t y);
bool isequal2i8(Vec2i8 v1, Vec2i8 v2);

extern const float kPif;
extern const float k2Pif;

#define make2f __make2f
#define _atan2f ___atan2f
#define tan2f __tan2f
#define prj2f __prj2f
#define cmp2f __cmp2f
#define isequal2f __isequal2f

static inline Vec2f __make2f(float x, float y) {
  Vec2f r;
  r.x = x;
  r.y = y;
  return r;
}

static inline Vec2f __prj2f(Vec2f v1, Vec2f v2) {
  return mul2f(v1, dot2f(v1, v2)/dot2f(v1, v1));
}

static inline float __cmp2f(Vec2f v1, Vec2f v2) {
  return dot2f(v1, v2)/mag2f(v1);
}

static inline bool __isequal2f(Vec2f v1, Vec2f v2) {
  return v1.x == v2.x && v1.y == v2.y;
}

static inline Vec2f __tan2f(float theta) {
  float cosVal, sinVal;
  __sincosf(theta, &sinVal, &cosVal);
  return make2f(cosVal, sinVal);
}

static inline float ___atan2f(Vec2f dir) {
  return atan2f(dir.y, dir.x);
}

#endif  /* __VECTOR__ */
