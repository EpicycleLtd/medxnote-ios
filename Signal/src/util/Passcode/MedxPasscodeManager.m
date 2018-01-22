//
//  MedxPasscodeManager.m
//  Signal
//
//  Created by Upul Abayagunawardhana on 3/7/16.
//  Copyright © 2016 Open Whisper Systems. All rights reserved.
//

#import "MedxPasscodeManager.h"
#import "TSStorageManager.h"

NSString *const Medxnote_LockoutEnabled = @"MedxLockoutFlag";
NSString *const Medxnote_Passcode = @"MedxStoragePasscodeKey";
NSString *const Medxnote_PasscodeTimeout = @"MedxStorageTimeoutKey";
NSString *const Medxnote_LastActivity = @"MedxStorageLastActivityKey";

// this is copied from TSAccountManager.m
NSString *const UserAccountCollection = @"TSStorageUserAccountCollection";

@implementation MedxPasscodeManager

+ (BOOL)isLockoutEnabled {
    return [[TSStorageManager sharedManager] boolForKey:Medxnote_LockoutEnabled inCollection:UserAccountCollection];
}

+ (void)setLockoutEnabled {
    YapDatabaseConnection *dbConn = [TSStorageManager sharedManager].dbReadWriteConnection;
    [dbConn readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:@YES
                        forKey:Medxnote_LockoutEnabled
                  inCollection:UserAccountCollection];
    }];

}

+ (BOOL)isPasscodeEnabled {
    return [[self passcode] length] > 0;
}

+ (NSString *)passcode {
    return [[TSStorageManager sharedManager] stringForKey:Medxnote_Passcode inCollection:UserAccountCollection];
}

+ (void)storePasscode:(NSString *)passcode {
    if ([[MedxPasscodeManager inactivityTimeoutInMinutes] isEqualToNumber:@(0)]) {
        // set default value
        NSLog(@"No timeout setting stored, setting default value");
        [self storeInactivityTimeout:@(300)];
    }
    YapDatabaseConnection *dbConn = [TSStorageManager sharedManager].dbReadWriteConnection;
    [dbConn readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:passcode
                        forKey:Medxnote_Passcode
                  inCollection:UserAccountCollection];
    }];
}

+ (NSNumber *)inactivityTimeout {
    return [[TSStorageManager sharedManager] objectForKey:Medxnote_PasscodeTimeout inCollection:UserAccountCollection];
}

+ (NSNumber *)inactivityTimeoutInMinutes {
    NSNumber *timeout = [MedxPasscodeManager inactivityTimeout];
    return @(timeout.integerValue / 60);
}

+ (void)storeInactivityTimeout:(NSNumber *)timeout {
    YapDatabaseConnection *dbConn = [TSStorageManager sharedManager].dbReadWriteConnection;
    [dbConn readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:timeout
                        forKey:Medxnote_PasscodeTimeout
                  inCollection:UserAccountCollection];
    }];
}

+ (NSDate *)lastActivityTime {
    return [[TSStorageManager sharedManager] objectForKey:Medxnote_LastActivity inCollection:UserAccountCollection];
}

+ (void)storeLastActivityTime:(NSDate *)date {
    YapDatabaseConnection *dbConn = [TSStorageManager sharedManager].dbReadWriteConnection;
    [dbConn readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:date
                        forKey:Medxnote_LastActivity
                  inCollection:UserAccountCollection];
    }];
}

@end
