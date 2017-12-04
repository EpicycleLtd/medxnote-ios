//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSDatabaseMigrationRunner.h"
#import "OWSDatabaseMigration.h"
#import <SignalServiceKit/AppContext.h>

NS_ASSUME_NONNULL_BEGIN

@implementation OWSDatabaseMigrationRunner

- (instancetype)initWithStorageManager:(TSStorageManager *)storageManager
{
    self = [super init];
    if (!self) {
        return self;
    }

    _storageManager = storageManager;

    return self;
}

- (NSArray<OWSDatabaseMigration *> *)safeBlockingMigrations
{
    return CurrentAppContext().safeBlockingMigrations;
}

- (NSArray<OWSDatabaseMigration *> *)allMigrations
{
    return CurrentAppContext().allMigrations;
}

- (void)assumeAllExistingMigrationsRun
{
    for (OWSDatabaseMigration *migration in self.allMigrations) {
        DDLogInfo(@"%@ Skipping migration on new install: %@", self.logTag, migration);
        [migration save];
    }
}

- (void)runSafeBlockingMigrations
{
    [self runMigrations:self.safeBlockingMigrations];
}

- (void)runAllOutstanding
{
    [self runMigrations:self.allMigrations];
}

- (void)runMigrations:(NSArray<OWSDatabaseMigration *> *)migrations
{
    OWSAssert(migrations);

    for (OWSDatabaseMigration *migration in migrations) {
        if ([OWSDatabaseMigration fetchObjectWithUniqueID:migration.uniqueId]) {
            DDLogDebug(@"%@ Skipping previously run migration: %@", self.logTag, migration);
        } else {
            DDLogWarn(@"%@ Running migration: %@", self.logTag, migration);
            [migration runUp];
        }
    }
}

@end

NS_ASSUME_NONNULL_END
