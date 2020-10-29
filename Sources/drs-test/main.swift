import Foundation
#if os(Linux)
import FoundationNetworking
#endif

import Logging

LoggingSystem.bootstrap(StreamLogHandler.standardError)
var logger = Logger(label: "drs-test")
// logger.logLevel = .trace

let sraa = SRAA()

logger.info("Using IDX base URL \(sraa.locationURL)")
logger.info("Using DRS base URL \(sraa.locationURL)")

do {
    let accession = "SRR287671"
    let idx : SRAA.IDX = try test(sraa: sraa, url: SRAA.IDX.url(for: accession))
    let drsId = idx.response[accession]!.drs
    logger.info("Accession: \(accession) -> DRS ID: \(drsId)")

    let obj : DRS.Object = try test(sraa: sraa, url: DRS.url(for: drsId))
    guard let fileId = obj.contents?[0].id else {
        logger.error("Missing contents", metadata: ["object": "\(obj)"])
        exit(1)
    }
    logger.info("First content ID: \(fileId)")
    let access: DRS.AccessURL = try test(sraa: sraa, url: DRS.url(for: fileId, access: "1"), auth: "Foo.bar.baz")
    logger.info("File URL: \(access.url)")
}
catch {
    logger.error("\(error)")
}

func test<T: Decodable>(sraa: SRAA, url: String, auth: String? = nil) throws -> T {
    logger[metadataKey: "query"] = "\(url)"
    let (response, data) = try sraa.get(url: url, auth: auth)
    logger[metadataKey: "url"] = "\(response.url!.absoluteString)"
    logger[metadataKey: "statusCode"] = "\(response.statusCode)"
    logger[metadataKey: "query"] = .none
    if response.statusCode != 200 {
        logger.error("\(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))")
        exit(1)
    }
    guard let contentType = response.allHeaderFields["Content-Type"] as? String, contentType == "application/json" else {
        logger.error("Unexpected or missing content type")
        exit(1)
    }
    do {
        logger.trace("result=\(String(data: data, encoding: .utf8)!)")
        return try JSONDecoder().decode(T.self, from: data)
    }
    catch {
        logger.error("\(error)")
        exit(1)
    }
}
