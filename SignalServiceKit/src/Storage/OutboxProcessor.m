//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OutboxProcessor.h"
#import "OWSOutboxItem.h"
#import "TSAttachmentStream.h"
#import "TSOutgoingMessage.h"

//#import "Environment.h"
//#import "NotificationsManager.h"
//#import "OWSContactsManager.h"
//#import <SignalServiceKit/ContactsUpdater.h>
//#import <SignalServiceKit/OWSMessageSender.h>
#import "OWSOutboxStorage.h"

//#import <SignalServiceKit/OWSPrimaryCopyStorage.h>
//#import <SignalServiceKit/OWSSessionStorage.h>
//#import <SignalServiceKit/TSNetworkManager.h>
#import "TSStorageManager.h"
#import <YapDatabase/YapDatabaseSecondaryIndex.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const OutboxItemTimestampColumn = @"timestamp";
static NSString *const OutboxItemByTimestampIndex = @"OutboxItemByTimestampIndex";
static NSString *const OutgoingMessageSyncIdColumn = @"sync_id";
static NSString *const OutgoingMessageBySyncIdIndex = @"OutgoingMessageBySyncIdIndex";

@implementation OutboxProcessor

+ (instancetype)sharedManager
{
    static OutboxProcessor *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] initDefault];
    });
    return sharedMyManager;
}

- (instancetype)initDefault
{
    //    TSStorageManager *storageManager = [TSStorageManager sharedManager];
    //    OWSMessageSender *messageSender = [TextSecureKitEnv sharedEnv].messageSender;
    //
    //    return [self initWithStorageManager:storageManager messageSender:messageSender];
    //}
    //
    //- (instancetype)initWithStorageManager:(TSStorageManager *)storageManager messageSender:(OWSMessageSender
    //*)messageSender
    //{
    self = [super init];

    if (!self) {
        return self;
    }

    //    OWSAssert(storageManager);
    //    OWSAssert(messageSender);
    //
    //    _dbConnection = storageManager.newDatabaseConnection;
    //    _messageSender = messageSender;

    OWSSingletonAssert();

    //    // Register this manager with the message sender.
    //    // This is a circular dependency.
    //    [messageSender setBlockingManager:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModifiedExternally:)
                                                 name:YapDatabaseModifiedExternallyNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(storageIsReady:)
                                                 name:StorageIsReadyNotification
                                               object:nil];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)yapDatabaseModifiedExternally:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    DDLogVerbose(@"%@ %s", self.logTag, __PRETTY_FUNCTION__);

    [self tryToProcessOutbox];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    DDLogVerbose(@"%@ %s", self.logTag, __PRETTY_FUNCTION__);

    [self tryToProcessOutbox];
}

- (void)storageIsReady:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    DDLogVerbose(@"%@ %s", self.logTag, __PRETTY_FUNCTION__);

    [self tryToProcessOutbox];
}

- (void)tryToProcessOutbox
{
    OWSAssertIsOnMainThread();

    if (!OWSStorage.isStorageReady) {
        return;
    }

    DDLogVerbose(@"%@ %s", self.logTag, __PRETTY_FUNCTION__);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block BOOL didProcess = NO;

        [OWSOutboxStorage.sharedManager addClient];
        [OWSOutboxStorage.sharedManager.dbConnection readWriteWithBlock:^(
            YapDatabaseReadWriteTransaction *_Nonnull transaction) {

            NSString *formattedString = [NSString stringWithFormat:@"ORDER BY %@ ASC", OutboxItemTimestampColumn];
            YapDatabaseQuery *query = [YapDatabaseQuery queryWithFormat:formattedString];

            __block OWSOutboxItem *_Nullable firstItem = nil;
            [[transaction ext:OutboxItemByTimestampIndex]
                enumerateKeysAndObjectsMatchingQuery:query
                                          usingBlock:^void(
                                              NSString *collection, NSString *key, OWSOutboxItem *item, BOOL *stop) {
                                              //                 firstMessage = (TSMessage *)object;
                                              //                 *stop = YES;
                                              if (![item isKindOfClass:[OWSOutboxItem class]]) {
                                                  OWSFail(@"%@ unexpected object: %@", self.logTag, item.class);
                                                  return;
                                              }

                                              firstItem = item;
                                              *stop = YES;
                                          }];

            if (firstItem) {
                [self processItem:firstItem outboxTransaction:transaction];

                // Only process one item at a time to avoid long-running write transactions on
                // outbox database.
                //
                // TODO:
                didProcess = YES;
            }
        }];
        [OWSOutboxStorage.sharedManager removeClient];

        if (didProcess) {
            [self tryToProcessOutbox];
        }
    });
}

