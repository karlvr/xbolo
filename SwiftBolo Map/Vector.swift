//
//  Vector.swift
//  XBolo
//
//  Created by C.W. Betts on 5/28/16.
//  Copyright © 2016 Robert Chrzanowski. All rights reserved.
//

import Foundation
import simd

let INT16RADIX = 256
let INT32RADIX = 65536
let kPif: Float =  3.14159265358979;
let k2Pif: Float = 6.28318530717959;


struct Vec2i16 {
	var x: Int16 = 0
	var y: Int16 = 0
}

struct Vec2i8 {
	var x: Int8
	var y: Int8
}

struct Vec2u8 {
	var x: UInt8
	var y: UInt8
}

extension float2: Equatable {}
extension int2: Equatable {}

typealias Vec2f = simd.float2
typealias Vec2i32 = simd.int2

func make2f(x: Float, _ y: Float) -> Vec2f {
	return Vec2f(x: x, y: y)
}

func neg2f(v: Vec2f) -> Vec2f {
	return -v
}

func add2f(v1: Vec2f, _ v2: Vec2f) -> Vec2f {
	return v1 + v2
}
func sub2f(v1: Vec2f, _ v2: Vec2f) -> Vec2f {
	return v1 - v2
}
func mul2f(v: Vec2f, _ s: Float) -> Vec2f {
	return v * s
}
func div2f(v: Vec2f, _ s: Float) -> Vec2f {
	return v / Vec2f(s)
}

func dot2f(v1: Vec2f, _ v2: Vec2f) -> Float {
	return v1.x*v2.x + v1.y*v2.y
	//return distance_squared(v1, v2)
}

func mag2f(v: Vec2f) -> Float {
	return sqrt(dot2f(v, v));
}

func unit2f(v: Vec2f) -> Vec2f {
	return div2f(v, mag2f(v));
}

func prj2f(v1: Vec2f, _ v2: Vec2f) -> Vec2f {
	return mul2f(v1, dot2f(v1, v2)/dot2f(v1, v1));
}

public func ==(v1: float2, v2: float2) -> Bool {
	return v1.x == v2.x && v1.y == v2.y;
}


func isequal2f(v1: Vec2f, _ v2: Vec2f) -> Bool {
	return v1.x == v2.x && v1.y == v2.y;
}

func tan2f(theta: Float) -> Vec2f {
	return make2f(cos(theta), sin(theta));
}

func _atan2f(dir: Vec2f) -> Float {
	return atan2(dir.y, dir.x);
}


struct Fixed16 {
	var rawValue: Int16 = 0
	var toFloat: Float {
		return Float(rawValue)/Float(INT16RADIX)
	}
}

struct FixedU16 {
	var rawValue: UInt16 = 0
	var toFloat: Float {
		return Float(rawValue)/Float(INT16RADIX)
	}
}

extension FixedU16 {
	init(float: Float) {
		rawValue = UInt16(float*Float(INT16RADIX))
	}
}

extension Fixed16 {
	init(float: Float) {
		rawValue = Int16(float*Float(INT16RADIX))
	}
}

func make2i32(x: Int32, _ y: Int32) -> Vec2i32 {
	return Vec2i32(x, y);
}

func neg2i32(v: Vec2i32) -> Vec2i32 {
	return -v
}

func +(lhs: Vec2i32, rhs: Vec2i32) -> Vec2i32 {
	return int2(lhs.x + rhs.x, lhs.y + rhs.y);
}

func -(lhs: Vec2i32, rhs: Vec2i32) -> Vec2i32 {
	return int2(lhs.x - rhs.x, lhs.y - rhs.y);
}


func add2i32(v1: Vec2i32, _ v2: Vec2i32) -> Vec2i32 {
	return v1 + v2
}

func sub2i32(v1: Vec2i32, _ v2: Vec2i32) -> Vec2i32 {
	return v1 - v2
}

func mul2i32(v: Vec2i32, _ s: Int32) -> Vec2i32 {
	return make2i32(v.x*s, v.y*s);
}

func div2i32(v: Vec2i32, _ s: Int32) -> Vec2i32 {
	return make2i32(v.x/s, v.y/s);
}

func dot2i32(v1: Vec2i32, _ v2: Vec2i32) -> Int32 {
	return v1.x*v2.x + v1.y*v2.y;
}

func mag2i32(v: Vec2i32) -> Int32 {
	return Int32(sqrt(Double(dot2i32(v, v))))
}

func prj2i32(v1: Vec2i32, _ v2: Vec2i32) -> Vec2i32 {
	return mul2i32(v1, dot2i32(v1, v2)/dot2i32(v1, v1));
}

func cmp2i32(v1: Vec2i32, _ v2: Vec2i32) -> Int32 {
	return dot2i32(v1, v2)/mag2i32(v1);
}

public func ==(v1: int2, v2: int2) -> Bool {
	return v1.x == v2.x && v1.y == v2.y;
}


