//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSSharedStorage.h"
#import "TSYapDatabaseObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface OWSOutboxItem : TSYapDatabaseObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSourceMessageId:(NSString *)sourceMessageId
                        outboxMessageId:(NSString *)outboxMessageId
                            recipientId:(NSString *)recipientId;
- (instancetype)initWithSourceMessageId:(NSString *)sourceMessageId
                        outboxMessageId:(NSString *)outboxMessageId
                                groupId:(NSData *)groupId;

@property (nonatomic, readonly) NSString *sourceMessageId;
@property (nonatomic, readonly) NSString *outboxMessageId;

// Exactly one of recipientId and groupId should be set.
// Every outbox message should correspond to either:
//
// * A message in a 1:1 thread.  If it does not exist, a new 1:1 thread should be created.
// * A message to a group thread that "already exists" in the primary database.  If it has been deleted,
//   the outbox item can be safely discarded.
@property (nonatomic, nullable, readonly) NSString *recipientId;
@property (nonatomic, nullable, readonly) NSData *groupId;

@end

#pragma mark -

@interface OWSOutboxStorage : OWSSharedStorage

+ (instancetype)sharedManager;

// NOTE: Do not cache references to this connection elsewhere.
//
// OWSOutboxStorage will close the database when the app is in the background,
// which will invalidate thise connection.
+ (YapDatabaseConnection *)dbConnection;

- (NSString *)databaseFilePath;
+ (NSString *)databaseFilePath;
+ (NSString *)databaseFilePath_SHM;
+ (NSString *)databaseFilePath_WAL;

@end

NS_ASSUME_NONNULL_END
