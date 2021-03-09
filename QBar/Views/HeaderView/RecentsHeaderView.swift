//
//  RecentsHeaderView.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 2/27/21.
//

import UIKit

enum Tab: String {
    case History = "History"
    case Bookmarks = "Bookmarks"
}

protocol TabDelegate: class {
    func didChoose(tab: Tab)
}

class RecentsHeaderView: UIView {
    
    lazy var headerTitle: UILabel = {
        let title = UILabel(frame: .zero)
        return title
    }()
    
    lazy var headerSegment: SegmentedControl = {
        let segmentControl = SegmentedControl(frame: .zero)
        return segmentControl
    }()
    
    weak var delegate: TabDelegate?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .mainWhite
        
        addSubview(headerTitle)
        addSubview(headerSegment)
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        headerSegment.translatesAutoresizingMaskIntoConstraints = false
        
        headerTitle.textAlignment = .center
        headerTitle.textColor = .mainBlack
        headerTitle.font = .sfProDisplay(ofSize: 30, style: .bold)
        
        let segments = LabelSegment.segments(withTitles: ["History", "Bookmarks"], numberOfLines: 1, normalBackgroundColor: .mainBlack, normalFont: .sfProDisplay(ofSize: 14, style: .medium), normalTextColor: .mainGrayAverage, selectedBackgroundColor: .mainBlue, selectedFont: .sfProDisplay(ofSize: 14, style: .medium), selectedTextColor: .mainWhite)
        
        headerSegment.segments = segments
        headerSegment.cornerRadius(to: 16)
        headerSegment.indicatorViewInset = 1.0
        headerSegment.indicatorViewBorderWidth = 1.0
        headerSegment.setIndex(0)
        headerSegment.addTarget(self, action: #selector(selectionDidChange(_:)), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            headerTitle.topAnchor.constraint(equalTo: topAnchor, constant: 48),
            headerTitle.centerXAnchor.constraint(equalTo: centerXAnchor),
            headerTitle.bottomAnchor.constraint(equalTo: headerSegment.topAnchor, constant: -16),

            headerSegment.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 72),
            headerSegment.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -72),
            headerSegment.heightAnchor.constraint(equalToConstant: 40),
            headerSegment.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -33)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Functions
    func configureHeader(text: String?) {
        headerTitle.text = text
    }
    
    func updateView() {
        switch headerSegment.index {
        case 0:
            delegate?.didChoose(tab: .History)
        case 1:
            delegate?.didChoose(tab: .Bookmarks)
        default:
            break
        }
        print("Segments changed")
    }
    
    // MARK: - OBJC Functions
    @objc func selectionDidChange(_ sender: SegmentedControl) {
        updateView()
    }
}
