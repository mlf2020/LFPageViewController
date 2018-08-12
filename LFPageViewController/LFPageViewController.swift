//
//  LFPageViewController.swift
//  LFPageViewController
//
//  Created by apple on 16/8/21.
//  Copyright © 2016年 mlf. All rights reserved.
//  使用UIScrollView实现

import UIKit


//public
let headerHight: CGFloat = 34
var titleFont = UIFont.systemFont(ofSize: 15)
var titleDefaultColor = UIColor.lightText
var titleSelectedColor = UIColor.purple


@objc
protocol LFPageViewControllerdelegate: class{
    
    @objc optional func pageViewController(pageViewController: LFPageViewController, willTranslateFromVc fromVc: UIViewController, toVc: UIViewController, animated: Bool)
    
    @objc optional func pageViewController(pageViewController: LFPageViewController, didTranslateFromVc fromVc: UIViewController, toVc: UIViewController, animated: Bool)
    
}

@objc
protocol LFPageViewControllerDataSource: class{
    
    func numberOfViewControllers(pageViewController: LFPageViewController) -> Int
    
    func pageViewController(pageViewController: LFPageViewController, controllerAtIndex index: Int) -> UIViewController!
    
}


extension LFPageViewController{
    
    func numberOfViewControllers() -> Int {
        return self.dataSource?.numberOfViewControllers(pageViewController: self) ?? 0
    }
    
    func controller(atIndex index: Int) -> UIViewController! {
        return self.dataSource?.pageViewController(pageViewController: self, controllerAtIndex: index)
    }
}

//滚动的方向
enum LFPageScrollDirction {
    case Left
    case Right
}

class LFPageViewController: UIViewController{
    
    weak var delegate: LFPageViewControllerdelegate?
    weak var dataSource: LFPageViewControllerDataSource?

    //properties
    private(set) var visiableController: UIViewController?
    
    private var titles: [String]?
    private lazy var titleSizes = [CGSize]()
    private weak var header: HeaderScroller!
    private weak var contentScrollerView: UIScrollView!
    private var currentIndex = 0
    private var lastIndex = 0
    //手势滑动的时候可能要去的位置（手指滑动需要）
    private var guessToIndex = -1
    //记录滚动完毕当前的位置（手指滑动需要）
    private var currentOffsetX: CGFloat = 0
    private var isAnimating = false
    
    //需要被移除的控制器
    private var needCleanVc = Set<UIViewController>()
    
