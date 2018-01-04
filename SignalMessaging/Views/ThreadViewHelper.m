//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "ThreadViewHelper.h"
#import <SignalServiceKit/AppContext.h>
#import <SignalServiceKit/TSDatabaseView.h>
#import <SignalServiceKit/TSStorageManager.h>
#import <SignalServiceKit/TSThread.h>
#import <YapDatabase/YapDatabase.h>
#import <YapDatabase/YapDatabaseViewChange.h>
#import <YapDatabase/YapDatabaseViewConnection.h>

NS_ASSUME_NONNULL_BEGIN

@interface ThreadViewHelper ()

@property (nonatomic) YapDatabaseConnection *uiDatabaseConnection;
@property (nonatomic) YapDatabaseViewMappings *threadMappings;
@property (nonatomic) BOOL shouldObserveDBModifications;

@end

#pragma mark -

@implementation ThreadViewHelper

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return self;
    }

    [self initializeMapping];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initializeMapping
{
    OWSAssertIsOnMainThread();

    NSString *grouping = TSInboxGroup;

    self.threadMappings =
        [[YapDatabaseViewMappings alloc] initWithGroups:@[ grouping ] view:TSThreadDatabaseViewExtensionName];
    [self.threadMappings setIsReversed:YES forGroup:grouping];

    self.uiDatabaseConnection = [TSStorageManager.sharedManager newDatabaseConnection];
    [self.uiDatabaseConnection beginLongLivedReadTransaction];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:OWSApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:OWSApplicationDidEnterBackgroundNotification
                                               object:nil];

    self.shouldObserveDBModifications
        = !(CurrentAppContext().isMainApp && CurrentAppContext().mainApplicationState == UIApplicationStateBackground);
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    self.shouldObserveDBModifications = YES;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    self.shouldObserveDBModifications = NO;
}

// Don't observe database change notifications when the app is in the background.
//
// Instead, rebuild model state when app enters foreground.
- (void)setShouldObserveDBModifications:(BOOL)shouldObserveDBModifications
{
    if (_shouldObserveDBModifications == shouldObserveDBModifications) {
        return;
    }

    _shouldObserveDBModifications = shouldObserveDBModifications;

    if (shouldObserveDBModifications) {
        [self.uiDatabaseConnection beginLongLivedReadTransaction];
        [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [self.threadMappings updateWithTransaction:transaction];
        }];
        [self updateThreads];
        [self.delegate threadListDidChange];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(yapDatabaseModified:)
                                                     name:YapDatabaseModifiedNotification
                                                   object:TSStorageManager.sharedManager.dbNotificationObject];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(yapDatabaseModifiedExternally:)
                                                     name:YapDatabaseModifiedExternallyNotification
                                                   object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:YapDatabaseModifiedNotification
                                                      object:TSStorageManager.sharedManager.dbNotificationObject];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:YapDatabaseModifiedExternallyNotification
                                                      object:nil];
    }
}

#pragma mark - Database

- (YapDatabaseConnection *)uiDatabaseConnection
{
    OWSAssertIsOnMainThread();

    return _uiDatabaseConnection;
}

- (void)yapDatabaseModifiedExternally:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    DDLogVerbose(@"%@ %s", self.logTag, __PRETTY_FUNCTION__);

    // External database modifications can't be converted into incremental updates,
    // so rebuild everything.  This is expensive and usually isn't necessary, but
    // there's no alternative.
    [self.uiDatabaseConnection beginLongLivedReadTransaction];
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.threadMappings updateWithTransaction:transaction];
    }];

    [self updateThreads];
    [self.delegate threadListDidChange];
}

- (void)yapDatabaseModified:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    DDLogVerbose(@"%@ %s", self.logTag, __PRETTY_FUNCTION__);

    NSArray *notifications = [self.uiDatabaseConnection beginLongLivedReadTransaction];

    if (!
        [[self.uiDatabaseConnection ext:TSMessageDatabaseViewExtensionName] hasChangesForNotifications:notifications]) {
        [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [self.threadMappings updateWithTransaction:transaction];
        }];
        return;
    }

    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    [[self.uiDatabaseConnection ext:TSThreadDatabaseViewExtensionName] getSectionChanges:&sectionChanges
                                                                              rowChanges:&rowChanges
                                                                        forNotifications:notifications
                                                                            withMappings:self.threadMappings];

    if (sectionChanges.count == 0 && rowChanges.count == 0) {
        // Ignore irrelevant modifications.
        return;
    }

    [self updateThreads];

    [self.delegate threadListDidChange];
}

- (void)updateThreads
{
    OWSAssertIsOnMainThread();

    NSMutableArray<TSThread *> *threads = [NSMutableArray new];
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        NSUInteger numberOfSections = [self.threadMappings numberOfSections];
        OWSAssert(numberOfSections == 1);
        for (NSUInteger section = 0; section < numberOfSections; section++) {
            NSUInteger numberOfItems = [self.threadMappings numberOfItemsInSection:section];
            for (NSUInteger item = 0; item < numberOfItems; item++) {
                TSThread *thread = [[transaction extension:TSThreadDatabaseViewExtensionName]
                    objectAtIndexPath:[NSIndexPath indexPathForItem:(NSInteger)item inSection:(NSInteger)section]
                         withMappings:self.threadMappings];
                [threads addObject:thread];
            }
        }
    }];

    _threads = [threads copy];
}

@end

NS_ASSUME_NONNULL_END
