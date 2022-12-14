//
//  AppPreferences.h
//  AcidLibrary
//
//  Created by Yevhen Khyzhniak on 29.05.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppPreferences : NSObject

@property (nonatomic, strong, nonnull) NSString *thePiu;
@property (nonatomic, strong, nonnull) NSString *theEncryptedPiu;
@property (nonatomic, strong, nonnull) NSString *theNetworkPiu;
@property (nonatomic, assign) BOOL enableDetector;

+ (AppPreferences * _Nonnull)sharedInstance;

-(NSMutableArray *_Nullable)getAllCompanyKeys;

@end

NS_ASSUME_NONNULL_END
