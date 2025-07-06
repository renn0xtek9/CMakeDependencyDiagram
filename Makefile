BUILD_DIR := $(shell pwd)/build
PACKAGE_NAME:= cmake-dependency-diagram
MAIN_VERSION := $(shell cat VERSION)
GIT_HASH:= $(shell git rev-parse --short HEAD)
FULL_PACKAGE_NAME= $(PACKAGE_NAME)_$(MAIN_VERSION)

DEBFULLNAME := "Maxime Haselbaueer"
DEBEMAIL := "maxime.haselbauer@googlemail.com"

export DEBFULLNAME
export DEBEMAIL

GREEN := \033[0;32m
NC := \033[0m # No Color

########## Packaging targets

# Create an environment for building a package (unify source and debian folder under build directory)
build/packaging_environment_%.stamp: $(wildcard src/*) $(wildcard packaging/*)
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
build/local_packaging_%.stamp: build/packaging_environment_%.stamp
	@echo "$(GREEN)Building local packaging for $*$(NC)"
	cd $(BUILD_DIR)/packaging/$*/$(FULL_PACKAGE_NAME)/ && dpkg-buildpackage -us -uc 
	@touch $@

ubuntu_22_local_package:build/local_packaging_ubuntu-22.stamp

# Install a locally build debian package
build/local_install_%.stamp: build/local_packaging_%.stamp
	@echo "$(GREEN)Installing the locally built package for $*$(NC)"
	@cd $(BUILD_DIR)/packaging/$*/ && sudo apt install -y ./${FULL_PACKAGE_NAME}_all.deb
	@touch $@

# Uninstall package via the dependency manager
uninstall_package:
	@echo "$(GREEN)Removing $(PACKAGE_NAME) via apt $(NC)"
	@sudo dpkg -r $(PACKAGE_NAME) || true
	@sudo dpkg -P $(PACKAGE_NAME) || true
	@rm -f build/*.installation-stamp
	@touch build/uninstall.stamp

########## Integration tests
build/integration_test/%/Makefile: build/local_install_ubuntu-22.stamp
	@echo "$(GREEN)Configuring integration tests CMake Project ($*) $(NC)"
	@cd tests && mkdir -p $(BUILD_DIR)/integration_test && mkdir -p $(BUILD_DIR)/integration_test
	@cd tests && cmake -S integration_test -B "$(BUILD_DIR)/integration_test/$*" --graphviz="$(BUILD_DIR)/integration_test/$*"/cmake.dot

build/integration_test/%/CMakeDependencyDiagram/index.html: build/integration_test/%/Makefile
	@echo "$(GREEN)Building integration tests CMake Project for ($*) $(NC)"
	@cmake --build $(BUILD_DIR)/integration_test/$* --target cmake-dependency-Diagram

build/test-%.stamp: build/integration_test/%/CMakeDependencyDiagram/index.html
	@echo "$(GREEN)Running tests for $*$(NC)"
	@./tests/integration_test.sh $*
	@touch $@

########## Upload to PPA 

build/create_a_signed_package%.stamp: build/test-%.stamp
	@echo "$(GREEN)Prepare a signed package for $*$(NC)"
	cd $(BUILD_DIR)/packaging/$*/$(FULL_PACKAGE_NAME)/ && debuild -S -sa -k04C9FB399050560B20F3DE85C86F45E902C8D9B7
	@touch $@

build/upload_to_ppa%.stamp: build/create_a_signed_package%.stamp
	@echo "$(GREEN)Uploading the signed package to PPA for $*$(NC)"
	cd $(BUILD_DIR)/packaging/$*/$(FULL_PACKAGE_NAME)/ && dput ppa:your-ppa-name/ppa ./${FULL_PACKAGE_NAME}_source.changes
	@touch $@

######### Global targets

test: build/test-ubuntu-22.stamp

upload_to_ppa: build/upload_to_ppa-ubuntu-22.stamp

clean: uninstall_package
	@rm -rf $(BUILD_DIR)
