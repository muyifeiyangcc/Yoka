//
//  YKFindDetailViewController.m
//  Yoka
//

#import "YKFindDetailViewController.h"
#import "YKFindItemsViewController.h"
#import "YKFindPersonaBoardViewController.h"
#import "YKRemarkLedger.h"
#import "YKFindFavorLedger.h"
#import "YKPieceUnlockLedger.h"
#import "YKPublishLedger.h"
#import "YKPersonaCatalog.h"
#import "YKRosterVault.h"
#import "YKBondLedger.h"
#import "YKSparkCoffer.h"
#import "YKSparkTopUpViewController.h"
#import "YKReportShadeSheet.h"
#import "YKReportViewController.h"
#import "YKShadeRoster.h"
#import "YKCenterToast.h"
#import "YKEmptyStateView.h"
#import <AVFoundation/AVFoundation.h>
#import "YKCipherLoom.h"

@interface YKFindDetailPhotoView : UIView

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *playerHostView;
@property (nonatomic, strong) UIImageView *playIconView;
@property (nonatomic, strong) CAGradientLayer *fallbackGradientLayer;
@property (nonatomic, strong) CAGradientLayer *bottomGradientLayer;
@property (nonatomic, strong) UILabel *fallbackTitleLabel;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) id loopObserver;
@property (nonatomic, assign) BOOL yk_hasVideo;
@property (nonatomic, assign) BOOL yk_userPaused;

- (void)yk_showImage:(UIImage *)image;
- (void)yk_playVideoAtURL:(NSURL *)url;
- (void)yk_pausePlayback;
- (void)yk_resumePlayback;
- (void)yk_stopPlayback;
- (void)yk_togglePlaybackIfVideo;

@end

@implementation YKFindDetailPhotoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self yk_setupViews];
    }
    return self;
}

- (void)dealloc {
    [self yk_stopPlayback];
}

