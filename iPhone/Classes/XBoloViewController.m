//
//  XBoloViewController.m
//  XBolo
//
//  Created by Robert Chrzanowski on 6/28/09.
//  Copyright Robert Chrzanowski 2009. All rights reserved.
//

#import "XBoloViewController.h"

#import "XBoloView.h"
#import "XBoloBonjour.h"
#import "GSBoloViews.h"

#import "server.h"
#import "client.h"
#include "errchk.h"

#include <netdb.h>

static XBoloViewController *controller = nil;

/* Sound */
static BOOL muteBool;

@interface XBoloViewController() {
  XBoloView *_boloView;
  XBoloBonjour *_broadcaster;
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
}

- (void)awakeFromNib {
  [super awakeFromNib];

  // schedule a timer
  [NSTimer scheduledTimerWithTimeInterval:0.0625 target:self selector:@selector(refresh:) userInfo:nil repeats:YES];
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

  _boloView.frame = self.view.bounds;
  [self.view addSubview:_boloView];
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

  NSString *bonjourName = [NSString stringWithFormat:@"%@ (%@)", UIDevice.currentDevice.name, playerNameString];
  _broadcaster.serviceName = bonjourName;
  _broadcaster.mapName = [[[mapURL path] lastPathComponent] stringByDeletingPathExtension];
  [_broadcaster startPublishing];
  
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
  [_boloView clientLoopUpdate];
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
//  if (!muteBool) {
//    int i;
//    NSArray *array;
//
//    @autoreleasepool {
//
//      switch (snd) {
//        case kBubblesSound:
//          array = bubblessounds;
//          break;
//
//        case kBuildSound:
//          array = buildsounds;
//          break;
//
//        case kBuilderDeathSound:
//          array = builderdeathsounds;
//          break;
//
//        case kExplosionSound:
//          array = explosionsounds;
//          break;
//
//        case kFarBuildSound:
//          array = farbuildsounds;
//          break;
//
//        case kFarBuilderDeathSound:
//          array = farbuilderdeathsounds;
//          break;
//
//        case kFarExplosionSound:
//          array = farexplosionsounds;
//          break;
//
//        case kFarHitTankSound:
//          array = farhittanksounds;
//          break;
//
//        case kFarHitTerrainSound:
//          array = farhitterrainsounds;
//          break;
//
//        case kFarHitTreeSound:
//          array = farhittreesounds;
//          break;
//
//        case kFarShotSound:
//          array = farshotsounds;
//          break;
//
//        case kFarSinkSound:
//          array = farsinksounds;
//          break;
//
//        case kFarSuperBoomSound:
//          array = farsuperboomsounds;
//          break;
//
//        case kFarTreeSound:
//          array = fartreesounds;
//          break;
//
//        case kHitTankSound:
//          array = hittanksounds;
//          break;
//
//        case kHitTerrainSound:
//          array = hitterrainsounds;
//          break;
//
//        case kHitTreeSound:
//          array = hittreesounds;
//          break;
//
//        case kMineSound:
//          array = minesounds;
//          break;
//
//        case kMsgReceivedSound:
//          array = msgreceivedsounds;
//          break;
//
//        case kPillShotSound:
//          array = pillshotsounds;
//          break;
//
//        case kSinkSound:
//          array = sinksounds;
//          break;
//
//        case kSuperBoomSound:
//          array = superboomsounds;
//          break;
//
//        case kTankShotSound:
//          array = tankshotsounds;
//          break;
//
//        case kTreeSound:
//          array = treesounds;
//          break;
//
//        default:
//          array = nil;
//          break;
//      }
//
//      // start playing sound
//      for (i = 0; i < array.count; i++) {
//        if (![array[i] isPlaying]) {
//          [array[i] play];
//          break;
//        }
//      }
//
//    }
//  }
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
