//
//  MetalAdder.h
//  MetalTutorial
//
//  Created by 유승우 on 2021/10/31.
//

#ifndef MetalAdder_h
#define MetalAdder_h

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface MetalAdder : NSObject
- (instancetype) initWithDevice: (id<MTLDevice>) device;
- (void) prepareData;
- (void) sendComputeCommand;
@end

#endif /* MetalAdder_h */
