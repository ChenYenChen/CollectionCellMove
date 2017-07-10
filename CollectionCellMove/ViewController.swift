//
//  ViewController.swift
//  CollectionCellMove
//
//  Created by Ray on 2017/6/9.
//  Copyright © 2017年 Ray. All rights reserved.
//

import UIKit

class moveCell: UICollectionViewCell {
    
    @IBOutlet weak var textLable: UILabel!
    @IBOutlet weak var colseBtn: UIButton!
    
    
}

class ViewController: UIViewController {

    @IBOutlet weak var moveCollection: RMCollection!
    
    var list: [String] = ["+"]
    var items: Int = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for i in 0..<30 {
            self.list.insert("\(i)", at: 0)
        }
        
        self.moveCollection.delegate = self
        self.moveCollection.dataSource = self
        self.moveCollection.rmDataSource = self
        self.moveCollection.rmDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.list.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! moveCell
        
        if indexPath.row == self.list.count - 1 {
            self.moveCollection.stopMove.removeAll()
            self.moveCollection.stopMove.append(indexPath)
        }
        cell.textLable.text = self.list[indexPath.row]
        cell.colseBtn.tag = indexPath.row
        cell.colseBtn.addTarget(self, action: #selector(deleteCell(_:)), for: .touchUpInside)
        cell.colseBtn.isHidden = indexPath.row == self.list.count - 1 ? true : false
        
        return cell
    }
    func deleteCell(_ sender: UIButton) {
        self.list.remove(at: sender.tag)
        self.moveCollection.reloadData()
    }
}
extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 5)
    }
}
extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row == self.list.count - 1 else {
            return
        }
        self.list.insert("\(items)", at: 0)
        items = items + 1
        collectionView.reloadData()
    }
}

extension ViewController: RMCollectionDataSource {
    func RMCollectionMove(_ collectionView: RMCollection, section: Int) -> NSMutableArray {
        let tmp = NSMutableArray()
        for data in self.list {
            tmp.add(data)
        }
        return tmp
    }
}
extension ViewController: RMCollectionDelegate {
    func RMCollection(_ collectionView: RMCollection, section: Int, newArray: NSMutableArray) {
        self.list = newArray as! [String]
    }
}
