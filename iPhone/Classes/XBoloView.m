//
//  XBoloView.m
//  XBolo
//
//  Created by Robert Chrzanowski on 6/28/09.
//  Copyright 2009 Robert Chrzanowski. All rights reserved.
//

#import "XBoloView.h"


@implementation XBoloView

- (void)drawRect:(CGRect)rect {
  UIImage *image;
  [super drawRect:rect];
  [[UIColor blueColor] set];
  image = [UIImage imageNamed:@"BaseStatDead"];
  [image drawAtPoint:CGPointMake(0.0, 0.0)];
}

@end
