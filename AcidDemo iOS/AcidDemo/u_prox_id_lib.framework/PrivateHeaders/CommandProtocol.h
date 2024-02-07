//
//  CommandProtocol.h
//  acid
//
//  Created by Boris Zinkovich on 05.12.16.
//  Copyright © 2016 Boris Zinkovich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACIDBLEConnection;

@protocol CommandProtocol <NSObject>

- (double)methodGetTimeout;
- (NSData * _Nullable)getCommandData;
- (NSError * _Nullable)methodProcessData:(NSData * _Nullable)theData;
- (void)enqueud;
- (BOOL)isSucceded;

@end
