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
    @State var isAuthorized = false
    @State var requestPermissionAlert = false
    @State var cannotStartAround = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Permissions").fontWeight(.bold), footer: Text("Around sends notifications to look around when you're walking and using your phone.").font(.caption2)) {
                     
                    switch around.authorizationStatus {
                    case .authorizedAlways:
                        Text("Background location authorization received")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    case .notDetermined:
                        requestAuthorizationButton
                    default:
                        requestAuthorizationSettingsButton
                    }
                    
                    Toggle(isOn: $around.locationTracking, label: {
                        Text("Use Around").font(.subheadline)
                            .onChange(of: around.locationTracking) { shouldReceiveLocationUpdates in
                                if shouldReceiveLocationUpdates {
                                    if around.isAuthorized() {
                                        around.receiveLocationUpdates(true)
                                    } else {
                                        self.cannotStartAround = true
                                        around.locationTracking = false
                                    }
                                } else {
                                    if around.isAuthorized() {
                                        around.receiveLocationUpdates(false)
                                    }
                                }
                            }
                    })
                    .toggleStyle(CheckboxToggleStyle())
                    .alert(isPresented: $cannotStartAround, content: {
                        Alert(
                            title: Text("Background location authorization required"),
                            message: Text("Enable background location authorization to use Around"),
                            dismissButton: .cancel()
                        )
                    })
                }
                Section(header: Text("Annotation (Optional)").fontWeight(.bold), footer: Text("Annotate to disable Around notifications when you're inside your home building.").font(.caption2)) {
                    if let home = around.getHomeCordinate() {
                        NavigationLink(destination: HomeMapView(around: around, centerCoordinate: around.getCurrentCoordinates(), locations: [MKPointAnnotation(home)])) {
                            Text("Update your home location").font(.subheadline)
                        }
                        HStack {
                            Text("Home Location")
                            Spacer()
                            Text("\(home.latitude), \(home.longitude)")
                                .foregroundColor(.gray)
                        }
                        .font(.subheadline)
                    } else {
                        NavigationLink(destination: HomeMapView(around: around, centerCoordinate: around.getCurrentCoordinates())) {
                            Text("Annotate your home location").font(.subheadline)
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Around"))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var requestAuthorizationButton: some View {
        Button(action: {
            around.requestAlwaysAuthorization()
        }, label: {
            Text("Enable background location updates").font(.subheadline)
        })
    }
    
    private var requestAuthorizationSettingsButton: some View {
        Button(action: {
            self.requestPermissionAlert = true
        }, label: {
            Text("Not enough permission")
                .font(.subheadline)
        })
        .alert(isPresented: $requestPermissionAlert) {
            Alert(
                title: Text("Couldn't receive required permissions"),
                message: Text("Click on the link to go to settings to turn on the required permission"),
                primaryButton: .default(Text("Settings")) {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                },
                secondaryButton: .cancel())
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        return HStack {
            configuration.label
            
            Spacer()
            
            Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                .resizable()
                .accessibility(label: Text(configuration.isOn ? "Checked" : "Unchecked"))
                .frame(width: 22, height: 22)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let around = Around()
        AroundMainView(around: around).preferredColorScheme(.dark)
//        AroundMainView(around: around).preferredColorScheme(.light)
    }
}
