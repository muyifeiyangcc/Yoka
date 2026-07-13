//
//  YKFindViewController.m
//  Yoka
//

#import "YKFindViewController.h"
#import "YKFindDetailViewController.h"

@interface YKFindSegmentButton : UIControl

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, assign, readonly) CGFloat selectedTextWidth;

- (instancetype)initWithTitle:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (void)setSelectionProgress:(CGFloat)progress;
- (void)setActive:(BOOL)active animated:(BOOL)animated;

@end

@interface YKFindSegmentButton ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) CGFloat selectedTextWidth;
@property (nonatomic, strong) UILabel *normalLabel;
@property (nonatomic, strong) UIView *gradientTextView;
@property (nonatomic, strong) UILabel *gradientMaskLabel;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, assign) BOOL active;

@end

@implementation YKFindSegmentButton

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
        (__bridge id)UIColor.whiteColor.CGColor,
        (__bridge id)[UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:1.0].CGColor
    ];
    [gradientTextView.layer addSublayer:gradientLayer];
    self.gradientLayer = gradientLayer;

    UILabel *gradientMaskLabel = [self yk_labelWithText:self.title font:selectedFont];
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

@class YKFindWaterfallLayout;

@protocol YKFindWaterfallLayoutDelegate <NSObject>

- (CGFloat)waterfallLayout:(YKFindWaterfallLayout *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath itemWidth:(CGFloat)itemWidth;

@end

@interface YKFindWaterfallLayout : UICollectionViewLayout

@property (nonatomic, weak) id<YKFindWaterfallLayoutDelegate> delegate;
@property (nonatomic, assign) NSInteger columnCount;
@property (nonatomic, assign) CGFloat columnSpacing;
@property (nonatomic, assign) CGFloat rowSpacing;
@property (nonatomic, assign) UIEdgeInsets sectionInset;

@end

@interface YKFindWaterfallLayout ()

@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *cachedAttributes;
@property (nonatomic, assign) CGSize contentSize;

@end

@implementation YKFindWaterfallLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        _columnCount = 2;
        _columnSpacing = 14.0;
        _rowSpacing = 14.0;
        _sectionInset = UIEdgeInsetsMake(0.0, 20.0, 18.0, 20.0);
        _cachedAttributes = [NSMutableArray array];
    }
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];
    [self.cachedAttributes removeAllObjects];

    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    if (itemCount <= 0 || self.columnCount <= 0) {
        self.contentSize = self.collectionView.bounds.size;
        return;
    }

    CGFloat contentWidth = CGRectGetWidth(self.collectionView.bounds) - self.sectionInset.left - self.sectionInset.right;
    CGFloat itemWidth = floor((contentWidth - self.columnSpacing * (CGFloat)(self.columnCount - 1)) / (CGFloat)self.columnCount);
    NSMutableArray<NSNumber *> *columnHeights = [NSMutableArray arrayWithCapacity:self.columnCount];
    for (NSInteger column = 0; column < self.columnCount; column++) {
        [columnHeights addObject:@(self.sectionInset.top)];
    }

    for (NSInteger item = 0; item < itemCount; item++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
        NSInteger targetColumn = 0;
        CGFloat minHeight = columnHeights.firstObject.doubleValue;
        for (NSInteger column = 1; column < self.columnCount; column++) {
            CGFloat height = columnHeights[column].doubleValue;
            if (height < minHeight) {
                minHeight = height;
                targetColumn = column;
            }
        }

        CGFloat itemHeight = [self.delegate waterfallLayout:self heightForItemAtIndexPath:indexPath itemWidth:itemWidth];
        CGFloat x = self.sectionInset.left + (itemWidth + self.columnSpacing) * (CGFloat)targetColumn;
        CGFloat y = minHeight;
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attributes.frame = CGRectMake(x, y, itemWidth, itemHeight);
        [self.cachedAttributes addObject:attributes];
        columnHeights[targetColumn] = @(CGRectGetMaxY(attributes.frame) + self.rowSpacing);
    }

    CGFloat maxHeight = columnHeights.firstObject.doubleValue;
    for (NSNumber *height in columnHeights) {
        maxHeight = MAX(maxHeight, height.doubleValue);
    }
    maxHeight = maxHeight - self.rowSpacing + self.sectionInset.bottom;
    self.contentSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), maxHeight);
}

