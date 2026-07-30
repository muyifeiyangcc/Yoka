//
//  YKPublicGoodsViewController.h
//  Yoka
//

#import "YKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface YKPublicGoodsViewController : YKBaseViewController

@property (nonatomic, copy, nullable) void (^completion)(NSDictionary<NSString *, id> *item);

@end

NS_ASSUME_NONNULL_END
