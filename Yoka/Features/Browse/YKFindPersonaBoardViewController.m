//
//  YKFindPersonaBoardViewController.m
//  Yoka
//

#import "YKFindPersonaBoardViewController.h"
#import "YKFindDetailViewController.h"
#import "YKOutfitFeedCatalog.h"
#import "YKPublishLedger.h"
#import "YKRosterVault.h"
#import "YKBondLedger.h"
#import "YKPersonaCatalog.h"
#import "YKThreadViewController.h"
#import "YKInboxViewController.h"
#import "YKReportShadeSheet.h"
#import "YKReportViewController.h"
#import "YKShadeRoster.h"
#import "YKCenterToast.h"
#import "YKEmptyStateView.h"
#import <AVFoundation/AVFoundation.h>
#import "YKCipherLoom.h"

#pragma mark - Entry card (Mine-style)

@interface YKFindPersonaBoardCell : UICollectionViewCell
@property (nonatomic, copy, nullable) void (^yk_moreTapHandler)(void);
- (void)configureWithEntry:(NSDictionary *)entry
              displayName:(NSString *)displayName
                   avatar:(UIImage *)avatar;
@end

@interface YKFindPersonaBoardCell ()
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *subNameLabel;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIView *photoView;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIImageView *playImageView;
@property (nonatomic, copy) NSString *yk_coverToken;
@end

@implementation YKFindPersonaBoardCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = UIColor.whiteColor;
        self.contentView.layer.cornerRadius = 14.0;
        self.contentView.layer.masksToBounds = YES;

        UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
        avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
        avatarImageView.layer.cornerRadius = 18.0;
        avatarImageView.layer.masksToBounds = YES;
        [self.contentView addSubview:avatarImageView];
        self.avatarImageView = avatarImageView;

        UILabel *nameLabel = [[UILabel alloc] init];
        nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        nameLabel.textColor = UIColor.blackColor;
        nameLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
        [self.contentView addSubview:nameLabel];
        self.nameLabel = nameLabel;

        UILabel *subNameLabel = [[UILabel alloc] init];
        subNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        subNameLabel.textColor = [UIColor colorWithWhite:0.35 alpha:1.0];
        subNameLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
        [self.contentView addSubview:subNameLabel];
        self.subNameLabel = subNameLabel;

        UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        moreButton.translatesAutoresizingMaskIntoConstraints = NO;
        [moreButton setImage:[[UIImage imageNamed:@"detail_more_button"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        [moreButton addTarget:self action:@selector(yk_cardMoreTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:moreButton];
        self.moreButton = moreButton;

        UIView *photoView = [[UIView alloc] init];
        photoView.translatesAutoresizingMaskIntoConstraints = NO;
        photoView.layer.cornerRadius = 10.0;
        photoView.layer.masksToBounds = YES;
        photoView.backgroundColor = [UIColor colorWithRed:0.12 green:0.11 blue:0.18 alpha:1.0];
        [self.contentView addSubview:photoView];
        self.photoView = photoView;

        UIImageView *coverImageView = [[UIImageView alloc] init];
        coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
        coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        coverImageView.clipsToBounds = YES;
        [photoView addSubview:coverImageView];
        self.coverImageView = coverImageView;

        UIImageView *playImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"mine_play_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        playImageView.translatesAutoresizingMaskIntoConstraints = NO;
        playImageView.contentMode = UIViewContentModeScaleAspectFit;
        playImageView.hidden = YES;
        [photoView addSubview:playImageView];
        self.playImageView = playImageView;

        [NSLayoutConstraint activateConstraints:@[
            [avatarImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:14.0],
            [avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:18.0],
            [avatarImageView.widthAnchor constraintEqualToConstant:36.0],
            [avatarImageView.heightAnchor constraintEqualToConstant:36.0],

            [nameLabel.topAnchor constraintEqualToAnchor:avatarImageView.topAnchor constant:2.0],
            [nameLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:10.0],

            [subNameLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:1.0],
            [subNameLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],

            [moreButton.centerYAnchor constraintEqualToAnchor:avatarImageView.centerYAnchor],
            [moreButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0],
            [moreButton.widthAnchor constraintEqualToConstant:28.0],
            [moreButton.heightAnchor constraintEqualToConstant:28.0],

            [photoView.topAnchor constraintEqualToAnchor:avatarImageView.bottomAnchor constant:16.0],
            [photoView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:18.0],
            [photoView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-18.0],
            [photoView.heightAnchor constraintEqualToAnchor:photoView.widthAnchor multiplier:0.83],
            [photoView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-14.0],

            [coverImageView.topAnchor constraintEqualToAnchor:photoView.topAnchor],
            [coverImageView.leadingAnchor constraintEqualToAnchor:photoView.leadingAnchor],
            [coverImageView.trailingAnchor constraintEqualToAnchor:photoView.trailingAnchor],
            [coverImageView.bottomAnchor constraintEqualToAnchor:photoView.bottomAnchor],

            [playImageView.centerXAnchor constraintEqualToAnchor:photoView.centerXAnchor],
            [playImageView.centerYAnchor constraintEqualToAnchor:photoView.centerYAnchor],
            [playImageView.widthAnchor constraintEqualToConstant:24.0],
            [playImageView.heightAnchor constraintEqualToConstant:24.0]
        ]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.yk_coverToken = nil;
    self.coverImageView.image = nil;
    self.playImageView.hidden = YES;
    self.yk_moreTapHandler = nil;
}

- (void)yk_cardMoreTapped:(UIButton *)sender {
    if (self.yk_moreTapHandler) {
        self.yk_moreTapHandler();
    }
}

- (void)configureWithEntry:(NSDictionary *)entry
              displayName:(NSString *)displayName
                   avatar:(UIImage *)avatar {
    NSString *name = displayName.length > 0 ? displayName : (entry[@"name"] ?: @"Yoka");
    self.nameLabel.text = name;
    self.subNameLabel.text = name;
    self.avatarImageView.image = [(avatar ?: [UIImage imageNamed:@"headplace"]) imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    NSString *videoName = [entry[@"video"] isKindOfClass:NSString.class] ? entry[@"video"] : @"";
    NSString *imageName = [entry[@"image"] isKindOfClass:NSString.class] ? entry[@"image"] : @"";
    BOOL isPublishedVideo = [entry[@"isVideo"] boolValue] || ([YKPublishLedger yk_videoURLForEntry:entry] != nil);
    self.playImageView.hidden = (videoName.length == 0 && !isPublishedVideo);
    self.coverImageView.image = nil;

    if (imageName.length > 0 && videoName.length == 0) {
        self.yk_coverToken = imageName;
        self.coverImageView.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        return;
    }
    UIImage *fileCover = [YKPublishLedger yk_coverImageForEntry:entry];
    if (fileCover) {
        self.yk_coverToken = entry[@"imageFile"] ?: entry[@"imagePath"] ?: @"file";
        self.coverImageView.image = [fileCover imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        if (videoName.length == 0) {
            return;
        }
    }
    if (videoName.length == 0) {
        self.yk_coverToken = nil;
        return;
    }

    self.yk_coverToken = videoName;
    NSURL *url = [[NSBundle mainBundle] URLForResource:videoName withExtension:@"mp4"];
    if (!url) {
        return;
    }
    NSString *token = videoName;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        AVAsset *asset = [AVAsset assetWithURL:url];
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
        generator.maximumSize = CGSizeMake(600.0, 900.0);
        NSError *error = nil;
        CGImageRef cgImage = [generator copyCGImageAtTime:CMTimeMake(1, 2) actualTime:NULL error:&error];
        if (!cgImage) {
            return;
        }
        UIImage *thumb = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self.yk_coverToken isEqualToString:token]) {
                return;
            }
            self.coverImageView.image = thumb;
        });
    });
}

