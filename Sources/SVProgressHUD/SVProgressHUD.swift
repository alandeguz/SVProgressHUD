//
//  SVProgressHUD.swift
//
//
//  Created by Alan DeGuzman on 10/3/22.
//

import UIKit

@available(iOS 13.0, *)
public class SVProgressHUD: UIView {
  
  public static let didReceiveTouchEventNotification = Notification.Name(rawValue: "SVProgressHUDDidReceiveTouchEventNotification")
  public static let didTouchDownInsideNotification = Notification.Name(rawValue: "SVProgressHUDDidTouchDownInsideNotification")
  public static let willDisappearNotification = Notification.Name(rawValue: "SVProgressHUDWillDisappearNotification")
  public static let didDisappearNotification = Notification.Name(rawValue: "SVProgressHUDDidDisappearNotification")
  public static let willAppearNotification = Notification.Name(rawValue: "SVProgressHUDWillAppearNotification")
  public static let didAppearNotification = Notification.Name(rawValue: "SVProgressHUDDidAppearNotification")
  
  public enum MaskType {
    case none     // default mask type, allow user interactions while HUD is displayed
    case clear    // don't allow user interactions with background objects
    case black    // don't allow user interactions with background objects and dim the UI in the back of the HUD (as seen in iOS 7 and above)
    case gradient // don't allow user interactions with background objects and dim the UI with a a-la UIAlertView background gradient (as seen in iOS 6)
    case custom   // don't allow user interactions with background objects and dim the UI in the back of the HUD with a custom color
  }
  
  public enum Style {
    case light   // default style, white HUD with black text, HUD background will be blurred
    case dark // black HUD and white text, HUD background will be blurred
    case custom // uses the fore- and background color properties
  }
  
  public enum AnimationType {
    case flat // default animation type, custom flat animation (indefinite animated ring)
    case native // iOS native UIActivityIndicatorView
  }
  
  public typealias SVProgressHUDShowCompletion = () -> Void
  public typealias SVProgressHUDDismissCompletion = () -> Void
  
  let SVProgressHUDStatusUserInfoKey = "SVProgressHUDStatusUserInfoKey"
  
  static let SVProgressHUDParallaxDepthPoints: CGFloat = 10
  static let SVProgressHUDUndefinedProgress: CGFloat = -1
  static let SVProgressHUDDefaultAnimationDuration: CGFloat = 0.15
  static let SVProgressHUDVerticalSpacing: CGFloat = 12
  static let SVProgressHUDHorizontalSpacing: CGFloat = 12
  static let SVProgressHUDLabelSpacing: CGFloat = 8
  
  var defaultMaskType: MaskType = .none
  var defaultStyle: Style = .light
  var defaultAnimationType: AnimationType = .flat
  
  var containerView: UIView?
  
  var minimumSize: CGSize = .zero
  var ringThickness: CGFloat = 2
  var ringRadius: CGFloat = 18
  var ringNoTextRadius: CGFloat = 24
  var cornerRadius: CGFloat = 14
  var font: UIFont = .preferredFont(forTextStyle: .subheadline)
  var aBackgroundColor: UIColor = .clear
  var foregroundColor: UIColor = .white
  var foregroundImageColor: UIColor?
  var backgroundLayerColor: UIColor = .init(white: 0, alpha: 0.4)
  var imageViewSize: CGSize = .init(width: 28, height: 28)
  var shouldTintImages: Bool = true
  var infoImage: UIImage = SVImageResource.info.getImage().unsafelyUnwrapped
  var successImage: UIImage = SVImageResource.success.getImage().unsafelyUnwrapped
  var errorImage: UIImage = SVImageResource.error.getImage().unsafelyUnwrapped
  var graceTimeInterval: TimeInterval = 0
  var minimumDismissTimeInterval: TimeInterval = 5
  var maximumDismissTimeInterval: TimeInterval = CGFLOAT_MAX
  var offsetFromCenter: UIOffset = .init(horizontal: 0, vertical: 0)
  var fadeInAnimationDuration: TimeInterval = 0.15
  var fadeOutAnimationDuration: TimeInterval = 0.15
  var maxSupportedWindowLevel: UIWindow.Level = .normal
  var hapticsEnabled = false
  var motionEffectEnabled = true
  
  private lazy var internalControlView: UIControl = {
    let control = UIControl()
    control.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    control.backgroundColor = .clear
    control.isUserInteractionEnabled = true
    control.addTarget(self, action: #selector(controlViewDidReceiveTouchEvent(_:forEvent:)), for: .touchDown)
    return control
  }()
  
  private var fadeOutTimer: Timer? {
    didSet {
      oldValue?.invalidate()
    }
  }
  
  private var graceTimer: Timer? {
    didSet {
      oldValue?.invalidate()
    }
  }
  
  private var activityCount = 0
  
  private lazy var internalImageView: UIImageView = {
    return UIImageView(frame: CGRect(origin: .zero, size: self.imageViewSize))
  }()
  
  private var internalStatusLabel: UILabel = {
    let label = UILabel(frame: .zero)
    label.backgroundColor = .clear
    label.adjustsFontSizeToFitWidth = true
    label.textAlignment = .center
    label.baselineAdjustment = .alignBaselines
    label.numberOfLines = 0
    label.alpha = 0
    return label
  }()
  
  private var progress: CGFloat = 0
  private var internalIndefiniteAnimatedView: UIView?
  
  private lazy var internalRingView: SVProgressAnimatedView = {
    let view = SVProgressAnimatedView(frame: .zero)
    view.alpha = 0
    self.backgroundRingView.alpha = 0
    return view
  }()
  
  private lazy var internalBackgroundRingView: SVProgressAnimatedView = {
    let view = SVProgressAnimatedView(frame: .zero)
    view.strokeEnd = 1
    return view
  }()
  
  private lazy var internalBackgroundView: UIView = {
    let view = UIView()
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.alpha = 0
    return view
  }()
  
  private var backgroundRadialGradientLayer: SVRadialGradientLayer?
  
  private lazy var internalHudView: UIVisualEffectView = {
    let view = UIVisualEffectView()
    view.layer.masksToBounds = true
    view.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin, .flexibleRightMargin, .flexibleLeftMargin]
    return view
  }()
  
