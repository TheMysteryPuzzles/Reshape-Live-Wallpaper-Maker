//
//  AssetEditorViewController.swift
//  Lively
//
//  Created by Work on 6/7/19.
//  Copyright © 2019 TheMysteryPuzzles. All rights reserved.
//

import UIKit
import TLPhotoPicker
import Photos
import AVFoundation
import MobileCoreServices
import PryntTrimmerView
import GIFGenerator
import NVActivityIndicatorView
import SwiftMessages

class AssetEditorViewController: UIViewController, NVActivityIndicatorViewable {
    
    var tempUrl: URL?
    var trimmedUrl: URL?
    var selectedPhotoAssets = [TLPHAsset]()
    var selectedAsset: PHAsset?
    var isPhotoAssetSelected = true
    var selectionType: SelectionType!
    var isExporting = false
    
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var trimmerView: TrimmerView!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var makeButton: UIButton!
    
    var player: AVPlayer?
    var playbackTimeCheckerTimer: Timer?
    var trimmerPositionChangedTimer: Timer?

    
    
    @objc private func makeLivePhoto(){
        print(self.trimmerView.startTime!.seconds)
        if trimmedUrl == nil {
            cropVideo(sourceURL: self.tempUrl!, startTime: trimmerView.startTime!.seconds, endTime: trimmerView.endTime!.seconds) { (url) in

                self.trimmedUrl = url
                self.loadVideoWithVideoURL(self.trimmedUrl!)
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.navigationBar.isHidden = false
    
        makeButton.layer.masksToBounds = true
        makeButton.layer.cornerRadius = 20
        
        makeButton.setTitle("Create & Download", for: .normal)
        makeButton.titleLabel?.font = UIFont(name: "Billabong", size: 32)
        makeButton.titleLabel?.adjustsFontSizeToFitWidth = true

        
        self.view.applyMainAppTheme()
        self.playerView.backgroundColor = #colorLiteral(red: 0.1212944761, green: 0.1292245686, blue: 0.141699791, alpha: 1)
        trimmerView.handleColor = .white
        trimmerView.mainColor = #colorLiteral(red: 0.6935398579, green: 0.1595383584, blue: 0.4565044641, alpha: 1)
        trimmerView.maxDuration = 3
        trimmerView.minDuration = 1
        playButton.addTarget(self, action: #selector(play(_:)), for: .touchUpInside)
        makeButton.addTarget(self, action: #selector(makeLivePhoto), for: .touchUpInside)
        
       trimmerView.isHidden = true
       playerView.isHidden = true
        playButton.isHidden = true
        makeButton.isHidden = true
        applyLogoInTitleView()
         self.showActivityIndicator()
    }
    
    
    func applyLogoInTitleView(){
        
        let navController = navigationController!
        
        let image = UIImage(named: "ic_LogoColor") //Your logo url here
        let imageView = UIImageView(image: image)
        
        let bannerWidth = navController.navigationBar.frame.size.width
        let bannerHeight = navController.navigationBar.frame.size.height
        
        let bannerX = bannerWidth / 2 - (image?.size.width)! / 2
        let bannerY = bannerHeight / 2 - (image?.size.height)! / 2
        
        print(bannerWidth)
        print(bannerHeight)
        
        imageView.frame = CGRect(x: bannerX, y: bannerY, width: bannerWidth, height: bannerHeight)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        
        navigationItem.titleView = imageView
        
    }
    
    @objc func play(_ sender: Any) {
        
        guard let player = player else {
            return
            
        }
       
        if !player.isPlaying {
            player.play()
            startPlaybackTimeChecker()
            DispatchQueue.main.async {
                   self.playButton.setImage(UIImage(named: "ic_Pause"), for: .normal)
            }
        
            self.playButton.imageView?.contentMode = .scaleAspectFit
        } else {
            player.pause()
            stopPlaybackTimeChecker()
            DispatchQueue.main.async {
                self.playButton.setImage(UIImage(named: "ic_Play"), for: .normal)
            }
            
        }
    }
    
    func startPlaybackTimeChecker() {
        
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
                                                        selector:
            #selector(AssetEditorViewController.onPlaybackTimeChecker), userInfo: nil, repeats: true)
    }
    
    func stopPlaybackTimeChecker() {
        
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    
    @objc func onPlaybackTimeChecker() {
        
        guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime, let player = player else {
            return
        }
        
        let playBackTime = player.currentTime()
        trimmerView.seek(to: playBackTime)
        
        if playBackTime >= endTime {
            player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            trimmerView.seek(to: startTime)
        }
    }
    
    
    func resizedImage(image: UIImage?, for size: CGSize) -> UIImage? {
        guard let image = image  else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private func addVideoPlayer(with assetUrl: URL, playerView: UIView) {
        let playerItem = AVPlayerItem(url: assetUrl)
        
        player = AVPlayer(playerItem: playerItem)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(AssetEditorViewController.itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        let layer: AVPlayerLayer = AVPlayerLayer(player: player)
        layer.backgroundColor = UIColor.clear.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerView.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        playerView.layer.addSublayer(layer)
        
    }
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        if let startTime = trimmerView.startTime {
            player?.seek(to: startTime)
        }
    }
    
  
    
    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            self.trimmerView.delegate = self
            if !self.isPhotoAssetSelected{
               
                self.perform(#selector(self.unlockLoadingView), with: nil, afterDelay: 1.5)
                guard let selectionType = self.selectionType else { return }
                switch self.selectionType!{
                case .gif: self.createVideoAndSetupSlider()
                case .images: self.trimmerView.isHidden = true
                case .video: self.playVideoAndSetupSlider()
                }
            }else{
                self.trimmerView.isHidden = true
                DispatchQueue.main.async {
                  
                }
                self.createAndPlayVideoFromPhotosArray()
            }
        }
     
    }
    
    
    
    
    private func showActivityIndicator(){
          startAnimating(CGSize(width: 50, height: 50), message: "Processing..", messageFont: nil, type: .ballScaleMultiple, color: .white, padding: nil, displayTimeThreshold: nil, minimumDisplayTime: nil, backgroundColor: nil, textColor: nil, fadeInAnimation: nil)
    }
    
    
    private func createAndPlayVideoFromPhotosArray(){
     
    
        
          //self.activityIndicator.startAnimating()
        
        var frames = [UIImage]()
        for image in self.selectedPhotoAssets {
            if let resizedImage = self.resizedImage(image: image.fullResolutionImage!, for: self.playerView.frame.size){
                  frames.append(resizedImage)
            }
            
        }
        let gifGenerator = GifGenerator()
        let giftempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.gif")
        gifGenerator.generateGifFromImages(imagesArray: frames, frameDelay: 0.5, destinationURL: giftempUrl, callback: { (data, error) -> () in
            
            if error == nil{
                let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.mp4")
                let gifdata = try! Data(contentsOf: giftempUrl)
                GIF2MP4(data: gifdata)?.convertAndExport(to: tempUrl, completion: {
                    self.tempUrl = tempUrl
                    self.trimmerView.asset = AVAsset(url: tempUrl)
                    print(self.trimmerView.asset?.duration)
                    self.addVideoPlayer(with: tempUrl, playerView: self.playerView)
                    self.perform(#selector(self.unlockLoadingView), with: nil, afterDelay: 1.5)
                    self.trimmerView.isHidden = true
                })
            }
         
        })

      
    }
    
    
    @objc func unlockLoadingView(){
        
       
        if isPhotoAssetSelected{
             self.trimmerView.isHidden = true
        }else{
             self.trimmerView.isHidden = false
        }
        UIView.transition(with: playerView, duration: 0.5, options: .curveEaseIn, animations: {
           
            self.playerView.isHidden = false
            self.playButton.isHidden = false
            self.makeButton.isHidden = false
        })
         stopAnimating()

    }
    
   
    
 
    private func playVideoAndSetupSlider(){

        
          guard let selectedAsset = self.selectedAsset else { return }
        self.selectedAsset?.getURL(completionHandler: { (url) in
            guard let url = url else { return }
            DispatchQueue.main.async(execute: {
                self.tempUrl = url
                self.trimmerView.asset = AVAsset(url: url)
                self.addVideoPlayer(with: url, playerView: self.playerView)
            })
         
            
        })
        
    }
    
    
    private func createVideoAndSetupSlider(){
     
     //   LoadingView.lockView()
          guard let selectionType = self.selectionType else { return }
        if self.selectionType! == .gif {
            
            
            guard let selectedAsset = self.selectedAsset else { return }
            
            
            self.selectedAsset?.getURL(completionHandler: { (url) in
                guard let url = url else {return }
                let data = try! Data(contentsOf: url)
                  let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.mp4")
                GIF2MP4(data: data)?.convertAndExport(to: tempUrl, completion: {
                    self.tempUrl = tempUrl
                    self.trimmerView.asset = AVAsset(url: tempUrl)
                    self.addVideoPlayer(with: tempUrl, playerView: self.playerView)
                })
            })
            
            
          
        }
    }

}
extension AVPlayer {
    
    var isPlaying: Bool {
        return self.rate != 0 && self.error == nil
    }
}


extension AssetEditorViewController: TrimmerViewDelegate {
    
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        player?.play()
        startPlaybackTimeChecker()
    }
    
    func didChangePositionBar(_ playerTime: CMTime) {
        stopPlaybackTimeChecker()
        player?.pause()
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
        print(duration)
     
        
    }
    
     func cropVideo(sourceURL: URL, startTime: Double, endTime: Double, completion: ((_ outputUrl: URL) -> Void)? = nil)
    {
        let fileManager = FileManager.default
       
        
        let asset = AVAsset(url: sourceURL)
        let length = Float(asset.duration.value) / Float(asset.duration.timescale)
        print("video length: \(length) seconds")
        
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.mp4")
        
        //Remove existing file
        try? fileManager.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { return }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        let timeRange = CMTimeRange(start: CMTime(seconds: startTime, preferredTimescale: 1000),
                                    end: CMTime(seconds: endTime, preferredTimescale: 1000))
        
        exportSession.timeRange = timeRange
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("exported at \(outputURL)")
                completion?(outputURL)
            case .failed:
                print("failed \(exportSession.error.debugDescription)")
            case .cancelled:
                print("cancelled \(exportSession.error.debugDescription)")
            default: break
            }
        }
    }
}

extension PHAsset {
    func image(targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?) -> UIImage {
        var thumbnail = UIImage()
        let imageManager = PHCachingImageManager()
        imageManager.requestImage(for: self, targetSize: targetSize, contentMode: contentMode, options: options, resultHandler: { image, _ in
            thumbnail = image!
        })
        return thumbnail
    }
}

extension UIImage{
    
    func resizeImageWith(newSize: CGSize) -> UIImage {
        
        let horizontalRatio = newSize.width / size.width
        let verticalRatio = newSize.height / size.height
        
        let ratio = max(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
        draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    
}
extension AssetEditorViewController {

    func loadVideoWithVideoURL(_ videoURL: URL) {
    // livePhotoView.livePhoto = nil
    let asset = AVURLAsset(url: videoURL)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    let time = NSValue(time: CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration)/2, preferredTimescale: asset.duration.timescale))
    generator.generateCGImagesAsynchronously(forTimes: [time]) { [weak self] _, image, _, _, _ in
    if let image = image, let data = UIImage(cgImage: image).pngData() {
    let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let imageURL = urls[0].appendingPathComponent("image.jpg")
        try? data.write(to: imageURL, options: [.atomic])
        
        let image = imageURL.path
        let mov = videoURL.path
        let output = FilePaths.VidToLive.livePath
        let assetIdentifier = UUID().uuidString
        let _ = try? FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true, attributes: nil)
        do {
            try FileManager.default.removeItem(atPath: output + "/IMG.JPG")
            try FileManager.default.removeItem(atPath: output + "/IMG.MOV")
            
        } catch {
            
        }
        JPEG(path: image).write(output + "/IMG.JPG",
                                assetIdentifier: assetIdentifier)
        QuickTimeMov(path: mov).write(output + "/IMG.MOV",
                                      assetIdentifier: assetIdentifier)
        
        _ = DispatchQueue.main.sync {
            PHLivePhoto.request(withResourceFileURLs: [ URL(fileURLWithPath: FilePaths.VidToLive.livePath + "/IMG.MOV"), URL(fileURLWithPath: FilePaths.VidToLive.livePath + "/IMG.JPG")],
                                placeholderImage: nil,
                                targetSize: self!.view.bounds.size,
                                contentMode: PHImageContentMode.aspectFit,
                                resultHandler: { (livePhoto, info) -> Void in
                                    if self!.isExporting{
                                         self?.exportLivePhoto()
                                       
                                    }else{
                                         self?.isExporting = true
                                    }
                                 
                    })
                }
            }
        }
    }
    
    
    
    func exportLivePhoto () {
        PHPhotoLibrary.shared().performChanges({ () -> Void in
            let creationRequest = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            
            creationRequest.addResource(with: PHAssetResourceType.pairedVideo, fileURL: URL(fileURLWithPath: FilePaths.VidToLive.livePath + "/IMG.MOV"), options: options)
            creationRequest.addResource(with: PHAssetResourceType.photo, fileURL: URL(fileURLWithPath: FilePaths.VidToLive.livePath + "/IMG.JPG"), options: options)
            
        }, completionHandler: { (success, error) -> Void in
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
                SwiftMessages.showToast("LivePhoto is sucessfully downloaded.", type: .success)
            }
            
            if !success {
                print((error?.localizedDescription)!)
            }
        })
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
    
}

struct FilePaths {
    static let documentsPath : AnyObject = NSSearchPathForDirectoriesInDomains(.cachesDirectory,.userDomainMask,true)[0] as AnyObject
    
    struct VidToLive {
        static var livePath = FilePaths.documentsPath.appending("/")
    }
}

extension SwiftMessages {
    
    class func showToast(_ message: String, type: Theme = .warning, buttonTitle: String? = nil) {
        
        let view = MessageView.viewFromNib(layout: .cardView)
        
        if let buttonTitle = buttonTitle {
            
            view.configureContent(title: nil,
                                  body: message,
                                  iconImage: nil,
                                  iconText: nil,
                                  buttonImage: nil,
                                  buttonTitle: buttonTitle, buttonTapHandler: { _ in SwiftMessages.hide() })
        } else {
            view.configureContent(title: "", body: message)
            view.button?.isHidden = true
        }
        
        //view.bodyLabel?.font = UIFont.robotoRegular(13.0)
        view.configureTheme(type, iconStyle: .default)
        view.configureDropShadow()
        view.titleLabel?.isHidden = true
        view.backgroundView.backgroundColor = #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
        
        var config = SwiftMessages.defaultConfig
        config.dimMode = .gray(interactive: false)
        config.interactiveHide = true
        config.presentationContext = .window(windowLevel: UIWindow.Level.normal)
        config.duration = .seconds(seconds: type == .warning ? 1.5:3.0)
        
        SwiftMessages.show(config: config, view: view)
    }
    
    
    class func showMessageToast(_ message: String, title: String) -> UIView {
        
        // Instantiate a message view from the provided card view layout. SwiftMessages searches for nib
        // files in the main bundle first, so you can easily copy them into your project and make changes.
        let view = MessageView.viewFromNib(layout: .messageView)
        
        view.button?.isHidden = true
        
        // Theme message elements with the warning style.
        view.configureTheme(.info)
        
        // Add a drop shadow.
        view.configureDropShadow()
        
        view.configureContent(title: title, body: message)
        
        return view
        // Show the message.
        //SwiftMessages.show(view: view)
        
    }
}
