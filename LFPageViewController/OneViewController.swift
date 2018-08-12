//
//  OneViewController.swift
//  LFPageViewController
//
//  Created by apple on 16/8/21.
//  Copyright © 2016年 mlf. All rights reserved.
//

import UIKit

class OneViewController: UIViewController {
    
    var label = UILabel()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: (180 + (20 * CGFloat(index))) / 255, green: (180 + (20 * CGFloat(index))) / 255, blue: (180 + (20 * CGFloat(index))) / 255, alpha: 1.0)
        self.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        self.automaticallyAdjustsScrollViewInsets = false
        label.textColor = UIColor.darkText
        label.font = UIFont.systemFont(ofSize: 20)
        label.frame = view.bounds
        label.textAlignment = .center
        view.addSubview(label)
        self.label.text = "这里是第\(self.index)个控制器"
    }
    
    /*
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("\n----------第\(self.index)个控制器viewWillAppear")
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        print("\n----------第\(self.index)个控制器viewDidAppear")
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        print("\n----------第\(self.index)个控制器viewWillDisappear")
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        print("\n----------第\(self.index)个控制器viewDidDisappear")
    }
    
 
    
    deinit{
        print("\n----------第\(self.index)个控制器deinit deinit deinit")
    }
 
 */
    
    func set(index aIndex: Int){
        self.index = aIndex
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
