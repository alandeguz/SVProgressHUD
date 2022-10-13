//
//  ViewController.swift
//  SVProgressHUDDemo
//
//  Created by Alan DeGuzman on 10/4/22.
//

import UIKit
import SVProgressHUD

class ViewController: UIViewController {
  
  private let keyPathActivityCount = "activityCount"
  var activityCount = 0
  
  @IBOutlet weak var popActivityButton: UIButton!
  // MARK: - ViewController lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    activityCount = 0
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    let names: [Notification.Name] = [
      SVProgressHUD.willAppearNotification,
      SVProgressHUD.didAppearNotification,
      SVProgressHUD.willDisappearNotification,
      SVProgressHUD.didDisappearNotification,
      SVProgressHUD.didReceiveTouchEventNotification]
    
    for name in names {
      NotificationCenter.default.addObserver(self,
                                             selector: #selector(self.handleNotification(_:)),
                                             name: name,
                                             object: nil)
    }
    addObserver(self, forKeyPath: keyPathActivityCount, options: .new, context: nil)
  }
  
  // MARK: - Notification handling

  @objc func handleNotification(_ notification: Notification) {
    if notification.name == SVProgressHUD.didReceiveTouchEventNotification {
      sampleDismiss()
    }
  }
  
  // MARK: - Show Methods Sample
  
  @IBAction func show(sender: Any?) {
    SVProgressHUD.show()
    activityCount += 1
  }
  
  @IBAction func showWithStatus( sender: Any?) {
    SVProgressHUD.showWithStatus("Doing Stuff")
    activityCount += 1
  }

  static var progress: CGFloat = 0
  
  @IBAction func showWithProgress(_ sender: Any?) {
    Self.progress = 0
    SVProgressHUD.showProgress(0, status: "Loading")
    perform(#selector(increaseProgress), with: nil, afterDelay: 0.1)
    activityCount += 1
  }
  
  @objc func increaseProgress() {
    Self.progress += 0.05
    SVProgressHUD.showProgress(Self.progress, status: "Loading")
    
    if Self.progress < 1 {
      perform(#selector(increaseProgress), with: nil, afterDelay: 0.1)
    } else {
      if activityCount > 1 {
        perform(#selector(popActivity), with: nil, afterDelay: 0.4)
      } else {
        perform(#selector(sampleDismiss), with: nil, afterDelay: 0.4)
      }
    }
  }
  
  @IBAction func sampleDismiss() {
    SVProgressHUD.dismiss()
    activityCount = 0
  }
  
  @IBAction func popActivity() {
    SVProgressHUD.popActivity()
    
    if activityCount != 0 {
      activityCount -= 1
    }
  }
  
  @IBAction func showInfoWithStatus(_ sender: Any) {
    SVProgressHUD.showInfoWithStatus("Useful Information.")
    activityCount += 1
  }
  
  @IBAction func showSuccessWithStatus(_ sender: Any) {
    SVProgressHUD.showSuccessWithStatus("Great Success!")
    activityCount += 1
  }
  
  @IBAction func showErrorWithStatus(_ sender: Any) {
    SVProgressHUD.showErrorWithStatus("Failed with Errorx")
    activityCount += 1
  }
  
  // MARK: - Styling
  
  @IBAction func changeStyle(_ sender: Any) {
    guard let segmentedControl = sender as? UISegmentedControl else { return }
    if segmentedControl.selectedSegmentIndex == 0 {
      SVProgressHUD.setDefaultStyle(.light)
    } else {
      SVProgressHUD.setDefaultStyle(.dark)
    }
  }
  
  @IBAction func changeAnimationType(_ sender: Any) {
    guard let segmentedControl = sender as? UISegmentedControl else { return }
    if segmentedControl.selectedSegmentIndex == 0 {
      SVProgressHUD.setDefaultAnimationType(.flat)
    } else {
      SVProgressHUD.setDefaultAnimationType(.native)
    }
  }
  
  @IBAction func changeMaskType(_ sender: Any) {
    guard let segmentedControl = sender as? UISegmentedControl else { return }
    switch segmentedControl.selectedSegmentIndex {
    case 0:
      SVProgressHUD.setDefaultMaskType(.none)
    case 1:
      SVProgressHUD.setDefaultMaskType(.clear)
    case 2:
      SVProgressHUD.setDefaultMaskType(.black)
    case 3:
      SVProgressHUD.setDefaultMaskType(.gradient)
    default:
      SVProgressHUD.setBackgroundLayerColor(UIColor.red.withAlphaComponent(0.4))
      SVProgressHUD.setDefaultMaskType(.custom)
    }
  }
  
  // MARK: - Helper
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?,
                                   context: UnsafeMutableRawPointer?) {
    if keyPath == "activityCount" {
      let activityCount = change?[.newKey]
      popActivityButton?.setTitle("popActivity - \(String(describing: activityCount))", for: .normal)
    }
  
  }
  
}