- (void)yk_setupViews {
    self.layer.cornerRadius = 14.0;
    self.layer.masksToBounds = YES;
    self.backgroundColor = [UIColor colorWithRed:0.39 green:0.13 blue:0.55 alpha:1.0];
    self.userInteractionEnabled = YES;

    CAGradientLayer *fallbackGradientLayer = [CAGradientLayer layer];
    fallbackGradientLayer.startPoint = CGPointMake(0.0, 0.0);
    fallbackGradientLayer.endPoint = CGPointMake(1.0, 1.0);
    fallbackGradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.10 green:0.11 blue:0.20 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.85 green:0.00 blue:0.76 alpha:1.0].CGColor
    ];
    [self.layer addSublayer:fallbackGradientLayer];
    self.fallbackGradientLayer = fallbackGradientLayer;

    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [self addSubview:imageView];
    self.imageView = imageView;

    UIView *playerHostView = [[UIView alloc] init];
    playerHostView.translatesAutoresizingMaskIntoConstraints = NO;
    playerHostView.backgroundColor = UIColor.clearColor;
    playerHostView.userInteractionEnabled = NO;
    [self addSubview:playerHostView];
    self.playerHostView = playerHostView;

    UILabel *fallbackTitleLabel = [[UILabel alloc] init];
    fallbackTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    fallbackTitleLabel.text = @"Y2K FIT";
    fallbackTitleLabel.textColor = UIColor.whiteColor;
    fallbackTitleLabel.textAlignment = NSTextAlignmentCenter;
    fallbackTitleLabel.font = [UIFont systemFontOfSize:36.0 weight:UIFontWeightBlack];
    fallbackTitleLabel.alpha = 1.0;
    [self addSubview:fallbackTitleLabel];
    self.fallbackTitleLabel = fallbackTitleLabel;

    CAGradientLayer *bottomGradientLayer = [CAGradientLayer layer];
    bottomGradientLayer.colors = @[
        (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor,
        (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.52].CGColor
    ];
    bottomGradientLayer.locations = @[@0.45, @1.0];
    [self.layer addSublayer:bottomGradientLayer];
    self.bottomGradientLayer = bottomGradientLayer;

    UIImageView *playIconView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"mine_play_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    playIconView.translatesAutoresizingMaskIntoConstraints = NO;
    playIconView.contentMode = UIViewContentModeScaleAspectFit;
    playIconView.hidden = YES;
    playIconView.userInteractionEnabled = NO;
    [self addSubview:playIconView];
    self.playIconView = playIconView;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(yk_mediaTapped:)];
    [self addGestureRecognizer:tap];

    [NSLayoutConstraint activateConstraints:@[
        [imageView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [imageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [imageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [imageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        [playerHostView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [playerHostView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [playerHostView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [playerHostView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        [fallbackTitleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [fallbackTitleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

        [playIconView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [playIconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [playIconView.widthAnchor constraintEqualToConstant:54.0],
        [playIconView.heightAnchor constraintEqualToConstant:54.0]
    ]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.fallbackGradientLayer.frame = self.bounds;
    self.bottomGradientLayer.frame = self.bounds;
    self.playerLayer.frame = self.playerHostView.bounds;
}

- (void)yk_showImage:(UIImage *)image {
    [self yk_stopPlayback];
    self.yk_hasVideo = NO;
    self.yk_userPaused = NO;
    self.playerHostView.hidden = YES;
    self.playIconView.hidden = YES;
    self.imageView.image = image;
    self.fallbackTitleLabel.alpha = image ? 0.0 : 1.0;
}

- (void)yk_playVideoAtURL:(NSURL *)url {
    [self yk_stopPlayback];
    self.yk_hasVideo = (url != nil);
    self.yk_userPaused = NO;
    self.playerHostView.hidden = NO;
    self.playIconView.hidden = YES;
    if (!url) {
        return;
    }

    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
    player.muted = YES;
    player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    self.player = player;

    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    playerLayer.frame = self.playerHostView.bounds;
    [self.playerHostView.layer addSublayer:playerLayer];
    self.playerLayer = playerLayer;

    __weak typeof(self) weakSelf = self;
    self.loopObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                                          object:item
                                                                           queue:[NSOperationQueue mainQueue]
                                                                      usingBlock:^(NSNotification * _Nonnull note) {
        if (weakSelf.yk_userPaused) {
            return;
        }
        [weakSelf.player seekToTime:kCMTimeZero];
        [weakSelf.player play];
    }];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        AVAsset *asset = [AVAsset assetWithURL:url];
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
        generator.maximumSize = CGSizeMake(900.0, 1200.0);
        NSError *error = nil;
        CGImageRef cgImage = [generator copyCGImageAtTime:CMTimeMake(1, 2) actualTime:NULL error:&error];
        if (!cgImage) {
            return;
        }
        UIImage *thumb = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = thumb;
            self.fallbackTitleLabel.alpha = 0.0;
        });
    });

    [player play];
}

- (void)yk_mediaTapped:(UITapGestureRecognizer *)gesture {
    [self yk_togglePlaybackIfVideo];
}

- (void)yk_togglePlaybackIfVideo {
    if (!self.yk_hasVideo || !self.player) {
        return;
    }
    if (self.yk_userPaused) {
        self.yk_userPaused = NO;
        self.playIconView.hidden = YES;
        [self.player play];
    } else {
        self.yk_userPaused = YES;
        self.playIconView.hidden = NO;
        [self.player pause];
    }
}

- (void)yk_pausePlayback {
    [self.player pause];
}

- (void)yk_resumePlayback {
    if (!self.yk_hasVideo || self.yk_userPaused) {
        return;
    }
    [self.player play];
}

- (void)yk_stopPlayback {
    if (self.loopObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.loopObserver];
        self.loopObserver = nil;
    }
    [self.player pause];
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    self.player = nil;
    self.yk_hasVideo = NO;
}

@end

@interface YKFindDetailViewController () <UITextFieldDelegate>

@property (nonatomic, copy) NSDictionary *entry;
@property (nonatomic, copy) NSString *displayAlias;
@property (nonatomic, weak) YKFindDetailPhotoView *photoView;
@property (nonatomic, weak) UILabel *commentCountLabel;
@property (nonatomic, weak) UIImageView *favorIconView;
@property (nonatomic, weak) UILabel *likeCountLabel;
@property (nonatomic, assign) BOOL yk_favored;
@property (nonatomic, assign) NSInteger yk_favorCount;
@property (nonatomic, strong) UIView *commentOverlayView;
@property (nonatomic, strong) UIView *commentPanelView;
@property (nonatomic, strong) UIView *yk_remarkInputBar;
@property (nonatomic, strong) UIView *yk_remarkInputPane;
@property (nonatomic, strong) UIView *yk_commentKeyboardCornerFill;
@property (nonatomic, strong) UIStackView *yk_remarksStackView;
@property (nonatomic, strong) YKEmptyStateView *yk_commentsEmptyView;
@property (nonatomic, strong) UITextField *yk_commentField;
@property (nonatomic, strong) NSLayoutConstraint *yk_remarkInputBottomPin;
@property (nonatomic, strong) NSLayoutConstraint *yk_remarkInputLeading;
@property (nonatomic, strong) NSLayoutConstraint *yk_remarkInputTrailing;
@property (nonatomic, strong) NSLayoutConstraint *yk_remarkInputHeight;
@property (nonatomic, strong) NSLayoutConstraint *yk_remarkInputPaneLeading;
@property (nonatomic, strong) NSLayoutConstraint *yk_remarkInputPaneTrailing;
@property (nonatomic, strong) NSLayoutConstraint *yk_remarkInputPaneTop;
@property (nonatomic, strong) NSLayoutConstraint *yk_remarkInputPaneBottom;
@property (nonatomic, strong) NSLayoutConstraint *yk_commentKeyboardFillHeight;
@property (nonatomic, copy) NSArray<NSDictionary *> *yk_displayRemarks;
@property (nonatomic, copy) NSString *yk_actionPeerId;
@property (nonatomic, strong) UIView *spendDialogOverlayView;
@property (nonatomic, weak) UIImageView *yk_spendDialogImageView;
@property (nonatomic, assign) BOOL yk_spendDialogIsAffordable;

@end

@implementation YKFindDetailViewController

- (instancetype)initWithEntry:(NSDictionary *)post {
    self = [super init];
    if (self) {
        _entry = [post copy] ?: @{};
        NSString *name = _entry[@"name"];
        _displayAlias = name.length > 0 ? [name copy] : @"Yoka";
    }
    return self;
}

- (instancetype)initWithDisplayAlias:(NSString *)userName {
    return [self initWithEntry:@{@"name": userName.length > 0 ? userName : @"Yoka"}];
}

- (void)yk_configurePage {
    [super yk_configurePage];
    [self yk_setupContentView];
    [self yk_registerCommentKeyboardObservers];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.photoView yk_resumePlayback];
    self.yk_favored = [[YKFindFavorLedger sharedLedger] yk_isEntryFavored:self.entry ownerKey:[self yk_ownerKey]];
    [self yk_refreshFavorAppearance];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.photoView yk_pausePlayback];
}

- (void)yk_setupContentView {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    scrollView.clipsToBounds = YES;
    [self.view addSubview:scrollView];

    UIButton *backButton = [self yk_addBackButton];
    [self.view bringSubviewToFront:backButton];

    UIButton *viewItemsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    viewItemsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [viewItemsButton setTitle:@"View Items" forState:UIControlStateNormal];
    [viewItemsButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    viewItemsButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    viewItemsButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.55 blue:0.86 alpha:0.55];
    viewItemsButton.contentEdgeInsets = UIEdgeInsetsMake(0.0, 14.0, 0.0, 14.0);
    viewItemsButton.layer.cornerRadius = 16.0;
    viewItemsButton.layer.borderWidth = 1.0;
    viewItemsButton.layer.borderColor = UIColor.whiteColor.CGColor;
    viewItemsButton.clipsToBounds = YES;
    [viewItemsButton addTarget:self action:@selector(yk_viewItemsNavTapped:) forControlEvents:UIControlEventTouchUpInside];
    viewItemsButton.hidden = ![self yk_hasItemsList];
    [self.view addSubview:viewItemsButton];
    [self.view bringSubviewToFront:viewItemsButton];

    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];

    NSString *personaId = self.entry[@"personaId"];
    BOOL isOwnPost = [self yk_isOwnPost];
    UIImage *avatar = nil;
    if (isOwnPost) {
        avatar = [[YKRosterVault sharedRoster] yk_portraitImageForActiveMailbox];
    }
    if (!avatar) {
        avatar = [YKPersonaCatalog yk_avatarImageForPersonaId:personaId] ?: [UIImage imageNamed:@"headplace"];
    }
    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[avatar imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    avatarImageView.layer.cornerRadius = 22.0;
    avatarImageView.layer.masksToBounds = YES;
    avatarImageView.userInteractionEnabled = YES;
    [contentView addSubview:avatarImageView];

    UIButton *avatarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    avatarButton.translatesAutoresizingMaskIntoConstraints = NO;
    if (!isOwnPost) {
        [avatarButton addTarget:self action:@selector(yk_avatarButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        avatarButton.userInteractionEnabled = NO;
    }
    [contentView addSubview:avatarButton];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = self.displayAlias;
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    [contentView addSubview:nameLabel];

    UILabel *subNameLabel = [[UILabel alloc] init];
    subNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subNameLabel.text = self.displayAlias;
    subNameLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.86];
    subNameLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    [contentView addSubview:subNameLabel];

    YKFindDetailPhotoView *photoView = [[YKFindDetailPhotoView alloc] initWithFrame:CGRectZero];
    photoView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:photoView];
    self.photoView = photoView;
    [self yk_loadMediaIntoPhotoView:photoView];

    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [moreButton setImage:[[UIImage imageNamed:@"detail_more_button"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [moreButton addTarget:self action:@selector(yk_moreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    moreButton.hidden = isOwnPost;
    [contentView addSubview:moreButton];

    NSString *caption = self.entry[@"caption"];
    UILabel *descriptionLabel = [[UILabel alloc] init];
    descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    descriptionLabel.numberOfLines = 0;
    descriptionLabel.text = caption.length > 0 ? caption : @"";
    descriptionLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.92];
    descriptionLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    [contentView addSubview:descriptionLabel];

    UIView *statsRow = [[UIView alloc] init];
    statsRow.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:statsRow];

    UIStackView *statsStackView = [[UIStackView alloc] init];
    statsStackView.translatesAutoresizingMaskIntoConstraints = NO;
    statsStackView.axis = UILayoutConstraintAxisHorizontal;
    statsStackView.alignment = UIStackViewAlignmentCenter;
    statsStackView.spacing = 16.0;
    [statsRow addSubview:statsStackView];

    NSNumber *likesNumber = self.entry[@"favors"];
    NSInteger baseFavors;
    if ([likesNumber isKindOfClass:NSNumber.class]) {
        baseFavors = MAX(0, MIN(20, likesNumber.integerValue));
    } else {
        // Stable 1…20 from post identity when likes are missing.
        NSUInteger mixTag = [self yk_entryFavorKey].hash;
        baseFavors = (NSInteger)(mixTag % 20) + 1;
    }
    self.yk_favored = [[YKFindFavorLedger sharedLedger] yk_isEntryFavored:self.entry ownerKey:[self yk_ownerKey]];
    self.yk_favorCount = MIN(20, baseFavors + (self.yk_favored ? 1 : 0));
    [statsStackView addArrangedSubview:[self yk_favorStatButton]];
    [statsStackView addArrangedSubview:[self yk_commentStatButton]];

    UIButton *unlockButton = [self yk_unlockItemButton];
    unlockButton.hidden = ![self yk_hasItemsList] || [self yk_isOwnPost];
    [statsRow addSubview:unlockButton];

    [self yk_setupCommentPanelView];
    [self yk_setupSpendDialogView];
    [self.view bringSubviewToFront:backButton];
    [self.view bringSubviewToFront:viewItemsButton];

    UILayoutGuide *safeGuide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [viewItemsButton.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
        [viewItemsButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16.0],
        [viewItemsButton.heightAnchor constraintEqualToConstant:32.0],

        // Content starts below the nav controls; page background stays continuous (no chrome seam).
        [scrollView.topAnchor constraintEqualToAnchor:safeGuide.topAnchor constant:52.0],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],

        [avatarImageView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:8.0],
        [avatarImageView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24.0],
        [avatarImageView.widthAnchor constraintEqualToConstant:44.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:44.0],

        [avatarButton.topAnchor constraintEqualToAnchor:avatarImageView.topAnchor],
        [avatarButton.leadingAnchor constraintEqualToAnchor:avatarImageView.leadingAnchor],
        [avatarButton.trailingAnchor constraintEqualToAnchor:subNameLabel.trailingAnchor constant:8.0],
        [avatarButton.bottomAnchor constraintEqualToAnchor:avatarImageView.bottomAnchor],

        [nameLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:10.0],
        [nameLabel.topAnchor constraintEqualToAnchor:avatarImageView.topAnchor constant:2.0],

        [subNameLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [subNameLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:2.0],

        [moreButton.centerYAnchor constraintEqualToAnchor:avatarImageView.centerYAnchor],
        [moreButton.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-24.0],
        [moreButton.widthAnchor constraintEqualToConstant:36.0],
        [moreButton.heightAnchor constraintEqualToConstant:36.0],

        [photoView.topAnchor constraintEqualToAnchor:avatarImageView.bottomAnchor constant:18.0],
        [photoView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24.0],
        [photoView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-24.0],
        [photoView.heightAnchor constraintEqualToAnchor:photoView.widthAnchor multiplier:1.23],

        [descriptionLabel.topAnchor constraintEqualToAnchor:photoView.bottomAnchor constant:16.0],
        [descriptionLabel.leadingAnchor constraintEqualToAnchor:photoView.leadingAnchor],
        [descriptionLabel.trailingAnchor constraintEqualToAnchor:photoView.trailingAnchor],

        [statsRow.topAnchor constraintEqualToAnchor:descriptionLabel.bottomAnchor constant:16.0],
        [statsRow.leadingAnchor constraintEqualToAnchor:photoView.leadingAnchor],
        [statsRow.trailingAnchor constraintEqualToAnchor:photoView.trailingAnchor],
        [statsRow.heightAnchor constraintEqualToConstant:28.0],
        [statsRow.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-40.0],

        [statsStackView.leadingAnchor constraintEqualToAnchor:statsRow.leadingAnchor],
        [statsStackView.centerYAnchor constraintEqualToAnchor:statsRow.centerYAnchor],

        [unlockButton.trailingAnchor constraintEqualToAnchor:statsRow.trailingAnchor],
        [unlockButton.centerYAnchor constraintEqualToAnchor:statsRow.centerYAnchor],
        [unlockButton.leadingAnchor constraintGreaterThanOrEqualToAnchor:statsStackView.trailingAnchor constant:12.0]
    ]];
}

- (void)yk_loadMediaIntoPhotoView:(YKFindDetailPhotoView *)photoView {
    NSString *videoName = self.entry[@"video"];
    if (videoName.length > 0) {
        NSURL *videoURL = [[NSBundle mainBundle] URLForResource:videoName withExtension:@"mp4"];
        if (videoURL) {
            [photoView yk_playVideoAtURL:videoURL];
            return;
        }
    }

    NSURL *publishedVideoURL = [YKPublishLedger yk_videoURLForEntry:self.entry];
    if (publishedVideoURL) {
        [photoView yk_playVideoAtURL:publishedVideoURL];
        return;
    }

    UIImage *image = nil;
    NSString *imageName = self.entry[@"image"];
    if (imageName.length > 0) {
        image = [UIImage imageNamed:imageName];
    }
    if (!image) {
        image = [YKPublishLedger yk_coverImageForEntry:self.entry];
    }
    [photoView yk_showImage:image];
}

- (NSString *)yk_entryFavorKey {
    return [YKFindFavorLedger yk_entryKeyForEntry:self.entry];
}

- (UIButton *)yk_favorStatButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button addTarget:self action:@selector(yk_favorButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 5.0;
    stackView.userInteractionEnabled = NO;
    [button addSubview:stackView];

    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [stackView addArrangedSubview:imageView];
    self.favorIconView = imageView;

    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor colorWithWhite:1.0 alpha:0.88];
    label.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    [stackView addArrangedSubview:label];
    self.likeCountLabel = label;
    [self yk_refreshFavorAppearance];

    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:button.topAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:button.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:button.trailingAnchor],
        [stackView.bottomAnchor constraintEqualToAnchor:button.bottomAnchor],
        [imageView.widthAnchor constraintEqualToConstant:16.0],
        [imageView.heightAnchor constraintEqualToConstant:16.0]
    ]];

    return button;
}

- (void)yk_refreshFavorAppearance {
    YKFindFavorLedger *ledger = [YKFindFavorLedger sharedLedger];
    NSString *iconName = self.yk_favored ? [ledger yk_favoredStarImageName] : [ledger yk_unfavoredStarImageName];
    self.favorIconView.image = [[UIImage imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.yk_favorCount];
}

- (void)yk_favorButtonTapped:(UIButton *)sender {
    self.yk_favored = !self.yk_favored;
    self.yk_favorCount += self.yk_favored ? 1 : -1;
    if (self.yk_favorCount < 0) {
        self.yk_favorCount = 0;
    }
    if (self.yk_favorCount > 20) {
        self.yk_favorCount = 20;
    }
    [[YKFindFavorLedger sharedLedger] yk_setEntry:self.entry favored:self.yk_favored ownerKey:[self yk_ownerKey]];
    [self yk_refreshFavorAppearance];
}

- (UIView *)yk_statViewWithImageName:(NSString *)imageName title:(NSString *)title {
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 5.0;

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [stackView addArrangedSubview:imageView];

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.textColor = [UIColor colorWithWhite:1.0 alpha:0.88];
    label.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    [stackView addArrangedSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [imageView.widthAnchor constraintEqualToConstant:16.0],
        [imageView.heightAnchor constraintEqualToConstant:16.0]
    ]];

    return stackView;
}

- (UIButton *)yk_commentStatButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button addTarget:self action:@selector(yk_commentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 5.0;
    stackView.userInteractionEnabled = NO;
    [button addSubview:stackView];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"detail_remark_icon"]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [stackView addArrangedSubview:imageView];

    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor colorWithWhite:1.0 alpha:0.88];
    label.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    [stackView addArrangedSubview:label];
    self.commentCountLabel = label;
    [self yk_refreshCommentCountLabel];

    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:button.topAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:button.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:button.trailingAnchor],
        [stackView.bottomAnchor constraintEqualToAnchor:button.bottomAnchor],
        [imageView.widthAnchor constraintEqualToConstant:16.0],
        [imageView.heightAnchor constraintEqualToConstant:16.0]
    ]];

    return button;
}

