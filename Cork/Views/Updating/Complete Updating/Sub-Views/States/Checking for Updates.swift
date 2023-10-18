//
//  Checking for Updates.swift
//  Cork
//
//  Created by David Bureš on 17.10.2023.
//

import SwiftUI

struct CheckingForUpdatesStateView: View
{
    @EnvironmentObject var outdatedPackageTracker: OutdatedPackageTracker
    @EnvironmentObject var updateProgressTracker: UpdateProgressTracker

    @Binding var packageUpdatingStep: PackageUpdatingProcessSteps
    @Binding var packageUpdatingStage: PackageUpdatingStage

    @Binding var updateAvailability: PackageUpdateAvailability

    @Binding var isShowingRealTimeTerminalOutput: Bool

    var body: some View
    {
        VStack(alignment: .leading)
        {
            Text("update-packages.updating.checking")
            LiveTerminalOutputView(
                lineArray: $updateProgressTracker.realTimeOutput,
                isRealTimeTerminalOutputExpanded: $isShowingRealTimeTerminalOutput,
                forceKeepTerminalOutputInMemory: true
            )
        }
        .task(priority: .userInitiated)
        {
            updateAvailability = await refreshPackages(updateProgressTracker, outdatedPackageTracker: outdatedPackageTracker)

            print("Update availability result: \(updateAvailability)")

            if updateAvailability == .noUpdatesAvailable
            {
                print("Outside update function: No updates available")

                updateProgressTracker.realTimeOutput = .init()

                packageUpdatingStage = .noUpdatesAvailable
            }
            else
            {
                print("Outside update function: Updates available")
                packageUpdatingStep = .updatingPackages
            }
        }
    }
}
