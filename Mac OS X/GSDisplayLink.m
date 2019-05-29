//
//  GSDisplayLink.m
//  Mac OS X
//
//  Created by Karl von Randow on 30/05/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import "GSDisplayLink.h"

#import <CoreVideo/CoreVideo.h>

@interface GSDisplayLink() {
  CVDisplayLinkRef _displayLink;
  dispatch_source_t _source;
}

- (void)displayLinkTick;

@end

CVReturn myCVDisplayLinkOutputCallback(
                                        CVDisplayLinkRef CV_NONNULL displayLink,
                                        const CVTimeStamp * CV_NONNULL inNow,
                                        const CVTimeStamp * CV_NONNULL inOutputTime,
                                        CVOptionFlags flagsIn,
                                        CVOptionFlags * CV_NONNULL flagsOut,
                                        void * CV_NULLABLE displayLinkContext)
{
  GSDisplayLink *link = (__bridge GSDisplayLink *)displayLinkContext;
  [link displayLinkTick];
  return kCVReturnSuccess;
}

@implementation GSDisplayLink

- (instancetype)initWithQueue:(nullable dispatch_queue_t)queue {
  if (self = [super init]) {
    if (queue == nil) {
      queue = dispatch_get_main_queue();
    }
    _source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, queue);

    const CVReturn createSuccess = CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
    if (createSuccess != kCVReturnSuccess || !_displayLink) {
      return nil;
    }

    // TODO release bridging retain
    const CVReturn setOutputSuccess = CVDisplayLinkSetOutputCallback(_displayLink, myCVDisplayLinkOutputCallback, CFBridgingRetain(self));
    if (setOutputSuccess != kCVReturnSuccess) {
      return nil;
    }

    const CVReturn setCurrentCGDisplaySuccess = CVDisplayLinkSetCurrentCGDisplay(_displayLink, CGMainDisplayID());
    if (setCurrentCGDisplaySuccess != kCVReturnSuccess) {
      return nil;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(_source, ^{
      [weakSelf tick];
    });
  }
  return self;
}

- (BOOL)running {
  if (_displayLink == nil) {
    return NO;
  }
  return CVDisplayLinkIsRunning(_displayLink);
}

- (void)start {
  CVDisplayLinkStart(_displayLink);
  dispatch_resume(_source);
}

- (void)cancel {
  if (!self.running) {
    return;
  }
  CVDisplayLinkStop(_displayLink);
  dispatch_cancel(_source);
}

- (void)tick {
  if (_callback) {
    _callback();
  }
}

- (void)displayLinkTick {
  dispatch_source_merge_data(_source, 1);
}

@end
