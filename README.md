SimpleDefaults
==============

A simple wrapper for NSUserDefaults

### Types of defaults

* Device defaults: defaults that won't change based on the signed in user
* User defaults: defaults that depend on the signed in user

## Usage

Set a device default
```swift
SimpleDefaults.sharedInstance.setDeviceDefaultValue(value: [1,2,3,4,5], key: "my_key")
```

Retrieve the device default you just set
```swift
// This would return [1,2,3,4,5]
SimpleDefaults.sharedInstance.getDeviceDefault(key: "my_default_key", fallbackValue: [])
```

Value is typechecked against the type of fallbackValue
If they aren't the same type, returns fallbackValue even if the default exists
```swift
// This would return 5
SimpleDefaults.sharedInstance.getDeviceDefault(key: "my_default_key", fallbackValue: 5)
```

## Contact

* Brian Kracoff
* bkracoff@gmail.com
* http://www.kracoff.org

## License

Literally is available under the MIT license. See the LICENSE file for more info.
