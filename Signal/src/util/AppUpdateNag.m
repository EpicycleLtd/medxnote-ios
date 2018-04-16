//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "AppUpdateNag.h"
#import "RegistrationViewController.h"
#import "Signal-Swift.h"
#import <ATAppUpdater/ATAppUpdater.h>
#import <SignalServiceKit/NSDate+OWS.h>
#import <SignalServiceKit/TSStorageManager.h>

NSString *const TSStorageManagerAppUpgradeNagCollection = @"TSStorageManagerAppUpgradeNagCollection";
NSString *const TSStorageManagerAppUpgradeNagDate = @"TSStorageManagerAppUpgradeNagDate";

@interface AppUpdateNag () <ATAppUpdaterDelegate>

@property (nonatomic, readonly) YapDatabaseConnection *dbConnection;

@end

#pragma mark -

@implementation AppUpdateNag

+ (instancetype)sharedInstance
{
    static AppUpdateNag *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initDefault];
    });
    return sharedInstance;
}

- (instancetype)initDefault
{
    TSStorageManager *storageManager = [TSStorageManager sharedManager];

    return [self initWithStorageManager:storageManager];
}

- (instancetype)initWithStorageManager:(TSStorageManager *)storageManager
{
    self = [super init];

    if (!self) {
        return self;
    }

    OWSAssert(storageManager);

    _dbConnection = storageManager.newDatabaseConnection;

    OWSSingletonAssert();

    return self;
}

- (void)showAppUpgradeNagIfNecessary
{
    // Only show nag if we are "at rest" in the home view or registration view without any
    // alerts or dialogs showing.
    UIViewController *frontmostViewController =
    [UIApplication sharedApplication].frontmostViewController;
    OWSAssert(frontmostViewController);
    BOOL canPresent = ([frontmostViewController isKindOfClass:[HomeViewController class]] ||
        [frontmostViewController isKindOfClass:[RegistrationViewController class]]);
    if (!canPresent) {
        return;
    }

    NSDate *lastNagDate = [self.dbConnection dateForKey:TSStorageManagerAppUpgradeNagDate
                                           inCollection:TSStorageManagerAppUpgradeNagCollection];
    const NSTimeInterval kNagFrequency = kDayInterval * 14;
    BOOL canNag = (!lastNagDate || fabs(lastNagDate.timeIntervalSinceNow) > kNagFrequency);
    if (!canNag) {
        return;
    }

    ATAppUpdater *updater = [ATAppUpdater sharedUpdater];
    [updater setAlertTitle:@"A new version of Medxnote is available"];
    [updater setAlertMessage:NSLocalizedString(@"APP_UPDATE_NAG_ALERT_MESSAGE_FORMAT",
                                 @"Message format for the 'new app version available' alert. Embeds: {{The latest app "
                                 @"version number.}}.")];
    [updater setAlertUpdateButtonTitle:NSLocalizedString(@"APP_UPDATE_NAG_ALERT_UPDATE_BUTTON",
                                           @"Label for the 'update' button in the 'new app version available' alert.")];
    [updater setAlertCancelButtonTitle:CommonStrings.cancelButton];
    [updater setDelegate:self];
    [updater showUpdateWithConfirmation];
}

#pragma mark - ATAppUpdaterDelegate

- (void)appUpdaterDidShowUpdateDialog
{
    DDLogInfo(@"%@ %s", self.logTag, __PRETTY_FUNCTION__);

    [self.dbConnection setDate:[NSDate new]
                        forKey:TSStorageManagerAppUpgradeNagDate
                  inCollection:TSStorageManagerAppUpgradeNagCollection];
}

- (void)appUpdaterUserDidLaunchAppStore
{
    DDLogInfo(@"%@ %s", self.logTag, __PRETTY_FUNCTION__);
}

- (void)appUpdaterUserDidCancel
{
    DDLogInfo(@"%@ %s", self.logTag, __PRETTY_FUNCTION__);
}

@end
