//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "ConversationViewCell.h"
#import "ConversationViewItem.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ConversationViewCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    _viewItem = nil;
    self.messageDateHeaderText = nil;
    self.delegate = nil;
    self.isCellVisible = NO;
}

//// TODO:
//- (void)setFrame:(CGRect)frame {
//    [super setFrame:frame];
//    
//    DDLogError(@"%@ setFrame: %@", NSStringFromClass(self.class), NSStringFromCGRect(frame));
//}
//
//// TODO:
//- (void)setBounds:(CGRect)bounds {
//    [super setBounds:bounds];
//    
//    DDLogError(@"%@ setFrame: %@", ConversationViewCell.logTag, NSStringFromCGRect(bounds));
//}

- (void)configure
{
    OWSFail(@"%@ This method should be overridden.", self.logTag);
}

- (CGSize)cellSizeForViewWidth:(int)viewWidth
               maxMessageWidth:(int)maxMessageWidth
{
    OWSFail(@"%@ This method should be overridden.", self.logTag);
    return CGSizeZero;
}

#pragma mark - Logging

+ (NSString *)logTag
{
    return [NSString stringWithFormat:@"[%@]", self.class];
}

- (NSString *)logTag
{
    return self.class.logTag;
}

@end

NS_ASSUME_NONNULL_END

