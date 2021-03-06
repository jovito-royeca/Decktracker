//
//  CardQuizGameViewController.swift
//  Decktracker
//
//  Created by Jovit Royeca on 1/14/15.
//  Copyright (c) 2015 Jovito Royeca. All rights reserved.
//

import UIKit
import AVFoundation
import Realm

class CardQuizGameViewController: UIViewController, MBProgressHUDDelegate, InAppPurchaseViewControllerDelegate, CQManaChooserViewDelegate {

//  MARK: Variables
    var btnClose:UIImageView?
    var lblBlack:UILabel?
    var lblBlue:UILabel?
    var lblGreen:UILabel?
    var lblRed:UILabel?
    var lblWhite:UILabel?
    var lblColorless:UILabel?
    
    var manaBlack     = 0
    var manaBlue      = 0
    var manaGreen     = 0
    var manaRed       = 0
    var manaWhite     = 0
    var manaColorless = 0
    
    var lblCastingCost:UILabel?
    var viewCastingCost:UIView?
    var viewImage:UIImageView?
    var btnHelp:UILabel?
    var btnBuy:UILabel?
    var btnCast:UILabel?
    var btnNextCard:UILabel?
    var arrAnswers:Array<Array<UILabel>>?
    var arrQuizzes:[UILabel]?
    var cardIds:Array<String>?
    var currentCropPath:String?
    var currentCardPath:String?
    
    var predicate:NSPredicate?
    var userMana:PFObject?
    var gameType:String?

    // sounds
    var backgroundSoundPlayer:AVAudioPlayer?
    var successSoundPlayer:AVAudioPlayer?
    var failSoundPlayer:AVAudioPlayer?
    var answerDeleteSoundPlayer:AVAudioPlayer?
    var castSoundPlayer:AVAudioPlayer?
    
    
//  MARK: Boilerplate
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        hidesBottomBarWhenPushed = true
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name:kParseUserManaDone,  object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"fetchUserManaDone:",  name:kParseUserManaDone, object:nil)
        
        // load the sounds
//        backgroundSoundPlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("/audio/cardquiz_game", ofType: "caf")!), error: nil)
        
//        do {
//            try {
        
        
        self.backgroundSoundPlayer = try? AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("/audio/cardquiz_game", ofType: "caf")!), fileTypeHint: AVFileTypeCoreAudioFormat)
        self.backgroundSoundPlayer!.prepareToPlay()
        self.backgroundSoundPlayer!.volume = 1.0
        
        self.successSoundPlayer = try? AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("/audio/cardquiz_success", ofType: "caf")!), fileTypeHint: AVFileTypeCoreAudioFormat)
        self.successSoundPlayer!.prepareToPlay()
        self.successSoundPlayer!.volume = 1.0
        
        self.failSoundPlayer = try? AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("/audio/cardquiz_fail", ofType: "caf")!), fileTypeHint: AVFileTypeCoreAudioFormat)
        self.failSoundPlayer!.prepareToPlay()
        self.failSoundPlayer!.volume = 1.0
        
        self.answerDeleteSoundPlayer = try? AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("/audio/cardquiz_answer_delete", ofType: "caf")!), fileTypeHint: AVFileTypeCoreAudioFormat)
        self.answerDeleteSoundPlayer!.prepareToPlay()
        self.answerDeleteSoundPlayer!.volume = 1.0
        
        self.castSoundPlayer = try? AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("/audio/cardquiz_cast", ofType: "caf")!), fileTypeHint: AVFileTypeCoreAudioFormat)
        self.castSoundPlayer!.prepareToPlay()
        self.castSoundPlayer!.volume = 1.0
        
        setupBackground()
        setupManaPoints()
        setupCastingCost()
        setupFunctionButtons()
        updateManaPool()
        displayQuiz()
        
#if !DEBUG
        // send the screen to Google Analytics
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "Card Quiz Game")
        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject : AnyObject])
#endif
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.None
    }

    
