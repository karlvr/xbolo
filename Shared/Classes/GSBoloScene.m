//
//  GSBoloScene.m
//  XBolo
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import "GSBoloScene.h"

#import "bolo.h"
#import "images.h"
#import "client.h"

static SKTextureAtlas *_tilesAtlas;
static SKTextureAtlas *_spritesAtlas;

@interface GSBoloScene() {
  SKTileSet *_tileSet;
  SKTileMapNode *_map;
  SKTileMapNode *_mineMap;
  SKTileMapNode *_fogMap;
  SKSpriteNode *_player;
  NSMutableArray<SKSpriteNode *> *_shells;
  NSMutableArray<SKSpriteNode *> *_builders;
  NSMutableArray<SKSpriteNode *> *_otherPlayers;
  NSMutableArray<SKSpriteNode *> *_explosions;
  NSMutableArray<SKSpriteNode *> *_parachutingBuilders;
  SKSpriteNode *_pointer;
  SKSpriteNode *_selector;
  SKSpriteNode *_crosshair;
  NSMutableArray<SKLabelNode *> *_otherPlayerLabels;
  SKLabelNode *_gameStateLabel;
  SKCameraNode *_camera;
  BOOL _autoScroll;
  BOOL _scrolling;
  CGPoint _scroll;

  NSView *_nonSKView;
}

@property (nonatomic, readonly) NSView *anyView;

@end

NSString *spriteName(GSImage image) {
  int row = image / 16;
  int col = image % 16;
  int tileNo = (15 - row) * 16 + col;
  return [NSString stringWithFormat:@"sprite%03i", tileNo];
}

void hideUnusedNodes(NSArray<SKNode *> *nodes, NSUInteger fromIndex) {
  NSUInteger count = nodes.count;
  for (NSUInteger i = fromIndex; i < count; i++) {
    nodes[i].hidden = YES;
  }
}

CGFloat CGPointDist(CGPoint a, CGPoint b) {
  return sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}

CGPoint CGPointSubtract(CGPoint a, CGPoint b) {
  return CGPointMake(a.x - b.x, a.y - b.y);
}

CGPoint CGPointAdd(CGPoint a, CGPoint b) {
  return CGPointMake(a.x + b.x, a.y + b.y);
}

@implementation GSBoloScene

+ (void)initialize {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _tilesAtlas = [SKTextureAtlas atlasNamed:@"TilesAtlas"];
    _spritesAtlas = [SKTextureAtlas atlasNamed:@"SpritesAtlas"];
  });
}

- (instancetype)initWithSize:(CGSize)size {
  if (self = [super initWithSize:size]) {
    _autoScroll = YES;

    _shells = [NSMutableArray array];
    _builders = [NSMutableArray array];
    _otherPlayers = [NSMutableArray array];
    _explosions = [NSMutableArray array];
    _parachutingBuilders = [NSMutableArray array];
    _otherPlayerLabels = [NSMutableArray array];

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

    /* Fog image tile */
    {
      NSString *tileName = [self tileName:UNKNOWNIMAGE - 1];
      SKTileDefinition *tileDef = [[SKTileDefinition alloc] initWithTexture:[_tilesAtlas textureNamed:tileName]];
      SKTileGroup *group = [[SKTileGroup alloc] initWithTileDefinition:tileDef];
      [tileGroups addObject:group];
    }

    _tileSet = [[SKTileSet alloc] initWithTileGroups:tileGroups];

    SKTileMapNode *map = [[SKTileMapNode alloc] initWithTileSet:_tileSet columns:WIDTH rows:WIDTH tileSize:CGSizeMake(IMAGEWIDTH, IMAGEWIDTH) fillWithTileGroup:tileGroups[MINE00IMAGE + 1]];
    map.position = CGPointMake(2048, 2048);

    SKTileMapNode *mineMap = [[SKTileMapNode alloc] initWithTileSet:_tileSet columns:WIDTH rows:WIDTH tileSize:CGSizeMake(IMAGEWIDTH, IMAGEWIDTH)];
    mineMap.position = map.position;

    SKTileMapNode *fogMap = [[SKTileMapNode alloc] initWithTileSet:_tileSet columns:WIDTH rows:WIDTH tileSize:CGSizeMake(IMAGEWIDTH, IMAGEWIDTH)];
    fogMap.position = map.position;

    [self addChild:map];
    [self addChild:mineMap];
    [self addChild:fogMap];
    _map = map;
    _mineMap = mineMap;
    _fogMap = fogMap;

    _camera = [[SKCameraNode alloc] init];
    [self addChild:_camera];
    self.camera = _camera;
  }
  return self;
}

