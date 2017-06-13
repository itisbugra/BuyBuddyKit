//
//  ShoppingCartButton.swift
//  BuyBuddyKit
//
//  Created by Emir Çiftçioğlu on 11/05/2017.
//
//

import Foundation
import UIKit

public protocol BuyBuddyCartButtonDelegate:class {
    func buttonWasPressed(_ button:UIButton)

}
public protocol BuyBuddyCartButtonBadgeDelegate {
    func countDidChange(_ data:String)
    
}
@IBDesignable
public class BuyBuddyCartButton:UIButton,BuyBuddyCartButtonBadgeDelegate{
    
    fileprivate var countLabel: UILabel = UILabel(frame: .zero)
    public weak var delegate:BuyBuddyCartButtonDelegate?
    
    @IBInspectable
    public var badgeColor = UIColor.buddyGreen() {
        didSet {
            self.countLabel.backgroundColor = badgeColor
        }
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        self.adjustImageAndTitleOffsets()
        self.addBlurEffect()
        self.addTarget(self, action: #selector(buttonPress), for: .touchUpInside)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.adjustImageAndTitleOffsets()
        self.addBlurEffect()
        self.addTarget(self, action: #selector(buttonPress), for: .touchUpInside)
        createLabel()
        self.setImage(UIImage(named: "shopping_cart", in: Bundle(for: type(of: self)), compatibleWith: nil), for: UIControlState.normal)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createLabel()
        self.setImage(UIImage(named: "shopping_cart", in: Bundle(for: type(of: self)), compatibleWith: nil), for: UIControlState.normal)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.layer.frame.width / 2
        self.layer.masksToBounds = true
    }
    
    private func createLabel(){
        countLabel.frame = CGRect(x:   self.frame.width/2, y:  self.frame.width/2, width: self.frame.width/3.5, height: self.frame.width/3.5)
        countLabel.textAlignment = .center
        countLabel.backgroundColor = UIColor.buddyGreen()
        countLabel.textColor = UIColor.white
        countLabel.layer.masksToBounds = true
        countLabel.text = "0"
        countLabel.font = UIFont(name: "Avenir-Heavy", size: 13)
        countLabel.layer.cornerRadius = countLabel.layer.frame.width / 2

        self.addSubview(countLabel)
    }
    
    func buttonPress(button:UIButton) {
        delegate?.buttonWasPressed(self)
        BuyBuddyViewManager.callShoppingBasketView(viewController:self.parentViewController! ,transitionStyle:.crossDissolve,cartButton:self)
    }
    
    public func withBlur(blur:Bool = true){
    
        if(blur){
            self.addBlurEffect()
        }else{
            let subViews = self.subviews
            for subview in subViews{
                if subview.tag == 100{
                    subview.removeFromSuperview()
                }
            }
        }
    }
    
    public func countDidChange(_ data: String) {
        countLabel.text = data
    }
    
    private func adjustImageAndTitleOffsets () {
        
        let spacing: CGFloat = 3.0
        let imageSize = self.imageView!.frame.size
        self.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width, -(imageSize.height + spacing), 0)
        let titleSize = self.titleLabel!.frame.size
        self.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + spacing), 0, 0, -titleSize.width)
    }
    
}
