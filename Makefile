windows:
	CGO_ENABLED=0 GOOS=windows \
		go build -o dist/windows/gorts.exe -ldflags -H=windowsgui
	rm -rf dist/windows/web
	cp -r web dist/windows/
	rm -rf dist/windows/tcl
	cp -r tcl dist/windows/
	cp players.sample.csv dist/windows/
	cp README.md dist/windows/

linux:
	CGO_ENABLED=0 GOOS=linux go build -o dist/linux/gorts
	rm -rf dist/linux/web
	cp -r web dist/linux/
	rm -rf dist/linux/tcl
	cp -r tcl dist/linux/
	cp players.sample.csv dist/linux/
	cp README.md dist/linux/

dist/GORTS-Windows.zip: windows
	cd dist/windows; \
		curl -L 'https://tclkits.rkeene.org/fossil/raw/tclkit-8.6.3-win32-x86_64.exe?name=403c507437d0b10035c7839f22f5bb806ec1f491' > tclkit.exe; \
		zip -r ../GORTS-Windows.zip .

dist/GORTS-Linux.zip: linux
	cd dist/linux; zip -r ../GORTS-Linux.zip .

watch:
	find . -name '*.go' -o -name '*.tcl' | entr -rc go run .

gorts.png: gorts.svg
	convert -background transparent -density 300 -resize 256x256 gorts.svg gorts.png

gorts.ico: gorts.svg
	convert -background transparent -density 300 \
		-define 'icon:auto-resize=256,128,64,32,24,16' \
		gorts.svg gorts.ico

gorts.syso: gorts.ico
	# needs `go install github.com/akavel/rsrc@latest`
	rsrc -ico gorts.ico -o gorts.syso

clean:
	rm -rf dist/*
