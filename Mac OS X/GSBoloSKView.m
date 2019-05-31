//
//  GSBoloSKView.m
//  Mac OS X
//
//  Created by Karl von Randow on 30/05/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import "GSBoloSKView.h"

#import "bolo.h"
#import "images.h"
#import "client.h"

static SKTextureAtlas *_tilesAtlas;
static SKTextureAtlas *_spritesAtlas;

@import SpriteKit;

@interface TestScene: SKScene {
  SKTileSet *_tileSet;
  SKTileMapNode *_map;
  SKSpriteNode *_player;
  NSMutableArray<SKSpriteNode *> *_shells;
  NSMutableArray<SKSpriteNode *> *_builders;
  NSMutableArray<SKSpriteNode *> *_otherPlayers;
  NSMutableArray<SKSpriteNode *> *_explosions;
  NSMutableArray<SKSpriteNode *> *_parachutingBuilders;
  SKSpriteNode *_pointer;
  SKSpriteNode *_crosshair;
}

- (void)mapDidUpdate;
- (void)update;

@end

NSString *spriteName(GSImage image) {
  int row = image / 16;
  int col = image % 16;
  int tileNo = (15 - row) * 16 + col;
  return [NSString stringWithFormat:@"sprite%03i", tileNo];
}

void hideUnusedSprites(NSArray<SKSpriteNode *> *sprites, NSUInteger fromIndex) {
  NSUInteger count = sprites.count;
  for (NSUInteger i = fromIndex; i < count; i++) {
    sprites[i].hidden = YES;
  }
}

@implementation TestScene

- (instancetype)initWithSize:(CGSize)size {
  if (self = [super initWithSize:size]) {
    _shells = [NSMutableArray array];
    _builders = [NSMutableArray array];
    _otherPlayers = [NSMutableArray array];
    _explosions = [NSMutableArray array];
    _parachutingBuilders = [NSMutableArray array];
  }
  return self;
}

- (void)didMoveToView:(SKView *)view {
  self.backgroundColor = [NSColor redColor];


  NSMutableArray<SKTileGroup *> *tileGroups = [NSMutableArray array];
  for (GSImage image = 0; image <= MINE00IMAGE; image++) {
    NSString *tileName = [self tileName:image];
    SKTileDefinition *tileDef = [[SKTileDefinition alloc] initWithTexture:[_tilesAtlas textureNamed:tileName]];
    SKTileGroup *group = [[SKTileGroup alloc] initWithTileDefinition:tileDef];
    [tileGroups addObject:group];
  }

  /* Unknown image tile */
  {
    NSString *tileName = [self tileName:UNKNOWNIMAGE];
    SKTileDefinition *tileDef = [[SKTileDefinition alloc] initWithTexture:[_tilesAtlas textureNamed:tileName]];
    SKTileGroup *group = [[SKTileGroup alloc] initWithTileDefinition:tileDef];
    [tileGroups addObject:group];
  }

  _tileSet = [[SKTileSet alloc] initWithTileGroups:tileGroups];
}

- (BOOL)becomeFirstResponder {
  return NO;
}

- (BOOL)acceptsFirstResponder {
  return NO;
}

- (void)mapDidUpdate {
  if (_map) {
    [_map removeFromParent];
    _map = nil;
  }

  NSArray<SKTileGroup *> *tileGroups = _tileSet.tileGroups;

  SKTileMapNode *map = [[SKTileMapNode alloc] initWithTileSet:_tileSet columns:WIDTH rows:WIDTH tileSize:CGSizeMake(IMAGEWIDTH, IMAGEWIDTH) fillWithTileGroup:tileGroups[MINE00IMAGE + 1]];
  map.position = CGPointMake(2048, 2048);

  for (int y = 0; y <= WIDTH; y++) {
    for (int x = 0; x <= WIDTH; x++) {
      GSImage image = client.images[y][x];
      if (image != UNKNOWNIMAGE) {
        [map setTileGroup:tileGroups[image] forColumn:x row:WIDTH - y];
      } else {
        [map setTileGroup:tileGroups[MINE00IMAGE + 1] forColumn:x row:WIDTH - y];
      }
    }
  }

  [self addChild:map];
  _map = map;
}

