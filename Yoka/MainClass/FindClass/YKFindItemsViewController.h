//
//  YKFindItemsViewController.h
//  Yoka
//

#import "../../BaseClass/YKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKFindItemsViewController : YKBaseViewController

- (instancetype)initWithItems:(NSArray<NSDictionary *> *)items;
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
