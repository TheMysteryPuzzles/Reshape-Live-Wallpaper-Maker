//
//  ViewController.swift
//  Lively
//
//  Created by Work on 6/7/19.
//  Copyright © 2019 TheMysteryPuzzles. All rights reserved.
//

import UIKit
import TLPhotoPicker
import Photos
import SwiftMessages
import MobileCoreServices


enum SelectionType{
    case gif
    case video
    case images
}

class AssetSelectionViewController: UIViewController, TLPhotosPickerViewControllerDelegate {
    var selectedPhotoAssets = [TLPHAsset]()
    var selectedAsset: PHAsset?
   
    var tempAssetUrl: URL?
    var isPhotoAcceddAllowed = true{
        didSet{
            DispatchQueue.main.async {
                self.logoView.isHidden = true
                self.allowPhotoAccesView.isHidden = false
            }
           
        }
    }
    
    lazy var allowPhotoAccesView: AllowLibraryAccessView = {
       let view = AllowLibraryAccessView()
       view.translatesAutoresizingMaskIntoConstraints = false
       return view
    }()
    
    
    var seletedAssetType: SelectionType?{
        didSet{
            
            if seletedAssetType != .images{
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "AssetEditorViewController") as! AssetEditorViewController
                vc.isPhotoAssetSelected = false
                vc.selectedAsset = self.selectedAsset
                vc.selectionType = self.seletedAssetType
                DispatchQueue.main.async {
                   self.viewController.navigationController?.pushViewController(vc, animated: true)
                }
              
            }
        }
    }
    
 
    
    override func viewWillAppear(_ animated: Bool) {
        self.selectedPhotoAssets = [TLPHAsset]()
        selectedAsset = nil
        viewController.tempPhotoAssets = [PHAsset]()
    }
    
    lazy var logoView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "ic_Logo"))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.applyMainAppTheme()
        self.view.addSubview(logoView)
        NSLayoutConstraint.activate([
            
            logoView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            logoView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8),
            logoView.heightAnchor.constraint(equalTo: logoView.widthAnchor)
            
            ])
        
        self.view.addSubview(allowPhotoAccesView)
        NSLayoutConstraint.activate([
            
            allowPhotoAccesView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            allowPhotoAccesView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            allowPhotoAccesView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.85),
            allowPhotoAccesView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.45)
            ])
      
        allowPhotoAccesView.isHidden = true
        
        
    }
    
    lazy var viewController:CustomPhotoPickerViewController =  {
        let vc = CustomPhotoPickerViewController()
        var configure = TLPhotosPickerConfigure()
        configure.allowedLivePhotos = false
        configure.cancelTitle = ""
        configure.allowedAlbumCloudShared = false
        configure.allowedVideoRecording = false
        configure.maxVideoDuration = 3.0
        configure.maxSelectedAssets = 3
        vc.configure = configure
      return vc
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        
        
   
        
        if isPhotoAcceddAllowed{
            viewController.delegate = self
            viewController.logDelegate = self
            let embeddedVc = UINavigationController(rootViewController: viewController)
            DispatchQueue.main.async {
                self.present(embeddedVc, animated: true, completion: nil)
            }
           
        }
      
    }

    //TLPhotosPickerViewControllerDelegate
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        // use selected order, fullresolution image
        //2
        self.selectedPhotoAssets = withTLPHAssets
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "AssetEditorViewController") as! AssetEditorViewController
        vc.isPhotoAssetSelected = true
        vc.selectedAsset = nil
        vc.selectionType = .images
        vc.selectedPhotoAssets = withTLPHAssets
        DispatchQueue.main.async {
             self.viewController.navigationController?.pushViewController(vc, animated: true)
        }
       
    }
    func dismissPhotoPicker(withPHAssets: [PHAsset]) {
      //1
    }
    func photoPickerDidCancel() {
        
    }
    func dismissComplete() {
       //3
    }
    func canSelectAsset(phAsset: PHAsset) -> Bool {
     
        
        switch phAsset.mediaType {
        case .image:

            if let identifier = phAsset.value(forKey: "uniformTypeIdentifier") as? String
            {
                if identifier == kUTTypeGIF as String
                    
                {   if self.viewController.tempPhotoAssets.count >= 1 {
                    SwiftMessages.showToast("Video and Gifs can only be selected individually.", type: .warning)
                    return false
                    }
                 
                    self.selectedAsset = phAsset
                    self.seletedAssetType = .gif
                }
            }
            if (phAsset.mediaSubtypes == .photoLive) {
               return false
                
            }else {
                self.viewController.tempPhotoAssets.append(phAsset)
            }
         
            
        case .video:
            if self.viewController.tempPhotoAssets.count >= 1 {
                 SwiftMessages.showToast("Video and Gifs can only be selected individually.", type: .warning)
                return false
            }
         
            self.selectedAsset = phAsset
            self.seletedAssetType = .video
        default:
            print("Unknown")
        }
        return true
    }
    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) {
      SwiftMessages.showToast("Photos Selection Limit is 3.", type: .warning)
    }
    func handleNoAlbumPermissions(picker: TLPhotosPickerViewController) {
        self.isPhotoAcceddAllowed = false
        self.dismiss(animated: false, completion: nil)
    }
    func handleNoCameraPermissions(picker: TLPhotosPickerViewController) {
        
    }
    
}


