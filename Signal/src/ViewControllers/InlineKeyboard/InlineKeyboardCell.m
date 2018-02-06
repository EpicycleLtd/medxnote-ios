//
//  InlineKeyboardCell.m
//  Medxnote
//
//  Created by Jan Nemecek on 13/4/17.
//  Copyright © 2017 Open Whisper Systems. All rights reserved.
//

#import "InlineKeyboardCell.h"
#import "PredefinedAnswerItem.h"

@implementation InlineKeyboardCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
    
- (void)customizeWithItem:(PredefinedAnswerItem *)item {
    self.titleLabel.text = item.title;
    self.contentView.backgroundColor = item.backgroundColor;
    self.contentView.layer.cornerRadius = 3;
    self.contentView.clipsToBounds = true;
    self.contentView.layer.borderColor = item.borderColor.CGColor;
    self.contentView.layer.borderWidth = 1.0f;
    self.titleLabel.textColor = item.textColor;
}

@end
