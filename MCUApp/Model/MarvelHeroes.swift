//
//  MarvelHeroes.swift
//  MCUApp
//
//  Created by Lucas Tarasconi on 15/12/2018.
//  Copyright © 2018 Lucas Tarasconi. All rights reserved.
//

import Foundation


class MarvelHeroes {
    var heroes: [Hero] = []
    
    init() {
        self.heroes = []
    }
    
    func storeAllHeroes(json: [[String: Any]]) throws {
        for hero in json {
            do {
                guard let currentHero = try Hero(json: hero) else {
                    throw SerializationError.missing("Hero")
                }
                self.addHero(hero: currentHero)
            } catch let error {
                print(error)
                
            }
        }
    }
    
    func addHero(hero: Hero) {
        heroes.append(hero)
    }
}
