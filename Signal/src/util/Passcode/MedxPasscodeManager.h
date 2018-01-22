//
//  MedxPasscodeManager.h
//  Medxnote
//
//  Created by Upul Abayagunawardhana on 3/7/16.
//  Copyright © 2016 Open Whisper Systems. All rights reserved.
//

#import "ActivityWindow.h"
#import "PasscodeHelper.h"
#import <Foundation/Foundation.h>

@interface MedxPasscodeManager : NSObject

+ (BOOL)isLockoutEnabled;
+ (void)setLockoutEnabled;
+ (BOOL)isPasscodeEnabled;
+ (NSString *)passcode;
+ (void)storePasscode:(NSString *)passcode;
+ (NSNumber *)inactivityTimeout;
+ (NSNumber *)inactivityTimeoutInMinutes;
+ (void)storeInactivityTimeout:(NSNumber *)timeout;
+ (NSDate *)lastActivityTime;
+ (void)storeLastActivityTime:(NSDate *)date;

@end
