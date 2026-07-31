//
//  YKBondListViewController.h
//  Yoka
//

#import "YKBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YKBondListKind) {
    YKBondListKindInbound = 0,
    YKBondListKindOutbound
};

@interface YKBondListViewController : YKBaseViewController

- (instancetype)initWithKind:(YKBondListKind)kind;

@end

NS_ASSUME_NONNULL_END
