//
//  GSBoloSKView.h
//  Mac OS X
//
//  Created by Karl von Randow on 30/05/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "GSBoloViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class GSXBoloController;

@interface GSBoloSKView : SKView<GSBoloViewProtocol> {
  IBOutlet GSXBoloController *boloController;
  NSEventModifierFlags modifiers;
}

@end

NS_ASSUME_NONNULL_END
