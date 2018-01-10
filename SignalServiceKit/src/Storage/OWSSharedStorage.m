//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSSharedStorage.h"
#import "OWSFileSystem.h"
#import "OWSStorage+Subclass.h"
#import "TSDatabaseView.h"
#import <YapDatabase/YapDatabase.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const OWSSharedStorageExceptionName_CouldNotCreateDatabaseDirectory
    = @"OWSSharedStorageExceptionName_CouldNotCreateDatabaseDirectory";

#pragma mark -

@interface OWSSharedStorage ()

@property (nonatomic, readonly) YapDatabaseConnection *dbConnection;

@property (atomic) BOOL areAsyncRegistrationsComplete;
@property (atomic) BOOL areSyncRegistrationsComplete;
@property (atomic) int clientCount;

@end

#pragma mark -

@implementation OWSSharedStorage

@synthesize dbConnection = _dbConnection;

- (instancetype)initStorage
{
    self = [super initStorage];

    if (self) {
        [self openDatabase];

        [self observeNotifications];

        OWSSingletonAssert();
    }

    return self;
}

- (StorageType)storageType
{
    return StorageType_Unknown;
}

- (void)openDatabase
{
    [super openDatabase];

    _dbConnection = self.newDatabaseConnection;

    self.dbConnection.objectCacheEnabled = NO;
#if DEBUG
    self.dbConnection.permittedTransactions = YDB_AnySyncTransaction;
#endif
}

- (void)closeDatabase
{
    [super closeDatabase];

    _dbConnection = nil;
}

- (void)resetStorage
{
    _dbConnection = nil;

    [super resetStorage];
}

- (void)runSyncRegistrations
{
    // Synchronously register extensions which are essential for views.
    [TSDatabaseView registerCrossProcessNotifier:self];

    OWSAssert(!self.areSyncRegistrationsComplete);
    self.areSyncRegistrationsComplete = YES;
}

- (void)runAsyncRegistrationsWithCompletion:(void (^_Nonnull)(void))completion
{
    OWSAssert(completion);

    // Asynchronously register other extensions.
    //
    // All sync registrations must be done before all async registrations,
    // or the sync registrations will block on the async registrations.

    // Block until all async registrations are complete.
    [self.newDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        OWSAssert(!self.areAsyncRegistrationsComplete);

        self.areAsyncRegistrationsComplete = YES;

        completion();
    }];
}

+ (void)protectFiles
{
    // Protect the entire new database directory.
    [OWSFileSystem protectFileOrFolderAtPath:self.databaseDirPath];
}

+ (NSString *)databaseDirName
{
    OWS_ABSTRACT_METHOD();

    return @"";
}

+ (NSString *)databaseDirPath
{
    NSString *databaseDirPath =
        [[OWSFileSystem appSharedDataDirectoryPath] stringByAppendingPathComponent:self.databaseDirName];

    if (![OWSFileSystem ensureDirectoryExists:databaseDirPath]) {
        [NSException raise:OWSSharedStorageExceptionName_CouldNotCreateDatabaseDirectory
                    format:@"Could not create new database directory"];
    }
    return databaseDirPath;
}

+ (NSString *)databaseFilename
{
    OWS_ABSTRACT_METHOD();

    return @"";
}

+ (NSString *)databaseFilename_SHM
{
    return [self.databaseFilename stringByAppendingString:@"-shm"];
}

+ (NSString *)databaseFilename_WAL
{
    return [self.databaseFilename stringByAppendingString:@"-wal"];
}

+ (NSString *)databaseFilePath
{
    NSString *databaseFilePath = [self.databaseDirPath stringByAppendingPathComponent:self.databaseFilename];
    return databaseFilePath;
}

+ (NSString *)databaseFilePath_SHM
{
    return [self.databaseDirPath stringByAppendingPathComponent:self.databaseFilename_SHM];
}

+ (NSString *)databaseFilePath_WAL
{
    return [self.databaseDirPath stringByAppendingPathComponent:self.databaseFilename_WAL];
}

- (NSString *)databaseFilePath
{
    NSString *databaseFilePath = OWSSharedStorage.databaseFilePath;
    DDLogVerbose(@"%@ databaseFilePath: %@", self.logTag, databaseFilePath);
    return databaseFilePath;
}

- (NSString *)databaseFilePath_SHM
{
    return OWSSharedStorage.databaseFilePath_SHM;
}

- (NSString *)databaseFilePath_WAL
{
    return OWSSharedStorage.databaseFilePath_WAL;
}

- (YapDatabaseConnection *)dbConnection
{
    OWSAssert(_dbConnection);

    return _dbConnection;
}

#pragma mark - Clients

- (BOOL)shouldDatabaseBeOpen
{
    @synchronized(self)
    {
        if (self.clientCount > 0) {
            return YES;
        }
    }
    return [super shouldDatabaseBeOpen];
}

- (void)addClient
{
    @synchronized(self)
    {
        self.clientCount = self.clientCount + 1;
    }
    [self openDatabaseIfNecessary];
}

- (void)removeClient
{
    @synchronized(self)
    {
        OWSAssert(self.clientCount > 0);

        self.clientCount = MAX(0, self.clientCount - 1);
    }
    [self closeDatabaseIfNecessary];
}

@end

NS_ASSUME_NONNULL_END
