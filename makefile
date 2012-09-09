all:
	@coffee -co bin/ src/*.coffee
	@echo "#!/usr/bin/env node" > bin/tmp.js
	@cat bin/cli.js >> bin/tmp.js
	@mv bin/tmp.js bin/cli.js

clean:
	@rm -f bin/*