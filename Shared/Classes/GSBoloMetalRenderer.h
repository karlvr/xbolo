//
//  GSBoloMetalRenderer.h
//  XBolo
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@class GSBoloScene;

API_AVAILABLE(ios(11), macosx(10.13))
@interface GSBoloMetalRenderer : NSObject <MTKViewDelegate>

- (instancetype)initWithMTLView:(MTKView *)view;

@property (nonatomic, strong, readonly) GSBoloScene *scene;

@end

NS_ASSUME_NONNULL_END
