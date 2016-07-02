//
//  GSRobot.h
//  XBolo
//
//  Created by Michael Ash on 9/7/09.
//

#import <Cocoa/Cocoa.h>


@protocol GSRobot;

@interface GSRobot : NSObject
{
    NSBundle *_bundle;
    id <GSRobot> _robot;
    
    NSConditionLock *_condLock;
    NSMutableData *_gamestateData;
    NSMutableArray *_messages;
    BOOL _halt;
}

+ (NSArray<GSRobot*> *)availableRobots;
#if __has_feature(objc_class_property)
@property (class, copy, readonly) NSArray<id <GSRobot>> *availableRobots;
#endif

@property (readonly) NSString *name;
- (NSString *)name;

- (BOOL)loadWithError:(NSError**)error;
- (NSError *)load NS_SWIFT_UNAVAILABLE("Use `load() throws` instead");

/// just cleans up memory, does not actually unload code (which is enormously dangerous)
- (void)unload;

/// call with client locked
- (void)step;
- (void)receivedMessage: (NSString *)message;

@end