//  MARK: UI Setup Code
    func setupBackground() {
        // play the background sound infinitely
        backgroundSoundPlayer!.numberOfLoops = -1
        backgroundSoundPlayer!.play()
        
        var dX = CGFloat(5)
        var dY = CGFloat(5)
        var dWidth = CGFloat(30)
        var dHeight = CGFloat(30)
        var dFrame = CGRect(x:dX, y:dY, width:dWidth, height:dHeight)
        
        btnClose = UIImageView(frame: dFrame)
        btnClose!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "closeTapped:"))
        btnClose!.userInteractionEnabled = true
        btnClose!.contentMode = UIViewContentMode.ScaleAspectFill
        btnClose!.image = UIImage(named: "cancel.png")
        self.view.addSubview(btnClose!)
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(contentsOfFile: "\(NSBundle.mainBundle().bundlePath)/images/Gray_Patterned_BG.jpg")!)
        
        dX = CGFloat(0)
        dY = btnClose!.frame.origin.y + btnClose!.frame.size.height + 10
        dWidth = self.view.frame.size.width
        dHeight = self.view.frame.height - dY - 125
        dFrame = CGRect(x:dX, y:dY, width:dWidth, height:dHeight)
        
        let circleImage = UIImageView(frame: dFrame)
        circleImage.contentMode = UIViewContentMode.ScaleAspectFill
        circleImage.image = UIImage(contentsOfFile: "\(NSBundle.mainBundle().bundlePath)/images/Card_Circles.png")
        self.view.addSubview(circleImage)
    }
    
    func setupManaPoints() {
        let manaWidth = (self.view.frame.size.width-10)/6
        let manaImageWidth = CGFloat(16)
        let manaImageHeight = CGFloat(16)
        let manaLabelWidth = manaWidth-manaImageWidth
        let manaLabelHeight = manaImageHeight+2
        
        var dX:CGFloat = 10
        let dY = btnClose!.frame.origin.y + btnClose!.frame.size.height + 10
        var dFrame = CGRect(x:dX, y:dY, width:manaImageWidth, height:manaImageHeight)
        var imageView = UIImageView(frame: dFrame)
        imageView.image = UIImage(contentsOfFile: "\(NSBundle.mainBundle().bundlePath)/images/mana/B/32.png")
        self.view.addSubview(imageView)
        
        dX = dFrame.origin.x + dFrame.size.width
        dFrame = CGRect(x:dX, y:dY, width:manaLabelWidth, height:manaLabelHeight)
        lblBlack = UILabel(frame: dFrame)
        lblBlack!.text = " 0"
        lblBlack!.font = CQTheme.kManaLabelFont
        lblBlack!.adjustsFontSizeToFitWidth = true
        lblBlack!.textColor = CQTheme.kManaLabelColor
        self.view.addSubview(lblBlack!)
        
        dX = dFrame.origin.x + dFrame.size.width
        dFrame = CGRect(x:dX, y:dY, width:manaImageWidth, height:manaImageHeight)
        imageView = UIImageView(frame: dFrame)
        imageView.image = UIImage(contentsOfFile: "\(NSBundle.mainBundle().bundlePath)/images/mana/U/32.png")
        self.view.addSubview(imageView)
        
        dX = dFrame.origin.x + dFrame.size.width
        dFrame = CGRect(x:dX, y:dY, width:manaLabelWidth, height:manaLabelHeight)
        lblBlue = UILabel(frame: dFrame)
        lblBlue!.text = " 0"
        lblBlue!.font = CQTheme.kManaLabelFont
        lblBlue!.adjustsFontSizeToFitWidth = true
        lblBlue!.textColor = CQTheme.kManaLabelColor
        self.view.addSubview(lblBlue!)
        
        dX = dFrame.origin.x + dFrame.size.width
        dFrame = CGRect(x:dX, y:dY, width:manaImageWidth, height:manaImageHeight)
        imageView = UIImageView(frame: dFrame)
        imageView.image = UIImage(contentsOfFile: "\(NSBundle.mainBundle().bundlePath)/images/mana/G/32.png")
        self.view.addSubview(imageView)
        
        dX = dFrame.origin.x + dFrame.size.width
        dFrame = CGRect(x:dX, y:dY, width:manaLabelWidth, height:manaLabelHeight)
        lblGreen = UILabel(frame: dFrame)
        lblGreen!.text = " 0"
        lblGreen!.font = CQTheme.kManaLabelFont
        lblGreen!.adjustsFontSizeToFitWidth = true
        lblGreen!.textColor = CQTheme.kManaLabelColor
        self.view.addSubview(lblGreen!)
        
        dX = dFrame.origin.x + dFrame.size.width
        dFrame = CGRect(x:dX, y:dY, width:manaImageWidth, height:manaImageHeight)
        imageView = UIImageView(frame: dFrame)
        imageView.image = UIImage(contentsOfFile: "\(NSBundle.mainBundle().bundlePath)/images/mana/R/32.png")
        self.view.addSubview(imageView)
        
        dX = dFrame.origin.x + dFrame.size.width
        dFrame = CGRect(x:dX, y:dY, width:manaLabelWidth, height:manaLabelHeight)
        lblRed = UILabel(frame: dFrame)
        lblRed!.text = " 0"
        lblRed!.font = CQTheme.kManaLabelFont
        lblRed!.adjustsFontSizeToFitWidth = true
        lblRed!.textColor = CQTheme.kManaLabelColor
        self.view.addSubview(lblRed!)
        
        dX = dFrame.origin.x + dFrame.size.width
        dFrame = CGRect(x:dX, y:dY, width:manaImageWidth, height:manaImageHeight)
        imageView = UIImageView(frame: dFrame)
        imageView.image = UIImage(contentsOfFile: "\(NSBundle.mainBundle().bundlePath)/images/mana/W/32.png")
        self.view.addSubview(imageView)
        
        dX = dFrame.origin.x + dFrame.size.width
        dFrame = CGRect(x:dX, y:dY, width:manaLabelWidth, height:manaLabelHeight)
        lblWhite = UILabel(frame: dFrame)
        lblWhite!.text = " 0"
        lblWhite!.font = CQTheme.kManaLabelFont
        lblWhite!.adjustsFontSizeToFitWidth = true
        lblWhite!.textColor = CQTheme.kManaLabelColor
        self.view.addSubview(lblWhite!)
        
        dX = dFrame.origin.x + dFrame.size.width
        dFrame = CGRect(x:dX, y:dY, width:manaImageWidth, height:manaImageHeight)
        imageView = UIImageView(frame: dFrame)
        imageView.image = UIImage(contentsOfFile: "\(NSBundle.mainBundle().bundlePath)/images/mana/Colorless/32.png")
        self.view.addSubview(imageView)
        
        dX = dFrame.origin.x + dFrame.size.width
        dFrame = CGRect(x:dX, y:dY, width:manaLabelWidth, height:manaLabelHeight)
        lblColorless = UILabel(frame: dFrame)
        lblColorless!.text = " 0"
        lblColorless!.font = CQTheme.kManaLabelFont
        lblColorless!.adjustsFontSizeToFitWidth = true
        lblColorless!.textColor = CQTheme.kManaLabelColor
        self.view.addSubview(lblColorless!)
    }
    
    func setupCastingCost() {
        let dWidth = self.view.frame.size.width * 0.70
        let dX = (self.view.frame.size.width - dWidth) / 2
        let dY = lblColorless!.frame.origin.y + lblColorless!.frame.size.height + 10
        let dHeight = CGFloat(16)
        let dFrame = CGRect(x:dX, y:dY, width:dWidth, height:dHeight)
        
        viewCastingCost = UIView(frame: dFrame)
        self.view.addSubview(viewCastingCost!)
    }
    
    func setupFunctionButtons() {
        var dX = CGFloat(0)
        let dY = self.view.frame.height - 120
        let dWidth = self.view.frame.size.width/3
        let dHeight = CGFloat(40)
        var dFrame = CGRect(x: dX, y: dY, width: dWidth, height: dHeight)
        
        // draw the ask button
        btnHelp = UILabel(frame: dFrame)
        btnHelp!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "helpTapped:"))
        btnHelp!.userInteractionEnabled = true
        btnHelp!.text = "Help"
        btnHelp!.textAlignment = NSTextAlignment.Center
        btnHelp!.font = CQTheme.kManaLabelFont
        btnHelp!.textColor = CQTheme.kTileTextColor
        btnHelp!.backgroundColor = JJJUtil.colorFromRGB(CQTheme.kTileColor)
        btnHelp!.layer.borderColor = JJJUtil.colorFromRGB(CQTheme.kTileBorderColor).CGColor
        btnHelp!.layer.borderWidth = 1
        self.view.addSubview(btnHelp!)
        
        // draw the buy button
        dX = dFrame.origin.x + dFrame.size.width
        dFrame = CGRect(x: dX, y: dY, width: dWidth, height: dHeight)
        btnBuy = UILabel(frame: dFrame)
        btnBuy!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "buyTapped:"))
        btnBuy!.userInteractionEnabled = true
        btnBuy!.text = "Buy Mana"
        btnBuy!.textAlignment = NSTextAlignment.Center
        btnBuy!.font = CQTheme.kManaLabelFont
        btnBuy!.textColor = CQTheme.kTileTextColor
        btnBuy!.backgroundColor = JJJUtil.colorFromRGB(CQTheme.kTileColor)
        btnBuy!.layer.borderColor = JJJUtil.colorFromRGB(CQTheme.kTileBorderColor).CGColor
        btnBuy!.layer.borderWidth = 1
        self.view.addSubview(btnBuy!)
        
        // draw the cast button
        dX = dFrame.origin.x + dFrame.size.width
        dFrame = CGRect(x: dX, y: dY, width: dWidth, height: dHeight)
        btnCast = UILabel(frame: dFrame)
        btnCast!.userInteractionEnabled = false
        btnCast!.text = "Cast"
        btnCast!.textAlignment = NSTextAlignment.Center
        btnCast!.font = CQTheme.kManaLabelFont
        btnCast!.textColor = CQTheme.kTileTextColorX
        btnCast!.backgroundColor = JJJUtil.colorFromRGB(CQTheme.kTileColor)
        btnCast!.layer.borderColor = JJJUtil.colorFromRGB(CQTheme.kTileBorderColor).CGColor
        btnCast!.layer.borderWidth = 1
        self.view.addSubview(btnCast!)
    }

    func updateManaPool() {
        if let mana = userMana {
            manaBlack     = mana.objectForKey("black")!.integerValue
            manaBlue      = mana.objectForKey("blue")!.integerValue
            manaGreen     = mana.objectForKey("green")!.integerValue
            manaRed       = mana.objectForKey("red")!.integerValue
            manaWhite     = mana.objectForKey("white")!.integerValue
            manaColorless = mana.objectForKey("colorless")!.integerValue
        }
        
        lblBlack!.text     = " \(manaBlack)"
        lblBlue!.text      = " \(manaBlue)"
        lblGreen!.text     = " \(manaGreen)"
        lblRed!.text       = " \(manaRed)"
        lblWhite!.text     = " \(manaWhite)"
        lblColorless!.text = " \(manaColorless)"
        
        if canCastCard() && btnCast != nil {
            if let recognizers = btnCast!.gestureRecognizers {
                for recognizer in recognizers {
                    btnCast!.removeGestureRecognizer(recognizer)
                }
            }
            btnCast!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "castTapped:"))
            btnCast!.userInteractionEnabled = true
            btnCast!.textColor = CQTheme.kTileTextColor
        }
    }

    func animateManaLabels() {
        // black
        var mana = Int(lblBlack!.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
        var color:UIColor?
        lblBlack!.text     = " \(manaBlack)"
        if mana < manaBlack {
            color = UIColor.greenColor()
        } else if mana > manaBlack {
            color = UIColor.redColor()
        }
        if color != nil {
            UIView.transitionWithView(lblBlack!, duration: 2, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {() in
                    self.lblBlack!.textColor = color
                }, completion: nil)
        }
        color = nil
        
        // blue
        mana = Int(lblBlue!.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
        lblBlue!.text     = " \(manaBlue)"
        if mana < manaBlue {
            color = UIColor.greenColor()
        } else if mana > manaBlue {
            color = UIColor.redColor()
        }
        if color != nil {
            UIView.transitionWithView(lblBlue!, duration: 2, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {() in
                self.lblBlue!.textColor = color
                }, completion: nil)
        }
        color = nil
        
        // green
        mana = Int(lblGreen!.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
        lblGreen!.text     = " \(manaGreen)"
        if mana < manaGreen {
            color = UIColor.greenColor()
        } else if mana > manaGreen {
            color = UIColor.redColor()
        }
        if color != nil {
            UIView.transitionWithView(lblGreen!, duration: 2, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {() in
                self.lblGreen!.textColor = color
                }, completion: nil)
        }
        color = nil

        // red
        mana = Int(lblRed!.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
        lblRed!.text     = " \(manaRed)"
        if mana < manaRed {
            color = UIColor.greenColor()
        } else if mana > manaRed {
            color = UIColor.redColor()
        }
        if color != nil {
            UIView.transitionWithView(lblRed!, duration: 2, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {() in
                self.lblRed!.textColor = color
                }, completion: nil)
        }
        color = nil

        // white
        mana = Int(lblWhite!.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
        lblWhite!.text     = " \(manaWhite)"
        if mana < manaWhite {
            color = UIColor.greenColor()
        } else if mana > manaWhite {
            color = UIColor.redColor()
        }
        if color != nil {
            UIView.transitionWithView(lblWhite!, duration: 2, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {() in
                self.lblWhite!.textColor = color
                }, completion: nil)
        }
        color = nil
        
        // colorless
        mana = Int(lblColorless!.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
        lblColorless!.text     = " \(manaColorless)"
        if mana < manaColorless {
            color = UIColor.greenColor()
        } else if mana > manaColorless {
            color = UIColor.redColor()
        }
        if color != nil {
            UIView.transitionWithView(lblColorless!, duration: 2, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {() in
                self.lblColorless!.textColor = color
                }, completion: nil)
        }
        color = nil
    }
    
    func displayQuiz() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name:kCardDownloadCompleted,  object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"loadCropImage:",  name:kCardDownloadCompleted, object:nil)
        
        let card = DTCard(forPrimaryKey: self.cardIds!.first)

        // reset the mana labels's colors
        if lblBlack!.textColor != CQTheme.kTileTextColor {
            lblBlack!.textColor = CQTheme.kTileTextColor
        }
        if lblBlue!.textColor != CQTheme.kTileTextColor {
            lblBlue!.textColor = CQTheme.kTileTextColor
        }
        if lblGreen!.textColor != CQTheme.kTileTextColor {
            lblGreen!.textColor = CQTheme.kTileTextColor
        }
        if lblRed!.textColor != CQTheme.kTileTextColor {
            lblRed!.textColor = CQTheme.kTileTextColor
        }
        if lblWhite!.textColor != CQTheme.kTileTextColor {
            lblWhite!.textColor = CQTheme.kTileTextColor
        }
        if lblColorless!.textColor != CQTheme.kTileTextColor {
            lblColorless!.textColor = CQTheme.kTileTextColor
        }
        
        // draw the mana cost
        let manaImages = FileManager.sharedInstance().manaImagesForCard(self.cardIds!.first) as! [NSDictionary]
        var dX = CGFloat(0)
        var dY = CGFloat(0)
        var index = 0
        var dWidth = viewCastingCost!.frame.size.width - CGFloat(manaImages.count * 16)
        var dHeight = CGFloat(20)
        var dFrame:CGRect?
        lblCastingCost = UILabel(frame: CGRect(x: dX, y: dY, width: dWidth, height: dHeight))
        lblCastingCost!.text = "Casting Cost: "
        lblCastingCost!.font = CQTheme.kLabelFont
        lblCastingCost!.adjustsFontSizeToFitWidth = true
        lblCastingCost!.textColor = CQTheme.kLabelColor
        viewCastingCost!.addSubview(lblCastingCost!)
        for dict in manaImages {
            dWidth = CGFloat((dict["width"] as! NSNumber).floatValue)
            dHeight = CGFloat((dict["height"] as! NSNumber).floatValue)
            let path = dict["path"] as! String
            dX = viewCastingCost!.frame.size.width - (CGFloat(manaImages.count-index) * dWidth)
            
            dFrame = CGRect(x: dX, y: dY, width: dWidth, height: dHeight)
            let imgMana = UIImageView(frame: dFrame!)
            
            imgMana.image = UIImage(contentsOfFile: path)
            viewCastingCost!.addSubview(imgMana)
            index++
        }
        
        // tokenize the answer
        arrAnswers = Array<Array<UILabel>>()
        var lines = [String]()
        for word in card!.name.componentsSeparatedByString(" ") {
            var line = lines.last != nil ? lines.last : word
            
            if word == line {
                lines.append(word)
                
            } else {
                if (line!.characters.count + word.characters.count + 1) <= 12 {
                    lines.removeLast()
                    line = line! + " " + word
                    lines.append(line!)
                } else {
                    lines.append(word)
                }
            }
        }
        
        // draw the answer view
        index = 0
        dY = self.view.frame.height - (120+10) - CGFloat(30*lines.count)
        for line in lines {
            var arr = Array<UILabel>()
            
            dWidth = self.view.frame.size.width/12
            dHeight = 30
            dX = (self.view.frame.width - (dWidth*CGFloat(line.characters.count)))/2
            for character in line.characters {
                dFrame = CGRect(x: dX, y: dY, width: dWidth, height: dHeight)
                let label = UILabel(frame: dFrame!)
                
                if character != " " {
                    label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "answerActivated:"))
                    label.userInteractionEnabled = true
                    label.text = "*"
                    label.textAlignment = NSTextAlignment.Center
                    label.font = CQTheme.kTileAnswerFont
                    label.textColor = CQTheme.kTileTextColor
                    label.backgroundColor = JJJUtil.colorFromRGB(CQTheme.kTileColor)
                    label.layer.borderColor = JJJUtil.colorFromRGB(CQTheme.kTileBorderColor).CGColor
                    label.layer.borderWidth = 1
                    label.tag = index
                } else {
                    label.text = " "
                }
                index++
                
                arr.append(label)
                self.view.addSubview(label)
                dX += dWidth
            }
            arrAnswers!.append(arr)
            dY += dHeight
            index++
        }
        
        // draw the image
        if let x = viewImage {
            x.removeFromSuperview()
        }
        dWidth = self.view.frame.size.width * 0.90
        dX = (self.view.frame.size.width - dWidth) / 2
        dY = viewCastingCost!.frame.origin.y + viewCastingCost!.frame.size.height + 10
        dHeight = self.view.frame.height - (120+20) - CGFloat(30*lines.count) - dY
        dFrame = CGRect(x:dX, y:dY, width:dWidth, height:dHeight)
        viewImage = UIImageView(frame: dFrame!)
        viewImage!.contentMode = UIViewContentMode.ScaleAspectFit
        self.view.addSubview(viewImage!)
        
        currentCropPath = FileManager.sharedInstance().cropPath(self.cardIds!.first)
        viewImage!.image = UIImage(contentsOfFile: currentCropPath!)
        FileManager.sharedInstance().downloadCardImage(self.cardIds!.first, immediately:true)
        
        // draw the quiz
        let quiz = self.quizForCard(card!)
        index = 0
        arrQuizzes = Array()
        dWidth = self.view.frame.size.width/10
        dHeight = 40
        dFrame = btnCast!.frame
        for i in 0...19 {
            if i%10 == 0 {
                dX = 0
                dY = dFrame!.origin.y + dFrame!.size.height
            }
            dFrame = CGRect(x: dX, y: dY, width: dWidth, height: dHeight)
            
            var text:String?
            if i <= quiz.characters.count-1 {
                let quizIndex = quiz.startIndex.advancedBy(i)
                text = String(quiz[quizIndex])
            }
            
            let label = UILabel(frame: dFrame!)
            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "quizActivated:"))
            label.userInteractionEnabled = true
            label.text = text != nil ? text : " "
            label.textAlignment = NSTextAlignment.Center
            label.font = CQTheme.kTileQuizFont
            label.textColor = CQTheme.kTileTextColor
            label.backgroundColor = JJJUtil.colorFromRGB(CQTheme.kTileColor)
            label.layer.borderColor = JJJUtil.colorFromRGB(CQTheme.kTileBorderColor).CGColor
            label.layer.borderWidth = 1
            label.tag = index
            index++
            arrQuizzes!.append(label)
            self.view.addSubview(label)
            
            dX += dFrame!.size.width
        }
    }
    
    func displayAnswer() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name:kCardDownloadCompleted,  object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"loadCardImage:",  name:kCardDownloadCompleted, object:nil)
        
        let dWidth = self.view.frame.size.width * 0.90
        let dX = (self.view.frame.size.width - dWidth) / 2
        let dY = viewCastingCost!.frame.origin.y + viewCastingCost!.frame.size.height + 10
        let dHeight = self.view.frame.height - 160
        
        let viewImageFrame = CGRect(x: dX, y: dY, width: dWidth, height: dHeight)
        let btnNextCardFrame = CGRect(x: btnBuy!.frame.origin.x, y: btnBuy!.frame.origin.y+80, width: btnBuy!.frame.size.width, height: btnBuy!.frame.size.height)
        
        // clean up
        viewImage!.removeFromSuperview()
        viewImage = nil
        
        if arrAnswers != nil {
            for arr in arrAnswers! {
                for label in arr {
                    label.removeFromSuperview()
                }
            }
        }
        btnHelp!.removeFromSuperview()
        btnHelp = nil
        
        btnBuy!.removeFromSuperview()
        btnBuy = nil
        
        btnCast!.removeFromSuperview()
        btnCast = nil
        
        if arrQuizzes != nil {
            for label in arrQuizzes! {
                label.removeFromSuperview()
            }
        }

        // load the full card image
        viewImage = UIImageView(frame: viewImageFrame)
        viewImage!.contentMode = UIViewContentMode.ScaleAspectFit
        self.view.addSubview(viewImage!)
        currentCardPath = FileManager.sharedInstance().cardPath(self.cardIds!.first)
        viewImage!.image = UIImage(contentsOfFile: currentCardPath!)
        FileManager.sharedInstance().downloadCardImage(self.cardIds!.first, immediately:true)
        
        // draw the next card button
        btnNextCard = UILabel(frame: btnNextCardFrame)
        btnNextCard!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "nextCardTapped:"))
        btnNextCard!.userInteractionEnabled = true
        btnNextCard!.text = "Next Card"
        btnNextCard!.textAlignment = NSTextAlignment.Center
        btnNextCard!.font = CQTheme.kManaLabelFont
        btnNextCard!.textColor = CQTheme.kTileTextColor
        btnNextCard!.backgroundColor = JJJUtil.colorFromRGB(CQTheme.kTileColor)
        btnNextCard!.layer.borderColor = JJJUtil.colorFromRGB(CQTheme.kTileBorderColor).CGColor
        btnNextCard!.layer.borderWidth = 1
        self.view.addSubview(btnNextCard!)
        
        self.animateManaLabels()
        self.saveMana()
    }

