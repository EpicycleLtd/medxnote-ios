//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "AppDelegate.h"
#import "AppStoreRating.h"
#import "AppUpdateNag.h"
#import "CodeVerificationViewController.h"
#import "DebugLogger.h"
#import "Environment.h"
#import "MedxPasscodeManager.h"
#import "NotificationsManager.h"
#import "OWSContactsManager.h"
#import "OWSContactsSyncing.h"
#import "OWSNavigationController.h"
#import "OWSPreferences.h"
#import "OWSProfileManager.h"
#import "Pastelog.h"
#import "PushManager.h"
#import "RegistrationViewController.h"
#import "Release.h"
#import "SendExternalFileViewController.h"
#import "Signal-Swift.h"
#import "SignalsNavigationController.h"
#import "VersionMigrations.h"
#import "ViewControllerUtils.h"
#import <AxolotlKit/SessionCipher.h>
#import <Reachability/Reachability.h>
#import <SignalServiceKit/OWSBatchMessageProcessor.h>
#import <SignalServiceKit/OWSDisappearingMessagesJob.h>
#import <SignalServiceKit/OWSFailedAttachmentDownloadsJob.h>
#import <SignalServiceKit/OWSFailedMessagesJob.h>
#import <SignalServiceKit/OWSMessageManager.h>
#import <SignalServiceKit/OWSMessageSender.h>
#import <SignalServiceKit/OWSOrphanedDataCleaner.h>
#import <SignalServiceKit/OWSReadReceiptManager.h>
#import <SignalServiceKit/TSAccountManager.h>
#import <SignalServiceKit/TSDatabaseView.h>
#import <SignalServiceKit/TSPreKeyManager.h>
#import <SignalServiceKit/TSSocketManager.h>
#import <SignalServiceKit/TSStorageManager+Calling.h>
#import <SignalServiceKit/TextSecureKitEnv.h>

@import WebRTC;
@import Intents;

NSString *const AppDelegateStoryboardMain = @"Main";

static NSString *const kInitialViewControllerIdentifier = @"UserInitialViewController";
static NSString *const kURLSchemeSGNLKey                = @"sgnl";
static NSString *const kURLHostVerifyPrefix             = @"verify";

@interface AppDelegate ()

@property (nonatomic) UIWindow *screenProtectionWindow;
@property (nonatomic) OWSContactsSyncing *contactsSyncing;
@property (nonatomic) BOOL hasInitialRootViewController;
    
// passcode
@property (nonatomic, copy) void (^onUnlock)(void);
@property (nonatomic, strong) PasscodeHelper *passcodeHelper;

@end

#pragma mark -

@implementation AppDelegate

@synthesize window = _window;

- (void)applicationDidEnterBackground:(UIApplication *)application {
    DDLogWarn(@"%@ applicationDidEnterBackground.", self.logTag);

    [DDLog flushLog];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    DDLogWarn(@"%@ applicationWillEnterForeground.", self.logTag);

    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    DDLogWarn(@"%@ applicationDidReceiveMemoryWarning.", self.logTag);
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    DDLogWarn(@"%@ applicationWillTerminate.", self.logTag);

    [DDLog flushLog];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL loggingIsEnabled;
#ifdef DEBUG
    // Specified at Product -> Scheme -> Edit Scheme -> Test -> Arguments -> Environment to avoid things like
    // the phone directory being looked up during tests.
    loggingIsEnabled = TRUE;
    [DebugLogger.sharedLogger enableTTYLogging];
#elif RELEASE
    loggingIsEnabled = OWSPreferences.loggingIsEnabled;
#endif
    if (loggingIsEnabled) {
        [DebugLogger.sharedLogger enableFileLogging];
    }

    DDLogWarn(@"%@ application: didFinishLaunchingWithOptions.", self.logTag);

    [AppVersion instance];

    [self startupLogging];

    // Set the seed the generator for rand().
    //
    // We should always use arc4random() instead of rand(), but we
    // still want to ensure that any third-party code that uses rand()
    // gets random values.
    srand((unsigned int)time(NULL));

    // XXX - careful when moving this. It must happen before we initialize TSStorageManager.
    [self verifyDBKeysAvailableBeforeBackgroundLaunch];

    // Prevent the device from sleeping during database view async registration
    // (e.g. long database upgrades).
    //
    // This block will be cleared in databaseViewRegistrationComplete.
    [DeviceSleepManager.sharedInstance addBlockWithBlockObject:self];

    [self setupEnvironment];

    [UIUtil applySignalAppearence];

    if (getenv("runningTests_dontStartApp")) {
        return YES;
    }

    self.passcodeHelper = [[PasscodeHelper alloc] init];
    self.window = [[ActivityWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Show the launch screen until the async database view registrations are complete.
    self.window.rootViewController = [self loadingRootViewController];

    [self.window makeKeyAndVisible];

    // performUpdateCheck must be invoked after Environment has been initialized because
    // upgrade process may depend on Environment.
    [VersionMigrations performUpdateCheck];

    // Accept push notification when app is not open
    NSDictionary *remoteNotif = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotif) {
        DDLogInfo(@"Application was launched by tapping a push notification.");
        [self application:application didReceiveRemoteNotification:remoteNotif];
    }

    [self prepareScreenProtection];
    [self setupReachability];

    self.contactsSyncing = [[OWSContactsSyncing alloc] initWithContactsManager:[Environment getCurrent].contactsManager
                                                               identityManager:[OWSIdentityManager sharedManager]
                                                                 messageSender:[Environment getCurrent].messageSender
                                                                profileManager:[OWSProfileManager sharedManager]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(databaseViewRegistrationComplete)
                                                 name:kNSNotificationName_DatabaseViewRegistrationComplete
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationStateDidChange)
                                                 name:kNSNotificationName_RegistrationStateDidChange
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(presentPasscodeEntry)
                                                 name:@"ActivityTimeoutExceeded"
                                               object:nil];

    DDLogInfo(@"%@ application: didFinishLaunchingWithOptions completed.", self.logTag);

    [OWSAnalytics appLaunchDidBegin];

    return YES;
}

