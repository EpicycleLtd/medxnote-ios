//
//  InlineKeyboard.h
//  Medxnote
//
//  Created by Jan Nemecek on 13/4/17.
//  Copyright © 2017 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PredefinedAnswerItem;

@protocol InlineKeyboardDelegate <NSObject>

- (void)tappedInlineKeyboardCell:(PredefinedAnswerItem *)item;

@end

@interface InlineKeyboard : NSObject
    
@property (nonatomic, weak) id<InlineKeyboardDelegate> delegate;
    
- (instancetype)initWithAnswers:(NSDictionary *)answers;
- (UIView *)keyboardView;

@end
