//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

import Foundation
import PromiseKit

class OWS106EnsureProfileComplete: OWSDatabaseMigration {

    let TAG = "[OWS106EnsureProfileComplete]"

    private static var sharedCompleteRegistrationFixerJob: CompleteRegistrationFixerJob?

    // increment a similar constant for each migration.
    @objc class func migrationId() -> String {
        return "106"
    }

    // Overriding runUp since we have some specific completion criteria which
    // is more likely to fail since it involves network requests.
    override func runUp() {
        guard type(of: self).sharedCompleteRegistrationFixerJob == nil else {
            owsFail("\(self.TAG) should only be called once.")
            return
        }

        let job = CompleteRegistrationFixerJob(completionHandler: {
            Logger.info("\(self.TAG) Completed. Saving.")
            self.save()
        })

        type(of: self).sharedCompleteRegistrationFixerJob = job

        job.start()
    }

    /**
     * A previous client bug made it possible for re-registering users to register their new account
     * but never upload new pre-keys. The symptom is that there will be accounts with no uploaded
     * identity key. We detect that here and fix the situation
     */
    private class CompleteRegistrationFixerJob {

        let TAG = "[CompleteRegistrationFixerJob]"

        // Duration between retries if update fails.
        static let kRetryInterval: TimeInterval = 5 * 60

        var timer: Timer?
        let completionHandler: () -> Void

        init(completionHandler: @escaping () -> Void) {
            self.completionHandler = completionHandler
        }

        func start() {
            assert(self.timer == nil)

            let timer = WeakTimer.scheduledTimer(timeInterval: CompleteRegistrationFixerJob.kRetryInterval, target: self, userInfo: nil, repeats: true) { [weak self] aTimer in
                guard let strongSelf = self else {
                    return
                }

                var isCompleted = false
                strongSelf.ensureProfileComplete().done {
                    guard isCompleted == false else {
                        Logger.info("Already saved. Skipping redundant call.")
                        return
                    }
                    Logger.info("\(strongSelf.TAG) complete. Canceling timer and saving.")
                    isCompleted = true
                    aTimer.invalidate()
                    strongSelf.completionHandler()
                }.catch { error in
                    Logger.error("\(strongSelf.TAG) failed with \(error). We'll try again in \(CompleteRegistrationFixerJob.kRetryInterval) seconds.")
                }.retainUntilComplete()
            }
            self.timer = timer

            timer.fire()
        }

        func ensureProfileComplete() -> Promise<Void> {
            guard let localRecipientId = TSAccountManager.localNumber() else {
                // local app doesn't think we're registered, so nothing to worry about.
                return Promise.value(())
            }

            let (promise, resolver) = Promise<Void>.pending()

            guard let networkManager = Environment.getCurrent().networkManager else {
                owsFail("\(TAG) network manager was unexpectedly not set")
                return Promise(error: OWSErrorMakeAssertionError())
            }

            ProfileFetcherJob(networkManager: networkManager).getProfile(recipientId: localRecipientId).map { _ -> Void in
                Logger.info("\(self.TAG) verified recipient profile is in good shape: \(localRecipientId)")

                resolver.fulfill(())
            }.catch { error in
                switch error {
                case SignalServiceProfile.ValidationError.invalidIdentityKey(let description):
                    Logger.warn("\(self.TAG) detected incomplete profile for \(localRecipientId) error: \(description)")
                    // This is the error condition we're looking for. Update prekeys to properly set the identity key, completing registration.
                    TSPreKeyManager.registerPreKeys(with: .signedAndOneTime,
                                                    success: {
                                                        Logger.info("\(self.TAG) successfully uploaded pre-keys. Profile should be fixed.")
                                                        resolver.fulfill(())
                    },
                                                    failure: { _ in
                                                        resolver.reject(OWSErrorWithCodeDescription(.signalServiceFailure, "\(self.TAG) Unknown error in \(#function)"))
                    })
                default:
                    resolver.reject(error)
                }
            }.retainUntilComplete()

            return promise
        }
    }
}
