//
//  Types.swift
//  SalmonDayoffScanner
//
//  Created by Shibo Lyu on 2020/8/24.
//  Copyright © 2020 Inkwire Technology (Hangzhou) Co., Ltd. All rights reserved.
//

import Foundation

struct LMResponse<Data: Codable>: Codable {
  var cache: Bool
  var data: Data
  var error: Int
  var msg: String
}

struct LMFailedResponse: Codable {
  var cache: Bool
  var error: Int
  var msg: String
}

struct SDSTicketCheckinPayload: Codable {
  enum Direction: Int, Codable {
    case `in` = -1, out = 1
  }
  var ticket: String
  var type: Direction
}

typealias SDSDayoffTicketCheckinResponse = LMResponse<String>
