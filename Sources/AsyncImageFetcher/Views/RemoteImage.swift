//
//  RemoteImage.swift
//  Alkeon
//
//  Created by Andrea Sacerdoti on 18/03/21.
//

import SwiftUI
import Combine

#if canImport(SwiftUI)
/// A view containing an image and an optional placeholder, asynchronously fetched from a URL.
public struct RemoteImage: View {

  /// The URL from which to fetch the image.
  @State public var url: String
  /// The request timeout in seconds.
  ///
  /// Defaults to 10.
  @State public var timeout: Int

  /// The placeholder to apply while the request is running, or no image could be fetched.
  ///
  /// Defaults to an animated light gray background.
  public var placeholder: (() -> AnyView)? = nil

  @State private var image: UIImage?
  @State private var placeholderOpacity = 0.2
  @State private var subscriptions: [AnyCancellable] = []

  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  /// Creates
  /// - Parameters:
  ///   - url: The URL from which to fetch the image.
  ///   - placeholder: The placeholder to apply while the request is running, or no image could be fetched.
  public init(url: String, timeout: Int = 10, placeholder: (() -> AnyView)? = nil) {
    self._url = State(initialValue: url)
    self._timeout = State(initialValue: timeout)
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
        Color.primary.opacity(placeholderOpacity)
          .onReceive(timer) { _ in
            timeout -= 1

            if timeout <= 0 {
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
          switch completion {
          case .failure(let error):
            if error == ImageFetchError.invalidURL {
              timeout = 0
            }
          default:
            break
          }
          
          subscriptions.first?.cancel()
        }, receiveValue: { [self] value in
          image = value
        })
        .store(in: &subscriptions)
    }
  }
}

#if DEBUG
public struct RemoteImage_Previews: PreviewProvider {
  public static var previews: some View {
    RemoteImage(url: "")
  }
}
#endif
#endif
