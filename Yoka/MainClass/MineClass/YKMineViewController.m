//
//  YKMineViewController.m
//  Yoka
//

#import "YKMineViewController.h"

@interface YKMinePostCell : UICollectionViewCell

- (void)configureWithColor:(UIColor *)color;

@end

@interface YKMinePostCell ()

@property (nonatomic, strong) UIView *photoView;
@property (nonatomic, strong) CAGradientLayer *photoGradientLayer;

@end

@implementation YKMinePostCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self yk_setupViews];
    }
    return self;
}

- (void)yk_setupViews {
    self.contentView.backgroundColor = UIColor.whiteColor;
    self.contentView.layer.cornerRadius = 14.0;
    self.contentView.layer.masksToBounds = YES;

    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.layer.cornerRadius = 18.0;
    avatarImageView.layer.masksToBounds = YES;
    [self.contentView addSubview:avatarImageView];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = @"Amelia";
    nameLabel.textColor = UIColor.blackColor;
    nameLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
    [self.contentView addSubview:nameLabel];

    UILabel *subNameLabel = [[UILabel alloc] init];
    subNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subNameLabel.text = @"Amelia";
    subNameLabel.textColor = [UIColor colorWithWhite:0.35 alpha:1.0];
    subNameLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    [self.contentView addSubview:subNameLabel];

    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [moreButton setImage:[[UIImage imageNamed:@"detail_more_button"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [self.contentView addSubview:moreButton];

    UIView *photoView = [[UIView alloc] init];
    photoView.translatesAutoresizingMaskIntoConstraints = NO;
    photoView.layer.cornerRadius = 10.0;
    photoView.layer.masksToBounds = YES;
    [self.contentView addSubview:photoView];
    self.photoView = photoView;

    CAGradientLayer *photoGradientLayer = [CAGradientLayer layer];
    photoGradientLayer.startPoint = CGPointMake(0.0, 0.0);
    photoGradientLayer.endPoint = CGPointMake(1.0, 1.0);
    [photoView.layer addSublayer:photoGradientLayer];
    self.photoGradientLayer = photoGradientLayer;

    UILabel *photoTitleLabel = [[UILabel alloc] init];
    photoTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    photoTitleLabel.text = @"Y2K FIT";
    photoTitleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.86];
    photoTitleLabel.textAlignment = NSTextAlignmentCenter;
    photoTitleLabel.font = [UIFont systemFontOfSize:30.0 weight:UIFontWeightBlack];
    [photoView addSubview:photoTitleLabel];

    UIImageView *playImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mine_play_icon"]];
    playImageView.translatesAutoresizingMaskIntoConstraints = NO;
    playImageView.contentMode = UIViewContentModeScaleAspectFit;
    [photoView addSubview:playImageView];

    UIStackView *statsStackView = [[UIStackView alloc] init];
    statsStackView.translatesAutoresizingMaskIntoConstraints = NO;
    statsStackView.axis = UILayoutConstraintAxisHorizontal;
    statsStackView.alignment = UIStackViewAlignmentCenter;
    statsStackView.spacing = 18.0;
    [self.contentView addSubview:statsStackView];
    [statsStackView addArrangedSubview:[self yk_statViewWithImageName:@"detail_like_star" title:@"666 Likes"]];
    [statsStackView addArrangedSubview:[self yk_statViewWithImageName:@"detail_comment_icon" title:@"777 Comments"]];

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

        [photoTitleLabel.centerXAnchor constraintEqualToAnchor:photoView.centerXAnchor],
        [photoTitleLabel.centerYAnchor constraintEqualToAnchor:photoView.centerYAnchor],

        [playImageView.centerXAnchor constraintEqualToAnchor:photoView.centerXAnchor],
        [playImageView.centerYAnchor constraintEqualToAnchor:photoView.centerYAnchor],
        [playImageView.widthAnchor constraintEqualToConstant:24.0],
        [playImageView.heightAnchor constraintEqualToConstant:24.0],

        [statsStackView.topAnchor constraintEqualToAnchor:photoView.bottomAnchor constant:10.0],
        [statsStackView.leadingAnchor constraintEqualToAnchor:photoView.leadingAnchor],
        [statsStackView.heightAnchor constraintEqualToConstant:18.0]
    ]];
}

