//
//  AsyncImageFetcher.swift
//  Alkeon
//
//  Created by Andrea Sacerdoti on 18/03/21.
//

import UIKit
import Combine

enum ImageFetchError: LocalizedError {
  case invalidData
  case invalidURL

  var errorDescription: String? {
    switch self {
    case .invalidData:
      return NSLocalizedString("Unable to fetch image from data", comment: "")
    case .invalidURL:
      return NSLocalizedString("Image URL is invalid", comment: "")
    }
  }
}

class AsyncImageFetcher {
  static let cache = NSCache<NSString, AnyObject>()
}

extension UIImage {
  static func load(from urlString: String) -> AnyPublisher<UIImage?, Error> {
    guard let url = URL(string: urlString) else {
      return Fail(error: ImageFetchError.invalidURL)
        .eraseToAnyPublisher()
    }

    if let cachedImage = AsyncImageFetcher.cache.object(forKey: NSString(string: urlString)) as? UIImage {
      return Just(cachedImage)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }

    return URLSession.shared.dataTaskPublisher(for: url)
      .map(\.data)
      .tryCompactMap { data in
        guard let image = UIImage(data: data) else {
          throw ImageFetchError.invalidData
        }

        AsyncImageFetcher.cache.setObject(image, forKey: NSString(string: urlString))
        return image
      }
      .handleEvents(receiveOutput: { image in
        if let image = image {
          AsyncImageFetcher.cache.setObject(image, forKey: NSString(string: urlString))
        }
      })
      .eraseToAnyPublisher()
  }
}
