//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "PrivacySettingsTableViewController.h"
#import "BlockListViewController.h"
#import "Environment.h"
#import "MedxPasscodeManager.h"
#import "OWSPreferences.h"
#import "Signal-Swift.h"
#import <SignalServiceKit/OWSReadReceiptManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface PrivacySettingsTableViewController ()
    
@property (nonatomic, strong) PasscodeHelper *passcodeHelper;
    
@end

@implementation PrivacySettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.passcodeHelper = [[PasscodeHelper alloc] init];
    self.title = NSLocalizedString(@"SETTINGS_PRIVACY_TITLE", @"");

    [self updateTableContents];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self updateTableContents];
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];

    __weak PrivacySettingsTableViewController *weakSelf = self;

    [contents
        addSection:[OWSTableSection
                       sectionWithTitle:nil
                                  items:@[
                                      [OWSTableItem disclosureItemWithText:
                                                        NSLocalizedString(@"SETTINGS_BLOCK_LIST_TITLE",
                                                            @"Label for the block list section of the settings view")
                                                               actionBlock:^{
                                                                   [weakSelf showBlocklist];
                                                               }],
                                  ]]];

    OWSTableSection *readReceiptsSection = [OWSTableSection new];
    readReceiptsSection.footerTitle = NSLocalizedString(
        @"SETTINGS_READ_RECEIPTS_SECTION_FOOTER", @"An explanation of the 'read receipts' setting.");
    [readReceiptsSection
        addItem:[OWSTableItem switchItemWithText:NSLocalizedString(@"SETTINGS_READ_RECEIPT",
                                                     @"Label for the 'read receipts' setting.")
                                            isOn:[OWSReadReceiptManager.sharedManager areReadReceiptsEnabled]
                                          target:weakSelf
                                        selector:@selector(didToggleReadReceiptsSwitch:)]];
    [contents addSection:readReceiptsSection];

    OWSTableSection *screenSecuritySection = [OWSTableSection new];
    screenSecuritySection.headerTitle = NSLocalizedString(@"SETTINGS_SECURITY_TITLE", @"Section header");
    screenSecuritySection.footerTitle = NSLocalizedString(@"Prevent Medxnote previews from appearing in the app switcher.", @"");
//    screenSecuritySection.footerTitle = NSLocalizedString(@"SETTINGS_SCREEN_SECURITY_DETAIL", nil);
    [screenSecuritySection addItem:[OWSTableItem switchItemWithText:NSLocalizedString(@"SETTINGS_SCREEN_SECURITY", @"")
                                                               isOn:[Environment.preferences screenSecurityIsEnabled]
                                                             target:weakSelf
                                                           selector:@selector(didToggleScreenSecuritySwitch:)]];
    [contents addSection:screenSecuritySection];
    
    [self addMedxSpecificContent:contents];

    // Allow calls to connect directly vs. using TURN exclusively
    OWSTableSection *callingSection = [OWSTableSection new];
    callingSection.headerTitle
        = NSLocalizedString(@"SETTINGS_SECTION_TITLE_CALLING", @"settings topic header for table section");
    callingSection.footerTitle = NSLocalizedString(@"Relay all calls through the Medxnote server to avoid revealing your IP address to your contact. Enabling will reduce call quality.", @"");
//    callingSection.footerTitle = NSLocalizedString(@"SETTINGS_CALLING_HIDES_IP_ADDRESS_PREFERENCE_TITLE_DETAIL",
//        @"User settings section footer, a detailed explanation");
    [callingSection addItem:[OWSTableItem switchItemWithText:NSLocalizedString(
                                                                 @"SETTINGS_CALLING_HIDES_IP_ADDRESS_PREFERENCE_TITLE",
                                                                 @"Table cell label")
                                                        isOn:[Environment.preferences doCallsHideIPAddress]
                                                      target:weakSelf
                                                    selector:@selector(didToggleCallsHideIPAddressSwitch:)]];
    [contents addSection:callingSection];

    if ([UIDevice currentDevice].supportsCallKit) {
        OWSTableSection *callKitSection = [OWSTableSection new];
        callKitSection.footerTitle = NSLocalizedString(@"iOS Call Integration shows Medxnote calls on your lock screen and in the system's call history. You may optionally show your contact's name and number. If iCloud is enabled, this call history will be shared with Apple.", @"");
//        callKitSection.footerTitle
//            = NSLocalizedString(@"SETTINGS_SECTION_CALL_KIT_DESCRIPTION", @"Settings table section footer.");
        [callKitSection addItem:[OWSTableItem switchItemWithText:NSLocalizedString(@"SETTINGS_PRIVACY_CALLKIT_TITLE",
                                                                     @"Short table cell label")
                                                            isOn:[Environment.preferences isCallKitEnabled]
                                                          target:weakSelf
                                                        selector:@selector(didToggleEnableCallKitSwitch:)]];
        if (Environment.preferences.isCallKitEnabled) {
            [callKitSection
                addItem:[OWSTableItem switchItemWithText:NSLocalizedString(@"SETTINGS_PRIVACY_CALLKIT_PRIVACY_TITLE",
                                                             @"Label for 'CallKit privacy' preference")
                                                    isOn:![Environment.preferences isCallKitPrivacyEnabled]
                                                  target:weakSelf
                                                selector:@selector(didToggleEnableCallKitPrivacySwitch:)]];
        }
        [contents addSection:callKitSection];
    }

    OWSTableSection *historyLogsSection = [OWSTableSection new];
    historyLogsSection.headerTitle = NSLocalizedString(@"SETTINGS_HISTORYLOG_TITLE", @"Section header");
    [historyLogsSection addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"SETTINGS_CLEAR_HISTORY", @"")
                                                         actionBlock:^{
                                                             [weakSelf clearHistoryLogs];
                                                         }]];
    [contents addSection:historyLogsSection];

    self.contents = contents;
}
    
