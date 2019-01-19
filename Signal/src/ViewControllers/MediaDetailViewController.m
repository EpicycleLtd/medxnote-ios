//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "MediaDetailViewController.h"
#import "AttachmentSharing.h"
#import "ConversationViewController.h"
#import "ConversationViewItem.h"
#import "Signal-Swift.h"
#import "TSAttachmentStream.h"
#import "TSInteraction.h"
#import "UIColor+OWS.h"
#import "UIUtil.h"
#import "UIView+OWS.h"
#import <AVKit/AVKit.h>
#import <MediaPlayer/MPMoviePlayerViewController.h>
#import <MediaPlayer/MediaPlayer.h>
#import <SignalServiceKit/NSData+Image.h>
#import <YYImage/YYImage.h>

NS_ASSUME_NONNULL_BEGIN

// In order to use UIMenuController, the view from which it is
// presented must have certain custom behaviors.
@interface AttachmentMenuView : UIView

@end

#pragma mark -

@implementation AttachmentMenuView

- (BOOL)canBecomeFirstResponder {
    return YES;
}

// We only use custom actions in UIMenuController.
- (BOOL)canPerformAction:(SEL)action withSender:(nullable id)sender
{
    return NO;
}

@end

#pragma mark -

@interface MediaDetailViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, PlayerProgressBarDelegate>

@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIView *mediaView;

@property (nonatomic) UIButton *shareButton;

@property (nonatomic) CGRect originRect;
@property (nonatomic) NSData *fileData;

@property (nonatomic, nullable) TSAttachmentStream *attachmentStream;
@property (nonatomic, nullable) SignalAttachment *attachment;
@property (nonatomic, nullable) ConversationViewItem *viewItem;

@property (nonatomic) UIToolbar *footerBar;
@property (nonatomic) BOOL areToolbarsHidden;

@property (nonatomic, nullable) AVPlayer *videoPlayer;
@property (nonatomic, nullable) UIButton *playVideoButton;
@property (nonatomic, nullable) PlayerProgressBar *videoProgressBar;
@property (nonatomic, nullable) UIBarButtonItem *videoPlayBarButton;
@property (nonatomic, nullable) UIBarButtonItem *videoPauseBarButton;

@property (nonatomic, nullable) NSArray<NSLayoutConstraint *> *imageViewConstraints;
@property (nonatomic, nullable) NSLayoutConstraint *mediaViewBottomConstraint;
@property (nonatomic, nullable) NSLayoutConstraint *mediaViewLeadingConstraint;
@property (nonatomic, nullable) NSLayoutConstraint *mediaViewTopConstraint;
@property (nonatomic, nullable) NSLayoutConstraint *mediaViewTrailingConstraint;

@end

@implementation MediaDetailViewController

- (instancetype)initWithAttachmentStream:(TSAttachmentStream *)attachmentStream
                                fromRect:(CGRect)rect
                                viewItem:(ConversationViewItem *_Nullable)viewItem
{
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        self.attachmentStream = attachmentStream;
        self.originRect  = rect;
        self.viewItem = viewItem;
    }

    return self;
}

- (instancetype)initWithAttachment:(SignalAttachment *)attachment fromRect:(CGRect)rect
{
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        self.attachment = attachment;
        self.originRect = rect;
    }

    return self;
}

- (NSURL *_Nullable)attachmentUrl
{
    if (self.attachmentStream) {
        return self.attachmentStream.mediaURL;
    } else if (self.attachment) {
        return self.attachment.dataUrl;
    } else {
        return nil;
    }
}

- (NSData *)fileData
{
    if (!_fileData) {
        NSURL *_Nullable url = self.attachmentUrl;
        if (url) {
            _fileData = [NSData dataWithContentsOfURL:url];
        }
    }
    return _fileData;
}

- (UIImage *)image {
    if (self.attachmentStream) {
        return self.attachmentStream.image;
    } else if (self.attachment) {
        if (self.isVideo) {
            return self.attachment.videoPreview;
        } else {
            return self.attachment.image;
        }
    } else {
        return nil;
    }
}

