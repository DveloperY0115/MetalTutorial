//
//  add.metal
//  MetalTutorial
//
//  Created by 유승우 on 2021/10/31.
//

#include <metal_stdlib>
using namespace metal;

kernel void add_arrays(device const float* inA,
                       device const float* inB,
                       device float* result,
                       uint index [[thread_position_in_grid]]) {
    result[index] = inA[index] + inB[index];
}

