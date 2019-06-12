//
//  GSBoloViews.h
//  Mac OS X
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GSBoloViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface GSBoloViews : NSObject

+ (void)refresh;
+ (void)addView:(id<GSBoloViewProtocol>)view;
+ (void)removeView:(id<GSBoloViewProtocol>)view;

@end

NS_ASSUME_NONNULL_END