- (BOOL)isAnimated
{
    if (self.attachmentStream) {
        return self.attachmentStream.isAnimated;
    } else if (self.attachment) {
        return self.attachment.isAnimatedImage;
    } else {
        return NO;
    }
}

- (BOOL)isVideo
{
    if (self.attachmentStream) {
        return self.attachmentStream.isVideo;
    } else if (self.attachment) {
        return self.attachment.isVideo;
    } else {
        return NO;
    }
}

- (void)loadView
{
    self.view = [AttachmentMenuView new];
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self createContents];
    [self initializeGestureRecognizers];

    // Even though bars are opaque, we want content to be layed out behind them.
    // The bars might obscure part of the content, but they can easily be hidden by tapping
    // The alternative would be that content would shift when the navbars hide.
    self.extendedLayoutIncludesOpaqueBars = YES;

    // TODO better title.
    self.title = @"Attachment";

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                      target:self
                                                      action:@selector(didTapDismissButton:)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([UIMenuController sharedMenuController].isMenuVisible) {
        [[UIMenuController sharedMenuController] setMenuVisible:NO
                                                       animated:NO];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateMinZoomScale];
    [self centerImageViewConstraints];
}

- (void)updateMinZoomScale
{
    CGSize viewSize = self.scrollView.bounds.size;
    UIImage *image = self.image;
    OWSAssert(image);

    if (image.size.width == 0 || image.size.height == 0) {
        OWSFail(@"%@ Invalid image dimensions. %@", self.logTag, NSStringFromCGSize(image.size));
        return;
    }

    CGFloat scaleWidth = viewSize.width / image.size.width;
    CGFloat scaleHeight = viewSize.height / image.size.height;
    CGFloat minScale = MIN(scaleWidth, scaleHeight);

    if (minScale != self.scrollView.minimumZoomScale) {
        self.scrollView.minimumZoomScale = minScale;
        self.scrollView.maximumZoomScale = minScale * 8;
        self.scrollView.zoomScale = minScale;
    }
}

#pragma mark - Initializers

- (void)createContents
{
    CGFloat kFooterHeight = 44;

    UIScrollView *scrollView = [UIScrollView new];
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    scrollView.delegate = self;

    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.automaticallyAdjustsScrollViewInsets = NO;

    [scrollView autoPinToSuperviewEdges];

    if (self.isAnimated) {
        if ([self.fileData ows_isValidImage]) {
            YYImage *animatedGif = [YYImage imageWithData:self.fileData];
            YYAnimatedImageView *animatedView = [YYAnimatedImageView new];
            animatedView.image = animatedGif;
            self.mediaView = animatedView;
        } else {
            self.mediaView = [UIImageView new];
        }
    } else if (self.isVideo) {
        self.mediaView = [self buildVideoPlayerView];
    } else {
        // Present the static image using standard UIImageView
        UIImageView *imageView = [[UIImageView alloc] initWithImage:self.image];

        self.mediaView = imageView;
    }

    OWSAssert(self.mediaView);

    [scrollView addSubview:self.mediaView];
    self.mediaView.contentMode = UIViewContentModeScaleAspectFit;
    self.mediaView.userInteractionEnabled = YES;
    self.mediaView.clipsToBounds = YES;
    self.mediaView.layer.allowsEdgeAntialiasing = YES;
    self.mediaView.translatesAutoresizingMaskIntoConstraints = NO;

    // Use trilinear filters for better scaling quality at
    // some performance cost.
    self.mediaView.layer.minificationFilter = kCAFilterTrilinear;
    self.mediaView.layer.magnificationFilter = kCAFilterTrilinear;

    [self applyInitialImageViewConstraints];

    if (self.isVideo) {
        if (@available(iOS 9, *)) {
            PlayerProgressBar *videoProgressBar = [PlayerProgressBar new];
            videoProgressBar.delegate = self;
            videoProgressBar.player = self.videoPlayer;

            self.videoProgressBar = videoProgressBar;
            [self.view addSubview:videoProgressBar];
            [videoProgressBar autoPinWidthToSuperview];
            [videoProgressBar autoPinToTopLayoutGuideOfViewController:self withInset:0];
            CGFloat kVideoProgressBarHeight = 44;
            [videoProgressBar autoSetDimension:ALDimensionHeight toSize:kVideoProgressBarHeight];
        }

        UIButton *playVideoButton = [UIButton new];
        self.playVideoButton = playVideoButton;

        [playVideoButton addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];

        UIImage *playImage = [UIImage imageNamed:@"play_button"];
        [playVideoButton setBackgroundImage:playImage forState:UIControlStateNormal];
        playVideoButton.contentMode = UIViewContentModeScaleAspectFill;

        [self.view addSubview:playVideoButton];

        CGFloat playVideoButtonWidth = ScaleFromIPhone5(70);
        [playVideoButton autoSetDimensionsToSize:CGSizeMake(playVideoButtonWidth, playVideoButtonWidth)];
        [playVideoButton autoCenterInSuperview];
    }


    // Don't show footer bar after tapping approval-view
    if (self.viewItem) {
        UIToolbar *footerBar = [UIToolbar new];
        _footerBar = footerBar;
        footerBar.barTintColor = [UIColor ows_signalBrandBlueColor];
        self.videoPlayBarButton =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                          target:self
                                                          action:@selector(didPressPlayBarButton:)];
        self.videoPauseBarButton =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                                                          target:self
                                                          action:@selector(didPressPauseBarButton:)];
        [self updateFooterBarButtonItemsWithIsPlayingVideo:YES];
        [self.view addSubview:footerBar];

        [footerBar autoPinWidthToSuperview];
        [footerBar autoPinToBottomLayoutGuideOfViewController:self withInset:0];
        [footerBar autoSetDimension:ALDimensionHeight toSize:kFooterHeight];
    }
}

