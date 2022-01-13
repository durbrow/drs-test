import Foundation
#if os(Linux)
import FoundationNetworking
#endif

import Logging

LoggingSystem.bootstrap(StreamLogHandler.standardError)
var logger = Logger(label: "drs-test")
logger.logLevel = .info
//logger.logLevel = .trace

let sraa = SRAA(for: .regional)

logger.info("Using IDX base URL \(sraa.locationURL)")
logger.info("Using DRS base URL \(sraa.locationURL)")

do {
    try test_SRR16198144()
    try test_IDX(accession: "SRR10734239")
    try test_SRR287671()
    try test_dbGaP_SRR()
    try test_SRP048601()
    print("All tests without signed URLs passed.")
    try test_dbGaP_SRR_3(region: "s3.us-east-1")
    try test_dbGaP_SRR_3(region: "gs.US")
    //try test_dbGaP_SRR_2(region: "gs.US")
    print("All tests passed.")
}
catch {
    logger.error("\(error)")
    exit(1)
}

func getPassport() throws -> String? {
    #if os(macOS)
        let downloads = try FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let passport = String(data: try Data(contentsOf: URL(string: "RAS_Passport.enc", relativeTo: downloads)!), encoding: .utf8)!
        return passport
    #else
        return nil
    #endif
}

func test_IDX(accession: String) throws {
    let url = SRAA.IDX.url(for: accession, ETL: true)
    let idx : SRAA.IDX = try test(sraa: sraa, url: url)
    guard let drsId = idx.response[accession]?.drs else {
        logger.error("Could not get DRS ID for \(accession)");
        exit(1);
    }
    logger.info("Accession: \(accession) -> DRS ID: \(drsId)")
}

func test_SRR16198144(region: String = "s3.us-east-1") throws {
    let accession = "SRR16198144"
    let idx : SRAA.IDX = try test(sraa: sraa, url: SRAA.IDX.url(for: accession))
    let drsId = idx.response[accession]!.drs
    logger.trace("Accession: \(accession) -> DRS ID: \(drsId)")

    let srr : DRS.Object = try test(sraa: sraa, url: DRS.url(for: drsId))
    guard let fileId = srr.contents?.first?.id else {
        logger.error("Missing contents", metadata: ["object": "\(srr)"])
        exit(1)
    }
    logger.trace("fileId: \(fileId)")

    let file : DRS.Object = try test(sraa: sraa, url: DRS.url(for: fileId))
    guard let accessId = file.access_methods?.first(where: {region == $0.region})?.access_id else {
        logger.error("Missing contents", metadata: ["object": "\(file)"])
        exit(1)
    }
    logger.trace("accessId: \(accessId)")

    do {
        let access : DRS.AccessURL = try test(sraa: sraa, url: DRS.url(for: fileId, access: accessId))
        logger.info("Got Access URL: \(access.url)", metadata: [:])
    }
    catch {
        logger.error("Failure: \(error)")
        exit(1)
    }
}

func test_dbGaP_SRR_2(region: String = "s3.us-east-1") throws {
    let accession = "SRR7273699"
    let idx : SRAA.IDX = try test(sraa: sraa, url: SRAA.IDX.url(for: accession))
    let drsId = idx.response[accession]!.drs
    logger.trace("Accession: \(accession) -> DRS ID: \(drsId)")

    let srr : DRS.Object = try test(sraa: sraa, url: DRS.url(for: drsId))
    guard let fileId = srr.contents?.first?.id else {
        logger.error("Missing contents", metadata: ["object": "\(srr)"])
        exit(1)
    }
    logger.trace("fileId: \(fileId)")

    let file : DRS.Object = try test(sraa: sraa, url: DRS.url(for: fileId))
    guard let accessId = file.access_methods?.first(where: {region == $0.region})?.access_id else {
        logger.error("Missing contents", metadata: ["object": "\(file)"])
        exit(1)
    }
    logger.trace("accessId: \(accessId)")

    let passport = try getPassport()
    do {
        let access : DRS.AccessURL = try test(sraa: sraa, url: DRS.url(for: fileId, access: accessId), auth: passport!)
        logger.info("Got Access URL: \(access.url)", metadata: [:])
    }
    catch let error as HTTPResponseCode where error.value == 403 {
        logger.info("Expected failure: \(error)")
    }
    catch {
        logger.error("Failure: \(error)")
        exit(1)
    }
}

func test_dbGaP_SRR_3(region: String = "s3.us-east-1") throws {
    let accession = "SRR5031422"
    let idx : SRAA.IDX = try test(sraa: sraa, url: SRAA.IDX.url(for: accession, submitted: false, ETL: true))
    let drsId = idx.response[accession]!.drs
    logger.trace("Accession: \(accession) -> DRS ID: \(drsId)")

    let srr : DRS.Object = try test(sraa: sraa, url: DRS.url(for: drsId))
    guard let fileId = srr.contents?.first(where: {accession == $0.name})?.id else {
        logger.error("Missing contents", metadata: ["object": "\(srr)"])
        exit(1)
    }
    logger.trace("fileId: \(fileId)")

    let file : DRS.Object = try test(sraa: sraa, url: DRS.url(for: fileId))
    guard let accessId = file.access_methods?.first(where: {region == $0.region})?.access_id else {
        logger.error("Missing contents", metadata: ["object": "\(file)"])
        exit(1)
    }
    logger.trace("accessId: \(accessId)")

    let passport = try getPassport()
    do {
        let access : DRS.AccessURL = try test(sraa: sraa, url: DRS.url(for: fileId, access: accessId), auth: passport!)
        logger.info("Got Access URL: \(access.url)")
    }
    catch let error as HTTPResponseCode where error.value == 403 {
        logger.info("Expected failure: \(error)")
    }
    catch {
        logger.error("Failure: \(error)")
        exit(1)
    }
}

