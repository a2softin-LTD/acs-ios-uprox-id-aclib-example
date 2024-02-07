//
//  OperationsCrypt.h
//  AcidLibrary
//
//  Created by Yevhen Khyzhniak on 29.05.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <u_prox_id_lib/CryptKey.h>

@interface OperationsCrypt : NSObject

+ (NSData * _Nonnull)methodEncode:(CryptKey * _Nonnull)theKey withValue:(NSData * _Nonnull)theValueData;

+ (NSData * _Nonnull)methodDecodeWithCryptKey:(CryptKey * _Nonnull)theCryptKey
                            withData:(NSData * _Nonnull)theData;

@end