- (void)updateFooterBarButtonItemsWithIsPlayingVideo:(BOOL)isPlayingVideo
{
    OWSAssert(self.footerBar);

    NSMutableArray<UIBarButtonItem *> *toolbarItems = [NSMutableArray new];

    [toolbarItems addObjectsFromArray:@[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                      target:self
                                                      action:@selector(didPressShare:)],
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
    ]];

    if (self.isVideo) {
        // bar button video controls only work on iOS9+
        if (@available(iOS 9.0, *)) {
            UIBarButtonItem *playerButton = isPlayingVideo ? self.videoPauseBarButton : self.videoPlayBarButton;
            [toolbarItems addObjectsFromArray:@[
                playerButton,
                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                              target:nil
                                                              action:nil],
            ]];
        }
    }

    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                          target:self
                                                                          action:@selector(didPressDelete:)]];

    [self.footerBar setItems:toolbarItems animated:NO];
}

- (void)applyInitialImageViewConstraints
{
    if (self.imageViewConstraints.count > 0) {
        [NSLayoutConstraint deactivateConstraints:self.imageViewConstraints];
    }

    CGRect convertedRect =
        [self.mediaView.superview convertRect:self.originRect fromView:[UIApplication sharedApplication].keyWindow];

    NSMutableArray<NSLayoutConstraint *> *imageViewConstraints = [NSMutableArray new];
    self.imageViewConstraints = imageViewConstraints;

    [imageViewConstraints addObjectsFromArray:[self.mediaView autoSetDimensionsToSize:convertedRect.size]];
    [imageViewConstraints addObjectsFromArray:@[
        [self.mediaView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:convertedRect.origin.y],
        [self.mediaView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:convertedRect.origin.x]
    ]];
}

