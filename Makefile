windows:
	CGO_ENABLED=0 GOOS=windows \
		go build -o dist/windows/gorts.exe -ldflags -H=windowsgui
	cp -r web dist/windows/
	cp -r tcl dist/windows/
	cp players.sample.csv dist/windows/
	cp README.md dist/windows/
	cp -r screenshots dist/windows/
	cp gorts.png dist/windows/

linux:
	CGO_ENABLED=0 GOOS=linux go build -o dist/linux/gorts
	cp -r web dist/linux/
	cp -r tcl dist/linux/
	cp players.sample.csv dist/linux/
	cp README.md dist/linux/
	cp -r screenshots dist/linux/
	cp gorts.png dist/linux/

dist/GORTS-Windows.zip: windows
	cd dist/windows; \
		curl -L 'https://www.irontcl.com/downloads/irontcl-amd64-8.6.7.zip' > irontcl.zip; \
		unzip -o irontcl.zip; \
		rm irontcl.zip; \
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
