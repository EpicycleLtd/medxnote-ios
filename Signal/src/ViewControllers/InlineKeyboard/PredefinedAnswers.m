//
//  PredefinedAnswers.m
//  Medxnote
//
//  Created by Jan Nemecek on 6/2/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import "PredefinedAnswers.h"
#import "PredefinedAnswerSection.h"

@interface PredefinedAnswers ()

@end

@implementation PredefinedAnswers

- (instancetype)initWithJson:(NSDictionary *)dictionary {
    self = [super init];
    if(self) {
        NSMutableArray *parsedRows = [NSMutableArray new];
        NSArray *rows = dictionary[@"rows"];
        for (NSDictionary *dict in rows) {
            [parsedRows addObject:[[PredefinedAnswerSection alloc] initWithJson:dict]];
        }
        self.sections = parsedRows.copy;
    }
    return self;
}

@end
