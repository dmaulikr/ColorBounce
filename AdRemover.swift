//
//  AdRemover.swift
//  ColorBounce
//
//  Created by Phil Javinsky III on 6/10/17.
//  Copyright © 2017 Phil Javinsky III. All rights reserved.
//

import StoreKit

var hideAds: Bool = false

class AdRemover: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    private var fetched: Bool = false
    private var product: SKProduct?
    private var productID = "colorWheelRemoveAds"
    private var readyForIAP = false
    
    func initialize() {
        //print("initialized")
        SKPaymentQueue.default().add(self)
        if defaults.bool(forKey: "purchased") {
            //print("Already purchased")
            bannerAd.isHidden = true
            hideAds = true
        }
        else {
            //print("Not purchased")
            if !fetched {
                //print("Fetching")
                getProductInfo()
                fetched = true
            }
        }
    }
    
    func removeAds() {
        if readyForIAP {
            self.buyProduct()
        }
        else {
            //print("Not ready for IAP")
            let alert = UIAlertController.init(title: "Error", message: "Something went wrong, try again later.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
            UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
        }
    }
    
    func restoreAdRemoval() {
        if (SKPaymentQueue.canMakePayments()) {
            SKPaymentQueue.default().restoreCompletedTransactions()
        }
    }
    
    func getProductInfo() {
        //print("About to fetch the products")
        // Check if allowed to make the purchase
        if SKPaymentQueue.canMakePayments() {
            let productIdentifier: NSSet = NSSet(object: productID)
            let productsRequest: SKProductsRequest = SKProductsRequest(productIdentifiers: productIdentifier as! Set<String>)
            productsRequest.delegate = self
            productsRequest.start()
            //print("Fetching Products")
        }
        //else {
            //print("can't make purchases")
        //}
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        var products = response.products
        if (products.count != 0) {
            product = products[0]
            //print(product!.localizedTitle)
            //print(product!.localizedDescription)
            //print(product!.price)
            readyForIAP = true
        }
        //else {
            //print("Product not found")
        //}
    }
    
    func buyProduct() {
        //print("Sending the Payment Request to Apple")
        let payment = SKPayment(product: product!)
        SKPaymentQueue.default().add(payment)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        //print("Received Payment Transaction Response from Apple")
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                //print("Product Purchased")
                defaults.set(true, forKey: "purchased")
                bannerAd.isHidden = true
                hideAds = true
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                //print("Purchased Failed")
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                //print("Already Purchased")
                let alert: UIAlertController = UIAlertController(title: "Restored", message: "Purchase restored, ads removed.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
                UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
                defaults.set(true, forKey: "purchased")
                bannerAd.isHidden = true
                hideAds = true
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Error Fetching product information");
    }
    
    func removeObserver() {
        SKPaymentQueue.default().remove(self)
    }

}

extension UIApplication {
    
    static func topViewController(base: UIViewController? = UIApplication.shared.delegate?.window??.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        
        return base
    }
}