- (NSString *)yk_selfAuthorId {
    YKRosterVault *vault = [YKRosterVault sharedRoster];
    if ([YKRosterVault yk_isReviewMailbox:vault.yk_activeMailbox ?: @""]) {
        return [YKPersonaCatalog yk_reviewPersonaId];
    }
    NSDictionary *dossier = [vault yk_dossierForActiveMailbox];
    NSString *personaId = dossier[@"personaId"];
    if ([personaId isKindOfClass:NSString.class] && personaId.length > 0) {
        return personaId;
    }
    return vault.yk_activeMailbox.length > 0 ? vault.yk_activeMailbox : @"guest";
}

- (NSString *)yk_selfAuthorName {
    NSString *name = [[YKRosterVault sharedRoster] yk_displayNameForActiveMailbox];
    if (name.length > 0) {
        return name;
    }
    if ([YKRosterVault yk_isReviewMailbox:[[YKRosterVault sharedRoster] yk_activeMailbox] ?: @""]) {
        return [YKPersonaCatalog yk_reviewPersonaDisplayName];
    }
    return @"Me";
}

- (BOOL)yk_isMineRemark:(NSDictionary *)remark {
    if ([remark[@"isMine"] boolValue]) {
        return YES;
    }
    NSString *personaId = remark[@"personaId"];
    return [personaId isKindOfClass:NSString.class] && [personaId isEqualToString:[self yk_selfAuthorId]];
}

