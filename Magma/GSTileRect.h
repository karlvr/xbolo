//
//  GSTileRect.h
//  XBolo Map Editor
//
//  Created by Robert Chrzanowski on 1/2/10.
//  Copyright 2010 Robert Chrzanowski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "bmap.h"


NS_ASSUME_NONNULL_BEGIN

@interface GSTileRect : NSObject < NSPasteboardReading, NSPasteboardWriting > {
  GSRect rect;
  GSTile *tiles;
}

+ (instancetype)tileRectWithTiles:(const GSTile *)aTiles inRect:(GSRect)aRect;
+ (instancetype)tileRectWithTile:(GSTile)tile inRect:(GSRect)aRect;
+ (instancetype)tileRectWithTileRect:(GSTileRect *)tileRect inRect:(GSRect)aRect;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithTiles:(const GSTile *)aTiles inRect:(GSRect)aRect NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTile:(GSTile)tile inRect:(GSRect)aRect NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTileRect:(GSTileRect *)tileRect inRect:(GSRect)aRect NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type NS_DESIGNATED_INITIALIZER;

@property (readonly) GSRect rect;
- (void)setOrigin:(GSPoint)origin;
- (void)offsetX:(int)dx y:(int)dy;

- (void)drawFilledEllipse:(GSTile)tile;

- (void)drawEllipse:(GSTile)tile;
- (void)drawRectangle:(GSTile)tile;
- (void)drawLine:(GSTile)tile fromPoint:(GSPoint)from toPoint:(GSPoint)to;
- (void)floodFillWithTile:(GSTile)tile atPoint:(GSPoint)point;
- (void)rotateLeft;
- (void)rotateRight;
- (void)flipHorizontal;
- (void)flipVertical;

- (void)copyToTiles:(GSTile *)aTiles;

@end

NS_ASSUME_NONNULL_END
