//
//  PreviewProviderSwift.swift
//  newQLGenerator
//
//  Created by C.W. Betts on 10/11/22.
//  Copyright © 2022 Robert Chrzanowski. All rights reserved.
//

import Foundation
import Quartz

let MAPFILEIDENT_swift: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0x42, 0x4D, 0x41, 0x50, 0x42, 0x4F, 0x4C, 0x4F)

public class PreviewProviderSwift : QLPreviewProvider, QLPreviewingController {
	
	public func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
		let data = try Data(contentsOf: request.fileURL)
		
		let nbytes = data.count

		guard nbytes > MemoryLayout<BMAP_Preamble>.size else {
			throw CocoaError(.fileReadCorruptFile, userInfo: [NSURLErrorKey: request.fileURL])
		}
		
		let preamble: BMAP_Preamble = data.withUnsafeBytes { urbp -> BMAP_Preamble in
			return urbp.load(as: BMAP_Preamble.self)
		}
		
		guard preamble.ident.0 == MAPFILEIDENT_swift.0, preamble.ident.1 == MAPFILEIDENT_swift.1, preamble.ident.2 == MAPFILEIDENT_swift.2, preamble.ident.3 == MAPFILEIDENT_swift.3, preamble.ident.4 == MAPFILEIDENT_swift.4, preamble.ident.5 == MAPFILEIDENT_swift.5, preamble.ident.6 == MAPFILEIDENT_swift.6, preamble.ident.7 == MAPFILEIDENT_swift.7 else {
			throw CocoaError(.fileReadCorruptFile, userInfo: [NSURLErrorKey: request.fileURL])
		}
		
		guard preamble.version == CURRENTMAPVERSION else {
			throw CocoaError(.fileReadCorruptFile, userInfo: [NSURLErrorKey: request.fileURL])
		}
		
		guard preamble.npills <= MAX_PILLS else {
			throw CocoaError(.fileReadCorruptFile, userInfo: [NSURLErrorKey: request.fileURL])
		}
		
		guard preamble.nbases <= MAX_BASES else {
			throw CocoaError(.fileReadCorruptFile, userInfo: [NSURLErrorKey: request.fileURL])
		}
		
		guard preamble.nstarts <= MAXSTARTS else {
			throw CocoaError(.fileReadCorruptFile, userInfo: [NSURLErrorKey: request.fileURL])
		}
		
		guard nbytes >= MemoryLayout<BMAP_Preamble>.size +
				Int(preamble.npills) * MemoryLayout<BMAP_PillInfo>.size +
				Int(preamble.nbases) * MemoryLayout<BMAP_BaseInfo>.size +
				Int(preamble.nstarts) * MemoryLayout<BMAP_StartInfo>.size else {
			throw CocoaError(.fileReadCorruptFile, userInfo: [NSURLErrorKey: request.fileURL])
		}
		
