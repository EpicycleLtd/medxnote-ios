//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "UpdateGroupViewController.h"
#import "BlockListUIUtils.h"
#import "ContactAccount.h"
#import "ContactTableViewCell.h"
#import "ContactsViewHelper.h"
#import "Environment.h"
#import "FunctionalUtil.h"
#import "GroupViewHelper.h"
#import "OWSAnyTouchGestureRecognizer.h"
#import "OWSContactsManager.h"
#import "OWSTableViewController.h"
#import "SecurityUtils.h"
#import "SignalKeyingStorage.h"
#import "SignalsViewController.h"
#import "TSOutgoingMessage.h"
#import "UIImage+normalizeImage.h"
#import "UIUtil.h"
#import "UIView+OWS.h"
#import "UIViewController+OWS.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <SignalServiceKit/MimeTypeUtil.h>
#import <SignalServiceKit/NSDate+millisecondTimeStamp.h>
#import <SignalServiceKit/OWSBlockingManager.h>
#import <SignalServiceKit/OWSMessageSender.h>
#import <SignalServiceKit/TSAccountManager.h>

// TODO
//#import "OWSAvatarBuilder.h"

NS_ASSUME_NONNULL_BEGIN

@interface UpdateGroupViewController () <UIImagePickerControllerDelegate,
    UITextFieldDelegate,
    ContactsViewHelperDelegate,
    GroupViewHelperDelegate,
    OWSTableViewControllerDelegate,
    UINavigationControllerDelegate>

@property (nonatomic, readonly) TSGroupThread *thread;
@property (nonatomic, readonly) OWSMessageSender *messageSender;
@property (nonatomic, readonly) ContactsViewHelper *contactsViewHelper;
@property (nonatomic, readonly) GroupViewHelper *groupViewHelper;

@property (nonatomic, readonly) OWSTableViewController *tableViewController;
@property (nonatomic, readonly) UIImageView *avatarView;
@property (nonatomic, readonly) UITextField *groupNameTextField;

@property (nonatomic, nullable) UIImage *groupAvatar;
@property (nonatomic, nullable) NSSet<NSString *> *previousMemberRecipientIds;
@property (nonatomic, nullable) NSMutableSet<NSString *> *memberRecipientIds;

@property (nonatomic) BOOL hasUnsavedChanges;

@end

#pragma mark -

@implementation UpdateGroupViewController

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return self;
    }

    [self commonInit];

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return self;
    }

    [self commonInit];

    return self;
}

- (void)commonInit
{
    _messageSender = [Environment getCurrent].messageSender;
    _contactsViewHelper = [ContactsViewHelper new];
    _contactsViewHelper.delegate = self;
    _groupViewHelper = [GroupViewHelper new];
    _groupViewHelper.delegate = self;

    self.memberRecipientIds = [NSMutableSet new];
}

#pragma mark - View Lifecycle

