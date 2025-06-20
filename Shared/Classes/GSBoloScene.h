//
//  GSBoloScene.h
//  XBolo
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

@import SpriteKit;

#import "bolo.h"

#if TARGET_OS_IOS
#define VIEW_TYPE UIView
#elif TARGET_OS_OSX
#define VIEW_TYPE NSView
#else
#error Unsupported target
#endif

NS_ASSUME_NONNULL_BEGIN

@interface GSBoloScene: SKScene

@property (nonatomic) CGFloat baseZoom;
@property (nonatomic) BOOL povMode;

- (void)update;
- (void)scroll:(CGPoint)delta;
- (void)scrollToVisible:(Vec2f)point;
- (void)zoomTo:(CGFloat)zoom;
- (void)tankCenter;
- (void)nextPillCenter;

- (void)didMoveToNonSKView:(VIEW_TYPE *)view;

@end

NS_ASSUME_NONNULL_END
