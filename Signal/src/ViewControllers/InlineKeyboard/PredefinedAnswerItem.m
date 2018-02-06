//
//  PredefinedAnswerItem.m
//  Medxnote
//
//  Created by Jan Nemecek on 6/2/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import "PredefinedAnswerItem.h"
#import "UIColor+HexString.h"

@implementation PredefinedAnswerItem

- (instancetype)initWithJson:(NSDictionary *)dictionary {
    self = [super init];
    if(self) {
        self.command = dictionary[@"cmd"];
        self.title = dictionary[@"title"];
        NSDictionary *style = dictionary[@"style"];
        NSNumber *width = style[@"width"];
        if (width.integerValue != 1) {
            self.width = [UIScreen mainScreen].bounds.size.width * width.floatValue/100.0f;
        }
        self.backgroundColor = [UIColor colorWithHexString:[style[@"bg_color"] stringByReplacingOccurrencesOfString:@"#" withString:@""]];
        self.borderColor = [UIColor colorWithHexString:[style[@"border"] stringByReplacingOccurrencesOfString:@"#" withString:@""]];
        self.textColor = [UIColor colorWithHexString:[style[@"color"] stringByReplacingOccurrencesOfString:@"#" withString:@""]];
    }
    return self;
}

@end
