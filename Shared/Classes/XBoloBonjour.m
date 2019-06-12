//
//  XBoloBonjour.m
//  XBolo
//
//  Created by Karl von Randow on 11/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import "XBoloBonjour.h"
#import "XBoloBonjourKeys.h"

#import "server.h"
#import "client.h"

@interface XBoloBonjour() <NSNetServiceDelegate, NSNetServiceBrowserDelegate> {
  NSNetService *broadcaster;
  NSNetServiceBrowser *listener;
}

@end

@implementation XBoloBonjour

- (void)startPublishing {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self startPublishingOnBackgroundQueue];
  });
}

- (void)startPublishingOnBackgroundQueue {
  broadcaster = [[NSNetService alloc] initWithDomain:@"" type:XBoloBonjourType name:self.serviceName port:getservertcpport()];
  broadcaster.delegate = self;
  [self updatePublishedInfo];
  [broadcaster publish];
}

- (void)updatePublishedInfo {
  if (broadcaster) {
    lockserver();
    NSMutableDictionary<NSString *, NSData *> *ourTxtDict = [[NSMutableDictionary alloc] initWithCapacity:6];
    ourTxtDict[XBoloBonjourPlayerName] = [[NSString stringWithCString:client.players[client.player].name encoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding];
    ourTxtDict[XBoloBonjourMapName] = [self.mapName dataUsingEncoding:NSUTF8StringEncoding];
    ourTxtDict[XBoloBonjourReqiresPassword] = server.passreq ? [@"1" dataUsingEncoding:NSASCIIStringEncoding] : [@"0" dataUsingEncoding:NSASCIIStringEncoding];
    ourTxtDict[XBoloBonjourIsPaused] = server.pause == 0 ? [@"0" dataUsingEncoding:NSASCIIStringEncoding] : [@"1" dataUsingEncoding:NSASCIIStringEncoding];
    //allowjoin
    ourTxtDict[XBoloBonjourCanJoin] = server.allowjoin ? [@"1" dataUsingEncoding:NSASCIIStringEncoding] : [@"0" dataUsingEncoding:NSASCIIStringEncoding];
    int playerCount = 0;
    for (NSInteger i = 0; i < MAX_PLAYERS; i++) {
      if (server.players[i].used) {
        playerCount++;
      }
    }
    unlockserver();
    ourTxtDict[XBoloBonjourPlayerCount] = [[NSString stringWithFormat:@"%i", playerCount] dataUsingEncoding:NSASCIIStringEncoding];

    NSData *txtData = [NSNetService dataFromTXTRecordDictionary:ourTxtDict];

    [broadcaster setTXTRecordData:txtData];
  }
}

- (void)stopPublishing {
  [broadcaster stop];
  broadcaster = nil;
}

- (BOOL)isListening {
  return listener != nil;
}

- (void)startListening {
  listener = [[NSNetServiceBrowser alloc] init];
  listener.delegate = self;
  [listener searchForServicesOfType:XBoloBonjourType inDomain:@""];
}

- (void)stopListening {
  [listener stop];
  listener = nil;

  if (_didStopListeningBlock) {
    _didStopListeningBlock();
  }
}

- (XBoloBonjourGameInfo *)gameInfoFor:(NSNetService *)service {
  XBoloBonjourGameInfo *gameInfo = [[XBoloBonjourGameInfo alloc] init];
  gameInfo.playerName = @"unknown";
  gameInfo.mapName = @"unknown";
  gameInfo.passReq = @"?";
  gameInfo.paused = @"?";
  gameInfo.canJoin = @"?";
  gameInfo.playerCount = @"?";
  NSData *txtData = [service TXTRecordData];
  if (txtData) {
    NSDictionary *txtDict = [NSNetService dictionaryFromTXTRecordData: txtData];
    id val;
    val = txtDict[XBoloBonjourPlayerName];
    if (val) {
      gameInfo.playerName = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
    }
    val = txtDict[XBoloBonjourMapName];
    if (val) {
      gameInfo.mapName = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
    }
    val = txtDict[XBoloBonjourReqiresPassword];
    if (val) {
      NSString *passBool = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
      if ([passBool isEqualToString:@"0"]) {
        gameInfo.passReq = @"No";
      } else {
        gameInfo.passReq = @"Yes";
      }
    }
    val = txtDict[XBoloBonjourIsPaused];
    if (val) {
      NSString *passBool = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
      if ([passBool isEqualToString:@"0"]) {
        gameInfo.paused = @"No";
      } else {
        gameInfo.paused = @"Yes";
      }
    }
    val = txtDict[XBoloBonjourCanJoin];
    if (val) {
      NSString *passBool = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
      if ([passBool isEqualToString:@"0"]) {
        gameInfo.canJoin = @"No";
      } else {
        gameInfo.canJoin = @"Yes";
      }
    }
    val = txtDict[XBoloBonjourPlayerCount];
    if (val) {
      gameInfo.playerCount = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
    }
  }

  gameInfo.hostName = service.hostName;
  gameInfo.port = [NSString stringWithFormat:@"%ld", (long)service.port];
  gameInfo.service = service;
  return gameInfo;
}

#pragma mark - NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
  [service resolveWithTimeout:5];

  XBoloBonjourFoundGameInfoBlock gameInfoBlock = _gameInfoBlock;
  if (!gameInfoBlock) {
    return;
  }

  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    //usleep(500);
    sleep(1);

    XBoloBonjourGameInfo *gameInfo = [self gameInfoFor:service];
    if (!gameInfo.hostName) {
      NSLog(@"Did not get host name from \"%@\"!", service);
      return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      gameInfoBlock(gameInfo);
      service.delegate = self;
    });
  });
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing
{
  if (_gameInfoRemovedBlock) {
    _gameInfoRemovedBlock(service);
  }
}

#pragma mark - NSNetServiceDelegate

- (void)netService:(NSNetService *)service didUpdateTXTRecordData:(NSData *)data
{
  if (service == broadcaster) {
    //We should have been the one to change this...
    return;
  }

  XBoloBonjourFoundGameInfoBlock gameInfoBlock = _gameInfoBlock;
  if (!gameInfoBlock) {
    return;
  }

  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    //usleep(500);
    sleep(1);

    XBoloBonjourGameInfo *gameInfo = [self gameInfoFor:service];
    if (!gameInfo.hostName) {
      NSLog(@"Did not get host name from \"%@\"!", service);
      return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      gameInfoBlock(gameInfo);
    });
  });
}

@end

@implementation XBoloBonjourGameInfo

@end
