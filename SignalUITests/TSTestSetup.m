//
//  TSTestSetup.m
//  Signal
//
//  Created by Michael Kirk on 3/31/16.
//  Copyright © 2016 Open Whisper Systems. All rights reserved.
//

#import "TSTestSetup.h"

#import "TSStartingStateForTest.h"
#import "TSStorageManager.h"
#import "TSStorageManager+keyingMaterial.h"
#import "SignalRecipient.h"

@implementation TSTestSetup

+ (BOOL)isSimulator {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

+ (void)setupWithLaunchArguments:(NSArray<NSString *> * _Nonnull)launchArguments {

    if (![self isSimulator]) {
        NSLog(@"Cowardly refusing to do any test setup since this is not a Simulator.");
        exit(1);
    }

    if ([launchArguments containsObject:TSRunTestSetup]) {
        NSLog(@"Deleting threads and messages.");
        [[TSStorageManager sharedManager] wipeSignalStorage];
    }

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
    // Corresponds to "Jonny Appleseed" contact in simulator address book.
    NSString *phoneNumber = @"+18885555512";
    NSLog(@"Faking registration with number: %@", phoneNumber);

    [TSStorageManager storePhoneNumber:phoneNumber];
    [[TSStorageManager sharedManager].dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {

        if (![SignalRecipient recipientWithTextSecureIdentifier:phoneNumber withTransaction:transaction]) {
            SignalRecipient *recipient = [[SignalRecipient alloc] initWithTextSecureIdentifier:phoneNumber
                                                                                         relay:@"fake-raley"
                                                                                 supportsVoice:YES];
            [recipient save];
            NSLog(@"Creating fake SignalRecipient with number: %@", phoneNumber);
        }
    }];
}

+ (void)unregistered {
    NSLog(@"Faking unregistration by erasing storedPhoneNumber. Any other app data (messages, contacts, etc.) remain.");
    [TSStorageManager storePhoneNumber:nil];
}

@end
