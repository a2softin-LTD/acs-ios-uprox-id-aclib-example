//
//  PiuBanch.h
//  AcidLibrary
//
//  Created by Yevhen Khyzhniak on 29.05.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger
{
    PiuTypePersonal = 1,
    PiuTypeNetwork = 2,
    PiuTypeEncrypted = 3,
    PiuTypeCompany = 4,
    PiuTypeTime = 5,
    PiuTypeUnknown = 6
} PiuType;


@interface PiuBanch : NSObject

@property (nonatomic, strong, nullable) NSString *thePersonalPiu;
@property (nonatomic, strong, nullable) NSString *theNetworkPiu;
@property (nonatomic, strong, nullable) NSString *theEncryptedPiu;

+ (PiuBanch * _Nonnull)sharedInstance;

- (BOOL)hasAnyPiu;
- (void)methodUpdateWithGeneratedPersonalPiu;
- (NSString * _Nullable)methodGetPiuDescriptionWithType:(PiuType)theType;
- (void)methodRemovePiuWithType:(PiuType)theType;
- (void)methodSetPiuWithType:(PiuType)theType withId:(NSString * _Nullable)thePiu;
- (void)methodSaveToPreferences;
- (int)methodGetPiuCount;

@end