- (void)didMoveToNonSKView:(NSView *)view {
  _nonSKView = view;
}

- (NSView *)anyView {
  if (_nonSKView) {
    return _nonSKView;
  } else {
    return self.view;
  }
}

- (SKSpriteNode *)nextSprite:(NSMutableArray<SKSpriteNode *> *)sprites nextSprite:(NSUInteger *)nextSprite image:(GSImage)image {
  SKSpriteNode *sprite;
  if (*nextSprite < sprites.count) {
    sprite = sprites[*nextSprite];
    *nextSprite += 1;
  } else {
    sprite = [[SKSpriteNode alloc] initWithTexture:[_spritesAtlas textureNamed:spriteName(image)]];
    [sprites addObject:sprite];
    [self addChild:sprite];
    *nextSprite += 1;
  }
  return sprite;
}

- (SKLabelNode *)nextLabel:(NSMutableArray<SKLabelNode *> *)labels
                 nextLabel:(NSUInteger *)nextLabel
                  fontName:(NSString *)fontName
                  fontSize:(CGFloat)fontSize
                 fontColor:(NSColor *)fontColor {
  SKLabelNode *label;
  if (*nextLabel < labels.count) {
    label = labels[*nextLabel];
    *nextLabel += 1;
  } else {
    label = [[SKLabelNode alloc] initWithFontNamed:fontName];
    label.fontSize = fontSize;
    label.fontColor = fontColor;
    [labels addObject:label];
    [self addChild:label];
    *nextLabel += 1;
  }
  return label;
}

- (void)drawSprite:(SKSpriteNode *)sprite image:(GSImage)image at:(Vec2f)point fraction:(CGFloat)vis {
  if (vis > 0.00001) {
    sprite.texture = [_spritesAtlas textureNamed:spriteName(image)];
    CGPoint p = CGPointMake(floor(point.x*16.0), floor((FWIDTH - point.y)*16.0)); // TODO this +1 is a hack?
    sprite.position = p;
    sprite.hidden = NO;
  } else {
    sprite.hidden = YES;
  }
}

- (void)drawSprite:(SKSpriteNode *)sprite at:(Vec2f)point fraction:(CGFloat)vis {
  if (vis > 0.00001) {
    CGPoint p = CGPointMake(floor(point.x*16.0), floor((FWIDTH - point.y)*16.0)); // TODO this +1 is a hack?
    sprite.position = p;
    sprite.hidden = NO;
  } else {
    sprite.hidden = YES;
  }
}

- (void)drawLabel:(SKLabelNode *)label text:(NSString *)text at:(Vec2f)point {
  label.text = text;
  CGPoint p = CGPointMake(floor(point.x*16.0), floor((FWIDTH - point.y)*16.0)); // TODO this +1 is a hack?
  label.position = p;
  label.hidden = NO;
}

- (void)update {
  [self refreshTiles];
  [self refreshSprites];
  [self updateCamera];
}

- (void)updateCamera {
  if (_scrolling || !_camera) {
    return;
  }

  if (_autoScroll) {
    CGFloat cameraDistance = CGPointDist(_camera.position, _player.position);
    if (cameraDistance > 16 * 8) {
      [self moveCamera:_player.position animated:YES];
    }
  } else if (!CGPointEqualToPoint(_scroll, CGPointZero)) {
    [self moveCamera:CGPointAdd(_camera.position, _scroll) animated:NO];
  }
}

- (void)moveCamera:(CGPoint)position animated:(BOOL)animated {
  const CGPoint delta = CGPointSubtract(position, _camera.position);

  const NSPoint aPoint = [self.anyView convertPoint:self.anyView.window.mouseLocationOutsideOfEventStream fromView:nil];
  const BOOL moveCursor = [self.anyView mouse:aPoint inRect:self.anyView.visibleRect];

  if (animated) {
    _scrolling = YES;

    SKAction *action = [SKAction moveTo:position duration:0.2];
    if (moveCursor) {
      CGEventRef event = CGEventCreate(NULL);
      CGPoint mouseLocation = CGEventGetLocation(event);
      CFRelease(event);

      action.timingFunction = ^float(float value) {
        CGPoint newMouseLocation = mouseLocation;
        newMouseLocation.x -= (delta.x * value);
        newMouseLocation.y += (delta.y * value);
        CGWarpMouseCursorPosition(newMouseLocation);

        return value;
      };
    }
    [_camera runAction:action completion:^{
      self->_scrolling = NO;
    }];
  } else {
    _camera.position = position;
    if (moveCursor) {
      CGEventRef event = CGEventCreate(NULL);
      CGPoint mouseLocation = CGEventGetLocation(event);
      CFRelease(event);

      CGPoint newMouseLocation = mouseLocation;
      newMouseLocation.x -= delta.x;
      newMouseLocation.y += delta.y;
      CGWarpMouseCursorPosition(newMouseLocation);
    }
  }
}

