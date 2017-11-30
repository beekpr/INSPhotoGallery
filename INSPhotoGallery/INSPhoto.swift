//
//  INSPhoto.swift
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

import UIKit
/*
 This is marked as @objc because of Swift bug http://stackoverflow.com/questions/30100787/fatal-error-array-cannot-be-bridged-from-objective-c-why-are-you-even-trying when passing for example [INSPhoto] array to INSPhotosViewController
 */
@objc public protocol INSPhotoViewable: class {
    
    var imageURL: URL? { get }
    var attributedTitle: NSAttributedString? { get }
    @objc var httpHeaderKey: String? { get }
    @objc var httpHeaderValue: String? { get }
    @objc optional var isDeletable: Bool { get }
}

@objc open class INSPhoto: NSObject, INSPhotoViewable {
    
    public var imageURL: URL?
    @objc open var isDeletable: Bool
    @objc open var attributedTitle: NSAttributedString?
    
    public var httpHeaderKey: String?
    public var httpHeaderValue: String?
    
    public init (imageURL: URL?) {
        self.imageURL = imageURL
        self.isDeletable = false
    }
    
}

public func ==<T: INSPhoto>(lhs: T, rhs: T) -> Bool {
    return lhs === rhs
}
