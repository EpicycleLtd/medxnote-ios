//
//  PredefinedAnswerItem.h
//  Medxnote
//
//  Created by Jan Nemecek on 6/2/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PredefinedAnswerItem : NSObject

@property NSString *command;
@property NSString *title;
@property CGFloat width;
@property UIColor *backgroundColor;
@property UIColor *borderColor;
@property UIColor *textColor;

- (instancetype)initWithJson:(NSDictionary *)dictionary;

@end