@end

#pragma mark - Segment

@interface YKPersonaBoardSegmentButton : UIControl
@property (nonatomic, copy, readonly) NSString *title;
- (instancetype)initWithTitle:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (void)setSelectionProgress:(CGFloat)progress;
@end

@interface YKPersonaBoardSegmentButton ()
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UILabel *label;
@end

@implementation YKPersonaBoardSegmentButton

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _title = [title copy];
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.text = title;
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];
        self.label = label;
        [NSLayoutConstraint activateConstraints:@[
            [label.topAnchor constraintEqualToAnchor:self.topAnchor],
            [label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
        [self setSelectionProgress:0.0];
    }
    return self;
}

- (void)setSelectionProgress:(CGFloat)progress {
    CGFloat boundedProgress = MIN(MAX(progress, 0.0), 1.0);
    CGFloat fontSize = 20.0 + 4.0 * boundedProgress;
    CGFloat alpha = 0.44 + 0.56 * boundedProgress;
    self.label.font = [UIFont systemFontOfSize:fontSize weight:boundedProgress > 0.5 ? UIFontWeightBold : UIFontWeightRegular];
    self.label.textColor = [UIColor colorWithWhite:1.0 alpha:alpha];
}

@end

#pragma mark - Board

@interface YKFindPersonaBoardViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>
@property (nonatomic, copy) NSString *displayAlias;
@property (nonatomic, copy) NSString *personaId;
@property (nonatomic, strong) UIButton *yk_linkButton;
@property (nonatomic, strong) UIView *yk_twinHintOverlay;
@property (nonatomic, strong) NSLayoutConstraint *yk_twinHintWidth;
@property (nonatomic, strong) NSLayoutConstraint *yk_twinHintHeight;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualCancelLeading;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualCancelBottom;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualCancelWidth;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualCancelHeight;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualSureTrailing;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualSureBottom;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualSureWidth;
@property (nonatomic, strong) NSLayoutConstraint *yk_mutualSureHeight;

@property (nonatomic, strong) NSArray<NSString *> *segmentTitles;
@property (nonatomic, strong) NSMutableArray<YKPersonaBoardSegmentButton *> *segmentButtons;
@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) NSLayoutConstraint *indicatorLeadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *indicatorWidthConstraint;
@property (nonatomic, strong) UIScrollView *pageScrollView;
@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, strong) UICollectionView *entriesCollectionView;
@property (nonatomic, strong) UICollectionView *collectionsCollectionView;
@property (nonatomic, strong) YKEmptyStateView *yk_entriesEmptyView;
@property (nonatomic, strong) YKEmptyStateView *yk_collectionsEmptyView;
@property (nonatomic, strong) NSLayoutConstraint *pagerHeightConstraint;
@property (nonatomic, copy) NSArray<NSDictionary *> *yk_entries;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) NSInteger yk_inboundBaseCount;
@property (nonatomic, assign) NSInteger yk_outboundCount;
@property (nonatomic, strong) UILabel *yk_inboundValueLabel;
@end

