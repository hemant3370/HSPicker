//
//  HSPicker.swift
//  HSPicker
//
//  Created by Hemant Singh on 26/05/16.
//  Copyright © 2016 Hemant Singh. All rights reserved.
//

import UIKit
import SwiftyJSON

import ChameleonFramework

class HSEntity: NSObject {
    let name: String
    var section: Int?
    
    init(name: String) {
        self.name = name
        
    }
}


public struct HSSection {
    var entities: [HSEntity] = []
    
    mutating func addEntity(entity: HSEntity) {
        entities.append(entity)
    }
}

public protocol HSPickerDelegate: class {
    func entityPicker(picker: HSPicker, didSelectEntityWithName name: String)
    func entityPicker(picker: HSPicker, didUnSelectEntityWithName name: String)
}

public class HSPicker: UITableViewController, UINavigationBarDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    var dataSource: [String]! = []
    public var listNameForSocket : String!
    public var selectedItems : [String]?
    public var tag : Int!
    public var selectionLimit : Int!
    private var searchController: UISearchController!
    private var filteredList = [HSEntity]()
    private var unsourtedEntities : [HSEntity] {
        var unsortedEntities = [HSEntity]()
        let data = dataSource
        
        for entity in data! {
            let entity = HSEntity(name: entity)
            unsortedEntities.append(entity)
        }
        
        return unsortedEntities
    }
    
    private var _sections: [HSSection]?
    private var sections: [HSSection] {
        
        if _sections != nil {
            return _sections!
        }
        
        let entities: [HSEntity] = unsourtedEntities.map { entity in
            let entity = HSEntity(name: entity.name)
            entity.section = collation.sectionForObject(entity, collationStringSelector: Selector("name"))
            return entity
        }
        
        // create empty sections
        var sections = [HSSection]()
        for _ in 0..<self.collation.sectionIndexTitles.count {
            sections.append(HSSection())
        }
        
        // put each entity in a section
        for entity in entities {
            sections[entity.section!].addEntity(entity)
        }
        
        // sort each section
        for section in sections {
            var s = section
            s.entities = collation.sortedArrayFromArray(section.entities, collationStringSelector: Selector("name")) as! [HSEntity]
        }
        
        _sections = sections
        
        return _sections!
    }
    private let collation = UILocalizedIndexedCollation.currentCollation()
        as UILocalizedIndexedCollation
    public weak var delegate: HSPickerDelegate?
    public var backImage : UIImage!
    public var didSelectEntityClosure: ((String) -> ())?
    
    convenience public init(completionHandler: ((String) -> ())) {
        self.init()
        self.didSelectEntityClosure = completionHandler
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Light)) as UIVisualEffectView
        visualEffectView.frame = CGRectMake(0, 0, view.bounds.width, view.bounds.height + 30)
        tableView.backgroundColor = .clearColor()
        view.backgroundColor = .clearColor()
//            GradientColor(.LeftToRight, frame: view.frame, colors: [UIColor.flatSkyBlueColor(),UIColor.flatLimeColor()])
    
        if backImage != nil {
            tableView.backgroundView = UIImageView(image: backImage)
        }
        tableView.backgroundView?.addSubview(visualEffectView)
        tableView.separatorStyle = .None
        tableView.reloadData()
        tableView.separatorEffect = UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: .Light))
       self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationController!.navigationBar.topItem!.title = ""
       
    
        
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        for str in self.selectedItems! {
            selectedItems![(selectedItems?.indexOf(str))!] = str.lowercaseString
        }
    }
    func btn_clicked(sender: UIBarButtonItem) {
        // Do something
         self.dismissViewControllerAnimated(true, completion: nil)
    }
   
    
//    func animateTable() {
//        
//        self.tableView.reloadData()
//        
//        let cells = tableView.visibleCells
//        let tableHeight: CGFloat = tableView.bounds.size.height
//        
//        for (index, cell) in cells.enumerate() {
//            cell.transform = CGAffineTransformMakeTranslation(0, tableHeight)
//            UIView.animateWithDuration(1.0, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
//                cell.transform = CGAffineTransformMakeTranslation(0, 0);
//                }, completion: nil)
//        }
//    }
    public override func viewDidAppear(animated: Bool) {
        createSearchBar()
        searchController.searchBar.becomeFirstResponder()
    }
    
    public override func viewWillDisappear(animated: Bool) {
        // Clear the Search bar text
        searchController.active = false
        self.clearAllNotice()
        // Dismiss the search tableview
        searchController.dismissViewControllerAnimated(true) { 
            
        }
        
    }
    // MARK: Methods
    public func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let title : NSMutableAttributedString = NSMutableAttributedString(string: "No matches found.")
        title.addAttribute(NSForegroundColorAttributeName, value: UIColor.flatBlackColor(), range: NSRange.init(location: 0, length: 17))
        
        return title
    }
    
   
    
 
    
    
    
  
    private func createSearchBar() {
//        self.navigationController?.navigationBarHidden = true
            searchController = UISearchController(searchResultsController: nil)
            searchController.searchResultsUpdater = self
            searchController.dimsBackgroundDuringPresentation = false
        
//            tableView.tableHeaderView = searchController.searchBar
            self.navigationItem.titleView = searchController.searchBar
            searchController.searchBar.searchBarStyle = UISearchBarStyle.Prominent
            searchController.searchBar.barTintColor = UIColor.whiteColor()
            searchController.searchBar.tintColor = UIColor.whiteColor()
            searchController.searchBar.backgroundColor = UIColor.clearColor()
        
//        UIColor(hex: 0x0C94C2)
            searchController.searchBar.showsBookmarkButton = false
            searchController.searchBar.showsCancelButton = false
//            searchController.active = true
            searchController.hidesNavigationBarDuringPresentation = false
            if self.navigationController == nil{
            self.tableView.frame = CGRectMake(0, 64, view.frame.size.width, view.frame.size.height - 64)
//            }
        }
        
    }
    
    private func filter(searchText: String) -> [HSEntity] {
        filteredList.removeAll()
        sections.forEach { (section) -> () in
            section.entities.forEach({ (entity) -> () in
                if entity.name.characters.count >= searchText.characters.count {
                let result = entity.name.compare(searchText, options: [.CaseInsensitiveSearch, .DiacriticInsensitiveSearch], range: searchText.startIndex ..< searchText.endIndex)
                if (result == .OrderedSame) {
                    filteredList.append(entity)
                }
               
            }
            })
            }
        
        return  filteredList.count == 0 ? [] : filteredList
    }
}

