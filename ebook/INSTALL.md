
INSTALLATION
-------------

Need to Replace offical registry by taobao mirror ( registry access issue in mainland china)

~~~~
$ npm config ls -l |grep registry
registry = "https://registry.npmjs.org/"

$ npm config set registry https://registry.npm.taobao.org

$ npm config ls -l |grep registry
registry = "https://registry.npm.taobao.org/"
; registry = "https://registry.npmjs.org/" (overridden)

~~~~


Install required modoles

    $ npm install -g request cheerio minimist

NODE_PATH is required for windows7 

    $ export NODE_PATH=$APPDATA\\npm\\node_modules

DONE!

    $ node rename.js









































































