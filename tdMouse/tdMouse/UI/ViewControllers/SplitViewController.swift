import Cocoa

class SplitViewController: NSSplitViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sidebarVC = SidebarViewController()
        let mainVC = NavigationController()
        
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarVC)
        let mainItem = NSSplitViewItem(viewController: mainVC)
        
        addSplitViewItem(sidebarItem)
        addSplitViewItem(mainItem)
    }
}
