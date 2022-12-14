//
//  Hex.h
//  AcidLibrary
//
//  Created by Yevhen Khyzhniak on 29.05.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Hex : NSObject

+ (NSString *)convertDataToString:(NSData *)theData;
+ (NSString *)convertDataToString:(NSData *)theData withPos:(int)thePos withLength:(int)theLength;
+ (NSData *)dataFromHex:(NSString *)theHex;
+ (NSString *)methodGenerateRandomHexWithLength:(int)theLength;

@end

NS_ASSUME_NONNULL_END
