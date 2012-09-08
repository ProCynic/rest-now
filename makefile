all:
	@coffee -co bin/ src/*.coffee
	@echo "#!/usr/bin/env node" > bin/tmp.js
	@cat bin/cluster.js >> bin/tmp.js
	@mv bin/tmp.js bin/cluster.js