- (void)startupLogging
{
    DDLogInfo(@"iOS Version: %@", [UIDevice currentDevice].systemVersion);

    NSString *localeIdentifier = [NSLocale.currentLocale objectForKey:NSLocaleIdentifier];
    if (localeIdentifier.length > 0) {
        DDLogInfo(@"Locale Identifier: %@", localeIdentifier);
    }
    NSString *countryCode = [NSLocale.currentLocale objectForKey:NSLocaleCountryCode];
    if (countryCode.length > 0) {
        DDLogInfo(@"Country Code: %@", countryCode);
    }
    NSString *languageCode = [NSLocale.currentLocale objectForKey:NSLocaleLanguageCode];
    if (languageCode.length > 0) {
        DDLogInfo(@"Language Code: %@", languageCode);
    }
}

- (UIViewController *)loadingRootViewController
{
    UIViewController *viewController =
        [[UIStoryboard storyboardWithName:@"Launch Screen" bundle:nil] instantiateInitialViewController];

    NSString *lastLaunchedAppVersion = AppVersion.instance.lastAppVersion;
    NSString *lastCompletedLaunchAppVersion = AppVersion.instance.lastCompletedLaunchAppVersion;
    // Every time we change or add a database view in such a way that
    // might cause a delay on launch, we need to bump this constant.
    //
    // We added a number of database views in v2.13.0.
    NSString *kLastVersionWithDatabaseViewChange = @"2.13.0";
    BOOL mayNeedUpgrade = ([TSAccountManager isRegistered] && lastLaunchedAppVersion
        && (!lastCompletedLaunchAppVersion ||
               [VersionMigrations isVersion:lastCompletedLaunchAppVersion
                                   lessThan:kLastVersionWithDatabaseViewChange]));
    DDLogInfo(@"%@ mayNeedUpgrade: %d", self.logTag, mayNeedUpgrade);
    if (mayNeedUpgrade) {
        UIView *rootView = viewController.view;
        UIImageView *iconView = nil;
        for (UIView *subview in viewController.view.subviews) {
            if ([subview isKindOfClass:[UIImageView class]]) {
                iconView = (UIImageView *)subview;
                break;
            }
        }
        if (!iconView) {
            OWSFail(@"Database view registration overlay has unexpected contents.");
        } else {
            UILabel *bottomLabel = [UILabel new];
            bottomLabel.text = NSLocalizedString(
                @"DATABASE_VIEW_OVERLAY_SUBTITLE", @"Subtitle shown while the app is updating its database.");
            bottomLabel.font = [UIFont ows_mediumFontWithSize:16.f];
            bottomLabel.textColor = [UIColor whiteColor];
            bottomLabel.numberOfLines = 0;
            bottomLabel.lineBreakMode = NSLineBreakByWordWrapping;
            bottomLabel.textAlignment = NSTextAlignmentCenter;
            [rootView addSubview:bottomLabel];

            UILabel *topLabel = [UILabel new];
            topLabel.text = NSLocalizedString(
                @"DATABASE_VIEW_OVERLAY_TITLE", @"Title shown while the app is updating its database.");
            topLabel.font = [UIFont ows_mediumFontWithSize:20.f];
            topLabel.textColor = [UIColor whiteColor];
            topLabel.numberOfLines = 0;
            topLabel.lineBreakMode = NSLineBreakByWordWrapping;
            topLabel.textAlignment = NSTextAlignmentCenter;
            [rootView addSubview:topLabel];

            [bottomLabel autoPinWidthToSuperviewWithMargin:20.f];
            [topLabel autoPinWidthToSuperviewWithMargin:20.f];
            [bottomLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:topLabel withOffset:10.f];
            [iconView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:bottomLabel withOffset:40.f];
        }
    }

    return viewController;
}

