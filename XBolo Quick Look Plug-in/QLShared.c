//
//  QLShared.m
//  XBolo Quick Look Plug-in
//
//  Created by C.W. Betts on 4/12/16.
//  Copyright © 2016 Robert Chrzanowski. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include "QLSharedStructs.h"

static int setterraincolor(CGContextRef context, BoloTerrainTypes tile);
static int readnibble(const void *buf, size_t i);

int drawrun(CGContextRef context, struct BMAP_Run run, const void *buf) {
  int i;
  int x;
  int offset;
  
  x = run.startx;
  offset = 0;
  
  while (x < run.endx) {
    int len;
    
    if (sizeof(struct BMAP_Run) + (offset + 2)/2 > run.datalen) {
      return -1;
    }
    
    len = readnibble(buf, offset++);
    
    if (len >= 0 && len <= 7) {  /* this is a sequence of different tiles */
      len += 1;
      
      if (sizeof(struct BMAP_Run) + (offset + len + 1)/2 > run.datalen) {
        return -1;
      }
      
      for (i = 0; i < len; i++) {
        /* draw terrain */
        setterraincolor(context, readnibble(buf, offset++));
        CGContextFillRect(context, CGRectMake(x++, run.y, 1, 1));
      }
    }
    else if (len >= 8 && len <= 15) {  /* this is a sequence of like tiles */
      len -= 6;
      
      if (sizeof(struct BMAP_Run) + (offset + 2)/2 > run.datalen) {
        return -1;
      }
      
      /* draw terrain */
      setterraincolor(context, readnibble(buf, offset++));
      CGContextFillRect(context, CGRectMake(x, run.y, len, 1));
      x += len;
    }
    else {
      return -1;
    }
  }
  
  if (sizeof(struct BMAP_Run) + (offset + 1)/2 != run.datalen) {
    return -1;
  }
  
  return 0;
}

int setterraincolor(CGContextRef context, BoloTerrainTypes tile) {
  switch (tile) {
    case kWallTile:  /* wall */
      CGContextSetFillColorWithColor(context, myGetBrownColor());
      return 0;
      
    case kRiverTile:  /* river */
      CGContextSetFillColorWithColor(context, myGetCyanColor());
      return 0;
      
    case kSwampTile:  /* swamp */
    case kMinedSwampTile:  /* mined swamp */
      CGContextSetFillColorWithColor(context, myGetDarkCyanColor());
      return 0;
      
    case kCraterTile:  /* crater */
    case kMinedCraterTile:  /* mined crater */
      CGContextSetFillColorWithColor(context, myGetDarkBrownColor());
      return 0;
      
    case kRoadTile:  /* road */
    case kMinedRoadTile:  /* mined road */
      CGContextSetFillColorWithColor(context, myGetBlackColor());
      return 0;
      
    case kForestTile:  /* forest */
    case kMinedForestTile:  /* mined forest */
      CGContextSetFillColorWithColor(context, myGetDarkGreenColor());
      return 0;
      
    case kRubbleTile:  /* rubble */
    case kMinedRubbleTile:  /* mined rubble */
      CGContextSetFillColorWithColor(context, myGetVeryLightBrownColor());
      return 0;
      
    case kGrassTile:  /* grass */
    case kMinedGrassTile:  /* mined grass */
      CGContextSetFillColorWithColor(context, myGetGreenColor());
      return 0;
      
    case kDamagedWallTile:  /* damaged wall */
      CGContextSetFillColorWithColor(context, myGetLightBrownColor());
      return 0;
      
    case kBoatTile:  /* river w/boat */
      CGContextSetFillColorWithColor(context, myGetDarkBlueColor());
      return 0;
      
    default:
      return -1;
  }
}

int readnibble(const void *buf, size_t i) {
  return i%2 ? *(uint8_t *)(buf + i/2) & 0x0f : (*(uint8_t *)(buf + i/2) & 0xf0) >> 4;
}

static CGColorRef red = NULL;
static CGColorRef green = NULL;
static CGColorRef darkGreen = NULL;
static CGColorRef blue = NULL;
static CGColorRef darkBlue = NULL;
static CGColorRef yellow = NULL;
static CGColorRef cyan = NULL;
static CGColorRef darkCyan = NULL;
static CGColorRef brown = NULL;
static CGColorRef lightBrown = NULL;
static CGColorRef veryLightBrown = NULL;
static CGColorRef darkBrown = NULL;
static CGColorRef grey = NULL;
static CGColorRef black = NULL;

