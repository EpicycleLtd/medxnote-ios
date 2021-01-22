//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc(OWSWebRTCCallMessageHandler)
class WebRTCCallMessageHandler: NSObject, OWSCallMessageHandler {

    // MARK - Properties

    let TAG = "[WebRTCCallMessageHandler]"

    // MARK: Dependencies

    let accountManager: AccountManager
    let callService: CallService
    let messageSender: MessageSender

    // MARK: Initializers

    @objc required init(accountManager: AccountManager, callService: CallService, messageSender: MessageSender) {
        self.accountManager = accountManager
        self.callService = callService
        self.messageSender = messageSender
    }

    // MARK: - Call Handlers

    public func receivedOffer(_ offer: OWSSignalServiceProtosCallMessageOffer, from callerId: String) {
        AssertIsOnMainThread()
        guard offer.hasId() else {
            owsFail("no callId in \(#function)")
            return
        }

        let thread = TSContactThread.getOrCreateThread(contactId: callerId)
        self.callService.handleReceivedOffer(thread: thread, callId: offer.id, sessionDescription: offer.sessionDescription)
    }

    public func receivedAnswer(_ answer: OWSSignalServiceProtosCallMessageAnswer, from callerId: String) {
        AssertIsOnMainThread()
        guard answer.hasId() else {
            owsFail("no callId in \(#function)")
            return
        }

        let thread = TSContactThread.getOrCreateThread(contactId: callerId)
        self.callService.handleReceivedAnswer(thread: thread, callId: answer.id, sessionDescription: answer.sessionDescription)
    }

    public func receivedIceUpdate(_ iceUpdate: OWSSignalServiceProtosCallMessageIceUpdate, from callerId: String) {
        AssertIsOnMainThread()
        guard iceUpdate.hasId() else {
            owsFail("no callId in \(#function)")
            return
        }

        let thread = TSContactThread.getOrCreateThread(contactId: callerId)

        // Discrepency between our protobuf's sdpMlineIndex, which is unsigned, 
        // while the RTC iOS API requires a signed int.
        let lineIndex = Int32(iceUpdate.sdpMlineIndex)

        self.callService.handleRemoteAddedIceCandidate(thread: thread, callId: iceUpdate.id, sdp: iceUpdate.sdp, lineIndex: lineIndex, mid: iceUpdate.sdpMid)
    }

    public func receivedHangup(_ hangup: OWSSignalServiceProtosCallMessageHangup, from callerId: String) {
        AssertIsOnMainThread()
        guard hangup.hasId() else {
            owsFail("no callId in \(#function)")
            return
        }

        let thread = TSContactThread.getOrCreateThread(contactId: callerId)
        self.callService.handleRemoteHangup(thread: thread, callId: hangup.id)
    }

    public func receivedBusy(_ busy: OWSSignalServiceProtosCallMessageBusy, from callerId: String) {
        AssertIsOnMainThread()
        guard busy.hasId() else {
            owsFail("no callId in \(#function)")
            return
        }

        let thread = TSContactThread.getOrCreateThread(contactId: callerId)
        self.callService.handleRemoteBusy(thread: thread, callId: busy.id)
    }

}
