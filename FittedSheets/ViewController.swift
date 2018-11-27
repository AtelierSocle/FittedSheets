//
//  ViewController.swift
//  FittedSheets
//
//  Created by Gordon Tucker on 8/16/18.
//  Copyright © 2018 Gordon Tucker. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismissKeyboard(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    @IBAction func presentSheet1(_ sender: Any) {
        let controller = SheetViewController(controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sheet1"))
        controller.blurBottomSafeArea = false
        controller.topGap = (true, -24.0)//-28 by default
        self.present(controller, animated: false, completion: nil)
    }
    
    @IBAction func presentSheet2(_ sender: Any) {
        
        let controller = SheetViewController(controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sheet2"), sizes: [.halfScreen, .fullScreen, .fixed(250)])
        
        self.present(controller, animated: false, completion: nil)
    }
    
    @IBAction func presentSheetCustom(_ sender: Any) {
        // test tableView
        let controller = SheetViewController(controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sheetTbV"), sizes: [.fullScreen, .fixed(200)])
        controller.adjustForBottomSafeArea = false
        controller.blurBottomSafeArea = false
        self.present(controller, animated: false, completion: nil)
    }
    
    @IBAction func presentSheet3(_ sender: Any) {
        let controller = SheetViewController(controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sheet3"), sizes: [.fullScreen, .fixed(200)])
        controller.adjustForBottomSafeArea = true
        self.present(controller, animated: false, completion: nil)
    }
    
    @IBAction func presentSheet3v2(_ sender: Any) {
        let controller = SheetViewController(controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sheet3"), sizes: [.fixed(100)])
        controller.adjustForBottomSafeArea = true
        self.present(controller, animated: false, completion: nil)
    }
    
    @IBAction func presentSheet4(_ sender: Any) {
        let controller = SheetViewController(controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sheet4"), sizes: [.fixed(450), .fixed(300), .fixed(600), .fullScreen])
        self.present(controller, animated: false, completion: nil)
    }
    
    @IBAction func presentSheet5(_ sender: Any) {
        let controller = SheetViewController(controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sheet5"), sizes: [.fixed(450), .fixed(300), .fixed(160), .fullScreen])
        self.present(controller, animated: false, completion: nil)
    }
}


class CustomVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func presentSheet(_ sender: Any) {
        
        let controller = SheetViewController(controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sheet2"), sizes: [.halfScreen, .fullScreen, .fixed(250)])
        
        self.present(controller, animated: false, completion: nil)
    }
}


class CustomTableVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        self.sheetViewController?.handleScrollView(self.tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: .default, reuseIdentifier: "cc0")
        cell.textLabel?.text = "row: \(indexPath.row)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected row: \(indexPath.row)")
        presentSheet(true)
        // test close completion handle
        /*self.sheetViewController?.closeSheet(completion: {
            print("selected row: \(indexPath.row)")
        })*/
    }
    
    @IBAction func presentSheet(_ sender: Any) {
        let controller = SheetViewController(controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sheet1"))
        controller.blurBottomSafeArea = false
        controller.topGap = (true, -24.0)//-28 by default
        self.present(controller, animated: false, completion: nil)
    }
}


public extension UIViewController {
    /// resize trait from size with tabBarController
    /// - Parameter size: `CGSize`
    /// - Returns: `CGSize`
    public func sizeTrait(_ size: CGSize) -> CGSize {
        if let tab = self.tabBarController?.tabBar.bounds.size.height {
            return CGSize(width: size.width, height: size.height + tab)
        }else{
            return size
        }
    }
}

/// SheetViewController extension
extension SheetViewController {
    
    /// called to notify the view controller that its view has just laid out its subviews.
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        guard !isRun else { return }
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.update()
            self.isRun = true
        }
    }
    
    
    /// notifies the container that the size of its view is about to change.
    /// - Parameters:
    ///     - size: `CGSize`
    ///     - coordinator: `UIViewControllerTransitionCoordinator`
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        // update size trait
        update(for: nil, size: sizeTrait(size))
        coordinator.animate(alongsideTransition: { (context) in
            //..
        }, completion: nil)
    }
    
    /// update for trait collection - iPad requirements
    /// - Parameters:
    ///     - traitCollection: `UITraitCollection` optional
    ///     - size: `CGSize` optional
    func update(for traitCollection: UITraitCollection? = nil, size: CGSize? = nil) {
        guard let trait = SizeClasser.init(traitCollection: traitCollection ?? super.traitCollection, traitSize: size ?? ( UIApplication.shared.keyWindow?.bounds.size ?? CGSize.zero) ) else { return }
        //print("current size for main: \(trait.toFullType())")
        //currentSizeClass = trait.toFullType()
        TraitSizeManager.shared.trait = trait.toFullType()
        //self.postNotificationName(name: UX.Notifs.Trait.size, object: trait.toFullType())
        switch trait.toFullType() {
        case .iPadPortrait:
            if let cnL = self.containerView.constraints.filter({ $0.firstAttribute == .left }).first {
                cnL.constant = 100.0
            }
            if let cnR = self.containerView.constraints.filter({ $0.firstAttribute == .right }).first {
                cnR.constant = -100.0
            }
            break
        case .iPadLandscapeTwoThird:
            if let cnL = self.containerView.constraints.filter({ $0.firstAttribute == .left }).first {
                cnL.constant = 100.0
            }
            if let cnR = self.containerView.constraints.filter({ $0.firstAttribute == .right }).first {
                cnR.constant = -100.0
            }
            break
        case .iPadLandscape:
            if let cnL = self.containerView.constraints.filter({ $0.firstAttribute == .left }).first {
                cnL.constant = 240.0
            }
            if let cnR = self.containerView.constraints.filter({ $0.firstAttribute == .right }).first {
                cnR.constant = -240.0
            }
            break
        default:
            if let cnL = self.containerView.constraints.filter({ $0.firstAttribute == .left }).first {
                cnL.constant = 0.0
            }
            if let cnR = self.containerView.constraints.filter({ $0.firstAttribute == .right }).first {
                cnR.constant = 0.0
            }
            break
        }
    }
}



