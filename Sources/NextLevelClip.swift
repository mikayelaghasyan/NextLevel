//
//  NextLevelClip.swift
//  NextLevel (http://nextlevel.engineering/)
//
//  Copyright (c) 2016-present patrick piemonte (http://patrickpiemonte.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit
import Foundation
import AVFoundation

public let NextLevelClipFilenameKey = "NextLevelClipFilenameKey"
public let NextLevelClipInfoDictKey = "NextLevelClipInfoDictKey"

public class NextLevelClip: NSObject {

    // config
    
    public var url: URL? {
        didSet {
            self.clipAsset = nil
        }
    }
    
    // state
    
    public var fileExists: Bool {
        get {
            if let url = self.url {
                return FileManager.default.fileExists(atPath: url.path)
            }
            return false
        }
    }
    
    public var asset: AVAsset? {
        get {
            if let url = self.url, let _ = self.clipAsset {
                self.clipAsset = AVAsset(url: url)
            }
            return self.clipAsset
        }
    }
    
    public var duration: CMTime {
        get {
            if let asset = self.asset {
                return asset.duration
            }
            return kCMTimeInvalid
        }
    }
    
    public var thumbnailImage: UIImage? {
        get {
            guard
                self.clipThumbnailImage == nil
            else {
                return self.clipThumbnailImage
            }
            
            if let asset = self.asset {
                let imageGenerator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                
                do {
                    let cgimage: CGImage = try imageGenerator.copyCGImage(at: kCMTimeZero, actualTime: nil)
                    let uiimage: UIImage = UIImage(cgImage: cgimage)
                    self.clipThumbnailImage = uiimage
                } catch {
                    print("NextLevel, unable to generate lastFrameImage for \(self.url)")
                    self.clipThumbnailImage = nil
                }
            }
            return self.clipThumbnailImage
        }
    }
    
    public var lastFrameImage: UIImage? {
        get {
            guard
                self.clipLastFrameImage == nil
            else {
                return self.clipLastFrameImage
            }
            
            if let asset = self.asset {
                let imageGenerator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
            
                do {
                    let cgimage: CGImage = try imageGenerator.copyCGImage(at: self.duration, actualTime: nil)
                    let uiimage: UIImage = UIImage(cgImage: cgimage)
                    self.clipLastFrameImage = uiimage
                } catch {
                    print("NextLevel, unable to generate lastFrameImage for \(self.url)")
                    self.clipLastFrameImage = nil
                }
            }
            return self.clipLastFrameImage
        }
    }
    
    public var frameRate: Float {
        get {
            if let asset = self.asset {
                let tracks: [AVAssetTrack] = asset.tracks(withMediaType: AVMediaTypeVideo)
                if tracks.count > 0 {
                    if let videoTrack = tracks.first {
                        return videoTrack.nominalFrameRate
                    }
                }
            }
            return 0
        }
    }
    
    public var infoDict: [String: Any]? {
        get {
            if let dict = self.clipInfoDict {
                return dict
            }
            return nil
        }
    }
    
    // MARK: - class functions
    
    public class func clipURL(withFilename filename: String, directory: String) -> URL? {
        var clipURL: URL = URL(fileURLWithPath: directory)
        clipURL.appendPathComponent(filename)
        return clipURL
    }
    
    public class func clip(withUrl url: URL?, infoDict: [String: Any]?) -> NextLevelClip {
        return NextLevelClip(url: url, infoDict: infoDict)
    }
    
    // MARK: - private instance vars
    
    internal var clipAsset: AVAsset?
    internal var clipInfoDict: [String : Any]?
    internal weak var clipThumbnailImage: UIImage?
    internal weak var clipLastFrameImage: UIImage?
    
    // MARK: - object lifecycle
    
    override init() {
        
        super.init()
    }
    
    convenience init(url: URL?, infoDict: [String : Any]?) {
        self.init()
        self.url = url
        self.clipInfoDict = infoDict
    }
    
    convenience init(dictionaryRep: [String : Any]?, directory: String) {
        if let clipDict = dictionaryRep,
           let filename = clipDict[NextLevelClipFilenameKey] as? String,
           let url: URL = NextLevelClip.clipURL(withFilename: filename, directory: directory) {
            let infoDict = clipDict[NextLevelClipInfoDictKey] as? [String : Any]
            self.init(url: url, infoDict: infoDict)
        } else {
            self.init()
        }
    }
    
    deinit {
    }
    
    // MARK: - functions
    
    public func removeFile()  {
        do {
            if let url = self.url {
                try FileManager.default.removeItem(at: url)
                self.url = nil
            }
        } catch {
            print("NextLevel, error deleting a clip's file \(self.url)")
        }
    }
    
    public func dictionaryRep() -> [String : Any]? {
        if let infoDict = self.infoDict, let url = self.url {
            return [NextLevelClipFilenameKey:url.lastPathComponent,
                    NextLevelClipInfoDictKey:infoDict]
        } else if let url = self.url {
            return [NextLevelClipFilenameKey:url.lastPathComponent]
        } else {
            return nil
        }
    }
    
}