- (void)scroll:(CGPoint)delta {
  _scroll = delta;
  if (!CGPointEqualToPoint(_scroll, CGPointZero)) {
    _autoScroll = NO;
  }
}

- (void)activateAutoScroll {
  _scroll = CGPointZero;
  _autoScroll = YES;
}

- (void)deactivateAutoScroll {
  _autoScroll = NO;
}

- (void)refreshSprites {
  int i;
  struct ListNode *node;
  NSUInteger nextSprite;
  NSUInteger nextLabel;

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
  hideUnusedNodes(_builders, nextSprite);

  /* draw other players */
  nextSprite = 0;
  nextLabel = 0;
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
        SKLabelNode *label = [self nextLabel:_otherPlayerLabels nextLabel:&nextLabel fontName:@"Helvetica" fontSize:9 fontColor:[NSColor whiteColor]];
        NSString *text = [NSString stringWithCString:client.players[i].name encoding:NSUTF8StringEncoding];
        [self drawLabel:label text:text at:client.players[i].tank];
      }
    }
  }
  hideUnusedNodes(_otherPlayers, nextSprite);
  hideUnusedNodes(_otherPlayerLabels, nextLabel);

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
  hideUnusedNodes(_shells, nextSprite);

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
  hideUnusedNodes(_explosions, nextSprite);

  /* draw parachuting builders */
  nextSprite = 0;
  for (i = 0; i < MAX_PLAYERS; i++) {
    if (client.players[i].connected) {
      if (client.players[i].builderstatus == kBuilderParachute) {
        SKSpriteNode *sprite = [self nextSprite:_parachutingBuilders nextSprite:&nextSprite image:BUILD2IMAGE];
        [self drawSprite:sprite at:client.players[i].builder fraction:fogvis(client.players[i].builder)];
      }
    }
  }
  hideUnusedNodes(_parachutingBuilders, nextSprite);

  /* draw selector */
  {
    NSPoint aPoint;
    aPoint = [self.anyView convertPoint:self.anyView.window.mouseLocationOutsideOfEventStream fromView:nil];
    if ([self.anyView mouse:aPoint inRect:self.anyView.visibleRect]) {
      aPoint = [self convertPointFromView:aPoint];

      if (!_selector) {
        _selector = [[SKSpriteNode alloc] initWithTexture:[_spritesAtlas textureNamed:spriteName(SELETRIMAGE)]];
        [self addChild: _selector];
      }

      [self drawSprite:_selector at:make2f(floor(aPoint.x/16.0) + 0.5, floor(FWIDTH - ((aPoint.y + 0.5)/16.0)) + 0.5) fraction:1.0];
    }
  }

  /* draw crosshair */
  if (!client.players[client.player].dead) {
    if (!_crosshair) {
      _crosshair = [[SKSpriteNode alloc] initWithTexture:[_spritesAtlas textureNamed:spriteName(CROSSHIMAGE)]];
      [self addChild:_crosshair];
    }
    [self drawSprite:_crosshair image:CROSSHIMAGE at:add2f(client.players[client.player].tank, mul2f(dir2vec(client.players[client.player].dir), client.range)) fraction:1.0];
  } else {
    _crosshair.hidden = YES;
  }

  if (client.pause) {
    if (!_gameStateLabel) {
      _gameStateLabel = [[SKLabelNode alloc] initWithFontNamed:@"Helvetica"];
      _gameStateLabel.fontColor = [NSColor whiteColor];
      _gameStateLabel.fontSize = 90;
      _gameStateLabel.position = self.position;
      [_camera addChild: _gameStateLabel];
    }

    if (client.pause == -1) {
      _gameStateLabel.text = @"Paused";
    } else {
      NSString *text = [NSString stringWithFormat:@"Resume in %i", client.pause];
      _gameStateLabel.text = text;
    }
    _gameStateLabel.hidden = NO;
  } else {
    _gameStateLabel.hidden = YES;
  }
}

