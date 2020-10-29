//
//  DRS.swift
//  
//
//  Created by Kenneth Durbrow on 10/21/20.
//

import Foundation

enum DRS {
    struct AccessURL: Codable {
        let url: String
        let headers: String?
    }
    struct AccessMethod: Codable {
        let type: String
        let access_id: String?
        let access_url: AccessURL?
        let region: String?
    }
    struct Checksum: Codable {
        let checksum: String
        let type: String
    }
    struct Content: Codable {
        let name: String
        let id: String?
        let contents: [Content]?
        let drs_uri: String?
    }
    struct Object: Codable {
        let id: String
        let created_time: String
        let self_url: String
        let size: Int

        let checksums: [Checksum]

        let name: String?
        let description: String?
        let mime_type: String?
        let updated_time: String?
        let version: String?

        let contents: [Content]?
        let access_methods: [AccessMethod]?
        let aliases: String?
    }
    struct Error: Codable {
        let status_code: Int?
        let msg: String?
    }
    static func url(for drsId: String) -> String {
        "ga4gh/drs/v1/objects/\(drsId)"
    }
    static func url(for drsId: String, access id: String) -> String {
        "\(Self.url(for: drsId))/access/\(id)"
    }
}
