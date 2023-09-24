//
//  Package Details.swift
//  Cork
//
//  Created by David Bureš on 03.07.2022.
//

import SwiftUI
import SwiftyJSON

struct PackageDetailView: View
{
    @AppStorage("caveatDisplayOptions") var caveatDisplayOptions: PackageCaveatDisplay = .full
    @AppStorage("allowMoreCompleteUninstallations") var allowMoreCompleteUninstallations: Bool = false

    @State var package: BrewPackage

    @EnvironmentObject var brewData: BrewDataStorage

    @State var packageInfoRaw: String?

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var outdatedPackageTracker: OutdatedPackageTracker

    @State private var description: String = ""
    @State private var homepage: URL = .init(string: "https://google.com")!
    @State private var tap: String = ""
    @State private var installedAsDependency: Bool = false
    @State private var packageDependents: [String]? = nil
    @State private var dependencies: [BrewPackageDependency]? = nil
    @State private var outdated: Bool = false
    @State private var caveats: String? = nil
    @State private var pinned: Bool = false

    @State private var isShowingExpandedCaveats: Bool = false
    @State private var canExpandCaveats: Bool = false

    @State private var isShowingCaveatPopover: Bool = false
    @State var isShowingPopover: Bool = false

    @State private var erroredOut: Bool = false

