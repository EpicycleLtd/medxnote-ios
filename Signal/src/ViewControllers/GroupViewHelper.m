//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "GroupViewHelper.h"
//#import "BlockListUIUtils.h"
//#import "ContactTableViewCell.h"
//#import "ContactsViewHelper.h"
//#import "Environment.h"
//#import "FunctionalUtil.h"
//#import "TSGroupModel.h"
//#import "TSGroupThread.h"
//#import "OWSAnyTouchGestureRecognizer.h"
//#import "PhoneNumber.h"
//#import "OWSContactsManager.h"
//#import "OWSTableViewController.h"
//#import "SecurityUtils.h"
//#import "SignalKeyingStorage.h"
//#import "SignalsViewController.h"
//#import "TSOutgoingMessage.h"
//#import "UIImage+normalizeImage.h"
#import "UIUtil.h"
//#import "UIFont+OWS.h"
//#import "UIView+OWS.h"
#import <MobileCoreServices/UTCoreTypes.h>
//#import <SignalServiceKit/MimeTypeUtil.h>
//#import <SignalServiceKit/NSDate+millisecondTimeStamp.h>
//#import <SignalServiceKit/OWSBlockingManager.h>
//#import <SignalServiceKit/OWSMessageSender.h>
//#import <SignalServiceKit/TSAccountManager.h>
#import <SignalServiceKit/PhoneNumber.h>
#import <SignalServiceKit/TSGroupModel.h>
#import <SignalServiceKit/TSGroupThread.h>
#import <SignalServiceKit/TSThread.h>

// TODO
//#import "OWSAvatarBuilder.h"

NS_ASSUME_NONNULL_BEGIN

// typedef NS_ENUM(NSInteger, GroupMemberType) { GroupMemberTypeExisting, GroupMemberTypeProposed };
//
//@interface GroupMember : NSObject
//
//@property (nonatomic, readonly) GroupMemberType groupMemberType;
//
//// An E164 value identifying the signal account.
//@property (nonatomic, readonly) NSString *recipientId;
//
////// This property is optional and will not be set for non-contacts.
////@property (nonatomic, readonly) Contact *contact;
//
//@end
//
//#pragma mark -
//
//@implementation GroupMember
//
//@end

#pragma mark -

@interface GroupViewHelper () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

//@property (nonatomic, readonly) TSGroupThread *thread;
//@property (nonatomic, readonly) OWSMessageSender *messageSender;
//@property (nonatomic, readonly) OWSContactsManager *contactsManager;
//@property (nonatomic, readonly) ContactsViewHelper *helper;
//
//@property (nonatomic, readonly) OWSTableViewController *tableViewController;

//@property (nonatomic, nullable) UIImage *groupImage;
//@property (nonatomic, nullable) NSSet<NSString *> *previousMemberRecipientIds;
//@property (nonatomic, nullable) NSMutableArray<NSString *> *memberRecipientIds;

@end

#pragma mark -

@implementation GroupViewHelper

