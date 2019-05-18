//
//  OneSignal.swift
//  App
//
//  Created by Christoph Pageler on 15.08.18.
//


import Foundation


public struct OneSignal {

    public static func appID() -> String {
        return ProcessInfo.processInfo.environment["ONE_SIGNAL_APP_ID"] ?? ""
    }

    public static func restAPIKey() -> String {
        return ProcessInfo.processInfo.environment["ONE_SIGNAL_REST_API_KEY"] ?? ""
    }

}
