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
    var heroes: MarvelHeroes = MarvelHeroes()
    var filteredHeroes: MarvelHeroes = MarvelHeroes()
    
    var downloading: Bool = false
    let searchController = UISearchController(searchResultsController: nil)
    
    let PRIVATE_KEY: String = "f653fd68a72a50dc6eb9eb76eeac1feb9f9d3f27"
    let PUBLIC_KEY: String = "9c1667932eae5fe170a0eed765bc228e"
    let TIMESTAMP: String = "1"
    
    
    //MARK: - Outlet
    @IBOutlet weak var downloadButton: UIBarButtonItem!
    
    // MARK: - View Start
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Connexion informations
        let HASH: String = md5(TIMESTAMP +  PRIVATE_KEY + PUBLIC_KEY)
        let url = URL(string: "https://gateway.marvel.com:443/v1/public/characters?limit=100&ts=\(TIMESTAMP)&apikey=\(PUBLIC_KEY)&hash=\(HASH)")!
        
        // Initialization
        getHeroesList(url: url)
        
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search marvel heroes"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        if downloading {
            downloadButton.isEnabled = !downloading
        } else {
            downloadButton.isEnabled = downloading
        }
 
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    // MARK: - Action
    
    
    @IBAction func forceDownload(_ sender: Any) {
        for _ in 1...10 {
            if downloading == false  {
                let offsetNumber = heroes.heroes.count / 100
                let HASH: String = md5(TIMESTAMP +  PRIVATE_KEY + PUBLIC_KEY)
                let url = URL(string: "https://gateway.marvel.com:443/v1/public/characters?limit=100&offset=\(100 * offsetNumber)&ts=\(TIMESTAMP)&apikey=\(PUBLIC_KEY)&hash=\(HASH)")!
                getHeroesList(url: url)
            }
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
    func getHeroesList (url: URL) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        print("Donwloading with request : \(url.absoluteString)")
        downloading = true
        downloadButton.isEnabled = false
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
                            self.heroes.addHero(hero: currentHero)
                            let queue = OperationQueue.main
                            queue.addOperation {
                                self.tableView.reloadData()
                            }
                        } catch let error {
                            print(error)
                        }
                    }

                }
                let queue = OperationQueue.main
                queue.addOperation {
                    self.tableView.reloadData()
                    self.downloading = false
                    self.downloadButton.isEnabled = true
                }
            }
        }
        
        task.resume()

    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.title = "Marvel's heroes (\(heroes.heroes.count))"
        if isFiltering() {
            return filteredHeroes.heroes.count
        }
        return heroes.heroes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "heroCell", for: indexPath)
        let position = indexPath.row
        let hero: Hero
        if isFiltering() {
            hero = filteredHeroes.heroes[position]
        } else {
            hero = heroes.heroes[position]
        }
        
        if let label = cell.viewWithTag(20) as? UILabel {
            label.text = hero.name
        }
        if let image = cell.viewWithTag(10) as? UIImageView{
            image.image = hero.image
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
            if isFiltering() {
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