  private var hudViewCustomBlurEffect: UIBlurEffect?
  
  private var internalHapticGenerator: UINotificationFeedbackGenerator?
  
  
  public private(set) var text = "Hello, World!"
  
  static let sharedView = SVProgressHUD()
  
  // MARK: - Setters
  
  public static func setStatus(_ status: String) {
    sharedView.setStatus(status)
  }
  
  public static func setDefaultStyle(_ style: Style) {
    sharedView.defaultStyle = style
  }
  
  public static func setDefaultMaskType(_ maskType: MaskType) {
    sharedView.defaultMaskType = maskType
  }
  
  public static func setDefaultAnimationType(_ animationType: AnimationType) {
    sharedView.defaultAnimationType = animationType
  }
  
  public static func setBackgroundColor(_ color: UIColor) {
    sharedView.backgroundColor = color
    sharedView.defaultStyle = .custom
  }
  
  public static func setContainerView(_ containerView: UIView?) {
    sharedView.containerView = containerView
  }
  
  public static func setMinimumSize(_ minimumSize: CGSize) {
    sharedView.minimumSize = minimumSize
  }
  
  public static func setRingThickness(_ ringThickness: CGFloat) {
    sharedView.ringThickness = ringThickness
  }
  
  public static func setRingRadius(_ radius: CGFloat) {
    sharedView.ringRadius = radius
  }
  
  public static func setRingNoTextRadius(_ radius: CGFloat) {
    sharedView.ringNoTextRadius = radius
  }
  
  public static func setCornerRadius(_ cornerRadius: CGFloat) {
    sharedView.cornerRadius = cornerRadius
  }
  
  public static func setBorderColor(_ color: UIColor) {
    sharedView.hudView.layer.borderColor = color.cgColor
  }
  
  public static func setBorderWidth(_ width: CGFloat) {
    sharedView.hudView.layer.borderWidth = width
  }
  
  public static func setFont(_ font: UIFont) {
    sharedView.font = font
  }
  
  public static func setForegroundColor(_ color: UIColor) {
    sharedView.foregroundColor = color
    setDefaultStyle(.custom)
  }
  
  public static func setForegroundImageColor(_ color: UIColor) {
    sharedView.foregroundImageColor = color
    setDefaultStyle(.custom)
  }
  
  public static func setHudViewCustomBlurEffect(_ blurEffect: UIBlurEffect) {
    sharedView.hudViewCustomBlurEffect = blurEffect
    setDefaultStyle(.custom)
  }
  
  public static func setBackgroundLayerColor(_ color: UIColor) {
    sharedView.backgroundLayerColor = color
  }
  
  public static func setImageViewSize(_ size: CGSize) {
    sharedView.imageViewSize = size
  }
  
  public static func setShouldTintImages(_ shouldTintImages: Bool) {
    sharedView.shouldTintImages = shouldTintImages
  }
  
  public static func setInfoImage(_ image: UIImage) {
    sharedView.infoImage = image
  }
  
  public static func setSuccessImage(_ image: UIImage) {
    sharedView.successImage = image
  }
  
  public static func setErrorImage(_ image: UIImage) {
    sharedView.errorImage = image
  }
  
  public static func setGraceTimeInterval(_ interval: TimeInterval) {
    sharedView.graceTimeInterval = interval
  }
  
  public static func setMinimumDismissTimeInterval(_ interval: TimeInterval) {
    sharedView.minimumDismissTimeInterval = interval
  }
  
  public static func setMaximumDismissTimeInterval(_ interval: TimeInterval) {
    sharedView.maximumDismissTimeInterval = interval
  }
  
  public static func setFadeInAnimationDuration(_ interval: TimeInterval) {
    sharedView.fadeInAnimationDuration = interval
  }
  
  public static func setFadeOutAnimationDuration(_ interval: TimeInterval) {
    sharedView.fadeOutAnimationDuration = interval
  }
  
  public static func setMaxSupportedWindowLevel(_ windowLevel: UIWindow.Level) {
    sharedView.maxSupportedWindowLevel = windowLevel
  }
  
  public static func setHapticsEnabled(_ hapticsEnabled: Bool) {
    sharedView.hapticsEnabled = hapticsEnabled
  }
  
  public static func setMotionEffectEnabled(_ motionEffectEnabled: Bool) {
    sharedView.motionEffectEnabled = motionEffectEnabled
  }
  
  // MARK: - Show Methods
  
  public static func show() {
    showWithStatus(nil)
  }
  
  public static func showWithMaskType(_ maskType: MaskType) {
    let existingMaskType = sharedView.defaultMaskType
    setDefaultMaskType(maskType)
    show()
    setDefaultMaskType(existingMaskType)
  }
  
  public static func showWithStatus(_ status: String?) {
    showProgress(Self.SVProgressHUDUndefinedProgress, status: status)
  }
  
  public static func showWithStatus(_ status: String?, maskType: MaskType) {
    let existingMaskType = sharedView.defaultMaskType
    setDefaultMaskType(maskType)
    showWithStatus(status)
    setDefaultMaskType(existingMaskType)
  }
  
  public static func showProgress(_ progress: CGFloat) {
    showProgress(progress, status: nil)
  }
  
  public static func showProgress(_ progress: CGFloat, maskType: MaskType) {
    let existingMaskType = sharedView.defaultMaskType
    setDefaultMaskType(maskType)
    showProgress(progress)
    setDefaultMaskType(existingMaskType)
  }
  
  public static func showProgress(_ progress: CGFloat, status: String?) {
    sharedView.showProgress(progress, status: status)
  }
  
  public static func showProgress(_ progress: CGFloat, status: String?, maskType: MaskType) {
    let existingMaskType = sharedView.defaultMaskType
    setDefaultMaskType(maskType)
    sharedView.showProgress(progress, status: status)
    setDefaultMaskType(existingMaskType)
  }
  
