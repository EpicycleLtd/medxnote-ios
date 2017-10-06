//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "ConversationViewLayout.h"
#import "OWSAudioAttachmentPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@class TSInteraction;
@class ConversationViewCell;
@class OWSAudioMessageView;

@interface ConversationViewItem : NSObject <ConversationViewLayoutItem, OWSAudioAttachmentPlayerDelegate>

@property (nonatomic, readonly) TSInteraction *interaction;

@property (nonatomic) BOOL shouldShowDate;

//@property (nonatomic, weak) ConversationViewCell *lastCell;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTSInteraction:(TSInteraction *)interaction;

- (ConversationViewCell *)dequeueCellForCollectionView:(UICollectionView *)collectionView
                                             indexPath:(NSIndexPath *)indexPath;

- (void)clearCachedLayoutState;

#pragma mark - Audio Playback

@property (nonatomic, weak) OWSAudioMessageView *lastAudioMessageView;

@property (nonatomic, nullable) NSNumber *audioDurationSeconds;

- (CGFloat)audioProgressSeconds;

@end

NS_ASSUME_NONNULL_END