    private lazy var memeCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.delegate = self
        cache.countLimit = 3
        return cache
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpSubViews()
    
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.controller(atIndex: self.currentIndex).endAppearanceTransition()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.controller(atIndex: self.currentIndex).beginAppearanceTransition(true, animated: true)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.controller(atIndex: self.currentIndex).beginAppearanceTransition(false, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.controller(atIndex: self.currentIndex).endAppearanceTransition()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { (context) in
            
            self.contentScrollerView.setContentOffset(CGPoint(x:size.width * CGFloat(self.currentIndex), y:0), animated: false)
            self.contentScrollerView.contentSize = CGSize(width:size.width * CGFloat(self.numberOfViewControllers()), height:0)
            
        }, completion: nil)
        
    }

    
    private func setUpSubViews(){
        
        self.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        self.automaticallyAdjustsScrollViewInsets = false
        
        let textModels = self.titles?.map{
           return TextModel($0)
        }
        let header = HeaderScroller(withDatalist: textModels ?? [TextModel](), titleSizes: self.titleSizes )
        header.delegate = self
        self.header = header
        view.addSubview(self.header)
        layout(header: self.header)
        
        let contentScrollerView = UIScrollView()
        contentScrollerView.isPagingEnabled = true
        contentScrollerView.showsHorizontalScrollIndicator = false
        contentScrollerView.backgroundColor = UIColor.red
        contentScrollerView.delegate = self
        self.contentScrollerView = contentScrollerView
        view.addSubview(self.contentScrollerView)
        layout(content: self.contentScrollerView)
        
        self.delegate?.pageViewController?(pageViewController: self, willTranslateFromVc: self.controller(atIndex: 0), toVc: self.controller(atIndex: 0), animated: true)
        addVisiableController(withIndex: 0)
    }
    
    private func layout(header: HeaderScroller){
        
        header.translatesAutoresizingMaskIntoConstraints = false
        let left = NSLayoutConstraint(item: header, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0)
        let top = NSLayoutConstraint(item: header, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0)
        let right = NSLayoutConstraint(item: header, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0)
        let height = NSLayoutConstraint(item: header, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: headerHight)
        view.addConstraints([left,top,height,right])

    }
    
    private func layout(content: UIScrollView){
        
        content.frame = CGRect(x:0, y:headerHight, width:UIScreen.main.bounds.size.width, height:UIScreen.main.bounds.size.height-64-headerHight)
        content.autoresizingMask = [ .flexibleLeftMargin, .flexibleRightMargin,.flexibleWidth]
        
        //旋转的时候会报：the item height must be less than the height of the UICollectionView minus the section insets top and bottom values, minus the content insets top and bottom values.错误信息，itemSize必须小于collectionView的frame，设置相同的尺寸竖屏正常，横屏报这个错误
        
//        content.translatesAutoresizingMaskIntoConstraints = false
//        let left = NSLayoutConstraint(item: content, attribute: .Left, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1.0, constant: 0)
//        let top = NSLayoutConstraint(item: content, attribute: .Top, relatedBy: .Equal, toItem: header, attribute: .Bottom, multiplier: 1.0, constant: 0)
//        let right = NSLayoutConstraint(item: content, attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .Right, multiplier: 1.0, constant: 0)
//        let bottom = NSLayoutConstraint(item: content, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: 0)
//        view.addConstraints([left,top,bottom,right])
        
        let width = UIScreen.main.bounds.size.width
        //contentSize
        content.contentSize = CGSize(width:width * CGFloat(numberOfViewControllers()), height:0)
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.memeCache.removeAllObjects()
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

    private func titleSize(withTitles titles: [String]){
    
        for title in titles {
            var size = (title as NSString).boundingRect(with: CGSize(width:CGFloat(MAXFLOAT), height:CGFloat(MAXFLOAT)),
                                                        options: .usesLineFragmentOrigin,
                                                        attributes: [NSAttributedStringKey.font: titleFont],
                                                                context: nil).size
            size.width += 0.02
            titleSizes.append(size)
        }
    }
    
    
    
    //滚动到具体位置
    func scroll(toIndex index: Int, animated: Bool){

        guard index >= 0 || index < self.numberOfViewControllers() else{
            return
        }
        
        let oldSelectedIndex = self.lastIndex
        self.lastIndex = self.currentIndex
        self.currentIndex = index
        
        if self.contentScrollerView.contentSize.width > 0{
            self.delegate?.pageViewController?(pageViewController: self, willTranslateFromVc: self.controller(atIndex: self.lastIndex), toVc: self.controller(atIndex: index), animated: animated)
            addVisiableController(withIndex: index)
        }
        
        
        //开始动画
        let animationBeginClosure = {[weak self] ()->() in
            //当前的控制器即将显示
            self?.controller(atIndex: self?.currentIndex ?? 0).beginAppearanceTransition(true, animated: animated)
            if self?.lastIndex != self?.currentIndex{
                //上一个页面即将消失
                self?.controller(atIndex: self?.lastIndex ?? 0).beginAppearanceTransition(false, animated: animated)
            }
        }
        //动画进行
        let animationProcessClosure = {[weak self] ()->() in
            //取消动画
            self?.contentScrollerView.setContentOffset(self?.visiableOffset(withIndex: index) ?? CGPoint.zero, animated: false)
        }
        //动画结束
        let animationEndClosure = {[weak self] ()->() in
            guard let strong = self else{
                return
            }
            //当前的控制器显示完毕
            strong.controller(atIndex: strong.currentIndex).endAppearanceTransition()
            if strong.lastIndex != strong.currentIndex{
                //上一个页面消失完毕
                strong.controller(atIndex: strong.lastIndex).endAppearanceTransition()
            }
            
            self?.delegate?.pageViewController?(pageViewController: strong, didTranslateFromVc: strong.controller(atIndex: strong.lastIndex), toVc: strong.controller(atIndex: strong.currentIndex), animated: animated)
            strong.header.selected(atIndex: index, animated: true)
            
            strong.cleanSet()
        }
        
        //即将开始
        animationBeginClosure()
        
        if animated{
            guard self.lastIndex != self.currentIndex else{
                return
            }
            
            //上上次的控制器视图
            let oldSelectView = controller(atIndex: oldSelectedIndex).view
            //上次的控制器视图
            let lastView = controller(atIndex: lastIndex).view
            //当前的控制器视图
            let currentView = controller(atIndex: currentIndex).view
            //滚动的方向
            let direction: LFPageScrollDirction = self.lastIndex > self.currentIndex ? .Left : .Right
            let duration = 0.3
            let containerSize = CGSize(width:UIScreen.main.bounds.size.width, height:self.contentScrollerView.frame.size.height)
            
            
            //添加动画之前移除之前的动画
            self.contentScrollerView.layer.removeAllAnimations()
            oldSelectView?.layer.removeAllAnimations()
            lastView?.layer.removeAllAnimations()
            currentView?.layer.removeAllAnimations()

            
            //两个视图相邻的切换
            let last_startLocation = lastView?.frame.origin ?? .zero
            var current_startLocation = lastView?.frame.origin ?? .zero
            
            switch direction {
            case .Left:
                current_startLocation.x -= UIScreen.main.bounds.size.width
            default:
                current_startLocation.x += UIScreen.main.bounds.size.width
            }
            
            var last_toLocation = lastView?.frame.origin ?? .zero
            switch direction {
            case .Left:
                last_toLocation.x += UIScreen.main.bounds.size.width
            default:
                last_toLocation.x -= UIScreen.main.bounds.size.width
            }
            
            //当前需要显示的位置
            let current_toLocation = lastView?.frame.origin ?? .zero
            
            //归位位置
            let last_endLocation = lastView?.frame.origin ?? .zero
            let current_endLocation = currentView?.frame.origin ?? .zero
            
            
            //两个视图的位置
            lastView?.frame = CGRect(x:last_startLocation.x, y:last_startLocation.y, width:containerSize.width, height:containerSize.height)
            currentView?.frame = CGRect(x:current_startLocation.x, y:current_startLocation.y, width:containerSize.width, height:containerSize.height)
            
//            print("初始位置：lastView.frame: \(lastView.frame) currentView.frame:\(currentView.frame)")

            //动画滚动
            UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseOut, animations: {
                self.isAnimating = true
                lastView?.frame = CGRect(x:last_toLocation.x, y:last_toLocation.y, width:containerSize.width, height:containerSize.height)
                currentView?.frame = CGRect(x:current_toLocation.x, y:current_toLocation.y, width:containerSize.width, height:containerSize.height)

//                print("移动的位置：lastView.frame: \(lastView.frame) currentView.frame:\(currentView.frame)")
                }, completion: { [unowned self](finished) in

                    if finished{
                        //归位
                        lastView?.frame = CGRect(x:last_endLocation.x, y:last_endLocation.y,width:containerSize.width, height:containerSize.height)
                        currentView?.frame = CGRect(x:current_endLocation.x, y:current_endLocation.y, width:containerSize.width, height:containerSize.height)
//                        print("完成的位置：lastView.frame: \(lastView.frame) currentView.frame:\(currentView.frame)")

                    }
                    self.isAnimating = false
                    animationProcessClosure()
                    animationEndClosure()
            })
            
        
        }else{
            
            self.isAnimating = false
            animationProcessClosure()
            animationEndClosure()
        }
        
    }
    
     private func moveBackToOriginPositionIfNeeded(view:UIView?,index:Int){
        if index < 0 || index >= numberOfViewControllers() {
            return
        }
        
        guard let destView = view else { print("moveBackToOriginPositionIfNeeded view nil"); return;}
        
        
        let originPosition = self.calcOffsetWithIndex(index: index,
                                                      width: Float(self.contentScrollerView.frame.size.width),
                                                      maxWidth: Float(self.contentScrollerView.contentSize.width))
        if destView.frame.origin.x != originPosition.x {
            var newFrame = destView.frame
            newFrame.origin = originPosition
            destView.frame = newFrame
        }
    }
    
    private func calcOffsetWithIndex(index:Int,width:Float,maxWidth:Float) -> CGPoint {
        var offsetX = Float(Float(index) * width)
        
        if offsetX < 0 {
            offsetX = 0
        }
        
        if maxWidth > 0.0 &&
            offsetX > maxWidth - width
        {
            offsetX = maxWidth - width
        }
        
        return CGPoint(x:CGFloat(offsetX),y:0)
    }
    
    private func cleanSet(){
        
        for vc in self.needCleanVc {
            vc.removeFromParent()
        }
    
        needCleanVc.removeAll()
    }

    
    
    private func visiableOffset(withIndex index: Int) -> CGPoint{
        var offsetX : CGFloat = 0
        if index < 0{
            offsetX = 0
        }
        
        offsetX = CGFloat(index) * UIScreen.main.bounds.size.width

        if offsetX > self.contentScrollerView.contentSize.width{
            offsetX = self.contentScrollerView.contentSize.width - UIScreen.main.bounds.size.width
        }
    
        return CGPoint(x:offsetX, y:0)
    }
    
    private func visiableFrame(withIndex index: Int) -> CGRect{
        let width = UIScreen.main.bounds.size.width
        return CGRect(x:CGFloat(index) * width, y:0, width:width, height:self.contentScrollerView.frame.size.height)
    }
    
    private func addVisiableController(withIndex index: Int){
        
        guard index >= 0 || index < self.numberOfViewControllers() else{
            return
        }
    
        //从缓存中取出控制器
        var viewController: UIViewController? = self.memeCache.object(forKey: index as AnyObject) as? UIViewController
        if viewController == nil{
            viewController = controller(atIndex: index)
        }
        
        //计算位置
        let childFrame = visiableFrame(withIndex: index)
        //添加控制器
        self.addChildVc(childViewController: viewController!, toView: self.contentScrollerView, withFrame: childFrame)
        //添加进缓存
        self.memeCache.setObject(controller(atIndex: index), forKey: index as AnyObject as AnyObject)
    
    }
    
    //手动管理子控制器的生命周期
    override var shouldAutomaticallyForwardAppearanceMethods: Bool{
        return false
    }

}