//- (instancetype)init
//{
//    self = [super init];
//    if (!self) {
//        return self;
//    }
//
//    [self commonInit];
//
//    return self;
//}
//
//- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
//{
//    self = [super initWithCoder:aDecoder];
//    if (!self) {
//        return self;
//    }
//
//    [self commonInit];
//
//    return self;
//}
//
//- (void)commonInit
//{
//    _messageSender = [Environment getCurrent].messageSender;
//    _helper = [ContactsViewHelper new];
//    _contactsManager = [Environment getCurrent].contactsManager;
//    //
//    //    _blockingManager = [OWSBlockingManager sharedManager];
//    //    self.blockedPhoneNumbers = [_blockingManager blockedPhoneNumbers];
//
//    self.memberRecipientIds = [NSMutableArray new];
//
//    //    [self observeNotifications];
//}
//
////- (void)observeNotifications
////{
////    [[NSNotificationCenter defaultCenter] addObserver:self
////                                             selector:@selector(signalRecipientsDidChange:)
////                                                 name:OWSContactsManagerSignalRecipientsDidChangeNotification
////                                               object:nil];
////    [[NSNotificationCenter defaultCenter] addObserver:self
////                                             selector:@selector(blockedPhoneNumbersDidChange:)
////                                                 name:kNSNotificationName_BlockedPhoneNumbersDidChange
////                                               object:nil];
////}
//
////- (void)dealloc
////{
////    [[NSNotificationCenter defaultCenter] removeObserver:self];
////}
////
////- (void)signalRecipientsDidChange:(NSNotification *)notification {
////    dispatch_async(dispatch_get_main_queue(), ^{
////        [self updateContacts];
////    });
////}
////
////- (void)blockedPhoneNumbersDidChange:(id)notification
////{
////    dispatch_async(dispatch_get_main_queue(), ^{
////        self.blockedPhoneNumbers = [_blockingManager blockedPhoneNumbers];
////
////        [self updateContacts];
////    });
////}
//
//#pragma mark - View Lifecycle
//
//- (void)loadView
//{
//    UIView *view = [UIView new];
//    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    self.view = view;
//    //    [self.view autoPinWidthToSuperview];
//    //    [self.view autoPinToTopLayoutGuideOfViewController:self withInset:0.f];
//    //    [self.view autoPinToBottomLayoutGuideOfViewController:self withInset:0.f];
//
//    // First section.
//
//    UIView *firstSection = [self firstSectionHeader];
//    [self.view addSubview:firstSection];
//    [firstSection autoSetDimension:ALDimensionHeight toSize:100.f];
//    [firstSection autoPinWidthToSuperview];
//    [firstSection autoPinEdgeToSuperviewEdge:ALEdgeTop];
//
//    _tableViewController = [OWSTableViewController new];
//    _tableViewController.contents = [OWSTableContents new];
//    [self.view addSubview:self.tableViewController.view];
//    [_tableViewController.view autoPinWidthToSuperview];
//    [_tableViewController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:firstSection];
//    [_tableViewController.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//
//    //    [self updateContacts];
//    //    [self updateGroupMembers];
//    [self updateTableContents];
//}

