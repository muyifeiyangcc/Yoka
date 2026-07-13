//
//  YKAuthBaseViewController.h
//  Yoka
//

#import "../../BaseClass/YKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKAuthBaseViewController : YKBaseViewController

- (UILabel *)yk_authTitleLabelWithText:(NSString *)text;
- (UILabel *)yk_authFieldTitleLabelWithText:(NSString *)text;
- (UIImageView *)yk_authFieldTitleImageViewWithName:(NSString *)imageName;
- (UITextField *)yk_authTextFieldWithPlaceholder:(NSString *)placeholder secure:(BOOL)secure;
- (UIButton *)yk_authPixelButtonWithTitle:(NSString *)title primary:(BOOL)primary;
- (UIButton *)yk_authSelectButtonWithTitle:(NSString *)title;
- (void)yk_enterMainInterface;

@end

NS_ASSUME_NONNULL_END