extension LFPageViewController: UIScrollViewDelegate,HeaderScrollerDelegate,NSCacheDelegate{

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        var offsetX = scrollView.contentOffset.x
        if scrollView.contentOffset.x < 0{
            offsetX = 0
        }
    
        let oldIndex = currentIndex
        let newIndex = Int(offsetX / UIScreen.main.bounds.size.width)
        currentIndex = newIndex
        
        //归位一些变量
        currentOffsetX = scrollView.contentOffset.x

        self.delegate?.pageViewController?(pageViewController:self, didTranslateFromVc: controller(atIndex: oldIndex), toVc: controller(atIndex: newIndex), animated: true)
        
        self.header.selected(atIndex: currentIndex, animated: true)
        
        self.cleanSet()
        
        guard guessToIndex >= 0 && guessToIndex < numberOfViewControllers() else{return}
        
        if oldIndex == newIndex{
            //位置相同,猜测的控制器视图需要消失，当前的视图重新显示
            controller(atIndex: newIndex).beginAppearanceTransition(true, animated: true)
            controller(atIndex: newIndex).endAppearanceTransition()
            controller(atIndex: guessToIndex).beginAppearanceTransition(false, animated: true)
            controller(atIndex: guessToIndex).endAppearanceTransition()

        }else{
            //old didDisappear
            controller(atIndex: oldIndex).endAppearanceTransition()
            //old didAppear
            controller(atIndex: newIndex).endAppearanceTransition()
        }
        
