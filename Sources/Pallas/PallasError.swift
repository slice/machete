public import Foundation

public enum PallasError: Error {
  case httpNotOk(URLResponse)
  case illFormedResponse(reason: String, URLResponse)
}
