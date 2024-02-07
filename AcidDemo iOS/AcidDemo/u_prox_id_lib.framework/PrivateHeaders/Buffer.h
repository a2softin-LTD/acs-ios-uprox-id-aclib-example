//
//  Buffer.h
//  AcidLibrary
//
//  Created by Yevhen Khyzhniak on 29.05.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BufferBlock;
@interface Bounds : NSObject

@property (nonatomic, assign) int theStart;
@property (nonatomic, assign) int theSize;

- (instancetype _Nonnull)initWithStart:(int)theStart withSize:(int)theSize;

@end

@interface Buffer : NSObject

+ (int)methodGetNearPointIndex:(NSArray<NSNumber *> * _Nonnull)theArray withPoint:(int)thePoint;
+ (BOOL)methodEquals:(NSData * _Nonnull)theBuffer1 withIndex:(int)theIndex1 withBuffer:(NSData * _Nonnull)theBuffer2 withIndex:(int)theIndex2 withSize:(int)theSize;
+ (NSArray<BufferBlock *> * _Nullable)methodExtractDiffernces:(int)theBaseAdress withGranularity:(int)theGranularity withOriginalData:(NSData * _Nonnull)theOriginalData withChangedData:(NSData * _Nonnull)theChangedData;
+ (int)methodLookupDword:(NSData * _Nonnull)theBuffer withPosition:(int)thePosition;
+ (Bounds * _Nullable)methodLookupForMeaningData:(NSData * _Nonnull)theBufferData withPosition:(int)thePosition withSize:(int)theSize withByte:(Byte)meanNothing;
+ (int)methodLookupForMeaningDataBegins:(NSData * _Nonnull)theBuffer withPosition:(int)thePosition withSize:(int)theSize
                        withMeanNothing:(Byte)theMeanNothing;
+ (NSUUID * _Nullable)methodLookupUUID:(NSData * _Nonnull)theBuffer withPosition:(int)thePosition;
+ (int)methodLookupWord:(NSData * _Nonnull)theBuffer withPosition:(int)thePosition;
+ (int)methodLookupWordBigEndian:(NSData * _Nonnull)theBuffer withPosition:(int)thePosition;
+ (long)methodLookupLong:(NSData * _Nonnull)theBuffer withPosition:(int)thePosition;

@end