  // MARK: - Show, then automatically dismiss methods
  
  public static func showInfoWithStatus(_ status: String?) {
    showImage(sharedView.infoImage, status: status)
    DispatchQueue.main.async {
      sharedView.hapticGenerator?.notificationOccurred(.warning)
    }
  }
  
  public static func showInfoWithStatus(_ status: String?, maskType: MaskType) {
    let existingMaskType = sharedView.defaultMaskType
    setDefaultMaskType(maskType)
    showInfoWithStatus(status)
    setDefaultMaskType(existingMaskType)
  }
  
  public static func showSuccessWithStatus(_ status: String?) {
    showImage(sharedView.successImage, status: status)
    DispatchQueue.main.async {
      sharedView.hapticGenerator?.notificationOccurred(.warning)
    }
  }
  
  public static func showSuccessWithStatus(_ status: String?, maskType: MaskType) {
    let existingMaskType = sharedView.defaultMaskType
    setDefaultMaskType(maskType)
    showSuccessWithStatus(status)
    setDefaultMaskType(existingMaskType)
    DispatchQueue.main.async {
      sharedView.hapticGenerator?.notificationOccurred(.warning)
    }
  }
  
  public static func showErrorWithStatus(_ status: String?) {
    showImage(sharedView.errorImage, status: status)
    DispatchQueue.main.async {
      sharedView.hapticGenerator?.notificationOccurred(.warning)
    }
  }
  
  public static func showErrorWithStatus(_ status: String?, maskType: MaskType) {
    let existingMaskType = sharedView.defaultMaskType
    setDefaultMaskType(maskType)
    showErrorWithStatus(status)
    setDefaultMaskType(existingMaskType)
    DispatchQueue.main.async {
      sharedView.hapticGenerator?.notificationOccurred(.warning)
    }
  }
  
  public static func showImage(_ image: UIImage, status: String?) {
    let displayInterval = Self.displayDuration(for: status)
    sharedView.showImage(image, status: status, duration: displayInterval)
  }
  
  public static func showImage(_ image: UIImage, status: String?, maskType: MaskType) {
    let existingMaskType = sharedView.defaultMaskType
    setDefaultMaskType(maskType)
    showImage(image, status: status)
    setDefaultMaskType(existingMaskType)
  }
  
  // MARK: - Dismiss Methods
  
  public static func popActivity() {
    if sharedView.activityCount > 0 {
      sharedView.activityCount -= 1
    }
    if sharedView.activityCount == 0 {
      sharedView.dismiss()
    }
  }
  
  public static func dismiss() {
    Self.dismissWithDelay(0, completion: nil)
  }
  
  public static func dismissWithCompletion(_ completion: SVProgressHUDDismissCompletion?) {
    Self.dismissWithDelay(0, completion: completion)
  }
  
  public static func dismissWithDelay(_ delay: TimeInterval) {
    Self.dismissWithDelay(delay, completion: nil)
  }
  
  public static func dismissWithDelay(_ delay: TimeInterval, completion: SVProgressHUDDismissCompletion?) {
    sharedView.dismissWithDelay(delay, completion: completion)
  }
  
  // MARK: - Offset
  
  public static func setOffsetFromCenter(_ offset: UIOffset) {
    Self.sharedView.offsetFromCenter = offset
  }
  
  public static func resetOffsetFromCenter() {
    Self.setOffsetFromCenter(.zero)
  }
  
  // MARK: - Instance Methods
  
