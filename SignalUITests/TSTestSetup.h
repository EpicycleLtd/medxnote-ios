//
//  TSTestSetup.h
//  Signal
//
//  Created by Michael Kirk on 3/31/16.
//  Copyright © 2016 Open Whisper Systems. All rights reserved.
//

/**
 * Puts the app in a state useful for running certain tests. Probably you should 
 * not run this against your own device unless you have a custom bundle ID or 
 * don't mind blowing away your Signal contacts and message history.
 */


@interface TSTestSetup: NSObject

+ (void)setupWithLaunchArguments:(NSArray<NSString *> * _Nonnull)launchArguments;

@end