- (void)setupEnvironment
{
    [Environment setCurrent:[Release releaseEnvironment]];

    // Encryption/Descryption mutates session state and must be synchronized on a serial queue.
    [SessionCipher setSessionCipherDispatchQueue:[OWSDispatch sessionStoreQueue]];

    TextSecureKitEnv *sharedEnv =
        [[TextSecureKitEnv alloc] initWithCallMessageHandler:[Environment getCurrent].callMessageHandler
                                             contactsManager:[Environment getCurrent].contactsManager
                                               messageSender:[Environment getCurrent].messageSender
                                        notificationsManager:[Environment getCurrent].notificationsManager
                                              profileManager:OWSProfileManager.sharedManager];
    [TextSecureKitEnv setSharedEnv:sharedEnv];

    [[TSStorageManager sharedManager] setupDatabaseWithSafeBlockingMigrations:^{
        [VersionMigrations runSafeBlockingMigrations];
    }];
    [[Environment getCurrent].contactsManager startObserving];
}

- (void)setupReachability {
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    reach.reachableBlock = ^(Reachability *reachability) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"REACHABLE");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"InternetNowReachable" object:nil];
        });
    };
    
    reach.unreachableBlock = ^(Reachability *reachability) {
        NSLog(@"UNREACHABLE");
    };
    
    [reach startNotifier];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    DDLogInfo(@"%@ registered vanilla push token: %@", self.logTag, deviceToken);
    [PushRegistrationManager.sharedManager didReceiveVanillaPushToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    DDLogError(@"%@ failed to register vanilla push token with error: %@", self.logTag, error);
#ifdef DEBUG
    DDLogWarn(
        @"%@ We're in debug mode. Faking success for remote registration with a fake push identifier", self.logTag);
    [PushRegistrationManager.sharedManager didReceiveVanillaPushToken:[[NSMutableData dataWithLength:32] copy]];
#else
    OWSProdError([OWSAnalyticsEvents appDelegateErrorFailedToRegisterForRemoteNotifications]);
    [PushRegistrationManager.sharedManager didFailToReceiveVanillaPushTokenWithError:error];
#endif
}

