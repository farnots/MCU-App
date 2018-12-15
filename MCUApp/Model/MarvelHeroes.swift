//
//  MarvelHeroes.swift
//  MCUApp
//
//  Created by Lucas Tarasconi on 15/12/2018.
//  Copyright © 2018 Lucas Tarasconi. All rights reserved.
//

import Foundation

enum Status {
    case done
    case add
    case empty
}

class MarvelHeroes {
    public var status: Status = Status.empty
    var offset: Int = 0
    var heroes: [Hero] = []
    
    init() {
        self.heroes = []
    }
    
    init(with offset: Int) {
        self.heroes = []
        self.offset = 0
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
