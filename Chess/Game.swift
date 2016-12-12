//
//  Game.swift
//  Chess
//
//  Created by Roselle Milvich on 5/16/16.
//  Copyright © 2016 Roselle Tanner. All rights reserved.
//

// TODO:


import UIKit

struct Move {
    let piece: Piece
    let remove: Bool
    let position: Position?
}



protocol GamePresenterProtocol: class {
    func gameMessage(_ string: String, status: GameStatus?)
    func secondaryGameMessage(string: String)
    func showAlert(_ alert: UIViewController)
}

enum GameStatus {
    case gameOver, whoseTurn, illegalMove, `default`
}

typealias Completions = [(() -> Void)]

class GameSnapshot {
    static var shared: GameSnapshot? = nil
    var board: Board
    var players: [Player]
    var selectedPiece: Piece?
    var whoseTurn: Int
    var nextTurn: Int
    var round: Int
    var allPieces: [Piece] {
        get {
            var pieces = [Piece]()
            for player in players {
                pieces += player.pieces
            }
            return pieces
        }
    }
    
    convenience init(game: Game) {
        self.init(board: game.board, players: game.players, selectedPiece: game.selectedPiece, whoseTurn: game.whoseTurn, nextTurn: game.nextTurn, round: game.round)
    }
    
    convenience init(gameSnapshot: GameSnapshot) {
        self.init(board: gameSnapshot.board, players: gameSnapshot.players, selectedPiece: gameSnapshot.selectedPiece, whoseTurn: gameSnapshot.whoseTurn, nextTurn: gameSnapshot.nextTurn, round: gameSnapshot.round)
    }
    
    func pieceForPosition(_ position: Position, snapshot: GameSnapshot?) -> Piece? {
        let pieces = snapshot?.allPieces ?? allPieces
        var pieceFound: Piece?
        for piece in pieces {
            if piece.position == position {
                pieceFound = piece
            }
        }
        return pieceFound
    }
    
    func makeMove(_ move: Move) {
        if let snapshotPiece = self.allPieces.elementPassing({$0.id == move.piece.id && $0.player != nil && $0.player!.id == move.piece.player!.id}) {
            if move.remove {
                for player in self.players {
                    if let index = player.pieces.index(of: snapshotPiece) {
                        player.pieces.remove(at: index)
                    }
                }
            } else if move.position != nil {
                if let snapshotPieceToReplace = pieceForPosition(move.position!, snapshot: self) {
                    if snapshotPieceToReplace.removePieceOccupyingNewPosition == true {
                        for player in self.players {
                            if let index = player.pieces.index(of: snapshotPieceToReplace) {
                                player.pieces.remove(at: index)
                            }
                        }
                    }
                }
                snapshotPiece.position = move.position!
            }
        }
    }
    
    init(board: Board, players: [Player], selectedPiece: Piece?, whoseTurn: Int, nextTurn: Int, round: Int) {
        self.board = board.copy()
        self.players = players.map({$0.copy()})
        self.whoseTurn = whoseTurn
        self.nextTurn = nextTurn
        self.round = round
        self.selectedPiece = self.allPieces.elementPassing({$0.id == selectedPiece?.id})
    }
    
    func copy() -> GameSnapshot {
        return GameSnapshot(board: board.copy(), players: players.map({$0.copy()}), selectedPiece: allPieces.elementPassing({$0.id == selectedPiece?.id}), whoseTurn: whoseTurn, nextTurn: nextTurn, round: round)
    }
}


class Game: PieceViewProtocol {
    var board: Board
    var boardView: BoardView
    var players: [Player]
    var pieceViews: [PieceView] = [PieceView]()
    var selectedPiece: Piece?
    var round = 0
    var firstInRound = 0
    var whoseTurn: Int = 0 {
        didSet {
            if whoseTurn >= players.count {
                whoseTurn = 0
                round += 1
            }
        }
    }
    var nextTurn: Int {
        get {
            var next = whoseTurn + 1
            if next >= players.count {
                next = 0
            }
            return next
        }
    }
    weak var presenterDelegate: GamePresenterProtocol? {
        didSet {
            presenterDelegate?.gameMessage((players[whoseTurn].name ?? "") + " Starts!", status: .whoseTurn)
        }
    }
    var allPieces: [Piece] {
        get {
            var pieces = [Piece]()
            for player in players {
                pieces += player.pieces
            }
            return pieces
        }
    }
    var reusableGameSnapshot: GameSnapshot?
    