- (void)application:(UIApplication *)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    DDLogInfo(@"%@ registered user notification settings", self.logTag);
    [PushRegistrationManager.sharedManager didRegisterUserNotificationSettings];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    if ([url.scheme isEqualToString:kURLSchemeSGNLKey]) {
        if ([url.host hasPrefix:kURLHostVerifyPrefix] && ![TSAccountManager isRegistered]) {
            id signupController = [Environment getCurrent].signUpFlowNavigationController;
            if ([signupController isKindOfClass:[UINavigationController class]]) {
                UINavigationController *navController = (UINavigationController *)signupController;
                UIViewController *controller          = [navController.childViewControllers lastObject];
                if ([controller isKindOfClass:[CodeVerificationViewController class]]) {
                    CodeVerificationViewController *cvvc = (CodeVerificationViewController *)controller;
                    NSString *verificationCode           = [url.path substringFromIndex:1];
                    [cvvc setVerificationCodeAndTryToVerify:verificationCode];
                } else {
                    DDLogWarn(@"Not the verification view controller we expected. Got %@ instead",
                              NSStringFromClass(controller.class));
                }
            }
        } else {
            DDLogWarn(@"Application opened with an unknown URL action: %@", url.host);
        }
    } else if ([url.scheme.lowercaseString isEqualToString:@"file"]) {

        if ([Environment getCurrent].callService.call != nil) {
            DDLogWarn(@"%@ ignoring 'open with Signal' due to ongoing WebRTC call.", self.logTag);
            return NO;
        }

        NSString *filename = url.lastPathComponent;
        if ([filename stringByDeletingPathExtension].length < 1) {
            DDLogError(@"Application opened with URL invalid filename: %@", url);
            [OWSAlerts showAlertWithTitle:
                           NSLocalizedString(@"EXPORT_WITH_SIGNAL_ERROR_TITLE",
                               @"Title for the alert indicating the 'export with signal' attachment had an error.")
                                  message:NSLocalizedString(@"EXPORT_WITH_SIGNAL_ERROR_MESSAGE_INVALID_FILENAME",
                                              @"Message for the alert indicating the 'export with signal' file had an "
                                              @"invalid filename.")];
            return NO;
        }
        NSString *fileExtension = [filename pathExtension];
        if (fileExtension.length < 1) {
            DDLogError(@"Application opened with URL missing file extension: %@", url);
            [OWSAlerts showAlertWithTitle:
                           NSLocalizedString(@"EXPORT_WITH_SIGNAL_ERROR_TITLE",
                               @"Title for the alert indicating the 'export with signal' attachment had an error.")
                                  message:NSLocalizedString(@"EXPORT_WITH_SIGNAL_ERROR_MESSAGE_UNKNOWN_TYPE",
                                              @"Message for the alert indicating the 'export with signal' file had "
                                              @"unknown type.")];
            return NO;
        }
        
        
        NSString *utiType;
        NSError *typeError;
        [url getResourceValue:&utiType forKey:NSURLTypeIdentifierKey error:&typeError];
        if (typeError) {
            OWSFail(@"%@ Determining type of picked document at url: %@ failed with error: %@",
                self.logTag,
                url,
                typeError);
            return NO;
        }
        if (!utiType) {
            OWSFail(@"%@ falling back to default filetype for picked document at url: %@", self.logTag, url);
            utiType = (__bridge NSString *)kUTTypeData;
            return NO;
        }
        
        NSNumber *isDirectory;
        NSError *isDirectoryError;
        [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&isDirectoryError];
        if (isDirectoryError) {
            OWSFail(@"%@ Determining if picked document at url: %@ was a directory failed with error: %@",
                self.logTag,
                url,
                isDirectoryError);
            return NO;
        } else if ([isDirectory boolValue]) {
            DDLogInfo(@"%@ User picked directory at url: %@", self.logTag, url);
            DDLogError(@"Application opened with URL of unknown UTI type: %@", url);
            [OWSAlerts
                showAlertWithTitle:
                    NSLocalizedString(@"ATTACHMENT_PICKER_DOCUMENTS_PICKED_DIRECTORY_FAILED_ALERT_TITLE",
                        @"Alert title when picking a document fails because user picked a directory/bundle")
                           message:
                               NSLocalizedString(@"ATTACHMENT_PICKER_DOCUMENTS_PICKED_DIRECTORY_FAILED_ALERT_BODY",
                                   @"Alert body when picking a document fails because user picked a directory/bundle")];
            return NO;
        }

        DataSource *_Nullable dataSource = [DataSourcePath dataSourceWithURL:url];
        if (!dataSource) {
            DDLogError(@"Application opened with URL with unloadable content: %@", url);
            [OWSAlerts showAlertWithTitle:
                           NSLocalizedString(@"EXPORT_WITH_SIGNAL_ERROR_TITLE",
                               @"Title for the alert indicating the 'export with signal' attachment had an error.")
                                  message:NSLocalizedString(@"EXPORT_WITH_SIGNAL_ERROR_MESSAGE_MISSING_DATA",
                                              @"Message for the alert indicating the 'export with signal' data "
                                              @"couldn't be loaded.")];
            return NO;
        }
        [dataSource setSourceFilename:filename];

        SignalAttachment *attachment = [SignalAttachment attachmentWithDataSource:dataSource dataUTI:utiType];
        if (!attachment) {
            DDLogError(@"Application opened with URL with invalid content: %@", url);
            [OWSAlerts showAlertWithTitle:
                           NSLocalizedString(@"EXPORT_WITH_SIGNAL_ERROR_TITLE",
                               @"Title for the alert indicating the 'export with signal' attachment had an error.")
                                  message:NSLocalizedString(@"EXPORT_WITH_SIGNAL_ERROR_MESSAGE_MISSING_ATTACHMENT",
                                              @"Message for the alert indicating the 'export with signal' attachment "
                                              @"couldn't be loaded.")];
            return NO;
        }
        if ([attachment hasError]) {
            DDLogError(@"Application opened with URL with content error: %@ %@", url, [attachment errorName]);
            [OWSAlerts showAlertWithTitle:
                           NSLocalizedString(@"EXPORT_WITH_SIGNAL_ERROR_TITLE",
                               @"Title for the alert indicating the 'export with signal' attachment had an error.")
                                  message:[attachment errorName]];
            return NO;
        }
        DDLogInfo(@"Application opened with URL: %@", url);

        if ([TSAccountManager isRegistered]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Wait up to N seconds for database view registrations to
                // complete.
                [self showImportUIForAttachment:attachment remainingRetries:5];
            });
        }

        return YES;
    } else {
        DDLogWarn(@"Application opened with an unknown URL scheme: %@", url.scheme);
    }
    return NO;
}

