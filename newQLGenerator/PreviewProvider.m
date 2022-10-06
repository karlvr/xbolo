//
//  PreviewProvider.m
//  newQLGenerator
//
//  Created by C.W. Betts on 10/6/22.
//  Copyright © 2022 Robert Chrzanowski. All rights reserved.
//

#import "PreviewProvider.h"
#include "QLSharedStructs.h"

@implementation PreviewProvider

/*

 Use a QLPreviewProvider to provide data-based previews.
 
 To set up your extension as a data-based preview extension:

 - Modify the extension's Info.plist by setting
   <key>QLIsDataBasedPreview</key>
   <true/>
 
 - Add the supported content types to QLSupportedContentTypes array in the extension's Info.plist.

 - Change the NSExtensionPrincipalClass to this class.
   e.g.
   <key>NSExtensionPrincipalClass</key>
   <string>PreviewProvider</string>
 
 - Implement providePreviewForFileRequest:completionHandler:
 
 */

- (void)providePreviewForFileRequest:(QLFilePreviewRequest *)request completionHandler:(void (^)(QLPreviewReply * _Nullable reply, NSError * _Nullable error))handler
{
	QLPreviewReply* reply = [[QLPreviewReply alloc] initWithContextSize:CGSizeMake(256, 256) isBitmap:NO drawingBlock:^BOOL(CGContextRef  _Nonnull context, QLPreviewReply * _Nonnull reply, NSError *__autoreleasing  _Nullable * _Nullable error) {
		NSData *data = [NSData dataWithContentsOfURL:request.fileURL options:0 error:error];
		if (!data) {
			return NO;
		}
		
		const void *buf = data.bytes;
		size_t nbytes = data.length;

		int i;
		const struct BMAP_Preamble *preamble;
		const struct BMAP_PillInfo *pillInfos;
		const struct BMAP_BaseInfo *baseInfos;
		const struct BMAP_StartInfo *startInfos;
		const void *runData;
		int runDataLen;
		int offset;
		int minx = 256, maxx = 0, miny = 256, maxy = 0;

		/* turn off antialiasing */
		CGContextSetShouldAntialias(context, 0);

		/* draw deep sea */
		CGContextSetFillColorWithColor(context, myGetBlueColor());
		CGContextFillRect(context, CGRectMake(0, 0, 256, 256));

		/* invert y axis */
		CGContextTranslateCTM(context, 0, 256);
		CGContextScaleCTM(context, 1, -1);

		if (nbytes < sizeof(struct BMAP_Preamble)) {
		  return NO;
		}

		preamble = buf;

		if (strncmp((char *)preamble->ident, MAPFILEIDENT, MAPFILEIDENTLEN) != 0) {
			return NO;
		}
		
		if (preamble->version != CURRENTMAPVERSION) {
			return NO;
		}
		
		if (preamble->npills > MAX_PILLS) {
			return NO;
		}
		
		if (preamble->nbases > MAX_BASES) {
			return NO;
		}

		if (preamble->nstarts > MAXSTARTS) {
			return NO;
		}

		if (nbytes <
			sizeof(struct BMAP_Preamble) +
			preamble->npills*sizeof(struct BMAP_PillInfo) +
			preamble->nbases*sizeof(struct BMAP_BaseInfo) +
			preamble->nstarts*sizeof(struct BMAP_StartInfo)) {
			return NO;
		}

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
		} else {
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
				return NO;
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
		
		return YES;
	}];
	
	//You can also create a QLPreviewReply with a fileURL of a supported file type, by drawing directly into a bitmap context, or by providing a PDFDocument.
	
	handler(reply, nil);
}

@end