    init(gameView: UIView, board: Board, boardView: BoardView, players: [Player]) {
        self.board = board
        self.boardView = boardView
        self.players = players
        self.pieceViews = makePieceViews(players: players)
        
        // boardView layout
        gameView.addSubview(boardView)
        boardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(NSLayoutConstraint.bindTopBottomLeftRight(boardView))
        
        // pieceView layout and observing
        setupLayoutAndObservingForPieceViews(pieceViews: pieceViews)

        // add taps to cells on boardView
        boardView.cells.forEach({ (view: UIView) in
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(Game.cellTapped(_:))))
        })
        
        
    }
    
    /// creates a default board for testing purposes
    convenience init(gameView: UIView) {
        
        // create the board
        let defaultBoard = Board(numRows: 8, numColumns: 5, emptyCells: [0, 4, 20])
        
        // create the boardView
        var images = [UIImage]()
        for i in 1...3 {
            if let image = UIImage(named: "\(i).jpg") {
                images.append(image)
            }
        }
        let defaultBoardView = BoardView(board: defaultBoard, checkered: false, images: images, backgroundColors: nil)
        
        // create the players with pieces
        let isPossibleTranslation: (Translation) -> Bool = {_ in return true}
        let defaultPlayers = [Player(name: "alien", id: 0, forwardDirection: .top, pieces: [Piece(name: "hi", position: Position(row: 0,column: 0), isPossibleTranslation: isPossibleTranslation, isLegalMove: {_ in return (true, nil)})])]
        
        // create pieceView's
        self.init(gameView: gameView, board: defaultBoard, boardView: defaultBoardView, players: defaultPlayers)
    }
    
    deinit {
       print("deinit Game")
    }
    
    func makePieceViews(players: [Player]) -> [PieceView] {
        var pieceViews = [PieceView]()
        for player in players {
            for piece in player.pieces {
                if let pieceView = makePieceView(piece: piece) {
                    pieceViews.append(pieceView)
                }
            }
        }
        return pieceViews
    }
    
    func makePieceView(piece: Piece) -> PieceView? {
        if let player = piece.player {
            let name = piece.name + (player.name ?? "")
            var radians: Double
            switch player.forwardDirection {
            case .top:
                radians = 0
            case .bottom:
                radians = M_PI
            case .left:
                radians = M_PI_2 * -1
            case .right:
                radians = M_PI_2
            }
            if let image = UIImage(named: name) {
                let imageView = PieceView(image: image, pieceTag: piece.id)
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat(radians))
                return imageView
            }
        }

        return nil
    }
    
    func setupLayoutAndObservingForPieceViews(pieceViews: [PieceView]) {
        // pieceView layout and observing
        for pieceView in pieceViews {
            setupLayoutAndObservingForPieceView(pieceView: pieceView)
        }
    }
    
    func setupLayoutAndObservingForPieceView(pieceView: PieceView) {
        if let piece = pieceForPieceView(pieceView) {
            // add delegate
            pieceView.delegate = self
            // add observing
            pieceView.observing = [(piece, "selected"), (piece, "position")]
            
            // pieceView layout
            let indexOfPieceOnBoard = board.index(position: piece.position)
            if let cell = boardView.cells.elementPassing({return indexOfPieceOnBoard == $0.tag}) {
                boardView.addSubview(pieceView)
                pieceView.constrainToCell(cell)
            }
        }
    }
    
    // MARK: Game Logic (that can't be in an extension)
    func checkIfConditionsAreMet(piece: Piece, snapshot: GameSnapshot, legalIfs: [LegalIf]?) -> IsMetAndCompletions {
        if legalIfs == nil {
            return IsMetAndCompletions(isMet: true, completions: nil)
        }
        var isMet = true
        var completions: [(() -> Void)]? =  [(() -> Void)]()
        for legalIf in legalIfs! where isMet == true {
            let isMetAndCompletions = legalIf.condition.checkIfConditionIsMet(piece: piece, translations: legalIf.translations, snapshot: snapshot)
            
            isMet = isMetAndCompletions.isMet
            if let complete = isMetAndCompletions.completions {
                completions! += complete
            }
        }
        return IsMetAndCompletions(isMet: isMet, completions: completions!.count > 0 ? completions : nil)
    }
    
    func checkForGameOver() {
        for player in players {
            if player.pieces.count == 0 {
                presenterDelegate?.gameMessage("Game Over", status: .gameOver)
            }
        }
    }
}


