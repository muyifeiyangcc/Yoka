//
//  YKHomeViewController.m
//  Yoka
//

#import "YKHomeViewController.h"

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

@interface YKHomeViewController () <UIScrollViewDelegate>

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
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, NSString *> *> *forYouCards;
@property (nonatomic, strong) NSMutableArray<UIView *> *visibleForYouCardViews;
@property (nonatomic, assign) NSInteger selectedContentIndex;
@property (nonatomic, assign) NSInteger currentForYouCardIndex;
@property (nonatomic, assign) BOOL isAnimatingForYouCard;
@property (nonatomic, assign) CGSize lastForYouCardContainerSize;

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

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"Welcome Back!";
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightBold];
    [self.view addSubview:titleLabel];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = @"Amelia";
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    [self.view addSubview:nameLabel];

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

    self.forYouCards = @[
        @{@"title": @"Y2K FIT", @"name": @"Alina", @"desc": @"Today's fit is pure Y2K energy. Vintage vibes, bold details, and zero compromises."},
        @{@"title": @"RETRO", @"name": @"Freya", @"desc": @"Glossy textures, silver accents, and a soft neon palette for the day."},
        @{@"title": @"GLAM", @"name": @"Lumi", @"desc": @"A playful mix of denim, pink chrome, and statement accessories."},
        @{@"title": @"CHROME", @"name": @"Bodhi", @"desc": @"Metallic layers, low-rise shapes, and soft club lighting."},
        @{@"title": @"NEON", @"name": @"Amelia", @"desc": @"A bright throwback look with glossy details and a clean silhouette."}
    ];
    self.currentForYouCardIndex = 0;
    self.visibleForYouCardViews = [NSMutableArray arrayWithCapacity:3];

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

    UIView *frontRingDecorationView = [self yk_cardRingDecorationViewWithBackPart:NO];
    [pageView addSubview:frontRingDecorationView];
    self.forYouFrontRingDecorationView = frontRingDecorationView;

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
        [frontRingDecorationView.topAnchor constraintEqualToAnchor:backRingDecorationView.topAnchor]
    ]];

    [self yk_reloadForYouCardStack];

    return pageView;
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

