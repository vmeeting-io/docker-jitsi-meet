ifneq "$(MAKELEVEL)" "0"
ifdef VMEETING_API_BASE
	override BUILD_ARGS := $(BUILD_ARGS) --build-arg REACT_APP_AUTH_API_BASE=$(VMEETING_API_BASE)
endif
ifdef VMEETING_FRONT_BASE
 	override BUILD_ARGS := $(BUILD_ARGS) --build-arg REACT_APP_AUTH_PAGE_BASE=$(VMEETING_FRONT_BASE)
endif
ifdef JWT_APP_ID
	override BUILD_ARGS := $(BUILD_ARGS) --build-arg REACT_APP_JWT_TOKEN=$(JWT_APP_ID)
endif
endif

build:
	docker build $(BUILD_ARGS) -t $(JITSI_REPO)/web .

.PHONY: build