- (void)showImportUIForAttachment:(SignalAttachment *)attachment remainingRetries:(int)remainingRetries
{
    OWSAssert([NSThread isMainThread]);
    OWSAssert(attachment);
    OWSAssert(remainingRetries > 0);

    if ([TSDatabaseView hasPendingViewRegistrations]) {
        if (remainingRetries < 1) {
            DDLogInfo(@"Ignoring 'Import with Signal...' due to pending view registrations.");
        } else {
            DDLogInfo(@"Delaying 'Import with Signal...' due to pending view registrations.");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)1.f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if (![TSDatabaseView hasPendingViewRegistrations]) {
                    [self showImportUIForAttachment:attachment remainingRetries:remainingRetries - 1];
                }
            });
        }
        return;
    }

    SendExternalFileViewController *viewController = [SendExternalFileViewController new];
    viewController.attachment = attachment;
    UINavigationController *navigationController =
        [[UINavigationController alloc] initWithRootViewController:viewController];
    [[[Environment getCurrent] homeViewController] presentTopLevelModalViewController:navigationController
                                                                     animateDismissal:NO
                                                                  animatePresentation:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    DDLogWarn(@"%@ applicationDidBecomeActive.", self.logTag);

    if (getenv("runningTests_dontStartApp")) {
        return;
    }
    
    [self ensureRootViewController];
    
    // this needs to happen after root is set up
    [self removeScreenProtection];

    // Always check prekeys after app launches, and sometimes check on app activation.
    [TSPreKeyManager checkPreKeysIfNecessary];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        RTCInitializeSSL();

        if ([TSAccountManager isRegistered]) {
            // At this point, potentially lengthy DB locking migrations could be running.
            // Avoid blocking app launch by putting all further possible DB access in async block
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                DDLogInfo(@"%@ running post launch block for registered user: %@",
                    self.logTag,
                    [TSAccountManager localNumber]);

                // Clean up any messages that expired since last launch immediately
                // and continue cleaning in the background.
                [[OWSDisappearingMessagesJob sharedJob] startIfNecessary];

                // TODO remove this once we're sure our app boot process is coherent.
                // Currently this happens *before* db registration is complete when
                // launching the app directly, but *after* db registration is complete when
                // the app is launched in the background, e.g. from a voip notification.
                [[OWSProfileManager sharedManager] ensureLocalProfileCached];

                // Mark all "attempting out" messages as "unsent", i.e. any messages that were not successfully
                // sent before the app exited should be marked as failures.
                [[[OWSFailedMessagesJob alloc] initWithStorageManager:[TSStorageManager sharedManager]] run];
                [[[OWSFailedAttachmentDownloadsJob alloc] initWithStorageManager:[TSStorageManager sharedManager]] run];

//                [AppStoreRating setupRatingLibrary];
            });
        } else {
            DDLogInfo(@"%@ running post launch block for unregistered user.", self.logTag);

            // Unregistered user should have no unread messages. e.g. if you delete your account.
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];

            [TSSocketManager requestSocketOpen];

            UITapGestureRecognizer *gesture =
                [[UITapGestureRecognizer alloc] initWithTarget:[Pastelog class] action:@selector(submitLogs)];
            gesture.numberOfTapsRequired = 8;
            [self.window addGestureRecognizer:gesture];
        }
    }); // end dispatchOnce for first time we become active

    // Every time we become active...
    if ([TSAccountManager isRegistered]) {
        // At this point, potentially lengthy DB locking migrations could be running.
        // Avoid blocking app launch by putting all further possible DB access in async block
        dispatch_async(dispatch_get_main_queue(), ^{
            [TSSocketManager requestSocketOpen];
            [[Environment getCurrent].contactsManager fetchSystemContactsOnceIfAlreadyAuthorized];
            // This will fetch new messages, if we're using domain fronting.
            [[PushManager sharedManager] applicationDidBecomeActive];

            if (![UIApplication sharedApplication].isRegisteredForRemoteNotifications) {
                DDLogInfo(
                    @"%@ Retrying to register for remote notifications since user hasn't registered yet.", self.logTag);
                // Push tokens don't normally change while the app is launched, so checking once during launch is
                // usually sufficient, but e.g. on iOS11, users who have disabled "Allow Notifications" and disabled
                // "Background App Refresh" will not be able to obtain an APN token. Enabling those settings does not
                // restart the app, so we check every activation for users who haven't yet registered.
                __unused AnyPromise *promise =
                    [OWSSyncPushTokensJob runWithAccountManager:[Environment getCurrent].accountManager
                                                    preferences:[Environment preferences]];
            }
        });
        
    }

    DDLogInfo(@"%@ applicationDidBecomeActive completed.", self.logTag);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    DDLogWarn(@"%@ applicationWillResignActive.", self.logTag);

    UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([TSAccountManager isRegistered]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
                    // If app has not re-entered active, show screen protection if necessary.
                    [self showScreenProtection];
                }
                [[[Environment getCurrent] homeViewController] updateInboxCountLabel];
                [application endBackgroundTask:bgTask];
            });
        }
    });

    [DDLog flushLog];
}

- (void)application:(UIApplication *)application
    performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler {
    BOOL passcodeNeeded = [self removeScreenProtection];
    __weak typeof(self) weakSelf = self;
    if (passcodeNeeded) {
        // pin needs to be input before proceeding so this action is stored for later
        self.onUnlock = ^void() {
            [weakSelf application:application performActionForShortcutItem:shortcutItem completionHandler:completionHandler];
        };
        completionHandler(NO);
        return;
    }
    if ([TSAccountManager isRegistered]) {
        [[Environment getCurrent].homeViewController showNewConversationView];
        completionHandler(YES);
    } else {
        UIAlertController *controller =
            [UIAlertController alertControllerWithTitle:NSLocalizedString(@"REGISTER_CONTACTS_WELCOME", nil)
                                                message:NSLocalizedString(@"REGISTRATION_RESTRICTED_MESSAGE", nil)
                                         preferredStyle:UIAlertControllerStyleAlert];

        [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *_Nonnull action){

                                                     }]];
        UIViewController *fromViewController = [[UIApplication sharedApplication] frontmostViewController];
        [fromViewController presentViewController:controller
                                         animated:YES
                                       completion:^{
                                           completionHandler(NO);
                                       }];
    }
}

