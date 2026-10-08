# osint-toolkit-linux

> Install and use practical **OSINT tools on Linux** — with what each tool is, what it's for, exact install commands, a basic usage example, and a live terminal demo.

A GitHub-style, single-page guide. The rendered version lives at **`index.html`** (and is published via GitHub Pages).

![interface](https://img.shields.io/badge/UI-Forge%20%C2%B7%20GitHub--inspired-2dd4bf) ![platform](https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu%20%7C%20Kali-2496ed) ![license](https://img.shields.io/badge/license-MIT-blue)

---

## ⚠️ Disclaimer — read first

These tools are provided **for authorised, ethical security testing and educational use only**.

Only run them against systems, domains, accounts and people you **own** or have **explicit written permission** to test. Unauthorised scanning, enumeration or account investigation may be illegal in your jurisdiction (for example the US CFAA, the UK Computer Misuse Act, or Pakistan's PECA) and can carry criminal and civil penalties.

You are solely responsible for how you use anything in this repository.

---

## 00 · Prerequisites & safe setup

This guide targets **Debian 12 / Ubuntu 22.04+** and **Kali**. On Kali many of these tools are pre-installed — check with `which <tool>` before installing again.

Install the base toolchain once:

```bash
sudo apt update && sudo apt install -y git python3 python3-pip python3-venv pipx golang-go whois dnsutils jq
pipx ensurepath
source ~/.bashrc
```

**Why `pipx` instead of `pip`?** Most OSINT tools ship as Python CLIs. `pipx` installs each one into its own isolated virtualenv and drops a single executable on your `PATH` — no dependency conflicts between tools that pin different versions of `requests`, and no fighting with PEP 668's "externally-managed-environment" block on Debian/Ubuntu.

### Keep the lab isolated

- Use a **dedicated VM or container** — snapshots let you roll back after a tool misbehaves.
- Route traffic through a **VPN/proxy you control** so scans don't resolve back to your corporate IP.
- Never paste a **production API key** (Shodan, Hunter, etc.) into a shared lab host.

> **Optional: one-shot bootstrap.** `scripts/bootstrap.sh` installs the apt packages, sets up `pipx`, and creates `~/osint/` for output. Read it before running it — never pipe a remote script straight into a shell.

---

## 01 · The toolset

Fifteen tools, grouped roughly by what stage of recon they serve. Each entry gives you **what it is**, **what it's for**, the exact **install** commands, and a **usage** example.

### theHarvester

`email & host harvesting` · `python` · `passive`

- **What it is:** A Python recon tool that aggregates emails, subdomains, hostnames, employee names, open ports and banners from public sources — search engines, certificate transparency, PGP keyservers, Shodan, and more.
- **What it's for:** The classic first pass on an organisation: build the email list (for phishing-simulation scoping or breach exposure checks) and the host list (for attack-surface mapping) without touching the target's own infrastructure.

```bash
# Kali / Debian repo (preferred on Kali)
sudo apt install -y theharvester

# Or from source (get the newest data sources)
git clone https://github.com/laramies/theHarvester.git
cd theHarvester
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

```bash
theHarvester -d example.com -b duckduckgo,bing,crtsh -l 300 -f recon-example

# -d  target domain
# -b  comma-separated data sources
# -l  result limit per source
# -f  write HTML + XML report to this base name
```

### Sherlock

`username enumeration` · `python` · `passive`

- **What it is:** A CLI that hunts a username across 400+ social networks and forums, using each site's own account-lookup, and reports where the handle exists.
- **What it's for:** Turning a single handle into a footprint of accounts. Useful for mapping an attacker's aliases during an incident, or checking how exposed a brand/handle is across platforms. No password guessing — it only checks existence.

```bash
# Isolated install (recommended)
pipx install sherlock-project

# Or from source
git clone https://github.com/sherlock-project/sherlock.git
cd sherlock
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

```bash
sherlock demo_analyst
sherlock --timeout 5 --csv --output results/ demo_analyst alt_handle

# --timeout  seconds to wait per site before giving up
# --csv      also write a CSV report
# --output   directory for reports
```

### Maltego

`link analysis` · `GUI · Java` · `hybrid`

- **What it is:** A graphical link-analysis platform. You place "entities" (a domain, email, phone, person) on a graph and run **transforms** that pull in related data and draw the relationships.
- **What it's for:** Making sense of how things connect — "which domains, MX records, emails and names cluster around this org?" The Community Edition is free; commercial transforms are paid.

```bash
# Debian/Kali package
sudo apt install -y maltego

# Otherwise download the Linux installer from the vendor site,
# make it executable and run it:
chmod +x Maltego*.sh
./Maltego*.sh
```

```bash
maltego            # launch the graph UI (needs a display)

# In the UI:  New Graph -> add a "Domain" entity -> type example.com
#             right-click -> Run Transform -> "To DNS Name [MX]"
#             repeat for Email / Person entities to grow the graph
```

### Recon-ng

`recon framework` · `python` · `hybrid`

- **What it is:** A Metasploit-style modular framework for web reconnaissance. Everything you collect lands in a local SQLite database, and modules read from and write to that database.
- **What it's for:** Running a structured recon engagement where results from one module feed the next, with a persistent workspace you can export. Think "repeatable methodology", not one-off commands.

```bash
sudo apt install -y recon-ng

# Or from source
git clone https://github.com/lanmaster53/recon-ng.git
cd recon-ng
python3 -m venv .venv && source .venv/bin/activate
pip install -r REQUIREMENTS
```

```bash
recon-ng

# then, inside the prompt:
> marketplace search
> workspaces create acme
> db insert domains
> modules load recon/domains-hosts/hackertarget
> run
> show hosts
```

### SpiderFoot

`automated OSINT` · `python` · `web UI`

- **What it is:** An automation engine with 200+ modules that correlate domains, IPs, emails, names and leaks into a single scan. Ships with a browser UI and a CLI.
- **What it's for:** "Set it and walk away" recon on a target, surfacing things you didn't know to look for. Good for a baseline exposure scan before a red-team engagement.

```bash
sudo apt install -y spiderfoot

# Or from source
git clone https://github.com/smicallef/spiderfoot.git
cd spiderfoot
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

```bash
# Web UI on localhost only
python3 sf.py -l 127.0.0.1:5001

# Headless scan of one target
python3 sf.py -s example.com -m sfp_dnsresolve,sfp_crt -o csv -q
```

### Amass (OWASP)

`attack surface` · `go` · `hybrid`

- **What it is:** The OWASP attack-surface mapping tool, in Go. It does deep subdomain enumeration (passive sources plus DNS brute-force and permutation) and network mapping via ASN lookups.
- **What it's for:** The most thorough subdomain/DNS recon you can get from one CLI. Also useful for discovering which ASNs and CIDR blocks a target actually owns.

```bash
sudo apt install -y amass

# Or via Go (latest)
go install -v github.com/owasp-amass/amass/v4/...@master

# Or snap
sudo snap install amass
```

```bash
amass enum -d example.com -o subs.txt
amass enum -passive -d example.com        # passive sources only
amass intel -whois -d example.com         # ownership / ASN intel
```

### ExifTool

`metadata / forensics` · `perl` · `offline`

- **What it is:** The reference tool for reading and writing metadata in images, PDFs, Office docs, videos and more — EXIF, GPS, camera serials, author names, software versions, embedded thumbnails.
- **What it's for:** Geolocating a photo from its GPS tags, fingerprinting which camera/phone took it, spotting the software that produced a document, and finding hidden embedded objects. The single highest-yield "one file" OSINT tool.

```bash
# Debian/Ubuntu/Kali — note the package name
sudo apt install -y libimage-exiftool-perl

exiftool -ver    # confirm it installed
```

```bash
exiftool photo.jpg                                  # dump all metadata
exiftool -a -gps:all -DateTimeOriginal photo.jpg     # just the location/time
exiftool -r -csv -ext jpg -ext pdf ./evidence > meta.csv   # batch to CSV
exiftool -all= copy.jpg                              # strip metadata (sanitise before publishing)
```

### Shodan CLI

`internet-wide scan` · `python` · `API key`

- **What it is:** The command-line client for Shodan — the search engine for internet-connected devices and services. You query Shodan's already-collected banner data rather than scanning the target yourself.
- **What it's for:** Finding exposed services (RDP, databases, ICS, cameras) tied to an org or netblock, checking what your own external footprint looks like, and grabbing host details without touching the host. Requires a free API key.

```bash
pipx install shodan        # or: pip install shodan

shodan init YOUR_API_KEY   # key from account.shodan.io
```

```bash
shodan host 8.8.8.8
shodan search --limit 20 "org:Example Corp port:3389"
shodan domain example.com
shodan stats --facets country:10 "product:nginx"
```

### Metagoofil

`document metadata` · `python` · `passive`

- **What it is:** Searches a domain for publicly indexed documents (PDF, DOCX, XLSX, PPTX), downloads them, and extracts metadata — usernames, software versions, internal file paths.
- **What it's for:** Building a people-and-software profile of an org from the documents it publishes. Author names and internal paths leak more than teams expect — a favourite for scoping phishing simulations and password-spray wordlists.

```bash
sudo apt install -y metagoofil

# Maintained fork (recommended — original is unmaintained)
git clone https://github.com/opsdisk/metagoofil.git
cd metagoofil
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

```bash
python3 metagoofil.py -d example.com -t pdf,docx,xlsx -n 20 -o out/

# -d  target domain      -t  file types
# -n  files per type     -o  output directory
```

### Photon

`crawler` · `python` · `active`

- **What it is:** A very fast web crawler written for OSINT — it walks a site and harvests URLs, emails, social handles, API keys, secret-looking strings, and interesting file links (PDFs, JS, backups).
- **What it's for:** Turning a website into structured data. Great for finding parameterised URLs and JS endpoints worth reviewing, and for spotting leaked keys in client-side bundles.

```bash
git clone https://github.com/s0md3v/Photon.git
cd Photon
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

```bash
python3 photon.py -u https://example.com -l 3 -t 20 --output results

# -u  seed URL       -l  crawl depth
# -t  threads        --output  directory for harvested data
```

### GHunt

`Google account OSINT` · `python` · `needs auth`

- **What it is:** Investigates a Google account from an email address — resolving the GAIA ID, public profile name, profile picture, linked public Maps reviews, and whether the account exists.
- **What it's for:** Attribution and account-recovery checks. In an incident you might use it to confirm whether a suspicious Gmail is real and what public footprint it carries. **It uses your own authenticated Google session**, so treat the results as personal data.

```bash
pipx install ghunt
ghunt login     # authenticate once with your own browser cookies
```

```bash
ghunt email target@example.com
ghunt drive target@example.com    # if the account exposes a public Drive item

# Only ever run this against accounts you are authorised to investigate.
```

### holehe

`email registration` · `python` · `passive`

- **What it is:** Checks whether an email address is registered on 120+ websites, using each site's own password-reset / signup existence check. It deliberately does not trigger a recovery email to the target.
- **What it's for:** Measuring where one of your users' emails is exposed — a strong input for credential-stuffing risk assessment (i.e. which third-party sites hold a password for that account).

```bash
pipx install holehe
# or
pip3 install holehe
```

```bash
holehe target@example.com
holehe --only-used target@example.com    # print only positive hits
```

### Sublist3r

`subdomain enum` · `python` · `hybrid`

- **What it is:** A subdomain enumerator that queries multiple search engines and certificate logs, with optional DNS brute-force on top.
- **What it's for:** A fast, low-friction subdomain pass when Amass is overkill. Many practitioners now run Amass as the primary and keep Sublist3r as a quick second opinion.

```bash
sudo apt install -y sublist3r

# Or from source
git clone https://github.com/aboul3la/Sublist3r.git
cd Sublist3r
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

```bash
python3 sublist3r.py -d example.com -o subs.txt -t 20
python3 sublist3r.py -d example.com -b -p 80,443    # brute-force + port check
```

### dnsrecon

`DNS enumeration` · `python` · `active`

- **What it is:** A DNS enumeration and reconnaissance script — standard record enumeration, zone-transfer attempts, SRV/MX discovery, wildcard detection, and dictionary brute-force.
- **What it's for:** Understanding a domain's DNS posture: is AXFR left open? What internal hostnames leak through records? Which mail and service endpoints exist?

```bash
sudo apt install -y dnsrecon
# or
pipx install dnsrecon
```

```bash
dnsrecon -d example.com -t std          # standard record sweep
dnsrecon -d example.com -t axfr         # attempt zone transfer
dnsrecon -d example.com -t brt -D wordlist.txt -j out.json
```

### whois & dig

`registrar & DNS` · `apt` · `built-in`

- **What they are:** The two pre-installed classics. `whois` queries domain/IP registration records; `dig` queries DNS directly.
- **What they're for:** Everything starts here. Registrar, creation date, name servers, registrant org (redacted on most gTLDs now), then the full DNS picture — A/AAAA/MX/TXT/NS/SOA and zone-transfer attempts.

```bash
sudo apt install -y whois dnsutils
# newer Debian/Ubuntu may use: sudo apt install -y bind9-dnsutils
```

```bash
whois example.com
dig +short example.com A
dig +short example.com MX
dig example.com ANY +noall +answer
dig axfr @ns1.example.com example.com     # does the zone leak?
```

---

## 02 · A real recon workflow

Tools matter less than order. This is the sequence to run against an **authorised** target — each stage feeds the next:

1. **Registration & DNS baseline** — `whois example.com`, `dig NS/A/MX/TXT`, then `dnsrecon -t std`. You now know the registrar, name servers and mail surface.
2. **Subdomain discovery** — `amass enum -d example.com`, cross-checked with `sublist3r`. Resolve the list and note anything non-production (dev, staging, vpn, jenkins).
3. **Host & service profiling** — feed the host list to `theHarvester`, then check the external footprint with `shodan` (no packets to the target).
4. **People & email surface** — `theHarvester` emails, `metagoofil` document metadata, and `holehe` to see where your own users' emails are registered.
5. **Content & artefacts** — `photon` the web app, then pull any published files through `exiftool` for GPS/author leakage.
6. **Correlate** — load everything into `recon-ng` (or `spiderfoot` for an automated sweep) and map relationships in `maltego` when a graph tells the story better than a list.

> **Keep the evidence tidy.** Write every stage to a dated folder (`~/osint/2026-10-07-example.com/`), keep the raw output next to your notes, and record the exact command and timestamp. If the work ever feeds an investigation or a report, that provenance is the difference between a finding and an anecdote.

---

## 03 · Demo: tools in action

**Output below is simulated** for the write-up — real runs return different sites, counts and timings.

### Demo A — username footprint with Sherlock

Goal: a single handle appears in a report. Which platforms is it registered on?

```terminal
$ sherlock --timeout 5 --csv --output results/ demo_analyst
[*] Checking username demo_analyst on:
[+] GitHub: https://github.com/demo_analyst
[+] GitLab: https://gitlab.com/demo_analyst
[+] DockerHub: https://hub.docker.com/u/demo_analyst
[+] Reddit: https://www.reddit.com/user/demo_analyst
[+] DevTo: https://dev.to/demo_analyst
[+] HackerNews: https://news.ycombinator.com/user?id=demo_analyst
[+] Keybase: https://keybase.io/demo_analyst
[-] Twitter: Not Found
[-] Instagram: Not Found
[-] TikTok: Not Found
[*] Saved CSV report to results/demo_analyst.csv
[*] Finished in 21.6s
$ head -3 results/demo_analyst.csv
username,name,url_main,exists
demo_analyst,GitHub,https://github.com/demo_analyst,Claimed
demo_analyst,GitLab,https://gitlab.com/demo_analyst,Claimed
```

**Reading it:** the handle is a real developer identity on GitHub/GitLab/DockerHub — worth pivoting on (commit emails, linked domains). The absence of Twitter/Instagram tells you where the person *isn't*, which is just as useful for narrowing a profile.

### Demo B — domain recon with theHarvester

Goal: harvest hosts and emails for a domain from public sources before touching it.

```terminal
$ theHarvester -d example.com -b duckduckgo,bing,crtsh -l 300 -f recon-example
[*] Target: example.com
[*] Searching 3 sources, limit 300 results each...

[*] Hosts found: 14
mail.example.com:203.0.113.10
vpn.example.com:203.0.113.24
dev.example.com:198.51.100.7
staging.example.com:198.51.100.19
jenkins.example.com:198.51.100.42
api.example.com:203.0.113.55
...
[*] Emails found: 6
j.smith@example.com
s.rahman@example.com
info@example.com
careers@example.com
[*] IPs found: 9
[*] Report saved: recon-example.html / recon-example.xml
$ grep -c "," recon-example.xml
14
```

**Reading it:** `dev`, `staging` and `jenkins` are classic weak points — often less hardened and sometimes reachable from the internet. The email pattern `f.lastname@` gives you the naming convention for the organisation, and the two named addresses become pivots for further enumeration.

### Demo C — 30 seconds with ExifTool

A published photo can carry everything you need to locate it.

```terminal
$ exiftool -a -FileName -Make -Model -DateTimeOriginal -gps:all leak.jpg
File Name                        : leak.jpg
Make                             : Apple
Camera Model Name                : iPhone 13
Date/Time Original               : 2025:11:03 14:22:07
GPS Latitude Ref                 : North
GPS Latitude                     : 24 deg 51' 36.00"
GPS Longitude Ref                : East
GPS Longitude                    : 67 deg 0' 36.00"
GPS Position                     : 24 deg 51' 36.00" N, 67 deg 0' 36.00" E
$ echo "$(exiftool -s3 -GPSPosition leak.jpg)" | sed 's/ deg /d /g'
24d 51' 36.00" N, 67d 0' 36.00" E
[*] Feed the coordinate pair into any map service to place the photo.
```

> **Two lessons from this demo**
> - **Publish sanitised images.** `exiftool -all= copy.jpg` before any photo leaves your machine — GPS tags survive almost every "resize" and "share" workflow.
> - **Metadata is double-edged.** The same technique locates your own staff's published photos. It belongs in your OSINT exposure review *and* in your pre-publish checklist.

---

## 04 · Quick reference table

| Tool | Category | Install | Primary use |
|---|---|---|---|
| `theHarvester` | Harvesting | apt / git | Emails, hosts, names from public sources |
| `sherlock` | Username | pipx / git | Handle → accounts across 400+ sites |
| `maltego` | Link analysis | apt / installer | Graph relationships between entities |
| `recon-ng` | Framework | apt / git | Modular recon with a persistent DB |
| `spiderfoot` | Automation | apt / git | Broad automated OSINT sweep |
| `amass` | Attack surface | apt / go / snap | Deep subdomain & ASN enumeration |
| `exiftool` | Metadata | apt | Read/strip file metadata & GPS |
| `shodan` | Exposure | pipx / pip | Query exposed services by org/IP |
| `metagoofil` | Documents | apt / git | Users & software from public docs |
| `photon` | Crawler | git | URLs, keys, emails from a website |
| `ghunt` | Google OSINT | pipx | Google account footprint from email |
| `holehe` | Email | pipx / pip | Where an email is registered |
| `sublist3r` | Subdomains | apt / git | Quick subdomain enumeration |
| `dnsrecon` | DNS | apt / pipx | Records, AXFR, brute-force |
| `whois / dig` | Baseline | apt | Registration + DNS lookups |

---

## 05 · Ethics & legal

- Get **written authorisation** that names the exact domains, IP ranges and time window before you scan anything.
- **Passive beats active.** Prefer sources that never touch the target's infrastructure (`crtsh`, `shodan`, `whois`).
- **Respect rate limits and `robots.txt`.** Aggressive brute-force from a corporate IP is how a security team becomes the incident.
- **Handle personal data carefully.** Emails, names and account existence checks are personal data in most jurisdictions — minimise, encrypt at rest, and delete when the engagement ends.
- **Never** use these tools for stalking, harassment, credential theft or unauthorised access. That is a crime in most countries, and none of it is "just OSINT".

---

## 06 · Troubleshooting

**`error: externally-managed-environment`**
PEP 668 protects the system Python on Debian/Ubuntu. Use `pipx install <tool>` or a `venv`, never `sudo pip install`.

**Tool not found after `pipx install`**
`~/.local/bin` is not on your `PATH`. Run `pipx ensurepath` then `source ~/.bashrc`.

**`theHarvester` returns few/no results**
Most sources need API keys or are rate-limited. Start with `-b duckduckgo,bing,crtsh` and check the tool's `api-keys.yaml`.

**Amass is extremely slow**
That's the deep mode. Use `amass enum -passive -d <domain>` for a fast pass, then run the full enum overnight.

**Maltego won't start**
No display or missing Java. Run it on a desktop VM; `sudo apt install default-jre`.

**DNS tools missing (`dig`, `nslookup`)**
Newer Debian/Ubuntu split them out: `sudo apt install -y bind9-dnsutils`.

---

## Files in this repository

```
.
├── index.html              # the full GitHub-style single-page guide (published via Pages)
├── README.md               # this file — the post content in Markdown
├── LICENSE                 # MIT
└── scripts/
    └── bootstrap.sh        # one-shot toolchain bootstrap (read before running)
```

---

## License

Released under the **MIT License** — see [LICENSE](LICENSE).

The tools described are the work of their respective authors and carry their own licences; this repository only documents how to install and use them.
