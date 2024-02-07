//
//  BCDPacket.h
//  AcidLibrary
//
//  Created by Yevhen Khyzhniak on 29.05.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BCDPacket : NSObject

+ (NSData *)methodGetvalueOfHexString:(NSString *)theString;

@end
