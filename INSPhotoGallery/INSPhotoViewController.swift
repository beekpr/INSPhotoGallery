//
//  INSPhotoViewController.swift
//  INSPhotoViewer
//
//  Created by Michal Zaborowski on 28.02.2016.
//  Copyright © 2016 Inspace Labs Sp z o. o. Spółka Komandytowa. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this library except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import SDWebImage

open class INSPhotoViewController: UIViewController, UIScrollViewDelegate {
    var photo: INSPhotoViewable
    
    var longPressGestureHandler: ((UILongPressGestureRecognizer) -> ())?
    
    lazy private(set) var scalingImageView: INSScalingImageView = {
        return INSScalingImageView()
    }()
    
    lazy private(set) var doubleTapGestureRecognizer: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(INSPhotoViewController.handleDoubleTapWithGestureRecognizer(_:)))
        gesture.numberOfTapsRequired = 2
        return gesture
    }()
    
    lazy private(set) var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(INSPhotoViewController.handleLongPressWithGestureRecognizer(_:)))
        return gesture
    }()
    
    lazy private(set) var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityIndicator.startAnimating()
        return activityIndicator
    }()
    
    public init(photo: INSPhotoViewable) {
        self.photo = photo
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        scalingImageView.delegate = nil
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        scalingImageView.delegate = self
        scalingImageView.frame = view.bounds
        scalingImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scalingImageView)
        
        view.addSubview(activityIndicator)
        activityIndicator.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        activityIndicator.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
        activityIndicator.sizeToFit()
        
        view.addGestureRecognizer(doubleTapGestureRecognizer)
        view.addGestureRecognizer(longPressGestureRecognizer)
        
        loadFullSizeImage()
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        scalingImageView.frame = view.bounds
    }
    
    private func loadFullSizeImage() {
        view.bringSubview(toFront: activityIndicator)
        
        guard let url = self.photo.imageURL else {
            return
        }
        
        // Retrieve Image from Cache
        if let image = SDImageCache.shared().imageFromCache(forKey: url.absoluteString) {
            
            // Stop Loading Animation
            self.activityIndicator.stopAnimating()
           
            let path = SDImageCache.shared().defaultCachePath(forKey: url.absoluteString)
            if let animatedImagePath = path, let data = NSData(contentsOfFile: animatedImagePath) as Data? {

                if image.isGIF() {
                    // Set Animated Image
                    let animatedImage = FLAnimatedImage(gifData: data)
                    self.scalingImageView.animatedImage = animatedImage
                }
                else {
                    // Set  Image
                    let image = UIImage(data: data)
                    self.scalingImageView.image = image
                }
            }
        }
        else {
            
            // Download Image
            let imageDownloader = SDWebImageDownloader.shared()
            if let value = self.photo.httpHeaderValue, let field = self.photo.httpHeaderKey, value.count > 0 {
                imageDownloader.setValue(value, forHTTPHeaderField: field)
            }
            imageDownloader.downloadImage(with: url,
                                          options: .highPriority,
                                          progress: nil,
                                          completed: { [weak self] image, data, _, _  in
                                    
                                            self?.activityIndicator.stopAnimating()

                                            let imageFormat = NSData.sd_imageFormat(forImageData: data)
                                            if imageFormat == .GIF {
                                                if let imageData = data {
                                                    
                                                    // Store in Cache
                                                    SDImageCache.shared().storeImageData(toDisk: imageData, forKey: url.absoluteString)
                                                    
                                                    // Set Animated Image
                                                    let animatedImage = FLAnimatedImage(animatedGIFData: imageData)
                                                    self?.scalingImageView.animatedImage = animatedImage
                                                }
                                            }
                                            else if let image = image {
                                                
                                                // Store in Cache
                                                SDImageCache.shared().store(image, forKey: url.absoluteString)
                                                
                                                // Set Image
                                                self?.scalingImageView.image = image
                                            }
            })
        }
    }
    
    @objc private func handleLongPressWithGestureRecognizer(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
            longPressGestureHandler?(recognizer)
        }
    }
    
    @objc private func handleDoubleTapWithGestureRecognizer(_ recognizer: UITapGestureRecognizer) {
        let pointInView = recognizer.location(in: scalingImageView.imageView)
        var newZoomScale = scalingImageView.maximumZoomScale
        
        if scalingImageView.zoomScale >= scalingImageView.maximumZoomScale || abs(scalingImageView.zoomScale - scalingImageView.maximumZoomScale) <= 0.01 {
            newZoomScale = scalingImageView.minimumZoomScale
        }
        
        let scrollViewSize = scalingImageView.bounds.size
        let width = scrollViewSize.width / newZoomScale
        let height = scrollViewSize.height / newZoomScale
        let originX = pointInView.x - (width / 2.0)
        let originY = pointInView.y - (height / 2.0)
        
        let rectToZoom = CGRect(x: originX, y: originY, width: width, height: height)
        scalingImageView.zoom(to: rectToZoom, animated: true)
    }
    
    // MARK:- UIScrollViewDelegate
    
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scalingImageView.imageView
    }
    
    open func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.panGestureRecognizer.isEnabled = true
    }
    
    open func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        // There is a bug, especially prevalent on iPhone 6 Plus, that causes zooming to render all other gesture recognizers ineffective.
        // This bug is fixed by disabling the pan gesture recognizer of the scroll view when it is not needed.
        if (scrollView.zoomScale == scrollView.minimumZoomScale) {
            scrollView.panGestureRecognizer.isEnabled = false;
        }
    }
}
