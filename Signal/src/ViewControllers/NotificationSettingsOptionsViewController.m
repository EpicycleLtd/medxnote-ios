//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "NotificationSettingsOptionsViewController.h"
#import "Environment.h"

@implementation NotificationSettingsOptionsViewController

- (void)viewDidLoad {
    [self updateTableContents];
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];

    __weak NotificationSettingsOptionsViewController *weakSelf = self;

    OWSTableSection *section = [OWSTableSection new];
    section.footerTitle = NSLocalizedString(@"NOTIFICATIONS_FOOTER_WARNING", nil);

    OWSPreferences *prefs = [Environment preferences];
    NotificationType selectedNotifType = [prefs notificationPreviewType];
    for (NSNumber *option in
        @[ @(NotificationNameNoPreview), @(NotificationNoNameNoPreview) ]) {
        NotificationType notificationType = (NotificationType)option.intValue;

        [section addItem:[OWSTableItem itemWithCustomCellBlock:^{
            UITableViewCell *cell = [UITableViewCell new];
            [[cell textLabel] setText:[prefs nameForNotificationPreviewType:notificationType]];
            if (selectedNotifType == notificationType) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            return cell;
        }
                             actionBlock:^{
                                 [weakSelf setNotificationType:notificationType];
                             }]];
    }
    [contents addSection:section];

    self.contents = contents;
}

- (void)setNotificationType:(NotificationType)notificationType
{
    [Environment.preferences setNotificationPreviewType:notificationType];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