//- (TSGroupThread *)groupThread
//{
//    OWSAssert(self.thread);
//
//    if ([self.thread isKindOfClass:[TSGroupThread class]]) {
//        return (TSGroupThread *) self.thread;
//    }
//
//    return nil;
//}
//
//- (UIView *)threadViewHeader:(BOOL)isEditing
//{
//    // TODO: Observe remote changes to the group model.
//
//    UIView *firstSectionHeader = [UIView new];
//    firstSectionHeader.backgroundColor = [UIColor whiteColor];
//    UIView *threadInfoView = [UIView new];
//    [firstSectionHeader addSubview:threadInfoView];
//    [threadInfoView autoPinWidthToSuperviewWithMargin:16.f];
//    [threadInfoView autoPinHeightToSuperviewWithMargin:16.f];
//
//    const CGFloat kAvatarSize = 68.f;
//    UIImageView *avatarView = [UIImageView new];
//    _avatarView = avatarView;
//    avatarView.layer.borderColor = UIColor.clearColor.CGColor;
//    avatarView.layer.masksToBounds = YES;
//    avatarView.layer.cornerRadius = kAvatarSize / 2.0f;
//    avatarView.contentMode = UIViewContentModeScaleAspectFill;
//    [threadInfoView addSubview:avatarView];
//    [avatarView autoVCenterInSuperview];
//    [avatarView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
//    [avatarView autoSetDimension:ALDimensionWidth toSize:kAvatarSize];
//    [avatarView autoSetDimension:ALDimensionHeight toSize:kAvatarSize];
//    // TODO:
////    [self updateAvatarView];
//
//    if (self.thread.groupModel) {
//        self.groupImage = self.thread.groupModel.groupImage;
//    } else {
//        UIImage *avatar = [OWSAvatarBuilder buildImageForThread:self.thread contactsManager:self.contactsManager];
//        OWSAssert(avatar);
//    }
//
//    if (isEditing)
//    {
//        UITextField *threadNameTextField = [UITextField new];
//        _threadNameTextField = threadNameTextField;
//        if (self.thread) {
//            _threadNameTextField.text = self.thread.groupModel.groupName;
//        }
//        threadNameTextField.textColor = [UIColor blackColor];
//        threadNameTextField.font = [UIFont ows_dynamicTypeTitle2Font];
//        threadNameTextField.placeholder = NSLocalizedString(@"NEW_GROUP_NAMEGROUP_REQUEST_DEFAULT", @"");
//        threadNameTextField.delegate = self;
//        [threadInfoView addSubview:threadNameTextField];
//        [threadNameTextField autoVCenterInSuperview];
//        [threadNameTextField autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:avatarView withOffset:16.f];
//        [threadNameTextField autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16.f];
//
//        [avatarView addGestureRecognizer:[[OWSAnyTouchGestureRecognizer alloc] initWithTarget:self
//                                                                                       action:@selector(avatarTouched:)]];
//        avatarView.userInteractionEnabled = YES;
//    } else {
//        UIView *threadNameView = [UIView new];
//        [threadInfoView addSubview:threadNameView];
//        [threadNameView autoVCenterInSuperview];
//        [threadNameView autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:avatarView withOffset:16.f];
//        [threadNameView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16.f];
//
//        UILabel *threadTitleLabel = [UILabel new];
//        threadTitleLabel.text = self.threadName;
//        threadTitleLabel.textColor = [UIColor blackColor];
//        threadTitleLabel.font = [UIFont ows_dynamicTypeTitle2Font];
//        threadTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
//        [threadNameView addSubview:threadTitleLabel];
//        [threadTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
//        [threadTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft];
//
//        if (![self isGroupThread] && ![self.thread.name isEqualToString:self.thread.contactIdentifier]) {
//            NSString *subtitle =
//            [PhoneNumber
//            bestEffortFormatPartialUserSpecifiedTextToLookLikeAPhoneNumber:self.thread.contactIdentifier];
//
//            UILabel *threadSubtitleLabel = [UILabel new];
//            threadSubtitleLabel.text = subtitle;
//            threadSubtitleLabel.textColor = [UIColor blackColor];
//            // TODO:
//            threadSubtitleLabel.font = [UIFont ows_regularFontWithSize:12.f];
//            threadSubtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
//            [threadNameView addSubview:threadSubtitleLabel];
//            [threadSubtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//            [threadSubtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:threadTitleLabel];
//            [threadSubtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft];
//        } else {
//            [threadTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
//        }
//
//        [firstSectionHeader
//         addGestureRecognizer:[[OWSAnyTouchGestureRecognizer alloc] initWithTarget:self
//                                                                            action:@selector(conversationNameTouched:)]];
//        firstSectionHeader.userInteractionEnabled = YES;
//    }
//
//    return firstSectionHeader;
//}
//
//- (void)avatarTouched:(UIGestureRecognizer *)sender
//{
//    if (sender.state == UIGestureRecognizerStateRecognized) {
//        [self showChangeGroupAvatarUI:nil];
//    }
//}

