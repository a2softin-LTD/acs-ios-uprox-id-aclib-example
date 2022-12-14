//
//  BGWorker.swift
//  AcidDemo
//
//  Created by Yevhen Khyzhniak on 18.11.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import AcidLibrary
import CoreLocation
import Foundation
import UIKit

/// Для работи режима "свободные руки"
/// 1. Необходимо подписаться под нотификации в методе - startMonitoringBeaconsRegion
/// 2. Когда телефон находится в зоне действия маяков, запускать скан эфира - startRangingBeacons
/// Когда телефон будет в зона действия маяков - будет обратный вызов в методах:
/// locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) , где CLRegionState - INSIDE
/// или
/// locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion)
/// так же нужно стопать процесс поиска маяков - stopRangingBeacons, когда система сделает обратный вызов в методах:
/// locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion)
/// или
/// locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion), где CLRegionState - OUTSIDE

/// Для работи режима "по вкл экрана"
/// 1. Нужна Дарвин подписка на Экран (ВКЛ/ВЫКЛ)
/// 2. И "толчок" в виде startMonitoringBeaconsRegion - для того, чтобы CBCentralManager начал искать периферию в background режиме

final class BgAccessRequestTask: NSObject {

  //MARK: - Private Enum

  private enum BgAccessRequestTaskType {
    case handsFree
    case onTurnOnScreen
    case disabledAll
  }

  //MARK: - Singleton

  public static let shared = BgAccessRequestTask()

  //MARK: - Private Constants

  private let beaconRegionUUID = "6DBA3E9E-F6E0-4B65-B6A8-1C259E306918"
  private let minimumValidRSSIValue = -65

  //MARK: - Private Properties

  private lazy var locationManager: CLLocationManager = CLLocationManager()
  private let requestTask = BluetoothService.init()
  private let bgTask: BackgroundTask = .init()
  private var regions: [CLBeaconRegion] = []

  private var lastTypeCLProximity: CLProximity?
  private var handsFreeCommandInProcess: Bool = false
  private var beaconScannerWasStarted: Bool = false

  //MARK:  - Private Init

  private override init() {
    super.init()
    self.initialBeaconRegionArray()
    self.configureLocationManager()
    self.subscribeOnNotifications()
  }

  //MARK: - Private Computed Properties

  private var bgTaskType: BgAccessRequestTaskType {
    if AppPreferences.turnByScreenMode {
      return .onTurnOnScreen
    } else if AppPreferences.handsFreeMode {
      return .handsFree
    } else {
      return .disabledAll
    }
  }

  //MARK: - Public Methods

  public func startMonitoring() {
    self.subscribeOnDisplayStatus()
  }
}

extension BgAccessRequestTask {

  //MARK: - Private Methods (AcidRequestTask)

  private func sendCommand() {
    self.bgTask.registerBackgroundTask()
    self.requestTask.requestAccess(method: .backgroundMethod) { [weak self] state in
      switch state {
      default:
        switch self?.bgTaskType {
        case .onTurnOnScreen:
          self?.stopMonitoringBeaconsRegion()
        case .handsFree:
          self?.handsFreeCommandInProcess = false
        default:
          break
        }
        self?.bgTask.endBackgroundTask()
      }
    }
  }
}

extension BgAccessRequestTask {

  //MARK: - Public Methods (Core Location)

  func configureLocationManager() {
    self.locationManager.delegate = self
    self.locationManager.requestAlwaysAuthorization()
    self.locationManager.startUpdatingLocation()
    self.locationManager.allowsBackgroundLocationUpdates = true
    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    self.stopMonitoringBeaconsRegion()
  }

  //MARK: - Private Methods (Core Location)

  func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
    ///locationManager(_:didDetermineState:for:)
    locationManager.requestState(for: region)
  }

  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    self.lastTypeCLProximity = nil
    self.startRangingBeacons()
    self.writeLog(
      m: "Вход в регион действия зарегистрированого iBeacon маяка", type: .prepareConnect)
  }

  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    self.lastTypeCLProximity = nil
    self.stopRangingBeacons()
    self.writeLog(m: "Выход из региона действия зарегистрированого iBeacon маяка", type: .warning)
  }
}

extension BgAccessRequestTask {

  //MARK: - Private Methods (IBeacon)

  private func startMonitoringLocationDidChanged() {
    self.locationManager.startUpdatingLocation()
    self.locationManager.startMonitoringSignificantLocationChanges()
    self.startMonitoringBeaconsRegion()
  }

  /// Инициализация регионов для мониторинга
  private func initialBeaconRegionArray() {
    let uuid: UUID = UUID(uuidString: self.beaconRegionUUID)!
    let clBeaconRegion: CLBeaconRegion = CLBeaconRegion(
      beaconIdentityConstraint: CLBeaconIdentityConstraint(uuid: uuid), identifier: uuid.uuidString)
    self.regions.append(clBeaconRegion)
  }

  /// Подписка на мониторинг входа и выход
  private func startMonitoringBeaconsRegion() {
    for region in regions {
      region.notifyOnEntry = true
      region.notifyOnExit = true
      region.notifyEntryStateOnDisplay = true
      locationManager.startMonitoring(for: region)
    }
  }

