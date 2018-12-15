//
//  DetailViewController.swift
//  MCUApp
//
//  Created by Lucas Tarasconi on 15/12/2018.
//  Copyright © 2018 Lucas Tarasconi. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    var hero: Hero?
    
    @IBOutlet weak var imageHero: UIImageView!
    @IBOutlet weak var nameHero: UILabel!
    @IBOutlet weak var descriptionHero: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title? = hero?.name ?? "No name"
        imageHero.image = hero!.image
        nameHero.text = hero?.name
        descriptionHero.text = hero?.description
        // Do any additional setup after loading the view.
    }
    
}
