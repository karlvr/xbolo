//
//  GSStatusBar.h
//  XBolo
//
//  Created by Robert Chrzanowski on 11/12/04.
//  Copyright 2004 Robert Chrzanowski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, GSStatusBarType) {
  GSHorizontalBar,
  GSVerticalBar,
};

@interface GSStatusBar : NSView
@property (nonatomic) GSStatusBarType type;
@property (nonatomic) CGFloat value;
@end
