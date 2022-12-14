//
//  ACIDBLEConnection.h
//  acid
//
//  Created by Boris Zinkovich on 09.08.16.
//  Copyright © 2016 Boris Zinkovich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <AcidLibrary/CommandProtocol.h>

@class OpenPermission;

typedef enum : NSInteger
{
  BLEConnectionErrorTypeTimeOut = 1,
  BLEConnectionErrorTypeWrongData = 2,
  BLEConnectionErrorTypeConnectionTimeOut = 3,
  BLEConnectionErrorTypeInternal = 4,
  BLEConnectionErrorTypeCancelled = 5
} BLEConnectionErrorType;

@protocol ACIDBLEConnectionDelegate;

@interface ACIDBLEConnection : NSObject

@property (nonatomic, weak, nullable) id<ACIDBLEConnectionDelegate> theDelegate;
@property (nonatomic, strong, nonnull) CBPeripheral *theConnectedPeripheral;
@property (nonatomic, strong, nullable) OpenPermission *theOpenPermission;
@property (nonatomic, assign) BOOL isConnected;

- (instancetype _Nonnull)initWithCBPeripheral:(CBPeripheral * _Nonnull)thePeripheral;

- (void)methodStartConnectionWithCommand:(id<CommandProtocol> _Nonnull)theCommand;
- (void)methodStopConnectionWithResponse:(BOOL)hasResponse;
- (void)methodResponseWithError:(NSError * _Nullable)theError withObject:(id _Nullable)theObject;
- (void)methodFinishConnection;

@end

@protocol ACIDBLEConnectionDelegate <NSObject>

@required

- (void)ACIDBLEConnection:(ACIDBLEConnection * _Nonnull)theConnection
     hasFinishedWithError:(NSError * _Nullable)theError
               withObject:(id _Nullable )theObject;

@end





























