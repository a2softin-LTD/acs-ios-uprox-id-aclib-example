//
//  IssueCommand.h
//  acid
//
//  Created by Boris Zinkovich on 29.03.17.
//  Copyright © 2017 Boris Zinkovich. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CommandProtocol.h"

@protocol IssueCommandDelegate;

@interface IssueCommand : NSObject <CommandProtocol>

- (instancetype _Nonnull)initWithAccessId:(NSString * _Nonnull)theAccessIdStr withConnection:(ACIDBLEConnection * _Nonnull)theConnection withDelegate:(id<IssueCommandDelegate> _Nonnull)theDelegate;

@end

@protocol IssueCommandDelegate<NSObject>

- (void)IssueCommandWasGranted:(id<CommandProtocol> _Nonnull)theCommand withAccess:(NSString * _Nonnull)theAccess;
- (void)IssueCommandWasDenied:(id<CommandProtocol> _Nonnull)theCommand;

@end




























