//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSSessionStorage.h"
#import "OWSFileSystem.h"
#import "OWSOutboxStorage.h"
#import "OWSStorage+Subclass.h"
#import "TSDatabaseView.h"
#import <YapDatabase/YapDatabase.h>

NS_ASSUME_NONNULL_BEGIN

@implementation OWSSessionStorage

+ (instancetype)sharedManager
{
    static OWSSessionStorage *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] initStorage];

        [OWSSessionStorage protectFiles];
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
    return StorageType_Session;
}

+ (NSString *)databaseDirName
{
    return @"Sessions";
}

+ (NSString *)databaseFilename
{
    return @"Sessions.sqlite";
}

- (NSString *)databaseFilePath
{
    NSString *databaseFilePath = OWSSessionStorage.databaseFilePath;
    DDLogVerbose(@"%@ databaseFilePath: %@", self.logTag, databaseFilePath);
    return databaseFilePath;
}

+ (YapDatabaseConnection *)dbConnection
{
    return OWSSessionStorage.sharedManager.dbConnection;
}

#pragma mark - Migration

- (void)copyCollection:(NSString *)collection fromStorage:(OWSStorage *)storage valueClass:(Class)valueClass
{
    OWSAssert(collection.length > 0);
    OWSAssert(storage);

    [OWSStorage copyCollection:collection
               srcDBConnection:storage.newDatabaseConnection
               dstDBConnection:self.dbConnection
                    valueClass:valueClass];
}

@end

NS_ASSUME_NONNULL_END