- (CGSize)collectionViewContentSize {
    return self.contentSize;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray<UICollectionViewLayoutAttributes *> *visibleAttributes = [NSMutableArray array];
    for (UICollectionViewLayoutAttributes *attributes in self.cachedAttributes) {
        if (CGRectIntersectsRect(attributes.frame, rect)) {
            [visibleAttributes addObject:attributes];
        }
    }
    return visibleAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < self.cachedAttributes.count) {
        return self.cachedAttributes[indexPath.item];
    }
    return nil;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return !CGSizeEqualToSize(newBounds.size, self.collectionView.bounds.size);
}

@end

@interface YKFindDiscoverCell : UICollectionViewCell

- (void)configureWithName:(NSString *)name color:(UIColor *)color;

@end

@interface YKFindDiscoverCell ()

@property (nonatomic, strong) CAGradientLayer *overlayLayer;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UILabel *heartLabel;
@property (nonatomic, strong) UIButton *moreButton;

@end

@implementation YKFindDiscoverCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self yk_setupViews];
    }
    return self;
}

- (void)yk_setupViews {
    self.contentView.layer.cornerRadius = 12.0;
    self.contentView.layer.masksToBounds = YES;

    CAGradientLayer *overlayLayer = [CAGradientLayer layer];
    overlayLayer.colors = @[
        (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor,
        (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.66].CGColor
    ];
    overlayLayer.locations = @[@0.45, @1.0];
    [self.contentView.layer addSublayer:overlayLayer];
    self.overlayLayer = overlayLayer;

    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [moreButton setImage:[[UIImage imageNamed:@"nav_more"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [self.contentView addSubview:moreButton];
    self.moreButton = moreButton;

    UIImageView *avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarImageView.layer.cornerRadius = 10.0;
    avatarImageView.layer.masksToBounds = YES;
    [self.contentView addSubview:avatarImageView];
    self.avatarImageView = avatarImageView;

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightBold];
    [self.contentView addSubview:nameLabel];
    self.nameLabel = nameLabel;

    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.translatesAutoresizingMaskIntoConstraints = NO;
    descLabel.text = @"Feeling this look...";
    descLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.82];
    descLabel.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightRegular];
    [self.contentView addSubview:descLabel];
    self.descLabel = descLabel;

    UILabel *heartLabel = [[UILabel alloc] init];
    heartLabel.translatesAutoresizingMaskIntoConstraints = NO;
    heartLabel.text = @"+";
    heartLabel.textAlignment = NSTextAlignmentCenter;
    heartLabel.textColor = [UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:1.0];
    heartLabel.backgroundColor = UIColor.whiteColor;
    heartLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBlack];
    heartLabel.layer.cornerRadius = 12.0;
    heartLabel.layer.masksToBounds = YES;
    [self.contentView addSubview:heartLabel];
    self.heartLabel = heartLabel;

    [NSLayoutConstraint activateConstraints:@[
        [moreButton.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8.0],
        [moreButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8.0],
        [moreButton.widthAnchor constraintEqualToConstant:28.0],
        [moreButton.heightAnchor constraintEqualToConstant:28.0],

        [avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:10.0],
        [avatarImageView.bottomAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:2.0],
        [avatarImageView.widthAnchor constraintEqualToConstant:20.0],
        [avatarImageView.heightAnchor constraintEqualToConstant:20.0],

        [nameLabel.leadingAnchor constraintEqualToAnchor:avatarImageView.trailingAnchor constant:5.0],
        [nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:heartLabel.leadingAnchor constant:-8.0],
        [nameLabel.bottomAnchor constraintEqualToAnchor:descLabel.topAnchor constant:-2.0],

        [descLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:10.0],
        [descLabel.trailingAnchor constraintLessThanOrEqualToAnchor:heartLabel.leadingAnchor constant:-8.0],
        [descLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12.0],

        [heartLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8.0],
        [heartLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8.0],
        [heartLabel.widthAnchor constraintEqualToConstant:24.0],
        [heartLabel.heightAnchor constraintEqualToConstant:24.0]
    ]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.overlayLayer.frame = self.contentView.bounds;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.nameLabel.text = nil;
    self.contentView.backgroundColor = UIColor.clearColor;
}

- (void)configureWithName:(NSString *)name color:(UIColor *)color {
    self.nameLabel.text = name;
    self.contentView.backgroundColor = color;
}

@end

@interface YKFindViewController () <UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, YKFindWaterfallLayoutDelegate>

@property (nonatomic, copy) NSArray<NSString *> *categoryTitles;
@property (nonatomic, strong) UIScrollView *segmentScrollView;
@property (nonatomic, strong) UIStackView *segmentStackView;
@property (nonatomic, strong) NSMutableArray<YKFindSegmentButton *> *segmentButtons;
@property (nonatomic, strong) UIView *tabUnderlineView;
@property (nonatomic, strong) CAGradientLayer *tabUnderlineGradientLayer;
@property (nonatomic, strong) NSLayoutConstraint *tabUnderlineLeadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *tabUnderlineWidthConstraint;
@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, strong) NSMutableArray<UICollectionView *> *collectionViews;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *discoverItems;
@property (nonatomic, assign) NSInteger selectedContentIndex;

