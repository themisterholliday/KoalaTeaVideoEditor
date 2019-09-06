////
////  VideoEditorViewController.swift
////  AssetPlayer
////
////  Created by Craig Holliday on 8/29/18.
////
//
//import UIKit
//
//public protocol VideoEditorViewControllerDelegate: class {
//    func videoEditorDidFinishEditingVideo(videoEditor: VideoEditorViewController, videoURL: URL, sendWithAudioOn: Bool)
//    func videoEditorDidDisappear(videoEditor: VideoEditorViewController)
//}
//
//public enum VideoEditorVCState {
//    case loading
//    case playing
//    case paused
//    case muted
//    case unmuted
//    case none
//    case exportError
//}
//
//public enum VideoEditorVCIntentions {
//    case setup(video: VideoAsset)
//    case didTapPauseButton
//    case didTapPlayButton
//    case didTapMuteButton
//    case didTapUnmuteButton
//    case didStartScrolling
//    case didScroll(to: (startTime: Double, endTime: Double))
//    case didTapContinueButton(playerViewFrame: CGRect,
//        playerViewTransform: CGAffineTransform,
//        playerViewAdjustedOrigin: CGPoint,
//        cropViewFrame: CGRect,
//        viewController: VideoEditorViewController)
//    case didDisappear
//}
//
//public class VideoEditorViewController: UIViewController {
//    @IBOutlet weak var playerView: DraggablePlayerView!
//    @IBOutlet weak var timelineView: TimelineView!
//    @IBOutlet weak var canvasView: UIView!
//    @IBOutlet weak var cropView: UIView!
//    @IBOutlet weak var sendWithAudioLabel: UILabel!
//    @IBOutlet weak var playPauseButton: UIButton!
//    @IBOutlet weak var muteUnmuteButton: UIButton!
//    @IBOutlet weak var playButtonImageView: UIImageView!
//    @IBOutlet weak var muteButtonImageView: UIImageView!
//
//    @IBOutlet weak var secondsTickView: SecondsTickView!
//    @IBOutlet weak var secondsTickViewWidthConstraint: NSLayoutConstraint!
//    @IBOutlet weak var doneButton: UIBarButtonItem!
//
//    public var videoAsset: VideoAsset!
//    private var logicController: VideoEditorLogicController!
//
//    private lazy var renderHandler: VideoEditorLogicController.StateHandler = { [weak self] state in self?.render(state: state) }
//
//    private lazy var userAccentColor: UIColor = {
//        return UserAccentColor.color
//    }()
//
//    weak var delegate: VideoEditorViewControllerDelegate?
//
//    override public func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        if self.videoAsset == nil {
//            assertionFailure("Can't use this view without passing in video asset")
//        }
//
//        self.doneButton.tintColor = userAccentColor
//        self.playButtonImageView.image = self.playButtonImageView.image?.tint(with: userAccentColor)
//        self.playButtonImageView.highlightedImage = self.playButtonImageView.highlightedImage?.tint(with: userAccentColor)
//
//        self.muteButtonImageView.image = self.muteButtonImageView.image?.tint(with: userAccentColor)
//        self.muteButtonImageView.highlightedImage = self.muteButtonImageView.highlightedImage?.tint(with: userAccentColor)
//
//        self.sendWithAudioLabel.text = Constants.SendWithAudioOnText
//
//        self.timelineView.delegate = self
//
//        self.logicController = VideoEditorLogicController(videoAsset: self.videoAsset, setupHandler: { [weak self] (assetPlayer) in
//            guard let strongSelf = self else { return }
//
//            strongSelf.playerView.player = assetPlayer.player
//
//            // Set player view frame to aspect fill canvas view
//            guard let size = assetPlayer.asset?.naturalAssetSize else {
//                return
//            }
//            guard let isPortrait = assetPlayer.asset?.urlAsset.getFirstVideoTrack()?.assetInfo.isPortrait else {
//                return
//            }
//            // Cleanup this check
//            // Have to check if is protrait
//            let finalSize = isPortrait ? CGSize(width: size.height, height: size.width) : size
//            let scaledSize = CGSize.aspectFill(aspectRatio: finalSize, minimumSize: strongSelf.cropView.frame.size)
//            strongSelf.playerView.frame = CGRect(origin: .zero, size: scaledSize)
//            strongSelf.playerView.center = strongSelf.canvasView.center
//        }, trackingHandler: { [weak self] (startTime, currentTime) in
//            // Handle timeline tracking here
//            self?.timelineView.handleTracking(startTime: startTime, currentTime: currentTime)
//        })
//
//        self.logicController.handle(intent: .setup(video: self.videoAsset), stateHandler: renderHandler)
//    }
//
//    override public func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        self.timelineView.setupTimeline(with: self.videoAsset)
//        self.timelineView.changeAccentColor(to: userAccentColor)
//
//        guard let cropViewFrame = self.timelineView.cropViewFrame else {
//            return
//        }
//        let duration = self.videoAsset.cropDurationInSeconds
//        self.secondsTickView.setupWithSeconds(seconds: duration, cropViewFrame: cropViewFrame)
//        // Update width constraint because we calculate secondsTickView width in `setupWithSeconds`
//        secondsTickViewWidthConstraint.constant = self.secondsTickView.frame.width
//    }
//
//    public override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//
//        self.logicController.handle(intent: .didDisappear, stateHandler: renderHandler)
//        self.delegate?.videoEditorDidDisappear(videoEditor: self)
//        self.delegate = nil
//    }
//
//    func render(state: VideoEditorVCState) {
//        self.hideHUD()
//
//        switch state {
//        case .loading:
//            self.showSimpleActivityHUD()
//        case .playing:
//            // Switch play/pause button to play
//            self.playPauseButton.isSelected = true
//            self.playButtonImageView.isHighlighted = true
//        case .paused:
//            // Switch play/pause button to pause
//            self.playPauseButton.isSelected = false
//            self.playButtonImageView.isHighlighted = false
//        case .muted:
//            // Switch mute button to muted
//            self.muteUnmuteButton.isSelected = true
//            self.muteButtonImageView.isHighlighted = true
//
//            // Update send audio label
//            self.sendWithAudioLabel.text = Constants.SendWithAudioOffText
//        case .unmuted:
//            // Switch mute button to unmuted
//            self.muteUnmuteButton.isSelected = false
//            self.muteButtonImageView.isHighlighted = false
//
//            // Update send audio label
//            self.sendWithAudioLabel.text = Constants.SendWithAudioOnText
//        case .none:
//            break
//        case .exportError:
//            UIAlertController.present(withTitle: Constants.ExportErrorTitle, message: Constants.ExportErrorMessage, overViewController: self, defaultHandler: nil)
//        }
//    }
//
//    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
//        let intent: VideoEditorVCIntentions = sender.isSelected ? .didTapPauseButton : .didTapPlayButton
//        self.logicController.handle(intent: intent, stateHandler: renderHandler)
//    }
//
//    @IBAction func muteUnmuteButtonPressed(_ sender: UIButton) {
//        let intent: VideoEditorVCIntentions = sender.isSelected ? .didTapUnmuteButton : .didTapMuteButton
//        self.logicController.handle(intent: intent, stateHandler: renderHandler)
//    }
//
//    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
//        let intent = VideoEditorVCIntentions.didTapContinueButton(playerViewFrame: self.playerView.bounds,
//                                                                  playerViewTransform: self.playerView.transform,
//                                                                  playerViewAdjustedOrigin: self.playerView.transformAdjustTopLeft,
//                                                                  cropViewFrame: self.cropView.frame,
//                                                                  viewController: self)
//        self.logicController.handle(intent: intent, stateHandler: renderHandler)
//    }
//}
//
//extension VideoEditorViewController: TimelineViewDelegate {
//    public func isScrolling() {
//        self.logicController.handle(intent: .didStartScrolling, stateHandler: renderHandler)
//    }
//
//    public func endScrolling() {}
//
//    public func didChangeStartAndEndTime(to time: (startTime: Double, endTime: Double)) {
//        self.logicController.handle(intent: .didScroll(to: time), stateHandler: renderHandler)
//    }
//}
//
//extension VideoEditorViewController {
//    private struct Constants {
//        static let SendWithAudioOnText = "Send with audio on"
//        static let SendWithAudioOffText = "Send with audio off"
//        static let ExportErrorTitle = "Error"
//        static let ExportErrorMessage = "Something went wrong..."
//    }
//}
//extension VideoEditorViewController: StoryboardRepresentable {
//    static var storyboardName: String {
//        return "VideoEditor"
//    }
//}
//
//extension UIViewController {
//    public func dch_checkDeallocation(afterDelay delay: TimeInterval = 2.0) {
//        let rootParentViewController = dch_rootParentViewController
//
//        // We don’t check `isBeingDismissed` simply on this view controller because it’s common
//        // to wrap a view controller in another view controller (e.g. in UINavigationController)
//        // and present the wrapping view controller instead.
//        if isMovingFromParent || rootParentViewController.isBeingDismissed {
//            let selfType = type(of: self)
//            let disappearanceSource: String = isMovingFromParent ? "removed from its parent" : "dismissed"
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: { [weak self] in
//                assert(self == nil, "\(selfType) not deallocated after being \(disappearanceSource)")
//            })
//        }
//    }
//
//    private var dch_rootParentViewController: UIViewController {
//        var root = self
//
//        while let parent = root.parent {
//            root = parent
//        }
//
//        return root
//    }
//}
