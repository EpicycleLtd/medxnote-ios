//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSCall.h"
#import "TSCall.h"
#import "TSContactThread.h"
#import <JSQMessagesViewController/JSQMessagesTimestampFormatter.h>
#import <JSQMessagesViewController/UIImage+JSQMessages.h>
#import <SignalServiceKit/TSCall.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSCall ()

@property (nonatomic) TSCall *call;

@property (nonatomic, readonly) NSString *senderId;
@property (nonatomic, readonly) NSString *senderDisplayName;

@property (nonatomic, readonly) NSString *text;

@end

@implementation OWSCall

#pragma mark - Initialzation

- (instancetype)initWithCallRecord:(TSCall *)call
{
    OWSAssert(call);

    self = [super init];
    if (!self) {
        return self;
    }

    _call = call;

    OWSAssert([call.thread isKindOfClass:[TSContactThread class]]);
    TSContactThread *contactThread = (TSContactThread *)call.thread;

    _senderId = contactThread.contactIdentifier;
    OWSAssert(_senderId.length > 0);
    NSString *name = contactThread.name;
    _senderDisplayName = name;
    OWSAssert(_senderDisplayName.length > 0);

    switch (call.callType) {
        case RPRecentCallTypeMissed:
            _text = [NSString stringWithFormat:NSLocalizedString(@"MSGVIEW_MISSED_CALL_WITH_NAME", nil), name];
            break;
        case RPRecentCallTypeIncoming:
            _text = [NSString stringWithFormat:NSLocalizedString(@"MSGVIEW_RECEIVED_CALL", nil), name];
            break;
        case RPRecentCallTypeIncomingIncomplete:
            _text = [NSString stringWithFormat:NSLocalizedString(@"MSGVIEW_THEY_TRIED_TO_CALL_YOU", nil), name];
            break;
        case RPRecentCallTypeOutgoing:
            _text = [NSString stringWithFormat:NSLocalizedString(@"MSGVIEW_YOU_CALLED", nil), name];
            break;
        case RPRecentCallTypeOutgoingIncomplete:
            _text = [NSString stringWithFormat:NSLocalizedString(@"MSGVIEW_YOU_TRIED_TO_CALL", nil), name];
            break;
        case RPRecentCallTypeMissedBecauseOfChangedIdentity:
            _text = [NSString
                stringWithFormat:NSLocalizedString(@"MSGVIEW_MISSED_CALL_BECAUSE_OF_CHANGED_IDENTITY", nil), name];
            break;
        case RPRecentCallTypeDeclined:
            _text = [NSString
                stringWithFormat:NSLocalizedString(@"MSGVIEW_MISSED_CALL_BECAUSE_OF_CHANGED_IDENTITY", nil), name];
            break;
    }

    return self;
}

- (BOOL)isExpiringMessage
{
    return NO;
}

- (BOOL)shouldStartExpireTimer
{
    return NO;
}

- (double)expiresAtSeconds
{
    return 0;
}

- (uint32_t)expiresInSeconds
{
    return 0;
}

- (TSMessageAdapterType)messageType
{
    return TSCallAdapter;
}

- (NSDate *)date
{
    return self.call.dateForSorting;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    OWSCall *otherCall = (OWSCall *)object;

    return [self.call.uniqueId isEqualToString:otherCall.call.uniqueId];
}

- (NSUInteger)hash
{
    return self.call.uniqueId.hash;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: senderId=%@, senderDisplayName=%@, date=%@>",
                     [self class],
                     self.senderId,
                     self.senderDisplayName,
                     self.date];
}

- (TSInteraction *)interaction
{
    return self.call;
}

#pragma mark - OWSMessageEditing

- (BOOL)canPerformEditingAction:(SEL)action
{
    return action == @selector(delete:);
}

- (void)performEditingAction:(SEL)action
{
    // Deletes are always handled by TSMessageAdapter
    if (action == @selector(delete:)) {
        DDLogDebug(@"%@ Deleting interaction with uniqueId: %@", self.tag, self.interaction.uniqueId);
        [self.interaction remove];
        return;
    }

    // Shouldn't get here, as only supported actions should be exposed via canPerformEditingAction
    NSString *actionString = NSStringFromSelector(action);
    DDLogError(@"%@ '%@' action unsupported", self.tag, actionString);
}

#pragma mark - JSQMessageData

- (BOOL)isMediaMessage
{
    return NO;
}

- (NSUInteger)messageHash
{
    return self.call.uniqueId.hash;
}

#pragma mark - Logging

+ (NSString *)tag
{
    return [NSString stringWithFormat:@"[%@]", self.class];
}

- (NSString *)tag
{
    return self.class.tag;
}

@end

NS_ASSUME_NONNULL_END
