//
//  RMCollection.swift
//  CollectionCellMove
//
//  Created by Ray on 2017/6/9.
//  Copyright © 2017年 Ray. All rights reserved.
//

import UIKit

protocol RMCollectionDataSource: UICollectionViewDataSource {
    /// 回傳數據 移動Cell時進行修改重排
    func RMCollectionMove(_ collectionView: RMCollection, section: Int) -> NSMutableArray
}

protocol RMCollectionDelegate: UICollectionViewDelegate {
    func RMCollection(_ collectionView: RMCollection, section: Int, newArray: NSMutableArray)
}

class RMCollection: UICollectionView {
    
    var rmDataSource: RMCollectionDataSource?
    var rmDelegate: RMCollectionDelegate?
    var stopMove: [IndexPath] = []
    
    /// 手指位置
    private var fingerLocaltion: CGPoint = CGPoint()
    /// 被選中Cell的新位置
    private var newLocatedIndex: IndexPath?
    /// 被選中Cell的舊位置
    private var oldLocatedIndex: IndexPath?
    /// 被選中Cell的開始位置
    private var beginLocatedIndex: IndexPath?
    /// 被選中的Cell的截圖
    private var screenshot: UIView?
    /// cell被拖到邊緣後 collectionview自動向上或向下滾動
    private var autoScrollTimer: CADisplayLink?
    /// 自動滾動方向
    private var autoScrollDirection: SnapshotMeetsEdge = .SnapshotMeetsEdgeTop
    
    enum SnapshotMeetsEdge {
        case SnapshotMeetsEdgeTop
        case SnapshotMeetsEdgeBottom
    }
    
