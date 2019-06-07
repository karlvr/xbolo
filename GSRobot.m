//
//  GSRobot.m
//  XBolo
//
//  Created by Michael Ash on 9/7/09.
//

#import "GSRobot.h"

#import "bolo.h"
#import "client.h"

#define INTERNAL_GSROBOT_INCLUDE 1 // what a horrible hack
#import <BoloKit/GSRobotExternal.h>
#undef INTERNAL_GSROBOT_INCLUDE


#define ENABLE_LOGGING 0

#if ENABLE_LOGGING
#define LOG(...) NSLog(__VA_ARGS__)
#else
#define LOG(...) (void)0
#endif

@interface GSRobot ()

- (instancetype)initWithBundle: (NSBundle *)bundle;

@end

@implementation GSRobot

#define NO_NEW_DATA 0
#define NEW_DATA 1
#define THREAD_EXITED 2

+ (NSArray<NSURL*>*) searchURLs
{
    static NSArray<NSURL*> *savedURLs = nil;
    if (savedURLs == nil) {
        @autoreleasepool {
            NSFileManager *fm = [NSFileManager defaultManager];
            NSMutableArray<NSURL*> *tmpURLs = [[NSMutableArray alloc] initWithCapacity:5];
            NSURL *tmpURL = [NSBundle mainBundle].builtInPlugInsURL;
            if (tmpURL && [tmpURL checkResourceIsReachableAndReturnError:NULL]) {
                [tmpURLs addObject:tmpURL];
            }
            tmpURL = [[NSBundle mainBundle].bundleURL URLByDeletingLastPathComponent];
            tmpURL = [tmpURL URLByAppendingPathComponent:@"Robots" isDirectory:YES];
            if (tmpURL && [tmpURL checkResourceIsReachableAndReturnError:NULL]) {
                [tmpURLs addObject:tmpURL];
            }
            NSArray *libURLs = [fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSAllDomainsMask & ~NSSystemDomainMask];
            for (NSURL *url in libURLs) {
                tmpURL = [url URLByAppendingPathComponent:@"XBolo"];
                tmpURL = [tmpURL URLByAppendingPathComponent:@"Robots" isDirectory:YES];
                if (tmpURL && [tmpURL checkResourceIsReachableAndReturnError:NULL]) {
                    [tmpURLs addObject:tmpURL];
                }
            }
            
            savedURLs = [tmpURLs copy];
            [tmpURLs release];
        }
    }
    return [[savedURLs retain] autorelease];
}

+ (NSArray *)availableRobots
{
    static NSMutableArray *robots = nil;
    if(!robots)
    {
        robots = [NSMutableArray array];
        
        NSString *myPath = [NSBundle mainBundle].bundlePath;
        NSString *enclosingPath = myPath.stringByDeletingLastPathComponent;
        NSString *botsPath = [enclosingPath stringByAppendingPathComponent: @"Robots"];

        [self _loadRobotsFromPath:botsPath into:robots];

        NSArray<NSString *> *applicationSupportPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSAllDomainsMask, YES);
        for (NSString *applicationSupportPath in applicationSupportPaths) {
            [self _loadRobotsFromPath:[[applicationSupportPath stringByAppendingPathComponent:@"XBolo"] stringByAppendingPathComponent:@"Robots"]
                                 into:robots];
        }
    }
    return robots;
}

+ (void)_loadRobotsFromPath:(NSString *)botsPath into:(NSMutableArray *)robots {
    NSEnumerator<NSURL*> *enumerator = [[[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:botsPath] includingPropertiesForKeys:nil options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles) error:NULL] objectEnumerator];
    LOG(@"availableRobots: myPath:%@ enclosingPath:%@ botsPath:%@ enumerator:%@", myPath, enclosingPath, botsPath, enumerator);

    for (NSURL *fullURL in enumerator)
    {
        LOG(@"availableRobots: checking file %@", fullURL);
        if([fullURL.pathExtension compare: @"xbolorobot"] == NSOrderedSame)
        {
            NSBundle *bundle = [NSBundle bundleWithURL:fullURL];
            LOG(@"availableRobots: bundle:%@", bundle);
            if([bundle load])
            {
                [robots addObject: [[[self alloc] initWithBundle: bundle] autorelease]];
                LOG(@"availableRobots: load succeeded");
            }
        }
    }
}

