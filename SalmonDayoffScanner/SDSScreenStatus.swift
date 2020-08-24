//
//  ScreenStatus.swift
//  SalmonDayoffScanner
//
//  Created by Shibo Lyu on 2020/8/24.
//  Copyright © 2020 Inkwire Technology (Hangzhou) Co., Ltd. All rights reserved.
//

import Foundation

enum SDSScreenStatus {
  case Initialized
  case Loading

  case InvalidTicket
  case InvalidDirection
  case Unauthorized // Insufficient privilege to use this scanner.
  case SystemError

  case Valid // Valid, check in / out in progress.
  case CheckInSuccess
  case CheckOutSuccess
  case ConfigUpdated
}

struct StatusInfo {
  enum VisualStatus {
    case Neutral
    case Positive
    case Negative
  }

  var title: String
  var desc: String
  var visual: VisualStatus
  var hideScanning = false
}

func getStatusInfoFor (_ screenStatus: SDSScreenStatus) -> StatusInfo {
  let ready = "可以继续扫码。"

  switch (screenStatus) {
  case .Initialized: return StatusInfo(title: "已就绪", desc: ready, visual: .Neutral)
  case .Loading: return StatusInfo(title: "查驗中", desc: "系统正在查验请假码状态", visual: .Neutral, hideScanning: true)
  case .InvalidTicket:
    return StatusInfo(
      title: "无效凭证",
      desc: "该二维码不是杭电助手请假单码，或该请假已经过期，禁止出入。",
      visual: .Negative
    )
  case .InvalidDirection:
    return StatusInfo(
      title: "方向错误",
      desc: "本次出入方向与上一次一致，禁止连续出校或入校。",
      visual: .Negative
    )
  case .Unauthorized:
    return StatusInfo(
      title: "没有权限",
      desc: "本机授权失败，请联系相关人员授权",
      visual: .Negative
    )
  case .SystemError:
    return StatusInfo(
      title: "系统错误",
      desc: "发生错误，请尝试重扫，若问题持续存在请联系杭电助手。",
      visual: .Negative
    )

  case .Valid:
    return StatusInfo(
      title: "請稍後",
      desc: "请等待系统完成出入闸状态上报。",
      visual: .Neutral,
      hideScanning: true
    )
  case .CheckInSuccess: return StatusInfo(title: "入校成功", desc: ready, visual: .Positive)
  case .CheckOutSuccess: return StatusInfo(title: "出校成功", desc: ready, visual: .Positive)
  case .ConfigUpdated: return StatusInfo(title: "配置成功", desc: ready, visual: .Positive)
  }
}
