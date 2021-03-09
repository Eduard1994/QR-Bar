//
//  SettingsTableViewCell.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/28/21.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {

    // MARK: - IBOutlets
    @IBOutlet weak var settingsImageView: UIImageView!
    @IBOutlet weak var settingsTitle: UILabel!
    
    
    // MARK: - Properties
    var settingsModel: SettingsCellModel! {
        didSet {
            settingsImageView.image = nil
            settingsTitle.text = settingsModel.settingsTitle
            settingsImageView.image = UIImage(named: settingsModel.settingsImageName)
        }
    }
    
    // MARK: - Override Functions
    override func awakeFromNib() {
        super.awakeFromNib()
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
