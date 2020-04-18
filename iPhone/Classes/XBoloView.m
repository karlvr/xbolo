//
//  XBoloView.m
//  XBolo
//
//  Created by Robert Chrzanowski on 6/28/09.
//  Copyright 2009 Robert Chrzanowski. All rights reserved.
//

#import "XBoloView.h"

#import "GSBoloScene.h"
#import "XBolo-Swift.h"

@interface XBoloView() {
  GSBoloScene *_scene;
}

@end

@implementation XBoloView

@synthesize boloController;

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.showsFPS = YES;
    self.showsNodeCount = YES;
    self.preferredFramesPerSecond = 16;
    self.ignoresSiblingOrder = YES;
    self.shouldCullNonVisibleNodes = YES;
  }
  return self;
}

- (void)reset {
  _scene = [[GSBoloScene alloc] initWithSize:self.bounds.size];
  _scene.povMode = YES;
  [_scene zoomTo:1.5];
  [self presentScene:_scene];
}

- (void)refresh {
  [_scene update];
}

- (void)scroll:(CGPoint)delta {
  [_scene scroll:delta];
}

- (void)scrollToVisible:(Vec2f)point {
  [_scene scrollToVisible:point];
}

- (void)zoomTo:(CGFloat)zoom {
  [_scene zoomTo:zoom];
}

- (void)tankCenter {
  [_scene tankCenter];
}

- (void)nextPillCenter {
  [_scene nextPillCenter];
}

#pragma mark -

- (CGPoint)convertToScenePointFromViewPoint:(CGPoint)pt {
  return [_scene convertPointFromView:pt];
}

@end
