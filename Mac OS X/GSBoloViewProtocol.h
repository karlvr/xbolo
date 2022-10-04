//
//  GSBoloViewProtocol.h
//  XBolo
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import "bolo.h"

NS_ASSUME_NONNULL_BEGIN

@class GSXBoloController;

@protocol GSBoloViewProtocol <NSObject>

@property (strong, nonatomic) GSXBoloController *boloController;

- (void)reset;
- (void)refresh;
- (void)scroll:(CGPoint)delta;
- (void)scrollToVisible:(Vec2f)point;
- (void)zoomTo:(CGFloat)zoom;
- (void)tankCenter;
- (void)nextPillCenter;

@end

NS_ASSUME_NONNULL_END
