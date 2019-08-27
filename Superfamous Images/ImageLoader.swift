//
//  ImageLoader.swift
//  Superfamous Images
//
//  Created by Daniel Eggert on 21/06/2014.
//  Copyright (c) 2014 objc.io. All rights reserved.
//

import Cocoa
import ApplicationServices


class ImageLoader: NSObject {
    
    // An XPC service
    lazy var imageDownloadConnection: NSXPCConnection = {
        let connection = NSXPCConnection(serviceName: "io.objc.Superfamous-Images.ImageDownloader")
        connection.remoteObjectInterface = NSXPCInterface(with: ImageDownloaderProtocol.self)
        connection.resume()
        return connection
    }()
    
    deinit {
        self.imageDownloadConnection.invalidate()
    }
    
    func retrieveImageAtURL(url: URL, completionHandler: @escaping (NSImage?) -> Void) {
        let downloader = self.imageDownloadConnection.remoteObjectProxyWithErrorHandler {
            	(error) in NSLog("remote proxy error: \(error.localizedDescription)")
            } as! ImageDownloaderProtocol
        downloader.downloadImageAtURL(url: url) { data in
            DispatchQueue.global().async {
                if let data = data,
                    let source = CGImageSourceCreateWithData(data as CFData, nil),
                    let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                    let size = CGSize(width: CGFloat(cgImage.width),
                                      height: CGFloat(cgImage.height))
                    let image = NSImage(cgImage: cgImage, size: size)
                    completionHandler(image)
                } else {
                    completionHandler(nil)
                }
            }
        }
    }

}
