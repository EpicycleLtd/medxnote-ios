//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "SelectRecipientViewController.h"
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

@property (nonatomic) UIButton *countryNameButton;
@property (nonatomic) UIButton *countryCodeButton;

@property (nonatomic) UITextField *phoneNumberTextField;

@property (nonatomic) UIButton *phoneNumberButton;

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

    [self createViews];

    [self populateDefaultCountryNameAndCode];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController.navigationBar setTranslucent:NO];
}

- (void)createViews
{
    OWSAssert(self.delegate);

    // Phone Number Section Title Row
    UIView *phoneNumberSectionTitleRow =
        [self createTitleRowWithText:[self.delegate phoneNumberSectionTitle] previousRow:nil];

    // Country Row
    UIView *countryRow = [self createRowWithHeight:60 previousRow:phoneNumberSectionTitleRow];

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

    // Phone Number Button Row
    UIView *phoneNumberButtonRow = [self createRowWithHeight:60 previousRow:borderRow2];

    // TODO: Eventually we should make a view factory that will allow us to
    //       create views with consistent appearance across the app and move
    //       towards a "design language."
    _phoneNumberButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _phoneNumberButton.titleLabel.font = [UIFont ows_mediumFontWithSize:16.f];
    [_phoneNumberButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_phoneNumberButton setBackgroundColor:[UIColor ows_signalBrandBlueColor]];
    _phoneNumberButton.clipsToBounds = YES;
    _phoneNumberButton.layer.cornerRadius = 3.f;
    [_phoneNumberButton setTitle:[self.delegate phoneNumberButtonText] forState:UIControlStateNormal];
    [_phoneNumberButton addTarget:self
                           action:@selector(phoneNumberButtonPressed:)
                 forControlEvents:UIControlEventTouchUpInside];
    [phoneNumberButtonRow addSubview:_phoneNumberButton];
    [_phoneNumberButton autoCenterInSuperview];
    [_phoneNumberButton autoSetDimension:ALDimensionWidth toSize:160];
    [_phoneNumberButton autoSetDimension:ALDimensionHeight toSize:40];

    // Separator Row
    UIView *separatorRow = [self createRowWithHeight:10 previousRow:phoneNumberButtonRow];

    // Contact Section Title Row
    UIView *contactSectionTitleRow =
        [self createTitleRowWithText:[self.delegate contactsSectionTitle] previousRow:separatorRow];

    _tableViewController = [OWSTableViewController new];
    _tableViewController.delegate = self;
    _tableViewController.contents = [OWSTableContents new];
    [self.view addSubview:self.tableViewController.view];
    [_tableViewController.view autoPinWidthToSuperview];
    [_tableViewController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:contactSectionTitleRow withOffset:10];
    [_tableViewController.view autoPinToBottomLayoutGuideOfViewController:self withInset:0];

    [self updateTableContents];

    [self updatephoneNumberButtonEnabling];
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

    [self updatephoneNumberButtonEnabling];
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

- (void)phoneNumberButtonPressed:(id)sender
{
    [self tryToSelectPhoneNumber];
}

- (void)tryToSelectPhoneNumber
{
    OWSAssert(self.delegate);

    if (![self hasValidPhoneNumber]) {
        OWSAssert(0);
        return;
    }

    NSString *possiblePhoneNumber = [self.callingCode stringByAppendingString:_phoneNumberTextField.text.digitsOnly];
    PhoneNumber *parsedPhoneNumber = [PhoneNumber tryParsePhoneNumberFromUserSpecifiedText:possiblePhoneNumber];
    OWSAssert(parsedPhoneNumber);

    [self.delegate phoneNumberWasSelected:[parsedPhoneNumber toE164]];
}

- (void)textFieldDidChange:(id)sender
{
    [self updatephoneNumberButtonEnabling];
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

- (void)updatephoneNumberButtonEnabling
{
    BOOL isEnabled = [self hasValidPhoneNumber];
    _phoneNumberButton.enabled = isEnabled;
    [_phoneNumberButton setBackgroundColor:(isEnabled ? [UIColor ows_signalBrandBlueColor] : [UIColor lightGrayColor])];
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

    [self updatephoneNumberButtonEnabling];

    return NO; // inform our caller that we took care of performing the change
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self tryToSelectPhoneNumber];
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
        NSArray<ContactAccount *> *allRecipientContactAccounts = helper.allRecipientContactAccounts;
        for (ContactAccount *contactAccount in allRecipientContactAccounts) {
            [contactAccountSection addItem:[OWSTableItem itemWithCustomCellBlock:^{
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
                                                   [weakSelf.delegate contactAccountWasSelected:contactAccount];
                                               }]];
        }
        [contents addSection:contactAccountSection];
    }

    self.tableViewController.contents = contents;
}

#pragma mark - OWSTableViewControllerDelegate

- (void)tableViewDidScroll
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
