//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

import Foundation

private class IntroductingReadReceiptsExperienceUpgradeViewController: ExperienceUpgradeViewController {

    var buttonAction: ((UIButton) -> Void)?

    override func loadView() {
        self.view = UIView()

        /// Create Views

        // Title label
        let titleLabel = UILabel()
        view.addSubview(titleLabel)
        titleLabel.text = header
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.ows_regularFont(withSize: ScaleFromIPhone5(24))
        titleLabel.textColor = UIColor.white
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.adjustsFontSizeToFitWidth = true

        // Body label
        let bodyLabel = UILabel()
        self.bodyLabel = bodyLabel
        view.addSubview(bodyLabel)
        bodyLabel.text = body
        bodyLabel.font = UIFont.ows_lightFont(withSize: ScaleFromIPhone5To7Plus(17, 22))
        bodyLabel.textColor = UIColor.black
        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.textAlignment = .center

        // Image
        let imageView = UIImageView(image: image)
        view.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit

        let buttonTitle = NSLocalizedString("UPGRADE_EXPERIENCE_INTRODUCING_READ_RECEIPTS_PRIVACY_SETTINGS", comment: "button label shown one time, after upgrade")
        let button = addButton(title: buttonTitle) { _ in
            // dismiss the modally presented view controller, then proceed.
            self.experienceUpgradesPageViewController.dismiss(animated: true) {
                guard let fromViewController = UIApplication.shared.frontmostViewController as? HomeViewController else {
                    owsFail("unexpected frontmostViewController: \(String(describing: UIApplication.shared.frontmostViewController))")
                    return
                }

                // Construct the "settings" view & push the "privacy settings" view.
                let navigationController = AppSettingsViewController.inModalNavigationController()
                navigationController.pushViewController(PrivacySettingsTableViewController(), animated:false)

                fromViewController.present(navigationController, animated: true)
            }
        }

        let bottomSpacer = UIView()
        view.addSubview(bottomSpacer)

        /// Layout Views

        // Image layout
        imageView.autoAlignAxis(toSuperviewAxis: .vertical)
        imageView.autoPinToSquareAspectRatio()
        imageView.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: ScaleFromIPhone5To7Plus(36, 40))
        imageView.autoSetDimension(.height, toSize: ScaleFromIPhone5(225))

        // Title label layout
        titleLabel.autoSetDimension(.height, toSize: ScaleFromIPhone5(40))
        titleLabel.autoPinWidthToSuperview(withMargin: ScaleFromIPhone5To7Plus(16, 24))
        titleLabel.autoPinEdge(toSuperviewEdge: .top)

        // Body label layout
        bodyLabel.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: ScaleFromIPhone5To7Plus(18, 28))
        bodyLabel.autoPinWidthToSuperview(withMargin: bodyMargin)
        bodyLabel.setContentHuggingVerticalHigh()

        // Button layout
        button.autoPinEdge(.top, to: .bottom, of: bodyLabel, withOffset: ScaleFromIPhone5(16))
        button.autoPinWidthToSuperview(withMargin: ScaleFromIPhone5(32))

        bottomSpacer.autoPinEdge(.top, to: .bottom, of: button, withOffset: ScaleFromIPhone5(16))
        bottomSpacer.autoPinEdge(toSuperviewEdge: .bottom)
        bottomSpacer.autoPinWidthToSuperview()
    }

    // MARK: - Actions

    func addButton(title: String, action: @escaping (UIButton) -> Void) -> UIButton {
        self.buttonAction = action
        let button = MultiLineButton()
        view.addSubview(button)
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.ows_signalBrandBlue(), for: .normal)
        button.isUserInteractionEnabled = true
        button.addTarget(self, action:#selector(didTapButton), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.ows_mediumFont(withSize: ScaleFromIPhone5(18))
        return button
    }

    @objc func didTapButton(sender: UIButton) {
        Logger.debug("\(TAG) in \(#function)")

        guard let buttonAction = self.buttonAction else {
            owsFail("\(TAG) button action was nil")
            return
        }

        buttonAction(sender)
    }
}

