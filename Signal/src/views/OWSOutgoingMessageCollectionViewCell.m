//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSOutgoingMessageCollectionViewCell.h"
#import "OWSExpirationTimerView.h"
#import "UIView+OWS.h"
#import <JSQMessagesViewController/JSQMediaItem.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSOutgoingMessageCollectionViewCell ()

@property (strong, nonatomic) IBOutlet OWSExpirationTimerView *expirationTimerView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *expirationTimerViewWidthConstraint;
@property (strong, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

@end

@implementation OWSOutgoingMessageCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.expirationTimerViewWidthConstraint.constant = 0.0;
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self addGestureRecognizer:self.panGestureRecognizer];

    // Our text alignment needs to adapt to RTL.
    self.cellBottomLabel.textAlignment = [self.cellBottomLabel textAlignmentUnnatural];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.mediaView.alpha = 1.0;
    self.expirationTimerViewWidthConstraint.constant = 0.0f;

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

- (UIColor *)ows_textColor
{
    return [UIColor whiteColor];
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
