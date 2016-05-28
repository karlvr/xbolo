//
//  BuilderStatusView.swift
//  XBolo
//
//  Created by C.W. Betts on 5/28/16.
//  Copyright © 2016 Robert Chrzanowski. All rights reserved.
//

import Cocoa

class BuilderStatusView : NSView {
	@objc(BuilderStatusViewState) enum State: Int32 {
		case Ready
		case Direction
		case Dead
	}
	
	var state: State = State.Ready {
		didSet {
			if state != oldValue {
				needsDisplay = true
			}
		}
	}
	var direction: CGFloat = 0 {
		didSet {
			if direction != oldValue && state == .Direction {
				needsDisplay = true
			}
		}
	}
	
	override func drawRect(dirtyRect: NSRect) {
		switch (state) {
		case .Direction:
			let bounds = self.bounds;
			NSColor.whiteColor().set()
			let p = NSBezierPath(ovalInRect: NSRect(x: -2, y: -2, width: 4, height: 4))
			p.moveToPoint(NSPoint(x: bounds.size.width*0.25, y: bounds.size.height*0.125))
			p.lineToPoint(NSPoint(x: bounds.size.width*0.5, y: 0.0))
			p.lineToPoint(NSPoint(x: bounds.size.width*0.25, y: -bounds.size.height*0.125))
			p.moveToPoint(.zero)
			p.lineToPoint(NSPoint(x: bounds.size.width*0.5, y: 0.0))
			
			let t = NSAffineTransform()
			t.translateXBy(bounds.size.width*0.5, yBy: bounds.size.height*0.5)
			t.rotateByRadians(direction)
			p.transformUsingAffineTransform(t)
			p.stroke()
			p.fill()
			
		case .Dead:
			NSColor(patternImage: NSImage(named: "StipplePattern")!).set()
			NSBezierPath(ovalInRect: bounds).fill()
			break;
			
		case .Ready:
			break;
		}
		
	}
}
