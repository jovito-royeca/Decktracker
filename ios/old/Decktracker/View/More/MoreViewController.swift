//
//  MoreViewController.swift
//  Decktracker
//
//  Created by Jovit Royeca on 10/17/14.
//  Copyright (c) 2014 Jovito Royeca. All rights reserved.
//

import UIKit

class MoreViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ReaderViewControllerDelegate {
    
    var tblMore:UITableView!
    let arrayData = [["Rules": ["Basic Rulebook", "Comprehensive Rules"]],
                     ["": ["Settings"]]]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let height = view.frame.size.height - tabBarController!.tabBar.frame.size.height
        let frame = CGRect(x:0, y:0, width:view.frame.width, height:height)
        tblMore = UITableView(frame: frame, style: UITableViewStyle.Grouped)
        tblMore.delegate = self
        tblMore.dataSource = self
        
        view.addSubview(tblMore)
        self.navigationItem.title = "More"

#if !DEBUG
        // send the screen to Google Analytics
        if let tracker = GAI.sharedInstance().defaultTracker {
            tracker.set(kGAIScreenName, value: "More")
            tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject : AnyObject])
        }
#endif
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let row = arrayData[section]
        let key = Array(row.keys)[0]
        let dict = row[key]!
        return dict.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return arrayData.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        let row = arrayData[section]
        return Array(row.keys)[0]
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell:UITableViewCell?
        
        if let x = tableView.dequeueReusableCellWithIdentifier("DefaultCell") as UITableViewCell! {
            cell = x
        } else  {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "DefaultCell")
            cell!.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        }
        let row = arrayData[indexPath.section]
        let key = Array(row.keys)[0]
        let dict = row[key]!
        let value = dict[indexPath.row]
        
        cell!.textLabel!.text = value
        cell!.imageView!.image = nil
        
        if value == "Card Quiz" {
            cell!.imageView!.image = UIImage(named: "questions.png")
        }
        else if value == "Settings" {
            cell!.imageView!.image = UIImage(named: "settings.png")
        }
        return cell!
    }
    
//    MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let row = arrayData[indexPath.section]
        let key = Array(row.keys)[0]
        let dict = row[key]!
        let value = dict[indexPath.row]
        
        var newView:UIViewController?
        var fullScreen = false
        
        if value == "Basic Rulebook" {
            let pdfs = NSBundle.mainBundle().pathsForResourcesOfType("pdf", inDirectory:"rules")
            let file = pdfs[indexPath.row]
            let document = ReaderDocument.withDocumentFilePath(file, password: nil)
            let readerView = ReaderViewController(readerDocument:document)
            readerView.delegate = self
            newView = readerView
            newView!.hidesBottomBarWhenPushed = true
            navigationController?.setNavigationBarHidden(true, animated:true)
            
        } else if value == "Comprehensive Rules" {
            let compView = ComprehensiveRulesViewController()
            newView = compView
            
        } else if value == "Card Quiz" {
            newView = CardQuizHomeViewController()
            fullScreen = true
            
        } else if value == "Life Counter" {
            
        } else if value == "Settings" {
            newView = SettingsViewController()
        }
        
        if let v = newView {
            if fullScreen {
                self.presentViewController(v, animated: false, completion: nil)
            } else {
                navigationController?.pushViewController(v, animated:true)
            }
        }
    }
    
//    MARK: ReaderViewControllerDelegate
    func dismissReaderViewController(viewController:ReaderViewController)
    {
        navigationController?.popViewControllerAnimated(true);
        navigationController?.setNavigationBarHidden(false, animated:true)
    }
}
