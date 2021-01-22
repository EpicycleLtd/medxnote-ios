//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

import Foundation

/**
 * Strings re-used in multiple places should be added here.
 */

@objc class CommonStrings: NSObject {
    @objc static let dismissButton = NSLocalizedString("DISMISS_BUTTON_TEXT", comment: "Short text to dismiss current modal / actionsheet / screen")
    @objc static let cancelButton = NSLocalizedString("TXT_CANCEL_TITLE", comment:"Label for the cancel button in an alert or action sheet.")
    @objc static let retryButton = NSLocalizedString("RETRY_BUTTON_TEXT", comment:"Generic text for button that retries whatever the last action was.")
}

@objc class MessageStrings: NSObject {
    @objc static let newGroupDefaultTitle = NSLocalizedString("NEW_GROUP_DEFAULT_TITLE", comment: "Used in place of the group name when a group has not yet been named.")
}

@objc class CallStrings: NSObject {

    @objc static let callStatusFormat = NSLocalizedString("CALL_STATUS_FORMAT", comment: "embeds {{Call Status}} in call screen label. For ongoing calls, {{Call Status}} is a seconds timer like 01:23, otherwise {{Call Status}} is a short text like 'Ringing', 'Busy', or 'Failed Call'")

    @objc static let confirmAndCallButtonTitle = NSLocalizedString("SAFETY_NUMBER_CHANGED_CONFIRM_CALL_ACTION", comment: "alert button text to confirm placing an outgoing call after the recipients Safety Number has changed.")

    @objc static let callBackAlertTitle = NSLocalizedString("CALL_USER_ALERT_TITLE", comment: "Title for alert offering to call a user.")
    @objc static let callBackAlertMessageFormat = NSLocalizedString("CALL_USER_ALERT_MESSAGE_FORMAT", comment: "Message format for alert offering to call a user. Embeds {{the user's display name or phone number}}.")
    @objc static let callBackAlertCallButton = NSLocalizedString("CALL_USER_ALERT_CALL_BUTTON", comment: "Label for call button for alert offering to call a user.")

    // MARK: Notification actions
    @objc static let callBackButtonTitle = NSLocalizedString("CALLBACK_BUTTON_TITLE", comment: "notification action")
    @objc static let showThreadButtonTitle = NSLocalizedString("SHOW_THREAD_BUTTON_TITLE", comment: "notification action")

    // MARK: Missed Call Notification
    @objc static let missedCallNotificationBodyWithoutCallerName = NSLocalizedString("MISSED_CALL", comment: "notification title")
    @objc static let missedCallNotificationBodyWithCallerName = NSLocalizedString("MSGVIEW_MISSED_CALL_WITH_NAME", comment: "notification title. Embeds {{caller's name or phone number}}")

    // MARK: Missed with changed identity notification (for not previously verified identity)
    @objc static let missedCallWithIdentityChangeNotificationBodyWithoutCallerName =  NSLocalizedString("MISSED_CALL_WITH_CHANGED_IDENTITY_BODY_WITHOUT_CALLER_NAME", comment: "notification title")
    @objc static let missedCallWithIdentityChangeNotificationBodyWithCallerName =  NSLocalizedString("MISSED_CALL_WITH_CHANGED_IDENTITY_BODY_WITH_CALLER_NAME", comment: "notification title. Embeds {{caller's name or phone number}}")
}

@objc class SafetyNumberStrings: NSObject {
    @objc static let confirmSendButton = NSLocalizedString("SAFETY_NUMBER_CHANGED_CONFIRM_SEND_ACTION",
                                                      comment: "button title to confirm sending to a recipient whose safety number recently changed")
}
