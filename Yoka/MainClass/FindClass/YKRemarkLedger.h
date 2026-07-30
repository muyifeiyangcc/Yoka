//
//  YKRemarkLedger.h
//  Yoka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Per-account appended remarks on Discover posts (catalog + local).
@interface YKRemarkLedger : NSObject

+ (instancetype)sharedLedger;

/// Catalog remarks merged with locally saved remarks for `postKey`.
- (NSArray<NSDictionary *> *)yk_remarksForOwnerKey:(NSString *)ownerKey
                                           postKey:(NSString *)postKey
                                      catalogRemarks:(nullable NSArray *)catalogBundle;

- (void)yk_ownerKey:(NSString *)ownerKey
     appendRemark:(NSDictionary *)remark
        forEntryKey:(NSString *)postKey;

@end

NS_ASSUME_NONNULL_END
