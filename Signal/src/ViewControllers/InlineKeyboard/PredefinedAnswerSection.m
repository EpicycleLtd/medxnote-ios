//
//  PredefinedAnswerSection.m
//  Medxnote
//
//  Created by Jan Nemecek on 6/2/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import "PredefinedAnswerSection.h"
#import "PredefinedAnswerItem.h"

@implementation PredefinedAnswerSection

- (instancetype)initWithJson:(NSDictionary *)dictionary {
    self = [super init];
    if(self) {
//        "style": {
//            "bg_color": "",
//            "size": "1.00"
//        }
        NSMutableArray *parsed = [NSMutableArray new];
        NSArray *cells = dictionary[@"cells"];
        for (NSDictionary *dict in cells) {
            [parsed addObject:[[PredefinedAnswerItem alloc] initWithJson:dict]];
        }
        self.items = parsed.copy;
    }
    return self;
}

@end
