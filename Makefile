BUILD_DIR := $(shell pwd)/build

build/cmake-dependency-diagram-%.stamp:
	@mkdir -p $(BUILD_DIR)/packaging
	@cp -r packaging/$* $(BUILD_DIR)/packaging/$*/
	cd $(BUILD_DIR)/packaging/$* && pwd && dpkg-buildpackage -us -uc 
	@mkdir -p output 
	@mv $(BUILD_DIR)/packaging/*.deb output/
	@touch $@

packaging: build/cmake-dependency-diagram-ubuntu-20.stamp
    
clean: 
	@rm -rf $(BUILD_DIR)
	@rm -rf output
