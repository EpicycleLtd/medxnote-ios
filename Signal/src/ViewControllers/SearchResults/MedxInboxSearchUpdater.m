//
//  MedxInboxSearchUpdater.m
//  Medxnote
//
//  Created by Jan Nemecek on 27/1/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import "Environment.h"
#import "MedxInboxSearchUpdater.h"
#import "OWSContactsManager.h"
#import "TSDatabaseView.h"
#import "TSGroupThread.h"
#import "TSIncomingMessage.h"
#import "TSOutgoingMessage.h"
#import <YapDatabase/YapDatabaseView.h>
#import <YapDatabase/YapDatabaseViewChange.h>
#import <YapDatabase/YapDatabaseViewConnection.h>

@interface MedxInboxSearchUpdater () <UISearchBarDelegate>
    
@property (nonatomic, weak) YapDatabaseConnection *uiDatabaseConnection;
@property (nonatomic, weak) YapDatabaseViewMappings *threadMappings;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) YapDatabaseViewMappings *messageMappings;
@property NSArray <TSThread *> *threads;
@property NSMutableDictionary *memberNameCache;
    
@end

@implementation MedxInboxSearchUpdater
    
- (instancetype)initWithTableView:(UITableView *)tableView
                     dbConnection:(YapDatabaseConnection *)db
                   threadMappings:(YapDatabaseViewMappings *)threadMappings {
    if (self = [super init]) {
        self.tableView = tableView;
        self.uiDatabaseConnection = db;
        self.threadMappings = threadMappings;
        self.results = [NSMutableArray new];
        self.memberNameCache = [NSMutableDictionary new];
        [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setDefaultTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
        [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTintColor:[UIColor whiteColor]];
        [self setupSearch];
    }
    return self;
}
    
- (void)setupSearch {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.tintColor = [UIColor whiteColor];
    self.searchController.dimsBackgroundDuringPresentation = false;
    UITextField *searchField = [self.searchController.searchBar valueForKey:@"searchField"];
    searchField.textColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        self.searchController.automaticallyShowsCancelButton = true;
    }
}
    
- (BOOL)isSearching {
    return self.searchController.searchBar.text.length > 0;
}
    
#pragma mark - Search
    
- (void)updateMappings {
    NSMutableArray *threads = [NSMutableArray new];
    NSMutableArray *threadIds = [NSMutableArray new];
    for (NSUInteger i = 0; i < [self.threadMappings numberOfItemsInSection:0]; i++) {
        TSThread *thread = [self threadForIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        [threads addObject:thread];
        [threadIds addObject:thread.uniqueId];
    }
    self.threads = threads.copy;
    
    // mappings
    self.messageMappings =
    [[YapDatabaseViewMappings alloc] initWithGroups:threadIds.copy view:TSMessageDatabaseViewExtensionName];
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.messageMappings updateWithTransaction:transaction];
    }];
    NSLog(@"total messages %ld", [self.messageMappings numberOfItemsInAllGroups]);
}
    
- (TSThread *)threadForIndexPath:(NSIndexPath *)indexPath {
    __block TSThread *thread = nil;
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        thread = [[transaction extension:TSThreadDatabaseViewExtensionName] objectAtIndexPath:indexPath
                                                                                 withMappings:self.threadMappings];
    }];
    
    return thread;
}
    
- (void)searchForText:(NSString *)searchText {
    NSString *text = searchText.lowercaseString;
    NSMutableArray *results = [NSMutableArray new];
    for (TSThread *thread in self.threads) {
        // check thread name
        if ([thread.name.lowercaseString containsString:text]) {
            SearchResult *result = [SearchResult new];
            result.thread = thread;
            [results addObject:result];
        }
        if (thread.isGroupThread) {
            TSGroupThread *group = (TSGroupThread *)thread;
            for (NSString *memberId in group.groupModel.groupMemberIds) {
                NSString *memberName = self.memberNameCache[memberId];
                // if member name is not cached, get from contacts manager
                if (!memberName) {
                    memberName = [[Environment getCurrent].contactsManager displayNameForPhoneIdentifier:memberId];
                    self.memberNameCache[memberId] = memberName;
                }
                if ([memberName.lowercaseString containsString:text]) {
                    SearchResult *result = [SearchResult new];
                    result.thread = thread;
                    [results addObject:result];
                    break;
                }
            }
        }
        
        // search messages
        NSInteger count = [self.messageMappings numberOfItemsInGroup:thread.uniqueId];
        for (NSInteger i = 0; i < count; i++) {
            // TODO: we can also store this index in search result so we can scroll to the appropriate message
            TSInteraction *interaction = [self interactionForGroup:thread.uniqueId index:i];
            if ([interaction isKindOfClass:[TSIncomingMessage class]]) {
                TSIncomingMessage *message = (TSIncomingMessage *)interaction;
                if ([message.body.lowercaseString containsString:text]) {
                    SearchResult *result = [SearchResult new];
                    result.interaction = message;
                    result.thread = thread;
                    [results addObject:result];
                }
            } else if ([interaction isKindOfClass:[TSOutgoingMessage class]]) {
                TSOutgoingMessage *message = (TSOutgoingMessage *)interaction;
                if ([message.body.lowercaseString containsString:text]) {
                    SearchResult *result = [SearchResult new];
                    result.interaction = message;
                    result.thread = thread;
                    [results addObject:result];
                }
            }
        }
    }
    NSLog(@"found %ld results", results.count);
    [self.results removeAllObjects];
    [self.results addObjectsFromArray:results];
    [self.tableView reloadData];
}
    
- (TSInteraction *)interactionForGroup:(NSString *)group index:(NSInteger)index {
    __block TSInteraction *message = nil;
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        YapDatabaseViewTransaction *viewTransaction = [transaction ext:TSMessageDatabaseViewExtensionName];
        message = [viewTransaction objectAtIndex:index inGroup:group];
    }];
    
    return message;
}
    
#pragma mark - Search bar delegate
    
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self searchForText:searchText];
}
    
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [searchBar resignFirstResponder];
}
    
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [searchBar setText:nil];
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    [self.results removeAllObjects];
    [self.tableView reloadData];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
    return YES;
}

@end
