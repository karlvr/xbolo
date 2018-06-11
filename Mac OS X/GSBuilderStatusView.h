//
//  GSBuilderStatusView.h
//  XBolo
//
//  Created by Robert Chrzanowski on 11/12/04.
//  Copyright 2004 Robert Chrzanowski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(int, GSBuilderStatusViewState) {
  GSBuilderStatusViewStateReady,
  GSBuilderStatusViewStateDirection,
  GSBuilderStatusViewStateDead,
};

@interface GSBuilderStatusView : NSView
@property (nonatomic) GSBuilderStatusViewState state;
@property (nonatomic) CGFloat direction;

@end
