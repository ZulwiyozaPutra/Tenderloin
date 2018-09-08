//
//  TenderloinViewController.swift
//  Tenderloin
//
//  Created by Zulwiyoza Putra on 07/09/18.
//  Copyright © 2018 Wiyoza. All rights reserved.
//

import UIKit

class TenderloinViewController: UICollectionViewController {
    let cellIdentifier = "ProductCell"
    var networkController: NetworkController!
    var products: [Product]? {
        didSet {
            DispatchQueue.main.async {
                self.reloadData()
            }
        }
    }
    
    init(networkController: NetworkController, layout: UICollectionViewFlowLayout) {
        super.init(collectionViewLayout: layout)
        self.networkController = networkController
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }

}

extension TenderloinViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let products = products else {
            return 0
        }
        return products.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ProductCell
        guard let products = products else {
            return cell
        }
        let product = products[indexPath.row]
        cell.product = product
        if indexPath.row == 0 {
            cell.position = .top
        } else if indexPath.row == products.count - 1 {
            cell.position = .bottom
        } else {
            cell.position = .middle
        }
        return cell
    }
}

extension TenderloinViewController {
    private func setUp() {
        setNavigationController()
        setCollectionView()
        getProducts { (products: [Product]?) in
            self.products = products
        }
    }
    
    private func reloadData() {
        guard let collectionView = collectionView else {
            fatalError("""
                TenderloinViewController doesn't have a collectionView.
                Make sure TenderloinViewController subclasses UICollectionViewContrller
                """
            )
        }
        collectionView.reloadData()
    }
    
    private func setNavigationController(withTitle title: String = "Home") {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        guard appDelegate.window != nil else {
            print("""
                The app delegate window is remaining nil.
                Please set the window in AppDelegate to present a viewController.
                Ignore this if you are on unit test.
                """
            )
            return
        }
        guard let navigationController = navigationController else {
            fatalError("""
                TenderloinViewController doesn't have a navigationController.
                Make sure the TenderloinViewController has been set as a root of a UINavigationController.
                """
            )
        }
        navigationController.navigationBar.barTintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        navigationItem.title = title
    }
    
    private func setCollectionView() {
        guard let collectionView = collectionView else {
            fatalError("""
                TenderloinViewController doesn't have a collectionView.
                Make sure TenderloinViewController subclasses UICollectionViewContrller
                """
            )
        }
        
        let flow = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let itemSpacing: CGFloat = 16.0
        let itemsInOneLine: CGFloat = 1
        let width = UIScreen.main.bounds.size.width - itemSpacing * CGFloat(itemsInOneLine + 1)
        let height: CGFloat = 128
        flow.sectionInset = UIEdgeInsets(top: itemSpacing, left: itemSpacing, bottom: itemSpacing, right: itemSpacing)
        flow.itemSize = CGSize(width: floor(width/itemsInOneLine), height: height)
        flow.minimumInteritemSpacing = 16
        flow.minimumLineSpacing = 8
        
        collectionView.register(ProductCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    }
}


extension TenderloinViewController {
    typealias GetProductsCompletionHandler = ((_ products: [Product]?) -> Void)?
    
    func getProducts(completionHandler: GetProductsCompletionHandler = nil) {
        networkController.searchProducts(key: "Philips", minPrice: "0", maxPrice: "10000", isWholesale: false, isOfficial: true, golds: 3, startingIndex: 0, items: 30) { (products: [Product]?, errorMessage: String?) in
            if let errorMessage = errorMessage, errorMessage != "" {
                if let handler = completionHandler {
                    handler(nil)
                }
            }
            
            if let products = products {
                if let handler = completionHandler {
                    DispatchQueue.global(qos: .userInitiated).async {
                        var productsWithImage: [Product] = []
                        let downloadGroup = DispatchGroup()
                        for product in products {
                            downloadGroup.enter()
                            self.networkController.downloadImage(imageURI: product.imageURI, completionHandler: { (data: Data?, errorMessage: String?) in
                                if let data = data {
                                    var product = product
                                    product.imageData = data
                                    productsWithImage.append(product)
                                }
                                downloadGroup.leave()
                            })
                        }
                        downloadGroup.wait()
                        DispatchQueue.main.async {
                            handler(productsWithImage)
                        }
                    }
                }
            }
        }
    }
}


