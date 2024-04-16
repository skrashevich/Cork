//
//  Licensing View.swift
//  Cork
//
//  Created by David Bureš on 18.03.2024.
//

import SwiftUI

struct LicensingView: View
{
    @AppStorage("demoActivatedAt") var demoActivatedAt: Date?
    @AppStorage("hasValidatedEmail") var hasValidatedEmail: Bool = false
    
    @EnvironmentObject var appState: AppState
    
    var body: some View
    {
        VStack
        {
            switch appState.licensingState {
                case .notBoughtOrHasNotActivatedDemo:
                    Licensing_NotBoughtOrActivatedView()
                case .demo:
                    Licensing_DemoView()
                case .bought:
                    Licensing_BoughtView()
            }
        }
        .onAppear
        {
            appState.licensingState = .bought
        }
    }
}
