//
//  GSDisplayLink.h
//  Mac OS X
//
//  Created by Karl von Randow on 30/05/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^GSDisplayLinkCallbackBlock)(void);

/** From https://gist.github.com/CanTheAlmighty/ee76fbf701a61651fe439fcd6d25f41d */
@interface GSDisplayLink : NSObject

@property (copy) GSDisplayLinkCallbackBlock callback;
@property (readonly) BOOL running;

- (instancetype)initWithQueue:(nullable dispatch_queue_t)queue;

- (void)start;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
