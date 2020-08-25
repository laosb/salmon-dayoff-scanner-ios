//
//  ContentView.swift
//  SalmonDayoffScanner
//
//  Created by Shibo Lyu on 2020/8/24.
//  Copyright © 2020 Inkwire Technology (Hangzhou) Co., Ltd. All rights reserved.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
  @State var orientation: UIDeviceOrientation = UIDevice.current.orientation

  @State private var status: SDSScreenStatus = .Initialized
  @State private var settings = SDSSettings.get()
  @State private var synth = AVSpeechSynthesizer()

  var statusInfo: StatusInfo { getStatusInfoFor(status) }
  var bgColor: Color {
    switch statusInfo.visual {
    case .Neutral: return .init(.systemBackground)
    case .Negative: return .red
    case .Positive: return .green
    }
  }
  var cameraHintValue: (String, String?) {
    switch orientation {
    case .portrait: return ("请将请假码对准上方摄像头", "arrow.up.circle.fill")
    case .portraitUpsideDown: return ("请将请假码对准下方摄像头", "arrow.down.circle.fill")
    case .landscapeLeft: return ("请\n将\n请\n假\n码\n对\n准\n左\n侧\n摄\n像\n头", "arrow.left.circle.fill")
    case .landscapeRight: return ("请\n将\n请\n假\n码\n对\n准\n右\n侧\n摄\n像\n头", "arrow.right.circle.fill")
    default: return ("请将请假码对准摄像头", nil)
    }
  }

  var cameraHints: some View {
    Group {
      if orientation == .portraitUpsideDown || orientation == .landscapeRight {
        Text(cameraHintValue.0).font(.custom("", size: 30))
      }
      if let icon = cameraHintValue.1 {
        Image(systemName: icon)
          .imageScale(.large)
          .font(.custom("", size: 30))
          .padding()
      }
      if orientation == .portrait || orientation == .landscapeLeft {
        Text(cameraHintValue.0).font(.custom("", size: 30))
      }
    }.opacity(statusInfo.hideScanning ? 0 : 1)
  }

  var indicator: some View {
    Text("\(settings.name) \(settings.direction == .in ? "入校" : "出校")方向") +
    Text(" · 成功 \(settings.stats!.success) | 失败 \(settings.stats!.fail) | 错误 \(settings.stats!.error)")
  }

  var screenStatus: some View {
    Group {
      Text(statusInfo.title).font(.custom("", size: 70)).fontWeight(.black)
      Text(statusInfo.desc).font(.custom("", size: 40)).multilineTextAlignment(.center)
    }.padding()
  }

  var scanner: some View {
    CodeScannerView(codeTypes: [.qr]) { res in
      guard !self.statusInfo.hideScanning else { return }
      switch res {
      case let .success(str):
        synth.stopSpeaking(at: .immediate)
        handleScan(
          str,
          with: settings,
          onSettingsUpdate: { self.settings = $0 },
          onScreenUpdate: {
            self.status = $0

            if $0 != .Valid && $0 != .Loading && $0 != .Initialized {
              Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in self.status = .Initialized }
            }

            switch $0 {
            case .SystemError, .Unauthorized: settings.stats?.error += 1
            case .CheckInSuccess, .CheckOutSuccess:
              settings.stats?.success += 1
              synth.speak(.init(string: "验证通过"))
            case .InvalidTicket, .InvalidDirection:
              settings.stats?.fail += 1
              synth.speak(.init(string: "禁止通行"))
            default: print("counting nothing")
            }
            self.settings.persist()
          }
        )
      case .failure: self.status = .SystemError
      }
    }.opacity(statusInfo.hideScanning ? 0 : 1)
  }

  var body: some View {
    Group {
      if orientation.isPortrait {
        VStack {
          if orientation == .portrait { cameraHints } else { indicator }
          Spacer()
          scanner.frame(width: 400, height: 500, alignment: .center)
          screenStatus
          Spacer()
          if orientation == .portraitUpsideDown { cameraHints } else { indicator }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else if orientation.isLandscape {
        HStack {
          if orientation == .landscapeLeft { cameraHints }
          VStack {
            scanner.frame(width: 400, height: 500, alignment: .center)
            indicator
          }.padding()
          VStack {
            screenStatus
          }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
          if orientation == .landscapeRight { cameraHints }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else {
        VStack {
          Text("为方便扫码，请不要平放 iPad。")
          Text("如必须平放，请先竖起 iPad 并转动来选择一个方向，然后锁定屏幕旋转后再放平。")
        }
      }
    }
      .background(bgColor)
      .edgesIgnoringSafeArea(.all)
      .onReceive(NotificationCenter.Publisher(center: .default, name: UIDevice.orientationDidChangeNotification)) { _ in
        self.orientation = UIDevice.current.orientation
      }

  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
