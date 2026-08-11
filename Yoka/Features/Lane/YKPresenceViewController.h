//
//  YKPresenceViewController.h
//  Yoka
//

#import "YKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKPresenceViewController : YKBaseViewController

- (instancetype)initWithDisplayAlias:(NSString *)displayAlias
                             portrait:(nullable UIImage *)portrait;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
