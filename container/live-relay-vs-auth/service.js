
const path       = require("path")
const fs         = require("fs")
const HAPI       = require("@hapi/hapi")
const jsYAML     = require("js-yaml")
const micromatch = require("micromatch")

;(async () => {
    const yaml = await fs.promises.readFile("./service.yaml", { encoding: "utf8" })
    const config = jsYAML.load(yaml)
    const server = HAPI.server({
        host:  "0.0.0.0",
        port:  9090,
        debug: false
    })
    server.events.on("log", (event, tags) => {
        if (tags.error) {
            const err = event.error
            if (err instanceof Error)
                process.stderr.write(`HAPI: ${err.message}\n`)
            else
                process.stderr.write(`HAPI: ${err}\n`)
        }
        else
            process.stderr.write(`HAPI: ${event} ${tags}\n`)
    })
    server.route({
        method:   "POST",
        path:     "/hook",
        options: {
            payload: { parse: true }
        },
        handler: async (req, h) => {
            let params = {}
            if (req.payload.param !== "") {
                let param = req.payload.param
                param = param.replace(/^\?/, "")
                for (const kv of param.split(/&/)) {
                    let m
                    if ((m = kv.match(/^(.+)=(.*)$/)) !== null) {
                        let [ , key, val ] = m
                        params[key] = val
                    }
                }
            }
            let ip     = req.payload.ip     !== undefined ? req.payload.ip     : "<none>"
            let app    = req.payload.app    !== undefined ? req.payload.app    : "<none>"
            let stream = req.payload.stream !== undefined ? req.payload.stream : "<none>"
            let key    = params.key         !== undefined ? params.key         : "<none>"

            let granted = false
            for (const entry of config) {
                if (   micromatch.isMatch(ip,     entry.ip)
                    && micromatch.isMatch(app,    entry.app)
                    && micromatch.isMatch(stream, entry.stream)
                    && micromatch.isMatch(key,    entry.keys)  ) {
                    granted = true
                    break
                }
            }
            process.stderr.write(`srs-auth: ip="${ip}" app="${app}" stream="${stream}" key="${key}" response=${granted ? "ALLOW" : "DENY"}\n`)

            if (granted)
                return h.response("0").code(200)
            else
                return h.response("1").code(200)
        }
    })
    await server.start()
})().catch((err) => {
    process.stderr.write(`ERROR: ${err.message}\n`)
    process.exit(1)
})