- (void)loadView
{
    self.title = NSLocalizedString(@"EDIT_GROUP_DEFAULT_TITLE", @"The default title for the 'update group' view.");
    //    self.title = (self.thread.groupModel.groupName.length > 0
    //                  ? NSLocalizedString(@"EDIT_GROUP_DEFAULT_TITLE", @"The default title for the 'update group'
    //                  view.") : self.thread.groupModel.groupName);
    self.navigationItem.leftBarButtonItem =
        [self createOWSBackButtonWithTarget:self selector:@selector(backButtonPressed:)];

    UIView *view = [UIView new];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = view;
    //    [self.view autoPinWidthToSuperview];
    //    [self.view autoPinToTopLayoutGuideOfViewController:self withInset:0.f];
    //    [self.view autoPinToBottomLayoutGuideOfViewController:self withInset:0.f];

    // First section.

    UIView *firstSection = [self firstSectionHeader];
    [self.view addSubview:firstSection];
    [firstSection autoSetDimension:ALDimensionHeight toSize:100.f];
    [firstSection autoPinWidthToSuperview];
    [firstSection autoPinEdgeToSuperviewEdge:ALEdgeTop];

    _tableViewController = [OWSTableViewController new];
    _tableViewController.delegate = self;
    _tableViewController.contents = [OWSTableContents new];
    [self.view addSubview:self.tableViewController.view];
    [_tableViewController.view autoPinWidthToSuperview];
    [_tableViewController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:firstSection];
    [_tableViewController.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    //    [self updateContacts];
    //    [self updateGroupMembers];
    [self updateTableContents];
}

- (UIView *)firstSectionHeader
{
    UIView *firstSectionHeader = [UIView new];
    firstSectionHeader.backgroundColor = [UIColor whiteColor];
    UIView *threadInfoView = [UIView new];
    [firstSectionHeader addSubview:threadInfoView];
    [threadInfoView autoPinWidthToSuperviewWithMargin:16.f];
    [threadInfoView autoPinHeightToSuperviewWithMargin:16.f];

    //    UIImage *avatar = [OWSAvatarBuilder buildImageForThread:self.thread contactsManager:self.contactsManager];
    //    OWSAssert(avatar);
    const CGFloat kAvatarSize = 68.f;
    UIImageView *avatarView = [UIImageView new];
    _avatarView = avatarView;
    avatarView.layer.borderColor = UIColor.clearColor.CGColor;
    avatarView.layer.masksToBounds = YES;
    avatarView.layer.cornerRadius = kAvatarSize / 2.0f;
    avatarView.contentMode = UIViewContentModeScaleAspectFill;
    [threadInfoView addSubview:avatarView];
    [avatarView autoVCenterInSuperview];
    [avatarView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [avatarView autoSetDimension:ALDimensionWidth toSize:kAvatarSize];
    [avatarView autoSetDimension:ALDimensionHeight toSize:kAvatarSize];
    if (self.thread.groupModel) {
        _groupAvatar = self.thread.groupModel.groupImage;
    }
    [self updateAvatarView];

    UITextField *groupNameTextField = [UITextField new];
    _groupNameTextField = groupNameTextField;
    if (self.thread) {
        _groupNameTextField.text = self.thread.groupModel.groupName;
        self.groupNameTextField.text = self.thread.groupModel.groupName;
    }
    groupNameTextField.textColor = [UIColor blackColor];
    groupNameTextField.font = [UIFont ows_dynamicTypeTitle2Font];
    groupNameTextField.placeholder = NSLocalizedString(@"NEW_GROUP_NAMEGROUP_REQUEST_DEFAULT", @"");
    groupNameTextField.delegate = self;
    [groupNameTextField addTarget:self
                           action:@selector(groupNameDidChange:)
                 forControlEvents:UIControlEventEditingChanged];
    [threadInfoView addSubview:groupNameTextField];
    [groupNameTextField autoVCenterInSuperview];
    [groupNameTextField autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:avatarView withOffset:16.f];
    [groupNameTextField autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16.f];

    [avatarView addGestureRecognizer:[[OWSAnyTouchGestureRecognizer alloc] initWithTarget:self
                                                                                   action:@selector(avatarTouched:)]];
    avatarView.userInteractionEnabled = YES;

    return firstSectionHeader;
}

- (void)avatarTouched:(UIGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateRecognized) {
        [self showChangeGroupAvatarUI:nil];
    }
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];

    //    // TODO: Copy
    //    contents.title
    //        = (self.thread ? NSLocalizedString(@"CONVERSATION_SETTINGS", @"title for conversation settings screen")
    //                       : NSLocalizedString(@"CONVERSATION_SETTINGS", @"title for conversation settings screen"));

    __weak UpdateGroupViewController *weakSelf = self;
    ContactsViewHelper *helper = self.contactsViewHelper;

    // Group Members

    if (self.memberRecipientIds.count > 0) {
        OWSTableSection *membersSection = [OWSTableSection new];
        membersSection.headerTitle = NSLocalizedString(
            @"EDIT_GROUP_MEMBERS_SECTION_TITLE", @"a title for the members section of the 'new/update group' view.");

        for (NSString *recipientId in
            [self.memberRecipientIds.allObjects sortedArrayUsingSelector:@selector(compare:)]) {
            [membersSection addItem:[OWSTableItem itemWithCustomCellBlock:^{
                UpdateGroupViewController *strongSelf = weakSelf;
                if (!strongSelf) {
                    return (ContactTableViewCell *)nil;
                }

                ContactTableViewCell *cell = [ContactTableViewCell new];
                ContactAccount *contactAccount = [helper contactAccountForRecipientId:recipientId];
                BOOL isPreviousMember = [strongSelf.previousMemberRecipientIds containsObject:recipientId];
                BOOL isCurrentMember = YES;
                BOOL isBlocked = [helper isRecipientIdBlocked:recipientId];
                if ((strongSelf.thread && isPreviousMember) || (!strongSelf.thread && isCurrentMember)) {
                    // In the "members" section, we label "previous" members as members when
                    // editing an existing group and we label "new" members as members creating a new group.
                    //                    cell.accessoryMessage
                    //                    = NSLocalizedString(@"EDIT_GROUP_CURRENT_MEMBER_LABEL", @"An indicator that a
                    //                    user is a current member of the group.");
                } else if (strongSelf.thread && isCurrentMember) {
                    // In the "members" section, we label "new" members as such when editing an existing group.
                    cell.accessoryMessage = NSLocalizedString(
                        @"EDIT_GROUP_NEW_MEMBER_LABEL", @"An indicator that a user is a new member of the group.");
                } else if (isBlocked) {
                    cell.accessoryMessage = NSLocalizedString(
                        @"CONTACT_CELL_IS_BLOCKED", @"An indicator that a contact has been blocked.");
                } else {
                    OWSAssert(cell.accessoryMessage == nil);
                }

                if (contactAccount) {
                    // TODO: Use the account label.
                    [cell configureWithContact:contactAccount.contact contactsManager:helper.contactsManager];
                } else {
                    [cell configureWithRecipientId:recipientId contactsManager:helper.contactsManager];
                }

                return cell;
            }
                                                          customRowHeight:[ContactTableViewCell rowHeight]
                                                              actionBlock:^{
                                                                  // TODO:
                                                              }]];
        }
        [contents addSection:membersSection];
    }

    // Contacts

    OWSTableSection *contactAccountSection = [OWSTableSection new];
    contactAccountSection.headerTitle = NSLocalizedString(
        @"EDIT_GROUP_CONTACTS_SECTION_TITLE", @"a title for the contacts section of the 'new/update group' view.");
    NSArray<ContactAccount *> *allRecipientContactAccounts = self.contactsViewHelper.allRecipientContactAccounts;
    if (allRecipientContactAccounts.count > 0) {
        for (ContactAccount *contactAccount in allRecipientContactAccounts) {
            [contactAccountSection addItem:[OWSTableItem itemWithCustomCellBlock:^{
                UpdateGroupViewController *strongSelf = weakSelf;
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
                                                                         // TODO:
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

    //    ContactAccount *contactAccount
    self.tableViewController.contents = contents;
}

#pragma mark - Methods

- (void)configWithThread:(TSGroupThread *)thread
{
    _thread = thread;

    if (self.thread.groupModel.groupMemberIds) {
        [self.memberRecipientIds addObjectsFromArray:self.thread.groupModel.groupMemberIds];
        self.previousMemberRecipientIds = [NSSet setWithArray:self.thread.groupModel.groupMemberIds];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationController.navigationBar setTranslucent:NO];

    //    self.contacts = [self filteredContacts];
    //
    //    self.tableView.tableHeaderView.frame = CGRectMake(0, 0, 400, 44);
    //    self.tableView.tableHeaderView       = self.tableView.tableHeaderView;
    //
    //    [self initializeDelegates];
    //    [self initializeTableView];
    //    [self initializeKeyboardHandlers];
    //
    //    if (self.thread == nil) {
    //        self.navigationItem.rightBarButtonItem =
    //            [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"add-conversation"]
    //                                                       imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
    //                                             style:UIBarButtonItemStylePlain
    //                                            target:self
    //                                            action:@selector(createGroup)];
    //        self.navigationItem.rightBarButtonItem.imageInsets = UIEdgeInsetsMake(0, -10, 0, 10);
    //        self.navigationItem.title                          = NSLocalizedString(@"NEW_GROUP_DEFAULT_TITLE", @"");
    //        self.navigationItem.rightBarButtonItem.accessibilityLabel =
    //        NSLocalizedString(@"FINISH_GROUP_CREATION_LABEL",
    //        @"Accessibilty label for finishing new group");
    //    } else {
    //    self.navigationItem.rightBarButtonItem =
    //    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"UPDATE_BUTTON_TITLE", @"")
    //                                     style:UIBarButtonItemStylePlain
    //                                    target:self
    //                                    action:@selector(updateGroup)];
    //    self.navigationItem.title = self.thread.groupModel.groupName;
    //    self.groupNameTextField.text = self.thread.groupModel.groupName;
    //    }
    //    _addPeopleLabel.text            = NSLocalizedString(@"NEW_GROUP_REQUEST_ADDPEOPLE", @"");
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.shouldEditGroupNameOnAppear) {
        [self.groupNameTextField becomeFirstResponder];
    } else if (self.shouldEditAvatarOnAppear) {
        [self showChangeGroupAvatarUI:nil];
    }
    self.shouldEditGroupNameOnAppear = NO;
    self.shouldEditAvatarOnAppear = NO;
}

//#pragma mark - Initializers
//
//- (void)initializeDelegates {
//    self.nameGroupTextField.delegate = self;
//}
//
//- (void)initializeTableView {
//    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
//}
//
//#pragma mark - Keyboard notifications
//
//- (void)initializeKeyboardHandlers {
//    UITapGestureRecognizer *outsideTabRecognizer =
//        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboardFromAppropriateSubView)];
//    [self.tapToDismissView addGestureRecognizer:outsideTabRecognizer];
//}
//
//- (void)dismissKeyboardFromAppropriateSubView {
//    [self.nameGroupTextField resignFirstResponder];
//}
//
//
//#pragma mark - Actions
//
//- (void)createGroup
//{
//    TSGroupModel *model = [self makeGroup];
//
//    [[TSStorageManager sharedManager]
//            .dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
//      self.thread = [TSGroupThread getOrCreateThreadWithGroupModel:model transaction:transaction];
//    }];
//
//    void (^popToThread)() = ^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self dismissViewControllerAnimated:YES
//                                     completion:^{
//                                         [Environment messageGroup:self.thread];
//                                     }];
//
//        });
//    };
//
//    void (^removeThreadWithError)(NSError *error) = ^(NSError *error) {
//        [self.thread remove];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self dismissViewControllerAnimated:YES
//                                     completion:^{
//                                         SignalAlertView(NSLocalizedString(@"GROUP_CREATING_FAILED", nil),
//                                             error.localizedDescription);
//                                     }];
//        });
//    };
//
//    UIAlertController *alertController =
//        [UIAlertController alertControllerWithTitle:NSLocalizedString(@"GROUP_CREATING", nil)
//                                            message:nil
//                                     preferredStyle:UIAlertControllerStyleAlert];
//
//    [self presentViewController:alertController
//                       animated:YES
//                     completion:^{
//                         TSOutgoingMessage *message =
//                             [[TSOutgoingMessage alloc] initWithTimestamp:[NSDate ows_millisecondTimeStamp]
//                                                                 inThread:self.thread
//                                                         groupMetaMessage:TSGroupMessageNew];
//
//                         // This will save the message.
//                         [message updateWithCustomMessage:NSLocalizedString(@"GROUP_CREATED", nil)];
//                         if (model.groupImage) {
//                             [self.messageSender sendAttachmentData:UIImagePNGRepresentation(model.groupImage)
//                                                        contentType:OWSMimeTypeImagePng
//                                                           filename:nil
//                                                          inMessage:message
//                                                            success:popToThread
//                                                            failure:removeThreadWithError];
//                         } else {
//                             [self.messageSender sendMessage:message success:popToThread
//                             failure:removeThreadWithError];
//                         }
//                     }];
//}
//

- (void)updateGroup
{
    OWSAssert(self.delegate);

    TSGroupModel *groupModel = [[TSGroupModel alloc] initWithTitle:self.groupNameTextField.text
                                                         memberIds:[self.memberRecipientIds.allObjects mutableCopy]
                                                             image:self.groupAvatar
                                                           groupId:self.thread.groupModel.groupId];
    [self.delegate groupWasUpdated:groupModel];
}

//
//- (TSGroupModel *)makeGroup
//{
//    NSString *title     = _nameGroupTextField.text;
//    NSMutableArray *mut = [[NSMutableArray alloc] init];
//
//    for (NSIndexPath *idx in _tableView.indexPathsForSelectedRows) {
//        [mut addObjectsFromArray:[[self.contacts objectAtIndex:(NSUInteger)idx.row] textSecureIdentifiers]];
//    }
//    [mut addObject:[TSAccountManager localNumber]];
//    NSData *groupId = [SecurityUtils generateRandomBytes:16];
//
//    return [[TSGroupModel alloc] initWithTitle:title memberIds:mut image:self.groupImage groupId:groupId];
//}

#pragma mark - Group Avatar

- (void)showChangeGroupAvatarUI:(nullable id)sender
{
    [self.groupViewHelper showChangeGroupAvatarUI];
}

- (void)setGroupAvatar:(nullable UIImage *)groupAvatar
{
    OWSAssert([NSThread isMainThread]);

    _groupAvatar = groupAvatar;

    self.hasUnsavedChanges = YES;

    [self updateAvatarView];
}

- (void)updateAvatarView
{
    UIImage *image = (self.groupAvatar ?: [UIImage imageNamed:@"empty-group-avatar"]);
    OWSAssert(image);

    self.avatarView.image = image;
    //    [self.avatarView setImage:image forState:UIControlStateNormal];
    //    self.groupImageButton.imageView.layer.cornerRadius  = CGRectGetWidth([self.groupImageButton.imageView frame])
    //    / 2.0f; self.groupImageButton.imageView.layer.masksToBounds = YES;
    // TODO.
    //    self.groupImageButton.imageView.layer.borderColor   = [[UIColor lightGrayColor] CGColor];
    //    self.groupImageButton.imageView.layer.borderWidth   = 0.5f;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
}

//#pragma mark - Table view data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return 1;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return (NSInteger)[self.contacts count];
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    ContactTableViewCell *cell
//        = (ContactTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[ContactTableViewCell
//        reuseIdentifier]];
//    if (!cell) {
//        cell = [ContactTableViewCell new];
//    }
//
//    [self updateContentsOfCell:cell indexPath:indexPath];
//
//    return cell;
//}
//
//- (void)updateContentsOfCell:(ContactTableViewCell *)cell indexPath:(NSIndexPath *)indexPath
//{
//    OWSAssert(cell);
//    OWSAssert(indexPath);
//
//    Contact *contact = self.contacts[(NSUInteger)indexPath.row];
//    OWSAssert(contact != nil);
//
//    BOOL isBlocked = [self isContactBlocked:contact];
//    BOOL isInGroup = [self isContactInGroup:contact];
//    BOOL isSelected = [[self.tableView indexPathsForSelectedRows] containsObject:indexPath];
//    // More than one of these conditions might be true.
//    // In order of priority...
//    cell.accessoryMessage = nil;
//    cell.accessoryView = nil;
//    cell.accessoryType = UITableViewCellAccessoryNone;
//    if (isInGroup) {
//        OWSAssert(!isSelected);
//        // ...if the user is already in the group, indicate that.
//        cell.accessoryMessage = NSLocalizedString(
//            @"CONTACT_CELL_IS_IN_GROUP", @"An indicator that a contact is a member of the current group.");
//    } else if (isSelected) {
//        // ...if the user is being added to the group, indicate that.
//        cell.accessoryType = UITableViewCellAccessoryCheckmark;
//    } else if (isBlocked) {
//        // ...if the user is blocked, indicate that.
//        cell.accessoryMessage
//            = NSLocalizedString(@"CONTACT_CELL_IS_BLOCKED", @"An indicator that a contact has been blocked.");
//    }
//    [cell configureWithContact:contact contactsManager:self.contactsManager];
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return [ContactTableViewCell rowHeight];
//}
//
//#pragma mark - Table View delegate
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    Contact *contact = self.contacts[(NSUInteger)indexPath.row];
//    BOOL isBlocked = [self isContactBlocked:contact];
//    BOOL isInGroup = [self isContactInGroup:contact];
//    if (isInGroup) {
//        // Deselect.
//        [tableView deselectRowAtIndexPath:indexPath animated:YES];
//
//        NSString *displayName = [_contactsManager displayNameForContact:contact];
//        UIAlertController *controller = [UIAlertController
//            alertControllerWithTitle:
//                NSLocalizedString(@"EDIT_GROUP_VIEW_ALREADY_IN_GROUP_ALERT_TITLE",
//                    @"A title of the alert if user tries to add a user to a group who is already in the group.")
//                             message:[NSString
//                                         stringWithFormat:
//                                             NSLocalizedString(@"EDIT_GROUP_VIEW_ALREADY_IN_GROUP_ALERT_MESSAGE_FORMAT",
//                                                 @"A format for the message of the alert if user tries to "
//                                                 @"add a user to a group who is already in the group.  Embeds {{the "
//                                                 @"blocked user's name or phone number}}."),
//                                         displayName]
//                      preferredStyle:UIAlertControllerStyleAlert];
//        [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
//                                                       style:UIAlertActionStyleDefault
//                                                     handler:nil]];
//        [self presentViewController:controller animated:YES completion:nil];
//        return;
//    } else if (isBlocked) {
//        // Deselect.
//        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
//
//        __weak UpdateGroupViewController *weakSelf = self;
//        [BlockListUIUtils showUnblockContactActionSheet:contact
//                                     fromViewController:self
//                                        blockingManager:_blockingManager
//                                        contactsManager:_contactsManager
//                                        completionBlock:^(BOOL isStillBlocked) {
//                                            if (!isStillBlocked) {
//                                                // Re-select.
//                                                [weakSelf.tableView selectRowAtIndexPath:indexPath
//                                                                                animated:YES
//                                                                          scrollPosition:UITableViewScrollPositionNone];
//
//                                                ContactTableViewCell *cell = (ContactTableViewCell
//                                                *)[weakSelf.tableView
//                                                    cellForRowAtIndexPath:indexPath];
//                                                [weakSelf updateContentsOfCell:cell indexPath:indexPath];
//                                            }
//                                        }];
//        return;
//    }
//
//    ContactTableViewCell *cell = (ContactTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
//    [self updateContentsOfCell:cell indexPath:indexPath];
//}
//
//- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
//    ContactTableViewCell *cell = (ContactTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
//    [self updateContentsOfCell:cell indexPath:indexPath];
//}

#pragma mark - Event Handling

- (void)backButtonPressed:(id)sender
{
    [self.groupNameTextField resignFirstResponder];

    if (!self.hasUnsavedChanges) {
        // If user made no changes, return to conversation settings view.
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }

    UIAlertController *controller = [UIAlertController
        alertControllerWithTitle:NSLocalizedString(@"EDIT_GROUP_VIEW_UNSAVED_CHANGES_TITLE",
                                     @"The alert title if user tries to exit update group view without saving changes.")
                         message:
                             NSLocalizedString(@"EDIT_GROUP_VIEW_UNSAVED_CHANGES_MESSAGE",
                                 @"The alert message if user tries to exit update group view without saving changes.")
                  preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ALERT_SAVE",
                                                             @"The label for the 'save' button in action sheets.")
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
                                                     OWSAssert(self.delegate);

                                                     [self updateGroup];

                                                     [self.delegate popAllConversationSettingsViews];
                                                 }]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ALERT_DONT_SAVE",
                                                             @"The label for the 'don't save' button in action sheets.")
                                                   style:UIAlertActionStyleDestructive
                                                 handler:^(UIAlertAction *action) {
                                                     [self.navigationController popViewControllerAnimated:YES];
                                                 }]];
    [self presentViewController:controller animated:YES completion:nil];
}


- (void)groupNameDidChange:(id)sender
{
    self.hasUnsavedChanges = YES;
}

#pragma mark - Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.groupNameTextField resignFirstResponder];
    return NO;
}

#pragma mark - OWSTableViewControllerDelegate

- (void)tableViewDidScroll
{
    [self.groupNameTextField resignFirstResponder];
}

#pragma mark - ContactsViewHelperDelegate

- (void)contactsViewHelperDidUpdateContacts
{
    [self updateTableContents];
}

#pragma mark - GroupViewHelperDelegate

- (void)groupAvatarDidChange:(UIImage *)image
{
    OWSAssert(image);

    self.thread.groupModel.groupImage = image;
    self.groupAvatar = image;
}

- (UIViewController *)fromViewController
{
    return self;
}

@end

NS_ASSUME_NONNULL_END
