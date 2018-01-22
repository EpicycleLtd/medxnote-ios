//
//  BaseWindow.m
//  Medxnote
//
//  Created by Jan Nemecek on 1/11/17.
//  Copyright © 2017 Open Whisper Systems. All rights reserved.
//

#import "ActivityWindow.h"
#import "MedxPasscodeManager.h"

@interface ActivityWindow ()

@property NSTimer *activityTimer;

@end

@implementation ActivityWindow

- (void)sendEvent:(UIEvent *)event {
    if (event.type == UIEventTypeTouches) {
        for (UITouch *touch in event.allTouches) {
            if (touch.phase == UITouchPhaseEnded) {
                [self startTimer];
            } else if (touch.phase == UITouchPhaseBegan) {
                [self resetTimer];
            }
        }
    }
    [super sendEvent:event];
}

- (void)startTimer {
    if (![MedxPasscodeManager isPasscodeEnabled]) { return; }
    NSNumber *timeout = [MedxPasscodeManager inactivityTimeout];
    self.activityTimer = [NSTimer scheduledTimerWithTimeInterval:timeout.integerValue repeats:false block:^(NSTimer * _Nonnull timer) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ActivityTimeoutExceeded" object:nil];
    }];
}

- (void)resetTimer {
    [self.activityTimer invalidate];
}

- (void)restartTimer {
    [self resetTimer];
    [self startTimer];
}

@end
