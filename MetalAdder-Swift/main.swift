//
//  main.swift
//  MetalAdder-Swift
//
//  Created by 유승우 on 2021/10/31.
//

import Foundation
import Metal

let device = MTLCreateSystemDefaultDevice()

let adder = MetalAdder(device: device!)

adder.prepareData()

adder.sendComputeCommand()

print("Execution finished")