// MARK: Game Logic

extension Game {
    @objc func cellTapped(_ sender: UITapGestureRecognizer) {
        if let view = sender.view {
            let positionTapped = board.position(index: view.tag)
            let pieceTapped = pieceForPosition(positionTapped, snapshot: nil)
            
            // beginning of turn, selecting the piece
            let isBeginningOfTurn = selectedPiece == nil
            if isBeginningOfTurn {
                // get the piece
                if pieceTapped != nil {// cell must be occupied for selection
                    let isPlayersOwnPiece = players[whoseTurn].pieces.contains(pieceTapped!)
                    if isPlayersOwnPiece {
                        pieceTapped!.selected = true
                        selectedPiece = pieceTapped
                    }
                }
            }
                
            // final part of turn, choosing where to go
            else {
                let translation = Position.calculateTranslation(fromPosition: selectedPiece!.position, toPosition: positionTapped, direction: players[whoseTurn].forwardDirection)
                let moveFunction = selectedPiece!.isLegalMove(translation)
                reusableGameSnapshot = GameSnapshot(game: self)
                if moveFunction.isLegal {
                    // check
                    let isMetAndCompletions = checkIfConditionsAreMet(piece: selectedPiece!, snapshot: reusableGameSnapshot!, legalIfs: moveFunction.legalIf)
                    if isMetAndCompletions.isMet {
                        // remove occupying piece if needed     // put in condition: removeOccupying, completions: removeOccupying
                        if selectedPiece!.removePieceOccupyingNewPosition == true && pieceTapped != nil {
                            makeMove(Move(piece: pieceTapped!, remove: true, position: nil))
                        }
                        
                        // move the piece
                        makeMove(Move(piece: selectedPiece!, remove: false, position: positionTapped))
                        
                        // completions
                        if let completions = isMetAndCompletions.completions {
                            for completion in completions {
                                completion()
                            }
                        }
                        
                        // check for gameOver
                        checkForGameOver()
                        whoseTurn += 1
                        presenterDelegate?.gameMessage((players[whoseTurn].name ?? "") + "'s turn", status: .whoseTurn)
                    } else {
                        if let completions = isMetAndCompletions.completions {
                            for completion in completions {
                                completion()
                            }
                        }
                    }
                }
                selectedPiece!.selected = false
                selectedPiece = nil
            }
        }
    }
}

// MARK: Moving Pieces

extension Game {
//    struct Move {
//        let piece: Piece
//        let remove: Bool
//        let position: Position?
//    }
//    
    func makeMove(_ move: Move) {
        if move.remove {
            removePieceAndViewFromGame(piece: move.piece)
        } else if move.position != nil {
            move.piece.position = move.position!
        }
    }
    
    func makeMoves(_ moves: [Move]) {
        for move in moves {
            makeMove(move)
        }
    }
    
//    func makeMoveInSnapshot(_ move: Move, snapshot: GameSnapshot) {
//        if let snapshotPiece = snapshot.allPieces.elementPassing({$0.id == move.piece.id && $0.player != nil && $0.player!.id == move.piece.player!.id}) {
//            if move.remove {
//                for player in snapshot.players {
//                    if let index = player.pieces.index(of: snapshotPiece) {
//                        player.pieces.remove(at: index)
//                    }
//                }
//            } else if move.position != nil {
//                if let snapshotPieceToReplace = pieceForPosition(move.position!, snapshot: snapshot) {
//                    if snapshotPieceToReplace.removePieceOccupyingNewPosition == true {
//                        for player in snapshot.players {
//                            if let index = player.pieces.index(of: snapshotPieceToReplace) {
//                                player.pieces.remove(at: index)
//                            }
//                        }
//                    }
//                }
//                snapshotPiece.position = move.position!
//            }
//        }
//    }
//    
//    func makeMovesInSnapshot(_ moves: [Move], snapshot: GameSnapshot) {
//        for move in moves {
//            makeMoveInSnapshot(move, snapshot: snapshot)
//        }
//    }
    
