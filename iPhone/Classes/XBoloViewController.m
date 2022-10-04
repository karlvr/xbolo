//
//  XBoloViewController.m
//  XBolo
//
//  Created by Robert Chrzanowski on 6/28/09.
//  Copyright Robert Chrzanowski 2009. All rights reserved.
//

#import "XBoloViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "XBoloView.h"
#import "XBoloBonjour.h"
#import "GSBoloViews.h"
#import "XBolo-Swift.h"

#import "server.h"
#import "client.h"
#include "errchk.h"

#include <netdb.h>

static XBoloViewController *controller = nil;

static int TicksToWaitForRate(double rate) {
  return (1 - rate) * 15 + 1;
}

/* Sound */
static BOOL muteBool;

static NSMutableArray<AVAudioPlayer *> *bubblessounds;
static NSMutableArray<AVAudioPlayer*> *builderdeathsounds;
static NSMutableArray<AVAudioPlayer*> *buildsounds;
static NSMutableArray<AVAudioPlayer*> *sinksounds;
static NSMutableArray<AVAudioPlayer*> *superboomsounds;
static NSMutableArray<AVAudioPlayer*> *explosionsounds;
static NSMutableArray<AVAudioPlayer*> *farbuildsounds;
static NSMutableArray<AVAudioPlayer*> *farbuilderdeathsounds;
static NSMutableArray<AVAudioPlayer*> *farexplosionsounds;
static NSMutableArray<AVAudioPlayer*> *farhittanksounds;
static NSMutableArray<AVAudioPlayer*> *farhitterrainsounds;
static NSMutableArray<AVAudioPlayer*> *farhittreesounds;
static NSMutableArray<AVAudioPlayer*> *farshotsounds;
static NSMutableArray<AVAudioPlayer*> *farsinksounds;
static NSMutableArray<AVAudioPlayer*> *farsuperboomsounds;
static NSMutableArray<AVAudioPlayer*> *fartreesounds;
static NSMutableArray<AVAudioPlayer*> *minesounds;
static NSMutableArray<AVAudioPlayer*> *msgreceivedsounds;
static NSMutableArray<AVAudioPlayer*> *pillshotsounds;
static NSMutableArray<AVAudioPlayer*> *hittanksounds;
static NSMutableArray<AVAudioPlayer*> *tankshotsounds;
static NSMutableArray<AVAudioPlayer*> *hitterrainsounds;
static NSMutableArray<AVAudioPlayer*> *hittreesounds;
static NSMutableArray<AVAudioPlayer*> *treesounds;


@interface XBoloViewController() <UIGestureRecognizerDelegate> {
  XBoloView *_boloView;
  XBoloBonjour *_broadcaster;

  XBoloBuildGestureRecognizer *_buildGesture;
  int builderToolInt;

  XBoloSteerGestureRecognizer *_steerGesture;
  XBoloDriveGestureRecognizer *_driveGesture;
  XBoloShootGestureRecognizer *_shootGesture;
  BOOL _autoSlowDown;
  int _ticks;
  int _lastControlTick;
  int _lastAccelerateTick;
  int _lastBrakeTick;
  int _lastTurnLeftTick;
  int _lastTurnRightTick;
  BOOL _shoot;
  NSTimer *_controlTimer;
}

@end

@interface AVAudioPlayer (NSSound)

+ (AVAudioPlayer *)soundNamed:(NSString *)name;

- (AVAudioPlayer *)copy;

@end

@implementation AVAudioPlayer (NSSound)

+ (AVAudioPlayer *)soundNamed:(NSString *)name {
  NSDataAsset *asset = [[NSDataAsset alloc] initWithName:[@"Sounds/" stringByAppendingString:name]];
  NSError *error = nil;
  return [[AVAudioPlayer alloc] initWithData:asset.data fileTypeHint:@"public.aiff-audio" error:&error];
}

- (AVAudioPlayer *)copy {
  return [[AVAudioPlayer alloc] initWithData:self.data error:NULL];
}

@end
@implementation XBoloViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    [self commonInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    [self commonInit];
    }
    return self;
}

- (void)commonInit {
  controller = self;
  _boloView = [[XBoloView alloc] initWithFrame:CGRectZero];

  [GSBoloViews addView:_boloView];

  _broadcaster = [[XBoloBonjour alloc] init];

  _autoSlowDown = YES;
}

