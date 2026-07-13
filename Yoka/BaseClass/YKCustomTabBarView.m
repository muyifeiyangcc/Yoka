//
//  YKCustomTabBarView.m
//  Yoka
//

#import "YKCustomTabBarView.h"
#import "YKCustomTabBarItem.h"

@interface YKCustomTabBarView ()

@property (nonatomic, strong) NSArray<YKCustomTabBarItem *> *items;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIButton *publishButton;
@property (nonatomic, strong) CAShapeLayer *backgroundShapeLayer;
@property (nonatomic, strong) CAShapeLayer *borderShapeLayer;

@end

@implementation YKCustomTabBarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _selectedIndex = 0;
        [self yk_setupViews];
        [self yk_updateSelection];
    }
    return self;
}

- (void)yk_setupViews {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = UIColor.clearColor;

    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.backgroundColor = UIColor.clearColor;
    [self addSubview:contentView];
    self.contentView = contentView;

    CAShapeLayer *backgroundShapeLayer = [CAShapeLayer layer];
    backgroundShapeLayer.fillColor = [UIColor colorWithRed:0.93 green:0.34 blue:0.95 alpha:0.92].CGColor;
    [contentView.layer addSublayer:backgroundShapeLayer];
    self.backgroundShapeLayer = backgroundShapeLayer;

    CAShapeLayer *borderShapeLayer = [CAShapeLayer layer];
    borderShapeLayer.fillColor = UIColor.clearColor.CGColor;
    borderShapeLayer.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.92].CGColor;
    borderShapeLayer.lineWidth = 1.5;
    [contentView.layer addSublayer:borderShapeLayer];
    self.borderShapeLayer = borderShapeLayer;

    UIStackView *leftStackView = [[UIStackView alloc] init];
    leftStackView.translatesAutoresizingMaskIntoConstraints = NO;
    leftStackView.axis = UILayoutConstraintAxisHorizontal;
    leftStackView.alignment = UIStackViewAlignmentCenter;
    leftStackView.distribution = UIStackViewDistributionEqualSpacing;
    [contentView addSubview:leftStackView];

    UIStackView *rightStackView = [[UIStackView alloc] init];
    rightStackView.translatesAutoresizingMaskIntoConstraints = NO;
    rightStackView.axis = UILayoutConstraintAxisHorizontal;
    rightStackView.alignment = UIStackViewAlignmentCenter;
    rightStackView.distribution = UIStackViewDistributionEqualSpacing;
    [contentView addSubview:rightStackView];

    NSArray<NSDictionary<NSString *, NSString *> *> *configs = @[
        @{@"normal": @"tab_home_normal", @"selected": @"tab_home_selected", @"title": @"Home"},
        @{@"normal": @"tab_discover_normal", @"selected": @"tab_discover_selected", @"title": @"Discover"},
        @{@"normal": @"tab_message_normal", @"selected": @"tab_message_selected", @"title": @"Message"},
        @{@"normal": @"tab_mine_normal", @"selected": @"tab_mine_selected", @"title": @"Mine"}
    ];

    NSMutableArray<YKCustomTabBarItem *> *items = [NSMutableArray arrayWithCapacity:configs.count];
    [configs enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSString *> *config, NSUInteger idx, BOOL *stop) {
        YKCustomTabBarItem *item = [[YKCustomTabBarItem alloc] initWithNormalImageName:config[@"normal"]
                                                                     selectedImageName:config[@"selected"]
                                                                    accessibilityTitle:config[@"title"]];
        item.tag = idx;
        [item addTarget:self action:@selector(yk_itemTapped:) forControlEvents:UIControlEventTouchUpInside];
        if (idx < 2) {
            [leftStackView addArrangedSubview:item];
        } else {
            [rightStackView addArrangedSubview:item];
        }
        [items addObject:item];

        [NSLayoutConstraint activateConstraints:@[
            [item.widthAnchor constraintEqualToConstant:36.0],
            [item.heightAnchor constraintEqualToConstant:36.0]
        ]];
    }];
    self.items = items;

    UIButton *publishButton = [UIButton buttonWithType:UIButtonTypeCustom];
    publishButton.translatesAutoresizingMaskIntoConstraints = NO;
    publishButton.adjustsImageWhenHighlighted = NO;
    publishButton.accessibilityLabel = @"Publish";
    publishButton.backgroundColor = UIColor.clearColor;
    publishButton.layer.cornerRadius = 30.0;
    publishButton.layer.masksToBounds = YES;
    publishButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    publishButton.contentEdgeInsets = UIEdgeInsetsZero;
    [publishButton setBackgroundImage:[[UIImage imageNamed:@"publicadd"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [publishButton addTarget:self action:@selector(yk_publishButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:publishButton];
    self.publishButton = publishButton;

    [NSLayoutConstraint activateConstraints:@[
        [contentView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        [leftStackView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:15.0],
        [leftStackView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:18.0],
        [leftStackView.widthAnchor constraintEqualToConstant:112.0],
        [leftStackView.heightAnchor constraintEqualToConstant:36.0],

        [rightStackView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:15.0],
        [rightStackView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-18.0],
        [rightStackView.widthAnchor constraintEqualToConstant:112.0],
        [rightStackView.heightAnchor constraintEqualToConstant:36.0],

        [publishButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [publishButton.centerYAnchor constraintEqualToAnchor:contentView.topAnchor constant:25.0],
        [publishButton.widthAnchor constraintEqualToConstant:60.0],
        [publishButton.heightAnchor constraintEqualToConstant:60.0]
    ]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIBezierPath *fillPath = [self yk_tabBarFillPathInRect:self.contentView.bounds];
    UIBezierPath *borderPath = [self yk_tabBarBorderPathInRect:self.contentView.bounds];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.backgroundShapeLayer.frame = self.contentView.bounds;
    self.backgroundShapeLayer.path = fillPath.CGPath;
    self.borderShapeLayer.frame = self.contentView.bounds;
    self.borderShapeLayer.path = borderPath.CGPath;
    [CATransaction commit];
    [self bringSubviewToFront:self.publishButton];
}

- (UIBezierPath *)yk_tabBarFillPathInRect:(CGRect)rect {
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    CGFloat cornerRadius = 28.0;
    CGFloat buttonRadius = 30.0;
    CGFloat buttonCenterX = width * 0.5;
    CGFloat buttonCenterY = 25.0;
    CGFloat curveTouchY = buttonCenterY - 5.0;
    CGFloat lineUnderButtonInset = 5.0;
    CGFloat leftTouchX = buttonCenterX - buttonRadius + lineUnderButtonInset;
    CGFloat rightTouchX = buttonCenterX + buttonRadius - lineUnderButtonInset;
    CGFloat curveStartX = leftTouchX - 46.0;
    CGFloat curveEndX = rightTouchX + 46.0;
    CGFloat buttonBottomY = buttonCenterY + buttonRadius + 1.0;

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0.0, height)];
    [path addLineToPoint:CGPointMake(0.0, cornerRadius)];
    [path addQuadCurveToPoint:CGPointMake(cornerRadius, 0.0) controlPoint:CGPointMake(0.0, 0.0)];
    [path addLineToPoint:CGPointMake(curveStartX, 0.0)];
    [path addCurveToPoint:CGPointMake(leftTouchX, curveTouchY)
            controlPoint1:CGPointMake(curveStartX + 30.0, 0.0)
            controlPoint2:CGPointMake(leftTouchX - 12.0, curveTouchY - 2.0)];
    [path addCurveToPoint:CGPointMake(buttonCenterX, buttonBottomY)
            controlPoint1:CGPointMake(leftTouchX + 4.0, curveTouchY + 18.0)
            controlPoint2:CGPointMake(buttonCenterX - 26.0, buttonBottomY)];
    [path addCurveToPoint:CGPointMake(rightTouchX, curveTouchY)
            controlPoint1:CGPointMake(buttonCenterX + 26.0, buttonBottomY)
            controlPoint2:CGPointMake(rightTouchX - 4.0, curveTouchY + 18.0)];
    [path addCurveToPoint:CGPointMake(curveEndX, 0.0)
            controlPoint1:CGPointMake(rightTouchX + 12.0, curveTouchY - 2.0)
            controlPoint2:CGPointMake(curveEndX - 30.0, 0.0)];
    [path addLineToPoint:CGPointMake(width - cornerRadius, 0.0)];
    [path addQuadCurveToPoint:CGPointMake(width, cornerRadius) controlPoint:CGPointMake(width, 0.0)];
    [path addLineToPoint:CGPointMake(width, height)];
    [path closePath];
    return path;
}

- (UIBezierPath *)yk_tabBarBorderPathInRect:(CGRect)rect {
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    CGFloat cornerRadius = 28.0;
    CGFloat buttonRadius = 30.0;
    CGFloat buttonCenterX = width * 0.5;
    CGFloat buttonCenterY = 25.0;
    CGFloat curveTouchY = buttonCenterY - 5.0;
    CGFloat lineUnderButtonInset = 5.0;
    CGFloat leftTouchX = buttonCenterX - buttonRadius + lineUnderButtonInset;
    CGFloat rightTouchX = buttonCenterX + buttonRadius - lineUnderButtonInset;
    CGFloat curveStartX = leftTouchX - 46.0;
    CGFloat curveEndX = rightTouchX + 46.0;

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0.0, height)];
    [path addLineToPoint:CGPointMake(0.0, cornerRadius)];
    [path addQuadCurveToPoint:CGPointMake(cornerRadius, 0.0) controlPoint:CGPointMake(0.0, 0.0)];
    [path addLineToPoint:CGPointMake(curveStartX, 0.0)];
    [path addCurveToPoint:CGPointMake(leftTouchX, curveTouchY)
            controlPoint1:CGPointMake(curveStartX + 30.0, 0.0)
            controlPoint2:CGPointMake(leftTouchX - 12.0, curveTouchY - 2.0)];

    [path moveToPoint:CGPointMake(width, height)];
    [path addLineToPoint:CGPointMake(width, cornerRadius)];
    [path addQuadCurveToPoint:CGPointMake(width - cornerRadius, 0.0) controlPoint:CGPointMake(width, 0.0)];
    [path addLineToPoint:CGPointMake(curveEndX, 0.0)];
    [path addCurveToPoint:CGPointMake(rightTouchX, curveTouchY)
            controlPoint1:CGPointMake(curveEndX - 30.0, 0.0)
            controlPoint2:CGPointMake(rightTouchX + 12.0, curveTouchY - 2.0)];
    return path;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    if (selectedIndex < 0 || selectedIndex >= self.items.count) {
        return;
    }
    _selectedIndex = selectedIndex;
    [self yk_updateSelection];
}

- (void)yk_itemTapped:(YKCustomTabBarItem *)sender {
    [self.delegate customTabBarView:self didSelectIndex:sender.tag];
}

- (void)yk_publishButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(customTabBarViewDidTapPublish:)]) {
        [self.delegate customTabBarViewDidTapPublish:self];
    }
}

- (void)yk_updateSelection {
    [self.items enumerateObjectsUsingBlock:^(YKCustomTabBarItem *item, NSUInteger idx, BOOL *stop) {
        item.selected = (idx == self.selectedIndex);
    }];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden || self.alpha <= 0.01 || !self.userInteractionEnabled) {
        return nil;
    }

    CGPoint publishPoint = [self.publishButton convertPoint:point fromView:self];
    if ([self.publishButton pointInside:publishPoint withEvent:event]) {
        return [self.publishButton hitTest:publishPoint withEvent:event];
    }

    return [super hitTest:point withEvent:event];
}

@end