- (void)applyFinalImageViewConstraints
{
    if (self.imageViewConstraints.count > 0) {
        [NSLayoutConstraint deactivateConstraints:self.imageViewConstraints];
    }

    NSMutableArray<NSLayoutConstraint *> *imageViewConstraints = [NSMutableArray new];
    self.imageViewConstraints = imageViewConstraints;

    self.mediaViewLeadingConstraint = [self.mediaView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    self.mediaViewTopConstraint = [self.mediaView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    self.mediaViewTrailingConstraint = [self.mediaView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    self.mediaViewBottomConstraint = [self.mediaView autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    [imageViewConstraints addObjectsFromArray:@[
        self.mediaViewTopConstraint,
        self.mediaViewTrailingConstraint,
        self.mediaViewBottomConstraint,
        self.mediaViewLeadingConstraint
    ]];
}

- (UIView *)buildVideoPlayerView
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:[self.attachmentUrl path]]) {
        OWSFail(@"%@ Missing video file: %@", self.logTag, self.attachmentStream.mediaURL);
    }

    if (@available(iOS 9.0, *)) {
        AVPlayer *player = [[AVPlayer alloc] initWithURL:self.attachmentUrl];
        [player seekToTime:kCMTimeZero];
        self.videoPlayer = player;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidPlayToCompletion:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:player.currentItem];

        VideoPlayerView *playerView = [VideoPlayerView new];
        playerView.player = player;

        [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow
                             forConstraints:^{
                                 [playerView autoSetDimensionsToSize:self.image.size];
                             }];

        return playerView;
    } else {
        return [[UIImageView alloc] initWithImage:self.image];
    }
}

- (void)setAreToolbarsHidden:(BOOL)areToolbarsHidden
{
    if (_areToolbarsHidden == areToolbarsHidden) {
        return;
    }

    _areToolbarsHidden = areToolbarsHidden;

    // Hiding the status bar affects the positioing of the navbar. We don't want to show that in an animation, it's
    // better to just have everythign "flit" in/out.
    [[UIApplication sharedApplication] setStatusBarHidden:areToolbarsHidden withAnimation:UIStatusBarAnimationNone];
    [self.navigationController setNavigationBarHidden:areToolbarsHidden animated:NO];
    self.videoProgressBar.hidden = areToolbarsHidden;

    [UIView animateWithDuration:0.1
                     animations:^(void) {
                         self.view.backgroundColor = areToolbarsHidden ? UIColor.blackColor : UIColor.whiteColor;
                         self.footerBar.alpha = areToolbarsHidden ? 0 : 1;
                     }];
}

- (void)initializeGestureRecognizers
{
    UITapGestureRecognizer *doubleTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTapImage:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];

    UITapGestureRecognizer *singleTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapImage:)];
    [singleTap requireGestureRecognizerToFail:doubleTap];

    [self.view addGestureRecognizer:singleTap];

    // UISwipeGestureRecognizer supposedly supports multiple directions,
    // but in practice it works better if you use a separate GR for each
    // direction.
    for (NSNumber *direction in @[
                                  @(UISwipeGestureRecognizerDirectionRight),
                                  @(UISwipeGestureRecognizerDirectionLeft),
                                  @(UISwipeGestureRecognizerDirectionUp),
                                  @(UISwipeGestureRecognizerDirectionDown),
                                  ]) {
        UISwipeGestureRecognizer *swipe =
            [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeImage:)];
        swipe.direction = (UISwipeGestureRecognizerDirection) direction.integerValue;
        swipe.delegate = self;
        [self.view addGestureRecognizer:swipe];
    }

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(longPressGesture:)];
    longPress.delegate = self;
    [self.view addGestureRecognizer:longPress];
}

#pragma mark - Gesture Recognizers

- (void)didTapDismissButton:(id)sender
{
    [self dismissSelfAnimated:YES completion:nil];
}

- (void)didTapImage:(id)sender
{
    DDLogVerbose(@"%@ did tap image.", self.logTag);
    self.areToolbarsHidden = !self.areToolbarsHidden;
}

