kill -9 $(pgrep -f 'appium')
#adb -s 2a9c3b082c0b7ece shell pm clear com.facebook.katana
adb -s 5200e9eaece0b4ff shell pm clear com.facebook.katana
#adb -s f1f690c7 shell pm clear com.facebook.katana
#adb -s b2fbdeea shell pm clear com.facebook.katana

#adb -s 2a9c3b082c0b7ece shell pm grant com.facebook.katana android.permission.WRITE_CONTACTS
#adb -s 2a9c3b082c0b7ece shell pm grant com.facebook.katana android.permission.READ_CONTACTS
#adb -s 2a9c3b082c0b7ece shell pm grant com.facebook.katana android.permission.READ_PHONE_STATE
#adb -s 2a9c3b082c0b7ece shell pm grant com.facebook.katana android.permission.ACCESS_FINE_LOCATION
#adb -s 2a9c3b082c0b7ece shell pm grant com.facebook.katana android.permission.ACCESS_COARSE_LOCATION


adb -s 5200e9eaece0b4ff shell pm grant com.facebook.katana android.permission.WRITE_CONTACTS
adb -s 5200e9eaece0b4ff shell pm grant com.facebook.katana android.permission.READ_CONTACTS
adb -s 5200e9eaece0b4ff shell pm grant com.facebook.katana android.permission.READ_PHONE_STATE
adb -s 5200e9eaece0b4ff shell pm grant com.facebook.katana android.permission.ACCESS_FINE_LOCATION
adb -s 5200e9eaece0b4ff shell pm grant com.facebook.katana android.permission.ACCESS_COARSE_LOCATION

#adb -s b2fbdeea shell pm grant com.facebook.katana android.permission.WRITE_CONTACTS
#adb -s b2fbdeea shell pm grant com.facebook.katana android.permission.READ_CONTACTS
#adb -s b2fbdeea shell pm grant com.facebook.katana android.permission.READ_PHONE_STATE
#adb -s b2fbdeea shell pm grant com.facebook.katana android.permission.ACCESS_FINE_LOCATION
#adb -s b2fbdeea shell pm grant com.facebook.katana android.permission.ACCESS_COARSE_LOCATION


#adb -s f1f690c7 shell pm grant com.facebook.katana android.permission.WRITE_CONTACTS
#adb -s f1f690c7 shell pm grant com.facebook.katana android.permission.READ_CONTACTS
#adb -s f1f690c7 shell pm grant com.facebook.katana android.permission.READ_PHONE_STATE
#adb -s f1f690c7 shell pm grant com.facebook.katana android.permission.ACCESS_FINE_LOCATION
#adb -s f1f690c7 shell pm grant com.facebook.katana android.permission.ACCESS_COARSE_LOCATION


#adb -s 2a9c3b082c0b7ece uninstall io.appium.uiautomator2.server
adb -s 5200e9eaece0b4ff uninstall io.appium.uiautomator2.server
#adb -s 2a9c3b082c0b7ece uninstall io.appium.uiautomator2.server.test
adb -s 5200e9eaece0b4ff uninstall io.appium.uiautomator2.server.test
#adb -s f1f690c7 uninstall io.appium.uiautomator2.server
#adb -s f1f690c7 uninstall io.appium.uiautomator2.server.test
#adb -s b2fbdeea uninstall io.appium.uiautomator2.server
#adb -s b2fbdeea uninstall io.appium.uiautomator2.server.test

appium --nodeconfig ./configs/5200e9eaece0b4ff.json -p 34568 --default-capabilities '{"udid":"5200e9eaece0b4ff"}' &
#appium --nodeconfig ./configs/b2fbdeea.json -p 34570 --default-capabilities '{"udid":"b2fbdeea"}' &
#appium --nodeconfig ./configs/2a9c3b082c0b7ece.json -p 34567 --default-capabilities '{"udid":"2a9c3b082c0b7ece"}' &
#appium --nodeconfig ./configs/f1f690c7.json -p 34569 --default-capabilities '{"udid":"f1f690c7"}' &
