//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSConversationSettingsViewDelegate.h"
#import "OWSTableViewController.h"
#import <UIKit/UIKit.h>

@class YapDatabaseConnection;

NS_ASSUME_NONNULL_BEGIN

@class TSThread;

@interface OWSConversationSettingsViewController : OWSTableViewController

@property (nonatomic, weak) id<OWSConversationSettingsViewDelegate> conversationSettingsViewDelegate;

@property (nonatomic) BOOL showVerificationOnAppear;
@property (nonatomic) YapDatabaseConnection *editingDatabaseConnection;

- (void)configureWithThread:(TSThread *)thread;

@end

NS_ASSUME_NONNULL_END
