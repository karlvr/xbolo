#import "GSXBoloController.h"
#import "GSBoloViews.h"
#import "GSRobot.h"
#import "GSStatusBar.h"
#import "GSBuilderStatusView.h"
#import "GSKeyCodeField.h"
#import "XBoloBonjourKeys.h"
#import "GSBoloViews.h"

#include "bolo.h"
#include "server.h"
#include "client.h"
#include "resolver.h"
#include "tracker.h"
#include "errchk.h"

#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

typedef NS_ENUM(NSInteger, GSServerSource) {
  GSServerSourceTracker = 0,
  GSServerSourceBonjour
};

static NSString * const GSHostMap                    = @"GSHostMapString";
static NSString * const GSHostUPnP                   = @"GSHostUPnPBool";
static NSString * const GSHostPort                   = @"GSHostPortNumber";
static NSString * const GSHostUsePassword            = @"GSHostPasswordBool";
static NSString * const GSHostPassword               = @"GSHostPasswordString";
static NSString * const GSHostUseTimeLimit           = @"GSHostTimeLimitBool";
static NSString * const GSHostTimeLimit              = @"GSHostTimeLimitString";
static NSString * const GSHostHiddenMines            = @"GSHostHiddenMinesBool";
static NSString * const GSHostTracker                = @"GSHostTrackerBool";
static NSString * const GSHostGameType               = @"GSHostGameTypeNumber";
static NSString * const GSHostDominationType         = @"GSHostDominationTypeNumber";
static NSString * const GSHostDominationBaseControl  = @"GSHostDominationBaseControlString";
static NSString * const GSJoinAddress                = @"GSJoinAddressString";
static NSString * const GSJoinPort                   = @"GSJoinPortNumber";
static NSString * const GSJoinHasPassword            = @"GSJoinPasswordBool";
static NSString * const GSJoinPassword               = @"GSJoinPasswordString";
static NSString * const GSTracker                    = @"GSTrackerString";

static NSString * const GSPrefPaneIdentifier         = @"GSPrefPaneIdentifierString";
static NSString * const GSPlayerNameString           = @"GSPlayerNameString";
static NSString * const GSKeyConfigDict              = @"GSKeyConfigDict";
static NSString * const GSAutoSlowdown               = @"GSAutoSlowdownBool";
static NSString * const GSAccelerate                 = @"GSAccelerateString";
static NSString * const GSBrake                      = @"GSBrakeString";
static NSString * const GSTurnLeft                   = @"GSTurnLeftString";
static NSString * const GSTurnRight                  = @"GSTurnRightString";
static NSString * const GSLayMine                    = @"GSLayMineString";
static NSString * const GSShoot                      = @"GSShootString";
static NSString * const GSIncreaseAim                = @"GSIncreaseAimString";
static NSString * const GSDecreaseAim                = @"GSDecreaseAimString";
static NSString * const GSUp                         = @"GSUpString";
static NSString * const GSDown                       = @"GSDownString";
static NSString * const GSLeft                       = @"GSLeftString";
static NSString * const GSRight                      = @"GSRightString";
static NSString * const GSTankView                   = @"GSTankViewString";
static NSString * const GSPillView                   = @"GSPillViewString";

static NSString * const GSMute                       = @"GSMuteBool";

// bolo toolbar prefs
static NSString * const GSBuilderTool                = @"GSBuilderToolInteger";

//static NSString * const GSPlayerInfoImage            = @"PlayerInfo";
static NSImageName const GSKeyConfigImage             = @"KeyConfig";

static NSImageName const GSTankCenterImage            = @"TankCenter";
static NSImageName const GSPillCenterImage            = @"PillCenter";
static NSImageName const GSZoomInImage                = @"ZoomIn";
static NSImageName const GSZoomOutImage               = @"ZoomOut";

// toolbar item identifiers
static NSToolbarIdentifier const GSPreferencesToolbar               = @"GSPreferencesToolbar";
static NSToolbarItemIdentifier const GSToolbarPlayerInfoItemIdentifier  = @"GSToolbarPlayerInfoItemIdentifier";
static NSToolbarItemIdentifier const GSToolbarKeyConfigItemIdentifier   = @"GSToolbarKeyConfigItemIdentifier";

static NSToolbarIdentifier const GSBoloToolbar                      = @"GSBoloToolbar";
static NSToolbarItemIdentifier const GSZoomInItemIdentifier         = @"GSZoomInItemIdentifier";
static NSToolbarItemIdentifier const GSZoomOutItemIdentifier        = @"GSZoomOutItemIdentifier";
static NSToolbarItemIdentifier const GSBoloToolItemIdentifier       = @"GSBoloToolItemIdentifier";
static NSToolbarItemIdentifier const GSTankCenterItemIdentifier     = @"GSTankCenterItemIdentifier";
static NSToolbarItemIdentifier const GSPillCenterItemIdentifier     = @"GSPillCenterItemIdentifier";

static NSString * const GSShowStatus                       = @"GSShowStatusBool";
static NSString * const GSShowAllegiance                   = @"GSShowAllegianceBool";
static NSString * const GSShowMessages                     = @"GSShowMessagesBool";

// tracker table view columns
static NSString * const GSSourceColumn                     = @"GSSourceColumn";
static NSString * const GSHostPlayerColumn                 = @"GSHostPlayerColumn";
static NSString * const GSMapNameColumn                    = @"GSMapNameColumn";
static NSString * const GSPlayersColumn                    = @"GSPlayersColumn";
static NSString * const GSPasswordColumn                   = @"GSPasswordColumn";
static NSString * const GSAllowJoinColumn                  = @"GSAllowJoinColumn";
static NSString * const GSPausedColumn                     = @"GSPausedColumn";
static NSString * const GSHostnameColumn                   = @"GSHostnameColumn";
static NSString * const GSPortColumn                       = @"GSPortColumn";

// message panel
static NSString * const GSMessageTarget                   = @"GSMessageTarget";

// private settings
static NSString * const GSDisableBonjour                  = @"GSDisableBonjour";


static GSXBoloController *controller = nil;

// sound
static BOOL muteBool;

static NSMutableArray<NSSound*> *bubblessounds;
static NSMutableArray<NSSound*> *builderdeathsounds;
static NSMutableArray<NSSound*> *buildsounds;
static NSMutableArray<NSSound*> *sinksounds;
static NSMutableArray<NSSound*> *superboomsounds;
static NSMutableArray<NSSound*> *explosionsounds;
static NSMutableArray<NSSound*> *farbuildsounds;
static NSMutableArray<NSSound*> *farbuilderdeathsounds;
static NSMutableArray<NSSound*> *farexplosionsounds;
static NSMutableArray<NSSound*> *farhittanksounds;
static NSMutableArray<NSSound*> *farhitterrainsounds;
static NSMutableArray<NSSound*> *farhittreesounds;
static NSMutableArray<NSSound*> *farshotsounds;
static NSMutableArray<NSSound*> *farsinksounds;
static NSMutableArray<NSSound*> *farsuperboomsounds;
static NSMutableArray<NSSound*> *fartreesounds;
static NSMutableArray<NSSound*> *minesounds;
static NSMutableArray<NSSound*> *msgreceivedsounds;
static NSMutableArray<NSSound*> *pillshotsounds;
static NSMutableArray<NSSound*> *hittanksounds;
static NSMutableArray<NSSound*> *tankshotsounds;
static NSMutableArray<NSSound*> *hitterrainsounds;
static NSMutableArray<NSSound*> *hittreesounds;
static NSMutableArray<NSSound*> *treesounds;

static NSMutableArray<NSSpeechSynthesizer*> *speechSynthesizers;

static struct ListNode trackerlist;

static const CGFloat kZoomLevels[] = {
    0.5,
    0.75,
    1.0,
    1.5,
    2.0
};

#define DEFAULT_ZOOM 2
#define MAX_ZOOM (sizeof(kZoomLevels) / sizeof(*kZoomLevels) - 1)

// set the key
int setKey(NSMutableDictionary *dict, NSWindow *win, GSKeyCodeField *field, NSString *newObject);

static void registercallback(int status);
static void getlisttrackerstatus(int status);

@interface GSXBoloController ()

// bolo callbacks
- (void)setPlayerStatus:(NSString *)aString;
- (void)setPillStatus:(NSString *)aString;
- (void)setBaseStatus:(NSString *)aString;
- (void)setTankStatusBars;
- (void)refresh:(NSTimer *)aTimer;
- (void)printMessage:(NSAttributedString *)string;
- (void)setJoinProgressStatusTextField:(NSString *)aString;
- (void)setJoinProgressIndicator:(NSNumber *)aString;

// callbacks from client thread
- (void)joinSuccess;
- (void)joinDNSError:(NSString *)eString;
- (void)joinTimeOut;
- (void)joinConnectionRefused;
- (void)joinNetUnreachable;
- (void)joinHostUnreachable;
- (void)joinBadVersion;
- (void)joinDisallow;
- (void)joinBadPassword;
- (void)joinServerFull;
- (void)joinTimeLimit;
- (void)joinBannedPlayer;
- (void)joinServerError;
- (void)joinConnectionReset;

- (void)registerSuccess;

// callback for tracker dns error
- (void)trackerDNSError:(NSString *)eString;

// callbacks from registertracker
- (void)registerTrackerTimeOut;
- (void)registerTrackerConnectionRefused;
- (void)registerTrackerHostDown;
- (void)registerTrackerHostUnreachable;
- (void)registerTrackerBadVersion;
- (void)registerTrackerTCPPortBlocked;
- (void)registerTrackerUDPPortBlocked;
- (void)registerTrackerConnectionReset;

// callbacks from getlisttracker
- (void)getListTrackerTimeOut;
- (void)getListTrackerConnectionRefused;
- (void)getListTrackerHostDown;
- (void)getListTrackerHostUnreachable;
- (void)getListTrackerBadVersion;
- (void)getListTrackerSuccess;

// robots
- (BOOL)_validateRobotMenuItem: (NSMenuItem *)item;
- (void)setupRobotsMenu;
@end

@interface GSXBoloController (NetService) <NSNetServiceDelegate, NSNetServiceBrowserDelegate>
- (void)startPublishing;
- (void)updatePublishedInfo;
- (void)stopPublishing;

- (void)startListening;
- (void)stopListening;
- (void)clearBonjourEntries;
@end

@implementation GSXBoloController {
  NSNetService *broadcaster;
  NSNetServiceBrowser *listener;
}
@synthesize joinAddress = joinAddressString;
@synthesize joinPort = joinPortNumber;
@synthesize hostPort = hostPortNumber;
@synthesize mute = muteBool;
@synthesize playerName = playerNameString;
@synthesize joinPasswordEnabled = joinPasswordBool;
@synthesize joinPassword = joinPasswordString;
@synthesize autoSlowdown = autoSlowdownBool;
@synthesize tracker = trackerString;

// NIB methods

