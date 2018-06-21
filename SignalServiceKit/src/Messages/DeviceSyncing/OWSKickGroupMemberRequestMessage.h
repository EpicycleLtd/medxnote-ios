//
//  OWSKickGroupMemberRequestMessage.h
//  SignalServiceKit
//
//  Created by Jan Nemecek on 21/6/18.
//

#import "OWSOutgoingSyncMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface OWSKickGroupMemberRequestMessage : TSOutgoingMessage

@property (nonatomic, strong) NSString *recipientId;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithThread:(nullable TSThread *)thread groupId:(NSData *)groupId;

@end

NS_ASSUME_NONNULL_END