    /// 增加長按手勢
    private func addLongTouch() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture(_:)))
        self.addGestureRecognizer(longPress)
    }
    
    @objc private func longPressGesture(_ sender: UILongPressGestureRecognizer) {
        
        self.fingerLocaltion = sender.location(in: self)
        
        if let index = self.indexPathForItem(at: self.fingerLocaltion), let begin = self.beginLocatedIndex, index.section == begin.section {
            self.newLocatedIndex = index
        }
        
        switch sender.state {
        case .began:
            guard let index = self.indexPathForItem(at: self.fingerLocaltion) else {
                break
            }
            guard !self.stopMove.contains(index) else {
                return
            }
            self.oldLocatedIndex = index
            self.beginLocatedIndex = index
            self.cellSelected(at: index)
            break
        case .changed:
            guard let shot = self.screenshot else {
                break
            }
            var center = shot.center
            center.y = self.fingerLocaltion.y
            center.x = self.fingerLocaltion.x
            self.screenshot?.center = center
            
            guard let newSection = self.newLocatedIndex, let oldSection = self.oldLocatedIndex, newSection.section == oldSection.section else {
                break
            }
            
            guard !self.stopMove.contains(newSection) else {
                return
            }
            
            if self.checkScreenshotMeetEdge() {
                self.creatAutoScrollTimer()
            } else {
                self.stopAutoScrollTimer()
            }
            
            guard let new = self.newLocatedIndex, let old = self.oldLocatedIndex, new != old else {
                break
            }
            self.cellRelocatedToNewIndexPath(new)
            break
        default:
            self.stopAutoScrollTimer()
            self.didEndDraging()
            break
        }
    }
    
    /// cell 被選中時 截圖並隱藏原始cell
    private func cellSelected(at index: IndexPath) {
        guard let cell = self.cellForItem(at: index) else {
            return
        }
        
        let shot = self.customScreenshot(cell)
        self.addSubview(shot)
        self.screenshot = shot
        cell.isHidden = true
        var center = shot.center
        center.y = self.fingerLocaltion.y
        
        UIView.animate(withDuration: 0.3) { 
            self.screenshot?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.screenshot?.alpha = 0.9
            self.screenshot?.center = center
        }
    }
    /// 截圖
    private func customScreenshot(_ view: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let shot = UIImageView(image: image)
        shot.center = view.center
        shot.layer.masksToBounds = true
        shot.layer.cornerRadius = 5
        shot.layer.shadowOffset = CGSize(width: -5, height: 0)
        shot.layer.shadowRadius = 5
        shot.layer.shadowOpacity = 0.4
        
        return shot
    }
    
    /// 建立計時器
    private func creatAutoScrollTimer() {
        if self.autoScrollTimer == nil {
            self.autoScrollTimer = CADisplayLink(target: self, selector: #selector(startAutoScroll))
        }
    }
    /// 開始滾動
    @objc private func startAutoScroll() {
        
        guard let moveCell = self.screenshot else {
            return
        }
        
        if self.autoScrollDirection == .SnapshotMeetsEdgeTop {
            if self.contentOffset.y > 0 {
                let point = CGPoint(x: 0, y: self.contentOffset.y - 4)
                self.setContentOffset(point, animated: false)
                moveCell.center = CGPoint(x: moveCell.center.x, y: moveCell.center.y - 4)
            }
        } else {
            if self.contentOffset.y + self.bounds.height < self.contentSize.height {
                let point = CGPoint(x: 0, y: self.contentOffset.y + 4)
                self.setContentOffset(point, animated: false)
                moveCell.center = CGPoint(x: moveCell.center.x, y: moveCell.center.y + 4)
            }
        }
        
        self.oldLocatedIndex = self.indexPathForItem(at: moveCell.center)
        
        guard let new = self.newLocatedIndex, let old = self.oldLocatedIndex, new != old else {
            return
        }
        self.cellRelocatedToNewIndexPath(new)
        
    }
    
    ///
    private func cellRelocatedToNewIndexPath(_ index: IndexPath) {
        guard let old = self.oldLocatedIndex else {
            return
        }
        self.moveItem(at: old, to: index)
        self.oldLocatedIndex = index
    }
    /// 檢查是否到達邊緣
    private func checkScreenshotMeetEdge() -> Bool {
        guard let shot = self.screenshot else {
            return false
        }
        let minY = shot.frame.minY
        let maxY = shot.frame.maxY
        if minY < self.contentOffset.y {
            self.autoScrollDirection = .SnapshotMeetsEdgeTop
            return true
        }
        
        if maxY > self.bounds.height + self.contentOffset.y {
            self.autoScrollDirection = .SnapshotMeetsEdgeBottom
            return true
        }
        
        return false
    }
    
    /// 更新數據
    private func updateDataSource() {
        guard let begin = self.beginLocatedIndex, let new = self.newLocatedIndex  else {
            return
        }
        guard var temp = self.rmDataSource?.RMCollectionMove(self, section: begin.section) else {
            return
        }
        temp = self.moveArray(temp, formIndex: begin.row, toIndex: new.row)
        
        self.rmDelegate?.RMCollection(self, section: begin.section, newArray: temp)
    }
    /// 移動數據
    private func moveArray(_ array: NSMutableArray, formIndex: Int, toIndex: Int) -> NSMutableArray {
        if formIndex < toIndex {
            for i in formIndex..<toIndex {
                array.exchangeObject(at: i, withObjectAt: i + 1)
            }
        } else {
            for i in (toIndex + 1)...formIndex {
                array.exchangeObject(at: i, withObjectAt: i - 1)
            }
        }
        return array
    }
    
    /// 停止計時器
    private func stopAutoScrollTimer() {
        self.autoScrollTimer?.invalidate()
        self.autoScrollTimer = nil
    }
    
    /// 拖曳結束 顯示cell 並移除截圖
    private func didEndDraging() {
        guard let index = self.oldLocatedIndex else {
            return
        }
        let cell = self.cellForItem(at: index)
        cell?.isHidden = false
        cell?.alpha = 0
        
        guard let center = cell?.center else {
            return
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            
            self.screenshot?.center = center
            self.screenshot?.alpha = 0
            self.screenshot?.transform = CGAffineTransform.identity
            cell?.alpha = 1
            
        }) { (finished) in
            self.updateDataSource()
            cell?.isHidden = false
            self.screenshot?.removeFromSuperview()
            self.screenshot = nil
            self.beginLocatedIndex = nil
            self.newLocatedIndex = nil
            self.oldLocatedIndex = nil
        }
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        
        self.addLongTouch()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.addLongTouch()
    }
}