        guessToIndex = currentIndex

    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        //FIXME: 快速滑动视图会消失
        guard guessToIndex >= 0 && guessToIndex < numberOfViewControllers() else{
            return
        }
        
        guard scrollView.isDragging == true && scrollView === self.contentScrollerView else{
            return
        }
        
        //这里是手指滑动调用
        let offsetX = scrollView.contentOffset.x
        let width = UIScreen.main.bounds.width
        //上一次的位置
        let lastGuessToIndex = self.guessToIndex < 0 ? self.currentIndex : self.guessToIndex
        //判断是向左滑还是向右滑动
        if currentOffsetX < offsetX{
            //左滑
            self.guessToIndex = Int(ceil(offsetX/width))
        }else{
            //右滑
            self.guessToIndex = Int(floor(offsetX/width))
        }

        //用户连续滚动
        guard ((guessToIndex != currentIndex && scrollView.isDecelerating == false) || scrollView.isDecelerating == true) else{
            return
          
        }
        
        
        if lastGuessToIndex != guessToIndex{
            
            if guessToIndex >= 0 && guessToIndex < numberOfViewControllers(){
                //滚动显示下一个视图
                self.delegate?.pageViewController?(pageViewController: self, willTranslateFromVc: controller(atIndex: self.currentIndex), toVc: controller(atIndex: self.guessToIndex), animated: true)
                addVisiableController(withIndex: guessToIndex)
                controller(atIndex: guessToIndex).beginAppearanceTransition(true, animated: true)
            }
            if lastGuessToIndex == self.currentIndex{
                //上一个视图开始消失
                controller(atIndex: lastGuessToIndex).beginAppearanceTransition(false, animated: true)
            }
        
            //在中间页面来回快速切换的时候
            if lastGuessToIndex != self.currentIndex &&  lastGuessToIndex >= 0 && lastGuessToIndex < numberOfViewControllers(){
                controller(atIndex: lastGuessToIndex).beginAppearanceTransition(false, animated: true)
                controller(atIndex: lastGuessToIndex).endAppearanceTransition()
            }
        
        }
        
    }
    
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //用户手指还在拖动decelerating = false，用户抬起手指为true
        if scrollView.isDecelerating == false{
            //手指开始滚动，初始化位置
            currentOffsetX = scrollView.contentOffset.x
            guessToIndex = self.currentIndex
        }
    }
    
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
    }
    
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if scrollView.isDecelerating == true {
            let offset = scrollView.contentOffset.x
            let width = scrollView.frame.size.width
            //归位当前的currentOffsetX，用于准确计算将要去的位置
            if velocity.x > 0 {
                //手指快速向左滑动
                self.currentOffsetX = CGFloat(floor(offset/width)) * CGFloat(width)
            } else if velocity.x < 0 {
                //手指快速向右滑动
                self.currentOffsetX = CGFloat(ceil(offset/width)) * CGFloat(width)
            }
        }
    }
    
    func headerScroller(headerScroller: HeaderScroller, didScrollToIndex index: NSIndexPath) {
        
        if !isAnimating{
            headerScroller.scroll(toIndexPath: index)
            scroll(toIndex: index.row, animated: true)
        }
//        self.contentScrollerView.setContentOffset(CGPointMake(UIScreen.main.bounds.size.width * CGFloat(index), 0), animated: true)
    }

    
    
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        
        if let viewController = obj as? UIViewController{
            
            guard self.childViewControllers.contains(viewController) else{
                return
            }
            //左中右三个控制器
            func addToSet(middleIndex index: Int){
                var leftIndex = index - 1
                var rightIndex = index + 1
                if leftIndex < 0{
                    leftIndex = index
                }
                
                if rightIndex > numberOfViewControllers() - 1{
                    rightIndex = index
                }
            
                let leftVc = controller(atIndex: leftIndex)
                let middleVc = controller(atIndex: index)
                let rightVc = controller(atIndex: rightIndex)
                
                if viewController == leftVc || viewController == middleVc || viewController == rightVc{
                    needCleanVc.insert(viewController)
                }
            
            }
            
            
            //区分手指滑动与点击滑动
            if self.contentScrollerView.isTracking == false && self.contentScrollerView.isDragging == false && self.contentScrollerView.isDecelerating == false{
                //点击滑动
                let lastVc = controller(atIndex: self.lastIndex)
                let currentVc = controller(atIndex: self.currentIndex)
                if viewController == lastVc || viewController == currentVc{
                    needCleanVc.insert(viewController)
                }
            }else{
                //手指滑动
                addToSet(middleIndex: self.guessToIndex)
            }
            
            if needCleanVc.count > 0 {return}
            
//            print("第\(viewController.index)个控制器被回收")
            viewController.removeFromParent()
        }
        
    }
}



