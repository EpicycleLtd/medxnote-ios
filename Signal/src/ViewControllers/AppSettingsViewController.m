//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "AppSettingsViewController.h"
#import "AboutTableViewController.h"
#import "AdvancedSettingsTableViewController.h"
#import "DebugUITableViewController.h"
#import "Environment.h"
#import "NotificationSettingsViewController.h"
#import "OWSContactsManager.h"
#import "OWSLinkedDevicesTableViewController.h"
#import "OWSNavigationController.h"
#import "PrivacySettingsTableViewController.h"
#import "ProfileViewController.h"
#import "PushManager.h"
#import "Signal-Swift.h"
#import "UIUtil.h"
#import <SignalServiceKit/TSAccountManager.h>
#import <SignalServiceKit/TSSocketManager.h>

@interface AppSettingsViewController ()

@property (nonatomic, readonly) OWSContactsManager *contactsManager;

@end

#pragma mark -

@implementation AppSettingsViewController

/**
 * We always present the settings controller modally, from within an OWSNavigationController
 */
+ (OWSNavigationController *)inModalNavigationController
{
    AppSettingsViewController *viewController = [AppSettingsViewController new];
    OWSNavigationController *navController =
        [[OWSNavigationController alloc] initWithRootViewController:viewController];

    return navController;
}

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return self;
    }

    _contactsManager = [Environment getCurrent].contactsManager;

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return self;
    }

    _contactsManager = [Environment getCurrent].contactsManager;

    return self;
}

- (void)loadView
{
    self.tableViewStyle = UITableViewStylePlain;
    [super loadView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationItem setHidesBackButton:YES];

    OWSAssert([self.navigationController isKindOfClass:[OWSNavigationController class]]);

    [self.navigationController.navigationBar setTranslucent:NO];
    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                      target:self
                                                      action:@selector(dismissWasPressed:)];

    [self observeNotifications];

    self.title = NSLocalizedString(@"SETTINGS_NAV_BAR_TITLE", @"Title for settings activity");

    [self updateTableContents];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateTableContents];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];
    OWSTableSection *section = [OWSTableSection new];

    __weak AppSettingsViewController *weakSelf = self;

    [section addItem:[OWSTableItem itemWithCustomCellBlock:^{
        return [weakSelf profileHeaderCell];
    }
                         customRowHeight:100.f
                         actionBlock:^{
                             [weakSelf showProfile];
                         }]];

    if (OWSSignalService.sharedInstance.isCensorshipCircumventionActive) {
        [section
            addItem:[OWSTableItem disclosureItemWithText:
                                      NSLocalizedString(@"NETWORK_STATUS_CENSORSHIP_CIRCUMVENTION_ACTIVE",
                                          @"Indicates to the user that censorship circumvention has been activated.")
                                             actionBlock:^{
                                                 [weakSelf showAdvanced];
                                             }]];
    } else {
        [section addItem:[OWSTableItem itemWithCustomCellBlock:^{
            UITableViewCell *cell = [UITableViewCell new];
            cell.textLabel.text = NSLocalizedString(@"NETWORK_STATUS_HEADER", @"");
            cell.textLabel.font = [UIFont ows_regularFontWithSize:18.f];
            cell.textLabel.textColor = [UIColor blackColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UILabel *accessoryLabel = [UILabel new];
            accessoryLabel.font = [UIFont ows_regularFontWithSize:18.f];
            switch ([TSSocketManager sharedManager].state) {
                case SocketManagerStateClosed:
                    accessoryLabel.text = NSLocalizedString(@"NETWORK_STATUS_OFFLINE", @"");
                    accessoryLabel.textColor = [UIColor ows_redColor];
                    break;
                case SocketManagerStateConnecting:
                    accessoryLabel.text = NSLocalizedString(@"NETWORK_STATUS_CONNECTING", @"");
                    accessoryLabel.textColor = [UIColor ows_yellowColor];
                    break;
                case SocketManagerStateOpen:
                    accessoryLabel.text = NSLocalizedString(@"NETWORK_STATUS_CONNECTED", @"");
                    accessoryLabel.textColor = [UIColor ows_greenColor];
                    break;
            }
            [accessoryLabel sizeToFit];
            cell.accessoryView = accessoryLabel;
            return cell;
        }
                                                   actionBlock:nil]];
    }

//    [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"SETTINGS_INVITE_TITLE",
//                                                              @"Settings table view cell label")
//                                              actionBlock:^{
//                                                  [weakSelf showInviteFlow];
//                                              }]];
    [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"SETTINGS_PRIVACY_TITLE",
                                                              @"Settings table view cell label")
                                              actionBlock:^{
                                                  [weakSelf showPrivacy];
                                              }]];
    [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"SETTINGS_NOTIFICATIONS", nil)
                                              actionBlock:^{
                                                  [weakSelf showNotifications];
                                              }]];
    [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"LINKED_DEVICES_TITLE",
                                                              @"Menu item and navbar title for the device manager")
                                              actionBlock:^{
                                                  [weakSelf showLinkedDevices];
                                              }]];
    [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"SETTINGS_ADVANCED_TITLE", @"")
                                              actionBlock:^{
                                                  [weakSelf showAdvanced];
                                              }]];
    [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"SETTINGS_ABOUT", @"")
                                              actionBlock:^{
                                                  [weakSelf showAbout];
                                              }]];

