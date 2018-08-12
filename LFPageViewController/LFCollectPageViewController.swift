//
//  LFCollectPageViewController.swift
//  LFCollectPageViewController
//
//  Created by apple on 16/8/21.
//  Copyright © 2016年 mlf. All rights reserved.
//  使用UICollectionView 实现

import UIKit


//public
let c_headerHight: CGFloat = 34
var c_titleFont = UIFont.systemFont(ofSize: 15)
var c_titleDefaultColor = UIColor.lightText
var c_titleSelectedColor = UIColor.purple


class LFCollectPageViewController: UIViewController{
    
    //properties
    private(set) var viewControllers: [UIViewController]?
    
    private var titles: [String]?
    private lazy var titleSizes = [CGSize]()
    private weak var header: CHeaderScroller!
    private weak var contentCollectionView: UICollectionView!
    private var currentIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpSubViews()
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            
            self.contentCollectionView.collectionViewLayout.invalidateLayout()
            self.contentCollectionView.setContentOffset(CGPoint(x: size.width * CGFloat(self.currentIndex), y: 0), animated: false)
            
        }, completion: nil)
    }
    
    
    private func setUpSubViews(){
        
        self.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        self.automaticallyAdjustsScrollViewInsets = false
        
        let textModels = self.titles?.map{
            return CTextModel($0)
        }
        let header = CHeaderScroller(withDatalist: textModels ?? [CTextModel](), titleSizes: self.titleSizes )
        header.delegate = self
        self.header = header
        view.addSubview(self.header)
        layout(header: self.header)
        
        let contentCollectionView = UICollectionView(frame: .zero, collectionViewLayout: ContentFlowLayout())
        contentCollectionView.isPagingEnabled = true
        contentCollectionView.showsHorizontalScrollIndicator = false
        contentCollectionView.register(ContentCell.self, forCellWithReuseIdentifier: "contentCell")
        contentCollectionView.backgroundColor = UIColor.clear
        contentCollectionView.delegate = self
        contentCollectionView.dataSource = self
        self.contentCollectionView = contentCollectionView
        view.addSubview(self.contentCollectionView)
        layout(content: self.contentCollectionView)
    }
    
    private func layout(header: CHeaderScroller){
        
        header.translatesAutoresizingMaskIntoConstraints = false
        let left = NSLayoutConstraint(item: header, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0)
        let top = NSLayoutConstraint(item: header, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0)
        let right = NSLayoutConstraint(item: header, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0)
        let height = NSLayoutConstraint(item: header, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: c_headerHight)
        view.addConstraints([left,top,height,right])
        
    }
    
    private func layout(content: UICollectionView){
        
        content.frame = CGRect(x: 0, y: c_headerHight, width: UIScreen.main.bounds.size.width,height:  UIScreen.main.bounds.size.height-64-c_headerHight)
        content.autoresizingMask = [ .flexibleLeftMargin, .flexibleRightMargin,.flexibleWidth]
        
        //旋转的时候会报：the item height must be less than the height of the UICollectionView minus the section insets top and bottom values, minus the content insets top and bottom values.错误信息，itemSize必须小于collectionView的frame，设置相同的尺寸竖屏正常，横屏报这个错误
        
        //        content.translatesAutoresizingMaskIntoConstraints = false
        //        let left = NSLayoutConstraint(item: content, attribute: .Left, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1.0, constant: 0)
        //        let top = NSLayoutConstraint(item: content, attribute: .Top, relatedBy: .Equal, toItem: header, attribute: .Bottom, multiplier: 1.0, constant: 0)
        //        let right = NSLayoutConstraint(item: content, attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .Right, multiplier: 1.0, constant: 0)
        //        let bottom = NSLayoutConstraint(item: content, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: 0)
        //        view.addConstraints([left,top,bottom,right])
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(self.contentCollectionView.frame)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //public function
    init(withTitles titles: [String]){
        super.init(nibName: nil, bundle: nil)
        self.titles = titles
        //计算title的size
        titleSize(withTitles: titles)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    
    func set(viewControllers controllers: [UIViewController]?){
        self.viewControllers = controllers
        
        for viewController in self.viewControllers ?? [UIViewController]() {
            self.addChildViewController(viewController)
            viewController.didMove(toParentViewController: self)
        }
    }
    
    private func titleSize(withTitles titles: [String]){
        
        for title in titles {
            
            var size = (title as NSString).boundingRect(with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: c_titleFont], context: nil).size
            size.width += 0.02
            titleSizes.append(size)
        }
    }
}