@implementation YKFindPersonaBoardViewController

- (instancetype)initWithDisplayAlias:(NSString *)userName {
    self = [super init];
    if (self) {
        _displayAlias = userName.length > 0 ? [userName copy] : @"Freya";
        _personaId = [self yk_resolvePersonaIdForName:_displayAlias] ?: @"";
        [self yk_prepareDisplayStats];
    }
    return self;
}

- (instancetype)initWithPersonaId:(NSString *)personaId {
    NSDictionary *persona = [YKPersonaCatalog yk_personaWithId:personaId];
    self = [super init];
    if (self) {
        _personaId = [personaId copy] ?: @"";
        _displayAlias = persona[@"name"] ?: @"Yoka";
        [self yk_prepareDisplayStats];
    }
    return self;
}

- (void)yk_prepareDisplayStats {
    NSUInteger mixTag = (self.personaId.length > 0 ? self.personaId : self.displayAlias).hash;
    self.yk_inboundBaseCount = (NSInteger)(mixTag % 9) + 1;
    self.yk_outboundCount = (NSInteger)((mixTag / 9) % 9) + 1;
    self.yk_entries = [YKOutfitFeedCatalog yk_postsForPersonaId:self.personaId] ?: @[];
}

- (nullable NSString *)yk_resolvePersonaIdForName:(NSString *)name {
    for (NSDictionary *persona in [YKPersonaCatalog yk_allPersonas]) {
        if ([persona[@"name"] isEqualToString:name]) {
            return persona[@"id"];
        }
    }
    return nil;
}

- (NSString *)yk_ownerKey {
    YKRosterVault *vault = [YKRosterVault sharedRoster];
    if ([YKRosterVault yk_isReviewMailbox:vault.yk_activeMailbox ?: @""]) {
        return [YKPersonaCatalog yk_reviewPersonaId];
    }
    return vault.yk_activeMailbox.length > 0 ? vault.yk_activeMailbox : @"guest";
}

- (void)yk_configurePage {
    [super yk_configurePage];
    self.segmentTitles = @[[YKCipherLoom yk_unfurl:@"BJOCwYUjx2NBenty6NZ6Xw=="], @"Collections"];
    self.segmentButtons = [NSMutableArray arrayWithCapacity:self.segmentTitles.count];
    self.selectedIndex = 0;
    [self yk_setupViews];
    [self yk_setupMutualTipOverlay];
    [self yk_refreshLinkButton];
    [self yk_updateSelectionWithProgress:0.0];
    [self yk_updateEmptyStates];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.yk_twinHintOverlay) {
        [self yk_updateMutualTipHitRects];
    }
    [self yk_updatePagerHeightIfNeeded];
    if (!self.contentScrollView.isDragging && !self.contentScrollView.isDecelerating) {
        [self yk_updateSelectionWithProgress:self.selectedIndex];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self yk_refreshLinkButton];
}

