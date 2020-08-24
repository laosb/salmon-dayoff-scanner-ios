//
//  ContentView.swift
//  SalmonDayoffScanner
//
//  Created by Shibo Lyu on 2020/8/24.
//  Copyright © 2020 Inkwire Technology (Hangzhou) Co., Ltd. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  @State private var status: SDSScreenStatus = .Initialized
  @State private var settings = SDSSettings.get()

  var statusInfo: StatusInfo { getStatusInfoFor(status) }
  var bgColor: Color {
    switch statusInfo.visual {
    case .Neutral: return .init(.systemBackground)
    case .Negative: return .red
    case .Positive: return .green
    }
  }

  var body: some View {
    ZStack {
      VStack {
        Group {
          Image(systemName: "arrow.up.circle.fill")
            .imageScale(.large)
            .font(.custom("", size: 30))
            .padding()
          Text("请将请假码对准上方摄像头").font(.custom("", size: 30))
          Spacer()
          CodeScannerView(codeTypes: [.qr]) { res in
            guard !self.statusInfo.hideScanning else { return }
            switch res {
            case let .success(str):
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
                  case .SystemError, .Unauthorized: self.settings.stats?.error += 1
                  case .CheckInSuccess, .CheckOutSuccess: self.settings.stats?.success += 1
                  case .InvalidTicket, .InvalidDirection: self.settings.stats?.fail += 1
                  default: print("counting nothing")
                  }
                  self.settings.persist()
                }
              )
            case .failure: self.status = .SystemError
            }
          }
          .frame(width: 400, height: 500, alignment: .center)
        }.opacity(statusInfo.hideScanning ? 0 : 1)
        Group {
          Text(statusInfo.title).font(.custom("", size: 70)).fontWeight(.black)
          Text(statusInfo.desc).font(.custom("", size: 40)).multilineTextAlignment(.center)
        }.padding()
        Spacer()
        Text("\(settings.name) \(settings.direction == .in ? "入校" : "出校")方向") +
        Text(" · 成功 \(settings.stats!.success) | 失败 \(settings.stats!.fail) | 错误 \(settings.stats!.error)")
      }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
      .background(bgColor)
      .edgesIgnoringSafeArea(.all)
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