- (UIView *)yk_statViewWithImageName:(NSString *)imageName title:(NSString *)title {
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 4.0;

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [stackView addArrangedSubview:imageView];

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.textColor = UIColor.blackColor;
    label.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightRegular];
    [stackView addArrangedSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [imageView.widthAnchor constraintEqualToConstant:13.0],
        [imageView.heightAnchor constraintEqualToConstant:13.0]
    ]];

    return stackView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.photoGradientLayer.frame = self.photoView.bounds;
}

- (void)configureWithColor:(UIColor *)color {
    UIColor *endColor = [UIColor colorWithRed:0.92 green:0.02 blue:0.80 alpha:1.0];
    self.photoGradientLayer.colors = @[
        (__bridge id)color.CGColor,
        (__bridge id)endColor.CGColor
    ];
}

@end

@interface YKMineCollectionCell : UICollectionViewCell

- (void)configureWithColor:(UIColor *)color;

@end

@interface YKMineCollectionCell ()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation YKMineCollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.layer.cornerRadius = 14.0;
        self.contentView.layer.masksToBounds = YES;

        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.startPoint = CGPointMake(0.0, 0.0);
        gradientLayer.endPoint = CGPointMake(1.0, 1.0);
        [self.contentView.layer addSublayer:gradientLayer];
        self.gradientLayer = gradientLayer;

        UIImageView *playImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mine_play_icon"]];
        playImageView.translatesAutoresizingMaskIntoConstraints = NO;
        playImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:playImageView];

        [NSLayoutConstraint activateConstraints:@[
            [playImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [playImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [playImageView.widthAnchor constraintEqualToConstant:24.0],
            [playImageView.heightAnchor constraintEqualToConstant:24.0]
        ]];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.contentView.bounds;
}

- (void)configureWithColor:(UIColor *)color {
    self.gradientLayer.colors = @[
        (__bridge id)color.CGColor,
        (__bridge id)[UIColor colorWithRed:0.14 green:0.10 blue:0.18 alpha:1.0].CGColor
    ];
}

@end

@interface YKMineSegmentButton : UIControl

@property (nonatomic, copy, readonly) NSString *title;

- (instancetype)initWithTitle:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (void)setSelectionProgress:(CGFloat)progress;

@end

@interface YKMineSegmentButton ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UILabel *label;

@end

@implementation YKMineSegmentButton

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

@interface YKMineViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

@property (nonatomic, strong) NSArray<NSString *> *segmentTitles;
@property (nonatomic, strong) NSMutableArray<YKMineSegmentButton *> *segmentButtons;
@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) NSLayoutConstraint *indicatorLeadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *indicatorWidthConstraint;
@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, strong) UICollectionView *postsCollectionView;
@property (nonatomic, strong) UICollectionView *collectionsCollectionView;
@property (nonatomic, strong) NSArray<UIColor *> *itemColors;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

@implementation YKMineViewController

- (void)yk_configurePage {
    [super yk_configurePage];

    self.segmentTitles = @[@"Posts", @"Collections"];
    self.segmentButtons = [NSMutableArray arrayWithCapacity:self.segmentTitles.count];
    self.itemColors = @[
        [UIColor colorWithRed:0.12 green:0.11 blue:0.18 alpha:1.0],
        [UIColor colorWithRed:0.54 green:0.36 blue:0.26 alpha:1.0],
        [UIColor colorWithRed:0.40 green:0.20 blue:0.18 alpha:1.0],
        [UIColor colorWithRed:0.24 green:0.23 blue:0.30 alpha:1.0],
        [UIColor colorWithRed:0.60 green:0.42 blue:0.36 alpha:1.0],
        [UIColor colorWithRed:0.18 green:0.30 blue:0.38 alpha:1.0]
    ];

    [self yk_setupHeaderView];
    [self yk_setupSegments];
    [self yk_setupContentScrollView];
    [self yk_updateSelectionWithProgress:0.0];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!self.contentScrollView.isDragging && !self.contentScrollView.isDecelerating) {
        [self yk_updateSelectionWithProgress:self.selectedIndex];
    }
}

