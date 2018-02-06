//
//  InlineKeyboardCell.h
//  Medxnote
//
//  Created by Jan Nemecek on 13/4/17.
//  Copyright © 2017 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PredefinedAnswerItem;

@interface InlineKeyboardCell : UICollectionViewCell
    
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
    
- (void)customizeWithItem:(PredefinedAnswerItem *)item;

@end