- (void)addMedxSpecificContent:(OWSTableContents *)contents {
    __weak PrivacySettingsTableViewController *weakSelf = self;
    OWSTableSection *screenSecuritySection = [OWSTableSection new];
    screenSecuritySection.headerTitle = NSLocalizedString(@"Passcode", @"Section header");
    // TODO: add TouchID/FaceID setting
    [screenSecuritySection addItem:[OWSTableItem switchItemWithText:NSLocalizedString(@"Passcode Security", @"")
                                                               isOn:[MedxPasscodeManager isPasscodeEnabled]
                                                          isEnabled:false
                                                             target:weakSelf
                                                           selector:@selector(didTogglePasscodeEnabled:)]];
    [contents addSection:screenSecuritySection];
}

#pragma mark - Events

- (void)showBlocklist
{
    BlockListViewController *vc = [BlockListViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)clearHistoryLogs
{
    UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:nil
                                            message:NSLocalizedString(@"SETTINGS_DELETE_HISTORYLOG_CONFIRMATION",
                                                        @"Alert message before user confirms clearing history")
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:[OWSAlerts cancelAction]];

    UIAlertAction *deleteAction =
        [UIAlertAction actionWithTitle:NSLocalizedString(@"SETTINGS_DELETE_HISTORYLOG_CONFIRMATION_BUTTON", @"")
                                 style:UIAlertActionStyleDestructive
                               handler:^(UIAlertAction *_Nonnull action) {
                                   [[TSStorageManager sharedManager] deleteThreadsAndMessages];
                               }];
    [alertController addAction:deleteAction];

    [self presentViewController:alertController animated:true completion:nil];
}

- (void)didToggleScreenSecuritySwitch:(UISwitch *)sender
{
    BOOL enabled = sender.isOn;
    DDLogInfo(@"%@ toggled screen security: %@", self.logTag, enabled ? @"ON" : @"OFF");
    [Environment.preferences setScreenSecurity:enabled];
}

- (void)didToggleReadReceiptsSwitch:(UISwitch *)sender
{
    BOOL enabled = sender.isOn;
    DDLogInfo(@"%@ toggled areReadReceiptsEnabled: %@", self.logTag, enabled ? @"ON" : @"OFF");
    [OWSReadReceiptManager.sharedManager setAreReadReceiptsEnabled:enabled];
}

- (void)didToggleCallsHideIPAddressSwitch:(UISwitch *)sender
{
    BOOL enabled = sender.isOn;
    DDLogInfo(@"%@ toggled callsHideIPAddress: %@", self.logTag, enabled ? @"ON" : @"OFF");
    [Environment.preferences setDoCallsHideIPAddress:enabled];
}

- (void)didToggleEnableCallKitSwitch:(UISwitch *)sender {
    DDLogInfo(@"%@ user toggled call kit preference: %@", self.logTag, (sender.isOn ? @"ON" : @"OFF"));
    [[Environment getCurrent].preferences setIsCallKitEnabled:sender.isOn];
    // rebuild callUIAdapter since CallKit vs not changed.
    [[Environment getCurrent].callService createCallUIAdapter];
    [self updateTableContents];
}

- (void)didToggleEnableCallKitPrivacySwitch:(UISwitch *)sender {
    DDLogInfo(@"%@ user toggled call kit privacy preference: %@", self.logTag, (sender.isOn ? @"ON" : @"OFF"));
    [[Environment getCurrent].preferences setIsCallKitPrivacyEnabled:!sender.isOn];
}
    
- (void)didTogglePasscodeEnabled:(UISwitch *)sender {
    if ([MedxPasscodeManager isPasscodeEnabled]) {
        [self.passcodeHelper initiateAction:PasscodeHelperActionDisablePasscode from:self completion:^{
            [sender setOn:false];
        }];
    } else {
        [self.passcodeHelper initiateAction:PasscodeHelperActionEnablePasscode from:self completion:^{
            [sender setOn:true];
        }];
    }
}

#pragma mark - Log util

+ (NSString *)tag
{
    return [NSString stringWithFormat:@"[%@]", self.class];
}

- (NSString *)tag
{
    return self.class.logTag;
}

@end

NS_ASSUME_NONNULL_END
