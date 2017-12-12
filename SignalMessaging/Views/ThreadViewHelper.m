//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "ThreadViewHelper.h"
#import <SignalServiceKit/AppContext.h>
#import <SignalServiceKit/TSDatabaseView.h>
#import <SignalServiceKit/TSStorageManager.h>
#import <SignalServiceKit/TSThread.h>
#import <YapDatabase/YapDatabaseConnection.h>
#import <YapDatabase/YapDatabaseViewChange.h>
#import <YapDatabase/YapDatabaseViewConnection.h>

NS_ASSUME_NONNULL_BEGIN

@interface YapDatabaseConnection ()

- (uint64_t)readSnapshotFromDatabase;

@end

#pragma mark -

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
    OWSAssert([NSThread isMainThread]);

    DDLogWarn(@"%@ %s %p %llu", self.logTag, __PRETTY_FUNCTION__, self, _threadMappings.snapshotOfLastUpdate);
    [DDLog flushLog];

    NSString *grouping = TSInboxGroup;

    self.threadMappings =
        [[YapDatabaseViewMappings alloc] initWithGroups:@[ grouping ] view:TSThreadDatabaseViewExtensionName];
    [self.threadMappings setIsReversed:YES forGroup:grouping];

    self.uiDatabaseConnection = [TSStorageManager.sharedManager newDatabaseConnection];
    [self.uiDatabaseConnection beginLongLivedReadTransaction];
    //    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
    //        [self.threadMappings updateWithTransaction:transaction];
    //    }];
    //    [self updateThreads];
    //    [self.delegate threadListDidChange];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    //    DDLogWarn(@"%@ %s %p %llu complete", self.logTag, __PRETTY_FUNCTION__, self,
    //    _threadMappings.snapshotOfLastUpdate); [DDLog flushLog];

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

        DDLogWarn(
            @"%@ %s %p %llu complete", self.logTag, __PRETTY_FUNCTION__, self, _threadMappings.snapshotOfLastUpdate);
        [DDLog flushLog];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(yapDatabaseModified:)
                                                     name:YapDatabaseModifiedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(yapDatabaseModifiedExternally:)
                                                     name:YapDatabaseModifiedExternallyNotification
                                                   object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:YapDatabaseModifiedNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:YapDatabaseModifiedExternallyNotification
                                                      object:nil];
    }
}

#pragma mark - Database

- (YapDatabaseConnection *)uiDatabaseConnection
{
    NSAssert([NSThread isMainThread], @"Must access uiDatabaseConnection on main thread!");
    //    if (!_uiDatabaseConnection) {
    //        YapDatabase *database = TSStorageManager.sharedManager.database;
    //        _uiDatabaseConnection = [database newConnection];
    //        [_uiDatabaseConnection beginLongLivedReadTransaction];
    //
    //        [[NSNotificationCenter defaultCenter] addObserver:self
    //                                                 selector:@selector(yapDatabaseModified:)
    //                                                     name:YapDatabaseModifiedNotification
    //                                                   object:nil];
    //        [[NSNotificationCenter defaultCenter] addObserver:self
    //                                                 selector:@selector(yapDatabaseModifiedExternally:)
    //                                                     name:YapDatabaseModifiedExternallyNotification
    //                                                   object:nil];
    //    }
    return _uiDatabaseConnection;
}

- (void)resetMapping
{
    DDLogWarn(@"%@ %s %p %llu, %llu, %llu, %llu",
        self.logTag,
        __PRETTY_FUNCTION__,
        self,
        _threadMappings.snapshotOfLastUpdate,
        self.uiDatabaseConnection.snapshot,
        self.uiDatabaseConnection.readSnapshotFromDatabase,
        self.uiDatabaseConnection.database.snapshot);
    [DDLog flushLog];

    self.uiDatabaseConnection = [TSStorageManager.sharedManager newDatabaseConnection];
    [self.uiDatabaseConnection beginLongLivedReadTransaction];
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.threadMappings updateWithTransaction:transaction];
    }];
    [self updateThreads];
    [self.delegate threadListDidChange];

    DDLogWarn(@"%@ %s %p %llu, %llu, %llu completed",
        self.logTag,
        __PRETTY_FUNCTION__,
        self,
        _threadMappings.snapshotOfLastUpdate,
        self.uiDatabaseConnection.snapshot,
        self.uiDatabaseConnection.database.snapshot);
    [DDLog flushLog];
}

