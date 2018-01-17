//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc
public protocol MessageApprovalViewControllerDelegate: class {
    func messageApproval(_ messageApproval: MessageApprovalViewController, didApproveMessage messageText: String)
    func messageApprovalDidCancel(_ messageApproval: MessageApprovalViewController)
}

@objc
public class MessageApprovalViewController: OWSViewController, UITextViewDelegate {

    let TAG = "[MessageApprovalViewController]"
    weak var delegate: MessageApprovalViewControllerDelegate?

    // MARK: Properties

    let thread: TSThread
    let initialMessageText: String
    let contactsManager: OWSContactsManager

    private(set) var textView: UITextView!
    private(set) var topToolbar: UIToolbar!

    // MARK: Initializers

    @available(*, unavailable, message:"use attachment: constructor instead.")
    required public init?(coder aDecoder: NSCoder) {
        fatalError("unimplemented")
    }

    @objc
    required public init(messageText: String, thread: TSThread, contactsManager: OWSContactsManager, delegate: MessageApprovalViewControllerDelegate) {
        self.initialMessageText = messageText
        self.thread = thread
        self.contactsManager = contactsManager
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    // MARK: View Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = NSLocalizedString("MESSAGE_APPROVAL_DIALOG_TITLE",
                                                      comment: "Title for the 'message approval' dialog.")
    }

    private func updateToolbar() {
        var items = [UIBarButtonItem]()

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(cancelPressed))
        items.append(cancelButton)

        if textView.text.count > 0 {
            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            items.append(spacer)
            let sendButton = UIBarButtonItem(title: NSLocalizedString("SEND_BUTTON_TITLE",
                                                                      comment:"Label for the send button in the conversation view."),
                                             style:.plain,
                                             target: self,
                                             action: #selector(sendPressed))
            items.append(sendButton)
        }

        topToolbar.items = items
    }

    // MARK: - Create Views

    public override func loadView() {

        self.view = UIView.container()
        self.view.backgroundColor = UIColor.white

        // Top Toolbar
        topToolbar = UIToolbar()
        topToolbar.backgroundColor = UIColor.ows_toolbarBackground
        self.view.addSubview(topToolbar)
        topToolbar.autoPinWidthToSuperview()
        topToolbar.autoPin(toTopLayoutGuideOf: self, withInset: 0)
        topToolbar.setContentHuggingVerticalHigh()
        topToolbar.setCompressionResistanceVerticalHigh()

        // Recipient Row
        let recipientRow = createRecipientRow()
        view.addSubview(recipientRow)
        recipientRow.autoPinWidthToSuperview()
        recipientRow.autoPinEdge(.top, to: .bottom, of: topToolbar)

        // Text View
        textView = UITextView()
        textView.delegate = self
        textView.backgroundColor = UIColor.white
        textView.textColor = UIColor.black
        textView.font = UIFont.ows_dynamicTypeBody()
        textView.text = self.initialMessageText
        textView.contentInset = UIEdgeInsets(top:0.0, left:0.0, bottom:0.0, right:0.0)
        textView.textContainerInset = UIEdgeInsets(top:10.0, left:10.0, bottom:10.0, right:10.0)
        view.addSubview(textView)
        textView.autoPinWidthToSuperview()
        textView.autoPinEdge(.top, to: .bottom, of: recipientRow)
        textView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)

        updateToolbar()
    }

    private func createRecipientRow() -> UIView {
        let recipientRow = UIView.container()
        recipientRow.backgroundColor = UIColor.ows_toolbarBackground

        // Hairline borders should be 1 pixel, not 1 point.
        let borderThickness = 1.0 / UIScreen.main.scale
        let borderColor = UIColor(white:135 / 255.0, alpha:1.0)

        let topBorder = UIView.container()
        topBorder.backgroundColor = borderColor
        recipientRow.addSubview(topBorder)
        topBorder.autoPinWidthToSuperview()
        topBorder.autoPinTopToSuperview()
        topBorder.autoSetDimension(.height, toSize: borderThickness)

        let bottomBorder = UIView.container()
        bottomBorder.backgroundColor = borderColor
        recipientRow.addSubview(bottomBorder)
        bottomBorder.autoPinWidthToSuperview()
        bottomBorder.autoPinBottomToSuperview()
        bottomBorder.autoSetDimension(.height, toSize: borderThickness)

        guard let font = UIFont.ows_regularFont(withSize:ScaleFromIPhone5To7Plus(14.0, 18.0)) else {
            owsFail("Can't load font")
            return recipientRow
        }
        let hSpacing = CGFloat(10)
        let hMargin = CGFloat(15)
        let vSpacing = CGFloat(5)
        let vMargin = CGFloat(10)

        let toLabel = UILabel()
        toLabel.text = NSLocalizedString("MESSAGE_APPROVAL_RECIPIENT_LABEL",
                                         comment: "Label for the recipient name in the 'message approval' dialog.")
        toLabel.textColor = UIColor.ows_darkGray
        toLabel.font = font
        recipientRow.addSubview(toLabel)

        let nameLabel = UILabel()
        nameLabel.textColor = UIColor.black
        nameLabel.font = font
        nameLabel.lineBreakMode = .byTruncatingTail
        recipientRow.addSubview(nameLabel)

        toLabel.autoPinLeadingToSuperview(withMargin: hMargin)
        toLabel.setContentHuggingHorizontalHigh()
        toLabel.setCompressionResistanceHorizontalHigh()
        toLabel.autoAlignAxis(.horizontal, toSameAxisOf: nameLabel)

        nameLabel.autoPinLeading(toTrailingOf: toLabel, margin:hSpacing)
        nameLabel.autoPinTrailingToSuperview(withMargin: hMargin)
        nameLabel.setContentHuggingHorizontalLow()
        nameLabel.setCompressionResistanceHorizontalLow()
        nameLabel.autoPinTopToSuperview(withMargin: vMargin)

        recipientRow.logFrameLater(withLabel: "recipientRow")
        toLabel.logFrameLater(withLabel: "toLabel")
        nameLabel.logFrameLater(withLabel: "nameLabel")

        if let groupThread = self.thread as? TSGroupThread {
            let groupName = (groupThread.name().count > 0
            ? groupThread.name()
                : MessageStrings.newGroupDefaultTitle)

            nameLabel.text = groupName
            nameLabel.autoPinBottomToSuperview(withMargin: vMargin)

            return recipientRow
        }
        guard let contactThread = self.thread as? TSContactThread else {
            owsFail("Unexpected thread type")
            return recipientRow
        }

        nameLabel.attributedText = contactsManager.formattedFullName(forRecipientId:contactThread.contactIdentifier(), font:font)
        nameLabel.textColor = UIColor.black

        if let profileName = self.profileName(contactThread:contactThread) {
            // If there's a profile name worth showing, add it as a second line below the name.
            let profileNameLabel = UILabel()
            profileNameLabel.textColor = UIColor.ows_darkGray
            profileNameLabel.font = font
            profileNameLabel.text = profileName
            profileNameLabel.lineBreakMode = .byTruncatingTail
            recipientRow.addSubview(profileNameLabel)
            profileNameLabel.autoPinEdge(.top, to: .bottom, of: nameLabel, withOffset: vSpacing)
            profileNameLabel.autoPinLeading(toTrailingOf: toLabel, margin:hSpacing)
            profileNameLabel.autoPinTrailingToSuperview(withMargin: hMargin)
            profileNameLabel.setContentHuggingHorizontalLow()
            profileNameLabel.setCompressionResistanceHorizontalLow()
            profileNameLabel.autoPinBottomToSuperview(withMargin: vMargin)
        } else {
            nameLabel.autoPinBottomToSuperview(withMargin: vMargin)
        }

        return recipientRow
    }

    private func profileName(contactThread: TSContactThread) -> String? {
        let recipientId = contactThread.contactIdentifier()

        if contactsManager.hasNameInSystemContacts(forRecipientId:recipientId) {
            // Don't display profile name when we have a veritas name in system Contacts
            return nil
        }
        return contactsManager.formattedProfileName(forRecipientId:recipientId)
    }

    // MARK: - Event Handlers

    func cancelPressed(sender: UIButton) {
        delegate?.messageApprovalDidCancel(self)
    }

    func sendPressed(sender: UIButton) {
        delegate?.messageApproval(self, didApproveMessage: self.textView.text)
    }

    // MARK: - UITextViewDelegate

    public func textViewDidChange(_ textView: UITextView) {
        updateToolbar()
    }
}
