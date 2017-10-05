//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "ConversationViewLayout.h"

@class TSInteraction;
@class ConversationViewCell;

@interface ConversationViewItem : NSObject <ConversationViewLayoutItem>

@property (nonatomic, readonly) TSInteraction *interaction;

@property (nonatomic) BOOL shouldShowDate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTSInteraction:(TSInteraction *)interaction;


- (ConversationViewCell *)dequeueCellForCollectionView:(UICollectionView *)collectionView
                                             indexPath:(NSIndexPath *)indexPath;

- (void)clearCachedLayoutState;

@end
