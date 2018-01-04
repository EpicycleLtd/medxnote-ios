//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "TSYapDatabaseObject.h"

NS_ASSUME_NONNULL_BEGIN

// Messages sent from the SAE have the following lifecycle:
//
// * Saved in primary storage copy.
// * Sent.
// * Cloned into "outbox" storage by SAE.
// * Cloned into primary storage by main app.
//
// There are various issues around how to identify messages through this lifecycle.
//
// * The primary copy can be overwritten.
// * Messages may be written multiple times to the outbox (as separate items) in order
//   to capture "recipient delivery" state.
// * Outbox items may be saved multiple times since we don't synchronize transactions
//   across databases.
// * To avoid uniqueId conflicts, the models' unique ids are regenerated each time they
//   are "cloned" between storages.
//
// Therefore we use syncIds (UUIDs) to uniquely identify messages sent from the SAE.
@interface OWSOutboxItem : TSYapDatabaseObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSyncId:(NSString *)syncId
               outboxMessageId:(NSString *)outboxMessageId
                   recipientId:(NSString *)recipientId;
- (instancetype)initWithSyncId:(NSString *)syncId outboxMessageId:(NSString *)outboxMessageId groupId:(NSData *)groupId;

@property (nonatomic, readonly) uint64_t timestamp;
@property (nonatomic, readonly) NSString *syncId;
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

NS_ASSUME_NONNULL_END
