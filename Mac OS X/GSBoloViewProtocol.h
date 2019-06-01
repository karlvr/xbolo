//
//  GSBoloViewProtocol.h
//  XBolo
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class GSXBoloController;

@protocol GSBoloViewProtocol <NSObject>

@property (strong, nonatomic) GSXBoloController *boloController;

- (void)refresh;
- (void)scroll:(CGPoint)delta;
- (void)tankCenter;
- (void)nextPillCenter;

@end

NS_ASSUME_NONNULL_END
