//
//  Tap - Adding.swift
//  Cork
//
//  Created by David Bureš on 05.12.2023.
//

import SwiftUI

struct AddTapAddingView: View
{
    let requestedTap: String
    let forcedRepoAddress: String
    
    @Binding var progress: TapAddingStates
    @Binding var tappingError: TappingError
    
    var body: some View
    {
        ProgressView
        {
            Text("add-tap.progress-\(requestedTap)")
        }
        .task(priority: .medium)
        {
            var tapResult: String
            
            if forcedRepoAddress.isEmpty
            {
                tapResult = await addTap(name: requestedTap)
            }
            else
            {
                tapResult = await addTap(name: requestedTap, forcedRepoAddress: forcedRepoAddress)
            }

            print("Result: \(tapResult)")

            if tapResult.contains("Tapped")
            {
                print("Tapping was successful!")
                progress = .finished
            }
            else
            {
                progress = .error
                tappingError = .other

                if tapResult.contains("Repository not found")
                {
                    print("Repository was not found")

                    tappingError = .repositoryNotFound
                }
            }
        }
    }
}