- (void)yapDatabaseModifiedExternally:(NSNotification *)notification
{
    DDLogWarn(@"%@ %s %p %llu, %llu, %llu, %llu",
        self.logTag,
        __PRETTY_FUNCTION__,
        self,
        _threadMappings.snapshotOfLastUpdate,
        self.uiDatabaseConnection.snapshot,
        self.uiDatabaseConnection.readSnapshotFromDatabase,
        self.uiDatabaseConnection.database.snapshot);

    //    DDLogWarn(@"%@ %s %p %llu", self.logTag, __PRETTY_FUNCTION__, self, _threadMappings.snapshotOfLastUpdate);
    DDLogWarn(@"\t %@", notification);
    DDLogWarn(@"\t %@", notification.userInfo);
    [DDLog flushLog];

    if (!self.uiDatabaseConnection.database.options.enableMultiProcessSupport) {
        OWSFail(@"%@ Missing enableMultiProcessSupport", self.logTag);
    }

    [self resetMapping];

    //    [self.uiDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction){
    //        // Do nothing.
    //    }];

    //    [self handleDatabaseUpdate];

    //    DDLogWarn(@"%@ %s %p %llu, %llu, %llu completed",
    //              self.logTag,
    //              __PRETTY_FUNCTION__,
    //              self,
    //              _threadMappings.snapshotOfLastUpdate,
    //              self.uiDatabaseConnection.snapshot,
    //              self.uiDatabaseConnection.database.snapshot);
    //    [DDLog flushLog];

    //    [self.uiDatabaseConnection
    //        flushTransactionsWithCompletionQueue:dispatch_get_main_queue()
    //                             completionBlock:^{
    //                                 DDLogWarn(@"%@ flushTransactionsWithCompletionQueue", self.logTag);
    //
    //                                 [self handleDatabaseUpdate];
    //                             }];
}

- (void)yapDatabaseModified:(NSNotification *)notification
{
    DDLogWarn(@"%@ %s %p %llu", self.logTag, __PRETTY_FUNCTION__, self, _threadMappings.snapshotOfLastUpdate);
    DDLogWarn(@"\t %@", notification);
    DDLogWarn(@"\t %@", notification.userInfo);
    [DDLog flushLog];

    [self handleDatabaseUpdate];
}

- (void)handleDatabaseUpdate
{
    DDLogWarn(@"%@ %s %p %llu, %llu, %llu, %llu",
        self.logTag,
        __PRETTY_FUNCTION__,
        self,
        _threadMappings.snapshotOfLastUpdate,
        self.uiDatabaseConnection.snapshot,
        self.uiDatabaseConnection.readSnapshotFromDatabase,
        self.uiDatabaseConnection.database.snapshot);
    [DDLog flushLog];

    OWSAssert([NSThread isMainThread]);

    NSArray *notifications = [self.uiDatabaseConnection beginLongLivedReadTransaction];

    BOOL modifiedExternally = NO;
    for (NSNotification *notification in notifications) {
        if (![notification isKindOfClass:[NSNotification class]]) {
            OWSFail(@"%@ - notifications parameter contains non-NSNotification object", self.logTag);
            continue;
        }

        NSDictionary *changeset = notification.userInfo;

        BOOL changeset_modifiedExternally = [[changeset objectForKey:YapDatabaseModifiedExternallyKey] boolValue];
        if (changeset_modifiedExternally) {
            modifiedExternally = YES;
            break;
        }
    }

    if (modifiedExternally) {
        [self resetMapping];
        return;
    }

    DDLogWarn(@"%@ %s %p %llu, %llu, %llu, %llu updating",
        self.logTag,
        __PRETTY_FUNCTION__,
        self,
        _threadMappings.snapshotOfLastUpdate,
        self.uiDatabaseConnection.snapshot,
        self.uiDatabaseConnection.readSnapshotFromDatabase,
        self.uiDatabaseConnection.database.snapshot);

    DDLogWarn(@"%@ notifications: %@", self.logTag, notifications);
    DDLogWarn(@"%@ modifiedExternally: %d", self.logTag, modifiedExternally);
    [DDLog flushLog];

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

    DDLogWarn(
        @"%@ %s %p %llu post update", self.logTag, __PRETTY_FUNCTION__, self, _threadMappings.snapshotOfLastUpdate);
    [DDLog flushLog];

    if (sectionChanges.count == 0 && rowChanges.count == 0) {
        // Ignore irrelevant modifications.
        return;
    }

    [self updateThreads];

    [self.delegate threadListDidChange];
}

- (void)updateThreads
{
    OWSAssert([NSThread isMainThread]);

    DDLogWarn(@"%@ %s %p %llu", self.logTag, __PRETTY_FUNCTION__, self, _threadMappings.snapshotOfLastUpdate);
    [DDLog flushLog];

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
