BUILD_DIR := $(shell pwd)/build

build/cmake-dependency-diagram-%.stamp: $(wildcard src/*) $(wildcard packaging/*)
	@mkdir -p $(BUILD_DIR)/packaging
	@cp -r packaging/$* $(BUILD_DIR)/packaging/$*/
	cd $(BUILD_DIR)/packaging/$* && pwd && dpkg-buildpackage -us -uc 
	@mkdir -p output 
	@mv $(BUILD_DIR)/packaging/*.deb output/
	@touch $@

packaging: build/cmake-dependency-diagram-ubuntu-20.stamp

test: build/cmake-dependency-diagram-ubuntu-20.stamp
	@echo "Testing the package..."
	./tests/debian_package_test/debian_package_test.sh
	
clean: 
	@rm -rf $(BUILD_DIR)
	@rm -rf output
