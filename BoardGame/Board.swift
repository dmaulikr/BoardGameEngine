//
//  Board.swift
//  Chess
//
//  Created by Roselle Milvich on 5/15/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

import UIKit


struct Position: Hashable {
    var row: Int
    var column: Int
    var hashValue: Int {
        return row.hashValue ^ column.hashValue
    }
    
    static func positionFromTranslation(_ translation: Translation, fromPosition: Position, direction: Direction) -> Position {
        let row: Int
        let column: Int
        switch direction {
        case .bottom:
            row = fromPosition.row + translation.row
            column = fromPosition.column - translation.column
        case .top:
            row = fromPosition.row - translation.row
            column = fromPosition.column + translation.column
        case .left:
            row = fromPosition.row - translation.column
            column = fromPosition.column - translation.row
        case .right:
            row = fromPosition.row + translation.column
            column = fromPosition.column + translation.row
        }
        return Position(row: row, column: column)
    }
    
    static func calculateTranslation(fromPosition:Position, toPosition: Position, direction: Direction) -> Translation {
        let row: Int
        let column: Int
        switch direction {
        case .bottom:
            row = toPosition.row - fromPosition.row
            column = fromPosition.column - toPosition.column
        case .top:
            row = fromPosition.row - toPosition.row
            column = toPosition.column - fromPosition.column
        case .left:
            row = fromPosition.column - toPosition.column
            column = fromPosition.row - toPosition.row
        case .right:
            row = toPosition.column - fromPosition.column
            column = toPosition.row - fromPosition.row
        }
        return Translation(row: row, column: column)
    }
    
    static func betweenLinearExclusive(position1: Position, position2: Position) -> [Position] {
        var positions = [Position]()
        var lower = 0
        var higher = 0
        if position1.row == position2.row {
            if position1.column + 1 < position2.column {
                lower = position1.column + 1
                higher = position2.column - 1
            } else if position2.column + 1 < position1.column {
                lower = position2.column + 1
                higher = position1.column - 1
            }
            if lower != higher {
                for i in lower...higher {
                    positions.append(Position(row: position1.row, column: i))
                }
            }
        } else if position1.column == position2.column {
            if position1.row + 1 < position2.row {
                lower = position1.row + 1
                higher = position2.row - 1
            } else if position2.row + 1 < position1.row {
                lower = position2.row + 1
                higher = position1.row - 1
            }
            if lower != higher {
                for i in lower...higher {
                    positions.append(Position(row: i, column: position1.column))
                }
            }
        }
        return positions
    }
}

func ==(lhs: Position, rhs: Position) -> Bool {
    return lhs.row == rhs.row && lhs.column == rhs.column
}

typealias Translation = Position


/// Board: Grid of rows and columns that may include skipped cells.

struct Board {
    var numRows: Int
    var numColumns: Int
    var numCells: Int {get {return numRows * numColumns}}
    var skipCells: Set<Int>?
    var indexesNotSkipped: Set<Int> {
        get {
            return Set(0..<numCells).subtracting(skipCells ?? [])
        }
    }
    
    func index(position: Position) -> Int {
        return position.column + position.row * numColumns
    }
    
    func position(index: Int) -> Position {
        if numColumns > 0  {
            return Position(row: index / numColumns, column: index % numColumns)
        } else {
            return Position(row: 0, column: 0)
        }
    }
    
    func isACellAndIsNotSkipped(index: Int) -> Bool {
        return indexesNotSkipped.contains(index)
    }
    
    func numberedDescription(position: Position) -> String {
        guard let column = UnicodeScalar(position.column + 65) else { return "" }
        let row = numRows - position.row
        return "\(column)\(row)"
    }
    
    func columnFromFromNonSkippedEdge(row: Int, offset: Int, fromTheLeft: Bool) -> Int? {
        guard offset == 0 || (fromTheLeft == (offset >= 0)) else { return nil }
        var column: Int? = nil
        var index = fromTheLeft ? 0 : self.numColumns - 1
        let limitingCase = fromTheLeft ? index < self.numColumns - 1 : index >= 0
        let crimenter = fromTheLeft ? 1 : -1
        while column == nil && limitingCase {
            if isACellAndIsNotSkipped(index: self.index(position: Position(row: row, column: index))) {
                column = index
            }
            index += crimenter
        }
        if column != nil {
            let offsetColumn = column! + offset
            column = isACellAndIsNotSkipped(index: self.index(position: Position(row: row, column: offsetColumn))) ? offsetColumn : nil
        }
        return column
    }
    
