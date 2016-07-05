//
//  BoloURLHandler.swift
//  XBolo
//
//  Created by C.W. Betts on 7/5/16.
//  Copyright © 2016 Robert Chrzanowski. All rights reserved.
//

import Cocoa


@objc(BoloURLHandler) class BoloURLHandler : NSScriptCommand {
	override func performDefaultImplementation() -> AnyObject? {
		guard let param = directParameter as? String else {
			return nil
		}
		
		guard let boloURL = NSURL(string: param) else {
			return nil
		}
		
		guard boloURL.scheme.caseInsensitiveCompare("xbolo") == .OrderedSame else {
			NSBeep()
			return nil
		}
		
		let port = (boloURL.port ?? 50_000).unsignedShortValue
		
		(NSApp.delegate as? GSXBoloController)?.requestConnectionToServer(boloURL.host, port: port)
		
		return nil
	}
}
