//
//  TableViewController.swift
//  MCUApp
//
//  Created by Lucas Tarasconi on 14/12/2018.
//  Copyright © 2018 Lucas Tarasconi. All rights reserved.
//

import UIKit
import CommonCrypto


class TableViewController: UITableViewController {

    // MARK: - Variables & Constant
    // Data
    var heroes: MarvelHeroes = MarvelHeroes()
    var filteredHeroes: MarvelHeroes = MarvelHeroes()
    var tempHeroes: [MarvelHeroes] = []
    
    // State
    var downloading: Bool = false
    var downloadAccumulation: Int = 0
    
    // UI
    let searchController = UISearchController(searchResultsController: nil)
    
    // Constant configuration
    let PRIVATE_KEY: String = "f653fd68a72a50dc6eb9eb76eeac1feb9f9d3f27"
    let PUBLIC_KEY: String = "9c1667932eae5fe170a0eed765bc228e"
    let TIMESTAMP: String = "1"
    
    @IBOutlet weak var filteredButton: UIBarButtonItem!
    
    // MARK: - View Start
    override func viewDidLoad() {
        super.viewDidLoad()
        
        download(16)
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Marvel heroes"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    // MARK: - Action
    
    @IBAction func filterLovedHeroes(_ sender: Any) {
        if !isShowLoved() {
            filteredButton.title = "All"
            filteredHeroes.heroes = heroes.heroes.filter({( hero  : Hero) -> Bool in
                return hero.loved
            })
            
            tableView.reloadData()
        } else {
            filteredButton.title = "Favorites"
            tableView.reloadData()
        }
    }
    
    func isShowLoved() -> Bool{
        if filteredButton.title == "All" {
            return true
        } else {
            return false
        }
    }
    
    
    func download(_ iteration: Int) {
        for i in 1...iteration {
            let offsetNumber = (heroes.heroes.count / 100) + (i-1)
            let HASH: String = md5(TIMESTAMP +  PRIVATE_KEY + PUBLIC_KEY)
            tempHeroes.append(MarvelHeroes(with: offsetNumber))
            let url = URL(string: "https://gateway.marvel.com:443/v1/public/characters?limit=100&offset=\(100 * offsetNumber)&ts=\(TIMESTAMP)&apikey=\(PUBLIC_KEY)&hash=\(HASH)")!
            getHeroesList(url: url, offset: offsetNumber)
        }
    }
    
    
    // MARK: - Function
    
    // Hasing methods
    func md5(_ string: String) -> String {
        
        let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        var digest = Array<UInt8>(repeating:0, count:Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Init(context)
        CC_MD5_Update(context, string, CC_LONG(string.lengthOfBytes(using: String.Encoding.utf8)))
        CC_MD5_Final(&digest, context)
        context.deallocate()
        var hexString = ""
        for byte in digest {
            hexString += String(format:"%02x", byte)
        }
        
        return hexString
    }
    
    // MARVEL API REST
    func getHeroesList (url: URL, offset: Int = 0) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        print("Donwloading with request : \(url.absoluteString)")
        downloading = true
        let task = session.dataTask(with: url) {
            (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200,
                let data = data else {
                    return
            }
            do {
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any]  else {
                    return
                }
                guard let jsonData = json?["data"] as? [String:Any],
                    let jsonResults = jsonData["results"] as? [[String:Any]] else {
                        return
                }
                do {
                    for hero in jsonResults {
                        do {
                            guard let currentHero = try Hero(json: hero) else {
                                throw SerializationError.missing("Hero")
                            }
                            if offset < self.tempHeroes.count{
                                 self.tempHeroes[offset].addHero(hero: currentHero)
                            }
                        } catch let error {
                            print(error)
                        }
                    }

                }
                let queue = OperationQueue.main
                queue.addOperation {
                    if offset < self.tempHeroes.count{
                        self.tempHeroes[offset].status = Status.add
                    }
                    // Adding only possible value in order
                    var i = 0
                    while i < self.tempHeroes.count && self.tempHeroes[i].status != Status.empty {
                        if self.tempHeroes[i].status == Status.add {
                            self.heroes.heroes += self.tempHeroes[i].heroes
                            self.tempHeroes[i].status = Status.done
                        }
                        i+=1
                    }
                    
                    if i == self.tempHeroes.count {
                        self.downloading = false
                        self.tempHeroes = []
                        self.navigationItem.prompt = nil
                    }
                    
                    self.tableView.reloadData()
                }
            }
        }
        task.resume()
    }

    @objc func loveHero(_ sender: UIButton) {
        
        guard let cell = sender.superview?.superview as? UITableViewCell,  let indexPath = tableView.indexPath(for: cell) else {
            return // or fatalError() or whatever
        }
        
        if isFiltering() || isShowLoved() {
            if filteredHeroes.heroes[indexPath.row].loved {
                filteredHeroes.heroes[indexPath.row].loved = false
            } else {
                filteredHeroes.heroes[indexPath.row].loved = true
            }

        } else {
            if heroes.heroes[indexPath.row].loved {
                heroes.heroes[indexPath.row].loved = false
            } else {
                heroes.heroes[indexPath.row].loved = true
            }
        }
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.title = "Marvel's heroes (\(heroes.heroes.count))"
        if downloading {
            self.navigationItem.prompt = "Downloading..."
        }
        if isFiltering() || isShowLoved() {
            return filteredHeroes.heroes.count
        }
        return heroes.heroes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "heroCell", for: indexPath)
        cell.tag = indexPath.row
        let position = indexPath.row
        let hero: Hero
        if isFiltering() || isShowLoved() {
            hero = filteredHeroes.heroes[position]
        } else {
            hero = heroes.heroes[position]
        }
        
        if hero.fullPathImage == "http://i.annihil.us/u/prod/marvel/i/mg/b/40/image_not_available.jpg" {
            hero.image = UIImage.init(named: "no_image")
        }
        
        
        if let heart = cell.viewWithTag(75) as? UIButton {
            heart.addTarget(self, action: #selector(self.loveHero), for: .touchUpInside)
            if hero.loved {
                heart.titleLabel?.font =  UIFont.systemFont(ofSize: 23)
                heart.setTitle("♥︎", for: .normal)
            } else {
                heart.titleLabel?.font =  UIFont.systemFont(ofSize: 19)
                heart.setTitle("♡", for: .normal)
            }
        }
        if let label = cell.viewWithTag(20) as? UILabel {
            label.text = hero.name
        }
        
        
            if let image = cell.viewWithTag(10) as? UIImageView{
                print("\(hero.name) : Set from standard ")
                if hero.image == nil {
                    image.image = nil
                } else {
                    image.image = hero.image
                }
                
            }
        
        
        
        let queue = OperationQueue()
        let mainQueue = OperationQueue.main
        if hero.image == nil {
            queue.addOperation {
                let imageURL = URL(string: hero.fullPathImage! )!
                let imageData = try! Data(contentsOf: imageURL)
                print("\(hero.name) : Start download")
                hero.image = UIImage(data: imageData)!
                
                mainQueue.addOperation {
                    if let image = cell.viewWithTag(10) as? UIImageView {
                        if (cell.tag == indexPath.row) {
                            print("\(hero.name) : Set from queue ")
                            image.image = hero.image
                            self.downloadAccumulation = 0
                        } else {
                            self.downloadAccumulation += 1
                            print("\(hero.name) : NO MORE IN VIEW \(self.downloadAccumulation)")
                            
                        }
                    }
                }
                
            }
        }
    
           
        
        
        if downloading == false && position >= heroes.heroes.count - 30 {
            let offsetNumber = heroes.heroes.count / 100
            let HASH: String = md5(TIMESTAMP +  PRIVATE_KEY + PUBLIC_KEY)
            let url = URL(string: "https://gateway.marvel.com:443/v1/public/characters?limit=100&offset=\(100 * offsetNumber)&ts=\(TIMESTAMP)&apikey=\(PUBLIC_KEY)&hash=\(HASH)")!
            getHeroesList(url: url)
        }
        
        return cell
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            guard let cell = sender as? UITableViewCell, let detailViewController = segue.destination as? DetailViewController,  let indexPath = tableView.indexPath(for: cell) else {
                return
            }
            if isFiltering() || isShowLoved() {
                detailViewController.hero = filteredHeroes.heroes[indexPath.row]
            } else {
                detailViewController.hero = heroes.heroes[indexPath.row]
            }
        }
        
    }
    
    // MARK: - Search
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredHeroes.heroes = heroes.heroes.filter({( hero  : Hero) -> Bool in
            return hero.name.lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
}

extension TableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}



