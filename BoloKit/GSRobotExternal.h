//
//  GSRobotExternal.h
//  XBolo
//
//  Created by Michael Ash on 9/7/09.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, GSBuilderOperation) {
    BUILDERNILL = -1,
    BUILDERTREE,
    BUILDERROAD,
    BUILDERWALL,
    BUILDERPILL,
    BUILDERMINE,
} ;

typedef NS_ENUM(uint8_t, GSTileType) {
    kWallTile         = 0,
    kRiverTile        = 1,
    kSwampTile        = 2,
    kCraterTile       = 3,
    kRoadTile         = 4,
    kForestTile       = 5,
    kRubbleTile       = 6,
    kGrassTile        = 7,
    kDamagedWallTile  = 8,
    kBoatTile         = 9,
    
    kMinedSwampTile   = 10,
    kMinedCraterTile  = 11,
    kMinedRoadTile    = 12,
    kMinedForestTile  = 13,
    kMinedRubbleTile  = 14,
    kMinedGrassTile   = 15,
    
    kSeaTile,
    kMinedSeaTile,
    kFriendlyBaseTile,
    kHostileBaseTile,
    kNeutralBaseTile,
    kFriendlyPill00Tile,
    kFriendlyPill01Tile,
    kFriendlyPill02Tile,
    kFriendlyPill03Tile,
    kFriendlyPill04Tile,
    kFriendlyPill05Tile,
    kFriendlyPill06Tile,
    kFriendlyPill07Tile,
    kFriendlyPill08Tile,
    kFriendlyPill09Tile,
    kFriendlyPill10Tile,
    kFriendlyPill11Tile,
    kFriendlyPill12Tile,
    kFriendlyPill13Tile,
    kFriendlyPill14Tile,
    kFriendlyPill15Tile,
    kHostilePill00Tile,
    kHostilePill01Tile,
    kHostilePill02Tile,
    kHostilePill03Tile,
    kHostilePill04Tile,
    kHostilePill05Tile,
    kHostilePill06Tile,
    kHostilePill07Tile,
    kHostilePill08Tile,
    kHostilePill09Tile,
    kHostilePill10Tile,
    kHostilePill11Tile,
    kHostilePill12Tile,
    kHostilePill13Tile,
    kHostilePill14Tile,
    kHostilePill15Tile,
    kUnknownTile,
} ;

#if defined(USE_SIMD_H) && USE_SIMD_H
NS_ASSUME_NONNULL_END
#include <simd/simd.h>
NS_ASSUME_NONNULL_BEGIN
typedef vector_float2 Vec2f;
#else
typedef struct Vec2f {
    float x;
    float y;
} Vec2f;
#endif

struct Tank
{
    BOOL friendly;
    Vec2f position;
    int direction;
};

#if INTERNAL_GSROBOT_INCLUDE
#define Shell ExternalShell
#endif
struct Shell
{
    float direction; //!< radians
    Vec2f position;
};

struct Builder
{
    BOOL isParachute;
    Vec2f position;
};

@interface GSRobotGameState: NSObject
@property int worldwidth, worldheight;
@property GSTileType *visibletiles; //!< worldwidth * worldheight elements, row major

@property Vec2f tankposition;
@property Vec2f gunsightposition;
@property int tankdirection; //!< 0-15
@property int tankarmor;
@property int tankshells;
@property int tankmines;
@property int tanktrees;
@property int tankhasboat;
@property int tankpillcount;

//! 0 = dead, 1 = in tank, 2 = out of tank
@property int builderstate;
//! radians, only valid if \c builderstate is out of tank
@property float builderdirection;

@property int tankscount;
@property struct Tank *tanks;

@property int shellscount;
@property struct Shell *shells;

@property int builderscount;
@property struct Builder *builders;

//! array of NSString, may be nil if no messages
@property (copy, nullable) NSArray<NSString*> *messages;
@property (strong) NSMutableData *gamestateData;

@end

#if INTERNAL_GSROBOT_INCLUDE
#undef Shell
#endif

@interface GSRobotCommandState: NSObject
- (instancetype)init;

@property BOOL accelerate;
@property BOOL decelerate;
@property BOOL left;
@property BOOL right;
@property BOOL gunup;
@property BOOL gundown;
@property BOOL mine;
@property BOOL fire;

@property GSBuilderOperation buildercommand;
@property int builderx, buildery;

//! NSStrings containing player names
@property (copy) NSArray<NSString*> *playersToAllyWith;

@end

#define GS_ROBOT_CURRENT_INTERFACE_VERSION 2

NS_SWIFT_NAME(GSRobotProtocol)
@protocol GSRobot <NSObject>

@property (class, readonly) int minimumRobotInterfaceVersionRequired;
- (instancetype)init; // designated initializer
- (GSRobotCommandState *)stepXBoloRobotWithGameState: (GSRobotGameState *)gameState freeFunction: (void (*)(void *))freeF freeContext: (void *)freeCtx;

@end

NS_ASSUME_NONNULL_END
