//
//  AccessDemand.h
//  AcidLibrary
//
//  Created by Yevhen Khyzhniak on 17.05.2023.
//  Copyright © 2023 Yevhen Khyzhniak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <u_prox_id_lib/CryptKey.h>

NS_ASSUME_NONNULL_BEGIN

@interface AccessDemand : NSObject

+ (CryptKey * _Nonnull)methodGetCryptKey:(int)key;

@end

NS_ASSUME_NONNULL_END