//  MARK: Logic Code
    func preloadRandomCards() {
        var key:String?
        var value:String?
        var format:String?
        var formatEx1:String?
        var formatEx2:String?
        
        if gameType == kCQEasyCurrentCard ||
           gameType == nil {
            if let v = NSUserDefaults.standardUserDefaults().stringForKey(kCQEasyCurrentCard) {
                value = v
            } else {
                key = kCQEasyCurrentCard
            }
            format = "Standard"
            formatEx1 = "Modern"
            formatEx2 = "Vintage"
            
        } else if gameType == kCQModerateCurrentCard {
            if let v = NSUserDefaults.standardUserDefaults().stringForKey(kCQModerateCurrentCard) {
                value = v
            } else {
                key = kCQModerateCurrentCard
            }
            format = "Modern"
            formatEx1 = "Standard"
            formatEx2 = "Vintage"
            
        } else if gameType == kCQHardCurrentCard {
            if let v = NSUserDefaults.standardUserDefaults().stringForKey(kCQHardCurrentCard) {
                value = v
            } else {
                key = kCQHardCurrentCard
            }
            format = "Vintage"
            formatEx1 = "Standard"
            formatEx2 = "Modern"
        }
        
//        let predicate1 = NSPredicate(format: "ANY legalities.format.name IN %@ AND NOT (ANY legalities.format.name IN %@)", [format!], [formatEx1!, formatEx2!])
        
        // 'Operator 'MATCHES' not supported for string type'
//        let predicate2 = NSPredicate(format: "cmc >= 1 AND cmc <= 15 AND name MATCHES %@", "^.{0,20}")
//        let predicate2 = NSPredicate(format: "cmc >= 1 AND cmc <= 15")
//        predicate = NSCompoundPredicate.andPredicateWithSubpredicates([predicate1, predicate2])
        
        cardIds = Array()
        for x in Database.sharedInstance().fetchRandomCardsFromFormats([format!], excludeFormats: [formatEx1!, formatEx2!], howMany: kCQMaxCurrentCards) {
            let card = x as! DTCard
            if self.checkValidCard(card) {
                let cardId = card.cardId
                FileManager.sharedInstance().downloadCardImage(cardId, immediately:false)
                cardIds!.append(cardId)
            }
        }
        
        if value != nil {
//            let array = split(value!) {$0 == "_"}
            // Swift 2: Xcode 7
            let array = value!.characters.split{$0 == " "}.map(String.init)
            let code = array[0]
            let number = array[1]
            let pred = NSPredicate(format: "set.code = %@ AND number = %@", code, number)
            let card = DTCard.objectsWithPredicate(pred).firstObject() as! DTCard
                
            if self.checkValidCard(card) {
                let cardId = card.cardId
                FileManager.sharedInstance().downloadCardImage(cardId, immediately:true)
                cardIds!.insert(cardId, atIndex:0)
            }
            
        } else {
            if cardIds!.count > 0 {
                let card = DTCard(forPrimaryKey: cardIds!.first)
                let value = card!.set.code + "_" + card!.number
                
                NSUserDefaults.standardUserDefaults().setObject(value, forKey: key!)
                NSUserDefaults.standardUserDefaults().synchronize()
            }
        }
    }
    
    func checkValidCard(card: DTCard) -> Bool {
        var nameOk = true
        
        // exclude cards with more than 12 characters in it's name
        for word in card.name.componentsSeparatedByString(" ") {
            if word.characters.count > 12 {
                return false
            }
        }
        
        // exclude cards with more than 20 characters in it's name
        if card.name.characters.count > 20 {
            return false
        }

        // exclude special mana symbols. only include B,U,G,R,W, and Colorless
        for elem in FileManager.sharedInstance().manaImagesForCard(card.cardId) as NSArray {
            let dict = elem as! NSDictionary
            
            for key in dict.allKeys {
                let k = key as! String
                
                if k == "symbol" {
                    if let v = dict[k] as? String {
                        if  v == "B"  ||
                            v == "U"  ||
                            v == "G"  ||
                            v == "R"  ||
                            v == "W"  ||
                            v == "1"  ||
                            v == "2"  ||
                            v == "3"  ||
                            v == "4"  ||
                            v == "5"  ||
                            v == "6"  ||
                            v == "7"  ||
                            v == "8"  ||
                            v == "9"  ||
                            v == "10" ||
                            v == "11" ||
                            v == "12" ||
                            v == "13" ||
                            v == "14" ||
                            v == "15" {
                            nameOk = true
                        } else {
                            nameOk = false
                        }
                    }
                }
            }
        }
        
        return nameOk
    }
    
    func rotateCards() {
        // remove the last card
        self.cardIds!.removeAtIndex(0)
        
        if self.gameType == kCQEasyCurrentCard {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(kCQEasyCurrentCard)
        } else if self.gameType == kCQModerateCurrentCard {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(kCQModerateCurrentCard)
        } else if self.gameType == kCQHardCurrentCard {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(kCQHardCurrentCard)
        }
        
        if self.cardIds!.count == 0 {
            self.preloadRandomCards()

        } else {
            // set up a new card
            let card = DTCard(forPrimaryKey: cardIds!.first)
            let value = card!.set.code + "_" + card!.number
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: self.gameType!)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }

    func saveMana() {
        let totalCMC = manaBlack +
            manaBlue +
            manaGreen +
            manaRed +
            manaWhite +
        manaColorless;
        
        userMana!.setObject(NSNumber(integer: manaBlack), forKey:"black")
        userMana!.setObject(NSNumber(integer: manaBlue), forKey:"blue")
        userMana!.setObject(NSNumber(integer: manaGreen), forKey:"green")
        userMana!.setObject(NSNumber(integer: manaRed), forKey:"red")
        userMana!.setObject(NSNumber(integer: manaWhite), forKey:"white")
        userMana!.setObject(NSNumber(integer: manaColorless), forKey:"colorless")
        userMana!.setObject(NSNumber(integer: totalCMC), forKey:"totalCMC")
        
        Database.sharedInstance().saveUserMana(userMana!)
    }
    
    func loadCropImage(sender: AnyObject) {
        let dict = sender.userInfo as Dictionary?
        let cardId = dict?["cardId"] as! String
        
        if cardIds!.first == cardId {
            let path = FileManager.sharedInstance().cropPath(cardIds!.first!)
            
            if path != currentCropPath {
                let hiResImage = UIImage(contentsOfFile: path)
                
                UIView.transitionWithView(viewImage!,
                    duration:1,
                    options: UIViewAnimationOptions.TransitionCrossDissolve,
                    animations: { self.viewImage!.image = hiResImage },
                    completion: nil)
            }
            
            NSNotificationCenter.defaultCenter().removeObserver(self, name:kCardDownloadCompleted,  object:nil)
        }
    }
    
    func loadCardImage(sender: AnyObject) {
        if btnNextCard == nil {
            return
        }

        let dict = sender.userInfo as Dictionary?
        let cardId = dict?["cardId"] as! String
        
        if cardIds!.first == cardId {
            let path = FileManager.sharedInstance().cardPath(cardIds!.first!)
            
            if path != currentCardPath {
                let hiResImage = UIImage(contentsOfFile: path)
                
                UIView.transitionWithView(viewImage!,
                    duration:1,
                    options: UIViewAnimationOptions.TransitionFlipFromLeft,
                    animations: { self.viewImage!.image = hiResImage },
                    completion: nil)
            }
            
            NSNotificationCenter.defaultCenter().removeObserver(self, name:kCardDownloadCompleted,  object:nil)
        }
    }

    func canCastCard() -> Bool {
        var ccBlack     = 0
        var ccBlue      = 0
        var ccGreen     = 0
        var ccRed       = 0
        var ccWhite     = 0
        var ccColorless = 0
        
        for dict in FileManager.sharedInstance().manaImagesForCard(cardIds!.first) as! [NSDictionary] {
            let symbol = dict["symbol"] as! String
            
            if symbol == "B" {
                ccBlack++
            } else if symbol == "U" {
                ccBlue++
            } else if symbol == "G" {
                ccGreen++
            } else if symbol == "R" {
                ccRed++
            } else if symbol == "W" {
                ccWhite++
            } else if symbol == "1" {
                ccColorless += 1
            } else if symbol == "2" {
                ccColorless += 2
            } else if symbol == "3" {
                ccColorless += 3
            } else if symbol == "4" {
                ccColorless += 4
            } else if symbol == "5" {
                ccColorless += 5
            } else if symbol == "6" {
                ccColorless += 6
            } else if symbol == "7" {
                ccColorless += 7
            } else if symbol == "8" {
                ccColorless += 8
            } else if symbol == "9" {
                ccColorless += 9
            } else if symbol == "10" {
                ccColorless += 10
            } else if symbol == "11" {
                ccColorless += 11
            } else if symbol == "12" {
                ccColorless += 12
            } else if symbol == "13" {
                ccColorless += 13
            } else if symbol == "14" {
                ccColorless += 14
            } else if symbol == "15" {
                ccColorless += 15
            }
        }
        
        var result = false
        let totalMana = manaBlack  + manaBlue + manaGreen + manaRed  + manaWhite + manaColorless
        result = totalMana > 0 &&
            manaBlack >= ccBlack &&
            manaBlue  >= ccBlue &&
            manaGreen >= ccGreen &&
            manaRed   >= ccRed &&
            manaWhite >= ccWhite &&
            totalMana >= ccColorless
        return result
    }
    
    func fetchUserManaDone(sender: AnyObject) {
        let dict = sender.userInfo as Dictionary?
        userMana = dict?["userMana"] as? PFObject
        self.updateManaPool()
    }

    func toggleUI(enabled: Bool) {
        
        lblBlack?.textColor = enabled ? CQTheme.kTileTextColor : CQTheme.kTileTextColorX
        lblBlue?.textColor = enabled ? CQTheme.kTileTextColor : CQTheme.kTileTextColorX
        lblGreen?.textColor = enabled ? CQTheme.kTileTextColor : CQTheme.kTileTextColorX
        lblRed?.textColor = enabled ? CQTheme.kTileTextColor : CQTheme.kTileTextColorX
        lblWhite?.textColor = enabled ? CQTheme.kTileTextColor : CQTheme.kTileTextColorX
        lblColorless?.textColor = enabled ? CQTheme.kTileTextColor : CQTheme.kTileTextColorX
        lblCastingCost?.textColor = enabled ? CQTheme.kTileTextColor : CQTheme.kTileTextColorX
        
        if arrAnswers != nil {
            for arr in arrAnswers! {
                for label in arr {
                    label.textColor = enabled ? CQTheme.kTileTextColor : CQTheme.kTileTextColorX
                    label.userInteractionEnabled = enabled
                }
            }
        }
        
        btnHelp?.textColor = enabled ? CQTheme.kTileTextColor : CQTheme.kTileTextColorX
        btnHelp?.userInteractionEnabled = enabled
        
        btnBuy?.textColor = enabled ? CQTheme.kTileTextColor : CQTheme.kTileTextColorX
        btnBuy?.userInteractionEnabled = enabled
        
        btnCast?.textColor = enabled ? CQTheme.kTileTextColor : CQTheme.kTileTextColorX
        btnCast?.userInteractionEnabled = enabled
        
        if arrQuizzes != nil {
            for label in arrQuizzes! {
                label.textColor = enabled ? CQTheme.kTileTextColor : CQTheme.kTileTextColorX
                label.userInteractionEnabled = enabled
            }
        }
    }
    
    
