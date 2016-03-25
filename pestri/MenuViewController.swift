//
//  MenuViewController.swift
//  pestri
//
//  Created by Mathieu Dutour on 25/03/2016.
//
//

import UIKit

class MenuViewController: UIViewController {
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "pattern")!)
    }
}