- (void)awakeFromNib {
  [super awakeFromNib];

  // schedule a timer
  [NSTimer scheduledTimerWithTimeInterval:0.0625 target:self selector:@selector(refresh:) userInfo:nil repeats:YES];

  AVAudioPlayer *sound;

  sound = [AVAudioPlayer soundNamed:@"bubbles"];
  bubblessounds = [[NSMutableArray alloc] init];
  [bubblessounds addObject: sound];

  sound = [AVAudioPlayer soundNamed:@"build"];
  buildsounds = [[NSMutableArray alloc] init];
  [buildsounds addObject:sound];
  [buildsounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"builderdeath"];
  builderdeathsounds = [[NSMutableArray alloc] init];
  [builderdeathsounds addObject:sound];
  [builderdeathsounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"explosion"];
  explosionsounds = [[NSMutableArray alloc] init];
  [explosionsounds addObject:sound];
  [explosionsounds addObject:[sound copy]];
  [explosionsounds addObject:[sound copy]];
  [explosionsounds addObject:[sound copy]];
  [explosionsounds addObject:[sound copy]];
  [explosionsounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"fbuild"];
  farbuildsounds = [[NSMutableArray alloc] init];
  [farbuildsounds addObject:sound];
  [farbuildsounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"fbuilderdeath"];
  farbuilderdeathsounds = [[NSMutableArray alloc] init];
  [farbuilderdeathsounds addObject:sound];
  [farbuilderdeathsounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"fexplosion"];
  farexplosionsounds = [[NSMutableArray alloc] init];
  [farexplosionsounds addObject:sound];
  [farexplosionsounds addObject:[sound copy]];
  [farexplosionsounds addObject:[sound copy]];
  [farexplosionsounds addObject:[sound copy]];
  [farexplosionsounds addObject:[sound copy]];
  [farexplosionsounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"fhittank"];
  farhittanksounds = [[NSMutableArray alloc] init];
  [farhittanksounds addObject:sound];
  [farhittanksounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"fhitterrain"];
  farhitterrainsounds = [[NSMutableArray alloc] init];
  [farhitterrainsounds addObject:sound];
  [farhitterrainsounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"fhittree"];
  farhittreesounds = [[NSMutableArray alloc] init];
  [farhittreesounds addObject:sound];
  [farhittreesounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"fshot"];
  farshotsounds = [[NSMutableArray alloc] init];
  [farshotsounds addObject:sound];
  [farshotsounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"fsink"];
  farsinksounds = [[NSMutableArray alloc] init];
  [farsinksounds addObject:sound];
  [farsinksounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"fsuperboom"];
  farsuperboomsounds = [[NSMutableArray alloc] init];
  [farsuperboomsounds addObject:sound];
  [farsuperboomsounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"ftree"];
  fartreesounds = [[NSMutableArray alloc] init];
  [fartreesounds addObject:sound];
  [fartreesounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"hittank"];
  hittanksounds = [[NSMutableArray alloc] init];
  [hittanksounds addObject:sound];
  [hittanksounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"hitterrain"];
  hitterrainsounds = [[NSMutableArray alloc] init];
  [hitterrainsounds addObject:sound];
  [hitterrainsounds addObject:[sound copy]];
  [hitterrainsounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"hittree"];
  hittreesounds = [[NSMutableArray alloc] init];
  [hittreesounds addObject:sound];
  [hittreesounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"mine"];
  minesounds = [[NSMutableArray alloc] init];
  [minesounds addObject:sound];
  [minesounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"msgreceived"];
  msgreceivedsounds = [[NSMutableArray alloc] init];
  [msgreceivedsounds addObject:sound];
  [msgreceivedsounds addObject:[sound copy]];
  [msgreceivedsounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"pillshot"];
  pillshotsounds = [[NSMutableArray alloc] init];
  [pillshotsounds addObject:sound];
  [pillshotsounds addObject:[sound copy]];
  [pillshotsounds addObject:[sound copy]];
  [pillshotsounds addObject:[sound copy]];
  [pillshotsounds addObject:[sound copy]];
  [pillshotsounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"sink"];
  sinksounds = [[NSMutableArray alloc] init];
  [sinksounds addObject:sound];

  sound = [AVAudioPlayer soundNamed:@"superboom"];
  superboomsounds = [[NSMutableArray alloc] init];
  [superboomsounds addObject:sound];

  sound = [AVAudioPlayer soundNamed:@"tankshot"];
  tankshotsounds = [[NSMutableArray alloc] init];
  [tankshotsounds addObject:sound];
  [tankshotsounds addObject:[sound copy]];
  [tankshotsounds addObject:[sound copy]];
  [tankshotsounds addObject:[sound copy]];
  [tankshotsounds addObject:[sound copy]];

  sound = [AVAudioPlayer soundNamed:@"tree"];
  treesounds = [[NSMutableArray alloc] init];
  [treesounds addObject:sound];
  [treesounds addObject:[sound copy]];
  [treesounds addObject:[sound copy]];
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

  self.gameViewContainer.multipleTouchEnabled = YES;

  _boloView.frame = self.gameViewContainer.bounds;
  [self.gameViewContainer addSubview:_boloView];

  _steerGesture = [[XBoloSteerGestureRecognizer alloc] initWithTarget:nil action:nil];
  _steerGesture.delegate = self;
  [self.gameViewContainer addGestureRecognizer:_steerGesture];

  _driveGesture = [[XBoloDriveGestureRecognizer alloc] initWithTarget:nil action:nil];
  XBoloControlPanelViewController *controlPanel = self.childViewControllers[0];
  [controlPanel.driveGestureView addGestureRecognizer:_driveGesture];

  _buildGesture = [[XBoloBuildGestureRecognizer alloc] initWithTarget:self action:@selector(doBuildGesture)];
  _buildGesture.delegate = self;
  [self.gameViewContainer addGestureRecognizer:_buildGesture];

  _shootGesture = [[XBoloShootGestureRecognizer alloc] initWithTarget:self action:@selector(doShootGesture)];
  _shootGesture.delegate = self;
  [self.gameViewContainer addGestureRecognizer:_shootGesture];

  /* We need the shoot gesture to fail before the build gesture detects, as shoot is two taps, build is one. */
  [_buildGesture requireGestureRecognizerToFail:_shootGesture];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

TRY
//  [_boloView refresh];
  NSURL *mapURL = [[NSBundle mainBundle] URLForResource:@"Everard Island" withExtension:@"map"];

  NSData *mapData = nil;
  mapData = [NSData dataWithContentsOfURL:mapURL];

  int timelimit = 1800;
  struct Domination domination;
  domination.basecontrol = 30;

  int paused = 0;
  BOOL hostUPnPBool = NO;
  int hostPortNumber = 50000;
  BOOL hostPasswordBool = NO;
  NSString *hostPasswordString = nil;
  BOOL hostTimeLimitBool = NO;
  BOOL hostHiddenMinesBool = YES;
  int hostGameTypeNumber = 0;
  NSString *playerNameString = @"Newbie";

  if (setupserver(paused, mapData.bytes, mapData.length, hostUPnPBool ? 0 : hostPortNumber, hostPasswordBool ? hostPasswordString.UTF8String : NULL, hostTimeLimitBool ? timelimit : 0, hostHiddenMinesBool, 0, hostGameTypeNumber, &domination)) LOGFAIL(errno)
  if (startserverthread()) LOGFAIL(errno)
  if (startclient("localhost", getservertcpport(), playerNameString.UTF8String, hostPasswordBool ? hostPasswordString.UTF8String : NULL)) LOGFAIL(errno)
  [_boloView reset];

  _buildGesture.scene = _boloView.scene;

  NSString *bonjourName = [NSString stringWithFormat:@"%@ (%@)", UIDevice.currentDevice.name, playerNameString];
  _broadcaster.serviceName = bonjourName;
  _broadcaster.mapName = [[[mapURL path] lastPathComponent] stringByDeletingPathExtension];
  [_broadcaster startPublishing];

  _controlTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60 target:self selector:@selector(controlTick) userInfo:nil repeats:YES];
  
