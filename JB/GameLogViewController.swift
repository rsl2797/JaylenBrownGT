//
//  SecondViewController.swift
//  JB
//
//  Created by Raymond Li on 8/18/16.
//  Copyright © 2016 Raymond Li. All rights reserved.
//

import UIKit
class GameLogViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    var games = [Game]()
    var showGames = [Game]()
    var favoriteGames = Set<String>()
    var currentSeason: String = ""
    var headers: [String: Int] = [:]
    
    @IBOutlet weak var navStarButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    var loadingView: UIView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.allowsSelection = false
        
        let nib = UINib(nibName: "GameCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "GameCell")
        
        let window = UIApplication.shared.keyWindow!
        
        var navBarHeight: CGFloat = 40
        var tabBarHeight: CGFloat = 49
        if #available(iOS 11.0, *) {
            navBarHeight += window.safeAreaInsets.top
            tabBarHeight += window.safeAreaInsets.bottom
        }
        loadingView = UIView(frame: CGRect(x: window.frame.origin.x, y: window.frame.origin.y + navBarHeight, width: window.frame.width, height: window.frame.height - navBarHeight - tabBarHeight))
        loadingView.backgroundColor = .white
        
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .gray
        loadingView.addSubview(activityIndicator)
        window.addSubview(loadingView)
        
        activityIndicator.startAnimating()
        
        navStarButton.setImage(UIImage(named: "Star")!, for: .normal)
        navStarButton.tintColor = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1)
        
        if let decoded = UserDefaults.standard.object(forKey: "FavoriteGames") as? Data {
            let favoriteGamesArray = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [String]
            for gameDate in favoriteGamesArray {
                favoriteGames.insert(gameDate)
            }
        }
        
        let currentDate = Date()
        let calendar = Calendar.current
        let curYear = calendar.component(.year, from: currentDate)
        let curMonth = calendar.component(.month, from: currentDate)
        
        if curMonth >= 10 {
            currentSeason = String(curYear) + "-" + String(curYear - 2000 + 1)
        } else {
            currentSeason = String(curYear - 1) + "-" + String(curYear - 2000)
        }
        
        getGameLogJSON()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.activityIndicator.isAnimating {
            self.activityIndicator.stopAnimating()
            self.loadingView.removeFromSuperview()
        }
    }
    
    func getGameLogJSON() {
        let url = URL(string: "https://stats.nba.com/stats/playergamelog?DateFrom=&DateTo=&LeagueID=00&SeasonType=Regular+Season&Season=" + currentSeason + "&PlayerID=1627759")
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30
        sessionConfig.timeoutIntervalForResource = 30
        let session = URLSession(configuration: sessionConfig)
        
        session.dataTask(with: url!, completionHandler: {(data, response, error) in
            if data != nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: Any]
                    let resultSetsTemp: NSArray = json["resultSets"] as! NSArray
                    let resultSets = resultSetsTemp[0] as! [String: Any]
                    let head = resultSets["headers"] as! NSArray
                    let rowSet: NSArray = resultSets["rowSet"] as! NSArray
                    
                    self.fillHeadersDict(head: head)
                    self.turnRowSetIntoGames(rowSet)
                    
                    DispatchQueue.main.async(execute: {
                        self.activityIndicator.stopAnimating()
                        self.loadingView.removeFromSuperview()
                        self.tableView.reloadData()
                    })
                } catch {
                    print("Could not serialize")
                }
            }
        }).resume()
    }
    
    func fillHeadersDict(head: NSArray) {
        for i in 0..<head.count {
            headers[head[i] as! String] = i
        }
    }
    
    func turnRowSetIntoGames(_ rowSet: NSArray) {
        var i: Int = 0
        
        while i < rowSet.count {
            let currentGame: NSArray = rowSet[i] as! NSArray
            
            let gameNumber = rowSet.count - i
            let date = currentGame[headers["GAME_DATE"]!] as! String
            
            let oppo = currentGame[headers["MATCHUP"]!] as! String
            let opponent = String(oppo[oppo.index(oppo.startIndex, offsetBy: 4)...])
            
            let winLoss = currentGame[headers["WL"]!] as! String
            
            let MIN = convertToString(val: currentGame[headers["MIN"]!] as! Double)
            
            let PTS = convertToString(val: currentGame[headers["PTS"]!] as! Double)
            let OREB = convertToString(val: currentGame[headers["OREB"]!] as! Double)
            let DREB = convertToString(val: currentGame[headers["DREB"]!] as! Double)
            let REB = convertToString(val: currentGame[headers["REB"]!] as! Double)
            let AST = convertToString(val: currentGame[headers["AST"]!] as! Double)
            let STL = convertToString(val: currentGame[headers["STL"]!] as! Double)
            let BLK = convertToString(val: currentGame[headers["BLK"]!] as! Double)
            let TOV = convertToString(val: currentGame[headers["TOV"]!] as! Double)
            let PF = convertToString(val: currentGame[headers["PF"]!] as! Double)
            let PLUSMINUS = convertToString(val: currentGame[headers["PLUS_MINUS"]!] as! Double)
            
            let FGM = convertToString(val: currentGame[headers["FGM"]!] as! Double)
            let FGA = convertToString(val: currentGame[headers["FGA"]!] as! Double)
            let FGP = convertToString(val: currentGame[headers["FG_PCT"]!] as! Double * 100)
            
            let FG3M = convertToString(val: currentGame[headers["FG3M"]!] as! Double)
            let FG3A = convertToString(val: currentGame[headers["FG3A"]!] as! Double)
            let FG3P = convertToString(val: currentGame[headers["FG3_PCT"]!] as! Double * 100)
            
            let FTM = convertToString(val: currentGame[headers["FTM"]!] as! Double)
            let FTA = convertToString(val: currentGame[headers["FTA"]!] as! Double)
            let FTP = convertToString(val: currentGame[headers["FT_PCT"]!] as! Double * 100)
            
            let game = Game(date: date, opponent: opponent, gameNumber: gameNumber, winLoss: winLoss, MIN: MIN, PTS: PTS, OREB: OREB, DREB: DREB, REB: REB, AST: AST, STL: STL, BLK: BLK, TOV: TOV, PF: PF, PLUSMINUS: PLUSMINUS, FGM: FGM, FGA: FGA, FGP: FGP, FG3M: FG3M, FG3A: FG3A, FG3P: FG3P, FTM: FTM, FTA: FTA, FTP: FTP)
            self.games.append(game)
            self.showGames.append(game)
            
            i = i + 1
        }
    }
    
    func convertToString(val: Double) -> String {
        let valString = String(val)
        let valArr = valString.components(separatedBy: ".")
        
        guard valArr.count == 2 else {
            return ""
        }
        
        var wholeNumberString = valArr[0]
        var decimalString = String(valArr[1].prefix(3))
        
        if decimalString.count == 3 {
            let lastString = decimalString.last
            let lastInt = Int(String(lastString!))
            
            guard lastInt != nil else {
                return ""
            }
            
            decimalString = String(decimalString.dropLast())
            
            if lastInt! >= 5 {
                let secondLastString = decimalString.last
                var secondLastInt = Int(String(secondLastString!))
                
                if secondLastInt == 9 {
                    secondLastInt = 0
                    var firstLastInt = Int(decimalString.prefix(1))
                    
                    if firstLastInt == 9 {
                        firstLastInt = 0
                        wholeNumberString = String(Int(wholeNumberString)! + 1)
                    } else {
                        firstLastInt = firstLastInt! + 1
                    }
                    
                    decimalString = String(firstLastInt!) + String(secondLastInt!)
                } else {
                    secondLastInt = secondLastInt! + 1
                    decimalString = decimalString.prefix(1) + String(secondLastInt!)
                }
            }
        }
        
        decimalString = removeTrailingZeroes(dec: decimalString)
        
        if decimalString == "" {
            return wholeNumberString
        }
        
        return wholeNumberString + "." + decimalString
    }
    
    
    
    func removeTrailingZeroes(dec: String) -> String {
        var decString = dec
        while decString.last == "0" {
            decString = String(decString.dropLast())
        }
        
        return decString
    }
    
    @objc func handleMarkAsFavorite(sender: FavoriteGameButton) {
        if sender.currentImage == UIImage(named: "Star") {
            sender.setImage(UIImage(named: "FilledStar")!, for: .normal)
            favoriteGames.insert(sender.gameDate)
        } else {
            sender.setImage(UIImage(named: "Star")!, for: .normal)
            favoriteGames.remove(sender.gameDate)
        }
        
        var favoriteGamesArray : [String] = []
        for gameDate in favoriteGames {
            favoriteGamesArray.append(gameDate)
        }
        
        let userDefaults = UserDefaults.standard
        let encodedPT: Data = NSKeyedArchiver.archivedData(withRootObject: favoriteGamesArray)
        userDefaults.set(encodedPT, forKey: "FavoriteGames")
        userDefaults.synchronize()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = self.tableView.dequeueReusableCell(withIdentifier: "GameCell") as? GameCell {
            cell.backgroundColor = .white
            let game = showGames[indexPath.row]
            
            cell.star.gameDate = game.date
            if favoriteGames.contains(game.date) {
                cell.star.setImage(UIImage(named: "FilledStar")!, for: .normal)
            } else {
                cell.star.setImage(UIImage(named: "Star")!, for: .normal)
            }
            cell.star.tintColor = UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1)
            cell.star.addTarget(self, action: #selector(handleMarkAsFavorite), for: .touchUpInside)
            
            cell.gameNumber.adjustsFontSizeToFitWidth = true
            cell.gameDetails.adjustsFontSizeToFitWidth = true
            cell.winLoss.adjustsFontSizeToFitWidth = true
            
            cell.gameNumber.text = "Game " + String(game.gameNumber)
            cell.gameDetails.text = game.date + " " + game.opponent
            cell.winLoss.text = game.winLoss
            
            if game.winLoss == "W" {
                cell.winLoss.textColor = UIColor(red: 38/255, green: 166/255, blue: 91/255, alpha: 1.0)
            } else if game.winLoss == "L" {
                cell.winLoss.textColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1.0)
            }
            
            cell.row1.stat1.text = "MIN"
            cell.row1.stat2.text = "PTS"
            cell.row1.stat3.text = "REB"
            cell.row1.stat4.text = "OREB"
            cell.row1.amount1.text = game.MIN
            cell.row1.amount2.text = game.PTS
            cell.row1.amount3.text = game.REB
            cell.row1.amount4.text = game.OREB
            
            cell.row2.stat1.text = "AST"
            cell.row2.stat2.text = "STL"
            cell.row2.stat3.text = "FG%"
            cell.row2.stat4.text = "FGM | FGA"
            cell.row2.amount1.text = game.AST
            cell.row2.amount2.text = game.STL
            cell.row2.amount3.text = game.FGP + "%"
            cell.row2.amount4.text = game.FGM + " | " + game.FGA
            
            cell.row3.stat1.text = "BLK"
            cell.row3.stat2.text = "TOV"
            cell.row3.stat3.text = "3P%"
            cell.row3.stat4.text = "3PM | 3PA"
            cell.row3.amount1.text = game.BLK
            cell.row3.amount2.text = game.TOV
            cell.row3.amount3.text = game.FG3P + "%"
            cell.row3.amount4.text = game.FG3M + " | " + game.FG3A
            
            cell.row4.stat1.text = "PF"
            cell.row4.stat2.text = "+/-"
            cell.row4.stat3.text = "FT%"
            cell.row4.stat4.text = "FTM | FTA"
            cell.row4.amount1.text = game.PF
            cell.row4.amount2.text = game.PLUSMINUS
            cell.row4.amount3.text = game.FTP + "%"
            cell.row4.amount4.text = game.FTM + " | " + game.FTA
            
            return cell
        } else {
            return GameCell()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if games.count == 0 {
            self.tableView.setEmptyMessage("No games played")
        } else if showGames.count == 0 {
            self.tableView.setEmptyMessage("No games to show")
        } else {
            self.tableView.restore()
        }
        return showGames.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 370.0
    }
    
    @IBAction func gameLogPressed(_ sender: Any) {
        if games.count > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
    
    @IBAction func navStarButtonPressed(_ sender: Any) {
            if navStarButton.imageView?.image == UIImage(named: "FilledStar")! {
                showGames = games
                navStarButton.setImage(UIImage(named: "Star")!, for: .normal)
            } else if navStarButton.imageView?.image == UIImage(named: "Star")!{
                showGames = []
                for game in games {
                    if favoriteGames.contains(game.date) {
                        showGames.append(game)
                    }
                }
                navStarButton.setImage(UIImage(named: "FilledStar")!, for: .normal)
            }
            tableView.reloadData()
    }
    
}

