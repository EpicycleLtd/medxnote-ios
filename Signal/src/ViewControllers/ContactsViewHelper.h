//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class ContactsViewHelper;
@class Contact;

// We want to be able to present contacts with multiple signal
// accounts in the UI.  This class represents a given (contact,
// signal account) tuple.
@interface ContactAccount : NSObject

@property (nonatomic) Contact *contact;

// An E164 value identifying the signal account.
@property (nonatomic) NSString *recipientId;

// TODO: This might be redundant.
@property (nonatomic) BOOL isMultipleAccountContact;

// For contacts with more than one signal account,
// this is a label for the account.
@property (nonatomic) NSString *multipleAccountLabel;

@end

#pragma mark -

@protocol ContactsViewHelperDelegate <NSObject>

- (void)contactsViewHelperDidUpdateContacts;

@end

#pragma mark -

@interface ContactsViewHelper : NSObject

@property (nonatomic, weak) id<ContactsViewHelperDelegate> delegate;

// A list of all of the current user's contacts which have
// at least one signal account.
- (nullable NSArray<Contact *> *)allRecipientContacts;

// A list of all of the current user's ContactAccounts.
// See the comments on the ContactAccount class.
//
// The list is ordered by contact sorting (by OWSContactsManager)
// and within contacts by phone number, alphabetically.
- (nullable NSArray<ContactAccount *> *)allRecipientContactAccounts;

- (nullable ContactAccount *)contactAccountForRecipientId:(NSString *)recipientId;

- (nullable NSArray<NSString *> *)blockedPhoneNumbers;

// This method is faster than OWSBlockingManager but
// is only safe to be called on the main thread.
//
// Returns true if _any_ number associated with this contact
// is blocked.
- (BOOL)isContactBlocked:(Contact *)contact;

// This method is faster than OWSBlockingManager but
// is only safe to be called on the main thread.
- (BOOL)isRecipientIdBlocked:(NSString *)recipientId;

@end

NS_ASSUME_NONNULL_END
