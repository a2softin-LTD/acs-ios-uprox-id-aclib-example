#  AcidLibrary

Бібліотека для зберігання, обробки та передачі мобільних ідентифікаторів до зчитувачів (периферійних пристроїв, PD) U-PROX(tm).

Бібліотека дозволяє працювати з постійними, шифрованими, та  тимчасовими мобільними ідентифікаторами (ключами)

**Постійні мобільні ідентифікатори**
    
Ключі, які можна завантажити в додаток на смартфоні тільки один раз. 
Період життя - весь час, поки не буде видалений додаток, чи ключ з додатку, чи смартфон не вийде з ладу.
Ключ (в вигляді контрейнера з зашифрованими даними) можна отримати від настільного зчитувача, чи по одноразовому QR з хмарного сервера постійни мобільних ідентифікаторів.


**Тимчасові мобільні ідентифікатори**
    
Багаторазові мобільні ідентифікатори, можуть бути видані на певний час користувачу.
Тимчасові мобільні ідентифікатори мають дату початку та дату закінчення дії, а також можіть керуватися з хмарного серверу - наприклад продовжуватися строк дії чи видалятися зі смартфону користвача (відкликатися)
Ключ можна отримати по QR коду від серверу тимчасових мобільних міток

        
**Шифровані мобільні ідентифікатори**
    
Ключі з додатковим шифруванням контейнеру даних. 
Пароль шифрування встановлюється в настольному зчитувачі чи на хмарному сервері перед видачею ключа в користувацький додаток.
Ключ можна отримати як від настільного зчитувача так і по QR коду від хмарних серверів.


> [!IMPORTANT]
> Для роботи з тимчасовими мітками необхідно використовувати firebase в вашому додатку. Зв'яжіться з нами для отримання додаткової інформації та інструкцій

## Призначення

- Надати можливість вбудовування мобільної ідентифікації в додатки замовника

- Надати прості методи для роботи з постійними, шифрованими, та  тимчасовими мобільними ідентифікаторами

- Бібліотека надає всі методи для повноцінної роботи з мобільними ідентифікаторами: 
  - Встановлення адреси сервера, на якому міститься платформа мобільних ідентифікаторів 
  - Отримання ідентифікаторів
  - Зберігання ідентифікаторів
  - Обробка push команд від хмарного сервера
  - Передача мобільних ідентифікаторів до зчитувача по 2.4 ГГц радіо (BLE) и NFC

- Бібліотека містить демо додаток для швидкого старту 

## Бібліотека

Бібліотека містить методи:

- struct BluetoothService, використовується для сканування периферійних пристроїв, підключення та надсилання команд зі зворотними викликами в RequestAccessResult та RequestKeyFromDesktopReaderResult.

- NetworkService, клас використовується для надсилання запитів на перевірку "ключа доступу" на хмарному сервері. Зворотні виклики в RequestKeyFromServerResult.

- AccessKeysService, клас використовується редагування назви "ключа доступу", видалення, зміни ключа за замовчуванням.

- RemoteNotification, структура для обробки push-сповіщень та управління станом ключів через віддалені команди.


## Встановлення 

1. Скопіюйте u_prox_id_lib.framawork у свій проєкт.

2.  Дозволи для info.plist:

    - Privacy - Location When In Use Usage Description - `необхідно для виявлення периферії у фоновому режимі`
    - Privacy - Location Always and When In Use Usage Description - `необхідно для виявлення периферії у фоновому режимі`
    
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

Якщо вам потрібно надіслати запит до зчитувача на відкриття дверей, використовуйте функцію
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

case error // Помилка в відповіді зчитувача (Unknown response from the reader after request.)
case noAccessKeyForReader // Не визначено ключ для передачі зчитувачу (Key was not found to apply for the reader.)
case accepted // Виконано успішно, зчитувач не може підтвердити результат (Request finished correctly, but reader unable to inform about success or fail.)
case granted // Виконано успішно, доступ дозволено (Access finished successfully, person is able to pass.)
case denied // Виконано успішно, доступ заборонено (Access finished successfully, person is not allowed to pass.)
case unidentified // Обраний ключ не може бути опрацьований зчитувачем (Unknown key was applied to the reader.)
case bluetoothPowerOff // Bluetooth не включено (Bluetooth is not enabled)
case timeout // Виконано успішно, проте не отримано відповідь від зчитувача. В деяких випадках цей стан може означати що периферія прийняла команду від додатку, але відповідь не надіслала (хоча фактично дія пройшла успішно)