- (void)processItem:(OWSOutboxItem *)item outboxTransaction:(YapDatabaseReadWriteTransaction *)outboxTransaction
{
    OWSAssert(item);
    OWSAssert(outboxTransaction);

    TSOutgoingMessage *_Nullable outboxMessage = nil;
    TSAttachmentStream *_Nullable outboxAttachment = nil;
    void (^cleanupOutbox)(void) = ^{
        [item removeWithTransaction:outboxTransaction];
        // Might be nil.
        [outboxMessage removeWithTransaction:outboxTransaction];
        // Might be nil.
        [outboxAttachment removeWithTransaction:outboxTransaction];
    };

    outboxMessage = [TSOutgoingMessage fetchObjectWithUniqueID:item.outboxMessageId transaction:outboxTransaction];
    if (!outboxMessage) {
        OWSFail(@"%@ outbox item refers to missing message: %@", self.logTag, item.outboxMessageId);
        cleanupOutbox();
        return;
    }

    if (outboxMessage.attachmentIds.count > 0) {
        OWSAssert(outboxMessage.attachmentIds.count == 1);

        NSString *attachmentId = outboxMessage.attachmentIds.firstObject;
        outboxAttachment = [TSAttachmentStream fetchObjectWithUniqueID:attachmentId transaction:outboxTransaction];
        if (!outboxAttachment) {
            OWSFail(@"%@ outbox item refers to missing attachment: %@", self.logTag, attachmentId);
            cleanupOutbox();
            return;
        }
    }

    if (item.syncId.length < 1 || ![item.syncId isEqualToString:outboxMessage.syncId]) {
        OWSFail(@"%@ outbox item missing sync id: %@", self.logTag, item.outboxMessageId);
        cleanupOutbox();
        return;
    }

    YapDatabaseConnection *primaryDBConnection = TSStorageManager.sharedManager.newDatabaseConnection;
    // We split up the primary database work across two transactions.
    //
    // * The first transaction determines whether or not we are in the "update" or "create" case by
    //   trying to locate an existing message in the primary storage for this item.
    // * The second transaction does the "update" or "create".
    //
    // Between these two transactions we do any file copy, since this is expensive.
    // We don't need to worry about consistency between these two transactions; only
    // this class processes outbox items so
    YapDatabaseQuery *query = [YapDatabaseQuery
        queryWithFormat:[NSString stringWithFormat:@"WHERE %@ = %@", OutgoingMessageSyncIdColumn, item.syncId]];
    __block TSOutgoingMessage *_Nullable primaryMessage = nil;
    [primaryDBConnection readWithBlock:^(YapDatabaseReadTransaction *primaryTransaction) {
        [[primaryTransaction ext:OutgoingMessageBySyncIdIndex]
            enumerateKeysAndObjectsMatchingQuery:query
                                      usingBlock:^void(
                                          NSString *collection, NSString *key, TSOutgoingMessage *message, BOOL *stop) {
                                          if (![message isKindOfClass:[TSOutgoingMessage class]]) {
                                              OWSFail(@"%@ unexpected object: %@", self.logTag, message.class);
                                              return;
                                          }

                                          primaryMessage = message;
                                          *stop = YES;
                                      }];
    }];

    if (primaryMessage) {
        // The update case.

        [primaryDBConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull primaryTransaction) {
            if (primaryMessage.messageState != outboxMessage.messageState) {
                [primaryMessage updateWithMessageState:outboxMessage.messageState transaction:primaryTransaction];
            }
            [outboxMessage.recipientDeliveryMap
                enumerateKeysAndObjectsUsingBlock:^(NSString *recipientId, NSNumber *deliveryTimestamp, BOOL *stop) {
                    [primaryMessage updateWithDeliveredToRecipientId:recipientId
                                                   deliveryTimestamp:deliveryTimestamp
                                                         transaction:primaryTransaction];
                }];
            if (outboxMessage.hasSyncedTranscript) {
                [primaryMessage updateWithHasSyncedTranscript:outboxMessage.hasSyncedTranscript
                                                  transaction:primaryTransaction];
            }
            if (outboxMessage.hasSyncedTranscript) {
                [primaryMessage updateWithHasSyncedTranscript:outboxMessage.hasSyncedTranscript
                                                  transaction:primaryTransaction];
            }
            if (outboxMessage.mostRecentFailureText) {
                [primaryMessage updateWithMostRecentFailureText:outboxMessage.mostRecentFailureText
                                                    transaction:primaryTransaction];
            }
        }];
    } else {
        // The create case.

        NSError *_Nullable error = nil;
        TSAttachmentStream *_Nullable primaryAttachment = nil;
        if (outboxAttachment) {
            primaryAttachment =
                [[TSAttachmentStream alloc] initWithDictionary:outboxAttachment.dictionaryValue error:&error];
            if (!primaryAttachment || error) {
                OWSFail(@"%@ Failed to copy attachment with error: %@", self.logTag, error);
                return NO;
            }
            primaryAttachment.uniqueId = nil;

            NSString *_Nullable outboxAttachmentFilePath = [outboxAttachment filePath];
            if (!outboxAttachmentFilePath) {
                OWSFail(@"%@ outbox attachment missing file path: %@", self.logTag, item.syncId);
                cleanupOutbox();
                return;
            }
            DataSource *_Nullable dataSource = [DataSourcePath dataSourceWithFilePath:outboxAttachment];
            if (!dataSource) {
                OWSFail(@"%@ outbox attachment has invalid file: %@", self.logTag, outboxAttachmentFilePath);
                cleanupOutbox();
                return;
            }

            if (![primaryAttachment writeDataSource:dataSource]) {
                OWSFail(@"%@ outbox attachment file can't be copied: %@", self.logTag, outboxAttachmentFilePath);
                cleanupOutbox();
                return;
            }
        }

        //        TSThread *_Nullable thread = message.thread;
        //        if (!thread) {
        //            OWSFail(@"%@ Failed to fetch thread for message.", self.logTag);
        //            return NO;
        //        }

        //        TSAttachmentStream *_Nullable attachmentStream =
        //        [TSAttachmentStream fetchObjectWithUniqueID:message.attachmentIds.firstObject];

        TSOutgoingMessage *primaryMessage =
            [[TSOutgoingMessage alloc] initWithDictionary:outboxMessage.dictionaryValue error:&error];
        if (!primaryMessage || error) {
            OWSFail(@"%@ Failed to copy message with error: %@", self.logTag, error);
            return NO;
        }
        messageCopy.uniqueId = nil;

        [primaryDBConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull primaryTransaction) {
            //        [outboxDBConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
            if (primaryAttachment) {
                [primaryAttachment saveWithTransaction:primaryTransaction];

                OWSAssert(primaryAttachment.uniqueId.length > 0);

                DDLogDebug(@"%@ Attachment cloned to primary: %@", self.logTag, primaryAttachment.uniqueId);

                [primaryMessage.attachmentIds removeAllObjects];
                [primaryMessage.attachmentIds addObject:primaryAttachment.uniqueId];
            }

            // TODO:
            //            //            uniqueThreadId
            //
            //            [primaryMessage saveWithTransaction:primaryTransaction];
            //
            //            OWSOutboxItem *_Nullable outboxItem = nil;
            //            if (thread.isGroupThread) {
            //                TSGroupThread *groupThread = (TSGroupThread *)thread;
            //                outboxItem = [[OWSOutboxItem alloc] initWithSyncId:message.syncId
            //                                                   outboxMessageId:messageCopy.uniqueId
            //                                                           groupId:groupThread.groupModel.groupId];
            //            } else {
            //                TSContactThread *contactThread = (TSContactThread *)thread;
            //                outboxItem = [[OWSOutboxItem alloc] initWithSyncId:message.syncId
            //                                                   outboxMessageId:messageCopy.uniqueId
            //                                                       recipientId:contactThread.contactIdentifier];
            //            }
            //            OWSAssert(outboxItem);
            //            [outboxItem saveWithTransaction:transaction];
            //
            //            DDLogDebug(@"%@ Message cloned to primary: %@, %@, %@",
            //                self.logTag,
            //                outboxItem.syncId,
            //                outboxItem.outboxMessageId,
            //                outboxItem.uniqueId);
        }];
    }

    cleanupOutbox();


    //#import "TSOutgoingMessage.h"
    //#import "TSAttachmentStream.h"

    //    @property (nonatomic, readonly) uint64_t timestamp;
    //    @property (nonatomic, readonly) NSString *syncId;
    //    @property (nonatomic, readonly) NSString *outboxMessageId;
    //
    //    // Exactly one of recipientId and groupId should be set.
    //    // Every outbox message should correspond to either:
    //    //
    //    // * A message in a 1:1 thread.  If it does not exist, a new 1:1 thread should be created.
    //    // * A message to a group thread that "already exists" in the primary database.  If it has been deleted,
    //    //   the outbox item can be safely discarded.
    //    @property (nonatomic, nullable, readonly) NSString *recipientId;
    //    @property (nonatomic, nullable, readonly) NSData *groupId;
}

