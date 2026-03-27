CACHETEST_SITE = $(BR2_EXTERNAL_EXTENSIONS_PATH)/package/cachetest
CACHETEST_SITE_METHOD = local

define CACHETEST_BUILD_CMDS
    cd $(@D) && $(TARGET_CC) -o cachetest.elf $(CACHETEST_SITE)/files/cachetest.c
endef

define CACHETEST_INSTALL_TARGET_CMDS
	cp $(@D)/cachetest.elf $(TARGET_DIR)/cachetest.elf
endef

$(eval $(generic-package))
