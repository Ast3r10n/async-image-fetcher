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
  public static func load(from url: URL, compression: CGFloat? = nil) -> AnyPublisher<UIImage?, ImageFetchError> {

    if let cachedImage = AsyncImageFetcher.cache.object(forKey: NSString(string: url.absoluteString)) as? UIImage {
      return Just(cachedImage)
        .setFailureType(to: ImageFetchError.self)
        .eraseToAnyPublisher()
    }

    return URLSession.shared.dataTaskPublisher(for: url)
      .map(\.data)
      .tryCompactMap { data in
        let image = UIImage(data: data)
        if let image = image,
           let compression = compression,
           let compressedData = image.jpegData(compressionQuality: compression) {
          return UIImage(data: compressedData)
        }

        return image
      }
      .handleEvents(receiveOutput: { image in
        if let image = image {
          AsyncImageFetcher.cache.setObject(image, forKey: NSString(string: url.absoluteString))
        }
      })
      .mapError { _ in
        ImageFetchError.invalidData
      }
      .eraseToAnyPublisher()
  }

  /// Returns a publisher which fetches a UIImage from a URL.
  /// - Parameter urlString: The URL (in String format) from which to fetch the image.
  public static func load(from urlString: String, compression: CGFloat? = nil) -> AnyPublisher<UIImage?, ImageFetchError> {
    guard let url = URL(string: urlString) else {
      return Fail(error: ImageFetchError.invalidURL)
        .eraseToAnyPublisher()
    }

    return UIImage.load(from: url, compression: compression)
  }
}
