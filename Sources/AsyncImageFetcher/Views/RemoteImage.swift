//
//  RemoteImage.swift
//  Alkeon
//
//  Created by Andrea Sacerdoti on 18/03/21.
//

import SwiftUI

struct RemoteImage: View {
  @State var url: String
  @State private var image: UIImage?
  @State private var placeholderOpacity = 0.2
  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  var placeholder: (() -> AnyView)? = nil

  var body: some View {
    if let image = image {
      Image(uiImage: image)
    } else if let placeholder = placeholder {
      placeholder()
    } else {
      ZStack {
        Color.black.opacity(placeholderOpacity)
          .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 1)) {
              placeholderOpacity = placeholderOpacity == 0.2 ? 0.4 : 0.2
            }
          }

        Text("Loading...")
      }
    }
  }
}

struct RemoteImage_Previews: PreviewProvider {
  static var previews: some View {
    RemoteImage(url: "")
  }
}
