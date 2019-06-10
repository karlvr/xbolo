//
//  XBoloViewController.h
//  XBolo
//
//  Created by Robert Chrzanowski on 6/28/09.
//  Copyright Robert Chrzanowski 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XBoloViewController : UIViewController {

}

@end

// bolo callbacksinitclient
void setplayerstatus(int player);
void setpillstatus(int pill);
void setbasestatus(int base);
void settankstatus(void);
void playsound(int sound);
void printmessage(int type, const char *text);
void joinprogress(int statuscode, float progress);
void trackerprogress(int statuscode);
void clientloopupdate(void);

NS_ASSUME_NONNULL_END
