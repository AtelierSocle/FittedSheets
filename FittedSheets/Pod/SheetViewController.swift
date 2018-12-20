//
//  SheetViewController.swift
//  FittedSheets
//
//  Created by Gordon Tucker on 8/23/18.
//  Copyright © 2018 Gordon Tucker. All rights reserved.
//

import UIKit

public class SheetViewController: UIViewController {
    public private(set) var childViewController: UIViewController!
    
    public private(set) weak var containerView: UIView!
    public private(set) weak var pullBarView: UIView!
    
    /// If true, tapping on the overlay above the sheet will dismiss the sheet view controller
    public var dismissOnBackgroundTap: Bool = true
    
    private var firstPanPoint: CGPoint = CGPoint.zero
    
    /// If true, the child view controller will be inset to account for the bottom safe area. This must be set before the sheet view controller loads for it to function properly
    public var adjustForBottomSafeArea: Bool = false
    
    /// If true, the bottom safe area will have a blur effect over it. This must be set before the sheet view controller loads for it to function properly
    public var blurBottomSafeArea: Bool = true
    
    /// pull tint color as `UIColor`, default is `UIColor(white: 0.868, alpha: 1.0)`, could be better to use `.lightGray`
    public var pullTintColor: UIColor = UIColor(white: 0.868, alpha: 1.0)
    
    /// with close button as `Bool`, default is `true`
    public var withCloseButton: Bool = true
    /// close image string value as `String`, default is `fts_cross_custom_small_button`
    public var closeImage: String = "fts_cross_custom_small_button_new"
    /// close image tint color as `UIColor`, default is `UIColor(white: 0.868, alpha: 0.84)`, could be better to use `.lightGray`
    public var closeImageTintColor: UIColor = UIColor(white: 0.868, alpha: 0.84)
    /// close button background color as `UIColor` optional, default is `nil`
    public var closeBackgroundColor: UIColor? = nil
    /// corner radii as `CGSize`, default is `20.0, 20.0`
    public var cornerRadii: CGSize = CGSize(width: 20.0, height: 20.0)
    /// custom top inset as `CGFloat`, default is `24.0`
    public var customTopInset: CGFloat = 24.0
    /// custom top margin as `CGFloat`, default is `-24.0`
    public var customTop: CGFloat = -24.0
    /// top gap as `(Bool, CGFloat)`, default is `(false, 0.0)`
    public var topGap: (Bool, CGFloat) = (true, -28.0)
    /// update parent status bar appearance option as `Bool`, default is `false`
    public var updateParentStatusBarAppearance: Bool = false
    
    /// run as `Bool`, default is `false`
    public var run: Bool = false
    /// is run as `Bool`, getter/setter
    public var isRun: Bool {
        get { return run }
        set(newValue){ self.run = newValue }
    }
    
    /// The current preferred container size
    private var containerSize: SheetSize = .fixed(300)
    /// The current actual container size
    private var actualContainerSize: SheetSize = .fixed(300)
    /// The array of sizes we are trying to pin to when resizing the sheet. To set, use `setSizes` function
    private var orderedSheetSizes: [SheetSize] = [.fixed(300), .fullScreen]
    
    private var panGestureRecognizer: InitialTouchPanGestureRecognizer!
    /// The child view controller's scroll view we are watching so we can override the pull down/up to work on the sheet when needed
    private weak var childScrollView: UIScrollView?
    
    private var containerHeightConstraint: NSLayoutConstraint!
    private var containerBottomConstraint: NSLayoutConstraint!
    private var keyboardHeight: CGFloat = 0
    
    /// The color of the overlay above the sheet. Default is a transparent black.
    var overlayColor: UIColor = UIColor(white: 0, alpha: 0.7) {
        didSet {
            if self.isViewLoaded {
                self.view.backgroundColor = self.overlayColor
            }
        }
    }
    