- (void)yk_setupHeaderView {
    UIImageView *backImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav_back"]];
    backImageView.translatesAutoresizingMaskIntoConstraints = NO;
    backImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:backImageView];

    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [settingsButton setImage:[[UIImage imageNamed:@"mine_settings_button"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [self.view addSubview:settingsButton];

    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.layer.cornerRadius = 50.0;
    avatarImageView.layer.masksToBounds = YES;
    [self.view addSubview:avatarImageView];

    UILabel *followersValueLabel = [self yk_countLabelWithText:@"23"];
    UILabel *followersTitleLabel = [self yk_captionLabelWithText:@"Followers"];
    UILabel *followingValueLabel = [self yk_countLabelWithText:@"34"];
    UILabel *followingTitleLabel = [self yk_captionLabelWithText:@"Following"];
    [self.view addSubview:followersValueLabel];
    [self.view addSubview:followersTitleLabel];
    [self.view addSubview:followingValueLabel];
    [self.view addSubview:followingTitleLabel];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = @"Amelia";
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:27.0 weight:UIFontWeightBold];
    [self.view addSubview:nameLabel];

    UIButton *editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    editButton.translatesAutoresizingMaskIntoConstraints = NO;
    [editButton setTitle:@"Edit" forState:UIControlStateNormal];
    [editButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    editButton.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
    editButton.layer.cornerRadius = 19.0;
    editButton.layer.borderWidth = 2.0;
    editButton.layer.borderColor = UIColor.whiteColor.CGColor;
    [self.view addSubview:editButton];

    UIImageView *balanceImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mine_balance_banner"]];
    balanceImageView.translatesAutoresizingMaskIntoConstraints = NO;
    balanceImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:balanceImageView];

    UILabel *balanceValueLabel = [[UILabel alloc] init];
    balanceValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    balanceValueLabel.text = @"400";
    balanceValueLabel.textColor = UIColor.whiteColor;
    balanceValueLabel.font = [UIFont systemFontOfSize:27.0 weight:UIFontWeightBold];
    [balanceImageView addSubview:balanceValueLabel];

    UILabel *balanceTitleLabel = [[UILabel alloc] init];
    balanceTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    balanceTitleLabel.text = @"Balance";
    balanceTitleLabel.textColor = UIColor.whiteColor;
    balanceTitleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
    [balanceImageView addSubview:balanceTitleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [backImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24.0],
        [backImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28.0],
        [backImageView.widthAnchor constraintEqualToConstant:24.0],
        [backImageView.heightAnchor constraintEqualToConstant:24.0],

        [settingsButton.centerYAnchor constraintEqualToAnchor:backImageView.centerYAnchor],
        [settingsButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-28.0],
        [settingsButton.widthAnchor constraintEqualToConstant:32.0],
        [settingsButton.heightAnchor constraintEqualToConstant:32.0],

        [avatarImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:74.0],
        [avatarImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:26.0],
        [avatarImageView.widthAnchor constraintEqualToConstant:100.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:100.0],

        [followersValueLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:30.0],
        [followersValueLabel.topAnchor constraintEqualToAnchor:avatarImageView.topAnchor constant:26.0],
        [followersTitleLabel.leadingAnchor constraintEqualToAnchor:followersValueLabel.leadingAnchor],
        [followersTitleLabel.topAnchor constraintEqualToAnchor:followersValueLabel.bottomAnchor constant:3.0],

        [followingValueLabel.leadingAnchor constraintEqualToAnchor:followersValueLabel.trailingAnchor constant:68.0],
        [followingValueLabel.centerYAnchor constraintEqualToAnchor:followersValueLabel.centerYAnchor],
        [followingTitleLabel.leadingAnchor constraintEqualToAnchor:followingValueLabel.leadingAnchor],
        [followingTitleLabel.topAnchor constraintEqualToAnchor:followingValueLabel.bottomAnchor constant:3.0],

        [nameLabel.topAnchor constraintEqualToAnchor:avatarImageView.bottomAnchor constant:12.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:38.0],

        [editButton.centerYAnchor constraintEqualToAnchor:nameLabel.centerYAnchor],
        [editButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-28.0],
        [editButton.widthAnchor constraintEqualToConstant:78.0],
        [editButton.heightAnchor constraintEqualToConstant:38.0],

        [balanceImageView.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:28.0],
        [balanceImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:26.0],
        [balanceImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-26.0],
        [balanceImageView.heightAnchor constraintEqualToAnchor:balanceImageView.widthAnchor multiplier:258.0 / 969.0],

        [balanceValueLabel.leadingAnchor constraintEqualToAnchor:balanceImageView.leadingAnchor constant:46.0],
        [balanceValueLabel.topAnchor constraintEqualToAnchor:balanceImageView.topAnchor constant:20.0],
        [balanceTitleLabel.leadingAnchor constraintEqualToAnchor:balanceValueLabel.leadingAnchor],
        [balanceTitleLabel.topAnchor constraintEqualToAnchor:balanceValueLabel.bottomAnchor constant:1.0]
    ]];
}