func test_dbGaP_SRR() throws {
    let accession = "SRR13455616"
    let idx : SRAA.IDX = try test(sraa: sraa, url: SRAA.IDX.url(for: accession))
    let drsId = idx.response[accession]!.drs
    logger.trace("Accession: \(accession) -> DRS ID: \(drsId)")

    let srr : DRS.Object = try test(sraa: sraa, url: DRS.url(for: drsId))
    guard let fileId = srr.contents?.first?.id else {
        logger.error("Missing contents", metadata: ["object": "\(srr)"])
        exit(1)
    }
    let file : DRS.Object = try test(sraa: sraa, url: DRS.url(for: fileId))
    guard let accessId = file.access_methods?.first?.access_id else {
        logger.error("Missing contents", metadata: ["object": "\(srr)"])
        exit(1)
    }
    do {
        let access : DRS.AccessURL = try test(sraa: sraa, url: DRS.url(for: fileId, access: accessId))
        logger.error("This was supposed to fail!!! \(access)")
        exit(1)
    }
    catch let error as HTTPResponseCode where error.value == 401 {
        logger.info("Expected failure: \(error)")
    }
    catch {
        logger.error("Unexpected failure: \(error)")
        exit(1)
    }
}

func test_SRP048601() throws {
    logger.info("test_SRP048601 skipped: SRP lookup is too expensive.")
    return

    // SRP with expand=true
    let accession = "SRP048601"
    let idx : SRAA.IDX = try test(sraa: sraa, url: SRAA.IDX.url(for: accession))
    let drsId = idx.response[accession]!.drs
    logger.info("Accession: \(accession) -> DRS ID: \(drsId)")

    let srp : DRS.Object = try test(sraa: sraa, url: DRS.url(for: drsId), expand: true)
    guard let srx = srp.contents?.first(where: {"SRX000001" == $0.name}) else {
        logger.error("Missing contents", metadata: ["object": "\(srp)"])
        exit(1)
    }
    guard let srr = srx.contents?.first(where: {"SRR000021" == $0.name}) else {
        logger.error("Missing contents", metadata: ["object": "\(srx)"])
        exit(1)
    }
    guard let file = srr.contents?.first(where: {"EI3DH7J01.sff" == $0.name}) else {
        logger.error("Missing contents", metadata: ["object": "\(srr)"])
        exit(1)
    }
    guard let fileId = file.id else {
        logger.error("Missing id", metadata: ["object": "\(file)"])
        exit(1)
    }
    let access : DRS.AccessURL = try test(sraa: sraa, url: DRS.url(for: fileId))
    logger.info("\(access)")
}

func test_SRR287671() throws {
    let accession = "SRR287671"
    let idx : SRAA.IDX = try test(sraa: sraa, url: SRAA.IDX.url(for: accession))
    let drsId = idx.response[accession]!.drs
    logger.trace("Accession: \(accession) -> DRS ID: \(drsId)")

    let srr : DRS.Object = try test(sraa: sraa, url: DRS.url(for: drsId))
    guard let fileId = srr.contents?[0].id else {
        logger.error("Missing contents", metadata: ["object": "\(srr)"])
        exit(1)
    }
    logger.trace("First content ID: \(fileId)")
    let obj : DRS.Object = try test(sraa: sraa, url: DRS.url(for: fileId))
    guard let accessId = obj.access_methods?[0].access_id else {
        logger.error("Missing access method", metadata: ["object": "\(obj)"])
        exit(1)
    }

    let access: DRS.AccessURL = try test(sraa: sraa, url: DRS.url(for: fileId, access: accessId))
    logger.trace("File URL: \(access.url)")
}

struct HTTPResponseCode: Error {
    public let value: Int
    public init(_ value: Int) { self.value = value }
}

extension HTTPResponseCode: CustomStringConvertible {
    var description: String {
        "\(value) \(HTTPURLResponse.localizedString(forStatusCode: value))"
    }
}

func test<T: Decodable>(sraa: SRAA, url: String, expand: Bool = false, auth: String? = nil) throws -> T {
    logger[metadataKey: "query"] = "\(url)"
    let (response, data) = try sraa.get(url: url, expand: expand, auth: auth)
    logger[metadataKey: "url"] = "\(response.url!.absoluteString)"
    logger[metadataKey: "statusCode"] = "\(response.statusCode)"
    logger[metadataKey: "query"] = .none
    logger[metadataKey: "result"] = "\(String(data: data, encoding: .utf8)!)"
    if response.statusCode != 200 {
        throw HTTPResponseCode(response.statusCode)
    }
    guard let contentType = response.allHeaderFields["Content-Type"] as? String
          , contentType == "application/json"
    else {
        logger.error("Unexpected or missing content type")
        exit(1)
    }
    do {
        return try JSONDecoder().decode(T.self, from: data)
    }
    catch {
        logger.error("\(error)")
        exit(1)
    }
}