/**
 * Among other things, this is used by "call back" callkit dialog and calling from native contacts app.
 */
- (BOOL)application:(UIApplication *)application continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(nonnull void (^)(NSArray * _Nullable))restorationHandler
{
    if ([userActivity.activityType isEqualToString:@"INStartVideoCallIntent"]) {
        if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(10, 0)) {
            DDLogError(@"%@ unexpectedly received INStartVideoCallIntent pre iOS10", self.logTag);
            return NO;
        }

        DDLogInfo(@"%@ got start video call intent", self.logTag);

        INInteraction *interaction = [userActivity interaction];
        INIntent *intent = interaction.intent;

        if (![intent isKindOfClass:[INStartVideoCallIntent class]]) {
            DDLogError(@"%@ unexpected class for start call video: %@", self.logTag, intent);
            return NO;
        }
        INStartVideoCallIntent *startCallIntent = (INStartVideoCallIntent *)intent;
        NSString *_Nullable handle = startCallIntent.contacts.firstObject.personHandle.value;
        if (!handle) {
            DDLogWarn(@"%@ unable to find handle in startCallIntent: %@", self.logTag, startCallIntent);
            return NO;
        }

        NSString *_Nullable phoneNumber = handle;
        if ([handle hasPrefix:CallKitCallManager.kAnonymousCallHandlePrefix]) {
            phoneNumber = [[TSStorageManager sharedManager] phoneNumberForCallKitId:handle];
            if (phoneNumber.length < 1) {
                DDLogWarn(@"%@ ignoring attempt to initiate video call to unknown anonymous signal user.", self.logTag);
                return NO;
            }
        }

        // This intent can be received from more than one user interaction.
        //
        // * It can be received if the user taps the "video" button in the CallKit UI for an
        //   an ongoing call.  If so, the correct response is to try to activate the local
        //   video for that call.
        // * It can be received if the user taps the "video" button for a contact in the
        //   contacts app.  If so, the correct response is to try to initiate a new call
        //   to that user - unless there already is another call in progress.
        if ([Environment getCurrent].callService.call != nil) {
            if ([phoneNumber isEqualToString:[Environment getCurrent].callService.call.remotePhoneNumber]) {
                DDLogWarn(@"%@ trying to upgrade ongoing call to video.", self.logTag);
                [[Environment getCurrent].callService handleCallKitStartVideo];
                return YES;
            } else {
                DDLogWarn(
                    @"%@ ignoring INStartVideoCallIntent due to ongoing WebRTC call with another party.", self.logTag);
                return NO;
            }
        }

        OutboundCallInitiator *outboundCallInitiator = [Environment getCurrent].outboundCallInitiator;
        OWSAssert(outboundCallInitiator);
        return [outboundCallInitiator initiateCallWithHandle:phoneNumber];
    } else if ([userActivity.activityType isEqualToString:@"INStartAudioCallIntent"]) {

        if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(10, 0)) {
            DDLogError(@"%@ unexpectedly received INStartAudioCallIntent pre iOS10", self.logTag);
            return NO;
        }

        DDLogInfo(@"%@ got start audio call intent", self.logTag);

        INInteraction *interaction = [userActivity interaction];
        INIntent *intent = interaction.intent;

        if (![intent isKindOfClass:[INStartAudioCallIntent class]]) {
            DDLogError(@"%@ unexpected class for start call audio: %@", self.logTag, intent);
            return NO;
        }
        INStartAudioCallIntent *startCallIntent = (INStartAudioCallIntent *)intent;
        NSString *_Nullable handle = startCallIntent.contacts.firstObject.personHandle.value;
        if (!handle) {
            DDLogWarn(@"%@ unable to find handle in startCallIntent: %@", self.logTag, startCallIntent);
            return NO;
        }

        NSString *_Nullable phoneNumber = handle;
        if ([handle hasPrefix:CallKitCallManager.kAnonymousCallHandlePrefix]) {
            phoneNumber = [[TSStorageManager sharedManager] phoneNumberForCallKitId:handle];
            if (phoneNumber.length < 1) {
                DDLogWarn(@"%@ ignoring attempt to initiate audio call to unknown anonymous signal user.", self.logTag);
                return NO;
            }
        }

        if ([Environment getCurrent].callService.call != nil) {
            DDLogWarn(@"%@ ignoring INStartAudioCallIntent due to ongoing WebRTC call.", self.logTag);
            return NO;
        }

        OutboundCallInitiator *outboundCallInitiator = [Environment getCurrent].outboundCallInitiator;
        OWSAssert(outboundCallInitiator);
        return [outboundCallInitiator initiateCallWithHandle:phoneNumber];
    } else {
        DDLogWarn(@"%@ called %s with userActivity: %@, but not yet supported.",
            self.logTag,
            __PRETTY_FUNCTION__,
            userActivity.activityType);
    }

    // TODO Something like...
    // *phoneNumber = [[[[[[userActivity interaction] intent] contacts] firstObject] personHandle] value]
    // thread = blah
    // [callUIAdapter startCall:thread]
    //
    // Here's the Speakerbox Example for intent / NSUserActivity handling:
    //
    //    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
    //        guard let handle = userActivity.startCallHandle else {
    //            print("Could not determine start call handle from user activity: \(userActivity)")
    //            return false
    //        }
    //
    //        guard let video = userActivity.video else {
    //            print("Could not determine video from user activity: \(userActivity)")
    //            return false
    //        }
    //
    //        callManager.startCall(handle: handle, video: video)
    //        return true
    //    }
    return NO;
}


