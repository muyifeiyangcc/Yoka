//
//  YKAuthBaseViewController.m
//  Yoka
//

#import "YKAuthBaseViewController.h"
#import "YKBootNavigator.h"

@implementation YKAuthBaseViewController

- (UILabel *)yk_authTitleLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont fontWithName:@"Limelight" size:23.0] ?: [UIFont systemFontOfSize:23.0 weight:UIFontWeightBold];
    return label;
}

- (UILabel *)yk_authFieldTitleLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont fontWithName:@"SquadaOne-Regular" size:24.0] ?: [UIFont systemFontOfSize:24.0 weight:UIFontWeightRegular];
    return label;
}

- (UIImageView *)yk_authFieldTitleImageViewWithName:(NSString *)imageName {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    return imageView;
}

- (UITextField *)yk_authTextFieldWithPlaceholder:(NSString *)placeholder secure:(BOOL)secure {
    UITextField *textField = [[UITextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.textColor = UIColor.whiteColor;
    textField.tintColor = UIColor.whiteColor;
    textField.secureTextEntry = secure;
    textField.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
    textField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.18];
    textField.layer.borderColor = UIColor.whiteColor.CGColor;
    textField.layer.borderWidth = 1.5;
    textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 12.0, 1.0)];
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.58]
    }];
    return textField;
}

- (UIButton *)yk_authPixelButtonWithTitle:(NSString *)title primary:(BOOL)primary {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = UIColor.clearColor;
    button.contentMode = UIViewContentModeScaleAspectFit;
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;

    NSString *imageName = @"auth_asset_02";
    if ([title isEqualToString:@"Log in"]) {
        imageName = @"auth_asset_05";
    } else if ([title isEqualToString:@"Sign up"]) {
        imageName = @"auth_asset_04";
    } else if ([title isEqualToString:@"Save"]) {
        imageName = @"auth_asset_02";
    } else if ([title isEqualToString:@"Cancel"]) {
        imageName = @"auth_asset_06";
    } else if ([title isEqualToString:@"Agree"]) {
        imageName = @"auth_asset_08";
    }
    [button setImage:[[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    return button;
}

- (UIButton *)yk_authSelectButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.18];
    button.layer.borderColor = UIColor.whiteColor.CGColor;
    button.layer.borderWidth = 1.5;
    [button setTitle:[NSString stringWithFormat:@"  %@", title] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.72] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];

    UIImageView *dropImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Dropd"]];
    dropImageView.translatesAutoresizingMaskIntoConstraints = NO;
    dropImageView.contentMode = UIViewContentModeScaleAspectFit;
    dropImageView.userInteractionEnabled = NO;
    [button addSubview:dropImageView];

    [NSLayoutConstraint activateConstraints:@[
        [dropImageView.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
        [dropImageView.trailingAnchor constraintEqualToAnchor:button.trailingAnchor constant:-12.0],
        [dropImageView.widthAnchor constraintEqualToConstant:20.0],
        [dropImageView.heightAnchor constraintEqualToConstant:20.0]
    ]];
    return button;
}

- (void)yk_enterMainInterface {
    [YKBootNavigator yk_showMainTabs];
}

@end
