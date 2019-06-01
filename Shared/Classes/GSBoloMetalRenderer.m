//
//  GSBoloMetalRenderer.m
//  XBolo
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Karl von Randow. All rights reserved.
//

#import "GSBoloMetalRenderer.h"

#import "GSBoloScene.h"

@interface GSBoloMetalRenderer() {
  SKRenderer *_renderer;
  id <MTLCommandQueue> _commandQueue;
}

@end

@implementation GSBoloMetalRenderer

- (instancetype)initWithMTLView:(MTKView *)view {
  if (self = [super init]) {
    CGFloat scale = view.window.backingScaleFactor;

    _scene = [[GSBoloScene alloc] initWithSize:view.drawableSize];
    _scene.baseZoom = 1.0 / scale;
    _renderer = [SKRenderer rendererWithDevice:view.device];
    _renderer.scene = _scene;
    _renderer.ignoresSiblingOrder = YES;
    _renderer.shouldCullNonVisibleNodes = YES;
    _renderer.showsNodeCount = YES;
    _scene.paused = NO;

    _commandQueue = [view.device newCommandQueue];
    [_scene didMoveToNonSKView:view];
  }
  return self;
}

- (void)drawInMTKView:(MTKView *)view {
  MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
  if (renderPassDescriptor == nil) {
    return;
  }

  [_renderer updateAtTime:CACurrentMediaTime()];

  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  CGRect viewport = CGRectMake(0, 0, view.drawableSize.width, view.drawableSize.height);

  [_renderer renderWithViewport:viewport
                      commandBuffer:commandBuffer
               renderPassDescriptor:renderPassDescriptor];

  [commandBuffer presentDrawable:view.currentDrawable];
  [commandBuffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
  [_scene setSize:size];
}

@end