extension LFCollectPageViewController: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,CHeaderScrollerDelegate{


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.titles?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let ContentCell = collectionView.dequeueReusableCell(withReuseIdentifier: "contentCell", for: indexPath)
        
        if indexPath.row < (self.viewControllers?.count)!{
            if let viewController = self.viewControllers?[indexPath.row]{
                
                viewController.view.backgroundColor = UIColor(red: (180+CGFloat(indexPath.row * 10))/255.0, green: (180+CGFloat(indexPath.row * 10))/255.0, blue: (180+CGFloat(indexPath.row * 10))/255.0, alpha: 1.0)
                print("\n\n-----------\(viewController.isViewLoaded)")
                //                if viewController.parentViewController == nil{
                //没有加载过那么加入
                
                ContentCell.addSubview(viewController.view)
                viewController.view.frame = ContentCell.bounds
                viewController.view.autoresizingMask =  [ .flexibleLeftMargin, .flexibleRightMargin, .flexibleWidth]
                //                }
            }
            
        }
        
        return ContentCell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.contentCollectionView.bounds.size
    }
    
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        currentIndex =  Int(offsetX / scrollView.frame.size.width)
        self.header.selected(atIndex: currentIndex, animated: true)
        //        print("scrollViewDidEndDecelerating :\(currentIndex)")
    }
    
    
    
    
    func headerScroller(headerScroller: CHeaderScroller, didScrollToIndex index: Int) {
        self.contentCollectionView.setContentOffset(CGPoint(x: UIScreen.main.bounds.size.width * CGFloat(index), y: 0), animated: true)
    }

    
}

class ContentCell: UICollectionViewCell {
    
    
    
}



protocol CHeaderScrollerDelegate: class{
    func headerScroller(headerScroller: CHeaderScroller,didScrollToIndex index: Int)
}

class CHeaderScroller: UIView,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UICollectionViewDataSource {
    
    private var datalist: [CTextModel]?
    private weak var collectionView: UICollectionView!
    private weak var rightButton: UIButton!
    private var titleSizes: [CGSize]?
    private var previousIndexPath: IndexPath?
    private var animated = true
    
    weak var delegate: CHeaderScrollerDelegate?
    
    init(withDatalist list: [CTextModel],titleSizes: [CGSize]){
        super.init(frame: .zero)
        self.datalist = list
        self.titleSizes = titleSizes
        setup()
    }
    
    
    private func setup(){
        
        self.backgroundColor = UIColor.white
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 15
        flowLayout.scrollDirection = .horizontal
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 15, 0, 15)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.alwaysBounceHorizontal = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.lightGray
        collectionView.register(CHeaderCell.self, forCellWithReuseIdentifier: "titleHeader")
        collectionView.delegate = self
        collectionView.dataSource = self
        addSubview(collectionView)
        self.collectionView = collectionView
        layout(collectionView: collectionView)
        
        let rightButton = UIButton()
        rightButton.backgroundColor = UIColor.red
        rightButton.setTitle("+", for: .normal)
        rightButton.setTitleColor(c_titleDefaultColor, for: .normal)
        rightButton.titleLabel?.font = c_titleFont
        addSubview(rightButton)
        self.rightButton = rightButton
        layout(rightButton: rightButton)
        
