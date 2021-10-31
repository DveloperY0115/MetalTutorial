//
//  MetalAdder.m
//  MetalTutorial
//
//  Created by 유승우 on 2021/10/31.
//

#import "MetalAdder.h"

const unsigned int arrayLength = 1 << 24;
const unsigned int bufferSize = arrayLength * sizeof(float);

@implementation MetalAdder {
    id<MTLDevice> _mDevice;
    
    // The compute pipeline generated from the compute kernel
    // in the .metal shader file.
    id<MTLComputePipelineState> _mAddFunctionPSO;
    
    // The command queue used to pass commands to the device.
    id<MTLCommandQueue> _mCommandQueue;
    
    // Buffers to hold data.
    id<MTLBuffer> _mBufferA;
    id<MTLBuffer> _mBufferB;
    id<MTLBuffer> _mBufferResult;
}

- (instancetype) initWithDevice: (id<MTLDevice>) device {
    self = [super init];
    
    if (self) {
        _mDevice = device;
        
        NSError* error = nil;
        
        // Load the shader files with a .metal file extension
        // in the project
        id<MTLLibrary> defaultLibrary = [_mDevice newDefaultLibrary];
        if (defaultLibrary == nil) {
            NSLog(@"Failed to find the default library.");
            return nil;
        }
        
        // Ask Default Library for a shader function 'add_arrays'.
        id<MTLFunction> addFunction = [defaultLibrary newFunctionWithName:@"add_arrays"];
        if (addFunction == nil) {
            NSLog(@"Failed to find the adder function.");
            return nil;
        }
        
        // Create a Metal Pipeline
        _mAddFunctionPSO = [_mDevice newComputePipelineStateWithFunction: addFunction error: &error];
        
        // Create a command queue.
        // Command queue is used to commit workloads to GPU(s).
        _mCommandQueue = [_mDevice newCommandQueue];
    }
    
    return self;
}

- (void) prepareData {
    // Prepare data
    _mBufferA = [_mDevice newBufferWithLength: bufferSize options: MTLResourceStorageModeShared];
    _mBufferB = [_mDevice newBufferWithLength: bufferSize options: MTLResourceStorageModeShared];
    _mBufferResult = [_mDevice newBufferWithLength: bufferSize options: MTLResourceStorageModeShared];

    [self generateRandomFloatData: _mBufferA];
    [self generateRandomFloatData: _mBufferB];
}

- (void) sendComputeCommand {
    // Create a command buffer
    id<MTLCommandBuffer> commandBuffer = [_mCommandQueue commandBuffer];
    assert(commandBuffer != nil);
    
    // Create a command encoder.
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    assert(computeEncoder != nil);
    
    
    // Encode command
    [self encodeCommand: computeEncoder];
    
    // Finish encoding command.
    [computeEncoder endEncoding];
    
    // Run the commands in the command buffer.
    [commandBuffer commit];
    
    // Wait until the execution is finished.
    [commandBuffer waitUntilCompleted];
}

- (void) encodeCommand: (id<MTLComputeCommandEncoder>) computeEncoder {
    // Set pipeline state and argument data
    [computeEncoder setComputePipelineState: _mAddFunctionPSO];
    [computeEncoder setBuffer: _mBufferA offset: 0 atIndex: 0];
    [computeEncoder setBuffer: _mBufferB offset: 0 atIndex: 1];
    [computeEncoder setBuffer: _mBufferResult offset: 0 atIndex: 2];
    
    // Determine the number of threads to create
    MTLSize gridSize = MTLSizeMake(arrayLength, 1, 1);

    // Specify Threadgroup size
    NSUInteger threadGroupSize = _mAddFunctionPSO.maxTotalThreadsPerThreadgroup;
    if (threadGroupSize > arrayLength) {
        threadGroupSize = arrayLength;
    }
    MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
    
    [computeEncoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
}

- (void) verifyResults {
    // Retrieve content from each buffer.
    float* a = _mBufferA.contents;
    float* b = _mBufferB.contents;
    float* result = _mBufferResult.contents;
    
    // Compare and validate result one-by-one.
    for (unsigned long index = 0; index < arrayLength; index++) {
        if (result[index] != (a[index] + b[index])) {
            printf("Compute ERROR: index=%lu result=%g vs %g=a+b\n", index, result[index], a[index] + b[index]);
            assert(result[index] == (a[index] + b[index]));
        }
    }
    printf("Result is correct\n");
}

- (void) generateRandomFloatData: (id<MTLBuffer>) buffer {
    float* dataPtr = buffer.contents;
    
    for (unsigned long index = 0; index < arrayLength; index++) {
        dataPtr[index] = (float)rand()/(float)(RAND_MAX);
    }
}

@end