- (CGPoint)convertPointFromView:(CGPoint)point {
  if (self.view) {
    return [super convertPointFromView:point];
  } else if (_nonSKView) {
    CGRect viewBounds = _nonSKView.bounds;
    CGSize sceneSize = self.size;
    CGPoint cameraPos = _camera.position;
    CGFloat xScale = _camera.xScale;
    CGFloat yScale = _camera.yScale;
    sceneSize.width *= xScale;
    sceneSize.height *= yScale;

    return CGPointMake(point.x * sceneSize.width / viewBounds.size.width + cameraPos.x - viewBounds.size.width / 2.0,
                       point.y * sceneSize.height / viewBounds.size.height + cameraPos.y - viewBounds.size.height / 2.0);
  } else {
    NSLog(@"GSBoloScene: No view");
    return point;
  }
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
      [_map setTileGroup:tileGroups[image] forColumn:p->x row:WIDTH - p->y - 1];
    } else {
      [_map setTileGroup:tileGroups[MINE00IMAGE + 1] forColumn:p->x row:WIDTH - p->y - 1];
    }

    /* draw mine */
    if (isMinedTile(client.seentiles, p->x, p->y)) {
      [_mineMap setTileGroup:tileGroups[MINE00IMAGE] forColumn:p->x row:WIDTH - p->y - 1];
    } else {
      [_mineMap setTileGroup:nil forColumn:p->x row:WIDTH - p->y - 1];
    }

    /* draw fog */
    if (client.fog[p->y][p->x] == 0) {
      [_fogMap setTileGroup:tileGroups[MINE00IMAGE + 2] forColumn:p->x row:WIDTH - p->y - 1];
    } else {
      [_fogMap setTileGroup:nil forColumn:p->x row:WIDTH - p->y - 1];
    }
  }
}

- (NSString *)tileName:(GSImage)image {
  /*
   Tiles were previously indexed bottom-left, left to right, moving up, starting at 0 in the bottom-left corner. 16 per row.
   Our tile imsges are numbered 00-255 starting in the top-left.

   */
  int row = image / 16;
  int col = image % 16;
  int tileNo = (15 - row) * 16 + col;
  return [NSString stringWithFormat:@"tile%02i", tileNo];
}

- (void)tankCenter {
  [self moveCamera:_player.position animated:NO];
  [self activateAutoScroll];
}

- (void)nextPillCenter {
  GSPoint square;
  int i, j;
  int gotlock = 0;
  BOOL found = NO;

  TRY
  square.x = _camera.position.x/16.0;
  square.y = FWIDTH - (_camera.position.y/16.0);

  if (lockclient()) LOGFAIL(errno)
    gotlock = 1;

  /* Find the currently centered pillbox */
  for (i = 0; i < client.npills; i++) {
    if (
        client.pills[i].owner == client.player &&
        client.pills[i].armour != ONBOARD && client.pills[i].armour != 0 &&
        square.x == client.pills[i].x && square.y == client.pills[i].y
        ) {
      for (j = (i + 1)%client.npills; j != i; j = (j + 1)%client.npills) {
        if (
            client.pills[j].owner == client.player &&
            client.pills[j].armour != ONBOARD && client.pills[j].armour != 0
            ) {
          square.x = client.pills[j].x;
          square.y = client.pills[j].y;
          if (unlockclient()) LOGFAIL(errno)
            gotlock = 0;
          found = YES;
          SUCCESS
        }
      }

      square.x = client.pills[i].x;
      square.y = client.pills[i].y;
      if (unlockclient()) LOGFAIL(errno)
        gotlock = 0;
      found = YES;
      SUCCESS
    }
  }

  /* Center on the first pillbox */
  for (i = 0; i < client.npills; i++) {
    if (
        client.pills[i].owner == client.player &&
        client.pills[i].armour != ONBOARD && client.pills[i].armour != 0
        ) {
      square.x = client.pills[i].x;
      square.y = client.pills[i].y;
      if (unlockclient()) LOGFAIL(errno)
        gotlock = 0;
      found = YES;
      SUCCESS
    }
  }

  if (unlockclient()) LOGFAIL(errno)
    gotlock = 0;

  CLEANUP
  switch (ERROR) {
    case 0:
      if (found) {
        [self deactivateAutoScroll];
        [self moveCamera:CGPointMake(square.x * 16, (WIDTH - square.y) * 16) animated:NO];
      }
      break;

    default:
      if (gotlock) {
        unlockclient();
      }

      PCRIT(ERROR)
      printlineinfo();
      CLEARERRLOG
      exit(EXIT_FAILURE);
      break;
  }
  END
}

@end
