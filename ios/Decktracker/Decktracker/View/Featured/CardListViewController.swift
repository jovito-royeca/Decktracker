//
//  CardListViewController.swift
//  Decktracker
//
//  Created by Jovit Royeca on 1/18/15.
//  Copyright (c) 2015 Jovito Royeca. All rights reserved.
//

import UIKit

enum CardViewMode: Printable  {
    case ByList
    case ByGrid2x2
    case ByGrid3x3
    
    var description : String {
        switch self {
        case ByList: return "List"
        case ByGrid2x2: return "Grid 2x2"
        case ByGrid3x3: return "Grid 3x3"
        }
    }
}

enum CardSortMode: Printable  {
    case ByName
    case ByColor
    case ByType
    case ByRarity
    case ByPrice
    
    var description : String {
        switch self {
        case ByName: return "Name"
        case ByColor: return "Color"
        case ByType: return "Type"
        case ByRarity: return "Rarity"
        case ByPrice: return "Price (Median)"
        }
    }
}

class CardListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

    let kSearchResultsIdentifier = "kSearchResultsIdentifier"
    
    var viewButton:UIBarButtonItem?
    var sortButton:UIBarButtonItem?
    var tblSets:UITableView?
    var colSets:UICollectionView?
    var sections:[String: [AnyObject]]?
    var sectionIndexTitles:[String]?
    var arrayData:[AnyObject]?
    var predicate:NSPredicate?
    var sorters:[NSSortDescriptor]?
    var viewMode:CardViewMode?
    var sortMode:CardSortMode?
    var sectionName:String?
    var viewLoadedOnce = true
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        var nsfrc = Database.sharedInstance().search(nil, withPredicate:self.predicate, withSortDescriptors: self.sorters, withSectionName:self.sectionName)
        
        self.fetchedResultsController = nsfrc
        self.fetchedResultsController.delegate = self
        return self.fetchedResultsController
        } ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        viewButton = UIBarButtonItem(image: UIImage(named: "insert_table.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "viewButtonTapped")
        sortButton = UIBarButtonItem(image: UIImage(named: "generic_sorting.png"), style: UIBarButtonItemStyle.Plain, target: self, action: "sortButtonTapped")
        
        navigationItem.rightBarButtonItems = [sortButton!, viewButton!]
        
        self.viewMode = CardViewMode.ByList
        self.sortMode = CardSortMode.ByName
        self.sectionName = "sectionNameInitial"
        self.showTableView()
        self.loadData()
        self.viewLoadedOnce = false
        
#if !DEBUG
        // send the screen to Google Analytics
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "Set: \(self.navigationItem.title!)")
        tracker.send(GAIDictionaryBuilder.createScreenView().build())
#endif
    }
    
    func hidesBottomBarWhenPushed() -> Bool {
        return true
    }

    func viewButtonTapped() {
        let viewOptions = [CardViewMode.ByList.description,
                           CardViewMode.ByGrid2x2.description,
                           CardViewMode.ByGrid3x3.description]
        var initialSelection = 0
        
        switch self.viewMode! {
        case .ByList:
            initialSelection = 0
        case .ByGrid2x2:
            initialSelection = 1
        case .ByGrid3x3:
            initialSelection = 2
        default:
            break
        }
        
        let doneBlock = { (picker: ActionSheetStringPicker?, selectedIndex: NSInteger, selectedValue: AnyObject?) -> Void in
            
            switch selectedIndex {
            case 0:
                self.viewMode = .ByList
                self.showTableView()
            case 1:
                self.viewMode = .ByGrid2x2
                self.showGridView()
            case 2:
                self.viewMode = .ByGrid3x3
                self.showGridView()
            default:
                break
            }
            
            self.loadData()
        }
        
        ActionSheetStringPicker.showPickerWithTitle("View As",
            rows: viewOptions,
            initialSelection: initialSelection,
            doneBlock: doneBlock,
            cancelBlock: nil,
            origin: view)
    }
    
    func sortButtonTapped() {
        var sortOptions:[String]?
        var initialSelection = 0
        
        sortOptions = [CardSortMode.ByName.description, CardSortMode.ByColor.description, CardSortMode.ByType.description, CardSortMode.ByRarity.description, CardSortMode.ByPrice.description]
        
        switch self.sortMode! {
        case .ByName:
            initialSelection = 0
        case .ByColor:
            initialSelection = 1
        case .ByType:
            initialSelection = 2
        case .ByRarity:
            initialSelection = 3
        case .ByPrice:
            initialSelection = 4
        default:
            break
        }
        
        let doneBlock = { (picker: ActionSheetStringPicker?, selectedIndex: NSInteger, selectedValue: AnyObject?) -> Void in
            
            switch selectedIndex {
            case 0:
                self.sortMode = .ByName
                self.sectionName = "sectionNameInitial"
            case 1:
                self.sortMode = .ByColor
                self.sectionName = "sectionColor"
            case 2:
                self.sortMode = .ByType
                self.sectionName = "sectionType"
            case 3:
                self.sortMode = .ByRarity
                self.sectionName = "rarity.name"
            case 4:
                self.sortMode = .ByPrice
                self.sectionName = nil
            default:
                break
            }
            
            self.loadData()
            self.tblSets!.reloadData()
        }
        
        ActionSheetStringPicker.showPickerWithTitle("Sort By",
            rows: sortOptions,
            initialSelection: initialSelection,
            doneBlock: doneBlock,
            cancelBlock: nil,
            origin: view)
    }
    
    func loadData() {
        switch sortMode! {
        case .ByName:
            self.sorters = [NSSortDescriptor(key: "sectionNameInitial", ascending: true),
                            NSSortDescriptor(key: "name", ascending: true)]
        case .ByColor:
            self.sorters = [NSSortDescriptor(key: "sectionColor", ascending: true),
                            NSSortDescriptor(key: "name", ascending: true)]
            
        case .ByType:
            self.sorters = [NSSortDescriptor(key: "sectionType", ascending: true),
                            NSSortDescriptor(key: "name", ascending: true)]
            
        case .ByRarity:
            self.sorters = [NSSortDescriptor(key: "rarity.name", ascending: true),
                            NSSortDescriptor(key: "name", ascending: true)]
            
        case .ByPrice:
            self.sorters = [NSSortDescriptor(key: "tcgPlayerMidPrice", ascending: false),
                            NSSortDescriptor(key: "name", ascending: true)]
        default:
            break
        }
        
        var nsfrc = Database.sharedInstance().search(nil, withPredicate:self.predicate, withSortDescriptors: self.sorters, withSectionName:self.sectionName)
        self.fetchedResultsController = nsfrc
        self.fetchedResultsController.delegate = self
        self.doSearch()
    }
    
    func doSearch() {
        var error:NSError?
        
        if (!fetchedResultsController.performFetch(&error)) {
            println("Unresolved error \(error), \(error?.userInfo)");
        }
        
        sections = [String: [AnyObject]]()
        sectionIndexTitles = [String]()
        
        for sectionInfo in fetchedResultsController.sections as [NSFetchedResultsSectionInfo]! {
            if self.sortMode != .ByPrice {
                let name = sectionInfo.name
                
                if (name != nil) {
                    let cards = sectionInfo.objects
                    let index = advance(name!.startIndex, 1)
                    var indexTitle = name!.substringToIndex(index)
                    
                    if name == "Blue" {
                        indexTitle = "U"
                    }
                    
                    sections!.updateValue(cards, forKey: name!)
                    self.sectionIndexTitles!.append(indexTitle)
                }
            }
        }
        
        if tblSets != nil {
            tblSets!.reloadData()
        }
        
        if (colSets != nil) {
            colSets!.reloadData()
        }
    }
    
    func showTableView() {
        let y = viewLoadedOnce ? 0 : UIApplication.sharedApplication().statusBarFrame.size.height + self.navigationController!.navigationBar.frame.size.height
        let height = view.frame.size.height - y
        var frame = CGRect(x:0, y:y, width:view.frame.width, height:height)
        
        tblSets = UITableView(frame: frame, style: UITableViewStyle.Plain)
        tblSets!.delegate = self
        tblSets!.dataSource = self
        tblSets!.registerNib(UINib(nibName: "SearchResultsTableViewCell", bundle: nil), forCellReuseIdentifier: kSearchResultsIdentifier)

        if colSets != nil {
            colSets!.removeFromSuperview()
        }
        view.addSubview(tblSets!)
    }
    
    func showGridView() {
        let y = viewLoadedOnce ? 0 : UIApplication.sharedApplication().statusBarFrame.size.height + self.navigationController!.navigationBar.frame.size.height
        let height = view.frame.size.height - y
        let divisor:CGFloat = viewMode == CardViewMode.ByGrid2x2 ? 2 : 3
        var frame = CGRect(x:0, y:y, width:view.frame.width, height:height)
        
        
        let layout = CSStickyHeaderFlowLayout()
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.headerReferenceSize = CGSize(width:view.frame.width, height: 22)
        layout.itemSize = CGSize(width: frame.width/divisor, height: frame.height/divisor)
        
        colSets = UICollectionView(frame: frame, collectionViewLayout: layout)
        colSets!.dataSource = self
        colSets!.delegate = self
        colSets!.registerClass(CardListCollectionViewCell.self, forCellWithReuseIdentifier: "Card")
        colSets!.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier:"Header")
        colSets!.backgroundColor = UIColor.lightGrayColor()
        
        if tblSets != nil {
            tblSets!.removeFromSuperview()
        }
        view.addSubview(colSets!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // UITableViewDataSource
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(SEARCH_RESULTS_CELL_HEIGHT)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfos = fetchedResultsController.sections as [NSFetchedResultsSectionInfo]?
        let sectionInfo = sectionInfos![section]
        return sectionInfo.numberOfObjects
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let sectionInfos = fetchedResultsController.sections as [NSFetchedResultsSectionInfo]?
        return sectionInfos!.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (self.sortMode == CardSortMode.ByPrice) {
            return nil
            
        } else {
            let sectionInfos = fetchedResultsController.sections as [NSFetchedResultsSectionInfo]
            let sectionInfo = sectionInfos[section]
            let cardsString = sectionInfo.numberOfObjects > 1 ? "cards" : "card"
            let name = sectionInfo.name
            return "\(name!) (\(sectionInfo.numberOfObjects) \(cardsString))"
        }
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return sectionIndexTitles
    }
    
    func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        var section = -1
        
        let keys = Array(sections!.keys).sorted(<)
        
        for (i, value) in enumerate(keys) {
            if (value == "Blue" && title == "U") {
                section = i
                break
                
            } else {
                if value.hasPrefix(title) {
                    section = i
                    break
                }
            }
        }
        
        return section
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let card = fetchedResultsController.objectAtIndexPath(indexPath) as DTCard
        var cell = tableView.dequeueReusableCellWithIdentifier(kSearchResultsIdentifier) as SearchResultsTableViewCell?

        if cell == nil {
            cell = SearchResultsTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: kSearchResultsIdentifier)
        }
        
        cell!.accessoryType = UITableViewCellAccessoryType.None
        cell!.selectionStyle = UITableViewCellSelectionStyle.None
        cell!.displayCard(card)
        
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let card = fetchedResultsController.objectAtIndexPath(indexPath) as DTCard
        
        let dict = Database.sharedInstance().inAppSettingsForSet(card.set)
        if dict != nil {
            return
        }
        
        let view = CardDetailsViewController()
        view.addButtonVisible = true
        view.fetchedResultsController = fetchedResultsController
        view.card = card
        
        self.navigationController?.pushViewController(view, animated:true)
    }
    
    // UICollectionViewDataSource
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        let sectionInfos = fetchedResultsController.sections as [NSFetchedResultsSectionInfo]?
        return sectionInfos!.count
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfos = fetchedResultsController.sections as [NSFetchedResultsSectionInfo]?
        let sectionInfo = sectionInfos![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let card = fetchedResultsController.objectAtIndexPath(indexPath) as DTCard
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Card", forIndexPath: indexPath) as CardListCollectionViewCell

        cell.displayCard(card)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        var view:UICollectionReusableView?
        
        if kind == UICollectionElementKindSectionHeader {
            if (self.sortMode == CardSortMode.ByPrice) {
                
            } else {
                let sectionInfos = fetchedResultsController.sections as [NSFetchedResultsSectionInfo]
                let sectionInfo = sectionInfos[indexPath.section]
                let cardsString = sectionInfo.numberOfObjects > 1 ? "cards" : "card"
                let name = sectionInfo.name
                let text = "  \(name!) (\(sectionInfo.numberOfObjects) \(cardsString))"
                
                let label = UILabel(frame: CGRect(x:0, y:0, width:self.view.frame.size.width, height:22))
                label.text = text
                label.backgroundColor = UIColor.whiteColor()
                label.font = UIFont.boldSystemFontOfSize(18)
                
                view = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier:"Header", forIndexPath:indexPath) as? UICollectionReusableView
                
                if view == nil {
                    view = UICollectionReusableView(frame: CGRect(x:0, y:0, width:self.view.frame.size.width, height:22))
                }
                view!.addSubview(label)
            }
        }
        
        return view!
    }

    // UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let card = fetchedResultsController.objectAtIndexPath(indexPath) as DTCard
        
        let dict = Database.sharedInstance().inAppSettingsForSet(card.set)
        if dict != nil {
            return
        }
        
        let view = CardDetailsViewController()
        view.addButtonVisible = true
        view.fetchedResultsController = fetchedResultsController
        view.card = card
        
        self.navigationController?.pushViewController(view, animated:true)
    }

    // NSFetchedResultsControllerDelegate
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        //        println("\(__LINE__) \(__PRETTY_FUNCTION__) \(__FUNCTION__)")
        
        let tableView = tblSets;
        var paths = [NSIndexPath]()
        
        switch(type) {
        case NSFetchedResultsChangeType.Insert:
            paths.append(newIndexPath!)
            tblSets!.insertRowsAtIndexPaths(paths, withRowAnimation:UITableViewRowAnimation.Fade)
            
        case NSFetchedResultsChangeType.Delete:
            paths.append(indexPath!)
            tblSets!.deleteRowsAtIndexPaths(paths, withRowAnimation:UITableViewRowAnimation.Fade)
            
        case NSFetchedResultsChangeType.Update:
            let card = fetchedResultsController.objectAtIndexPath(indexPath!) as DTCard
            let cell = tblSets!.cellForRowAtIndexPath(indexPath!) as SearchResultsTableViewCell?
            cell?.displayCard(card)
        case NSFetchedResultsChangeType.Move:
            paths.append(indexPath!)
            tblSets!.deleteRowsAtIndexPaths(paths, withRowAnimation:UITableViewRowAnimation.Fade)
            
            paths = [NSIndexPath]()
            paths.append(newIndexPath!)
            tblSets!.insertRowsAtIndexPaths(paths, withRowAnimation:UITableViewRowAnimation.Fade)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        //        println("\(__LINE__) \(__PRETTY_FUNCTION__) \(__FUNCTION__)")
        
        switch(type) {
        case NSFetchedResultsChangeType.Insert:
            tblSets!.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation:UITableViewRowAnimation.Fade)
        case NSFetchedResultsChangeType.Delete:
            tblSets!.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation:UITableViewRowAnimation.Fade)
        default:
            break;
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tblSets!.beginUpdates()
        //        println("\(__LINE__) \(__PRETTY_FUNCTION__) \(__FUNCTION__)")
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        //        println("\(__LINE__) \(__PRETTY_FUNCTION__) \(__FUNCTION__)")        
        tblSets!.endUpdates()
    }
}
