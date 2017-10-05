//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "ConversationViewLayout.h"

@class TSInteraction;
@class ConversationViewCell;

@interface ConversationViewItem : NSObject <ConversationViewLayoutItem>

@property (nonatomic) TSInteraction *interaction;
@property (nonatomic) BOOL shouldShowDate;

- (ConversationViewCell *)dequeueCellForCollectionView:(UICollectionView *)collectionView
                                             indexPath:(NSIndexPath *)indexPath;

- (void)clearCachedLayoutState;

@end
