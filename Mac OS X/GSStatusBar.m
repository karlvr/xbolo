//
//  GSStatusBar.m
//  XBolo
//
//  Created by Robert Chrzanowski on 11/12/04.
//  Copyright 2004 Robert Chrzanowski. All rights reserved.
//

#import "GSStatusBar.h"


@implementation GSStatusBar
@synthesize type;
@synthesize value;

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
      type = GSStatusBarHorizontal;
      value = 0.0f;
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
  switch (type) {
    case GSStatusBarHorizontal:
    [[NSColor greenColor] set];
    [NSBezierPath fillRect:NSMakeRect(0.0f, 0.0f, NSWidth(self.frame)*value, NSHeight(self.frame))];
    break;

    case GSStatusBarVertical:
    [[NSColor greenColor] set];
    [NSBezierPath fillRect:NSMakeRect(0.0f, 0.0f, NSWidth(self.frame), NSHeight(self.frame)*value)];
    break;

  default:
    break;
  }
}

- (void)setType:(GSStatusBarType)aType {
  switch (aType) {
  case GSStatusBarHorizontal:
  case GSStatusBarVertical:
    if (type != aType) {
      type = aType;
      [self setNeedsDisplay:YES];
    }

    break;

  default:
    assert(0);
    break;
  }
}

- (void)setValue:(CGFloat)aValue {
  if (value != aValue) {
    value = aValue;
    [self setNeedsDisplay:YES];
  }
}

@end
