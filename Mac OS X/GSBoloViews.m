//
//  GSBoloViews.m
//  Mac OS X
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import "GSBoloViews.h"

#import "client.h"

static NSMutableArray<id<GSBoloViewProtocol>> *boloViews = nil;

@implementation GSBoloViews

+ (void)initialize {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    boloViews = [[NSMutableArray alloc] init];
  });
}

+ (void)refresh {
  /* draw */
  for (id<GSBoloViewProtocol> view in boloViews) {
    [view refresh];
  }

  clearchangedtiles();
}

+ (void)addView:(id<GSBoloViewProtocol>)view {
  [boloViews addObject:view];
}

+ (void)removeView:(id<GSBoloViewProtocol>)view {
  [boloViews removeObject:view];
}

@end
