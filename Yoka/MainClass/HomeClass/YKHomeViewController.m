//
//  YKHomeViewController.m
//  Yoka
//

#import "YKHomeViewController.h"
#import "../LoginandReClass/YKPersonaCatalog.h"
#import "../LoginandReClass/YKAccountVault.h"
#import "../LoginandReClass/YKBondLedger.h"
#import "../FindClass/YKFindDetailViewController.h"
#import "../FindClass/YKFindPersonaBoardViewController.h"
#import "../RelayClass/YKReportShadeSheet.h"
#import "../RelayClass/YKReportViewController.h"
#import "../RelayClass/YKShadeRoster.h"
#import "../../BaseClass/YKEmptyStateView.h"
#import "../../BaseClass/YKCenterToast.h"
#import "../../BaseClass/YKSigilForge.h"

@interface YKHomeSegmentButton : UIControl

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, assign, readonly) CGFloat selectedTextWidth;

- (instancetype)initWithTitle:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (void)setActive:(BOOL)active animated:(BOOL)animated;
- (void)setSelectionProgress:(CGFloat)progress;

@end

@interface YKHomeSegmentButton ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) CGFloat selectedTextWidth;
@property (nonatomic, strong) UILabel *normalLabel;
@property (nonatomic, strong) UIView *gradientTextView;
@property (nonatomic, strong) UILabel *gradientMaskLabel;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, assign) BOOL active;

@end

@implementation YKHomeSegmentButton

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _title = [title copy];
        [self yk_setupViews];
    }
    return self;
}