/////////////////////
#if os(iOS)
import Foundation
import UIKit

/// Helper `OptionSet` type struct for extending `UITraitCollection` with device
/// specific landscape, portrait or split view mode detections.
public struct SizeClasser: OptionSet {
    
    // MARK: OptionSet
    
    /// raw value as `Int`
    public var rawValue: Int
    
    /// init with rawValue as `Int`
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    // MARK: Init
    
    /// Initilizes with UITraitCollection.
    /// Recommended usage is in UIViewController's `viewDidLayoutSubviews`
    /// or `traitCollectionDidChanged:previousTraitCollection` function
    /// with UIViewController's `traitCollection` property.
    public init?(traitCollection: UITraitCollection, traitSize: CGSize) {
        let appSize = traitSize
        let screenSize = UIScreen.main.bounds.size
        var sizes = SizeClasser()
        
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            if screenSize.width > screenSize.height { // Landscape
                sizes.insert(.iPhoneLandscape)
                sizes.insert(.landscape)
            } else { // Portrait
                sizes.insert(.iPhonePortrait)
                sizes.insert(.portrait)
            }
            
        case .pad:
            if screenSize.width > screenSize.height { // Landscape
                sizes.insert(.iPadLandscape)
                sizes.insert(.landscape)
            } else { // Portrait
                sizes.insert(.iPadPortrait)
                sizes.insert(.portrait)
            }
            
            // Split View
            if screenSize != appSize {
                if screenSize.height > screenSize.width { // Portrait
                    if appSize.width < screenSize.width / 2.0 {
                        sizes.insert(.iPadSplitOneThird)
                    } else {
                        sizes.insert(.iPadSplitTwoThird)
                    }
                } else { // Landscape
                    let lowRange = screenSize.width - 15
                    let highRange = screenSize.width + 15
                    if lowRange / 2.0 <= appSize.width && appSize.width <= highRange / 2.0 {
                        sizes.insert(.iPadSplitHalf)
                    } else if appSize.width <= highRange / 3.0 {
                        sizes.insert(.iPadSplitOneThird)
                    } else {
                        sizes.insert(.iPadSplitTwoThird)
                    }
                }
            }
            
        default:
            return nil
        }
        
