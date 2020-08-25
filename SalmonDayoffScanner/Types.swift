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

struct SDSDayoffTicketResponseData: Codable {
  enum `Type`: Int, Codable {
    case Under2Hours = 1
    case Over2Hours = 2
    case Intern = 3
    case Other = 4
  }
  enum Status: Int, Codable {
    case NoRecord = 0 //無出入紀錄
    case RecordFound = 1 //有出入紀錄
    case Invalid = 2 //失效
  }
  enum LastDirection: Int, Codable {
    case NoRecord = 0
    case In = 1
    case Out = 2
  }
  struct Dayoff: Codable {
    var DayOffType: Type
    var OutTime: Date? //出门时间
    var BackTime: Date? //返回时间
    var Status: Status
    var Direction: LastDirection //最後出入方向
    var UID: String
  }
  struct Request: Codable {
    var StaffID: String //学号
    var StaffName: String //姓名
    var School: String = "hdu"
    var TemplateID: String
    var InputValue: String
    var ExtraData: String
  }

  var dayOff: Dayoff
  var request: Request
}
typealias SDSDayoffTicketResponse = LMResponse<SDSDayoffTicketResponseData>

struct SDSTicketCheckinPayload: Codable {
  enum Direction: Int, Codable {
    case `in` = -1, out = 1
  }
  var ticket: String
  var type: Direction
}
