//
//  AsyncImageFetcher.swift
//  Alkeon
//
//  Created by Andrea Sacerdoti on 18/03/21.
//

import UIKit
import Combine

/// A LocalizedError related to image fetching.
public enum ImageFetchError: LocalizedError {
  case invalidData
  case invalidURL

  /// The error description String.
  public var errorDescription: String? {
    switch self {
    case .invalidData:
      return NSLocalizedString("Unable to fetch image from data", comment: "")
    case .invalidURL:
      return NSLocalizedString("Image URL is invalid", comment: "")
    }
  }
}

class AsyncImageFetcher {
  /// The static cache in which to store remotely fetched images.
  static let cache = NSCache<NSString, AnyObject>()
}

extension UIImage {
  /// Returns a publisher which fetches a UIImage from a URL.
  /// - Parameter urlString: The URL (in String format) from which to fetch the image.
  public static func load(from urlString: String) -> AnyPublisher<UIImage?, ImageFetchError> {
    guard let url = URL(string: urlString) else {
      return Fail(error: ImageFetchError.invalidURL)
        .eraseToAnyPublisher()
    }

    if let cachedImage = AsyncImageFetcher.cache.object(forKey: NSString(string: urlString)) as? UIImage {
      return Just(cachedImage)
        .setFailureType(to: ImageFetchError.self)
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
      .mapError { _ in
        ImageFetchError.invalidData
      }
      .eraseToAnyPublisher()
  }
}
