//
//  YKSpinRingView.m
//  Yoka
//

#import "YKSpinRingView.h"

static NSString * const kYKSpinRingAnimKey = @"yk.spin.ring.rotate";

@interface YKSpinRingView ()
@property (nonatomic, strong) CAShapeLayer *yk_trackLayer;
@property (nonatomic, strong) CAShapeLayer *yk_arcLayer;
@property (nonatomic, strong) CAGradientLayer *yk_gradientLayer;
@property (nonatomic, assign) CGFloat yk_side;
@end

@implementation YKSpinRingView

- (instancetype)initWithSide:(CGFloat)side {
    CGFloat s = MAX(24.0, side);
    self = [super initWithFrame:CGRectMake(0.0, 0.0, s, s)];
    if (self) {
        _yk_side = s;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = NO;
        [self yk_buildLayers];
        [NSLayoutConstraint activateConstraints:@[
            [self.widthAnchor constraintEqualToConstant:s],
            [self.heightAnchor constraintEqualToConstant:s]
        ]];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    CGFloat side = MAX(CGRectGetWidth(frame), CGRectGetHeight(frame));
    if (side < 1.0) {
        side = 44.0;
    }
    return [self initWithSide:side];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    return [self initWithSide:44.0];
}

- (void)yk_buildLayers {
    CGFloat s = self.yk_side;
    CGFloat line = MAX(3.0, s * 0.08);
    CGRect ringRect = CGRectInset(CGRectMake(0.0, 0.0, s, s), line * 0.5 + 1.0, line * 0.5 + 1.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:ringRect];

    CAShapeLayer *track = [CAShapeLayer layer];
    track.path = path.CGPath;
    track.fillColor = UIColor.clearColor.CGColor;
    track.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.18].CGColor;
    track.lineWidth = line;
    track.lineCap = kCALineCapRound;
    [self.layer addSublayer:track];
    self.yk_trackLayer = track;

    CAShapeLayer *arc = [CAShapeLayer layer];
    arc.path = path.CGPath;
    arc.fillColor = UIColor.clearColor.CGColor;
    arc.strokeColor = UIColor.whiteColor.CGColor;
    arc.lineWidth = line;
    arc.lineCap = kCALineCapRound;
    arc.strokeStart = 0.08;
    arc.strokeEnd = 0.72;

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0.0, 0.0, s, s);
    gradient.colors = @[
        (__bridge id)[UIColor colorWithRed:0.98 green:0.28 blue:0.82 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.55 green:0.22 blue:0.98 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.42 green:0.55 blue:1.0 alpha:1.0].CGColor
    ];
    gradient.startPoint = CGPointMake(0.0, 0.0);
    gradient.endPoint = CGPointMake(1.0, 1.0);
    gradient.mask = arc;
    [self.layer addSublayer:gradient];
    self.yk_arcLayer = arc;
    self.yk_gradientLayer = gradient;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat s = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    if (s < 1.0) {
        return;
    }
    self.yk_side = s;
    CGFloat line = MAX(3.0, s * 0.08);
    CGRect ringRect = CGRectInset(CGRectMake(0.0, 0.0, s, s), line * 0.5 + 1.0, line * 0.5 + 1.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:ringRect];
    self.yk_trackLayer.path = path.CGPath;
    self.yk_trackLayer.lineWidth = line;
    self.yk_arcLayer.path = path.CGPath;
    self.yk_arcLayer.lineWidth = line;
    self.yk_gradientLayer.frame = CGRectMake(0.0, 0.0, s, s);
}

- (void)yk_startSpinning {
    if ([self.yk_gradientLayer animationForKey:kYKSpinRingAnimKey]) {
        return;
    }
    CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    spin.fromValue = @0;
    spin.toValue = @(M_PI * 2.0);
    spin.duration = 0.85;
    spin.repeatCount = HUGE_VALF;
    spin.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [self.yk_gradientLayer addAnimation:spin forKey:kYKSpinRingAnimKey];
}

- (void)yk_stopSpinning {
    [self.yk_gradientLayer removeAnimationForKey:kYKSpinRingAnimKey];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window) {
        [self yk_startSpinning];
    } else {
        [self yk_stopSpinning];
    }
}

@end
