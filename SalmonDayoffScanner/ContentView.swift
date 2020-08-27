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
  @State var orientation = UIApplication.shared.statusBarOrientation

  @State private var status: SDSScreenStatus = .Initialized
  @State private var settings = SDSSettings.get()
  @State private var synth = AVSpeechSynthesizer()
  @State private var timer: Timer? = nil

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
    case .portrait: return ("请对准上方摄像头", "arrow.up.circle.fill")
    case .portraitUpsideDown: return ("请对准下方摄像头", "arrow.down.circle.fill")
    case .landscapeRight: return ("请\n对\n准\n左\n侧\n摄\n像\n头", "arrow.left.circle.fill")
    case .landscapeLeft: return ("请\n对\n准\n右\n侧\n摄\n像\n头", "arrow.right.circle.fill")
    default: return ("请对准摄像头", nil)
    }
  }

  var cameraHints: some View {
    Group {
      if orientation == .portraitUpsideDown || orientation == .landscapeLeft {
        Text(cameraHintValue.0).font(.system(size: 40, weight: .bold))
      }
      if let icon = cameraHintValue.1 {
        Image(systemName: icon)
          .imageScale(.large)
          .font(.system(size: 40, weight: .black))
          .padding()
      }
      if orientation == .portrait || orientation == .landscapeRight {
        Text(cameraHintValue.0).font(.system(size: 40, weight: .bold))
      }
    }
      .opacity(statusInfo.hideScanning ? 0 : 1)
      .foregroundColor(.orange)
  }

  var indicator: some View {
    Text("\(settings.name) \(settings.direction == .in ? "入校" : "出校")方向") +
    Text(" · 成功 \(settings.stats!.success) | 失败 \(settings.stats!.fail) | 错误 \(settings.stats!.error)")
  }

  var screenStatus: some View {
    Group {
      Text(statusInfo.title).font(.system(size: 70, weight: .black))
      Text(statusInfo.desc).font(.system(size: 40, weight: .bold)).multilineTextAlignment(.center)
    }.padding()
  }

  var scanner: some View {
    CodeScannerView(codeTypes: [.qr]) { res in
      guard !self.statusInfo.hideScanning else { return }
      switch res {
      case let .success(str):
        if timer != nil {
          timer?.invalidate()
          timer = nil
        }
        synth.stopSpeaking(at: .immediate)
        handleScan(
          str,
          with: settings,
          onSettingsUpdate: { self.settings = $0 },
          onScreenUpdate: {
            self.status = $0

            if $0 != .Valid && $0 != .Loading && $0 != .Initialized {
              timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in self.status = .Initialized }
            }

            try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            var voiceHint = ""

            switch $0 {
            case .SystemError, .Unauthorized: settings.stats?.error += 1
            case .CheckInSuccess, .CheckOutSuccess:
              settings.stats?.success += 1
              voiceHint = "验证通过"
            case .InvalidTicket, .InvalidDirection:
              settings.stats?.fail += 1
              voiceHint = "禁止通行"
            default: print("counting nothing")
            }

            let utterance = AVSpeechUtterance(string: voiceHint)
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
            utterance.rate = 0.8 * AVSpeechUtteranceDefaultSpeechRate + 0.2 * AVSpeechUtteranceMaximumSpeechRate
            synth.speak(utterance)

            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

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
          if orientation == .landscapeRight { cameraHints }
          VStack {
            scanner.frame(width: 400, height: 500, alignment: .center)
            indicator
          }.padding()
          VStack {
            screenStatus
          }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
          if orientation == .landscapeLeft { cameraHints }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else {
        VStack {
          Text("獲取裝置朝向失敗，非正常 iPad 裝置")
        }
      }
    }
      .background(bgColor)
      .edgesIgnoringSafeArea(.all)
    .onReceive(NotificationCenter.Publisher(center: .default, name: UIApplication.didChangeStatusBarOrientationNotification)) { _ in
      self.orientation = UIApplication.shared.statusBarOrientation
    }
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
