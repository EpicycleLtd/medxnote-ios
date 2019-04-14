//
//  OWSInstallMessage.h
//  SignalServiceKit
//
//  Created by Jan Nemeček on 3/17/19.
//

#import "TSOutgoingMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface OWSInstallMessage : TSOutgoingMessage

@property NSString *recipientId;

@end

NS_ASSUME_NONNULL_END
