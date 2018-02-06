//
//  PredefinedAnswerSection.h
//  Medxnote
//
//  Created by Jan Nemecek on 6/2/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PredefinedAnswerItem;

@interface PredefinedAnswerSection : NSObject

@property (nonatomic) NSArray <PredefinedAnswerItem *> *items;

- (instancetype)initWithJson:(NSDictionary *)dictionary;

@end