//#pragma mark - Table Contents
//
//- (void)updateTableContents
//{
//    OWSTableContents *contents = [OWSTableContents new];
//
//    // TODO: Copy
//    contents.title
//        = (self.thread ? NSLocalizedString(@"CONVERSATION_SETTINGS", @"title for conversation settings screen")
//                       : NSLocalizedString(@"CONVERSATION_SETTINGS", @"title for conversation settings screen"));
//
//    __weak GroupViewHelper *weakSelf = self;
//    ContactsViewHelper *helper = self.helper;
//
//    // Group Members
//
//    if (self.memberRecipientIds.count > 0) {
//        OWSTableSection *membersSection = [OWSTableSection new];
//        membersSection.headerTitle = NSLocalizedString(
//            @"EDIT_GROUP_MEMBERS_SECTION_TITLE", @"a title for the members section of the 'new/update group' view.");
//
//        for (NSString *recipientId in [self.memberRecipientIds sortedArrayUsingSelector:@selector(compare:)]) {
//            [membersSection addItem:[OWSTableItem itemWithCustomCellBlock:^{
//                GroupViewHelper *strongSelf = weakSelf;
//                if (!strongSelf) {
//                    return (ContactTableViewCell *)nil;
//                }
//
//                ContactTableViewCell *cell = [ContactTableViewCell new];
//                ContactAccount *contactAccount = [helper contactAccountForRecipientId:recipientId];
//                BOOL isPreviousMember = [strongSelf.previousMemberRecipientIds containsObject:recipientId];
//                BOOL isCurrentMember = YES;
//                BOOL isBlocked = [helper isRecipientIdBlocked:recipientId];
//                if ((strongSelf.thread && isPreviousMember) || (!strongSelf.thread && isCurrentMember)) {
//                    // In the "members" section, we label "previous" members as members when
//                    // editing an existing group and we label "new" members as members creating a new group.
//                    //                    cell.accessoryMessage
//                    //                    = NSLocalizedString(@"EDIT_GROUP_CURRENT_MEMBER_LABEL", @"An indicator that
//                    a
//                    //                    user is a current member of the group.");
//                } else if (strongSelf.thread && isCurrentMember) {
//                    // In the "members" section, we label "new" members as such when editing an existing group.
//                    cell.accessoryMessage = NSLocalizedString(
//                        @"EDIT_GROUP_NEW_MEMBER_LABEL", @"An indicator that a user is a new member of the group.");
//                } else if (isBlocked) {
//                    cell.accessoryMessage = NSLocalizedString(
//                        @"CONTACT_CELL_IS_BLOCKED", @"An indicator that a contact has been blocked.");
//                } else {
//                    OWSAssert(cell.accessoryMessage == nil);
//                }
//
//                if (contactAccount) {
//                    // TODO: Use the account label.
//                    [cell configureWithContact:contactAccount.contact contactsManager:strongSelf.contactsManager];
//                } else {
//                    [cell configureWithRecipientId:recipientId contactsManager:strongSelf.contactsManager];
//                }
//
//                return cell;
//            }
//                                                          customRowHeight:[ContactTableViewCell rowHeight]
//                                                              actionBlock:^{
//                                                                  // TODO:
//                                                              }]];
//        }
//        [contents addSection:membersSection];
//    }
//
//    // Contacts
//
//    OWSTableSection *contactAccountSection = [OWSTableSection new];
//    contactAccountSection.headerTitle = NSLocalizedString(
//        @"EDIT_GROUP_CONTACTS_SECTION_TITLE", @"a title for the contacts section of the 'new/update group' view.");
//    NSArray<ContactAccount *> *allRecipientContactAccounts = self.helper.allRecipientContactAccounts;
//    if (allRecipientContactAccounts.count > 0) {
//        for (ContactAccount *contactAccount in allRecipientContactAccounts) {
//            [contactAccountSection
//                addItem:
//                    [OWSTableItem
//                        itemWithCustomCellBlock:^{
//                            GroupViewHelper *strongSelf = weakSelf;
//                            if (!strongSelf) {
//                                return (ContactTableViewCell *)nil;
//                            }
//
//                            ContactTableViewCell *cell = [ContactTableViewCell new];
//                            BOOL isBlocked = [helper isContactBlocked:contactAccount.contact];
//                            if (isBlocked) {
//                                cell.accessoryMessage = NSLocalizedString(
//                                    @"CONTACT_CELL_IS_BLOCKED", @"An indicator that a contact has been blocked.");
//                            } else {
//                                OWSAssert(cell.accessoryMessage == nil);
//                            }
//                            // TODO: Use the account label.
//                            [cell configureWithContact:contactAccount.contact
//                                       contactsManager:strongSelf.contactsManager];
//
//                            return cell;
//                        }
//                                customRowHeight:[ContactTableViewCell rowHeight]
//                                    actionBlock:^{
//                                        // <#code#>
//                                    }]];
//        }
//    } else {
//        [contactAccountSection addItem:[OWSTableItem itemWithCustomCellBlock:^{
//            UITableViewCell *cell = [UITableViewCell new];
//            cell.textLabel.text = NSLocalizedString(
//                @"SETTINGS_BLOCK_LIST_NO_CONTACTS", @"A label that indicates the user has no Signal contacts.");
//            cell.textLabel.font = [UIFont ows_regularFontWithSize:15.f];
//            cell.textLabel.textColor = [UIColor colorWithWhite:0.5f alpha:1.f];
//            cell.textLabel.textAlignment = NSTextAlignmentCenter;
//            return cell;
//        }
//                                                                 actionBlock:nil]];
//    }
//    [contents addSection:contactAccountSection];
//
//    //    ContactAccount *contactAccount
//    self.tableViewController.contents = contents;
//}
//
//#pragma mark - Methods
//
////- (void)updateContacts {
////    AssertIsOnMainThread();
////
////    // Snapshot selection state.
////    NSMutableSet *selectedContacts = [NSMutableSet set];
////    for (NSIndexPath *indexPath in [self.tableView indexPathsForSelectedRows]) {
////        Contact *contact = self.contacts[(NSUInteger)indexPath.row];
////        [selectedContacts addObject:contact];
////    }
////
////    self.contacts = [self filteredContacts];
////
////    [self.tableView reloadData];
////
////    // Restore selection state.
////    for (Contact *contact in selectedContacts) {
////        if ([self.contacts containsObject:contact]) {
////            NSInteger row = (NSInteger)[self.contacts indexOfObject:contact];
////            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]
////                                        animated:NO
////                                  scrollPosition:UITableViewScrollPositionNone];
////        }
////    }
////}
////
////- (BOOL)isContactHidden:(Contact *)contact
////{
////    if (contact.parsedPhoneNumbers.count < 1) {
////        // Hide contacts without any valid phone numbers.
////        return YES;
////    }
////
////    if ([self isCurrentUserContact:contact]) {
////        // We never want to add ourselves to a group.
////        return YES;
////    }
////
////    return NO;
////}
////
////- (BOOL)isContactBlocked:(Contact *)contact
////{
////    if (contact.parsedPhoneNumbers.count < 1) {
////        // Hide contacts without any valid phone numbers.
////        return NO;
////    }
////
////    for (PhoneNumber *phoneNumber in contact.parsedPhoneNumbers) {
////        if ([_blockedPhoneNumbers containsObject:phoneNumber.toE164]) {
////            return YES;
////        }
////    }
////
////    return NO;
////}
////
////- (BOOL)isCurrentUserContact:(Contact *)contact
////{
////    for (PhoneNumber *phoneNumber in contact.parsedPhoneNumbers) {
////        if ([[phoneNumber toE164] isEqualToString:[TSAccountManager localNumber]]) {
////            return YES;
////        }
////    }
////
////    return NO;
////}
////
////- (NSArray<Contact *> *_Nonnull)filteredContacts
////{
////    NSMutableArray<Contact *> *result = [NSMutableArray new];
////    for (Contact *contact in self.contactsManager.signalContacts) {
////        if (![self isContactHidden:contact]) {
////            [result addObject:contact];
////        }
////    }
////    return [result copy];
////}
////
////- (BOOL)isContactInGroup:(Contact *)contact
////{
////    for (PhoneNumber *phoneNumber in contact.parsedPhoneNumbers) {
////        if (self.thread != nil && self.thread.groupModel.groupMemberIds) {
////            // TODO: What if a contact has two phone numbers that
////            // correspond to signal account and one has been added
////            // to the group but not the other?
////            if ([self.thread.groupModel.groupMemberIds containsObject:[phoneNumber toE164]]) {
////                return YES;
////            }
////        }
////    }
////
////    return NO;
////}
//
//- (void)configWithThread:(TSGroupThread *)thread
//{
//    _thread = thread;
//
//    if (self.thread.groupModel.groupMemberIds) {
//        [self.memberRecipientIds addObjectsFromArray:self.thread.groupModel.groupMemberIds];
//        self.previousMemberRecipientIds = [NSSet setWithArray:self.thread.groupModel.groupMemberIds];
//    }
//}
//
////- (void)viewDidLoad {
////    [super viewDidLoad];
////    [self.navigationController.navigationBar setTranslucent:NO];
////
////    self.contacts = [self filteredContacts];
////
////    self.tableView.tableHeaderView.frame = CGRectMake(0, 0, 400, 44);
////    self.tableView.tableHeaderView       = self.tableView.tableHeaderView;
////
////    [self initializeDelegates];
////    [self initializeTableView];
////    [self initializeKeyboardHandlers];
////
////    if (self.thread == nil) {
////        self.navigationItem.rightBarButtonItem =
////            [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"add-conversation"]
////                                                       imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
////                                             style:UIBarButtonItemStylePlain
////                                            target:self
////                                            action:@selector(createGroup)];
////        self.navigationItem.rightBarButtonItem.imageInsets = UIEdgeInsetsMake(0, -10, 0, 10);
////        self.navigationItem.title                          = NSLocalizedString(@"NEW_GROUP_DEFAULT_TITLE", @"");
////        self.navigationItem.rightBarButtonItem.accessibilityLabel =
///NSLocalizedString(@"FINISH_GROUP_CREATION_LABEL", /        @"Accessibilty label for finishing new group"); /    }
///else { /        self.navigationItem.rightBarButtonItem = /            [[UIBarButtonItem alloc]
///initWithTitle:NSLocalizedString(@"UPDATE_BUTTON_TITLE", @"") /
///style:UIBarButtonItemStylePlain /                                            target:self /
///action:@selector(updateGroup)]; /        self.navigationItem.title    = self.thread.groupModel.groupName; /
///self.nameGroupTextField.text = self.thread.groupModel.groupName; /    } /    _addPeopleLabel.text            =
///NSLocalizedString(@"NEW_GROUP_REQUEST_ADDPEOPLE", @"");
////}
//
//- (void)viewDidAppear:(BOOL)animated
//{
//    [super viewDidAppear:animated];
//
//    if (self.shouldEditGroupNameOnAppear) {
//        [self.threadNameTextField becomeFirstResponder];
//    } else if (self.shouldEditAvatarOnAppear) {
//        [self showChangeGroupAvatarUI:nil];
//    }
//    self.shouldEditGroupNameOnAppear = NO;
//    self.shouldEditAvatarOnAppear = NO;
//}
//
////#pragma mark - Initializers
////
////- (void)initializeDelegates {
////    self.nameGroupTextField.delegate = self;
////}
////
////- (void)initializeTableView {
////    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
////}
////
////#pragma mark - Keyboard notifications
////
////- (void)initializeKeyboardHandlers {
////    UITapGestureRecognizer *outsideTabRecognizer =
////        [[UITapGestureRecognizer alloc] initWithTarget:self
///action:@selector(dismissKeyboardFromAppropriateSubView)]; /    [self.tapToDismissView
///addGestureRecognizer:outsideTabRecognizer];
////}
////
////- (void)dismissKeyboardFromAppropriateSubView {
////    [self.nameGroupTextField resignFirstResponder];
////}
////
////
////#pragma mark - Actions
////
////- (void)createGroup
////{
////    TSGroupModel *model = [self makeGroup];
////
////    [[TSStorageManager sharedManager]
////            .dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
////      self.thread = [TSGroupThread getOrCreateThreadWithGroupModel:model transaction:transaction];
////    }];
////
////    void (^popToThread)() = ^{
////        dispatch_async(dispatch_get_main_queue(), ^{
////            [self dismissViewControllerAnimated:YES
////                                     completion:^{
////                                         [Environment messageGroup:self.thread];
////                                     }];
////
////        });
////    };
////
////    void (^removeThreadWithError)(NSError *error) = ^(NSError *error) {
////        [self.thread remove];
////        dispatch_async(dispatch_get_main_queue(), ^{
////            [self dismissViewControllerAnimated:YES
////                                     completion:^{
////                                         SignalAlertView(NSLocalizedString(@"GROUP_CREATING_FAILED", nil),
////                                             error.localizedDescription);
////                                     }];
////        });
////    };
////
////    UIAlertController *alertController =
////        [UIAlertController alertControllerWithTitle:NSLocalizedString(@"GROUP_CREATING", nil)
////                                            message:nil
////                                     preferredStyle:UIAlertControllerStyleAlert];
////
////    [self presentViewController:alertController
////                       animated:YES
////                     completion:^{
////                         TSOutgoingMessage *message =
////                             [[TSOutgoingMessage alloc] initWithTimestamp:[NSDate ows_millisecondTimeStamp]
////                                                                 inThread:self.thread
////                                                         groupMetaMessage:TSGroupMessageNew];
////
////                         // This will save the message.
////                         [message updateWithCustomMessage:NSLocalizedString(@"GROUP_CREATED", nil)];
////                         if (model.groupImage) {
////                             [self.messageSender sendAttachmentData:UIImagePNGRepresentation(model.groupImage)
////                                                        contentType:OWSMimeTypeImagePng
////                                                           filename:nil
////                                                          inMessage:message
////                                                            success:popToThread
////                                                            failure:removeThreadWithError];
////                         } else {
////                             [self.messageSender sendMessage:message success:popToThread
////                             failure:removeThreadWithError];
////                         }
////                     }];
////}
////
////
////- (void)updateGroup
////{
////    NSMutableArray *mut = [[NSMutableArray alloc] init];
////    for (NSIndexPath *idx in _tableView.indexPathsForSelectedRows) {
////        [mut addObjectsFromArray:[[self.contacts objectAtIndex:(NSUInteger)idx.row] textSecureIdentifiers]];
////    }
////    [mut addObjectsFromArray:self.thread.groupModel.groupMemberIds];
////
////    _groupModel = [[TSGroupModel alloc] initWithTitle:_nameGroupTextField.text
////                                            memberIds:[[[NSSet setWithArray:mut] allObjects] mutableCopy]
////                                                image:self.thread.groupModel.groupImage
////                                              groupId:self.thread.groupModel.groupId];
////
////    [self.nameGroupTextField resignFirstResponder];
////
////    [self performSegueWithIdentifier:kUnwindToMessagesViewSegue sender:self];
////}
////
////
////- (TSGroupModel *)makeGroup
////{
////    NSString *title     = _nameGroupTextField.text;
////    NSMutableArray *mut = [[NSMutableArray alloc] init];
////
////    for (NSIndexPath *idx in _tableView.indexPathsForSelectedRows) {
////        [mut addObjectsFromArray:[[self.contacts objectAtIndex:(NSUInteger)idx.row] textSecureIdentifiers]];
////    }
////    [mut addObject:[TSAccountManager localNumber]];
////    NSData *groupId = [SecurityUtils generateRandomBytes:16];
////
////    return [[TSGroupModel alloc] initWithTitle:title memberIds:mut image:self.groupImage groupId:groupId];
////}

