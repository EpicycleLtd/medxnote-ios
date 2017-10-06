//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSMessageCell.h"
//#import "OWSExpirationTimerView.h"
//#import "UIView+OWS.h"
//#import <JSQMessagesViewController/JSQMediaItem.h>
#import "ConversationViewItem.h"
#import "Signal-Swift.h"
#import "AttachmentUploadView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, OWSMessageCellMode) {
    OWSMessageCellMode_TextMessage,
    OWSMessageCellMode_StillImage,
    OWSMessageCellMode_AnimatedImage,
    OWSMessageCellMode_Audio,
    OWSMessageCellMode_Video,
    OWSMessageCellMode_GenericAttachment,
    OWSMessageCellMode_DownloadingAttachment,
    // Treat invalid messages as empty text messages.
    OWSMessageCellMode_Unknown = OWSMessageCellMode_TextMessage,
};

@interface OWSMessageCell ()

@property (nonatomic) OWSMessageCellMode cellMode;

@property (nonatomic, nullable) NSString *textMessage;
@property (nonatomic, nullable) TSAttachmentStream *attachmentStream;
@property (nonatomic, nullable) TSAttachmentPointer *attachmentPointer;
@property (nonatomic) CGSize contentSize;

// The text label is used so frequently that we always keep one around.
@property (nonatomic) UILabel *textLabel;
@property (nonatomic, nullable) UIImageView *bubbleImageView;
@property (nonatomic, nullable) AttachmentUploadView *attachmentUploadView;
@property (nonatomic, nullable) UIImageView *stillImageView;
@property (nonatomic, nullable) UIImageView *animatedImageView;
@property (nonatomic, nullable) UIView *errorView;
@property (nonatomic, nullable) NSArray<NSLayoutConstraint *> *contentConstraints;

//@property (strong, nonatomic) IBOutlet OWSExpirationTimerView *expirationTimerView;
//@property (strong, nonatomic) IBOutlet NSLayoutConstraint *expirationTimerViewWidthConstraint;

@end

@implementation OWSMessageCell

// `[UIView init]` invokes `[self initWithFrame:...]`.
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commontInit];
    }
    
    return self;
}

- (void)commontInit
{
    OWSAssert(!self.textLabel);
    
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.layoutMargins = UIEdgeInsetsZero;

    self.bubbleImageView = [UIImageView new];
    self.bubbleImageView.layoutMargins = UIEdgeInsetsZero;
    [self.contentView addSubview:self.bubbleImageView];
    [self.bubbleImageView autoPinToSuperviewEdges];

    self.textLabel = [UILabel new];
    self.textLabel.font = [UIFont ows_regularFontWithSize:16.f];
    self.textLabel.numberOfLines = 0;
    self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.textLabel.textAlignment = NSTextAlignmentLeft;
    self.textLabel.hidden = YES;
    [self.bubbleImageView addSubview:self.textLabel];
    OWSAssert(self.textLabel.superview);

//    [self.contentView addRedBorder];
//    self.addToContactsButton = [self
//                                createButtonWithTitle:
//                                NSLocalizedString(@"CONVERSATION_VIEW_ADD_TO_CONTACTS_OFFER",
//                                                  @"Message shown in conversation view that offers to add an unknown user to your phone's contacts.")
//                                selector:@selector(addToContacts)];
//    self.addToProfileWhitelistButton = [self
//                                        createButtonWithTitle:NSLocalizedString(@"CONVERSATION_VIEW_ADD_USER_TO_PROFILE_WHITELIST_OFFER",
//                                                                                @"Message shown in conversation view that offers to share your profile with a user.")
//                                        selector:@selector(addToProfileWhitelist)];
//    self.blockButton =
//    [self createButtonWithTitle:NSLocalizedString(@"CONVERSATION_VIEW_UNKNOWN_CONTACT_BLOCK_OFFER",
//                                                  @"Message shown in conversation view that offers to block an unknown user.")
//                       selector:@selector(block)];

    UITapGestureRecognizer *tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self addGestureRecognizer:tap];

    UILongPressGestureRecognizer *longPress =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self addGestureRecognizer:longPress];
}