@end

@implementation YKFindViewController

- (void)yk_configurePage {
    [super yk_configurePage];

    self.categoryTitles = @[@"Outfit", @"Makeup", @"Hair", @"Jewelry", @"Shoes"];
    self.segmentButtons = [NSMutableArray arrayWithCapacity:self.categoryTitles.count];
    self.collectionViews = [NSMutableArray arrayWithCapacity:self.categoryTitles.count];
    self.discoverItems = [self yk_makeDiscoverItems];
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
}

- (void)yk_setupHeaderView {
    UIImageView *titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Discover"]];
    titleImageView.translatesAutoresizingMaskIntoConstraints = NO;
    titleImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:titleImageView];

    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [moreButton setImage:[[UIImage imageNamed:@"nav_more"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [self.view addSubview:moreButton];

    [NSLayoutConstraint activateConstraints:@[
        [titleImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24.0],
        [titleImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28.0],
        [titleImageView.trailingAnchor constraintLessThanOrEqualToAnchor:moreButton.leadingAnchor constant:-12.0],
        [titleImageView.widthAnchor constraintEqualToConstant:108.0],
        [titleImageView.heightAnchor constraintEqualToConstant:30.0],

        [moreButton.centerYAnchor constraintEqualToAnchor:titleImageView.centerYAnchor],
        [moreButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-26.0],
        [moreButton.widthAnchor constraintEqualToConstant:32.0],
        [moreButton.heightAnchor constraintEqualToConstant:32.0]
    ]];
}

- (void)yk_setupSegmentTabs {
    UIScrollView *segmentScrollView = [[UIScrollView alloc] init];
    segmentScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    segmentScrollView.showsHorizontalScrollIndicator = NO;
    segmentScrollView.showsVerticalScrollIndicator = NO;
    segmentScrollView.backgroundColor = UIColor.clearColor;
    segmentScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:segmentScrollView];
    self.segmentScrollView = segmentScrollView;

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 14.0;
    [segmentScrollView addSubview:stackView];
    self.segmentStackView = stackView;

    for (NSInteger index = 0; index < self.categoryTitles.count; index++) {
        YKFindSegmentButton *button = [[YKFindSegmentButton alloc] initWithTitle:self.categoryTitles[index]];
        button.tag = index;
        [button addTarget:self action:@selector(yk_segmentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [stackView addArrangedSubview:button];
        [self.segmentButtons addObject:button];

        [NSLayoutConstraint activateConstraints:@[
            [button.heightAnchor constraintEqualToConstant:32.0]
        ]];
    }

    UIView *underlineView = [[UIView alloc] init];
    underlineView.translatesAutoresizingMaskIntoConstraints = NO;
    underlineView.layer.cornerRadius = 2.0;
    underlineView.layer.masksToBounds = YES;
    [segmentScrollView addSubview:underlineView];
    self.tabUnderlineView = underlineView;

    CAGradientLayer *underlineGradientLayer = [CAGradientLayer layer];
    underlineGradientLayer.startPoint = CGPointMake(0.0, 0.5);
    underlineGradientLayer.endPoint = CGPointMake(1.0, 0.5);
    underlineGradientLayer.colors = @[
        (__bridge id)UIColor.whiteColor.CGColor,
        (__bridge id)[UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:1.0 green:0.0 blue:242.0 / 255.0 alpha:0.0].CGColor
    ];
    underlineGradientLayer.locations = @[@0.0, @0.5, @0.5, @1.0];
    [underlineView.layer addSublayer:underlineGradientLayer];
    self.tabUnderlineGradientLayer = underlineGradientLayer;

    self.tabUnderlineLeadingConstraint = [underlineView.leadingAnchor constraintEqualToAnchor:segmentScrollView.contentLayoutGuide.leadingAnchor constant:0.0];
    self.tabUnderlineWidthConstraint = [underlineView.widthAnchor constraintEqualToConstant:60.0];

    [NSLayoutConstraint activateConstraints:@[
        [segmentScrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:78.0],
        [segmentScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [segmentScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [segmentScrollView.heightAnchor constraintEqualToConstant:42.0],

        [stackView.topAnchor constraintEqualToAnchor:segmentScrollView.contentLayoutGuide.topAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:segmentScrollView.contentLayoutGuide.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:segmentScrollView.contentLayoutGuide.trailingAnchor constant:-20.0],
        [stackView.heightAnchor constraintEqualToAnchor:segmentScrollView.frameLayoutGuide.heightAnchor],

        self.tabUnderlineLeadingConstraint,
        [underlineView.topAnchor constraintEqualToAnchor:stackView.topAnchor constant:32.0],
        self.tabUnderlineWidthConstraint,
        [underlineView.heightAnchor constraintEqualToConstant:4.0]
    ]];
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

    NSMutableArray<UIView *> *pages = [NSMutableArray arrayWithCapacity:self.categoryTitles.count];
    for (NSInteger index = 0; index < self.categoryTitles.count; index++) {
        UIView *pageView = [self yk_categoryPageViewWithIndex:index];
        [contentView addSubview:pageView];
        [pages addObject:pageView];
    }

    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray arrayWithArray:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.segmentScrollView.bottomAnchor constant:10.0],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-92.0],

        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.heightAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.heightAnchor]
    ]];

    UIView *previousPageView = nil;
    for (UIView *pageView in pages) {
        [constraints addObject:[pageView.topAnchor constraintEqualToAnchor:contentView.topAnchor]];
        [constraints addObject:[pageView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor]];
        [constraints addObject:[pageView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor]];

        if (previousPageView) {
            [constraints addObject:[pageView.leadingAnchor constraintEqualToAnchor:previousPageView.trailingAnchor]];
        } else {
            [constraints addObject:[pageView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor]];
        }
        previousPageView = pageView;
    }
    if (previousPageView) {
        [constraints addObject:[previousPageView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor]];
    }

    [NSLayoutConstraint activateConstraints:constraints];
}

