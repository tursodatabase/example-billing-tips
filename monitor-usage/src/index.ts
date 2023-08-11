import sleep from "sleep-promise"

type Config = {
    apiToken: string
    org: string
    db: string
}

type Usage = {
    rows_read: number
    rows_written: number
    storage_bytes: number
}

async function main() {
    const apiToken = process.env.TURSO_TOKEN
    if (apiToken === undefined) {
        console.error("TURSO_TOKEN env not set")
        return
    }

    const org = process.env.TURSO_ORG
    if (org === undefined) {
        console.error("TURSO_ORG env not set")
        return
    }

    const db = process.env.TURSO_DB
    if (db === undefined) {
        console.error("TURSO_DB env not set")
        return
    }

    const config = { apiToken, org, db }

    let lastUsage: Usage = {
        rows_read: 0, rows_written: 0, storage_bytes: 0
    }
    let lastChange = Date.now()
    for (;;) {
        const latestUsage = await getUsage(config)
        const readDiff = latestUsage.rows_read - lastUsage.rows_read
        const writeDiff = latestUsage.rows_written - lastUsage.rows_written
        const storageDiff = latestUsage.storage_bytes - lastUsage.storage_bytes
        if (readDiff > 0 || writeDiff > 0 || storageDiff > 0) {
            lastChange = Date.now()
            console.log(new Date(lastChange), '\u0007')
            console.log(`rows_read: ${latestUsage.rows_read} (+${readDiff})`)
            console.log(`rows_written: ${latestUsage.rows_written} (+${writeDiff})`)
            console.log(`storage_bytes: ${latestUsage.storage_bytes} (+${storageDiff})`)
        }
        lastUsage = latestUsage

        await sleep(10 * 1000)
        if (lastChange + (30 * 60 * 1000) < Date.now()) {
            console.log("No changes in 30m")
            return
        }
    }
}

async function getUsage(config: Config): Promise<Usage> {
    const url = `https://api.turso.tech/v1/organizations/${config.org}/databases/${config.db}/usage`
    const res = await fetch(url, {
        headers: {
            "Authorization": `Bearer ${config.apiToken}`
        }
    })
    if (res.status !== 200) {
        throw new Error(`fetch returned ${res.status} ${res.statusText}`)
    }
    const data = await res.json()
    const { rows_read, rows_written, storage_bytes } = data.database.usage
    return { rows_read, rows_written, storage_bytes }
}

main()