static dispatch_once_t onceColorToken = 0;
static dispatch_block_t initColors = ^{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
  // R,G,B,A
  const CGFloat opaqueRed[4] = { 1, 0, 0, 1 };
  const CGFloat opaqueGreen[4] = { 0, 1, 0, 1 };
  const CGFloat opaqueDarkGreen[4] = { 0, 0.502, 0, 1 };
  const CGFloat opaqueBlue[4] = { 0, 0, 1, 1 };
  const CGFloat opaqueDarkBlue[4] = { 0, 0, 0.475, 1 };
  const CGFloat opaqueYellow[4] = { 1, 1, 0, 1 };
  const CGFloat opaqueCyan[4] = { 0, 1, 1, 1 };
  const CGFloat opaqueDarkCyan[4] = { 0, 0.502, 0.502, 1 };
  const CGFloat opaqueBrown[4] = { 0.702, 0.475, 0.059, 1 };
  const CGFloat opaqueLightBrown[4] = { 0.875, 0.596, 0.075, 1 };
  const CGFloat opaqueVeryLightBrown[4] = { 0.918, 0.647, 0.482, 1 };
  const CGFloat opaqueDarkBrown[4] = { 0.502, 0.251, 0.0, 1 };
  const CGFloat opaqueGrey[4] = { 0.502, 0.502, 0.502, 1 };
  const CGFloat opaqueBlack[4] = { 0, 0, 0, 1 };

  // Only create the CGColor objects once.
  red = CGColorCreate(space, opaqueRed);
  green = CGColorCreate(space, opaqueGreen);
  darkGreen = CGColorCreate(space, opaqueDarkGreen);
  blue = CGColorCreate(space, opaqueBlue);
  darkBlue = CGColorCreate(space, opaqueDarkBlue);
  yellow = CGColorCreate(space, opaqueYellow);
  cyan = CGColorCreate(space, opaqueCyan);
  darkCyan = CGColorCreate(space, opaqueDarkCyan);
  brown = CGColorCreate(space, opaqueBrown);
  lightBrown = CGColorCreate(space, opaqueLightBrown);
  veryLightBrown = CGColorCreate(space, opaqueVeryLightBrown);
  darkBrown = CGColorCreate(space, opaqueDarkBrown);
  grey = CGColorCreate(space, opaqueGrey);
  black = CGColorCreate(space, opaqueBlack);
  
  CGColorSpaceRelease(space);
};

CGColorRef myGetRedColor(void) {
  dispatch_once(&onceColorToken, initColors);
  
  return red;
}

CGColorRef myGetGreenColor(void) {
  dispatch_once(&onceColorToken, initColors);
  
  return green;
}

CGColorRef myGetDarkGreenColor(void) {
  dispatch_once(&onceColorToken, initColors);
  
  return darkGreen;
}

CGColorRef myGetBlueColor(void) {
  dispatch_once(&onceColorToken, initColors);
  
  return blue;
}

CGColorRef myGetDarkBlueColor(void) {
  dispatch_once(&onceColorToken, initColors);
  
  return darkBlue;
}

CGColorRef myGetYellowColor(void) {
  dispatch_once(&onceColorToken, initColors);
  
  return yellow;
}

CGColorRef myGetCyanColor(void) {
  dispatch_once(&onceColorToken, initColors);
  
  return cyan;
}

CGColorRef myGetDarkCyanColor(void) {
  dispatch_once(&onceColorToken, initColors);
  
  return darkCyan;
}

CGColorRef myGetBrownColor(void) {
  dispatch_once(&onceColorToken, initColors);
  
  return brown;
}

CGColorRef myGetLightBrownColor(void) {
  dispatch_once(&onceColorToken, initColors);
  
  return lightBrown;
}

CGColorRef myGetVeryLightBrownColor(void) {
  dispatch_once(&onceColorToken, initColors);
  
  return veryLightBrown;
}

CGColorRef myGetDarkBrownColor(void) {
  dispatch_once(&onceColorToken, initColors);
  
  return darkBrown;
}

CGColorRef myGetGreyColor(void) {
  dispatch_once(&onceColorToken, initColors);
  
  return grey;
}

CGColorRef myGetBlackColor(void) {
  dispatch_once(&onceColorToken, initColors);
  
  return black;
}
