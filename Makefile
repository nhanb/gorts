all: dist-linux dist-windows

dist-linux:
	CGO_ENABLED=0 GOOS=linux go build -o dist/linux/gorts
	cp -r web dist/linux/web

dist-windows:
	CGO_ENABLED=0 GOOS=windows \
		go build -o dist/windows/gorts.exe -ldflags -H=windowsgui
	cp -r web dist/windows/web

dist/GORTS-Linux.zip: dist-linux
	cd dist/linux; zip -r ../GORTS-Linux.zip .

dist/GORTS-Windows.zip: dist-windows
	cd dist/windows; \
		curl -L 'https://tclkits.rkeene.org/fossil/raw/tclkit-8.6.3-win32-x86_64.exe?name=403c507437d0b10035c7839f22f5bb806ec1f491' > tclkit.exe; \
		zip -r ../GORTS-Windows.zip .

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