/**
 * Allows multiple lines of button text, and ensures the buttons intrinsic content size reflects that of it's label.
 */
class MultiLineButton: UIButton {

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInit()
    }

    required init() {
        super.init(frame: CGRect.zero)

        self.commonInit()
    }

    private func commonInit() {
        self.titleLabel?.numberOfLines = 0
        self.titleLabel?.lineBreakMode = .byWordWrapping
    }

    // MARK: - Overrides

    override var intrinsicContentSize: CGSize {
        guard let titleLabel = titleLabel else {
            return CGSize.zero
        }

        // be more forgiving with the tappable area
        let extraPadding: CGFloat = 20
        let labelSize = titleLabel.intrinsicContentSize
        return CGSize(width: labelSize.width + extraPadding, height: labelSize.height + extraPadding)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel?.preferredMaxLayoutWidth = titleLabel?.frame.size.width ?? 0
        super.layoutSubviews()
    }
}

private class IntroductingProfilesExperienceUpgradeViewController: ExperienceUpgradeViewController {

    override func loadView() {
        self.view = UIView()

        /// Create Views

        // Title label
        let titleLabel = UILabel()
        view.addSubview(titleLabel)
        titleLabel.text = header
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.ows_regularFont(withSize: ScaleFromIPhone5(24))
        titleLabel.textColor = UIColor.white
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.adjustsFontSizeToFitWidth = true

        // Body label
        let bodyLabel = UILabel()
        self.bodyLabel = bodyLabel
        view.addSubview(bodyLabel)
        bodyLabel.text = body
        bodyLabel.font = UIFont.ows_lightFont(withSize: ScaleFromIPhone5To7Plus(17, 22))
        bodyLabel.textColor = UIColor.black
        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.textAlignment = .center

        // Image
        let imageView = UIImageView(image: image)
        view.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit

        // Button
        let button = UIButton()
        view.addSubview(button)
        let buttonTitle = NSLocalizedString("UPGRADE_EXPERIENCE_INTRODUCING_PROFILES_BUTTON", comment: "button label shown one time, after user upgrades app")
        button.setTitle(buttonTitle, for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor.ows_materialBlue()

        button.isUserInteractionEnabled = true
        button.addTarget(self, action:#selector(didTapButton), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)

        button.titleLabel?.font = UIFont.ows_mediumFont(withSize: ScaleFromIPhone5(18))

        /// Layout Views

        // Image layout
        imageView.autoAlignAxis(toSuperviewAxis: .vertical)
        imageView.autoPinToSquareAspectRatio()
        imageView.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: ScaleFromIPhone5To7Plus(36, 40))
        imageView.autoSetDimension(.height, toSize: ScaleFromIPhone5(225))

        // Title label layout
        titleLabel.autoSetDimension(.height, toSize: ScaleFromIPhone5(40))
        titleLabel.autoPinWidthToSuperview(withMargin: ScaleFromIPhone5To7Plus(16, 24))
        titleLabel.autoPinEdge(toSuperviewEdge: .top)

        // Body label layout
        bodyLabel.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: ScaleFromIPhone5To7Plus(18, 28))
        bodyLabel.autoPinWidthToSuperview(withMargin: bodyMargin)
        bodyLabel.sizeToFit()

        // Button layout
        button.autoPinEdge(.top, to: .bottom, of: bodyLabel, withOffset: ScaleFromIPhone5(18))
        button.autoPinWidthToSuperview(withMargin: ScaleFromIPhone5(32))
        button.autoPinEdge(toSuperviewEdge: .bottom, withInset: ScaleFromIPhone5(16))
        button.autoSetDimension(.height, toSize: ScaleFromIPhone5(36))
    }

    // MARK: - Actions

