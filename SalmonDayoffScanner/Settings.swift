//
//  Settings.swift
//  SalmonDayoffScanner
//
//  Created by Shibo Lyu on 2020/8/24.
//  Copyright © 2020 Inkwire Technology (Hangzhou) Co., Ltd. All rights reserved.
//

import Foundation

struct SDSSettings: Codable {
  struct Stats: Codable {
    var success: Int
    var fail: Int
    var error: Int
  }

  var token: String
  var direction: SDSTicketCheckinPayload.Direction
  var name: String
  var stats: Stats?

  private static let udStore = UserDefaults.standard
  private static let settingsKey = "settings"

  static func getDefault () -> Self {
    Self(token: "", direction: .in, name: "默认闸口", stats: Stats(success: 0, fail: 0, error: 0))
  }

  func persist () {
    let data = try! JSONEncoder().encode(self)
    SDSSettings.udStore.setValue(data, forKey: SDSSettings.settingsKey)
  }

  static func fromJson (_ json: String) -> Self? {
    Self.fromJson(json.data(using: .utf8) ?? Data())
  }
  static func fromJson (_ json: Data) -> Self? {
    try? JSONDecoder().decode(Self.self, from: json)
  }

  static func get () -> Self {
    let data = SDSSettings.udStore.data(forKey: SDSSettings.settingsKey)
    guard let obj = Self.fromJson(data ?? Data()) else { return Self.getDefault() }
    return obj
  }

  static func `import` (_ settings: Self) -> Self {
    var obj = settings
    if obj.stats == nil { obj.stats = Self.get().stats }
    obj.persist()
    return obj
  }
}
