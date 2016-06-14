//
//  Player.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import Foundation




class Player {
    let index: Int
    var name: String?
    var pieces: [Piece]
    
    init(name: String?, index: Int, pieces: [Piece]) {
        self.name = name
        self.index = index
        self.pieces = pieces
    }
}