- (void)awakeFromNib {
  NSUserDefaults *defaults;
  NSSound *sound;

  controller = self;
  defaults = [NSUserDefaults standardUserDefaults];
  [defaults registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultPreferences" ofType:@"plist"]]];

  // init toolbar items
  toolbarPlayerInfoItem = [[NSToolbarItem alloc] initWithItemIdentifier:GSToolbarPlayerInfoItemIdentifier];
  [toolbarPlayerInfoItem setLabel:NSLocalizedString(@"Player Info", nil)];
  toolbarPlayerInfoItem.image = [NSImage imageNamed:NSImageNameUser];
  toolbarPlayerInfoItem.target = self;
  toolbarPlayerInfoItem.action = @selector(prefPane:);

  toolbarKeyConfigItem = [[NSToolbarItem alloc] initWithItemIdentifier:GSToolbarKeyConfigItemIdentifier];
  [toolbarKeyConfigItem setLabel:NSLocalizedString(@"Key Config", nil)];
  toolbarKeyConfigItem.image = [NSImage imageNamed:GSKeyConfigImage];
  toolbarKeyConfigItem.target = self;
  toolbarKeyConfigItem.action = @selector(prefPane:);
  [toolbarKeyConfigItem setEnabled:YES];

  // init the preferences toolbar
  prefToolbar = [[NSToolbar alloc] initWithIdentifier:GSPreferencesToolbar];
  prefToolbar.delegate = self;
  prefToolbar.selectedItemIdentifier = GSToolbarPlayerInfoItemIdentifier;
  preferencesWindow.toolbar = prefToolbar;

  // init bolo toolbar items
  builderToolItem = [[NSToolbarItem alloc] initWithItemIdentifier:GSBoloToolItemIdentifier];
  [builderToolItem setLabel:NSLocalizedString(@"Builder Tool", nil)];
  builderToolItem.view = builderToolView;
  builderToolItem.minSize = builderToolView.frame.size;

  tankCenterItem = [[NSToolbarItem alloc] initWithItemIdentifier:GSTankCenterItemIdentifier];
  [tankCenterItem setLabel:NSLocalizedString(@"Tank Center", nil)];
  tankCenterItem.image = [NSImage imageNamed:GSTankCenterImage];
  tankCenterItem.target = self;
  tankCenterItem.action = @selector(tankCenter:);

  pillCenterItem = [[NSToolbarItem alloc] initWithItemIdentifier:GSPillCenterItemIdentifier];
  [pillCenterItem setLabel:NSLocalizedString(@"Pill Center", nil)];
  pillCenterItem.image = [NSImage imageNamed:GSPillCenterImage];
  pillCenterItem.target = self;
  pillCenterItem.action = @selector(pillCenter:);

  zoomInItem = [[NSToolbarItem alloc] initWithItemIdentifier:GSZoomInItemIdentifier];
  [zoomInItem setLabel:NSLocalizedString(@"Zoom In", nil)];
  zoomInItem.image = [NSImage imageNamed:GSZoomInImage];
  zoomInItem.target = self;
  zoomInItem.action = @selector(zoomIn:);

  zoomOutItem = [[NSToolbarItem alloc] initWithItemIdentifier:GSZoomOutItemIdentifier];
  [zoomOutItem setLabel:NSLocalizedString(@"Zoom Out", nil)];
  zoomOutItem.image = [NSImage imageNamed:GSZoomOutImage];
  zoomOutItem.target = self;
  zoomOutItem.action = @selector(zoomOut:);

  // init the builder toolbar
  boloToolbar = [[NSToolbar alloc] initWithIdentifier:GSBoloToolbar];
  boloToolbar.delegate = self;
  [boloToolbar setAllowsUserCustomization:YES];
  boloWindow.toolbar = boloToolbar;

  // init status bars
  playerShellsStatusBar.type = GSStatusBarVertical;
  playerMinesStatusBar.type = GSStatusBarVertical;
  playerArmourStatusBar.type = GSStatusBarVertical;
  playerTreesStatusBar.type = GSStatusBarVertical;
  baseShellsStatusBar.type = GSStatusBarHorizontal;
  baseMinesStatusBar.type = GSStatusBarHorizontal;
  baseArmourStatusBar.type = GSStatusBarHorizontal;

  // we don't need no stink'n windows menu
  [newGameWindow setExcludedFromWindowsMenu:YES];
  [boloWindow setExcludedFromWindowsMenu:YES];
  [statusPanel setExcludedFromWindowsMenu:YES];
  [allegiancePanel setExcludedFromWindowsMenu:YES];
  [messagesPanel setExcludedFromWindowsMenu:YES];
  [preferencesWindow setExcludedFromWindowsMenu:YES];

  // keep panels visible
  [statusPanel setHidesOnDeactivate:NO];
  [allegiancePanel setHidesOnDeactivate:NO];
  [messagesPanel setHidesOnDeactivate:NO];

  // init the host pane
  [self setHostMap:[defaults stringForKey:GSHostMap]];
  [self setHostUPnP:[defaults integerForKey:GSHostUPnP]];
  if([defaults boolForKey:@"GSHostPortNumberRandom"])
    [self setHostPort:(random() % 40000) + 2000];
  else
    [self setHostPort:(int)[defaults integerForKey:GSHostPort]];
  [self setHasHostPassword:[defaults boolForKey:GSHostUsePassword]];
  [self setHostPassword:[defaults stringForKey:GSHostPassword]];
  [self setHasHostTimeLimit:[defaults boolForKey:GSHostUseTimeLimit]];
  [self setHostTimeLimit:[defaults stringForKey:GSHostTimeLimit]];
  [self setHostHiddenMines:[defaults boolForKey:GSHostHiddenMines]];
  [self setHostTracker:[defaults boolForKey:GSHostTracker]];
  [self setHostGameType:(int)[defaults integerForKey:GSHostGameType]];

  // init host domination pane
  [self setHostDominationType:(int)[defaults integerForKey:GSHostDominationType]];
  [self setHostDominationBaseControl:[defaults stringForKey:GSHostDominationBaseControl]];

  // init the join pane
  [self setJoinAddress:[defaults stringForKey:GSJoinAddress]];
  [self setJoinPort:(int)[defaults integerForKey:GSJoinPort]];
  [self setJoinPasswordEnabled:[defaults boolForKey:GSJoinHasPassword]];
  [self setJoinPassword:[defaults stringForKey:GSJoinPassword]];

  // init tracker string
  [self setTracker:[defaults stringForKey:GSTracker]];

  // init the pref panes
  [self setPrefPaneIdentifier:[defaults stringForKey:GSPrefPaneIdentifier]];
  [self setPlayerName:[defaults stringForKey:GSPlayerNameString]];
  [self setAutoSlowdown:[defaults boolForKey:GSAutoSlowdown]];
  [self revertKeyConfig:self];

  // init the show variables
  [self setShowStatus:[defaults boolForKey:GSShowStatus]];
  [self setShowAllegiance:[defaults boolForKey:GSShowAllegiance]];
  [self setShowMessages:[defaults boolForKey:GSShowMessages]];

  // init bolo window
  [self setBuilderTool:(int)[defaults integerForKey:GSBuilderTool]];

  // init allegiance panel
  playerInfoArray = [[NSMutableArray alloc] init];

  // init messages panel
  [self setMessageTarget:(int)[defaults integerForKey:GSMessageTarget]];

  // init the key config
  [self setKeyConfigDict:[defaults dictionaryForKey:GSKeyConfigDict]];

  // schedule a timer
  [NSTimer scheduledTimerWithTimeInterval:0.0625 target:self selector:@selector(refresh:) userInfo:nil repeats:YES];

  // init sound
  [self setMute:[defaults boolForKey:GSMute]];

  // allocate sounds
  sound = [NSSound soundNamed:@"bubbles"];
  bubblessounds = [[NSMutableArray alloc] init];
  [bubblessounds addObject:sound];

  sound = [NSSound soundNamed:@"build"];
  buildsounds = [[NSMutableArray alloc] init];
  [buildsounds addObject:sound];
  [buildsounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"builderdeath"];
  builderdeathsounds = [[NSMutableArray alloc] init];
  [builderdeathsounds addObject:sound];
  [builderdeathsounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"explosion"];
  explosionsounds = [[NSMutableArray alloc] init];
  [explosionsounds addObject:sound];
  [explosionsounds addObject:[sound copy]];
  [explosionsounds addObject:[sound copy]];
  [explosionsounds addObject:[sound copy]];
  [explosionsounds addObject:[sound copy]];
  [explosionsounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"fbuild"];
  farbuildsounds = [[NSMutableArray alloc] init];
  [farbuildsounds addObject:sound];
  [farbuildsounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"fbuilderdeath"];
  farbuilderdeathsounds = [[NSMutableArray alloc] init];
  [farbuilderdeathsounds addObject:sound];
  [farbuilderdeathsounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"fexplosion"];
  farexplosionsounds = [[NSMutableArray alloc] init];
  [farexplosionsounds addObject:sound];
  [farexplosionsounds addObject:[sound copy]];
  [farexplosionsounds addObject:[sound copy]];
  [farexplosionsounds addObject:[sound copy]];
  [farexplosionsounds addObject:[sound copy]];
  [farexplosionsounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"fhittank"];
  farhittanksounds = [[NSMutableArray alloc] init];
  [farhittanksounds addObject:sound];
  [farhittanksounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"fhitterrain"];
  farhitterrainsounds = [[NSMutableArray alloc] init];
  [farhitterrainsounds addObject:sound];
  [farhitterrainsounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"fhittree"];
  farhittreesounds = [[NSMutableArray alloc] init];
  [farhittreesounds addObject:sound];
  [farhittreesounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"fshot"];
  farshotsounds = [[NSMutableArray alloc] init];
  [farshotsounds addObject:sound];
  [farshotsounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"fsink"];
  farsinksounds = [[NSMutableArray alloc] init];
  [farsinksounds addObject:sound];
  [farsinksounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"fsuperboom"];
  farsuperboomsounds = [[NSMutableArray alloc] init];
  [farsuperboomsounds addObject:sound];
  [farsuperboomsounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"ftree"];
  fartreesounds = [[NSMutableArray alloc] init];
  [fartreesounds addObject:sound];
  [fartreesounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"hittank"];
  hittanksounds = [[NSMutableArray alloc] init];
  [hittanksounds addObject:sound];
  [hittanksounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"hitterrain"];
  hitterrainsounds = [[NSMutableArray alloc] init];
  [hitterrainsounds addObject:sound];
  [hitterrainsounds addObject:[sound copy]];
  [hitterrainsounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"hittree"];
  hittreesounds = [[NSMutableArray alloc] init];
  [hittreesounds addObject:sound];
  [hittreesounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"mine"];
  minesounds = [[NSMutableArray alloc] init];
  [minesounds addObject:sound];
  [minesounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"msgreceived"];
  msgreceivedsounds = [[NSMutableArray alloc] init];
  [msgreceivedsounds addObject:sound];
  [msgreceivedsounds addObject:[sound copy]];
  [msgreceivedsounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"pillshot"];
  pillshotsounds = [[NSMutableArray alloc] init];
  [pillshotsounds addObject:sound];
  [pillshotsounds addObject:[sound copy]];
  [pillshotsounds addObject:[sound copy]];
  [pillshotsounds addObject:[sound copy]];
  [pillshotsounds addObject:[sound copy]];
  [pillshotsounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"sink"];
  sinksounds = [[NSMutableArray alloc] init];
  [sinksounds addObject:sound];

  sound = [NSSound soundNamed:@"superboom"];
  superboomsounds = [[NSMutableArray alloc] init];
  [superboomsounds addObject:sound];

  sound = [NSSound soundNamed:@"tankshot"];
  tankshotsounds = [[NSMutableArray alloc] init];
  [tankshotsounds addObject:sound];
  [tankshotsounds addObject:[sound copy]];
  [tankshotsounds addObject:[sound copy]];
  [tankshotsounds addObject:[sound copy]];
  [tankshotsounds addObject:[sound copy]];

  sound = [NSSound soundNamed:@"tree"];
  treesounds = [[NSMutableArray alloc] init];
  [treesounds addObject:sound];
  [treesounds addObject:[sound copy]];
  [treesounds addObject:[sound copy]];

  speechSynthesizers = [[NSMutableArray alloc] init];
  [speechSynthesizers addObject:[[NSSpeechSynthesizer alloc] init]];
  [speechSynthesizers addObject:[[NSSpeechSynthesizer alloc] init]];

  zoomLevel = DEFAULT_ZOOM;

  // bug in interface builder prevents this outlet from working
  joinProgressStatusTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(76, 60, 193, 17)];
  [joinProgressStatusTextField setBordered:NO];
  [joinProgressStatusTextField setEditable:NO];
  [joinProgressStatusTextField setDrawsBackground:NO];
  [joinProgressWindow.contentView addSubview:joinProgressStatusTextField];

  joinProgressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(18, 18, 172, 20)];
  [joinProgressWindow.contentView addSubview:joinProgressIndicator];

  // setup double clicking in tracker
  joinTrackerTableView.target = self;
  joinTrackerTableView.doubleAction = @selector(joinOK:);

  // TCMPortMapper
  portMapper = [TCMPortMapper sharedInstance];
  [portMapper setUserID:[NSString stringWithFormat:@"%d", getpid()]];
 
  // set up robots menu
  [self setupRobotsMenu];
  
  // Register for Bonjour Services
  if (![defaults boolForKey:GSDisableBonjour]) {
    [self startListening];
  }
  
  _broadcastBonjour = ![defaults boolForKey:GSDisableBonjour];
}

// accessor methods

@synthesize hostMap=hostMapString;
- (void)setHostMap:(NSString *)aString {
  hostMapString = [aString copy];
  hostMapField.stringValue = [[NSFileManager defaultManager] displayNameAtPath:aString];
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSHostMap];
}

@synthesize hostUPnP=hostUPnPBool;
- (void)setHostUPnP:(BOOL)aBool {
  hostUPnPBool = aBool;
  hostUPnPSwitch.state = aBool ? NSOnState : NSOffState;
  hostPortField.enabled = !aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSHostUPnP];
}

- (void)setHostPort:(unsigned short)aNumber {
  hostPortNumber = aNumber;
  hostPortField.intValue = aNumber;
  [[NSUserDefaults standardUserDefaults] setInteger:aNumber forKey:GSHostPort];
}

@synthesize hasHostPassword=hostPasswordBool;
- (void)setHasHostPassword:(BOOL)aBool {
  hostPasswordBool = aBool;
  hostPasswordSwitch.state = aBool ? NSOnState : NSOffState;
  hostPasswordField.enabled = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSHostUsePassword];
}

@synthesize hostPassword=hostPasswordString;
- (void)setHostPassword:(NSString *)aString {
  hostPasswordString = [aString copy];
  hostPasswordField.stringValue = aString;
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSHostPassword];
}