#ifdef USE_DEBUG_UI
    [section addItem:[OWSTableItem disclosureItemWithText:@"Debug UI"
                                              actionBlock:^{
                                                  [weakSelf showDebugUI];
                                              }]];
#endif

    [section addItem:[OWSTableItem itemWithCustomCellBlock:^{
        UITableViewCell *cell = [UITableViewCell new];
        cell.preservesSuperviewLayoutMargins = YES;
        cell.contentView.preservesSuperviewLayoutMargins = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        const CGFloat kButtonHeight = 40.f;
        OWSFlatButton *button = [OWSFlatButton buttonWithTitle:NSLocalizedString(@"SETTINGS_DELETE_ACCOUNT_BUTTON", @"")
                                                          font:[OWSFlatButton fontForHeight:kButtonHeight]
                                                    titleColor:[UIColor whiteColor]
                                               backgroundColor:[UIColor ows_destructiveRedColor]
                                                        target:self
                                                      selector:@selector(unregisterUser)];
        [cell.contentView addSubview:button];
        [button autoSetDimension:ALDimensionHeight toSize:kButtonHeight];
        [button autoVCenterInSuperview];
        [button autoPinLeadingAndTrailingToSuperview];

        return cell;
    }
                                           customRowHeight:90.f
                                               actionBlock:nil]];

    [contents addSection:section];

    self.contents = contents;
}