    @objc func didTapButton(sender: UIButton) {
        Logger.debug("\(TAG) in \(#function)")

        // dismiss the modally presented view controller, then proceed.
        experienceUpgradesPageViewController.dismiss(animated: true) {
            guard let fromViewController = UIApplication.shared.frontmostViewController as? HomeViewController else {
                owsFail("unexpected frontmostViewController: \(String(describing: UIApplication.shared.frontmostViewController))")
                return
            }
            ProfileViewController.presentForUpgradeOrNag(from: fromViewController)
        }
    }
}

private class CallKitExperienceUpgradeViewController: ExperienceUpgradeViewController {

    override func loadView() {
        super.loadView()
        assert(view != nil)
        assert(bodyLabel != nil)

        // Privacy Settings Button
        let privacySettingsButton = UIButton()
        view.addSubview(privacySettingsButton)
        let privacyTitle = NSLocalizedString("UPGRADE_EXPERIENCE_CALLKIT_PRIVACY_SETTINGS_BUTTON", comment: "button label shown once when when user upgrades app, in context of call kit")
        privacySettingsButton.setTitle(privacyTitle, for: .normal)
        privacySettingsButton.setTitleColor(UIColor.ows_signalBrandBlue(), for: .normal)
        privacySettingsButton.isUserInteractionEnabled = true
        privacySettingsButton.addTarget(self, action:#selector(didTapPrivacySettingsButton), for: .touchUpInside)
        privacySettingsButton.titleLabel?.font = bodyLabel.font

        // Privacy Settings Button layout
        privacySettingsButton.autoPinWidthToSuperview(withMargin: bodyMargin)
        privacySettingsButton.autoPinEdge(.top, to: .bottom, of: bodyLabel, withOffset: ScaleFromIPhone5(12))
        privacySettingsButton.sizeToFit()
    }

    // MARK: - Actions

    @objc func didTapPrivacySettingsButton(sender: UIButton) {
        Logger.debug("\(TAG) in \(#function)")

        // dismiss the modally presented view controller, then proceed.
        experienceUpgradesPageViewController.dismiss(animated: true) {
            let fromViewController = UIApplication.shared.frontmostViewController
            assert(fromViewController != nil)

            // Construct the "settings" view & push the "privacy settings" view.
            let navigationController = AppSettingsViewController.inModalNavigationController()
            navigationController.pushViewController(PrivacySettingsTableViewController(), animated:false)

            fromViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
}

private class ExperienceUpgradeViewController: OWSViewController {
    let TAG = "[ExperienceUpgradeViewController]"

    let header: String
    let body: String
    let image: UIImage?
    let experienceUpgradesPageViewController: ExperienceUpgradesPageViewController

    var bodyLabel: UILabel!
    let bodyMargin = ScaleFromIPhone5To7Plus(12, 24)

    init(experienceUpgrade: ExperienceUpgrade, experienceUpgradesPageViewController: ExperienceUpgradesPageViewController) {
        header = experienceUpgrade.title
        body = experienceUpgrade.body
        image = experienceUpgrade.image
        self.experienceUpgradesPageViewController = experienceUpgradesPageViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = UIView()

        /// Create Views

        // Title label
        let titleLabel = UILabel()
        view.addSubview(titleLabel)
        titleLabel.text = header
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.ows_regularFont(withSize: ScaleFromIPhone5(24))
        titleLabel.textColor = UIColor.white
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.adjustsFontSizeToFitWidth = true

        // Body label
        let bodyLabel = UILabel()
        self.bodyLabel = bodyLabel
        view.addSubview(bodyLabel)
        bodyLabel.text = body
        bodyLabel.font = UIFont.ows_lightFont(withSize: ScaleFromIPhone5To7Plus(17, 22))
        bodyLabel.textColor = UIColor.black
        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.textAlignment = .center

        // Image
        let imageView = UIImageView(image: image)
        view.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit

        /// Layout Views

        // Image layout
        imageView.autoAlignAxis(toSuperviewAxis: .vertical)
        imageView.autoPinToSquareAspectRatio()
        imageView.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: ScaleFromIPhone5To7Plus(36, 60))
        imageView.autoSetDimension(.height, toSize: ScaleFromIPhone5(225))

        // Title label layout
        titleLabel.autoSetDimension(.height, toSize: ScaleFromIPhone5(40))
        titleLabel.autoPinWidthToSuperview(withMargin: ScaleFromIPhone5To7Plus(16, 24))
        titleLabel.autoPinEdge(toSuperviewEdge: .top)

        // Body label layout
        bodyLabel.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: ScaleFromIPhone5To7Plus(18, 28))
        bodyLabel.autoPinWidthToSuperview(withMargin: bodyMargin)
        bodyLabel.sizeToFit()
        bodyLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: ScaleFromIPhone5(16))
    }
}

