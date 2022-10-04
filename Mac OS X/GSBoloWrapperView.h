//
//  GSBoloWrapperView.h
//  Mac OS X
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GSBoloViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class GSXBoloController;

@interface GSBoloWrapperView : NSView <GSBoloViewProtocol> {
  IBOutlet GSXBoloController *boloController;
}

@end

NS_ASSUME_NONNULL_END