protocol HeaderScrollerDelegate: class{
    func headerScroller(headerScroller: HeaderScroller,didScrollToIndex indexPath: NSIndexPath)
}

class HeaderScroller: UIView,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UICollectionViewDataSource {
    
    private var datalist: [TextModel]?
    private weak var collectionView: UICollectionView!
    private weak var rightButton: UIButton!
    private var titleSizes: [CGSize]?
    private var previousIndexPath: NSIndexPath?
    private var animated = true
    
    weak var delegate: HeaderScrollerDelegate?
    
    init(withDatalist list: [TextModel],titleSizes: [CGSize]){
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
        collectionView.register(HeaderCell.self, forCellWithReuseIdentifier:"titleHeader")
        collectionView.delegate = self
        collectionView.dataSource = self
        addSubview(collectionView)
        self.collectionView = collectionView
        layout(collectionView: collectionView)
        
        let rightButton = UIButton()
        rightButton.backgroundColor = UIColor.red
        rightButton.setTitle("+", for: .normal)
        rightButton.setTitleColor(titleDefaultColor, for: .normal)
        rightButton.titleLabel?.font = titleFont
        addSubview(rightButton)
        self.rightButton = rightButton
        layout(rightButton: rightButton)
        
        //默认选中第一行)
        self.scroll(toIndexPath: NSIndexPath(item: 0, section: 0))
    }
    
    
    private func layout(collectionView: UICollectionView){
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        let left = NSLayoutConstraint(item: collectionView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0)
        let top = NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
//        let right = NSLayoutConstraint(item: collectionView, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1.0, constant: -headerHight)
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
        scroll(toIndexPath: NSIndexPath(item: index, section: 0))
    }
    
    
    func scroll(toIndexPath indexPath: NSIndexPath){
    
        guard previousIndexPath != indexPath else{
            return
        }
        
        if let previousIndexPath = previousIndexPath{
            let previousTextModel = self.datalist?[previousIndexPath.row]
            let previousCell = collectionView.cellForItem(at: previousIndexPath as IndexPath) as? HeaderCell
            previousTextModel?.selected = false
            previousCell?.canHighlight = false
        }
        
        let currentTextModel = self.datalist?[indexPath.row]
        let currentCell = collectionView.cellForItem(at: indexPath as IndexPath) as? HeaderCell
        
        if (currentTextModel?.selected ?? false){
            currentTextModel?.selected = false
            currentCell?.canHighlight = false
            
        }else{
            currentTextModel?.selected = true
            currentCell?.canHighlight = true
        }
        
        //滚动到相应的位置
        collectionView.scrollToItem(at: indexPath as IndexPath, at: .centeredHorizontally, animated: animated)
        
        previousIndexPath = indexPath
    }
    
    
    
