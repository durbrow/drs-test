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

        static func url(for accession: String) -> String {
            "idx/v1/\(accession)"
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
    private static var devURL = URL(string: "https://locate-dev.ncbi.nlm.nih.gov/")!
    private static var prdURL = URL(string: "https://locate.ncbi.nlm.nih.gov/")!
    private static var rgnURL = URL(string: "https://locate.be-md.ncbi.nlm.nih.gov/")!

    var locationURL: URL {
        switch systemType {
        case .development:
            return SRAA.devURL
        case .production:
            return SRAA.prdURL
        case .regional:
            return SRAA.rgnURL
        }
    }
    private func makeAuth(_ passport: String) -> Data {
        "{ \"ga4gh_passort\" = \"\(passport)\"}".data(using: .utf8)!
    }
    private func makeRequest(_ url: String, _ passport: String?) -> URLRequest {
        var req = URLRequest(url: URL(string: url, relativeTo: locationURL)!)
        if let passport = passport {
            req.httpMethod = "POST"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = makeAuth(passport)
        }
        return req
    }
    func get(url: String, auth: String? = nil) throws -> (HTTPURLResponse, Data) {
        var data: Data?
        var response: HTTPURLResponse?
        var error: Error?
        let sema = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: makeRequest(url, auth)) {
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
