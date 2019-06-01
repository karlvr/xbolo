//
//  GSBoloViewProtocol.h
//  XBolo
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@protocol GSBoloViewProtocol <NSObject>

- (void)refresh;
- (void)scroll:(CGPoint)delta;
- (void)tankCenter;
- (void)nextPillCenter;

@end

NS_ASSUME_NONNULL_END
