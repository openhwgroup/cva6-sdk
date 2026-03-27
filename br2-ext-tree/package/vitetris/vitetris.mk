VITETRIS_VERSION = 744b5090a6d1315cd7b818e5276ed90ba0f3df23
VITETRIS_SITE = $(call github,vicgeralds,vitetris,$(VITETRIS_VERSION))
VITETRIS_LICENSE_FILES = licence.txt

define VITETRIS_BUILD_CMDS
    $(MAKE) -C $(@D)/src CC="$(TARGET_CC)" CFLAGS="$(TARGET_CFLAGS)" tetris
endef

define VITETRIS_INSTALL_TARGET_CMDS
    cp $(@D)/src/tetris $(TARGET_DIR)/tetris
endef

$(eval $(generic-package))
