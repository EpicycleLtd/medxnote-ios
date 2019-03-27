//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSMessageHandler.h"

NS_ASSUME_NONNULL_BEGIN

@class OWSSignalServiceProtosEnvelope;
@class TSThread;
@class TSGroupThread;
@class YapDatabaseReadWriteTransaction;

@interface OWSMessageManager : OWSMessageHandler

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)sharedManager;

// processEnvelope: can be called from any thread.
- (void)processEnvelope:(OWSSignalServiceProtosEnvelope *)envelope
          plaintextData:(NSData *_Nullable)plaintextData
            transaction:(YapDatabaseReadWriteTransaction *)transaction;
- (void)sendGroupKick:(TSGroupThread *)thread
            recipient:(NSString *)recipientId
          transaction:(YapDatabaseReadWriteTransaction *)transaction;

- (NSUInteger)unreadMessagesCount;
- (NSUInteger)unreadMessagesCountExcept:(TSThread *)thread;
- (NSUInteger)unreadMessagesInThread:(TSThread *)thread;
- (NSUInteger)unreadMessagesCountInExtension:(NSString *)extension;

@end

NS_ASSUME_NONNULL_END
