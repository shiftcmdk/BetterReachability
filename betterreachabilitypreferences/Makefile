include $(THEOS)/makefiles/common.mk

ARCHS = arm64 arm64e

BUNDLE_NAME = BetterReachabilityPreferences
BetterReachabilityPreferences_FILES = BRRootListController.m Cells.m
BetterReachabilityPreferences_INSTALL_PATH = /Library/PreferenceBundles
BetterReachabilityPreferences_FRAMEWORKS = UIKit
BetterReachabilityPreferences_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/BetterReachabilityPreferences.plist$(ECHO_END)