- (instancetype)initWithBundle: (NSBundle *)bundle
{
    if((self = [self init])) {
        _bundle = [bundle retain];
        _condLock = [[NSConditionLock alloc] initWithCondition: NO_NEW_DATA];
        _messages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self unload];
    [_bundle release];
    [_messages release];
    [_condLock release];
    
    [super dealloc];
}

- (NSString *)name
{
    return [_bundle.bundlePath.lastPathComponent stringByDeletingPathExtension];
}

- (BOOL)loadWithError:(NSError**)error
{
    NSError *err = [self load];
    if (err) {
        if (error) {
            *error = err;
        }
        return NO;
    }
    return YES;
}

- (NSError *)load
{
    Class class = _bundle.principalClass;
    if([class minimumRobotInterfaceVersionRequired] > GS_ROBOT_CURRENT_INTERFACE_VERSION)
    {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"The robot could not be loaded because it requires a newer version of XBolo.",
                                  NSLocalizedRecoverySuggestionErrorKey: @"Check to see if a newer version of XBolo is available, and try again."};
        return [NSError errorWithDomain: NSPOSIXErrorDomain code: EINVAL userInfo: userInfo];
    }
    
    _robot = [[class alloc] init];
    _halt = NO;
    [NSThread detachNewThreadSelector: @selector(_watcherThread) toTarget: self withObject: nil];
    return nil; // no errors, never any error, hooray!
}

- (void)unload
{
    [_condLock lock];
    _halt = YES;
    [_condLock unlockWithCondition: NEW_DATA];
    [_condLock lockWhenCondition: THREAD_EXITED];
    [_condLock unlock];
    
    [_robot release];
    _robot = nil;
}

- (void)step
{
    NSParameterAssert(_robot);
    
    GSRobotGameState *gameState = [[GSRobotGameState new] autorelease];
    gameState.worldwidth = WIDTH;
    gameState.worldheight = WIDTH;
    
    gameState.tankposition = client.players[client.player].tank;
    float gunAngle = client.players[client.player].dir;
    float gunDeltaX = cos(gunAngle) * client.range;
    float gunDeltaY = -sin(gunAngle) * client.range;
    gameState.gunsightposition = __make2f(gameState.tankposition.x + gunDeltaX, gameState.tankposition.y + gunDeltaY);
    
    gameState.tankdirection = gunAngle * 8 / M_PI - 0.5;
    if(gameState.tankdirection < 0) gameState.tankdirection += 16;
    gameState.tankarmor = client.armour;
    gameState.tankshells = client.shells;
    gameState.tankmines = client.mines;
    gameState.tanktrees = client.trees;
    gameState.tankhasboat = client.players[client.player].boat ? 1 : 0;
    
    gameState.tankpillcount = 0;
    int i;
    for(i = 0; i < client.npills; i++)
        if(client.pills[i].owner == client.player && client.pills[i].armour == ONBOARD)
            gameState.tankpillcount++;
    
    switch(client.players[client.player].builderstatus)
    {
        case kBuilderReady:
            gameState.builderstate = 1;
            break;
        case kBuilderParachute:
            gameState.builderstate = 0;
            break;
        default:
        {
            gameState.builderstate = 2;
            Vec2f builderDelta = sub2f(gameState.tankposition, client.players[client.player].builder);
            gameState.builderdirection = _atan2f(builderDelta);
            break;
        }
    }
    
    struct Tank tanks[MAX_PLAYERS];
    int readi, writei;
    for(readi = 0, writei = 0; readi < MAX_PLAYERS; readi++)
    {
        if(readi != client.player) // don't include self
        {
            if(client.players[readi].connected && !client.players[readi].dead)
            {
                if(calcvis(client.players[readi].tank) > 0.1)
                {
                    tanks[writei].friendly = (client.players[readi].alliance & (1 << client.player)
                                              ? YES : NO);
                    tanks[writei].position = client.players[readi].tank;
                    tanks[writei].direction = client.players[readi].dir * 8 / M_PI - 0.5;
                    writei++;
                }
            }
        }
    }
    gameState.tankscount = writei;
    
    // FIXME: should make this be variable
    const int maxShellPositions = 256;
    struct ExternalShell shells[maxShellPositions];
    for(readi = 0, writei = 0; readi < MAX_PLAYERS; readi++)
    {
        if(client.players[readi].connected)
        {
            struct ListNode *node;
            for(node = nextlist(&client.players[readi].shells); node != NULL; node = nextlist(node))
            {
                struct Shell *shell = ptrlist(node);
                if(fogvis(shell->point) > 0.1)
                    if(writei < maxShellPositions)
                    {
                        shells[writei].direction = shell->dir;
                        shells[writei].position = shell->point;
                        writei++;
                    }
            }
        }
    }
    gameState.shellscount = writei;
    
    struct Builder builders[MAX_PLAYERS];
    for(readi = 0, writei = 0; readi < MAX_PLAYERS; readi++)
    {
        if(client.players[readi].connected)
        {
            int status = client.players[readi].builderstatus;
            if(status != kBuilderReady)
                if(fogvis(client.players[readi].builder) > 0.1)
                {
                    builders[writei].isParachute = status == kBuilderParachute;
                    builders[writei].position = client.players[readi].builder;
                    writei++;
                }
        }
    }
    
    gameState.builderscount = writei;
    
    int totalLength = (WIDTH * WIDTH * sizeof(*gameState.visibletiles) +
                       gameState.tankscount * sizeof(*gameState.tanks) +
                       gameState.shellscount * sizeof(*gameState.shells) +
                       gameState.builderscount * sizeof(*gameState.builders));
    
    NSMutableData *data = [NSMutableData dataWithLength: totalLength];
    void *ptr = data.mutableBytes;
    
    memcpy(ptr, client.seentiles, WIDTH * WIDTH * sizeof(*gameState.visibletiles));
    gameState.visibletiles = ptr;
    ptr += WIDTH * WIDTH * sizeof(*gameState.visibletiles);
    
    int size;
    
    size = gameState.tankscount * sizeof(*gameState.tanks);
    memcpy(ptr, tanks, size);
    gameState.tanks = ptr;
    ptr += size;
    
    size = gameState.shellscount * sizeof(*gameState.shells);
    memcpy(ptr, shells, size);
    gameState.shells = ptr;
    ptr += size;
    
    size = gameState.builderscount * sizeof(*gameState.builders);
    memcpy(ptr, builders, size);
    gameState.builders = ptr;
    ptr += size;
    gameState.gamestateData = data;
    
    [_condLock lock];
    if(_condLock.condition == THREAD_EXITED)
    {
        [_condLock unlock];
    }
    else
    {
        [_gamestate release];
        _gamestate = [gameState retain];
        [_condLock unlockWithCondition: NEW_DATA];
    }
}

