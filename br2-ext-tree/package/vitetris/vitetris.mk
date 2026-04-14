VITETRIS_VERSION = 744b5090a6d1315cd7b818e5276ed90ba0f3df23
VITETRIS_SITE = $(call github,vicgeralds,vitetris,$(VITETRIS_VERSION))
VITETRIS_LICENSE = BSD-2-Clause
VITETRIS_LICENSE_FILES = licence.txt

define VITETRIS_BUILD_CMDS
	$(MAKE) -C $(@D)/src CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS)" LDFLAGS="$(TARGET_LDFLAGS)" tetris
endef

define VITETRIS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/src/tetris $(TARGET_DIR)/usr/bin/tetris
endef

$(eval $(generic-package))
