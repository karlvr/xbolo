//
//  main.m
//  Untitled
//
//  Created by Robert Chrzanowski on 6/28/09.
//  Copyright Robert Chrzanowski 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "XBoloViewController.h"

#include "bolo.h"
#include "server.h"
#include "client.h"
#include "errchk.h"

int main(int argc, char *argv[]) {
  @autoreleasepool {
TRY
    if (initbolo(setplayerstatus, setpillstatus, setbasestatus, settankstatus, playsound, printmessage, joinprogress, clientloopupdate)) LOGFAIL(errno)

    return UIApplicationMain(argc, argv, nil, nil);
CLEANUP
    PCRIT(ERROR);
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
END
  }
}