    //MARK:UICollectionViewDelegate....
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.datalist?.count ?? 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "titleHeader", for: indexPath) as! HeaderCell
        let text = self.datalist?[indexPath.row]
        cell.canHighlight = text?.selected ?? false
        cell.set(text: text)
        return cell
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //通知代理滚动到相应的位置
        self.delegate?.headerScroller(headerScroller: self, didScrollToIndex: indexPath as NSIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard indexPath.row < (self.titleSizes?.count)! else{
            return CGSize(width:30, height:20)
        }
        
        let size = self.titleSizes?[indexPath.row]
        return CGSize(width:size?.width ?? 0, height:headerHight)
    }
    
}


class TextModel {
    let text: String
    var selected: Bool
    
    init(_ text: String,selected: Bool = false){
        self.text = text
        self.selected = selected
    }
}

class HeaderCell: UICollectionViewCell {
    
    var titleLabel: UILabel!
    
    var canHighlight: Bool = false{
        willSet{
            if newValue{
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.titleLabel.textColor = titleSelectedColor
                    self.titleLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    }, completion: nil)
                
            }else{
                
                UIView.animate(withDuration: 0.5, animations: {
                    self.titleLabel.textColor = titleDefaultColor
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
        titleLabel.font = titleFont
        titleLabel.textColor = titleDefaultColor
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
    
    func set(text textModel: TextModel?){
        titleLabel.text = textModel?.text
    }
    
    

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}