extension AssetSelectionViewController: TLPhotosPickerLogDelegate{
    func selectedCameraCell(picker: TLPhotosPickerViewController) {
        
    }
    
    func deselectedPhoto(picker: TLPhotosPickerViewController, at: Int) {
        
       
        if self.viewController.tempPhotoAssets.count >= 1{
            self.viewController.tempPhotoAssets.removeLast()
        }
   
    }
    
    func selectedPhoto(picker: TLPhotosPickerViewController, at: Int) {
        
    }
    
    func selectedAlbum(picker: TLPhotosPickerViewController, title: String, at: Int) {
        
    }
    
    
}


extension PHAsset {
    
    func getURL(completionHandler : @escaping ((_ responseURL : URL?) -> Void)){
        if self.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            self.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
                completionHandler(contentEditingInput!.fullSizeImageURL as URL?)
            })
        } else if self.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl: URL = urlAsset.url as URL
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }
}


class CustomPhotoPickerViewController: TLPhotosPickerViewController {
    
    
    var isFirstLoaded = false
     var tempPhotoAssets = [PHAsset]()
    
    override func viewWillAppear(_ animated: Bool) {
   
        if isFirstLoaded {
      self.selectedAssets =  [TLPHAsset]()
            self.tempPhotoAssets = [PHAsset]()
           self.collectionView.reloadData()
           
        }
             super.viewWillAppear(true)
         self.isFirstLoaded = true
    }
    
    override func makeUI() {
        super.makeUI()
        self.customNavItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(handleNextButtonTapped))
        self.customNavItem.leftBarButtonItem?.isEnabled = false
        applyLogoInTitleView()
    }
    @objc func handleNextButtonTapped() {
        
        if self.selectedAssets.count == 0 {
            return
        }
        DispatchQueue.main.async {
            self.delegate!.dismissPhotoPicker(withTLPHAssets: self.selectedAssets)
        }
       
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
    
}

class AllowLibraryAccessView: UIView {
    
    
    lazy var topLable: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 26)
        label.adjustsFontSizeToFitWidth = true
        label.textColor = .white
        label.text = "Please Allow Photo Library Access"
         label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var midLable: UILabel = {
        let label = UILabel()
        label.text = "This allow ReShape to access all photos and videos from your Photos app to let you create live photos."
        label.numberOfLines = 0
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var bottomLable: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 26)
        label.adjustsFontSizeToFitWidth = true
         label.numberOfLines = 0
        label.text = "Setting > Privacy > Photos > ReShape > Read and Write"
        label.textColor = .white
         label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var logoView: UIImageView = {
       let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
      
       view.image = UIImage(named: "ic_Logo")
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(logoView)
        NSLayoutConstraint.activate([
            logoView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            logoView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            logoView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.4),
            logoView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10)
            ])
        
        
        
        self.addSubview(topLable)
        NSLayoutConstraint.activate([
            topLable.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            topLable.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            topLable.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.15),
            topLable.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 10)
        ])
        
        self.addSubview(midLable)
        NSLayoutConstraint.activate([
            midLable.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            midLable.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            midLable.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.25),
            midLable.topAnchor.constraint(equalTo: topLable.bottomAnchor, constant: 10)
            ])
        
        self.addSubview(bottomLable)
        NSLayoutConstraint.activate([
            bottomLable.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            bottomLable.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            bottomLable.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            bottomLable.topAnchor.constraint(equalTo: midLable.bottomAnchor, constant: 10)
            ])
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
