//
//  DisplayManager.h
//  AcidDemo
//
//  Created by Yevhen Khyzhniak on 18.11.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

#import <Foundation/Foundation.h>

#define keyNotifDisplayOn @"keyNotifDisplayOn"
#define keyNotifDisplayOff @"keyNotifDisplayOff"

NS_ASSUME_NONNULL_BEGIN

/// Observes the screen on/off Darwin notification and re-posts it on
/// `NSNotificationCenter` (always on the main queue).
///
/// WARNING: `com.apple.iokit.hid.displayStatus` is an undocumented Darwin
/// notification. It works, but it is not public API — apps using it may be
/// rejected during App Store review. It is kept here only to demonstrate the
/// "unlock on screen wake" flow.
@interface DisplayManager : NSObject

/// Registers the observer. Safe to call repeatedly — only the first call registers.
+ (void)methodStart;

/// Cancels the observer registration, if any.
+ (void)methodStop;

@end

NS_ASSUME_NONNULL_END