@synthesize hasHostTimeLimit=hostTimeLimitBool;
- (void)setHasHostTimeLimit:(BOOL)aBool {
  hostTimeLimitBool = aBool;
  hostTimeLimitSwitch.state = aBool ? NSOnState : NSOffState;
  hostTimeLimitSlider.enabled = aBool;
  hostTimeLimitField.enabled = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSHostUseTimeLimit];
}

@synthesize hostTimeLimit=hostTimeLimitString;
- (void)setHostTimeLimit:(NSString *)aString {
  NSScanner *scanner;
  int hours, minutes, seconds;

  scanner = [NSScanner scannerWithString:aString];
  scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@":"];
  [scanner scanInt:&hours];
  [scanner scanInt:&minutes];
  [scanner scanInt:&seconds];
  hostTimeLimitString = [aString copy];
  hostTimeLimitSlider.intValue = hours*3600 + minutes*60 + seconds;
  hostTimeLimitField.stringValue = aString;
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSHostTimeLimit];
}

@synthesize hostHiddenMines=hostHiddenMinesBool;
- (void)setHostHiddenMines:(BOOL)aBool {
  hostHiddenMinesBool = aBool;
  hostHiddenMinesSwitch.state = aBool ? NSOnState : NSOffState;

  if (aBool) {
    hostHiddenMinesTextField.stringValue = @"Mines May Be Hidden";
  }
  else {
    hostHiddenMinesTextField.stringValue = @"Mines Will Always Be Visible";
  }

  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSHostHiddenMines];
}

@synthesize hostTracker=hostTrackerBool;
- (void)setHostTracker:(BOOL)aBool {
  hostTrackerBool = aBool;
  hostTrackerSwitch.state = hostTrackerBool ? NSOnState : NSOffState;
  hostTrackerField.enabled = hostTrackerBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSHostTracker];
}

@synthesize hostGameType=hostGameTypeNumber;
- (void)setHostGameType:(int)aNumber {
  hostGameTypeNumber = aNumber;
  [hostGameTypeMenu selectItemAtIndex:aNumber];
  [hostGameTypeTab selectTabViewItemAtIndex:aNumber];
  [[NSUserDefaults standardUserDefaults] setInteger:aNumber forKey:GSHostGameType];
}

@synthesize hostDominationType=hostDominationTypeNumber;
- (void)setHostDominationType:(int)aNumber {
  hostDominationTypeNumber = aNumber;
  [hostDominationTypeMatrix selectCellWithTag:aNumber];
  [[NSUserDefaults standardUserDefaults] setInteger:aNumber forKey:GSHostDominationType];
}

@synthesize hostDominationBaseControl=hostDominationBaseControlString;
- (void)setHostDominationBaseControl:(NSString *)aString {
  int hours, minutes, seconds;
  NSScanner *scanner = [NSScanner scannerWithString:aString];
  scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@":"];
  [scanner scanInt:&hours];
  [scanner scanInt:&minutes];
  [scanner scanInt:&seconds];
  hostDominationBaseControlString = [aString copy];
  hostDominationBaseControlSlider.intValue = hours*3600 + minutes*60 + seconds;
  hostDominationBaseControlField.stringValue = aString;
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSHostDominationBaseControl];
}

- (void)setJoinAddress:(NSString *)newJoinAddressString {
  joinAddressString = [newJoinAddressString copy];
  joinAddressField.stringValue = newJoinAddressString;
  [[NSUserDefaults standardUserDefaults] setObject:newJoinAddressString forKey:GSJoinAddress];
}

- (void)setJoinPort:(unsigned short)aNumber {
  joinPortNumber = aNumber;
  joinPortField.intValue = aNumber;
  [[NSUserDefaults standardUserDefaults] setInteger:aNumber forKey:GSJoinPort];
}

- (void)setJoinPasswordEnabled:(BOOL)aBool {
  joinPasswordBool = aBool;
  joinPasswordSwitch.state = aBool ? NSOnState : NSOffState;
  joinPasswordField.enabled = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSJoinHasPassword];
}

- (void)setJoinPassword:(NSString *)aString {
  joinPasswordString = [aString copy];
  joinPasswordField.stringValue = aString;
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSJoinPassword];
}

- (void)setJoinTrackerArray:(NSArray *)aArray {
  joinTrackerArray = [aArray mutableCopy];
  [joinTrackerArray sortUsingDescriptors:joinTrackerTableView.sortDescriptors];
  [joinTrackerTableView reloadData];
}

- (void)setTracker:(NSString *)aString {
  trackerString = [aString copy];
  hostTrackerField.stringValue = aString;
  joinTrackerField.stringValue = aString;
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSTracker];
}

- (void)setPrefPaneIdentifier:(NSString *)aString {
  prefToolbar.selectedItemIdentifier = aString;
  [prefTab selectTabViewItemWithIdentifier:aString];
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSPrefPaneIdentifier];
}

- (NSString*)prefPaneIdentifier
{
  return prefToolbar.selectedItemIdentifier;
}

- (void)setPlayerName:(NSString *)aString {
  playerNameString = [aString copy];
  prefPlayerNameField.stringValue = aString;
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSPlayerNameString];
}

- (void)setKeyConfigDict:(NSDictionary *)aDict {
  keyConfigDict = [aDict copy];
  [[NSUserDefaults standardUserDefaults] setObject:aDict forKey:GSKeyConfigDict];
}

- (void)setAutoSlowdown:(BOOL)aBool {
TRY
  autoSlowdownBool = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSAutoSlowdown];

  if (keyevent(BRAKEMASK, aBool) == -1) LOGFAIL(errno)

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

@synthesize showStatus = showStatusBool;
- (void)setShowStatusBool:(BOOL)aBool {
  showStatusBool = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSShowStatus];
}

@synthesize showAllegiance=showAllegianceBool;
- (void)setShowAllegianceBool:(BOOL)aBool {
  showAllegianceBool = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSShowAllegiance];
}

@synthesize showMessages=showMessagesBool;
- (void)setShowMessagesBool:(BOOL)aBool {
  showMessagesBool = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSShowMessages];
}

@synthesize builderTool=builderToolInt;
- (void)setBuilderTool:(int)anInt {
  builderToolInt = anInt;
  [builderToolMatrix selectCellWithTag:anInt];
  [[NSUserDefaults standardUserDefaults] setInteger:anInt forKey:GSBuilderTool];
}

@synthesize messageTarget=messageTargetInt;

- (void)setMessageTarget:(int)anInt {
  messageTargetInt = anInt;
  [messageTargetMatrix selectCellWithTag:anInt];
  [[NSUserDefaults standardUserDefaults] setInteger:anInt forKey:GSMessageTarget];
}

- (void)setMute:(BOOL)aBool {
  muteBool = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSMute];
}

// IBAction methods

- (IBAction)closeGame:(id)sender {
  [boloWindow orderOut:self];
  [statusPanel orderOut:self];
  [allegiancePanel orderOut:self];
  [messagesPanel orderOut:self];

  /* remove port mapping */
  for (TCMPortMapping *portMapping in [portMapper portMappings]) {
    [portMapper removePortMapping:portMapping];
  }

  [portMapper start];

  stopclient();

  if (server.setup) {
    stopserver();
    [self stopPublishing];
  }

  [self newGame:self];
}

- (IBAction)hostChoose:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.allowedFileTypes = @[NSFileTypeForHFSTypeCode('BMAP'), @"map", @"com.gengasw.xbolo.map"];
  if (hostMapString.length > 0) {
    panel.directoryURL = [NSURL fileURLWithPath:hostMapString.stringByDeletingLastPathComponent];
  }
  
  [panel beginSheetModalForWindow:newGameWindow completionHandler:^(NSInteger returnCode) {
    if (returnCode == NSOKButton) {
      [self setHostMap:panel.URLs[0].path];
    }
  }];
}

- (IBAction)hostUPnPSwitch:(NSButton*)sender {
  BOOL aBool;
  aBool = sender.state == NSOnState;
  [self setHostUPnP:aBool];
  if (!aBool) {
    [hostPortField selectText:self];
  }
}

- (IBAction)hostPort:(id)sender {
  [self setHostPort:[sender intValue]];
}

- (IBAction)hostPasswordSwitch:(NSButton*)sender {
  BOOL aBool;
  aBool = sender.state == NSOnState;
  [self setHasHostPassword:aBool];
  if (aBool) {
    [hostPasswordField selectText:self];
  }
}

- (IBAction)hostPassword:(id)sender {
  [self setHostPassword:[sender stringValue]];
}

- (IBAction)hostTimeLimitSwitch:(NSButton*)sender {
  BOOL aBool;
  aBool = sender.state == NSOnState;
  [self setHasHostTimeLimit:aBool];
  if (aBool) {
    [hostTimeLimitField selectText:self];
  }
}

- (IBAction)hostTimeLimit:(id)sender {
  NSString *aString;
  if ([sender isMemberOfClass:[NSTextField class]]) {
    aString = [sender stringValue];
  }
  else {
    int hours, minutes, seconds;
    int time;
    time = [sender intValue];
    hours = time/3600;
    minutes = (time%3600)/60;
    seconds = (time%3600)%60;
    aString =
      [NSString stringWithFormat:@"%@:%@:%@",
        (hours   >= 10 ? [NSString stringWithFormat:@"%d", hours  ] : [NSString stringWithFormat:@"0%d", hours  ]),
        (minutes >= 10 ? [NSString stringWithFormat:@"%d", minutes] : [NSString stringWithFormat:@"0%d", minutes]),
        (seconds >= 10 ? [NSString stringWithFormat:@"%d", seconds] : [NSString stringWithFormat:@"0%d", seconds])];
  }
  [self setHostTimeLimit:aString];
  [hostTimeLimitField selectText:self];
}

- (IBAction)hostHiddenMinesSwitch:(NSButton*)sender {
  BOOL aBool;
  aBool = sender.state == NSOnState;
  [self setHostHiddenMines:aBool];
}

- (IBAction)hostTrackerSwitch:(NSButton*)sender {
  BOOL aBool;
  aBool = sender.state == NSOnState;
  [self setHostTracker:aBool];
  if (aBool) {
    [hostTrackerField selectText:self];
  }
}

- (IBAction)hostGameType:(id)sender {
  [self setHostGameType:(int)[sender indexOfSelectedItem]];
}

- (IBAction)hostDominationType:(id)sender {
  [self setHostDominationType:(int)[hostDominationTypeMatrix.selectedCell tag]];
}

- (IBAction)hostDominationBaseControl:(id)sender {
  NSString *aString;
  if ([sender isMemberOfClass:[NSTextField class]]) {
    aString = [sender stringValue];
  }
  else {
    int hours, minutes, seconds;
    int time;
    time = [sender intValue];
    hours = time/3600;
    minutes = (time%3600)/60;
    seconds = (time%3600)%60;
    aString =
      [NSString stringWithFormat:@"%@:%@:%@",
        (hours   >= 10 ? [NSString stringWithFormat:@"%d", hours  ] : [NSString stringWithFormat:@"0%d", hours  ]),
        (minutes >= 10 ? [NSString stringWithFormat:@"%d", minutes] : [NSString stringWithFormat:@"0%d", minutes]),
        (seconds >= 10 ? [NSString stringWithFormat:@"%d", seconds] : [NSString stringWithFormat:@"0%d", seconds])];
  }

  [self setHostDominationBaseControl:aString];
  [hostDominationBaseControlField selectText:self];
}

