//
//  JSONLoader.swift
//  DataSource
//
//  Created by Jovit Royeca on 29/06/2016.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import Foundation

class JSONLoader: NSObject {

    let eightEditionRelease = "2003-07-28"
    var eightEditionReleaseDate:NSDate?
    var magicCardInfoSets = [String: AnyObject]()
    
    func json2Database() {
        let filePath = "\(NSBundle.mainBundle().resourcePath!)/Data/AllSets-x.json"
        print("filePath=\(filePath)")
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        eightEditionReleaseDate = dateFormatter.dateFromString(eightEditionRelease)
        
        CoreDataManager.sharedInstance.setup(Constants.CoreDataSQLiteFile, modelFile: Constants.CoreDataModelFile)
        
        // Create additional CardColors
        ObjectManager.sharedInstance.findOrCreateColor(["name": "Colorless"])
        ObjectManager.sharedInstance.findOrCreateColor(["name": "Multicolored"])
        CoreDataManager.sharedInstance.saveMainContext()

        if let data = NSData(contentsOfFile: filePath) {
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data,  options:.MutableContainers)
            
                if let dict = json as? [String: AnyObject] {
                    
                    // parse the sets
                    for setName in dict.keys {
                        if let dictSets = dict[setName] as? [String: AnyObject] {
                            parseSet(dictSets)
                        }
                    }
                    
                    // parse the cards
                    for setName in dict.keys {
                        if let dictSets = dict[setName] as? [String: AnyObject] {
                            let set = parseSet(dictSets)
//                            if set.code != "LEA" {
//                                continue
//                            }
                            
                            if let dictCards = dictSets["cards"] as? [[String: AnyObject]] {
                                let cards = parseCards(dictCards, forSet: set)
                                set.numberOfCards = NSNumber(integer: cards.count)
                                CoreDataManager.sharedInstance.saveMainContext()
                            }
                        }
                    }
                    
//                     parse extra info
                    var dateStart = NSDate()
                    print("Start parsing variations...")
                    for setName in dict.keys {
                        if let dictSets = dict[setName] as? [String: AnyObject] {
                            if let dictCards = dictSets["cards"] as? [[String: AnyObject]] {
                                parseVariations(dictCards)
                            }
                        }
                    }
                    var dateEnd = NSDate()
                    var timeDifference = dateEnd.timeIntervalSinceDate(dateStart)
                    print("Time Elapsed: \(JJJUtil.formatInterval(timeDifference))")
                    
                    dateStart = NSDate()
                    print("Start parsing rulings...")
                    for setName in dict.keys {
                        if let dictSets = dict[setName] as? [String: AnyObject] {
                            if let dictCards = dictSets["cards"] as? [[String: AnyObject]] {
                                parseRulings(dictCards)
                            }
                        }
                    }
                    dateEnd = NSDate()
                    timeDifference = dateEnd.timeIntervalSinceDate(dateStart)
                    print("Time Elapsed: \(JJJUtil.formatInterval(timeDifference))")
                    
                    dateStart = NSDate()
                    print("Start parsing legalities...")
                    for setName in dict.keys {
                        if let dictSets = dict[setName] as? [String: AnyObject] {
                            if let dictCards = dictSets["cards"] as? [[String: AnyObject]] {
                                parseLegalities(dictCards)
                            }
                        }
                    }
                    dateEnd = NSDate()
                    timeDifference = dateEnd.timeIntervalSinceDate(dateStart)
                    print("Time Elapsed: \(JJJUtil.formatInterval(timeDifference))")
                    
//                    dateStart = NSDate()
//                    print("Start parsing foreign names...")
//                    for setName in dict.keys {
//                        if let dictSets = dict[setName] as? [String: AnyObject] {
//                            if let dictCards = dictSets["cards"] as? [[String: AnyObject]] {
//                                parseForeignNames(dictCards)
//                            }
//                        }
//                    }
//                    dateEnd = NSDate()
//                    timeDifference = dateEnd.timeIntervalSinceDate(dateStart)
//                    print("Time Elapsed: \(JJJUtil.formatInterval(timeDifference))")
                }
            } catch {
                
            }
        }
        
        CoreDataManager.sharedInstance.saveMainContext()
    }
    
    func updateCardNumbers() {
        CoreDataManager.sharedInstance.setup(Constants.CoreDataSQLiteFile, modelFile: Constants.CoreDataModelFile)
        
        // update the card numbers
        let predicate = NSPredicate(format: "number == nil")
//        let predicate = NSPredicate(format: "set.name == %@", "Alliances")
        let sorters = [NSSortDescriptor(key: "set.releaseDate", ascending: true),
                       NSSortDescriptor(key: "name", ascending: true)]
        for card in ObjectManager.sharedInstance.findObjects("Card", predicate: predicate, sorters: sorters) {
            let c = card as! Card
            updateNumberOfCard(c)
        }
        CoreDataManager.sharedInstance.saveMainContext()
    }
    
    func parseSet(dict: [String: AnyObject]) -> Set {
        let set = ObjectManager.sharedInstance.findOrCreateSet(dict)
        
        if let _ = dict[Block.Keys.Name] as? String {
            set.block = ObjectManager.sharedInstance.findOrCreateBlock(dict)
        }
        if let _ = dict[Border.Keys.Name] as? String {
            set.border = ObjectManager.sharedInstance.findOrCreateBorder(dict)
        }
        if let _ = dict[SetType.Keys.Name] as? String {
            set.type = ObjectManager.sharedInstance.findOrCreateSetType(dict)
        }
        set.tcgPlayerName = getTcgPlayerName(set.name!)
        
        if set.magicCardsInfoCode == nil {
           set.magicCardsInfoCode = getMagicCardsInfoCode(set.code!)
        }
        CoreDataManager.sharedInstance.savePrivateContext()
        return set
    }
    
    func getTcgPlayerName(name: String) -> String? {
        let filePath = "\(NSBundle.mainBundle().resourcePath!)/Data/tcgplayer_sets.plist"
        
        if let dict = NSDictionary(contentsOfFile: filePath) as? [String: AnyObject] {
            if let tcgPlayerName = dict[name] as? String {
                return tcgPlayerName
            }
        }
        
        return nil
    }
    
    func getMagicCardsInfoCode(code: String) -> String? {
        let filePath = "\(NSBundle.mainBundle().resourcePath!)/Data/magiccardsinfo_sets.plist"
        
        if let dict = NSDictionary(contentsOfFile: filePath) as? [String: AnyObject] {
            if let magicCardsInfoCode = dict[code] as? String {
                return magicCardsInfoCode.characters.count > 0 ? magicCardsInfoCode : nil
            }
        }
        
        return nil
    }
    
    func parseCards(dict: [[String: AnyObject]], forSet set: Set) -> [Card] {
        var cards = [Card]()
        
        for dictCard in dict {
            let card = ObjectManager.sharedInstance.findOrCreateCard(dictCard)
            
            card.set = set
            if let _ = dictCard[Layout.Keys.Name] as? String {
                card.layout = ObjectManager.sharedInstance.findOrCreateLayout(dictCard)
            }
            if let dictColors = dictCard["colors"] as? [String] {
                let colors = card.mutableSetValueForKey("colors")
                var multicolored = false
                var currentColor:Color?
                
                for color in dictColors {
                    let cardColor = ObjectManager.sharedInstance.findOrCreateColor([Color.Keys.Name: color])
                    colors.addObject(cardColor)
                    
                    if cardColor.name != "Colorless" &&
                        currentColor != nil &&
                        cardColor.objectID != currentColor!.objectID {
                        multicolored = true
                    }
                    currentColor = cardColor
                }
                card.colorSection = multicolored ? ObjectManager.sharedInstance.findOrCreateColor([Color.Keys.Name: "Multicolor"]) : (currentColor != nil ? currentColor : ObjectManager.sharedInstance.findOrCreateColor([Color.Keys.Name: "Colorless"]))
            } else {
                card.colorSection = ObjectManager.sharedInstance.findOrCreateColor([Color.Keys.Name: "Colorless"])
            }
            
            if let dictColorIdentity = dictCard["colorIdentity"] as? [String] {
                let colorIdentities = card.mutableSetValueForKey("colors")
                
                for symbol in dictColorIdentity {
                    let predicate = NSPredicate(format: "symbol == %@", symbol)
                    
                    if let cardColor = ObjectManager.sharedInstance.findObjects("Color", predicate: predicate, sorters: [NSSortDescriptor(key: "name", ascending: true)]).first {
                        colorIdentities.addObject(cardColor)
                    }
                }
            }
            if let type = dictCard[CardType.Keys.Type] as? String {
                card.type = ObjectManager.sharedInstance.findOrCreateCardType([CardType.Keys.Name: type])
            }
            if let dictSupertypes = dictCard[CardType.Keys.Supertypes] as? [String] {
                let supertypes = card.mutableSetValueForKey(CardType.Keys.Supertypes)
                
                for supertype in dictSupertypes {
                    let cardSupertype = ObjectManager.sharedInstance.findOrCreateCardType([CardType.Keys.Name: supertype])
                    supertypes.addObject(cardSupertype)
                }
            }
            if let dictSubtypes = dictCard[CardType.Keys.Subtypes] as? [String] {
                let subtypes = card.mutableSetValueForKey(CardType.Keys.Subtypes)
                
                for subtype in dictSubtypes {
                    let cardSubtype = ObjectManager.sharedInstance.findOrCreateCardType([CardType.Keys.Name: subtype])
                    subtypes.addObject(cardSubtype)
                }
            }
            if let dictTypes = dictCard[CardType.Keys.Types] as? [String] {
                let types = card.mutableSetValueForKey(CardType.Keys.Types)
                
                for type in dictTypes {
                    let cardType = ObjectManager.sharedInstance.findOrCreateCardType([CardType.Keys.Name: type])
                    types.addObject(cardType)
                }
            }
            if let _ = dictCard[Rarity.Keys.Name] as? String {
                card.rarity = ObjectManager.sharedInstance.findOrCreateRarity(dictCard)
            }
            if let _ = dictCard[Artist.Keys.Name] as? String {
                card.artist = ObjectManager.sharedInstance.findOrCreateArtist(dictCard)
            }
            if let _ = dictCard[Watermark.Keys.Name] as? String {
                card.watermark = ObjectManager.sharedInstance.findOrCreateWatermark(dictCard)
            }
            if let _ = dictCard[Border.Keys.Name] as? String {
                card.border = ObjectManager.sharedInstance.findOrCreateBorder(dictCard)
            }
            if let dictPrintings = dictCard["printings"] as? [String] {
                let printings = card.mutableSetValueForKey("printings")
                
                for printing in dictPrintings {
                    let predicate = NSPredicate(format: "code == %@", printing)
                    if let set = ObjectManager.sharedInstance.findObjects("Set", predicate: predicate, sorters: [NSSortDescriptor(key: "code", ascending: true)]).first {
                        printings.addObject(set)
                    }
                }
            }
            if let originalType = dictCard[CardType.Keys.OriginalType] as? String {
                card.originalType = ObjectManager.sharedInstance.findOrCreateCardType([CardType.Keys.Name: originalType])
            }
            if let _ = dictCard[Source.Keys.Name] as? String {
                card.source = ObjectManager.sharedInstance.findOrCreateSource(dictCard)
            }

            // if release date is greater than 8th Edition, card is modern
            if let releaseDate = card.releaseDate {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "YYYY-MM-dd"
                
                var actualReleaseDate:NSDate?
                
                if releaseDate.characters.count == 4 {
                    actualReleaseDate = dateFormatter.dateFromString("\(releaseDate)-01-01")
                } else if releaseDate.characters.count == 7 {
                    actualReleaseDate = dateFormatter.dateFromString("\(releaseDate)-01")
                } else {
                    actualReleaseDate = dateFormatter.dateFromString(releaseDate)
                }
                
                if let actualReleaseDate = actualReleaseDate,
                    eightEditionReleaseDate = eightEditionReleaseDate {
                    card.modern = NSNumber(bool: actualReleaseDate.compare(eightEditionReleaseDate) == .OrderedSame ||
                    actualReleaseDate.compare(eightEditionReleaseDate) == .OrderedDescending)
                }
                
            } else {
                if let releaseDate = card.set!.releaseDate,
                    eightEditionReleaseDate = eightEditionReleaseDate {
                    card.modern = NSNumber(bool: releaseDate.compare(eightEditionReleaseDate) == .OrderedSame ||
                        releaseDate.compare(eightEditionReleaseDate) == .OrderedDescending)
                }
            }
            
            print("\(card.name!) (\(card.set!.code!))")
            cards.append(card)
        }
        
        CoreDataManager.sharedInstance.savePrivateContext()
        return cards
    }
    
    func parseVariations(dict: [[String: AnyObject]]) {
        for dictCard in dict {
            if let dictVariations = dictCard["variations"] as? [NSNumber] {
                let card = ObjectManager.sharedInstance.findOrCreateCard(dictCard)
                let variations = card.mutableSetValueForKey("variations")
        
                for variation in dictVariations {
                    let predicate = NSPredicate(format: "multiverseID == %@", variation)
                    
                    if let cardVariation = ObjectManager.sharedInstance.findObjects("Card", predicate: predicate, sorters: [NSSortDescriptor(key: "multiverseID", ascending: true)]).first {
                        variations.addObject(cardVariation)
                    }
                }
            }
        }
        
        CoreDataManager.sharedInstance.savePrivateContext()
    }
    
    func parseRulings(dict: [[String: AnyObject]]) {
        for dictCard in dict {
            if let dictRulings = dictCard["rulings"] as? [[String: AnyObject]] {
                let card = ObjectManager.sharedInstance.findOrCreateCard(dictCard)
                let rulings = card.mutableSetValueForKey("rulings")
                
                for ruling in dictRulings {
                    let cardRuling = ObjectManager.sharedInstance.findOrCreateRuling(card, dict: ruling)
                    rulings.addObject(cardRuling)
                }
            }
        }
        
        CoreDataManager.sharedInstance.savePrivateContext()
    }
    
    func parseLegalities(dict: [[String: AnyObject]]) {
        for dictCard in dict {
            if let dictLegalities = dictCard["legalities"] as? [[String: AnyObject]] {
                let card = ObjectManager.sharedInstance.findOrCreateCard(dictCard)
                let legalities = card.mutableSetValueForKey("legalities")
                
                for legality in dictLegalities {
                    let cardLegality = ObjectManager.sharedInstance.findOrCreateCardLegality(card, dict: legality)
                    legalities.addObject(cardLegality)
                }
            }
        }
        
        CoreDataManager.sharedInstance.savePrivateContext()
    }
    
    func parseForeignNames(dict: [[String: AnyObject]]) {
        for dictCard in dict {
            if let dictForeignNames = dictCard["foreignNames"] as? [[String: AnyObject]] {
                let card = ObjectManager.sharedInstance.findOrCreateCard(dictCard)
                let foreignNames = card.mutableSetValueForKey("foreignNames")
                
                for foreignName in dictForeignNames {
                    let cardForeignName = ObjectManager.sharedInstance.findOrCreateForeignName(card, dict: foreignName)
                    foreignNames.addObject(cardForeignName)
                }
            }
        }
        
        CoreDataManager.sharedInstance.savePrivateContext()
    }
    
    func updateNumberOfCard(card: Card) {
        if let magicCardsInfoCode = card.set!.magicCardsInfoCode {
            var dict:NSMutableDictionary?
            
            if let d = magicCardInfoSets[card.set!.code!] as? NSMutableDictionary {
                dict = d
            } else {
                let url = NSURL(string: "http://magiccards.info/\(magicCardsInfoCode)/en.html")
                let data = NSData(contentsOfURL: url!)
                let parser = TFHpple(HTMLData: data!)
                dict = NSMutableDictionary()
                
                dict!.addEntriesFromDictionary(parseCardNumber(parser.searchWithXPathQuery("//tr[@class='even']")) as [NSObject : AnyObject])
                dict!.addEntriesFromDictionary(parseCardNumber(parser.searchWithXPathQuery("//tr[@class='odd']")) as [NSObject : AnyObject])
                
                magicCardInfoSets[card.set!.code!] = dict
            }
            
            for (key,value) in dict! {
                if let name = card.name,
                    let key = key as? String,
                    let value = value as? String{
                    
                    if name.lowercaseString == value.lowercaseString {
                        print("\(card.name!) (\(card.set!.code!))")
                        card.number = key
                        CoreDataManager.sharedInstance.savePrivateContext()
                        
                        dict!.removeObjectForKey(key)
                        break
                    }
                }
            }
            
            if dict!.count == 0 {
                magicCardInfoSets[card.set!.code!] = nil
            }
            
        } else {
            return
        }
    }
    
    func parseCardNumber(nodes: NSArray) -> NSDictionary {
        let dict = NSMutableDictionary()
     
        for node in nodes {
            let tr = node as! TFHppleElement
            var number:String?
            var name:String?
            
            for td in tr.children {
                if td.tagName == "td" {
                    if number == nil {
                        if let firstChild = td.firstChild {
                            number = firstChild.content
                        }
                    }
                    if name == nil {
                        for elem in td.children {
                            if let firstChild = elem.firstChild {
                                name = firstChild?.content
                            }
                        }
                    }
                }
                
                if let number = number,
                    let name = name {
                    dict.setObject(name, forKey: number)
                }
            }
        }
        
        return dict
    }
}
