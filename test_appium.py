from appium import webdriver
from appium_flutter_finder import FlutterElement, FlutterFinder
import time

# Configuration for iOS
desired_caps = {
    "platformName": "iOS",
    "platformVersion": "17.2",
    "deviceName": "iPhone 15",
    "app": "build/ios/Debug-iphonesimulator/Runner.app",
    "automationName": "Flutter",
    "noReset": True,
    # Add these additional capabilities

    "waitForDebugger": True,
    "startIWDP": True,
    "webviewConnectRetries": 3,
    "clearSystemFiles": True,
    # "showXcodeLog": True,
    "derivedDataPath": "ios/DerivedData"
}

# Initialize the Appium driver
from appium.options.common import AppiumOptions
options = AppiumOptions().load_capabilities(desired_caps)

def init_driver(max_retries=3):
    for attempt in range(max_retries):
        try:
            driver = webdriver.Remote("http://127.0.0.1:4723", options=options)
            print("Driver initialized successfully")
            return driver
        except Exception as e:
            print(f"Attempt {attempt + 1} failed: {str(e)}")
            if attempt < max_retries - 1:
                time.sleep(5)  # Wait before retrying
            else:
                raise
                
try:
    # Initialize driver with retries
    driver = init_driver()
    
    # Flutter Finder
    finder = FlutterFinder()
    
    # Wait for the app to load (increased wait time)
    driver.implicitly_wait(60)
    
    # Add explicit wait before interaction
    time.sleep(10)  # Give extra time for Flutter app to initialize
    
    # Example interaction
    login_button = finder.by_value_key("loginButton")
    driver.find_element(login_button).click()
    
except Exception as e:
    print(f"Test failed: {str(e)}")
    raise
finally:
    if 'driver' in locals():
        driver.quit()