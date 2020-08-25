//
//  ProcessScan.swift
//  SalmonDayoffScanner
//
//  Created by Shibo Lyu on 2020/8/24.
//  Copyright © 2020 Inkwire Technology (Hangzhou) Co., Ltd. All rights reserved.
//

import Foundation
import Alamofire
import LocalAuthentication

let apiBaseUrl = "https://[REDACTED]"

func handleScan (
  _ text: String,
  with settings: SDSSettings,
  onSettingsUpdate: @escaping (SDSSettings) -> Void,
  onScreenUpdate: @escaping (SDSScreenStatus) -> Void
) {
  let regex = try! NSRegularExpression(pattern: "^https?://qr\\.hduhelp\\.com/pass\\?id=([0-9a-f-]+)")
  if let res = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
    let ticket = String(text[Range(res.range(at: 1), in: text)!])
    let headers: HTTPHeaders = ["Authorization": "token \(settings.token)"]

    onScreenUpdate(.Loading)
    DispatchQueue.global(qos: .userInitiated).async {
      func safeScreenUpdate (_ status: SDSScreenStatus) {
        DispatchQueue.main.async { onScreenUpdate(status) }
      }

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      AF.request("\(apiBaseUrl)/workflow/dayoff/management/ticket?uid=\(ticket)", headers: headers)
        .validate().responseDecodable(
          of: SDSDayoffTicketResponse.self,
          decoder: decoder
        ) { res in
          switch res.result {
          case let .success(resp):
            let noRecord = resp.data.dayOff.Direction == .NoRecord
            let inThenOut = resp.data.dayOff.Direction == .In && settings.direction == .out
            let outThenIn = resp.data.dayOff.Direction == .Out && settings.direction == .in

            if noRecord || inThenOut || outThenIn {
              safeScreenUpdate(.Valid)
              ticketCheckin(ticket, with: settings, headers: headers, onScreenUpdate: safeScreenUpdate)
            } else {
              safeScreenUpdate(.InvalidDirection)
            }
          case .failure:
            guard
              let data = res.data,
              let resp = try? JSONDecoder().decode(LMFailedResponse.self, from: data)
            else {
              safeScreenUpdate(.SystemError)
              return
            }

            switch resp.error {
            case 40100, 40101, 40302: safeScreenUpdate(.Unauthorized)
            case 40306, 40314: safeScreenUpdate(.InvalidTicket)
            default: safeScreenUpdate(.SystemError)
            }
          }
        }
    }
  } else {
    if var newSettings = SDSSettings.fromJson(text) {
      // Scaned a code of settings. Needs to auth first.
      let laCtx = LAContext()
      let reason = "如您不知道为何触发此验证，请选择「取消」。"
      laCtx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
        if success {
          newSettings = SDSSettings.import(newSettings)
          DispatchQueue.main.async {
            onSettingsUpdate(newSettings)
            onScreenUpdate(.ConfigUpdated)
          }
        } else {
          DispatchQueue.main.async {
            onScreenUpdate(.InvalidTicket)
          }
        }
      }
    } else {
      onScreenUpdate(.InvalidTicket)
    }
  }
}

func ticketCheckin (
  _ ticket: String,
  with settings: SDSSettings,
  headers: HTTPHeaders,
  onScreenUpdate: @escaping (SDSScreenStatus) -> Void
) {
  AF.request(
    "\(apiBaseUrl)/workflow/dayoff/management/checkin?ticketId=\(ticket)",
    method: .post,
    parameters: SDSTicketCheckinPayload(ticket: ticket, type: settings.direction),
    encoder: JSONParameterEncoder(),
    headers: headers
  ).validate().response { res in
    switch res.result {
    case .success: onScreenUpdate(settings.direction == .out ? .CheckOutSuccess : .CheckInSuccess)
    case .failure: onScreenUpdate(.SystemError)
    }
  }
}
