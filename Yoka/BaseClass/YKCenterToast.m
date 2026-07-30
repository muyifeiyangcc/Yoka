//
//  YKCenterToast.m
//  Yoka
//

#import "YKCenterToast.h"
#import "YKSpinRingView.h"

static const NSInteger kYKToastNoticeTag = 902417;
static const NSInteger kYKToastLoadingTag = 902418;

@implementation YKCenterToast

+ (void)yk_showNotice:(NSString *)message inView:(UIView *)view {
    if (message.length == 0 || view == nil) {
        return;
    }

    UIView *existing = [view viewWithTag:kYKToastNoticeTag];
    [existing removeFromSuperview];

    UIView *bubble = [[UIView alloc] init];
    bubble.tag = kYKToastNoticeTag;
    bubble.translatesAutoresizingMaskIntoConstraints = NO;
    bubble.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.78];
    bubble.layer.cornerRadius = 10.0;
    bubble.clipsToBounds = YES;
    bubble.alpha = 0.0;

    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    textLabel.text = message;
    textLabel.textColor = UIColor.whiteColor;
    textLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.numberOfLines = 0;
    [bubble addSubview:textLabel];
    [view addSubview:bubble];

    [NSLayoutConstraint activateConstraints:@[
        [bubble.centerXAnchor constraintEqualToAnchor:view.centerXAnchor],
        [bubble.centerYAnchor constraintEqualToAnchor:view.centerYAnchor],
        [bubble.widthAnchor constraintLessThanOrEqualToAnchor:view.widthAnchor multiplier:0.78],

        [textLabel.topAnchor constraintEqualToAnchor:bubble.topAnchor constant:12.0],
        [textLabel.bottomAnchor constraintEqualToAnchor:bubble.bottomAnchor constant:-12.0],
        [textLabel.leadingAnchor constraintEqualToAnchor:bubble.leadingAnchor constant:16.0],
        [textLabel.trailingAnchor constraintEqualToAnchor:bubble.trailingAnchor constant:-16.0]
    ]];

    [UIView animateWithDuration:0.2 animations:^{
        bubble.alpha = 1.0;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 animations:^{
                bubble.alpha = 0.0;
            } completion:^(BOOL done) {
                [bubble removeFromSuperview];
            }];
        });
    }];
}

+ (void)yk_showLoadingInView:(UIView *)view {
    if (view == nil) {
        return;
    }
    [self yk_hideLoadingInView:view];

    UIView *overlay = [[UIView alloc] init];
    overlay.tag = kYKToastLoadingTag;
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.28];
    [view addSubview:overlay];

    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.72];
    card.layer.cornerRadius = 16.0;
    card.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.22].CGColor;
    card.layer.borderWidth = 1.0;
    card.clipsToBounds = YES;
    [overlay addSubview:card];

    YKSpinRingView *ring = [[YKSpinRingView alloc] initWithSide:40.0];
    [card addSubview:ring];
    [ring yk_startSpinning];

    [NSLayoutConstraint activateConstraints:@[
        [overlay.topAnchor constraintEqualToAnchor:view.topAnchor],
        [overlay.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [overlay.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [overlay.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],

        [card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
        [card.widthAnchor constraintEqualToConstant:72.0],
        [card.heightAnchor constraintEqualToConstant:72.0],

        [ring.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [ring.centerYAnchor constraintEqualToAnchor:card.centerYAnchor]
    ]];
}

+ (void)yk_hideLoadingInView:(UIView *)view {
    UIView *overlay = [view viewWithTag:kYKToastLoadingTag];
    [overlay removeFromSuperview];
}

+ (void)yk_showLoadingInView:(UIView *)view
           performAfterDelay:(NSTimeInterval)delay
                        work:(void (^)(void))work {
    if (view == nil) {
        if (work) {
            work();
        }
        return;
    }
    [self yk_showLoadingInView:view];
    NSTimeInterval wait = MAX(0.0, delay);
    __weak UIView *weakView = view;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(wait * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIView *host = weakView;
        if (work) {
            work();
        }
        if (host) {
            [YKCenterToast yk_hideLoadingInView:host];
        }
    });
}

@end