//  MARK: Event Handlers
    func closeTapped(sender: AnyObject) {
        backgroundSoundPlayer!.stop()
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name:kParseUserManaDone,  object:nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:kCardDownloadCompleted,  object:nil)
        
        if btnNextCard != nil {
            if gameType == kCQEasyCurrentCard {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(kCQEasyCurrentCard)
            } else if gameType == kCQModerateCurrentCard {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(kCQModerateCurrentCard)
            } else if gameType == kCQHardCurrentCard {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(kCQHardCurrentCard)
            }
            self.cardIds!.removeAtIndex(0)
        }
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func helpTapped(sender: UITapGestureRecognizer) {
        var sharingItems = Array<AnyObject>()
        
        // get screenshot
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0)
        self.view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        sharingItems.append("Help, what is the name of this card? -Decktracker Card Quiz")
        sharingItems.append(screenshot!)
        
        let activityController = UIActivityViewController(activityItems:sharingItems, applicationActivities:nil)
        activityController.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList, UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypePrint]
        activityController.completionWithItemsHandler = {(activityType: String?, completed: Bool, returnedItems: [AnyObject]?, activityError: NSError?) -> Void in
            
            if (completed) {
                JJJUtil.alertWithTitle("Help", andMessage:"Help sent.")
            }
        }
        
        self.presentViewController(activityController, animated:true, completion:nil)
    }
    
    func buyTapped(sender: UITapGestureRecognizer) {
        let doneBlock = { (picker: ActionSheetStringPicker?, selectedIndex: NSInteger, selectedValue: AnyObject?) -> Void in
            
            self.backgroundSoundPlayer!.pause()
            
            let filePath = "\(NSBundle.mainBundle().bundlePath)/In-App Mana.plist"
            let arrMana = NSArray(contentsOfFile: filePath)
            var dict:Dictionary<String, String>?
            
            switch selectedIndex {
            case 0:
                dict = arrMana![0] as? Dictionary<String, String>
            case 1:
                dict = arrMana![1] as? Dictionary<String, String>
            case 2:
                dict = arrMana![2] as? Dictionary<String, String>
            default:
                break
            }
            
            let view2 = InAppPurchaseViewController()
            
            view2.delegate = self
            view2.productID = dict!["In-App Product ID"]
            view2.productDetails = ["name": dict!["In-App Display Name"] as String!,
                "description": dict!["In-App Description"] as String!]
            
            self.presentViewController(view2, animated: false, completion: nil)
        }
        
//        let cancelBlock = { (picker: ActionSheetStringPicker? ) -> Void in
//            self.backgroundSoundPlayer!.play()
//        }
        
        ActionSheetStringPicker.showPickerWithTitle("Buy Mana",
            rows: ["18 Mana", "60 Mana", "100 Mana"],
            initialSelection: 0,
            doneBlock: doneBlock,
            cancelBlock: nil,
            origin: view)
    }
    
    func nextCardTapped(sender: UITapGestureRecognizer) {
        let hud = MBProgressHUD(view: self.view)
        hud.delegate = self
        self.view.addSubview(hud)
        
        let executingBlock = { () -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                // clean
                self.lblCastingCost!.removeFromSuperview()
                self.lblCastingCost = nil
                
                for view in self.viewCastingCost!.subviews {
                    view.removeFromSuperview()
                }
                self.viewCastingCost!.removeFromSuperview()
                self.viewCastingCost = nil
                
                self.viewImage!.removeFromSuperview()
                self.viewImage = nil
                
                self.btnNextCard!.removeFromSuperview()
                self.btnNextCard = nil
                
                self.rotateCards()
                self.setupCastingCost()
                self.setupFunctionButtons()
                self.updateManaPool()
                self.displayQuiz()
            }
        }
        
        hud.showAnimated(true, whileExecutingBlock:executingBlock, completionBlock:nil)
    }
    
    func castTapped(sender: UITapGestureRecognizer) {
        let dX = viewCastingCost!.frame.origin.x
        let dY = viewCastingCost!.frame.origin.y + viewCastingCost!.frame.size.height + 10
        let dWidth = viewCastingCost!.frame.size.width
        let dHeight = self.view.frame.height - 120 - dY
        let dFrame = CGRect(x:dX, y:dY, width:dWidth, height:dHeight)
        
        let manaChooser = CQManaChooserView(frame: dFrame, title: "Pay the Casting Cost", userMana: userMana!, cardId: cardIds!.first!)
        manaChooser.delegate = self
        self.toggleUI(false)
        
        view.addSubview(manaChooser)
    }
    
    func answerActivated(sender: UITapGestureRecognizer) {
        let label = sender.view as! UILabel
        
        if label.text == "*" {
            return
        }
        
        for arr in arrAnswers! {
            for lblAnswer in arr {
                if lblAnswer.textColor == UIColor.redColor() {
                    lblAnswer.textColor = UIColor.whiteColor()
                }
            }
        }
        answerDeleteSoundPlayer!.play()
        
        for lblQuiz in arrQuizzes! {
            if lblQuiz.text == " " {
                lblQuiz.text = label.text
                label.text = "*"
                return
            }
        }
    }
    
    func quizActivated(sender: UITapGestureRecognizer) {
        let label = sender.view as! UILabel
        var answer = String()
        
        if label.text == " " {
            return
        }
        
        for arr in arrAnswers! {
            var bBreak = false
            
            for lblAnswer in arr {
                if lblAnswer.text == "*" {
                    lblAnswer.text = label.text
                    label.text = " "
                    bBreak = true
                    break
                }
            }
            
            if bBreak {
                break
            }
        }
        
        
        for arr in arrAnswers! {
            for lblAnswer in arr {
                answer += lblAnswer.text!
            }
            answer += " "
        }
        answer = answer.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())

        if answer.rangeOfString("*") == nil {
            let card = DTCard(forPrimaryKey: cardIds!.first)
            
            if answer.lowercaseString == card!.name.lowercaseString {

                for dict in FileManager.sharedInstance().manaImagesForCard(cardIds!.first) as! [NSDictionary] {
                    let symbol = dict["symbol"] as! String
                    
                    if symbol == "B" {
                        manaBlack++
                    } else if symbol == "U" {
                        manaBlue++
                    } else if symbol == "G" {
                        manaGreen++
                    } else if symbol == "R" {
                        manaRed++
                    } else if symbol == "W" {
                        manaWhite++
                    } else if symbol == "1" {
                        manaColorless += 1
                    } else if symbol == "2" {
                        manaColorless += 2
                    } else if symbol == "3" {
                        manaColorless += 3
                    } else if symbol == "4" {
                        manaColorless += 4
                    } else if symbol == "5" {
                        manaColorless += 5
                    } else if symbol == "6" {
                        manaColorless += 6
                    } else if symbol == "7" {
                        manaColorless += 7
                    } else if symbol == "8" {
                        manaColorless += 8
                    } else if symbol == "9" {
                        manaColorless += 9
                    } else if symbol == "10" {
                        manaColorless += 10
                    } else if symbol == "11" {
                        manaColorless += 11
                    } else if symbol == "12" {
                        manaColorless += 12
                    } else if symbol == "13" {
                        manaColorless += 13
                    } else if symbol == "14" {
                        manaColorless += 14
                    } else if symbol == "15" {
                        manaColorless += 15
                    }
                }
                
                lblCastingCost!.text = "Added To Your Mana Pool: "
                displayAnswer()
                successSoundPlayer!.play()
                
            } else {
                for arr in arrAnswers! {
                    for lblAnswer in arr {
                        lblAnswer.textColor = UIColor.redColor()
                    }
                }
                failSoundPlayer!.play()
            }
        }
    }
    
    func quizForCard(card: DTCard) -> String {
        let xcount = card.name.characters.count
        var quiz = String()
        var name = Array(arrayLiteral: card.name)
        
        for _ in 0...xcount-1 {
            let random = Int(arc4random_uniform(UInt32(name.count-1)))
            let letter = String(name[random])
            if letter != " " {
                quiz += letter.capitalizedString
            }
            name.removeAtIndex(random)
        }
        
        // add random spaces
        var jumble = String()
        let countQuiz = quiz.characters.count
        let countSpaces = 20 - countQuiz
        var iQuiz = 0
        var iSpaces = 0
        for _ in 0...19 {
            switch Int(arc4random_uniform(UInt32(2))) {
            case 0:
                if iQuiz <= countQuiz-1 {
                    let index = quiz.startIndex.advancedBy(iQuiz)
                    let letter = String(quiz[index])
                    jumble += letter
                    iQuiz++
                    
                } else if iSpaces <= countSpaces-1 {
                    jumble += " "
                    iSpaces++
                    
                }
                
            case 1:
                if iSpaces <= countSpaces-1 {
                    jumble += " "
                    iSpaces++

                } else if iQuiz <= countQuiz-1 {
                    let index = quiz.startIndex.advancedBy(iQuiz)
                    let letter = String(quiz[index])
                    jumble += letter
                    iQuiz++
                    
                }

            default:
                break
            }
        }
        
#if DEBUG
        print("\(card.name)")
#endif
        return jumble
    }
    
