#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <unistd.h>
#include <ApplicationServices/ApplicationServices.h>
#import <Cocoa/Cocoa.h>
#include "QLSharedStructs.h"
#include "main.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options) {
@autoreleasepool {
  NSData *data;
  const void *buf;
  size_t nbytes;
  const struct BMAP_Preamble *preamble;

  data = [NSData dataWithContentsOfURL:(__bridge NSURL *)url];
  buf = data.bytes;
  nbytes = data.length;

  if (nbytes < sizeof(struct BMAP_Preamble)) {
    return noErr;
  }
  
  preamble = buf;
  
  if (strncmp((const char *)preamble->ident, MAPFILEIDENT, MAPFILEIDENTLEN) != 0) {
    return noErr;
  }
  
  if (preamble->version != CURRENTMAPVERSION) {
    return noErr;
  }
  
  if (preamble->npills > MAX_PILLS) {
    return noErr;
  }
  
  if (preamble->nbases > MAX_BASES) {
    return noErr;
  }
  
  if (preamble->nstarts > MAXSTARTS) {
    return noErr;
  }
  
  if (nbytes <
      sizeof(struct BMAP_Preamble) +
      preamble->npills*sizeof(struct BMAP_PillInfo) +
      preamble->nbases*sizeof(struct BMAP_BaseInfo) +
      preamble->nstarts*sizeof(struct BMAP_StartInfo)) {
    return noErr;
  }
  
  CGContextRef context = QLPreviewRequestCreateContext(preview, CGSizeMake(256, 256), false, NULL);

  if(context) {
    int i;
    const struct BMAP_PillInfo *pillInfos;
    const struct BMAP_BaseInfo *baseInfos;
    const struct BMAP_StartInfo *startInfos;
    const void *runData;
    int runDataLen;
    int offset;
    int minx = 256, maxx = 0, miny = 256, maxy = 0;

    /* turn of antialiasing */
    CGContextSetShouldAntialias(context, 0);

    /* draw deep sea */
    CGContextSetFillColorWithColor(context, myGetBlueColor());
    CGContextFillRect(context, CGRectMake(0, 0, 256, 256));

    /* invert y axis */
    CGContextTranslateCTM(context, 0, 256);
    CGContextScaleCTM(context, 1, -1);

    pillInfos = (struct BMAP_PillInfo *)(preamble + 1);
    baseInfos = (struct BMAP_BaseInfo *)(pillInfos + preamble->npills);
    startInfos = (struct BMAP_StartInfo *)(baseInfos + preamble->nbases);
    runData = (void *)(startInfos + preamble->nstarts);
    runDataLen =
      (int)(nbytes - (sizeof(struct BMAP_Preamble) +
                preamble->npills*sizeof(struct BMAP_PillInfo) +
                preamble->nbases*sizeof(struct BMAP_BaseInfo) +
                preamble->nstarts*sizeof(struct BMAP_StartInfo)));

    offset = 0;

    for (;;) {
      struct BMAP_Run run;

      if (offset + sizeof(struct BMAP_Run) > runDataLen) {
        break;
      }

      run = *(struct BMAP_Run *)(runData + offset);

      if (run.datalen == 4 && run.y == 0xff && run.startx == 0xff && run.endx == 0xff) {
        break;
      }

      if (offset + run.datalen > runDataLen) {
        break;
      }

      if (run.y < miny) {
        miny = run.y;
      }
      if (run.y > maxy) {
        maxy = run.y;
      }

      if (run.startx < minx) {
        minx = run.startx;
      }
      if (run.endx > maxx) {
        maxx = run.endx;
      }

      offset += run.datalen;
    }

    minx -= 3;

    if (minx < 0) {
      minx = 0;
    }

    maxx += 3;

    if (maxx > 256) {
      maxx = 256;
    }

    miny -= 3;

    if (miny < 0) {
      miny = 0;
    }

    maxy += 3;

    if (maxy > 256) {
      maxy = 256;
    }

    if (maxx - minx > maxy - miny) {
      CGContextScaleCTM(context, 256.0/(maxx - minx), 256.0/(maxx - minx));
      CGContextTranslateCTM(context, -minx, -miny + ((maxx - minx) - (maxy - miny))/2);
    }
    else {
      CGContextScaleCTM(context, 256.0/(maxy - miny), 256.0/(maxy - miny));
      CGContextTranslateCTM(context, -minx + ((maxy - miny) - (maxx - minx))/2, -miny);
    }

    /* begin drawing terrain */

    offset = 0;

    for (;;) {
      struct BMAP_Run run;

      if (offset + sizeof(struct BMAP_Run) > runDataLen) {
        break;
      }

      run = *(struct BMAP_Run *)(runData + offset);

      if (run.datalen == 4 && run.y == 0xff && run.startx == 0xff && run.endx == 0xff) {
        break;
      }

      if (offset + run.datalen > runDataLen) {
        break;
      }

      if (drawrun(context, run, runData + offset + sizeof(struct BMAP_Run)) == -1) {
        QLPreviewRequestFlushContext(preview, context);
        CFRelease(context);
        return -1;
      }

      offset += run.datalen;
    }

    CGContextSetFillColorWithColor(context, myGetYellowColor());

    for (i = 0; i < preamble->nbases; i++) {
      CGContextFillRect(context, CGRectMake(baseInfos[i].x, baseInfos[i].y, 1, 1));
    }

    CGContextSetFillColorWithColor(context, myGetRedColor());

    for (i = 0; i < preamble->npills; i++) {
      CGContextFillRect(context, CGRectMake(pillInfos[i].x, pillInfos[i].y, 1, 1));
    }

    CGContextSetFillColorWithColor(context, myGetGreyColor());

    for (i = 0; i < preamble->nstarts; i++) {
      CGContextFillRect(context, CGRectMake(startInfos[i].x, startInfos[i].y, 1, 1));
    }

    QLPreviewRequestFlushContext(preview, context);
    CFRelease(context);
  }


  return noErr;
}
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview) {
  // implement only if supported
}
