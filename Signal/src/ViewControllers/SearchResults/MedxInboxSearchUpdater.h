//
//  MedxInboxSearchUpdater.h
//  Medxnote
//
//  Created by Jan Nemecek on 27/1/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import "SearchResult.h"
#import <UIKit/UIKit.h>

@class YapDatabaseConnection;
@class YapDatabaseViewMappings;

@interface MedxInboxSearchUpdater : NSObject
    
@property (nonatomic) UISearchController *searchController;
@property NSMutableArray *results;
    
- (instancetype)initWithTableView:(UITableView *)tableView
                          dbConnection:(YapDatabaseConnection *)db
                        threadMappings:(YapDatabaseViewMappings *)threadMappings;
- (void)updateMappings;
- (BOOL)isSearching;

@end