- (void)yk_setupViews {
    UIButton *backButton = [self yk_addBackButton];

    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [moreButton setImage:[[UIImage imageNamed:@"detail_more_button"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [moreButton addTarget:self action:@selector(yk_moreTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:moreButton];

    UIScrollView *pageScrollView = [[UIScrollView alloc] init];
    pageScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    pageScrollView.showsVerticalScrollIndicator = NO;
    pageScrollView.alwaysBounceVertical = YES;
    pageScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:pageScrollView];
    self.pageScrollView = pageScrollView;

    UIView *pageContentView = [[UIView alloc] init];
    pageContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [pageScrollView addSubview:pageContentView];

    UIImage *avatarImage = [YKPersonaCatalog yk_avatarImageForPersonaId:self.personaId] ?: [UIImage imageNamed:@"headplace"];
    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[avatarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    avatarImageView.layer.cornerRadius = 50.0;
    avatarImageView.layer.masksToBounds = YES;
    [pageContentView addSubview:avatarImageView];

    UILabel *inboundValueLabel = [self yk_countLabelWithText:@"0"];
    UILabel *inboundTitleLabel = [self yk_captionLabelWithText:[YKCipherLoom yk_unfurl:@"zp3IYTxq3Gjb3hnCBF06xA=="]];
    UILabel *outboundValueLabel = [self yk_countLabelWithText:[NSString stringWithFormat:@"%ld", (long)self.yk_outboundCount]];
    UILabel *outboundTitleLabel = [self yk_captionLabelWithText:[YKCipherLoom yk_unfurl:@"mQ3A5aWGAwIw5fwUx6iQZw=="]];
    [pageContentView addSubview:inboundValueLabel];
    [pageContentView addSubview:inboundTitleLabel];
    [pageContentView addSubview:outboundValueLabel];
    [pageContentView addSubview:outboundTitleLabel];
    self.yk_inboundValueLabel = inboundValueLabel;

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = self.displayAlias;
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:27.0 weight:UIFontWeightBold];
    [pageContentView addSubview:nameLabel];

    UIButton *linkBtn = [self yk_outlineButtonWithTitle:[YKCipherLoom yk_unfurl:@"XloucoaA2i7z2gsuWyglLg=="]];
    [linkBtn addTarget:self action:@selector(yk_linkTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.yk_linkButton = linkBtn;

    UIButton *chatButton = [self yk_filledButtonWithTitle:[YKCipherLoom yk_unfurl:@"LxxYycmiK3MNJKtiotJzPg=="]];
    [chatButton addTarget:self action:@selector(yk_threadTapped:) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *actionStack = [[UIStackView alloc] initWithArrangedSubviews:@[linkBtn, chatButton]];
    actionStack.translatesAutoresizingMaskIntoConstraints = NO;
    actionStack.axis = UILayoutConstraintAxisHorizontal;
    actionStack.alignment = UIStackViewAlignmentCenter;
    actionStack.spacing = 12.0;
    [pageContentView addSubview:actionStack];

    UIView *segmentContainer = [[UIView alloc] init];
    segmentContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [pageContentView addSubview:segmentContainer];

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.distribution = UIStackViewDistributionFillEqually;
    [segmentContainer addSubview:stackView];

    for (NSInteger index = 0; index < self.segmentTitles.count; index++) {
        YKPersonaBoardSegmentButton *button = [[YKPersonaBoardSegmentButton alloc] initWithTitle:self.segmentTitles[index]];
        button.tag = index;
        [button addTarget:self action:@selector(yk_segmentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [stackView addArrangedSubview:button];
        [self.segmentButtons addObject:button];
    }

    UIView *indicatorView = [[UIView alloc] init];
    indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    indicatorView.backgroundColor = UIColor.whiteColor;
    indicatorView.layer.cornerRadius = 2.0;
    indicatorView.layer.masksToBounds = YES;
    [segmentContainer addSubview:indicatorView];
    self.indicatorView = indicatorView;
    self.indicatorLeadingConstraint = [indicatorView.leadingAnchor constraintEqualToAnchor:segmentContainer.leadingAnchor constant:0.0];
    self.indicatorWidthConstraint = [indicatorView.widthAnchor constraintEqualToConstant:170.0];

    UIScrollView *pagerScrollView = [[UIScrollView alloc] init];
    pagerScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    pagerScrollView.pagingEnabled = YES;
    pagerScrollView.showsHorizontalScrollIndicator = NO;
    pagerScrollView.showsVerticalScrollIndicator = NO;
    pagerScrollView.delegate = self;
    pagerScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [pageContentView addSubview:pagerScrollView];
    self.contentScrollView = pagerScrollView;

    UIView *pagerContentView = [[UIView alloc] init];
    pagerContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [pagerScrollView addSubview:pagerContentView];

    UICollectionView *entriesCollectionView = [self yk_collectionViewWithTag:0];
    UICollectionView *collectionsCollectionView = [self yk_collectionViewWithTag:1];
    [pagerContentView addSubview:entriesCollectionView];
    [pagerContentView addSubview:collectionsCollectionView];
    self.entriesCollectionView = entriesCollectionView;
    self.collectionsCollectionView = collectionsCollectionView;

    YKEmptyStateView *postsEmpty = [[YKEmptyStateView alloc] init];
    YKEmptyStateView *collectionsEmpty = [[YKEmptyStateView alloc] init];
    [pagerContentView addSubview:postsEmpty];
    [pagerContentView addSubview:collectionsEmpty];
    self.yk_entriesEmptyView = postsEmpty;
    self.yk_collectionsEmptyView = collectionsEmpty;

    self.pagerHeightConstraint = [pagerScrollView.heightAnchor constraintEqualToConstant:400.0];

    [NSLayoutConstraint activateConstraints:@[
        [moreButton.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],
        [moreButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-22.0],
        [moreButton.widthAnchor constraintEqualToConstant:36.0],
        [moreButton.heightAnchor constraintEqualToConstant:36.0],

        [pageScrollView.topAnchor constraintEqualToAnchor:backButton.bottomAnchor constant:8.0],
        [pageScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [pageScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [pageScrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [pageContentView.topAnchor constraintEqualToAnchor:pageScrollView.contentLayoutGuide.topAnchor],
        [pageContentView.leadingAnchor constraintEqualToAnchor:pageScrollView.contentLayoutGuide.leadingAnchor],
        [pageContentView.trailingAnchor constraintEqualToAnchor:pageScrollView.contentLayoutGuide.trailingAnchor],
        [pageContentView.bottomAnchor constraintEqualToAnchor:pageScrollView.contentLayoutGuide.bottomAnchor],
        [pageContentView.widthAnchor constraintEqualToAnchor:pageScrollView.frameLayoutGuide.widthAnchor],

        [avatarImageView.topAnchor constraintEqualToAnchor:pageContentView.topAnchor constant:8.0],
        [avatarImageView.leadingAnchor constraintEqualToAnchor:pageContentView.leadingAnchor constant:26.0],
        [avatarImageView.widthAnchor constraintEqualToConstant:100.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:100.0],

        [inboundValueLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:30.0],
        [inboundValueLabel.topAnchor constraintEqualToAnchor:avatarImageView.topAnchor constant:26.0],
        [inboundTitleLabel.leadingAnchor constraintEqualToAnchor:inboundValueLabel.leadingAnchor],
        [inboundTitleLabel.topAnchor constraintEqualToAnchor:inboundValueLabel.bottomAnchor constant:3.0],

        [outboundValueLabel.leadingAnchor constraintEqualToAnchor:inboundValueLabel.trailingAnchor constant:68.0],
        [outboundValueLabel.centerYAnchor constraintEqualToAnchor:inboundValueLabel.centerYAnchor],
        [outboundTitleLabel.leadingAnchor constraintEqualToAnchor:outboundValueLabel.leadingAnchor],
        [outboundTitleLabel.topAnchor constraintEqualToAnchor:outboundValueLabel.bottomAnchor constant:3.0],

        [nameLabel.topAnchor constraintEqualToAnchor:avatarImageView.bottomAnchor constant:12.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:pageContentView.leadingAnchor constant:38.0],
        [nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:actionStack.leadingAnchor constant:-12.0],

        [actionStack.centerYAnchor constraintEqualToAnchor:nameLabel.centerYAnchor],
        [actionStack.trailingAnchor constraintEqualToAnchor:pageContentView.trailingAnchor constant:-26.0],
        [linkBtn.widthAnchor constraintEqualToConstant:80.0],
        [linkBtn.heightAnchor constraintEqualToConstant:28.0],
        [chatButton.widthAnchor constraintEqualToConstant:70.0],
        [chatButton.heightAnchor constraintEqualToConstant:28.0],

        [segmentContainer.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:22.0],
        [segmentContainer.leadingAnchor constraintEqualToAnchor:pageContentView.leadingAnchor constant:28.0],
        [segmentContainer.trailingAnchor constraintEqualToAnchor:pageContentView.trailingAnchor constant:-28.0],
        [segmentContainer.heightAnchor constraintEqualToConstant:58.0],

        [stackView.topAnchor constraintEqualToAnchor:segmentContainer.topAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:segmentContainer.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:segmentContainer.trailingAnchor],
        [stackView.heightAnchor constraintEqualToConstant:40.0],

        self.indicatorLeadingConstraint,
        [indicatorView.topAnchor constraintEqualToAnchor:stackView.bottomAnchor constant:4.0],
        self.indicatorWidthConstraint,
        [indicatorView.heightAnchor constraintEqualToConstant:4.0],

        [pagerScrollView.topAnchor constraintEqualToAnchor:segmentContainer.bottomAnchor constant:2.0],
        [pagerScrollView.leadingAnchor constraintEqualToAnchor:pageContentView.leadingAnchor],
        [pagerScrollView.trailingAnchor constraintEqualToAnchor:pageContentView.trailingAnchor],
        [pagerScrollView.bottomAnchor constraintEqualToAnchor:pageContentView.bottomAnchor],
        self.pagerHeightConstraint,

        [pagerContentView.topAnchor constraintEqualToAnchor:pagerScrollView.contentLayoutGuide.topAnchor],
        [pagerContentView.leadingAnchor constraintEqualToAnchor:pagerScrollView.contentLayoutGuide.leadingAnchor],
        [pagerContentView.trailingAnchor constraintEqualToAnchor:pagerScrollView.contentLayoutGuide.trailingAnchor],
        [pagerContentView.bottomAnchor constraintEqualToAnchor:pagerScrollView.contentLayoutGuide.bottomAnchor],
        [pagerContentView.heightAnchor constraintEqualToAnchor:pagerScrollView.frameLayoutGuide.heightAnchor],

        [entriesCollectionView.topAnchor constraintEqualToAnchor:pagerContentView.topAnchor],
        [entriesCollectionView.leadingAnchor constraintEqualToAnchor:pagerContentView.leadingAnchor],
        [entriesCollectionView.bottomAnchor constraintEqualToAnchor:pagerContentView.bottomAnchor],
        [entriesCollectionView.widthAnchor constraintEqualToAnchor:pagerScrollView.frameLayoutGuide.widthAnchor],

        [collectionsCollectionView.topAnchor constraintEqualToAnchor:pagerContentView.topAnchor],
        [collectionsCollectionView.leadingAnchor constraintEqualToAnchor:entriesCollectionView.trailingAnchor],
        [collectionsCollectionView.bottomAnchor constraintEqualToAnchor:pagerContentView.bottomAnchor],
        [collectionsCollectionView.widthAnchor constraintEqualToAnchor:pagerScrollView.frameLayoutGuide.widthAnchor],
        [collectionsCollectionView.trailingAnchor constraintEqualToAnchor:pagerContentView.trailingAnchor],

        [postsEmpty.centerXAnchor constraintEqualToAnchor:entriesCollectionView.centerXAnchor],
        [postsEmpty.topAnchor constraintEqualToAnchor:entriesCollectionView.topAnchor constant:40.0],
        [postsEmpty.widthAnchor constraintEqualToConstant:200.0],
        [collectionsEmpty.centerXAnchor constraintEqualToAnchor:collectionsCollectionView.centerXAnchor],
        [collectionsEmpty.topAnchor constraintEqualToAnchor:collectionsCollectionView.topAnchor constant:40.0],
        [collectionsEmpty.widthAnchor constraintEqualToConstant:200.0]
    ]];
}

- (UICollectionView *)yk_collectionViewWithTag:(NSInteger)tag {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumLineSpacing = 18.0;
    layout.minimumInteritemSpacing = 14.0;

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.scrollEnabled = NO;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.tag = tag;
    collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [collectionView registerClass:YKFindPersonaBoardCell.class forCellWithReuseIdentifier:@"YKFindPersonaBoardCell"];
    return collectionView;
}

- (UIButton *)yk_outlineButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = [UIColor colorWithRed:0.62 green:0.22 blue:0.88 alpha:0.55];
    button.layer.cornerRadius = 14.0;
    button.layer.borderColor = UIColor.whiteColor.CGColor;
    button.layer.borderWidth = 1.2;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightBold];
    return button;
}

- (UIButton *)yk_filledButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = UIColor.whiteColor;
    button.layer.cornerRadius = 14.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [UIColor colorWithRed:0xDD / 255.0 green:0x63 / 255.0 blue:0xFF / 255.0 alpha:1.0].CGColor;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRed:0.76 green:0.27 blue:0.92 alpha:1.0] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightBold];
    return button;
}

- (UILabel *)yk_countLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:19.0 weight:UIFontWeightBold];
    return label;
}

- (UILabel *)yk_captionLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = [UIColor colorWithWhite:1.0 alpha:0.78];
    label.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightRegular];
    return label;
}

- (void)yk_refreshInboundCount {
    BOOL linked = (self.personaId.length > 0) &&
        [[YKBondLedger sharedLedger] yk_ownerKey:[self yk_ownerKey] isLinkedTo:self.personaId];
    NSInteger shown = self.yk_inboundBaseCount + (linked ? 1 : 0);
    self.yk_inboundValueLabel.text = [NSString stringWithFormat:@"%ld", (long)shown];
}

- (void)yk_refreshLinkButton {
    if (self.personaId.length == 0) {
        [self yk_refreshInboundCount];
        return;
    }
    BOOL linked = [[YKBondLedger sharedLedger] yk_ownerKey:[self yk_ownerKey] isLinkedTo:self.personaId];
    if (linked) {
        [self.yk_linkButton setTitle:[YKCipherLoom yk_unfurl:@"TS+hCnu1QPAtWym+i+DnWQ=="] forState:UIControlStateNormal];
        self.yk_linkButton.backgroundColor = UIColor.whiteColor;
        [self.yk_linkButton setTitleColor:[UIColor colorWithRed:0.75 green:0.20 blue:0.90 alpha:1.0] forState:UIControlStateNormal];
        self.yk_linkButton.layer.borderColor = UIColor.whiteColor.CGColor;
    } else {
        [self.yk_linkButton setTitle:[YKCipherLoom yk_unfurl:@"XloucoaA2i7z2gsuWyglLg=="] forState:UIControlStateNormal];
        self.yk_linkButton.backgroundColor = [UIColor colorWithRed:0.62 green:0.22 blue:0.88 alpha:0.55];
        [self.yk_linkButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        self.yk_linkButton.layer.borderColor = UIColor.whiteColor.CGColor;
    }
    [self yk_refreshInboundCount];
}

- (void)yk_linkTapped:(UIButton *)sender {
    if (self.personaId.length == 0) {
        return;
    }
    NSString *owner = [self yk_ownerKey];
    YKBondLedger *ledger = [YKBondLedger sharedLedger];
    BOOL linked = [ledger yk_ownerKey:owner isLinkedTo:self.personaId];
    [ledger yk_ownerKey:owner setLink:self.personaId on:!linked];
    [self yk_refreshLinkButton];
}

- (void)yk_threadTapped:(UIButton *)sender {
    if (self.personaId.length == 0) {
        return;
    }
    NSString *owner = [self yk_ownerKey];
    if ([[YKShadeRoster sharedRoster] yk_ownerKey:owner hasShadedId:self.personaId]) {
        [YKCenterToast yk_showNotice:[YKCipherLoom yk_unfurl:@"gXSk12fDfGwMlYIIaZYBKg=="] inView:self.view];
        return;
    }
    if (![[YKBondLedger sharedLedger] yk_ownerKey:owner isTwinWith:self.personaId]) {
        [self yk_presentTwinHint];
        return;
    }
    YKThreadViewController *chat = [[YKThreadViewController alloc] initWithPersonaId:self.personaId];
    [self.navigationController pushViewController:chat animated:YES];
}

- (void)yk_moreTapped:(UIButton *)sender {
    __weak typeof(self) weakSelf = self;
    [YKReportShadeSheet yk_presentInView:self.view
                                  report:^{
        YKReportViewController *report = [[YKReportViewController alloc] initWithPersonaId:weakSelf.personaId];
        [weakSelf.navigationController pushViewController:report animated:YES];
    }
                                   block:^{
        [weakSelf yk_blockCurrentPeer];
    }];
}

- (void)yk_blockCurrentPeer {
    NSString *owner = [self yk_ownerKey];
    if (self.personaId.length == 0 || [self.personaId isEqualToString:owner]) {
        return;
    }
    [[YKShadeRoster sharedRoster] yk_ownerKey:owner shadeId:self.personaId];
    [[YKBondLedger sharedLedger] yk_ownerKey:owner setLink:self.personaId on:NO];
    [YKCenterToast yk_showNotice:[YKCipherLoom yk_unfurl:@"gXSk12fDfGwMlYIIaZYBKg=="] inView:self.view];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self yk_popAfterBlock];
    });
}

