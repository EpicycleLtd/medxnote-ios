//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSTableViewController.h"

@class TSGroupThread;
@class YapDatabaseConnection;

@interface ShowGroupMembersViewController : OWSTableViewController

@property (nonatomic) YapDatabaseConnection *editingDatabaseConnection;

- (void)configWithThread:(TSGroupThread *)thread;

@end
