//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "ConversationViewItem.h"
#import <SignalServiceKit/TSInteraction.h>
#import "OWSContactOffersCell.h"
#import "OWSIncomingMessageCell.h"
#import "OWSSystemMessageCell.h"
#import "OWSUnreadIndicatorCell.h"
#import "OWSOutgoingMessageCell.h"

@implementation ConversationViewItem

- (CGSize)cellSizeForViewWidth:(int)viewWidth
               maxMessageWidth:(int)maxMessageWidth
{
    // TODO:
    return CGSizeMake(maxMessageWidth, maxMessageWidth);
}

- (ConversationViewLayoutAlignment)layoutAlignment
{
    // TODO:
    return ConversationViewLayoutAlignment_Left;
}

- (ConversationViewCell *)dequeueCellForCollectionView:(UICollectionView *)collectionView
                                             indexPath:(NSIndexPath *)indexPath
{
    OWSAssert(collectionView);
    OWSAssert(indexPath);
    OWSAssert(self.interaction);
    
    switch (self.interaction.interactionType) {
        case OWSInteractionType_Unknown:
            OWSFail(@"%@ Unknown interaction type.", self.tag);
            return nil;
        case OWSInteractionType_IncomingMessage:
            return [collectionView dequeueReusableCellWithReuseIdentifier:[OWSIncomingMessageCell cellReuseIdentifier]
                                                                  forIndexPath:indexPath];
        case OWSInteractionType_OutgoingMessage:
            return [collectionView dequeueReusableCellWithReuseIdentifier:[OWSOutgoingMessageCell cellReuseIdentifier]
                                                                  forIndexPath:indexPath];
        case OWSInteractionType_Error:
        case OWSInteractionType_Info:
        case OWSInteractionType_Call:
            return [collectionView dequeueReusableCellWithReuseIdentifier:[OWSSystemMessageCell cellReuseIdentifier]
                                                                  forIndexPath:indexPath];
        case OWSInteractionType_UnreadIndicator:
            return [collectionView dequeueReusableCellWithReuseIdentifier:[OWSUnreadIndicatorCell cellReuseIdentifier]
                                                                  forIndexPath:indexPath];
        case OWSInteractionType_Offer:
            return [collectionView dequeueReusableCellWithReuseIdentifier:[OWSContactOffersCell cellReuseIdentifier]
                                                                  forIndexPath:indexPath];
    }
}

#pragma mark - Logging

+ (NSString *)tag
{
    return [NSString stringWithFormat:@"[%@]", self.class];
}

- (NSString *)tag
{
    return self.class.tag;
}

@end
