//
//  main.m
//  MetalTutorial
//
//  Created by 유승우 on 2021/10/31.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MetalAdder.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // create device, an abstraction of GPU provided by Metal
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        
        MetalAdder* adder = [[MetalAdder alloc] initWithDevice: device];
        
        [adder prepareData];
        
        [adder sendComputeCommand];
        
        NSLog(@"Execution finished");
    }
    return 0;
}
