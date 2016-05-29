//
//  vector_Swift.swift
//  XBolo
//
//  Created by C.W. Betts on 5/29/16.
//  Copyright © 2016 Robert Chrzanowski. All rights reserved.
//

import Foundation

extension Vec2f: Equatable {}
extension Vec2i32: Equatable {}

prefix func -(v: Vec2f) -> Vec2f {
  return neg2f(v)
}

func +(v1: Vec2f, v2: Vec2f) -> Vec2f {
  return add2f(v1, v2)
}

func -(v1: Vec2f, v2: Vec2f) -> Vec2f {
  return sub2f(v1, v2)
}

func *(v: Vec2f, s: Float) -> Vec2f {
  return mul2f(v, s)
}

func /(v: Vec2f, s: Float) -> Vec2f {
  return div2f(v, s)
}

public func ==(v1: Vec2f, v2: Vec2f) -> Bool {
  return isequal2f(v1, v2)
}

public func ==(v1: Vec2i32, v2: Vec2i32) -> Bool {
  return isequal2i32(v1, v2)
}

func atan2f(dir: Vec2f) -> Float {
  return _atan2f(dir)
}

prefix func -(v: Vec2i32) -> Vec2i32 {
  return neg2i32(v)
}

func +(v1: Vec2i32, v2: Vec2i32) -> Vec2i32 {
  return add2i32(v1, v2)
}

func -(v1: Vec2i32, v2: Vec2i32) -> Vec2i32 {
  return sub2i32(v1, v2)
}

func *(v: Vec2i32, s: Int32) -> Vec2i32 {
  return mul2i32(v, s)
}

func /(v: Vec2i32, s: Int32) -> Vec2i32 {
  return div2i32(v, s)
}

