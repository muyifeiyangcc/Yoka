//
//  YKEmptyStateView.m
//  Yoka
//

#import "YKEmptyStateView.h"

@implementation YKEmptyStateView

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.hidden = YES;
        self.userInteractionEnabled = NO;

        UIImageView *iconView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"empty_data"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        iconView.translatesAutoresizingMaskIntoConstraints = NO;
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:iconView];

        UILabel *hintLabel = [[UILabel alloc] init];
        hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
        hintLabel.text = @"No data.";
        hintLabel.textColor = UIColor.whiteColor;
        hintLabel.textAlignment = NSTextAlignmentCenter;
        hintLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
        [self addSubview:hintLabel];

        [NSLayoutConstraint activateConstraints:@[
            [iconView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [iconView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [iconView.widthAnchor constraintEqualToConstant:148.0],
            [iconView.heightAnchor constraintEqualToConstant:100.0],

            [hintLabel.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:18.0],
            [hintLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [hintLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [hintLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
    }
    return self;
}

+ (instancetype)yk_viewEmbeddedIn:(UIView *)host
                     relativeTo:(UILayoutGuide *)guide
                     centerYOffset:(CGFloat)offset {
    YKEmptyStateView *empty = [[YKEmptyStateView alloc] init];
    [host addSubview:empty];

    UILayoutGuide *anchor = guide ?: host.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [empty.leadingAnchor constraintEqualToAnchor:host.leadingAnchor constant:24.0],
        [empty.trailingAnchor constraintEqualToAnchor:host.trailingAnchor constant:-24.0],
        [empty.centerYAnchor constraintEqualToAnchor:anchor.centerYAnchor constant:offset]
    ]];
    return empty;
}

@end
