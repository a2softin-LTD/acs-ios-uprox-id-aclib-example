//
//  CBPeripheral+ACID.h
//  acid
//
//  Created by Yevhen Khyzhniak on 21.05.2020.
//  Copyright © 2020 Boris Zinkovich. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "PiuBanch.h"

typedef enum : NSUInteger
{
    PeripheralAccessTypeButton = 1,
    PeripheralAccessTypeAll = 2,
    PeripheralAccessTypeCount = PeripheralAccessTypeAll
} PeripheralAccessType;

typedef enum : NSUInteger
{
    Network = 1,
    Encrypted = 2,
    Personal = 3,
    Company = 4,
    Count = Company
} PeripheralKeyType;

NS_ASSUME_NONNULL_BEGIN

@interface CBPeripheral (ACID)

@property (nonatomic, strong) NSString *theRSSI;
@property (nonatomic, strong) NSNumber *theOneMeterPower;
@property (nonatomic, strong) NSData *theManufacturerData;
@property (nonatomic, strong, readonly) NSNumber *theLimitDistance;
@property (nonatomic, strong) NSString *theScanPackageName;
@property (nonatomic, assign) PeripheralAccessType theAccessType;

- (PiuType)theKeyTypeSupport;

- (double)methodCountDistance;

@end

NS_ASSUME_NONNULL_END
