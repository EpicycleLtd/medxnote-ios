//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
@objc
public class VideoPlayerView: UIView {
    @objc var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }

    @objc var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    // Override UIView property
    override public static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

@available(iOS 9.0, *)
@objc
public protocol PlayerProgressBarDelegate {
    func playerProgressBarDidStartScrubbing(_ playerProgressBar: PlayerProgressBar)
    func playerProgressBar(_ playerProgressBar: PlayerProgressBar, scrubbedToTime time: CMTime)
    func playerProgressBar(_ playerProgressBar: PlayerProgressBar, didFinishScrubbingAtTime time: CMTime, shouldResumePlayback: Bool)
}

@available(iOS 9.0, *)
@objc
public class PlayerProgressBar: UIView {
    public let TAG = "[PlayerProgressBar]"

    @objc
    public weak var delegate: PlayerProgressBarDelegate?

    private lazy var formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second ]
        formatter.zeroFormattingBehavior = [ .pad ]

        return formatter
    }()

    // MARK: Subviews
    private let positionLabel = UILabel()
    private let remainingLabel = UILabel()
    private let slider = UISlider()
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    weak private var progressObserver: AnyObject?

    private let kPreferredTimeScale: CMTimeScale = 100

    @objc public var player: AVPlayer? {
        didSet {
            guard let item = player?.currentItem else {
                owsFail("No player item")
                return
            }

            slider.minimumValue = 0

            let duration: CMTime = item.asset.duration
            slider.maximumValue = Float(CMTimeGetSeconds(duration))

            // OPTIMIZE We need a high frequency observer for smooth slider updates,
            // but could use a much less frequent observer for label updates
            progressObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: kPreferredTimeScale), queue: nil, using: { [weak self] (_) in
                self?.updateState()
            }) as AnyObject
            updateState()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)

        // Background
        backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            addSubview(blurEffectView)
            blurEffectView.autoPinToSuperviewEdges()
        }

        // Configure controls

        let kLabelFont = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: UIFont.Weight.regular)
        positionLabel.font = kLabelFont
        remainingLabel.font = kLabelFont

        // We use a smaller thumb for the progress slider.
        slider.setThumbImage(#imageLiteral(resourceName: "sliderProgressThumb"), for: .normal)
        slider.maximumTrackTintColor = UIColor.ows_black()
        slider.minimumTrackTintColor = UIColor.ows_black()

        slider.addTarget(self, action: #selector(handleSliderTouchDown), for: .touchDown)
        slider.addTarget(self, action: #selector(handleSliderTouchUp), for: .touchUpInside)
        slider.addTarget(self, action: #selector(handleSliderTouchUp), for: .touchUpOutside)
        slider.addTarget(self, action: #selector(handleSliderValueChanged), for: .valueChanged)

        // Layout Subviews

        addSubview(positionLabel)
        addSubview(remainingLabel)
        addSubview(slider)

        positionLabel.autoPinEdge(toSuperviewMargin: .leading)
        positionLabel.autoVCenterInSuperview()

        let kSliderMargin: CGFloat = 8

        slider.autoPinEdge(.leading, to: .trailing, of: positionLabel, withOffset: kSliderMargin)
        slider.autoVCenterInSuperview()

        remainingLabel.autoPinEdge(.leading, to: .trailing, of: slider, withOffset: kSliderMargin)
        remainingLabel.autoPinEdge(toSuperviewMargin: .trailing)
        remainingLabel.autoVCenterInSuperview()
    }

    // MARK: Gesture handling

    var wasPlayingWhenScrubbingStarted: Bool = false

    @objc
    private func handleSliderTouchDown(_ slider: UISlider) {
        guard let player = self.player else {
            owsFail("player was nil")
            return
        }

        self.wasPlayingWhenScrubbingStarted = (player.rate != 0) && (player.error == nil)

        self.delegate?.playerProgressBarDidStartScrubbing(self)
    }

    @objc
    private func handleSliderTouchUp(_ slider: UISlider) {
        let sliderTime = time(slider: slider)
        self.delegate?.playerProgressBar(self, didFinishScrubbingAtTime: sliderTime, shouldResumePlayback:wasPlayingWhenScrubbingStarted)
    }

    @objc
    private func handleSliderValueChanged(_ slider: UISlider) {
        let sliderTime = time(slider: slider)
        self.delegate?.playerProgressBar(self, scrubbedToTime: sliderTime)
    }

    // MARK: Render cycle

    private func updateState() {
        guard let player = player else {
            owsFail("\(TAG) player isn't set.")
            return
        }

        guard let item = player.currentItem else {
            owsFail("\(TAG) player has no item.")
            return
        }

        let position = player.currentTime()
        let positionSeconds: Float64 = CMTimeGetSeconds(position)
        positionLabel.text = formatter.string(from: positionSeconds)

        let duration: CMTime = item.asset.duration
        let remainingTime = duration - position
        let remainingSeconds = CMTimeGetSeconds(remainingTime)

        guard let remainingString = formatter.string(from: remainingSeconds) else {
            owsFail("unable to format time remaining")
            remainingLabel.text = "0:00"
            return
        }

        // show remaining time as negative
        remainingLabel.text = "-\(remainingString)"

        slider.setValue(Float(positionSeconds), animated: false)
    }

    // MARK: Util

    private func time(slider: UISlider) -> CMTime {
        let seconds: Double = Double(slider.value)
        return CMTime(seconds: seconds, preferredTimescale: kPreferredTimeScale)
    }
}