- (NSCache *)displayableTextCache
{
    static NSCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSCache new];
        // Cache the results for up to 1,000 messages.
        cache.countLimit = 1000;
    });
    return cache;
}

- (NSString *)displayableTextForText:(NSString *)text
                       interactionId:(NSString *)interactionId
{
    OWSAssert(text);
    OWSAssert(interactionId.length > 0);
    
    NSString *_Nullable displayableText = [[self displayableTextCache] objectForKey:interactionId];
    if (!displayableText) {
        // Only show up to 2kb of text.
        const NSUInteger kMaxTextDisplayLength = 2 * 1024;
        displayableText = [[DisplayableTextFilter new] displayableText:text];
        if (displayableText.length > kMaxTextDisplayLength) {
            // Trim whitespace before _AND_ after slicing the snipper from the string.
            NSString *snippet = [[[displayableText
                                   stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                                  substringWithRange:NSMakeRange(0, kMaxTextDisplayLength)]
                                 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            displayableText =
            [NSString stringWithFormat:NSLocalizedString(@"OVERSIZE_TEXT_DISPLAY_FORMAT",
                                                         @"A display format for oversize text messages."),
             snippet];
        }
        if (!displayableText) {
            displayableText = @"";
        }
        [[self displayableTextCache] setObject:displayableText forKey:interactionId];
    }
    return displayableText;
}

- (NSString *)displayableTextForAttachmentStream:(TSAttachmentStream *)attachmentStream
                       interactionId:(NSString *)interactionId
{
    OWSAssert(attachmentStream);
    OWSAssert(interactionId.length > 0);
    
    NSString *_Nullable displayableText = [[self displayableTextCache] objectForKey:interactionId];
    if (displayableText) {
        return displayableText;
    }
    
    NSData *textData = [NSData dataWithContentsOfURL:attachmentStream.mediaURL];
    NSString *text = [[NSString alloc] initWithData:textData encoding:NSUTF8StringEncoding];
    return [self displayableTextForText:text
                          interactionId:interactionId];
}

- (void)ensureCellMode
{
    OWSAssert(self.viewItem);
    OWSAssert(self.viewItem.interaction);
    OWSAssert([self.viewItem.interaction isKindOfClass:[TSMessage class]]);
    
    TSMessage *interaction = (TSMessage *) self.viewItem.interaction;
    if (interaction.body.length > 0) {
        self.cellMode = OWSMessageCellMode_TextMessage;
        // TODO: This can be expensive.  Should we cache it on the view item?
        self.textMessage = [self displayableTextForText:interaction.body
                                          interactionId:interaction.uniqueId];
        return;
    } else {
        NSString *_Nullable attachmentId = interaction.attachmentIds.firstObject;
        if (attachmentId.length > 0) {
            TSAttachment *attachment = [TSAttachment fetchObjectWithUniqueID:attachmentId];
            if ([attachment isKindOfClass:[TSAttachmentStream class]]) {
                self.attachmentStream = (TSAttachmentStream *)attachment;
                
                if ([attachment.contentType isEqualToString:OWSMimeTypeOversizeTextMessage]) {
                    self.cellMode = OWSMessageCellMode_TextMessage;
                    // TODO: This can be expensive.  Should we cache it on the view item?
                    self.textMessage = [self displayableTextForAttachmentStream:self.attachmentStream
                                                                  interactionId:interaction.uniqueId];
                    return;
                } else if ([self.attachmentStream isAnimated]) {
                    self.cellMode = OWSMessageCellMode_AnimatedImage;
                    self.contentSize = [self.attachmentStream imageSizeWithoutTransaction];
                    if (self.contentSize.width <= 0 ||
                        self.contentSize.height <= 0) {
                        self.cellMode = OWSMessageCellMode_GenericAttachment;
                    }
                    return;
                } else if ([self.attachmentStream isImage]) {
                    self.cellMode = OWSMessageCellMode_StillImage;
                    self.contentSize = [self.attachmentStream imageSizeWithoutTransaction];

//                    DDLogError(@"still image: %@ %@ %@", self.viewItem.interaction.description, self.attachmentStream.contentType, self.attachmentStream.mediaURL);
//                    DDLogError(@"\t contentSize: %@", NSStringFromCGSize(self.contentSize));

                    if (self.contentSize.width <= 0 ||
                        self.contentSize.height <= 0) {
                        self.cellMode = OWSMessageCellMode_GenericAttachment;
                    }
                    return;
//                    adapter.mediaItem =
//                    [[TSAnimatedAdapter alloc] initWithAttachment:stream incoming:isIncomingAttachment];
//                    adapter.mediaItem.appliesMediaViewMaskAsOutgoing = !isIncomingAttachment;
//                } else if ([self.attachmentStream isImage]) {
//                    adapter.mediaItem =
//                    [[TSPhotoAdapter alloc] initWithAttachment:stream incoming:isIncomingAttachment];
//                    adapter.mediaItem.appliesMediaViewMaskAsOutgoing = !isIncomingAttachment;
//                    break;
//                } else if ([self.attachmentStream isVideo] || [self.attachmentStream isAudio]) {
//                    adapter.mediaItem = [[TSVideoAttachmentAdapter alloc]
//                                         initWithAttachment:stream
//                                         incoming:[interaction isKindOfClass:[TSIncomingMessage class]]];
//                    adapter.mediaItem.appliesMediaViewMaskAsOutgoing = !isIncomingAttachment;
//                    break;
//                } else {
//                    adapter.mediaItem = [[TSGenericAttachmentAdapter alloc]
//                                         initWithAttachment:stream
//                                         incoming:[interaction isKindOfClass:[TSIncomingMessage class]]];
//                    adapter.mediaItem.appliesMediaViewMaskAsOutgoing = !isIncomingAttachment;
//                    break;
                }
            } else if ([attachment isKindOfClass:[TSAttachmentPointer class]]) {
                self.cellMode = OWSMessageCellMode_DownloadingAttachment;
                self.attachmentPointer = (TSAttachmentPointer *)attachment;
//                adapter.mediaItem =
//                [[AttachmentPointerAdapter alloc] initWithAttachmentPointer:pointer
//                                                                 isIncoming:isIncomingAttachment];
                return;
            }
//            } else {
        }
    }

    self.cellMode = OWSMessageCellMode_Unknown;
}

- (void)loadForDisplay
{
    OWSAssert(self.viewItem);
    OWSAssert(self.viewItem.interaction);
    OWSAssert([self.viewItem.interaction isKindOfClass:[TSMessage class]]);
    
    [self ensureCellMode];
    
    BOOL isIncoming = self.isIncoming;
    JSQMessagesBubbleImage *bubbleImageData = isIncoming ? [self.bubbleFactory incoming] : [self.bubbleFactory outgoing];
    self.bubbleImageView.image = bubbleImageData.messageBubbleImage;

    switch(self.cellMode) {
        case OWSMessageCellMode_TextMessage: {
            self.bubbleImageView.hidden = NO;
            self.textLabel.hidden = NO;
            self.textLabel.text = self.textMessage;
            self.textLabel.textColor = [self textColor];
            
            self.contentConstraints = @[
                                      [self.textLabel autoPinLeadingToSuperviewWithMargin:self.leadingMargin],
                                      [self.textLabel autoPinTrailingToSuperviewWithMargin:self.trailingMargin],
                                      [self.textLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:self.vMargin],
                                      [self.textLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:self.vMargin],
                                      ];
            return;
        }
        case OWSMessageCellMode_StillImage: {
            UIImage *_Nullable image = self.attachmentStream.image;
            if (!image) {
                DDLogError(@"%@ Could not load image: %@", [self logTag], [self.attachmentStream mediaURL]);
                [self showAttachmentErrorView];
                return;
            }

            self.stillImageView = [[UIImageView alloc] initWithImage:image];
            // Use trilinear filters for better scaling quality at
            // some performance cost.
            self.stillImageView.layer.minificationFilter = kCAFilterTrilinear;
            self.stillImageView.layer.magnificationFilter = kCAFilterTrilinear;
            [self.contentView addSubview:self.stillImageView];
            self.contentConstraints = [self.stillImageView autoPinToSuperviewEdges];
            [self cropViewToBubbbleShape:self.stillImageView];
            return;
        }
        case OWSMessageCellMode_AnimatedImage:
            break;
        case OWSMessageCellMode_Audio:
            break;
        case OWSMessageCellMode_Video:
            break;
        case OWSMessageCellMode_GenericAttachment:
            break;
        case OWSMessageCellMode_DownloadingAttachment:
            break;
    }
    
    self.contentView.backgroundColor = [UIColor redColor];

//    [self.textLabel addBorderWithColor:[UIColor blueColor]];
//    [self.bubbleImageView addBorderWithColor:[UIColor greenColor]];

//    dispatch_async(dispatch_get_main_queue(), ^{
//        NSLog(@"---- %@", self.viewItem.interaction.debugDescription);
//        NSLog(@"cell: %@", NSStringFromCGRect(self.frame));
//        NSLog(@"contentView: %@", NSStringFromCGRect(self.contentView.frame));
//        NSLog(@"textLabel: %@", NSStringFromCGRect(self.textLabel.frame));
//        NSLog(@"bubbleImageView: %@", NSStringFromCGRect(self.bubbleImageView.frame));
//    });
}

- (void)cropViewToBubbbleShape:(UIView *)view
{
    view.frame = view.superview.bounds;
    [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:view
                                                                isOutgoing:!self.isIncoming];
}

- (void)showAttachmentErrorView
{
    // TODO: We could do a better job of indicating that the image could not be loaded.
    self.errorView = [UIView new];
    self.errorView.backgroundColor = [UIColor colorWithWhite:0.85f alpha:1.f];
    [self.contentView addSubview:self.errorView];
    self.contentConstraints = [self.errorView autoPinToSuperviewEdges];
    [self cropViewToBubbbleShape:self.stillImageView];
}

- (CGSize)cellSizeForViewWidth:(int)viewWidth
               maxMessageWidth:(int)maxMessageWidth
{
    OWSAssert(self.viewItem);
    OWSAssert([self.viewItem.interaction isKindOfClass:[TSMessage class]]);
    
    [self ensureCellMode];

    switch(self.cellMode) {
        case OWSMessageCellMode_TextMessage: {
            BOOL isRTL = self.isRTL;
            CGFloat leftMargin = isRTL ? self.trailingMargin : self.leadingMargin;
            CGFloat rightMargin = isRTL ? self.leadingMargin : self.trailingMargin;
            CGFloat vMargin = self.vMargin;
            CGFloat maxTextWidth = maxMessageWidth - (leftMargin + rightMargin);
            
            self.textLabel.text = self.textMessage;
            CGSize textSize = [self.textLabel sizeThatFits:CGSizeMake(maxTextWidth, CGFLOAT_MAX)];
            CGSize result = CGSizeMake((CGFloat) ceil(textSize.width + leftMargin + rightMargin),
                                       (CGFloat) ceil(textSize.height + vMargin * 2));
            //        NSLog(@"???? %@", self.viewItem.interaction.debugDescription);
            //        NSLog(@"\t %@", messageBody);
            //        NSLog(@"textSize: %@", NSStringFromCGSize(textSize));
            //        NSLog(@"result: %@", NSStringFromCGSize(result));
            return result;
        }
        case OWSMessageCellMode_StillImage:
        case OWSMessageCellMode_AnimatedImage: {
            OWSAssert(self.contentSize.width > 0);
            OWSAssert(self.contentSize.height > 0);
            
            // TODO: Adjust this behavior.
            const CGFloat maxContentWidth = maxMessageWidth;
            const CGFloat maxContentHeight = maxMessageWidth;
            CGFloat contentWidth = (CGFloat) round(maxContentWidth);
            CGFloat contentHeight = (CGFloat) round(maxContentWidth * self.contentSize.height / self.contentSize.width);
            if (contentHeight > maxContentHeight) {
                contentWidth = (CGFloat) round(maxContentHeight * self.contentSize.width / self.contentSize.height);
                contentHeight = (CGFloat) round(maxContentHeight);
            }
            CGSize result = CGSizeMake(contentWidth, contentHeight);
//            DDLogError(@"measuring: %@ %@", self.viewItem.interaction.description, self.attachmentStream.contentType);
//            DDLogError(@"\t contentSize: %@", NSStringFromCGSize(self.contentSize));
//            DDLogError(@"\t result: %@", NSStringFromCGSize(result));
            return result;
        }
        case OWSMessageCellMode_Audio:
            break;
        case OWSMessageCellMode_Video:
            break;
        case OWSMessageCellMode_GenericAttachment:
            break;
        case OWSMessageCellMode_DownloadingAttachment:
            break;
    }
    
//    TSMessage *interaction = (TSMessage *) self.viewItem.interaction;
//    NSString *_Nullable messageBody = interaction.body;
//    NSString *_Nullable attachmentId = interaction.attachmentIds.firstObject;
////    
////    if (messageBody.length > 0) {
//        // Text
//        BOOL isRTL = self.isRTL;
//        CGFloat leftMargin = isRTL ? self.trailingMargin : self.leadingMargin;
//        CGFloat rightMargin = isRTL ? self.leadingMargin : self.trailingMargin;
//        CGFloat vMargin = self.vMargin;
//        CGFloat maxTextWidth = maxMessageWidth - (leftMargin + rightMargin);
//        
//        self.textLabel.text = self.textMessage;
//        CGSize textSize = [self.textLabel sizeThatFits:CGSizeMake(maxTextWidth, CGFLOAT_MAX)];
//        CGSize result = CGSizeMake((CGFloat) ceil(textSize.width + leftMargin + rightMargin),
//                          (CGFloat) ceil(textSize.height + vMargin * 2));
////        NSLog(@"???? %@", self.viewItem.interaction.debugDescription);
////        NSLog(@"\t %@", messageBody);
////        NSLog(@"textSize: %@", NSStringFromCGSize(textSize));
////        NSLog(@"result: %@", NSStringFromCGSize(result));
//        return result;
//    } else {
//        // Attachment
//        // TODO:
//        return CGSizeMake(maxMessageWidth, maxMessageWidth);
//    }
    return CGSizeMake(maxMessageWidth, maxMessageWidth);
}

- (BOOL)isIncoming {
    return YES;
}

- (CGFloat)leadingMargin {
    return self.isIncoming ? 15 : 10;
}

- (CGFloat)trailingMargin {
    return self.isIncoming ? 10 : 15;
}

- (CGFloat)vMargin {
    return 10;
}

- (UIColor *)textColor {
    return self.isIncoming ? [UIColor blackColor] : [UIColor whiteColor];
}

- (OWSMessagesBubbleImageFactory *)bubbleFactory
{
    static OWSMessagesBubbleImageFactory *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [OWSMessagesBubbleImageFactory new];
    });
    return instance;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [NSLayoutConstraint deactivateConstraints:self.contentConstraints];
    self.contentConstraints = nil;

    self.textMessage = nil;
    self.attachmentStream = nil;
    self.attachmentPointer = nil;
    self.contentSize = CGSizeZero;
    
    // The text label is used so frequently that we always keep one around.
    self.textLabel.text = nil;
    self.textLabel.hidden = YES;
    self.bubbleImageView.image = nil;
    self.bubbleImageView.hidden = YES;
    
    [self.stillImageView removeFromSuperview];
    self.stillImageView = nil;
    [self.animatedImageView removeFromSuperview];
    self.animatedImageView = nil;
    [self.errorView removeFromSuperview];
    self.errorView = nil;

//    [self.textLabel removeFromSuperview];
//    self.textLabel = nil;
//    [self.bubbleImageView removeFromSuperview];
//    self.bubbleImageView = nil;
//    [self.attachmentUploadView removeFromSuperview];
    self.attachmentUploadView = nil;
    self.cellMode = OWSMessageCellMode_Unknown;
    
    self.contentView.backgroundColor = [UIColor whiteColor];
}

