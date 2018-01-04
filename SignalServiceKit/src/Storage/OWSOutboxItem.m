//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSOutboxItem.h"
#import "NSDate+OWS.h"

NS_ASSUME_NONNULL_BEGIN

@implementation OWSOutboxItem

- (instancetype)initWithSyncId:(NSString *)syncId
               outboxMessageId:(NSString *)outboxMessageId
                   recipientId:(NSString *)recipientId
{
    OWSAssert(syncId.length > 0);
    OWSAssert(outboxMessageId.length > 0);
    OWSAssert(recipientId.length > 0);

    self = [super initWithUniqueId:syncId];

    if (!self) {
        return self;
    }

    _timestamp = [NSDate ows_millisecondTimeStamp];
    _syncId = syncId;
    _outboxMessageId = outboxMessageId;
    _recipientId = recipientId;

    return self;
}

- (instancetype)initWithSyncId:(NSString *)syncId outboxMessageId:(NSString *)outboxMessageId groupId:(NSData *)groupId
{
    OWSAssert(syncId.length > 0);
    OWSAssert(outboxMessageId.length > 0);
    OWSAssert(groupId.length > 0);

    self = [super initWithUniqueId:syncId];

    if (!self) {
        return self;
    }

    _timestamp = [NSDate ows_millisecondTimeStamp];
    _syncId = syncId;
    _outboxMessageId = outboxMessageId;
    _groupId = groupId;

    return self;
}

@end

NS_ASSUME_NONNULL_END