        self = sizes
    }
    
    // MARK: Options
    
    /// Screen height is bigger than width. Portrait mode in all devices. - 1
    public static let portrait = SizeClasser(rawValue: 1 << 0)
    /// Screen width is bigger than height. Landscape mode in all devices. - 2
    public static let landscape = SizeClasser(rawValue: 1 << 1)
    /// Portrait mode for iPhone devices. - 4
    public static let iPhonePortrait = SizeClasser(rawValue: 1 << 2)
    /// Landscape mode for iPhone devices. - 8
    public static let iPhoneLandscape = SizeClasser(rawValue: 1 << 3)
    /// Portrait mode for iPad devices. - 16
    public static let iPadPortrait = SizeClasser(rawValue: 1 << 4)
    /// Landscape mode for iPad devices. - 32
    public static let iPadLandscape = SizeClasser(rawValue: 1 << 5)
    /// Split mode 1/3 of visible area in iPad devices. - 256
    public static let iPadSplitOneThird = SizeClasser(rawValue: 1 << 8)
    /// Split mode 1/2 of visible area in iPad devices. - 512
    public static let iPadSplitHalf = SizeClasser(rawValue: 1 << 9)
    /// Split mode 2/3 of visible area in iPad devices. - 1024
    public static let iPadSplitTwoThird = SizeClasser(rawValue: 1 << 10)
    
    // MARK: Helpers
    
    /// Returns maximum length of screen wheater is in portrait or landscape mode.
    public static let maxScreenLength: CGFloat = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    /// iPad Pro 12.9" maximum length of screen.
    public static let ipadProMaxScreenLength: CGFloat = 1366.0
    /// Returns `true` if device is iPad Pro 12.9"
    public static let isiPadPro = SizeClasser.maxScreenLength == SizeClasser.ipadProMaxScreenLength
    
}

/// Size Classer Type Extension
public extension SizeClasser {
    
    /// to type - old
    /// - Returns: `SizeClasserType`
    public func toType() -> SizeClasserType {
        guard let size = SizeClasserType(rawValue: self.rawValue) else {
            return .portrait
        }
        return size
    }
    
    /// to full type
    /// - Returns: `SizeClasserFullType`
    public func toFullType() -> SizeClasserFullType {
        return asType(from: self)
    }
    
    /// Big Type struct
    public struct BigType {
        /// iPad 1/2 - Portrait - 528
        static let iPadPortraitHalf        : SizeClasser = [.iPadSplitHalf, .iPadPortrait]
        /// iPad 1/2 - Landscape - 544
        static let iPadLandscapeHalf       : SizeClasser = [.iPadSplitHalf, .iPadLandscape]
        /// iPad 1/3 - Portrait - 272
        static let iPadPortraitOneThird    : SizeClasser = [.iPadSplitOneThird, .iPadPortrait]
        /// iPad 1/3 - Landscape - 288
        static let iPadLandscapeOneThird   : SizeClasser = [.iPadSplitOneThird, .iPadLandscape]
        /// iPad 2/3 - Portrait - 1040
        static let iPadPortraitTwoThird    : SizeClasser = [.iPadSplitTwoThird, .iPadPortrait]
        /// iPad 2/3 - Landscape - 1056
        static let iPadLandscapeTwoThird   : SizeClasser = [.iPadSplitTwoThird, .iPadLandscape]
    }
    
