//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "SelectRecipientViewController.h"
#import "BlockListUIUtils.h"
#import "ContactAccount.h"
#import "ContactTableViewCell.h"
#import "ContactsViewHelper.h"
#import "CountryCodeViewController.h"
#import "Environment.h"
#import "OWSContactsManager.h"
#import "OWSTableViewController.h"
#import "PhoneNumber.h"
#import "StringUtil.h"
#import "UIFont+OWS.h"
#import "UIUtil.h"
#import "UIView+OWS.h"
#import "ViewControllerUtils.h"
#import <SignalServiceKit/OWSBlockingManager.h>
#import <SignalServiceKit/PhoneNumberUtil.h>
#import <SignalServiceKit/TSAccountManager.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const kSelectRecipientViewControllerCellIdentifier = @"kSelectRecipientViewControllerCellIdentifier";

#pragma mark -

@interface SelectRecipientViewController () <CountryCodeViewControllerDelegate,
    ContactsViewHelperDelegate,
    OWSTableViewControllerDelegate,
    UITextFieldDelegate>

@property (nonatomic, readonly) ContactsViewHelper *contactsViewHelper;

@property (nonatomic) UIButton *countryNameButton;
@property (nonatomic) UIButton *countryCodeButton;

@property (nonatomic) UITextField *phoneNumberTextField;

@property (nonatomic) UIButton *blockButton;

@property (nonatomic, readonly) OWSTableViewController *tableViewController;

@property (nonatomic) NSString *callingCode;

@end

#pragma mark -

@implementation SelectRecipientViewController

- (void)loadView
{
    [super loadView];

    self.view.backgroundColor = [UIColor whiteColor];

    _contactsViewHelper = [ContactsViewHelper new];
    _contactsViewHelper.delegate = self;

    self.title = NSLocalizedString(@"SETTINGS_ADD_TO_BLOCK_LIST_TITLE", @"Title for the 'add to block list' view.");

    [self createViews];

    [self populateDefaultCountryNameAndCode];

    //    [self addNotificationListeners];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController.navigationBar setTranslucent:NO];
}

//- (void)addNotificationListeners
//{
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(blockedPhoneNumbersDidChange:)
//                                                 name:kNSNotificationName_BlockedPhoneNumbersDidChange
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(signalRecipientsDidChange:)
//                                                 name:OWSContactsManagerSignalRecipientsDidChangeNotification
//                                               object:nil];
//}
//
//- (void)dealloc
//{
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}