- (void)yk_popAfterBlock {
    UINavigationController *nav = self.navigationController;
    if (!nav) {
        return;
    }
    UIViewController *inbox = nil;
    for (UIViewController *vc in nav.viewControllers) {
        if ([vc isKindOfClass:YKInboxViewController.class]) {
            inbox = vc;
            break;
        }
    }
    if (inbox) {
        [nav popToViewController:inbox animated:YES];
    } else {
        [nav popViewControllerAnimated:YES];
    }
}

#pragma mark - Twin hint

- (void)yk_setupMutualTipOverlay {
    UIView *overlay = [[UIView alloc] init];
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    overlay.hidden = YES;
    overlay.alpha = 0.0;
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.55];
    [self.view addSubview:overlay];
    self.yk_twinHintOverlay = overlay;

    UIImageView *dialog = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"mutual_link_tip"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    dialog.translatesAutoresizingMaskIntoConstraints = NO;
    dialog.contentMode = UIViewContentModeScaleAspectFit;
    dialog.userInteractionEnabled = YES;
    [overlay addSubview:dialog];

    UIButton *cancelHit = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelHit.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelHit addTarget:self action:@selector(yk_dismissTwinHint) forControlEvents:UIControlEventTouchUpInside];
    [dialog addSubview:cancelHit];

    UIButton *sureHit = [UIButton buttonWithType:UIButtonTypeCustom];
    sureHit.translatesAutoresizingMaskIntoConstraints = NO;
    [sureHit addTarget:self action:@selector(yk_dismissTwinHint) forControlEvents:UIControlEventTouchUpInside];
    [dialog addSubview:sureHit];

    self.yk_twinHintWidth = [dialog.widthAnchor constraintEqualToConstant:309.0];
    self.yk_twinHintHeight = [dialog.heightAnchor constraintEqualToConstant:241.0];
    self.yk_mutualCancelLeading = [cancelHit.leadingAnchor constraintEqualToAnchor:dialog.leadingAnchor constant:50.0];
    self.yk_mutualCancelBottom = [cancelHit.bottomAnchor constraintEqualToAnchor:dialog.bottomAnchor constant:-33.0];
    self.yk_mutualCancelWidth = [cancelHit.widthAnchor constraintEqualToConstant:100.0];
    self.yk_mutualCancelHeight = [cancelHit.heightAnchor constraintEqualToConstant:32.0];
    self.yk_mutualSureTrailing = [sureHit.trailingAnchor constraintEqualToAnchor:dialog.trailingAnchor constant:-36.0];
    self.yk_mutualSureBottom = [sureHit.bottomAnchor constraintEqualToAnchor:dialog.bottomAnchor constant:-33.0];
    self.yk_mutualSureWidth = [sureHit.widthAnchor constraintEqualToConstant:100.0];
    self.yk_mutualSureHeight = [sureHit.heightAnchor constraintEqualToConstant:32.0];

    [NSLayoutConstraint activateConstraints:@[
        [overlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [overlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [dialog.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [dialog.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor constant:-6.0],
        self.yk_twinHintWidth,
        self.yk_twinHintHeight,
        self.yk_mutualCancelLeading,
        self.yk_mutualCancelBottom,
        self.yk_mutualCancelWidth,
        self.yk_mutualCancelHeight,
        self.yk_mutualSureTrailing,
        self.yk_mutualSureBottom,
        self.yk_mutualSureWidth,
        self.yk_mutualSureHeight
    ]];
}

- (void)yk_updateMutualTipHitRects {
    CGFloat screenW = CGRectGetWidth(self.view.bounds);
    if (screenW <= 1.0) {
        return;
    }
    CGFloat dialogW = MIN(309.0, screenW - 48.0);
    CGFloat scale = dialogW / 309.0;
    self.yk_twinHintWidth.constant = dialogW;
    self.yk_twinHintHeight.constant = 241.0 * scale;
    self.yk_mutualCancelLeading.constant = 50.0 * scale;
    self.yk_mutualCancelBottom.constant = -33.0 * scale;
    self.yk_mutualCancelWidth.constant = 100.0 * scale;
    self.yk_mutualCancelHeight.constant = 32.0 * scale;
    self.yk_mutualSureTrailing.constant = -36.0 * scale;
    self.yk_mutualSureBottom.constant = -33.0 * scale;
    self.yk_mutualSureWidth.constant = 100.0 * scale;
    self.yk_mutualSureHeight.constant = 32.0 * scale;
}

- (void)yk_presentTwinHint {
    [self yk_updateMutualTipHitRects];
    self.yk_twinHintOverlay.hidden = NO;
    [self.view bringSubviewToFront:self.yk_twinHintOverlay];
    [UIView animateWithDuration:0.2 animations:^{
        self.yk_twinHintOverlay.alpha = 1.0;
    }];
}

- (void)yk_dismissTwinHint {
    [UIView animateWithDuration:0.18 animations:^{
        self.yk_twinHintOverlay.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.yk_twinHintOverlay.hidden = YES;
    }];
}

#pragma mark - Tabs / pager

- (CGFloat)yk_emptyPagerHeight {
    CGFloat viewport = CGRectGetHeight(self.pageScrollView.bounds);
    if (viewport <= 1.0) {
        return 280.0;
    }
    CGFloat pagerTop = CGRectGetMinY(self.contentScrollView.frame);
    if (pagerTop < 40.0) {
        pagerTop = 220.0;
    }
    return MAX(viewport - pagerTop, 220.0);
}

- (CGFloat)yk_postItemHeightForWidth:(CGFloat)itemWidth {
    CGFloat photoWidth = MAX(itemWidth - 36.0, 1.0);
    CGFloat photoHeight = floor(photoWidth * 0.83);
    return 14.0 + 36.0 + 16.0 + photoHeight + 14.0;
}

- (void)yk_updatePagerHeightIfNeeded {
    CGFloat width = CGRectGetWidth(self.entriesCollectionView.bounds);
    if (width <= 1.0) {
        width = CGRectGetWidth(self.view.bounds);
    }
    CGFloat emptyH = [self yk_emptyPagerHeight];
    CGFloat postsH = emptyH;
    if (self.yk_entries.count > 0) {
        CGFloat itemWidth = width - 52.0;
        CGFloat itemH = [self yk_postItemHeightForWidth:itemWidth];
        postsH = self.yk_entries.count * itemH + MAX(0, (NSInteger)self.yk_entries.count - 1) * 18.0 + 18.0;
        postsH = MAX(postsH, emptyH);
    }
    CGFloat collectionsH = emptyH;
    CGFloat target = (self.selectedIndex == 0) ? postsH : collectionsH;
    if (fabs(self.pagerHeightConstraint.constant - target) > 0.5) {
        self.pagerHeightConstraint.constant = target;
        [self.view layoutIfNeeded];
    }
}

- (void)yk_segmentButtonTapped:(YKPersonaBoardSegmentButton *)sender {
    self.selectedIndex = sender.tag;
    [self yk_updateEmptyStates];
    [self yk_updatePagerHeightIfNeeded];
    CGFloat width = CGRectGetWidth(self.contentScrollView.bounds);
    [self.contentScrollView setContentOffset:CGPointMake(width * sender.tag, 0.0) animated:YES];
    [UIView animateWithDuration:0.22 animations:^{
        [self yk_updateSelectionWithProgress:(CGFloat)sender.tag];
    }];
}

- (void)yk_updateSelectionWithProgress:(CGFloat)progress {
    CGFloat boundedProgress = MIN(MAX(progress, 0.0), 1.0);
    if (self.segmentButtons.count < 2) {
        return;
    }
    [self.segmentButtons[0] setSelectionProgress:1.0 - boundedProgress];
    [self.segmentButtons[1] setSelectionProgress:boundedProgress];

    YKPersonaBoardSegmentButton *firstButton = self.segmentButtons.firstObject;
    YKPersonaBoardSegmentButton *secondButton = self.segmentButtons.lastObject;
    CGFloat firstW = CGRectGetWidth(firstButton.bounds);
    CGFloat secondW = CGRectGetWidth(secondButton.bounds);
    if (firstW <= 1.0 || secondW <= 1.0) {
        return;
    }
    CGFloat indicatorW = firstW * 0.42;
    self.indicatorWidthConstraint.constant = indicatorW;
    CGFloat firstCenter = CGRectGetMidX(firstButton.frame) - indicatorW * 0.5;
    CGFloat secondCenter = CGRectGetMidX(secondButton.frame) - indicatorW * 0.5;
    self.indicatorLeadingConstraint.constant = firstCenter + (secondCenter - firstCenter) * boundedProgress;
}

- (void)yk_updateEmptyStates {
    BOOL postsEmpty = self.yk_entries.count == 0;
    self.yk_entriesEmptyView.hidden = !postsEmpty;
    self.yk_collectionsEmptyView.hidden = NO; // Collections always nodata
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.contentScrollView) {
        return;
    }
    CGFloat width = CGRectGetWidth(scrollView.bounds);
    if (width <= 0.0) {
        return;
    }
    CGFloat progress = MIN(MAX(scrollView.contentOffset.x / width, 0.0), 1.0);
    [self yk_updateSelectionWithProgress:progress];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.contentScrollView) {
        return;
    }
    CGFloat width = CGRectGetWidth(scrollView.bounds);
    if (width <= 0.0) {
        return;
    }
    NSInteger index = (NSInteger)lround(scrollView.contentOffset.x / width);
    self.selectedIndex = MIN(MAX(index, 0), 1);
    [self yk_updatePagerHeightIfNeeded];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self scrollViewDidEndDecelerating:scrollView];
}

