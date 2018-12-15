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

    // MARK: - Variables
    var heroes: MarvelHeroes = MarvelHeroes()
    
    
    // MARK: - View Start
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Connexion informations
        let PRIVATE_KEY: String = "f653fd68a72a50dc6eb9eb76eeac1feb9f9d3f27"
        let PUBLIC_KEY: String = "9c1667932eae5fe170a0eed765bc228e"
        let TIMESTAMP: String = "1"
        let HASH: String = md5(TIMESTAMP +  PRIVATE_KEY + PUBLIC_KEY)
        let url = URL(string: "https://gateway.marvel.com:443/v1/public/characters?ts=\(TIMESTAMP)&apikey=\(PUBLIC_KEY)&hash=\(HASH)")!
        
        // Initialization
        getHeroesList(url: url)
 
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
                     try? self.heroes.storeAllHeroes(json: jsonResults)
                }
                let queue = OperationQueue.main
                queue.addOperation {
                    self.tableView.reloadData()
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
        return heroes.heroes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "heroCell", for: indexPath)
        let position = indexPath.row
        let hero = heroes.heroes[position]
        
        
        if let label = cell.viewWithTag(20) as? UILabel {
            label.text = hero.name
        }
        if let image = cell.viewWithTag(10) as? UIImageView{
            image.image = hero.image
        }
        
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

