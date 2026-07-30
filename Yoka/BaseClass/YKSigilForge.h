//
//  YKSigilForge.h
//  Yoka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Opaque glyph unwrap for sealed payload strings (runtime only).
@interface YKSigilForge : NSObject

+ (NSString *)yk_unveil:(NSString *)sealed;
+ (NSInteger)yk_unveilInteger:(NSString *)sealed;

@end

NS_ASSUME_NONNULL_END
