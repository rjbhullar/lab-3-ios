//
//  ViewController.swift
//  Lab-3
//
//  Created by Rajdeep Bhullar on 2022-07-17.
//

import CoreLocation
import UIKit

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {

  @IBOutlet weak var locationTextField: UITextField!
  @IBOutlet weak var weatherConditionImage: UIImageView!
  @IBOutlet weak var tempeartureLabel: UILabel!
  @IBOutlet weak var locationLabel: UILabel!
  @IBOutlet weak var weatherInfoStackView: UIStackView!

  @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
  let manager = CLLocationManager()

  @IBOutlet weak var errorLabel: UILabel!
  override func viewDidLoad() {
    super.viewDidLoad()
    errorLabel.isHidden = true
    weatherInfoStackView.isHidden = true
    loadingIndicator.hidesWhenStopped = true
    locationTextField.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    manager.delegate = self

  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.endEditing(true)
    getWeatherInfo(locationName: locationTextField.text)
    return true
  }

  func displaySunnyImage(weatherCondition: Int) {
    print(weatherCondition)
    let config = UIImage.SymbolConfiguration(paletteColors: [
      .systemYellow, .systemBlue, .systemCyan,
    ])
    weatherConditionImage.preferredSymbolConfiguration = config
    var weatherImage: String
    switch weatherCondition {
    case 1000:
      weatherImage = "sun.max"
    case 1003:
      weatherImage = "cloud.sun"
    case 1006, 1009:
      weatherImage = "cloud"
    case 1030:
      weatherImage = "cloud.fog"
    case 1069, 1072:
      weatherImage = "cloud.sleet"
    case 1087, 1117:
      weatherImage = "cloud.bolt.rain"
    case 1063, 1153, 1183, 1186, 1240, 1243, 1258:
      weatherImage = "cloud.rain"
    case 1066, 1114, 1213, 1225, 1237, 1255, 1276, 1279, 1282:
      weatherImage = "snowflake"
    default:
      weatherImage = "sun.max"
    }
      weatherConditionImage.image = UIImage(systemName: weatherImage)
  }

  @IBAction func onLocationTapped(_ sender: UIButton) {
    manager.requestWhenInUseAuthorization()
    manager.startUpdatingLocation()
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let location = locations.first {
      manager.stopUpdatingLocation()
      print("Location: \(location.coordinate.latitude)")
      getWeatherInfo(
        locationName: "\(location.coordinate.latitude),\(location.coordinate.longitude)")
    }
  }

  @IBAction func onSearchLoactionTap(_ sender: UIButton) {
    getWeatherInfo(locationName: locationTextField.text)
  }

  func getWeatherInfo(locationName: String?) {
    guard let locationName = locationName, !locationName.isEmpty else {
      return
    }
    errorLabel.isHidden = true
    weatherInfoStackView.isHidden = true
    loadingIndicator.startAnimating()
    let apiKey = "5e569c1d2d4b431482b203623221707"
    guard
      let myUrl =
        "https://api.weatherapi.com/v1/current.json?key=\(apiKey)&q=\(locationName)&aqi=no"
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    else {
      return
    }

    let url = URL(string: myUrl)
    guard let url = url else {
      print("could not get url")
      return
    }
    //create session
    let session = URLSession.shared

    //create task for session
    let sessionTask = session.dataTask(with: url) {
      data, response, error in
      DispatchQueue.main.async {
        self.loadingIndicator.stopAnimating()
      }
      guard error == nil, let data = data else {
        DispatchQueue.main.async {
          self.errorLabel.isHidden = false
        }
        return
      }

      if let weatherInfo = self.parseJSON(data: data) {
        DispatchQueue.main.async {
          self.locationLabel.text = weatherInfo.location.name
          self.tempeartureLabel.text = "\(weatherInfo.current.temp_c)\u{00B0}C"
          self.displaySunnyImage(weatherCondition: weatherInfo.current.condition.code)
          self.weatherInfoStackView.isHidden = false
        }

      }
    }

    //start task
    sessionTask.resume()
  }

  private func parseJSON(data: Data) -> WeatherResponse? {
    let decoder = JSONDecoder()
    var weatherInfo: WeatherResponse?
    do {
      weatherInfo = try decoder.decode(WeatherResponse.self, from: data)
    } catch {
      DispatchQueue.main.async {
        self.errorLabel.isHidden = false
      }
      print("Error Decoding: \(error)")
    }
    return weatherInfo
  }

  struct WeatherResponse: Decodable {
    let location: Location
    let current: Weather
  }

  struct Location: Decodable {
    let name: String
  }

  struct Weather: Decodable {
    let temp_c: Float
    let condition: WeatherCondition
  }

  struct WeatherCondition: Decodable {
    let text: String
    let code: Int
  }
}
