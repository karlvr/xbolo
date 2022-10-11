//
//  PreviewProvider.h
//  newQLGenerator
//
//  Created by C.W. Betts on 10/6/22.
//  Copyright © 2022 Robert Chrzanowski. All rights reserved.
//

#import <Foundation/Foundation.h>
#if __MAC_OS_X_VERSION_MIN_REQUIRED
#import <Quartz/Quartz.h>
#else
#import <QuickLook/QuickLook.h>
#endif

@interface PreviewProvider : QLPreviewProvider <QLPreviewingController>

@end
