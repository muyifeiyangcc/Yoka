//
//  YKReportShadeSheet.m
//  Yoka
//

#import "YKReportShadeSheet.h"
#import <objc/runtime.h>
#import "../../BaseClass/YKSigilForge.h"

static const NSInteger kYKReportShadeSheetTag = 904501;
static const void *kYKReportHandlerKey = &kYKReportHandlerKey;
static const void *kYKBlockHandlerKey = &kYKBlockHandlerKey;
static const void *kYKActionStackKey = &kYKActionStackKey;
static const void *kYKConfirmPanelKey = &kYKConfirmPanelKey;

@implementation YKReportShadeSheet

+ (UIView *)yk_presentationContainerForHost:(UIView *)hostView {
    UIWindow *window = hostView.window;
    if (!window) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class] || scene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }
            for (UIWindow *candidate in ((UIWindowScene *)scene).windows) {
                if (candidate.isKeyWindow) {
                    window = candidate;
                    break;
                }
            }
            if (window) {
                break;
            }
        }
    }
    return window ?: hostView;
}

+ (void)yk_presentInView:(UIView *)hostView
                  report:(void (^)(void))reportHandler
                   block:(void (^)(void))blockHandler {
    if (!hostView) {
        return;
    }
    // Present on the key window so custom tab bars cannot cover Report / Block / Cancel.
    UIView *container = [self yk_presentationContainerForHost:hostView];
    [[hostView viewWithTag:kYKReportShadeSheetTag] removeFromSuperview];
    [[container viewWithTag:kYKReportShadeSheetTag] removeFromSuperview];

    UIView *overlay = [[UIView alloc] init];
    overlay.tag = kYKReportShadeSheetTag;
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.45];
    overlay.alpha = 0.0;
    [container addSubview:overlay];

    UIButton *dimHit = [UIButton buttonWithType:UIButtonTypeCustom];
    dimHit.translatesAutoresizingMaskIntoConstraints = NO;
    dimHit.backgroundColor = UIColor.clearColor;
    [dimHit addTarget:self action:@selector(yk_dismissFromSender:) forControlEvents:UIControlEventTouchUpInside];
    [overlay addSubview:dimHit];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 12.0;
    [overlay addSubview:stack];
    objc_setAssociatedObject(overlay, kYKActionStackKey, stack, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIButton *reportButton = [self yk_assetButtonNamed:@"report_button"];
    UIButton *blockButton = [self yk_assetButtonNamed:@"shade_button"];
    UIButton *cancelButton = [self yk_assetButtonNamed:@"cancel_button"];
    [stack addArrangedSubview:reportButton];
    [stack addArrangedSubview:blockButton];
    [stack addArrangedSubview:cancelButton];

    objc_setAssociatedObject(overlay, kYKReportHandlerKey, [reportHandler copy], OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(overlay, kYKBlockHandlerKey, [blockHandler copy], OBJC_ASSOCIATION_COPY_NONATOMIC);
    [reportButton addTarget:self action:@selector(yk_reportTapped:) forControlEvents:UIControlEventTouchUpInside];
    [blockButton addTarget:self action:@selector(yk_blockTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton addTarget:self action:@selector(yk_dismissFromSender:) forControlEvents:UIControlEventTouchUpInside];

    CGFloat hostWidth = CGRectGetWidth(container.bounds);
    if (hostWidth < 1.0) {
        hostWidth = CGRectGetWidth(hostView.bounds);
    }
    UIView *confirmPanel = [self yk_makeBlockConfirmPanelInOverlay:overlay hostWidth:hostWidth];
    confirmPanel.hidden = YES;
    confirmPanel.alpha = 0.0;
    objc_setAssociatedObject(overlay, kYKConfirmPanelKey, confirmPanel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    const CGFloat buttonW = 215.0;
    const CGFloat buttonH = 49.0;
    [NSLayoutConstraint activateConstraints:@[
        [overlay.topAnchor constraintEqualToAnchor:container.topAnchor],
        [overlay.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [overlay.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [overlay.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],

        [dimHit.topAnchor constraintEqualToAnchor:overlay.topAnchor],
        [dimHit.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor],
        [dimHit.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor],
        [dimHit.bottomAnchor constraintEqualToAnchor:overlay.bottomAnchor],

        [stack.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],

        [reportButton.widthAnchor constraintEqualToConstant:buttonW],
        [reportButton.heightAnchor constraintEqualToConstant:buttonH],
        [blockButton.widthAnchor constraintEqualToConstant:buttonW],
        [blockButton.heightAnchor constraintEqualToConstant:buttonH],
        [cancelButton.widthAnchor constraintEqualToConstant:buttonW],
        [cancelButton.heightAnchor constraintEqualToConstant:buttonH]
    ]];

    [container bringSubviewToFront:overlay];
    [UIView animateWithDuration:0.22 animations:^{
        overlay.alpha = 1.0;
    }];
}

+ (UIView *)yk_makeBlockConfirmPanelInOverlay:(UIView *)overlay hostWidth:(CGFloat)hostWidth {
    UIView *panel = [[UIView alloc] init];
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    [overlay addSubview:panel];

    UIImageView *dialog = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"shade_confirm_sheet"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    dialog.translatesAutoresizingMaskIntoConstraints = NO;
    dialog.contentMode = UIViewContentModeScaleAspectFit;
    dialog.userInteractionEnabled = YES;
    [panel addSubview:dialog];

    UIButton *cancelHit = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelHit.translatesAutoresizingMaskIntoConstraints = NO;
    cancelHit.accessibilityLabel = @"Cancel";
    [cancelHit addTarget:self action:@selector(yk_blockConfirmCancelTapped:) forControlEvents:UIControlEventTouchUpInside];
    [dialog addSubview:cancelHit];

    UIButton *blockHit = [UIButton buttonWithType:UIButtonTypeCustom];
    blockHit.translatesAutoresizingMaskIntoConstraints = NO;
    blockHit.accessibilityLabel = [YKSigilForge yk_unveil:@"qCn9Y+mO97RHwxUcCDdo6w=="];
    [blockHit addTarget:self action:@selector(yk_blockConfirmSureTapped:) forControlEvents:UIControlEventTouchUpInside];
    [dialog addSubview:blockHit];

    // Asset shade_confirm_sheet @3x 927×723 → 309×241 pt; hit zones match logout/delete sheets.
    CGFloat dialogW = MIN(309.0, MAX(hostWidth - 48.0, 240.0));
    CGFloat scale = dialogW / 309.0;
    CGFloat dialogH = 241.0 * scale;

    [NSLayoutConstraint activateConstraints:@[
        [panel.topAnchor constraintEqualToAnchor:overlay.topAnchor],
        [panel.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor],
        [panel.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor],
        [panel.bottomAnchor constraintEqualToAnchor:overlay.bottomAnchor],

        [dialog.centerXAnchor constraintEqualToAnchor:panel.centerXAnchor],
        [dialog.centerYAnchor constraintEqualToAnchor:panel.centerYAnchor constant:-6.0],
        [dialog.widthAnchor constraintEqualToConstant:dialogW],
        [dialog.heightAnchor constraintEqualToConstant:dialogH],

        [cancelHit.leadingAnchor constraintEqualToAnchor:dialog.leadingAnchor constant:50.0 * scale],
        [cancelHit.bottomAnchor constraintEqualToAnchor:dialog.bottomAnchor constant:-33.0 * scale],
        [cancelHit.widthAnchor constraintEqualToConstant:100.0 * scale],
        [cancelHit.heightAnchor constraintEqualToConstant:32.0 * scale],

        [blockHit.trailingAnchor constraintEqualToAnchor:dialog.trailingAnchor constant:-36.0 * scale],
        [blockHit.bottomAnchor constraintEqualToAnchor:dialog.bottomAnchor constant:-33.0 * scale],
        [blockHit.widthAnchor constraintEqualToConstant:100.0 * scale],
        [blockHit.heightAnchor constraintEqualToConstant:32.0 * scale]
    ]];

    return panel;
}

+ (UIButton *)yk_assetButtonNamed:(NSString *)imageName {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = UIColor.clearColor;
    button.adjustsImageWhenHighlighted = YES;
    UIImage *image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [button setBackgroundImage:image forState:UIControlStateNormal];
    [button setBackgroundImage:image forState:UIControlStateHighlighted];
    return button;
}

+ (UIView *)yk_hostOverlayFromSender:(UIView *)sender {
    UIView *view = sender;
    while (view && view.tag != kYKReportShadeSheetTag) {
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

+ (void)yk_dismissFromSender:(UIView *)sender {
    [self yk_dismissOverlay:[self yk_hostOverlayFromSender:sender] completion:nil];
}

+ (void)yk_reportTapped:(UIButton *)sender {
    UIView *overlay = [self yk_hostOverlayFromSender:sender];
    void (^handler)(void) = objc_getAssociatedObject(overlay, kYKReportHandlerKey);
    [self yk_dismissOverlay:overlay completion:^{
        if (handler) {
            handler();
        }
    }];
}

+ (void)yk_blockTapped:(UIButton *)sender {
    UIView *overlay = [self yk_hostOverlayFromSender:sender];
    UIStackView *stack = objc_getAssociatedObject(overlay, kYKActionStackKey);
    UIView *confirmPanel = objc_getAssociatedObject(overlay, kYKConfirmPanelKey);
    if (!stack || !confirmPanel) {
        void (^handler)(void) = objc_getAssociatedObject(overlay, kYKBlockHandlerKey);
        [self yk_dismissOverlay:overlay completion:^{
            if (handler) {
                handler();
            }
        }];
        return;
    }
    stack.hidden = YES;
    confirmPanel.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        confirmPanel.alpha = 1.0;
    }];
}

+ (void)yk_blockConfirmCancelTapped:(UIButton *)sender {
    UIView *overlay = [self yk_hostOverlayFromSender:sender];
    UIStackView *stack = objc_getAssociatedObject(overlay, kYKActionStackKey);
    UIView *confirmPanel = objc_getAssociatedObject(overlay, kYKConfirmPanelKey);
    [UIView animateWithDuration:0.18 animations:^{
        confirmPanel.alpha = 0.0;
    } completion:^(BOOL finished) {
        confirmPanel.hidden = YES;
        stack.hidden = NO;
    }];
}

+ (void)yk_blockConfirmSureTapped:(UIButton *)sender {
    UIView *overlay = [self yk_hostOverlayFromSender:sender];
    void (^handler)(void) = objc_getAssociatedObject(overlay, kYKBlockHandlerKey);
    [self yk_dismissOverlay:overlay completion:^{
        if (handler) {
            handler();
        }
    }];
}

@end