- (void)createViews
{

    // Block Phone Number Title Row
    UIView *blockPhoneNumberTitleRow =
        [self createTitleRowWithText:NSLocalizedString(@"SETTINGS_ADD_TO_BLOCK_LIST_BLOCK_PHONE_NUMBER_TITLE",
                                         @"Title for the 'block phone number' section of the 'add to block list' view.")
                         previousRow:nil];

    // Country Row
    UIView *countryRow = [self createRowWithHeight:60 previousRow:blockPhoneNumberTitleRow];

    _countryNameButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _countryNameButton.titleLabel.font = [UIFont ows_mediumFontWithSize:16.f];
    [_countryNameButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_countryNameButton
        setTitle:NSLocalizedString(@"REGISTRATION_DEFAULT_COUNTRY_NAME", @"Label for the country code field")
        forState:UIControlStateNormal];
    [_countryNameButton addTarget:self
                           action:@selector(showCountryCodeView:)
                 forControlEvents:UIControlEventTouchUpInside];
    [countryRow addSubview:_countryNameButton];
    [_countryNameButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.f];
    [_countryNameButton autoVCenterInSuperview];

    _countryCodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _countryCodeButton.titleLabel.font = [UIFont ows_mediumFontWithSize:16.f];
    _countryCodeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_countryCodeButton setTitleColor:[UIColor ows_signalBrandBlueColor] forState:UIControlStateNormal];
    [_countryCodeButton addTarget:self
                           action:@selector(showCountryCodeView:)
                 forControlEvents:UIControlEventTouchUpInside];
    [countryRow addSubview:_countryCodeButton];
    [_countryCodeButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16.f];
    [_countryCodeButton autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:_countryNameButton withOffset:0];
    [_countryCodeButton autoVCenterInSuperview];

    // Border Row
    UIView *borderRow1 = [self createRowWithHeight:1 previousRow:countryRow];
    UIColor *borderColor = [UIColor colorWithRed:0.75f green:0.75f blue:0.75f alpha:1.f];
    borderRow1.backgroundColor = borderColor;

    // Phone Number Row
    UIView *phoneNumberRow = [self createRowWithHeight:60 previousRow:borderRow1];

    UILabel *phoneNumberLabel = [UILabel new];
    phoneNumberLabel.font = [UIFont ows_mediumFontWithSize:16.f];
    phoneNumberLabel.textColor = [UIColor blackColor];
    phoneNumberLabel.text
        = NSLocalizedString(@"REGISTRATION_PHONENUMBER_BUTTON", @"Label for the phone number textfield");
    [phoneNumberRow addSubview:phoneNumberLabel];
    [phoneNumberLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.f];
    [phoneNumberLabel autoVCenterInSuperview];

    _phoneNumberTextField = [UITextField new];
    _phoneNumberTextField.font = [UIFont ows_mediumFontWithSize:16.f];
    _phoneNumberTextField.textAlignment = NSTextAlignmentRight;
    _phoneNumberTextField.textColor = [UIColor ows_signalBrandBlueColor];
    _phoneNumberTextField.placeholder = NSLocalizedString(
        @"REGISTRATION_ENTERNUMBER_DEFAULT_TEXT", @"Placeholder text for the phone number textfield");
    _phoneNumberTextField.keyboardType = UIKeyboardTypeNumberPad;
    _phoneNumberTextField.delegate = self;
    [_phoneNumberTextField addTarget:self
                              action:@selector(textFieldDidChange:)
                    forControlEvents:UIControlEventEditingChanged];
    [phoneNumberRow addSubview:_phoneNumberTextField];
    [_phoneNumberTextField autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16.f];
    [_phoneNumberTextField autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:phoneNumberLabel withOffset:0];
    [_phoneNumberTextField autoVCenterInSuperview];

    // Border Row
    UIView *borderRow2 = [self createRowWithHeight:1 previousRow:phoneNumberRow];
    borderRow2.backgroundColor = borderColor;

    // Block Button Row
    UIView *blockButtonRow = [self createRowWithHeight:60 previousRow:borderRow2];

    // TODO: Eventually we should make a view factory that will allow us to
    //       create views with consistent appearance across the app and move
    //       towards a "design language."
    _blockButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _blockButton.titleLabel.font = [UIFont ows_mediumFontWithSize:16.f];
    [_blockButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_blockButton setBackgroundColor:[UIColor ows_signalBrandBlueColor]];
    _blockButton.clipsToBounds = YES;
    _blockButton.layer.cornerRadius = 3.f;
    [_blockButton setTitle:NSLocalizedString(
                               @"BLOCK_LIST_VIEW_BLOCK_BUTTON", @"A label for the block button in the block list view")
                  forState:UIControlStateNormal];
    [_blockButton addTarget:self action:@selector(blockButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [blockButtonRow addSubview:_blockButton];
    [_blockButton autoCenterInSuperview];
    [_blockButton autoSetDimension:ALDimensionWidth toSize:160];
    [_blockButton autoSetDimension:ALDimensionHeight toSize:40];

    // Separator Row
    UIView *separatorRow = [self createRowWithHeight:10 previousRow:blockButtonRow];

    // Block Contact Title Row
    UIView *blockContactTitleRow =
        [self createTitleRowWithText:NSLocalizedString(@"SETTINGS_ADD_TO_BLOCK_LIST_BLOCK_CONTACT_TITLE",
                                         @"Title for the 'block contact' section of the 'add to block list' view.")
                         previousRow:separatorRow];

    _tableViewController = [OWSTableViewController new];
    _tableViewController.delegate = self;
    _tableViewController.contents = [OWSTableContents new];
    [self.view addSubview:self.tableViewController.view];
    [_tableViewController.view autoPinWidthToSuperview];
    [_tableViewController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:blockContactTitleRow withOffset:10];
    [_tableViewController.view autoPinToBottomLayoutGuideOfViewController:self withInset:0];

    [self updateTableContents];

    [self updateBlockButtonEnabling];
}

- (UIView *)createTitleRowWithText:(NSString *)text previousRow:(nullable UIView *)previousRow
{
    UIView *row = [self createRowWithHeight:40 previousRow:previousRow];

    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont ows_mediumFontWithSize:20.f];
    label.textColor = [UIColor colorWithWhite:0.3f alpha:1.f];
    label.textAlignment = NSTextAlignmentCenter;
    [row addSubview:label];
    [label autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.f];
    [label autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20.f];
    [label autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    return row;
}

- (UIView *)createRowWithHeight:(CGFloat)height previousRow:(nullable UIView *)previousRow
{
    UIView *row = [UIView new];
    [self.view addSubview:row];
    [row autoPinWidthToSuperview];
    if (previousRow) {
        [row autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousRow withOffset:0];
    } else {
        [row autoPinToTopLayoutGuideOfViewController:self withInset:0];
    }
    [row autoSetDimension:ALDimensionHeight toSize:height];
    return row;
}

#pragma mark - Country

- (void)populateDefaultCountryNameAndCode
{
    NSLocale *locale = NSLocale.currentLocale;
    NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
    NSNumber *callingCode = [[PhoneNumberUtil sharedUtil].nbPhoneNumberUtil getCountryCodeForRegion:countryCode];
    NSString *countryName = [PhoneNumberUtil countryNameFromCountryCode:countryCode];
    [self updateCountryWithName:countryName
                    callingCode:[NSString stringWithFormat:@"%@%@", COUNTRY_CODE_PREFIX, callingCode]
                    countryCode:countryCode];
}

- (void)updateCountryWithName:(NSString *)countryName
                  callingCode:(NSString *)callingCode
                  countryCode:(NSString *)countryCode
{

    _callingCode = callingCode;

    NSString *title = [NSString stringWithFormat:@"%@ (%@)", callingCode, countryCode.uppercaseString];
    [_countryCodeButton setTitle:title forState:UIControlStateNormal];
    [_countryCodeButton layoutSubviews];
}

- (void)setCallingCode:(NSString *)callingCode
{
    _callingCode = callingCode;

    [self updateBlockButtonEnabling];
}

#pragma mark - Actions

- (void)showCountryCodeView:(id)sender
{
    CountryCodeViewController *countryCodeController = [[UIStoryboard storyboardWithName:@"Registration" bundle:NULL]
        instantiateViewControllerWithIdentifier:@"CountryCodeViewController"];
    countryCodeController.delegate = self;
    countryCodeController.shouldDismissWithoutSegue = YES;
    UINavigationController *navigationController =
        [[UINavigationController alloc] initWithRootViewController:countryCodeController];
    [self presentViewController:navigationController animated:YES completion:[UIUtil modalCompletionBlock]];
}

- (void)blockButtonPressed:(id)sender
{
    [self tryToBlockPhoneNumber];
}

- (void)tryToBlockPhoneNumber
{
    if (![self hasValidPhoneNumber]) {
        OWSAssert(0);
        return;
    }

    NSString *possiblePhoneNumber = [self.callingCode stringByAppendingString:_phoneNumberTextField.text.digitsOnly];
    PhoneNumber *parsedPhoneNumber = [PhoneNumber tryParsePhoneNumberFromUserSpecifiedText:possiblePhoneNumber];
    OWSAssert(parsedPhoneNumber);

    __weak SelectRecipientViewController *weakSelf = self;
    [BlockListUIUtils showBlockPhoneNumberActionSheet:[parsedPhoneNumber toE164]
                                   fromViewController:self
                                      blockingManager:self.contactsViewHelper.blockingManager
                                      contactsManager:self.contactsViewHelper.contactsManager
                                      completionBlock:^(BOOL isBlocked) {
                                          if (isBlocked) {
                                              // Clear phone number text field if block succeeds.
                                              weakSelf.phoneNumberTextField.text = nil;
                                              [weakSelf.navigationController popViewControllerAnimated:YES];
                                          }
                                      }];
}

- (void)textFieldDidChange:(id)sender
{
    [self updateBlockButtonEnabling];
}

// TODO: We could also do this in registration view.
- (BOOL)hasValidPhoneNumber
{
    if (!self.callingCode) {
        return NO;
    }
    NSString *possiblePhoneNumber = [self.callingCode stringByAppendingString:_phoneNumberTextField.text.digitsOnly];
    PhoneNumber *parsedPhoneNumber = [PhoneNumber tryParsePhoneNumberFromUserSpecifiedText:possiblePhoneNumber];
    // It'd be nice to use [PhoneNumber isValid] but it always returns false for some countries
    // (like afghanistan) and there doesn't seem to be a good way to determine beforehand
    // which countries it can validate for without forking libPhoneNumber.
    return parsedPhoneNumber && parsedPhoneNumber.toE164.length > 1;
}

- (void)updateBlockButtonEnabling
{
    BOOL isEnabled = [self hasValidPhoneNumber];
    _blockButton.enabled = isEnabled;
    [_blockButton setBackgroundColor:(isEnabled ? [UIColor ows_signalBrandBlueColor] : [UIColor lightGrayColor])];
}

#pragma mark - CountryCodeViewControllerDelegate

- (void)countryCodeViewController:(CountryCodeViewController *)vc
             didSelectCountryCode:(NSString *)countryCode
                      countryName:(NSString *)countryName
                      callingCode:(NSString *)callingCode
{

    [self updateCountryWithName:countryName callingCode:callingCode countryCode:countryCode];

    [self textField:_phoneNumberTextField shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:@""];
}

#pragma mark - UITextFieldDelegate

// TODO: This logic resides in both RegistrationViewController and here.
//       We should refactor it out into a utility function.
- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)insertionText
{
    [ViewControllerUtils phoneNumberTextField:textField
                shouldChangeCharactersInRange:range
                            replacementString:insertionText
                                  countryCode:_callingCode];

    [self updateBlockButtonEnabling];

    return NO; // inform our caller that we took care of performing the change
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self tryToBlockPhoneNumber];
    return NO;
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];

    __weak SelectRecipientViewController *weakSelf = self;
    ContactsViewHelper *helper = self.contactsViewHelper;

    BOOL hasNoContacts = helper.allRecipientContacts.count == 0;
    if (hasNoContacts) {
        // No Contacts

        OWSTableSection *section = [OWSTableSection new];
        [section addItem:[OWSTableItem itemWithCustomCellBlock:^{
            UITableViewCell *cell = [UITableViewCell new];
            cell.textLabel.text = NSLocalizedString(
                @"SETTINGS_BLOCK_LIST_NO_CONTACTS", @"A label that indicates the user has no Signal contacts.");
            cell.textLabel.font = [UIFont ows_regularFontWithSize:15.f];
            cell.textLabel.textColor = [UIColor colorWithWhite:0.5f alpha:1.f];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
                                                   actionBlock:nil]];
        [contents addSection:section];
    } else {
        // Contacts

        OWSTableSection *contactAccountSection = [OWSTableSection new];
        contactAccountSection.headerTitle = NSLocalizedString(
            @"BLOCK_LIST_VIEW_CONTACTS_SECTION_TITLE", @"A title for the contacts section of the block list view.");
        contactAccountSection.headerTitle = NSLocalizedString(
            @"EDIT_GROUP_CONTACTS_SECTION_TITLE", @"a title for the contacts section of the 'new/update group' view.");
        NSArray<ContactAccount *> *allRecipientContactAccounts = helper.allRecipientContactAccounts;
        if (allRecipientContactAccounts.count > 0) {
            for (ContactAccount *contactAccount in allRecipientContactAccounts) {
                [contactAccountSection
                    addItem:
                        [OWSTableItem itemWithCustomCellBlock:^{
                            SelectRecipientViewController *strongSelf = weakSelf;
                            if (!strongSelf) {
                                return (ContactTableViewCell *)nil;
                            }

                            ContactTableViewCell *cell = [ContactTableViewCell new];
                            BOOL isBlocked = [helper isRecipientIdBlocked:contactAccount.recipientId];
                            if (isBlocked) {
                                cell.accessoryMessage = NSLocalizedString(
                                    @"CONTACT_CELL_IS_BLOCKED", @"An indicator that a contact has been blocked.");
                            } else {
                                OWSAssert(cell.accessoryMessage == nil);
                            }
                            // TODO: Use the account label.
                            [cell configureWithContact:contactAccount.contact contactsManager:helper.contactsManager];
                            return cell;
                        }
                            customRowHeight:[ContactTableViewCell rowHeight]
                            actionBlock:^{
                                __weak SelectRecipientViewController *weakSelf = self;
                                if ([helper isRecipientIdBlocked:contactAccount.recipientId]) {
                                    // TODO: Use the account label.
                                    NSString *displayName =
                                        [helper.contactsManager displayNameForContact:contactAccount.contact];
                                    UIAlertController *controller = [UIAlertController
                                        alertControllerWithTitle:NSLocalizedString(
                                                                     @"BLOCK_LIST_VIEW_ALREADY_BLOCKED_ALERT_TITLE",
                                                                     @"A title of the alert if user tries to block a "
                                                                     @"user who is already blocked.")
                                                         message:[NSString
                                                                     stringWithFormat:
                                                                         NSLocalizedString(@"BLOCK_LIST_VIEW_ALREADY_"
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
                                                                             [weakSelf.navigationController
                                                                                 popViewControllerAnimated:YES];
                                                                         }
                                                                     }];
                            }]];
            }
        } else {
            [contactAccountSection addItem:[OWSTableItem itemWithCustomCellBlock:^{
                UITableViewCell *cell = [UITableViewCell new];
                cell.textLabel.text = NSLocalizedString(
                    @"SETTINGS_BLOCK_LIST_NO_CONTACTS", @"A label that indicates the user has no Signal contacts.");
                cell.textLabel.font = [UIFont ows_regularFontWithSize:15.f];
                cell.textLabel.textColor = [UIColor colorWithWhite:0.5f alpha:1.f];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                return cell;
            }
                                                                     actionBlock:nil]];
        }
        [contents addSection:contactAccountSection];
    }

    self.tableViewController.contents = contents;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.phoneNumberTextField resignFirstResponder];
}

#pragma mark - ContactsViewHelperDelegate

- (void)contactsViewHelperDidUpdateContacts
{
    [self updateTableContents];
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
