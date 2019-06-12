//
//  XBoloBonjour.h
//  XBolo
//
//  Created by Karl von Randow on 11/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XBoloBonjourGameInfo: NSObject

@property (nonatomic, strong) NSString *playerName;
@property (nonatomic, strong) NSString *mapName;
@property (nonatomic, strong) NSString *playerCount;
@property (nonatomic, strong) NSString *passReq;
@property (nonatomic, strong) NSString *canJoin;
@property (nonatomic, strong) NSString *paused;
@property (nonatomic, strong) NSString *hostName;
@property (nonatomic, strong) NSString *port;
@property (nonatomic, strong) NSNetService *service;

@end

typedef void (^XBoloBonjourFoundGameInfoBlock)(XBoloBonjourGameInfo *gameInfo);

@interface XBoloBonjour : NSObject

@property (nonatomic, strong) NSString *serviceName;
@property (nonatomic, readonly, getter=isListening) BOOL listening;
@property (nonatomic, strong) NSString *mapName;

@property (nonatomic, copy, nullable) XBoloBonjourFoundGameInfoBlock gameInfoBlock;
@property (nonatomic, copy, nullable) void (^gameInfoRemovedBlock)(NSNetService *service);
@property (nonatomic, copy, nullable) void (^didStopListeningBlock)(void);

- (void)startPublishing;
- (void)updatePublishedInfo;
- (void)stopPublishing;

- (void)startListening;
- (void)stopListening;

@end

NS_ASSUME_NONNULL_END
