//
// AdsConfig.swift
//
// AdMob unit IDs + frequency caps. The only file that changes per app.
// Ads are shown only while the user has NOT bought "Remove Ads".
//

import CoreGraphics
import Foundation

enum AdsConfig {

    // MARK: - Ad unit IDs
    // AdMob app ID lives in Info.plist (GADApplicationIdentifier):
    //   ca-app-pub-5982140566133654~7091425404  (Hydrio)
    // DEBUG builds always use Google's test units so we never click our own live ads.

    #if DEBUG
    static let bannerUnitID       = "ca-app-pub-3940256099942544/2934735716"   // Google test banner
    static let interstitialUnitID = "ca-app-pub-3940256099942544/4411468910"   // Google test interstitial
    #else
    static let bannerUnitID       = releaseBannerUnitID
    static let interstitialUnitID = releaseInterstitialUnitID
    #endif

    static let releaseBannerUnitID       = "ca-app-pub-5982140566133654/4402964148"   // Hydrio Banner - above tab bar
    static let releaseInterstitialUnitID = "ca-app-pub-5982140566133654/1776800805"   // Hydrio Interstitial - after drinks

    // MARK: - Frequency caps

    /// An interstitial may only follow every Nth qualifying action (Hydrio: a logged drink).
    static let interstitialEveryNActions = 4

    /// Minimum gap between two interstitials.
    static let minSecondsBetweenInterstitials: TimeInterval = 180

    /// Short pause after the qualifying action, so its feedback (toast, sheet dismissal)
    /// is seen before the ad covers the screen.
    static let interstitialPresentationDelay: TimeInterval = 1.0

    /// Pause before the consent form / ATT prompt once the main UI is on screen.
    static let startupDelay: TimeInterval = 1.5

    // MARK: - Layout

    /// Gap between the banner and the floating tab bar.
    static let bannerSpacing: CGFloat = 8
}
