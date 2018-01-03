//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSOutboxStorage.h"
#import "OWSFileSystem.h"
#import "OWSStorage+Subclass.h"
#import "TSDatabaseView.h"
#import <YapDatabase/YapDatabase.h>

NS_ASSUME_NONNULL_BEGIN

@implementation OWSOutboxItem

- (instancetype)initWithSourceMessageId:(NSString *)sourceMessageId
                        outboxMessageId:(NSString *)outboxMessageId
                            recipientId:(NSString *)recipientId
{
    OWSAssert(sourceMessageId.length > 0);
    OWSAssert(outboxMessageId.length > 0);
    OWSAssert(recipientId.length > 0);

    self = [super initWithUniqueId:nil];

    if (!self) {
        return self;
    }

    _sourceMessageId = sourceMessageId;
    _outboxMessageId = outboxMessageId;
    _recipientId = recipientId;

    return self;
}

- (instancetype)initWithSourceMessageId:(NSString *)sourceMessageId
                        outboxMessageId:(NSString *)outboxMessageId
                                groupId:(NSData *)groupId
{
    OWSAssert(sourceMessageId.length > 0);
    OWSAssert(outboxMessageId.length > 0);
    OWSAssert(groupId.length > 0);

    self = [super initWithUniqueId:nil];

    if (!self) {
        return self;
    }

    _sourceMessageId = sourceMessageId;
    _outboxMessageId = outboxMessageId;
    _groupId = groupId;

    return self;
}

@end

#pragma mark -

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

@end

NS_ASSUME_NONNULL_END
