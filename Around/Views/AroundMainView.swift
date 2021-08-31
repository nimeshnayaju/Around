//
//  AroundMainView.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-17.
//

import SwiftUI
import MapKit

struct AroundMainView: View {

    @ObservedObject var around: Around

    var body: some View {
        NavigationView {
            VStack {
                if let status = around.authorizationStatus {
                    if status == .authorizedAlways {
                        Label("Background location update permission received", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.green)
                            .padding(.horizontal)
                    } else {
                        Text("Not enough permission to fetch background location information. Please update the location permission for Around in your device settings to complete the setup")
                            .font(.system(size: 13))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                } else {
                    requestAuthorizationButton
                }
                Text("Around requires periodic location updates so that the app doesn't send you notifications when you're at home.")
                    .fontWeight(.light)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .padding(4)
                
                Spacer()
                
                if let status = around.authorizationStatus {
                    if status == .authorizedAlways {
                        if around.home == nil {
                            Text("Please annotate your home building to complete setting up Around")
                                .fontWeight(.light)
                                .font(.system(size: 10))
                                .multilineTextAlignment(.center)
                                .font(.footnote)
                            
                            NavigationLink(destination: HomeMapView(around: around, centerCoordinate: getCenterCoordinate())) {
                                Label("Annotate your home building", systemImage: "pin")
                                    .font(.system(size: 12))
                                    .padding()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10.0)
                                            .stroke(lineWidth: 1.5)
                                    )
                                }
                        } else {
                            Text("Around has been set up successfully!")
                                .fontWeight(.regular)
                                .foregroundColor(.green)
                                .font(.system(size: 11))
                                .multilineTextAlignment(.center)
                                .font(.footnote)
                            
                            NavigationLink(destination: HomeMapView(around: around, centerCoordinate: getCenterCoordinate(), locations: [MKPointAnnotation(around.home!)])) {
                                Label("Update your home location", systemImage: "pin")
                                    .font(.system(size: 12))
                                    .padding()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10.0)
                                            .stroke(lineWidth: 1.5)
                                    )
                                }
                        }

                    }
                }
            }
        }
    }
    
    private func getCenterCoordinate() -> CLLocationCoordinate2D {
        if around.location != nil {
            return around.location!.coordinate
        } else {
            return CLLocationCoordinate2D()
        }
    }
    
    private var requestAuthorizationButton: some View {
        Button(action: {
            around.requestAlwaysAuthorization()
        }, label: {
            Label("Enable background location updates", systemImage: "location.circle.fill")
                .font(.system(size: 13))
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let around = Around()
        AroundMainView(around: around)
    }
}
