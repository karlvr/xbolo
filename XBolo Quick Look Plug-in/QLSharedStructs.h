//
//  QLSharedStructs.h
//  XBolo Quick Look Plug-in
//
//  Created by C.W. Betts on 4/12/16.
//  Copyright © 2016 Robert Chrzanowski. All rights reserved.
//

#ifndef QLSharedStructs_h
#define QLSharedStructs_h

#include <unistd.h>
#include <CoreGraphics/CoreGraphics.h>

#define MAPFILEIDENT        ("BMAPBOLO")
#define MAPFILEIDENTLEN     (8)
#define CURRENTMAPVERSION   (1)
#define MAXPILLS            (16)
#define MAXBASES            (16)
#define MAXSTARTS           (16)

/* terrain types */
enum {
  kWallTile         = 0,
  kRiverTile        = 1,
  kSwampTile        = 2,
  kCraterTile       = 3,
  kRoadTile         = 4,
  kForestTile       = 5,
  kRubbleTile       = 6,
  kGrassTile        = 7,
  kDamagedWallTile  = 8,
  kBoatTile         = 9,
  
  kMinedSwampTile   = 10,
  kMinedCraterTile  = 11,
  kMinedRoadTile    = 12,
  kMinedForestTile  = 13,
  kMinedRubbleTile  = 14,
  kMinedGrassTile   = 15,
} ;

/* file data structures */
struct BMAP_Preamble {
  uint8_t ident[8];  /* "BMAPBOLO" */
  uint8_t version;   /* currently 0 */
  uint8_t npills;    /* maximum 16 (at the moment) */
  uint8_t nbases;    /* maximum 16 (at the moment) */
  uint8_t nstarts;   /* maximum 16 (at the moment) */
} __attribute__((__packed__));

struct BMAP_PillInfo {
  uint8_t x;
  uint8_t y;
  uint8_t owner;   /* should be 0xFF except in speciality maps */
  uint8_t armour;  /* range 0-15 (dead pillbox = 0, full strength = 15) */
  uint8_t speed;   /* typically 50. Time between shots, in 20ms units
                    * Lower values makes the pillbox start off 'angry' */
} __attribute__((__packed__));

struct BMAP_BaseInfo {
  uint8_t x;
  uint8_t y;
  uint8_t owner;   /* should be 0xFF except in speciality maps */
  uint8_t armour;  /* initial stocks of base. Maximum value 90 */
  uint8_t shells;  /* initial stocks of base. Maximum value 90 */
  uint8_t mines;   /* initial stocks of base. Maximum value 90 */
} __attribute__((__packed__));

struct BMAP_StartInfo {
  uint8_t x;
  uint8_t y;
  uint8_t dir;  /* Direction towards land from this start. Range 0-15 */
} __attribute__((__packed__));

struct BMAP_Run {
  uint8_t datalen;  /* length of the data for this run
                     * INCLUDING this 4 byte header */
  uint8_t y;        /* y co-ordinate of this run. */
  uint8_t startx;   /* first square of the run */
  uint8_t endx;     /* last square of run + 1
                     * (ie first deep sea square after run)
                     *	uint8_t data[0xFF];*/  /* actual length of data is always much less than 0xFF */
} __attribute__((__packed__));

#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden")))
#endif

__private_extern int drawrun(CGContextRef context, struct BMAP_Run run, const void *buf);
__private_extern CGColorRef myGetRedColor(void);
__private_extern CGColorRef myGetGreenColor(void);
__private_extern CGColorRef myGetDarkGreenColor(void);
__private_extern CGColorRef myGetBlueColor(void);
__private_extern CGColorRef myGetDarkBlueColor(void);
__private_extern CGColorRef myGetYellowColor(void);
__private_extern CGColorRef myGetCyanColor(void);
__private_extern CGColorRef myGetDarkCyanColor(void);
__private_extern CGColorRef myGetBrownColor(void);
__private_extern CGColorRef myGetLightBrownColor(void);
__private_extern CGColorRef myGetVeryLightBrownColor(void);
__private_extern CGColorRef myGetDarkBrownColor(void);
__private_extern CGColorRef myGetGreyColor(void);
__private_extern CGColorRef myGetBlackColor(void);

#endif /* QLSharedStructs_h */
