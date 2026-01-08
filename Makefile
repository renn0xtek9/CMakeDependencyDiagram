BUILD_DIR := /tmp/build
PACKAGE_NAME:= cmake-dependency-diagram
MAIN_VERSION := $(shell cat VERSION)
GIT_HASH:= $(shell git rev-parse --short HEAD)
FULL_PACKAGE_NAME= $(PACKAGE_NAME)_$(MAIN_VERSION)~git$(GIT_HASH)_all
#FULL_PACKAGE_NAME= $(PACKAGE_NAME)-$(MAIN_VERSION)~git$(GIT_HASH)


GPG_KEY_FINGER_PRINT ?= 04C9FB399050560B20F3DE85C86F45E902C8D9B7

DEBFULLNAME := "Maxime Haselbaueer"
DEBEMAIL := "maxime.haselbauer@googlemail.com"

export DEBFULLNAME
export DEBEMAIL

GREEN := \033[0;32m
NC := \033[0m # No Color


# Handles dummy gpg key for testing packages
.PHONY: create-test-gpg-key 
create-test-gpg-key: $(BUILD_DIR)/test-key-fingerprint.stamp

$(BUILD_DIR)/test-key-fingerprint.stamp: dummy-gpg-key-batch
	@echo "Creating GPG test key..."s
	@mkdir -p $(BUILD_DIR)
	@# Generate the key
	gpg --batch --gen-key dummy-gpg-key-batch
	@# Extract email from batch file
	@EMAIL=$$(grep '^Name-Email:' dummy-gpg-key-batch | awk '{print $$2}'); \
	echo "Looking for key with email: $$EMAIL"; \
	FINGERPRINT=$$(gpg --list-secret-keys --fingerprint "$$EMAIL" | grep -A1 "sec" | tail -1 | tr -d ' '); \
	echo "$$FINGERPRINT" > $(BUILD_DIR)/test-key-fingerprint.stamp
	@echo "Key fingerprint saved to $(BUILD_DIR)/test-key-fingerprint.stamp"
	@cat $(BUILD_DIR)/test-key-fingerprint.stamp

.PHONY: clean-gpg-key
clean-gpg-key:
	@if [ -f $(BUILD_DIR)/test-key-fingerprint.stamp ]; then \
		EMAIL=$$(grep '^Name-Email:' dummy-gpg-key-batch | awk '{print $$2}'); \
		FINGERPRINT=$$(cat $(BUILD_DIR)/test-key-fingerprint.stamp); \
		echo "Removing GPG key $$FINGERPRINT"; \
		gpg --batch --yes --delete-secret-keys "$$FINGERPRINT" 2>/dev/null || true; \
		gpg --batch --yes --delete-keys "$$FINGERPRINT" 2>/dev/null || true; \
		rm -f $(BUILD_DIR)/test-key-fingerprint.stamp; \
	fi

########## Packaging targets

# Create an environment for building a package (unify source and debian folder under build directory)
$(BUILD_DIR)/packaging_environment_%.stamp: $(wildcard src/*) $(wildcard packaging/*)
	@echo "$(GREEN)Prepare local packaging environment for $*$(NC)"
	@mkdir -p $(BUILD_DIR)/packaging
	@mkdir -p $(BUILD_DIR)/packaging/$*/$(FULL_PACKAGE_NAME)
	@cp -r packaging/$*/* $(BUILD_DIR)/packaging/$*/$(FULL_PACKAGE_NAME)/
	@cp -r src/* $(BUILD_DIR)/packaging/$*/$(FULL_PACKAGE_NAME)/
	@cd $(BUILD_DIR)/packaging/$*/$(FULL_PACKAGE_NAME) && \
		DISTRIBUTION=$$(dpkg-parsechangelog --show-field Distribution) && \
		dch --newversion "$(MAIN_VERSION)~git$(GIT_HASH)" --distribution $$DISTRIBUTION -m "git revision: $(GIT_HASH)"
	@touch $@

# Create a debian package locally, not signed for testing purposes
$(BUILD_DIR)/local_packaging_%.stamp: $(BUILD_DIR)/packaging_environment_%.stamp $(BUILD_DIR)/test-key-fingerprint.stamp
	@echo "$(GREEN)Building local packaging for $*$(NC)"
	@FINGERPRINT=$$(cat $(BUILD_DIR)/test-key-fingerprint.stamp); \
	cd $(BUILD_DIR)/packaging/$*/$(FULL_PACKAGE_NAME)/ && debuild -sa -k$$FINGERPRINT
	@touch $@

ubuntu_22_local_package:$(BUILD_DIR)/local_packaging_ubuntu-22.stamp
ubuntu_24_local_package:$(BUILD_DIR)/local_packaging_ubuntu-24.stamp

# Install a locally build debian package
$(BUILD_DIR)/local_install_%.stamp: $(BUILD_DIR)/local_packaging_%.stamp
	@echo "$(GREEN)Installing the locally built package for $*$(NC)"
	@cd $(BUILD_DIR)/packaging/$*/ && sudo apt install -y ./${FULL_PACKAGE_NAME}.deb
	@touch $@

ubuntu_22_local_install: $(BUILD_DIR)/local_install_ubuntu-22.stamp
ubuntu_24_local_install: $(BUILD_DIR)/local_install_ubuntu-24.stamp

# Uninstall package via the dependency manager
uninstall_package:
	@echo "$(GREEN)Removing $(PACKAGE_NAME) via dpkg $(NC)"
	@sudo dpkg -r $(PACKAGE_NAME) || true
	@sudo dpkg -P $(PACKAGE_NAME) || true
	@mkdir -p $(BUILD_DIR)/
	@rm -f $(BUILD_DIR)/*.installation-stamp

########## Integration tests
$(BUILD_DIR)/integration_test/%/Makefile: $(BUILD_DIR)/local_install_%.stamp
	@echo "$(GREEN)Configuring integration tests CMake Project ($*) $(NC)"
	@cd tests && mkdir -p $(BUILD_DIR)/integration_test && mkdir -p $(BUILD_DIR)/integration_test
	@cd tests && cmake -S integration_test -B "$(BUILD_DIR)/integration_test/$*" --graphviz="$(BUILD_DIR)/integration_test/$*"/cmake.dot

$(BUILD_DIR)/integration_test/%/CMakeDependencyDiagram/index.html: $(BUILD_DIR)/integration_test/%/Makefile
	@echo "$(GREEN)Building integration tests CMake Project for ($*) $(NC)"
	@cmake --build $(BUILD_DIR)/integration_test/$* --target cmake-dependency-diagram

$(BUILD_DIR)/test_%.stamp: $(BUILD_DIR)/integration_test/%/CMakeDependencyDiagram/index.html
	@echo "$(GREEN)Running tests for $*$(NC)"
	@./tests/integration_test.sh $*
	@touch $@

test_ubuntu_22: $(BUILD_DIR)/test_ubuntu-22.stamp

test_ubuntu_24: $(BUILD_DIR)/test_ubuntu-24.stamp

########## Upload to PPA 

$(BUILD_DIR)/create_a_signed_package_%.stamp: $(BUILD_DIR)/test_%.stamp
	@echo "$(GREEN)Prepare a signed package for $*$(NC)"
	cd $(BUILD_DIR)/packaging/$*/$(FULL_PACKAGE_NAME)/ && debuild -S -sa -k$(GPG_KEY_FINGER_PRINT)
	@touch $@

$(BUILD_DIR)/upload_to_ppa_%.stamp: $(BUILD_DIR)/create_a_signed_package_%.stamp
	@echo "$(GREEN)Uploading the signed package to PPA for $*$(NC)"
	cd $(BUILD_DIR)/packaging/$* && dput ppa:maxime-haselbauer/cmake-dependency-diagram ./$(PACKAGE_NAME)_$(MAIN_VERSION)~git$(GIT_HASH)_source.changes
	@touch $@

upload_to_ppa_ubuntu_22: $(BUILD_DIR)/upload_to_ppa_ubuntu-22.stamp

upload_to_ppa_ubuntu_24: $(BUILD_DIR)/upload_to_ppa_ubuntu-24.stamp

######### Global targets

test: test_ubuntu_22

upload_to_ppa: upload_to_ppa_ubuntu_22

clean: uninstall_package clean-gpg-key
	@rm -rf $(BUILD_DIR)
