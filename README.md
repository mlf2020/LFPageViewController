# LFPageViewController
自定义UIPageViewController

![](https://github.com/mlf2020/LFPageViewController/blob/master/pageVc.gif)

### 使用两种实现方式

`LFPageViewController `: 使用UIScrollView实现，手动管理控制器生命周期

`LFCollectPageViewController`: 使用UICollectView实现, 自动管理控制器生命周期

使用方式

```
//定义标题数组
    var titles = ["头条", "科技", "推荐", "萌宠", "数码", "评测", "杭州", "手机", "电脑&PC", "平板", "娱乐", "笔记本", "台式机", "显示器", "智能家居", "手表", "苹果", "其他"]
    var controllers = [UIViewController]()

    let pageVc = LFPageViewController(withTitles: titles)
    pageVc.delegate = self
    pageVc.dataSource = self
    
    for index in 0..<self.titles.count {
        let normalVc = OneViewController()
        normalVc.set(index: index)
        controllers.append(normalVc)
    }
    
    self.addChildViewController(pageVc)
    view.addSubview(pageVc.view)
    pageVc.didMove(toParentViewController: self)
        
```

实现代理

```
    func numberOfViewControllers(pageViewController: LFPageViewController) -> Int {
        return controllers.count
    }

    
    func pageViewController(pageViewController: LFPageViewController, controllerAtIndex index: Int) -> UIViewController! {
        return controllers[index]
    }

```

