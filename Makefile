# This assumes that zola is installed from flatpak

.PHONY: build
build:
	@echo "Cleaning up"
	make clean
	@echo "Building into public/"
	flatpak run org.getzola.zola build
	@echo "Compressing CSS"
	csso public/style.css --output public/style.css --source-map public/style.css.map

.PHONY: build_dev
build_dev:
	@echo "Cleaning up"
	make clean
	@echo "Building into public/"
	flatpak run org.getzola.zola build -u "http://0.0.0.0:8080" --drafts
	@echo "Compressing CSS"
	csso public/style.css --output public/style.css --source-map public/style.css.map
	@echo "Serve Static"
	cd public/ && python3 -m http.server 8080 --bind 0.0.0.0

.PHONY: dev
dev:
	@echo "Starting dev server..."
	flatpak run org.getzola.zola serve

.PHONY: clean
clean:
	@touch public
	rm -rd public

.PHONY: setup
setup:
	@echo "Installing zola via flatpak"
	flatpak install flathub org.getzola.zola
	@echo "Installing csso-cli via npm, this might require root"
	sudo npm install -g csso-cli