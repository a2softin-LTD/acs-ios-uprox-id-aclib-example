//
//  ExtensionManager.h
//  AcidLibrary
//
//  Created by Yevhen Khyzhniak on 29.05.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

#import <Foundation/Foundation.h>

BOOL isEqual(id _Nullable theObject1, id _Nullable theObject2);
NSString * _Nullable sfs(SEL _Nonnull theSelector);
NSString * _Nullable sfc(Class _Nonnull theClass);

NS_ASSUME_NONNULL_BEGIN

@interface ExtensionManager : NSObject

+  (NSData * _Nonnull)methodArrayCopyWithSrcBuffer:(NSData * _Nonnull)theSdata withSrcPos:(int)theSrcPos withDestData:(NSData * _Nonnull)theData withDestPos:(int)theDestPos withLength:(int)theLength;
+ (NSString * _Nonnull)methodGetHexFromDecimal:(NSInteger)theDecimal withFormatCount:(NSUInteger)theFormatCount withPrefix:(BOOL)isPrefix;

+ (float)unsignedToSignedByte:(Byte)theByte;

+ (void)methodDispatchAfterSeconds:(double)theSeconds
                         withBlock:(void (^ _Nonnull)(void))theBlock;
+ (void)methodAsyncMainWithBlock:(void (^ _Nonnull)(void))theBlock;
+ (void)methodAsyncBackgroundWithBlock:(void (^ _Nonnull)(void))theBlock;

@end

NS_ASSUME_NONNULL_END