- (void)didDoubleTapImage:(UITapGestureRecognizer *)gesture
{
    DDLogVerbose(@"%@ did double tap image.", self.logTag);
    if (self.scrollView.zoomScale == self.scrollView.minimumZoomScale) {
        CGFloat kDoubleTapZoomScale = 2;

        CGFloat zoomWidth = self.scrollView.width / kDoubleTapZoomScale;
        CGFloat zoomHeight = self.scrollView.height / kDoubleTapZoomScale;

        // center zoom rect around tapLocation
        CGPoint tapLocation = [gesture locationInView:self.scrollView];
        CGFloat zoomX = MAX(0, tapLocation.x - zoomWidth / 2);
        CGFloat zoomY = MAX(0, tapLocation.y - zoomHeight / 2);

        CGRect zoomRect = CGRectMake(zoomX, zoomY, zoomWidth, zoomHeight);

        CGRect translatedRect = [self.mediaView convertRect:zoomRect fromView:self.scrollView];

        [self.scrollView zoomToRect:translatedRect animated:YES];
    } else {
        // If already zoomed in at all, zoom out all the way.
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    }
}

- (void)didSwipeImage:(UIGestureRecognizer *)sender
{
    // Ignore if image is zoomed in at all.
    // e.g. otherwise, for example, if the image is horizontally larger than the scroll
    // view, but fits vertically, swiping left/right will scroll the image, but swiping up/down
    // would dismiss the image. That would not be intuitive.
    if (self.scrollView.zoomScale != self.scrollView.minimumZoomScale) {
        return;
    }

    [self dismissSelfAnimated:YES completion:nil];
}

- (void)longPressGesture:(UIGestureRecognizer *)sender {
    // We "eagerly" respond when the long press begins, not when it ends.
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (!self.viewItem) {
            return;
        }

        [self.view becomeFirstResponder];
        
        if ([UIMenuController sharedMenuController].isMenuVisible) {
            [[UIMenuController sharedMenuController] setMenuVisible:NO
                                                           animated:NO];
        }

        NSArray *menuItems = self.viewItem.menuControllerItems;
        [UIMenuController sharedMenuController].menuItems = menuItems;
        CGPoint location = [sender locationInView:self.view];
        CGRect targetRect = CGRectMake(location.x,
                                       location.y,
                                       1, 1);
        [[UIMenuController sharedMenuController] setTargetRect:targetRect
                                                        inView:self.view];
        [[UIMenuController sharedMenuController] setMenuVisible:YES
                                                       animated:YES];
    }
}

- (void)didPressShare:(id)sender
{
    DDLogInfo(@"%@: didPressShare", self.logTag);
    if (!self.viewItem) {
        OWSFail(@"share should only be available when a viewItem is present");
        return;
    }

    [self.viewItem shareAction];
}

- (void)didPressDelete:(id)sender
{
    DDLogInfo(@"%@: didPressDelete", self.logTag);
    if (!self.viewItem) {
        OWSFail(@"delete should only be available when a viewItem is present");
        return;
    }

    UIAlertController *actionSheet =
        [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [actionSheet
        addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"TXT_DELETE_TITLE", nil)
                                           style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction *action) {
                                             OWSAssert([self.presentingViewController
                                                 isKindOfClass:[UINavigationController class]]);
                                             UINavigationController *navController
                                                 = (UINavigationController *)self.presentingViewController;

                                             if ([navController.topViewController
                                                     isKindOfClass:[ConversationViewController class]]) {
                                                 [self dismissSelfAnimated:YES
                                                                completion:^{
                                                                    [self.viewItem deleteAction];
                                                                }];
                                             } else if ([navController.topViewController
                                                            isKindOfClass:[MessageDetailViewController class]]) {
                                                 [self dismissSelfAnimated:NO
                                                                completion:^{
                                                                    [self.viewItem deleteAction];
                                                                }];
                                                 [navController popViewControllerAnimated:YES];
                                             } else {
                                                 OWSFail(@"Unexpected presentation context.");
                                                 [self dismissSelfAnimated:YES
                                                                completion:^{
                                                                    [self.viewItem deleteAction];
                                                                }];
                                             }
                                         }]];

    [actionSheet addAction:[OWSAlerts cancelAction]];
    actionSheet.popoverPresentationController.sourceView = self.view;
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (BOOL)canPerformAction:(SEL)action withSender:(nullable id)sender
{
    if (self.viewItem == nil) {
        return NO;
    }

    if (action == self.viewItem.metadataActionSelector) {
        return NO;
    }
    return [self.viewItem canPerformAction:action];
}

