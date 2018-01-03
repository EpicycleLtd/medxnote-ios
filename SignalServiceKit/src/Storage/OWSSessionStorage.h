//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSSharedStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface OWSSessionStorage : OWSSharedStorage

+ (instancetype)sharedManager;

// NOTE: Do not cache references to this connection elsewhere.
//
// OWSSessionStorage will close the database when the app is in the background,
// which will invalidate thise connection.
+ (YapDatabaseConnection *)dbConnection;

- (NSString *)databaseFilePath;
+ (NSString *)databaseFilePath;
+ (NSString *)databaseFilePath_SHM;
+ (NSString *)databaseFilePath_WAL;

#pragma mark - Migration

- (void)copyCollection:(NSString *)collection fromStorage:(OWSStorage *)storage valueClass:(Class)valueClass;

@end

NS_ASSUME_NONNULL_END