/**
 * Screen protection obscures the app screen shown in the app switcher.
 */
- (void)prepareScreenProtection
{
    UIWindow *window = [[UIWindow alloc] initWithFrame:self.window.bounds];
    window.hidden = NO;
    window.opaque = YES;
    window.userInteractionEnabled = NO;
    window.windowLevel = CGFLOAT_MAX;
    window.backgroundColor = UIColor.ows_materialBlueColor;
    window.rootViewController =
        [[UIStoryboard storyboardWithName:@"Launch Screen" bundle:nil] instantiateInitialViewController];

    self.screenProtectionWindow = window;
}

- (void)showScreenProtection
{
    [MedxPasscodeManager storeLastActivityTime:[NSDate date]];
    if (Environment.preferences.screenSecurityIsEnabled) {
        self.screenProtectionWindow.hidden = NO;
    }
}

- (BOOL)removeScreenProtection
{
    // get time when user exited the app and present passcode prompt if needed
    NSNumber *timeout = [MedxPasscodeManager inactivityTimeout];
    BOOL shouldShowPasscode = [MedxPasscodeManager lastActivityTime].timeIntervalSinceNow < -timeout.intValue || [MedxPasscodeManager isPasscodeChangeRequired];
    if ([MedxPasscodeManager isPasscodeEnabled] && shouldShowPasscode) {
        [self presentPasscodeEntry];
    }
    if ([MedxPasscodeManager isLockoutEnabled]) {
        return shouldShowPasscode;
    }
    if (Environment.preferences.screenSecurityIsEnabled) {
        self.screenProtectionWindow.hidden = YES;
    }
    return shouldShowPasscode;
}
    
- (void)presentPasscodeEntry
{
    if ([[UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController isKindOfClass:[TOPasscodeViewController class]]) {
        // no need to present again
        return;
    }
    if ([UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController != nil) {
        [[UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController dismissViewControllerAnimated:false completion:nil];
    }
    BOOL isPasscodeChangeRequired = [MedxPasscodeManager isPasscodeChangeRequired];
    PasscodeHelperAction type = isPasscodeChangeRequired ? PasscodeHelperActionChangePasscode : PasscodeHelperActionCheckPasscode;
    TOPasscodeViewController *vc = [self.passcodeHelper initiateAction:type from:UIApplication.sharedApplication.keyWindow.rootViewController completion:^{
        [(ActivityWindow *)UIApplication.sharedApplication.keyWindow restartTimer];
        if (self.onUnlock != nil) {
            self.onUnlock();
            self.onUnlock = nil; // not needed anymore
        }
    }];
    if (isPasscodeChangeRequired) {
        vc.passcodeView.titleLabel.text = @"Enter your old passcode. You will be required to change your passcode to match the new security requirements.";
    }
}

#pragma mark Push Notifications Delegate Methods

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[PushManager sharedManager] application:application didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[PushManager sharedManager] application:application
                didReceiveRemoteNotification:userInfo
                      fetchCompletionHandler:completionHandler];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    OWSAssert([NSThread isMainThread]);

    if (!self.isEnvironmentSetup) {
        OWSFail(@"%@ ignoring %s because environment is not yet set up: %@.",
            self.logTag,
            __PRETTY_FUNCTION__,
            notification);
        return;
    }
    DDLogInfo(@"%@ %s %@", self.logTag, __PRETTY_FUNCTION__, notification);

//    [AppStoreRating preventPromptAtNextTest];
    [[PushManager sharedManager] application:application didReceiveLocalNotification:notification];
}

- (void)application:(UIApplication *)application
    handleActionWithIdentifier:(NSString *)identifier
          forLocalNotification:(UILocalNotification *)notification
             completionHandler:(void (^)())completionHandler
{
    if (!self.isEnvironmentSetup) {
        OWSFail(@"%@ ignoring %s because environment is not yet set up.", self.logTag, __PRETTY_FUNCTION__);
        return;
    }

    [[PushManager sharedManager] application:application
                  handleActionWithIdentifier:identifier
                        forLocalNotification:notification
                           completionHandler:completionHandler];
}

- (void)application:(UIApplication *)application
    handleActionWithIdentifier:(NSString *)identifier
          forLocalNotification:(UILocalNotification *)notification
              withResponseInfo:(NSDictionary *)responseInfo
             completionHandler:(void (^)())completionHandler
{
    if (!self.isEnvironmentSetup) {
        OWSFail(@"%@ ignoring %s because environment is not yet set up.", self.logTag, __PRETTY_FUNCTION__);
        return;
    }

    [[PushManager sharedManager] application:application
                  handleActionWithIdentifier:identifier
                        forLocalNotification:notification
                            withResponseInfo:responseInfo
                           completionHandler:completionHandler];
}

/**
 *  The user must unlock the device once after reboot before the database encryption key can be accessed.
 */
- (void)verifyDBKeysAvailableBeforeBackgroundLaunch
{
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateBackground) {
        return;
    }

    if (![TSStorageManager isDatabasePasswordAccessible]) {
        DDLogInfo(
            @"%@ exiting because we are in the background and the database password is not accessible.", self.logTag);
        [DDLog flushLog];
        exit(0);
    }
}

