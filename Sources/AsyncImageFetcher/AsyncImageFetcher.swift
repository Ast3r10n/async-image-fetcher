//
//  AsyncImageFetcher.swift
//  Alkeon
//
//  Created by Andrea Sacerdoti on 18/03/21.
//

import UIKit
import Combine

class AsyncImageFetcher {
  static let cache = NSCache<NSString, AnyObject>()
}

extension UIImage {
  static func load(from urlString: String?) -> AnyPublisher<UIImage?, Never> {
    guard let urlString = urlString,
          let url = URL(string: urlString) else {
      return Just(nil)
        .eraseToAnyPublisher()
    }

    if let cachedImage = AsyncImageFetcher.cache.object(forKey: NSString(string: urlString)) as? UIImage {
      return Just(cachedImage)
        .eraseToAnyPublisher()
    }

    return URLSession.shared.dataTaskPublisher(for: url)
      .map(\.data)
      .compactMap { data in
        UIImage(data: data)
      }
      .handleEvents(receiveOutput: { image in
        if let image = image {
          AsyncImageFetcher.cache.setObject(image, forKey: NSString(string: urlString))
        }
      })
      .replaceError(with: nil)
      .eraseToAnyPublisher()
  }
}
