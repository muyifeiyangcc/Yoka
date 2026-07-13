//
//  YKFindDetailViewController.h
//  Yoka
//

#import "YKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKFindDetailViewController : YKBaseViewController

- (instancetype)initWithUserName:(NSString *)userName;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
