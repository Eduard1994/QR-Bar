//
//  VideoView.swift
//  QBar
//
//  Created by Eduard Shahnazaryan on 7/12/21.
//

import UIKit
import AVKit
import AVFoundation

class VideoView: UIView {
    
    var videoLayer: CALayer?
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    var isLoop: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        videoLayer?.frame = self.bounds
    }
    
    func configure(resource: String) {
        guard let path = Bundle.main.path(forResource: resource, ofType:"mp4") else {
            debugPrint("video.m4v not found")
            return
        }
        let videoURL = URL(fileURLWithPath: path)
        player = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerLayer?.frame = bounds
        if let playerLayer = self.playerLayer {
            layer.addSublayer(playerLayer)
        }
        videoLayer = playerLayer
        NotificationCenter.default.addObserver(self, selector: #selector(reachTheEndOfTheVideo(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
        
    }
    
    func play() {
        if player?.timeControlStatus != AVPlayer.TimeControlStatus.playing {
            player?.play()
        }
    }
    
    func pause() {
        player?.pause()
    }
    
    func stop() {
        player?.pause()
        player?.seek(to: CMTime.zero)
    }
    
    @objc func reachTheEndOfTheVideo(_ notification: Notification) {
        if isLoop {
            player?.pause()
            player?.seek(to: CMTime.zero)
            player?.play()
        }
    }
}

