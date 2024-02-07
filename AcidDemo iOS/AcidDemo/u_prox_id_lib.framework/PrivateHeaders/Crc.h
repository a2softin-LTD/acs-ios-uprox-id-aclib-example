//
//  Crc.h
//  AcidLibrary
//
//  Created by Yevhen Khyzhniak on 29.05.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger
{
    CrcTypeDallas8 = 1,
    CrcTypeCCITT8 = 2,
    CrcTypeStandart16 = 3,
    CrcTypeEnumCount = CrcTypeStandart16
} CrcType;

@interface Crc : NSObject

@property (nonatomic, assign) CrcType theCrcType;

//- (Byte)methodCalculateWithBytes:(Byte *)theData withStart:(int)theStart withEnd:(int)theEnd;
- (Byte)methodCalculateWithData:(NSMutableData *)theData withStart:(int)theStart withEnd:(int)theEnd;
- (short)methodCalculateShortWithData:(NSData *)theData withStart:(int)theStart withEnd:(int)theEnd;
- (short)methodCalculateWithData:(NSData *)theData;

@end