    /// as full type from `SizeClasser` trait
    /// - Parameter trait: `SizeClasser`
    /// - Returns: `SizeClasserFullType`
    private func asType(from trait: SizeClasser) -> SizeClasserFullType {
        
        switch trait {
        case let value where value.isSuperset(of: BigType.iPadPortraitHalf):
            print("TOOLS: iPad 1/2 - Portrait")
            return .iPadPortraitHalf
        case let value where value.isSuperset(of: BigType.iPadLandscapeHalf):
            print("TOOLS: iPad 1/2 - Landscape")
            return .iPadLandscapeHalf
        case let value where value.isSuperset(of: BigType.iPadPortraitOneThird):
            print("TOOLS: iPad 1/3 - Portrait")
            return .iPadPortraitOneThird
        case let value where value.isSuperset(of: BigType.iPadLandscapeOneThird):
            print("TOOLS: iPad 1/3 - Landscape")
            return .iPadLandscapeOneThird
        case let value where value.isSuperset(of: BigType.iPadPortraitTwoThird):
            print("TOOLS: iPad 2/3 - Portrait")
            return .iPadPortraitTwoThird
        case let value where value.isSuperset(of: BigType.iPadLandscapeTwoThird):
            print("TOOLS: iPad 2/3 - Landscape")
            return .iPadLandscapeTwoThird
        case let value where value.isSuperset(of: .iPadPortrait):
            print("TOOLS: iPad Full Portrait")
            return .iPadPortrait
        case let value where value.isSuperset(of: .iPadLandscape):
            print("TOOLS: iPad Full Landscape")
            return .iPadLandscape
        case let value where value.isSuperset(of: .iPhonePortrait):
            print("TOOLS: iPhone Full Portrait")
            return .iPhonePortrait
        case let value where value.isSuperset(of: .iPhoneLandscape):
            print("TOOLS: iPhone Full Landscape")
            return .iPhoneLandscape
        case let value where value.isSuperset(of: .iPadSplitOneThird):
            print("TOOLS: iPad Split 1/3")
            return .iPadSplitOneThird
        case let value where value.isSuperset(of: .iPadSplitHalf):
            print("TOOLS: iPad Split 1/2")
            return .iPadSplitHalf
        case let value where value.isSuperset(of: .iPadSplitTwoThird):
            print("TOOLS: iPad Split 2/3")
            return .iPadSplitTwoThird
        case let value where value.isSuperset(of: .portrait):
            print("TOOLS: portrait")
            return .portrait
        case let value where value.isSuperset(of: .landscape):
            print("TOOLS: landscape")
            return .landscape
        default:
            print("TOOLS: other size, return .portrait")
            return .portrait
        }
    }
}

/// Size Classer Full Type as `Int`
///
/// a public enum with all full types
///
public enum SizeClasserFullType : Int {
    /// device portrait
    case portrait
    /// device landscape
    case landscape
    /// iPhone portrait
    case iPhonePortrait
    /// iPhone landscape
    case iPhoneLandscape
    /// iPad portrait
    case iPadPortrait
    /// iPad landscape
    case iPadLandscape
    /// iPad 1/3 without orientation
    case iPadSplitOneThird
    /// iPad 1/2 without orientation
    case iPadSplitHalf
    /// iPad 2/3 without orientation
    case iPadSplitTwoThird
    
    /// iPad 1/2 - Portrait
    case iPadPortraitHalf
    /// iPad 1/2 - Landscape
    case iPadLandscapeHalf
    /// iPad 1/3 - Portrait
    case iPadPortraitOneThird
    /// iPad 1/3 - Landscape
    case iPadLandscapeOneThird
    /// iPad 2/3 - Portrait
    case iPadPortraitTwoThird
    /// iPad 2/3 - Landscape
    case iPadLandscapeTwoThird
    
    /// type as `SizeClasser` Type
    public var type: SizeClasser {
        switch self {
        case .portrait:                 return SizeClasser.portrait
        case .landscape:                return SizeClasser.landscape
        case .iPhonePortrait:           return SizeClasser.iPhonePortrait
        case .iPhoneLandscape:          return SizeClasser.iPhoneLandscape
        case .iPadPortrait:             return SizeClasser.iPadPortrait
        case .iPadLandscape:            return SizeClasser.iPadLandscape
        case .iPadSplitOneThird:        return SizeClasser.iPadSplitOneThird
        case .iPadSplitHalf:            return SizeClasser.iPadSplitHalf
        case .iPadSplitTwoThird:        return SizeClasser.iPadSplitTwoThird
            
        case .iPadPortraitHalf:         return SizeClasser.BigType.iPadPortraitHalf
        case .iPadLandscapeHalf:        return SizeClasser.BigType.iPadLandscapeHalf
        case .iPadPortraitOneThird:     return SizeClasser.BigType.iPadPortraitOneThird
        case .iPadLandscapeOneThird:    return SizeClasser.BigType.iPadLandscapeOneThird
        case .iPadPortraitTwoThird:     return SizeClasser.BigType.iPadPortraitTwoThird
        case .iPadLandscapeTwoThird:    return SizeClasser.BigType.iPadLandscapeTwoThird
        }
    }
}


