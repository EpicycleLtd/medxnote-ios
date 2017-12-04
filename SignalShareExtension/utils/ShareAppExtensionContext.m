//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "ShareAppExtensionContext.h"
#import <SignalMessaging/UIViewController+OWS.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShareAppExtensionContext ()

@property (nonatomic) UIViewController *rootViewController;

@end

#pragma mark -

@implementation ShareAppExtensionContext

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super init];

    if (!self) {
        return self;
    }

    OWSAssert(rootViewController);

    _rootViewController = rootViewController;

    OWSSingletonAssert();

    return self;
}

- (BOOL)isMainApp
{
    return NO;
}

- (BOOL)isMainAppAndActive
{
    return NO;
}

- (UIApplicationState)mainApplicationState
{
    OWSFail(@"%@ called %s.", self.logTag, __PRETTY_FUNCTION__);
    return UIApplicationStateBackground;
}

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:
    (BackgroundTaskExpirationHandler)expirationHandler
{
    return UIBackgroundTaskInvalid;
}

- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)backgroundTaskIdentifier
{
    OWSAssert(backgroundTaskIdentifier == UIBackgroundTaskInvalid);
}

- (void)setMainAppBadgeNumber:(NSInteger)value
{
    OWSFail(@"%@ called %s.", self.logTag, __PRETTY_FUNCTION__);
}

- (NSArray<OWSDatabaseMigration *> *)allMigrations
{
    return @[];
}

- (NSArray<OWSDatabaseMigration *> *)safeBlockingMigrations
{
    return @[];
}

- (nullable UIViewController *)frontmostViewController
{
    OWSAssert(self.rootViewController);

    return [self.rootViewController findFrontmostViewController:YES];
}

- (void)openSystemSettings
{
    OWSFail(@"%@ called %s.", self.logTag, __PRETTY_FUNCTION__);
}

- (void)doMultiDeviceUpdateWithProfileKey:(OWSAES256Key *)profileKey
{
    OWSFail(@"%@ called %s.", self.logTag, __PRETTY_FUNCTION__);
}

@end

NS_ASSUME_NONNULL_END