- (void)copyAction:(nullable id)sender
{
    if (!self.viewItem) {
        OWSFail(@"copy should only be available when a viewItem is present");
        return;
    }

    [self.viewItem copyAction];
}

- (void)shareAction:(nullable id)sender
{
    if (!self.viewItem) {
        OWSFail(@"share should only be available when a viewItem is present");
        return;
    }

    [self didPressShare:sender];
}

- (void)saveAction:(nullable id)sender
{
    if (!self.viewItem) {
        OWSFail(@"save should only be available when a viewItem is present");
        return;
    }

    [self.viewItem saveAction];
}

- (void)deleteAction:(nullable id)sender
{
    if (!self.viewItem) {
        OWSFail(@"delete should only be available when a viewItem is present");
        return;
    }

    [self didPressDelete:sender];
}

- (void)didPressPlayBarButton:(id)sender
{
    OWSAssert(self.isVideo);
    OWSAssert(self.videoPlayer);
    [self playVideo];
}

- (void)didPressPauseBarButton:(id)sender
{
    OWSAssert(self.isVideo);
    OWSAssert(self.videoPlayer);
    [self pauseVideo];
}

#pragma mark - Presentation

- (void)presentFromViewController:(UIViewController *)viewController
{
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self];

    // UIModalPresentationCustom retains the current view context behind our VC, allowing us to manually
    // animate in our view, over the existing context, similar to a cross disolve, but allowing us to have
    // more fine grained control
    navController.modalPresentationStyle = UIModalPresentationCustom;
    navController.navigationBar.barTintColor = UIColor.ows_materialBlueColor;
    navController.navigationBar.translucent = NO;
    navController.navigationBar.opaque = YES;

    self.view.userInteractionEnabled = NO;

    self.view.alpha = 0.0;
    [viewController presentViewController:navController
                                 animated:NO
                               completion:^{

                                   // 1. Fade in the entire view.
                                   [UIView animateWithDuration:0.1
                                                    animations:^{
                                                        self.view.alpha = 1.0;
                                                    }];

                                   // Make sure imageView is layed out before we update it's frame in the next
                                   // animation.
                                   [self.mediaView.superview layoutIfNeeded];

                                   // 2. Animate imageView from it's initial position, which should match where it was
                                   // in the presenting view to it's final position, front and center in this view. This
                                   // animation intentionally overlaps the previous
                                   [UIView animateWithDuration:0.2
                                       delay:0.08
                                       options:UIViewAnimationOptionCurveEaseOut
                                       animations:^(void) {
                                           [self applyFinalImageViewConstraints];
                                           [self.mediaView.superview layoutIfNeeded];
                                           // We must lay out *before* we centerImageViewConstraints
                                           // because it uses the imageView.frame to build the contstraints
                                           // that will center the imageView, and then once again
                                           // to ensure that the centered constraints are applied.
                                           [self centerImageViewConstraints];
                                           [self.mediaView.superview layoutIfNeeded];
                                           self.view.backgroundColor = UIColor.whiteColor;
                                       }
                                       completion:^(BOOL finished) {
                                           self.view.userInteractionEnabled = YES;

                                           if (self.isVideo) {
                                               [self playVideo];
                                           }
                                       }];
                               }];
}

- (void)dismissSelfAnimated:(BOOL)isAnimated completion:(void (^_Nullable)(void))completion
{
    self.view.userInteractionEnabled = NO;
    [UIApplication sharedApplication].statusBarHidden = NO;

    OWSAssert(self.mediaView.superview);

    [self.mediaView.superview layoutIfNeeded];

    // Move the image view pack to it's initial position, i.e. where
    // it sits on the screen in the conversation view.
    [self applyInitialImageViewConstraints];

    if (isAnimated) {
        [UIView animateWithDuration:0.2
            delay:0.0
            options:UIViewAnimationOptionCurveEaseInOut
            animations:^(void) {
                [self.mediaView.superview layoutIfNeeded];

                // In case user has hidden bars, which changes background to black.
                self.view.backgroundColor = UIColor.whiteColor;

                // fade out content and toolbars
                self.navigationController.view.alpha = 0.0;
            }
            completion:^(BOOL finished) {
                [self.presentingViewController dismissViewControllerAnimated:NO completion:completion];
            }];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:completion];
    }
}