    var body: some View
    {
        VStack(alignment: .leading, spacing: 15)
        {
            VStack(alignment: .leading, spacing: 5)
            {
                HStack(alignment: .firstTextBaseline, spacing: 5)
                {
                    SanitizedPackageName(packageName: package.name, shouldShowVersion: false)
                        .font(.title)
                    Text("v. \(returnFormattedVersions(package.versions))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if pinned
                    {
                        Image(systemName: "pin.fill")
                            .help("package-details.pinned.help-\(package.name)")
                    }
                }

                VStack(alignment: .leading, spacing: 5)
                {
                    HStack(alignment: .center, spacing: 5)
                    {
                        if installedAsDependency
                        {
                            if let packageDependents
                            {
                                if packageDependents.count != 0 // This happens when the package was originally installed as a dependency, but the parent is no longer installed
                                {
                                    OutlinedPillText(text: "package-details.dependants.dependency-of-\(packageDependents.formatted(.list(type: .and)))", color: .secondary)
                                }
                            }
                            else
                            {
                                OutlinedPill(content: {
                                    HStack(alignment: .center, spacing: 5)
                                    {
                                        ProgressView()
                                            .scaleEffect(0.3, anchor: .center)
                                            .frame(width: 5, height: 5)

                                        Text("package-details.dependants.loading")
                                    }
                                }, color: Color(nsColor: NSColor.tertiaryLabelColor))
                            }
                        }
                        if outdated
                        {
                            OutlinedPillText(text: "package-details.outdated", color: .orange)
                        }
                        if let caveats
                        {
                            if !caveats.isEmpty
                            {
                                if caveatDisplayOptions == .mini
                                {
                                    OutlinedPillText(text: "package-details.caveats.available", color: .indigo)
                                        .onTapGesture
                                        {
                                            isShowingCaveatPopover.toggle()
                                        }
                                        .popover(isPresented: $isShowingCaveatPopover)
                                        {
                                            Text(.init(caveats.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n\n", with: "\n")))
                                                .textSelection(.enabled)
                                                .lineSpacing(5)
                                                .padding()
                                                .help("package-details.caveats.help")
                                        }
                                }
                            }
                        }
                    }

                    if packageInfoRaw != nil
                    {
                        if !description.isEmpty
                        {
                            Text(description)
                                .font(.subheadline)
                        }
                        else
                        {
                            HStack(alignment: .center, spacing: 10)
                            {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .resizable()
                                    .frame(width: 15, height: 15)
                                    .foregroundColor(.yellow)
                                Text("package-details.description-none-\(package.name)")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }

            if packageInfoRaw == nil
            {
                HStack(alignment: .center)
                {
                    VStack(alignment: .center)
                    {
                        ProgressView
                        {
                            Text("package-details.contents.loading")
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
            else
            {
                if erroredOut
                {
                    InlineFatalError(errorMessage: "alert.generic.couldnt-parse-json")
                }
                else
                {
                    VStack(alignment: .leading, spacing: 10)
                    {
                        Text("package-details.info")
                            .font(.title2)

                        if let caveats
                        {
                            if !caveats.isEmpty
                            {
                                if caveatDisplayOptions == .full
                                {
                                    GroupBox
                                    {
                                        HStack(alignment: .top, spacing: 10)
                                        {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .resizable()
                                                .frame(width: 15, height: 15)
                                                .foregroundColor(.yellow)

                                            /// Remove the last newline from the text if there is one, and replace all double newlines with a single newline
                                            VStack(alignment: .leading, spacing: 5)
                                            {
                                                let text = Text(
                                                    .init(
                                                        caveats
                                                            .trimmingCharacters(in: .whitespacesAndNewlines)
                                                            .replacingOccurrences(of: "\n\n", with: "\n")
                                                    )
                                                )
                                                    .lineSpacing(5)

                                                text
                                                    .textSelection(.enabled)
                                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                                    .lineLimit(isShowingExpandedCaveats ? nil : 2)
                                                    .background
                                                {
                                                    ViewThatFits(in: .vertical)
                                                    {
                                                        text.hidden()
                                                        Color.clear.onAppear { canExpandCaveats = true }
                                                    }
                                                }

                                                if canExpandCaveats
                                                {
                                                    Button
                                                    {
                                                        withAnimation
                                                        {
                                                            isShowingExpandedCaveats.toggle()
                                                        }
                                                    } label: {
                                                        Text(isShowingExpandedCaveats ? "package-details.caveats.collapse" : "package-details.caveats.expand")
                                                    }
                                                    .padding(.top, 5)
                                                }
                                            }
                                        }
                                        .padding(2)
                                    }
                                }
                            }
                        }

                        GroupBox
                        {
                            Grid(alignment: .leading, horizontalSpacing: 20)
                            {
                                GridRow(alignment: .firstTextBaseline)
                                {
                                    Text("Tap")
                                    Text(tap)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                Divider()

                                GridRow(alignment: .top)
                                {
                                    Text("package-details.type")
                                    if package.isCask
                                    {
                                        Text("package-details.type.cask")
                                    }
                                    else
                                    {
                                        Text("package-details.type.formula")
                                    }
                                }

                                Divider()

                                GridRow(alignment: .top)
                                {
                                    Text("package-details.homepage")
                                    Link(destination: homepage)
                                    {
                                        Text(homepage.absoluteString)
                                    }
                                }
                            }
                        }

                        if let dependencies
                        {
                            GroupBox
                            {
                                VStack
                                {
                                    DisclosureGroup("package-details.dependencies")
                                    {
                                        DependencyList(dependencies: dependencies)
                                    }
                                    .disclosureGroupStyle(NoPadding())
                                }
                            }
                        }

                        if let installedOnDate = package.installedOn // Only show the "Installed on" date for packages that are actually installed
                        {
                            GroupBox
                            {
                                Grid(alignment: .leading, horizontalSpacing: 20)
                                {
                                    GridRow(alignment: .top)
                                    {
                                        Text("package-details.install-date")
                                        Text(installedOnDate.formatted(.packageInstallationStyle))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }

                                    if let packageSize = package.sizeInBytes
                                    {
                                        Divider()

                                        GridRow(alignment: .top)
                                        {
                                            Text("package-details.size")

                                            HStack
                                            {
                                                Text(packageSize.formatted(.byteCount(style: .file)))

                                                if package.isCask
                                                {
                                                    HelpButton
                                                    {
                                                        isShowingPopover.toggle()
                                                    }
                                                    .help("package-details.size.help")
                                                    .popover(isPresented: $isShowingPopover)
                                                    {
                                                        VStack(alignment: .leading, spacing: 10)
                                                        {
                                                            Text("package-details.size.help.title")
                                                                .font(.headline)
                                                            Text("package-details.size.help.body-1")
                                                            Text("package-details.size.help.body-2")
                                                        }
                                                        .padding()
                                                        .frame(width: 300, alignment: .center)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Spacer()

            if let _ = package.installedOn // Only show the uninstall button for packages that are actually installed
            {
                if packageInfoRaw != nil
                {
                    HStack
                    {
                        if !package.isCask
                        {
                            Button
                            {
                                Task
                                {
                                    pinned.toggle()

                                    await pinAndUnpinPackage(package: package, pinned: pinned)
                                }
                            } label: {
                                Text(pinned ? "package-details.action.unpin-version-\(package.versions.formatted(.list(type: .and)))" : "package-details.action.pin-version-\(package.versions.formatted(.list(type: .and)))")
                            }
                        }

                        Spacer()

                        HStack(spacing: 15)
                        {
                            UninstallationProgressWheel()
                            
                            if allowMoreCompleteUninstallations
                            {
                                Spacer()
                            }

                            if !allowMoreCompleteUninstallations
                            {
                                Button(role: .destructive)
                                {
                                    Task
                                    {
                                        try await uninstallSelectedPackage(
                                            package: package,
                                            brewData: brewData,
                                            appState: appState,
                                            outdatedPackageTracker: outdatedPackageTracker,
                                            shouldRemoveAllAssociatedFiles: false
                                        )
                                    }
                                } label: {
                                    Text("package-details.action.uninstall-\(package.name)")
                                }
                            }
                            else
                            {
                                Menu {
                                    Button(role: .destructive)
                                    {
                                        Task
                                        {
                                            try await uninstallSelectedPackage(
                                                package: package,
                                                brewData: brewData,
                                                appState: appState,
                                                outdatedPackageTracker: outdatedPackageTracker,
                                                shouldRemoveAllAssociatedFiles: true
                                            )
                                        }
                                    } label: {
                                        Text("package-details.action.uninstall-deep-\(package.name)")
                                    }
                                } label: {
                                    Text("package-details.action.uninstall-\(package.name)")
                                } primaryAction: {
                                    Task(priority: .userInitiated)
                                    {
                                        try! await uninstallSelectedPackage(
                                            package: package,
                                            brewData: brewData,
                                            appState: appState,
                                            outdatedPackageTracker: outdatedPackageTracker,
                                            shouldRemoveAllAssociatedFiles: false
                                        )
                                    }
                                }
                                .fixedSize()
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .task(priority: .userInitiated)
        {
            if !package.isCask
            {
                packageInfoRaw = await shell(AppConstants.brewExecutablePath.absoluteString, ["info", "--json=v2", package.name]).standardOutput
            }
            else
            {
                packageInfoRaw = await shell(AppConstants.brewExecutablePath.absoluteString, ["info", "--json=v2", "--cask", package.name]).standardOutput
            }

            do
            {
                let parsedJSON: JSON = try parseJSON(from: packageInfoRaw!)

                description = getPackageDescriptionFromJSON(json: parsedJSON, package: package)
                homepage = getPackageHomepageFromJSON(json: parsedJSON, package: package)
                tap = getPackageTapFromJSON(json: parsedJSON, package: package)
                installedAsDependency = getIfPackageWasInstalledAsDependencyFromJSON(json: parsedJSON, package: package) ?? false
                outdated = getIfPackageIsOutdated(json: parsedJSON, package: package)
                caveats = getCaveatsFromJSON(json: parsedJSON, package: package)
                pinned = getPinStatusFromJSON(json: parsedJSON, package: package)

                if let packageDependencies = getPackageDependenciesFromJSON(json: parsedJSON, package: package)
                {
                    dependencies = packageDependencies
                }

                if installedAsDependency
                {
                    async let packageDependentsRaw: String = await shell(AppConstants.brewExecutablePath.absoluteString, ["uses", "--installed", package.name]).standardOutput

                    packageDependents = await packageDependentsRaw.components(separatedBy: "\n").dropLast()

                    print("Package dependents: \(String(describing: packageDependents))")
                }
            }
            catch let packageInfoDecodingError
            {
                print("Failed while parsing package info: \(packageInfoDecodingError)")

                erroredOut = true
            }
        }
    }
}
