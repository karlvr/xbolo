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

#import "client.h"

static int TicksToWaitForRate(double rate) {
  return (1 - rate) * 15 + 1;
}

@interface XBoloView() {
  GSBoloScene *_scene;
  XBoloDriverGestureRecognizer *_driveGesture;
  BOOL _autoSlowDown;
  int _ticks;
  int _lastControlTick;
  int _lastAccelerateTick;
  int _lastBrakeTick;
  int _lastTurnLeftTick;
  int _lastTurnRightTick;

  NSTimer *_controlTimer;
}

@end

@implementation XBoloView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.showsFPS = YES;
    self.showsNodeCount = YES;
    self.preferredFramesPerSecond = 16;
    self.ignoresSiblingOrder = YES;
    self.shouldCullNonVisibleNodes = YES;

    _scene = [[GSBoloScene alloc] initWithSize:frame.size];
    _scene.povMode = YES;
    [self presentScene:_scene];

    XBoloDriverGestureRecognizer *driveGesture = [[XBoloDriverGestureRecognizer alloc] initWithTarget:nil action:nil];
    _driveGesture = driveGesture;
    [self addGestureRecognizer:driveGesture];

    _autoSlowDown = YES;
  }
  return self;
}

- (void)reset {
  _scene = [[GSBoloScene alloc] initWithSize:self.bounds.size];
  _scene.povMode = YES;
  [self presentScene:_scene];

  _controlTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60 target:self selector:@selector(controlTick) userInfo:nil repeats:YES];
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

- (void)clientLoopUpdate {
  _ticks++;
}

- (void)controlTick {
  const int ticksDiff = _ticks - _lastControlTick;
//  if (ticksDiff == 0) {
//    NSLog(@"drop");
//    return;
//  } else if (ticksDiff > 1) {
//    NSLog(@"skip %i", ticksDiff);
//  }
  if (ticksDiff == 0) {
    return;
  }

  _lastControlTick = _ticks;

  const double accelerateRate = _driveGesture.accelerateRate;
  const double brakeRate = _driveGesture.brakeRate;
  const double turnLeftRate = _driveGesture.turnLeftRate;
  const double turnRightRate = _driveGesture.turnRightRate;

  if (accelerateRate > 0 && _lastAccelerateTick + TicksToWaitForRate(accelerateRate) <= _ticks) {
    keyevent(ACCELMASK, 1);
    if (_autoSlowDown) {
      keyevent(BRAKEMASK, 0);
    }
    _lastAccelerateTick = _ticks;
  } else {
    keyevent(ACCELMASK, 0);
    if (_autoSlowDown) {
      keyevent(BRAKEMASK, 1);
    }
    _lastAccelerateTick = 0;
  }
  if (brakeRate > 0 && _lastBrakeTick + TicksToWaitForRate(brakeRate) <= _ticks) {
    keyevent(BRAKEMASK, 1);
    _lastBrakeTick = _ticks;
  } else {
    keyevent(BRAKEMASK, 0);
    _lastBrakeTick = 0;
  }
  if (turnLeftRate > 0 && _lastTurnLeftTick + TicksToWaitForRate(turnLeftRate) <= _ticks) {
    keyevent(TURNLMASK, 1);
    _lastTurnLeftTick = _ticks;
  } else {
    keyevent(TURNLMASK, 0);
    _lastTurnLeftTick = 0;
  }
  if (turnRightRate > 0 && _lastTurnRightTick + TicksToWaitForRate(turnRightRate) <= _ticks) {
    keyevent(TURNRMASK, 1);
    _lastTurnRightTick = _ticks;
  } else {
    keyevent(TURNRMASK, 0);
    _lastTurnRightTick = 0;
  }
}

@end