CLEANUP

END
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (BOOL)prefersStatusBarHidden {
  return YES;
}

#pragma mark -

- (void)setPlayerStatus:(NSString *)aString {

}

- (void)setJoinProgressStatusTextField:(NSString *)aString {

}

- (void)setJoinProgressIndicator:(NSNumber *)aString {

}

- (void)joinSuccess {

}

- (void)setTankStatusBars {
//  playerKillsTextField.stringValue = [NSString stringWithFormat:@"%d", client.kills];
//  playerDeathsTextField.stringValue = [NSString stringWithFormat:@"%d", client.deaths];
//  playerShellsStatusBar.value = ((CGFloat)client.shells)/MAXSHELLS;
//  playerMinesStatusBar.value = ((CGFloat)client.mines)/MAXMINES;
//  playerArmourStatusBar.value = ((CGFloat)client.armour)/MAXARMOUR;
//  playerTreesStatusBar.value = ((CGFloat)client.trees)/MAXTREES;
}

- (void)setPillStatus:(NSString *)aString {

}

- (void)setBaseStatus:(NSString *)aString {

}

- (void)printMessage:(NSAttributedString *)aString {
  NSLog(@"MESSAGE: %@", [aString string]);
}

- (void)sendMessageToRobot:(NSString *)message {
  // TODO
}