#pragma mark - UIScrollViewDelegate

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.mediaView;
}

- (void)centerImageViewConstraints
{
    OWSAssert(self.scrollView);

    CGSize scrollViewSize = self.scrollView.bounds.size;
    CGSize imageViewSize = self.mediaView.frame.size;

    CGFloat yOffset = MAX(0, (scrollViewSize.height - imageViewSize.height) / 2);
    self.mediaViewTopConstraint.constant = yOffset;
    self.mediaViewBottomConstraint.constant = yOffset;

    CGFloat xOffset = MAX(0, (scrollViewSize.width - imageViewSize.width) / 2);
    self.mediaViewLeadingConstraint.constant = xOffset;
    self.mediaViewTrailingConstraint.constant = xOffset;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self centerImageViewConstraints];
    [self.view layoutIfNeeded];
}

#pragma mark - Video Playback

- (void)playVideo
{
    if (@available(iOS 9, *)) {
        OWSAssert(self.videoPlayer);
        AVPlayer *player = self.videoPlayer;

        [self updateFooterBarButtonItemsWithIsPlayingVideo:YES];
        self.playVideoButton.hidden = YES;
        self.areToolbarsHidden = YES;

        OWSAssert(player.currentItem);
        AVPlayerItem *item = player.currentItem;
        if (CMTIME_COMPARE_INLINE(item.currentTime, ==, item.duration)) {
            // Rewind for repeated plays
            [player seekToTime:kCMTimeZero];
        }

        [player play];
    } else {
        [self legacyPlayVideo];
        return;
    }
}

- (void)pauseVideo
{
    OWSAssert(self.isVideo);
    OWSAssert(self.videoPlayer);

    [self updateFooterBarButtonItemsWithIsPlayingVideo:NO];
    [self.videoPlayer pause];
}

- (void)playerItemDidPlayToCompletion:(NSNotification *)notification
{
    OWSAssert(self.isVideo);
    OWSAssert(self.videoPlayer);
    DDLogVerbose(@"%@ %s", self.logTag, __PRETTY_FUNCTION__);

    self.areToolbarsHidden = NO;
    self.playVideoButton.hidden = NO;

    [self updateFooterBarButtonItemsWithIsPlayingVideo:NO];
}

- (void)playerProgressBarDidStartScrubbing:(PlayerProgressBar *)playerProgressBar
{
    OWSAssert(self.videoPlayer);
    [self.videoPlayer pause];
}

- (void)playerProgressBar:(PlayerProgressBar *)playerProgressBar scrubbedToTime:(CMTime)time
{
    OWSAssert(self.videoPlayer);
    [self.videoPlayer seekToTime:time];
}

- (void)playerProgressBar:(PlayerProgressBar *)playerProgressBar
    didFinishScrubbingAtTime:(CMTime)time
        shouldResumePlayback:(BOOL)shouldResumePlayback
{
    OWSAssert(self.videoPlayer);
    [self.videoPlayer seekToTime:time];

    if (shouldResumePlayback) {
        [self.videoPlayer play];
    }
}

#pragma mark iOS8 Video Playback

// AVPlayer was introduced in iOS9, so on iOS8 we fall back to MPMoviePlayer
// This causes an unforutnate "double present" since we present the full screen view and then the MPMovie view over top.
// And similarly a double dismiss.
- (void)legacyPlayVideo
{
    if (@available(iOS 9.0, *)) {
        OWSFail(@"legacy video is for iOS8 only");
    }
    MPMoviePlayerViewController *vc = [[MPMoviePlayerViewController alloc] initWithContentURL:self.attachmentUrl];

    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Saving images to Camera Roll

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        DDLogWarn(@"There was a problem saving <%@> to camera roll from %s ",
                  error.localizedDescription,
                  __PRETTY_FUNCTION__);
    }
}

@end

NS_ASSUME_NONNULL_END
