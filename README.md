#  AcidLibrary

Библиотека для связи с периферией.

## Используется


В библиотеке 1 структура и 1 класс:

- struct BluetoothService, структура-оболочка для CBCentralManager, используемая для сканирования периферийных устройств, подключения и отправки команд с обратными вызовами в BluetoothServiceState.

- NetworkService, класс-оболочка для NSURLSession, используется для отправки запросов на проверку «ключа доступа» на облачном сервере. Обратные вызовы в NetworkServiceState.


## Установка 


1. Скопируйте AcidLibrary.framawork в свой проект.

2.  Разрешения к info.plist:

    - Privacy - Location When In Use Usage Description - `необходимо для обнаружения периферии в бэкграунде`
    - Privacy - Location Always and When In Use Usage Description - `необходимо для обнаружения периферии в бэкграунде`
    
    - Privacy - Bluetooth Peripheral Usage Description - `необходимо для поиска периферии`
    - Privacy - Bluetooth Always Usage Description - `необходимо для поиска периферии (iOS 13 or later)`
    
    - Privacy - Camera Usage Description - `сканировать qr-коды`
    
    - App Transport Security Settings - Allow Arbitrary Loads - YES
    
3. В info.plist добавить фоновые режимы:

    - App communicates using CoreBluetooth - `используется для сканирования и подключения к периферийному устройству в фоновом режиме`
    
    - App registers for location updates - `используются для определения расстояния до периферии в фоновом режиме`
    

### Начало работы

####  Command - зашифрованный пакет данных, который будет отправлен на периферию.
####  AccessKey - ключ доступа, полученный от периферии или облачного сервера, необходимый для отправки команды на периферию.

##### BluetoothService

Если вам нужно отправить запрос на разблокировку двери, используйте функцию `.openDoorRequest(completion: @escaping (BluetoothServiceState) -> Void)`:
```
private let taks: BluetoothService

init() {
  self.taks = BluetoothService.init()
}

public enum BluetoothServiceTaskMethod {

    case defaultMethod

    case backgroundMethod
}

public func openDoorRequest(method: BluetoothServiceTaskMethod) {
  self.taks.requestAccess { [weak self] state in
    print("\(type.self)")
  }
}

// Unknown response from the reader after request.
error
// Key was not found to apply for the reader.
noAccessKeyForReader
// Request finished correctly, but reader unable to inform about success or fail.
accepted
// Access finished successfully, person is able to pass.
granted
// Access finished successfully, person is not allowed to pass.
denied
// Unknown key was applied to the reader.
unidentified 
// Bluetooth is not enabled
bluetoothPowerOff

```

Если вам нужно отправить запрос на получение AccessKey от периферии, используйте функцию `.accessKeyRequest(completion: @escaping (BluetoothServiceState) -> Void)`:
```
private let taks: BluetoothService

init() {
  self.taks = BluetoothService.init()
}

public func accessKeyRequest() {
  self.taks.requestKeyFromDesktopReader { [weak self] state in
    print("\(type.self)")
  }
}

// The key is successfully issued by a desktop reader.
success
// The key is not issued due to reject by a desktop reader.
rejected
// The key is not issued due this type of already exists in the application.
keyTypeAlreadyExists
// The key is not issued due to there is no key left in the desktop reader.
noKeyLeft
// The key is not issued due to master card is not on the desktop reader.
noMasterCard
// The key is not issued due to unknown response from a desktop reader.
unknown
// Bluetooth is not enabled
bluetoothPowerOff

```

##### NetworkService

Если вам нужно отправить запрос на активацию QR-кода на облачном сервере, используйте функцию `.sendCodeToGetAnAccessKey(
  _ code: String, completion: @escaping (NetworkServiceState) -> Void)`:
```

baseTimeKeyServerUrl - ваш адрес на сервер временных меток.
basePermanentKeyServerUrl - ваш адрес на сервер постоянных меток.

private let networker: NetworkService

init() {
  self.networker = .init()
}

init() {
  self.networker = .init(
      config: NetworkServiceConfig(
          baseTimeKeyServerUrl: "https://basetimekey.com/api/",
          basePermanentKeyServerUrl: "https://basetimekey.com/api/",
          applicationName: "Application name"
      )
  )
}

private func sendCode(_ code: String) {
  self.networker.sendCodeToGetAnAccessKey(code) { [weak self] state in
    print("\(type.self)")
  }
}

```

##### AccessKeysService

Если вам нужно получить весь список «AccessKey»
используйте функцию  `.allAvailableAccessKeys(completion: @escaping ([AccessKey]) -> Void)` :
```
private var keysService: AccessKeysService

public init() {
  self.keysService = .init()
}

public func fetchAccessKeys() {
  self.keysService.getKeys { [weak self] keys in
    print(keys)
  }
}

```

Если вам нужно изменить ключ доступа по умолчанию, чтобы открыть дверь, используйте функцию `setDefaultAccessKey(_ key: AccessKey, completion: @escaping ([AccessKey]) -> Void) `:
```
private var keysService: AccessKeysService

public init() {
  self.keysService = .init()
}

public func fetchAccessKeys() {
  self.keysService.setDefaultAccessKey(key) { [weak self] updated in
    print(updated)
  }
}

```

Если вам нужно удалить ключ доступа из списка ключей, используйте функцию `.removeAccessKey(_ key: AccessKey, completion: @escaping ([AccessKey]) -> Void)`:
```
private var keysService: AccessKeysService

public init() {
  self.keysService = .init()
}

public func removeAccessKey() {
  self.keysService.removeAccessKey(key) { [weak self] updated in
    print(updated)
  }
}

```

Если вам нужно обновить отображаемое имя ключа доступа, используйте функцию `.updateAccessKeyName(_ key: AccessKey, completion: @escaping ([AccessKey]) -> Void)`:
```
private var keysService: AccessKeysService

public init() {
  self.keysService = .init()
}

public func updateDisplayedName() {
  self.keysService.updateAccessKeyName(key) { [weak self] updated in
    print(updated)
  }
}

```
