//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "AddToBlockListViewController.h"
#import "BlockListUIUtils.h"
#import "ContactAccount.h"
#import "ContactsViewHelper.h"
//#import "ContactTableViewCell.h"
//#import "CountryCodeViewController.h"
//#import "Environment.h"
#import "OWSContactsManager.h"
//#import "PhoneNumber.h"
//#import "StringUtil.h"
//#import "UIFont+OWS.h"
//#import "UIUtil.h"
//#import "UIView+OWS.h"
//#import "ViewControllerUtils.h"
//#import <SignalServiceKit/OWSBlockingManager.h>
//#import <SignalServiceKit/PhoneNumberUtil.h>
//#import <SignalServiceKit/TSAccountManager.h>

NS_ASSUME_NONNULL_BEGIN

// NSString * const kAddToBlockListViewControllerCellIdentifier = @"kAddToBlockListViewControllerCellIdentifier";

#pragma mark -

@interface AddToBlockListViewController () <SelectRecipientViewControllerDelegate>

//<CountryCodeViewControllerDelegate,
//    UITextFieldDelegate,
//    UITableViewDataSource,
//    UITableViewDelegate>

//@property (nonatomic, readonly) OWSBlockingManager *blockingManager;
//@property (nonatomic, readonly) NSArray<NSString *> *blockedPhoneNumbers;
//
//@property (nonatomic) UIButton *countryNameButton;
//@property (nonatomic) UIButton *countryCodeButton;
//
//@property (nonatomic) UITextField *phoneNumberTextField;
//
//@property (nonatomic) UIButton *blockButton;
//
//@property (nonatomic) UITableView *contactsTableView;
//
//@property (nonatomic) NSString *callingCode;
//
//@property (nonatomic, readonly) OWSContactsManager *contactsManager;
//@property (nonatomic) NSArray<Contact *> *contacts;

@end

#pragma mark -

@implementation AddToBlockListViewController

- (void)loadView
{
    self.delegate = self;

    [super loadView];
    
    self.title = NSLocalizedString(@"SETTINGS_ADD_TO_BLOCK_LIST_TITLE", @"Title for the 'add to block list' view.");
}

- (NSString *)phoneNumberSectionTitle
{
    return NSLocalizedString(@"SETTINGS_ADD_TO_BLOCK_LIST_BLOCK_PHONE_NUMBER_TITLE",
        @"Title for the 'block phone number' section of the 'add to block list' view.");
}

- (NSString *)phoneNumberButtonText
{
    return NSLocalizedString(@"BLOCK_LIST_VIEW_BLOCK_BUTTON", @"A label for the block button in the block list view");
}

- (NSString *)contactsSectionTitle
{
    return NSLocalizedString(@"SETTINGS_ADD_TO_BLOCK_LIST_BLOCK_CONTACT_TITLE",
        @"Title for the 'block contact' section of the 'add to block list' view.");
}

- (void)phoneNumberWasSelected:(NSString *)phoneNumber
{
    OWSAssert(phoneNumber.length > 0);

    __weak AddToBlockListViewController *weakSelf = self;
    [BlockListUIUtils showBlockPhoneNumberActionSheet:phoneNumber
                                   fromViewController:self
                                      blockingManager:self.contactsViewHelper.blockingManager
                                      contactsManager:self.contactsViewHelper.contactsManager
                                      completionBlock:^(BOOL isBlocked) {
                                          if (isBlocked) {
                                              // Clear phone number text field if block succeeds.
                                              //                                              weakSelf.phoneNumberTextField.text
                                              //                                              = nil;
                                              [weakSelf.navigationController popViewControllerAnimated:YES];
                                          }
                                      }];
}

- (void)contactAccountWasSelected:(ContactAccount *)contactAccount
{
    OWSAssert(contactAccount);

    __weak AddToBlockListViewController *weakSelf = self;
    ContactsViewHelper *helper = self.contactsViewHelper;
    if ([helper isRecipientIdBlocked:contactAccount.recipientId]) {
        // TODO: Use the account label.
        NSString *displayName = [helper.contactsManager displayNameForContact:contactAccount.contact];
        UIAlertController *controller = [UIAlertController
            alertControllerWithTitle:NSLocalizedString(@"BLOCK_LIST_VIEW_ALREADY_BLOCKED_ALERT_TITLE",
                                         @"A title of the alert if user tries to block a "
                                         @"user who is already blocked.")
                             message:[NSString stringWithFormat:NSLocalizedString(@"BLOCK_LIST_VIEW_ALREADY_"
                                                                                  @"BLOCKED_ALERT_MESSAGE_"
                                                                                  @"FORMAT",
                                                                    @"A format for the message of the alert "
                                                                    @"if user tries to "
                                                                    @"block a user who is already blocked.  "
                                                                    @"Embeds {{the "
                                                                    @"blocked user's name or phone number}}."),
                                               displayName]
                      preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil]];
        [self presentViewController:controller animated:YES completion:nil];
        return;
    }
    [BlockListUIUtils showBlockContactAccountActionSheet:contactAccount
                                      fromViewController:self
                                         blockingManager:helper.blockingManager
                                         contactsManager:helper.contactsManager
                                         completionBlock:^(BOOL isBlocked) {
                                             if (isBlocked) {
                                                 [weakSelf.navigationController popViewControllerAnimated:YES];
                                             }
                                         }];
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