- (void)portMapperDidFinishWork:(NSNotification *)aNotification {
TRY
  for (TCMPortMapping *mapping in [portMapper portMappings]) {
    if ([mapping localPort] == getservertcpport()) {
      if ([mapping mappingStatus] == TCMPortMappingStatusMapped && [mapping transportProtocol] == TCMPortMappingTransportProtocolBoth) {
        if (hostTrackerBool) {
          startserverthreadwithtracker(trackerString.UTF8String, [mapping externalPort], playerNameString.UTF8String, hostMapString.lastPathComponent.UTF8String, registercallback);
        }
        else {
          [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMPortMapperDidFinishWorkNotification object:portMapper];

          if (hostTrackerBool) {  /* not using UPnP but registering with tracker */
            if (startserverthreadwithtracker(trackerString.UTF8String, getservertcpport(), playerNameString.UTF8String, hostMapString.lastPathComponent.UTF8String, registercallback)) LOGFAIL(errno)
          }
          else {
            if (startserverthread()) LOGFAIL(errno)
          }

          break;
        }
      }
      else {
        NSSet<TCMPortMapping*> *mappings;

        [joinProgressWindow orderOut:self];
        [joinProgressIndicator stopAnimation:self];
        [NSApp endSheet:joinProgressWindow];

        [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMPortMapperDidFinishWorkNotification object:portMapper];

        mappings = [[portMapper portMappings] copy];

        for (TCMPortMapping *portMapping in mappings) {
          [portMapper removePortMapping:portMapping];
        }

        [portMapper start];

        NSBeginAlertSheet(@"UPnP Failed", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"UPnP was unable to map to a port.  Please check your router settings.");

        if (stopserver()) LOGFAIL(errno)
      }
    }
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (IBAction)hostOK:(id)sender {
  //Always stop listening for Bonjour methods.
  [self stopListening];
  
  NSData *mapData;

TRY
  if (hostMapString.length == 0) {
    NSBeginAlertSheet(@"No map chosen.", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Please choose a map.");
  }
  else if ((mapData = [NSData dataWithContentsOfFile:hostMapString]) == nil) {
    NSBeginAlertSheet(@"Error occured when openning map.", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Please try another map.");
    [self setHostMap:[NSString string]];
  }
  else {
    NSScanner *scanner;
    int hours, minutes, seconds, timelimit;
    struct Domination domination;
    int paused;

    scanner = [NSScanner scannerWithString:hostTimeLimitString];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@":"];
    [scanner scanInt:&hours];
    [scanner scanInt:&minutes];
    [scanner scanInt:&seconds];
    timelimit = hours*3600 + minutes*60 + seconds;

    domination.type = hostDominationTypeNumber;
    scanner = [NSScanner scannerWithString:hostDominationBaseControlString];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@":"];
    [scanner scanInt:&hours];
    [scanner scanInt:&minutes];
    [scanner scanInt:&seconds];
    domination.basecontrol = hours*3600 + minutes*60 + seconds;

    if([[NSUserDefaults standardUserDefaults] boolForKey:@"GSStartGameImmediately"]) {
      paused = 0;
    }
    else {
      paused = 1;
    }

    joinProgressStatusTextField.stringValue = @"Starting...";
    [joinProgressIndicator setIndeterminate:YES];
    joinProgressIndicator.doubleValue = 0.0;
    [joinProgressIndicator startAnimation:self];
    [NSApp beginSheet:joinProgressWindow modalForWindow:newGameWindow modalDelegate:self didEndSelector:nil contextInfo:nil];

    if (setupserver(paused, mapData.bytes, mapData.length, hostUPnPBool ? 0 : hostPortNumber, hostPasswordBool ? hostPasswordString.UTF8String : NULL, hostTimeLimitBool ? timelimit : 0, hostHiddenMinesBool, 0, hostGameTypeNumber, &domination)) LOGFAIL(errno)

    /* if using UPnP */
    if (hostUPnPBool) {
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperDidFinishWork:) name:TCMPortMapperDidFinishWorkNotification object:portMapper];
      [portMapper addPortMapping:[TCMPortMapping portMappingWithLocalPort:getservertcpport() desiredExternalPort:getservertcpport() transportProtocol:TCMPortMappingTransportProtocolBoth userInfo:nil]];
      [portMapper start];

      joinProgressStatusTextField.stringValue = @"UPnP Mapping Port...";
    }
    else if (hostTrackerBool) {  /* not using UPnP but registering with tracker */
      if (startserverthreadwithtracker(trackerString.UTF8String, getservertcpport(), playerNameString.UTF8String, hostMapString.lastPathComponent.UTF8String, registercallback)) LOGFAIL(errno)
    }
    else {  /* not using UPnP and not registering with tracker */
      if (startserverthread()) LOGFAIL(errno)
      if (startclient("localhost", getservertcpport(), playerNameString.UTF8String, hostPasswordBool ? hostPasswordString.UTF8String : NULL)) LOGFAIL(errno)
    }
    if (_broadcastBonjour) { /* always check if we're broadcasting via Bonjour */
      [self startPublishing];
    }
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  case ECORFILE:
    [joinProgressWindow orderOut:self];
    [joinProgressIndicator stopAnimation:self];
    [NSApp endSheet:joinProgressWindow];
    NSBeginAlertSheet(@"Unable to Open Map File", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Please choose another map.");
    CLEARERRLOG
    break;

  case EINCMPAT:
    [joinProgressWindow orderOut:self];
    [joinProgressIndicator stopAnimation:self];
    [NSApp endSheet:joinProgressWindow];
    NSBeginAlertSheet(@"Incomaptile Map Version", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Please choose another map.");
    CLEARERRLOG
    break;

  case EADDRINUSE:
    [joinProgressWindow orderOut:self];
    [joinProgressIndicator stopAnimation:self];
    [NSApp endSheet:joinProgressWindow];
    NSBeginAlertSheet(@"Port Unavailable", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Please choose another port.");
    CLEARERRLOG
    break;

  default:
    [joinProgressWindow orderOut:self];
    [joinProgressIndicator stopAnimation:self];
    [NSApp endSheet:joinProgressWindow];
    NSBeginAlertSheet(@"Unexpected Error", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Error #%d: %s", ERROR, strerror(ERROR));
    CLEARERRLOG
    break;
  }
END
}

- (IBAction)joinAddress:(id)sender {
  [self setJoinAddress:[sender stringValue]];
}

- (IBAction)joinPort:(id)sender {
  [self setJoinPort:[sender intValue]];
}

- (IBAction)joinPasswordSwitch:(NSButton*)sender {
  BOOL aBool;
  aBool = sender.state == NSOnState;
  [self setJoinPasswordEnabled:aBool];

  if (aBool) {
    [joinPasswordField selectText:self];
  }
}

- (IBAction)joinPassword:(id)sender {
  self.joinPassword = [sender stringValue];
}

- (IBAction)tracker:(id)sender {
  self.tracker = [sender stringValue];
}

- (IBAction)joinTrackerRefresh:(id)sender {
TRY
  [joinTrackerTableView deselectAll:self];
  joinProgressStatusTextField.stringValue = @"";
  [joinProgressIndicator setIndeterminate:YES];
  joinProgressIndicator.doubleValue = 0.0;
  [joinProgressIndicator startAnimation:self];
  [NSApp beginSheet:joinProgressWindow modalForWindow:newGameWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
  
  // get tracker list from bolo
  if (initlist(&trackerlist)) LOGFAIL(errno)
  if (listtracker(trackerString.UTF8String, &trackerlist, getlisttrackerstatus)) LOGFAIL(errno)
  if (listener) {
    // "Have you tried turning it off then on again?"
    [self stopListening];
    [self startListening];
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (IBAction)joinOK:(id)sender {
TRY
  joinProgressStatusTextField.stringValue = @"";
  [joinProgressIndicator setIndeterminate:YES];
  joinProgressIndicator.doubleValue = 0.0;
  [joinProgressIndicator startAnimation:self];
  [NSApp beginSheet:joinProgressWindow modalForWindow:newGameWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
  if (startclient(joinAddressString.UTF8String, joinPortNumber, playerNameString.UTF8String, joinPasswordBool ? joinPasswordString.UTF8String : NULL)) LOGFAIL(errno)

  //Always stop listening for Bonjour methods.
  [self stopListening];

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (IBAction)joinCancel:(id)sender {
  NSEnumerator *enumerator;
  TCMPortMapping *portMapping;

TRY
  /* remove notifications from portmapper */
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMPortMapperDidFinishWorkNotification object:portMapper];

  /* remove all port maps */
  enumerator = [[portMapper portMappings] objectEnumerator];

  while ((portMapping = [enumerator nextObject])) {
    [portMapper removePortMapping:portMapping];
  }

  [portMapper start];

  if (client_running) {
    if (stopclient()) LOGFAIL(errno)
  }

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  /* close modal window */
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];

CLEANUP
  switch (ERROR) {
  case 0:
    return;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
  }
END
}

- (IBAction)statusPanel:(id)sender {
  if (statusPanel.keyWindow) {
    [boloWindow makeKeyAndOrderFront:self];
  }
  else {
    [statusPanel makeKeyAndOrderFront:self];
  }
}

- (IBAction)allegiancePanel:(id)sender {
  if (allegiancePanel.keyWindow) {
    [boloWindow makeKeyAndOrderFront:self];
  }
  else {
    [allegiancePanel makeKeyAndOrderFront:self];
  }
}

- (IBAction)messagesPanel:(id)sender {
  if (messagesPanel.keyWindow) {
    [boloWindow makeKeyAndOrderFront:self];
  }
  else {
    [messagesPanel makeKeyAndOrderFront:self];
  }
}

- (IBAction)newGame:(id)sender {
  [newGameWindow makeKeyAndOrderFront:self];
}

- (IBAction)toggleJoin:(id)sender {
  togglejoingame();
  [self updatePublishedInfo];
}

- (IBAction)toggleMute:(id)sender {
  [self setMute:!muteBool];
}

- (IBAction)gamePauseResumeMenu:(id)sender {
  pauseresumegame();
  [self updatePublishedInfo];
}

- (IBAction)kickPlayer:(id)sender {
  kickplayer((int)[sender tag]);
  [self updatePublishedInfo];
}

- (IBAction)banPlayer:(id)sender {
  banplayer((int)[sender tag]);
  [self updatePublishedInfo];
}

- (IBAction)unbanPlayer:(id)sender {
  unbanplayer((int)[sender tag]);
  [self updatePublishedInfo];
}

- (IBAction)scrollUp:(id)sender {
  NSScreen *screen;
  NSRect rect;
  NSPoint nspoint;
  CGPoint cgpoint;

  rect = boloView.visibleRect;
  rect.origin.y += 64.0/kZoomLevels[zoomLevel];
  [boloView scrollRectToVisible:rect];

  nspoint = [NSEvent mouseLocation];
  if ([boloView mouse:[boloView convertPoint:boloWindow.mouseLocationOutsideOfEventStream fromView:boloWindow.contentView] inRect:boloView.visibleRect] && (screen = boloWindow.screen)) {
    cgpoint.x = nspoint.x;
    cgpoint.y = screen.frame.size.height - nspoint.y + 64.0;
    CGWarpMouseCursorPosition(cgpoint);
  }
}

- (IBAction)scrollDown:(id)sender {
  NSScreen *screen;
  NSRect rect;
  NSPoint nspoint;
  CGPoint cgpoint;

  rect = boloView.visibleRect;
  rect.origin.y -= 64.0/kZoomLevels[zoomLevel];
  [boloView scrollRectToVisible:rect];

  nspoint = [NSEvent mouseLocation];
  if ([boloView mouse:[boloView convertPoint:boloWindow.mouseLocationOutsideOfEventStream fromView:boloWindow.contentView] inRect:boloView.visibleRect] && (screen = boloWindow.screen)) {
    cgpoint.x = nspoint.x;
    cgpoint.y = screen.frame.size.height - nspoint.y - 64.0;
    CGWarpMouseCursorPosition(cgpoint);
  }
}

- (IBAction)scrollLeft:(id)sender {
  NSScreen *screen;
  NSRect rect;
  NSPoint nspoint;
  CGPoint cgpoint;

  rect = boloView.visibleRect;
  rect.origin.x -= 64.0/kZoomLevels[zoomLevel];
  [boloView scrollRectToVisible:rect];

  nspoint = [NSEvent mouseLocation];
  if ([boloView mouse:[boloView convertPoint:boloWindow.mouseLocationOutsideOfEventStream fromView:boloWindow.contentView] inRect:boloView.visibleRect] && (screen = boloWindow.screen)) {
    cgpoint.x = nspoint.x + 64.0;
    cgpoint.y = screen.frame.size.height - nspoint.y;
    CGWarpMouseCursorPosition(cgpoint);
  }
}

- (IBAction)scrollRight:(id)sender {
  NSScreen *screen;
  NSRect rect;
  NSPoint nspoint;
  CGPoint cgpoint;

  rect = boloView.visibleRect;
  rect.origin.x += 64.0/kZoomLevels[zoomLevel];
  [boloView scrollRectToVisible:rect];

  nspoint = [NSEvent mouseLocation];
  if ([boloView mouse:[boloView convertPoint:boloWindow.mouseLocationOutsideOfEventStream fromView:boloWindow.contentView] inRect:boloView.visibleRect] && (screen = boloWindow.screen)) {
    cgpoint.x = nspoint.x - 64.0;
    cgpoint.y = screen.frame.size.height - nspoint.y;
    CGWarpMouseCursorPosition(cgpoint);
  }
}

- (IBAction)requestAlliance:(id)sender {
  NSInteger i;
  NSIndexSet *set;
  uint16_t players;
  int gotlock = 0;

TRY
  players = 0;
  set = playerInfoTableView.selectedRowIndexes;

  for (i = 0; (i = [set indexGreaterThanOrEqualToIndex:i]) != NSNotFound; i++) {
    players |= 1 << [playerInfoArray[i][@"Index"] intValue];
  }

  // lock client
  if (lockclient()) LOGFAIL(errno)
  gotlock = 1;

  if (requestalliance(players)) LOGFAIL(errno)

  // unlock client
  if (unlockclient()) LOGFAIL(errno)
  gotlock = 0;

CLEANUP
  if (gotlock) {
    unlockclient();
  }

  switch (ERROR) {
  case 0:
    return;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
  }
END
}

- (IBAction)leaveAlliance:(id)sender {
  NSInteger i;
  NSIndexSet *set;
  uint16_t players;
  BOOL gotlock = 0;

TRY
  players = 0;
  set = playerInfoTableView.selectedRowIndexes;

  for (i = 0; (i = [set indexGreaterThanOrEqualToIndex:i]) != NSNotFound; i++) {
    players |= 1 << [playerInfoArray[i][@"Index"] intValue];
  }

  // lock client
  if (lockclient()) LOGFAIL(errno)
  gotlock = 1;

  if (leavealliance(players)) LOGFAIL(errno)

  // unlock client
  if (unlockclient()) LOGFAIL(errno)
  gotlock = 0;

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

- (IBAction)sendMessage:(id)sender {
TRY
  if (sendmessage(messageTextField.stringValue.UTF8String, messageTargetInt)) LOGFAIL(errno)
  [messageTextField selectText:self];

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (IBAction)messageTarget:(id)sender {
  id cell;

  if ((cell = [sender selectedCell]) != nil) {
    [self setMessageTarget:(int)[cell tag]];
  }
}

- (IBAction)showPrefs:(id)sender {
  [preferencesWindow makeKeyAndOrderFront:self];
}

- (IBAction)prefPane:(id)sender {
  [self setPrefPaneIdentifier:[sender itemIdentifier]];
}

- (IBAction)prefPlayerName:(id)sender {
  self.playerName = [sender stringValue];
}

- (IBAction)revertKeyConfig:(id)sender {
  NSDictionary *dict;
  dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:GSKeyConfigDict];
  prefAccelerateField.stringValue = [dict allKeysForObject:GSAccelerate][0];
  prefBrakeField.stringValue = [dict allKeysForObject:GSBrake][0];
  prefTurnLeftField.stringValue = [dict allKeysForObject:GSTurnLeft][0];
  prefTurnRightField.stringValue = [dict allKeysForObject:GSTurnRight][0];
  prefLayMineField.stringValue = [dict allKeysForObject:GSLayMine][0];
  prefShootField.stringValue = [dict allKeysForObject:GSShoot][0];
  prefIncreaseAimField.stringValue = [dict allKeysForObject:GSIncreaseAim][0];
  prefDecreaseAimField.stringValue = [dict allKeysForObject:GSDecreaseAim][0];
  prefUpField.stringValue = [dict allKeysForObject:GSUp][0];
  prefDownField.stringValue = [dict allKeysForObject:GSDown][0];
  prefLeftField.stringValue = [dict allKeysForObject:GSLeft][0];
  prefRightField.stringValue = [dict allKeysForObject:GSRight][0];
  prefTankViewField.stringValue = [dict allKeysForObject:GSTankView][0];
  prefPillViewField.stringValue = [dict allKeysForObject:GSPillView][0];
  prefAutoSlowdownSwitch.state = [[NSUserDefaults standardUserDefaults] boolForKey:GSAutoSlowdown] ? NSOnState : NSOffState;
}

- (IBAction)applyKeyConfig:(id)sender {
  NSMutableDictionary<NSString*,NSString*> *dict;
  dict = [NSMutableDictionary dictionary];
  if
    (
      !(
        setKey(dict, preferencesWindow, prefAccelerateField, GSAccelerate) ||
        setKey(dict, preferencesWindow, prefBrakeField, GSBrake) ||
        setKey(dict, preferencesWindow, prefTurnLeftField, GSTurnLeft) ||
        setKey(dict, preferencesWindow, prefTurnRightField, GSTurnRight) ||
        setKey(dict, preferencesWindow, prefLayMineField, GSLayMine) ||
        setKey(dict, preferencesWindow, prefShootField, GSShoot) ||
        setKey(dict, preferencesWindow, prefIncreaseAimField, GSIncreaseAim) ||
        setKey(dict, preferencesWindow, prefDecreaseAimField, GSDecreaseAim) ||
        setKey(dict, preferencesWindow, prefUpField, GSUp) ||
        setKey(dict, preferencesWindow, prefDownField, GSDown) ||
        setKey(dict, preferencesWindow, prefLeftField, GSLeft) ||
        setKey(dict, preferencesWindow, prefRightField, GSRight) ||
        setKey(dict, preferencesWindow, prefTankViewField, GSTankView) ||
        setKey(dict, preferencesWindow, prefPillViewField, GSPillView)
      )
    )
  {
    [self setKeyConfigDict:dict];
    [self setAutoSlowdown:prefAutoSlowdownSwitch.state == NSOnState];
  }
}

// map interface actions

- (IBAction)zoomIn:(id)sender {
  NSSize size;
  NSRect visRect;

  if (zoomLevel < MAX_ZOOM) {
    zoomLevel++;
    CGFloat zoom = kZoomLevels[zoomLevel];
    visRect = boloView.visibleRect;
    size.width = 4096.0*zoom;
    size.height = 4096.0*zoom;
    [boloView setFrameSize:size];
    [boloView setBoundsSize:NSMakeSize(4096.0, 4096.0)];
    [boloView scrollPoint:NSMakePoint(visRect.origin.x + 0.25*visRect.size.width, visRect.origin.y + 0.25*visRect.size.height)];
    [boloView setNeedsDisplay:YES];
  }
}

- (IBAction)zoomOut:(id)sender {
  NSSize size;
  NSRect visRect;

  if (zoomLevel > 0) {
    zoomLevel--;
    CGFloat zoom = kZoomLevels[zoomLevel];
    visRect = boloView.visibleRect;
    size.width = 4096.0*zoom;
    size.height = 4096.0*zoom;
    [boloView setFrameSize:size];
    [boloView setBoundsSize:NSMakeSize(4096.0, 4096.0)];
    [boloView scrollPoint:NSMakePoint(visRect.origin.x - 0.5*visRect.size.width, visRect.origin.y - 0.5*visRect.size.height)];
    [boloView setNeedsDisplay:YES];
  }
}

- (IBAction)builderTool:(id)sender {
  id cell;

  if ((cell = [sender selectedCell]) != nil) {
    [self setBuilderTool:(int)[cell tag]];
  }
}

- (IBAction)builderToolMenu:(id)sender {
	[self setBuilderTool:(int)[sender tag]];
}

- (IBAction)tankCenter:(id)sender {
  [boloView tankCenter];
  return;
  
  NSRect rect;
  int gotlock = 0;

TRY
  rect = boloView.visibleRect;

  if (lockclient()) LOGFAIL(errno)
  gotlock = 1;

  rect.origin.x = ((client.players[client.player].tank.x + 0.5)*16.0) - rect.size.width*0.5;
  rect.origin.y = ((FWIDTH - (client.players[client.player].tank.y + 0.5))*16.0) - rect.size.height*0.5;

  if (unlockclient()) LOGFAIL(errno)
  gotlock = 0;

  [boloView scrollRectToVisible:rect];

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

- (IBAction)pillCenter:(id)sender {
  [boloView nextPillCenter];
  return;

  GSPoint square;
  NSRect rect;
  int i, j;
  int gotlock = 0;

TRY
  rect = boloView.visibleRect;
  square.x = (rect.origin.x + rect.size.width*0.5)/16.0;
  square.y = FWIDTH - ((rect.origin.y + rect.size.height*0.5)/16.0);

  if (lockclient()) LOGFAIL(errno)
  gotlock = 1;

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
          rect.origin.x = ((square.x + 0.5)*16.0) - rect.size.width*0.5;
          rect.origin.y = ((FWIDTH - (square.y + 0.5))*16.0) - rect.size.height*0.5;
          SUCCESS
        }
      }
      
      square.x = client.pills[i].x;
      square.y = client.pills[i].y;
      if (unlockclient()) LOGFAIL(errno)
      gotlock = 0;
      rect.origin.x = ((square.x + 0.5)*16.0) - rect.size.width*0.5;
      rect.origin.y = ((FWIDTH - (square.y + 0.5))*16.0) - rect.size.height*0.5;
      SUCCESS
    }
  }
  
  for (i = 0; i < client.npills; i++) {
    if (
        client.pills[i].owner == client.player &&
        client.pills[i].armour != ONBOARD && client.pills[i].armour != 0
        ) {
      square.x = client.pills[i].x;
      square.y = client.pills[i].y;
      if (unlockclient()) LOGFAIL(errno)
      gotlock = 0;
      rect.origin.x = ((square.x + 0.5)*16.0) - rect.size.width*0.5;
      rect.origin.y = ((FWIDTH - (square.y + 0.5))*16.0) - rect.size.height*0.5;
      SUCCESS
    }
  }

  if (unlockclient()) LOGFAIL(errno)
  gotlock = 0;

CLEANUP
  switch (ERROR) {
  case 0:
    [boloView scrollRectToVisible:rect];
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

// key event methods
- (void)keyEvent:(BOOL)event forKey:(unsigned short)keyCode {
  NSString *object;

TRY
  object = keyConfigDict[[NSString stringWithFormat:@"%d", keyCode]];
  if (object != nil) {
    if ([object isEqualToString:GSAccelerate]) {
      if (autoSlowdownBool) {
        if (keyevent(ACCELMASK, event) == -1) LOGFAIL(errno)
        if (keyevent(BRAKEMASK, !event) == -1) LOGFAIL(errno)
      }
      else {
        if (keyevent(ACCELMASK, event) == -1) LOGFAIL(errno)
      }
    }
    else if ([object isEqualToString:GSBrake]) {
      if (!autoSlowdownBool) {
        if (keyevent(BRAKEMASK, event) == -1) LOGFAIL(errno)
      }
    }
    else if ([object isEqualToString:GSTurnLeft]) {
      if (keyevent(TURNLMASK, event) == -1) LOGFAIL(errno)
    }
    else if ([object isEqualToString:GSTurnRight]) {
      if (keyevent(TURNRMASK, event) == -1) LOGFAIL(errno)
    }
    else if ([object isEqualToString:GSLayMine]) {
      if (keyevent(LMINEMASK, event) == -1) LOGFAIL(errno)
    }
    else if ([object isEqualToString:GSShoot]) {
      if (keyevent(SHOOTMASK, event) == -1) LOGFAIL(errno)
    }
    else if ([object isEqualToString:GSIncreaseAim]) {
      if (keyevent(INCREMASK, event) == -1) LOGFAIL(errno)
    }
    else if ([object isEqualToString:GSDecreaseAim]) {
      if (keyevent(DECREMASK, event) == -1) LOGFAIL(errno)
    }
    else if ([object isEqualToString:GSUp]) {
      if (event) {
        [boloView scroll:CGPointMake(0, -16)];
      } else {
        [boloView scroll:CGPointZero];
      }
    }
    else if ([object isEqualToString:GSDown]) {
      if (event) {
        [boloView scroll:CGPointMake(0, 16)];
      } else {
        [boloView scroll:CGPointZero];
      }
    }
    else if ([object isEqualToString:GSLeft]) {
      if (event) {
        [boloView scroll:CGPointMake(-16, 0)];
      } else {
        [boloView scroll:CGPointZero];
      }
    }
    else if ([object isEqualToString:GSRight]) {
      if (event) {
        [boloView scroll:CGPointMake(16, 0)];
      } else {
        [boloView scroll:CGPointZero];
      }
    }
    else if ([object isEqualToString:GSTankView]) {
      if (event) {
        [self tankCenter:self];
      }
    }
    else if ([object isEqualToString:GSPillView]) {
      if (event) {
        [self pillCenter:self];
      }
    }
  }
  else if (keyCode == 18 && event)
    [self setBuilderTool: 0];
  else if (keyCode == 19 && event)
    [self setBuilderTool: 1];
  else if (keyCode == 20 && event)
    [self setBuilderTool: 2];
  else if (keyCode == 21 && event)
    [self setBuilderTool: 3];
  else if (keyCode == 23 && event)
    [self setBuilderTool: 4];

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
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

// validate menu items method

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem {
  SEL action;
  action = menuItem.action;
	if (action == @selector(newGame:)) {
    return !client_running;
	}
	else if (action == @selector(closeGame:)) {
    return client_running;
	}
	else if (action == @selector(statusPanel:)) {
		return client_running;
	}
  else if (action == @selector(allegiancePanel:)) {
    return client_running;
  }
	else if (action == @selector(messagesPanel:)) {
		return client_running;
	}
	else if (action == @selector(hostGameType:)) {
    switch (menuItem.tag) {
    case kDominationGameType:  // Domination
      return YES;

    case kCTFGameType:  // Capture the Flag
      return NO;

    case kKOTHGameType:  // King of the Hill
      return NO;

    case kBallGameType:  // Kill the Man with the Ball
      return NO;

    case kBodyGameType:  // Body Count
      return NO;

    default:
      return NO;
    }
	}
	else if (action == @selector(builderToolMenu:)) {
		menuItem.state = menuItem.tag == builderToolInt ? NSOnState : NSOffState;
		return YES;
	}
	else if (action == @selector(gamePauseResumeMenu:)) {
    lockserver();

    if (server.setup) {
      menuItem.state = server.pause ? NSOnState: NSOffState;
      unlockserver();
      return YES;
    }
    else {
      unlockserver();
      return NO;
    }
  }
	else if (action == @selector(toggleJoin:)) {
    lockserver();

    if (server.setup) {
      menuItem.state = server.allowjoin ? NSOnState: NSOffState;
      unlockserver();
      return YES;
    }
    else {
      unlockserver();
      return NO;
    }
  }
	else if (action == @selector(toggleMute:)) {
    menuItem.state = muteBool;
    return YES;
  }
	else if (action == @selector(kickPlayer:)) {
    lockserver();

    if (server.setup) {
      int player, ret;

      player = (int)menuItem.tag;

      if (server.players[player].cntlsock != -1) {
        menuItem.title = [NSString stringWithFormat:@"%@@%@", [NSString stringWithString:@(server.players[player].name)], [NSString stringWithString:@(inet_ntoa(server.players[player].addr.sin_addr))]];
        lockclient();
        ret = player != client.player;
        unlockclient();
      }
      else {
        ret = NO;
      }

      unlockserver();
      menuItem.hidden = !ret;
      return ret;
    }
    else {
      unlockserver();
      [menuItem setHidden:YES];
      return NO;
    }
    return YES;
  }
	else if (action == @selector(banPlayer:)) {
    lockserver();

    if (server.setup) {
      int player, ret;

      player = (int)menuItem.tag;

      if (server.players[player].cntlsock != -1) {
        menuItem.title = [NSString stringWithFormat:@"%@@%@", [NSString stringWithString:@(server.players[player].name)], [NSString stringWithString:@(inet_ntoa(server.players[player].addr.sin_addr))]];
        lockclient();
        ret = player != client.player;
        unlockclient();
      }
      else {
        ret = NO;
      }

      unlockserver();
      menuItem.hidden = !ret;
      return ret;
    }
    else {
      unlockserver();
      [menuItem setHidden:YES];
      return NO;
    }
  }
    else if (action == @selector(choseRobotMenuItem:)) return [self _validateRobotMenuItem: menuItem];
    else if (action == @selector(hostToggleBonjourBroadcast:)) {
      lockserver();
      
      if (server.setup) {
        menuItem.state = _broadcastBonjour ? NSOnState: NSOffState;
        unlockserver();
        return YES;
      } else {
        menuItem.state = NSOffState;
        unlockserver();
        return NO;
      }
    }
	else {
		return YES;
	}
}

// NSApplication delegate methods

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
  [statusPanel setFloatingPanel:YES];
  [allegiancePanel setFloatingPanel:YES];
  [messagesPanel setFloatingPanel:YES];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification {
  [statusPanel setFloatingPanel:NO];
  [allegiancePanel setFloatingPanel:NO];
  [messagesPanel setFloatingPanel:NO];
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
  if (!client_running) {
    [newGameWindow makeKeyAndOrderFront:self];
    if([[NSUserDefaults standardUserDefaults] boolForKey: @"GSStartGameImmediately"])
      [self hostOK:nil];
    else
    {
        NSString *tojoin = [[NSUserDefaults standardUserDefaults] objectForKey: @"GSJoinGameImmediately"];
        if(tojoin)
        {
            NSArray *components = [tojoin componentsSeparatedByString: @":"];
            [self setJoinAddress: components[0]];
            [self setJoinPort: [components[1] intValue]];
            [self joinOK: nil];
        }
    }
    return YES;
  }
  else {
    return NO;
  }
}

// host with a map file

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
  if (!client_running) {
    [self setHostMap:filename];
    [newGameTabView selectFirstTabViewItem:self];
    [newGameWindow makeKeyAndOrderFront:self];
    return YES;
  }
  else {
    return NO;
  }
}

// NSMenu delegate methods
- (void)menuNeedsUpdate:(NSMenu *)menu {
  NSInteger i;

  for (i = menu.numberOfItems - 1; i >= 0; i--) {
    [menu removeItemAtIndex:i];
  }

  lockserver();

  if (server.setup) {
    struct ListNode *node;
    int i;
    struct BannedPlayer *bannedplayer;
    NSMenuItem *menuItem;

    i = 0;
    node = nextlist(&server.bannedplayers);

    while (node) {
      bannedplayer = ptrlist(node);
      menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@@%@", [NSString stringWithString:@(bannedplayer->name)], [NSString stringWithString:@(inet_ntoa(bannedplayer->sin_addr))]] action:@selector(unbanPlayer:) keyEquivalent:@""];
      menuItem.target = self;
      menuItem.tag = i;
      [menu addItem:menuItem];
      i++;
      node = nextlist(node);
    }
  }

  unlockserver();
}

// NSToolbar methods

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  if (toolbar == prefToolbar) {
    if ([itemIdentifier isEqual:GSToolbarPlayerInfoItemIdentifier]) {
      return toolbarPlayerInfoItem;
    }
    else if ([itemIdentifier isEqual:GSToolbarKeyConfigItemIdentifier]) {
      return toolbarKeyConfigItem;
    }
  }
  else if (toolbar == boloToolbar) {
    if ([itemIdentifier isEqual:GSBoloToolItemIdentifier]) {
      return builderToolItem;
    }
    else if ([itemIdentifier isEqual:GSTankCenterItemIdentifier]) {
      return tankCenterItem;
    }
    else if ([itemIdentifier isEqual:GSPillCenterItemIdentifier]) {
      return pillCenterItem;
    }
    else if ([itemIdentifier isEqual:GSZoomInItemIdentifier]) {
      return zoomInItem;
    }
    else if ([itemIdentifier isEqual:GSZoomOutItemIdentifier]) {
      return zoomOutItem;
    }
  }
  return nil;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
  if (toolbar == prefToolbar) {
    return @[GSToolbarPlayerInfoItemIdentifier, GSToolbarKeyConfigItemIdentifier];
  }
  else if (toolbar == boloToolbar) {
    return @[GSBoloToolItemIdentifier, GSTankCenterItemIdentifier, GSPillCenterItemIdentifier, GSZoomInItemIdentifier, GSZoomOutItemIdentifier, NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier];
  }
  else {
    return [NSArray array];
  }
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
  if (toolbar == prefToolbar) {
    return @[GSToolbarPlayerInfoItemIdentifier, GSToolbarKeyConfigItemIdentifier];
  }
  else if (toolbar == boloToolbar) {
    return @[GSBoloToolItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, GSTankCenterItemIdentifier, GSPillCenterItemIdentifier, NSToolbarSeparatorItemIdentifier, GSZoomInItemIdentifier, GSZoomOutItemIdentifier];
  }
  else {
    return [NSArray array];
  }
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
  if (toolbar == prefToolbar) {
    return @[GSToolbarPlayerInfoItemIdentifier, GSToolbarKeyConfigItemIdentifier];
  }
  else if (toolbar == boloToolbar) {
    return [NSArray array];
  }
  else {
    return [NSArray array];
  }
}

// NSWindow delegate methods
- (void)windowDidBecomeKey:(NSNotification *)aNotification {
  if (aNotification.object == statusPanel) {
    [self setShowStatus:YES];
  }
  else if (aNotification.object == allegiancePanel) {
    [self setShowAllegiance:YES];
  }
  else if (aNotification.object == messagesPanel) {
    [self setShowMessages:YES];
  }
}

- (void)windowWillClose:(NSNotification *)aNotification {
  if (aNotification.object == statusPanel) {
    [self setShowStatus:NO];
  }
  else if (aNotification.object == allegiancePanel) {
    [self setShowAllegiance:NO];
  }
  else if (aNotification.object == messagesPanel) {
    [self setShowMessages:NO];
  }
}

- (void)setPlayerStatus:(NSString *)aString {
  NSEnumerator *enumerator;
  NSAttributedString *name;
  NSMutableDictionary *playerRecord;
  NSString *indexString;
  NSImageView *imageView;
  int gotlock = 0;
  int player;

TRY
  if (lockclient()) LOGFAIL(errno)
  gotlock = 1;

  player = aString.intValue;

  switch (player) {
  case 0x0:
    imageView = player0StatusImageView;
    break;

  case 0x1:
    imageView = player1StatusImageView;
    break;

  case 0x2:
    imageView = player2StatusImageView;
    break;

  case 0x3:
    imageView = player3StatusImageView;
    break;

  case 0x4:
    imageView = player4StatusImageView;
    break;

  case 0x5:
    imageView = player5StatusImageView;
    break;

  case 0x6:
    imageView = player6StatusImageView;
    break;

  case 0x7:
    imageView = player7StatusImageView;
    break;

  case 0x8:
    imageView = player8StatusImageView;
    break;

  case 0x9:
    imageView = player9StatusImageView;
    break;

  case 0xa:
    imageView = playerAStatusImageView;
    break;

  case 0xb:
    imageView = playerBStatusImageView;
    break;

  case 0xc:
    imageView = playerCStatusImageView;
    break;

  case 0xd:
    imageView = playerDStatusImageView;
    break;

  case 0xe:
    imageView = playerEStatusImageView;
    break;

  case 0xf:
    imageView = playerFStatusImageView;
    break;

  default:
    imageView = nil;
    break;
  }

  indexString = [NSString stringWithFormat:@"%d", player];

  if (client.players[player].connected) {
    enumerator = [playerInfoArray objectEnumerator];

    while ((playerRecord = [enumerator nextObject])) {
      if ([playerRecord[@"Index"] isEqualToString:indexString]) {
        break;
      }
    }

    if (playerRecord == nil) {
      playerRecord = [[NSMutableDictionary alloc] init];
      [playerInfoArray addObject:playerRecord];
    }

    playerRecord[@"Index"] = indexString;

    if (client.players[client.player].seq - client.players[player].lastupdate >= 3*TICKSPERSEC) {
      name = [[NSAttributedString alloc] initWithString:@(client.players[player].name) attributes:@{NSForegroundColorAttributeName: [NSColor whiteColor], NSBackgroundColorAttributeName: [NSColor redColor]}];
    }
    else if (client.players[client.player].seq - client.players[player].lastupdate >= TICKSPERSEC) {
      name = [[NSAttributedString alloc] initWithString:@(client.players[player].name) attributes:@{NSBackgroundColorAttributeName: [NSColor yellowColor]}];
    }
    else {
      name = [[NSAttributedString alloc] initWithString:@(client.players[player].name) attributes:@{NSBackgroundColorAttributeName: [NSColor greenColor]}];
    }

    playerRecord[@"Player"] = name;

    if (client.player == player) {
      imageView.image = [NSImage imageNamed:@"PlayerStatFriendly"];
    }
    else if (
      (client.players[client.player].alliance & (1 << player)) &&
      (client.players[player].alliance & (1 << client.player))
    ) {
      imageView.image = [NSImage imageNamed:@"PlayerStatAlliedFriendly"];
    }
    else {
      imageView.image = [NSImage imageNamed:@"PlayerStatHostile"];
    }
  }
  else {
    enumerator = [playerInfoArray objectEnumerator];

    while ((playerRecord = [enumerator nextObject])) {
      if ([playerRecord[@"Index"] isEqualToString:indexString]) {
        [playerInfoArray removeObject:playerRecord];
        break;
      }
    }

    [imageView setImage:nil];
  }

  [playerInfoTableView reloadData];

  if (unlockclient()) LOGFAIL(errno)
  gotlock = 0;

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

- (void)setPillStatus:(NSString *)aString {
  NSImageView *imageView;
  int gotlock = 0;
  int pill;

TRY
  pill = aString.intValue;

  switch (pill) {
  case 0x0:
    imageView = pill0StatusImageView;
    break;

  case 0x1:
    imageView = pill1StatusImageView;
    break;

  case 0x2:
    imageView = pill2StatusImageView;
    break;

  case 0x3:
    imageView = pill3StatusImageView;
    break;

  case 0x4:
    imageView = pill4StatusImageView;
    break;

  case 0x5:
    imageView = pill5StatusImageView;
    break;

  case 0x6:
    imageView = pill6StatusImageView;
    break;

  case 0x7:
    imageView = pill7StatusImageView;
    break;

  case 0x8:
    imageView = pill8StatusImageView;
    break;

  case 0x9:
    imageView = pill9StatusImageView;
    break;

  case 0xa:
    imageView = pillAStatusImageView;
    break;

  case 0xb:
    imageView = pillBStatusImageView;
    break;

  case 0xc:
    imageView = pillCStatusImageView;
    break;

  case 0xd:
    imageView = pillDStatusImageView;
    break;

  case 0xe:
    imageView = pillEStatusImageView;
    break;

  case 0xf:
    imageView = pillFStatusImageView;
    break;

  default:
    imageView = nil;
    break;
  }

  if (lockclient()) LOGFAIL(errno)

  if (pill < client.npills) {
    switch (client.pills[pill].armour) {
    case 0:
      imageView.image = [NSImage imageNamed:@"PillStatDead"];
      break;

    case ONBOARD:
      if (client.pills[pill].owner == client.player) {
        imageView.image = [NSImage imageNamed:@"PillStatIntFriendly"];
      }
      else if (
        client.pills[pill].owner != NEUTRAL &&
        (
          (client.players[client.pills[pill].owner].alliance & (1 << client.player)) &&
          (client.players[client.player].alliance & (1 << client.pills[pill].owner))
        )
      ) {
        imageView.image = [NSImage imageNamed:@"PillStatIntAllied"];
      }
      else {
        imageView.image = [NSImage imageNamed:@"PillStatIntHostile"];
      }

      break;

    default:
      if (client.pills[pill].owner == client.player) {
        imageView.image = [NSImage imageNamed:@"PillStatFriendly"];
      }
      else if (client.pills[pill].owner == NEUTRAL) {
        imageView.image = [NSImage imageNamed:@"PillStatNeutral"];
      }
      else if (
        client.pills[pill].owner != NEUTRAL &&
        (
          (client.players[client.pills[pill].owner].alliance & (1 << client.player)) &&
          (client.players[client.player].alliance & (1 << client.pills[pill].owner))
        )
      ) {
        imageView.image = [NSImage imageNamed:@"PillStatFriendly"];
      }
      else {
        imageView.image = [NSImage imageNamed:@"PillStatHostile"];
      }

      break;
    }
  }
  else {
    [imageView setImage:nil];
  }

  if (unlockclient()) LOGFAIL(errno)

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

- (void)setBaseStatus:(NSString *)aString {
  NSImageView *imageView;
  int gotlock = 0;
  int base;

TRY
  if (lockclient()) LOGFAIL(errno)
  gotlock = 1;

  base = aString.intValue;

  switch (base) {
  case 0x0:
    imageView = base0StatusImageView;
    break;

  case 0x1:
    imageView = base1StatusImageView;
    break;

  case 0x2:
    imageView = base2StatusImageView;
    break;

  case 0x3:
    imageView = base3StatusImageView;
    break;

  case 0x4:
    imageView = base4StatusImageView;
    break;

  case 0x5:
    imageView = base5StatusImageView;
    break;

  case 0x6:
    imageView = base6StatusImageView;
    break;

  case 0x7:
    imageView = base7StatusImageView;
    break;

  case 0x8:
    imageView = base8StatusImageView;
    break;

  case 0x9:
    imageView = base9StatusImageView;
    break;

  case 0xa:
    imageView = baseAStatusImageView;
    break;

  case 0xb:
    imageView = baseBStatusImageView;
    break;

  case 0xc:
    imageView = baseCStatusImageView;
    break;

  case 0xd:
    imageView = baseDStatusImageView;
    break;

  case 0xe:
    imageView = baseEStatusImageView;
    break;

  case 0xf:
    imageView = baseFStatusImageView;
    break;

  default:
    assert(0);
    break;
  }

  if (base < client.nbases) {
    if (client.bases[base].owner == NEUTRAL) {
      imageView.image = [NSImage imageNamed:@"BaseStatNeutral"];
    }
    else if (client.bases[base].armour < MINBASEARMOUR) {
      imageView.image = [NSImage imageNamed:@"BaseStatDead"];
    }
    else if (client.bases[base].owner == client.player) {
      imageView.image = [NSImage imageNamed:@"BaseStatFriendly"];
    }
    else if (
      client.bases[base].owner != NEUTRAL &&
      (
        (client.players[client.bases[base].owner].alliance & (1 << client.player)) &&
        (client.players[client.player].alliance & (1 << client.bases[base].owner))
      )
    ) {
      imageView.image = [NSImage imageNamed:@"BaseStatFriendly"];
    }
    else {
      imageView.image = [NSImage imageNamed:@"BaseStatHostile"];
    }
  }
  else {
    [imageView setImage:nil];
  }

  if (unlockclient()) LOGFAIL(errno)
  gotlock = 0;

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

- (void)setTankStatusBars {
  playerKillsTextField.stringValue = [NSString stringWithFormat:@"%d", client.kills];
  playerDeathsTextField.stringValue = [NSString stringWithFormat:@"%d", client.deaths];
  playerShellsStatusBar.value = ((CGFloat)client.shells)/MAXSHELLS;
  playerMinesStatusBar.value = ((CGFloat)client.mines)/MAXMINES;
  playerArmourStatusBar.value = ((CGFloat)client.armour)/MAXARMOUR;
  playerTreesStatusBar.value = ((CGFloat)client.trees)/MAXTREES;
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
          NSRect rect;
          rect.size.width = rect.size.height = 16 * 16 * kZoomLevels[zoomLevel];
          rect.origin.x = ((client.players[client.player].tank.x + 0.5)*16.0) - rect.size.width*0.5;
          rect.origin.y = ((FWIDTH - (client.players[client.player].tank.y + 0.5))*16.0) - rect.size.height*0.5;

          if (unlockclient()) LOGFAIL(errno)
          gotlock = 0;

          [boloView scrollRectToVisible:rect];  /* potential to call drawRect: which locks client */
        }
        if (unlockclient()) LOGFAIL(errno)
        gotlock = 1;

        client.spawned = 0;
      }
      if(centerTank)
        [self tankCenter:nil];
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
          
            builderStatusView.state = GSBuilderStatusViewStateDirection;
            builderStatusView.direction = newdir;
          }
          
          break;
          
        case kBuilderParachute:
          builderStatusView.state = GSBuilderStatusViewStateDead;
          break;
          
        case kBuilderReady:
          builderStatusView.state = GSBuilderStatusViewStateReady;
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
      
        if (base != -1) {
          baseArmourStatusBar.value = (CGFloat)client.bases[base].armour/(CGFloat)MAX_BASE_ARMOUR;
          baseShellsStatusBar.value = (CGFloat)client.bases[base].shells/(CGFloat)MAX_BASE_SHELLS;
          baseMinesStatusBar.value = (CGFloat)client.bases[base].mines/(CGFloat)MAX_BASE_MINES;
        }
        else {
          baseShellsStatusBar.value = 0.0;
          baseMinesStatusBar.value = 0.0;
          baseArmourStatusBar.value = 0.0;
        }
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

- (void)printMessage:(NSAttributedString *)aString {
  NSAttributedString *newline;

  newline = [[NSAttributedString alloc] initWithString:@"\n"];
  [messagesTextView.textStorage appendAttributedString:newline];
  [messagesTextView.textStorage appendAttributedString:aString];
  [messagesTextView didChangeText];
  [messagesTextView scrollPoint:NSMakePoint(0.0f, NSHeight(messagesTextView.frame) - NSHeight(messagesTextView.visibleRect))];

//  int i;
//  if (!muteBool) {
//    for (i = 0; i < [speechSynthesizers count]; i++) {
//      NSSpeechSynthesizer *speechSynthesizer;
//
//      speechSynthesizer = [speechSynthesizers objectAtIndex:i];
//
//      if (![speechSynthesizer isSpeaking]) {
//        [speechSynthesizer startSpeakingString:[aString string]];
//        break;
//      }
//    }
//  }
	
}


// NSTableView delegate methods

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  NSTableView *table;
  NSInteger i;
  NSDictionary *row;

  table = aNotification.object;

  if (table == playerInfoTableView) {
    if (table.numberOfSelectedRows == 0) {
      [requestAllianceButton setEnabled:FALSE];
      [leaveAllianceButton setEnabled:FALSE];
    }
    else {
      [requestAllianceButton setEnabled:TRUE];
      [leaveAllianceButton setEnabled:TRUE];
    }
  }
  else if (table == joinTrackerTableView) {
    i = table.selectedRowIndexes.firstIndex;

    if (i != NSNotFound) {
      row = joinTrackerArray[i];
      [self setJoinAddress:row[GSHostnameColumn]];
      [self setJoinPort:[row[GSPortColumn] intValue]];
    }
  }
}


// NSTableView dataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  if (aTableView == playerInfoTableView) {
    return playerInfoArray.count;
  }
  else if (aTableView == joinTrackerTableView) {
    return joinTrackerArray.count;
  }
  else {
    return 0;
  }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  if (aTableView == playerInfoTableView) {
    NSParameterAssert(rowIndex >= 0 && rowIndex < [playerInfoArray count]);
    return playerInfoArray[rowIndex][aTableColumn.identifier];
  }
  else if (aTableView == joinTrackerTableView) {
    NSParameterAssert(rowIndex >= 0 && rowIndex < [joinTrackerArray count]);
    if ([aTableColumn.identifier isEqualToString:GSSourceColumn]) {
      NSNumber *servSource = joinTrackerArray[rowIndex][GSSourceColumn];
      if (servSource.integerValue == GSServerSourceTracker) {
        return [NSImage imageNamed:@"XBolo"];
      } else /* GSServerSourceBonjour */{
        return [NSImage imageNamed:NSImageNameBonjour];
      }
    }
    return joinTrackerArray[rowIndex][aTableColumn.identifier];
  }
  else {
    return nil;
  }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  if (aTableView == playerInfoTableView) {
    NSParameterAssert(rowIndex >= 0 && rowIndex < [playerInfoArray count]);
    playerInfoArray[rowIndex][aTableColumn.identifier] = anObject;
  }
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
  if (aTableView == joinTrackerTableView) {  /* sorts joinTrackerArray */
    NSInteger index;
    NSDictionary *selection;

    index = aTableView.selectedRowIndexes.firstIndex;

    if (index != NSNotFound) {
      selection = joinTrackerArray[index];
    }

    [joinTrackerArray sortUsingDescriptors:aTableView.sortDescriptors];
    [aTableView reloadData];

    if (index != NSNotFound) {
      [aTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[joinTrackerArray indexOfObject:selection]] byExtendingSelection:NO];
    }
  }
}

//

- (void)setJoinProgressStatusTextField:(NSString *)aString {
  joinProgressStatusTextField.stringValue = aString;
}

- (void)setJoinProgressIndicator:(NSNumber *)aString {
  [joinProgressIndicator setIndeterminate:NO];
  joinProgressIndicator.doubleValue = aString.doubleValue;
}

- (void)joinSuccess {
  [boloView setNeedsDisplay:YES];
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  [newGameWindow orderOut:self];
  [boloWindow makeKeyAndOrderFront:self];

  if (showStatusBool) {
    [statusPanel orderFront:self];
  }

  if (showAllegianceBool) {
    [allegiancePanel orderFront:self];
  }

  [messagesTextView.textStorage deleteCharactersInRange:NSMakeRange(0, messagesTextView.textStorage.length)];

  if (showMessagesBool) {
    [messagesPanel orderFront:self];
  }
}

- (void)joinDNSError:(NSString *)eString {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Error Resolving Hostname", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"%@", eString);
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)joinTimeOut {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Network Error", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Connection establishment timed out without establishing a connection.");
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)joinConnectionRefused {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Connection Error", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"The attempt to connect was forcefully rejected.");
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)joinNetUnreachable {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Network Error", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"The network is not reachable from this host.");
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)joinHostUnreachable {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Network Error", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"The remote host is not reachable from this host.");
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)joinBadVersion {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Server Error", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Server version doesn't match.");
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)joinDisallow {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Server Error", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Host is not allowing new players in the game.");
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)joinBadPassword {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Server Error", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Password rejected.");
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)joinServerFull {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Server Error", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Server is full.");
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)joinTimeLimit {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Server Error", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Time limit reached on server.");
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)joinBannedPlayer {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Server Error", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Host has banned you from the game.");
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)joinServerError {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Server Error", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Protocol error.");
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)joinConnectionReset {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Server Error", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Connection Reset by Peer.");
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)registerSuccess {
TRY
  if (startclient("localhost", getservertcpport(), playerNameString.UTF8String, hostPasswordBool ? hostPasswordString.UTF8String : NULL)) LOGFAIL(errno)

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)trackerDNSError:(NSString *)eString {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Error Resolving Tracker", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"%@", eString);

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)registerTrackerTimeOut {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Tracker Timed Out", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Could not connect to the tracker.");

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)registerTrackerConnectionRefused {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Tracker Connection Refused", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Connection was refused by the tracker.");

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)registerTrackerHostDown {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Tracker Host Down", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Tracker is not responding.");

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)registerTrackerHostUnreachable {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Tracker Host Unreachable", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Check your network connectivity.");

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)registerTrackerBadVersion {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Incompatible Version", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Tracker version doesn't match.");

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)registerTrackerTCPPortBlocked {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Failed to Verify TCP Port Forwarded", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Try setting up port forwarding in your router.  If you have port forwarding setup in your router, uncheck UPnP and try again.");

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)registerTrackerUDPPortBlocked {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Failed to Verify UDP Port Forwarded", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Try setting up port forwarding in your router.  If you have port forwarding setup in your router, uncheck UPnP and try again.");

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)registerTrackerConnectionReset {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Connection Error", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Connection Reset by Peer.");

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)getListTrackerTimeOut {
  stoptracker();
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Tracker Timed Out", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Could not connect to the tracker.");
}