- (void)clientLoopUpdate {
  _ticks++;
}

- (void)refresh:(NSTimer *)aTimer {
  int i;
  int base = -1;
  CGFloat dist = 8.0, dist2;
  BOOL gotlock = 0;
  static int counter = 0;

  TRY
  if (client_running) {
    counter++;

    if (lockclient()) LOGFAIL(errno)
      gotlock = 1;

    if (client.player != -1) {
      /* make sure tank is visible if just spawned */
      int centerTank = 0;
      if (client.spawned) {
        if(client.deaths == 0)
          centerTank = 1; // center it if this is the very first spawn
        else
        {
//          NSRect rect;
//          rect.size.width = rect.size.height = 16 * 16 * kZoomLevels[zoomLevel];
//          rect.origin.x = ((client.players[client.player].tank.x + 0.5)*16.0) - rect.size.width*0.5;
//          rect.origin.y = ((FWIDTH - (client.players[client.player].tank.y + 0.5))*16.0) - rect.size.height*0.5;
//
//          [boloView scrollToVisible:client.players[client.player].tank];
        }
        if (unlockclient()) LOGFAIL(errno)
          gotlock = 0;

        client.spawned = 0;
      }
      if(centerTank)
        [_boloView tankCenter];
      [GSBoloViews refresh];

      if (counter%2) {
        switch (client.players[client.player].builderstatus) {
          case kBuilderGoto:
          case kBuilderWork:
          case kBuilderWait:
          case kBuilderReturn:
          {
            Vec2f diff;
            float newdir;

            diff = sub2f(client.players[client.player].builder, client.players[client.player].tank);
            newdir = vec2dir(diff);

//            builderStatusView.state = GSBuilderStatusViewStateDirection;
//            builderStatusView.direction = newdir;
          }

            break;

          case kBuilderParachute:
//            builderStatusView.state = GSBuilderStatusViewStateDead;
            break;

          case kBuilderReady:
//            builderStatusView.state = GSBuilderStatusViewStateReady;
            break;

          default:
            assert(0);
            break;
        }

        // update base status bars
        for (i = 0; i < client.nbases; i++) {
          if (
              client.bases[i].owner != NEUTRAL &&
              (client.players[client.bases[i].owner].alliance & (1 << client.player)) &&
              (client.players[client.player].alliance & (1 << client.bases[i].owner))
              ) {
            dist2 = mag2f(sub2f(client.players[client.player].tank, make2f(client.bases[i].x + 0.5, client.bases[i].y + 0.5)));

            if (dist2 < dist) {
              base = i;
              dist = dist2;
            }
          }
        }

//        if (base != -1) {
//          baseArmourStatusBar.value = (CGFloat)client.bases[base].armour/(CGFloat)MAX_BASE_ARMOUR;
//          baseShellsStatusBar.value = (CGFloat)client.bases[base].shells/(CGFloat)MAX_BASE_SHELLS;
//          baseMinesStatusBar.value = (CGFloat)client.bases[base].mines/(CGFloat)MAX_BASE_MINES;
//        }
//        else {
//          baseShellsStatusBar.value = 0.0;
//          baseMinesStatusBar.value = 0.0;
//          baseArmourStatusBar.value = 0.0;
//        }
      }
    }

    if (unlockclient()) LOGFAIL(errno)
      gotlock = 0;
  }

  CLEANUP
  switch (ERROR) {
    case 0:
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

#pragma mark - Controls

- (void)doBuildGesture {
//  CGPoint point = [_buildGesture locationInView:self.gameViewContainer];
//  point = [_boloView convertToScenePointFromViewPoint:point];

  CGPoint point = [_buildGesture readNextBuildLocation];
  [self mouseEvent:GSMakePoint(point.x/16.0, WIDTH - (int)(point.y/16.0) - 1)];

  NSLog(@"BUILD GESTURE");
}

- (void)doShootGesture {
  if (_shootGesture.state == UIGestureRecognizerStateBegan || _shootGesture.state == UIGestureRecognizerStateChanged) {
    _shoot = YES;
  } else {
    _shoot = NO;
  }
}

// mouse event method
- (void)mouseEvent:(GSPoint)point {
  int gotlock = 0;

TRY
  if (GSPointInRect(GSMakeRect(0, 0, WIDTH, WIDTH), point)) {
    // lock client
    if (lockclient()) LOGFAIL(errno)
    gotlock = 1;

    buildercommand(builderToolInt, point);

    // unlock client
    if (unlockclient()) LOGFAIL(errno)
    gotlock = 0;
  }

CLEANUP
  switch (ERROR) {
  case 0:
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

- (void)controlTick {
  const int ticksDiff = _ticks - _lastControlTick;
//  if (ticksDiff == 0) {
//    NSLog(@"drop");
//    return;
//  } else if (ticksDiff > 1) {
//    NSLog(@"skip %i", ticksDiff);
//  }
  if (ticksDiff == 0) {
    return;
  }

  _lastControlTick = _ticks;

  const double accelerateRate = _driveGesture.accelerateRate;
  const double brakeRate = _driveGesture.brakeRate;

  if (accelerateRate > 0 && _lastAccelerateTick + TicksToWaitForRate(accelerateRate) <= _ticks) {
    keyevent(ACCELMASK, 1);
    keyevent(BRAKEMASK, 0);
    _lastAccelerateTick = _ticks;
  } else if (brakeRate > 0 && _lastBrakeTick + TicksToWaitForRate(brakeRate) <= _ticks) {
    keyevent(BRAKEMASK, 1);
    _lastBrakeTick = _ticks;
  } else {
    keyevent(ACCELMASK, 0);
    if (_autoSlowDown) {
      keyevent(BRAKEMASK, 1);
    } else {
      keyevent(BRAKEMASK, 0);
    }
    _lastAccelerateTick = 0;
    _lastBrakeTick = 0;
  }

  _steerGesture.tankdir = client.players[client.player].dir;
  
  if (_steerGesture.angleSet) {
    const float dir = client.players[client.player].dir;
    const CGFloat targetdir = _steerGesture.angle;
    float dirdiff = dir - targetdir;
    if (dirdiff > M_PI) {
      dirdiff -= M_PI * 2;
    } else if (dirdiff < -M_PI) {
      dirdiff += M_PI * 2;
    }

    const float mindirdiff = 0.01;
//    NSLog(@"dir %f target %f diff %f", dir, targetdir, dirdiff);
    if (dirdiff < -mindirdiff) {
      keyevent(TURNLMASK, 1);
      keyevent(TURNRMASK, 0);
    } else if (dirdiff > mindirdiff) {
      keyevent(TURNRMASK, 1);
      keyevent(TURNLMASK, 0);
    } else {
      keyevent(TURNLMASK, 0);
      keyevent(TURNRMASK, 0);
    }
  } else {
    keyevent(TURNLMASK, 0);
    keyevent(TURNRMASK, 0);
  }

  if (_shoot) {
    keyevent(SHOOTMASK, YES);
  } else {
    keyevent(SHOOTMASK, NO);
  }
}

@end

#pragma mark -

void setplayerstatus(int player) {
  assert(player >= 0 && player < MAX_PLAYERS);
  @autoreleasepool {
    [controller performSelectorOnMainThread:@selector(setPlayerStatus:) withObject:[NSString stringWithFormat:@"%d", player] waitUntilDone:NO];
  }
}

void setpillstatus(int pill) {
  assert(pill >= 0 && pill < MAX_PILLS);
  @autoreleasepool {
    [controller performSelectorOnMainThread:@selector(setPillStatus:) withObject:[NSString stringWithFormat:@"%d", pill] waitUntilDone:NO];
  }
}

void setbasestatus(int base) {
  assert(base >= 0 && base < MAX_BASES);
  @autoreleasepool {
    [controller performSelectorOnMainThread:@selector(setBaseStatus:) withObject:[NSString stringWithFormat:@"%d", base] waitUntilDone:NO];
  }
}

void settankstatus() {
  @autoreleasepool {
    [controller performSelectorOnMainThread:@selector(setTankStatusBars) withObject:nil waitUntilDone:NO];
  }
}

void playsound(int snd) {
  if (!muteBool) {
    int i;
    NSArray<AVAudioPlayer *> *array;

    @autoreleasepool {

      switch (snd) {
        case kBubblesSound:
          array = bubblessounds;
          break;

        case kBuildSound:
          array = buildsounds;
          break;

        case kBuilderDeathSound:
          array = builderdeathsounds;
          break;

        case kExplosionSound:
          array = explosionsounds;
          break;

        case kFarBuildSound:
          array = farbuildsounds;
          break;

        case kFarBuilderDeathSound:
          array = farbuilderdeathsounds;
          break;

        case kFarExplosionSound:
          array = farexplosionsounds;
          break;

        case kFarHitTankSound:
          array = farhittanksounds;
          break;

        case kFarHitTerrainSound:
          array = farhitterrainsounds;
          break;

        case kFarHitTreeSound:
          array = farhittreesounds;
          break;

        case kFarShotSound:
          array = farshotsounds;
          break;

        case kFarSinkSound:
          array = farsinksounds;
          break;

        case kFarSuperBoomSound:
          array = farsuperboomsounds;
          break;

        case kFarTreeSound:
          array = fartreesounds;
          break;

        case kHitTankSound:
          array = hittanksounds;
          break;

        case kHitTerrainSound:
          array = hitterrainsounds;
          break;

        case kHitTreeSound:
          array = hittreesounds;
          break;

        case kMineSound:
          array = minesounds;
          break;

        case kMsgReceivedSound:
          array = msgreceivedsounds;
          break;

        case kPillShotSound:
          array = pillshotsounds;
          break;

        case kSinkSound:
          array = sinksounds;
          break;

        case kSuperBoomSound:
          array = superboomsounds;
          break;

        case kTankShotSound:
          array = tankshotsounds;
          break;

        case kTreeSound:
          array = treesounds;
          break;

        default:
          array = nil;
          break;
      }

      // start playing sound
      for (i = 0; i < array.count; i++) {
        if (![array[i] isPlaying]) {
          [array[i] play];
          break;
        }
      }

    }
  }
}

void printmessage(int type, const char *text) {
  NSDictionary *attr;
  NSAttributedString *attrstring;

  assert(type == MSGEVERYONE || type == MSGALLIES || type == MSGNEARBY || type == MSGGAME);

  @autoreleasepool {

    switch (type) {
      case MSGEVERYONE:
        attr = [[NSDictionary alloc] init];
        break;

      case MSGALLIES:
        attr = @{NSForegroundColorAttributeName: [UIColor purpleColor]};
        break;

      case MSGNEARBY:
        attr = @{NSForegroundColorAttributeName: [UIColor redColor]};
        break;

      case MSGGAME:
        attr = @{NSForegroundColorAttributeName: [UIColor blueColor]};
        break;

      default:
        assert(0);
        break;
    }

    NSString *string = @(text);
    attrstring = [[NSAttributedString alloc] initWithString:string attributes:attr];
    [controller performSelectorOnMainThread:@selector(printMessage:) withObject:attrstring waitUntilDone:NO];

    if(type == MSGEVERYONE || type == MSGALLIES || type == MSGNEARBY) {
      playsound(kMsgReceivedSound);
      [controller sendMessageToRobot: string];
    }

  }
}

void joinprogress(int statuscode, float progress) {
  @autoreleasepool {
    switch (statuscode) {
        /* status udpates */
      case kJoinRESOLVING:
        [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Resolving Hostname...", @"Resolving Hostname...") waitUntilDone:NO];
        break;

      case kJoinCONNECTING:
        [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Connecting...", @"Connecting...") waitUntilDone:NO];
        break;

      case kJoinSENDJOIN:
        [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Sending Client Data", @"Sending Client Data") waitUntilDone:NO];
        break;

      case kJoinRECVPREAMBLE:
        [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Receiving Server Data", @"Receiving Server Data") waitUntilDone:NO];
        break;

      case kJoinRECVMAP:
        [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Receving Map Data", @"Receving Map Data") waitUntilDone:NO];
        [controller performSelectorOnMainThread:@selector(setJoinProgressIndicator:) withObject:@(progress) waitUntilDone:NO];
        break;

      case kJoinSUCCESS:
        [controller performSelectorOnMainThread:@selector(joinSuccess) withObject:nil waitUntilDone:NO];
        break;

        /* errors */
      case kJoinEHOSTNOTFOUND:
        [controller performSelectorOnMainThread:@selector(joinDNSError:) withObject:@(hstrerror(HOST_NOT_FOUND)) waitUntilDone:NO];
        break;

      case kJoinEHOSTNORECOVERY:
        [controller performSelectorOnMainThread:@selector(joinDNSError:) withObject:@(hstrerror(NO_RECOVERY)) waitUntilDone:NO];
        break;

      case kJoinEHOSTNODATA:
        [controller performSelectorOnMainThread:@selector(joinDNSError:) withObject:@(hstrerror(NO_DATA)) waitUntilDone:NO];
        break;

      case kJoinETIMEOUT:
        [controller performSelectorOnMainThread:@selector(joinTimeOut) withObject:nil waitUntilDone:NO];
        break;

      case kJoinECONNREFUSED:
        [controller performSelectorOnMainThread:@selector(joinConnectionRefused) withObject:nil waitUntilDone:NO];
        break;

      case kJoinENETUNREACH:
        [controller performSelectorOnMainThread:@selector(joinNetUnreachable) withObject:nil waitUntilDone:NO];
        break;

      case kJoinEHOSTUNREACH:
        [controller performSelectorOnMainThread:@selector(joinHostUnreachable) withObject:nil waitUntilDone:NO];
        break;

      case kJoinEBADVERSION:
        [controller performSelectorOnMainThread:@selector(joinBadVersion) withObject:nil waitUntilDone:NO];
        break;

      case kJoinEDISALLOW:
        [controller performSelectorOnMainThread:@selector(joinDisallow) withObject:nil waitUntilDone:NO];
        break;

      case kJoinEBADPASS:
        [controller performSelectorOnMainThread:@selector(joinBadPassword) withObject:nil waitUntilDone:NO];
        break;

      case kJoinESERVERFULL:
        [controller performSelectorOnMainThread:@selector(joinServerFull) withObject:nil waitUntilDone:NO];
        break;

      case kJoinETIMELIMIT:
        [controller performSelectorOnMainThread:@selector(joinTimeLimit) withObject:nil waitUntilDone:NO];
        break;

      case kJoinEBANNEDPLAYER:
        [controller performSelectorOnMainThread:@selector(joinBannedPlayer) withObject:nil waitUntilDone:NO];
        break;

      case kJoinESERVERERROR:
        [controller performSelectorOnMainThread:@selector(joinServerError) withObject:nil waitUntilDone:NO];
        break;

      case kJoinECONNRESET:
        [controller performSelectorOnMainThread:@selector(joinConnectionReset) withObject:nil waitUntilDone:NO];
        break;

      default:
        assert(0);
        break;
    }

  }
}

void registercallback(int status) {
  @autoreleasepool {
    switch (status) {
      case kRegisterRESOLVING:
        [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Resolving Tracker...", @"Resolving Tracker...") waitUntilDone:NO];
        break;

      case kRegisterCONNECTING:
        [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Connecting to Tracker...", @"Connecting to Tracker...") waitUntilDone:NO];
        break;

      case kRegisterSENDINGDATA:
        [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Sending Data...", @"Sending Data...") waitUntilDone:NO];
        break;

      case kRegisterTESTINGTCP:
        [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Testing TCP Port...", @"Testing TCP Port...") waitUntilDone:NO];
        break;

      case kRegisterTESTINGUDP:
        [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Testing UDP Port...", @"Testing UDP Port...") waitUntilDone:NO];
        break;

      case kRegisterSUCCESS:
        [controller performSelectorOnMainThread:@selector(registerSuccess) withObject:nil waitUntilDone:NO];
        break;

      case kRegisterEHOSTNORECOVERY:
        [controller performSelectorOnMainThread:@selector(trackerDNSError:) withObject:@(hstrerror(NO_RECOVERY)) waitUntilDone:NO];
        break;

      case kRegisterEHOSTNOTFOUND:
        [controller performSelectorOnMainThread:@selector(trackerDNSError:) withObject:@(hstrerror(HOST_NOT_FOUND)) waitUntilDone:NO];
        break;

      case kRegisterEHOSTNODATA:
        [controller performSelectorOnMainThread:@selector(trackerDNSError:) withObject:@(hstrerror(NO_DATA)) waitUntilDone:NO];
        break;

      case kRegisterETIMEOUT:
        [controller performSelectorOnMainThread:@selector(registerTrackerTimeOut) withObject:nil waitUntilDone:NO];
        break;

      case kRegisterECONNREFUSED:
        [controller performSelectorOnMainThread:@selector(registerTrackerConnectionRefused) withObject:nil waitUntilDone:NO];
        break;

      case kRegisterEHOSTDOWN:
        [controller performSelectorOnMainThread:@selector(registerTrackerHostDown) withObject:nil waitUntilDone:NO];
        break;

      case kRegisterEHOSTUNREACH:
        [controller performSelectorOnMainThread:@selector(registerTrackerHostUnreachable) withObject:nil waitUntilDone:NO];
        break;

      case kRegisterEBADVERSION:
        [controller performSelectorOnMainThread:@selector(registerTrackerBadVersion) withObject:nil waitUntilDone:NO];
        break;

      case kRegisterETCPCLOSED:
        [controller performSelectorOnMainThread:@selector(registerTrackerTCPPortBlocked) withObject:nil waitUntilDone:NO];
        break;

      case kRegisterEUDPCLOSED:
        [controller performSelectorOnMainThread:@selector(registerTrackerUDPPortBlocked) withObject:nil waitUntilDone:NO];
        break;

      case kRegisterECONNRESET:
        [controller performSelectorOnMainThread:@selector(registerTrackerConnectionReset) withObject:nil waitUntilDone:NO];
        break;

      default:
        assert(0);
        break;
    }

  }
}

void getlisttrackerstatus(int status) {
  @autoreleasepool {
    switch (status) {
      case kGetListTrackerRESOLVING:
        [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Resolving Tracker...", @"Resolving Tracker...") waitUntilDone:NO];
        break;

      case kGetListTrackerCONNECTING:
        [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Connecting to Tracker...", @"Connecting to Tracker...") waitUntilDone:NO];
        break;

      case kGetListTrackerGETTINGLIST:
        [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Receving Game List...", @"Receving Game List...") waitUntilDone:NO];
        break;

      case kGetListTrackerSUCCESS:
        [controller performSelectorOnMainThread:@selector(getListTrackerSuccess) withObject:nil waitUntilDone:NO];
        break;

      case kGetListTrackerECONNABORTED:  // error caused by user cancel
        break;

      case kGetListTrackerEPIPE:
        break;

      case kGetListTrackerEHOSTNOTFOUND:  // error from dns lookup
        [controller performSelectorOnMainThread:@selector(trackerDNSError:) withObject:@(hstrerror(HOST_NOT_FOUND)) waitUntilDone:NO];
        break;

      case kGetListTrackerEHOSTNORECOVERY:
        [controller performSelectorOnMainThread:@selector(trackerDNSError:) withObject:@(hstrerror(NO_RECOVERY)) waitUntilDone:NO];
        break;

      case kGetListTrackerEHOSTNODATA:
        [controller performSelectorOnMainThread:@selector(trackerDNSError:) withObject:@(hstrerror(NO_DATA)) waitUntilDone:NO];
        break;

      case kGetListTrackerETIMEOUT:  // error caused by other factors
        [controller performSelectorOnMainThread:@selector(getListTrackerTimeOut) withObject:nil waitUntilDone:NO];
        break;

      case kGetListTrackerECONNREFUSED:
        [controller performSelectorOnMainThread:@selector(getListTrackerConnectionRefused) withObject:nil waitUntilDone:NO];
        break;

      case kGetListTrackerEHOSTDOWN:
        [controller performSelectorOnMainThread:@selector(getListTrackerHostDown) withObject:nil waitUntilDone:NO];
        break;

      case kGetListTrackerEHOSTUNREACH:
        [controller performSelectorOnMainThread:@selector(getListTrackerHostUnreachable) withObject:nil waitUntilDone:NO];
        break;

      case kGetListTrackerEBADVERSION:
        [controller performSelectorOnMainThread:@selector(getListTrackerBadVersion) withObject:nil waitUntilDone:NO];
        break;

      default:
        assert(0);
        break;
    }

  }
}

//int setKey(NSMutableDictionary<NSString*,NSString*> *dict, NSWindow *win, GSKeyCodeField *field, NSString *newObject) {
//  NSString *key;
//  id object;
//  key = field.stringValue;
//  object = dict[key];
//
//  if (object != nil) {
//    [[NSAlert alertWithMessageText:@"There is a key conflict." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There is a conflict with %@ and %@.  Change one of them.", object, newObject] beginSheetModalForWindow:win modalDelegate:nil didEndSelector:nil contextInfo:NULL];
//    return -1;
//  }
//  else {
//    dict[key] = newObject;
//    return 0;
//  }
//}

void clientloopupdate(void) {
  [controller clientLoopUpdate];
}

@implementation XBoloViewController (UIGestureRecognizerDelegate)

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
}

@end