- (void)receivedMessage: (NSString *)message
{
    [_messages addObject: message];
}

- (void)_watcherThread
{
    while(1)
    @autoreleasepool {
        [_condLock lockWhenCondition: NEW_DATA];
        if(_halt)
        {
            [_condLock unlockWithCondition: THREAD_EXITED];
            return;
        }
        
        GSRobotGameState *gsdata = [_gamestate retain];
        NSArray *messages = [_messages copy];
        [_messages removeAllObjects];
        gsdata.messages = messages;
        [_condLock unlockWithCondition: NO_NEW_DATA];
        
        NSArray *objectsToDestroy = [[NSArray alloc] initWithObjects: gsdata, messages, nil];
        
        GSRobotCommandState *commandState = [_robot stepXBoloRobotWithGameState: gsdata freeFunction: (void *)CFRelease freeContext: objectsToDestroy];
        
        [gsdata release];
        [messages release];
        
        int keys = 0;
        if(commandState.accelerate) keys |= ACCELMASK;
        if(commandState.decelerate) keys |= BRAKEMASK;
        if(commandState.left)       keys |= TURNLMASK;
        if(commandState.right)      keys |= TURNRMASK;
        if(commandState.gunup)      keys |= INCREMASK;
        if(commandState.gundown)    keys |= DECREMASK;
        if(commandState.mine)       keys |= LMINEMASK;
        if(commandState.fire)       keys |= SHOOTMASK;
        
        keyevent(keys, 1);
        keyevent(~keys, 0);
        
        if(commandState.buildercommand != BUILDERNILL)
        {
            GSPoint p = { commandState.builderx, commandState.buildery };
            buildercommand(commandState.buildercommand, p);
        }
        
        if((commandState.playersToAllyWith).count)
        {
            lockclient();
            uint16_t players = 0;
            int i;
            for(NSString *name in commandState.playersToAllyWith)
            {
                const char *cname = name.UTF8String;
                for(i = 0; i < MAX_PLAYERS; i++)
                {
                    if(client.players[i].connected)
                        if(strncmp(client.players[i].name, cname, MAXNAME) == 0)
                            players |= 1 << i;
                }
            }
            if(players)
                requestalliance(players);
            unlockclient();
        }
    }
}

@end