#pragma mark - Collection

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView.tag == 1) {
        return 0; // Collections: always empty
    }
    return (NSInteger)self.yk_entries.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YKFindPersonaBoardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YKFindPersonaBoardCell" forIndexPath:indexPath];
    if (collectionView.tag == 0 &&
        indexPath.item >= 0 &&
        indexPath.item < (NSInteger)self.yk_entries.count) {
        NSDictionary *entry = self.yk_entries[indexPath.item];
        UIImage *avatar = [YKPersonaCatalog yk_avatarImageForPersonaId:self.personaId] ?: [UIImage imageNamed:@"headplace"];
        [cell configureWithEntry:entry displayName:self.displayAlias avatar:avatar];
        __weak typeof(self) weakSelf = self;
        cell.yk_moreTapHandler = ^{
            [weakSelf yk_moreTapped:nil];
        };
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = CGRectGetWidth(collectionView.bounds);
    CGFloat itemWidth = width - 52.0;
    return CGSizeMake(itemWidth, [self yk_postItemHeightForWidth:itemWidth]);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0.0, 26.0, 18.0, 26.0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag != 0) {
        return;
    }
    if (indexPath.item < 0 || indexPath.item >= (NSInteger)self.yk_entries.count) {
        return;
    }
    YKFindDetailViewController *detail = [[YKFindDetailViewController alloc] initWithEntry:self.yk_entries[indexPath.item]];
    [self.navigationController pushViewController:detail animated:YES];
}

@end