- (void)yk_setupViews {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.isAccessibilityElement = YES;
    self.accessibilityLabel = self.title;
    self.accessibilityTraits = UIAccessibilityTraitButton;

    UIFont *normalFont = [UIFont systemFontOfSize:20.0 weight:UIFontWeightRegular];
    UIFont *selectedFont = [UIFont systemFontOfSize:24.0 weight:UIFontWeightBold];
    self.selectedTextWidth = ceil([self.title sizeWithAttributes:@{NSFontAttributeName: selectedFont}].width);

    UILabel *normalLabel = [self yk_labelWithText:self.title font:normalFont];
    normalLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.48];
    [self addSubview:normalLabel];
    self.normalLabel = normalLabel;

    UIView *gradientTextView = [[UIView alloc] init];
    gradientTextView.translatesAutoresizingMaskIntoConstraints = NO;
    gradientTextView.userInteractionEnabled = NO;
    gradientTextView.alpha = 0.0;
    [self addSubview:gradientTextView];
    self.gradientTextView = gradientTextView;

    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    gradientLayer.colors = @[
        (__bridge id)[UIColor whiteColor].CGColor,
        (__bridge id)[UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:1.0].CGColor
    ];
    [gradientTextView.layer addSublayer:gradientLayer];
    self.gradientLayer = gradientLayer;

    UILabel *gradientMaskLabel = [self yk_labelWithText:self.title font:selectedFont];
    gradientMaskLabel.frame = gradientTextView.bounds;
    gradientTextView.layer.mask = gradientMaskLabel.layer;
    self.gradientMaskLabel = gradientMaskLabel;

    [NSLayoutConstraint activateConstraints:@[
        [normalLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
        [normalLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [normalLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [normalLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        [gradientTextView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [gradientTextView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [gradientTextView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [gradientTextView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
}

- (UILabel *)yk_labelWithText:(NSString *)text font:(UIFont *)font {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.font = font;
    label.textAlignment = NSTextAlignmentLeft;
    return label;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(self.selectedTextWidth, 32.0);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.gradientTextView.bounds;
    self.gradientMaskLabel.frame = self.gradientTextView.bounds;
}

- (void)setActive:(BOOL)active animated:(BOOL)animated {
    void (^changes)(void) = ^{
        [self setSelectionProgress:active ? 1.0 : 0.0];
    };

    if (animated) {
        [UIView animateWithDuration:0.24 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:changes completion:nil];
    } else {
        changes();
    }
}

- (void)setSelectionProgress:(CGFloat)progress {
    CGFloat boundedProgress = MIN(MAX(progress, 0.0), 1.0);
    _active = boundedProgress >= 0.5;
    self.accessibilityTraits = self.active ? (UIAccessibilityTraitButton | UIAccessibilityTraitSelected) : UIAccessibilityTraitButton;
    self.gradientTextView.alpha = boundedProgress;
    self.normalLabel.alpha = 1.0 - boundedProgress;
}

@end

@interface YKGradientCardContentView : UIView

@end

@interface YKGradientCardContentView ()

@property (nonatomic, strong) CAGradientLayer *backgroundGradientLayer;

@end

@implementation YKGradientCardContentView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.36 green:0.06 blue:0.54 alpha:0.96];
        self.layer.cornerRadius = 18.0;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.28].CGColor;

        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.startPoint = CGPointMake(0.0, 0.0);
        gradientLayer.endPoint = CGPointMake(1.0, 1.0);
        gradientLayer.colors = @[
            (__bridge id)[UIColor colorWithRed:0.22 green:0.04 blue:0.38 alpha:1.0].CGColor,
            (__bridge id)[UIColor colorWithRed:0.62 green:0.10 blue:0.78 alpha:1.0].CGColor,
            (__bridge id)[UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:0.72].CGColor
        ];
        [self.layer insertSublayer:gradientLayer atIndex:0];
        self.backgroundGradientLayer = gradientLayer;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.backgroundGradientLayer.frame = self.bounds;
}

@end

@interface YKHomeViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) YKHomeSegmentButton *forYouButton;
@property (nonatomic, strong) YKHomeSegmentButton *trendingButton;
@property (nonatomic, strong) UIView *tabUnderlineView;
@property (nonatomic, strong) CAGradientLayer *tabUnderlineGradientLayer;
@property (nonatomic, strong) NSLayoutConstraint *tabUnderlineLeadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *tabUnderlineWidthConstraint;
@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, strong) UIView *forYouCardContainerView;
@property (nonatomic, strong) UIView *forYouBackRingDecorationView;
@property (nonatomic, strong) UIView *forYouFrontRingDecorationView;
@property (nonatomic, strong) YKEmptyStateView *yk_forYouEmptyView;
@property (nonatomic, strong) YKEmptyStateView *yk_trendingEmptyView;
@property (nonatomic, strong) UIStackView *yk_topCreatorsStackView;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, NSString *> *> *forYouAllCards;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, NSString *> *> *forYouCards;
@property (nonatomic, strong) NSMutableArray<UIView *> *visibleForYouCardViews;
@property (nonatomic, assign) NSInteger selectedContentIndex;
@property (nonatomic, assign) NSInteger currentForYouCardIndex;
@property (nonatomic, assign) BOOL isAnimatingForYouCard;
@property (nonatomic, assign) CGSize lastForYouCardContainerSize;
@property (nonatomic, copy) NSString *yk_actionPeerId;
@property (nonatomic, strong) UIImageView *yk_welcomeAvatarView;
@property (nonatomic, strong) UILabel *yk_welcomeNameLabel;
@property (nonatomic, strong) UIPanGestureRecognizer *yk_forYouPanGesture;

@end

@implementation YKHomeViewController

- (void)yk_configurePage {
    [super yk_configurePage];
    self.selectedContentIndex = 0;

    [self yk_setupHeaderView];
    [self yk_setupSegmentTabs];
    [self yk_setupContentScrollView];
    [self yk_updateSegmentSelectionAnimated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self yk_refreshWelcomeHeader];
    [self yk_refreshForYouCardsExcludingBlocked];
    [self yk_refreshTopCreatorsExcludingBlocked];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tabUnderlineGradientLayer.frame = self.tabUnderlineView.bounds;
    if (!self.contentScrollView.isDragging && !self.contentScrollView.isDecelerating) {
        [self yk_updateSegmentSelectionAnimated:NO];
    }
    if (!self.isAnimatingForYouCard) {
        CGSize containerSize = self.forYouCardContainerView.bounds.size;
        if (!CGSizeEqualToSize(containerSize, CGSizeZero) && !CGSizeEqualToSize(containerSize, self.lastForYouCardContainerSize)) {
            self.lastForYouCardContainerSize = containerSize;
            [self yk_reloadForYouCardStack];
            return;
        }
        [self yk_layoutForYouCardStackAnimated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view layoutIfNeeded];
    if (self.visibleForYouCardViews.count == 0) {
        [self yk_reloadForYouCardStack];
    } else {
        [self yk_layoutForYouCardStackAnimated:NO];
    }
}

- (void)yk_setupHeaderView {
    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    avatarImageView.layer.cornerRadius = 26.0;
    avatarImageView.layer.masksToBounds = YES;
    [self.view addSubview:avatarImageView];
    self.yk_welcomeAvatarView = avatarImageView;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"Welcome Back!";
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightBold];
    [self.view addSubview:titleLabel];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = @"Yoka User";
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    [self.view addSubview:nameLabel];
    self.yk_welcomeNameLabel = nameLabel;

    [NSLayoutConstraint activateConstraints:@[
        [avatarImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:22.0],
        [avatarImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28.0],
        [avatarImageView.widthAnchor constraintEqualToConstant:52.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:52.0],

        [titleLabel.topAnchor constraintEqualToAnchor:avatarImageView.topAnchor constant:4.0],
        [titleLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:12.0],
        [titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20.0],

        [nameLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:2.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
        [nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20.0]
    ]];

    [self yk_refreshWelcomeHeader];
}

- (void)yk_refreshWelcomeHeader {
    YKAccountVault *vault = [YKAccountVault sharedVault];
    NSString *name = [vault yk_displayNameForActiveMailbox];
    self.yk_welcomeNameLabel.text = name.length > 0 ? name : @"Yoka User";
    UIImage *portrait = [vault yk_portraitImageForActiveMailbox];
    self.yk_welcomeAvatarView.image = portrait ?: [UIImage imageNamed:@"headplace"];
}

- (void)yk_setupSegmentTabs {
    YKHomeSegmentButton *forYouButton = [self yk_segmentButtonWithTitle:@"For You" tag:0];
    YKHomeSegmentButton *trendingButton = [self yk_segmentButtonWithTitle:@"Trending Styles" tag:1];
    [self.view addSubview:forYouButton];
    [self.view addSubview:trendingButton];
    self.forYouButton = forYouButton;
    self.trendingButton = trendingButton;

    UIView *underlineView = [[UIView alloc] init];
    underlineView.translatesAutoresizingMaskIntoConstraints = NO;
    underlineView.layer.cornerRadius = 2.0;
    underlineView.layer.masksToBounds = YES;
    [self.view addSubview:underlineView];
    self.tabUnderlineView = underlineView;

    CAGradientLayer *underlineGradientLayer = [CAGradientLayer layer];
    underlineGradientLayer.startPoint = CGPointMake(0.0, 0.5);
    underlineGradientLayer.endPoint = CGPointMake(1.0, 0.5);
    underlineGradientLayer.colors = @[
        (__bridge id)[UIColor whiteColor].CGColor,
        (__bridge id)[UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:0.0].CGColor
    ];
    underlineGradientLayer.locations = @[@0.0, @0.5, @0.5, @1.0];
    [underlineView.layer addSublayer:underlineGradientLayer];
    self.tabUnderlineGradientLayer = underlineGradientLayer;

    self.tabUnderlineLeadingConstraint = [underlineView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28.0];
    self.tabUnderlineWidthConstraint = [underlineView.widthAnchor constraintEqualToConstant:60.0];

    [NSLayoutConstraint activateConstraints:@[
        [forYouButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:112.0],
        [forYouButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28.0],
        [forYouButton.heightAnchor constraintEqualToConstant:32.0],

        [trendingButton.centerYAnchor constraintEqualToAnchor:forYouButton.centerYAnchor],
        [trendingButton.leadingAnchor constraintEqualToAnchor:forYouButton.trailingAnchor constant:14.0],
        [trendingButton.heightAnchor constraintEqualToConstant:32.0],
        [trendingButton.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20.0],

        self.tabUnderlineLeadingConstraint,
        [underlineView.topAnchor constraintEqualToAnchor:forYouButton.bottomAnchor constant:-2.0],
        self.tabUnderlineWidthConstraint,
        [underlineView.heightAnchor constraintEqualToConstant:4.0]
    ]];
}

- (YKHomeSegmentButton *)yk_segmentButtonWithTitle:(NSString *)title tag:(NSInteger)tag {
    YKHomeSegmentButton *button = [[YKHomeSegmentButton alloc] initWithTitle:title];
    button.tag = tag;
    [button addTarget:self action:@selector(yk_segmentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)yk_setupContentScrollView {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.delegate = self;
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.bounces = YES;
    scrollView.alwaysBounceHorizontal = YES;
    scrollView.backgroundColor = UIColor.clearColor;
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:scrollView];
    self.contentScrollView = scrollView;

    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];

    UIView *forYouPageView = [self yk_forYouPageView];
    UIView *trendingPageView = [self yk_trendingPageView];
    [contentView addSubview:forYouPageView];
    [contentView addSubview:trendingPageView];

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.tabUnderlineView.bottomAnchor constant:16.0],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-92.0],

        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.heightAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.heightAnchor],

        [forYouPageView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [forYouPageView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [forYouPageView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
        [forYouPageView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],

        [trendingPageView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [trendingPageView.leadingAnchor constraintEqualToAnchor:forYouPageView.trailingAnchor],
        [trendingPageView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
        [trendingPageView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
        [trendingPageView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor]
    ]];
}

- (UIView *)yk_forYouPageView {
    UIView *pageView = [[UIView alloc] init];
    pageView.translatesAutoresizingMaskIntoConstraints = NO;
    pageView.backgroundColor = UIColor.clearColor;
    pageView.clipsToBounds = YES;

    self.forYouAllCards = @[
        @{
            @"personaId": @"korae",
            @"name": @"Korae",
            @"desc": @"Floating between 2000s nostalgia and gentle botanical moments. Every flash photo holds soft pink haze.",
            @"image": @"style_cover_8p"
        },
        @{
            @"personaId": @"yuvette",
            @"name": @"Yuvette",
            @"desc": @"Soft but bold, sweet yet edgy. Bringing back the unfiltered magic of millennial aesthetics.",
            @"image": @"foryou_yuvette"
        },
        @{
            @"personaId": @"zely",
            @"name": @"Zely",
            @"desc": @"Pastel glow & millennial daydreams, captured on CCD.",
            @"image": @"foryou_zely"
        }
    ];
    self.currentForYouCardIndex = 0;
    self.visibleForYouCardViews = [NSMutableArray arrayWithCapacity:3];
    [self yk_refreshForYouCardsExcludingBlocked];

    UIView *backRingDecorationView = [self yk_cardRingDecorationViewWithBackPart:YES];
    [pageView addSubview:backRingDecorationView];
    self.forYouBackRingDecorationView = backRingDecorationView;

    UIView *cardContainerView = [[UIView alloc] init];
    cardContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    cardContainerView.backgroundColor = UIColor.clearColor;
    cardContainerView.clipsToBounds = NO;
    [pageView addSubview:cardContainerView];
    self.forYouCardContainerView = cardContainerView;

    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(yk_forYouCardPanGestureChanged:)];
    [cardContainerView addGestureRecognizer:panGestureRecognizer];
    self.yk_forYouPanGesture = panGestureRecognizer;

    UIView *frontRingDecorationView = [self yk_cardRingDecorationViewWithBackPart:NO];
    [pageView addSubview:frontRingDecorationView];
    self.forYouFrontRingDecorationView = frontRingDecorationView;

    YKEmptyStateView *emptyView = [[YKEmptyStateView alloc] init];
    [pageView addSubview:emptyView];
    self.yk_forYouEmptyView = emptyView;

    [NSLayoutConstraint activateConstraints:@[
        [cardContainerView.topAnchor constraintEqualToAnchor:pageView.topAnchor constant:8.0],
        [cardContainerView.leadingAnchor constraintEqualToAnchor:pageView.leadingAnchor constant:20.0],
        [cardContainerView.trailingAnchor constraintEqualToAnchor:pageView.trailingAnchor constant:-20.0],
        [cardContainerView.bottomAnchor constraintEqualToAnchor:pageView.bottomAnchor constant:-25.0],

        [backRingDecorationView.widthAnchor constraintEqualToConstant:128.0],
        [backRingDecorationView.heightAnchor constraintEqualToConstant:92.0],
        [backRingDecorationView.leadingAnchor constraintEqualToAnchor:pageView.leadingAnchor constant:-56.0],
        [backRingDecorationView.topAnchor constraintEqualToAnchor:cardContainerView.topAnchor constant:-34.0],

        [frontRingDecorationView.widthAnchor constraintEqualToConstant:128.0],
        [frontRingDecorationView.heightAnchor constraintEqualToConstant:92.0],
        [frontRingDecorationView.leadingAnchor constraintEqualToAnchor:backRingDecorationView.leadingAnchor],
        [frontRingDecorationView.topAnchor constraintEqualToAnchor:backRingDecorationView.topAnchor],

        [emptyView.centerXAnchor constraintEqualToAnchor:pageView.centerXAnchor],
        [emptyView.centerYAnchor constraintEqualToAnchor:pageView.centerYAnchor constant:-24.0],
        [emptyView.widthAnchor constraintEqualToConstant:200.0]
    ]];

    [self yk_reloadForYouCardStack];
    [self yk_updateForYouEmptyState];

    return pageView;
}

- (NSString *)yk_ownerKey {
    YKAccountVault *vault = [YKAccountVault sharedVault];
    if ([YKAccountVault yk_isReviewMailbox:vault.yk_activeMailbox ?: @""]) {
        return [YKPersonaCatalog yk_reviewPersonaId];
    }
    return vault.yk_activeMailbox.length > 0 ? vault.yk_activeMailbox : @"guest";
}

- (void)yk_refreshForYouCardsExcludingBlocked {
    if (self.forYouAllCards.count == 0) {
        return;
    }
    NSString *owner = [self yk_ownerKey];
    NSMutableArray *visible = [NSMutableArray array];
    for (NSDictionary *card in self.forYouAllCards) {
        NSString *personaId = card[@"personaId"];
        if ([personaId isKindOfClass:NSString.class] &&
            [[YKShadeRoster sharedRoster] yk_ownerKey:owner hasShadedId:personaId]) {
            continue;
        }
        [visible addObject:card];
    }
    self.forYouCards = visible;
    if (self.forYouCards.count == 0) {
        self.currentForYouCardIndex = 0;
    } else if (self.currentForYouCardIndex >= (NSInteger)self.forYouCards.count) {
        self.currentForYouCardIndex = 0;
    }
    if (self.forYouCardContainerView) {
        [self yk_reloadForYouCardStack];
    }
}

- (void)yk_refreshTopCreatorsExcludingBlocked {
    UIStackView *stack = self.yk_topCreatorsStackView;
    if (!stack) {
        return;
    }
    for (UIView *sub in [stack.arrangedSubviews copy]) {
        [stack removeArrangedSubview:sub];
        [sub removeFromSuperview];
    }
    NSString *owner = [self yk_ownerKey];
    for (NSDictionary *persona in [YKPersonaCatalog yk_allPersonas]) {
        if ([persona[@"isTest"] boolValue]) {
            continue;
        }
        NSString *personaId = persona[@"id"];
        if ([personaId isKindOfClass:NSString.class] &&
            [[YKShadeRoster sharedRoster] yk_ownerKey:owner hasShadedId:personaId]) {
            continue;
        }
        [stack addArrangedSubview:[self yk_creatorViewWithName:persona[@"name"] personaId:personaId]];
    }
}

- (UIView *)yk_cardRingDecorationViewWithBackPart:(BOOL)isBackPart {
    UIView *containerView = [[UIView alloc] init];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    containerView.userInteractionEnabled = NO;

    UIColor *loopColor = [UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:0.95];
    UIColor *backLoopColor = [UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:0.72];

    if (isBackPart) {
        UIBezierPath *backPath = [UIBezierPath bezierPath];
        [backPath moveToPoint:CGPointMake(-18.0, 52.0)];
        [backPath addCurveToPoint:CGPointMake(94.0, 64.0)
                    controlPoint1:CGPointMake(16.0, 50.0)
                    controlPoint2:CGPointMake(54.0, 78.0)];

        CAShapeLayer *backLoopLayer = [CAShapeLayer layer];
        backLoopLayer.path = backPath.CGPath;
        backLoopLayer.strokeColor = backLoopColor.CGColor;
        backLoopLayer.fillColor = UIColor.clearColor.CGColor;
        backLoopLayer.lineWidth = 10.0;
        backLoopLayer.lineCap = kCALineCapRound;
        backLoopLayer.lineJoin = kCALineJoinRound;
        [containerView.layer addSublayer:backLoopLayer];
        return containerView;
    }

    UIView *ringView = [[UIView alloc] init];
    ringView.translatesAutoresizingMaskIntoConstraints = NO;
    ringView.backgroundColor = UIColor.whiteColor;
    ringView.layer.cornerRadius = 11.0;
    [containerView addSubview:ringView];

    CAShapeLayer *ringLayer = [CAShapeLayer layer];
    UIBezierPath *frontPath = [UIBezierPath bezierPath];
    [frontPath moveToPoint:CGPointMake(-18.0, 28.0)];
    [frontPath addCurveToPoint:CGPointMake(96.0, 58.0)
                 controlPoint1:CGPointMake(22.0, 27.0)
                 controlPoint2:CGPointMake(72.0, 24.0)];
    ringLayer.path = frontPath.CGPath;
    ringLayer.strokeColor = loopColor.CGColor;
    ringLayer.fillColor = UIColor.clearColor.CGColor;
    ringLayer.lineWidth = 11.0;
    ringLayer.lineCap = kCALineCapRound;
    ringLayer.lineJoin = kCALineJoinRound;
    [containerView.layer addSublayer:ringLayer];

    [NSLayoutConstraint activateConstraints:@[
        [ringView.widthAnchor constraintEqualToConstant:22.0],
        [ringView.heightAnchor constraintEqualToConstant:22.0],
        [ringView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:85.0],
        [ringView.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:47.0]
    ]];

    return containerView;
}

- (UIView *)yk_forYouCardViewWithName:(NSString *)name
                          description:(NSString *)description
                            imageName:(NSString *)imageName
                            personaId:(NSString *)personaId {
    UIView *cardView = [[UIView alloc] init];
    cardView.translatesAutoresizingMaskIntoConstraints = YES;
    cardView.backgroundColor = UIColor.clearColor;
    cardView.layer.cornerRadius = 18.0;
    cardView.layer.shadowColor = [UIColor colorWithRed:0.18 green:0.0 blue:0.28 alpha:1.0].CGColor;
    cardView.layer.shadowOpacity = 0.32;
    cardView.layer.shadowRadius = 14.0;
    cardView.layer.shadowOffset = CGSizeMake(0.0, 10.0);

    YKGradientCardContentView *contentView = [[YKGradientCardContentView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [cardView addSubview:contentView];

    UIImageView *coverImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
    coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    coverImageView.clipsToBounds = YES;
    [contentView addSubview:coverImageView];

    UIView *bottomScrimView = [[UIView alloc] init];
    bottomScrimView.translatesAutoresizingMaskIntoConstraints = NO;
    bottomScrimView.userInteractionEnabled = NO;
    bottomScrimView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.42];
    [contentView addSubview:bottomScrimView];

    UIImage *avatarImage = [YKPersonaCatalog yk_avatarImageForPersonaId:personaId] ?: [UIImage imageNamed:@"headplace"];
    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[avatarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    avatarImageView.layer.cornerRadius = 21.0;
    avatarImageView.layer.masksToBounds = YES;
    [contentView addSubview:avatarImageView];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = name;
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightBold];
    [contentView addSubview:nameLabel];

    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.translatesAutoresizingMaskIntoConstraints = NO;
    descLabel.text = description;
    descLabel.numberOfLines = 2;
    descLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.86];
    descLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    [contentView addSubview:descLabel];

    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    moreButton.accessibilityIdentifier = personaId ?: @"";
    [moreButton setImage:[[UIImage imageNamed:@"cardmore"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [moreButton addTarget:self action:@selector(yk_forYouMoreTapped:) forControlEvents:UIControlEventTouchUpInside];
    [contentView addSubview:moreButton];

    UITapGestureRecognizer *openTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(yk_forYouCardTapped:)];
    openTap.cancelsTouchesInView = NO;
    openTap.delegate = self;
    if (self.yk_forYouPanGesture) {
        [openTap requireGestureRecognizerToFail:self.yk_forYouPanGesture];
    }
    [cardView addGestureRecognizer:openTap];

    [NSLayoutConstraint activateConstraints:@[
        [contentView.topAnchor constraintEqualToAnchor:cardView.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:cardView.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:cardView.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:cardView.bottomAnchor],

        [coverImageView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [coverImageView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [coverImageView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
        [coverImageView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],

        [bottomScrimView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [bottomScrimView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
        [bottomScrimView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
        [bottomScrimView.heightAnchor constraintEqualToConstant:118.0],

        [moreButton.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:18.0],
        [moreButton.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-18.0],
        [moreButton.widthAnchor constraintEqualToConstant:32.0],
        [moreButton.heightAnchor constraintEqualToConstant:32.0],

        [avatarImageView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:28.0],
        [avatarImageView.bottomAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:4.0],
        [avatarImageView.widthAnchor constraintEqualToConstant:42.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:42.0],

        [nameLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:10.0],
        [nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:contentView.trailingAnchor constant:-20.0],
        [nameLabel.bottomAnchor constraintEqualToAnchor:descLabel.topAnchor constant:-8.0],

        [descLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:28.0],
        [descLabel.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-28.0],
        [descLabel.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-30.0]
    ]];

    return cardView;
}

- (UIView *)yk_forYouCardViewAtIndex:(NSInteger)index {
    NSInteger cardIndex = [self yk_wrappedForYouCardIndex:index];
    NSDictionary<NSString *, NSString *> *cardInfo = self.forYouCards[cardIndex];
    UIView *cardView = [self yk_forYouCardViewWithName:cardInfo[@"name"]
                                           description:cardInfo[@"desc"]
                                             imageName:cardInfo[@"image"]
                                             personaId:cardInfo[@"personaId"]];
    cardView.tag = cardIndex;
    return cardView;
}

- (void)yk_reloadForYouCardStack {
    [self.visibleForYouCardViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.visibleForYouCardViews removeAllObjects];

    if (self.forYouCards.count == 0) {
        [self yk_updateForYouEmptyState];
        return;
    }

    NSInteger visibleCount = MIN(3, self.forYouCards.count);
    for (NSInteger offset = visibleCount - 1; offset >= 0; offset--) {
        UIView *cardView = [self yk_forYouCardViewAtIndex:self.currentForYouCardIndex + offset];
        [self.forYouCardContainerView addSubview:cardView];
        [self.visibleForYouCardViews insertObject:cardView atIndex:0];
    }

    [self yk_layoutForYouCardStackAnimated:NO];
    [self.forYouCardContainerView bringSubviewToFront:self.visibleForYouCardViews.firstObject];
    [self.forYouFrontRingDecorationView.superview bringSubviewToFront:self.forYouFrontRingDecorationView];
    [self yk_updateForYouEmptyState];
}

- (void)yk_updateForYouEmptyState {
    BOOL empty = self.forYouCards.count == 0;
    self.yk_forYouEmptyView.hidden = !empty;
    self.forYouCardContainerView.hidden = empty;
    self.forYouBackRingDecorationView.hidden = empty;
    self.forYouFrontRingDecorationView.hidden = empty;
}

- (NSDictionary *)yk_forYouCardInfoAtTag:(NSInteger)tag {
    if (tag < 0 || tag >= (NSInteger)self.forYouCards.count) {
        return nil;
    }
    return self.forYouCards[tag];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *view = touch.view;
    while (view && view != gestureRecognizer.view) {
        if ([view isKindOfClass:UIControl.class]) {
            return NO;
        }
        view = view.superview;
    }
    return YES;
}

- (void)yk_forYouCardTapped:(UITapGestureRecognizer *)gesture {
    if (self.isAnimatingForYouCard) {
        return;
    }
    UIView *cardView = gesture.view;
    if (cardView != self.visibleForYouCardViews.firstObject) {
        return;
    }
    // Extra guard: ignore taps that land on the more button (or any control).
    CGPoint point = [gesture locationInView:cardView];
    UIView *hit = [cardView hitTest:point withEvent:nil];
    UIView *walk = hit;
    while (walk && walk != cardView) {
        if ([walk isKindOfClass:UIControl.class]) {
            return;
        }
        walk = walk.superview;
    }
    NSDictionary *card = [self yk_forYouCardInfoAtTag:cardView.tag];
    if (!card) {
        return;
    }
    NSDictionary *entry = @{
        @"personaId": card[@"personaId"] ?: @"",
        @"name": card[@"name"] ?: @"Yoka",
        @"caption": card[@"desc"] ?: @"",
        @"image": card[@"image"] ?: @"",
        @"ratio": @1.2
    };
    YKFindDetailViewController *detail = [[YKFindDetailViewController alloc] initWithEntry:entry];
    [self.navigationController pushViewController:detail animated:YES];
}

- (void)yk_forYouMoreTapped:(UIButton *)sender {
    NSString *peerId = sender.accessibilityIdentifier ?: @"";
    if (peerId.length == 0) {
        return;
    }
    self.yk_actionPeerId = peerId;
    __weak typeof(self) weakSelf = self;
    [YKReportShadeSheet yk_presentInView:self.view
                                  report:^{
        YKReportViewController *report = [[YKReportViewController alloc] initWithPersonaId:weakSelf.yk_actionPeerId];
        [weakSelf.navigationController pushViewController:report animated:YES];
    }
                                   block:^{
        [weakSelf yk_shadeForYouPeer:weakSelf.yk_actionPeerId];
    }];
}

- (void)yk_shadeForYouPeer:(NSString *)peerId {
    if (peerId.length == 0) {
        return;
    }
    NSString *owner = [self yk_ownerKey];
    if ([peerId isEqualToString:owner]) {
        return;
    }
    [[YKShadeRoster sharedRoster] yk_ownerKey:owner shadeId:peerId];
    [[YKBondLedger sharedLedger] yk_ownerKey:owner setLink:peerId on:NO];
    [YKCenterToast yk_showNotice:[YKSigilForge yk_unveil:@"gXSk12fDfGwMlYIIaZYBKg=="] inView:self.view];
    [self yk_refreshForYouCardsExcludingBlocked];
}

- (NSInteger)yk_wrappedForYouCardIndex:(NSInteger)index {
    NSInteger count = self.forYouCards.count;
    if (count == 0) {
        return 0;
    }
    NSInteger wrappedIndex = index % count;
    if (wrappedIndex < 0) {
        wrappedIndex += count;
    }
    return wrappedIndex;
}

- (void)yk_layoutForYouCardStackAnimated:(BOOL)animated {
    if (CGRectIsEmpty(self.forYouCardContainerView.bounds)) {
        return;
    }

    void (^layoutBlock)(void) = ^{
        [self.visibleForYouCardViews enumerateObjectsUsingBlock:^(UIView *cardView, NSUInteger idx, BOOL *stop) {
            CGFloat offset = 25.0 * (CGFloat)idx;
            CGRect frame = CGRectInset(self.forYouCardContainerView.bounds, 0.0, 0.0);
            frame.size.height = MAX(0.0, CGRectGetHeight(self.forYouCardContainerView.bounds) - 50.0);
            frame.origin.y = offset;
            cardView.frame = frame;
            cardView.alpha = 1.0 - 0.08 * (CGFloat)idx;
            cardView.transform = CGAffineTransformIdentity;
            cardView.layer.zPosition = 100.0 - (CGFloat)idx;
        }];
    };

    if (animated) {
        [UIView animateWithDuration:0.24 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:layoutBlock completion:nil];
    } else {
        layoutBlock();
    }
}

- (void)yk_forYouCardPanGestureChanged:(UIPanGestureRecognizer *)gestureRecognizer {
    if (self.isAnimatingForYouCard || self.visibleForYouCardViews.count == 0) {
        return;
    }

    CGPoint translation = [gestureRecognizer translationInView:self.forYouCardContainerView];
    CGPoint velocity = [gestureRecognizer velocityInView:self.forYouCardContainerView];

    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            BOOL shouldGoNext = translation.x < -90.0 || velocity.x < -500.0;
            BOOL shouldGoPrevious = translation.x > 90.0 || velocity.x > 500.0;

            if (shouldGoNext) {
                [self yk_turnForYouPageForward];
            } else if (shouldGoPrevious) {
                [self yk_turnForYouPageBackward];
            } else {
                [self yk_restoreTopForYouCard:self.visibleForYouCardViews.firstObject];
            }
            break;
        }
        default:
            break;
    }
}

- (void)yk_restoreTopForYouCard:(UIView *)topCardView {
    topCardView.transform = CGAffineTransformIdentity;
    topCardView.alpha = 1.0;
    [self yk_layoutForYouCardStackAnimated:NO];
}

- (void)yk_turnForYouPageForward {
    if (self.visibleForYouCardViews.count == 0) {
        return;
    }

    self.isAnimatingForYouCard = YES;
    [self yk_turnForYouPageForwardToIndex:[self yk_wrappedForYouCardIndex:self.currentForYouCardIndex + 1]];
}

- (void)yk_turnForYouPageBackward {
    if (self.visibleForYouCardViews.count == 0) {
        return;
    }

    self.isAnimatingForYouCard = YES;
    [self yk_turnForYouPageBackwardToIndex:[self yk_wrappedForYouCardIndex:self.currentForYouCardIndex - 1]];
}

- (void)yk_turnForYouPageForwardToIndex:(NSInteger)newIndex {
    if (self.visibleForYouCardViews.count == 0) {
        self.isAnimatingForYouCard = NO;
        return;
    }

    UIView *currentTopCardView = self.visibleForYouCardViews.firstObject;
    UIView *pageOverlayView = [currentTopCardView snapshotViewAfterScreenUpdates:NO] ?: [self yk_forYouCardViewAtIndex:self.currentForYouCardIndex];
    pageOverlayView.frame = currentTopCardView.frame;
    pageOverlayView.layer.cornerRadius = currentTopCardView.layer.cornerRadius;
    pageOverlayView.layer.masksToBounds = YES;
    pageOverlayView.layer.zPosition = 300.0;
    [self.forYouCardContainerView addSubview:pageOverlayView];

    self.currentForYouCardIndex = newIndex;
    [self yk_reloadForYouCardStack];
    [self.forYouCardContainerView bringSubviewToFront:pageOverlayView];
    [self yk_setLayerAnchorPoint:CGPointMake(0.0, 0.5) forView:pageOverlayView];

    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0 / 700.0;
    transform = CATransform3DRotate(transform, (CGFloat)(-M_PI_2 * 0.92), 0.0, 1.0, 0.0);
    transform = CATransform3DTranslate(transform, -CGRectGetWidth(pageOverlayView.bounds) * 0.18, 0.0, 0.0);

    [UIView animateWithDuration:0.48 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        pageOverlayView.layer.transform = transform;
        pageOverlayView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [pageOverlayView removeFromSuperview];
        self.isAnimatingForYouCard = NO;
        [self.forYouFrontRingDecorationView.superview bringSubviewToFront:self.forYouFrontRingDecorationView];
    }];
}

- (void)yk_turnForYouPageBackwardToIndex:(NSInteger)newIndex {
    UIView *previousCardView = [self yk_forYouCardViewAtIndex:newIndex];
    previousCardView.frame = self.visibleForYouCardViews.firstObject.frame;
    previousCardView.layer.zPosition = 300.0;
    [self.forYouCardContainerView addSubview:previousCardView];
    [self yk_setLayerAnchorPoint:CGPointMake(0.0, 0.5) forView:previousCardView];

    CATransform3D startTransform = CATransform3DIdentity;
    startTransform.m34 = -1.0 / 700.0;
    startTransform = CATransform3DRotate(startTransform, (CGFloat)(-M_PI_2 * 0.92), 0.0, 1.0, 0.0);
    startTransform = CATransform3DTranslate(startTransform, -CGRectGetWidth(previousCardView.bounds) * 0.18, 0.0, 0.0);
    previousCardView.layer.transform = startTransform;
    previousCardView.alpha = 0.0;

    [UIView animateWithDuration:0.48 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        previousCardView.layer.transform = CATransform3DIdentity;
        previousCardView.alpha = 1.0;
    } completion:^(BOOL finished) {
        self.currentForYouCardIndex = newIndex;
        [previousCardView removeFromSuperview];
        [self yk_reloadForYouCardStack];
        [self yk_layoutForYouCardStackAnimated:NO];
        self.isAnimatingForYouCard = NO;
        [self.forYouFrontRingDecorationView.superview bringSubviewToFront:self.forYouFrontRingDecorationView];
    }];
}

- (void)yk_setLayerAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view {
    CGPoint oldOrigin = view.frame.origin;
    view.layer.anchorPoint = anchorPoint;
    CGPoint newOrigin = view.frame.origin;
    CGPoint transition = CGPointMake(newOrigin.x - oldOrigin.x, newOrigin.y - oldOrigin.y);
    view.center = CGPointMake(view.center.x - transition.x, view.center.y - transition.y);
}

- (UIView *)yk_trendingPageView {
    UIView *pageView = [[UIView alloc] init];
    pageView.translatesAutoresizingMaskIntoConstraints = NO;
    pageView.backgroundColor = UIColor.clearColor;

    UILabel *popularLabel = [self yk_sectionLabelWithText:@"Popular styles"];
    [pageView addSubview:popularLabel];

    UIView *gridView = [[UIView alloc] init];
    gridView.translatesAutoresizingMaskIntoConstraints = NO;
    [pageView addSubview:gridView];

    NSArray<NSString *> *styleImages = @[
        @"style_cover_01",
        @"style_cover_02",
        @"style_cover_03",
        @"trending_style_04"
    ];

    YKEmptyStateView *emptyView = [[YKEmptyStateView alloc] init];
    [pageView addSubview:emptyView];
    self.yk_trendingEmptyView = emptyView;
    BOOL empty = styleImages.count == 0;
    emptyView.hidden = !empty;
    popularLabel.hidden = empty;
    gridView.hidden = empty;

    NSMutableArray<UIView *> *cards = [NSMutableArray arrayWithCapacity:4];
    for (NSInteger index = 0; index < (NSInteger)styleImages.count; index++) {
        UIView *card = [self yk_trendingCardWithImageName:styleImages[index]];
        [gridView addSubview:card];
        [cards addObject:card];
    }

    UILabel *creatorLabel = [self yk_sectionLabelWithText:@"Top Style Creators"];
    [pageView addSubview:creatorLabel];
    creatorLabel.hidden = empty;

    UIStackView *creatorStackView = [[UIStackView alloc] init];
    creatorStackView.translatesAutoresizingMaskIntoConstraints = NO;
    creatorStackView.axis = UILayoutConstraintAxisHorizontal;
    creatorStackView.alignment = UIStackViewAlignmentTop;
    creatorStackView.distribution = UIStackViewDistributionFill;
    creatorStackView.spacing = 18.0;
    [pageView addSubview:creatorStackView];
    creatorStackView.hidden = empty;
    self.yk_topCreatorsStackView = creatorStackView;

    [self yk_refreshTopCreatorsExcludingBlocked];

    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray arrayWithArray:@[
        [emptyView.centerXAnchor constraintEqualToAnchor:pageView.centerXAnchor],
        [emptyView.centerYAnchor constraintEqualToAnchor:pageView.centerYAnchor constant:-24.0],
        [emptyView.widthAnchor constraintEqualToConstant:200.0],

        [popularLabel.topAnchor constraintEqualToAnchor:pageView.topAnchor],
        [popularLabel.leadingAnchor constraintEqualToAnchor:pageView.leadingAnchor constant:28.0],

        [gridView.topAnchor constraintEqualToAnchor:popularLabel.bottomAnchor constant:14.0],
        [gridView.leadingAnchor constraintEqualToAnchor:pageView.leadingAnchor constant:28.0],
        [gridView.trailingAnchor constraintEqualToAnchor:pageView.trailingAnchor constant:-28.0],
        [gridView.heightAnchor constraintEqualToAnchor:gridView.widthAnchor multiplier:1.02],

        [creatorLabel.topAnchor constraintEqualToAnchor:gridView.bottomAnchor constant:18.0],
        [creatorLabel.leadingAnchor constraintEqualToAnchor:popularLabel.leadingAnchor],

        [creatorStackView.topAnchor constraintEqualToAnchor:creatorLabel.bottomAnchor constant:12.0],
        [creatorStackView.leadingAnchor constraintEqualToAnchor:pageView.leadingAnchor constant:28.0],
        [creatorStackView.trailingAnchor constraintLessThanOrEqualToAnchor:pageView.trailingAnchor constant:-28.0],
        [creatorStackView.bottomAnchor constraintLessThanOrEqualToAnchor:pageView.bottomAnchor]
    ]];

    if (cards.count >= 4) {
        UIView *card0 = cards[0];
        UIView *card1 = cards[1];
        UIView *card2 = cards[2];
        UIView *card3 = cards[3];
        [constraints addObjectsFromArray:@[
            [card0.topAnchor constraintEqualToAnchor:gridView.topAnchor],
            [card0.leadingAnchor constraintEqualToAnchor:gridView.leadingAnchor],
            [card0.widthAnchor constraintEqualToAnchor:gridView.widthAnchor multiplier:0.48],
            [card0.heightAnchor constraintEqualToAnchor:card0.widthAnchor multiplier:1.08],

            [card1.topAnchor constraintEqualToAnchor:gridView.topAnchor],
            [card1.trailingAnchor constraintEqualToAnchor:gridView.trailingAnchor],
            [card1.widthAnchor constraintEqualToAnchor:card0.widthAnchor],
            [card1.heightAnchor constraintEqualToAnchor:card0.heightAnchor],

            [card2.topAnchor constraintEqualToAnchor:card0.bottomAnchor constant:12.0],
            [card2.leadingAnchor constraintEqualToAnchor:gridView.leadingAnchor],
            [card2.widthAnchor constraintEqualToAnchor:card0.widthAnchor],
            [card2.heightAnchor constraintEqualToAnchor:card0.heightAnchor],

            [card3.topAnchor constraintEqualToAnchor:card1.bottomAnchor constant:12.0],
            [card3.trailingAnchor constraintEqualToAnchor:gridView.trailingAnchor],
            [card3.widthAnchor constraintEqualToAnchor:card0.widthAnchor],
            [card3.heightAnchor constraintEqualToAnchor:card0.heightAnchor]
        ]];
    }

    [NSLayoutConstraint activateConstraints:constraints];

    return pageView;
}

- (UILabel *)yk_sectionLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
    return label;
}

- (UIView *)yk_trendingCardWithImageName:(NSString *)imageName {
    UIView *cardView = [[UIView alloc] init];
    cardView.translatesAutoresizingMaskIntoConstraints = NO;
    cardView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    cardView.layer.cornerRadius = 12.0;
    cardView.layer.masksToBounds = YES;

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [cardView addSubview:imageView];

    [NSLayoutConstraint activateConstraints:@[
        [imageView.topAnchor constraintEqualToAnchor:cardView.topAnchor],
        [imageView.leadingAnchor constraintEqualToAnchor:cardView.leadingAnchor],
        [imageView.trailingAnchor constraintEqualToAnchor:cardView.trailingAnchor],
        [imageView.bottomAnchor constraintEqualToAnchor:cardView.bottomAnchor]
    ]];

    return cardView;
}

- (UIView *)yk_creatorViewWithName:(NSString *)name personaId:(NSString *)personaId {
    UIView *containerView = [[UIView alloc] init];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;

    UIImage *avatarImage = [YKPersonaCatalog yk_avatarImageForPersonaId:personaId] ?: [UIImage imageNamed:@"headplace"];
    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[avatarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    avatarImageView.layer.cornerRadius = 21.0;
    avatarImageView.layer.masksToBounds = YES;
    avatarImageView.userInteractionEnabled = NO;
    [containerView addSubview:avatarImageView];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = name;
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
    nameLabel.userInteractionEnabled = NO;
    [containerView addSubview:nameLabel];

    UIButton *hitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    hitButton.translatesAutoresizingMaskIntoConstraints = NO;
    hitButton.backgroundColor = UIColor.clearColor;
    hitButton.accessibilityIdentifier = personaId ?: @"";
    [hitButton addTarget:self action:@selector(yk_topCreatorTapped:) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:hitButton];

    [NSLayoutConstraint activateConstraints:@[
        [containerView.widthAnchor constraintEqualToConstant:48.0],
        [avatarImageView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
        [avatarImageView.centerXAnchor constraintEqualToAnchor:containerView.centerXAnchor],
        [avatarImageView.widthAnchor constraintEqualToConstant:42.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:42.0],
        [nameLabel.topAnchor constraintEqualToAnchor:avatarImageView.bottomAnchor constant:4.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
        [nameLabel.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
        [nameLabel.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor],

        [hitButton.topAnchor constraintEqualToAnchor:containerView.topAnchor],
        [hitButton.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
        [hitButton.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
        [hitButton.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor]
    ]];

    return containerView;
}

- (void)yk_topCreatorTapped:(UIButton *)sender {
    NSString *personaId = sender.accessibilityIdentifier ?: @"";
    if (personaId.length == 0) {
        return;
    }
    YKFindPersonaBoardViewController *profile = [[YKFindPersonaBoardViewController alloc] initWithPersonaId:personaId];
    [self.navigationController pushViewController:profile animated:YES];
}

- (void)yk_segmentButtonTapped:(YKHomeSegmentButton *)sender {
    [self yk_selectContentIndex:sender.tag animated:YES];
}

- (void)yk_selectContentIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index > 1) {
        return;
    }

    self.selectedContentIndex = index;
    [self yk_updateSegmentSelectionAnimated:animated];

    CGFloat targetX = CGRectGetWidth(self.contentScrollView.bounds) * index;
    [self.contentScrollView setContentOffset:CGPointMake(targetX, 0) animated:animated];
}

- (void)yk_updateSegmentSelectionAnimated:(BOOL)animated {
    YKHomeSegmentButton *selectedButton = self.selectedContentIndex == 0 ? self.forYouButton : self.trendingButton;
    [self.forYouButton setActive:self.selectedContentIndex == 0 animated:animated];
    [self.trendingButton setActive:self.selectedContentIndex == 1 animated:animated];

    self.tabUnderlineLeadingConstraint.constant = CGRectGetMinX(selectedButton.frame);
    self.tabUnderlineWidthConstraint.constant = CGRectGetWidth(selectedButton.bounds);

    void (^changes)(void) = ^{
        [self.view layoutIfNeeded];
    };

    if (animated) {
        [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:changes completion:nil];
    } else {
        changes();
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.contentScrollView) {
        return;
    }

    CGFloat width = CGRectGetWidth(scrollView.bounds);
    if (width <= 0) {
        return;
    }

    CGFloat progress = MIN(MAX(scrollView.contentOffset.x / width, 0.0), 1.0);
    [self.forYouButton setSelectionProgress:1.0 - progress];
    [self.trendingButton setSelectionProgress:progress];
    [self yk_updateUnderlineWithProgress:progress];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self yk_syncSegmentWithScrollView:scrollView animated:YES];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self yk_syncSegmentWithScrollView:scrollView animated:YES];
}

- (void)yk_syncSegmentWithScrollView:(UIScrollView *)scrollView animated:(BOOL)animated {
    CGFloat width = CGRectGetWidth(scrollView.bounds);
    if (width <= 0) {
        return;
    }

    NSInteger index = (NSInteger)lround(scrollView.contentOffset.x / width);
    index = MAX(0, MIN(index, 1));
    if (index == self.selectedContentIndex) {
        return;
    }

    self.selectedContentIndex = index;
    [self yk_updateSegmentSelectionAnimated:animated];
}

- (void)yk_updateUnderlineWithProgress:(CGFloat)progress {
    CGFloat boundedProgress = MIN(MAX(progress, 0.0), 1.0);
    CGFloat startX = CGRectGetMinX(self.forYouButton.frame);
    CGFloat endX = CGRectGetMinX(self.trendingButton.frame);
    CGFloat startWidth = CGRectGetWidth(self.forYouButton.bounds);
    CGFloat endWidth = CGRectGetWidth(self.trendingButton.bounds);

    self.tabUnderlineLeadingConstraint.constant = startX + (endX - startX) * boundedProgress;
    self.tabUnderlineWidthConstraint.constant = startWidth + (endWidth - startWidth) * boundedProgress;
    [self.view layoutIfNeeded];
}

@end
