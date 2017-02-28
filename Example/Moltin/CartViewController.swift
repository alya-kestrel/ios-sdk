//
//  CartViewController.swift
//  Moltin
//
//  Created by Oliver Foggin on 28/02/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

import Moltin
import AlamofireImage

class CartViewController: UIViewController {
    static var cartReference: String?
    
    var cartItems: [CartItem] = []
    var cartMeta: CartMeta? = nil {
        didSet {
            guard let cartMeta = cartMeta else {
                return
            }
            
            totalPriceLabel.text = cartMeta.displayPriceWithTax?.formatted
        }
    }
    
    lazy var collectionView: UICollectionView = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .vertical
        l.minimumLineSpacing = 20
        l.minimumInteritemSpacing = 20
        l.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let c = UICollectionView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), collectionViewLayout: l)
        c.translatesAutoresizingMaskIntoConstraints = false
        c.backgroundColor = UIColor(red:0.17, green:0.22, blue:0.26, alpha:1.00)
        c.register(CartItemCell.self, forCellWithReuseIdentifier: "CartItemCell")
        c.delegate = self
        c.dataSource = self
        return c
    }()
    
    let totalPriceLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textColor = UIColor(red:0.62, green:0.49, blue:0.75, alpha:1.00)
        l.font = UIFont.montserratRegular(size: 25)
        l.text = "£0.00"
        l.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        l.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        return l
    }()
    
    let totalLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Total"
        l.textColor = .white
        l.font = UIFont.montserratRegular(size: 25)
        return l
    }()
    
    let addToCartButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Checkout", for: .normal)
        b.backgroundColor = UIColor(red:0.62, green:0.49, blue:0.75, alpha:1.00)
        b.heightAnchor.constraint(equalToConstant: 44).isActive = true
        b.layer.cornerRadius = 22
        b.layer.masksToBounds = true
        return b
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "SHOPPING CART"
        
        view.backgroundColor = UIColor(red:0.17, green:0.22, blue:0.26, alpha:1.00)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
        
        let labelStackView: UIStackView = {
            let s = UIStackView(arrangedSubviews: [totalLabel, totalPriceLabel])
            s.translatesAutoresizingMaskIntoConstraints = false
            s.axis = .horizontal
            s.spacing = 8
            s.distribution = .fill
            s.alignment = .firstBaseline
            s.isLayoutMarginsRelativeArrangement = true
            return s
        }()
        
        let mainStackView: UIStackView = {
            let s = UIStackView(arrangedSubviews: [collectionView, labelStackView, addToCartButton])
            s.translatesAutoresizingMaskIntoConstraints = false
            s.axis = .vertical
            s.spacing = 20
            s.distribution = .fill
            s.alignment = .fill
            s.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            s.isLayoutMarginsRelativeArrangement = true
            return s
        }()
        
        view.addSubview(mainStackView)
        
        mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        mainStackView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        if let cartRef = CartViewController.cartReference {
            Moltin.cart.list(itemsInCartID: cartRef) { result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let cartList):
                    self.cartItems = cartList.items
                    self.cartMeta = cartList.meta
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    func close() {
        dismiss(animated: true, completion: nil)
    }
}

extension CartViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cartItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CartItemCell", for: indexPath) as! CartItemCell
        
        let item = cartItems[indexPath.item]
        
        Moltin.product.get(withProductID: item.productID, include: [.files]) { result in
            switch result {
            case .failure(_):
                break
            case .success(let product):
                guard let product = product,
                    let file = product.files.first,
                    let cell = collectionView.cellForItem(at: indexPath) as? CartItemCell else {
                    return
                }
                
                cell.productImageView.af_setImage(withURL: file.url)
            }
        }
        
        cell.productNameLabel.text = item.name
        cell.productPriceLabel.text = "£12.34"
        cell.quantityLabel.text = "\(item.quantity)"
        
        return cell
    }
}

extension CartViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 100)
    }
}

class CartItemCell: UICollectionViewCell {
    let productImageView: UIImageView = {
        let i = UIImageView()
        i.translatesAutoresizingMaskIntoConstraints = false
        i.contentMode = .scaleAspectFit
        i.widthAnchor.constraint(equalTo: i.heightAnchor).isActive = true
        return i
    }()
    
    let productNameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.montserratRegular(size: 15)
        l.textColor = .white
        return l
    }()
    
    let productPriceLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.montserratRegular(size: 13)
        l.textColor = UIColor(red:0.62, green:0.49, blue:0.75, alpha:1.00)
        return l
    }()
    
    let quantityLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        l.font = UIFont.montserratRegular(size: 20)
        l.backgroundColor = .white
        l.setContentHuggingPriority(500, for: .vertical)
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(red:0.17, green:0.22, blue:0.26, alpha:1.00)
        
        let labelStackView: UIStackView = {
            let s = UIStackView(arrangedSubviews: [productNameLabel, productPriceLabel, quantityLabel])
            s.translatesAutoresizingMaskIntoConstraints = false
            s.axis = .vertical
            s.spacing = 6
            s.alignment = .fill
            return s
        }()
        
        let mainStackView: UIStackView = {
            let s = UIStackView(arrangedSubviews: [productImageView, labelStackView])
            s.translatesAutoresizingMaskIntoConstraints = false
            s.alignment = .fill
            s.distribution = .fill
            s.axis = .horizontal
            s.spacing = 6
            return s
        }()
        
        addSubview(mainStackView)
        
        mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        mainStackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
