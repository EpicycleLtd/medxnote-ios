//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "ConversationViewCell.h"
#import "ConversationViewItem.h"

@implementation ConversationViewCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.viewItem = nil;
    self.messageDateHeaderText = nil;
    self.delegate = nil;
    self.isCellVisible = NO;
}

// TODO:
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    DDLogError(@"%@ setFrame: %@", ConversationViewCell.logTag, NSStringFromCGRect(frame));
}

// TODO:
- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    
    DDLogError(@"%@ setFrame: %@", ConversationViewCell.logTag, NSStringFromCGRect(bounds));
}

- (void)configure
{
    OWSFail(@"%@ this method should be overridden.", self.logTag);
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

