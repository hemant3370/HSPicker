//
//  HSPicker.swift
//  HSPicker
//
//  Created by Hemant Singh on 26/05/16.
//  Copyright © 2016 Hemant Singh. All rights reserved.
//

import UIKit

class HSEntity: NSObject {
    let name: String
    var section: Int?
    
    init(name: String) {
        self.name = name
        
    }
}

struct HSSection {
    var entities: [HSEntity] = []
    
    mutating func addEntity(entity: HSEntity) {
        entities.append(entity)
    }
}

public protocol HSPickerDelegate: class {
    func entityPicker(picker: HSPicker, didSelectEntityWithName name: String)
}

public class HSPicker: UITableViewController {
    
    public var dataSource: [String]?
    
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
    public var didSelectEntityClosure: ((String) -> ())?
    
    convenience public init(completionHandler: ((String) -> ())) {
        self.init()
        self.didSelectEntityClosure = completionHandler
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        createSearchBar()
        tableView.reloadData()
    }
    
    // MARK: Methods
    
    private func createSearchBar() {
        if self.tableView.tableHeaderView == nil {
            searchController = UISearchController(searchResultsController: nil)
            searchController.searchResultsUpdater = self
            searchController.dimsBackgroundDuringPresentation = false
            tableView.tableHeaderView = searchController.searchBar
            searchController.searchBar.searchBarStyle = UISearchBarStyle.Prominent
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
        if searchController.searchBar.isFirstResponder() {
            return 1
        }
        return sections.count
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.searchBar.isFirstResponder() {
            return filteredList.count
        }
        return sections[section].entities.count
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var tempCell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("UITableViewCell")
        
        if tempCell == nil {
            tempCell = UITableViewCell(style: .Default, reuseIdentifier: "UITableViewCell")
        }
        
        let cell: UITableViewCell! = tempCell
        
        let entity: HSEntity!
        if searchController.searchBar.isFirstResponder() {
            entity = filteredList[indexPath.row]
        } else {
            entity = sections[indexPath.section].entities[indexPath.row]
            
        }
        cell.textLabel?.text = entity.name
        
        return cell
    }
    
    override public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !sections[section].entities.isEmpty {
            if searchController.searchBar.isFirstResponder() {
                return searchController.searchBar.text
            }
            return self.collation.sectionTitles[section] as String
        }
        
        return ""
    }
    
    override public func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return collation.sectionIndexTitles
    }
    
    override public func tableView(tableView: UITableView,
        sectionForSectionIndexTitle title: String,
        atIndex index: Int)
        -> Int {
            return collation.sectionForSectionIndexTitleAtIndex(index)
    }
}

// MARK: - Table view delegate

extension HSPicker {
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let entity: HSEntity!
        if searchController.searchBar.isFirstResponder() {
            entity = filteredList[indexPath.row]
        } else {
            entity = sections[indexPath.section].entities[indexPath.row]
            
        }

        delegate?.entityPicker(self, didSelectEntityWithName: entity.name)
        didSelectEntityClosure?(entity.name)
    }
}

// MARK: - UISearchDisplayDelegate

extension HSPicker: UISearchResultsUpdating {
    
    public func updateSearchResultsForSearchController(searchController: UISearchController) {
        filter(searchController.searchBar.text!)
        tableView.reloadData()
    }
}
