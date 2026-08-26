//
//  DisplayManager.m
//  AcidDemo
//
//  Created by Yevhen Khyzhniak on 18.11.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

#import "DisplayManager.h"
#import <notify.h>

static int kDisplayStatusToken = NOTIFY_TOKEN_INVALID;

@implementation DisplayManager

#pragma mark - Methods (Public)

+ (void)methodStart
{
    @synchronized (self) {
        if (kDisplayStatusToken != NOTIFY_TOKEN_INVALID) {
            return;
        }

        uint32_t status = notify_register_dispatch(
            "com.apple.iokit.hid.displayStatus",
            &kDisplayStatusToken,
            dispatch_get_global_queue(QOS_CLASS_UTILITY, 0),
            ^(int token)
        {
            uint64_t state = UINT64_MAX;
            notify_get_state(token, &state);
            NSString *name = (state == 1) ? keyNotifDisplayOn : keyNotifDisplayOff;

            // The Darwin callback runs on a global queue. Re-post on the main
            // queue so observers can safely touch UIKit and shared state.
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil];
            });
        });

        if (status != NOTIFY_STATUS_OK) {
            kDisplayStatusToken = NOTIFY_TOKEN_INVALID;
        }
    }
}

+ (void)methodStop
{
    @synchronized (self) {
        if (kDisplayStatusToken == NOTIFY_TOKEN_INVALID) {
            return;
        }
        notify_cancel(kDisplayStatusToken);
        kDisplayStatusToken = NOTIFY_TOKEN_INVALID;
    }
}

@end