extension UITableView {
    
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center;
        messageLabel.font = UIFont(name: "TrebuchetMS", size: 15)
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel;
        self.separatorStyle = .none;
    }
    
    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
    
}

class Game {
    var date: String
    var opponent: String
    var winLoss: String
    
    var gameNumber: Int
    
    var MIN: String
    
    var PTS: String
    var OREB: String
    var DREB: String //Not used
    var REB: String
    var AST: String
    var STL: String
    var BLK: String
    var TOV: String
    var PF: String
    var PLUSMINUS: String
    
    var FGM: String
    var FGA: String
    var FGP: String
    
    var FG3M: String
    var FG3A: String
    var FG3P: String
    
    var FTM: String
    var FTA: String
    var FTP: String
    
    init(date: String, opponent: String, gameNumber: Int, winLoss: String, MIN: String, PTS: String, OREB: String, DREB: String, REB: String, AST: String, STL: String, BLK: String, TOV: String, PF: String, PLUSMINUS: String, FGM: String, FGA: String, FGP: String, FG3M: String, FG3A: String, FG3P: String, FTM: String, FTA: String, FTP: String) {
        self.date = date
        self.opponent = opponent
        self.gameNumber = gameNumber
        self.winLoss = winLoss
        self.MIN = MIN
        self.PTS = PTS
        self.OREB = OREB
        self.DREB = DREB
        self.REB = REB
        self.AST = AST
        self.STL = STL
        self.BLK = BLK
        self.TOV = TOV
        self.PF = PF
        self.PLUSMINUS = PLUSMINUS
        self.FGM = FGM
        self.FGA = FGA
        self.FGP = FGP
        self.FG3M = FG3M
        self.FG3A = FG3A
        self.FG3P = FG3P
        self.FTM = FTM
        self.FTA = FTA
        self.FTP = FTP
    }
}

class FavoriteGameButton : UIButton {
//    var game = Game(date: "", opponent: "", gameNumber: 0, winLoss: "", MIN: "", PTS: "", OREB: "", DREB: "", REB: "", AST: "", STL: "", BLK: "", TOV: "", PF: "", PLUSMINUS: "", FGM: "", FGA: "", FGP: "", FG3M: "", FG3A: "", FG3P: "", FTM: "", FTA: "", FTP: "")
    var gameDate = ""
}
