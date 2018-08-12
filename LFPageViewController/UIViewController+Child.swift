//
//  UIViewController+Child.swift
//  LFPageViewController
//
//  Created by mlf on 16/8/23.
//  Copyright © 2016年 mlf. All rights reserved.
//

import UIKit


extension UIViewController{

    func removeFromParent(){
        
        self.willMove(toParentViewController: nil)
        self.removeFromParentViewController()
        self.view.removeFromSuperview()
    }

    func addChildVc(childViewController: UIViewController,toView: UIView,withFrame: CGRect){
        
        if self.childViewControllers.contains(childViewController) == false{
            self.addChildViewController(childViewController)
        }
        
        if toView.subviews.contains(childViewController.view) == false{
            toView.addSubview(childViewController.view)
            childViewController.view.frame = withFrame
        
        }
        
        if self.childViewControllers.contains(childViewController) == false{
            childViewController.didMove(toParentViewController: self)
        }
 
    }

}

var indexKey: String?

extension UIViewController{

    var index: Int {
        get{
            return objc_getAssociatedObject(self, &indexKey) as? Int ?? 0
        }
        set{
            objc_setAssociatedObject(self, &indexKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

}
