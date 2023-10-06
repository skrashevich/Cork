//
//  Updater Box.swift
//  Cork
//
//  Created by David Bureš on 05.04.2023.
//

import SwiftUI

struct OutdatedPackageListBox: View
{
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var outdatedPackageTracker: OutdatedPackageTracker

    @Binding var isDropdownExpanded: Bool

    var body: some View
    {
        Grid
        {
            GridRow(alignment: .firstTextBaseline)
            {
                VStack(alignment: .leading)
                {
                    GroupBoxHeadlineGroupWithArbitraryContent(image: outdatedPackageTracker.outdatedPackages.count == 1 ? "square.and.arrow.down" : "square.and.arrow.down.on.square")
                    {
                        VStack(alignment: .leading, spacing: 5)
                        {
                            HStack(alignment: .firstTextBaseline)
                            {
                                Text("start-page.updates.count-\(outdatedPackageTracker.outdatedPackages.count)")
                                    .font(.headline)

                                Spacer()

                                if outdatedPackageTracker.outdatedPackages.filter({ $0.isMarkedForUpdating }).count == outdatedPackageTracker.outdatedPackages.count
                                {
                                    Button
                                    {
                                        appState.isShowingUpdateSheet = true
                                    } label: {
                                        Text("start-page.updates.action")
                                    }
                                }
                                else
                                {
                                    Button
                                    {
                                        appState.isShowingIncrementalUpdateSheet = true
                                    } label: {
                                        Text("start-page.update-incremental.package-count-\(outdatedPackageTracker.outdatedPackages.filter { $0.isMarkedForUpdating }.count)")
                                    }
                                    .disabled(outdatedPackageTracker.outdatedPackages.filter { $0.isMarkedForUpdating }.count == 0)
                                }
                            }

                            DisclosureGroup(isExpanded: $isDropdownExpanded)
                            {
                                List
                                {
                                    Section
                                    {
                                        ForEach(outdatedPackageTracker.outdatedPackages.sorted(by: { $0.package.installedOn! < $1.package.installedOn! }))
                                        { outdatedPackage in
                                            Toggle(outdatedPackage.package.name, isOn: Binding<Bool>(
                                                get: {
                                                    outdatedPackage.isMarkedForUpdating
                                                }, set: { toggleState in
                                                    outdatedPackageTracker.outdatedPackages = Set(outdatedPackageTracker.outdatedPackages.map({ modifiedElement in
                                                        var copyOutdatedPackage = modifiedElement
                                                        if copyOutdatedPackage.id == modifiedElement.id
                                                        {
                                                            copyOutdatedPackage.isMarkedForUpdating = toggleState
                                                        }
                                                        return copyOutdatedPackage
                                                    }))
                                                }
                                            ))
                                        }
                                    } header: {
                                        HStack(alignment: .center, spacing: 10)
                                        {
                                            Button
                                            {
                                                outdatedPackageTracker.outdatedPackages = Set(outdatedPackageTracker.outdatedPackages.map({ modifiedElement in
                                                    var copyOutdatedPackage = modifiedElement
                                                    if copyOutdatedPackage.id == modifiedElement.id
                                                    {
                                                        copyOutdatedPackage.isMarkedForUpdating = true
                                                    }
                                                    return copyOutdatedPackage
                                                }))
                                            } label: {
                                                Text("start-page.updated.action.deselect-all")
                                            }
                                            .buttonStyle(.plain)
                                            .disabled(outdatedPackageTracker.outdatedPackages.filter { $0.isMarkedForUpdating }.count == 0)

                                            Button
                                            {
                                                outdatedPackageTracker.outdatedPackages = Set(outdatedPackageTracker.outdatedPackages.map({ modifiedElement in
                                                    var copyOutdatedPackage = modifiedElement
                                                    if copyOutdatedPackage.id == modifiedElement.id
                                                    {
                                                        copyOutdatedPackage.isMarkedForUpdating = false
                                                    }
                                                    return copyOutdatedPackage
                                                }))
                                            } label: {
                                                Text("start-page.updated.action.select-all")
                                            }
                                            .buttonStyle(.plain)
                                            .disabled(outdatedPackageTracker.outdatedPackages.filter { $0.isMarkedForUpdating }.count == outdatedPackageTracker.outdatedPackages.count)
                                        }
                                    }
                                }
                                .listStyle(.bordered(alternatesRowBackgrounds: true))
                            } label: {
                                Text("start-page.updates.list")
                                    .font(.subheadline)
                            }
                            .disclosureGroupStyle(NoPadding())
                        }
                    }
                }
            }
        }
    }
}
