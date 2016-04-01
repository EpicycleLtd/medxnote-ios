//
//  TSTestSetup.m
//  Signal
//
//  Created by Michael Kirk on 3/31/16.
//  Copyright © 2016 Open Whisper Systems. All rights reserved.
//

#import "TSStartingStateForTest.h"
#import "TSStorageManager+keyingMaterial.h"

#import "TSTestSetup.h"

@implementation TSTestSetup

+ (void)setupWithLaunchArguments:(NSArray<NSString *> * _Nonnull)launchArguments {

    if ([launchArguments containsObject:TSStartingStateForTestRegistered]) {
        NSLog(@"Lauching with test setup options: registered");
        [TSTestSetup registered];
    }

    if ([launchArguments containsObject:TSStartingStateForTestUnregistered]) {
        NSLog(@"Lauching with test setup options: unregistered");
        [TSTestSetup unregistered];
    }
}

// Configure a device as if it were registered
+ (void)registered {
    NSString *phoneNumber = @"+15555555555";
    NSLog(@"Faking registration with number: %@", phoneNumber);
    [TSStorageManager storePhoneNumber:@"+15555555555"];
}

+ (void)unregistered {
    NSLog(@"Faking unregistration by erasing storedPhoneNumber. Any other app data (messages, contacts, etc.) remain.");
    [TSStorageManager storePhoneNumber:nil];
}

@end
