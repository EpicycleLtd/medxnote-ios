//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSRecipientIdentity.h"
#import <AxolotlKit/IdentityKeyStore.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const TSStorageManagerTrustedKeysCollection;
extern NSString *const OWSIdentityStore_Collection;

// This notification will be fired whenever identities are created
// or their verification state changes.
extern NSString *const kNSNotificationName_IdentityStateDidChange;

// number of bytes in a signal identity key, excluding the key-type byte.
extern const NSUInteger kIdentityKeyLength;

@class OWSRecipientIdentity;
@class OWSSignalServiceProtosVerified;
@class OWSStorage;

// This class can be safely accessed and used from any thread.
@interface OWSIdentityManager : NSObject <IdentityKeyStore>

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)sharedManager;

- (void)generateNewIdentityKey;

- (nullable NSData *)identityKeyForRecipientId:(NSString *)recipientId;

- (void)setVerificationState:(OWSVerificationState)verificationState
                 identityKey:(NSData *)identityKey
                 recipientId:(NSString *)recipientId
       isUserInitiatedChange:(BOOL)isUserInitiatedChange;

- (OWSVerificationState)verificationStateForRecipientId:(NSString *)recipientId;

- (nullable OWSRecipientIdentity *)recipientIdentityForRecipientId:(NSString *)recipientId;

/**
 * @param   recipientId unique stable identifier for the recipient, e.g. e164 phone number
 * @returns nil if the recipient does not exist, or is trusted for sending
 *          else returns the untrusted recipient.
 */
- (nullable OWSRecipientIdentity *)untrustedIdentityForSendingToRecipientId:(NSString *)recipientId;

// This method can be called from any thread.
- (void)processIncomingSyncMessage:(OWSSignalServiceProtosVerified *)verified;

- (void)migrateFromStorageIfNecessary:(OWSStorage *)storage;

@end

NS_ASSUME_NONNULL_END