- (void)getListTrackerConnectionRefused {
  stoptracker();
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Tracker Connection Refused", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Connection was refused by the tracker.");
}

- (void)getListTrackerHostDown {
  stoptracker();
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Tracker Host Down", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Tracker is not responding.");
}

- (void)getListTrackerHostUnreachable {
  stoptracker();
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Tracker Host Unreachable", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Check your network connectivity.");
}

- (void)getListTrackerBadVersion {
  stoptracker();
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];
  NSBeginAlertSheet(@"Incompatible Version", @"OK", nil, nil, newGameWindow, self, nil, nil, nil, @"Tracker version doesn't match.");
}

- (void)getListTrackerSuccess {
  NSMutableArray *table;
  NSArray *keys, *objects;
  struct ListNode *node;

  stoptracker();

  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [NSApp endSheet:joinProgressWindow];

  // convert list to NSArray for displaying
  table = [NSMutableArray array];
  keys = @[GSHostPlayerColumn, GSMapNameColumn, GSPlayersColumn, GSPasswordColumn, GSAllowJoinColumn, GSPausedColumn, GSHostnameColumn, GSPortColumn, GSSourceColumn];
  NSNumber *sourceTracker = @(GSServerSourceTracker);

  for (node = nextlist(&trackerlist); node; node = nextlist(node)) {
    struct TrackerHostList *hostlist;
    hostlist = ptrlist(node);

    objects = @[@((char *)hostlist->game.playername),
      @((char *)hostlist->game.mapname),
      [NSString stringWithFormat:@"%d", hostlist->game.nplayers],
      hostlist->game.passreq ? @"Yes" : @"No",
      hostlist->game.allowjoin ? @"Yes" : @"No",
      hostlist->game.pause ? @"Yes" : @"No",
      @(inet_ntoa(hostlist->addr)),
      [NSString stringWithFormat:@"%d", hostlist->game.port],
      sourceTracker];
    [table addObject:[NSDictionary dictionaryWithObjects:objects forKeys:keys]];
  }

  // free list
  clearlist(&trackerlist, free);

  // update table
  [self setJoinTrackerArray:table];
}

