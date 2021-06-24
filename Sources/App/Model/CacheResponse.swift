//
//  CacheResponse.swift
//  
//
//  Created by Anıl Taşkıran on 24.06.2021.
//

import Vapor

struct CacheResponse: Decodable {
    let name: String?
}

struct Response<T: Content>: Content {
    let status: String
    let data: T

    static func ok(_ data: T) -> Response {
        .init(status: "ok", data: data)
    }
}

struct Resource: Content {
    let url: String
    let expiresAt: Double
}

struct VerifyResource: Content {
    let uploadedSize: Double
}