- (UIView *)yk_categoryPageViewWithIndex:(NSInteger)index {
    YKFindWaterfallLayout *layout = [[YKFindWaterfallLayout alloc] init];
    layout.delegate = self;
    layout.columnCount = 2;
    layout.columnSpacing = 14.0;
    layout.rowSpacing = 14.0;
    layout.sectionInset = UIEdgeInsetsMake(0.0, 20.0, 18.0, 20.0);

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.tag = index;
    collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [collectionView registerClass:YKFindDiscoverCell.class forCellWithReuseIdentifier:@"YKFindDiscoverCell"];
    [self.collectionViews addObject:collectionView];
    return collectionView;
}

- (void)yk_segmentButtonTapped:(YKFindSegmentButton *)sender {
    [self yk_selectContentIndex:sender.tag animated:YES];
}

- (void)yk_selectContentIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index >= (NSInteger)self.segmentButtons.count) {
        return;
    }

    self.selectedContentIndex = index;
    [self yk_updateSegmentSelectionAnimated:animated];

    CGFloat targetX = CGRectGetWidth(self.contentScrollView.bounds) * index;
    [self.contentScrollView setContentOffset:CGPointMake(targetX, 0.0) animated:animated];
}

- (void)yk_updateSegmentSelectionAnimated:(BOOL)animated {
    if (self.segmentButtons.count == 0) {
        return;
    }

    YKFindSegmentButton *selectedButton = self.segmentButtons[self.selectedContentIndex];
    [self.segmentButtons enumerateObjectsUsingBlock:^(YKFindSegmentButton *button, NSUInteger idx, BOOL *stop) {
        [button setActive:(NSInteger)idx == self.selectedContentIndex animated:animated];
    }];

    self.tabUnderlineLeadingConstraint.constant = CGRectGetMinX(selectedButton.frame);
    self.tabUnderlineWidthConstraint.constant = CGRectGetWidth(selectedButton.bounds);

    void (^changes)(void) = ^{
        [self.segmentScrollView layoutIfNeeded];
    };

    if (animated) {
        [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:changes completion:nil];
    } else {
        changes();
    }

    [self yk_scrollSelectedSegmentButtonIntoView:selectedButton animated:animated];
}

