//
//  MetalAdder.swift
//  MetalAdder-Swift
//
//  Created by 유승우 on 2021/10/31.
//

import Foundation
import Metal

// Define constants
let arrayLength = 1 << 10
let bufferSize = arrayLength * MemoryLayout<Float>.size

class MetalAdder {
    
    var _mDevice: MTLDevice?
    
    var _mAddFunctionPSO: MTLComputePipelineState?
    
    var _mCommandQueue: MTLCommandQueue?
    
    // Buffers for holding data
    var _mBufferA: MTLBuffer?
    var _mBufferB: MTLBuffer?
    var _mBufferResult: MTLBuffer?
    
    /*
     * Constructor of 'MetalAdder'.
     *
     * Initializes MetalAdder instance with provided
     * MTLDevice object.
     */
    init(device: MTLDevice) {
        _mDevice = device
        
        // Load the shader files with a .metal file extension in the project.
        let defaultLibrary: MTLLibrary = _mDevice!.makeDefaultLibrary()!
        
        // Ask Default Library for a shader function 'add_arrays'.
        let addFunction: MTLFunction = defaultLibrary.makeFunction(name: "add_arrays")!
        
        // Create a Metal Pipeline.
        // NOTE: Catching the errors like this is
        // not a good practice!!
        do {
        _mAddFunctionPSO = try _mDevice?.makeComputePipelineState(function: addFunction)
        } catch {
            print(error)
        }
        
        // Create a command queue.
        _mCommandQueue = _mDevice?.makeCommandQueue()
    }
    
    func sendComputeCommand() {
        // Create a command buffer.
        let commandBuffer = _mCommandQueue?.makeCommandBuffer()
        assert(commandBuffer != nil)
        
        // Create a compute encoder.
        let computeEncoder = commandBuffer?.makeComputeCommandEncoder()
        assert(computeEncoder != nil)
        
        // Encode command.
        self.encodeCommand(computeEncoder: computeEncoder!)
        
        // Finish encoding command.
        computeEncoder?.endEncoding()
        
        // Run the commands in the command buffer.
        commandBuffer?.commit()
        
        // Wait until the execution is finished.
        commandBuffer?.waitUntilCompleted()
        
        self.verifyResults()
    }
    
    func encodeCommand(computeEncoder: MTLComputeCommandEncoder) {
        // Set pipeline state
        computeEncoder.setComputePipelineState(_mAddFunctionPSO!)
        
        // Set argument data
        computeEncoder.setBuffer(_mBufferA, offset: 0, index: 0)
        computeEncoder.setBuffer(_mBufferB, offset: 0, index: 1)
        computeEncoder.setBuffer(_mBufferResult, offset: 0, index: 2)
        
        // Determine the number of threads to create.
        let gridSize = MTLSizeMake(arrayLength, 1, 1)
        
        // Specify Threadgroup size
        var threadGroupSize = _mAddFunctionPSO?.maxTotalThreadsPerThreadgroup
        if (threadGroupSize! > arrayLength) {
            threadGroupSize = arrayLength
        }
        let threadgroupSize = MTLSizeMake(threadGroupSize!, 1, 1)
        
        computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadgroupSize)
    }
    
    func prepareData() -> Void {
        _mBufferA = _mDevice?.makeBuffer(length: bufferSize, options: MTLResourceOptions.storageModeShared)
        _mBufferB = _mDevice?.makeBuffer(length: bufferSize, options: MTLResourceOptions.storageModeShared)
        _mBufferResult = _mDevice?.makeBuffer(length: bufferSize, options: MTLResourceOptions.storageModeShared)
        
        self.generateRandomFloatData(buffer: _mBufferA!)
        self.generateRandomFloatData(buffer: _mBufferB!)
    }
    
    func generateRandomFloatData(buffer: MTLBuffer) -> Void {
        func makeList(numElem: Int) -> [Float] {
            return (0..<numElem).map { _ in .random(in: 0.0...10.0) }
        }
        
        let data = makeList(numElem: arrayLength)
        
        buffer.contents().copyMemory(from: data, byteCount: data.count * MemoryLayout<Float>.stride)
    }
    
    func verifyResults() {
        let outA = _mBufferA?.contents().bindMemory(to: Float.self, capacity: arrayLength)
        let outB = _mBufferB?.contents().bindMemory(to: Float.self, capacity: arrayLength)
        let outResult = _mBufferResult?.contents().bindMemory(to: Float.self, capacity: arrayLength)
        
        for index in 0..<arrayLength {
            if (outResult![index] != (outA![index] + outB![index])) {
                print("Compute ERROR")
            }
        }
        
        print("Result is correct")
    }
}
