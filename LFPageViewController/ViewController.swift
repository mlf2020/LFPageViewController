//
//  ViewController.swift
//  LFPageViewController
//
//  Created by apple on 16/8/21.
//  Copyright © 2016年 mlf. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var titles = ["头条", "科技", "推荐", "萌宠", "数码", "评测", "杭州", "手机", "电脑&PC", "平板", "娱乐", "笔记本", "台式机", "显示器", "智能家居", "手表", "苹果", "其他"]
    var controllers = [UIViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        self.automaticallyAdjustsScrollViewInsets = false
        let pageVc = LFPageViewController(withTitles: titles)
        pageVc.delegate = self
        pageVc.dataSource = self
        
        
        
        for index in 0..<self.titles.count {
            
//            if index % 2 == 0{
//                let tableViewVc = TwoTableViewController(style: .Plain)
//                tableViewVc.index = index
//                controllers.append(tableViewVc)
//            }else{
            
                let normalVc = OneViewController()
                normalVc.set(index: index)
                controllers.append(normalVc)
//            }
        }
        
        
        self.addChildViewController(pageVc)
        view.addSubview(pageVc.view)
        pageVc.didMove(toParentViewController: self)
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}



extension ViewController: LFPageViewControllerdelegate, LFPageViewControllerDataSource{


    func numberOfViewControllers(pageViewController: LFPageViewController) -> Int {
        return controllers.count
    }

    
    func pageViewController(pageViewController: LFPageViewController, controllerAtIndex index: Int) -> UIViewController! {
        return controllers[index]
    }


}