- (void)yk_scrollSelectedSegmentButtonIntoView:(YKFindSegmentButton *)button animated:(BOOL)animated {
    CGRect buttonRect = [button.superview convertRect:button.frame toView:self.segmentScrollView];
    CGRect targetRect = CGRectInset(buttonRect, -28.0, 0.0);
    [self.segmentScrollView scrollRectToVisible:targetRect animated:animated];
}

- (void)yk_scrollSegmentButtonAtIndexIntoView:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index >= (NSInteger)self.segmentButtons.count) {
        return;
    }
    [self yk_scrollSelectedSegmentButtonIntoView:self.segmentButtons[index] animated:animated];
}

- (void)yk_updateSegmentScrollOffsetWithProgress:(CGFloat)progress {
    if (self.segmentButtons.count == 0) {
        return;
    }

    [self.segmentScrollView layoutIfNeeded];
    CGFloat maxOffsetX = MAX(0.0, self.segmentScrollView.contentSize.width - CGRectGetWidth(self.segmentScrollView.bounds));
    if (maxOffsetX <= 0.0) {
        return;
    }

    NSInteger maxIndex = (NSInteger)self.segmentButtons.count - 1;
    CGFloat boundedProgress = MIN(MAX(progress, 0.0), (CGFloat)maxIndex);
    CGFloat targetOffsetX = 0.0;

    if (maxIndex > 0) {
        targetOffsetX = maxOffsetX * (boundedProgress / (CGFloat)maxIndex);
    }

    targetOffsetX = MIN(MAX(targetOffsetX, 0.0), maxOffsetX);
    CGPoint currentOffset = self.segmentScrollView.contentOffset;
    if (fabs(currentOffset.x - targetOffsetX) > 0.5) {
        self.segmentScrollView.contentOffset = CGPointMake(targetOffsetX, currentOffset.y);
    }
}

- (NSArray<NSDictionary<NSString *, id> *> *)yk_makeDiscoverItems {
    NSArray<NSString *> *names = @[@"Freya", @"Lumi", @"Alina", @"Bodhi", @"Amelia", @"Stellan"];
    NSArray<UIColor *> *colors = @[
        [UIColor colorWithRed:0.38 green:0.32 blue:0.58 alpha:1.0],
        [UIColor colorWithRed:0.58 green:0.20 blue:0.28 alpha:1.0],
        [UIColor colorWithRed:0.20 green:0.16 blue:0.24 alpha:1.0],
        [UIColor colorWithRed:0.47 green:0.64 blue:0.82 alpha:1.0],
        [UIColor colorWithRed:0.52 green:0.34 blue:0.22 alpha:1.0],
        [UIColor colorWithRed:0.18 green:0.18 blue:0.28 alpha:1.0]
    ];
    NSArray<NSNumber *> *heightRatios = @[@1.38, @1.05, @1.45, @1.28, @1.18, @1.36, @1.52, @1.12, @1.32, @1.24];

    NSMutableArray<NSDictionary<NSString *, id> *> *items = [NSMutableArray arrayWithCapacity:30];
    for (NSInteger index = 0; index < 30; index++) {
        [items addObject:@{
            @"name": names[index % names.count],
            @"color": colors[index % colors.count],
            @"ratio": heightRatios[index % heightRatios.count]
        }];
    }
    return items;
}