//let bubbleFactory = OWSMessagesBubbleImageFactory()
//let bodyLabel = UILabel()
//bodyLabel.textColor = isIncoming ? UIColor.black : UIColor.white
//bodyLabel.font = UIFont.ows_regularFont(withSize:16)
//bodyLabel.text = messageBody
//// Only show the first N lines.
//bodyLabel.numberOfLines = 10
//bodyLabel.lineBreakMode = .byWordWrapping
//
//let bubbleImageData = isIncoming ? bubbleFactory.incoming : bubbleFactory.outgoing
//
//let leadingMargin: CGFloat = isIncoming ? 15 : 10
//let trailingMargin: CGFloat = isIncoming ? 10 : 15
//
//let bubbleView = UIImageView(image: bubbleImageData.messageBubbleImage)
//
//bubbleView.layer.cornerRadius = 10
//bubbleView.addSubview(bodyLabel)

//- (void)awakeFromNib
//{
//    [super awakeFromNib];
//    self.expirationTimerViewWidthConstraint.constant = 0.0;
//
//    // Our text alignment needs to adapt to RTL.
//    self.cellBottomLabel.textAlignment = [self.cellBottomLabel textAlignmentUnnatural];
//}
//
//- (void)prepareForReuse
//{
//    [super prepareForReuse];
//    self.mediaView.alpha = 1.0;
//    self.expirationTimerViewWidthConstraint.constant = 0.0f;
//
//    [self.mediaAdapter setCellVisible:NO];
//
//    // Clear this adapter's views IFF this was the last cell to use this adapter.
//    [self.mediaAdapter clearCachedMediaViewsIfLastPresentingCell:self];
//    [_mediaAdapter setLastPresentingCell:nil];
//
//    self.mediaAdapter = nil;
//}
//
//- (void)setMediaAdapter:(nullable id<OWSMessageMediaAdapter>)mediaAdapter
//{
//    _mediaAdapter = mediaAdapter;
//
//    // Mark this as the last cell to use this adapter.
//    [_mediaAdapter setLastPresentingCell:self];
//}
//
//// pragma mark - OWSMessageCollectionViewCell
//
//- (void)setCellVisible:(BOOL)isVisible
//{
//    [self.mediaAdapter setCellVisible:isVisible];
//}
//
//- (UIColor *)ows_textColor
//{
//    return [UIColor whiteColor];
//}
//
//// pragma mark - OWSExpirableMessageView
//
//- (void)startExpirationTimerWithExpiresAtSeconds:(double)expiresAtSeconds
//                          initialDurationSeconds:(uint32_t)initialDurationSeconds
//{
//    self.expirationTimerViewWidthConstraint.constant = OWSExpirableMessageViewTimerWidth;
//    [self.expirationTimerView startTimerWithExpiresAtSeconds:expiresAtSeconds
//                                      initialDurationSeconds:initialDurationSeconds];
//}
//
//- (void)stopExpirationTimer
//{
//    [self.expirationTimerView stopTimer];
//}

#pragma mark - Gesture recognizers

- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
    OWSAssert(self.delegate);
    
    if (sender.state == UIGestureRecognizerStateRecognized) {
        [self.delegate didTapViewItem:self.viewItem];
    }
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)longPress
{
    OWSAssert(self.delegate);
    
    if (longPress.state == UIGestureRecognizerStateBegan) {
        [self.delegate didLongPressViewItem:self.viewItem];
    }
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
