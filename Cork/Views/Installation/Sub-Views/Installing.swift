//
//  Installing.swift
//  Cork
//
//  Created by David Bureš on 29.09.2023.
//

import SwiftUI

struct InstallingPackageView: View
{
    @EnvironmentObject var brewData: BrewDataStorage

    @ObservedObject var installationProgressTracker: InstallationProgressTracker
    
    @Binding var packageInstallationProcessStep: PackageInstallationProcessSteps

    var body: some View
    {
        VStack(alignment: .leading)
        {
            ForEach(installationProgressTracker.packagesBeingInstalled)
            { packageBeingInstalled in

                if packageBeingInstalled.installationStage != .finished
                {
                    ProgressView(value: installationProgressTracker.packagesBeingInstalled[0].packageInstallationProgress, total: 10)
                    {
                        switch packageBeingInstalled.installationStage
                        {
                            case .ready:
                                Text("add-package.install.ready")

                                // FORMULAE
                            case .loadingDependencies:
                                Text("add-package.install.loading-dependencies")

                            case .fetchingDependencies:
                                Text("add-package.install.fetching-dependencies")

                            case .installingDependencies:
                                Text("add-package.install.installing-dependencies-\(installationProgressTracker.numberInLineOfPackageCurrentlyBeingInstalled)-of-\(installationProgressTracker.numberOfPackageDependencies)")

                            case .installingPackage:
                                Text("add-package.install.installing-package")

                            case .finished:
                                Text("add-package.install.finished")

                                // CASKS
                            case .downloadingCask:
                                Text("add-package.install.downloading-cask-\(installationProgressTracker.packagesBeingInstalled[0].package.name)")

                            case .installingCask:
                                Text("add-package.install.installing-cask-\(installationProgressTracker.packagesBeingInstalled[0].package.name)")

                            case .linkingCaskBinary:
                                Text("add-package.install.linking-cask-binary")

                            case .movingCask:
                                Text("add-package.install.moving-cask-\(installationProgressTracker.packagesBeingInstalled[0].package.name)")

                            case .requiresSudoPassword:
                                Text("add-package.install.requires-sudo-password-\(installationProgressTracker.packagesBeingInstalled[0].package.name)")
                                    .onAppear
                                {
                                    packageInstallationProcessStep = .requiresSudoPassword
                                }
                        }
                    }
                }
                else
                { // Show this when the installation is finished
                    Text("add-package.install.finished")
                        .onAppear
                    {
                        packageInstallationProcessStep = .finished
                    }
                }
            }
        }
        .task(priority: .userInitiated)
        {
            for var packageToInstall in installationProgressTracker.packagesBeingInstalled
            {
                do
                {
                    let installationResult = try await installPackage(installationProgressTracker: installationProgressTracker, brewData: brewData)
                    print("Installation result: \(installationResult)")
                }
                catch let fatalInstallationError
                {
                    print("Fatal error occured during installing a package: \(fatalInstallationError)")
                }
            }
        }
    }
}
