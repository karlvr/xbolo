//
//  GSToolsController.m
//  XBolo Map Editor
//
//  Created by Robert Chrzanowski on 12/31/09.
//  Copyright 2009 Robert Chrzanowski. All rights reserved.
//

#import "GSToolsController.h"


static __weak GSToolsController *controller = nil;

@implementation GSToolsController

+ (NSInteger)tool {
  return [controller tool];
}

- (instancetype)init {
  self = [super init];

  if (self) {
    controller = self;
  }

  return self;
}

- (NSInteger)tool {
  return [toolMatrix.selectedCell tag];
}

- (NSString *)windowFrameAutosaveName {
  return @"GSToolsPanel";
}

@end
