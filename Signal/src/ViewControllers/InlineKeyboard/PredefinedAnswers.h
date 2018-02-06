//
//  PredefinedAnswers.h
//  Medxnote
//
//  Created by Jan Nemecek on 6/2/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PredefinedAnswerSection;

@interface PredefinedAnswers : NSObject

@property NSArray <PredefinedAnswerSection *> *sections;

- (instancetype)initWithJson:(NSDictionary *)dictionary;

@end
