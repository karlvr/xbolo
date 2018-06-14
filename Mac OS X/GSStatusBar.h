//
//  GSStatusBar.h
//  XBolo
//
//  Created by Robert Chrzanowski on 11/12/04.
//  Copyright 2004 Robert Chrzanowski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, GSStatusBarType) {
  GSStatusBarHorizontal,
  GSStatusBarVertical,
};

@interface GSStatusBar : NSView
@property (nonatomic) GSStatusBarType type;
@property (nonatomic) CGFloat value;
@end

static const GSStatusBarType GSHorizontalBar NS_DEPRECATED_WITH_REPLACEMENT_MAC("GSStatusBarHorizontal", 10.0, 10.9) = GSStatusBarHorizontal;
static const GSStatusBarType GSVerticalBar NS_DEPRECATED_WITH_REPLACEMENT_MAC("GSStatusBarVertical", 10.0, 10.9) = GSStatusBarVertical;