#pragma mark - Group Avatar

- (void)showChangeGroupAvatarUI
{
    OWSAssert([NSThread isMainThread]);
    OWSAssert(self.delegate);

    UIAlertController *actionSheetController =
        [UIAlertController alertControllerWithTitle:NSLocalizedString(@"NEW_GROUP_ADD_PHOTO_ACTION",
                                                        @"Action Sheet title prompting the user for a group avatar")
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"TXT_CANCEL_TITLE", @"")
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];
    [actionSheetController addAction:dismissAction];

    UIAlertAction *takePictureAction = [UIAlertAction
        actionWithTitle:NSLocalizedString(@"MEDIA_FROM_CAMERA_BUTTON", @"media picker option to take photo or video")
                  style:UIAlertActionStyleDefault
                handler:^(UIAlertAction *_Nonnull action) {
                    [self takePicture];
                }];
    [actionSheetController addAction:takePictureAction];

    UIAlertAction *choosePictureAction = [UIAlertAction
        actionWithTitle:NSLocalizedString(@"MEDIA_FROM_LIBRARY_BUTTON", @"media picker option to choose from library")
                  style:UIAlertActionStyleDefault
                handler:^(UIAlertAction *_Nonnull action) {
                    [self chooseFromLibrary];
                }];
    [actionSheetController addAction:choosePictureAction];

    [self.delegate.fromViewController presentViewController:actionSheetController animated:true completion:nil];
}