  convenience init() {
    self.init(frame: UIScreen.main.bounds)
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    self.accessibilityIdentifier = "SVProgressHUD"
    self.isAccessibilityElement = true
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func updateHUDFrame() {
    // Check if an image or progress ring is displayed
    let imageUsed = imageView.image != nil && !imageView.isHidden
    let progressUsed = imageView.isHidden
    
    // Calculate size of string
    var labelRect: CGRect = .zero
    var labelHeight: CGFloat = 0
    var labelWidth: CGFloat  = 0
    
    if let slText = statusLabel.text, !slText.isEmpty {
      let constraintSize = CGSize(width: 200, height: 200)
      labelRect = slText.boundingRect(with: constraintSize,
                                      options: [.usesFontLeading, .truncatesLastVisibleLine, .usesLineFragmentOrigin],
                                      attributes: [NSAttributedString.Key.font: statusLabel.font as Any],
                                      context: nil)
      
      labelHeight = CGFloat(ceil(CGRectGetHeight(labelRect)))
      labelWidth = CGFloat(ceil(CGRectGetWidth(labelRect)))
    }
    
    // Calculate hud size based on content
    // For the beginning use default values, these
    // might get update if string is too large etc.
    var hudWidth: CGFloat = 0
    var hudHeight: CGFloat = 0
    
    var contentWidth: CGFloat = 0
    var contentHeight: CGFloat = 0
    
    if let indViewFrame = indefiniteAnimatedView?.frame, imageUsed || progressUsed {
      contentWidth = CGRectGetWidth(imageUsed ? imageView.frame : indViewFrame)
      contentHeight = CGRectGetHeight(imageUsed ? imageView.frame : indViewFrame)
    }
    
    // |-spacing-content-spacing-|
    hudWidth = Self.SVProgressHUDHorizontalSpacing + [labelWidth, contentWidth].theMax() + Self.SVProgressHUDHorizontalSpacing
    
    // |-spacing-content-(labelSpacing-label-)spacing-|
    hudHeight = Self.SVProgressHUDVerticalSpacing + labelHeight + contentHeight + Self.SVProgressHUDVerticalSpacing
    if hasStatusText && (imageUsed || progressUsed) {
      // Add spacing if both content and label are used
      hudHeight += Self.SVProgressHUDLabelSpacing
    }
    
    // Update values on subviews
    self.hudView.bounds = CGRectMake(0, 0, [minimumSize.width, hudWidth].theMax(), [minimumSize.height, hudHeight].theMax())
    
    // Animate value update
    CATransaction.begin()
    
    CATransaction.setDisableActions(true)
    
    // Spinner and image view
    var centerY: CGFloat = 0
    if hasStatusText {
      let yOffset: CGFloat = [Self.SVProgressHUDVerticalSpacing, (minimumSize.height - contentHeight - Self.SVProgressHUDLabelSpacing - labelHeight) / 2].theMax()
      centerY = yOffset + contentHeight / 2
    } else {
      centerY = CGRectGetMidY(hudView.bounds)
    }
    indefiniteAnimatedView?.center = CGPointMake(CGRectGetMidX(hudView.bounds), centerY)
    if progress != Self.SVProgressHUDUndefinedProgress {
      backgroundRingView.center = CGPointMake(CGRectGetMidX(hudView.bounds), centerY)
      ringView.center = CGPointMake(CGRectGetMidX(hudView.bounds), centerY)
    }
    imageView.center = CGPointMake(CGRectGetMidX(hudView.bounds), centerY)
    
    // Label
    if let idefViewFrame = indefiniteAnimatedView?.frame, imageUsed || progressUsed {
      centerY = CGRectGetMaxY(imageUsed ? imageView.frame : idefViewFrame) + Self.SVProgressHUDLabelSpacing + labelHeight / 2
    } else {
      centerY = CGRectGetMidY(hudView.bounds)
    }
    statusLabel.frame = labelRect
    statusLabel.center = CGPointMake(CGRectGetMidX(hudView.bounds), centerY)
    
    CATransaction.commit()
  }
  
  func updateMotionEffectForOrientation(_ orientation: UIInterfaceOrientation) {
    let xType: UIInterpolatingMotionEffect.EffectType = orientation.isPortrait ? .tiltAlongHorizontalAxis : .tiltAlongVerticalAxis
    let yType: UIInterpolatingMotionEffect.EffectType = orientation.isPortrait ? .tiltAlongVerticalAxis : .tiltAlongHorizontalAxis
    updateMotionEffectForXMotionEffectType(xType, yMotionEffectType: yType)
  }
  
  func updateMotionEffectForXMotionEffectType(_ xMotionEffectType: UIInterpolatingMotionEffect.EffectType, yMotionEffectType: UIInterpolatingMotionEffect.EffectType) {
    let effectX = UIInterpolatingMotionEffect(keyPath: "center.x", type: xMotionEffectType)
    effectX.minimumRelativeValue = -Self.SVProgressHUDParallaxDepthPoints
    effectX.maximumRelativeValue = Self.SVProgressHUDParallaxDepthPoints
    
    let effectY = UIInterpolatingMotionEffect(keyPath: "center.y", type: yMotionEffectType)
    effectY.minimumRelativeValue = -Self.SVProgressHUDParallaxDepthPoints
    effectY.maximumRelativeValue = Self.SVProgressHUDParallaxDepthPoints
    
    let effectGroup = UIMotionEffectGroup()
    effectGroup.motionEffects = [effectX, effectY]
    
    // Clear old motion effect, then add new motion effects
    hudView.motionEffects = []
    hudView.addMotionEffect(effectGroup)
  }
  
  func updateViewHierarchy() {
    // Add the overlay to the application window if necessary
    if controlView.superview == nil {
      if containerView != nil {
        containerView?.addSubview(controlView)
      } else {
        frontWindow?.addSubview(controlView)
      }
    } else {
      // The HUD is already on screen, but maybe not in front. Therefore
      // ensure that overlay will be on top of rootViewController (which may
      // be changed during runtime).
      controlView.superview?.bringSubviewToFront(controlView)
    }
    
    // Add to the overlay view
    if superview == nil {
      controlView.addSubview(self)
    }
  }
  
  func setStatus(_ status: String) {
    statusLabel.text = status
    statusLabel.isHidden = status.isEmpty
    updateHUDFrame()
  }
  
  // MARK: - Notifications and their handling
  
  func registerNotifications() {
    let names: [Notification.Name] = [
      UIApplication.didChangeStatusBarOrientationNotification,
      UIResponder.keyboardWillHideNotification,
      UIResponder.keyboardDidHideNotification,
      UIResponder.keyboardWillShowNotification,
      UIResponder.keyboardDidShowNotification,
      UIApplication.didBecomeActiveNotification
    ]
    
    for name in names {
      NotificationCenter.default.addObserver(self, selector: #selector(positionHUD(_:)), name: name, object: nil)
    }
  }
  
  var notificationUserInfo: [String: String]? {
    if let text = statusLabel.text, !text.isEmpty {
      return [SVProgressHUDStatusUserInfoKey: text]
    }
    return nil
  }
  
  @objc func positionHUD(_ notifi: Notification?) {
    var keyboardHeight: CGFloat = 0
    let animationDuration: Double = 0
    frame = UIApplication.shared.delegate?.window??.bounds ?? frame
    let orientation = UIApplication.shared.statusBarOrientation
    
    if let notification = notifi, let keyboardInfo = notification.userInfo, let keyboardFrame = keyboardInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect {
      if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardDidShowNotification {
        keyboardHeight = CGRectGetWidth(keyboardFrame)
        if orientation.isPortrait {
          keyboardHeight = CGRectGetHeight(keyboardFrame)
        }
      }
    } else {
      keyboardHeight = visibleKeyboardHeight
    }
    
    // Get the currently active frame of the display (depends on orientation)
    let orientationFrame = bounds
    let statusBarFrame = UIApplication.shared.statusBarFrame
    
    if motionEffectEnabled {
      updateMotionEffectForOrientation(orientation)
      updateMotionEffectForXMotionEffectType(.tiltAlongHorizontalAxis, yMotionEffectType: .tiltAlongHorizontalAxis)
    }
    
    // Calculate available height for display
    var activeHeight = CGRectGetHeight(orientationFrame)
    if keyboardHeight > 0 {
      activeHeight += CGRectGetHeight(statusBarFrame) * 2
    }
    activeHeight -= keyboardHeight
    
    let posX = CGRectGetMidX(orientationFrame)
    let posY = CGFloat(floorf(Float(activeHeight) * 0.45))
    
    let rotateAngle: CGFloat = 0
    let newCenter = CGPointMake(posX, posY)
    
    if notifi != nil {
      // Animate update if notification was present
      UIView.animate(withDuration: animationDuration,
                     delay: 0,
                     options: [.allowUserInteraction, .beginFromCurrentState],
                     animations: {
        self.moveToPoint(newCenter, rotateAngle: rotateAngle)
        self.hudView.setNeedsDisplay()
      },
                     completion: nil)
    } else {
      moveToPoint(newCenter, rotateAngle: rotateAngle)
    }
  }
  
  func moveToPoint(_ newCenter: CGPoint, rotateAngle angle: CGFloat) {
    hudView.transform = CGAffineTransformMakeRotation(angle)
    if let contain = containerView {
      hudView.center = CGPointMake(contain.center.x + offsetFromCenter.horizontal, contain.center.y + offsetFromCenter.vertical)
    } else {
      hudView.center = CGPointMake(newCenter.x + offsetFromCenter.horizontal, newCenter.y + offsetFromCenter.vertical)
    }
  }
  
  // MARK: - Event handling
  
  @objc public func controlViewDidReceiveTouchEvent(_ sender: Any?, forEvent event: UIEvent) {
    NotificationCenter
      .default
      .post(name: SVProgressHUD.didReceiveTouchEventNotification, object: self, userInfo: notificationUserInfo)
    
    if let touchLocation = event.allTouches?.first?.location(in: self), CGRectContainsPoint(hudView.frame, touchLocation) {
      NotificationCenter
        .default
        .post(name: SVProgressHUD.didTouchDownInsideNotification, object: self, userInfo: notificationUserInfo)
    }
  }
  
  // MARK: - Master show/dismiss methods
  
  func showImage(_ image: UIImage, status: String?, duration: TimeInterval) {
    weak var weakSelf = self
    OperationQueue
      .main
      .addOperation {
        guard let strongSelf = weakSelf else { return }
        // Stop timer
        strongSelf.fadeOutTimer = nil
        strongSelf.graceTimer = nil
        
        // Update / Check view hierarchy to ensure the HUD is visible
        strongSelf.updateViewHierarchy()
        
        // Reset progress and cancel any running animation
        strongSelf.progress = Self.SVProgressHUDUndefinedProgress
        strongSelf.cancelRingLayerAnimation()
        strongSelf.cancelIndefiniteAnimatedViewAnimation()
        
        // Update imageView
        if self.shouldTintImages {
          if image.renderingMode != .alwaysTemplate {
            strongSelf.imageView.image = image.withRenderingMode(.alwaysTemplate)
          } else {
            strongSelf.imageView.image = image
          }
          strongSelf.imageView.tintColor = strongSelf.foregroundImageColorForStyle
        } else {
          strongSelf.imageView.image = image
        }
        strongSelf.imageView.isHidden = false
        
        // Update text
        strongSelf.statusLabel.isHidden = status?.isEmpty ?? true
        strongSelf.statusLabel.text = status
        
        // Fade in delayed if a grace time is set
        // An image will be dismissed automatically. Thus pass the duration as userInfo.
        if self.graceTimeInterval > 0 && self.backgroundView.alpha == 0 {
          let timer = Timer(timeInterval: self.graceTimeInterval,
                            target: strongSelf,
                            selector: #selector(strongSelf.dofadein(_:)),
                            userInfo: nil,
                            repeats: false)
          
          strongSelf.graceTimer = timer
          RunLoop.main.add(timer, forMode: .common)
        } else {
          strongSelf.dofadein(NSNumber(value: duration))
        }
      }
  }
  
  func showProgress(_ progress: CGFloat, status: String?) {
    weak var weakSelf = self
    OperationQueue
      .main
      .addOperation {
        guard let strongSelf = weakSelf else { return }
        if strongSelf.fadeOutTimer != nil {
          strongSelf.activityCount = 0
        }
        
        // Stop timer
        strongSelf.fadeOutTimer = nil
        strongSelf.graceTimer = nil
        
        // Update / Check view hierarchy to ensure the HUD is visible
        strongSelf.updateViewHierarchy()
        
        // Reset imageView and fadeout timer if an image is currently displayed
        strongSelf.imageView.isHidden = true
        strongSelf.imageView.image = nil
        
        // Update text and set progress to the given value
        strongSelf.statusLabel.isHidden = status?.isEmpty ?? true
        strongSelf.statusLabel.text = status
        strongSelf.progress = progress
        
        // Choose the "right" indicator depending on the progress
        if progress >= 0 {
          // Cancel the indefiniteAnimatedView, then show the ringLayer
          strongSelf.cancelIndefiniteAnimatedViewAnimation()
          
          // Add ring to HUD
          if strongSelf.ringView.superview == nil {
            strongSelf.hudView.contentView.addSubview(strongSelf.ringView)
          }
          if strongSelf.backgroundRingView.superview == nil {
            strongSelf.hudView.contentView.addSubview(strongSelf.backgroundRingView)
          }
          
          // Set progress animated
          CATransaction.begin()
          CATransaction.setDisableActions(true)
          strongSelf.ringView.strokeEnd = CGFloat(progress)
          CATransaction.commit()
          
          // Update the activity count
          if progress == 0 {
            strongSelf.activityCount += 1
          }
        } else {
          // Cancel the ringLayer animation, then show the indefiniteAnimatedView
          strongSelf.cancelRingLayerAnimation()
          
          // Add indefiniteAnimatedView to HUD
          if let inView = strongSelf.indefiniteAnimatedView {
            strongSelf.hudView.contentView.addSubview(inView)
            if let view = inView as? UIActivityIndicatorView {
              view.startAnimating()
            }
          }
          
          // Update the activity count
          strongSelf.activityCount += 1
        }
        
        // Fade in delayed if a grace time is set
        if strongSelf.graceTimeInterval > 0 && strongSelf.backgroundView.alpha == 0 {
          let timer = Timer(timeInterval: self.graceTimeInterval,
                            target: strongSelf,
                            selector: #selector(strongSelf.dofadein(_:)),
                            userInfo: nil,
                            repeats: false)
          strongSelf.graceTimer = timer
          RunLoop.main.add(timer, forMode: .common)
        } else {
          strongSelf.dofadein(nil)
        }
        
        // Tell the Haptics Generator to prepare for feedback, which may come soon
        strongSelf.hapticGenerator?.prepare()
      }
  }
  
  @objc func dofadein(_ data: Any?) {
    // Update the HUDs frame to the new content and position HUD
    updateHUDFrame()
    positionHUD(nil)
    
    // Update accessibility as well as user interaction
    // \n cause to read text twice so remove "\n" new line character before setting up accessiblity label
    let accessibilityString = statusLabel.text?.components(separatedBy: CharacterSet.newlines).joined(separator: " ")
    if defaultMaskType != .none {
      controlView.isUserInteractionEnabled = true
      accessibilityLabel = accessibilityString ?? NSLocalizedString("Loading", comment: "")
      isAccessibilityElement = true
      controlView.accessibilityViewIsModal = true
    } else {
      controlView.isUserInteractionEnabled = false
      hudView.accessibilityLabel = accessibilityString ?? NSLocalizedString("Loading", comment: "")
      hudView.isAccessibilityElement = true
      controlView.accessibilityViewIsModal = false
    }
    
    // Get duration
    
    let duration: NSNumber? = {
      if let timer = data as? Timer, let num = timer.userInfo as? NSNumber {
        return num
      }
      return data as? NSNumber
    }()
    
    // Show if not already visible
    if backgroundView.alpha != 1 {
      
      // Post notification to inform user
      NotificationCenter.default.post(name: SVProgressHUD.willAppearNotification, object: notificationUserInfo)
      
      // Zoom HUD a little to to make a nice appear / pop up animation
      hudView.transform = CGAffineTransformScale(hudView.transform, 1.3, 1.3)
      hudView.transform = CGAffineTransformScale(hudView.transform, 1.3, 1.3)
      
      let animationsBlock: (() -> Void) = {
        // Zoom HUD a little to make a nice appear / pop up animation
        self.hudView.transform = CGAffineTransformIdentity
        
        // Fade in all effects (colors, blur, etc.)
        self.fadeInEffects()
      }
      
      let completionBlock: (() -> Void) = {
        // Check if we really achieved to show the HUD (<=> alpha)
        // and the change of these values has not been cancelled in between e.g. due to a dismissal
        if self.backgroundView.alpha == 1 {
          // Register observer <=> we now have to handle orientation changes etc.
          self.registerNotifications()
          
          // Post notification to inform user
          
          NotificationCenter.default.post(name: SVProgressHUD.didAppearNotification, object: self.notificationUserInfo)
          
          // Update accessibility
          UIAccessibility.post(notification: .screenChanged, argument: nil)
          UIAccessibility.post(notification: .announcement, argument: self.statusLabel.text)
          
          // Dismiss automatically if a duration was passed as userInfo. We start a timer
          // which then will call dismiss after the predefined duration
          if let dur = duration {
            let timer = Timer(timeInterval: dur.doubleValue,
                              target: self,
                              selector: #selector(self.dismiss),
                              userInfo: nil,
                              repeats: false)
            self.fadeOutTimer = timer
            RunLoop.main.add(timer, forMode: .common)
          }
        }
      }
      
      // Animate appearance
      if fadeInAnimationDuration > 0 {
        // Animate appearance
        UIView.animate(
          withDuration: fadeInAnimationDuration,
          delay: 0,
          options: [.allowUserInteraction, .curveEaseIn, .beginFromCurrentState],
          animations: { animationsBlock() },
          completion: { _ in completionBlock() })
      } else {
        animationsBlock()
        completionBlock()
      }
      
      // Inform iOS to redraw the view hierarchy
      setNeedsDisplay()
      
    } else {
      // Update accessibility
      
      UIAccessibility.post(notification: .screenChanged, argument: nil)
      UIAccessibility.post(notification: .announcement, argument: self.statusLabel.text)
      
      // Dismiss automatically if a duration was passed as userInfo. We start a timer
      // which then will call dismiss after the predefined duration
      if let dur = duration {
        let timer = Timer(timeInterval: dur.doubleValue,
                          target: self,
                          selector: #selector(self.dismiss),
                          userInfo: nil,
                          repeats: false)
        self.fadeOutTimer = timer
        RunLoop.main.add(timer, forMode: .common)
      }
      
    }
  }
  
  func cancelIndefiniteAnimatedViewAnimation() {
    // Stop animation
    if let view = indefiniteAnimatedView as? UIActivityIndicatorView {
      view.stopAnimating()
    }
    
    // Remove from view
    indefiniteAnimatedView?.removeFromSuperview()
  }
  
  @objc func dismiss() {
    dismissWithDelay(0, completion: nil)
  }
  
  func dismissWithDelay(_ delay: TimeInterval, completion: SVProgressHUDDismissCompletion?) {
    weak var weakSelf = self
    OperationQueue
      .main
      .addOperation {
        guard let strongSelf = weakSelf else { return }
        
        // Post notification to inform user
        NotificationCenter.default.post(name: SVProgressHUD.willDisappearNotification, object: strongSelf.notificationUserInfo)
        
        // Reset activity count
        strongSelf.activityCount = 0
        
        let animationsBlock: (() -> Void) = {
          // Shrink HUD a little to make a nice disappear animation
          strongSelf.hudView.transform = CGAffineTransformScale(strongSelf.hudView.transform, 1 / 1.3, 1 / 1.3)
          
          // Fade out all effects (colors, blur, etc.)
          strongSelf.fadeOutEffects()
        }
        
        let completionBlock: (() -> Void) = {
          // Check if we really achieved to dismiss the HUD (<=> alpha values are applied)
          // and the change of these values has not been cancelled in between e.g. due to a new show
          if self.backgroundView.alpha == 0 {
            // Clean up view hierarchy (overlays)
            strongSelf.controlView.removeFromSuperview()
            strongSelf.backgroundView.removeFromSuperview()
            strongSelf.hudView.removeFromSuperview()
            strongSelf.removeFromSuperview()
            
            // Reset progress and cancel any running animation
            strongSelf.progress = Self.SVProgressHUDUndefinedProgress
            strongSelf.cancelRingLayerAnimation()
            strongSelf.cancelIndefiniteAnimatedViewAnimation()
            
            // Remove observer <=> we do not have to handle orientation changes etc.
            NotificationCenter.default.removeObserver(strongSelf)
            
            // Post notification to inform user
            NotificationCenter.default.post(name: SVProgressHUD.didDisappearNotification, object: strongSelf.notificationUserInfo)
            
            // Tell the rootViewController to update the StatusBar appearance
            UIApplication.shared.keyWindow?.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            
            // Run an (optional) completionHandler
            completion?()
            
          }
        }
        
        // UIViewAnimationOptionBeginFromCurrentState AND a delay doesn't always work as expected
        // When UIViewAnimationOptionBeginFromCurrentState is set, animateWithDuration: evaluates the current
        // values to check if an animation is necessary. The evaluation happens at function call time and not
        // after the delay => the animation is sometimes skipped. Therefore we delay using dispatch_after.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
          
          // Stop timer
          strongSelf.graceTimer = nil
          
          if strongSelf.fadeOutAnimationDuration > 0 {
            // Animate appearance
            UIView.animate(
              withDuration: strongSelf.fadeOutAnimationDuration,
              delay: 0,
              options: [.allowUserInteraction, .curveEaseOut, .beginFromCurrentState],
              animations: { animationsBlock() },
              completion: { _ in completionBlock() })
          } else {
            animationsBlock()
            completionBlock()
          }
        }
        
        // Inform iOS to redraw the view hierarchy
        strongSelf.setNeedsDisplay()
      }
  }
  
  // MARK: - Ring progress animation
  
  var indefiniteAnimatedView: UIView? {
    // Get the correct spinner for defaultAnimationType
    if defaultAnimationType == .flat {
      // Check if spinner exists and is an object of different class
      if let intern = internalIndefiniteAnimatedView, type(of: intern) != SVIndefiniteAnimatedView.self {
        internalIndefiniteAnimatedView?.removeFromSuperview()
        internalIndefiniteAnimatedView = nil
      }
      if internalIndefiniteAnimatedView == nil {
        internalIndefiniteAnimatedView = SVIndefiniteAnimatedView(frame: .zero)
      }
      
      // Update styling
      if let ind = internalIndefiniteAnimatedView as? SVIndefiniteAnimatedView {
        ind.strokeColor = foregroundImageColorForStyle ?? ind.strokeColor
        ind.strokeThickness = ringThickness
        ind.radius = hasStatusText ? ringRadius : ringNoTextRadius
      }
      
    } else {
      // Check if spinner exists and is an object of different class
      if let intern = internalIndefiniteAnimatedView, type(of: intern) != UIActivityIndicatorView.self {
        internalIndefiniteAnimatedView?.removeFromSuperview()
        internalIndefiniteAnimatedView = nil
      }
      
      if internalIndefiniteAnimatedView == nil {
        internalIndefiniteAnimatedView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
      }
      
      // Update styling
      if let ind = internalIndefiniteAnimatedView as? UIActivityIndicatorView {
        ind.color = foregroundImageColorForStyle
      }
    }
    internalIndefiniteAnimatedView?.sizeToFit()
    
    return internalIndefiniteAnimatedView
  }
  
  var ringView: SVProgressAnimatedView {
    // Update styling
    internalRingView.strokeColor = foregroundImageColorForStyle ?? internalRingView.strokeColor
    internalRingView.strokeThickness = ringThickness
    internalRingView.radius = hasStatusText ? ringRadius : ringNoTextRadius
    return internalRingView
  }
  
  var backgroundRingView: SVProgressAnimatedView {
    // Update styling
    internalBackgroundRingView.strokeColor = foregroundImageColorForStyle?.withAlphaComponent(0.1) ?? internalBackgroundRingView.strokeColor
    internalBackgroundRingView.strokeThickness = ringThickness
    internalBackgroundRingView.radius = hasStatusText ? ringRadius : ringNoTextRadius
    return internalBackgroundRingView
  }
  
  func cancelRingLayerAnimation() {
    // Animate value update, stop animation
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    
    hudView.layer.removeAllAnimations()
    ringView.strokeEnd = 0
    
    CATransaction.commit()
    
    // Remove from view
    ringView.removeFromSuperview()
    backgroundRingView.removeFromSuperview()
  }
  
  // MARK: - Utilities
  
  public static func isVisible() -> Bool {
    return Self.sharedView.backgroundView.alpha > 0
  }

  private var hasStatusText: Bool {
    statusLabel.text != nil && statusLabel.text?.isEmpty == false
  }
  
  // MARK: - Getters
  
  static func displayDuration(for string: String?) -> TimeInterval {
    let minimum = max(CGFloat(string?.count ?? 0) * 0.06 + 0.5, Self.sharedView.minimumDismissTimeInterval)
    return min(minimum, Self.sharedView.maximumDismissTimeInterval)
  }
  
  var foregroundColorForStyle: UIColor {
    switch defaultStyle {
    case .light:
      return .black
    case .dark:
      return .white
    default:
      return foregroundColor
    }
  }
  
  var foregroundImageColorForStyle: UIColor? {
    if let foregrouund = foregroundImageColor {
      return foregrouund
    }
    return foregroundColorForStyle
  }
  
  var backgroundColorForStyle: UIColor? {
    switch defaultStyle {
    case .light:
      return .white
    case .dark:
      return .black
    default:
      return backgroundColor
    }
  }
  
  var controlView: UIControl {
    internalControlView.frame = UIScreen.main.bounds
    return internalControlView
  }
  
  var backgroundView: UIView {
    
    if internalBackgroundView.superview == nil {
      insertSubview(internalBackgroundView, belowSubview: hudView)
    }
    
    // Update styling
    if defaultMaskType == .gradient {
      if backgroundRadialGradientLayer == nil {
        backgroundRadialGradientLayer = SVRadialGradientLayer()
      }
      if let brgl = backgroundRadialGradientLayer, brgl.superlayer == nil {
        internalBackgroundView.layer.insertSublayer(brgl, at: 0)
      }
      internalBackgroundView.backgroundColor = .clear
    } else {
      if let brgl = backgroundRadialGradientLayer, brgl.superlayer != nil {
        brgl.removeFromSuperlayer()
      }
      if defaultMaskType == .black {
        internalBackgroundView.backgroundColor = UIColor(white: 0, alpha: 0.4)
      } else if defaultMaskType == .custom {
        internalBackgroundView.backgroundColor = backgroundLayerColor
      } else {
        internalBackgroundView.backgroundColor = .clear
      }
    }
    
    // Update frame
    internalBackgroundView.frame = bounds
    if let brgl = backgroundRadialGradientLayer {
      brgl.frame = bounds
      
      // Calculate the new center of the gradient, it may change if keyboard is visible
      var gradientCenter = center
      gradientCenter.y = (bounds.size.height - visibleKeyboardHeight) / 2
      brgl.gradientCenter = gradientCenter
      brgl.setNeedsDisplay()
    }
    
    return internalBackgroundView
  }
  
  var hudView: UIVisualEffectView {
    if internalHudView.superview == nil {
      addSubview(internalHudView)
    }
    
    // Update styling
    internalHudView.layer.cornerRadius = cornerRadius
    
    return internalHudView
  }
  
  var statusLabel: UILabel {
    if internalStatusLabel.superview == nil {
      hudView.contentView.addSubview(internalStatusLabel)
    }
    
    // Update styling
    internalStatusLabel.textColor = foregroundColorForStyle
    internalStatusLabel.font = font
    
    return internalStatusLabel
  }
  
  var imageView: UIImageView {
    if !CGSizeEqualToSize(internalImageView.bounds.size, imageViewSize) {
      internalImageView.removeFromSuperview()
      internalImageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: imageViewSize))
      internalImageView.alpha = 0
    }
    
