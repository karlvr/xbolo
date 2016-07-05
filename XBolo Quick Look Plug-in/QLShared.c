//
//  QLShared.m
//  XBolo Quick Look Plug-in
//
//  Created by C.W. Betts on 4/12/16.
//  Copyright © 2016 Robert Chrzanowski. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include "QLSharedStructs.h"

static int setterraincolor(CGContextRef context, int tile);
static int readnibble(const void *buf, size_t i);
static CGColorSpaceRef myGetGenericRGBSpace(void);

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

int setterraincolor(CGContextRef context, int tile) {
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

CGColorSpaceRef myGetGenericRGBSpace(void) {
  // Only create the color space once.
  static CGColorSpaceRef colorSpace = NULL;
  
  if (colorSpace == NULL) {
    colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  }
  
  return colorSpace;
}

CGColorRef myGetRedColor(void) {
  // Only create the CGColor object once.
  static CGColorRef red = NULL;
  
  if (red == NULL) {
    // R,G,B,A
    CGFloat opaqueRed[4] = { 1, 0, 0, 1 };
    red = CGColorCreate(myGetGenericRGBSpace(), opaqueRed);
  }
  
  return red;
}

CGColorRef myGetGreenColor(void) {
  // Only create the CGColor object once.
  static CGColorRef green = NULL;
  
  if (green == NULL) {
    // R,G,B,A
    CGFloat opaqueGreen[4] = { 0, 1, 0, 1 };
    green = CGColorCreate(myGetGenericRGBSpace(), opaqueGreen);
  }
  
  return green;
}

CGColorRef myGetDarkGreenColor(void) {
  // Only create the CGColor object once.
  static CGColorRef darkGreen = NULL;
  
  if (darkGreen == NULL) {
    // R,G,B,A
    CGFloat opaqueDarkGreen[4] = { 0, 0.502, 0, 1 };
    darkGreen = CGColorCreate(myGetGenericRGBSpace(), opaqueDarkGreen);
  }
  
  return darkGreen;
}

CGColorRef myGetBlueColor(void) {
  // Only create the CGColor object once.
  static CGColorRef blue = NULL;
  if (blue == NULL) {
    // R,G,B,A
    CGFloat opaqueBlue[4] = { 0, 0, 1, 1 };
    blue = CGColorCreate(myGetGenericRGBSpace(), opaqueBlue);
  }
  
  return blue;
}

CGColorRef myGetDarkBlueColor(void) {
  // Only create the CGColor object once.
  static CGColorRef darkBlue = NULL;
  if (darkBlue == NULL) {
    // R,G,B,A
    CGFloat opaqueDarkBlue[4] = { 0, 0, 0.475, 1 };
    darkBlue = CGColorCreate(myGetGenericRGBSpace(), opaqueDarkBlue);
  }
  
  return darkBlue;
}

CGColorRef myGetYellowColor(void) {
  // Only create the CGColor object once.
  static CGColorRef yellow = NULL;
  
  if (yellow == NULL) {
    // R,G,B,A
    CGFloat opaqueYellow[4] = { 1, 1, 0, 1 };
    yellow = CGColorCreate(myGetGenericRGBSpace(), opaqueYellow);
  }
  
  return yellow;
}

CGColorRef myGetCyanColor(void) {
  // Only create the CGColor object once.
  static CGColorRef cyan = NULL;
  
  if (cyan == NULL) {
    // R,G,B,A
    CGFloat opaqueCyan[4] = { 0, 1, 1, 1 };
    cyan = CGColorCreate(myGetGenericRGBSpace(), opaqueCyan);
  }
  
  return cyan;
}

CGColorRef myGetDarkCyanColor(void) {
  // Only create the CGColor object once.
  static CGColorRef darkCyan = NULL;
  
  if (darkCyan == NULL) {
    // R,G,B,A
    CGFloat opaqueDarkCyan[4] = { 0, 0.502, 0.502, 1 };
    darkCyan = CGColorCreate(myGetGenericRGBSpace(), opaqueDarkCyan);
  }
  
  return darkCyan;
}

CGColorRef myGetBrownColor(void) {
  // Only create the CGColor object once.
  static CGColorRef brown = NULL;
  
  if (brown == NULL) {
    // R,G,B,A
    CGFloat opaqueBrown[4] = { 0.702, 0.475, 0.059, 1 };
    brown = CGColorCreate(myGetGenericRGBSpace(), opaqueBrown);
  }
  
  return brown;
}

CGColorRef myGetLightBrownColor(void) {
  // Only create the CGColor object once.
  static CGColorRef lightBrown = NULL;
  
  if (lightBrown == NULL) {
    // R,G,B,A
    CGFloat opaqueLightBrown[4] = { 0.875, 0.596, 0.075, 1 };
    lightBrown = CGColorCreate(myGetGenericRGBSpace(), opaqueLightBrown);
  }
  
  return lightBrown;
}

CGColorRef myGetVeryLightBrownColor(void) {
  // Only create the CGColor object once.
  static CGColorRef veryLightBrown = NULL;
  
  if (veryLightBrown == NULL) {
    // R,G,B,A
    CGFloat opaqueVeryLightBrown[4] = { 0.918, 0.647, 0.482, 1 };
    veryLightBrown = CGColorCreate(myGetGenericRGBSpace(), opaqueVeryLightBrown);
  }
  
  return veryLightBrown;
}

CGColorRef myGetDarkBrownColor(void) {
  // Only create the CGColor object once.
  static CGColorRef darkBrown = NULL;
  
  if (darkBrown == NULL) {
    // R,G,B,A
    CGFloat opaqueDarkBrown[4] = { 0.502, 0.251, 0.0, 1 };
    darkBrown = CGColorCreate(myGetGenericRGBSpace(), opaqueDarkBrown);
  }
  
  return darkBrown;
}

CGColorRef myGetGreyColor(void) {
  // Only create the CGColor object once.
  static CGColorRef grey = NULL;
  
  if (grey == NULL) {
    // R,G,B,A
    CGFloat opaqueGrey[4] = { 0.502, 0.502, 0.502, 1 };
    grey = CGColorCreate(myGetGenericRGBSpace(), opaqueGrey);
  }
  
  return grey;
}

CGColorRef myGetBlackColor(void) {
  // Only create the CGColor object once.
  static CGColorRef black = NULL;
  
  if (black == NULL) {
    // R,G,B,A
    CGFloat opaqueBlack[4] = { 0, 0, 0, 1 };
    black = CGColorCreate(myGetGenericRGBSpace(), opaqueBlack);
  }
  
  return black;
}