// MARK: - Table view data source

extension HSPicker {
    
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        if searchController.searchBar.isFirstResponder() {
            return 1
//        }
//        return sections.count
    }
    
    public override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if searchController.searchBar.isFirstResponder() {
//            return filteredList.count
//        }
//        return sections[section].entities.count
          return (dataSource?.count)!
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var tempCell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("UITableViewCell")
        
        if tempCell == nil {
            tempCell = UITableViewCell(style: .Default, reuseIdentifier: "UITableViewCell")
        }
        
        let cell: UITableViewCell! = tempCell
        cell.contentView.alpha = 0.9
        cell.backgroundColor = .clearColor()
    
        
        return cell
    }
    
    public override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let entity : String = dataSource![indexPath.row]
//        if searchController.searchBar.isFirstResponder() {
//            entity = filteredList[indexPath.row]
//        } else {
//            entity = sections[indexPath.section].entities[indexPath.row]
        
//        }
        cell.textLabel?.text = dataSource[indexPath.row].stringByReplacingOccurrencesOfString("_", withString: " ").capitalizedString
        //            .stringByReplacingOccurrencesOfString("skills_", withString: "").stringByReplacingOccurrencesOfString("locations_", withString: "")
        cell.textLabel?.textColor = UIColor.flatGrayColorDark()
        if ((selectedItems?.contains(entity.lowercaseString)) == true) {
            cell.accessoryType = .Checkmark
        }
        else{
            cell.accessoryType = .None
        }
    }
   
    
//    override public func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
//        return collation.sectionIndexTitles
//    }
//    
//    
//    
//    override public func tableView(tableView: UITableView,
//        sectionForSectionIndexTitle title: String,
//        atIndex index: Int)
//        -> Int {
//            return collation.sectionForSectionIndexTitleAtIndex(index)
//    }
}

// MARK: - Table view delegate

extension HSPicker {
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let entity = dataSource![indexPath.row]
//        if searchController.searchBar.isFirstResponder() {
//            entity = filteredList[indexPath.row]
//        } else {
//            entity = sections[indexPath.section].entities[indexPath.row]
//            
//        }
        if selectedItems?.count < selectionLimit || tableView.cellForRowAtIndexPath(indexPath)?.accessoryType == .Checkmark {
      tableView.cellForRowAtIndexPath(indexPath)?.accessoryType =  tableView.cellForRowAtIndexPath(indexPath)?.accessoryType == .Checkmark ? .None : .Checkmark
        if tableView.cellForRowAtIndexPath(indexPath)?.accessoryType == .Checkmark {
            selectedItems?.append(entity)
            delegate?.entityPicker(self, didSelectEntityWithName: entity)
        }
        else {
            selectedItems?.removeAtIndex((selectedItems?.indexOf(entity))!)
            delegate?.entityPicker(self, didUnSelectEntityWithName: entity)
        }
        }
        if selectedItems?.count >= selectionLimit {
            self.view.endEditing(true)
            
        }
//     self.navigationController?.popViewControllerAnimated(true)
    }
}

// MARK: - UISearchDisplayDelegate

extension HSPicker: UISearchResultsUpdating {
    
    public func updateSearchResultsForSearchController(searchController: UISearchController) {
        filter(searchController.searchBar.text!)
        if searchController.searchBar.text!.characters.count > 0 {
            self.pleaseWait()
            WebUtil.sharedInstance().get("/\(listNameForSocket)?query=" + searchController.searchBar.text! , completion: { (result) in
                self.dataSource = []
                
                    print(result["data"].stringValue)
                    for obj : JSON in result["data"].arrayValue{
                        self.dataSource.append(obj.stringValue)
                    }
                    self.clearAllNotice()
                    self.tableView.reloadData()
                
            })

        }

    }
}
