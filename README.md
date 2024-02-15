#  AcidLibrary

Бібліотека для зв'язку з периферією.

## Використовується


Бібліотека містить:

- struct BluetoothService, використовується для сканування периферійних пристроїв, підключення та надсилання команд зі зворотними викликами в RequestAccessResult та RequestKeyFromDesktopReaderResult.

- NetworkService, клас використовується для надсилання запитів на перевірку "ключа доступу" на хмарному сервері. Зворотні виклики в RequestKeyFromServerResult.

- AccessKeysService, клас використовується редагування назви "ключа доступу", видалення, зміни ключа за замовчуванням.


## Встановлення 


1. Скопіюйте u_prox_id_lib.framawork у свій проєкт.

2.  Дозволи для info.plist:

    - Privacy - Location When In Use Usage Description - `необхідно для виявлення периферії в бекграунді`
    - Privacy - Location Always and When In Use Usage Description - `необхідно для виявлення периферії в бекграунді`
    
    - Privacy - Bluetooth Peripheral Usage Description - `необхідно для пошуку периферії`
    - Privacy - Bluetooth Always Usage Description - `необхідно для пошуку периферії (iOS 13 or later)`
    
    - Privacy - Camera Usage Description - `сканувати qr-коди`
    
    - App Transport Security Settings - Allow Arbitrary Loads - YES
    
3. В info.plist додати фонові режими:

    - App communicates using CoreBluetooth - `використовується для сканування і підключення до периферійного пристрою у фоновому режимі`
    
    - App registers for location updates - `використовуються для визначення відстані до периферії у фоновому режимі`
    

### Початок роботи

####  Command - зашифрований пакет даних, який буде надіслано на периферію.
####  AccessKey - ключ доступу, отриманий від периферії або хмарного сервера, необхідний для надсилання команди на периферію.

##### BluetoothService

Якщо вам потрібно надіслати запит на розблокування дверей, використовуйте функцію
 `requestAccess(
    keyID: UUID,
    completion: @escaping (RequestAccessResult) -> Void
  )`
  
  де keyID: UUID - унікальний id ключа доступу
  
```
private let bleService: BluetoothService

init() {
  self.bleService = BluetoothService.init()
}

public func openDoorRequest() {
  self.bleService.requestAccess(keyID: "ID ключа") { [weak self] state in
    print("\(type.self)")
  }
}

Можливі варіанти відповіді: 

case error // Unknown response from the reader after request.
case noAccessKeyForReader // Key was not found to apply for the reader.
case accepted // Request finished correctly, but reader unable to inform about success or fail.
case granted // Access finished successfully, person is able to pass.
case denied // Access finished successfully, person is not allowed to pass.
case unidentified // Unknown key was applied to the reader.
case bluetoothPowerOff // Bluetooth is not enabled
case timeout // в деяких випадках цей стан може означати що периферія прийняла команду від додатку але відповідь не надіслала (хоча фактично дія пройшла успішно)

```

Якщо вам потрібно надіслати запит на отримання AccessKey від периферії, використовуйте функцію `.requestKeyFromDesktopReader(
completion: @escaping (RequestKeyFromDesktopReaderResult
) -> Void)`

```

private let bleService: BluetoothService

init() {
  self.bleService = BluetoothService.init()
}

public func accessKeyRequest() {
  self.bleService.requestKeyFromDesktopReader { [weak self] state in
    print("\(type.self)")
  }
}

Можливі варіанти відповіді:

case success // The key is successfully issued by a desktop reader.
case rejected // The key is not issued due to reject by a desktop reader.
case keyTypeAlreadyExists // The key is not issued due this type of already exists in the application.
case noKeyLeft // The key is not issued due to there is no key left in the desktop reader.
case noMasterCard // The key is not issued due to master card is not on the desktop reader.
case unknown // The key is not issued due to unknown response from a desktop reader.
case bluetoothPowerOff // Bluetooth is not enabled

```

##### NetworkService

Якщо вам потрібно надіслати запит на активацію QR-коду на хмарному сервері, використовуйте функцію`.sendCodeToGetAnAccessKey(
  _ code: String,
   completion: @escaping (RequestKeyFromServerResult
   ) -> Void)`
   
```

private let networker: NetworkService

init() {
  self.networker = .init()
}

private let baseTimeKeyServerUrl: String? = "ваша адреса на сервер тимчасових міток"
private let basePermanentKeyServerUrl: String? = "ваша адреса на сервер постійних міток"

private func sendCode(_ code: String) {
    Task {
        self.networker.setConfig(
            .init(
                token: AppStorage.firebaseToken, // Опціонально
                baseTimeKeyServerUrl: baseTimeKeyServerUrl, // Опціонально
                basePermanentKeyServerUrl: basePermanentKeyServerUrl, // Опціонально
                applicationName: "UPROX" // назва додатку (узгодити з сапортом)
            )
        )
        do {
            let result = try await self.networker.sendCodeToGetAnAccessKey(code)
 
            await MainActor.run {
                print("\(result.self)")
            }
        } catch let error as AppError {
            await MainActor.run {
                print("\(error.self)")
            }
        }
    }
}

Можливі варіанти відповіді:
    
case success // The key is successfully issued by a remote server.
case rejected // The key is not issued due to reject by a remote server.
case keyTypeAlreadyExists // The key is not issued due this type of already exists in the application.
case unknown(AppError) // The key is not issued due to unknown response from a remote server.

```

##### AccessKeysService

Якщо вам потрібно отримати весь список «AccessKey»
використовуйте функцію  `getKeys()`

```
private var keysService: AccessKeysService

public init() {
  self.keysService = .init()
}

private func actualizeAccessKeys() async {
  let list = await self.keysService.getKeys()
  await MainActor.run {
      print(result)
  }
}

```

Якщо потрібно призначити ключ, який буде використовуватись за замовчуванням, щоб відкрити двері (наприклад по включенню екрану), використовуйте функцію `setDefaultAccessKey(_ key: AccessKey) `

```

private var keysService: AccessKeysService

public init() {
  self.keysService = .init()
}

private func actualizeSelectedKeyOnStorage() {
    Task(priority: .background) {
            await self.keysService.setDefaultAccessKey(currentKey)
    }
}

```

Якщо потрібно видалити ключ доступу зі списку ключів, використовуйте функцію `.removeAccessKey(_ key: AccessKey)`
Увага!!! Видалення ключа - незворотня дія!!!

```
private var keysService: AccessKeysService

public init() {
  self.keysService = .init()
}

func deleteKey() {
    Task {
       let list = await self.keysService.removeAccessKey(key)
       
       await MainActor.run {
      		print(result)
  		}
    }
}

```

Якщо потрібно оновити назву ключа, що відображається в інетрфейсі, використовуйте функцію `.updateAccessKeyName(_ key: AccessKey)`

```
private var keysService: AccessKeysService

public init() {
  self.keysService = .init()
}

public func changeKeyName(_ new: String) {
    Task {
        guard var key = self.getCurrentSelectedKey() else { return }
        key.displayedName = new
        let updatedList = await self.keysService.updateAccessKeyName(key)
        
        await MainActor.run {
            print(result)
        }
    }
}

```