    func rowFromNonSkippedEdge(column: Int, offset: Int, fromTheTop: Bool) -> Int? {
        guard offset == 0 || (fromTheTop == (offset >= 0)) else { return nil }
        var row: Int? = nil
        var index = fromTheTop ? 0 : self.numRows - 1
        let limitingCase = fromTheTop ? index < self.numRows - 1 : index >= 0
        let crimenter = fromTheTop ? 1 : -1
        while row == nil && limitingCase {
            if isACellAndIsNotSkipped(index: self.index(position: Position(row: index, column: column))) {
                row = index
            }
            index += crimenter
        }
        if row != nil {
            let offsetRow = row! + offset
            row = isACellAndIsNotSkipped(index: self.index(position: Position(row: offsetRow, column: column))) ? offsetRow : nil
        }
        return row
    }
    
    func nonSkippedEdges() -> [Position] {
        var edges = Set([Position]())
        for row in 0..<numRows {
            if let column = columnFromFromNonSkippedEdge(row: row, offset: 0, fromTheLeft: true) {
                let position = Position(row: row, column: column)
                if isACellAndIsNotSkipped(index: index(position: position)) {
                    edges.insert(position)
                }
            }
            
            if let column = columnFromFromNonSkippedEdge(row: row, offset: 0, fromTheLeft: false) {
                let position = Position(row: row, column: column)
                if isACellAndIsNotSkipped(index: index(position: position)) {
                    edges.insert(position)
                }
            }
        }
        
        for column in 0..<numColumns {
            if let row = rowFromNonSkippedEdge(column: column, offset: 0, fromTheTop: true) {
                let position = Position(row: row, column: column)
                if isACellAndIsNotSkipped(index: index(position: position)) {
                    edges.insert(position)
                }
            }
            
            if let row = rowFromNonSkippedEdge(column: column, offset: 0, fromTheTop: false) {
                let position = Position(row: row, column: column)
                if isACellAndIsNotSkipped(index: index(position: position)) {
                    edges.insert(position)
                }
            }
        }
        return Array(edges)
    }
    
    func boarderedCells(position: Position) -> [Position] {
        let possiblePositions = [
            Position(row: position.row, column: position.column + 1),
            Position(row: position.row, column: position.column - 1),
            Position(row: position.row + 1, column: position.column + 1),
            Position(row: position.row - 1, column: position.column + 1),
            Position(row: position.row + 1, column: position.column - 1),
            Position(row: position.row - 1, column: position.column - 1),
            Position(row: position.row + 1, column: position.column),
            Position(row: position.row - 1, column: position.column)
        ]
        return possiblePositions.filter({ (pos: Position) -> Bool in
            isACellAndIsNotSkipped(index: index(position: pos))
        })
    }
    
    
    /// for making an octoganol board
    static func octoganalSkips(across: Int) -> [Int] {
        var skips = [Int]()
        let aThird = across/3
        var edges = aThird
        var middle = across - (edges * 2)
        var index = 0
        
        // top part of the octogon
        while edges > 0 {
            // beginning edge skips
            for _ in 0..<edges {
                skips.append(index)
                index += 1
            }
            // leave the middle
            index += middle
            
            // end edge skips
            for _ in 0..<edges {
                skips.append(index)
                index += 1
            }
            edges -= 1
            middle += 2
        }
        
        // middle part of the octagon
        index += across * (across - (aThird * 2))
        
        // bottom part of the octagon
        edges = 1
        middle = across - 2
        while edges <= aThird {
            // beginning edge skips
            for _ in 0..<edges {
                skips.append(index)
                index += 1
            }
            // leave the middle
            index += middle
            
            // end edge skips
            for _ in 0..<edges {
                skips.append(index)
                index += 1
            }
            edges += 1
            middle -= 2
        }
        return skips
    }
}


/// makes a checkered view from a Board. checkered will offset images by 1 on the next row. skipped cells are hidden but still there for layout

class Cell: UIView {
    let position: Position
    var positionDescription: String = ""
    var occupierDescription: String? = nil
    
    init(position: Position) {
        self.position = position
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isAccessibilityElement: Bool { get { return true } set { }}
    override var accessibilityLabel: String? {
        get {
            let occupierString = occupierDescription != nil ? occupierDescription! + " on " : nil
            return occupierString != nil ? occupierString! + positionDescription : positionDescription
        } set { }
    }
}














