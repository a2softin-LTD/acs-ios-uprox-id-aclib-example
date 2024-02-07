//
//  NSString+Extension.h
//  AcidLibrary
//
//  Created by Yevhen Khyzhniak on 29.05.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Extension)

- (NSString*)MD5;
- (NSString *)base64EncodedString;
- (NSData *)dataFromHexString;

+ (NSString *) base64StringFromData:(NSData *)data length:(int)length;
+ (NSString *)stringFromHexString:(NSString *)hexString;

@end

NS_ASSUME_NONNULL_END
