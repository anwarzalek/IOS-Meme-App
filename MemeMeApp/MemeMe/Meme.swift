//
//  File.swift
//  MemeMe
//
//  Created by admin on 2018/02/08.
//  Copyright © 2018 admin. All rights reserved.
//

import Foundation
import UIKit

struct Meme {
    let topText : String!
    let bottomText : String!
    let originalImage : UIImage!
    let memedImage : UIImage!
    init(topText : String , bottomText : String , originalImage : UIImage  , memedImage : UIImage) {
        self.topText = topText
        self.bottomText = bottomText
        self.originalImage = originalImage
        self.memedImage = memedImage
    }
}