    private var safeAreaInsets: UIEdgeInsets {
        var inserts = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            inserts = UIApplication.shared.keyWindow?.safeAreaInsets ?? inserts
        }
        inserts.top = max(inserts.top, customTopInset)//20 by default
        return inserts
    }
    
    @available(*, deprecated, message: "Use the init(controller:, sizes:) initializer")
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    /// Initialize the sheet view controller with a child. This is the only initializer that will function properly.
    public convenience init(controller: UIViewController, sizes: [SheetSize] = []) {
        self.init(nibName: nil, bundle: nil)
        self.childViewController = controller
        if sizes.count > 0 {
            self.setSizes(sizes)
        }
        self.modalPresentationStyle = .overFullScreen
        // this is required to update status bar style with non-fullscreen.
        self.modalPresentationCapturesStatusBarAppearance = true
    }
    
    /// called after the controller's view is loaded into memory.
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if (self.childViewController == nil) {
            fatalError("SheetViewController requires a child view controller")
        }
        
        self.view.backgroundColor = UIColor.clear
        self.setUpContainerView()
        self.setUpDismissView()
        
        let panGestureRecognizer = InitialTouchPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        self.view.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = self
        self.panGestureRecognizer = panGestureRecognizer
        self.setUpChildViewController()
        
        self.setUpPullBarView()
        if withCloseButton {
            self.setUpCrossButton()
        }
        // add keyboard notfications observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShown(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDismissed(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    /// status bar style setter as `UIStatusBarStyle`, default is `.lightContent`
    var statusBarStyle: UIStatusBarStyle = .lightContent {
        didSet(newValue) {
            if updateParentStatusBarAppearance {
                parent?.setNeedsStatusBarAppearanceUpdate()
            }
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    /// preferred status bar style as `UIStatusBarStyle`
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
    
    /// notifies the view controller that its view is about to be removed from a view hierarchy.
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        statusBarStyle = .default
    }
    
    /// notifies the view controller that its view is about to be added to a view hierarchy.
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: { [weak self] in
            guard let _self = self else { return }
            _self.view.backgroundColor = _self.overlayColor
            _self.containerView.transform = CGAffineTransform.identity
            _self.actualContainerSize = .fixed(_self.containerView.frame.height)
            _self.statusBarStyle = .lightContent
        }, completion: nil)
    }
    
    /// Change the sizes the sheet should try to pin to
    public func setSizes(_ sizes: [SheetSize]) {
        guard sizes.count > 0 else {
            return
        }
        self.orderedSheetSizes = sizes.sorted(by: { self.height(for: $0) < self.height(for: $1) })
        self.containerSize = sizes[0]
        self.actualContainerSize = sizes[0]
    }
    
    /// Because iOS 10 doesn't support the better rounded corners implementation, we need to fake it here. This can be deleted once iOS 10 support is dropped.
    private func updateLegacyRoundedCorners() {
        if #available(iOS 11.0, *) {
            self.childViewController.view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        } else {
            // iOS 10 doesn't have the better rounded corner feature so we need to fake it
            let path = UIBezierPath(roundedRect: self.childViewController.view.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: cornerRadii)
            let maskLayer = CAShapeLayer()
            maskLayer.path = path.cgPath
            self.childViewController.view.layer.mask = maskLayer
        }
    }
    
    private func setUpOverlay() {
        let overlay = UIView(frame: CGRect.zero)
        overlay.backgroundColor = self.overlayColor
        self.view.addSubview(overlay) { (subview) in
            subview.edges.pinToSuperview()
        }
    }
    
    private func setUpContainerView() {
        let containerView = UIView(frame: CGRect.zero)
        self.view.addSubview(containerView) { (subview) in
            subview.edges(.left, .right).pinToSuperview()
            self.containerBottomConstraint = subview.bottom.pinToSuperview()
            subview.top.pinToSuperview(inset: self.safeAreaInsets.top + 20, relation: .greaterThanOrEqual)
            self.containerHeightConstraint = subview.height.set(self.height(for: self.containerSize))
            self.containerHeightConstraint.priority = UILayoutPriority(900)
        }
        containerView.backgroundColor = UIColor.clear
        self.containerView = containerView
        containerView.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
        
        self.view.addSubview(UIView(frame: CGRect.zero)) { subview in
            subview.edges(.left, .right, .bottom).pinToSuperview()
            subview.height.set(0).priority = UILayoutPriority(100)
            subview.top.align(with: containerView.al.bottom)
            subview.base.backgroundColor = UIColor.white
        }
    }
    
    private func setUpChildViewController() {
        self.childViewController.willMove(toParent: self)
        self.addChild(self.childViewController)
        let bottomInset = self.safeAreaInsets.bottom
        
        self.containerView.addSubview(self.childViewController.view) { (subview) in
            
            subview.edges(.left, .right).pinToSuperview()
            
            switch self.adjustForBottomSafeArea {
            case true: subview.bottom.pinToSuperview(inset: bottomInset, relation: .equal)
            case false: subview.bottom.pinToSuperview()
            }
            
            subview.top.pinToSuperview(inset: customTop, relation: .equal)//TODO: - change inset value for top inset (like -24) default is "24"
        }
        if #available(iOS 11.0, *) {
            self.childViewController.view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
        self.childViewController.view.layer.cornerRadius = cornerRadii.width
        self.childViewController.view.layer.masksToBounds = true
        self.childViewController.didMove(toParent: self)
        
        if self.adjustForBottomSafeArea, bottomInset > 0 {
            // Add white background over bottom bar
            self.containerView.addSubview(UIView(frame: CGRect.zero)) { subview in
                subview.base.backgroundColor = UIColor.white
                subview.edges(.bottom, .left, .right).pinToSuperview()
                subview.height.set(bottomInset)
            }
        }
        
        if blurBottomSafeArea, bottomInset > 0 {
            self.view.addSubview(UIVisualEffectView(effect: UIBlurEffect(style: .light))) { subview in
                subview.edges(.bottom, .left, .right).pinToSuperview()
                subview.height.set(bottomInset)
            }
        }
    }
    
    private func setUpDismissView() {
        let dismissAreaView = UIView(frame: CGRect.zero)
        self.view.addSubview(dismissAreaView, containerView) { (dismissAreaView, containerView) in
            dismissAreaView.edges(.top, .left, .right).pinToSuperview()
            dismissAreaView.bottom.align(with: containerView.top)
        }
        dismissAreaView.backgroundColor = UIColor.clear
        dismissAreaView.isUserInteractionEnabled = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        dismissAreaView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func setUpPullBarView() {
        let pullBarView = UIView(frame: CGRect.zero)
        self.containerView.addSubview(pullBarView) { (subview) in
            subview.edges(.top, .left, .right).pinToSuperview()
            subview.height.set(customTopInset)
        }
        self.pullBarView = pullBarView
        
        let grabView = UIView(frame: CGRect.zero)
        pullBarView.addSubview(grabView) { (subview) in
            switch topGap.0 {
            case true: subview.centerY.alignWithSuperview(offset: topGap.1, relation: .equal)
            case false: subview.centerY.alignWithSuperview()
            }
            subview.centerX.alignWithSuperview()
            subview.size.set(CGSize(width: 50, height: 6))
        }
        grabView.layer.cornerRadius = 3
        grabView.layer.masksToBounds = true
        grabView.backgroundColor = pullTintColor
    }
    
    
    /// set up cross button
    private func setUpCrossButton() {
        let cross = UIButton(type: .custom)
        cross.frame = CGRect.zero
        cross.tag = 254
        self.containerView.addSubview(cross) { (subview) in
            subview.top.pin(to: self.pullBarView.layoutMarginsGuide, inset: -15)
            //subview.right.pin(to: self.pullBarView.layoutMarginsGuide, inset: 7)// default way
            subview.right.pin(to: self.childViewController.view.al.right.item, inset: 15)// pinned fixed way
            
            subview.size.set(CGSize.init(width: 26, height: 26))
        }
        cross.layer.cornerRadius = 13
        cross.layer.masksToBounds = true
        // add image
        let bundle = Bundle(for: classForCoder.self)
        let image = UIImage(named: closeImage, in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        cross.setImage(image, for: .normal)
        cross.imageView?.tintColor = closeImageTintColor
        if let color = closeBackgroundColor {
            cross.backgroundColor = color
        }
        cross.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
    }
    
    @objc func dismissTapped() {
        guard dismissOnBackgroundTap else { return }
        self.closeSheet()
    }
    
    /// Animates the sheet to the closed state and then dismisses the view controller
    public func closeSheet(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: { [weak self] in
            self?.containerView.transform = CGAffineTransform(translationX: 0, y: self?.containerView.frame.height ?? 0)
            self?.view.backgroundColor = UIColor.clear
        }, completion: { [weak self] complete in
            self?.dismiss(animated: false, completion: completion)
        })
    }
    
    @objc func panned(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.translation(in: gesture.view?.superview)
        if gesture.state == .began {
            self.firstPanPoint = point
            self.actualContainerSize = .fixed(self.containerView.frame.height)
        }
        
        let minHeight = min(self.height(for: self.actualContainerSize), self.height(for: self.orderedSheetSizes.first))
        let maxHeight = max(self.height(for: self.actualContainerSize), self.height(for: self.orderedSheetSizes.last))
        
        var newHeight = max(0, self.height(for: self.actualContainerSize) + (self.firstPanPoint.y - point.y))
        var offset: CGFloat = 0
        if newHeight < minHeight {
            offset = minHeight - newHeight
            newHeight = minHeight
        }
        if newHeight > maxHeight {
            newHeight = maxHeight
        }
        
        if gesture.state == .cancelled || gesture.state == .failed {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
                self.containerView.transform = CGAffineTransform.identity
                self.containerHeightConstraint.constant = self.height(for: self.containerSize)
            }, completion: nil)
        } else if gesture.state == .ended {
            let velocity = (0.2 * gesture.velocity(in: self.view).y)
            var finalHeight = newHeight - offset - velocity
            if velocity > 500 {
                // They swiped hard, always just close the sheet when they do
                finalHeight = -1
            }
            
            let animationDuration = TimeInterval(abs(velocity*0.0002) + 0.2)
            
            guard finalHeight >= (minHeight / 2) else {
                // Dismiss
                UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseOut], animations: { [weak self] in
                    self?.containerView.transform = CGAffineTransform(translationX: 0, y: self?.containerView.frame.height ?? 0)
                    self?.view.backgroundColor = UIColor.clear
                }, completion: { [weak self] complete in
                    self?.dismiss(animated: false, completion: nil)
                })
                return
            }
            
            var newSize = self.containerSize
            if point.y < 0 {
                // We need to move to the next larger one
                newSize = self.orderedSheetSizes.last ?? self.containerSize
                for size in self.orderedSheetSizes.reversed() {
                    if finalHeight < self.height(for: size) {
                        newSize = size
                    } else {
                        break
                    }
                }
            } else {
                // We need to move to the next smaller one
                newSize = self.orderedSheetSizes.first ?? self.containerSize
                for size in self.orderedSheetSizes {
                    if finalHeight > self.height(for: size) {
                        newSize = size
                    } else {
                        break
                    }
                }
            }
            self.containerSize = newSize
            
            UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseOut], animations: {
                self.containerView.transform = CGAffineTransform.identity
                self.containerHeightConstraint.constant = self.height(for: newSize)
                self.view.layoutIfNeeded()
            }, completion: { [weak self] complete in
                guard let _self = self else { return }
                _self.actualContainerSize = .fixed(_self.containerView.frame.height)
            })
        } else {
            Constraints(for: self.containerView) { (containerView) in
                self.containerHeightConstraint.constant = newHeight
            }
            
            if offset > 0 {
                self.containerView.transform = CGAffineTransform(translationX: 0, y: offset)
            } else {
                self.containerView.transform = CGAffineTransform.identity
            }
            
        }
    }
    
    @objc func keyboardShown(_ notification: Notification) {
        guard let info:[AnyHashable: Any] = notification.userInfo, let keyboardRect:CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        let windowRect = self.view.convert(self.view.bounds, to: nil)
        let actualHeight = windowRect.maxY - keyboardRect.origin.y
        self.adjustForKeyboard(height: actualHeight, from: notification)
    }
    
    @objc func keyboardDismissed(_ notification: Notification) {
        self.adjustForKeyboard(height: 0, from: notification)
    }
    
    private func adjustForKeyboard(height: CGFloat, from notification: Notification) {
        guard let info:[AnyHashable: Any] = notification.userInfo else { return }
        self.keyboardHeight = height
        
        let duration:TimeInterval = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
        
        UIView.animate(withDuration: duration, delay: 0, options: animationCurve, animations: {
            self.containerBottomConstraint.constant = min(0, -height + (self.adjustForBottomSafeArea ? self.safeAreaInsets.bottom : 0))
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    /// Handle a scroll view in the child view controller by watching for the offset for the scrollview and taking priority when at the top (so pulling up/down can grow/shrink the sheet instead of bouncing the child's scroll view)
    public func handleScrollView(_ scrollView: UIScrollView) {
        scrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
        self.childScrollView = scrollView
    }
    
    private func height(for size: SheetSize?) -> CGFloat {
        guard let size = size else { return 0 }
        switch (size) {
            case .fixed(let height):
                return height
            case .fullScreen:
                let insets = self.safeAreaInsets
                return UIScreen.main.bounds.height - insets.top - 20
            case .halfScreen:
                return (UIScreen.main.bounds.height) / 2 + customTopInset
        }
    }
}

extension SheetViewController: UIGestureRecognizerDelegate {
    
    /// asks the delegate if a gesture recognizer should begin interpreting touches.
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGestureRecognizer = gestureRecognizer as? InitialTouchPanGestureRecognizer, let childScrollView = self.childScrollView, let point = panGestureRecognizer.initialTouchLocation else { return true }
        
        let pointInChildScrollView = self.view.convert(point, to: childScrollView).y - childScrollView.contentOffset.y
        
        let velocity = panGestureRecognizer.velocity(in: panGestureRecognizer.view?.superview)
        guard pointInChildScrollView > 0, pointInChildScrollView < childScrollView.bounds.height else {
            if keyboardHeight > 0 {
                childScrollView.endEditing(true)
            }
            return true
        }
        
        guard abs(velocity.y) > abs(velocity.x), childScrollView.contentOffset.y == 0 else { return false }
        
        if velocity.y < 0 {
            let containerHeight = height(for: self.containerSize)
            return height(for: self.orderedSheetSizes.last) > containerHeight && containerHeight < height(for: SheetSize.fullScreen)
        } else {
            return true
        }
    }
}


//extension UIImage {
//
//    convenience init?(podAssetName: String) {
//        let podBundle = Bundle(for: SheetViewController.self)
//        /// A given class within your Pod framework
//        guard let url = podBundle.url(forResource: "FittedSheets", withExtension: "bundle")
//        else { return nil }
//        self.init(named: podAssetName, in: Bundle(url: url), compatibleWith: nil)
//    }
//
//}

/*
extension NSLayoutConstraint.Attribute {
    func toString() -> String {
        switch self {
        case .left:
            return "left"
        case .right:
            return "right"
        case .top:
            return "top"
        case .bottom:
            return "bottom"
        case .leading:
            return "leading"
        case .trailing:
            return "trailing"
        case .width:
            return "width"
        case .height:
            return "height"
        case .centerX:
            return "centerX"
        case .centerY:
            return "centerY"
        case .lastBaseline:
            return "lastBaseline"
        case .firstBaseline:
            return "firstBaseline"
        case .leftMargin:
            return "leftMargin"
        case .rightMargin:
            return "rightMargin"
        case .topMargin:
            return "topMargin"
        case .bottomMargin:
            return "bottomMargin"
        case .leadingMargin:
            return "leadingMargin"
        case .trailingMargin:
            return "trailingMargin"
        case .centerXWithinMargins:
            return "centerXWithinMargins"
        case .centerYWithinMargins:
            return "centerYWithinMargins"
        case .notAnAttribute:
            return "notAnAttribute"
        }
    }
}
*/
