//
//  GSBoloScene.h
//  XBolo
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

@import SpriteKit;

#import "bolo.h"

NS_ASSUME_NONNULL_BEGIN

@interface GSBoloScene: SKScene

@property (nonatomic) CGFloat baseZoom;

- (void)update;
- (void)scroll:(CGPoint)delta;
- (void)scrollToVisible:(Vec2f)point;
- (void)zoomTo:(CGFloat)zoom;
- (void)tankCenter;
- (void)nextPillCenter;

- (void)didMoveToNonSKView:(NSView *)view;

@end

NS_ASSUME_NONNULL_END
