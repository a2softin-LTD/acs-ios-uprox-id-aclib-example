//
//  DisplayManager.m
//  AcidDemo
//
//  Created by Yevhen Khyzhniak on 18.11.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

#import "DisplayManager.h"
#import <notify.h>

@interface DisplayManager ()

@end


@implementation DisplayManager

#pragma mark - Class Methods (Public)

#pragma mark - Class Methods (Private)

#pragma mark - Init & Dealloc

#pragma mark - Setters (Public)

#pragma mark - Getters (Public)

#pragma mark - Setters (Private)

#pragma mark - Getters (Private)

#pragma mark - Lifecycle

#pragma mark - Create Views & Variables

#pragma mark - Actions

#pragma mark - Notifications

#pragma mark - Gestures

#pragma mark - Delegates ()

#pragma mark - Methods (Public)

+ (void)methodStart
{
    int notify_token;
    notify_register_dispatch("com.apple.iokit.hid.displayStatus", &notify_token, dispatch_get_global_queue(0, 0), ^(int token)
    {
        uint64_t state = UINT64_MAX;
        notify_get_state(token, &state);
        if (state == 1)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:keyNotifDisplayOn object:nil];
        }
        else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:keyNotifDisplayOff object:nil];
        }
    });
}

#pragma mark - Methods (Private)

#pragma mark - Standard Methods

@end

