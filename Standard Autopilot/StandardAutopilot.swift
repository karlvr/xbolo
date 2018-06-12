//
//  StandardAutopilot.swift
//  XBolo
//
//  Created by C.W. Betts on 7/2/16.
//  Copyright © 2016 Robert Chrzanowski. All rights reserved.
//

import Foundation
import BoloKit

public class StandardAutopilot: NSObject, GSRobotProtocol {
	public override required init() {
		super.init()
	}
	
	public static var minimumRobotInterfaceVersionRequired: Int32 {
		return GS_ROBOT_CURRENT_INTERFACE_VERSION
	}
	
	public func stepXBoloRobot(with gameState: GSRobotGameState, freeFunction freeF: @escaping (@convention(c) (UnsafeMutableRawPointer) -> Void), freeContext freeCtx: UnsafeMutableRawPointer) -> GSRobotCommandState {
		defer {
			freeF(freeCtx)
		}
		let state = GSRobotCommandState()
		//let messages = gameState.messages
		let tanks = UnsafeBufferPointer(start: gameState.tanks, count: Int(gameState.tankscount))
		//let shells = UnsafeBufferPointer(start: gameState.shells, count: Int(gameState.shellscount))
		//let builders = UnsafeBufferPointer(start: gameState.builders, count: Int(gameState.builderscount))
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
