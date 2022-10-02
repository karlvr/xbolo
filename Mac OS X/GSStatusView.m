//
//  GSStatusView.m
//  XBolo
//
//  Created by Robert Chrzanowski on 11/12/04.
//  Copyright 2004 Robert Chrzanowski. All rights reserved.
//

#import "GSStatusView.h"


@implementation GSStatusView

- (instancetype)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
  }
  return self;
}

- (void)drawRect:(NSRect)rect {
  [[NSImage  imageNamed:@"StatusBackground"] drawInRect:rect fromRect:rect operation:NSCompositingOperationCopy fraction:1.0f];
}

@end
