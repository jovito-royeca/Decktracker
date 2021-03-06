//
// Created by Jovit Royeca on 4/8/15.
// Copyright (c) 2015 Jovito Royeca. All rights reserved.
//

import Foundation

let kCQEasyCurrentCard          = "kCQEasyCurrentCard"
let kCQModerateCurrentCard      = "kCQModerateCurrentCard"
let kCQHardCurrentCard          = "kCQHardCurrentCard"

let kCQMaxCurrentCards:Int32    = 10

struct CQTheme {
    static let kManaLabelColor  = UIColor.whiteColor()
    static let kLabelColor      = UIColor.whiteColor()
    static let kTileTextColor   = UIColor.whiteColor()
    static let kTileTextColorX  = UIColor.grayColor()
    static let kTileColor       = UInt(0x434343) // silver
    static let kTileBorderColor = UInt(0x191919) // black

    static let kTitleLabelFont  = UIFont(name: "Magic:the Gathering", size:26)
    static let kManaLabelFont   = UIFont(name: "Magic:the Gathering", size:18)
    static let kLabelFont       = UIFont(name: "Magic:the Gathering", size:20)
    static let kTileAnswerFont  = UIFont(name: "Magic:the Gathering", size:18)
    static let kTileQuizFont    = UIFont(name: "Magic:the Gathering", size:20)
    static let kTileButtonFont  = UIFont(name: "Magic:the Gathering", size:14)
    static let kStepperFont     = UIFont.systemFontOfSize(16)
    static let kStepperTextFont = UIFont(name: "Magic:the Gathering", size:16)
}
