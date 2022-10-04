#import <Cocoa/Cocoa.h>
#include "list.h"

#import "GSBoloViewProtocol.h"

@class NSImage;

@class GSXBoloController;

@interface GSBoloDrawRectView : NSView <GSBoloViewProtocol> {
  struct ListNode rectlist;

  IBOutlet GSXBoloController *boloController;
  NSEventModifierFlags modifiers;
}

@end