// robots!

- (BOOL)_validateRobotMenuItem: (NSMenuItem *)item
{
    [robotLock lock];
    item.state = item.representedObject == robot ? NSOnState : NSOffState;
    [robotLock unlock];
    return YES;
}

- (void)choseRobotMenuItem: (id)sender
{
    GSRobot *newRobot = [sender representedObject];
    [robotLock lock];
    if(newRobot != robot)
    {
        NSError *err = [newRobot load];
        if(err)
        {
            [NSApp presentError: err];
        }
        else
        {
            [robot unload];
            robot = newRobot;
        }
    }
    [robotLock unlock];
}

- (void)setupRobotsMenu
{
    NSArray<GSRobot*> *robots = [GSRobot availableRobots];
    
    NSMenuItem *autoMenu = nil;
    NSString *autoName = [[NSUserDefaults standardUserDefaults] stringForKey: @"GSAutomaticallyLoadRobot"];
    
    if(robots.count)
    {
        NSMenu *menu = [[NSMenu alloc] initWithTitle: @"Robots"];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: @"Manual Control" action: @selector(choseRobotMenuItem:) keyEquivalent: @""];
        [menu addItem: item];
        
        [menu addItem: [NSMenuItem separatorItem]];
        
        for(GSRobot *r in robots)
        {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: r.name action: @selector(choseRobotMenuItem:) keyEquivalent: @""];
            item.representedObject = r;
            [menu addItem: item];
            if(autoName && [r.name hasPrefix: autoName])
                autoMenu = item;
        }
        
        NSMenuItem *robotItem = [[NSMenuItem alloc] initWithTitle: @"Robots" action: NULL keyEquivalent: @""];
        robotItem.submenu = menu;
        [NSApp.mainMenu addItem: robotItem];
    }
    
    if(autoMenu)
        [self choseRobotMenuItem: autoMenu];
}

