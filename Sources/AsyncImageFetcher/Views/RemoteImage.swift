//
//  RemoteImage.swift
//  Alkeon
//
//  Created by Andrea Sacerdoti on 18/03/21.
//

import SwiftUI
import Combine

public struct RemoteImage: View {
  @State public var url: String
  @State private var image: UIImage?
  @State private var placeholderOpacity = 0.2
  @State private var subscriptions: [AnyCancellable] = []
  @State private var timeoutSeconds = 3
  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  public var placeholder: (() -> AnyView)? = nil

  public init(url: String, placeholder: (() -> AnyView)? = nil) {
    self._url = State(initialValue: url)
    self.placeholder = placeholder
  }

  public var body: some View {
    Group {
      if let image = image {
        Image(uiImage: image)
          .resizable()
      } else if let placeholder = placeholder {
        placeholder()
      } else {
        Color.black.opacity(placeholderOpacity)
          .onReceive(timer) { _ in
            timeoutSeconds -= 1

            if timeoutSeconds <= 0 {
              subscriptions.first?.cancel()
              withAnimation(.easeInOut(duration: 1)) {
                placeholderOpacity = 0.2
              }
            } else {
              withAnimation(.easeInOut(duration: 1)) {
                placeholderOpacity = placeholderOpacity == 0.2 ? 0.4 : 0.2
              }
            }
          }
      }
    }
    .onAppear {
      UIImage.load(from: url)
        .sink(receiveCompletion: { [self] completion in
          subscriptions.first?.cancel()
        }, receiveValue: { [self] value in
          image = value
        })
        .store(in: &subscriptions)
    }
  }
}

public struct RemoteImage_Previews: PreviewProvider {
  public static var previews: some View {
    RemoteImage(url: "")
  }
}
