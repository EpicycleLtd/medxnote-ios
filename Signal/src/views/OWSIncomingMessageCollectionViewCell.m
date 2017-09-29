//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSIncomingMessageCollectionViewCell.h"
#import "OWSExpirationTimerView.h"
#import "UIColor+OWS.h"
#import <JSQMessagesViewController/JSQMediaItem.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSIncomingMessageCollectionViewCell ()

@property (strong, nonatomic) IBOutlet OWSExpirationTimerView *expirationTimerView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *expirationTimerViewWidthConstraint;
@property (strong, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

@end

@implementation OWSIncomingMessageCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.expirationTimerViewWidthConstraint.constant = 0.0;
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self addGestureRecognizer:self.panGestureRecognizer];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.expirationTimerViewWidthConstraint.constant = 0.0f;
    self.panActionBlock = nil;
    [self.mediaAdapter setCellVisible:NO];

    // Clear this adapter's views IFF this was the last cell to use this adapter.
    [self.mediaAdapter clearCachedMediaViewsIfLastPresentingCell:self];
    [_mediaAdapter setLastPresentingCell:nil];

    self.mediaAdapter = nil;
}

- (void)setMediaAdapter:(nullable id<OWSMessageMediaAdapter>)mediaAdapter
{
    _mediaAdapter = mediaAdapter;

    // Mark this as the last cell to use this adapter.
    [_mediaAdapter setLastPresentingCell:self];
}

#pragma mark - OWSMessageCollectionViewCell

- (void)setCellVisible:(BOOL)isVisible
{
    [self.mediaAdapter setCellVisible:isVisible];
}

#pragma mark - OWSExpirableMessageView

- (void)startExpirationTimerWithExpiresAtSeconds:(double)expiresAtSeconds
                          initialDurationSeconds:(uint32_t)initialDurationSeconds
{
    self.expirationTimerViewWidthConstraint.constant = OWSExpirableMessageViewTimerWidth;
    [self.expirationTimerView startTimerWithExpiresAtSeconds:expiresAtSeconds
                                      initialDurationSeconds:initialDurationSeconds];
}

- (void)stopExpirationTimer
{
    [self.expirationTimerView stopTimer];
}

#pragma mark - panning for info view

- (void)didPan:(UIPanGestureRecognizer *)panRecognizer
{
    if (self.panActionBlock == nil) {
        OWSFail(@"%@ panActionBlock was unexpectedly nil", self.logTag);
        return;
    }

    return self.panActionBlock(panRecognizer);
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
