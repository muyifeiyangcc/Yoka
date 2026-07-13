//
//  YKChatViewController.h
//  Yoka
//

#import "../../BaseClass/YKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKChatViewController : YKBaseViewController

- (instancetype)initWithUserName:(NSString *)userName tintColor:(UIColor *)tintColor;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
