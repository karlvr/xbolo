//
//  StandardAutopilot.swift
//  XBolo
//
//  Created by C.W. Betts on 7/2/16.
//  Copyright © 2016 Robert Chrzanowski. All rights reserved.
//

import Foundation

public class StandardAutopilot: NSObject, GSRobotProtocol {
	public override required init() {
		super.init()
	}
	
	public static var minimumRobotInterfaceVersionRequired: Int32 {
		return GS_ROBOT_CURRENT_INTERFACE_VERSION
	}
	
	public func stepXBoloRobot(with gameState: UnsafePointer<GSRobotGameState>!, freeFunction freeF: (@convention(c) (UnsafeMutableRawPointer?) -> Void)!, freeContext freeCtx: UnsafeMutableRawPointer!) -> GSRobotCommandState {
		var state = GSRobotCommandState()
		//let messages = gameState.memory.messages?.takeUnretainedValue() as? NSArray as? [String]
		let tanks = UnsafeBufferPointer(start: gameState.pointee.tanks, count: Int(gameState.pointee.tankscount))
		//let shells = UnsafeBufferPointer(start: gameState.memory.shells, count: Int(gameState.memory.shellscount))
		//let builders = UnsafeBufferPointer(start: gameState.memory.builders, count: Int(gameState.memory.builderscount))
		var targetTank: Tank?
		for tank in tanks {
			if targetTank == nil {
				targetTank = tank
				continue
			}
		}
		state.accelerate = true
		
		return state
	}
}