- (void)clientLoopUpdate
{
    @autoreleasepool {
        [robotLock lock];
        [robot step];
        [robotLock unlock];
    }
}

- (void)sendMessageToRobot: (NSString *)string
{
    [robotLock lock];
    NSString *myPrefix = [NSString stringWithFormat: @"%s:", client.name];
    if(![string hasPrefix: myPrefix])
      [robot receivedMessage: string];
    [robotLock unlock];
}    

- (void)requestConnectionToServer:(NSString*)servStr port:(unsigned short)port password:(NSString *)pass
{
  self.joinPort = port;
  self.joinAddress = servStr;
  if (pass) {
    self.joinPasswordEnabled = YES;
    self.joinPassword = pass;
  } else {
    self.joinPasswordEnabled = NO;
  }
}

@synthesize broadcastBonjour = _broadcastBonjour;

- (void)setBroadcastBonjour:(BOOL)broadcastBonjour
{
  _broadcastBonjour = broadcastBonjour;
  if (broadcaster && !_broadcastBonjour) {
    [self stopPublishing];
  } else if (server.running && _broadcastBonjour) {
    [self startPublishing];
  }
}

- (IBAction)hostToggleBonjourBroadcast:(nullable id)sender
{
  self.broadcastBonjour = !_broadcastBonjour;
}