- (SKSpriteNode *)nextSprite:(NSMutableArray<SKSpriteNode *> *)sprites nextSprite:(NSUInteger *)nextSprite image:(GSImage)image {
  SKSpriteNode *sprite;
  if (*nextSprite < sprites.count) {
    sprite = sprites[*nextSprite];
    sprite.texture = [_spritesAtlas textureNamed:spriteName(image)];
    *nextSprite += 1;
  } else {
    sprite = [[SKSpriteNode alloc] initWithTexture:[_spritesAtlas textureNamed:spriteName(image)]];
    [sprites addObject:sprite];
    [self addChild:sprite];
    *nextSprite += 1;
  }
  return sprite;
}

- (void)drawSprite:(SKSpriteNode *)sprite image:(GSImage)image at:(Vec2f)point fraction:(CGFloat)vis {
  if (vis > 0.00001) {
    sprite.texture = [_spritesAtlas textureNamed:spriteName(image)];
    CGPoint p = CGPointMake(floor(point.x*16.0), floor((FWIDTH - point.y + 1)*16.0)); // TODO this +1 is a hack?
    sprite.position = p;
    sprite.hidden = NO;
  } else {
    sprite.hidden = YES;
  }
}

- (void)update {
  [self refreshTiles];

  int i;
  struct ListNode *node;
  char *string = NULL;
  NSUInteger nextSprite;

  /* draw builders */
  nextSprite = 0;
  for (i = 0; i < MAX_PLAYERS; i++) {
    if (client.players[i].connected) {
      switch (client.players[i].builderstatus) {
        case kBuilderGoto:
        case kBuilderWork:
        case kBuilderWait:
        case kBuilderReturn: {
          GSImage image = (client.players[client.player].seq/5)%2 ? BUILD0IMAGE : BUILD1IMAGE;
          SKSpriteNode *sprite = [self nextSprite:_builders nextSprite:&nextSprite image:image];
          [self drawSprite:sprite image:image at:client.players[i].builder fraction:calcvis(client.players[i].builder)];
          break;
        }
        default:
          break;
      }
    }
  }
  hideUnusedSprites(_builders, nextSprite);

  /* draw other players */
  nextSprite = 0;
  for (i = 0; i < MAX_PLAYERS; i++) {
    if (client.players[i].connected && i != client.player && !client.players[i].dead) {
      float vis;

      vis = calcvis(client.players[i].tank);

      SKSpriteNode *sprite = [self nextSprite:_otherPlayers nextSprite:&nextSprite image:FTNK00IMAGE];
      if
        (
         (client.players[client.player].alliance & (1 << i)) &&
         (client.players[i].alliance & (1 << client.player))
         ) {
          [self drawSprite:sprite image:(client.players[i].boat ? FTKB00IMAGE : FTNK00IMAGE) + (((int)(client.players[i].dir/(kPif/8.0) + 0.5))%16) at:client.players[i].tank fraction:vis];
        }
      else {
        [self drawSprite:sprite image:(client.players[i].boat ? ETKB00IMAGE : ETNK00IMAGE) + (((int)(client.players[i].dir/(kPif/8.0) + 0.5))%16) at:client.players[i].tank fraction:vis];
      }

      if (vis > 0.90) {
        // TODO
//        [self drawLabel:client.players[i].name at:client.players[i].tank withAttributes:@{NSForegroundColorAttributeName: [NSColor whiteColor]}];
      }
    }
  }
  hideUnusedSprites(_otherPlayers, nextSprite);

  /* draw player */
  if (!client.players[client.player].dead) {
    /* draw tank */
    if (!_player) {
      _player = [[SKSpriteNode alloc] initWithTexture:[_spritesAtlas textureNamed:spriteName(PTNK00IMAGE)]];
      [self addChild:_player];
    }
    GSImage image = (client.players[client.player].boat ? PTKB00IMAGE : PTNK00IMAGE) + (((int)(client.players[client.player].dir/(kPif/8.0) + 0.5))%16);
    [self drawSprite:_player image:image at:client.players[client.player].tank fraction:1.0];
  } else {
    _player.hidden = YES;
  }

  /* draw shells */
  nextSprite = 0;
  for (i = 0; i < MAX_PLAYERS; i++) {
    if (client.players[i].connected) {
      struct ListNode *node;

      for (node = nextlist(&client.players[i].shells); node != NULL; node = nextlist(node)) {
        struct Shell *shell;

        shell = ptrlist(node);

        GSImage image = SHELL0IMAGE + (((int)(shell->dir/(kPif/8.0) + 0.5))%16);
        SKSpriteNode *sprite = [self nextSprite:_shells nextSprite:&nextSprite image:image];
        [self drawSprite:sprite image:image at:shell->point fraction:fogvis(shell->point)];
      }
    }
  }
  hideUnusedSprites(_shells, nextSprite);

  /* draw explosions */
  node = nextlist(&client.explosions);

  nextSprite = 0;
  while (node != NULL) {
    struct Explosion *explosion;
    float f;

    explosion = ptrlist(node);
    f = ((float)explosion->counter)/EXPLOSIONTICKS;

    SKSpriteNode *sprite = [self nextSprite:_explosions nextSprite:&nextSprite image:EXPLO0IMAGE];
    [self drawSprite:sprite image:EXPLO0IMAGE + ((EXPLO5IMAGE - EXPLO0IMAGE)*f) at:explosion->point fraction:fogvis(explosion->point)];

    node = nextlist(node);
  }

  for (i = 0; i < MAX_PLAYERS; i++) {
    if (client.players[i].connected) {
      node = nextlist(&client.players[i].explosions);

      while (node != NULL) {
        struct Explosion *explosion;
        float f;

        explosion = ptrlist(node);
        f = ((float)explosion->counter)/EXPLOSIONTICKS;

        SKSpriteNode *sprite = [self nextSprite:_explosions nextSprite:&nextSprite image:EXPLO0IMAGE];
        [self drawSprite:sprite image:EXPLO0IMAGE + ((EXPLO5IMAGE - EXPLO0IMAGE)*f) at:explosion->point fraction:fogvis(explosion->point)];

        node = nextlist(node);
      }
    }
  }
  hideUnusedSprites(_explosions, nextSprite);

  /* draw parachuting builders */
  nextSprite = 0;
  for (i = 0; i < MAX_PLAYERS; i++) {
    if (client.players[i].connected) {
      if (client.players[i].builderstatus == kBuilderParachute) {
        SKSpriteNode *sprite = [self nextSprite:_parachutingBuilders nextSprite:&nextSprite image:BUILD2IMAGE];
        [self drawSprite:sprite image:BUILD2IMAGE at:client.players[i].builder fraction:fogvis(client.players[i].builder)];
      }
    }
  }
  hideUnusedSprites(_parachutingBuilders, nextSprite);

  /* draw selector */
//  {
//    NSPoint aPoint;
//    aPoint = [self convertPoint:self.window.mouseLocationOutsideOfEventStream fromView:nil];
//    if ([self mouse:aPoint inRect:self.visibleRect]) {
//      [self drawSprite:SELETRIMAGE at:make2f(floor(aPoint.x/16.0) + 0.5, floor(FWIDTH - ((aPoint.y + 0.5)/16.0)) + 0.5) fraction:1.0];
//    }
//  }

  /* draw crosshair */
  if (!client.players[client.player].dead) {
    if (!_crosshair) {
      _crosshair = [[SKSpriteNode alloc] initWithTexture:[_spritesAtlas textureNamed:spriteName(CROSSHIMAGE)]];
      [self addChild:_crosshair];
    }
    [self drawSprite:_crosshair image:CROSSHIMAGE at:add2f(client.players[client.player].tank, mul2f(dir2vec(client.players[client.player].dir), client.range)) fraction:1.0];
  }

//  if (client.pause) {
//    NSRect rect;
//    rect = self.visibleRect;
//
//    if (client.pause == -1) {
//      [self drawLabel:"Paused" at:make2f((rect.origin.x + rect.size.width*0.5)/16.0, (256.0*16.0 - (rect.origin.y + rect.size.height*0.5))/16.0) withAttributes:@{NSFontAttributeName: [NSFont fontWithName:@"Helvetica" size:90], NSForegroundColorAttributeName: [NSColor whiteColor]}];
//    }
//    else {
//      if (asprintf(&string, "Resume in %d", client.pause) == -1) LOGFAIL(errno)
//        [self drawLabel:string at:make2f((rect.origin.x + rect.size.width*0.5)/16.0, (256.0*16.0 - (rect.origin.y + rect.size.height*0.5))/16.0) withAttributes:@{NSFontAttributeName: [NSFont fontWithName:@"Helvetica" size:90], NSForegroundColorAttributeName: [NSColor whiteColor]}];
//      free(string);
//      string = NULL;
//    }
//  }
}

