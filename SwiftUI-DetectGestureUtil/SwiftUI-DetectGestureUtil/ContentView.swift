//
//  ContentView.swift
//  SwiftUI-DetectGestureUtil
//
//  Created by IeSo on 2025/11/01.
//

import SwiftUI
import MyModuleFeatureDetectGesture

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("sample text".sayHello())
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