		let reply = QLPreviewReply(contextSize: CGSize(width: 256, height: 256), isBitmap: false) { context, reply in
			
			var offset = 0
			var minx: Int32 = 256, maxx: Int32 = 0, miny: Int32 = 256, maxy: Int32 = 0;

			/* turn off antialiasing */
			context.setShouldAntialias(false)

			/* draw deep sea */
			context.setFillColor(myGetBlueColor())
			context.fill(CGRect(x: 0, y: 0, width: 256, height: 256))

			/* invert y axis */
			context.translateBy(x: 0, y: 256)
			context.scaleBy(x: 1, y: -1)

			let pillInfos: [BMAP_PillInfo]
			let baseInfos: [BMAP_BaseInfo]
			let startInfos: [BMAP_StartInfo]
			let runData: Data
			let runDataLen: Int
			do {
				var dataSubrange = MemoryLayout<BMAP_Preamble>.size ..< (MemoryLayout<BMAP_Preamble>.size + Int(preamble.npills) * MemoryLayout<BMAP_PillInfo>.size)
				var data2 = data[dataSubrange]
				pillInfos = data2.withUnsafeBytes { urbp -> [BMAP_PillInfo] in
					let var1 = urbp.bindMemory(to: BMAP_PillInfo.self)
					return [BMAP_PillInfo](var1)
				}
				dataSubrange = dataSubrange.last! ..< (dataSubrange.last! + Int(preamble.nbases) * MemoryLayout<BMAP_BaseInfo>.size)
				data2 = data[dataSubrange]
				baseInfos = data2.withUnsafeBytes { urbp -> [BMAP_BaseInfo] in
					let var1 = urbp.bindMemory(to: BMAP_BaseInfo.self)
					return [BMAP_BaseInfo](var1)
				}
				dataSubrange = dataSubrange.last! ..< (dataSubrange.last! + Int(preamble.nstarts) * MemoryLayout<BMAP_StartInfo>.size)
				data2 = data[dataSubrange]
				startInfos = data2.withUnsafeBytes { urbp -> [BMAP_StartInfo] in
					let var1 = urbp.bindMemory(to: BMAP_StartInfo.self)
					return [BMAP_StartInfo](var1)
				}
				runData = data[dataSubrange.last! ..< nbytes]
				runDataLen = runData.count
			}

			repeat {
				guard offset + MemoryLayout<BMAP_Run>.size <= runDataLen else {
					break
				}

				let run = runData.withUnsafeBytes { urbp -> BMAP_Run in
					return urbp.load(fromByteOffset: offset, as: BMAP_Run.self)
				}
				
				if run.datalen == 4 && run.y == 0xff && run.startx == 0xff && run.endx == 0xff {
					break
				}
				
				if offset + Int(run.datalen) > runDataLen {
					break
				}
				
				if run.y < miny {
					miny = Int32(run.y)
				}
				if run.y > maxy {
					maxy = Int32(run.y)
				}
				
				if run.startx < minx {
					minx = Int32(run.startx)
				}
				if run.endx > maxx {
					maxx = Int32(run.endx)
				}
				
				offset += Int(run.datalen)
			} while true
			
			minx -= 3
			if minx < 0 {
				minx = 0
			}
			
			maxx += 3
			if maxx > 256 {
				maxx = 256
			}
			
			miny -= 3
			if miny < 0 {
				miny = 0
			}
			
			maxy += 3
			if maxy > 256 {
				maxy = 256
			}

			if maxx - minx > maxy - miny {
				context.scaleBy(x: 256.0/CGFloat(maxx - minx), y: 256.0/CGFloat(maxx - minx))
				context.translateBy(x: -CGFloat(minx), y: -CGFloat(miny) + CGFloat((maxx - minx) - (maxy - miny))/2)
			} else {
				context.scaleBy(x: 256.0/CGFloat(maxy - miny), y: 256.0/CGFloat(maxy - miny))
				context.translateBy(x: -CGFloat(minx) + CGFloat((maxy - miny) - (maxx - minx))/2, y: -CGFloat(miny))
			}

			/* begin drawing terrain */

			offset = 0

			repeat {
				guard offset + MemoryLayout<BMAP_Run>.size <= runDataLen else {
					break
				}
				
				let run = runData.withUnsafeBytes { urbp in
					urbp.load(fromByteOffset: offset, as: BMAP_Run.self)
				}
				
				if run.datalen == 4 && run.y == 0xff && run.startx == 0xff && run.endx == 0xff {
					break
				}
				
				if offset + Int(run.datalen) > runDataLen {
					break
				}

				let drawStatus = runData.withUnsafeBytes { urbp in
					let rawDat = urbp.baseAddress!.advanced(by: offset + MemoryLayout<BMAP_Run>.size)
					return drawrun(context, run, rawDat)
				}
				
				guard drawStatus == 0 else {
					throw CocoaError(.fileReadCorruptFile, userInfo: [NSURLErrorKey: request.fileURL])
				}
				
				offset += Int(run.datalen)
			} while true
			
			context.setFillColor(myGetYellowColor())
			for bases in baseInfos {
				context.fill(CGRect(x: Int(bases.x), y: Int(bases.y), width: 1, height: 1))
			}
			
			context.setFillColor(myGetRedColor())
			for pill in pillInfos {
				context.fill(CGRect(x: Int(pill.x), y: Int(pill.y), width: 1, height: 1))
			}
			
			context.setFillColor(myGetGreyColor())
			for start in startInfos {
				context.fill(CGRect(x: Int(start.x), y: Int(start.y), width: 1, height: 1))
			}
		}
		
		return reply
	}
}