- (UILabel *)yk_countLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:23.0 weight:UIFontWeightBold];
    return label;
}

- (UILabel *)yk_captionLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = [UIColor colorWithWhite:1.0 alpha:0.76];
    label.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    return label;
}

- (void)yk_setupSegments {
    UIView *containerView = [[UIView alloc] init];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:containerView];

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.distribution = UIStackViewDistributionFillEqually;
    [containerView addSubview:stackView];

    for (NSInteger index = 0; index < self.segmentTitles.count; index++) {
        YKMineSegmentButton *button = [[YKMineSegmentButton alloc] initWithTitle:self.segmentTitles[index]];
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
    [containerView addSubview:indicatorView];
    self.indicatorView = indicatorView;
    self.indicatorLeadingConstraint = [indicatorView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:0.0];
    self.indicatorWidthConstraint = [indicatorView.widthAnchor constraintEqualToConstant:170.0];

    [NSLayoutConstraint activateConstraints:@[
        [containerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:366.0],
        [containerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28.0],
        [containerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-28.0],
        [containerView.heightAnchor constraintEqualToConstant:58.0],

        [stackView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
        [stackView.heightAnchor constraintEqualToConstant:40.0],

        self.indicatorLeadingConstraint,
        [indicatorView.topAnchor constraintEqualToAnchor:stackView.bottomAnchor constant:4.0],
        self.indicatorWidthConstraint,
        [indicatorView.heightAnchor constraintEqualToConstant:4.0]
    ]];
}

- (void)yk_setupContentScrollView {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.delegate = self;
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:scrollView];
    self.contentScrollView = scrollView;

    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];

    UICollectionView *postsCollectionView = [self yk_collectionViewWithTag:0];
    UICollectionView *collectionsCollectionView = [self yk_collectionViewWithTag:1];
    [contentView addSubview:postsCollectionView];
    [contentView addSubview:collectionsCollectionView];
    self.postsCollectionView = postsCollectionView;
    self.collectionsCollectionView = collectionsCollectionView;

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:426.0],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-92.0],

        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.heightAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.heightAnchor],

        [postsCollectionView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [postsCollectionView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [postsCollectionView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
        [postsCollectionView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],

        [collectionsCollectionView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [collectionsCollectionView.leadingAnchor constraintEqualToAnchor:postsCollectionView.trailingAnchor],
        [collectionsCollectionView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
        [collectionsCollectionView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],
        [collectionsCollectionView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor]
    ]];
}

- (UICollectionView *)yk_collectionViewWithTag:(NSInteger)tag {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumLineSpacing = tag == 0 ? 18.0 : 14.0;
    layout.minimumInteritemSpacing = 14.0;

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.tag = tag;
    collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    if (tag == 0) {
        [collectionView registerClass:YKMinePostCell.class forCellWithReuseIdentifier:@"YKMinePostCell"];
    } else {
        [collectionView registerClass:YKMineCollectionCell.class forCellWithReuseIdentifier:@"YKMineCollectionCell"];
    }
    return collectionView;
}

- (void)yk_segmentButtonTapped:(YKMineSegmentButton *)sender {
    self.selectedIndex = sender.tag;
    CGFloat targetX = CGRectGetWidth(self.contentScrollView.bounds) * sender.tag;
    [self.contentScrollView setContentOffset:CGPointMake(targetX, 0.0) animated:YES];
    [UIView animateWithDuration:0.22 animations:^{
        [self yk_updateSelectionWithProgress:(CGFloat)sender.tag];
        [self.view layoutIfNeeded];
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return collectionView.tag == 0 ? 3 : 8;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UIColor *color = self.itemColors[indexPath.item % self.itemColors.count];
    if (collectionView.tag == 0) {
        YKMinePostCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YKMinePostCell" forIndexPath:indexPath];
        [cell configureWithColor:color];
        return cell;
    }

    YKMineCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YKMineCollectionCell" forIndexPath:indexPath];
    [cell configureWithColor:color];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = CGRectGetWidth(collectionView.bounds);
    if (collectionView.tag == 0) {
        CGFloat itemWidth = width - 52.0;
        return CGSizeMake(itemWidth, floor(itemWidth * 526.0 / 327.0));
    }

    CGFloat itemWidth = floor((width - 28.0 * 2.0 - 14.0) / 2.0);
    return CGSizeMake(itemWidth, itemWidth * 1.09);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return collectionView.tag == 0 ? UIEdgeInsetsMake(0.0, 26.0, 18.0, 26.0) : UIEdgeInsetsMake(0.0, 28.0, 18.0, 28.0);
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
    if (scrollView == self.contentScrollView) {
        CGFloat width = CGRectGetWidth(scrollView.bounds);
        self.selectedIndex = width > 0.0 ? (NSInteger)lround(scrollView.contentOffset.x / width) : 0;
        [self yk_updateSelectionWithProgress:(CGFloat)self.selectedIndex];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView == self.contentScrollView) {
        CGFloat width = CGRectGetWidth(scrollView.bounds);
        self.selectedIndex = width > 0.0 ? (NSInteger)lround(scrollView.contentOffset.x / width) : self.selectedIndex;
        [self yk_updateSelectionWithProgress:(CGFloat)self.selectedIndex];
    }
}

- (void)yk_updateSelectionWithProgress:(CGFloat)progress {
    CGFloat boundedProgress = MIN(MAX(progress, 0.0), 1.0);
    [self.segmentButtons[0] setSelectionProgress:1.0 - boundedProgress];
    [self.segmentButtons[1] setSelectionProgress:boundedProgress];

    YKMineSegmentButton *firstButton = self.segmentButtons.firstObject;
    YKMineSegmentButton *secondButton = self.segmentButtons.lastObject;
    CGFloat firstX = CGRectGetMinX(firstButton.frame);
    CGFloat secondX = CGRectGetMinX(secondButton.frame);
    CGFloat firstWidth = CGRectGetWidth(firstButton.bounds);
    CGFloat secondWidth = CGRectGetWidth(secondButton.bounds);
    self.indicatorLeadingConstraint.constant = firstX + (secondX - firstX) * boundedProgress;
    self.indicatorWidthConstraint.constant = firstWidth + (secondWidth - firstWidth) * boundedProgress;
}

@end
