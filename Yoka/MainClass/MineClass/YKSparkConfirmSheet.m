//
//  YKSparkConfirmSheet.m
//  Yoka
//

#import "YKSparkConfirmSheet.h"
#import "../../BaseClass/YKSigilForge.h"
#import <objc/runtime.h>

static const NSInteger kYKSparkSheetTag = 904802;
static const void *kYKSparkCancelKey = &kYKSparkCancelKey;
static const void *kYKSparkSureKey = &kYKSparkSureKey;

@implementation YKSparkConfirmSheet

+ (void)yk_presentInView:(UIView *)hostView
                sparkQty:(NSInteger)sparkQty
                   price:(NSString *)price
                  cancel:(void (^)(void))cancel
                    sure:(void (^)(void))sure {
    if (hostView == nil) {
        return;
    }

    UIView *container = hostView.window ?: hostView;
    [[hostView viewWithTag:kYKSparkSheetTag] removeFromSuperview];
    [[container viewWithTag:kYKSparkSheetTag] removeFromSuperview];

    UIView *overlay = [[UIView alloc] init];
    overlay.tag = kYKSparkSheetTag;
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.55];
    overlay.alpha = 0.0;
    [container addSubview:overlay];

    objc_setAssociatedObject(overlay, kYKSparkCancelKey, cancel, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(overlay, kYKSparkSureKey, sure, OBJC_ASSOCIATION_COPY_NONATOMIC);

    UIButton *dimHit = [UIButton buttonWithType:UIButtonTypeCustom];
    dimHit.translatesAutoresizingMaskIntoConstraints = NO;
    [dimHit addTarget:self action:@selector(yk_cancelTapped:) forControlEvents:UIControlEventTouchUpInside];
    [overlay addSubview:dimHit];

    // Outer chrome — same purple family as enough / logout sheets.
    UIView *frame = [[UIView alloc] init];
    frame.translatesAutoresizingMaskIntoConstraints = NO;
    frame.backgroundColor = [UIColor colorWithRed:0x9B / 255.0 green:0x5C / 255.0 blue:0xFF / 255.0 alpha:1.0];
    frame.layer.cornerRadius = 18.0;
    frame.layer.borderWidth = 3.0;
    frame.layer.borderColor = UIColor.blackColor.CGColor;
    frame.clipsToBounds = YES;
    [overlay addSubview:frame];

    UIView *inner = [[UIView alloc] init];
    inner.translatesAutoresizingMaskIntoConstraints = NO;
    inner.backgroundColor = [UIColor colorWithRed:0xE8 / 255.0 green:0xDE / 255.0 blue:0xFF / 255.0 alpha:1.0];
    inner.layer.cornerRadius = 12.0;
    inner.layer.borderWidth = 2.0;
    inner.layer.borderColor = UIColor.blackColor.CGColor;
    [frame addSubview:inner];

    UIStackView *sparkRow = [[UIStackView alloc] init];
    sparkRow.translatesAutoresizingMaskIntoConstraints = NO;
    sparkRow.axis = UILayoutConstraintAxisHorizontal;
    sparkRow.alignment = UIStackViewAlignmentCenter;
    sparkRow.spacing = 8.0;
    [inner addSubview:sparkRow];

    UIImageView *sparkIcon = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"spark_icon_small"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    sparkIcon.translatesAutoresizingMaskIntoConstraints = NO;
    sparkIcon.contentMode = UIViewContentModeScaleAspectFit;
    [sparkRow addArrangedSubview:sparkIcon];

    UILabel *sparkLabel = [[UILabel alloc] init];
    sparkLabel.text = [NSString stringWithFormat:@"+%ld", (long)sparkQty];
    sparkLabel.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    sparkLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightBold];
    [sparkRow addArrangedSubview:sparkLabel];

    UILabel *priceLabel = [[UILabel alloc] init];
    priceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    priceLabel.text = price.length > 0 ? price : @"";
    priceLabel.textColor = [UIColor colorWithWhite:0.22 alpha:1.0];
    priceLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    priceLabel.textAlignment = NSTextAlignmentCenter;
    [inner addSubview:priceLabel];

    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    messageLabel.text = [YKSigilForge yk_unveil:@"5guQnwCu63UxHnQNumo0tD6lPAGp6STyfQGrxftO2cBd30fN0UeTdOwg0fcUFkg7"];
    messageLabel.textColor = [UIColor colorWithWhite:0.18 alpha:1.0];
    messageLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.numberOfLines = 0;
    [inner addSubview:messageLabel];

    UIButton *cancelButton = [self yk_pillButtonTitle:@"Cancel"
                                           fillColor:[UIColor colorWithWhite:0.92 alpha:1.0]
                                           titleColor:UIColor.blackColor
                                              action:@selector(yk_cancelTapped:)];
    [inner addSubview:cancelButton];

    UIButton *sureButton = [self yk_pillButtonTitle:@"Sure"
                                         fillColor:[UIColor colorWithRed:1.0 green:0.55 blue:0.12 alpha:1.0]
                                         titleColor:UIColor.whiteColor
                                            action:@selector(yk_sureTapped:)];
    [inner addSubview:sureButton];

    CGFloat hostW = CGRectGetWidth(container.bounds);
    if (hostW < 1.0) {
        hostW = CGRectGetWidth(hostView.bounds);
    }
    CGFloat dialogW = MIN(309.0, MAX(hostW - 48.0, 260.0));

    [NSLayoutConstraint activateConstraints:@[
        [overlay.topAnchor constraintEqualToAnchor:container.topAnchor],
        [overlay.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [overlay.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [overlay.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],

        [dimHit.topAnchor constraintEqualToAnchor:overlay.topAnchor],
        [dimHit.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor],
        [dimHit.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor],
        [dimHit.bottomAnchor constraintEqualToAnchor:overlay.bottomAnchor],

        [frame.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [frame.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor constant:-6.0],
        [frame.widthAnchor constraintEqualToConstant:dialogW],

        [inner.topAnchor constraintEqualToAnchor:frame.topAnchor constant:36.0],
        [inner.leadingAnchor constraintEqualToAnchor:frame.leadingAnchor constant:14.0],
        [inner.trailingAnchor constraintEqualToAnchor:frame.trailingAnchor constant:-14.0],
        [inner.bottomAnchor constraintEqualToAnchor:frame.bottomAnchor constant:-14.0],

        [sparkIcon.widthAnchor constraintEqualToConstant:38.0],
        [sparkIcon.heightAnchor constraintEqualToConstant:36.0],

        [sparkRow.topAnchor constraintEqualToAnchor:inner.topAnchor constant:22.0],
        [sparkRow.centerXAnchor constraintEqualToAnchor:inner.centerXAnchor],

        [priceLabel.topAnchor constraintEqualToAnchor:sparkRow.bottomAnchor constant:10.0],
        [priceLabel.leadingAnchor constraintEqualToAnchor:inner.leadingAnchor constant:16.0],
        [priceLabel.trailingAnchor constraintEqualToAnchor:inner.trailingAnchor constant:-16.0],

        [messageLabel.topAnchor constraintEqualToAnchor:priceLabel.bottomAnchor constant:12.0],
        [messageLabel.leadingAnchor constraintEqualToAnchor:inner.leadingAnchor constant:18.0],
        [messageLabel.trailingAnchor constraintEqualToAnchor:inner.trailingAnchor constant:-18.0],

        [cancelButton.topAnchor constraintEqualToAnchor:messageLabel.bottomAnchor constant:22.0],
        [cancelButton.leadingAnchor constraintEqualToAnchor:inner.leadingAnchor constant:22.0],
        [cancelButton.bottomAnchor constraintEqualToAnchor:inner.bottomAnchor constant:-18.0],
        [cancelButton.heightAnchor constraintEqualToConstant:36.0],

        [sureButton.centerYAnchor constraintEqualToAnchor:cancelButton.centerYAnchor],
        [sureButton.trailingAnchor constraintEqualToAnchor:inner.trailingAnchor constant:-22.0],
        [sureButton.leadingAnchor constraintEqualToAnchor:cancelButton.trailingAnchor constant:14.0],
        [sureButton.widthAnchor constraintEqualToAnchor:cancelButton.widthAnchor],
        [sureButton.heightAnchor constraintEqualToAnchor:cancelButton.heightAnchor]
    ]];

    [container bringSubviewToFront:overlay];
    [UIView animateWithDuration:0.22 animations:^{
        overlay.alpha = 1.0;
    }];
}

+ (UIButton *)yk_pillButtonTitle:(NSString *)title
                       fillColor:(UIColor *)fillColor
                      titleColor:(UIColor *)titleColor
                          action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = fillColor;
    button.layer.cornerRadius = 18.0;
    button.layer.borderWidth = 2.5;
    button.layer.borderColor = UIColor.blackColor.CGColor;
    button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:titleColor forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

+ (UIView *)yk_overlayFromSender:(UIView *)sender {
    UIView *view = sender;
    while (view && view.tag != kYKSparkSheetTag) {
        view = view.superview;
    }
    return view;
}

+ (void)yk_dismissOverlay:(UIView *)overlay completion:(void (^)(void))completion {
    if (!overlay) {
        if (completion) {
            completion();
        }
        return;
    }
    [UIView animateWithDuration:0.18 animations:^{
        overlay.alpha = 0.0;
    } completion:^(BOOL finished) {
        [overlay removeFromSuperview];
        if (completion) {
            completion();
        }
    }];
}

+ (void)yk_cancelTapped:(UIButton *)sender {
    UIView *overlay = [self yk_overlayFromSender:sender];
    void (^handler)(void) = objc_getAssociatedObject(overlay, kYKSparkCancelKey);
    [self yk_dismissOverlay:overlay completion:^{
        if (handler) {
            handler();
        }
    }];
}

+ (void)yk_sureTapped:(UIButton *)sender {
    UIView *overlay = [self yk_overlayFromSender:sender];
    void (^handler)(void) = objc_getAssociatedObject(overlay, kYKSparkSureKey);
    [self yk_dismissOverlay:overlay completion:^{
        if (handler) {
            handler();
        }
    }];
}

@end