- (UITableViewCell *)profileHeaderCell
{
    UITableViewCell *cell = [UITableViewCell new];
    cell.preservesSuperviewLayoutMargins = YES;
    cell.contentView.preservesSuperviewLayoutMargins = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    const NSUInteger kAvatarSize = 68;
    // TODO: Replace this icon.
    UIImage *_Nullable localProfileAvatarImage = [OWSProfileManager.sharedManager localProfileAvatarImage];
    UIImage *avatarImage = (localProfileAvatarImage
            ?: [[UIImage imageNamed:@"profile_avatar_default"]
                   imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]);
    OWSAssert(avatarImage);

    AvatarImageView *avatarView = [[AvatarImageView alloc] initWithImage:avatarImage];
    if (!localProfileAvatarImage) {
        avatarView.tintColor = [UIColor colorWithRGBHex:0x888888];
    }
    [cell.contentView addSubview:avatarView];
    [avatarView autoVCenterInSuperview];
    [avatarView autoPinLeadingToSuperview];
    [avatarView autoSetDimension:ALDimensionWidth toSize:kAvatarSize];
    [avatarView autoSetDimension:ALDimensionHeight toSize:kAvatarSize];

    if (!localProfileAvatarImage) {
        UIImage *cameraImage = [UIImage imageNamed:@"settings-avatar-camera"];
        UIImageView *cameraImageView = [[UIImageView alloc] initWithImage:cameraImage];
        [cell.contentView addSubview:cameraImageView];
        [cameraImageView autoPinTrailingToView:avatarView];
        [cameraImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:avatarView];
    }

    UIView *nameView = [UIView containerView];
    [cell.contentView addSubview:nameView];
    [nameView autoVCenterInSuperview];
    [nameView autoPinLeadingToTrailingOfView:avatarView margin:16.f];

    UILabel *titleLabel = [UILabel new];
    NSString *_Nullable localProfileName = [OWSProfileManager.sharedManager localProfileName];
    if (localProfileName.length > 0) {
        titleLabel.text = localProfileName;
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.font = [UIFont ows_dynamicTypeTitle2Font];
    } else {
        titleLabel.text = NSLocalizedString(
            @"APP_SETTINGS_EDIT_PROFILE_NAME_PROMPT", @"Text prompting user to edit their profile name.");
        titleLabel.textColor = [UIColor ows_materialBlueColor];
        titleLabel.font = [UIFont ows_dynamicTypeHeadlineFont];
    }
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [nameView addSubview:titleLabel];
    [titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [titleLabel autoPinWidthToSuperview];

    const CGFloat kSubtitlePointSize = 12.f;
    UILabel *subtitleLabel = [UILabel new];
    subtitleLabel.textColor = [UIColor ows_darkGrayColor];
    subtitleLabel.font = [UIFont ows_regularFontWithSize:kSubtitlePointSize];
    subtitleLabel.attributedText = [[NSAttributedString alloc]
        initWithString:[PhoneNumber bestEffortFormatPartialUserSpecifiedTextToLookLikeAPhoneNumber:[TSAccountManager
                                                                                                       localNumber]]];
    subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [nameView addSubview:subtitleLabel];
    [subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:titleLabel];
    [subtitleLabel autoPinLeadingToSuperview];
    [subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    UIImage *disclosureImage = [UIImage imageNamed:(self.view.isRTL ? @"NavBarBack" : @"NavBarBackRTL")];
    OWSAssert(disclosureImage);
    UIImageView *disclosureButton =
        [[UIImageView alloc] initWithImage:[disclosureImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    disclosureButton.tintColor = [UIColor colorWithRGBHex:0xcccccc];
    [cell.contentView addSubview:disclosureButton];
    [disclosureButton autoVCenterInSuperview];
    [disclosureButton autoPinTrailingToSuperview];
    [disclosureButton autoPinLeadingToTrailingOfView:nameView margin:16.f];
    [disclosureButton setContentCompressionResistancePriority:(UILayoutPriorityDefaultHigh + 1) forAxis:UILayoutConstraintAxisHorizontal];

    return cell;
}

- (void)showInviteFlow
{
    OWSInviteFlow *inviteFlow =
        [[OWSInviteFlow alloc] initWithPresentingViewController:self contactsManager:self.contactsManager];
    [self presentViewController:inviteFlow.actionSheetController animated:YES completion:nil];
}

- (void)showPrivacy
{
    PrivacySettingsTableViewController *vc = [[PrivacySettingsTableViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showNotifications
{
    NotificationSettingsViewController *vc = [[NotificationSettingsViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showLinkedDevices
{
    OWSLinkedDevicesTableViewController *vc =
        [[UIStoryboard main] instantiateViewControllerWithIdentifier:@"OWSLinkedDevicesTableViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showProfile
{
    [ProfileViewController presentForAppSettings:self.navigationController];
}

- (void)showAdvanced
{
    AdvancedSettingsTableViewController *vc = [[AdvancedSettingsTableViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showAbout
{
    AboutTableViewController *vc = [[AboutTableViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showDebugUI
{
    [DebugUITableViewController presentDebugUIFromViewController:self];
}

- (void)dismissWasPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (void)unregisterUser
{
    UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:NSLocalizedString(@"CONFIRM_ACCOUNT_DESTRUCTION_TITLE", @"")
                                            message:NSLocalizedString(@"CONFIRM_ACCOUNT_DESTRUCTION_TEXT", @"")
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"PROCEED_BUTTON", @"")
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction *action) {
                                                          [self proceedToUnregistration];
                                                      }]];
    [alertController addAction:[OWSAlerts cancelAction]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)proceedToUnregistration
{
    [ModalActivityIndicatorViewController
        presentFromViewController:self
                        canCancel:NO
                  backgroundBlock:^(ModalActivityIndicatorViewController *modalActivityIndicator) {
                      [TSAccountManager unregisterTextSecureWithSuccess:^{
                          [Environment resetAppData];
                      }
                          failure:^(NSError *error) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [modalActivityIndicator dismissWithCompletion:^{
                                      [OWSAlerts showAlertWithTitle:NSLocalizedString(@"UNREGISTER_SIGNAL_FAIL", @"")];
                                  }];
                              });
                          }];
                  }];
}

#pragma mark - Socket Status Notifications

- (void)observeNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(socketStateDidChange)
                                                 name:kNSNotification_SocketManagerStateDidChange
                                               object:nil];
}

- (void)socketStateDidChange
{
    OWSAssert([NSThread isMainThread]);

    [self updateTableContents];
}

@end
