//
//  BoloURLHandler.swift
//  XBolo
//
//  Created by C.W. Betts on 7/5/16.
//  Copyright © 2016 Robert Chrzanowski. All rights reserved.
//

import Cocoa


@objc(BoloURLHandler) class BoloURLHandler : NSScriptCommand {
	override func performDefaultImplementation() -> Any? {
		guard let param = directParameter as? String else {
			return nil
		}
		
		guard let boloURL = NSURL(string: param) else {
			return nil
		}
		
		// Only respond to xbolo schemes
		// TODO: how different is this from nubolo and old bolo?
		guard boloURL.scheme?.caseInsensitiveCompare("xbolo") == .orderedSame else {
			NSSound.beep()
			return nil
		}
		
		// If no port specified, use default port 50,000
		let port = (boloURL.port ?? 50_000).uint16Value
		if let host = boloURL.host {
			(NSApp.delegate as? GSXBoloController)?.requestConnection(toServer: host, port: port, password: boloURL.password)
		}
		
		return nil
	}
}
