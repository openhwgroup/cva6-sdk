CACHETEST_SITE = $(BR2_EXTERNAL_EXTENSIONS_PATH)/package/cachetest
CACHETEST_SITE_METHOD = local
CACHETEST_LICENSE = SHL-0.51
CACHETEST_LICENSE_FILES = files/cachetest.c

define CACHETEST_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) \
		-o $(@D)/cachetest $(@D)/files/cachetest.c
endef

define CACHETEST_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/cachetest $(TARGET_DIR)/usr/bin/cachetest
endef

$(eval $(generic-package))
