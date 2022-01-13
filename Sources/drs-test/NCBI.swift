//
//  File.swift
//  
//
//  Created by Kenneth Durbrow on 10/21/20.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif

struct SRAA {
    struct IDX: Codable {
        struct AccessionResponse: Codable {
            let drs: String
            let status_code: Int
        }
        let response: [String:AccessionResponse]
        let drs_base: String

        enum CodingKeys: String, CodingKey {
            case drs_base = "drs-base"
            case response
        }

        static func url(for accession: String, submitted: Bool = true, ETL: Bool = false) -> String {
            if submitted && !ETL {
                return "idx/v1/\(accession)"
            }
            var query = [String]()
            if !submitted { query.append("submitted=false") }
            if ETL { query.append("etl=true")}
            return "idx/v1/\(accession)?\(query.joined(separator: "&"))"
        }
    }
    enum SystemType {
        case development
        case production
        case regional
    }
    fileprivate let systemType: SystemType
    init(for systemType: SystemType = .regional) {
        self.systemType = systemType
    }
}

extension SRAA {
    private static let devURL = URL(string: "https://locate-dev.ncbi.nlm.nih.gov/")!
    private static let prdURL = URL(string: "https://locate.ncbi.nlm.nih.gov/")!
    private static let rgnURL = URL(string: "https://locate.be-md.ncbi.nlm.nih.gov/")!

    var locationURL: URL {
        switch systemType {
        case .development:
            return Self.devURL
        case .production:
            return Self.prdURL
        case .regional:
            return Self.rgnURL
        }
    }
}

private extension SRAA {
    /// The configuration used by the shared session
    private static let sessionConfig: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(300)
        config.timeoutIntervalForResource = TimeInterval(300)
        config.urlCache = URLCache.shared
        return config
    }()
    /// The shared session
    static let session = URLSession(configuration: sessionConfig)
}

extension SRAA {
    private func makeRequest(_ url: String, _ expand: Bool, _ passport: String?) -> URLRequest {
        var components = URLComponents(string: url)!
        if expand {
            if let qi = components.queryItems {
                components.queryItems = qi + [URLQueryItem(name: "expand", value: "true")]
            }
            else {
                components.queryItems = [URLQueryItem(name: "expand", value: "true")]
            }
        }
        let url = components.url(relativeTo: locationURL)!
        guard let passport = passport else {
            return URLRequest(url: url)
        }
        var req = URLRequest(url: url,
                             cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = ["Content-Type": "application/json"]
        req.httpBody = try! JSONEncoder().encode(["ga4gh_passport": passport])
        return req
    }
    func get(url: String, expand: Bool = false, auth: String? = nil) throws -> (HTTPURLResponse, Data) {
        var data: Data?
        var response: HTTPURLResponse?
        var error: Error?

        // TODO: Redo for async
        let sema = DispatchSemaphore(value: 0)
        let task = SRAA.session.dataTask(with: makeRequest(url, expand, auth)) {
            error = $2
            response = $1 as? HTTPURLResponse
            data = $0
            sema.signal()
        }
        task.resume()
        _ = sema.wait(timeout: .distantFuture)

        if let error = error { throw error }
        return (response!, data!)
    }
}
