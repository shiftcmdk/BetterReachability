include $(THEOS)/makefiles/common.mk

ARCHS = arm64 arm64e

TWEAK_NAME = BetterReachability
BetterReachability_FILES = Tweak.xm

BetterReachability_CFLAGS = -std=c++11 -stdlib=libc++
BetterReachability_LDFLAGS = -stdlib=libc++

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += betterreachabilitypreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