  /// Запуск процеса сканирования эфира для всех регионов, на которые была подписка
  /// Для экономии ресурса аккума телефона - метод вызывать только, когда телефон находится в зоне действия маяков (в регионе)
  /// Результат падает в метод locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion)
  private func startRangingBeacons() {
    for region in regions {
      locationManager.startRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: region.uuid))
    }
  }

  /// Отмена всех возможных подписок в CLLocationManager
  private func stopMonitoringBeaconsRegion() {
    for region in self.locationManager.monitoredRegions {
      locationManager.stopMonitoring(for: region)
    }
  }

  /// Стоп процеса сканирования эфира для регионов, на которые была подписка
  private func stopRangingBeacons() {
    for region in regions {
      locationManager.stopRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: region.uuid))
    }
  }

}

extension BgAccessRequestTask: CLLocationManagerDelegate {

  func locationManager(
    _ manager: CLLocationManager,
    didRangeBeacons beacons: [CLBeacon],
    in region: CLBeaconRegion
  ) {
    guard
      self.bgTaskType == .handsFree,
      UIApplication.shared.applicationState != .active,
      !beacons.isEmpty
    else {
      self.writeLog(
        m: "Не найдено зарегистрированных iBeacon маяков - сброс попыток", type: .warning)
      self.lastTypeCLProximity = nil
      return
    }
    self.preparationForFindingRightBeacon(beacons: beacons, region: region)
  }

  func locationManager(
    _ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion
  ) {
    if self.bgTaskType == .handsFree
      && UIApplication.shared.applicationState != .active
    {
      switch state {
      case .inside:
        self.writeLog(
          m: "Находится в зоне действия зарегистрированого iBeacon маяка", type: .startConnect)
        self.startRangingBeacons()
      case .outside:
        self.lastTypeCLProximity = nil
        self.writeLog(m: "Покинул зону действия зарегистрированого iBeacon маяка", type: .warning)
        self.stopRangingBeacons()
      default:
        break
      }
    }
  }

  /// Предварительный фильтр для найденных маяков в регионе
  private func preparationForFindingRightBeacon(beacons: [CLBeacon], region: CLBeaconRegion) {
    if self.bgTaskType == .handsFree,
      UIApplication.shared.applicationState != .active
    {
      if self.regions.contains(where: { $0.uuid == region.uuid }) {
        let sortedBeacons =
          beacons
          .filter { $0.proximity != .unknown }
          .sorted(by: { ($0.proximity.rawValue < $1.proximity.rawValue) })
        if let findedBeacon = sortedBeacons.first {
          self.preparationToSendAccessKeyOnHandsFreeMode(
            findedBeacon.proximity,
            rssi: findedBeacon.rssi
          )
        }
      }
    }
  }

  /// Подготовка к отправке комманды на считыватель
  private func preparationToSendAccessKeyOnHandsFreeMode(_ distance: CLProximity, rssi: Int) {
    if !self.handsFreeCommandInProcess {
      if distance == .immediate && rssi > self.minimumValidRSSIValue {
        self.handsFreeCommandInProcess = true
        self.writeLog(
          m:
            "Найден зарегистрированый iBeacon маяк(2 попытка c rssi/ min - \(self.minimumValidRSSIValue): дистанция - \(distance.description), rssi - \(rssi) ",
          type: .prepareConnect)
        self.sendCommand()
      }
    }
    self.lastTypeCLProximity = distance
  }
}

extension BgAccessRequestTask {

  //MARK: - Private Methods (Notification Center)

  /// Підписка на отримання Дарвін нотифікацій про вкл/викл екрану телефону
  private func subscribeOnDisplayStatus() {
    DisplayManager.methodStart()
  }

  private func subscribeOnNotifications() {
    NotificationCenter.default.addObserver(
      self, selector: #selector(willTerminateNotification(_:)),
      name: UIApplication.willTerminateNotification, object: nil)

    NotificationCenter.default.addObserver(
      self, selector: #selector(didEnterBackgroundNotification(_:)),
      name: UIApplication.didEnterBackgroundNotification, object: nil)

    NotificationCenter.default.addObserver(
      self, selector: #selector(displayOn), name: NSNotification.Name(keyNotifDisplayOn),
      object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(displayOff), name: NSNotification.Name(keyNotifDisplayOff),
      object: nil)
  }

  @objc private func displayOn(_ notification: Notification) {
    switch self.bgTaskType {
    case .onTurnOnScreen:
      self.startMonitoringBeaconsRegion()
      self.sendCommand()
    default:
      break
    }
  }

  @objc private func displayOff(_ notification: Notification) {
    self.bgTask.endBackgroundTask()
  }

  @objc private func willTerminateNotification(_ notification: Notification) {
    self.writeLog(m: "will Terminate Notification", type: .base)
    if self.bgTaskType == .handsFree {
      self.startMonitoringLocationDidChanged()
    }
  }

  @objc private func didEnterBackgroundNotification(_ notification: Notification) {
    self.writeLog(m: "did Enter Background Notification", type: .base)
    if self.bgTaskType == .handsFree {
      self.startMonitoringLocationDidChanged()
    }
  }

}

extension BgAccessRequestTask {

  private func writeLog(m: String, type: LogMessageType) {
    LogsManager.shared.writeLog(
      .init(
        message: m, type: type,
        devices: []))
  }

}

extension CLProximity {
  var description: String {
    switch self.rawValue {
    case 1: return "Immediate"
    case 2: return "Near"
    case 3: return "Far"
    default: return "Unknown"
    }
  }
}
