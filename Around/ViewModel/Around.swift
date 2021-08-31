//
//  Around.swift
//  Around
//
//  Created by Nimesh Nayaju on 2021-08-22.
//

import Foundation
import Combine
import CoreLocation
import os.log

class Around: ObservableObject {

    var subscribers = Set<AnyCancellable>()
    var locationSubsriber: AnyCancellable?

    @Published private(set) var location: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus?
    
    @Published private (set) var home: CLLocationCoordinate2D?
    
    private func startFetchingLocationData() {
        CLLocationManager.publishAuthorizationStatus()
            .sink { status in
                self.authorizationStatus = status
                switch status {
                case .authorizedAlways:
                    os_log("Authorization to fetch background updates received. Subscribing to location updates", log: OSLog.location, type: .debug)
                    self.locationSubsriber = CLLocationManager.publishLocation()
                        .sink(receiveCompletion: { error in
                            os_log("Error while fetching location", log: OSLog.location, type: .debug)
                        }, receiveValue: { location in
                            os_log("Location: %@", log: OSLog.location, type: .debug, location.description)
                            self.location = location
//                            // check if the location is within the circle representing the home building
//                            if (isInsidePolygon_(location)) {
//                                //
//                            }
                            self.location = location
                        })
                case .authorizedWhenInUse, .denied, .notDetermined, .restricted:
                    os_log("Not enough permission to fetch background location information", log: OSLog.location, type: .debug)
                    self.location = nil
                    self.locationSubsriber?.cancel()
                @unknown default:
                    self.location = nil
                }
            }
            .store(in: &subscribers)
    }
    
    private func isInsidePolygon(_ location: CLLocation) -> Bool {
        return true;
    }
    
    // MARK: Intents
    func requestAlwaysAuthorization() {
        self.startFetchingLocationData()
    }
    
    func setHomeCoordinates(coordinate: CLLocationCoordinate2D) {
        os_log("Home coordinates set to (%@, %@)", log: OSLog.around, type: .debug, coordinate.latitude.description, coordinate.longitude.description)
        self.home = coordinate
    }
}
