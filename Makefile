BUILD_DIR := $(shell pwd)/build

GREEN := \033[0;32m
NC := \033[0m # No Color

build/cmake-dependency-diagram-%.stamp: $(wildcard src/*) $(wildcard packaging/*)
	@mkdir -p $(BUILD_DIR)/packaging
	@cp -r packaging/$* $(BUILD_DIR)/packaging/$*/
	cd $(BUILD_DIR)/packaging/$* && pwd && dpkg-buildpackage -us -uc 
	@mkdir -p output 
	@mv $(BUILD_DIR)/packaging/*.deb output/
	@touch $@

local_debian_packaging: build/cmake-dependency-diagram-ubuntu-22.stamp


remove_currently_installed_package:
	@echo "$(GREEN)Removing currently installed package...$(NC)"
	@sudo dpkg -r cmake-dependency-diagram || true
	@sudo dpkg -P cmake-dependency-diagram || true
	@rm -f build/cmake-dependency-diagram-ubuntu-22.installation-stamp

build/cmake-dependency-diagram-ubuntu-22.installation-stamp: local_debian_packaging
	@echo "$(GREN)Installing the package...$(NC)"
	@cd output && sudo apt install -y ./cmake-dependency-diagram_1.0.0_all.deb
	@touch $@

local_debian_install: build/cmake-dependency-diagram-ubuntu-22.installation-stamp

install: build/cmake-dependency-diagram-ubuntu-22.installation-stamp
	@echo "$(GREEN)Package installed.$(NC)"


build/integration_test/Makefile: build/cmake-dependency-diagram-ubuntu-22.installation-stamp
	@cd tests && mkdir -p $(BUILD_DIR)/integration_test && mkdir -p $(BUILD_DIR)/integration_test
	@cd tests && cmake -S integration_test -B "$(BUILD_DIR)/integration_test" --graphviz="$(BUILD_DIR)/integration_test"/cmake.dot


build/integration_test/CMakeDependencyDiagram/index.html: build/integration_test/Makefile
	@cmake --build $(BUILD_DIR)/integration_test --target cmake-dependency-Diagram

test: build/integration_test/CMakeDependencyDiagram/index.html
	@echo "$(GREEN)Testing the package...$(NC)"
	@./tests/integration_test.sh

clean: remove_currently_installed_package
	@rm -rf $(BUILD_DIR)
	@rm -rf output



.PHONY: local_debian_install