- (void)refreshTiles {
  struct ListNode *node;

  NSArray<SKTileGroup *> *tileGroups = _tileSet.tileGroups;

  for (node = nextlist(&client.changedtiles); node != NULL; node = nextlist(node)) {
    GSPoint *p;
    GSImage image;

    p = (GSPoint *)ptrlist(node);
    image = client.images[p->y][p->x];

    if (image != UNKNOWNIMAGE) {
      [_map setTileGroup:tileGroups[image] forColumn:p->x row:WIDTH - p->y];
    } else {
      [_map setTileGroup:tileGroups[MINE00IMAGE + 1] forColumn:p->x row:WIDTH - p->y];
    }

      /* draw mine */
//      if (isMinedTile(client.seentiles, p->x, p->y)) {
//        NSRect mineImageRect;
//
//        mineImageRect = NSMakeRect((MINE00IMAGE%16)*16 * _tilesScale, (MINE00IMAGE/16)*16 * _tilesScale, 16.0 * _tilesScale, 16.0 * _tilesScale);
//        [_bestTiles drawInRect:dstRect fromRect:mineImageRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:NO hints:nil];
//      }
//
//      /* draw fog */
//      if (client.fog[p->y][p->x] == 0) {
//        [[[NSColor blackColor] colorWithAlphaComponent:0.5] set];
//        [NSBezierPath fillRect:dstRect];
//      }
  }
}

