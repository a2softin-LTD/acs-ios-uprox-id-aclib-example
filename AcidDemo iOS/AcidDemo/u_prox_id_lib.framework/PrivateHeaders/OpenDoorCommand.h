//
//  OpenDoorCommand.h
//  acid
//
//  Created by Boris Zinkovich on 05.12.16.
//  Copyright © 2016 Boris Zinkovich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <u_prox_id_lib/CommandProtocol.h>

@protocol OpenDoorCommandDelegate;

@interface OpenDoorCommand : NSObject<CommandProtocol>


- (instancetype _Nonnull)initWithAccessId:(NSString * _Nonnull)theAccessIdStr
                           withCompanyKey:(BOOL)isCompany
                           withConnection:(ACIDBLEConnection * _Nonnull)theConnection
                             withDelegate:(id<OpenDoorCommandDelegate> _Nonnull)theDelegate
                              withTimeout:(double)theSeconds;

- (instancetype _Nonnull)initWithCompanyAccessIds:(NSArray<NSString * > * _Nonnull)theAccessIdsStr
                                   withCompanyKey:(BOOL)isCompany
                                   withConnection:(ACIDBLEConnection * _Nonnull)theConnection
                                     withDelegate:(id<OpenDoorCommandDelegate> _Nonnull)theDelegate
                                      withTimeout:(double)theSeconds;

@end

@protocol OpenDoorCommandDelegate<NSObject>

- (void)OpenDoorCommandWasGranted:(id<CommandProtocol> _Nonnull)theCommand;
- (void)OpenDoorCommandWasDenied:(id<CommandProtocol> _Nonnull)theCommand;
- (void)OpenDoorCommandWasAccepted:(id<CommandProtocol> _Nonnull)theCommand;

@end




























