//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSOutboxStorage.h"
#import "OWSFileSystem.h"
#import "OWSStorage+Subclass.h"
#import "OutboxProcessor.h"
#import "TSDatabaseView.h"
#import <YapDatabase/YapDatabase.h>

NS_ASSUME_NONNULL_BEGIN

@implementation OWSOutboxStorage

+ (instancetype)sharedManager
{
    static OWSOutboxStorage *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] initStorage];

        [OWSOutboxStorage protectFiles];
    });
    return sharedManager;
}

- (instancetype)initStorage
{
    self = [super initStorage];

    if (self) {
        OWSSingletonAssert();
    }

    return self;
}

- (StorageType)storageType
{
    return StorageType_Outbox;
}

+ (NSString *)databaseDirName
{
    return @"Outbox";
}

+ (NSString *)databaseFilename
{
    return @"Outbox.sqlite";
}

- (NSString *)databaseFilePath
{
    NSString *databaseFilePath = OWSOutboxStorage.databaseFilePath;
    DDLogVerbose(@"%@ databaseFilePath: %@", self.logTag, databaseFilePath);
    return databaseFilePath;
}

+ (YapDatabaseConnection *)dbConnection
{
    return OWSOutboxStorage.sharedManager.dbConnection;
}

- (void)runAsyncRegistrationsWithCompletion:(void (^_Nonnull)(void))completion
{
    OWSAssert(completion);

    [OutboxProcessor asyncRegisterOutboxDatabaseExtensions:self];

    [super runAsyncRegistrationsWithCompletion:completion];
}

@end

NS_ASSUME_NONNULL_END