- (NSArray<NSDictionary *> *)yk_mergedRemarks {
    NSArray *catalogRemarksList = self.entry[@"remarks"];
    NSArray *merged = [[YKRemarkLedger sharedLedger] yk_remarksForOwnerKey:[self yk_ownerKey]
                                                                   postKey:[self yk_entryFavorKey]
                                                              catalogRemarks:catalogRemarksList];
    NSString *owner = [self yk_ownerKey];
    NSMutableArray *visible = [NSMutableArray array];
    for (NSDictionary *remark in merged) {
        NSString *personaId = remark[@"personaId"];
        if ([personaId isKindOfClass:NSString.class] &&
            [[YKShadeRoster sharedRoster] yk_ownerKey:owner hasShadedId:personaId] &&
            ![self yk_isMineRemark:remark]) {
            continue;
        }
        [visible addObject:remark];
    }
    return visible;
}

- (void)yk_refreshCommentCountLabel {
    NSInteger count = (NSInteger)[self yk_mergedRemarks].count;
    self.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
}

- (void)yk_setupCommentPanelView {
    UIView *overlayView = [[UIView alloc] init];
    overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    overlayView.hidden = YES;
    overlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.01];
    [self.view addSubview:overlayView];
    self.commentOverlayView = overlayView;

    UIButton *dismissHitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissHitButton.translatesAutoresizingMaskIntoConstraints = NO;
    dismissHitButton.backgroundColor = UIColor.clearColor;
    [dismissHitButton addTarget:self action:@selector(yk_dismissCommentPanel) forControlEvents:UIControlEventTouchUpInside];
    [overlayView addSubview:dismissHitButton];

    UIView *panelView = [[UIView alloc] init];
    panelView.translatesAutoresizingMaskIntoConstraints = NO;
    panelView.backgroundColor = [UIColor colorWithRed:0.88 green:0.31 blue:0.93 alpha:0.96];
    panelView.layer.cornerRadius = 18.0;
    panelView.layer.borderColor = UIColor.whiteColor.CGColor;
    panelView.layer.borderWidth = 1.4;
    panelView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [overlayView addSubview:panelView];
    self.commentPanelView = panelView;

    UIScrollView *commentsScrollView = [[UIScrollView alloc] init];
    commentsScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    commentsScrollView.showsVerticalScrollIndicator = NO;
    commentsScrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [panelView addSubview:commentsScrollView];

    UIStackView *remarksStackView = [[UIStackView alloc] init];
    remarksStackView.translatesAutoresizingMaskIntoConstraints = NO;
    remarksStackView.axis = UILayoutConstraintAxisVertical;
    remarksStackView.spacing = 10.0;
    [commentsScrollView addSubview:remarksStackView];
    self.yk_remarksStackView = remarksStackView;

    YKEmptyStateView *commentsEmpty = [[YKEmptyStateView alloc] init];
    [panelView addSubview:commentsEmpty];
    self.yk_commentsEmptyView = commentsEmpty;

    UIView *inputBar = [[UIView alloc] init];
    inputBar.translatesAutoresizingMaskIntoConstraints = NO;
    inputBar.backgroundColor = UIColor.clearColor;
    inputBar.clipsToBounds = NO;
    [overlayView addSubview:inputBar];
    self.yk_remarkInputBar = inputBar;

    // Fills the transparent rounded top corners of the system keyboard.
    UIView *keyboardCornerFill = [[UIView alloc] init];
    keyboardCornerFill.translatesAutoresizingMaskIntoConstraints = NO;
    keyboardCornerFill.backgroundColor = UIColor.whiteColor;
    keyboardCornerFill.hidden = YES;
    keyboardCornerFill.userInteractionEnabled = NO;
    [overlayView insertSubview:keyboardCornerFill belowSubview:inputBar];
    self.yk_commentKeyboardCornerFill = keyboardCornerFill;

    UIView *inputPane = [[UIView alloc] init];
    inputPane.translatesAutoresizingMaskIntoConstraints = NO;
    inputPane.backgroundColor = UIColor.whiteColor;
    inputPane.layer.cornerRadius = 22.0;
    [inputBar addSubview:inputPane];
    self.yk_remarkInputPane = inputPane;

    UITextField *textField = [[UITextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.placeholder = @"Say something";
    textField.textColor = UIColor.blackColor;
    textField.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    textField.returnKeyType = UIReturnKeySend;
    textField.delegate = self;
    [inputPane addSubview:textField];
    self.yk_commentField = textField;

    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [sendButton setImage:[[UIImage imageNamed:@"thread_dispatch"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [sendButton addTarget:self action:@selector(yk_sendRemarkTapped:) forControlEvents:UIControlEventTouchUpInside];
    [inputPane addSubview:sendButton];

    self.yk_remarkInputBottomPin = [inputBar.bottomAnchor constraintEqualToAnchor:overlayView.bottomAnchor constant:-10.0];
    self.yk_remarkInputLeading = [inputBar.leadingAnchor constraintEqualToAnchor:overlayView.leadingAnchor constant:20.0];
    self.yk_remarkInputTrailing = [inputBar.trailingAnchor constraintEqualToAnchor:overlayView.trailingAnchor constant:-20.0];
    self.yk_remarkInputHeight = [inputBar.heightAnchor constraintEqualToConstant:44.0];
    self.yk_remarkInputPaneLeading = [inputPane.leadingAnchor constraintEqualToAnchor:inputBar.leadingAnchor];
    self.yk_remarkInputPaneTrailing = [inputPane.trailingAnchor constraintEqualToAnchor:inputBar.trailingAnchor];
    self.yk_remarkInputPaneTop = [inputPane.topAnchor constraintEqualToAnchor:inputBar.topAnchor];
    self.yk_remarkInputPaneBottom = [inputPane.bottomAnchor constraintEqualToAnchor:inputBar.bottomAnchor];
    self.yk_commentKeyboardFillHeight = [keyboardCornerFill.heightAnchor constraintEqualToConstant:0.0];

    [NSLayoutConstraint activateConstraints:@[
        [overlayView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [overlayView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [overlayView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [overlayView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [dismissHitButton.topAnchor constraintEqualToAnchor:overlayView.topAnchor],
        [dismissHitButton.leadingAnchor constraintEqualToAnchor:overlayView.leadingAnchor],
        [dismissHitButton.trailingAnchor constraintEqualToAnchor:overlayView.trailingAnchor],
        [dismissHitButton.bottomAnchor constraintEqualToAnchor:panelView.topAnchor],

        [panelView.leadingAnchor constraintEqualToAnchor:overlayView.leadingAnchor],
        [panelView.trailingAnchor constraintEqualToAnchor:overlayView.trailingAnchor],
        [panelView.bottomAnchor constraintEqualToAnchor:overlayView.bottomAnchor],
        [panelView.heightAnchor constraintEqualToConstant:323.0],

        [commentsScrollView.topAnchor constraintEqualToAnchor:panelView.topAnchor constant:18.0],
        [commentsScrollView.leadingAnchor constraintEqualToAnchor:panelView.leadingAnchor constant:20.0],
        [commentsScrollView.trailingAnchor constraintEqualToAnchor:panelView.trailingAnchor constant:-20.0],
        [commentsScrollView.bottomAnchor constraintEqualToAnchor:panelView.safeAreaLayoutGuide.bottomAnchor constant:-66.0],

        [remarksStackView.topAnchor constraintEqualToAnchor:commentsScrollView.contentLayoutGuide.topAnchor],
        [remarksStackView.leadingAnchor constraintEqualToAnchor:commentsScrollView.contentLayoutGuide.leadingAnchor],
        [remarksStackView.trailingAnchor constraintEqualToAnchor:commentsScrollView.contentLayoutGuide.trailingAnchor],
        [remarksStackView.bottomAnchor constraintEqualToAnchor:commentsScrollView.contentLayoutGuide.bottomAnchor],
        [remarksStackView.widthAnchor constraintEqualToAnchor:commentsScrollView.frameLayoutGuide.widthAnchor],

        [commentsEmpty.centerXAnchor constraintEqualToAnchor:commentsScrollView.centerXAnchor],
        [commentsEmpty.centerYAnchor constraintEqualToAnchor:commentsScrollView.centerYAnchor constant:-8.0],
        [commentsEmpty.widthAnchor constraintEqualToConstant:200.0],

        self.yk_remarkInputLeading,
        self.yk_remarkInputTrailing,
        self.yk_remarkInputBottomPin,
        self.yk_remarkInputHeight,

        [keyboardCornerFill.leadingAnchor constraintEqualToAnchor:overlayView.leadingAnchor],
        [keyboardCornerFill.trailingAnchor constraintEqualToAnchor:overlayView.trailingAnchor],
        [keyboardCornerFill.topAnchor constraintEqualToAnchor:inputBar.bottomAnchor],
        self.yk_commentKeyboardFillHeight,

        self.yk_remarkInputPaneLeading,
        self.yk_remarkInputPaneTrailing,
        self.yk_remarkInputPaneTop,
        self.yk_remarkInputPaneBottom,

        [textField.centerYAnchor constraintEqualToAnchor:inputPane.centerYAnchor],
        [textField.leadingAnchor constraintEqualToAnchor:inputPane.leadingAnchor constant:14.0],
        [textField.trailingAnchor constraintEqualToAnchor:sendButton.leadingAnchor constant:-10.0],

        [sendButton.centerYAnchor constraintEqualToAnchor:inputPane.centerYAnchor],
        [sendButton.trailingAnchor constraintEqualToAnchor:inputPane.trailingAnchor constant:-5.0],
        [sendButton.widthAnchor constraintEqualToConstant:38.0],
        [sendButton.heightAnchor constraintEqualToConstant:38.0]
    ]];

    [self yk_applyCommentInputDockedToKeyboard:NO keyboardOverlap:0.0];
    [self yk_reloadCommentRows];
}

- (void)yk_reloadCommentRows {
    for (UIView *sub in [self.yk_remarksStackView.arrangedSubviews copy]) {
        [self.yk_remarksStackView removeArrangedSubview:sub];
        [sub removeFromSuperview];
    }
    self.yk_displayRemarks = [self yk_mergedRemarks];
    for (NSInteger index = 0; index < (NSInteger)self.yk_displayRemarks.count; index++) {
        NSDictionary *comment = self.yk_displayRemarks[index];
        if (index > 0) {
            [self.yk_remarksStackView addArrangedSubview:[self yk_commentSeparatorView]];
        }
        BOOL mine = [self yk_isMineRemark:comment];
        [self.yk_remarksStackView addArrangedSubview:[self yk_commentRowWithRemark:comment showMore:!mine]];
    }
    self.yk_commentsEmptyView.hidden = self.yk_displayRemarks.count > 0;
    [self yk_refreshCommentCountLabel];
}

- (void)yk_registerCommentKeyboardObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yk_commentKeyboardWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yk_commentKeyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)yk_applyCommentInputDockedToKeyboard:(BOOL)docked keyboardOverlap:(CGFloat)overlap {
    if (docked) {
        // White sheet sitting on the keyboard: rounded top, inset capsule field (not a hard full-bleed strip).
        self.yk_remarkInputBar.backgroundColor = UIColor.whiteColor;
        self.yk_remarkInputBar.clipsToBounds = YES;
        self.yk_remarkInputBar.layer.cornerRadius = 18.0;
        self.yk_remarkInputBar.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        if (@available(iOS 13.0, *)) {
            self.yk_remarkInputBar.layer.cornerCurve = kCACornerCurveContinuous;
        }
        self.yk_remarkInputLeading.constant = 0.0;
        self.yk_remarkInputTrailing.constant = 0.0;
        self.yk_remarkInputPaneLeading.constant = 16.0;
        self.yk_remarkInputPaneTrailing.constant = -16.0;
        self.yk_remarkInputPaneTop.constant = 8.0;
        self.yk_remarkInputPaneBottom.constant = -8.0;
        self.yk_remarkInputHeight.constant = 58.0;
        self.yk_remarkInputBottomPin.constant = -overlap;
        self.yk_remarkInputPane.layer.cornerRadius = 21.0;
        self.yk_remarkInputPane.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
        self.yk_commentKeyboardCornerFill.hidden = NO;
        self.yk_commentKeyboardCornerFill.backgroundColor = UIColor.whiteColor;
        self.yk_commentKeyboardFillHeight.constant = 28.0;
    } else {
        CGFloat safeBottom = self.view.safeAreaInsets.bottom;
        if (safeBottom < 0.5 && self.commentOverlayView.window) {
            safeBottom = self.commentOverlayView.window.safeAreaInsets.bottom;
        }
        self.yk_remarkInputBar.backgroundColor = UIColor.clearColor;
        self.yk_remarkInputBar.clipsToBounds = NO;
        self.yk_remarkInputBar.layer.cornerRadius = 0.0;
        self.yk_remarkInputBar.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
        self.yk_remarkInputLeading.constant = 20.0;
        self.yk_remarkInputTrailing.constant = -20.0;
        self.yk_remarkInputPaneLeading.constant = 0.0;
        self.yk_remarkInputPaneTrailing.constant = 0.0;
        self.yk_remarkInputPaneTop.constant = 0.0;
        self.yk_remarkInputPaneBottom.constant = 0.0;
        self.yk_remarkInputHeight.constant = 44.0;
        self.yk_remarkInputBottomPin.constant = -(safeBottom + 10.0);
        self.yk_remarkInputPane.layer.cornerRadius = 22.0;
        self.yk_remarkInputPane.backgroundColor = UIColor.whiteColor;
        self.yk_commentKeyboardCornerFill.hidden = YES;
        self.yk_commentKeyboardFillHeight.constant = 0.0;
    }
}

- (void)yk_commentKeyboardWillChange:(NSNotification *)note {
    if (self.commentOverlayView.hidden) {
        return;
    }
    CGRect endFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect inView = [self.view convertRect:endFrame fromView:nil];
    CGFloat overlap = MAX(0.0, CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(inView));
    NSTimeInterval duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [note.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    BOOL docked = overlap > 1.0;
    [self yk_applyCommentInputDockedToKeyboard:docked keyboardOverlap:overlap];
    [UIView animateWithDuration:duration delay:0 options:(curve << 16) animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)yk_commentKeyboardWillHide:(NSNotification *)note {
    if (self.commentOverlayView.hidden) {
        return;
    }
    NSTimeInterval duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [note.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [self yk_applyCommentInputDockedToKeyboard:NO keyboardOverlap:0.0];
    [UIView animateWithDuration:duration delay:0 options:(curve << 16) animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)yk_setupSpendDialogView {
    UIView *overlayView = [[UIView alloc] init];
    overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    overlayView.hidden = YES;
    overlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.58];
    [self.view addSubview:overlayView];
    self.spendDialogOverlayView = overlayView;

    UIImageView *dialogImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"enough"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    dialogImageView.translatesAutoresizingMaskIntoConstraints = NO;
    dialogImageView.contentMode = UIViewContentModeScaleAspectFit;
    dialogImageView.userInteractionEnabled = YES;
    [overlayView addSubview:dialogImageView];
    self.yk_spendDialogImageView = dialogImageView;

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton addTarget:self action:@selector(yk_cancelSpendDialog:) forControlEvents:UIControlEventTouchUpInside];
    [dialogImageView addSubview:cancelButton];

    UIButton *sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sureButton.translatesAutoresizingMaskIntoConstraints = NO;
    [sureButton addTarget:self action:@selector(yk_confirmSpendDialog:) forControlEvents:UIControlEventTouchUpInside];
    [dialogImageView addSubview:sureButton];

    [NSLayoutConstraint activateConstraints:@[
        [overlayView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [overlayView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [overlayView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [overlayView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [dialogImageView.centerXAnchor constraintEqualToAnchor:overlayView.centerXAnchor],
        [dialogImageView.centerYAnchor constraintEqualToAnchor:overlayView.centerYAnchor constant:-6.0],
        [dialogImageView.widthAnchor constraintEqualToConstant:309.0],
        [dialogImageView.heightAnchor constraintEqualToConstant:241.0],

        [cancelButton.leadingAnchor constraintEqualToAnchor:dialogImageView.leadingAnchor constant:50.0],
        [cancelButton.bottomAnchor constraintEqualToAnchor:dialogImageView.bottomAnchor constant:-32.0],
        [cancelButton.widthAnchor constraintEqualToConstant:92.0],
        [cancelButton.heightAnchor constraintEqualToConstant:31.0],

        [sureButton.trailingAnchor constraintEqualToAnchor:dialogImageView.trailingAnchor constant:-38.0],
        [sureButton.bottomAnchor constraintEqualToAnchor:dialogImageView.bottomAnchor constant:-32.0],
        [sureButton.widthAnchor constraintEqualToConstant:96.0],
        [sureButton.heightAnchor constraintEqualToConstant:31.0]
    ]];
}

- (UIView *)yk_commentRowWithRemark:(NSDictionary *)remark showMore:(BOOL)showMore {
    UIView *rowView = [[UIView alloc] init];
    rowView.translatesAutoresizingMaskIntoConstraints = NO;

    NSString *personaId = [remark[@"personaId"] isKindOfClass:NSString.class] ? remark[@"personaId"] : @"";
    UIImage *avatarImage = nil;
    if ([remark[@"isMine"] boolValue]) {
        avatarImage = [[YKRosterVault sharedRoster] yk_portraitImageForActiveMailbox];
    }
    if (!avatarImage) {
        avatarImage = [YKPersonaCatalog yk_avatarImageForPersonaId:personaId] ?: [UIImage imageNamed:@"headplace"];
    }
    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[avatarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    avatarImageView.layer.cornerRadius = 15.0;
    avatarImageView.layer.masksToBounds = YES;
    [rowView addSubview:avatarImageView];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = remark[@"name"] ?: @"Yoka";
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    [rowView addSubview:nameLabel];

    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    textLabel.numberOfLines = 0;
    textLabel.text = remark[@"text"] ?: @"";
    textLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.82];
    textLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    [rowView addSubview:textLabel];

    NSMutableArray *constraints = [NSMutableArray arrayWithArray:@[
        [rowView.heightAnchor constraintGreaterThanOrEqualToConstant:62.0],

        [avatarImageView.topAnchor constraintEqualToAnchor:rowView.topAnchor],
        [avatarImageView.leadingAnchor constraintEqualToAnchor:rowView.leadingAnchor],
        [avatarImageView.widthAnchor constraintEqualToConstant:30.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:30.0],

        [nameLabel.topAnchor constraintEqualToAnchor:rowView.topAnchor constant:2.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:10.0],

        [textLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:8.0],
        [textLabel.leadingAnchor constraintEqualToAnchor:rowView.leadingAnchor],
        [textLabel.trailingAnchor constraintEqualToAnchor:rowView.trailingAnchor constant:-4.0],
        [textLabel.bottomAnchor constraintEqualToAnchor:rowView.bottomAnchor]
    ]];

    if (showMore && personaId.length > 0) {
        UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        moreButton.translatesAutoresizingMaskIntoConstraints = NO;
        moreButton.accessibilityIdentifier = personaId;
        [moreButton setImage:[[UIImage imageNamed:@"detail_more_dots"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        [moreButton addTarget:self action:@selector(yk_commentMoreTapped:) forControlEvents:UIControlEventTouchUpInside];
        [rowView addSubview:moreButton];
        [constraints addObjectsFromArray:@[
            [moreButton.centerYAnchor constraintEqualToAnchor:nameLabel.centerYAnchor],
            [moreButton.trailingAnchor constraintEqualToAnchor:rowView.trailingAnchor],
            [moreButton.widthAnchor constraintEqualToConstant:32.0],
            [moreButton.heightAnchor constraintEqualToConstant:22.0],
            [nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:moreButton.leadingAnchor constant:-8.0]
        ]];
    } else {
        [constraints addObject:[nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:rowView.trailingAnchor]];
    }

    [NSLayoutConstraint activateConstraints:constraints];
    return rowView;
}

- (UIView *)yk_commentSeparatorView {
    UIView *separatorView = [[UIView alloc] init];
    separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    separatorView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.18];
    [NSLayoutConstraint activateConstraints:@[
        [separatorView.heightAnchor constraintEqualToConstant:1.0]
    ]];
    return separatorView;
}

- (void)yk_commentButtonTapped:(UIButton *)sender {
    [self.photoView yk_pausePlayback];
    [self yk_reloadCommentRows];
    [self yk_applyCommentInputDockedToKeyboard:NO keyboardOverlap:0.0];
    self.commentOverlayView.hidden = NO;
    self.commentOverlayView.alpha = 0.0;
    self.commentPanelView.transform = CGAffineTransformMakeTranslation(0.0, 28.0);
    self.yk_remarkInputBar.transform = CGAffineTransformMakeTranslation(0.0, 28.0);
    [self.view bringSubviewToFront:self.commentOverlayView];

    [UIView animateWithDuration:0.22
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.commentOverlayView.alpha = 1.0;
        self.commentPanelView.transform = CGAffineTransformIdentity;
        self.yk_remarkInputBar.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)yk_dismissCommentPanel {
    [self.view endEditing:YES];
    [self yk_applyCommentInputDockedToKeyboard:NO keyboardOverlap:0.0];
    [UIView animateWithDuration:0.18
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.commentOverlayView.alpha = 0.0;
        self.commentPanelView.transform = CGAffineTransformMakeTranslation(0.0, 28.0);
        self.yk_remarkInputBar.transform = CGAffineTransformMakeTranslation(0.0, 28.0);
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.commentOverlayView.hidden = YES;
        self.commentPanelView.transform = CGAffineTransformIdentity;
        self.yk_remarkInputBar.transform = CGAffineTransformIdentity;
        [self.photoView yk_resumePlayback];
    }];
}

- (void)yk_sendRemarkTapped:(UIButton *)sender {
    [self yk_commitCommentFromField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.yk_commentField) {
        [self yk_commitCommentFromField];
        return NO;
    }
    return YES;
}

- (void)yk_commitCommentFromField {
    NSString *body = [self.yk_commentField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (body.length == 0) {
        return;
    }
    NSDictionary *remark = @{
        @"personaId": [self yk_selfAuthorId],
        @"name": [self yk_selfAuthorName],
        @"text": body,
        @"isMine": @YES,
        @"stamp": @([[NSDate date] timeIntervalSince1970])
    };
    [[YKRemarkLedger sharedLedger] yk_ownerKey:[self yk_ownerKey]
                                 appendRemark:remark
                                    forEntryKey:[self yk_entryFavorKey]];
    self.yk_commentField.text = @"";
    [self yk_reloadCommentRows];
    [self.view layoutIfNeeded];
    UIView *lastRow = self.yk_remarksStackView.arrangedSubviews.lastObject;
    if (lastRow) {
        UIScrollView *scrollView = (UIScrollView *)self.yk_remarksStackView.superview;
        if ([scrollView isKindOfClass:UIScrollView.class]) {
            CGRect target = [lastRow convertRect:lastRow.bounds toView:scrollView];
            [scrollView scrollRectToVisible:target animated:YES];
        }
    }
    [self.view endEditing:YES];
}

- (void)yk_commentMoreTapped:(UIButton *)sender {
    NSString *peerId = sender.accessibilityIdentifier ?: @"";
    if (peerId.length == 0) {
        return;
    }
    self.yk_actionPeerId = peerId;
    [self.view endEditing:YES];
    __weak typeof(self) weakSelf = self;
    [YKReportShadeSheet yk_presentInView:self.view
                                  report:^{
        YKReportViewController *report = [[YKReportViewController alloc] initWithPersonaId:weakSelf.yk_actionPeerId];
        [weakSelf.navigationController pushViewController:report animated:YES];
    }
                                   block:^{
        [weakSelf yk_shadeRemarkPeer:weakSelf.yk_actionPeerId];
    }];
}

- (void)yk_shadeRemarkPeer:(NSString *)peerId {
    if (peerId.length == 0) {
        return;
    }
    NSString *owner = [self yk_ownerKey];
    if ([peerId isEqualToString:owner] || [peerId isEqualToString:[self yk_selfAuthorId]]) {
        return;
    }
    [[YKShadeRoster sharedRoster] yk_ownerKey:owner shadeId:peerId];
    [[YKBondLedger sharedLedger] yk_ownerKey:owner setLink:peerId on:NO];
    [YKCenterToast yk_showNotice:[YKCipherLoom yk_unfurl:@"gXSk12fDfGwMlYIIaZYBKg=="] inView:self.view];
    [self yk_reloadCommentRows];
}

- (UIButton *)yk_unlockItemButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button addTarget:self action:@selector(yk_viewItemsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 6.0;
    stack.userInteractionEnabled = NO;
    [button addSubview:stack];

    UILabel *label = [[UILabel alloc] init];
    label.text = [YKCipherLoom yk_unfurl:@"cYq4+GRHZRrXOY87mCU5eA=="];
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    [stack addArrangedSubview:label];

    UIImageView *sparkIcon = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"spark_icon_small"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    sparkIcon.translatesAutoresizingMaskIntoConstraints = NO;
    sparkIcon.contentMode = UIViewContentModeScaleAspectFit;
    [stack addArrangedSubview:sparkIcon];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:button.topAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:button.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:button.trailingAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:button.bottomAnchor],
        [sparkIcon.widthAnchor constraintEqualToConstant:21.0],
        [sparkIcon.heightAnchor constraintEqualToConstant:20.0]
    ]];
    return button;
}

- (BOOL)yk_hasItemsList {
    NSArray *items = self.entry[@"items"];
    return [items isKindOfClass:NSArray.class] && items.count > 0;
}

static NSInteger YKUnlockPieceCost(void) {
    return [YKCipherLoom yk_unfurlInteger:@"Sy9aSiyst5d8ldmq7Ob51w=="];
}

- (void)yk_viewItemsNavTapped:(UIButton *)sender {
    if (![self yk_hasItemsList]) {
        return;
    }
    if ([self yk_isOwnPost] || [self yk_hasUnlockedItems]) {
        [self yk_pushItemsList];
        return;
    }
    [self yk_presentUnlockSpendDialog];
}

- (void)yk_viewItemsButtonTapped:(UIButton *)sender {
    if ([self yk_isOwnPost] || [self yk_hasUnlockedItems]) {
        [self yk_pushItemsList];
        return;
    }
    [self yk_presentUnlockSpendDialog];
}

- (BOOL)yk_hasUnlockedItems {
    return [[YKPieceUnlockLedger sharedLedger] yk_ownerKey:[self yk_ownerKey] hasUnlockedEntry:self.entry];
}

- (void)yk_presentUnlockSpendDialog {
    NSInteger balance = [[YKSparkCoffer sharedCoffer] yk_tallyForOwnerKey:[self yk_ownerKey]];
    self.yk_spendDialogIsAffordable = (balance >= YKUnlockPieceCost());
    NSString *assetName = self.yk_spendDialogIsAffordable ? @"enough" : @"unenough";
    self.yk_spendDialogImageView.image = [[UIImage imageNamed:assetName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    self.spendDialogOverlayView.hidden = NO;
    self.spendDialogOverlayView.alpha = 0.0;
    [self.view bringSubviewToFront:self.spendDialogOverlayView];

    [UIView animateWithDuration:0.18
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.spendDialogOverlayView.alpha = 1.0;
    } completion:nil];
}

- (void)yk_cancelSpendDialog:(UIButton *)sender {
    [UIView animateWithDuration:0.16
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.spendDialogOverlayView.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.spendDialogOverlayView.hidden = YES;
    }];
}

- (void)yk_confirmSpendDialog:(UIButton *)sender {
    if (!self.yk_spendDialogIsAffordable) {
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.16
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
            weakSelf.spendDialogOverlayView.alpha = 0.0;
        } completion:^(BOOL finished) {
            weakSelf.spendDialogOverlayView.hidden = YES;
            YKSparkTopUpViewController *recharge = [[YKSparkTopUpViewController alloc] init];
            [weakSelf.navigationController pushViewController:recharge animated:YES];
        }];
        return;
    }
    BOOL spent = [[YKSparkCoffer sharedCoffer] yk_ownerKey:[self yk_ownerKey] spend:YKUnlockPieceCost()];
    if (!spent) {
        self.yk_spendDialogIsAffordable = NO;
        self.yk_spendDialogImageView.image = [[UIImage imageNamed:@"unenough"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        return;
    }
    [[YKPieceUnlockLedger sharedLedger] yk_ownerKey:[self yk_ownerKey] markUnlockedEntry:self.entry];
    self.spendDialogOverlayView.hidden = YES;
    [self yk_pushItemsList];
}

- (void)yk_pushItemsList {
    NSArray *items = self.entry[@"items"];
    if (![items isKindOfClass:NSArray.class]) {
        items = @[];
    }
    YKFindItemsViewController *itemsViewController = [[YKFindItemsViewController alloc] initWithItems:items];
    [self.navigationController pushViewController:itemsViewController animated:YES];
}

- (NSString *)yk_ownerKey {
    YKRosterVault *vault = [YKRosterVault sharedRoster];
    if ([YKRosterVault yk_isReviewMailbox:vault.yk_activeMailbox ?: @""]) {
        return [YKPersonaCatalog yk_reviewPersonaId];
    }
    return vault.yk_activeMailbox.length > 0 ? vault.yk_activeMailbox : @"guest";
}

- (NSString *)yk_peerPersonaId {
    NSString *personaId = self.entry[@"personaId"];
    return [personaId isKindOfClass:NSString.class] ? personaId : @"";
}

- (BOOL)yk_isOwnPost {
    if ([self.entry[@"isMine"] boolValue]) {
        return YES;
    }
    NSString *peerId = [self yk_peerPersonaId];
    if (peerId.length == 0) {
        return NO;
    }
    if ([peerId isEqualToString:[self yk_ownerKey]]) {
        return YES;
    }
    return [peerId isEqualToString:[self yk_selfAuthorId]];
}

- (void)yk_moreButtonTapped:(UIButton *)sender {
    if ([self yk_isOwnPost]) {
        return;
    }
    [self.view endEditing:YES];
    [self.photoView yk_pausePlayback];
    __weak typeof(self) weakSelf = self;
    [YKReportShadeSheet yk_presentInView:self.view
                                  report:^{
        NSString *peerId = [weakSelf yk_peerPersonaId];
        YKReportViewController *report = [[YKReportViewController alloc] initWithPersonaId:peerId];
        [weakSelf.navigationController pushViewController:report animated:YES];
    }
                                   block:^{
        [weakSelf yk_blockCurrentPublisher];
    }];
}

- (void)yk_blockCurrentPublisher {
    NSString *peerId = [self yk_peerPersonaId];
    NSString *owner = [self yk_ownerKey];
    if (peerId.length == 0 || [peerId isEqualToString:owner] || [self yk_isOwnPost]) {
        return;
    }
    [[YKShadeRoster sharedRoster] yk_ownerKey:owner shadeId:peerId];
    [[YKBondLedger sharedLedger] yk_ownerKey:owner setLink:peerId on:NO];
    [YKCenterToast yk_showNotice:[YKCipherLoom yk_unfurl:@"gXSk12fDfGwMlYIIaZYBKg=="] inView:self.view];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

- (void)yk_avatarButtonTapped:(UIButton *)sender {
    if ([self yk_isOwnPost]) {
        return;
    }
    NSString *personaId = self.entry[@"personaId"];
    YKFindPersonaBoardViewController *profileViewController = nil;
    if ([personaId isKindOfClass:NSString.class] && personaId.length > 0) {
        profileViewController = [[YKFindPersonaBoardViewController alloc] initWithPersonaId:personaId];
    } else {
        profileViewController = [[YKFindPersonaBoardViewController alloc] initWithDisplayAlias:self.displayAlias];
    }
    [self.navigationController pushViewController:profileViewController animated:YES];
}

@end
