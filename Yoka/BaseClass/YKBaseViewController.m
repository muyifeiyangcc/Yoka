//
//  YKBaseViewController.m
//  Yoka
//

#import "YKBaseViewController.h"

@interface YKBaseViewController ()

@property (nonatomic, strong) UIImageView *backgroundImageView;

@end

@implementation YKBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self yk_setupBackgroundImageView];
    [self yk_configurePage];
}

- (void)yk_configurePage {
}

- (void)yk_setupBackgroundImageView {
    self.view.backgroundColor = UIColor.blackColor;

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"app_background"]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.userInteractionEnabled = NO;
    [self.view insertSubview:imageView atIndex:0];

    [NSLayoutConstraint activateConstraints:@[
        [imageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [imageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [imageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [imageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    self.backgroundImageView = imageView;
}

- (UIButton *)yk_addBackButton {
    return [self yk_addBackButtonWithTitle:nil];
}

- (UIButton *)yk_addBackButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.tintColor = UIColor.whiteColor;
    [button setImage:[[UIImage imageNamed:@"nav_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [button setTitle:title ?: @"" forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, title.length > 0 ? 8.0 : 0);
    button.titleEdgeInsets = UIEdgeInsetsMake(0, title.length > 0 ? 8.0 : 0, 0, 0);
    [button addTarget:self action:@selector(yk_backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

    CGFloat width = title.length > 0 ? 180.0 : 44.0;
    [NSLayoutConstraint activateConstraints:@[
        [button.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
        [button.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [button.widthAnchor constraintEqualToConstant:width],
        [button.heightAnchor constraintEqualToConstant:44.0]
    ]];

    return button;
}

- (void)yk_backButtonTapped:(UIButton *)sender {
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

