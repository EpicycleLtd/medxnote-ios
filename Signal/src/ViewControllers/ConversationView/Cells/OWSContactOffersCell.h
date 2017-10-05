//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "ConversationViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@class OWSContactOffersInteraction;

#pragma mark -

@interface OWSContactOffersCell : ConversationViewCell

//- (CGSize)bubbleSizeForInteraction:(OWSContactOffersInteraction *)interaction
//               collectionViewWidth:(CGFloat)collectionViewWidth;

+ (NSString *)cellReuseIdentifier;

@end

NS_ASSUME_NONNULL_END
