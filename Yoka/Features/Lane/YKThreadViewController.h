//
//  YKThreadViewController.h
//  Yoka
//

#import "YKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKThreadViewController : YKBaseViewController

- (instancetype)initWithPersonaId:(NSString *)personaId;
- (instancetype)initWithDisplayAlias:(NSString *)userName tintColor:(UIColor *)tintColor;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