func isequal2i32(v1: Vec2i32, v2: Vec2i32) -> Bool {
	return v1 == v2
}

func tan2i32(dir: UInt8) -> Vec2i32 {
	return make2i32(Int32(cos(Float(dir)*(kPif/8.0))*Float(INT32_MAX)), Int32(sin(Float(dir)*(kPif/8.0))*Float(INT32_MAX)))
}

func scale2i32(dir: UInt8, scale: Int32) -> Vec2i32 {
	return div2i32(tan2i32(dir), INT32_MAX/scale);
}

func c2i32to2i16(v: Vec2i32) -> Vec2i16 {
	return make2i16(Int16(v.x), Int16(v.y));
}

/*
* returns a vector with x and y
*/

func make2i16(x: Int16, _ y: Int16) -> Vec2i16 {
	return Vec2i16(x: x, y: y)
}


prefix func -(rhs: Vec2i16) -> Vec2i16 {
	return Vec2i16(x: -rhs.x, y: -rhs.y)
}
/*
* r = -v
*/

func neg2i16(v: Vec2i16) -> Vec2i16 {
	return -v
}

func +(v1: Vec2i16, v2: Vec2i16) -> Vec2i16 {
	return Vec2i16(x: v1.x + v2.x, y: v1.y + v2.y)
}
/*
* r = v1 + v2
*/

func add2i16(v1: Vec2i16, _ v2: Vec2i16) -> Vec2i16 {
	return v1 + v2
}

func -(v1: Vec2i16, v2: Vec2i16) -> Vec2i16 {
	return Vec2i16(x: v1.x - v2.x, y: v1.y - v2.y)
}

/*
* r = v1 - v2
*/

func sub2i16(v1: Vec2i16, _ v2: Vec2i16) -> Vec2i16 {
	return v1 - v2
}

/*
* r = v X s
*/

func mul2i16(v: Vec2i16, _ s: Int16) -> Vec2i16 {
	var r = Vec2i16();
	//  r.x = ((int32_t)v.x)*((int32_t)s)/((int32_t)INT16RADIX);
	//  r.y = ((int32_t)v.y)*((int32_t)s)/((int32_t)INT16RADIX);
	r.x = v.x*s;
	r.y = v.y*s;
	return r;
}

/*
* r = v/s
*/

func div2i16(v: Vec2i16, _ s: Int16) -> Vec2i16 {
	var r = Vec2i16();
	//  r.x = ((int32_t)v.x)*((int32_t)INT16RADIX)/((int32_t)s);
	//  r.y = ((int32_t)v.y)*((int32_t)INT16RADIX)/((int32_t)s);
	r.x = v.x/s;
	r.y = v.y/s;
	return r;
}

/*
* r = v1*v2
*/

func dot2i16(v1: Vec2i16, _ v2: Vec2i16) -> Int16 {
	return v1.x*v2.x + v1.y*v2.y;
}

/*
* r = |v|
*/

func mag2i16(v: Vec2i16) -> Int16 {
	return Int16(sqrt(Float(dot2i16(v, v))))
}

/*
* r = v1.proj(v2)
*/

func prj2i16(v1: Vec2i16, v2: Vec2i16) -> Vec2i16 {
	return mul2i16(v1, dot2i16(v1, v2)/dot2i16(v1, v1));
}

/*
* r = v1.comp(v2)
*/

func cmp2i16(v1: Vec2i16, v2: Vec2i16) -> Int16 {
	return dot2i16(v1, v2)/mag2i16(v1);
}

func ==(v1: Vec2i16, v2: Vec2i16) -> Bool {
	return v1.x == v2.x && v1.y == v2.y;
}

/*
* returns 0 if v1 != v2
*/

func isequal2i16(v1: Vec2i16, v2: Vec2i16) -> Bool {
	return v1.x == v2.x && v1.y == v2.y;
}

func tan2i16(dir: UInt8) -> Vec2i16 {
	return make2i16(Int16(cos(Float(dir)*(kPif/8.0))*Float(INT16_MAX)), Int16(sin(Float(dir)*(kPif/8.0))*Float(INT16_MAX)))
}

func scale2i16(dir: UInt8, scale: Int16) -> Vec2i16 {
	return div2i16(tan2i16(dir), Int16.max/scale);
}

func c2i16to2i8(v: Vec2i16) -> Vec2i8 {
	return make2i8(Int8(v.x), Int8(v.y));
}

/*
* U8to2i16() converts dir to a vector.
*/

func make2i8(x: Int8, _ y: Int8) -> Vec2i8 {
	return Vec2i8(x: x, y: y)
}

func ==(v1: Vec2i8, v2: Vec2i8) -> Bool {
	return v1.x == v2.x && v1.y == v2.y;
}

func isequal2i8(v1: Vec2i8, _ v2: Vec2i8) -> Bool {
	return v1.x == v2.x && v1.y == v2.y;
}