    if internalImageView.superview == nil {
      hudView.contentView.addSubview(internalImageView)
    }
    
    return internalImageView
  }
  
  // MARK: - Helper
  
  var visibleKeyboardHeight: CGFloat {
    let keyboardWindow = UIApplication.shared.windows.first { type(of: $0) != UIWindow.self }
    for possibleKeyboard in (keyboardWindow?.subviews ?? []) {
      let viewName = String(describing: type(of: possibleKeyboard))
      guard viewName.hasPrefix("UI") else { continue }
      if viewName.hasSuffix("PeripheralHostView") || viewName.hasSuffix("Keyboard") {
        return CGRectGetHeight(possibleKeyboard.bounds)
      } else if viewName.hasSuffix("InputSetContainerView") {
        for possibleKeyboardSubview in possibleKeyboard.subviews {
          let viewName2 = String(describing: type(of: possibleKeyboardSubview))
          guard viewName2.hasSuffix("UI") || viewName2.hasSuffix("InputSetHostView") else { continue }
          let convertedRect = possibleKeyboard.convert(possibleKeyboardSubview.frame, to: self)
          let intersectedRect = CGRectIntersection(convertedRect, bounds)
          guard !CGRectIsNull(intersectedRect) else { continue }
          return CGRectGetHeight(intersectedRect)
        }
      }
    }
    return 0
  }
  
  var frontWindow: UIWindow? {
    let frontToBackWindows = UIApplication.shared.windows.reversed()
    
    for window in frontToBackWindows {
      let windowOnMainScreen = window.screen == UIScreen.main
      let windowIsVisible = !window.isHidden && window.alpha > 0
      let windowLevelSupported = window.windowLevel >= .normal && window.windowLevel <= maxSupportedWindowLevel
      let windowKeyWindow = window.isKeyWindow
      
      if windowOnMainScreen && windowIsVisible && windowLevelSupported && windowKeyWindow {
        return window
      }
    }
    
    return nil
  }
  
  func fadeInEffects() {
    if defaultStyle != .custom {
      // Add blur effect
      let blurEffectStyle: UIBlurEffect.Style = (defaultStyle == .dark) ? .dark : .light
      let blurEffect = UIBlurEffect(style: blurEffectStyle)
      hudView.effect = blurEffect
      // We omit UIVibrancy effect and use a suitable background color as an alternative.
      // This will make everything more readable. See the following for details:
      // https://www.omnigroup.com/developer/how-to-make-text-in-a-uivisualeffectview-readable-on-any-background
      
      hudView.backgroundColor = backgroundColorForStyle?.withAlphaComponent(0.6)
    } else {
      hudView.effect = hudViewCustomBlurEffect
      hudView.backgroundColor = backgroundColorForStyle
    }
    
    // Fade in views
    backgroundView.alpha = 1
    
    imageView.alpha = 1
    statusLabel.alpha = 1
    indefiniteAnimatedView?.alpha = 1
    ringView.alpha = 1
    backgroundRingView.alpha = 1
  }
  
  func fadeOutEffects() {
    if defaultStyle != .custom {
      // Remove blur effect
      hudView.effect = nil
    }
    
    // Remove background color
    hudView.backgroundColor = .clear
    
    // Fade out views
    backgroundView.alpha = 0
    
    imageView.alpha = 0
    statusLabel.alpha = 0
    indefiniteAnimatedView?.alpha = 0
    ringView.alpha = 0
    backgroundRingView.alpha = 0
  }
  
  var hapticGenerator: UINotificationFeedbackGenerator? {
    // Only return if haptics are enabled
    if !hapticsEnabled {
      return nil
    }
    
    if internalHapticGenerator == nil {
      internalHapticGenerator = UINotificationFeedbackGenerator()
    }
    return internalHapticGenerator
  }
  
  // MARK: - UIAppearance Setters
  
}

extension Array where Element : Comparable {
 
  func theMax() -> Element {
    return max().unsafelyUnwrapped
  }
}
