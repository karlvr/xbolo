//
//  GSBoloScene.h
//  XBolo
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

@import SpriteKit;

NS_ASSUME_NONNULL_BEGIN

@interface GSBoloScene: SKScene

- (void)update;
- (void)scroll:(CGPoint)delta;
- (void)activateAutoScroll;
- (void)tankCenter;
- (void)nextPillCenter;

@end

NS_ASSUME_NONNULL_END