- (NSDictionary<NSString *, id> *)yk_itemForCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath {
    NSInteger offset = collectionView.tag * 3;
    NSInteger itemIndex = (indexPath.item + offset) % self.discoverItems.count;
    return self.discoverItems[itemIndex];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.discoverItems.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YKFindDiscoverCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YKFindDiscoverCell" forIndexPath:indexPath];
    NSDictionary<NSString *, id> *item = [self yk_itemForCollectionView:collectionView indexPath:indexPath];
    [cell configureWithName:item[@"name"] color:item[@"color"]];
    return cell;
}

- (CGFloat)waterfallLayout:(YKFindWaterfallLayout *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath itemWidth:(CGFloat)itemWidth {
    UICollectionView *collectionView = layout.collectionView;
    NSDictionary<NSString *, id> *item = [self yk_itemForCollectionView:collectionView indexPath:indexPath];
    NSNumber *ratio = item[@"ratio"];
    return floor(itemWidth * ratio.doubleValue);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary<NSString *, id> *item = [self yk_itemForCollectionView:collectionView indexPath:indexPath];
    YKFindDetailViewController *detailViewController = [[YKFindDetailViewController alloc] initWithUserName:item[@"name"]];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.contentScrollView) {
        return;
    }

    CGFloat width = CGRectGetWidth(scrollView.bounds);
    if (width <= 0.0 || self.segmentButtons.count == 0) {
        return;
    }

    CGFloat rawProgress = scrollView.contentOffset.x / width;
    CGFloat boundedProgress = MIN(MAX(rawProgress, 0.0), (CGFloat)self.segmentButtons.count - 1.0);
    NSInteger leftIndex = (NSInteger)floor(boundedProgress);
    NSInteger maxIndex = (NSInteger)self.segmentButtons.count - 1;
    NSInteger rightIndex = MIN(leftIndex + 1, maxIndex);
    CGFloat localProgress = boundedProgress - (CGFloat)leftIndex;

    [self.segmentButtons enumerateObjectsUsingBlock:^(YKFindSegmentButton *button, NSUInteger idx, BOOL *stop) {
        CGFloat progress = 0.0;
        if ((NSInteger)idx == leftIndex) {
            progress = 1.0 - localProgress;
        } else if ((NSInteger)idx == rightIndex) {
            progress = localProgress;
        }
        [button setSelectionProgress:progress];
    }];

    [self yk_updateUnderlineFromIndex:leftIndex toIndex:rightIndex progress:localProgress];
    [self yk_updateSegmentScrollOffsetWithProgress:boundedProgress];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self yk_syncSegmentWithScrollView:scrollView animated:YES];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self yk_syncSegmentWithScrollView:scrollView animated:YES];
}

- (void)yk_syncSegmentWithScrollView:(UIScrollView *)scrollView animated:(BOOL)animated {
    if (scrollView != self.contentScrollView) {
        return;
    }

    CGFloat width = CGRectGetWidth(scrollView.bounds);
    if (width <= 0.0) {
        return;
    }

    NSInteger index = (NSInteger)lround(scrollView.contentOffset.x / width);
    NSInteger maxIndex = (NSInteger)self.segmentButtons.count - 1;
    index = MAX(0, MIN(index, maxIndex));
    if (index == self.selectedContentIndex) {
        return;
    }

    self.selectedContentIndex = index;
    [self yk_updateSegmentSelectionAnimated:animated];
}

- (void)yk_updateUnderlineFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress {
    if (fromIndex < 0 || toIndex >= (NSInteger)self.segmentButtons.count) {
        return;
    }

    YKFindSegmentButton *fromButton = self.segmentButtons[fromIndex];
    YKFindSegmentButton *toButton = self.segmentButtons[toIndex];
    CGFloat boundedProgress = MIN(MAX(progress, 0.0), 1.0);
    CGFloat startX = CGRectGetMinX(fromButton.frame);
    CGFloat endX = CGRectGetMinX(toButton.frame);
    CGFloat startWidth = CGRectGetWidth(fromButton.bounds);
    CGFloat endWidth = CGRectGetWidth(toButton.bounds);

    self.tabUnderlineLeadingConstraint.constant = startX + (endX - startX) * boundedProgress;
    self.tabUnderlineWidthConstraint.constant = startWidth + (endWidth - startWidth) * boundedProgress;
    [self.segmentScrollView layoutIfNeeded];
}

@end
