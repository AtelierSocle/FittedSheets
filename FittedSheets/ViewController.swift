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
    }
    
    @IBAction func presentSheet(_ sender: Any) {
        let controller = SheetViewController(controller: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sheet1"))
        controller.blurBottomSafeArea = false
        controller.topGap = (true, -24.0)//-28 by default
        self.present(controller, animated: false, completion: nil)
    }
}
