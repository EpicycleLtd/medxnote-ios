//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "Release.h"
#import "Environment.h"
#import "NotificationsManager.h"
#import "OWSContactsManager.h"
#import <SignalServiceKit/ContactsUpdater.h>
#import <SignalServiceKit/OWSMessageSender.h>
#import <SignalServiceKit/OWSOutboxStorage.h>
#import <SignalServiceKit/OWSPrimaryCopyStorage.h>
#import <SignalServiceKit/OWSSessionStorage.h>
#import <SignalServiceKit/TSNetworkManager.h>

@implementation Release

+ (Environment *)releaseEnvironment
{
    static Environment *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Order matters here.
        TSStorageManager *storageManager = [TSStorageManager sharedManager];
        OWSSessionStorage *sessionStorage = [OWSSessionStorage sharedManager];
        __unused OWSOutboxStorage *outboxStorage = [OWSOutboxStorage sharedManager];
        TSNetworkManager *networkManager = [TSNetworkManager sharedManager];
        OWSContactsManager *contactsManager = [OWSContactsManager new];
        ContactsUpdater *contactsUpdater = [ContactsUpdater sharedUpdater];
        OWSMessageSender *messageSender = [[OWSMessageSender alloc] initWithNetworkManager:networkManager
                                                                            storageManager:storageManager
                                                                            sessionStorage:sessionStorage
                                                                           contactsManager:contactsManager
                                                                           contactsUpdater:contactsUpdater];

        instance = [[Environment alloc] initWithContactsManager:contactsManager
                                                contactsUpdater:contactsUpdater
                                                 networkManager:networkManager
                                                  messageSender:messageSender];
    });
    return instance;
}

@end