func setPageControlAppearance() {
    if #available(iOS 9.0, *) {
        let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [UIPageViewController.self])
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        pageControl.currentPageIndicatorTintColor = UIColor.ows_materialBlue()
    } else {
        // iOS8 won't see the page controls =(
    }
}

class ExperienceUpgradesPageViewController: OWSViewController, UIPageViewControllerDataSource {

    let TAG = "[ExperienceUpgradeViewController]"

    private let experienceUpgrades: [ExperienceUpgrade]
    private var allViewControllers = [UIViewController]()
    private var viewControllerIndexes = [UIViewController: Int]()

    let pageViewController: UIPageViewController

    // MARK: - Initializers

    @objc required init(experienceUpgrades: [ExperienceUpgrade]) {
        self.experienceUpgrades = experienceUpgrades

        setPageControlAppearance()
        self.pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation:.horizontal, options: nil)
        super.init(nibName: nil, bundle: nil)
        self.pageViewController.dataSource = self

        experienceUpgrades.forEach { addViewController(experienceUpgrade: $0) }
    }

    @available(*, unavailable, message:"unavailable, use initWithExperienceUpgrade instead")
    required init?(coder aDecoder: NSCoder) {
        assert(false)
        // This should never happen, but so as not to explode we give some bogus data
        self.experienceUpgrades = [ExperienceUpgrade()]
        self.pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation:.horizontal, options: nil)
        super.init(coder: aDecoder)
        self.pageViewController.dataSource = self
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        guard let firstViewController = allViewControllers.first else {
            owsFail("\(TAG) no pages to show.")
            dismiss(animated: true)
            return
        }

        addDismissGesture()
        self.pageViewController.setViewControllers([ firstViewController ], direction: .forward, animated: false, completion: nil)
    }

    override func loadView() {
        self.view = UIView()
        view.backgroundColor = UIColor.white

        //// Create Views

        // Header Background
        let headerBackgroundView = UIView()
        view.addSubview(headerBackgroundView)
        headerBackgroundView.backgroundColor = UIColor.ows_materialBlue()

        // Dismiss button
        let dismissButton = UIButton()
        view.addSubview(dismissButton)
        dismissButton.setTitle(CommonStrings.dismissButton, for: .normal)
        dismissButton.setTitleColor(UIColor.ows_signalBrandBlue(), for: .normal)
        dismissButton.isUserInteractionEnabled = true
        dismissButton.addTarget(self, action:#selector(didTapDismissButton), for: .touchUpInside)
        dismissButton.titleLabel?.font = UIFont.ows_mediumFont(withSize: ScaleFromIPhone5(16))
        let dismissInsetValue: CGFloat = ScaleFromIPhone5(10)
        dismissButton.contentEdgeInsets = UIEdgeInsets(top: dismissInsetValue, left: dismissInsetValue, bottom: dismissInsetValue, right: dismissInsetValue)

        guard let carouselView = self.pageViewController.view else {
            Logger.error("\(TAG) carousel view was unexpectedly nil")
            return
        }

        self.view.addSubview(carouselView)

        //// Layout Views

        // Header Background layout
        headerBackgroundView.autoPinWidthToSuperview()
        headerBackgroundView.autoPinEdge(toSuperviewEdge: .top)
        headerBackgroundView.autoSetDimension(.height, toSize: ScaleFromIPhone5(80))

        // Dismiss button layout
        dismissButton.autoHCenterInSuperview()
        dismissButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: ScaleFromIPhone5(10))

        // Carousel View layout
        carouselView.autoPinWidthToSuperview()
        // negative inset so as to overlay the header text in the carousel view with the header background which
        // lives outside of the carousel. We do this so that the user can't bounce past the page view controllers
        // width limits, exposing the edge of the header.
        carouselView.autoPin(toTopLayoutGuideOf: self, withInset: ScaleFromIPhone5To7Plus(14, 24))
        carouselView.autoPinEdge(.bottom, to: .top, of: dismissButton, withOffset: ScaleFromIPhone5(-10))
    }

    private func addDismissGesture() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleDismissGesture))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
    }

    // MARK: - UIPageViewControllerDataSource

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        Logger.debug("\(TAG) in \(#function)")
        guard let currentIndex = self.viewControllerIndexes[viewController] else {
            owsFail("\(TAG) unknown view controller: \(viewController)")
            return nil
        }

        if currentIndex + 1 == allViewControllers.count {
            // already at last view controller
            return nil
        }

        return allViewControllers[currentIndex + 1]
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        Logger.debug("\(TAG) in \(#function)")
        guard let currentIndex = self.viewControllerIndexes[viewController] else {
            owsFail("\(TAG) unknown view controller: \(viewController)")
            return nil
        }

        if currentIndex <= 0 {
            // already at first view controller
            return nil
        }

        return allViewControllers[currentIndex - 1]
    }

    public func presentationCount(for pageViewController: UIPageViewController) -> Int {
        // don't show a page indicator if there's only one page.
        return allViewControllers.count == 1 ? 0 : allViewControllers.count
    }

    public func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let currentViewController = pageViewController.viewControllers?.first else {
            Logger.error("\(TAG) unexpectedly empty view controllers.")
            return 0
        }

        guard let currentIndex = self.viewControllerIndexes[currentViewController] else {
            Logger.error("\(TAG) unknown view controller: \(currentViewController)")
            return 0
        }

        return currentIndex
    }

    public func addViewController(experienceUpgrade: ExperienceUpgrade) {
        guard let uniqueId = experienceUpgrade.uniqueId else {
            Logger.error("\(self.TAG) experienceUpgrade is missing uniqueId.")
            return
        }
        guard let identifier = ExperienceUpgradeId(rawValue: uniqueId) else {
            owsFail("\(TAG) unknown experience upgrade. skipping")
            return
        }

        let viewController: ExperienceUpgradeViewController = {
            switch identifier {
            case .callKit:
                return CallKitExperienceUpgradeViewController(experienceUpgrade: experienceUpgrade, experienceUpgradesPageViewController: self)
            case .introducingProfiles:
                return IntroductingProfilesExperienceUpgradeViewController(experienceUpgrade: experienceUpgrade, experienceUpgradesPageViewController: self)
            case .introducingReadReceipts:
                return IntroductingReadReceiptsExperienceUpgradeViewController(experienceUpgrade: experienceUpgrade, experienceUpgradesPageViewController: self)
            default:
                return ExperienceUpgradeViewController(experienceUpgrade: experienceUpgrade, experienceUpgradesPageViewController: self)
            }
        }()

        let count = allViewControllers.count
        viewControllerIndexes[viewController] = count
        allViewControllers.append(viewController)
    }

    @objc func didTapDismissButton(sender: UIButton) {
        Logger.debug("\(TAG) in \(#function)")
        self.dismiss(animated: true)
    }

    @objc func handleDismissGesture(sender: AnyObject) {
        Logger.debug("\(TAG) in \(#function)")
        self.dismiss(animated: true)
    }
}
