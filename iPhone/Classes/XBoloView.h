//
//  XBoloView.h
//  XBolo
//
//  Created by Robert Chrzanowski on 6/28/09.
//  Copyright 2009 Robert Chrzanowski. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "GSBoloViewProtocol.h"
#import "XBolo-Swift.h"

@interface XBoloView : SKView <GSBoloViewProtocol> {

}

- (CGPoint)convertToScenePointFromViewPoint:(CGPoint)pt;

@end