//    MARK:  MBProgressHUDDelegate
    func hudWasHidden(hud: MBProgressHUD) {
        hud.removeFromSuperview()
    }
    
//    MARK: InAppPurchaseViewControllerDelegate
    func productPurchaseCancelled() {
        backgroundSoundPlayer!.play()
    }
    
    func productPurchaseSucceeded(productID: String) {
        
        if productID == "18Mana_ID" {
            manaBlack     += 3
            manaBlue      += 3
            manaGreen     += 3
            manaRed       += 3
            manaWhite     += 3
            manaColorless += 3
        } else if productID == "60Mana_ID" {
            manaBlack     += 11
            manaBlue      += 11
            manaGreen     += 11
            manaRed       += 11
            manaWhite     += 11
            manaColorless += 5
        } else if productID == "100BMana_ID" {
            manaBlack     += 18
            manaBlue      += 18
            manaGreen     += 18
            manaRed       += 18
            manaWhite     += 18
            manaColorless += 10
        }
        
        backgroundSoundPlayer!.play()
        animateManaLabels()
        saveMana()
    }
    
//    MARK: CQManaChooserViewDelegate
    func manaChooserCancelTapped(sender: CQManaChooserView) {
        sender.removeFromSuperview()
        toggleUI(true)
    }
    
    func manaChooserOkTapped(sender: CQManaChooserView, mana: Dictionary<String, NSNumber>) {
        for (k,v) in mana {
            if k == "black" {
                manaBlack -= v.integerValue
            } else if k == "blue" {
                manaBlue -= v.integerValue
            } else if k == "green" {
                manaGreen -= v.integerValue
            } else if k == "red" {
                manaRed -= v.integerValue
            } else if k == "white" {
                manaWhite -= v.integerValue
            } else if k == "colorless" {
                manaColorless -= v.integerValue
            }
        }
        
        sender.removeFromSuperview()
        toggleUI(true)
        
        lblCastingCost!.text = "Removed From Your Mana Pool: "
        displayAnswer()
        castSoundPlayer!.play()
    }
}
