//
//  Hero.swift
//  MCUApp
//
//  Created by Lucas Tarasconi on 15/12/2018.
//  Copyright © 2018 Lucas Tarasconi. All rights reserved.
//

import Foundation
import UIKit

enum SerializationError: Error {
    case missing(String)
}


class Hero {
    let id: Int
    let name: String
    let description: String
    let fullPathImage: String?
    var image: UIImage?
    var loved: Bool = false
    
    init(id: Int, name: String, description: String, image: UIImage) {
        self.id = id
        self.name = name
        self.image = image
        self.description = description
        self.fullPathImage = ""
    }
    
    init?(json: [String: Any]) throws {
        guard let id = json["id"] as? Int else {
            throw SerializationError.missing("id")
        }
        guard let name = json["name"] as? String else {
            throw SerializationError.missing("name")
        }
        guard let description = json["description"] as? String else {
            throw SerializationError.missing("description")
        }
        guard let thumbnail = json["thumbnail"] as? [String : Any],
            let imagePath = thumbnail["path"] as? String,
            let imageExt = thumbnail["extension"] as? String else {
                throw SerializationError.missing("thumbnail")
        }
        
        self.id = id
        self.name = name
        self.description = description
        self.fullPathImage = imagePath + "." + imageExt
    }
}
