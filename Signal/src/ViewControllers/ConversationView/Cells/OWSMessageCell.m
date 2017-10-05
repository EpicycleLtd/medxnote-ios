//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSMessageCell.h"
//#import "OWSExpirationTimerView.h"
//#import "UIView+OWS.h"
//#import <JSQMessagesViewController/JSQMediaItem.h>
#import "ConversationViewItem.h"
#import "Signal-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface OWSMessageCell ()

@property (nonatomic) UILabel *textLabel;
@property (nonatomic) UIImageView *bubbleImageView;
@property (nonatomic) NSArray<NSLayoutConstraint *> *bubbleContraints;

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
    self.layoutMargins = UIEdgeInsetsMake(0, 0, 0, 0);
    
    self.bubbleImageView = [UIImageView new];
    self.bubbleImageView.layoutMargins = UIEdgeInsetsMake(0, 0, 0, 0);
    [self.contentView addSubview:self.bubbleImageView];
    [self.bubbleImageView autoPinToSuperviewEdges];
    
    self.textLabel = [UILabel new];
    self.textLabel.font = [UIFont ows_regularFontWithSize:16.f];
    self.textLabel.numberOfLines = 0;
    self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.textLabel.textAlignment = NSTextAlignmentLeft;
    [self.bubbleImageView addSubview:self.textLabel];
    
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
}

- (void)configure
{
    OWSAssert(self.viewItem);
    OWSAssert(self.viewItem.interaction);
    OWSAssert([self.viewItem.interaction isKindOfClass:[TSMessage class]]);
    
    TSMessage *interaction = (TSMessage *) self.viewItem.interaction;
    NSString *_Nullable messageBody = interaction.body;
    NSString *_Nullable attachmentId = interaction.attachmentIds.firstObject;
    
    if (messageBody.length > 0) {
        // Text
        BOOL isRTL = self.isRTL;
//        CGFloat leftMargin = isRTL ? self.trailingMargin : self.leadingMargin;
//        CGFloat rightMargin = isRTL ? self.leadingMargin : self.trailingMargin;
//        CGFloat vMargin = self.vMargin;
        BOOL isIncoming = self.isIncoming;
        
        // Zalgo.
        self.textLabel.text = messageBody;
        self.textLabel.textColor = [self textColor];

        JSQMessagesBubbleImage *bubbleImageData = isIncoming ? [self.bubbleFactory incoming] : [self.bubbleFactory outgoing];
        self.bubbleImageView.image = bubbleImageData.messageBubbleImage;
        
        [NSLayoutConstraint deactivateConstraints:self.bubbleContraints];
//        NSMutableArray<NSLayoutConstraint *> *bubbleContraints = [NSMutableArray new];
        self.bubbleContraints = @[
                                  [self.textLabel autoPinLeadingToSuperviewWithMargin:self.leadingMargin],
                                  [self.textLabel autoPinTrailingToSuperviewWithMargin:self.trailingMargin],
                                  [self.textLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:self.vMargin],
                                  [self.textLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:self.vMargin],
                                  ];
//
//        @property (nonatomic) NSArray<NSLayoutConstraint *> *bubbleContraints;

        //
        //let leadingMargin: CGFloat = isIncoming ? 15 : 10
        //let trailingMargin: CGFloat = isIncoming ? 10 : 15
        //
        //let bubbleView = UIImageView(image: bubbleImageData.messageBubbleImage)

        
        self.textLabel.hidden = NO;
        self.bubbleImageView.hidden = NO;
        self.contentView.backgroundColor = [UIColor whiteColor];
    } else {
        // Attachment
        self.textLabel.hidden = YES;
        self.bubbleImageView.hidden = YES;
        self.contentView.backgroundColor = [UIColor redColor];
    }

//    [self.textLabel addBorderWithColor:[UIColor blueColor]];
//    [self.bubbleImageView addBorderWithColor:[UIColor greenColor]];

//    dispatch_async(dispatch_get_main_queue(), ^{
//        NSLog(@"---- %@", self.viewItem.interaction.debugDescription);
//        NSLog(@"cell: %@", NSStringFromCGRect(self.frame));
//        NSLog(@"contentView: %@", NSStringFromCGRect(self.contentView.frame));
//        NSLog(@"textLabel: %@", NSStringFromCGRect(self.textLabel.frame));
//        NSLog(@"bubbleImageView: %@", NSStringFromCGRect(self.bubbleImageView.frame));
//    });

    //
//
//    OWSAssert(
//              interaction.hasBlockOffer || interaction.hasAddToContactsOffer || interaction.hasAddToProfileWhitelistOffer);
    
//    [self setNeedsLayout];
}

- (CGSize)cellSizeForViewWidth:(int)viewWidth
               maxMessageWidth:(int)maxMessageWidth
{
    OWSAssert(self.viewItem);
    OWSAssert([self.viewItem.interaction isKindOfClass:[TSMessage class]]);
    
    TSMessage *interaction = (TSMessage *) self.viewItem.interaction;
    NSString *_Nullable messageBody = interaction.body;
    NSString *_Nullable attachmentId = interaction.attachmentIds.firstObject;
    
    if (messageBody.length > 0) {
        // Text
        BOOL isRTL = self.isRTL;
        CGFloat leftMargin = isRTL ? self.trailingMargin : self.leadingMargin;
        CGFloat rightMargin = isRTL ? self.leadingMargin : self.trailingMargin;
        CGFloat vMargin = self.vMargin;
        CGFloat maxTextWidth = maxMessageWidth - (leftMargin + rightMargin);
        
        // Zalgo.
        self.textLabel.text = messageBody;
        CGSize textSize = [self.textLabel sizeThatFits:CGSizeMake(maxTextWidth, CGFLOAT_MAX)];
        CGSize result = CGSizeMake((CGFloat) ceil(textSize.width + leftMargin + rightMargin),
                          (CGFloat) ceil(textSize.height + vMargin * 2));
//        NSLog(@"???? %@", self.viewItem.interaction.debugDescription);
//        NSLog(@"\t %@", messageBody);
//        NSLog(@"textSize: %@", NSStringFromCGSize(textSize));
//        NSLog(@"result: %@", NSStringFromCGSize(result));
        return result;
    } else {
        // Attachment
        // TODO:
        return CGSizeMake(maxMessageWidth, maxMessageWidth);
    }
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
    
    self.textLabel.text = nil;
    self.bubbleImageView.image = nil;
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

@end

NS_ASSUME_NONNULL_END
