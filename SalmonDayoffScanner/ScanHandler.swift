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

var lastSuccessRequestId: String = ""

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

    func safeScreenUpdate (_ status: SDSScreenStatus) {
      DispatchQueue.main.async { onScreenUpdate(status) }
    }
    ticketCheckin(ticket, with: settings, headers: headers, onScreenUpdate: safeScreenUpdate)
  } else {
    if var newSettings = SDSSettings.fromJson(text) {
      func importSettings () {
        newSettings = SDSSettings.import(newSettings)
        DispatchQueue.main.async {
          onSettingsUpdate(newSettings)
          onScreenUpdate(.ConfigUpdated)
        }
      }

      if SDSSettings.get().token.isEmpty {
        importSettings()
      } else {
        // Scaned a code of settings but token is already done. Needs to auth first.
        let laCtx = LAContext()
        let reason = "如您不知道为何触发此验证，请选择「取消」。"
        laCtx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
          if success {
            importSettings()
          } else {
            DispatchQueue.main.async {
              onScreenUpdate(.InvalidTicket)
            }
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
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .iso8601

  AF.request(
    "\(apiBaseUrl)/workflow/dayoff/management/checkin?ticketId=\(ticket)",
    method: .post,
    parameters: SDSTicketCheckinPayload(ticket: ticket, type: settings.direction),
    encoder: JSONParameterEncoder(),
    headers: headers
  ) { $0.timeoutInterval = 5 }
    .validate().responseDecodable(
      of: SDSDayoffTicketCheckinResponse.self,
      decoder: decoder
    ) { res in
    switch res.result {
    case let .success(resp):
      lastSuccessRequestId = resp.data
      onScreenUpdate(settings.direction == .out ? .CheckOutSuccess : .CheckInSuccess)
    case .failure:
      guard
        let data = res.data,
        let resp = try? JSONDecoder().decode(LMFailedResponse.self, from: data)
      else {
        onScreenUpdate(.SystemError)
        return
      }

      switch resp.error {
      case 40100, 40101, 40302: onScreenUpdate(.Unauthorized)
      case 40306, 40314: onScreenUpdate(.InvalidTicket)
      case 40316: onScreenUpdate(.InvalidDirection)
      default: onScreenUpdate(.SystemError)
      }
    }
  }
}