        //默认选中第一行)
        self.collectionView(collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))
    }
    
    
    private func layout(collectionView: UICollectionView){
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        let left = NSLayoutConstraint(item: collectionView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0)
        let top = NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
        //        let right = NSLayoutConstraint(item: collectionView, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1.0, constant: -c_headerHight)
        self.addConstraints([left,top,bottom])
    }
    
    private func layout(rightButton: UIButton){
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        let left = NSLayoutConstraint(item: rightButton, attribute: .left, relatedBy: .equal, toItem: collectionView, attribute: .right, multiplier: 1.0, constant: 0)
        let top = NSLayoutConstraint(item: rightButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: rightButton, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
        let right = NSLayoutConstraint(item: rightButton, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0)
        self.addConstraints([left,top,bottom,right])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: public func
    func selected(atIndex index: Int,animated: Bool){
        self.animated = animated
        scroll(toIndexPath: IndexPath(item: index, section: 0))
    }
    
    
    private func scroll(toIndexPath indexPath: IndexPath){
        
        guard previousIndexPath != indexPath else{
            return
        }
        
        if let previousIndexPath = previousIndexPath{
            let previousTextModel = self.datalist?[previousIndexPath.row]
            let previousCell = collectionView.cellForItem(at: previousIndexPath) as? HeaderCell
            previousTextModel?.selected = false
            previousCell?.canHighlight = false
        }
        
        let currentTextModel = self.datalist?[indexPath.row]
        let currentCell = collectionView.cellForItem(at: indexPath) as? HeaderCell
        
        if (currentTextModel?.selected ?? false){
            currentTextModel?.selected = false
            currentCell?.canHighlight = false
            
        }else{
            currentTextModel?.selected = true
            currentCell?.canHighlight = true
        }
        
        //滚动到相应的位置
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
        
        previousIndexPath = indexPath
    }
    
    
    
    //MARK:UICollectionViewDelegate....
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.datalist?.count ?? 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "titleHeader", for: indexPath) as! CHeaderCell
        let text = self.datalist?[indexPath.row]
        cell.canHighlight = text?.selected ?? false
        cell.set(text: text)
        return cell
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        scroll(toIndexPath: indexPath)
        //通知代理滚动到相应的位置
        self.delegate?.headerScroller(headerScroller: self, didScrollToIndex: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard indexPath.row < (self.titleSizes?.count)! else{
            return CGSize(width: 30, height: 20)
        }
        
        let size = self.titleSizes?[indexPath.row]
        print(indexPath.row,size?.width ?? 0)
        return CGSize(width: size?.width ?? 0, height: c_headerHight)
    }
    
}


class CTextModel {
    let text: String
    var selected: Bool
    
    init(_ text: String,selected: Bool = false){
        self.text = text
        self.selected = selected
    }
}

class CHeaderCell: UICollectionViewCell {
    
    var titleLabel: UILabel!
    
    var canHighlight: Bool = false{
        willSet{
            if newValue{
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.titleLabel.textColor = c_titleSelectedColor
                    self.titleLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }, completion: nil)
                
            }else{
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.titleLabel.textColor = c_titleDefaultColor
                    self.titleLabel.transform = .identity
                }, completion: nil)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup(){
        //        self.contentView.backgroundColor = UIColor.whiteColor()
        let titleLabel = UILabel()
        titleLabel.font = c_titleFont
        titleLabel.textColor = c_titleDefaultColor
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        self.titleLabel = titleLabel
        layout(titleLabel: titleLabel)
    }
    
    private func layout(titleLabel: UILabel){
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        let left = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1.0, constant: 0)
        let top = NSLayoutConstraint(item: titleLabel, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: titleLabel, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0)
        let right = NSLayoutConstraint(item: titleLabel, attribute: .right, relatedBy: .equal, toItem: contentView, attribute: .right, multiplier: 1.0, constant: 0)
        self.addConstraints([left,top,bottom,right])
    }
    
    func set(text textModel: CTextModel?){
        titleLabel.text = textModel?.text
    }
    
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}




class ContentFlowLayout: UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        
        self.minimumLineSpacing = 0
        //        self.itemSize = CGSizeMake(UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height-64-c_headerHight)
        self.scrollDirection = .horizontal
        
    }
}



