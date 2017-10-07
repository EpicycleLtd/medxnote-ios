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
#import "OWSAudioMessageView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConversationViewItem ()

@property (nonatomic, nullable) NSValue *cachedCellSize;

#pragma mark - OWSAudioAttachmentPlayerDelegate

@property (nonatomic) AudioPlaybackState audioPlaybackState;
@property (nonatomic) CGFloat audioProgressSeconds;

@end

#pragma mark -

@implementation ConversationViewItem

- (instancetype)initWithTSInteraction:(TSInteraction *)interaction
{
    self = [super init];
    
    if (!self) {
        return self;
    }
    
    _interaction = interaction;
    
    return self;
}

- (void)replaceInteraction:(TSInteraction*)interaction
{
    OWSAssert(interaction);
    
    _interaction = interaction;

    [self clearCachedLayoutState];
}

- (void)setShouldShowDate:(BOOL)shouldShowDate {
    if (_shouldShowDate == shouldShowDate) {
        return;
    }
    
    _shouldShowDate = shouldShowDate;
    
    [self clearCachedLayoutState];
}

- (void)clearCachedLayoutState
{
    self.cachedCellSize = nil;
}

- (CGSize)cellSizeForViewWidth:(int)viewWidth
               maxMessageWidth:(int)maxMessageWidth
{
    OWSAssert([NSThread isMainThread]);

    CGSize cellSize = CGSizeZero;
    if (!self.cachedCellSize) {
        ConversationViewCell *_Nullable measurementCell = [self measurementCell];        
        measurementCell.viewItem = self;
        cellSize =
        [measurementCell cellSizeForViewWidth:viewWidth maxMessageWidth:maxMessageWidth];
        self.cachedCellSize = [NSValue valueWithCGSize:cellSize];
        [measurementCell prepareForReuse];
        
//        DDLogError(@"cellSizeForViewWidth: %@ %@", self.interaction.uniqueId, self.interaction.description);
//        DDLogError(@"\t fresh cellSize: %@", NSStringFromCGSize(cellSize));
    } else {
        cellSize = [self.cachedCellSize CGSizeValue];
//        DDLogError(@"cellSizeForViewWidth: %@ %@", self.interaction.uniqueId, self.interaction.description);
//        DDLogError(@"\t cached cellSize: %@", NSStringFromCGSize(cellSize));
    }
    return cellSize;
}

- (ConversationViewLayoutAlignment)layoutAlignment
{
    switch (self.interaction.interactionType) {
        case OWSInteractionType_Unknown:
            return ConversationViewLayoutAlignment_Center;
        case OWSInteractionType_IncomingMessage:
            return ConversationViewLayoutAlignment_Incoming;
            break;
        case OWSInteractionType_OutgoingMessage:
            return ConversationViewLayoutAlignment_Outgoing;
            break;
        case OWSInteractionType_Error:
        case OWSInteractionType_Info:
        case OWSInteractionType_Call:
            return ConversationViewLayoutAlignment_Center;
        case OWSInteractionType_UnreadIndicator:
            return ConversationViewLayoutAlignment_FullWidth;
        case OWSInteractionType_Offer:
            return ConversationViewLayoutAlignment_Center;
    }
}

- (nullable ConversationViewCell *)measurementCell
{
    OWSAssert([NSThread isMainThread]);
    OWSAssert(self.interaction);
    
    // For performance reasons, we cache one instance of each kind of
    // cell and uses these cells for measurement.
    static NSMutableDictionary<NSNumber *, ConversationViewCell *> *measurementCellCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        measurementCellCache = [NSMutableDictionary new];
    });
    
    NSNumber *cellCacheKey = @(self.interaction.interactionType);
    ConversationViewCell *_Nullable measurementCell = measurementCellCache[cellCacheKey];
    if (!measurementCell) {
        switch (self.interaction.interactionType) {
            case OWSInteractionType_Unknown:
                OWSFail(@"%@ Unknown interaction type.", self.tag);
                return nil;
            case OWSInteractionType_IncomingMessage:
                measurementCell = [OWSIncomingMessageCell new];
                break;
            case OWSInteractionType_OutgoingMessage:
                measurementCell = [OWSOutgoingMessageCell new];
                break;
            case OWSInteractionType_Error:
            case OWSInteractionType_Info:
            case OWSInteractionType_Call:
                measurementCell = [OWSSystemMessageCell new];
                break;
            case OWSInteractionType_UnreadIndicator:
                measurementCell = [OWSUnreadIndicatorCell new];
                break;
            case OWSInteractionType_Offer:
                measurementCell = [OWSContactOffersCell new];
                break;
        }
        
        OWSAssert(measurementCell);
        measurementCellCache[cellCacheKey] = measurementCell;
    }
    
    return measurementCell;
}

- (ConversationViewCell *)dequeueCellForCollectionView:(UICollectionView *)collectionView
                                             indexPath:(NSIndexPath *)indexPath
{
    OWSAssert([NSThread isMainThread]);
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

#pragma mark - OWSAudioAttachmentPlayerDelegate

- (void)setAudioPlaybackState:(AudioPlaybackState)audioPlaybackState {
    _audioPlaybackState = audioPlaybackState;
    
    [self.lastAudioMessageView updateContents];
}

- (void)setAudioProgress:(CGFloat)progress duration:(CGFloat)duration
{
    OWSAssert([NSThread isMainThread]);
    
    self.audioProgressSeconds = progress;
    if (duration > 0) {
        self.audioDurationSeconds = @(duration);
    }
    
    [self.lastAudioMessageView updateContents];
}

#pragma mark - Menu Actions

- (BOOL)canPerformEditingAction:(SEL)selector
{
    // TODO:
    OWSFail(@"%@", self.tag);
    return NO;
}

- (void)performEditingAction:(SEL)selector
{
    // TODO:
    OWSFail(@"%@", self.tag);
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

NS_ASSUME_NONNULL_END
