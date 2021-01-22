//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

import Foundation
import PromiseKit

/**
 * Signal is actually two services - textSecure for messages and red phone (for calls). 
 * AccountManager delegates to both.
 */
@objc
class AccountManager: NSObject {
    let TAG = "[AccountManager]"

    let textSecureAccountManager: TSAccountManager
    let networkManager: TSNetworkManager
    let preferences: OWSPreferences

    var pushManager: PushManager {
        // dependency injection hack since PushManager has *alot* of dependencies, and would induce a cycle.
        return PushManager.shared()
    }

    @objc required init(textSecureAccountManager: TSAccountManager, preferences: OWSPreferences) {
        self.networkManager = textSecureAccountManager.networkManager
        self.textSecureAccountManager = textSecureAccountManager
        self.preferences = preferences
    }

    // MARK: registration

    @objc func register(verificationCode: String) -> AnyPromise {
        return AnyPromise(register(verificationCode: verificationCode) as Promise<Void>)
    }

    func register(verificationCode: String) -> Promise<Void> {
        guard verificationCode.characters.count > 0 else {
            let error = OWSErrorWithCodeDescription(.userError,
                                                    NSLocalizedString("REGISTRATION_ERROR_BLANK_VERIFICATION_CODE",
                                                                      comment: "alert body during registration"))
            return Promise(error: error)
        }

        Logger.debug("\(self.TAG) registering with signal server")
        let registrationPromise: Promise<Void> = firstly {
            self.registerForTextSecure(verificationCode: verificationCode)
        }.then {
            self.syncPushTokens()
        }.recover { (error) -> Promise<Void> in
            switch error {
            case PushRegistrationError.pushNotSupported(let description):
                // This can happen with:
                // - simulators, none of which support receiving push notifications
                // - on iOS11 devices which have disabled "Allow Notifications" and disabled "Enable Background Refresh" in the system settings.
                Logger.info("\(self.TAG) Recovered push registration error. Registering for manual message fetcher because push not supported: \(description)")
                return self.registerForManualMessageFetching()
            default:
                throw error
            }
        }.done {
            self.completeRegistration()
        }

        registrationPromise.retainUntilComplete()

        return registrationPromise
    }

    private func registerForTextSecure(verificationCode: String) -> Promise<Void> {
        return Promise { resolver in
            self.textSecureAccountManager.verifyAccount(withCode:verificationCode,
                                                        success:resolver.fulfill,
                                                        failure:resolver.reject)
        }
    }

    private func syncPushTokens() -> Promise<Void> {
        Logger.info("\(self.TAG) in \(#function)")
        let job = SyncPushTokensJob(accountManager: self, preferences: self.preferences)
        job.uploadOnlyIfStale = false
        return job.run()
    }

    private func completeRegistration() {
        Logger.info("\(self.TAG) in \(#function)")
        self.textSecureAccountManager.didRegister()
    }

    // MARK: Message Delivery

    func updatePushTokens(pushToken: String, voipToken: String) -> Promise<Void> {
        return Promise { resolver in
            self.textSecureAccountManager.registerForPushNotifications(pushToken:pushToken,
                                                                       voipToken:voipToken,
                                                                       success:resolver.fulfill,
                                                                       failure:resolver.reject)
        }
    }

    func registerForManualMessageFetching() -> Promise<Void> {
        return Promise { resolver in
            self.textSecureAccountManager.registerForManualMessageFetching(success:resolver.fulfill, failure:resolver.reject)
        }
    }

    // MARK: Turn Server

    func getTurnServerInfo() -> Promise<TurnServerInfo> {
        return Promise { resolver in
            self.networkManager.makeRequest(TurnServerInfoRequest(),
                                            success: { (_: URLSessionDataTask, responseObject: Any?) in
                                                guard responseObject != nil else {
                                                    return resolver.reject(OWSErrorMakeUnableToProcessServerResponseError())
                                                }

                                                if let responseDictionary = responseObject as? [String: AnyObject] {
                                                    if let turnServerInfo = TurnServerInfo(attributes:responseDictionary) {
                                                        return resolver.fulfill(turnServerInfo)
                                                    }
                                                    Logger.error("\(self.TAG) unexpected server response:\(responseDictionary)")
                                                }
                                                return resolver.reject(OWSErrorMakeUnableToProcessServerResponseError())
            },
                                            failure: { (_: URLSessionDataTask, error: Error) in
                                                    return resolver.reject(error)
            })
        }
    }

}
