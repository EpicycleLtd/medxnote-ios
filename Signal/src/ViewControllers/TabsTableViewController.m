//
//  TabsTableViewController.m
//  Medxnote
//
//  Created by Jan Nemeček on 3/22/19.
//  Copyright © 2019 Open Whisper Systems. All rights reserved.
//

#import "TabsTableViewController.h"

@interface TabsTableViewController ()

@end

@implementation TabsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Tabs", @"").capitalizedString;
    
    [self updateTableContents];
}

#pragma mark - Table Contents
    
- (void)updateTableContents {
    OWSTableContents *contents = [OWSTableContents new];
    
    __weak TabsTableViewController *weakSelf = self;
    
    OWSTableSection *screenSecuritySection = [OWSTableSection new];
    screenSecuritySection.headerTitle = @"Tabs preference";
    [screenSecuritySection addItem:[OWSTableItem switchItemWithText:@"Queues"
                                                               isOn:[NSUserDefaults.standardUserDefaults boolForKey:@"ShowMedxQueues"]
                                                          isEnabled:true
                                                             target:weakSelf
                                                           selector:@selector(didToggleQueuesEnabled:)]];
    [screenSecuritySection addItem:[OWSTableItem switchItemWithText:@"Results"
                                                               isOn:[NSUserDefaults.standardUserDefaults boolForKey:@"ShowMedxResults"]
                                                          isEnabled:true
                                                             target:weakSelf
                                                           selector:@selector(didToggleResultsEnabled:)]];
    [contents addSection:screenSecuritySection];
    
    self.contents = contents;
}
    
- (void)didToggleQueuesEnabled:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn forKey:@"ShowMedxQueues"];
    [NSUserDefaults.standardUserDefaults synchronize];
}
    
- (void)didToggleResultsEnabled:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn forKey:@"ShowMedxResults"];
    [NSUserDefaults.standardUserDefaults synchronize];
}

@end
