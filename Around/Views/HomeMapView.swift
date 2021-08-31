//
//  HomeMapView.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-29.
//

import SwiftUI
import MapKit

struct HomeMapView: View {
    @ObservedObject var around: Around
    
    @State var centerCoordinate: CLLocationCoordinate2D
    @State var locations =  [MKPointAnnotation]()
    @State private var pinnedCoordinate: CLLocationCoordinate2D?
    @State private var homeIsSelected = false
    
    var body: some View {
        ZStack {
            MapView(centerCoordinate: $centerCoordinate, annotations: locations)
                .edgesIgnoringSafeArea(.all)
            Circle()
                .fill(Color.blue)
                .opacity(0.3)
                .frame(width: 32, height: 32)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    pinButton
                    if pinnedCoordinate != nil {
                        doneButton
                    }

                }
            }
        }
    }
    
    private var pinButton: some View {
        Button(action: {
            self.locations.removeAll()
            let home = MKPointAnnotation()
            home.coordinate = self.centerCoordinate
            self.locations.append(home)
            self.pinnedCoordinate = home.coordinate
        }, label: {
            Image(systemName: "mappin.and.ellipse")
                .padding()
        })
        .background(Color.black.opacity(0.75))
        .foregroundColor(.white)
        .font(.title)
        .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
        .padding(.trailing)
    }
    
    private var doneButton: some View {
        Button(action: {
            if pinnedCoordinate != nil {
                around.setHomeCoordinates(coordinate: self.pinnedCoordinate!)
                self.homeIsSelected = true
            }
        }, label: {
            Image(systemName: "checkmark")
                .padding()
        })
        .alert(isPresented: $homeIsSelected, content: {
            Alert(title: Text("Home building annotated"), message: Text("Around has ben set up successfully. You'll start receiving notifications from Around"), dismissButton: Alert.Button.default(Text("Dismiss")))
        })
        .background(Color.black.opacity(0.75))
        .foregroundColor(.white)
        .font(.title)
        .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
        .padding(.trailing)
    }
}

struct HomeMapView_Previews: PreviewProvider {
    static var previews: some View {
        HomeMapView(around: Around(), centerCoordinate: CLLocationCoordinate2D(latitude: 50.0730393511899, longitude: -119.41216717736901))
    }
}