#pragma mark - YapDatabaseExtension

+ (YapDatabaseSecondaryIndex *)outboxItemByTimestampIndex
{
    YapDatabaseSecondaryIndexSetup *setup = [YapDatabaseSecondaryIndexSetup new];
    [setup addColumn:OutboxItemTimestampColumn withType:YapDatabaseSecondaryIndexTypeInteger];

    YapDatabaseSecondaryIndexHandler *handler =
        [YapDatabaseSecondaryIndexHandler withObjectBlock:^(YapDatabaseReadTransaction *transaction,
            NSMutableDictionary *dict,
            NSString *collection,
            NSString *key,
            id object) {
            if (![object isKindOfClass:[OWSOutboxItem class]]) {
                OWSFail(@"%@ Unexpected item in index: %@", self.logTag, [object class]);
                return;
            }
            OWSOutboxItem *item = (OWSOutboxItem *)object;

            dict[OutboxItemTimestampColumn] = @(item.timestamp);
        }];

    return [[YapDatabaseSecondaryIndex alloc] initWithSetup:setup handler:handler];
}

+ (YapDatabaseSecondaryIndex *)outgoingMessageBySyncIdIndex
{
    YapDatabaseSecondaryIndexSetup *setup = [YapDatabaseSecondaryIndexSetup new];
    [setup addColumn:OutgoingMessageSyncIdColumn withType:YapDatabaseSecondaryIndexTypeText];

    YapDatabaseSecondaryIndexHandler *handler =
        [YapDatabaseSecondaryIndexHandler withObjectBlock:^(YapDatabaseReadTransaction *transaction,
            NSMutableDictionary *dict,
            NSString *collection,
            NSString *key,
            id object) {
            if (![object isKindOfClass:[TSOutgoingMessage class]]) {
                OWSFail(@"%@ Unexpected item in index: %@", self.logTag, [object class]);
                return;
            }
            TSOutgoingMessage *item = (TSOutgoingMessage *)object;

            dict[OutgoingMessageSyncIdColumn] = item.syncId;
        }];

    return [[YapDatabaseSecondaryIndex alloc] initWithSetup:setup handler:handler];
}

+ (void)asyncRegisterPrimaryDatabaseExtensions:(OWSStorage *)storage
{
    [storage asyncRegisterExtension:[self outgoingMessageBySyncIdIndex]
                           withName:OutgoingMessageBySyncIdIndex
                    completionBlock:^(BOOL ready) {
                        if (ready) {
                            DDLogDebug(@"%@ completed registering extension async.", self.logTag);
                        } else {
                            DDLogError(@"%@ failed registering extension async.", self.logTag);
                        }
                    }];
}

+ (void)asyncRegisterOutboxDatabaseExtensions:(OWSStorage *)storage
{
    [storage asyncRegisterExtension:[self outboxItemByTimestampIndex]
                           withName:OutboxItemByTimestampIndex
                    completionBlock:^(BOOL ready) {
                        if (ready) {
                            DDLogDebug(@"%@ completed registering extension async.", self.logTag);
                        } else {
                            DDLogError(@"%@ failed registering extension async.", self.logTag);
                        }
                    }];
}

@end

NS_ASSUME_NONNULL_END
