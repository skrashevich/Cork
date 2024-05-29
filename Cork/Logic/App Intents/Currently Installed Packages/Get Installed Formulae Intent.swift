//
//  Get Installed Formulae Intent.swift
//  Cork
//
//  Created by David Bureš on 25.05.2024.
//

import AppIntents
import Foundation

enum FolderAccessingError: Error
{
    case couldNotObtainPermissionToAccessFolder
}

struct GetInstalledFormulaeIntent: AppIntent
{
    @Parameter(title: "intent.get-installed-packages.limit-to-manually-installed-packages")
    var getOnlyManuallyInstalledPackages: Bool
    
    static var title: LocalizedStringResource = "intent.get-installed-formulae.title"
    static var description: LocalizedStringResource = "intent.get-installed-formulae.description"

    static var isDiscoverable: Bool = true
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some ReturnsValue<[MinimalHomebrewPackage]>
    {
        let allowAccessToFile: Bool = AppConstants.brewCellarPath.startAccessingSecurityScopedResource()
        
        if allowAccessToFile
        {
            let installedFormulae = await loadUpPackages(whatToLoad: .formula, appState: AppState())
            
            AppConstants.brewCellarPath.stopAccessingSecurityScopedResource()
            
            var minimalPackages: [MinimalHomebrewPackage] = installedFormulae.map { package in
                return .init(name: package.name, type: .formula, installedIntentionally: package.installedIntentionally)
            }
            
            if getOnlyManuallyInstalledPackages
            {
                minimalPackages = minimalPackages.filter({$0.installedIntentionally})
            }
            
            return .result(value: minimalPackages)
        }
        else
        {
            print("Could not obtain access to folder")
            throw FolderAccessingError.couldNotObtainPermissionToAccessFolder
        }
    }
}
