//
//  GSPaletteController.m
//  XBolo Map Editor
//
//  Created by Robert Chrzanowski on 1/2/10.
//  Copyright 2010 Robert Chrzanowski. All rights reserved.
//

#import "GSPaletteController.h"


static __weak GSPaletteController *controller = nil;

@implementation GSPaletteController

+ (NSInteger)palette {
  return [controller palette];
}

- (id)init {
  self = [super init];

  if (self) {
    controller = self;
  }

  return self;
}

- (NSInteger)palette {
  return [[paletteMatrix selectedCell] tag];
}

- (NSString *)windowFrameAutosaveName {
  return @"GSPalettePanel";
}

@end
