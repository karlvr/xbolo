//
//  GSToolsController.h
//  XBolo Map Editor
//
//  Created by Robert Chrzanowski on 12/31/09.
//  Copyright 2009 Robert Chrzanowski. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef NS_ENUM(NSInteger, Tool) {
  /* pencil and fill tools*/
  kPencilTool           = 0,

  /* filled primative tools */
  kFilledEllipseTool    = 1,
  kFilledRectangleTool  = 2,

  /* primative tools */
  kEllipseTool          = 3,
  kRectangleTool        = 4,
  kFillTool             = 5,

  /* selection tools */
  kSelectTool           = 6,
  kMineTool             = 7,

  /* object tools */
  kPillTool             = 8,
  kBaseTool             = 9,
  kStartTool            = 10,
  kDeleteTool           = 11
};

@interface GSToolsController : NSWindowController {
  IBOutlet NSMatrix *toolMatrix;
}

+ (NSInteger)tool;
- (NSInteger)tool;

@end
