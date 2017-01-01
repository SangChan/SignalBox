//
//  DriverTests.swift
//  SignalBox
//
//  Created by Scott James Remnant on 12/30/16.
//
//

import XCTest

@testable import RaspberryPi
@testable import DCC

#if os(Linux)
import CBSD
#endif


class DriverTests: XCTestCase {

    var raspberryPi: RaspberryPi!
    var randomWords: [Int] = []

    override func setUp() {
        super.setUp()
        
        raspberryPi = RaspberryPi(peripheralAddress: 0x3f000000, peripheralAddressSize: 0x01000000)
        
        randomWords.removeAll()
        for _ in 0..<512 {
            randomWords.append(Int(bitPattern: UInt(arc4random_uniform(.max))))
        }
    }
    
    func testParseBitstreamSingleWord() {
        var bitstream = Bitstream(bitDuration: 14.5, wordSize: 32)
        bitstream.append(physicalBits: randomWords[0], count: 32)
        
        let driver = Driver(raspberryPi: raspberryPi)
        let (controlBlocks, data) = driver.parseBitstream(bitstream)
        
        XCTAssertEqual(controlBlocks.count, 4)
        XCTAssertEqual(data.count, 2)
        
        XCTAssertEqual(controlBlocks[0].transferInformation,  [ .sourceIgnoreWrites ])
        XCTAssertEqual(controlBlocks[0].sourceAddress,  0)
        XCTAssertEqual(controlBlocks[0].destinationAddress, MemoryLayout<DMAControlBlock>.stride * 0 + DMAControlBlock.nextControlBlockOffset)
        XCTAssertEqual(controlBlocks[0].transferLength, MemoryLayout<Int>.stride)
        XCTAssertEqual(controlBlocks[0].tdModeStride, 0)
        XCTAssertEqual(controlBlocks[0].nextControlBlockAddress, MemoryLayout<DMAControlBlock>.stride * 1)

        XCTAssertEqual(controlBlocks[1].transferInformation,  [ .noWideBursts, .peripheralMapping(.pwm), .sourceAddressIncrement, .destinationDREQ, .waitForWriteResponse ])
        XCTAssertEqual(controlBlocks[1].sourceAddress,  MemoryLayout<Int>.stride * 0)
        XCTAssertEqual(controlBlocks[1].destinationAddress, raspberryPi.peripheralBusAddress + PWM.offset + PWM.fifoInputOffset)
        XCTAssertEqual(controlBlocks[1].transferLength, MemoryLayout<Int>.stride)
        XCTAssertEqual(controlBlocks[1].tdModeStride, 0)
        XCTAssertEqual(controlBlocks[1].nextControlBlockAddress, MemoryLayout<DMAControlBlock>.stride * 2)
        
        XCTAssertEqual(data[0], randomWords[0])

        XCTAssertEqual(controlBlocks[2].transferInformation, [ .noWideBursts, .peripheralMapping(.pwm), .destinationDREQ, .waitForWriteResponse ])
        XCTAssertEqual(controlBlocks[2].sourceAddress, MemoryLayout<Int>.stride * 1)
        XCTAssertEqual(controlBlocks[2].destinationAddress, raspberryPi.peripheralBusAddress + PWM.offset + PWM.channel1RangeOffset)
        XCTAssertEqual(controlBlocks[2].transferLength, MemoryLayout<Int>.stride)
        XCTAssertEqual(controlBlocks[2].tdModeStride, 0)
        XCTAssertEqual(controlBlocks[2].nextControlBlockAddress, MemoryLayout<DMAControlBlock>.stride * 3)
        
        XCTAssertEqual(data[1], 32)
        
        XCTAssertEqual(controlBlocks[3].transferInformation,  [ .sourceIgnoreWrites ])
        XCTAssertEqual(controlBlocks[3].sourceAddress,  0)
        XCTAssertEqual(controlBlocks[3].destinationAddress, MemoryLayout<DMAControlBlock>.stride * 0)
        XCTAssertEqual(controlBlocks[3].transferLength, MemoryLayout<DMAControlBlock>.stride)
        XCTAssertEqual(controlBlocks[3].tdModeStride, 0)
        XCTAssertEqual(controlBlocks[3].nextControlBlockAddress, MemoryLayout<DMAControlBlock>.stride * 1)
    }
    
}

extension DriverTests {
    
    static var allTests = {
        return [
            ("testParseBitstreamSingleWord", testParseBitstreamSingleWord),
        ]
    }()

}
