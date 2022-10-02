//
//  GSRobot.h
//  XBolo
//
//  Created by Michael Ash on 9/7/09.
//

#import <Cocoa/Cocoa.h>


@protocol GSRobot;
@class GSRobotGameState;

NS_ASSUME_NONNULL_BEGIN

@interface GSRobot : NSObject
{
    NSBundle *_bundle;
    id <GSRobot> _robot;
    
    NSConditionLock *_condLock;
    GSRobotGameState *_gamestate;
    NSMutableArray<NSString*> *_messages;
    BOOL _halt;
}

@property (class, copy, readonly) NSArray<GSRobot*> *availableRobots;
@property (class, copy, readonly) NSArray<NSURL*> *searchURLs;

@property (readonly) NSString *name;
- (NSString *)name;

- (BOOL)loadWithError:(NSError*__nullable*__nullable)error;

/// just cleans up memory, does not actually unload code (which is enormously dangerous)
- (void)unload;

/// call with client locked
- (void)step;
- (void)receivedMessage: (NSString *)message;

@end

NS_ASSUME_NONNULL_END