- (NSString *)tileName:(GSImage)image {
  /*
   Tiles were previously indexed bottom-left, left to right, moving up, starting at 0 in the bottom-lefgt corner. 16 per row.
   Our tile imsges are numbered 00-255 starting in the top-left.

   */
  int row = image / 16;
  int col = image % 16;
  int tileNo = (15 - row) * 16 + col;
  return [NSString stringWithFormat:@"tile%02i", tileNo];
}

@end

@interface GSBoloSKView() {
  TestScene *_scene;
}

@end

@implementation GSBoloSKView

+ (void)initialize {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _tilesAtlas = [SKTextureAtlas atlasNamed:@"TilesAtlas"];
    _spritesAtlas = [SKTextureAtlas atlasNamed:@"SpritesAtlas"];
  });
}

- (instancetype)initWithFrame:(NSRect)frameRect {
  if (self = [super initWithFrame:frameRect]) {
    self.showsFPS = YES;
    self.showsNodeCount = YES;
    self.preferredFramesPerSecond = 16;

    _scene = [[TestScene alloc] initWithSize:frameRect.size];
    [self presentScene:_scene];
  }
  return self;
}

- (void)mapDidUpdate {
  [_scene mapDidUpdate];
}

- (void)refresh {
  [_scene update];
}

@end