- (UIView *)yk_forYouCardViewWithTitle:(NSString *)title name:(NSString *)name description:(NSString *)description {
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

    UILabel *imagePlaceholderLabel = [[UILabel alloc] init];
    imagePlaceholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    imagePlaceholderLabel.text = title;
    imagePlaceholderLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.82];
    imagePlaceholderLabel.textAlignment = NSTextAlignmentCenter;
    imagePlaceholderLabel.font = [UIFont systemFontOfSize:36.0 weight:UIFontWeightBlack];
    [contentView addSubview:imagePlaceholderLabel];

    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
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
    [moreButton setImage:[[UIImage imageNamed:@"cardmore"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [contentView addSubview:moreButton];

    [NSLayoutConstraint activateConstraints:@[
        [contentView.topAnchor constraintEqualToAnchor:cardView.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:cardView.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:cardView.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:cardView.bottomAnchor],

        [imagePlaceholderLabel.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        [imagePlaceholderLabel.centerYAnchor constraintEqualToAnchor:contentView.centerYAnchor constant:-24.0],

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
    UIView *cardView = [self yk_forYouCardViewWithTitle:cardInfo[@"title"]
                                                   name:cardInfo[@"name"]
                                            description:cardInfo[@"desc"]];
    cardView.tag = cardIndex;
    return cardView;
}

- (void)yk_reloadForYouCardStack {
    [self.visibleForYouCardViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.visibleForYouCardViews removeAllObjects];

    NSInteger visibleCount = MIN(3, self.forYouCards.count);
    for (NSInteger offset = visibleCount - 1; offset >= 0; offset--) {
        UIView *cardView = [self yk_forYouCardViewAtIndex:self.currentForYouCardIndex + offset];
        [self.forYouCardContainerView addSubview:cardView];
        [self.visibleForYouCardViews insertObject:cardView atIndex:0];
    }

    [self yk_layoutForYouCardStackAnimated:NO];
    [self.forYouCardContainerView bringSubviewToFront:self.visibleForYouCardViews.firstObject];
    [self.forYouFrontRingDecorationView.superview bringSubviewToFront:self.forYouFrontRingDecorationView];
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

    NSArray<UIColor *> *colors = @[
        [UIColor colorWithRed:0.36 green:0.46 blue:0.83 alpha:1.0],
        [UIColor colorWithRed:0.96 green:0.58 blue:0.73 alpha:1.0],
        [UIColor colorWithRed:0.78 green:0.42 blue:0.24 alpha:1.0],
        [UIColor colorWithRed:0.72 green:0.78 blue:0.77 alpha:1.0]
    ];

    NSMutableArray<UIView *> *cards = [NSMutableArray arrayWithCapacity:4];
    for (NSInteger index = 0; index < 4; index++) {
        UIView *card = [self yk_trendingCardWithColor:colors[index]];
        [gridView addSubview:card];
        [cards addObject:card];
    }

    UILabel *creatorLabel = [self yk_sectionLabelWithText:@"Top Style Creators"];
    [pageView addSubview:creatorLabel];

    UIStackView *creatorStackView = [[UIStackView alloc] init];
    creatorStackView.translatesAutoresizingMaskIntoConstraints = NO;
    creatorStackView.axis = UILayoutConstraintAxisHorizontal;
    creatorStackView.alignment = UIStackViewAlignmentTop;
    creatorStackView.distribution = UIStackViewDistributionEqualSpacing;
    [pageView addSubview:creatorStackView];

    NSArray<NSString *> *names = @[@"Freya", @"Stellan", @"Lumi", @"Bodhi", @"Alina"];
    for (NSString *name in names) {
        [creatorStackView addArrangedSubview:[self yk_creatorViewWithName:name]];
    }

    UIView *card0 = cards[0];
    UIView *card1 = cards[1];
    UIView *card2 = cards[2];
    UIView *card3 = cards[3];

    [NSLayoutConstraint activateConstraints:@[
        [popularLabel.topAnchor constraintEqualToAnchor:pageView.topAnchor],
        [popularLabel.leadingAnchor constraintEqualToAnchor:pageView.leadingAnchor constant:28.0],

        [gridView.topAnchor constraintEqualToAnchor:popularLabel.bottomAnchor constant:14.0],
        [gridView.leadingAnchor constraintEqualToAnchor:pageView.leadingAnchor constant:28.0],
        [gridView.trailingAnchor constraintEqualToAnchor:pageView.trailingAnchor constant:-28.0],
        [gridView.heightAnchor constraintEqualToAnchor:gridView.widthAnchor multiplier:1.02],

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
        [card3.heightAnchor constraintEqualToAnchor:card0.heightAnchor],

        [creatorLabel.topAnchor constraintEqualToAnchor:gridView.bottomAnchor constant:18.0],
        [creatorLabel.leadingAnchor constraintEqualToAnchor:popularLabel.leadingAnchor],

        [creatorStackView.topAnchor constraintEqualToAnchor:creatorLabel.bottomAnchor constant:12.0],
        [creatorStackView.leadingAnchor constraintEqualToAnchor:pageView.leadingAnchor constant:28.0],
        [creatorStackView.trailingAnchor constraintEqualToAnchor:pageView.trailingAnchor constant:-28.0],
        [creatorStackView.bottomAnchor constraintLessThanOrEqualToAnchor:pageView.bottomAnchor]
    ]];

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

- (UIView *)yk_trendingCardWithColor:(UIColor *)color {
    UIView *cardView = [[UIView alloc] init];
    cardView.translatesAutoresizingMaskIntoConstraints = NO;
    cardView.backgroundColor = color;
    cardView.layer.cornerRadius = 12.0;
    cardView.layer.masksToBounds = YES;

    UILabel *heartLabel = [[UILabel alloc] init];
    heartLabel.translatesAutoresizingMaskIntoConstraints = NO;
    heartLabel.text = @"+";
    heartLabel.textAlignment = NSTextAlignmentCenter;
    heartLabel.textColor = [UIColor colorWithRed:1.0 green:0.14 blue:0.76 alpha:1.0];
    heartLabel.backgroundColor = UIColor.whiteColor;
    heartLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
    heartLabel.layer.cornerRadius = 12.0;
    heartLabel.layer.masksToBounds = YES;
    [cardView addSubview:heartLabel];

    [NSLayoutConstraint activateConstraints:@[
        [heartLabel.trailingAnchor constraintEqualToAnchor:cardView.trailingAnchor constant:-8.0],
        [heartLabel.bottomAnchor constraintEqualToAnchor:cardView.bottomAnchor constant:-8.0],
        [heartLabel.widthAnchor constraintEqualToConstant:24.0],
        [heartLabel.heightAnchor constraintEqualToConstant:24.0]
    ]];

    return cardView;
}

- (UIView *)yk_creatorViewWithName:(NSString *)name {
    UIView *containerView = [[UIView alloc] init];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;

    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    avatarImageView.layer.cornerRadius = 21.0;
    avatarImageView.layer.masksToBounds = YES;
    [containerView addSubview:avatarImageView];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = name;
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
    [containerView addSubview:nameLabel];

    [NSLayoutConstraint activateConstraints:@[
        [containerView.widthAnchor constraintEqualToConstant:48.0],
        [avatarImageView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
        [avatarImageView.centerXAnchor constraintEqualToAnchor:containerView.centerXAnchor],
        [avatarImageView.widthAnchor constraintEqualToConstant:42.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:42.0],
        [nameLabel.topAnchor constraintEqualToAnchor:avatarImageView.bottomAnchor constant:4.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
        [nameLabel.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
        [nameLabel.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor]
    ]];

    return containerView;
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
