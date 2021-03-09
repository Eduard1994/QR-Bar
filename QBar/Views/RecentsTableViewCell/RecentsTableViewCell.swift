//
//  RecentsTableViewCell.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/27/21.
//

import UIKit

class RecentsTableViewCell: UITableViewCell {

    // MARK: - IBOutlets
    @IBOutlet weak var codeImageView: UIImageView!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var codeDate: UILabel!
    @IBOutlet weak var leftArrorButton: UIButton!
    
    
    // MARK: - Properties
    var codeModel: CodeCellModel! {
        didSet {
            codeImageView.image = nil
            codeLabel.text = codeModel.codeTitle
            codeDate.text = codeModel.dateTitle
            codeImageView.image = UIImage(named: codeModel.codeImageName)
        }
    }
    
    // MARK: - Override Functions
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.mainGrayAverage
        
        if selected {
            selectedBackgroundView = backgroundView
        }
    }
}