- (void)takePicture
{
    OWSAssert([NSThread isMainThread]);
    OWSAssert(self.delegate);

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        picker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage, nil];
        [self.delegate.fromViewController presentViewController:picker
                                                       animated:YES
                                                     completion:[UIUtil modalCompletionBlock]];
    }
}

- (void)chooseFromLibrary
{
    OWSAssert([NSThread isMainThread]);
    OWSAssert(self.delegate);

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        picker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage, nil];
        [self.delegate.fromViewController presentViewController:picker
                                                       animated:YES
                                                     completion:[UIUtil modalCompletionBlock]];
    }
}

/*
 *  Dismissing UIImagePickerController
 */

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    OWSAssert([NSThread isMainThread]);
    OWSAssert(self.delegate);

    [self.delegate.fromViewController dismissViewControllerAnimated:YES completion:nil];
}

/*
 *  Fetch data from UIImagePickerController
 */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    OWSAssert([NSThread isMainThread]);
    OWSAssert(self.delegate);

    UIImage *rawAvatar = [info objectForKey:UIImagePickerControllerOriginalImage];

    if (rawAvatar) {
        // TODO: This is busted.
        UIImage *resizedAvatar = [rawAvatar resizedImageToFitInSize:CGSizeMake(100.00, 100.00) scaleIfSmaller:NO];
        [self.delegate groupAvatarDidChange:resizedAvatar];
    }

    [self.delegate.fromViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

NS_ASSUME_NONNULL_END
