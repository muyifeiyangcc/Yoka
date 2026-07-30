//
//  YKFindPersonaBoardViewController.h
//  Yoka
//

#import "../../BaseClass/YKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKFindPersonaBoardViewController : YKBaseViewController

- (instancetype)initWithDisplayAlias:(NSString *)userName;
- (instancetype)initWithPersonaId:(NSString *)personaId;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
