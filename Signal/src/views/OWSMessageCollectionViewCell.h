//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

/**
 * Methods that must be implemented on both incoming and outgoing message cells.
 */
@protocol OWSMessageCollectionViewCell

- (void)setCellVisible:(BOOL)isVisible;


#pragma mark - panning left for info

@property (nonatomic, copy, nullable) void (^panActionBlock)(UIPanGestureRecognizer *recognizer);

- (void)didPan:(UIPanGestureRecognizer *)panRecognizer;

@end

NS_ASSUME_NONNULL_END