```

###### Ручний пошук зчитувача та передача ключа

Метод `requestAccess` самостійно сканує периферію, підключається до найближчого зчитувача за умовами та відправляє ключ. Якщо потрібно, щоб користувач сам обрав зчитувач перед відправкою ключа, використовуйте публічні методи `discoverAccessPoints` та `connect`.

1. Викликайте `discoverAccessPoints`, щоб отримати список доступних зчитувачів. У відповідь приходить масив `AccessPoint` з `identifier` та `name`, далі ви можете показати його у своєму UI.
2. Після вибору зчитувача викличте `connect(to:key:isBackground:completion:)`, передаючи обраний `AccessPoint` та `AccessKey`. Колбек повертає той самий `RequestAccessResult`, що й `requestAccess`.

```swift
private let bleService = BluetoothService()
private let keysService = AccessKeysService()

func manualSend() async {
  let keys = await self.keysService.getKeys()
  guard let key = keys.first else { return } // обираємо потрібний ключ

  self.bleService.powerCorrection = 1.0 // необов'язково: налаштування радіусу пошуку

  self.bleService.discoverAccessPoints { points in
    // тут можна дати користувачу обрати зчитувач з points
    guard let point = points.first else { return }

    self.bleService.connect(to: point, key: key) { result in
      print(result) // RequestAccessResult
    }
  }
}
```

Якщо вам потрібно надіслати запит на отримання ключа(AccessKey) від настільного зчитувача, використовуйте функцію `.requestKeyFromDesktopReader(
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

case success // Ключ видано успішно з настільного зчитувача (The key is successfully issued by a desktop reader.)
case rejected // Ключ не видано, настільний зчитувач відхилив запит (The key is not issued due to reject by a desktop reader.)
case keyTypeAlreadyExists // Ключ не видано, так як ключ з таким типом вже збережено в додатку ( The key is not issued due this type of already exists in the application.)
case noKeyLeft // Ключ не видано, настільний зчитувач не має ліцензій на ключі (The key is not issued due to there is no key left in the desktop reader.)
case noMasterCard // Ключ не видано, відсутня майстер картка на настільному зчитувачі (The key is not issued due to master card is not on the desktop reader.)
case unknown // Ключ не видано, відповідь від настільного зчитувача не розпізнана (The key is not issued due to unknown response from a desktop reader.)
case bluetoothPowerOff // Bluetooth не включено (Bluetooth is not enabled)

```

##### NetworkService

Якщо вам потрібно надіслати запит на отримання ключа по QR-коду на хмарному сервері, використовуйте функцію`.sendCodeToGetAnAccessKey(
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
    
case success // Ключ видано хмарним сервером (The key is successfully issued by a remote server.)
case rejected //  Ключ не видано хмарним сервером (The key is not issued due to reject by a remote server.)
case keyTypeAlreadyExists // Ключ не видано, так як ключ з таким типом вже збережено в додатку ( The key is not issued due this type of already exists in the application.)
case unknown(AppError) // Ключ не видано хмарним сервером з-за помилки в відповіді (The key is not issued due to unknown response from a remote server.)

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
> [!WARNING]
> Увага!!! Видалення ключа - незворотня дія!!!

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

Якщо потрібно оновити назву ключа, що відображається в інтерфейсі, використовуйте функцію `.updateAccessKeyName(_ key: AccessKey)`

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

##### RemoteNotification

Для обробки push-сповіщень від сервера (наприклад, для деактивації тимчасового ключа) використовуйте структуру `RemoteNotification`.

> [!NOTE]
> Push-сповіщення надходять як "тихі" (silent) — без звуку та банера. Вони обробляються у фоновому режимі (`content-available: 1`).

```swift
import UserNotifications
import u_prox_id_lib

class AppDelegate: UIResponder, UIApplicationDelegate {

    private var remoteNotifications: RemoteNotification = .init(token: nil, env: nil)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.configurateAppleNotification(application)
        return true
    }

    fileprivate func configurateAppleNotification(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in })
        
        application.registerForRemoteNotifications()
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            var remoteNotifications = self.remoteNotifications
            _ = await self.remoteNotifications.receive(userInfo)
            completionHandler(.newData)
        }
    }
}
```
