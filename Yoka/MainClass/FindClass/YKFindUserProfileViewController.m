//
//  YKFindUserProfileViewController.m
//  Yoka
//

#import "YKFindUserProfileViewController.h"

@interface YKFindUserProfileCell : UICollectionViewCell

- (void)configureWithColor:(UIColor *)color;

@end

@interface YKFindUserProfileCell ()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation YKFindUserProfileCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.layer.cornerRadius = 10.0;
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
        (__bridge id)[UIColor colorWithRed:0.12 green:0.10 blue:0.16 alpha:1.0].CGColor
    ];
}

@end

@interface YKFindUserProfileSegmentButton : UIControl

@property (nonatomic, strong) UILabel *titleLabel;

- (instancetype)initWithTitle:(NSString *)title;
- (void)setSelectedProgress:(CGFloat)progress;

@end

@implementation YKFindUserProfileSegmentButton

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.text = title;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:titleLabel];
        self.titleLabel = titleLabel;

        [NSLayoutConstraint activateConstraints:@[
            [titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
            [titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [titleLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
        [self setSelectedProgress:0.0];
    }
    return self;
}

- (void)setSelectedProgress:(CGFloat)progress {
    CGFloat boundedProgress = MIN(MAX(progress, 0.0), 1.0);
    self.titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.48 + boundedProgress * 0.52];
    self.titleLabel.font = [UIFont systemFontOfSize:18.0 + boundedProgress * 2.0
                                             weight:boundedProgress > 0.5 ? UIFontWeightBold : UIFontWeightRegular];
}

@end

@interface YKFindUserProfileViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

@property (nonatomic, copy) NSString *userName;
@property (nonatomic, strong) NSArray<UIColor *> *itemColors;
@property (nonatomic, strong) NSMutableArray<YKFindUserProfileSegmentButton *> *segmentButtons;
@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) NSLayoutConstraint *indicatorLeadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *indicatorWidthConstraint;
@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

@implementation YKFindUserProfileViewController

- (instancetype)initWithUserName:(NSString *)userName {
    self = [super init];
    if (self) {
        _userName = userName.length > 0 ? [userName copy] : @"Freya";
    }
    return self;
}

- (void)yk_configurePage {
    [super yk_configurePage];
    self.selectedIndex = 1;
    self.segmentButtons = [NSMutableArray arrayWithCapacity:2];
    self.itemColors = @[
        [UIColor colorWithRed:0.20 green:0.12 blue:0.18 alpha:1.0],
        [UIColor colorWithRed:0.55 green:0.42 blue:0.31 alpha:1.0],
        [UIColor colorWithRed:0.34 green:0.24 blue:0.22 alpha:1.0],
        [UIColor colorWithRed:0.13 green:0.14 blue:0.18 alpha:1.0],
        [UIColor colorWithRed:0.54 green:0.28 blue:0.32 alpha:1.0],
        [UIColor colorWithRed:0.18 green:0.25 blue:0.35 alpha:1.0]
    ];
    [self yk_setupViews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!self.contentScrollView.isDragging && !self.contentScrollView.isDecelerating) {
        self.contentScrollView.contentOffset = CGPointMake(CGRectGetWidth(self.contentScrollView.bounds) * self.selectedIndex, 0.0);
        [self yk_updateSelectionWithProgress:self.selectedIndex];
    }
}

- (void)yk_setupViews {
    [self yk_addBackButton];

    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [moreButton setImage:[[UIImage imageNamed:@"detail_more_button"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [self.view addSubview:moreButton];

    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.layer.cornerRadius = 40.0;
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
    nameLabel.text = self.userName;
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightBold];
    [self.view addSubview:nameLabel];

    UIButton *followButton = [self yk_outlineButtonWithTitle:@"+Follow"];
    UIButton *chatButton = [self yk_filledButtonWithTitle:@"Chat"];
    [self.view addSubview:followButton];
    [self.view addSubview:chatButton];

    UIView *segmentContainerView = [[UIView alloc] init];
    segmentContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:segmentContainerView];

    UIStackView *segmentStackView = [[UIStackView alloc] init];
    segmentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    segmentStackView.axis = UILayoutConstraintAxisHorizontal;
    segmentStackView.distribution = UIStackViewDistributionFillEqually;
    [segmentContainerView addSubview:segmentStackView];

    NSArray<NSString *> *titles = @[@"Posts", @"Collections"];
    for (NSInteger index = 0; index < titles.count; index++) {
        YKFindUserProfileSegmentButton *button = [[YKFindUserProfileSegmentButton alloc] initWithTitle:titles[index]];
        button.tag = index;
        [button addTarget:self action:@selector(yk_segmentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [segmentStackView addArrangedSubview:button];
        [self.segmentButtons addObject:button];
    }

    UIView *indicatorView = [[UIView alloc] init];
    indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    indicatorView.backgroundColor = UIColor.whiteColor;
    indicatorView.layer.cornerRadius = 2.0;
    [segmentContainerView addSubview:indicatorView];
    self.indicatorView = indicatorView;
    self.indicatorLeadingConstraint = [indicatorView.leadingAnchor constraintEqualToAnchor:segmentContainerView.leadingAnchor];
    self.indicatorWidthConstraint = [indicatorView.widthAnchor constraintEqualToConstant:160.0];

    [self yk_setupContentScrollView];

    [NSLayoutConstraint activateConstraints:@[
        [moreButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
        [moreButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-22.0],
        [moreButton.widthAnchor constraintEqualToConstant:36.0],
        [moreButton.heightAnchor constraintEqualToConstant:36.0],

        [avatarImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:66.0],
        [avatarImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [avatarImageView.widthAnchor constraintEqualToConstant:80.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:80.0],

        [followersValueLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:24.0],
        [followersValueLabel.topAnchor constraintEqualToAnchor:avatarImageView.topAnchor constant:14.0],
        [followersTitleLabel.leadingAnchor constraintEqualToAnchor:followersValueLabel.leadingAnchor],
        [followersTitleLabel.topAnchor constraintEqualToAnchor:followersValueLabel.bottomAnchor constant:3.0],

        [followingValueLabel.leadingAnchor constraintEqualToAnchor:followersValueLabel.trailingAnchor constant:58.0],
        [followingValueLabel.centerYAnchor constraintEqualToAnchor:followersValueLabel.centerYAnchor],
        [followingTitleLabel.leadingAnchor constraintEqualToAnchor:followingValueLabel.leadingAnchor],
        [followingTitleLabel.topAnchor constraintEqualToAnchor:followingValueLabel.bottomAnchor constant:3.0],

        [nameLabel.topAnchor constraintEqualToAnchor:avatarImageView.bottomAnchor constant:8.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.leadingAnchor constant:4.0],

        [followButton.centerYAnchor constraintEqualToAnchor:nameLabel.centerYAnchor],
        [followButton.leadingAnchor constraintEqualToAnchor:followersValueLabel.leadingAnchor],
        [followButton.widthAnchor constraintEqualToConstant:80.0],
        [followButton.heightAnchor constraintEqualToConstant:28.0],

        [chatButton.centerYAnchor constraintEqualToAnchor:followButton.centerYAnchor],
        [chatButton.leadingAnchor constraintEqualToAnchor:followButton.trailingAnchor constant:12.0],
        [chatButton.widthAnchor constraintEqualToConstant:70.0],
        [chatButton.heightAnchor constraintEqualToConstant:28.0],

        [segmentContainerView.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:28.0],
        [segmentContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18.0],
        [segmentContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-18.0],
        [segmentContainerView.heightAnchor constraintEqualToConstant:46.0],

        [segmentStackView.topAnchor constraintEqualToAnchor:segmentContainerView.topAnchor],
        [segmentStackView.leadingAnchor constraintEqualToAnchor:segmentContainerView.leadingAnchor],
        [segmentStackView.trailingAnchor constraintEqualToAnchor:segmentContainerView.trailingAnchor],
        [segmentStackView.heightAnchor constraintEqualToConstant:34.0],

        self.indicatorLeadingConstraint,
        [indicatorView.topAnchor constraintEqualToAnchor:segmentStackView.bottomAnchor constant:4.0],
        self.indicatorWidthConstraint,
        [indicatorView.heightAnchor constraintEqualToConstant:4.0]
    ]];

    [self yk_updateSelectionWithProgress:self.selectedIndex];
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

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:236.0],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.heightAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.heightAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor multiplier:2.0],

        [postsCollectionView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [postsCollectionView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [postsCollectionView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],
        [postsCollectionView.heightAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.heightAnchor],

        [collectionsCollectionView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [collectionsCollectionView.leadingAnchor constraintEqualToAnchor:postsCollectionView.trailingAnchor],
        [collectionsCollectionView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],
        [collectionsCollectionView.heightAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.heightAnchor],
        [collectionsCollectionView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor]
    ]];
}

- (UICollectionView *)yk_collectionViewWithTag:(NSInteger)tag {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumLineSpacing = 8.0;
    layout.minimumInteritemSpacing = 8.0;
    layout.sectionInset = UIEdgeInsetsMake(0.0, 18.0, 24.0, 18.0);

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.tag = tag;
    [collectionView registerClass:YKFindUserProfileCell.class forCellWithReuseIdentifier:@"YKFindUserProfileCell"];
    return collectionView;
}

- (UIButton *)yk_outlineButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
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

- (void)yk_segmentButtonTapped:(YKFindUserProfileSegmentButton *)sender {
    self.selectedIndex = sender.tag;
    [self.contentScrollView setContentOffset:CGPointMake(CGRectGetWidth(self.contentScrollView.bounds) * sender.tag, 0.0) animated:YES];
    [self yk_updateSelectionWithProgress:sender.tag];
}

- (void)yk_updateSelectionWithProgress:(CGFloat)progress {
    if (self.segmentButtons.count == 0) {
        return;
    }
    CGFloat segmentWidth = CGRectGetWidth(self.view.bounds) - 36.0;
    CGFloat buttonWidth = segmentWidth / 2.0;
    CGFloat boundedProgress = MIN(MAX(progress, 0.0), 1.0);
    self.indicatorLeadingConstraint.constant = buttonWidth * boundedProgress;
    self.indicatorWidthConstraint.constant = buttonWidth;

    for (NSInteger index = 0; index < self.segmentButtons.count; index++) {
        CGFloat distance = fabs(boundedProgress - index);
        [self.segmentButtons[index] setSelectedProgress:1.0 - MIN(distance, 1.0)];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 6;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YKFindUserProfileCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YKFindUserProfileCell" forIndexPath:indexPath];
    UIColor *color = self.itemColors[(indexPath.item + collectionView.tag) % self.itemColors.count];
    [cell configureWithColor:color];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = floor((CGRectGetWidth(collectionView.bounds) - 44.0) * 0.5);
    return CGSizeMake(width, width * 1.18);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.contentScrollView && CGRectGetWidth(scrollView.bounds) > 0.0) {
        [self yk_updateSelectionWithProgress:scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds)];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.contentScrollView && CGRectGetWidth(scrollView.bounds) > 0.0) {
        self.selectedIndex = (NSInteger)lround(scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds));
        [self yk_updateSelectionWithProgress:self.selectedIndex];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView == self.contentScrollView && CGRectGetWidth(scrollView.bounds) > 0.0) {
        self.selectedIndex = (NSInteger)lround(scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds));
        [self yk_updateSelectionWithProgress:self.selectedIndex];
    }
}

@end
