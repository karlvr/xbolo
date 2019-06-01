//
//  GSBoloWrapperView.m
//  Mac OS X
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import "GSBoloWrapperView.h"

#import "GSBoloMTKView.h"
#import "GSBoloSKView.h"
#import "GSBoloDrawRectView.h"

@interface GSBoloWrapperView() {
  id<GSBoloViewProtocol> _wrapped;
  NSScrollView *_scrollView;
  id<NSObject> _boundsChangeObserver;
}

- (void)boundsDidChange;

@end

@implementation GSBoloWrapperView

@synthesize boloController = boloController;

- (instancetype)initWithFrame:(NSRect)frameRect {
  if (self = [super initWithFrame:frameRect]) {
    self.postsBoundsChangedNotifications = YES;
    __weak typeof(self) weakSelf = self;
    _boundsChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification object:self queue:nil usingBlock:^(NSNotification * _Nonnull note) {
      [weakSelf boundsDidChange];
    }];
    
    if (@available(macOS 10.13, *)) {
      _wrapped = [[GSBoloMTKView alloc] initWithFrame:self.bounds];
      [self addSubview:(NSView *)_wrapped];
    } else if (@available(macOS 10.9, *)) {
      _wrapped = [[GSBoloSKView alloc] initWithFrame:self.bounds];
      [self addSubview:(NSView *)_wrapped];
    } else {
      NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
      _wrapped = [[GSBoloDrawRectView alloc] initWithFrame:NSMakeRect(0, 0, 4096, 4096)];
      NSView *wrappedView = (NSView *)_wrapped;
      scrollView.documentView = wrappedView;
      [self addSubview:scrollView];
      _scrollView = scrollView;
    }
  }

  return self;
}

- (void)awakeFromNib {
  _wrapped.boloController = boloController;
}

- (void)boundsDidChange {
  if (_scrollView) {
    _scrollView.frame = self.bounds;
  } else {
    ((NSView *)_wrapped).frame = self.bounds;
  }
}

- (void)nextPillCenter {
  [_wrapped nextPillCenter];
}

- (void)refresh {
  [_wrapped refresh];
}

- (void)scroll:(CGPoint)delta {
  [_wrapped scroll:delta];
}

- (void)tankCenter {
  [_wrapped tankCenter];
}

@end
