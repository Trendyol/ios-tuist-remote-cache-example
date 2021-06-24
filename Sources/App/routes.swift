//
//  Routes.swift
//  
//
//  Created by Mustafa Yusuf on 24.06.2021.
//

import Vapor

func routes(_ app: Application) throws {
    let api = app.grouped("api")

    // Called to get download url of the artifact
    api.on(.GET, "cache", use: { req -> Response<Resource> in
        // hash for the artifact
        let hash = req.hash
        // id for the project. I think you can use same cache for the multiple projects
        let projectId = req.projectId

        // get the download url for the given artifact and return it
        let url = "artifact_download_url"
        let expire: Double = 123123

        return .ok(.init(url: url, expiresAt: expire))
    })

    // Called to check if artifact exists on cache
    api.on(.HEAD, "cache" , use: { req -> HTTPStatus in
        let hash = req.hash
        let projectId = req.projectId

        // check if the artifact exist in the cache
        let isArtifactExist = true
        if isArtifactExist {
            return .ok
        } else {
            return .notFound
        }
    })

    // Called to get upload url for the artifact. You can use S3 storage and return its url from here
    // Or you can make upload url another endpoint in same vapor app
    api.on(.POST, "cache") { req -> Response<Resource> in
        let hash = req.hash
        let projectId = req.projectId
        // md5 for artifact.
        let contentMD5 = req.contentMD5

        let url = "serverUrl/api/cache/upload?hash=\(hash)&project_id=\(projectId)&content_md5=\(contentMD5)"
        let expiresAt: Double = 1718975826

        return .ok(.init(url: url, expiresAt: expiresAt))
    }

    // Called after the artifact upload to verify the upload
    api.on(.POST, "cache", "verify_upload") { req -> Response<VerifyResource> in
        // check the cache and return the size
        return .ok(.init(uploadedSize: 123456))
    }

    // Sample upload endpoint that tuist sends the artifact in http body
    // Here you can write the artifact in file or upload it to another storage like amazon s3
    api.on(.PUT, "cache", "upload", body: .collect(maxSize: "100mb")) { req -> EventLoopFuture<HTTPStatus> in
        guard
            let data = req.body.data
        else {
            return req.eventLoop.makeSucceededFuture(.notFound)
        }

        // sample folder in server to save artifact
        let folder = "/tmp/tuist_cache/\(req.projectId)/" + req.hash
        let path =  folder + "/data.zip"

        if !FileManager.default.fileExists(atPath: folder, isDirectory: nil) {
            try? FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
        }

        return req.application.fileio.openFile(
            path: path,
            mode: .write,
            flags: .allowFileCreation(posixMode: 0x744),
            eventLoop: req.eventLoop
        )
        .flatMap { file in
            req.application.fileio.write(
                fileHandle: file,
                buffer: data,
                eventLoop: req.eventLoop
            )
            .flatMapThrowing {
                try file.close()
            }
        }
        .map { _ -> HTTPStatus in
            .ok
        }
        .recover { error in
            print(error)
            return .notFound
        }
    }
}

private extension Request {
    var projectId: String {
        query[String.self, at: "project_id"] ?? ""
    }

    var hash: String {
        query[String.self, at: "hash"] ?? ""
    }

    var contentMD5: String {
        query[String.self, at: "content_md5"] ?? ""
    }
}