- (IBAction)joinToggleBonjourListen:(nullable NSButton*)sender
{
  if (listener) {
    [self stopListening];
    sender.state = NSOffState;
  } else {
    [self startListening];
    sender.state = NSOnState;
  }
}

@end

@implementation GSXBoloController (NetService)

- (void)startPublishing {
  NSString *bonjourName = [NSString stringWithFormat:@"%@ (%@)", [NSHost currentHost].localizedName, playerNameString];
  broadcaster = [[NSNetService alloc] initWithDomain:@"" type:XBoloBonjourType name:bonjourName port:hostPortNumber];
  broadcaster.delegate = self;
  [self updatePublishedInfo];
  [broadcaster publish];
}

- (void)updatePublishedInfo {
  if (broadcaster) {
    lockserver();
    NSMutableDictionary<NSString *, NSData *> *ourTxtDict = [[NSMutableDictionary alloc] initWithCapacity:6];
    ourTxtDict[XBoloBonjourPlayerName] = [playerNameString dataUsingEncoding:NSUTF8StringEncoding];
    ourTxtDict[XBoloBonjourMapName] = [hostMapString.lastPathComponent.stringByDeletingPathExtension dataUsingEncoding:NSUTF8StringEncoding];
    ourTxtDict[XBoloBonjourReqiresPassword] = hostPasswordBool ? [@"1" dataUsingEncoding:NSASCIIStringEncoding] : [@"0" dataUsingEncoding:NSASCIIStringEncoding];
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

- (void)startListening {
  listener = [[NSNetServiceBrowser alloc] init];
  listener.delegate = self;
  [listener searchForServicesOfType:XBoloBonjourType inDomain:@""];
}

- (void)stopListening {
  [listener stop];
  listener = nil;
  [self clearBonjourEntries];
}

- (void)clearBonjourEntries {
  NSMutableIndexSet *mutSet = [NSMutableIndexSet indexSet];
  for (NSInteger i = 0; i < joinTrackerArray.count; i++) {
    if ([joinTrackerArray[i][GSSourceColumn] isEqual:@(GSServerSourceBonjour)]) {
      [mutSet addIndex:i];
    }
  }
  [joinTrackerArray removeObjectsAtIndexes:mutSet];
  [self setJoinTrackerArray:joinTrackerArray];
}

#define GSNetServiceKey @"NetService"

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
  [service resolveWithTimeout:5];

  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    //usleep(500);
    sleep(1);

    NSString *playerName = @"unknown";
    NSString *mapName = @"unknown";
    NSString *passReq = @"?";
    NSString *paused = @"?";
    NSString *canJoin = @"?";
    NSString *playerCount = @"?";
    NSData *txtData = [service TXTRecordData];
    if (txtData) {
      NSDictionary *txtDict = [NSNetService dictionaryFromTXTRecordData: txtData];
      id val;
      val = txtDict[XBoloBonjourPlayerName];
      if (val) {
        playerName = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
      }
      val = txtDict[XBoloBonjourMapName];
      if (val) {
        mapName = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
      }
      val = txtDict[XBoloBonjourReqiresPassword];
      if (val) {
        NSString *passBool = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
        if ([passBool isEqualToString:@"0"]) {
          passReq = @"No";
        } else {
          passReq = @"Yes";
        }
      }
      val = txtDict[XBoloBonjourIsPaused];
      if (val) {
        NSString *passBool = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
        if ([passBool isEqualToString:@"0"]) {
          paused = @"No";
        } else {
          paused = @"Yes";
        }
      }
      val = txtDict[XBoloBonjourCanJoin];
      if (val) {
        NSString *passBool = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
        if ([passBool isEqualToString:@"0"]) {
          canJoin = @"No";
        } else {
          canJoin = @"Yes";
        }
      }
      val = txtDict[XBoloBonjourPlayerCount];
      if (val) {
        playerCount = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
      }
    }
    
    if (!service.hostName) {
      NSLog(@"Did not get host name from \"%@\"!", service);
      return;
    }
    
    NSDictionary *toSet =
    @{GSHostPlayerColumn: playerName,
      GSMapNameColumn: mapName,
      GSPlayersColumn: playerCount,
      GSPasswordColumn: passReq,
      GSAllowJoinColumn: canJoin,
      GSPausedColumn: paused,
      GSHostnameColumn: service.hostName,
      GSPortColumn: [NSString stringWithFormat:@"%ld", (long)service.port],
      GSSourceColumn: @(GSServerSourceBonjour),
      GSNetServiceKey: service};
    
    dispatch_async(dispatch_get_main_queue(), ^{
      NSMutableArray *newTrackArr = self->joinTrackerArray;
      if (!newTrackArr) {
        newTrackArr = [[NSMutableArray alloc] initWithCapacity: moreComing ? 2 : 1];
      }
      [newTrackArr addObject:toSet];
      [self setJoinTrackerArray:newTrackArr];
      service.delegate = self;
    });
  });
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data
{
  if (sender == broadcaster) {
    //We should have been the one to change this...
    return;
  }
  NSDictionary *txtDict = [NSNetService dictionaryFromTXTRecordData: data];
  NSDictionary *toUpdate;
  for (NSDictionary *theDict in joinTrackerArray) {
    if ([theDict[GSNetServiceKey] isEqual:sender]) {
      toUpdate = theDict;
      break;
    }
  }
  NSAssert(toUpdate != nil, @"Uh, oops");
  NSMutableDictionary *mutUpdate = [toUpdate copy];
  NSInteger idx = [joinTrackerArray indexOfObject:toUpdate];
  
  NSData *val;
  val = txtDict[XBoloBonjourPlayerName];
  if (val) {
    mutUpdate[GSHostPlayerColumn] = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
  }
  val = txtDict[XBoloBonjourMapName];
  if (val) {
    mutUpdate[GSMapNameColumn] = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
  }
  val = txtDict[XBoloBonjourReqiresPassword];
  if (val) {
    NSString *passBool = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
    if ([passBool isEqualToString:@"0"]) {
      mutUpdate[GSPasswordColumn] = @"No";
    } else {
      mutUpdate[GSPasswordColumn] = @"Yes";
    }
  }
  val = txtDict[XBoloBonjourIsPaused];
  if (val) {
    NSString *passBool = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
    if ([passBool isEqualToString:@"0"]) {
      mutUpdate[GSPausedColumn] = @"No";
    } else {
      mutUpdate[GSPausedColumn] = @"Yes";
    }
  }
  val = txtDict[XBoloBonjourCanJoin];
  if (val) {
    NSString *passBool = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
    if ([passBool isEqualToString:@"0"]) {
      mutUpdate[GSAllowJoinColumn] = @"No";
    } else {
      mutUpdate[GSAllowJoinColumn] = @"Yes";
    }
  }
  val = txtDict[XBoloBonjourPlayerCount];
  if (val) {
    mutUpdate[GSPlayersColumn] = [[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding];
  }

  [joinTrackerArray replaceObjectAtIndex:idx withObject:[mutUpdate copy]];
  [self setJoinTrackerArray:joinTrackerArray];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing
{
  NSDictionary *toRemove;
  for (NSDictionary *theDict in joinTrackerArray) {
    if ([theDict[GSNetServiceKey] isEqual:service]) {
      toRemove = theDict;
      break;
    }
  }
  
  [joinTrackerArray removeObject:toRemove];
  [self setJoinTrackerArray:joinTrackerArray];
}

@end

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
    NSArray *array;

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
      attr = @{NSForegroundColorAttributeName: [NSColor purpleColor]};
      break;

    case MSGNEARBY:
      attr = @{NSForegroundColorAttributeName: [NSColor redColor]};
      break;

    case MSGGAME:
      attr = @{NSForegroundColorAttributeName: [NSColor blueColor]};
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

int setKey(NSMutableDictionary<NSString*,NSString*> *dict, NSWindow *win, GSKeyCodeField *field, NSString *newObject) {
  NSString *key;
  id object;
  key = field.stringValue;
  object = dict[key];

  if (object != nil) {
    [[NSAlert alertWithMessageText:@"There is a key conflict." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There is a conflict with %@ and %@.  Change one of them.", object, newObject] beginSheetModalForWindow:win modalDelegate:nil didEndSelector:nil contextInfo:NULL];
    return -1;
  }
  else {
    dict[key] = newObject;
    return 0;
  }
}

void clientloopupdate(void)
{
  [controller clientLoopUpdate];
}
