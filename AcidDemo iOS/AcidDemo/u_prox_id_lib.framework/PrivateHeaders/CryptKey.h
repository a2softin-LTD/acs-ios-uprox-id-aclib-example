//
//  CryptKey.h
//  AcidLibrary
//
//  Created by Yevhen Khyzhniak on 18.05.2023.
//  Copyright © 2023 Yevhen Khyzhniak. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CryptKey : NSObject

@property(nonatomic, strong, nonnull) NSData *theData;

- (instancetype _Nonnull)initWithA:(int)theA withB:(int)theB withC:(int)theC withD:(int)theD withE:(int)theE withF:(int)theF withG:(int)theG withH:(int)theH;

@end

NS_ASSUME_NONNULL_END