- (void)databaseViewRegistrationComplete
{
    DDLogInfo(@"%@ databaseViewRegistrationComplete", self.logTag);

    if ([TSAccountManager isRegistered]) {
        DDLogInfo(@"localNumber: %@", [TSAccountManager localNumber]);

        // Fetch messages as soon as possible after launching. In particular, when
        // launching from the background, without this, we end up waiting some extra
        // seconds before receiving an actionable push notification.
        __unused AnyPromise *messagePromise = [[Environment getCurrent].messageFetcherJob run];

        // This should happen at any launch, background or foreground.
        __unused AnyPromise *pushTokenpromise =
            [OWSSyncPushTokensJob runWithAccountManager:[Environment getCurrent].accountManager
                                            preferences:[Environment preferences]];
    }

    [DeviceSleepManager.sharedInstance removeBlockWithBlockObject:self];

    [AppVersion.instance appLaunchDidComplete];

    [[Environment getCurrent].contactsManager loadSignalAccountsFromCache];
    
    [self ensureRootViewController];

    // If there were any messages in our local queue which we hadn't yet processed.
    [[OWSMessageReceiver sharedInstance] handleAnyUnprocessedEnvelopesAsync];
    [[OWSBatchMessageProcessor sharedInstance] handleAnyUnprocessedEnvelopesAsync];

    [[OWSProfileManager sharedManager] ensureLocalProfileCached];

    self.isEnvironmentSetup = YES;

#ifdef DEBUG
    // A bug in orphan cleanup could be disastrous so let's only
    // run it in DEBUG builds for a few releases.
    //
    // TODO: Release to production once we have analytics.
    // TODO: Orphan cleanup is somewhat expensive - not least in doing a bunch
    //       of disk access.  We might want to only run it "once per version"
    //       or something like that in production.
    [OWSOrphanedDataCleaner auditAndCleanupAsync:nil];
#endif

    [OWSProfileManager.sharedManager fetchLocalUsersProfile];
    [[OWSReadReceiptManager sharedManager] prepareCachedValues];
    [OWSReadReceiptManager.sharedManager setAreReadReceiptsEnabled:true]; // enable always
}

- (void)registrationStateDidChange
{
    OWSAssert([NSThread isMainThread]);

    DDLogInfo(@"registrationStateDidChange");

    if ([TSAccountManager isRegistered]) {
        DDLogInfo(@"localNumber: %@", [TSAccountManager localNumber]);

        [[TSStorageManager sharedManager].newDatabaseConnection
            readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
                [[ExperienceUpgradeFinder new] markAllAsSeenWithTransaction:transaction];
            }];
        // Start running the disappearing messages job in case the newly registered user
        // enables this feature
        [[OWSDisappearingMessagesJob sharedJob] startIfNecessary];
        [[OWSProfileManager sharedManager] ensureLocalProfileCached];

        // For non-legacy users, read receipts are on by default.
        [OWSReadReceiptManager.sharedManager setAreReadReceiptsEnabled:YES];
    }
}

- (void)ensureRootViewController
{
    DDLogInfo(@"%@ ensureRootViewController", self.logTag);

    if ([TSDatabaseView hasPendingViewRegistrations] || self.hasInitialRootViewController) {
        return;
    }
    self.hasInitialRootViewController = YES;

    DDLogInfo(@"Presenting initial root view controller");

    if ([TSAccountManager isRegistered]) {
        HomeViewController *homeView = [HomeViewController new];
        SignalsNavigationController *navigationController =
            [[SignalsNavigationController alloc] initWithRootViewController:homeView];
        self.window.rootViewController = navigationController;
    } else {
        RegistrationViewController *viewController = [RegistrationViewController new];
        OWSNavigationController *navigationController =
            [[OWSNavigationController alloc] initWithRootViewController:viewController];
        navigationController.navigationBarHidden = YES;
        self.window.rootViewController = navigationController;
    }

    [AppUpdateNag.sharedInstance showAppUpgradeNagIfNecessary];
}

@end
