//
//  Update Packages.swift
//  Cork
//
//  Created by David Bureš on 09.03.2023.
//

import Foundation
import SwiftUI

@MainActor
func refreshPackages(_ updateProgressTracker: UpdateProgressTracker, outdatedPackageTracker: OutdatedPackageTracker) async -> PackageUpdateAvailability
{
    let showRealTimeTerminalOutputs = UserDefaults.standard.bool(forKey: "showRealTimeTerminalOutputOfOperations")

    for await output in shell(AppConstants.brewExecutablePath, ["update"])
    {
        switch output
        {
        case let .standardOutput(outputLine):
            print("Update function output: \(outputLine)")

            if showRealTimeTerminalOutputs
            {
                updateProgressTracker.realTimeOutput.append(RealTimeTerminalLine(line: outputLine))
            }

            updateProgressTracker.updateProgress = updateProgressTracker.updateProgress + 0.1

            if outdatedPackageTracker.outdatedPackages.isEmpty
            {
                if outputLine.starts(with: "Already up-to-date")
                {
                    print("Inside update function: No updates available")
                    return .noUpdatesAvailable
                }
            }

        case let .standardError(errorLine):

            if showRealTimeTerminalOutputs
            {
                updateProgressTracker.realTimeOutput.append(RealTimeTerminalLine(line: errorLine))
            }

            if errorLine.starts(with: "Another active Homebrew update process is already in progress") || errorLine == "Error: " || errorLine.contains("Updated [0-9]+ tap") || errorLine == "Already up-to-date" || errorLine.contains("No checksum defined")
            {
                updateProgressTracker.updateProgress = updateProgressTracker.updateProgress + 0.1
                print("Ignorable update function error: \(errorLine)")

                return .noUpdatesAvailable
            }
            else
            {
                print("Update function error: \(errorLine)")
                updateProgressTracker.errors.append("Update error: \(errorLine)")
            }
        }
    }
    updateProgressTracker.updateProgress = Float(10) / Float(2)

    return .updatesAvailable
}