    func removePieceAndViewFromGame(piece: Piece) {
        for player in players {
            if let index = player.pieces.index(of: piece) {
                if let pieceViewToRemove = pieceViews.elementPassing({$0.tag == piece.id}) {
                    pieceViewToRemove.removeFromSuperview()
                }
                player.pieces.remove(at: index)
            }
        }
    }
    
    func addPieceAndViewToGame(piece: Piece) {
        if let player = piece.player {
            player.pieces.append(piece)
            if let pieceView = makePieceView(piece: piece) {
                setupLayoutAndObservingForPieceView(pieceView: pieceView)
            }
        }
    }
    
    func animateMove(_ pieceView: PieceView, position: Position, duration: TimeInterval) {
        
        // deactivate position constraints
        NSLayoutConstraint.deactivate(pieceView.positionConstraints)
        
        // activate new position constraints matching cell constraints
        let cellIndex = board.index(position: position)
        if let cell = boardView.cells.elementPassing({$0.tag == cellIndex}) {
            let positionX = NSLayoutConstraint(item: pieceView, attribute: .centerX, relatedBy: .equal, toItem: cell, attribute: .centerX, multiplier: 1, constant: 0)
            let positionY = NSLayoutConstraint(item: pieceView, attribute: .centerY, relatedBy: .equal, toItem: cell, attribute: .centerY, multiplier: 1, constant: 0)
            pieceView.positionConstraints = [positionX, positionY]
            NSLayoutConstraint.activate(pieceView.positionConstraints)
        }
        
        // animate the change
        boardView.setNeedsUpdateConstraints()
        UIView.animate(withDuration: duration, animations: {
            self.boardView.layoutIfNeeded()
        })
    }
}


// MARK: Conversions

extension Game {
//    func positionFromTranslation(_ translation: Translation, fromPosition: Position, direction: Direction) -> Position {
//        let row: Int
//        let column: Int
//        switch direction {
//        case .bottom:
//            row = fromPosition.row + translation.row
//            column = fromPosition.column - translation.column
//        case .top:
//            row = fromPosition.row - translation.row
//            column = fromPosition.column + translation.column
//        case .left:
//            row = fromPosition.row - translation.column
//            column = fromPosition.column - translation.row
//        case .right:
//            row = fromPosition.row + translation.column
//            column = fromPosition.column + translation.row
//        }
//        return Position(row: row, column: column)
//    }
//    
//    func calculateTranslation(_ fromPosition:Position, toPosition: Position, direction: Direction) -> Translation {
//        let row: Int
//        let column: Int
//        switch direction {
//        case .bottom:
//            row = toPosition.row - fromPosition.row
//            column = fromPosition.column - toPosition.column
//        case .top:
//            row = fromPosition.row - toPosition.row
//            column = toPosition.column - fromPosition.column
//        case .left:
//            row = fromPosition.column - toPosition.column
//            column = fromPosition.row - toPosition.row
//        case .right:
//            row = toPosition.column - fromPosition.column
//            column = toPosition.row - fromPosition.row
//        }
//        return Translation(row: row, column: column)
//    }
    
    func pieceForPosition(_ position: Position, snapshot: GameSnapshot?) -> Piece? {
        let pieces = snapshot?.allPieces ?? allPieces
        var pieceFound: Piece?
        for piece in pieces {
            if piece.position == position {
                pieceFound = piece
            }
        }
        return pieceFound
    }
    
    func pieceForPieceView(_ pieceView: PieceView) -> Piece? {
        for piece in allPieces {
            if piece.id == pieceView.tag {return piece}
        }
        return nil
    }
    

    

}