/// Size Classer Type public enum as `Int` - Old
public enum SizeClasserType : Int {
    case portrait
    case landscape
    case iPhonePortrait
    case iPhoneLandscape
    case iPadPortrait
    case iPadLandscape
    case iPadSplitOneThird
    case iPadSplitHalf
    case iPadSplitTwoThird
    
    public var type: SizeClasser {
        switch self {
        case .portrait:             return SizeClasser.portrait
        case .landscape:            return SizeClasser.landscape
        case .iPhonePortrait:       return SizeClasser.iPhonePortrait
        case .iPhoneLandscape:      return SizeClasser.iPhoneLandscape
        case .iPadPortrait:         return SizeClasser.iPadPortrait
        case .iPadLandscape:        return SizeClasser.iPadLandscape
        case .iPadSplitOneThird:    return SizeClasser.iPadSplitOneThird
        case .iPadSplitHalf:        return SizeClasser.iPadSplitHalf
        case .iPadSplitTwoThird:    return SizeClasser.iPadSplitTwoThird
        }
    }
}
#endif



/// trait size manager delegate protocol class
protocol TraitSizeManagerDelegate: class {
    
    /// trait size did change for trait
    /// - Parameter trait: `SizeClasserFullType`
    func traitSizeDidChange(for trait: SizeClasserFullType)
}

/// trait size manager delegate protocol extension as optional
extension TraitSizeManagerDelegate {
    
    /// trait size did change for trait
    /// - Parameter trait: `SizeClasserFullType`
    func traitSizeDidChange(for trait: SizeClasserFullType) {}
}

/// trait size manager delegate protocol extension
extension TraitSizeManagerDelegate where Self: UIViewController {
    
    /// register trait size for view controller
    /// - Parameter vc: `UIViewController` optional
    func registerTraitSize(_ vc: UIViewController?) {
        guard let traitDelegate = vc , UIDevice.current.userInterfaceIdiom == .pad else { return }
        TraitSizeManager.shared.delegate = traitDelegate
        //self.addNotificationObserver(name: UX.Notifs.Trait.size, selector: #selector(sizeClassUpdated(for:)))
    }
}

/// `UIViewController` type extension
/// conforms to `TraitSizeManagerDelegate`
extension UIViewController: TraitSizeManagerDelegate {}

/// `UIViewController` type extension
extension UIViewController {
    
    /// size class updated for notification
    /// - Parameter notification: `Notification`
    @objc func sizeClassUpdated(for notification: Notification) {
        guard let trait = notification.object as? SizeClasserFullType else { return }
        TraitSizeManager.shared.trait = trait
        //currentSizeTrait = trait
        let new = GenericSizeClasserFullType()
        new.type = trait
        self.sizeClass(for: new)
    }
    
    /// size class for trait collection from generic size classer full type
    /// notifies the container that the size class has change.
    /// - Parameter trait: `GenericSizeClasserFullType`
    @objc func sizeClass(for trait: GenericSizeClasserFullType) {}
}

/// Generic Size Classer Full Type class as `NSObject`
/// a model to set generic size classer full type optional
class GenericSizeClasserFullType: NSObject {
    
    /// initializer
    override init() {
        super.init()
    }
    
    /// type as `SizeClasserFullType`, default is `nil`
    var type: SizeClasserFullType? = nil
}

/// Size Trait Manager class as `NSObject`
class TraitSizeManager: NSObject {
    
    /// instance as `TraitSizeManager`
    fileprivate static let instance: TraitSizeManager = TraitSizeManager()
    
    /// shared instance as `TraitSizeManager`
    static var shared: TraitSizeManager {
        return instance
    }
    
    /// trait as `SizeClasserFullType`, default is `nil`
    public internal(set) var trait: SizeClasserFullType? = nil
    
    /// delegate as `TraitSizeManagerDelegate` optional protocol
    weak var delegate: TraitSizeManagerDelegate?
}
