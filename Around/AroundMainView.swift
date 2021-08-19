//
//  AroundMainView.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-17.
//

import SwiftUI
import CoreMotion

struct AroundMainView: View {
    
    @ObservedObject var around: Around
    
    var body: some View {
        VStack {
            if around.isWalking {
                Text("user is walking");
            } else {
                Text("user is not walking")
            }
            if around.lookAround {
                Text("Look around")
            } else {
                Text("No need to look around")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let lookAround = Around()
//        lookAround.startTracking()
        AroundMainView(around: lookAround)
    }
}
