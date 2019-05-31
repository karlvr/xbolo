//
//  GSBoloSKView.h
//  Mac OS X
//
//  Created by Karl von Randow on 30/05/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GSBoloSKView : SKView

- (void)mapDidUpdate;
- (void)refresh;

@end

NS_ASSUME_NONNULL_END
