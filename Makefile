all: dist-linux dist-windows

dist-linux:
	CGO_ENABLED=0 GOOS=linux go build -o dist/linux/gorts
	cp -r web dist/linux/web

dist-windows:
	CGO_ENABLED=0 GOOS=windows \
		go build -o dist/windows/gorts.exe -ldflags -H=windowsgui
	cp -r web dist/windows/web

clean:
	rm -rf dist/*
